from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from openai import OpenAI

from app.core.database import get_db
from app.core.config import settings
from app.core import security

from app.modules.gatekeeper import schemas, agent as gatekeeper_agent, models as gk_models
from app.modules.finance import agent as cfo_agent, services as finance_services, models as cfo_models
from app.modules.schedule import agent as strategist_agent, services as schedule_services, models as sch_models

import traceback

from app.modules.gatekeeper.agent import get_real_app_name


router = APIRouter()
client = OpenAI(api_key=settings.OPENAI_API_KEY)

@router.post("/webhook", response_model=schemas.GatekeeperResponse)
async def receive_notification(req: schemas.WebhookRequest, db: Session = Depends(get_db)):
    """
    Receives notification, classifies it, validates security, and routes to sub-agents.
    """

    # Auto-clean logs older than 30 days
    cutoff_date = datetime.now() - timedelta(days=30)
    db.query(gk_models.NotificationLog).filter(
        gk_models.NotificationLog.received_at < cutoff_date
    ).delete()
    

    # 1. Classify notification
    gk_result = gatekeeper_agent.classify_notification(
         req.source_app, content=req.content, title=req.title, received_at=req.received_at
    )
    category = gk_result.get("classification")
    summary = gk_result.get("summary")
    priority = gk_result.get("priority")
    action_log = f"Classified as {category} with priority {priority}."
    source_app = get_real_app_name(req.source_app)

    is_risk = gk_result.get("is_spam")

    # # 2. Security Check (Only for Finance)
    # if category == "FINANCE":
    #     trust_check = security.verify_source_trust(db, req.user_id, req.source_app)
    #     if not trust_check["is_trusted"]:
    #         category = "RISK"
    #         is_risk = True
    #         priority = 5
    #         summary = f"[SECURITY ALERT] {trust_check['reason']}"
    #         action_log += f" -> BLOCKED by Security: {trust_check['reason']}"

    # 3. Save Log
    log = gk_models.NotificationLog(
        id=None,
        user_id=req.user_id,
        received_at=req.received_at,
        source_app=source_app,
        raw_content=req.content,
        is_included_in_briefing=False,
        summary=summary,
        category=category,
        priority=priority,
        is_risk=is_risk
    )
    db.add(log)

    # 4. Route to agents if safe
    if not is_risk:
        if category == "FINANCE":
            finance_data = cfo_agent.extract_financial_data(received_at=req.received_at,
                                                            summary=summary, 
                                                            user_lang="Vietnamese", 
                                                            user_id=req.user_id
                                                            )
            if finance_data.get("amount") is not None:
                # --- FIXED: USING KEYWORD ARGUMENTS TO PREVENT MISMATCH ---
                finance_result = finance_services.process_transaction(
                    db=db,
                    user_id=req.user_id,
                    amount=finance_data["amount"],
                    currency=finance_data["currency"],
                    transaction_type=finance_data["type_of_transaction"],
                    institution_name=source_app,
                    received_at=req.received_at
                )

                action_log += f" Finance result: {finance_result.get('status')}."
            else:
                 action_log += " CFO could not extract amount."

        elif category == "SCHEDULE":
            schedule_data = strategist_agent.extract_schedule_data(req.content)
            if schedule_data.get("event_title") and schedule_data.get("start_time"):
                schedule_result = schedule_services.create_event(
                    db=db,
                    user_id=req.user_id,
                    title=schedule_data.get("event_title"),
                    start_time_str=schedule_data.get("start_time"),
                    end_time_str=schedule_data.get("end_time"),
                    source=source_app
                )
                action_log += " Schedule event created."

    db.commit()
    
    return {
        "source_app": source_app,
        "is_spam": is_risk,
        "priority": priority,
        "content": req.content,
        "received_at": req.received_at,
        "classification": category,
        "finance_data": finance_result if category == "FINANCE" else None,
        "schedule_data": schedule_result if category == "SCHEDULE" else None
    }

