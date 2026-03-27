def analyze_text(text: str):
    text = text.lower().strip()

<<<<<<< HEAD
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
=======
    # ✅ correct indentation
    clean_text = text.replace(" ", "")

    scam_keywords = [
        "otp", "urgent", "bank", "account", "blocked",
        "transfer", "password", "verify", "click link",
        "loan", "prize", "winner", "upi", "refund"
    ]

    score = 0

    for word in scam_keywords:
        if word in clean_text:
            score += 1

    print("INPUT:", text)
    print("CLEAN:", clean_text)
    print("SCORE:", score)

    if score >= 2:
        return {"risk": 0.9, "label": "scam"}
    elif score == 1:
        return {"risk": 0.6, "label": "suspicious"}
    else:
        return {"risk": 0.1, "label": "safe"}
>>>>>>> 0962c39d993a101c159388a18ce3f8d16c3962f1
