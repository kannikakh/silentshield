import joblib

# Load trained model
model = joblib.load("scam_detector_model.pkl")


def analyze_text(text: str):

    prediction = model.predict([text])[0]

    probability = model.predict_proba([text])[0][1]

    if prediction == 1:

        return {
            "transcript": text,
            "label": "scam",
            "risk": round(float(probability), 2),
            "confidenceScore": round(float(probability * 100), 2)
        }

    else:

        return {
            "transcript": text,
            "label": "safe",
            "risk": round(float(probability), 2),
            "confidenceScore": round(float((1 - probability) * 100), 2)
        }


# =========================
# TESTING
# =========================

print(analyze_text(
    "Your bank account has been blocked. Share OTP immediately."
))

print(analyze_text(
    "Hello, your appointment is confirmed for tomorrow."
))
