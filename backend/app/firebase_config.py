import firebase_admin
from firebase_admin import credentials, firestore

FIREBASE_KEY_PATH = "D:/Web Page/Portfolio/silentshield/backend/serviceAccountKey.json"

cred = credentials.Certificate(FIREBASE_KEY_PATH)

# Prevent multiple initializations
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()
