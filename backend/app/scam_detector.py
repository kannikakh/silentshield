import joblib
import re

model = joblib.load("scam_detector_model.pkl")


def analyze_text(text: str):

    original_text = text

    text = text.lower().strip()

    safe_words = [
        "hi",
        "hello",
        "hey",
        "hello how are you",
        "how are you",
        "good morning",
        "good evening"
    ]

    if text in safe_words:

        return {
            "transcript": original_text,
            "label": "safe",
            "risk": 0.01,
            "scamPatterns": [],
            "confidenceScore": 99
        }

    text = re.sub(r"[^a-zA-Z0-9\s]", "", text)

    prediction = model.predict([text])[0]

    probabilities = model.predict_proba([text])[0]

    scam_prob = probabilities[1]

    if scam_prob >= 0.75:

        label = "scam"

        patterns = [
            "Fraudulent or suspicious content detected"
        ]

    elif scam_prob >= 0.45:

        label = "suspicious"

        patterns = [
            "Potential scam indicators found"
        ]

    else:

        label = "safe"

        patterns = []

    return {
        "transcript": original_text,
        "label": label,
        "risk": round(float(scam_prob), 2),
        "scamPatterns": patterns,
        "confidenceScore": round(float(max(probabilities) * 100), 2)
    }