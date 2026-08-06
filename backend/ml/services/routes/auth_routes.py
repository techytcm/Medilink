"""Authentication routes: register, login, logout, password reset."""
from flask import Blueprint, render_template, request, redirect, url_for, flash, session
from backend.db import query, execute
from backend.auth import (hash_password, verify_password, login_user, logout_user,
                          generate_reset_token, validate_reset_token,
                          consume_reset_token)
from backend.validators import valid_email, valid_password, sanitize_text
from backend.services.audit_service import log as audit_log
from backend.services.notification_service import notify
import bcrypt, secrets

auth_bp = Blueprint("auth", __name__)

@auth_bp.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        full_name = sanitize_text(request.form.get("full_name", ""), 120)
        email     = request.form.get("email", "").strip().lower()
        phone     = request.form.get("phone", "").strip()
        password  = request.form.get("password", "")
        role      = request.form.get("role", "patient")
        confirm   = request.form.get("confirm_password", "")

        errors = []
        if not full_name:                       errors.append("Full name is required.")
        if not valid_email(email):              errors.append("A valid email is required.")
        if query("SELECT user_id FROM users WHERE email=%s", (email,), one=True):
            errors.append("An account with this email already exists.")
        if not valid_password(password):        errors.append("Password must be 8+ chars with a letter and a number.")
        if password != confirm:                 errors.append("Passwords do not match.")
        if role not in ("patient", "doctor"):   role = "patient"

        if errors:
            for e in errors: flash(e, "danger")
            return render_template("auth/register.html", form=request.form)

        user_id, _ = execute(
            """INSERT INTO users (full_name, email, phone, password_hash, role)
               VALUES (%s,%s,%s,%s,%s)""",
            (full_name, email, phone, hash_password(password), role),
        )

        if role == "patient":
            execute("INSERT INTO patient_profiles (user_id) VALUES (%s)", (user_id,))
        elif role == "doctor":
            specialization = sanitize_text(request.form.get("specialization", "General"), 100)
            license_no     = sanitize_text(request.form.get("license_number", ""), 50)
            execute(
                """INSERT INTO doctor_profiles
                   (user_id, specialization, license_number, years_of_experience, is_verified)
                   VALUES (%s,%s,%s,%s,FALSE)""",
                (user_id, specialization or "General Physician", license_no,
                 int(request.form.get("experience", 0) or 0)),
            )

        notify(user_id, "Welcome to MediLink!",
               "Your account has been created. Complete your profile to get the most out of MediLink.",
               "success")
        audit_log(user_id, "register", "users", user_id)
        flash("Account created. Please sign in.", "success")
        return redirect(url_for("auth.login"))

    return render_template("auth/register.html")

@auth_bp.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email    = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        remember = bool(request.form.get("remember"))

        user = query("SELECT * FROM users WHERE email=%s", (email,), one=True)
        if not user or not verify_password(password, user["password_hash"]):
            flash("Invalid email or password.", "danger")
            return render_template("auth/login.html", form=request.form)

        if not user["is_active"]:
            flash("Your account has been deactivated. Contact support.", "warning")
            return render_template("auth/login.html")

        login_user(user)
        audit_log(user["user_id"], "login")
        flash(f"Welcome back, {user['full_name'].split()[0]}!", "success")

        next_url = request.args.get("next")
        if next_url and next_url.startswith("/"):
            return redirect(next_url)

        if user["role"] == "admin":
            return redirect(url_for("admin.dashboard"))
        elif user["role"] == "doctor":
            return redirect(url_for("doctor.dashboard"))
        return redirect(url_for("patient.dashboard"))

    return render_template("auth/login.html")

@auth_bp.route("/logout")
def logout():
    audit_log(session.get("user_id"), "logout")
    logout_user()
    flash("You've been signed out.", "info")
    return redirect(url_for("auth.login"))

@auth_bp.route("/reset", methods=["GET", "POST"])
def reset_request():
    if request.method == "POST":
        email = request.form.get("email", "").strip().lower()
        user = query("SELECT * FROM users WHERE email=%s", (email,), one=True)
        if user:
            token = generate_reset_token(user["user_id"])
            # In production, email this link. For demo, we flash it.
            flash(f"Password reset link generated (demo): "
                  f"<a href='{url_for('auth.reset_confirm', token=token)}' class='underline'>reset now</a>",
                  "info")
        else:
            flash("If that email exists, a reset link has been sent.", "info")
        return redirect(url_for("auth.reset_request"))
    return render_template("auth/reset.html", stage="request")

@auth_bp.route("/reset/<token>", methods=["GET", "POST"])
def reset_confirm(token):
    row = validate_reset_token(token)
    if not row:
        flash("Reset link is invalid or expired.", "danger")
        return redirect(url_for("auth.reset_request"))
    if request.method == "POST":
        password = request.form.get("password", "")
        confirm  = request.form.get("confirm_password", "")
        if not valid_password(password):
            flash("Password must be 8+ chars with a letter and a number.", "danger")
            return render_template("auth/reset.html", stage="confirm", token=token)
        if password != confirm:
            flash("Passwords do not match.", "danger")
            return render_template("auth/reset.html", stage="confirm", token=token)
        execute("UPDATE users SET password_hash=%s WHERE user_id=%s",
                (hash_password(password), row["user_id"]))
        consume_reset_token(token)
        audit_log(row["user_id"], "password_reset", "users", row["user_id"])
        flash("Password updated. Please sign in.", "success")
        return redirect(url_for("auth.login"))
    return render_template("auth/reset.html", stage="confirm", token=token)