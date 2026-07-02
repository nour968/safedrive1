<div align="center">

# 🚗 ALERTO

### 🛡️ AI-Powered Smart Transportation & Vehicle Monitoring System

*Enhancing road safety through Computer Vision, Deep Learning, and Real-Time Monitoring.*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge\&logo=flutter\&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge\&logo=python\&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge\&logo=flask\&logoColor=white)
![YOLO](https://img.shields.io/badge/YOLO-Ultralytics-blueviolet?style=for-the-badge)
![OpenCV](https://img.shields.io/badge/OpenCV-5C3EE8?style=for-the-badge\&logo=opencv\&logoColor=white)
![MediaPipe](https://img.shields.io/badge/MediaPipe-FF6F00?style=for-the-badge)
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge\&logo=sqlite\&logoColor=white)

</div>

---

# 📖 Overview

**ALERTO** is an AI-powered driver monitoring system that improves road safety by analyzing live video streams and detecting unsafe driving behaviors in real time.

The system combines **Flutter**, **Flask**, **SQLite**, **OpenCV**, **MediaPipe**, and custom **YOLO (Ultralytics)** models to provide instant alerts through a cross-platform mobile application.

---

# ✨ Features

✅ Real-time driver monitoring

😴 Driver drowsiness detection

🥱 Yawning detection

📱 Phone usage detection

🪑 Seatbelt compliance detection

👥 Passenger overload detection

⚡ Instant safety alerts

📊 Ride history & alert logs

🌍 English & Arabic localization

📡 Live communication between AI engine and mobile application

---

# 🏗️ System Architecture

```text
📷 Driver Camera
        │
        ▼
🖼️ OpenCV Image Processing
        │
        ▼
🧠 AI Detection
(MediaPipe + YOLO)
        │
        ▼
🐍 Flask Backend
(REST API + Socket.IO)
        │
        ▼
🗄️ SQLite Database
        │
        ▼
📱 Flutter Mobile App
```

---

# 🛠️ Technology Stack

| Category                | Technologies                                         |
| ----------------------- | ---------------------------------------------------- |
| 📱 Mobile               | Flutter, Dart                                        |
| 🐍 Backend              | Flask, REST APIs, Socket.IO, WebSockets              |
| 🤖 AI & Computer Vision | Ultralytics YOLO, Roboflow, OpenCV, MediaPipe, NumPy |
| 🗄️ Database            | SQLite                                               |
| 💻 Development Tools    | Git, GitHub, Android Studio, VS Code                 |

---

# ⚙️ Workflow

1. 📷 Capture live video from the driver's camera.
2. 🖼️ Preprocess frames using OpenCV.
3. 😊 Detect facial landmarks with MediaPipe.
4. 🎯 Run custom YOLO models trained using Roboflow & Ultralytics.
5. 🚨 Detect unsafe driving behaviors.
6. 🌐 Send detection results to the Flask backend.
7. 📡 Broadcast alerts using Socket.IO.
8. 📱 Display live notifications in the Flutter application.

---

# 🚀 Project Highlights

⭐ Full-stack AI-powered transportation safety platform

⭐ Custom-trained YOLO models using Roboflow & Ultralytics

⭐ Real-time computer vision pipeline

⭐ Responsive Flutter mobile application

⭐ RESTful backend with Flask

⭐ Low-latency communication using Socket.IO & WebSockets

⭐ End-to-end integration of AI, backend, database, and mobile application

---

# 🔮 Future Improvements

* ☁️ Cloud deployment
* 📍 GPS tracking
* 📈 Driver behavior analytics dashboard
* 🚘 Multi-camera support
* 🤖 Enhanced AI models
* 🗄️ Cloud database integration

---

# 📜 License

This project was developed as a **Graduation Project** for academic and educational purposes.

