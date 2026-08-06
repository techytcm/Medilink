"""
MediLink Symptom & Risk Engine
------------------------------
A rule-based, NLP-light medical inference engine.
Designed so a future scikit-learn / transformer model can be dropped
in by replacing the `predict()` function while keeping the same I/O contract.
"""
import re
from typing import List, Dict, Any

# ----------------------------------------------------------
# Disease Knowledge Base
# ----------------------------------------------------------
DISEASE_KB: Dict[str, Dict[str, Any]] = {
    "Common Cold": {
        "symptoms": {"fever": 1, "cough": 1, "sore throat": 1, "runny nose": 1,
                     "sneezing": 1, "congestion": 1, "fatigue": 0.5},
        "risk": "low",
        "specialist": "General Physician",
        "advice": "Rest, hydrate, and use over-the-counter relievers. Symptoms usually resolve within 7 days."
    },
    "Influenza (Flu)": {
        "symptoms": {"fever": 1, "cough": 1, "body ache": 1, "fatigue": 1,
                     "chills": 1, "headache": 0.8, "sore throat": 0.5},
        "risk": "moderate",
        "specialist": "General Physician",
        "advice": "Antiviral medication may help if started early. Rest, fluids, and isolation recommended."
    },
    "COVID-19": {
        "symptoms": {"fever": 1, "cough": 1, "shortness of breath": 1, "fatigue": 1,
                     "loss of appetite": 0.7, "body ache": 0.6, "headache": 0.5},
        "risk": "high",
        "specialist": "General Physician / Pulmonologist",
        "advice": "Isolate immediately. Consider RT-PCR or antigen test. Seek emergency care if breathing worsens."
    },
    "Gastroenteritis": {
        "symptoms": {"nausea": 1, "vomiting": 1, "diarrhea": 1, "abdominal pain": 1,
                     "fever": 0.6, "loss of appetite": 0.7},
        "risk": "moderate",
        "specialist": "Gastroenterologist",
        "advice": "Maintain hydration with ORS. Avoid solid food briefly. Visit a doctor if symptoms persist > 48h."
    },
    "Migraine": {
        "symptoms": {"headache": 1, "dizziness": 0.7, "blurred vision": 0.7,
                     "nausea": 0.6, "vomiting": 0.4},
        "risk": "moderate",
        "specialist": "Neurologist",
        "advice": "Rest in a dark, quiet room. Track triggers. Consult a neurologist for recurrent episodes."
    },
    "Bronchitis": {
        "symptoms": {"cough": 1, "congestion": 1, "wheezing": 1, "fatigue": 0.7,
                     "chest pain": 0.4, "shortness of breath": 0.6},
        "risk": "moderate",
        "specialist": "Pulmonologist",
        "advice": "Avoid smoke, hydrate, and use prescribed inhalers. Antibiotics rarely needed unless bacterial."
    },
    "Hypertension": {
        "symptoms": {"headache": 0.6, "dizziness": 0.6, "high blood pressure": 1,
                     "blurred vision": 0.5, "chest pain": 0.4},
        "risk": "high",
        "specialist": "Cardiologist",
        "advice": "Monitor BP regularly, reduce salt intake, exercise, and follow up with a cardiologist."
    },
    "Pneumonia": {
        "symptoms": {"fever": 1, "cough": 1, "shortness of breath": 1, "chest pain": 1,
                     "chills": 1, "fatigue": 0.8},
        "risk": "critical",
        "specialist": "Pulmonologist",
        "advice": "Seek medical attention urgently. Chest X-ray and antibiotics may be required."
    },
    "Dermatitis": {
        "symptoms": {"rash": 1, "itching": 1, "skin redness": 1},
        "risk": "low",
        "specialist": "Dermatologist",
        "advice": "Identify and avoid triggers. Use moisturizers and prescribed topical steroids."
    },
    "Arthritis": {
        "symptoms": {"joint pain": 1, "body ache": 0.6, "fatigue": 0.5, "back pain": 0.4},
        "risk": "moderate",
        "specialist": "Rheumatologist",
        "advice": "Gentle exercise, anti-inflammatory medication, and rheumatology evaluation recommended."
    },
    "Diabetes (warning signs)": {
        "symptoms": {"frequent urination": 1, "fatigue": 0.8, "blurred vision": 0.7,
                     "weight loss": 0.7, "loss of appetite": 0.4},
        "risk": "high",
        "specialist": "Endocrinologist",
        "advice": "Check fasting blood sugar and HbA1c. Consult an endocrinologist for management."
    },
}

# Aliases for natural-language mapping
ALIASES = {
    "temperature": "fever", "high temp": "fever", "hot": "fever",
    "throat pain": "sore throat", "painful throat": "sore throat",
    "stuffy nose": "congestion", "blocked nose": "congestion",
    "tired": "fatigue", "exhausted": "fatigue", "weak": "fatigue",
    "muscle pain": "body ache", "muscle ache": "body ache",
    "sick": "nausea", "queasy": "nausea",
    "throwing up": "vomiting", "puking": "vomiting",
    "loose motion": "diarrhea", "loose stool": "diarrhea",
    "stomach pain": "abdominal pain", "belly pain": "abdominal pain",
    "breathlessness": "shortness of breath", "can't breathe": "shortness of breath",
    "dizzy": "dizziness", "lightheaded": "dizziness",
    "scratchy": "itching", "itches": "itching",
    "red skin": "skin redness",
    "bp high": "high blood pressure",
    "pee often": "frequent urination",
    "fuzzy vision": "blurred vision",
    "whistle breath": "wheezing",
}

# ----------------------------------------------------------
# NLP-light preprocessing
# ----------------------------------------------------------
STOPWORDS = {"i", "have", "having", "feel", "feeling", "am", "a", "an", "the",
             "and", "or", "of", "to", "with", "my", "is", "are", "really",
             "very", "slightly", "kind", "sort", "bit", "from", "since", "for"}

def preprocess_input(raw: str) -> List[str]:
    """Lowercase, tokenize, remove punctuation, apply aliases, drop stopwords."""
    raw = (raw or "").lower()
    raw = re.sub(r"[^a-z\s',-]", " ", raw)
    tokens = [t.strip("',-") for t in raw.split()]
    tokens = [t for t in tokens if t and t not in STOPWORDS]

    # Phrase-level alias substitution (bigrams + trigrams)
    phrase_map = {}
    for alias in ALIASES.keys():
        if " " in alias:
            phrase_map[alias] = ALIASES[alias]
    joined = " ".join(tokens)
    for phrase, canonical in phrase_map.items():
        joined = joined.replace(phrase, canonical)
    tokens = joined.split()

    # Word-level alias substitution
    canonical = []
    for t in tokens:
        canonical.append(ALIASES.get(t, t))
    # Deduplicate preserving order
    seen, result = set(), []
    for t in canonical:
        if t not in seen:
            seen.add(t)
            result.append(t)
    return result

# ----------------------------------------------------------
# Prediction
# ----------------------------------------------------------
def predict(symptom_text: str) -> Dict[str, Any]:
    """
    Returns a prediction payload:
    {
        processed_symptoms: [...],
        predictions: [{disease, confidence, ...}, ...],
        top: {disease, risk_level, specialist, recommendations, confidence},
        disclaimer: str
    }
    """
    tokens = preprocess_input(symptom_text)

    if not tokens:
        return {
            "processed_symptoms": [],
            "predictions": [],
            "top": None,
            "disclaimer": ("We couldn't identify recognized symptoms. "
                           "Please describe your symptoms in more detail or consult a physician."),
        }

    scored = []
    for disease, info in DISEASE_KB.items():
        overlap = [s for s in tokens if s in info["symptoms"]]
        if not overlap:
            continue
        # Weighted coverage score
        matched_weight = sum(info["symptoms"][s] for s in overlap)
        total_weight   = sum(info["symptoms"].values())
        coverage = matched_weight / total_weight
        # Confidence = coverage * token coverage factor
        token_factor = len(overlap) / max(len(tokens), 1)
        confidence = round((coverage * 0.7 + token_factor * 0.3) * 100, 2)
        if confidence < 15:
            continue
        scored.append({
            "disease": disease,
            "confidence": confidence,
            "matched_symptoms": overlap,
            "risk_level": info["risk"],
            "specialist": info["specialist"],
            "recommendations": info["advice"],
        })

    scored.sort(key=lambda x: x["confidence"], reverse=True)
    top = scored[0] if scored else None

    return {
        "processed_symptoms": tokens,
        "predictions": scored[:5],
        "top": top,
        "disclaimer": ("This is an AI-assisted preliminary assessment based on symptom patterns "
                       "and is not a medical diagnosis. Always consult a licensed healthcare professional."),
    }

# ----------------------------------------------------------
# Chatbot response generation
# ----------------------------------------------------------
CHAT_INTENTS = [
    {"keywords": ["headache"],      "reply": "Headaches can be caused by stress, dehydration, screen strain, or migraines. Try hydrating and resting. If persistent or severe, please book a consultation."},
    {"keywords": ["fever"],         "reply": "For fever, rest and drink fluids. Monitor your temperature. If it crosses 39°C or lasts > 3 days, consult a physician immediately."},
    {"keywords": ["cough"],         "reply": "A persistent cough may indicate cold, flu, bronchitis, or allergies. Use our symptom analyzer for a preliminary assessment, or book a pulmonologist visit if it lasts > 2 weeks."},
    {"keywords": ["appointment","book"], "reply": "You can book an appointment from the Appointments page. Choose a specialist based on your symptoms, pick a slot, and we'll confirm shortly."},
    {"keywords": ["diet","food"],   "reply": "A balanced diet with vegetables, lean protein, whole grains, and adequate water supports overall health. Avoid excess sugar and processed foods."},
    {"keywords": ["blood pressure","bp"], "reply": "Normal BP is around 120/80 mmHg. Regular monitoring is important. Please consult a cardiologist if you have persistently high readings."},
    {"keywords": ["diabetes","sugar"], "reply": "Warning signs of diabetes include frequent urination, fatigue, and blurred vision. An HbA1c test can confirm. Book an endocrinologist appointment."},
    {"keywords": ["hello","hi","hey"], "reply": "Hello! I'm MediBot, your healthcare assistant. Tell me your symptoms or ask about appointments, specialists, or general wellness."},
    {"keywords": ["thank"],         "reply": "You're welcome! Stay healthy and don't hesitate to reach out anytime."},
]

def chatbot_reply(message: str) -> str:
    msg = (message or "").lower()
    for intent in CHAT_INTENTS:
        if any(k in msg for k in intent["keywords"]):
            return intent["reply"]
    # Fallback: try prediction-driven guidance
    result = predict(msg)
    if result["top"]:
        top = result["top"]
        return (f"Based on what you described, this may relate to {top['disease']} "
                f"(risk: {top['risk_level']}). Recommended specialist: {top['specialist']}. "
                f"Advice: {top['recommendations']}")
    return ("I'm not sure I fully understood. Could you describe your symptoms in more detail? "
            "You can also use the Symptom Analyzer for a structured assessment.")