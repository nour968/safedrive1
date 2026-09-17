import cv2
import numpy as np
import mediapipe as mp
from ultralytics import YOLO
import time
import threading

# =========================================================
# MODELS
# =========================================================

phone_model    = YOLO("../models/yolov8n.pt")
seatbelt_model = YOLO("../models/final.pt")

print("PHONE MODEL CLASSES:",    phone_model.names)
print("SEATBELT MODEL CLASSES:", seatbelt_model.names)

# =========================================================
# FACEMESH
# =========================================================

mp_face   = mp.solutions.face_mesh
face_mesh = mp_face.FaceMesh(
    static_image_mode=False,
    max_num_faces=1,
    refine_landmarks=True,
    min_detection_confidence=0.6,
    min_tracking_confidence=0.6
)

LEFT_EYE  = [33, 160, 158, 133, 153, 144]
RIGHT_EYE = [362, 385, 387, 263, 373, 380]
MOUTH     = [61, 291, 13, 14]

# =========================================================
# THRESHOLDS
# =========================================================

EYE_FRAMES      = 2     # fast drowsiness detection
MOUTH_FRAMES    = 3
PHONE_FRAMES    = 2     # was 3 — combined with YOLO skip this was too slow to trigger
SEATBELT_FRAMES = 2

YOLO_SKIP_FRAMES   = 5    # run YOLO every 5th frame to reduce lag
CALIBRATION_FRAMES = 20   # baseline ready faster
EAR_CLOSED_RATIO   = 0.75
MAR_OPEN_RATIO     = 2.0  # yawn threshold = mar_baseline * this multiplier

# Phone model runs at a higher resolution than the seatbelt model.
# At imgsz=320 a phone held low/at an angle is frequently too small
# for yolov8n to pick up. 640 costs more time per inference, but it
# only runs once every YOLO_SKIP_FRAMES frames, so the added cost is
# amortized and worth it for recall.
PHONE_IMGSZ    = 640
SEATBELT_IMGSZ = 320

# =========================================================
# GLOBALS — protected by _state_lock
# All module-level mutable state is accessed only while
# holding this lock so concurrent /frame requests from the
# same driver cannot corrupt counters or flags.
# =========================================================

_state_lock = threading.Lock()

frame_count = 0

eye_counter      = 0
mouth_counter    = 0
phone_counter    = 0
seatbelt_counter = 0

face_seen_counter    = 0
face_missing_counter = 0

# --- EAR calibration ---
ear_calibration_samples = []
ear_baseline            = None

# --- MAR calibration ---
# Mirrors the EAR calibration approach. A fixed MAR > 0.5 threshold
# does not work reliably across different face geometries / camera
# distances because mouth width also changes during a yawn, keeping
# the corner-to-corner distance in the denominator from shrinking as
# much as expected. Calibrating a per-driver "mouth closed" baseline
# and comparing against a multiple of it is far more robust.
mar_calibration_samples = []
mar_baseline            = None

drowsy_active      = False
yawn_active        = False
phone_active       = False
no_seatbelt_active = False

# Cached YOLO results — updated only on YOLO frames
_last_phone_detected = False
_last_no_seatbelt    = None   # None = YOLO hasn't run yet

# =========================================================
# HELPERS
# =========================================================

def dist(a, b):
    return np.linalg.norm(np.array(a) - np.array(b))

def eye_ratio(lm, pts, w, h):
    p = [(lm[i].x * w, lm[i].y * h) for i in pts]
    A = dist(p[1], p[5])
    B = dist(p[2], p[4])
    C = dist(p[0], p[3])
    return (A + B) / (2.0 * C + 1e-6)

def mouth_ratio(lm, w, h):
    p = [(lm[i].x * w, lm[i].y * h) for i in MOUTH]
    return dist(p[2], p[3]) / (dist(p[0], p[1]) + 1e-6)

def _filtered_median(samples, low_pct=25, high_pct=75):
    """
    Robust baseline estimate: clips outliers (blinks/yawns that may
    have slipped into the calibration window) before taking the
    median, so a single bad sample doesn't permanently skew the
    baseline for the rest of the session.
    """
    arr = np.array(samples)
    lo, hi = np.percentile(arr, [low_pct, high_pct])
    clipped = arr[(arr >= lo) & (arr <= hi)]
    if len(clipped) == 0:
        clipped = arr
    return float(np.median(clipped))

# =========================================================
# MAIN FUNCTION
# =========================================================

def process_frame(frame):

    global eye_counter, mouth_counter
    global phone_counter, seatbelt_counter
    global face_seen_counter, face_missing_counter
    global ear_calibration_samples, ear_baseline
    global mar_calibration_samples, mar_baseline
    global drowsy_active, yawn_active, phone_active, no_seatbelt_active
    global frame_count
    global _last_phone_detected, _last_no_seatbelt

    with _state_lock:

        try:

            frame_count += 1
            run_yolo = (frame_count % YOLO_SKIP_FRAMES == 0)

            frame  = cv2.resize(frame, (480, 360))
            rgb    = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            result = face_mesh.process(rgb)

            # =================================================
            # FACE DETECTION
            # =================================================

            if not result or not result.multi_face_landmarks:
                face_missing_counter += 1
                face_seen_counter = 0
                if face_missing_counter > 5:
                    eye_counter = mouth_counter = phone_counter = seatbelt_counter = 0
                    drowsy_active = yawn_active = phone_active = no_seatbelt_active = False
                return {"detected": False, "event_type": None, "confidence": 0.0,
                        "phone": False, "seatbelt": True, "drowsy": False, "yawn": False}

            face_missing_counter = 0
            face_seen_counter   += 1

            if face_seen_counter < 2:
                return {"detected": False, "event_type": None, "confidence": 0.0,
                        "phone": False, "seatbelt": True, "drowsy": False, "yawn": False}

            lm = result.multi_face_landmarks[0].landmark

            # =================================================
            # EAR / MAR
            # =================================================

            ear = (eye_ratio(lm, LEFT_EYE, 480, 360) + eye_ratio(lm, RIGHT_EYE, 480, 360)) / 2
            mar = mouth_ratio(lm, 480, 360)

            # =================================================
            # DROWSINESS — calibrated baseline
            # =================================================
            #
            # Calibration filtering: only feed samples into the
            # calibration buffer that look like "eyes plausibly
            # open" (ear > 0.15), then take a percentile-clipped
            # median rather than a raw median. This prevents a
            # blink that happens to land inside the calibration
            # window from dragging the whole-session baseline down,
            # which otherwise makes EAR_CLOSED_RATIO threshold sit
            # too low to ever be crossed by a real closure.

            if ear_baseline is None:
                if ear > 0.15:
                    ear_calibration_samples.append(ear)
                if len(ear_calibration_samples) >= CALIBRATION_FRAMES:
                    ear_baseline = _filtered_median(ear_calibration_samples)
                    print(f"EAR CALIBRATED: {ear_baseline:.4f}  "
                          f"threshold: {ear_baseline * EAR_CLOSED_RATIO:.4f}")
                eye_counter   = 0
                drowsy_active = False
            else:
                if ear < ear_baseline * EAR_CLOSED_RATIO:
                    eye_counter += 1
                else:
                    eye_counter   = 0
                    drowsy_active = False

                if eye_counter >= EYE_FRAMES:
                    drowsy_active = True

            # =================================================
            # YAWNING — calibrated baseline
            # =================================================
            #
            # Same approach as EAR: a fixed MAR > 0.5 threshold does
            # not reliably trigger because mouth width also grows
            # during a yawn, keeping the ratio lower than expected
            # on many faces/camera angles. Instead we calibrate a
            # per-session "mouth closed" baseline during the same
            # warm-up window as EAR, then flag a yawn when MAR rises
            # well above that baseline.

            if mar_baseline is None:
                # Only accept plausible "mouth closed" samples into
                # calibration (a wide-open mouth during calibration
                # would otherwise corrupt the baseline upward).
                if mar < 0.35:
                    mar_calibration_samples.append(mar)
                if len(mar_calibration_samples) >= CALIBRATION_FRAMES:
                    mar_baseline = _filtered_median(mar_calibration_samples)
                    print(f"MAR CALIBRATED: {mar_baseline:.4f}  "
                          f"threshold: {mar_baseline * MAR_OPEN_RATIO:.4f}")
                mouth_counter = 0
                yawn_active   = False
            else:
                if mar > mar_baseline * MAR_OPEN_RATIO:
                    mouth_counter += 1
                else:
                    mouth_counter = 0
                    yawn_active   = False

                if mouth_counter >= MOUTH_FRAMES:
                    yawn_active = True

            # =================================================
            # PHONE DETECTION
            # Counter only updates on YOLO frames — prevents
            # the counter resetting to 0 on every skipped frame.
            # Runs at PHONE_IMGSZ (640) instead of 320: a phone
            # held at a normal angle is often too small to detect
            # reliably by yolov8n at 320px, even with a clear view.
            # =================================================

            if run_yolo:
                phone_detected_this_run = False
                for r in phone_model.predict(frame, conf=0.25, imgsz=PHONE_IMGSZ, verbose=False):
                    if r.boxes is None:
                        continue
                    for b in r.boxes:
                        if r.names[int(b.cls[0])].lower() == "cell phone":
                            phone_detected_this_run = True
                            break
                    if phone_detected_this_run:
                        break

                _last_phone_detected = phone_detected_this_run

                if _last_phone_detected:
                    phone_counter += 1
                else:
                    phone_counter = 0
                    phone_active  = False

                if phone_counter >= PHONE_FRAMES:
                    phone_active = True

            print(f"PHONE: {'DETECTED' if _last_phone_detected else 'NOT DETECTED'} "
                  f"| counter={phone_counter} | active={phone_active}")

            # =================================================
            # SEATBELT DETECTION
            # Counter only updates on YOLO frames — same reason.
            # =================================================

            if run_yolo:
                best_class = None
                best_conf  = 0.0
                for r in seatbelt_model.predict(frame, conf=0.20, imgsz=SEATBELT_IMGSZ, verbose=False):
                    if r.boxes is None or len(r.boxes) == 0:
                        continue
                    for b in r.boxes:
                        conf = float(b.conf[0])
                        name = r.names[int(b.cls[0])].lower()
                        if conf > best_conf:
                            best_conf  = conf
                            best_class = name

                if best_class == "seatbelt" and best_conf >= 0.50:
                    _last_no_seatbelt  = False
                    no_seatbelt_active = False
                    seatbelt_counter   = 0
                else:
                    _last_no_seatbelt = True
                    seatbelt_counter += 1

                if seatbelt_counter >= SEATBELT_FRAMES:
                    no_seatbelt_active = True

            no_seatbelt_detected = False if _last_no_seatbelt is None else _last_no_seatbelt
            print(f"SEATBELT: {'NOT DETECTED' if no_seatbelt_detected else 'DETECTED'} "
                  f"| counter={seatbelt_counter} | active={no_seatbelt_active}")

            print(f"DROWSINESS: {'DETECTED' if drowsy_active else 'NOT DETECTED'} "
                  f"| EAR={ear:.3f} | counter={eye_counter}")
            print(f"YAWN: {'DETECTED' if yawn_active else 'NOT DETECTED'} "
                  f"| MAR={mar:.3f} | counter={mouth_counter}")

            # =================================================
            # DRAW ON FRAME
            # =================================================

            if phone_active:
                cv2.putText(frame, "PHONE DETECTED!", (50, 80),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 3)
            if no_seatbelt_active:
                cv2.putText(frame, "NO SEATBELT!", (50, 120),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 3)
            if drowsy_active:
                cv2.putText(frame, "DROWSY!", (50, 160),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 165, 255), 3)
            if yawn_active:
                cv2.putText(frame, "YAWNING!", (50, 200),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 165, 255), 3)

            # =================================================
            # RETURN
            # Priority: Drowsiness > Yawning > Phone > No Seatbelt
            # No cooldown here — server.py is the only gate.
            # Returning the active event_type on every frame lets
            # server.py re-emit once its cooldown elapses, so
            # sustained events (phone still held, still drowsy)
            # trigger repeat alerts automatically.
            # =================================================

            event_type = None
            confidence = 0.0

            if drowsy_active:
                event_type = "Drowsiness"
                confidence = 0.90
            elif yawn_active:
                event_type = "Yawning"
                confidence = 0.85
            elif phone_active:
                event_type = "Phone"
                confidence = 0.80
            elif no_seatbelt_active:
                event_type = "No Seatbelt Detected"
                confidence = 0.75

            return {
                "detected":    event_type is not None,
                "event_type":  event_type,
                "confidence":  confidence,
                "phone":       _last_phone_detected,
                "seatbelt":    not no_seatbelt_detected,
                "drowsy":      drowsy_active,
                "yawn":        yawn_active
            }

        except Exception as e:
            print(f"PROCESS_FRAME ERROR: {e}")
            return {"detected": False, "event_type": None, "confidence": 0.0,
                    "phone": False, "seatbelt": True, "drowsy": False, "yawn": False}