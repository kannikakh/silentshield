from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routes import router

app = FastAPI(title="SilentShield API", version="1.0")

# ✅ Allow Flutter to call API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # later restrict domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)
