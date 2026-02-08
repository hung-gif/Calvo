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
    current_time = datetime.now()
    system_prompt = f"""
    Role: Expert Scheduler.
    Task: Extract event title, event start time, and event end time from the given text.
    Current Date: {current_time.strftime("%Y-%m-%d")}
    Current Time: {current_time.strftime("%H:%M:%S")}

    Guidelines for Relative Time Extraction:
        1. Reference Point: Use the "Current Time" provided above as the baseline for all relative expressions (e.g., "in 2 hours", "next hour").
        2. Contextual Parsing:
        - "x h tối": Interpret as X:00 of the current or next logical day.
        - "X tiếng nữa": Calculate by adding X hours to the "Current Time".
        - "Sáng/Chiều/Tối": If the user doesn't specify AM/PM, use context (e.g., "9h" in the morning vs "9h tối").
        3. Output Format: Strictly return a JSON object with keys: 
        {{
        "event_title": summary of the event",
        "start_time": "YYYY-MM-DD HH:mm",
        "end_time": "YYYY-MM-DD HH:mm"
        }}
    """
    
    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": content}
            ],
            response_format={"type": "json_object"},
            temperature=0.5
        )
        return json.loads(response.choices[0].message.content)
    except Exception as e:
        print(f"   [Strategist Agent] Error: {e}")
        return {"event_title": None, "start_time": None, "end_time": None}
