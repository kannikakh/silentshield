from pydantic import BaseModel
from typing import Optional


class UserSaveRequest(BaseModel):
    uid: str
    name: str
    email: str
    phone: str


class ContactAddRequest(BaseModel):
    uid: str
    name: str
    phone: str
    relation: str
    priority: int = 1


class SOSCreateRequest(BaseModel):
    uid: str
    triggerType: str  # button / voice
    message: str


class LocationAddRequest(BaseModel):
    uid: str
    sosId: str
    lat: float
    lng: float


class SOSStatusUpdateRequest(BaseModel):
    status: str  # CREATED / SENT / FAILED


class LoginHistoryAddRequest(BaseModel):
    uid: str
    email: str
    event: str  # LOGIN / LOGOUT / FAILED_LOGIN
