def analyze_text(text: str):
    text = text.lower()

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

    # 🔥 Check if any keyword present
    if any(word in text for word in high_risk_words):
        return {
            "transcript": text,
            "risk": 0.8,  # 🚨 HIGH RISK
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