<<<<<<< HEAD
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

=======
import os
import sys
from typing import Optional


_INFER = None


def _load_inference_runner():
    global _INFER
    if _INFER is not None:
        return _INFER
    # try to add training folder to path
    base = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    training_dir = os.path.join(base, 'training')
    if training_dir not in sys.path:
        sys.path.append(training_dir)
    try:
        from inference import InferenceRunner
        text_model = os.path.join(training_dir, 'bert_classifier.pt')
        audio_model = os.path.join(training_dir, 'audio_cnn.pt')
        
        _INFER = InferenceRunner(text_model_path=text_model if os.path.exists(text_model) else None,
                                 audio_model_path=audio_model if os.path.exists(audio_model) else None)
    except Exception:
        _INFER = None
    return _INFER


def analyze_text(text: str):
    # prefer model inference when available
    runner = _load_inference_runner()
    if runner and getattr(runner, 'text_model', None):
        probs = runner.predict_text(text)
        if probs is not None:
            # assume index 1 == scam
            scam_prob = float(probs[1])

            # If model predicts a low probability but the text contains
            # clearly sensitive keywords, boost the risk to ensure
            # sensitive requests (OTP, account details, etc.) are flagged.
            text_l = text.lower()
            high_risk_words = [
                "otp",
                "bank account",
                "account details",
                "password",
                "cvv",
                "pin",
                "urgent",
                "click the link"
            ]
            patterns = []
            if any(word in text_l for word in high_risk_words):
                patterns.append("Sensitive information request")
                # raise to a high risk if model is underconfident
                if scam_prob < 0.5:
                    scam_prob = max(scam_prob, 0.8)

            return {
                'transcript': text,
                'risk': scam_prob,
                'scamPatterns': patterns,
                'confidenceScore': int(scam_prob * 100)
            }

    # fallback rule-based checks
    text_l = text.lower()
    high_risk_words = [
        "otp",
        "bank account",
        "account details",
        "password",
        "cvv",
        "pin",
        "urgent",
        "click the link"
    ]
    if any(word in text_l for word in high_risk_words):
        return {
            "transcript": text,
            "risk": 0.8,
            "scamPatterns": ["Sensitive information request"],
            "confidenceScore": 95
        }

>>>>>>> 8c047fc (updated backend)
    return {
        "transcript": original_text,
        "label": label,
        "risk": round(float(scam_prob), 2),
        "scamPatterns": patterns,
        "confidenceScore": round(float(max(probabilities) * 100), 2)
    }