from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from twilio.rest import Client
from dotenv import load_dotenv
from app.scam_detector import analyze_text

import os

# =========================
# LOAD ENV
# =========================

load_dotenv()

# =========================
# FASTAPI APP
# =========================

app = FastAPI()

# =========================
# CORS
# =========================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
# TWILIO CONFIG
# =========================

TWILIO_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE = os.getenv("TWILIO_PHONE")

try:

    if TWILIO_SID and TWILIO_AUTH:

        client = Client(TWILIO_SID, TWILIO_AUTH)

    else:

        client = None
        print("⚠️ Twilio credentials not found")

except Exception as e:

    client = None
    print(f"⚠️ Twilio Error: {e}")

# =========================
# REQUEST MODELS
# =========================

class SOSRequest(BaseModel):
    message: str
    numbers: list[str]


class TextInput(BaseModel):
    text: str

# =========================
# SOS SMS ROUTE
# =========================

@app.post("/send-sos-sms")
def send_sos_sms(data: SOSRequest):

    if client is None:

        return {
            "status": "error",
            "message": "SMS service not configured",
            "sent": [],
            "failed": []
        }

    sent = []
    failed = []

    for number in data.numbers:

        try:

            msg = client.messages.create(
                body=data.message,
                from_=TWILIO_PHONE,
                to=number
            )

            sent.append({
                "to": number,
                "sid": msg.sid
            })

        except Exception as e:

            failed.append({
                "to": number,
                "error": str(e)
            })

    return {
        "status": "done",
        "sent": sent,
        "failed": failed
    }

# =========================
# SCAM ANALYSIS ROUTE
# =========================

@app.post("/analyze-call")
def analyze_call(data: TextInput):

    result = analyze_text(data.text)

    return result

# =========================
# ROOT ROUTE
# =========================

@app.get("/")
def home():

    return {
        "message": "SilentShield Backend Running"
    }