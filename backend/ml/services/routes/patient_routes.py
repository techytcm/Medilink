"""Patient-facing routes."""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session, jsonify
from backend.auth import login_required, role_required
from backend.db import query, execute
from backend.services.prediction_service import analyze, history_for_user
from backend.services.appointment_service import list_doctors, book, for_patient
from backend.services.notification_service import for_user, mark_read, mark_all_read
from backend.services.chatbot_service import handle_message, history as chat_history
from backend.validators import sanitize_text
from backend.ml.symptom_engine import chatbot_reply
from datetime import datetime

patient_bp = Blueprint("patient", __name__, url_prefix="/patient")

@patient_bp.route("/dashboard")
@role_required("patient")
def dashboard():
    uid = session["user_id"]
    stats = {
        "predictions": query("SELECT COUNT(*) AS c FROM predictions WHERE user_id=%s", (uid,), one=True)["c"],
        "appointments": query("SELECT COUNT(*) AS c FROM appointments WHERE patient_id=%s", (uid,), one=True)["c"],
        "upcoming": query(
            "SELECT COUNT(*) AS c FROM appointments WHERE patient_id=%s AND scheduled_at > NOW() AND status IN ('pending','confirmed')",
            (uid,), one=True)["c"],
        "unread": query("SELECT COUNT(*) AS c FROM notifications WHERE user_id=%s AND is_read=FALSE", (uid,), one=True)["c"],
    }
    recent_predictions = query(
        "SELECT * FROM predictions WHERE user_id=%s ORDER BY created_at DESC LIMIT 3", (uid,))
    upcoming_appointments = query(
        """SELECT a.*, u.full_name AS doctor_name, d.specialization
           FROM appointments a JOIN users u ON a.doctor_id=u.user_id
           LEFT JOIN doctor_profiles d ON a.doctor_id=d.user_id
           WHERE a.patient_id=%s AND a.scheduled_at > NOW()
             AND a.status IN ('pending','confirmed')
           ORDER BY a.scheduled_at ASC LIMIT 3""", (uid,))
    return render_template("patient/dashboard.html", stats=stats,
                           recent_predictions=recent_predictions,
                           upcoming_appointments=upcoming_appointments)

@patient_bp.route("/symptoms", methods=["GET", "POST"])
@role_required("patient")
def symptoms():
    if request.method == "POST":
        text = sanitize_text(request.form.get("symptoms", ""), 2000)
        if not text:
            flash("Please describe your symptoms.", "warning")
            return redirect(url_for("patient.symptoms"))
        result = analyze(text, session["user_id"])
        if result["top"]:
            return render_template("patient/prediction.html", result=result)
        flash("We couldn't identify recognizable symptoms. Please add more detail.", "info")
        return render_template("patient/symptoms.html", input=text)
    return render_template("patient/symptoms.html")

@patient_bp.route("/prediction/history")
@role_required("patient")
def prediction_history():
    history = history_for_user(session["user_id"], limit=50)
    return render_template("patient/prediction.html", history=history, mode="history")

@patient_bp.route("/appointments", methods=["GET", "POST"])
@role_required("patient")
def appointments():
    if request.method == "POST":
        doctor_id    = request.form.get("doctor_id", type=int)
        scheduled_at = request.form.get("scheduled_at")
        reason       = sanitize_text(request.form.get("reason", ""), 500)
        if not doctor_id or not scheduled_at:
            flash("Please pick a doctor and a valid date/time.", "danger")
            return redirect(url_for("patient.appointments"))
        try:
            dt = datetime.fromisoformat(scheduled_at)
            if dt < datetime.now():
                flash("Cannot book in the past.", "danger")
                return redirect(url_for("patient.appointments"))
        except ValueError:
            flash("Invalid date/time.", "danger")
            return redirect(url_for("patient.appointments"))
        book(session["user_id"], doctor_id, scheduled_at, reason)
        flash("Appointment requested. We'll notify you once confirmed.", "success")
        return redirect(url_for("patient.appointments"))

    doctors = list_doctors() or []
    appts   = for_patient(session["user_id"]) or []
    return render_template("patient/appointments.html", doctors=doctors, appointments=appts)

@patient_bp.route("/profile", methods=["GET", "POST"])
@role_required("patient")
def profile():
    uid = session["user_id"]
    if request.method == "POST":
        dob      = request.form.get("date_of_birth") or None
        gender   = request.form.get("gender") or None
        blood    = request.form.get("blood_group") or None
        height   = request.form.get("height_cm") or None
        weight   = request.form.get("weight_kg") or None
        allergies = sanitize_text(request.form.get("allergies"), 500)
        chronic  = sanitize_text(request.form.get("chronic_conditions"), 500)
        emerg    = sanitize_text(request.form.get("emergency_contact"), 120)
        ephone   = sanitize_text(request.form.get("emergency_phone"), 20)
        addr     = sanitize_text(request.form.get("address"), 500)
        full_name = sanitize_text(request.form.get("full_name"), 120)
        phone    = sanitize_text(request.form.get("phone"), 20)

        execute("UPDATE users SET full_name=%s, phone=%s WHERE user_id=%s",
                (full_name, phone, uid))
        exists = query("SELECT profile_id FROM patient_profiles WHERE user_id=%s", (uid,), one=True)
        if exists:
            execute("""UPDATE patient_profiles SET
                       date_of_birth=%s, gender=%s, blood_group=%s, height_cm=%s, weight_kg=%s,
                       allergies=%s, chronic_conditions=%s, emergency_contact=%s,
                       emergency_phone=%s, address=%s WHERE user_id=%s""",
                    (dob, gender, blood, height, weight, allergies, chronic, emerg, ephone, addr, uid))
        else:
            execute("""INSERT INTO patient_profiles
                       (user_id, date_of_birth, gender, blood_group, height_cm, weight_kg,
                        allergies, chronic_conditions, emergency_contact, emergency_phone, address)
                       VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                    (uid, dob, gender, blood, height, weight, allergies, chronic, emerg, ephone, addr))
        session["full_name"] = full_name
        flash("Profile updated.", "success")
        return redirect(url_for("patient.profile"))

    user    = query("SELECT * FROM users WHERE user_id=%s", (uid,), one=True)
    profile = query("SELECT * FROM patient_profiles WHERE user_id=%s", (uid,), one=True)
    return render_template("patient/profile.html", user=user, profile=profile)

@patient_bp.route("/chatbot", methods=["GET"])
@role_required("patient")
def chatbot():
    history = chat_history(session["user_id"])
    return render_template("patient/chatbot.html", history=history)

@patient_bp.route("/chatbot/send", methods=["POST"])
@role_required("patient")
def chatbot_send():
    msg = sanitize_text(request.form.get("message", ""), 1000)
    if not msg:
        return jsonify({"error": "empty"}), 400
    reply = handle_message(session["user_id"], msg)
    return jsonify({"user": msg, "bot": reply})

@patient_bp.route("/feedback", methods=["GET", "POST"])
@role_required("patient")
def feedback():
    if request.method == "POST":
        rating  = request.form.get("rating", type=int)
        subject = sanitize_text(request.form.get("subject"), 200)
        message = sanitize_text(request.form.get("message"), 1000)
        if not message or not rating or not (1 <= rating <= 5):
            flash("Please provide a rating and message.", "danger")
            return redirect(url_for("patient.feedback"))
        execute(
            "INSERT INTO feedback (user_id, rating, subject, message) VALUES (%s,%s,%s,%s)",
            (session["user_id"], rating, subject, message),
        )
        flash("Thank you for your feedback!", "success")
        return redirect(url_for("patient.feedback"))
    rows = query("SELECT * FROM feedback WHERE user_id=%s ORDER BY created_at DESC",
                 (session["user_id"],))
    return render_template("patient/feedback.html", feedback=rows)

@patient_bp.route("/notifications")
@role_required("patient")
def notifications():
    rows = for_user(session["user_id"])
    return render_template("patient/notifications.html", notifications=rows)

@patient_bp.route("/notifications/<int:nid>/read", methods=["POST"])
@role_required("patient")
def read_notification(nid):
    mark_read(nid, session["user_id"])
    return redirect(url_for("patient.notifications"))

@patient_bp.route("/notifications/read-all", methods=["POST"])
@role_required("patient")
def read_all_notifications():
    mark_all_read(session["user_id"])
    flash("All notifications marked as read.", "success")
    return redirect(url_for("patient.notifications"))

@patient_bp.route("/settings", methods=["GET", "POST"])
@role_required("patient")
def settings():
    if request.method == "POST":
        # Stub for preferences (theme, notifications toggles, etc.)
        flash("Preferences saved.", "success")
        return redirect(url_for("patient.settings"))
    return render_template("patient/settings.html")