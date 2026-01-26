# File: app/modules/finance/agent.py
# Purpose: CFO Agent (Fail-safe version).
# Responsibility: Extract financial data safely using AI.
# Language: English

import json
from openai import OpenAI
from app.core.config import settings
from opik import track

client = OpenAI(api_key=settings.OPENAI_API_KEY)

@track(name="CFO Agent Extraction")
def extract_financial_data(content: str, user_lang: str = "Vietnamese"):
    """
    Extracts amount, currency, and transaction type.
    Fail-safe design: If AI output is invalid, returns UNKNOWN safely.
    """
    default_currency = "VND" if user_lang == "Vietnamese" else "EUR"

    system_prompt = f"""
    Role: Financial Parser.
    Task: Extract transaction details from the notification.

    Rules:
    1. 'amount': Float (absolute value).
    2. 'type_of_transaction': "DEPOSIT", "WITHDRAW", or "UNKNOWN".
    3. 'currency': Symbol or code. Default to '{default_currency}' if unclear.

    Output JSON:
    {{
        "amount": float or null,
        "currency": "string",
        "type_of_transaction": "DEPOSIT" | "WITHDRAW" | "UNKNOWN"
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
            temperature=0.1
        )

        data = json.loads(response.choices[0].message.content)

        # Basic validation
        if not isinstance(data.get("amount"), (int, float)):
            return {"amount": None, "currency": default_currency, "type_of_transaction": "UNKNOWN"}

        if data.get("type_of_transaction") not in ["DEPOSIT", "WITHDRAW"]:
            data["type_of_transaction"] = "UNKNOWN"

        return data

    except Exception as e:
        print(f"[CFO Agent] Fail-safe triggered: {e}")
        return {"amount": None, "currency": default_currency, "type_of_transaction": "UNKNOWN"}
