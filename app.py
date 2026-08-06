"""MediLink: Healthcare Assistant — Flask application entry point."""
import os
from datetime import timedelta
from flask import Flask, render_template, g, redirect, url_for, session
from config import Config
from backend.db import query
from backend.routes.auth_routes     import auth_bp
from backend.routes.patient_routes  import patient_bp
from backend.routes.doctor_routes   import doctor_bp
from backend.routes.admin_routes    import admin_bp
from backend.routes.api_routes      import api_bp
from backend.routes.error_routes    import errors_bp

def create_app():
    app = Flask(__name__, static_folder="static", template_folder="templates")
    app.config.from_object(Config)
    app.permanent_session_lifetime = timedelta(days=7)

    # ---------------- Template helpers ----------------
    from markupsafe import Markup, escape
    from flask import request, url_for

    def sidebar_link(endpoint, label, icon=None):
        """Return a sidebar link HTML snippet. Safe for direct inclusion in templates."""
        try:
            href = url_for(endpoint)
        except Exception:
            href = "#"
        is_active = False
        try:
            is_active = request.endpoint == endpoint
        except Exception:
            is_active = False
        classes = "block px-3 py-2 rounded-md text-sm"
        if is_active:
            classes += " bg-brand-50 text-brand-700"
        return Markup(f'<a href="{escape(href)}" class="{escape(classes)}">{escape(label)}</a>')

    # ---------------- Blueprints ----------------
    app.register_blueprint(auth_bp)
    app.register_blueprint(patient_bp)
    app.register_blueprint(doctor_bp)
    app.register_blueprint(admin_bp)
    app.register_blueprint(api_bp)
    app.register_blueprint(errors_bp)

    # ---------------- Template context ----------------
    @app.context_processor
    def inject_globals():
        user = None
        if "user_id" in session:
            user = query("SELECT user_id, full_name, email, role, avatar_url FROM users WHERE user_id=%s",
                         (session["user_id"],), one=True)
        unread = 0
        if user:
            r = query("SELECT COUNT(*) AS c FROM notifications WHERE user_id=%s AND is_read=FALSE",
                      (user["user_id"],), one=True)
            unread = r["c"] if r else 0
        return dict(current_user=user, unread_count=unread, app_name="MediLink", sidebar_link=sidebar_link)

    # ---------------- Landing ----------------
    @app.route("/")
    def landing():
        if "user_id" in session:
            role = session.get("role")
            if role == "admin":   return redirect(url_for("admin.dashboard"))
            if role == "doctor":  return redirect(url_for("doctor.dashboard"))
            return redirect(url_for("patient.dashboard"))
        return render_template("landing.html")

    @app.route("/healthz")
    def healthz():
        return {"status": "ok"}

    return app

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)),
            debug=app.config.get("FLASK_DEBUG", False))