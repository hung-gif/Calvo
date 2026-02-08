from datetime import date

from sqlalchemy import func
from app.modules.gatekeeper.agent import classify_notification
from app.modules.gatekeeper.models import NotificationLog, DailyBriefing
from app.modules.prompts_config import SYSTEM_PROMPT_REPORTER
from openai import OpenAI
from app.core.config import settings
import json

def generate_mobile_briefing(db, user_id):
    """
    USE AI AGENT TO GENERATE A BRIEFING FROM NOTIFICATION LOGS
    """


    client = OpenAI(api_key=settings.OPENAI_API_KEY)

    today = date.today()

    logs = db.query(NotificationLog).filter(
    # So sánh chỉ phần ngày của received_at với ngày hôm nay
    func.date(NotificationLog.received_at) == today,
    
        NotificationLog.user_id == user_id,
        NotificationLog.is_included_in_briefing == False,
        NotificationLog.category != "TRASH"
).order_by(NotificationLog.received_at.desc()).all()
    
    if not logs:
        return None


    system_prompt = SYSTEM_PROMPT_REPORTER
    user_content = logs
    print(f"{user_content} [Reporter] Generating briefing for {len(logs)} logs")
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": str(user_content)}
            ],
            temperature=0.2
        )
        # Get the briefing text from the response
        return json.loads(response.choices[0].message.content)

    except Exception as e:
        print(f"   [Reporter] Error generating briefing: {e}")
        return None
