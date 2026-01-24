from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from twilio.rest import Client
from dotenv import load_dotenv
import os

load_dotenv()

app = FastAPI()

# ✅ ADD THIS CORS BLOCK
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # allow all (for testing)
    allow_credentials=True,
    allow_methods=["*"],  # allow POST, OPTIONS, etc.
    allow_headers=["*"],
)

TWILIO_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE = os.getenv("TWILIO_PHONE")

client = Client(TWILIO_SID, TWILIO_AUTH)

class SOSRequest(BaseModel):
    message: str
    numbers: list[str]

@app.post("/send-sos-sms")
def send_sos_sms(data: SOSRequest):
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
