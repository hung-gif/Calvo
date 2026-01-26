# File: app/modules/gatekeeper/models.py
from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class NotificationLog(Base):
    __tablename__ = "notification_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)                     # NOTE
    source_app = Column(String)
    raw_content = Column(Text)
    summary = Column(String)
    category = Column(String) # FINANCE, SCHEDULE, IMPORTANT, TRASH
    received_at = Column(DateTime, default=datetime.now)
    is_included_in_briefing = Column(Boolean, default=False)

class DailyBriefing(Base):
    __tablename__ = "daily_briefings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    type = Column(String) # MORNING / EVENING
    content = Column(Text)
    created_at = Column(DateTime, default=datetime.now)