"""Service layer for predictions."""
from datetime import datetime
from backend.db import query, execute
from backend.ml.symptom_engine import predict as engine_predict

def analyze(symptom_text: str, user_id: int) -> dict:
    result = engine_predict(symptom_text)

    # Persist the prediction record (only if a top disease was found)
    if result["top"]:
        top = result["top"]
        last_id, _ = execute(
            """INSERT INTO predictions
               (user_id, symptoms_input, symptoms_processed, predicted_disease,
                confidence_score, risk_level, recommendations, specialist)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s)""",
            (
                user_id,
                symptom_text,
                ",".join(result["processed_symptoms"]),
                top["disease"],
                top["confidence"],
                top["risk_level"],
                top["recommendations"],
                top["specialist"],
            ),
        )
        result["prediction_id"] = last_id
    return result

def history_for_user(user_id: int, limit: int = 20):
    return query(
        """SELECT * FROM predictions WHERE user_id=%s
           ORDER BY created_at DESC LIMIT %s""",
        (user_id, limit),
    )

def get_by_id(prediction_id: int, user_id: int):
    return query(
        "SELECT * FROM predictions WHERE prediction_id=%s AND user_id=%s",
        (prediction_id, user_id), one=True,
    )