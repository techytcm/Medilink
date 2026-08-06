"""Doctor-facing routes."""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session, abort
from backend.auth import role_required
from backend.db import query, execute
from backend.services.appointment_service import for_doctor, update_status

doctor_bp = Blueprint("doctor", __name__, url_prefix="/doctor")

@doctor_bp.route("/dashboard")
@role_required("doctor")
def dashboard():
    uid = session["user_id"]
    stats = {
        "today": query(
            "SELECT COUNT(*) AS c FROM appointments WHERE doctor_id=%s AND DATE(scheduled_at)=CURDATE()",
            (uid,), one=True)["c"],
        "pending": query(
            "SELECT COUNT(*) AS c FROM appointments WHERE doctor_id=%s AND status='pending'",
            (uid,), one=True)["c"],
        "completed": query(
            "SELECT COUNT(*) AS c FROM appointments WHERE doctor_id=%s AND status='completed'",
            (uid,), one=True)["c"],
        "unread": query(
            "SELECT COUNT(*) AS c FROM notifications WHERE user_id=%s AND is_read=FALSE",
            (uid,), one=True)["c"],
    }
    upcoming = query(
        """SELECT a.*, u.full_name AS patient_name
           FROM appointments a JOIN users u ON a.patient_id=u.user_id
           WHERE a.doctor_id=%s AND a.scheduled_at >= NOW()
             AND a.status IN ('pending','confirmed')
           ORDER BY a.scheduled_at ASC LIMIT 5""", (uid,))
    return render_template("doctor/dashboard.html", stats=stats, upcoming=upcoming)

@doctor_bp.route("/appointments")
@role_required("doctor")
def appointments():
    rows = for_doctor(session["user_id"])
    return render_template("doctor/appointments.html", appointments=rows)

@doctor_bp.route("/appointments/<int:aid>/status", methods=["POST"])
@role_required("doctor")
def change_status(aid):
    new_status = request.form.get("status")
    if new_status not in ("confirmed", "completed", "cancelled", "rejected"):
        abort(400)
    update_status(aid, new_status, session["user_id"])
    flash(f"Appointment {new_status}.", "success")
    return redirect(url_for("doctor.appointments"))

@doctor_bp.route("/patients/<int:pid>")
@role_required("doctor")
def patient_detail(pid):
    patient = query("SELECT * FROM users WHERE user_id=%s AND role='patient'", (pid,), one=True)
    if not patient:
        abort(404)
    profile = query("SELECT * FROM patient_profiles WHERE user_id=%s", (pid,), one=True)
    history = query("SELECT * FROM predictions WHERE user_id=%s ORDER BY created_at DESC LIMIT 20", (pid,))
    appts   = query("SELECT * FROM appointments WHERE patient_id=%s AND doctor_id=%s ORDER BY scheduled_at DESC",
                    (pid, session["user_id"]))
    return render_template("doctor/patient_detail.html", patient=patient, profile=profile,
                           history=history, appointments=appts)

@doctor_bp.route("/appointments/<int:aid>/notes", methods=["POST"])
@role_required("doctor")
def add_notes(aid):
    diagnosis    = request.form.get("diagnosis", "")
    prescription = request.form.get("prescription", "")
    notes        = request.form.get("notes", "")
    follow_up    = request.form.get("follow_up_date") or None
    execute(
        """INSERT INTO consultation_records
           (appointment_id, diagnosis, prescription, notes, follow_up_date)
           VALUES (%s,%s,%s,%s,%s)""",
        (aid, diagnosis, prescription, notes, follow_up),
    )
    execute("UPDATE appointments SET status='completed' WHERE appointment_id=%s", (aid,))
    flash("Consultation notes saved and appointment marked complete.", "success")
    return redirect(url_for("doctor.appointments"))