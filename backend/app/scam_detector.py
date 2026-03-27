def analyze_text(text: str):
    text = text.lower().strip()

    # 🟢 SAFE WORDS (force 0)
    safe_words = ["hello", "hi", "hey"]

    if text in safe_words:
        return {
            "transcript": text,
            "risk": 0.0,
            "scamPatterns": [],
            "confidenceScore": 100
        }

    # 🔴 HIGH RISK KEYWORDS
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

    # 🔥 Check keyword match
    if any(word in text for word in high_risk_words):
        return {
            "transcript": text,
            "risk": 0.8,
            "scamPatterns": ["Sensitive information request"],
            "confidenceScore": 95
        }

    # 🟢 DEFAULT SAFE
    return {
        "transcript": text,
        "risk": 0.0,
        "scamPatterns": [],
        "confidenceScore": 100
    }