# File: app/modules/mobile/router.py
# Purpose: Mobile-friendly APIs for Flutter app.
# Language: English

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from opik import track

from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.gatekeeper import models as gk_models

router = APIRouter()

@router.get("/briefing")
@track(name="Mobile Fetch Briefing")
def fetch_briefing(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user)
):
    logs = db.query(gk_models.NotificationLog).filter(
        gk_models.NotificationLog.user_id == user_id,
        gk_models.NotificationLog.is_included_in_briefing == False,
        gk_models.NotificationLog.category != "TRASH"
    ).order_by(gk_models.NotificationLog.received_at.desc()).all()

    if not logs:
        return {"success": True, "data": {"briefing": "No new updates."}}

    briefing = "\n".join([f"- {log.summary}" for log in logs])

    for log in logs:
        log.is_included_in_briefing = True

    db.commit()

    return {
        "success": True,
        "data": {
            "briefing": briefing,
            "items": len(logs)
        }
    }


@router.get("/alerts")
@track(name="Mobile Fetch Alerts")
def fetch_alerts(
    db: Session = Depends(get_db),
    user_id: int = Depends(get_current_user)
):
    alerts = db.query(gk_models.NotificationLog).filter(
        gk_models.NotificationLog.user_id == user_id,
        gk_models.NotificationLog.category.in_(["RISK", "FINANCE"]),
        gk_models.NotificationLog.received_at.isnot(None)
    ).order_by(gk_models.NotificationLog.received_at.desc()).limit(10).all()

    return {
        "success": True,
        "data": [
            {
                "source": a.source_app,
                "summary": a.summary,
                "category": a.category
            } for a in alerts
        ]
    }
