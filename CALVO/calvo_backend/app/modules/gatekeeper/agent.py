# File: app/modules/gatekeeper/agent.py
# Purpose: The Gatekeeper Agent.
# Responsibility: Classify intent ONLY. Does NOT extract money or time (to save tokens).

import json
from openai import OpenAI
from app.core.config import settings
from opik import track
from app.modules.prompts_config import SYSTEM_PROMPT_GATE_KEEPER
from google_play_scraper import app

client = OpenAI(api_key=settings.OPENAI_API_KEY)

@track(name="Gatekeeper Classification")
def classify_notification(app_name: str, content: str, title: str, received_at):
    """
    Decides if the notification is FINANCE, SCHEDULE or OTHER.
    """
    print(f"   [Gatekeeper] Classifying: {content[:30]}...") # BREAKPOINT

    system_prompt = SYSTEM_PROMPT_GATE_KEEPER
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"App: {app_name}, Content: {content}, Title: {title}"}
            ],
            response_format={"type": "json_object"},
            temperature=0.3
        )
        return json.loads(response.choices[0].message.content)
    
    except Exception as e:
        print(f"   [Gatekeeper] Error: {e}")
        return {
                "source_app": app_name,
                "is_spam": False,
                "classification": "OTHER",
                "received_at": received_at,
                "priority": 3,
            }
    
# Helper to get real app name from package name
def get_real_app_name(package_name):
    try:
        result = app(package_name, lang='vi', country='vn')
        return result['title']
    except Exception:
        # Nếu không tìm thấy, trả về phần cuối của package name làm dự phòng
        return package_name.split('.')[-1].capitalize()
