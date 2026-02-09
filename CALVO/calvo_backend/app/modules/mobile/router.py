# File: app/modules/mobile/router.py
# Purpose: Mobile-friendly APIs for Flutter app.
# Language: English

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from opik import track

from app.core.database import get_db
from app.core.security import get_current_user
from app.modules.gatekeeper import models as gk_models
from app.modules.mobile.agent import generate_mobile_briefing
from app.modules.mobile.schemas import FrontendNotificationTrigger, MobileBriefingRequest

router = APIRouter()

@router.post("/briefing", response_model=MobileBriefingRequest)
@track(name="Mobile Fetch Briefing")
async def fetch_briefing(req: FrontendNotificationTrigger,
    db: Session = Depends(get_db)
):
    briefing = db.query(gk_models.DailyBriefing).filter(
        gk_models.DailyBriefing.user_id == req.user_id
    ).order_by(gk_models.DailyBriefing.created_at.desc()).first()

    report = generate_mobile_briefing(db, req.user_id)

    if not briefing:
        return {
            "report": report.get("report") if report else "No briefing available."
        }

    return {
        "report": briefing.content
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

