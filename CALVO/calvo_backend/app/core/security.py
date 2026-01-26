# File: app/core/security.py
# Purpose: JWT Authentication AND Source Verification Logic.
# Language: English

from datetime import datetime, timedelta
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.modules.finance.models import Account

SECRET_KEY = "CHANGE_THIS_IN_PRODUCTION"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = 30

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/v1/auth/login")

def create_access_token(user_id: int):
    expire = datetime.utcnow() + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    to_encode = {"sub": str(user_id), "exp": expire}
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(token: str = Depends(oauth2_scheme)) -> int:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return int(payload.get("sub"))
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token"
        )

# --- NEW FUNCTION ADDED FOR GATEKEEPER ---
def verify_source_trust(db: Session, user_id: int, source_app: str) -> dict:
    """
    Checks if the source_app exists in the user's registered financial whitelist.
    """
    trusted_accounts = db.query(Account).filter(Account.user_id == user_id).all()
    whitelist = [acc.institution_name.lower() for acc in trusted_accounts]

    if source_app.lower() in whitelist:
        return {"is_trusted": True, "reason": "Verified Source"}
    
    return {
        "is_trusted": False, 
        "reason": f"UNTRUSTED SOURCE: '{source_app}' is not in your registered accounts."
    }