import os
from datetime import datetime, timezone

from flask import Flask, jsonify
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)


DB_CONFIG = {
    "host": os.getenv("DB_HOST", "db"),
    "port": int(os.getenv("DB_PORT", "5432")),
    "dbname": os.getenv("DB_NAME", "novasante"),
    "user": os.getenv("DB_USER", "novasante"),
    "password": os.getenv("DB_PASSWORD", "novasante"),
}
INSTANCE = os.getenv("APP_INSTANCE", "unknown")


def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)


@app.get("/")
def index():
    return jsonify(
        {
            "service": "NovaSante rendez-vous",
            "instance": INSTANCE,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "status": "ok",
        }
    )


@app.get("/appointments")
def list_appointments():
    with get_db_connection() as connection:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(
                """
                SELECT id, patient_name, doctor_name, appointment_at
                FROM appointments
                ORDER BY appointment_at ASC
                """
            )
            rows = cursor.fetchall()

    return jsonify(
        {
            "instance": INSTANCE,
            "count": len(rows),
            "appointments": rows,
        }
    )


@app.get("/health")
def health():
    db_ok = False
    try:
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                db_ok = cursor.fetchone()[0] == 1
    except Exception:
        db_ok = False

    status_code = 200 if db_ok else 503
    return (
        jsonify(
            {
                "status": "healthy" if db_ok else "degraded",
                "instance": INSTANCE,
                "database": "up" if db_ok else "down",
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
        ),
        status_code,
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
