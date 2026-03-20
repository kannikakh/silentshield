def analyze_text(text: str):
    text = text.lower()

    scam_keywords = [
        "otp", "urgent", "bank", "account", "blocked",
        "transfer", "password", "verify", "click link",
        "loan", "prize", "winner", "upi", "refund"
    ]

    score = 0

    for word in scam_keywords:
        if word in text:
            score += 1

    # 🔥 NEW LOGIC
    if score >= 3:
        risk = 0.9
        label = "scam"
    elif score == 2:
        risk = 0.6
        label = "scam"
    elif score == 1:
        risk = 0.3
        label = "suspicious"
    else:
        risk = 0.1
        label = "safe"

    return {
        "risk": risk,
        "label": label
    }