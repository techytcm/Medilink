"""JSON API endpoints used by frontend JS."""
from flask import Blueprint, jsonify, request, session
from backend.auth import login_required
from backend.db import query
from backend.services.appointment_service import list_doctors
from backend.ml.symptom_engine import predict

api_bp = Blueprint("api", __name__, url_prefix="/api")

@api_bp.route("/doctors")
def api_doctors():
    spec = request.args.get("specialization")
    return jsonify(list_doctors(spec))

@api_bp.route("/specializations")
def specializations():
    rows = query("SELECT DISTINCT specialization FROM doctor_profiles ORDER BY specialization")
    return jsonify([r["specialization"] for r in rows])

@api_bp.route("/notifications/unread")
@login_required
def unread_count():
    row = query("SELECT COUNT(*) AS c FROM notifications WHERE user_id=%s AND is_read=FALSE",
                (session["user_id"],), one=True)
    return jsonify({"count": row["c"]})

@api_bp.route("/predict", methods=["POST"])
@login_required
def quick_predict():
    data = request.get_json(silent=True) or {}
    text = (data.get("symptoms") or "").strip()
    if not text:
        return jsonify({"error": "no symptoms provided"}), 400
    return jsonify(predict(text))