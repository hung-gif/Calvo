# File: app/modules/schedule/agent.py
# Purpose: The Strategist Agent.
# Responsibility: Extract event title and standard datetime format.

import json
from openai import OpenAI
from app.core.config import settings
from opik import track
from datetime import datetime

client = OpenAI(api_key=settings.OPENAI_API_KEY)

@track(name="Strategist Agent Extraction")
def extract_schedule_data(content: str):
    """
    Parses text to find event details.
    """
    print(f"   [Strategist Agent] Analyzing time: {content[:50]}...") # BREAKPOINT
    
    current_time = datetime.now().strftime("%Y-%m-%d %H:%M")
    
    system_prompt = f"""
    Role: Expert Scheduler.
    Task: Extract event title and start time.
    Context: Current time is {current_time}.
    
    Rules:
    1. Extract 'event_title' (Keep it short).
    2. Extract 'start_time' in strict format: 'YYYY-MM-DD HH:MM'.
    3. If year is missing, assume current year or next year logic.
    4. Output JSON: {{ "event_title": string, "start_time": string }}
    """
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": content}
            ],
            response_format={"type": "json_object"},
            temperature=0.1
        )
        return json.loads(response.choices[0].message.content)
    except Exception as e:
        print(f"   [Strategist Agent] Error: {e}")
        return {"event_title": None, "start_time": None}