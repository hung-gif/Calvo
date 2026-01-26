# File: app/modules/gatekeeper/agent.py
# Purpose: The Gatekeeper Agent.
# Responsibility: Classify intent ONLY. Does NOT extract money or time (to save tokens).

import json
from openai import OpenAI
from app.core.config import settings
from opik import track

client = OpenAI(api_key=settings.OPENAI_API_KEY)

@track(name="Gatekeeper Classification")
def classify_notification(content: str, source: str, lang: str):
    """
    Decides if the notification is FINANCE, SCHEDULE, IMPORTANT, or TRASH.
    """
    print(f"   [Gatekeeper] Classifying: {content[:30]}...") # BREAKPOINT

    system_prompt = f"""
    Role: Calvo Gatekeeper.
    Task: Classify notification intent.
    Output Language: {lang}.
    
    Categories:
    - FINANCE: Money deduction, income, banking alerts.
    - SCHEDULE: Meetings, appointments, flight tickets, deadlines.
    - TRASH: Ads, promotions, spam.
    - IMPORTANT: OTP, personal messages, work updates (that are not Schedule).
    
    Output JSON: {{ "category": "FINANCE" | "SCHEDULE" | "TRASH" | "IMPORTANT", "summary": "Short summary", "is_spam": bool }}
    """
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"App: {source}\nContent: {content}"}
            ],
            response_format={"type": "json_object"},
            temperature=0.3
        )
        return json.loads(response.choices[0].message.content)
    except Exception as e:
        print(f"   [Gatekeeper] Error: {e}")
        return {"category": "IMPORTANT", "summary": "Error analyzing", "is_spam": False}