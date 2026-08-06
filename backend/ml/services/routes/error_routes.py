"""Error handlers."""
from flask import Blueprint, render_template

errors_bp = Blueprint("errors", __name__)

@errors_bp.app_errorhandler(404)
def not_found(e):
    return render_template("errors/404.html"), 404

@errors_bp.app_errorhandler(403)
def forbidden(e):
    return render_template("errors/404.html", code=403, message="Access denied"), 403

@errors_bp.app_errorhandler(500)
def server_error(e):
    return render_template("errors/404.html", code=500, message="Server error"), 500