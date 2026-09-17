import cv2
import numpy as np
import threading
import time
from datetime import datetime
import simpleaudio as sa
import dlib
from ultralytics import YOLO
import requests

# =========================================================
# CONFIG
# =========================================================

DRIVER_ID = 1

# CHANGE THIS TO YOUR SERVER IP LATER
API_URL = "http://192.168.1.23:8000/event"

EVENT_COOLDOWN = 5

# =========================================================
# LOAD MODELS
# =========================================================

# Phone detection model
phone_model = YOLO("../models/yolov8n.pt")

# Seatbelt custom model
seatbelt_model = YOLO("../models/final.pt")

# =========================================================
# AUDIO
# =========================================================

wave_obj = sa.WaveObject.from_wave_file("../sounds/alert.wav")

# =========================================================
# FACE DETECTION
# =========================================================

detector = dlib.get_frontal_face_detector()

predictor = dlib.shape_predictor(
    "../models/shape_predictor_68_face_landmarks.dat"
)

# =========================================================
# CAMERA
# =========================================================

cap = cv2.VideoCapture(0)

cap.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)
cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)

# =========================================================
# PARAMETERS
# =========================================================

EYE_AR_THRESH = 0.23
EYE_AR_CONSEC_FRAMES = 8

MAR_THRESH = 0.45
MOUTH_CONSEC_FRAMES = 4

PHONE_CONSEC_FRAMES = 2
SEATBELT_CONSEC_FRAMES = 5

SMOOTHING_FRAMES = 3
MAR_SMOOTHING_FRAMES = 2

YOLO_INTERVAL = 8
FACE_INTERVAL = 5

# =========================================================
# VARIABLES
# =========================================================

blink_counter = 0
mouth_counter = 0
phone_counter = 0

seatbelt_history = []

ear_history = []
mar_history = []

alert_active = False
alert_thread_running = False

frame_counter = 0

tracker_initialized = False
tracker = None
tracked_face = None

frame_for_yolo = None
yolo_lock = threading.Lock()

phone_boxes = []
seatbelt_warning = False

last_sent_times = {}

# =========================================================
# ALERT SOUND
# =========================================================

def alert_loop():

    global alert_active
    global alert_thread_running

    alert_thread_running = True

    while alert_active:

        try:
            wave_obj.play()
            time.sleep(1)

        except:
            pass

    alert_thread_running = False


def start_alert():

    global alert_thread_running

    if not alert_thread_running:

        threading.Thread(
            target=alert_loop,
            daemon=True
        ).start()

# =========================================================
# SEND EVENT
# =========================================================

def send_event(event):

    try:

        requests.post(
            API_URL,
            json=event,
            timeout=5
        )

    except Exception as e:

        print("API ERROR:", e)

# =========================================================
# EYE ASPECT RATIO
# =========================================================

def eye_aspect_ratio(eye):

    A = np.linalg.norm(eye[1] - eye[5])
    B = np.linalg.norm(eye[2] - eye[4])
    C = np.linalg.norm(eye[0] - eye[3])

    return (A + B) / (2.0 * C + 1e-6)

# =========================================================
# MOUTH ASPECT RATIO
# =========================================================

def mouth_aspect_ratio(mouth):

    A = np.linalg.norm(mouth[2] - mouth[6])
    B = np.linalg.norm(mouth[3] - mouth[5])
    C = np.linalg.norm(mouth[0] - mouth[4])

    return (A + B) / (2.0 * C + 1e-6)

# =========================================================
# YOLO WORKER THREAD
# =========================================================

def yolo_worker():

    global frame_for_yolo
    global phone_boxes
    global seatbelt_warning
    global seatbelt_history

    while True:

        if frame_for_yolo is None:

            time.sleep(0.01)
            continue

        with yolo_lock:

            frame = frame_for_yolo.copy()
            frame_for_yolo = None

        try:

            # =================================================
            # PHONE DETECTION
            # =================================================

            results_phone = phone_model.predict(
                frame,
                conf=0.3,
                imgsz=256,
                verbose=False
            )

            detected_boxes = []

            for r in results_phone:

                if r.boxes is not None:

                    for box, cls in zip(r.boxes.xyxy, r.boxes.cls):

                        # COCO phone class = 67
                        if int(cls.item()) == 67:

                            x1, y1, x2, y2 = map(int, box)

                            detected_boxes.append(
                                (x1, y1, x2, y2)
                            )

            phone_boxes = detected_boxes

            # =================================================
            # SEATBELT DETECTION
            # =================================================

            results_seatbelt = seatbelt_model.predict(
                frame,
                conf=0.4,
                imgsz=320,
                verbose=False
            )

            seatbelt_detected = False
            no_seatbelt_detected = False

            for r in results_seatbelt:

                if r.boxes is not None:

                    for box, cls in zip(r.boxes.xyxy, r.boxes.cls):

                        cls_id = int(cls.item())

                        x1, y1, x2, y2 = map(int, box)

                        if cls_id == 1:

                            label = "Seatbelt"
                            color = (0, 255, 0)

                            seatbelt_detected = True

                        else:

                            label = "No Seatbelt"
                            color = (0, 0, 255)

                            no_seatbelt_detected = True

                        cv2.rectangle(
                            frame,
                            (x1, y1),
                            (x2, y2),
                            color,
                            2
                        )

                        cv2.putText(
                            frame,
                            label,
                            (x1, y1 - 10),
                            cv2.FONT_HERSHEY_SIMPLEX,
                            0.5,
                            color,
                            2
                        )

            # =================================================
            # SEATBELT LOGIC
            # =================================================

            if no_seatbelt_detected:

                seatbelt_history.append(False)

            elif seatbelt_detected:

                seatbelt_history.append(True)

            else:

                seatbelt_history.append(False)

            if len(seatbelt_history) > SEATBELT_CONSEC_FRAMES:

                seatbelt_history.pop(0)

            seatbelt_warning = not any(seatbelt_history)

        except Exception as e:

            print("YOLO ERROR:", e)

# =========================================================
# START YOLO THREAD
# =========================================================

threading.Thread(
    target=yolo_worker,
    daemon=True
).start()

# =========================================================
# MAIN LOOP
# =========================================================

while True:

    ret, frame = cap.read()

    if not ret:
        break

    frame = cv2.resize(frame, (320, 240))

    frame_counter += 1

    gray = cv2.cvtColor(
        frame,
        cv2.COLOR_BGR2GRAY
    )

    new_alert = False
    current_event_type = None

    # =====================================================
    # FACE DETECTION + TRACKING
    # =====================================================

    if (
        not tracker_initialized or
        frame_counter % FACE_INTERVAL == 0
    ):

        faces = detector(gray, 0)

        if len(faces) > 0:

            tracked_face = faces[0]

            try:

                tracker = cv2.TrackerKCF_create()

            except:

                tracker = cv2.legacy.TrackerKCF_create()

            tracker.init(
                frame,
                (
                    tracked_face.left(),
                    tracked_face.top(),
                    tracked_face.width(),
                    tracked_face.height()
                )
            )

            tracker_initialized = True

    else:

        if tracker_initialized:

            success, bbox = tracker.update(frame)

            if success:

                x, y, w, h = map(int, bbox)

                tracked_face = dlib.rectangle(
                    x,
                    y,
                    x + w,
                    y + h
                )

            else:

                tracker_initialized = False

    # =====================================================
    # LANDMARKS
    # =====================================================

    if tracked_face:

        try:

            landmarks = predictor(
                gray,
                tracked_face
            )

            LEFT_EYE = [36, 37, 38, 39, 40, 41]
            RIGHT_EYE = [42, 43, 44, 45, 46, 47]
            MOUTH = [60, 61, 62, 63, 64, 65, 66, 67]

            left_eye = np.array([
                [landmarks.part(i).x, landmarks.part(i).y]
                for i in LEFT_EYE
            ])

            right_eye = np.array([
                [landmarks.part(i).x, landmarks.part(i).y]
                for i in RIGHT_EYE
            ])

            mouth = np.array([
                [landmarks.part(i).x, landmarks.part(i).y]
                for i in MOUTH
            ])

            # =================================================
            # EAR
            # =================================================

            ear = (
                eye_aspect_ratio(left_eye) +
                eye_aspect_ratio(right_eye)
            ) / 2

            ear_history.append(ear)

            if len(ear_history) > SMOOTHING_FRAMES:

                ear_history.pop(0)

            ear = np.mean(ear_history)

            # =================================================
            # MAR
            # =================================================

            mar = mouth_aspect_ratio(mouth)

            mar_history.append(mar)

            if len(mar_history) > MAR_SMOOTHING_FRAMES:

                mar_history.pop(0)

            mar = np.mean(mar_history)

            # =================================================
            # DROWSINESS
            # =================================================

            if ear < EYE_AR_THRESH:

                blink_counter += 1

                if blink_counter >= EYE_AR_CONSEC_FRAMES:

                    cv2.putText(
                        frame,
                        "DROWSINESS ALERT",
                        (10, 50),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.7,
                        (0, 0, 255),
                        2
                    )

                    new_alert = True
                    current_event_type = "Drowsiness"

            else:

                blink_counter = 0

            # =================================================
            # YAWNING
            # =================================================

            if mar > MAR_THRESH:

                mouth_counter += 1

                if mouth_counter >= MOUTH_CONSEC_FRAMES:

                    cv2.putText(
                        frame,
                        "YAWNING ALERT",
                        (10, 80),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.7,
                        (0, 0, 255),
                        2
                    )

                    if current_event_type != "Drowsiness":

                        current_event_type = "Yawning"

                    new_alert = True

            else:

                mouth_counter = 0

        except Exception as e:

            print("LANDMARK ERROR:", e)

    # =====================================================
    # YOLO FRAME UPDATE
    # =====================================================

    if frame_counter % YOLO_INTERVAL == 0:

        with yolo_lock:

            frame_for_yolo = frame.copy()

    # =====================================================
    # PHONE ALERT
    # =====================================================

    if len(phone_boxes) > 0:

        phone_counter += 1

        for (x1, y1, x2, y2) in phone_boxes:

            cv2.rectangle(
                frame,
                (x1, y1),
                (x2, y2),
                (255, 0, 0),
                2
            )

        if phone_counter >= PHONE_CONSEC_FRAMES:

            cv2.putText(
                frame,
                "PHONE ALERT",
                (10, 110),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                (0, 0, 255),
                2
            )

            if current_event_type not in ["Drowsiness"]:

                current_event_type = "Phone"

            new_alert = True

    else:

        phone_counter = 0

    # =====================================================
    # SEATBELT ALERT
    # =====================================================

    if seatbelt_warning:

        cv2.putText(
            frame,
            "NO SEATBELT",
            (10, 140),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (0, 0, 255),
            2
        )

        if current_event_type not in [
            "Drowsiness",
            "Phone"
        ]:

            current_event_type = "Seatbelt"

        new_alert = True

    # =====================================================
    # ALERT CONTROL
    # =====================================================

    if new_alert and not alert_active:

        alert_active = True
        start_alert()

    elif not new_alert:

        alert_active = False

    # =====================================================
    # SEND EVENT
    # =====================================================

    if new_alert and current_event_type is not None:

        current_time = time.time()

        if (
            current_event_type not in last_sent_times or
            current_time - last_sent_times[current_event_type]
            > EVENT_COOLDOWN
        ):

            last_sent_times[current_event_type] = current_time

            event = {
                "driver_id": DRIVER_ID,
                "event_type": current_event_type,
                "confidence": 0.95,
                "timestamp": datetime.now().strftime(
                    "%Y-%m-%d %H:%M:%S"
                )
            }

            threading.Thread(
                target=send_event,
                args=(event,),
                daemon=True
            ).start()

            print("EVENT SENT:", event)

    # =====================================================
    # DISPLAY
    # =====================================================

    cv2.imshow(
        "Safe Drive System",
        frame
    )

    key = cv2.waitKey(1) & 0xFF

    if key == ord('q'):
        break

# =========================================================
# CLEANUP
# =========================================================

cap.release()

cv2.destroyAllWindows()