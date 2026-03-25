def analyze_text(text: str):
    text = text.lower()

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