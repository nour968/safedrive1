from flask import (
    Flask,
    request,
    jsonify,
    send_from_directory
)
from database_handler import (
    init_db,
    insert_event,
    get_connection,
    start_ride,
    end_ride,
    get_rides,
    get_ride_detail
)

from flask_cors import CORS
from flask_socketio import SocketIO

from datetime import datetime

import sqlite3
import random
import time
import smtplib
import os
import base64
import cv2
import numpy as np

from werkzeug.utils import secure_filename

from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from ai_processor import process_frame

from database_handler import (
    init_db,
    insert_event,
    get_connection
)

# ======================================================
# APP SETUP
# ======================================================

app = Flask(__name__)

CORS(app)

socketio = SocketIO(
    app,
    cors_allowed_origins="*",
    async_mode="threading",
    logger=False,
    engineio_logger=False,
    ping_timeout=20,
    ping_interval=10
)

# ======================================================
# INIT DATABASE
# ======================================================

init_db()

# ======================================================
# UPLOAD FOLDER SETUP
# ======================================================

UPLOAD_FOLDER = "uploads"

if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER

# ======================================================
# OTP STORAGE
# ======================================================

otp_store = {}

# ======================================================
# EMAIL CONFIG
# ======================================================

EMAIL_ADDRESS = "alerto2026@gmail.com"
EMAIL_PASSWORD = "tnli xiem pzse jwzw"

# ======================================================
# ALERT DEDUPLICATION
# ======================================================

ALERT_COOLDOWN_SECONDS = 15

_last_sent: dict = {}

def should_emit_alert(driver_id, event_type):
    now = time.time()
    driver_state = _last_sent.setdefault(driver_id, {})
    last_time    = driver_state.get(event_type, 0)

    if now - last_time >= ALERT_COOLDOWN_SECONDS:
        driver_state[event_type] = now
        return True

    return False


# ======================================================
# HOME
# ======================================================

@app.route("/")
def home():
    return "SafeDrive Server Running"

# ======================================================
# SOCKET EVENTS
# ======================================================

@socketio.on("connect")
def on_connect():
    print("CLIENT CONNECTED")

@socketio.on("disconnect")
def on_disconnect():
    print("CLIENT DISCONNECTED")

# ======================================================
# SERVE IMAGES
# ======================================================

@app.route("/uploads/<filename>")
def uploaded_file(filename):
    return send_from_directory(
        app.config["UPLOAD_FOLDER"],
        filename
    )

# ======================================================
# UPLOAD PROFILE IMAGE
# ======================================================

@app.route("/upload-profile-image/<int:user_id>", methods=["POST"])
def upload_profile_image(user_id):

    try:

        if "image" not in request.files:
            return jsonify({"status": "error", "message": "No image provided"})

        image = request.files["image"]

        if image.filename == "":
            return jsonify({"status": "error", "message": "Empty filename"})

        filename   = secure_filename(f"user_{user_id}_{image.filename}")
        image_path = os.path.join(app.config["UPLOAD_FOLDER"], filename)
        image.save(image_path)

        conn   = get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE Users SET profile_image=? WHERE user_id=?", (filename, user_id))
        conn.commit()
        conn.close()

        return jsonify({
            "status":    "success",
            "image_url": f"http://192.168.1.8:8000/uploads/{filename}"
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# SIGNUP
# ======================================================

@app.route("/signup", methods=["POST"])
def signup():

    try:

        data = request.json

        first_name    = data.get("first_name")
        last_name     = data.get("last_name")
        age           = data.get("age")
        username      = data.get("username")
        email         = data.get("email")
        password      = data.get("password")
        national_id   = data.get("national_id")
        license_plate = data.get("license_plate")

        if not all([first_name, last_name, age, username, email, password, national_id, license_plate]):
            return jsonify({"status": "error", "message": "All fields required"})

        conn   = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT * FROM Users WHERE username=?", (username,))
        if cursor.fetchone():
            conn.close()
            return jsonify({"status": "error", "message": "Username already exists"})

        cursor.execute("SELECT * FROM Users WHERE email=?", (email,))
        if cursor.fetchone():
            conn.close()
            return jsonify({"status": "error", "message": "Email already exists"})

        cursor.execute("SELECT * FROM Users WHERE national_id=?", (national_id,))
        if cursor.fetchone():
            conn.close()
            return jsonify({"status": "error", "message": "National ID already exists"})

        cursor.execute("""
            INSERT INTO Users (first_name, last_name, age, username, email, password, national_id, license_plate)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (first_name, last_name, age, username, email, password, national_id, license_plate))

        conn.commit()
        conn.close()

        return jsonify({"status": "success", "message": "Signup successful"})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# LOGIN
# ======================================================

@app.route("/login", methods=["POST"])
def login():

    try:

        data     = request.json
        username = data.get("username")
        password = data.get("password")

        conn   = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT user_id, password FROM Users WHERE username=?", (username,))
        user = cursor.fetchone()
        conn.close()

        if not user:
            return jsonify({"status": "error", "field": "username", "message": "User not found"}), 401

        if user[1] != password:
            return jsonify({"status": "error", "field": "password", "message": "Wrong password"}), 401

        return jsonify({"status": "success", "user_id": user[0]}), 200

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# ======================================================
# GET USER PROFILE
# ======================================================

@app.route("/get-user/<int:user_id>", methods=["GET"])
def get_user(user_id):

    try:

        conn   = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT first_name, last_name, username, email, age, national_id, license_plate, profile_image
            FROM Users WHERE user_id=?
        """, (user_id,))
        user = cursor.fetchone()
        conn.close()

        if not user:
            return jsonify({"status": "error", "message": "User not found"})

        return jsonify({
            "status": "success",
            "user": {
                "name":          f"{user[0]} {user[1]}",
                "username":      user[2],
                "email":         user[3],
                "age":           user[4],
                "national_id":   user[5],
                "license_plate": user[6],
                "profile_image": user[7]
            }
        })

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# UPDATE USER
# ======================================================

@app.route("/update-user/<int:user_id>", methods=["POST"])
def update_user(user_id):

    try:

        data     = request.json
        username = data.get("username")

        conn   = get_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT user_id FROM Users WHERE username=? AND user_id!=?", (username, user_id))
        if cursor.fetchone():
            conn.close()
            return jsonify({"status": "error", "message": "Username already exists"})

        cursor.execute("""
            UPDATE Users
            SET first_name=?, last_name=?, username=?, email=?, age=?, national_id=?, license_plate=?
            WHERE user_id=?
        """, (
            data.get("first_name"), data.get("last_name"), username,
            data.get("email"), data.get("age"), data.get("national_id"),
            data.get("license_plate"), user_id
        ))

        conn.commit()
        conn.close()

        return jsonify({"status": "success", "message": "User updated"})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# SEND OTP
# ======================================================

@app.route("/send-otp", methods=["POST"])
def send_otp():

    try:

        data  = request.json
        email = data.get("email")

        if not email:
            return jsonify({"status": "error", "message": "Email required"})

        conn   = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM Users WHERE email=?", (email,))
        user = cursor.fetchone()
        conn.close()

        if not user:
            return jsonify({"status": "error", "message": "Email not found"})

        otp = str(random.randint(10000, 99999))

        otp_store[email] = {"otp": otp, "expiry": time.time() + 300}

        subject = "SafeDrive OTP Verification"
        body    = f"Hello,\n\nYour OTP code is:\n\n{otp}\n\nThis OTP expires in 5 minutes.\n\nSafeDrive Team"

        msg            = MIMEMultipart()
        msg["From"]    = EMAIL_ADDRESS
        msg["To"]      = email
        msg["Subject"] = subject
        msg.attach(MIMEText(body, "plain"))

        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()
        server.login(EMAIL_ADDRESS, EMAIL_PASSWORD)
        server.send_message(msg)
        server.quit()

        print(f"OTP sent to {email}: {otp}")

        return jsonify({"status": "success", "message": "OTP sent successfully"})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# VERIFY OTP
# ======================================================

@app.route("/verify-otp", methods=["POST"])
def verify_otp():

    try:

        data  = request.json
        email = data.get("email")
        otp   = data.get("otp")

        if not otp:
            return jsonify({"status": "error", "message": "OTP required"})

        if len(otp) != 5:
            return jsonify({"status": "error", "message": "OTP must be 5 digits"})

        if email not in otp_store:
            return jsonify({"status": "error", "message": "OTP not found"})

        stored = otp_store[email]

        if time.time() > stored["expiry"]:
            del otp_store[email]
            return jsonify({"status": "error", "message": "OTP expired"})

        if stored["otp"] != otp:
            return jsonify({"status": "error", "message": "Invalid OTP"})

        return jsonify({"status": "success", "message": "OTP verified"})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# RESET PASSWORD
# ======================================================

@app.route("/reset-password", methods=["POST"])
def reset_password():

    try:

        data         = request.json
        email        = data.get("email")
        new_password = data.get("new_password")

        if not email or not new_password:
            return jsonify({"status": "error", "message": "Email and password required"})

        conn   = get_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE Users SET password=? WHERE email=?", (new_password, email))
        conn.commit()
        conn.close()

        if email in otp_store:
            del otp_store[email]

        return jsonify({"status": "success", "message": "Password updated"})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# TEST ALERT
# ======================================================

@app.route("/test-alert")
def test_alert():

    event = {
        "driver_id":  1,
        "event_type": "Drowsiness",
        "confidence": 0.95,
        "timestamp":  datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }

    insert_event(event)
    socketio.emit("new_alert", event)
    print("TEST ALERT SENT")

    return jsonify({"status": "success"})

# ======================================================
# FRAME API
# ======================================================

@app.route("/frame", methods=["POST"])
def receive_frame():

    try:

        data       = request.json
        driver_id  = data.get("driver_id")
        ride_id    = data.get("ride_id")
        image_data = data.get("image")

        if image_data is None:
            return jsonify({"status": "error", "message": "No image received"})

        image_bytes = base64.b64decode(image_data)
        np_arr      = np.frombuffer(image_bytes, np.uint8)
        frame       = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        if frame is None:
            return jsonify({"status": "error", "message": "Invalid frame"})

        print("FRAME RECEIVED FROM DRIVER:", driver_id)

        start_time = time.time()
        result     = process_frame(frame)
        print("AI TIME:", round(time.time() - start_time, 2), "seconds")
        print("AI RESULT:", result)

        event_type = result.get("event_type")

        socketio.emit("frame_result", {
            "driver_id":  driver_id,
            "event_type": event_type,
            "confidence": result.get("confidence", 0.0),
            "drowsy":     result.get("drowsy",  False),
            "yawn":       result.get("yawn",    False),
            "phone":      result.get("phone",   False),
            "seatbelt":   result.get("seatbelt", True),
            "timestamp":  datetime.now().strftime("%H:%M:%S")
        })

        if event_type and should_emit_alert(driver_id, event_type):

            event = {
                "driver_id":  driver_id,
                "ride_id":    ride_id,
                "event_type": event_type,
                "confidence": result.get("confidence", 0.0),
                "timestamp":  datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }

            insert_event(event)
            socketio.emit("new_alert", event)
            print("ALERT SENT:", event)

        return jsonify({
            "status":     "success",
            "event_type": event_type,
            "confidence": result.get("confidence", 0.0)
        })

    except Exception as e:
        print("FRAME API ERROR:", str(e))
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# RECEIVE EVENT
# ======================================================

@app.route("/events", methods=["GET"])
def get_events():

    try:

        conn   = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT event_id, driver_id, ride_id, event_type, confidence, timestamp
            FROM Events
            ORDER BY event_id DESC
        """)
        rows = cursor.fetchall()
        conn.close()

        events = [
            {
                "event_id":   row[0],
                "driver_id":  row[1],
                "ride_id":    row[2],
                "event_type": row[3],
                "confidence": row[4],
                "timestamp":  row[5]
            }
            for row in rows
        ]

        return jsonify({"status": "success", "events": events})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})
# ======================================================
# RIDES
# ======================================================

@app.route("/rides/<int:driver_id>", methods=["GET"])
def rides_list(driver_id):
    try:
        rides = get_rides(driver_id)
        return jsonify({"status": "success", "rides": rides})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})


@app.route("/ride-detail/<int:ride_id>", methods=["GET"])
def ride_detail(ride_id):
    try:
        detail = get_ride_detail(ride_id)
        if detail is None:
            return jsonify({"status": "error", "message": "Ride not found"}), 404
        return jsonify({"status": "success", "ride": detail})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})


@app.route("/start-ride", methods=["POST"])
def start_ride_endpoint():
    try:
        data = request.json
        driver_id = data.get("driver_id")
        ride_id = start_ride(driver_id)
        return jsonify({"status": "success", "ride_id": ride_id})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})


@app.route("/end-ride/<int:ride_id>", methods=["POST"])
def end_ride_endpoint(ride_id):
    try:
        duration = end_ride(ride_id)
        if duration is None:
            return jsonify({"status": "error", "message": "Ride not found"}), 404
        return jsonify({"status": "success", "duration_minutes": duration})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

# ======================================================
# RUN SERVER
# ======================================================

if __name__ == "__main__":
    socketio.run(
        app,
        host="0.0.0.0",
        port=8000,
        debug=False
    )