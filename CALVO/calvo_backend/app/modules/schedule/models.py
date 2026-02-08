# File: app/modules/schedule/models.py
# Purpose: Define schema for Calendar Events.

from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Schedule(Base):
    """
    Stores events extracted from notifications.
    """
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    
    title = Column(String)
    start_time = Column(DateTime)
    end_time = Column(DateTime, nullable=True)
    # Flag to differentiate AI-created events vs Manual ones
    is_auto_generated = Column(Boolean, default=True)
    
    # Future feature: Link to original notification source
    source_app = Column(String, nullable=True)
