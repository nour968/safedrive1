import sqlite3
import threading
import os
from datetime import datetime

# ======================================================
# CONFIG
# ======================================================

DB_PATH = os.path.join(
    os.path.dirname(__file__),
    "driver_data.db"
)

db_lock = threading.Lock()

# ======================================================
# CONNECTION
# ======================================================

def get_connection():
    conn = sqlite3.connect(
        DB_PATH,
        timeout=10,
        check_same_thread=False
    )
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout = 5000")
    return conn

# ======================================================
# INIT DATABASE
# ======================================================

def init_db():
    with get_connection() as conn:
        cursor = conn.cursor()

        # ==================================================
        # USERS TABLE
        # ==================================================
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS Users (
            user_id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            age INTEGER NOT NULL,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            national_id TEXT UNIQUE NOT NULL,
            license_plate TEXT NOT NULL,
            profile_image TEXT
        )
        """)

        # ==================================================
        # MIGRATION: add profile_image if missing
        # (your app.py already references this column)
        # ==================================================
        cursor.execute("PRAGMA table_info(Users)")
        user_columns = [row[1] for row in cursor.fetchall()]
        if "profile_image" not in user_columns:
            cursor.execute("ALTER TABLE Users ADD COLUMN profile_image TEXT")

        # ==================================================
        # RIDES TABLE
        # ==================================================
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS Rides (
            ride_id INTEGER PRIMARY KEY AUTOINCREMENT,
            driver_id INTEGER,
            date TEXT,
            start_time TEXT,
            end_time TEXT,
            duration_minutes INTEGER,
            FOREIGN KEY (driver_id) REFERENCES Users(user_id)
        )
        """)

        # ==================================================
        # EVENTS TABLE
        # event_type values used: "phone", "noseatbelt", "drowsy", "yawning"
        # ==================================================
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS Events (
            event_id INTEGER PRIMARY KEY AUTOINCREMENT,
            driver_id INTEGER,
            ride_id INTEGER,
            event_type TEXT,
            confidence REAL,
            timestamp TEXT,
            FOREIGN KEY (driver_id) REFERENCES Users(user_id),
            FOREIGN KEY (ride_id) REFERENCES Rides(ride_id)
        )
        """)

        # ==================================================
        # MIGRATION: add ride_id to Events if missing
        # ==================================================
        cursor.execute("PRAGMA table_info(Events)")
        event_columns = [row[1] for row in cursor.fetchall()]
        if "ride_id" not in event_columns:
            cursor.execute("ALTER TABLE Events ADD COLUMN ride_id INTEGER")

        conn.commit()

    print("Database ready at:", os.path.abspath(DB_PATH))

# ======================================================
# RIDE LIFECYCLE
# ======================================================

def start_ride(driver_id):
    """Call when 'Start Session' is tapped. Returns the new ride_id."""
    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    time_str = now.strftime("%H:%M:%S")

    with db_lock:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("""
            INSERT INTO Rides (driver_id, date, start_time)
            VALUES (?, ?, ?)
        """, (driver_id, date_str, time_str))
        ride_id = cursor.lastrowid
        conn.commit()
        conn.close()

    return ride_id


def end_ride(ride_id):
    """Call when the recording session stops. Computes duration in minutes."""
    with db_lock:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute(
            "SELECT date, start_time FROM Rides WHERE ride_id = ?",
            (ride_id,)
        )
        row = cursor.fetchone()

        if row is None:
            conn.close()
            return None

        date_str, start_time_str = row
        now = datetime.now()
        end_time_str = now.strftime("%H:%M:%S")

        start_dt = datetime.strptime(f"{date_str} {start_time_str}", "%Y-%m-%d %H:%M:%S")
        end_dt = datetime.strptime(f"{date_str} {end_time_str}", "%Y-%m-%d %H:%M:%S")
        duration_minutes = max(int((end_dt - start_dt).total_seconds() // 60), 0)

        cursor.execute("""
            UPDATE Rides
            SET end_time = ?, duration_minutes = ?
            WHERE ride_id = ?
        """, (end_time_str, duration_minutes, ride_id))

        conn.commit()
        conn.close()

    return duration_minutes

# ======================================================
# INSERT EVENT
# ======================================================

def insert_event(data):
    """
    data must contain: driver_id, event_type, confidence, timestamp
    data may optionally contain: ride_id (defaults to None if not provided,
    so existing calls like /test-alert that don't pass ride_id still work)
    event_type should be one of: "phone", "noseatbelt", "drowsy", "yawning"
    """
    with db_lock:
        conn = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO Events (
                driver_id,
                ride_id,
                event_type,
                confidence,
                timestamp
            )
            VALUES (?, ?, ?, ?, ?)
        """, (
            data["driver_id"],
            data.get("ride_id"),
            data["event_type"],
            data["confidence"],
            data["timestamp"]
        ))

        conn.commit()
        conn.close()

# ======================================================
# READ: LIST OF RIDES FOR HOME SCREEN
# ======================================================

def get_rides(driver_id):
    """Returns rides for a driver with a total alert count each (newest first)."""
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT
                r.ride_id,
                r.date,
                r.start_time,
                COUNT(e.event_id) AS alerts
            FROM Rides r
            LEFT JOIN Events e ON e.ride_id = r.ride_id
            WHERE r.driver_id = ?
            GROUP BY r.ride_id
            ORDER BY r.ride_id DESC
        """, (driver_id,))

        rows = cursor.fetchall()

    return [
        {
            "ride_id": row[0],
            "date": row[1],
            "time": row[2],
            "alerts": row[3],
        }
        for row in rows
    ]

# ======================================================
# READ: SINGLE RIDE DETAIL
# ======================================================

def get_ride_detail(ride_id):
    """Returns full ride info plus per-category alert counts."""
    with get_connection() as conn:
        cursor = conn.cursor()

        cursor.execute("""
            SELECT ride_id, date, start_time, duration_minutes
            FROM Rides
            WHERE ride_id = ?
        """, (ride_id,))
        ride_row = cursor.fetchone()

        if ride_row is None:
            return None

        cursor.execute("""
            SELECT event_type, COUNT(*)
            FROM Events
            WHERE ride_id = ?
            GROUP BY event_type
        """, (ride_id,))
        counts = dict(cursor.fetchall())

    return {
        "ride_id": ride_row[0],
        "date": ride_row[1],
        "time": ride_row[2],
        "duration_minutes": ride_row[3] or 0,
        "mobile_alerts": counts.get("Phone", 0),
        "seatbelt_alerts": counts.get("No Seatbelt Detected", 0),
        "drowsy_alerts": counts.get("Drowsiness", 0),
        "yawning_alerts": counts.get("Yawning", 0),
        "total_alerts": sum(counts.values()),
    }