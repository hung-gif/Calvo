# File: app/modules/auth/router.py
# Purpose: Simple authentication entry for mobile app.
# Language: English

from fastapi import APIRouter
from pydantic import BaseModel
from app.core.security import create_access_token

router = APIRouter()

class LoginRequest(BaseModel):
    user_id: int  # Temporary: Replace with real auth later

@router.post("/login")
def login(req: LoginRequest):
    token = create_access_token(req.user_id)
    return {
        "success": True,
        "data": {
            "access_token": token,
            "token_type": "bearer"
        }
    }
