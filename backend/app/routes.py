from fastapi import APIRouter, HTTPException
from firebase_admin import firestore
from app.firebase_config import db
from app.models import (
    UserSaveRequest,
    ContactAddRequest,
    SOSCreateRequest,
    LocationAddRequest,
    SOSStatusUpdateRequest,
    LoginHistoryAddRequest,
)

router = APIRouter()


# ✅ Health Check
@router.get("/health")
def health():
    return {"status": "ok", "message": "SilentShield API running"}


# ✅ USERS
@router.post("/users/save")
def save_user(payload: UserSaveRequest):
    try:
        db.collection("users").document(payload.uid).set(
            {
                "uid": payload.uid,
                "name": payload.name,
                "email": payload.email,
                "phone": payload.phone,
                "createdAt": firestore.SERVER_TIMESTAMP,
            },
            merge=True,
        )
        return {"success": True, "message": "User saved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/users/{uid}")
def get_user(uid: str):
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    return doc.to_dict()


# ✅ CONTACTS
@router.post("/contacts/add")
def add_contact(payload: ContactAddRequest):
    try:
        db.collection("contacts").add(
            {
                "uid": payload.uid,
                "name": payload.name,
                "phone": payload.phone,
                "relation": payload.relation,
                "priority": payload.priority,
                "createdAt": firestore.SERVER_TIMESTAMP,
            }
        )
        return {"success": True, "message": "Contact added"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/contacts/{uid}")
def get_contacts(uid: str):
    try:
        contacts_ref = (
            db.collection("contacts")
            .where("uid", "==", uid)
            .order_by("priority")
            .stream()
        )

        contacts = []
        for c in contacts_ref:
            d = c.to_dict()
            d["contactId"] = c.id
            contacts.append(d)

        return {"success": True, "contacts": contacts}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/contacts/{contactId}")
def delete_contact(contactId: str):
    try:
        db.collection("contacts").document(contactId).delete()
        return {"success": True, "message": "Contact deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ✅ SOS EVENTS
@router.post("/sos/create")
def create_sos(payload: SOSCreateRequest):
    try:
        doc_ref = db.collection("sos_events").document()

        sos_data = {
            "uid": payload.uid,
            "triggerType": payload.triggerType,
            "message": payload.message,
            "status": "CREATED",
            "createdAt": firestore.SERVER_TIMESTAMP,
        }

        doc_ref.set(sos_data)

        return {"success": True, "sosId": doc_ref.id, "status": "CREATED"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.patch("/sos/{sosId}/status")
def update_sos_status(sosId: str, payload: SOSStatusUpdateRequest):
    try:
        db.collection("sos_events").document(sosId).update(
            {
                "status": payload.status,
                "updatedAt": firestore.SERVER_TIMESTAMP,
            }
        )
        return {"success": True, "message": "SOS status updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ✅ LOCATIONS
@router.post("/locations/add")
def add_location(payload: LocationAddRequest):
    try:
        map_link = f"https://maps.google.com/?q={payload.lat},{payload.lng}"

        db.collection("locations").add(
            {
                "uid": payload.uid,
                "sosId": payload.sosId,
                "lat": payload.lat,
                "lng": payload.lng,
                "mapLink": map_link,
                "timestamp": firestore.SERVER_TIMESTAMP,
            }
        )

        return {"success": True, "mapLink": map_link}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/locations/{sosId}")
def get_locations(sosId: str):
    try:
        loc_ref = (
            db.collection("locations")
            .where("sosId", "==", sosId)
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .stream()
        )

        locations = []
        for l in loc_ref:
            d = l.to_dict()
            d["locationId"] = l.id
            locations.append(d)

        return {"success": True, "locations": locations}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ✅ LOGIN HISTORY
@router.post("/login-history/add")
def add_login_history(payload: LoginHistoryAddRequest):
    try:
        db.collection("login_history").add(
            {
                "uid": payload.uid,
                "email": payload.email,
                "event": payload.event,
                "timestamp": firestore.SERVER_TIMESTAMP,
            }
        )
        return {"success": True, "message": "Login history saved"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/login-history/{uid}")
def get_login_history(uid: str):
    try:
        logs_ref = (
            db.collection("login_history")
            .where("uid", "==", uid)
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .stream()
        )

        logs = []
        for log in logs_ref:
            d = log.to_dict()
            d["logId"] = log.id
            logs.append(d)

        return {"success": True, "logs": logs}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
