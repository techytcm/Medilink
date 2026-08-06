"""Compatibility package: re-export route blueprints from their actual location.
This keeps the original imports in `app.py` working.
"""

__all__ = [
    "auth_routes",
    "patient_routes",
    "doctor_routes",
    "admin_routes",
    "api_routes",
    "error_routes",
]
