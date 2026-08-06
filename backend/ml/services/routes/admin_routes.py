"""Admin routes."""
from flask import Blueprint, render_template, request, redirect, url_for, flash, abort
from backend.auth import role_required
from backend.db import query, execute
from backend.services.appointment_service import all_appointments

admin_bp = Blueprint("admin", __name__, url_prefix="/admin")

@admin_bp.route("/dashboard")
@role_required("admin")
def dashboard():
    stats = {
        "users":      query("SELECT COUNT(*) AS c FROM users", one=True)["c"],
        "patients":   query("SELECT COUNT(*) AS c FROM users WHERE role='patient'", one=True)["c"],
        "doctors":    query("SELECT COUNT(*) AS c FROM users WHERE role='doctor'", one=True)["c"],
        "appointments": query("SELECT COUNT(*) AS c FROM appointments", one=True)["c"],
        "predictions":  query("SELECT COUNT(*) AS c FROM predictions", one=True)["c"],
        "feedback_open": query("SELECT COUNT(*) AS c FROM feedback WHERE status='open'", one=True)["c"],
    }
    by_risk = query(
        """SELECT risk_level, COUNT(*) AS c FROM predictions
           GROUP BY risk_level ORDER BY FIELD(risk_level,'critical','high','moderate','low')""") or []
    by_status = query(
        "SELECT status, COUNT(*) AS c FROM appointments GROUP BY status") or []
    recent_users = query("SELECT user_id, full_name, email, role, created_at FROM users ORDER BY created_at DESC LIMIT 5") or []
    return render_template("admin/dashboard.html", stats=stats, by_risk=by_risk,
                           by_status=by_status, recent_users=recent_users)

@admin_bp.route("/users")
@role_required("admin")
def users():
    rows = query(
        """SELECT u.*, p.gender, p.blood_group
           FROM users u LEFT JOIN patient_profiles p ON u.user_id=p.user_id
           ORDER BY u.created_at DESC""")
    return render_template("admin/users.html", users=rows or [])

@admin_bp.route("/users/<int:uid>/toggle", methods=["POST"])
@role_required("admin")
def toggle_user(uid):
    user = query("SELECT * FROM users WHERE user_id=%s", (uid,), one=True)
    if not user: abort(404)
    if user["role"] == "admin" and user["user_id"] == session["user_id"]:
        flash("You can't deactivate your own admin account.", "danger")
        return redirect(url_for("admin.users"))
    execute("UPDATE users SET is_active=NOT is_active WHERE user_id=%s", (uid,))
    flash(f"User {'activated' if not user['is_active'] else 'deactivated'}.", "success")
    return redirect(url_for("admin.users"))

@admin_bp.route("/doctors")
@role_required("admin")
def doctors():
    rows = query(
        """SELECT u.*, d.specialization, d.license_number, d.years_of_experience,
                  d.rating, d.is_verified, d.consultation_fee
           FROM users u JOIN doctor_profiles d ON u.user_id=d.user_id
           ORDER BY d.rating DESC""")
    return render_template("admin/doctors.html", doctors=rows or [])

@admin_bp.route("/doctors/<int:uid>/verify", methods=["POST"])
@role_required("admin")
def verify_doctor(uid):
    execute("UPDATE doctor_profiles SET is_verified=TRUE WHERE user_id=%s", (uid,))
    flash("Doctor verified.", "success")
    return redirect(url_for("admin.doctors"))

@admin_bp.route("/reports")
@role_required("admin")
def reports():
    report = {
        "appointments": all_appointments() or [],
        "predictions":  query("SELECT p.*, u.full_name FROM predictions p JOIN users u ON p.user_id=u.user_id ORDER BY p.created_at DESC LIMIT 100") or [],
        "risk_distribution": query("SELECT risk_level, COUNT(*) AS c FROM predictions GROUP BY risk_level") or [],
        "top_diseases": query("SELECT predicted_disease, COUNT(*) AS c FROM predictions WHERE predicted_disease IS NOT NULL GROUP BY predicted_disease ORDER BY c DESC LIMIT 10") or [],
    }
    return render_template("admin/reports.html", report=report)

@admin_bp.route("/audit")
@role_required("admin")
def audit_logs():
    rows = query(
        """SELECT l.*, u.full_name AS user_name
           FROM audit_logs l LEFT JOIN users u ON l.user_id=u.user_id
           ORDER BY l.created_at DESC LIMIT 200""")
    return render_template("admin/audit_logs.html", logs=rows or [])

@admin_bp.route("/feedback")
@role_required("admin")
def feedback():
    rows = query(
        """SELECT f.*, u.full_name, u.email
           FROM feedback f JOIN users u ON f.user_id=u.user_id
           ORDER BY f.created_at DESC""")
    return render_template("admin/feedback.html", feedback=rows or [])

@admin_bp.route("/feedback/<int:fid>/status", methods=["POST"])
@role_required("admin")
def feedback_status(fid):
    status = request.form.get("status")
    if status not in ("open", "in_review", "resolved"):
        abort(400)
    execute("UPDATE feedback SET status=%s WHERE feedback_id=%s", (status, fid))
    flash("Feedback status updated.", "success")
    return redirect(url_for("admin.feedback"))