# File: app/modules/schedule/services.py
# Purpose: Save events to database.

from sqlalchemy.orm import Session
from app.modules.schedule.models import Schedule
from datetime import datetime, timedelta

def create_event(db: Session, user_id: int, title: str, start_time_str: str, source: str):
    """
    Creates a new calendar event.
    """
    print(f"   [Schedule Service] Creating event: {title} at {start_time_str}") # BREAKPOINT
    
    # Parse time string to Python datetime object
    try:
        start_time = datetime.strptime(start_time_str, "%Y-%m-%d %H:%M")
    except:
        # Fallback: If AI fails format, set for 1 hour later
        start_time = datetime.now() + timedelta(hours=1)
        print("   [Schedule Service] ⚠️ Time parsing failed. Using fallback +1h.")

    new_event = Schedule(
        user_id=user_id,
        title=title,
        start_time=start_time,
        source_app=source,
        is_auto_generated=True
    )
    db.add(new_event)
    db.commit()
    db.refresh(new_event)
    
    return new_event