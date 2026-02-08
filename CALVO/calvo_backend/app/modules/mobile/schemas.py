from datetime import datetime
from pydantic import BaseModel

class MobileBriefingRequest(BaseModel):
    report: str

class FrontendNotificationTrigger(BaseModel):
    user_id: int
