# File: app/modules/gatekeeper/schemas.py
# Purpose: Define Pydantic models (DTOs) for API validation.

from pydantic import BaseModel

class WebhookRequest(BaseModel):
    user_id: int
    source_app: str
    content: str
    language: str = "Vietnamese"

class GatekeeperResponse(BaseModel):
    status: str
    classification: str
    summary: str
    action_taken: str