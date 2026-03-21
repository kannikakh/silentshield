from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from twilio.rest import Client
from dotenv import load_dotenv
import os

from app.scam_detector import analyze_text  # ✅ import here

load_dotenv()

app = FastAPI()  # ✅ MUST come BEFORE routes

# ✅ CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

TWILIO_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE = os.getenv("TWILIO_PHONE")

# Only create Twilio client if credentials exist (for testing, this is optional)
try:
    if TWILIO_SID and TWILIO_AUTH:
        client = Client(TWILIO_SID, TWILIO_AUTH)
    else:
        client = None
        print("⚠️  Twilio credentials not found - SMS features disabled")
except Exception as e:
    client = None
    print(f"⚠️  Twilio error: {e}")

# ✅ MODELS
class SOSRequest(BaseModel):
    message: str
    numbers: list[str]

@app.post("/send-sos-sms")
def send_sos_sms(data: SOSRequest):
    if client is None:
        return {"status": "error", "message": "SMS service not configured", "sent": [], "failed": []}
    
    sent = []
    failed = []

    for number in data.numbers:
        try:
            msg = client.messages.create(
                body=data.message,
                from_=TWILIO_PHONE,
                to=number
            )
            sent.append({"to": number, "sid": msg.sid})
        except Exception as e:
            failed.append({"to": number, "error": str(e)})

    return {"status": "done", "sent": sent, "failed": failed}


# ✅ NEW ROUTE (PUT AFTER app = FastAPI())
@app.post("/analyze-call")
def analyze_call(data: TextInput):
    return analyze_text(data.text)