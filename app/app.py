"""
Task 3 -- mini audio collection app.

A person enters name + phone, records audio in-browser (MediaRecorder)
or uploads a file, and submits. The audio is analyzed (duration, sample
rate, bitrate, loudness, rough quality estimate) and a record is written
into the same database built in Task 1 -- matching to an existing person
by normalized phone where possible, creating a new person otherwise.

Run:
    cd app
    python3 app.py
Then open http://localhost:5000
"""
import sqlite3
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

from flask import Flask, render_template, request, jsonify, send_from_directory

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
from normalize import norm_phone, norm_name  # noqa: E402

from audio_analysis import analyze_audio  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
DB_PATH = ROOT / "db" / "consultbae.db"
UPLOAD_DIR = Path(__file__).resolve().parent / "uploads"
UPLOAD_DIR.mkdir(exist_ok=True)

ALLOWED_EXTENSIONS = {"wav", "mp3", "webm", "ogg", "m4a", "flac"}

app = Flask(__name__)


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def find_or_create_person(conn, name, phone):
    """
    Match against Task 1's people table by normalized phone (same key
    used in the merge pipeline). If no match, create a new person rather
    than silently dropping the submission -- gig workers submitting audio
    may not have been in any of the original 3 CSVs.
    """
    phone_norm = norm_phone(phone)
    name_norm = norm_name(name)
    cur = conn.cursor()

    if phone_norm:
        cur.execute("SELECT person_id FROM people WHERE canonical_phone = ?", (phone_norm,))
        row = cur.fetchone()
        if row:
            return row["person_id"], phone_norm

    cur.execute(
        "INSERT INTO people (canonical_name, canonical_phone, matched_from_sources, match_confidence) "
        "VALUES (?, ?, 'audio_app', 'new_submission')",
        (name_norm, phone_norm),
    )
    conn.commit()
    return cur.lastrowid, phone_norm


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/submissions")
def submissions():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        SELECT s.submission_id, s.submitted_name, s.submitted_phone, s.file_path,
               s.duration_sec, s.sample_rate_hz, s.bitrate_kbps, s.loudness_dbfs,
               s.quality_estimate, s.created_at, p.person_id
        FROM audio_submissions s
        LEFT JOIN people p ON p.person_id = s.person_id
        ORDER BY s.created_at DESC
    """)
    rows = [dict(r) for r in cur.fetchall()]
    conn.close()
    return render_template("submissions.html", submissions=rows)


@app.route("/uploads/<path:filename>")
def serve_audio(filename):
    return send_from_directory(UPLOAD_DIR, filename)


@app.route("/api/submit", methods=["POST"])
def submit():
    name = (request.form.get("name") or "").strip()
    phone = (request.form.get("phone") or "").strip()
    audio_file = request.files.get("audio")

    if not name or not phone:
        return jsonify({"error": "Name and phone are required."}), 400
    if not audio_file or audio_file.filename == "":
        return jsonify({"error": "No audio provided."}), 400

    # Recorded blobs from MediaRecorder don't carry a real filename/extension;
    # default to webm (Chrome/Firefox default recording container) if none given.
    orig_name = audio_file.filename
    ext = orig_name.rsplit(".", 1)[-1].lower() if "." in orig_name else "webm"
    if ext not in ALLOWED_EXTENSIONS:
        ext = "webm"

    saved_name = f"{uuid.uuid4().hex}.{ext}"
    saved_path = UPLOAD_DIR / saved_name
    audio_file.save(saved_path)

    try:
        metrics = analyze_audio(saved_path)
    except Exception as e:
        saved_path.unlink(missing_ok=True)
        return jsonify({"error": f"Could not analyze audio: {e}"}), 422

    conn = get_db()
    person_id, phone_norm = find_or_create_person(conn, name, phone)

    cur = conn.cursor()
    cur.execute(
        """INSERT INTO audio_submissions
           (person_id, submitted_name, submitted_phone, file_path, duration_sec,
            sample_rate_hz, bitrate_kbps, loudness_dbfs, quality_estimate, created_at)
           VALUES (?,?,?,?,?,?,?,?,?,?)""",
        (
            person_id, name, phone_norm or phone, saved_name,
            metrics["duration_sec"], metrics["sample_rate_hz"], metrics["bitrate_kbps"],
            metrics["loudness_dbfs"], metrics["quality_estimate"],
            datetime.now(timezone.utc).isoformat(timespec="seconds"),
        ),
    )
    conn.commit()
    conn.close()

    return jsonify({"success": True, "person_id": person_id, "metrics": metrics})


if __name__ == "__main__":
    app.run(debug=True, port=5000)
