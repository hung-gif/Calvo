# File: app/modules/finance/agent.py
# Purpose: CFO Agent (Fail-safe version).
# Responsibility: Extract financial data safely using AI.
# Language: English

import json
from openai import OpenAI
from app.core.config import settings
from opik import track
from app.modules.prompts_config import SYSTEM_PROMPT_CFO

user_id = 0  # Placeholder, to be set when calling the function

client = OpenAI(api_key=settings.OPENAI_API_KEY)

@track(name="CFO Agent Extraction")
#sửa hàm đầu vào
def extract_financial_data(received_at, summary, user_lang: str = "Vietnamese", user_id: int = 0):
    """
    Extracts amount, currency, and transaction type.
    Fail-safe design: If AI output is invalid, returns UNKNOWN safely.
    """
    default_currency = "VND" if user_lang == "Vietnamese" else "EUR"
    # sửa prompt
    system_prompt = SYSTEM_PROMPT_CFO

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"summary: {summary}\n received_at: {received_at}"}
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
    # sửa output khi lỗi
    except Exception as e:
        print(f"[CFO Agent] Fail-safe triggered: {e}")
        return {
                "amount": 0.0,
                "currency": "VND",
                "created_at": received_at,
                "type_of_transaction": "UNKNOWN",
            }
