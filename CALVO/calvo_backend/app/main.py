# File: app/main.py
# Purpose: FastAPI initialization.
# Language: English

from fastapi import FastAPI
from app.core.config import settings
from app.core.database import engine, Base

from app.modules.gatekeeper.router import router as gatekeeper_router
from app.modules.auth.router import router as auth_router
from app.modules.mobile.router import router as mobile_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Calvo AI Backend"
)

@app.on_event("startup")
def startup_event():
    Base.metadata.create_all(bind=engine)

@app.get("/")
def health_check():
    return {"status": "Calvo backend running"}

app.include_router(auth_router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(gatekeeper_router, prefix="/api/v1", tags=["Gatekeeper"])
app.include_router(mobile_router, prefix="/api/v1/mobile", tags=["Mobile"])
