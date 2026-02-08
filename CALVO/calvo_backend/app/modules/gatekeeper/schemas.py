# File: app/modules/gatekeeper/schemas.py
# Purpose: Define Pydantic models (DTOs) for API validation.

from datetime import datetime
from pydantic import BaseModel

class WebhookRequest(BaseModel):
    user_id: int
    source_app: str
    content: str
    title: str
    language: str = "Vietnamese"
    received_at: datetime

class GatekeeperResponse(BaseModel):
    classification: str
    source_app: str
    is_spam: bool
    priority: int
    content: str
    received_at: datetime
    finance_data: dict | None = None
    schedule_data: dict | None = None
