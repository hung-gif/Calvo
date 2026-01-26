# File: app/modules/finance/currency_service.py
# Purpose: Handle currency conversion logic using real-time API.
# Language: English

import requests
import os
from app.core.config import settings

# External API Provider (ExchangeRate-API or Open Exchange Rates)
API_KEY = os.getenv("EXCHANGE_RATE_API_KEY", "")
BASE_URL = f"https://api.exchangerate-api.com/v4/latest"

def get_exchange_rate(from_currency: str, to_currency: str = "VND") -> float:
    """
    Fetches the exchange rate. 
    Priority:
    1. API with Key (Production).
    2. Fallback hardcoded values (if Network/API fails).
    """
    from_curr = from_currency.upper()
    to_curr = to_currency.upper()

    # 1. Optimization: Same currency needs no conversion
    if from_curr == to_curr:
        return 1.0

    # 2. Try fetching from Live API
    try:
        # Construct URL (Using standard endpoint format)
        url = f"{BASE_URL}/{from_curr}"
        
        response = requests.get(url, timeout=5)
        data = response.json()
        
        if response.status_code == 200 and "rates" in data:
            rate = data["rates"].get(to_curr)
            if rate:
                return float(rate)
    except Exception as e:
        print(f"   [Currency Service] API Connection Error: {e}. Switching to Fallback.")

    # 3. Fallback Static Rates (Safety net)
    # Base reference: 1 Unit -> VND
    fallback_rates_to_vnd = {
        "USD": 25400.0,
        "EUR": 27500.0,
        "JPY": 170.0,
        "KRW": 18.5,
        "VND": 1.0
    }
    
    rate_to_vnd = fallback_rates_to_vnd.get(from_curr, 1.0)
    rate_from_vnd = 1.0 / fallback_rates_to_vnd.get(to_curr, 1.0)
    
    # Calculate cross rate
    return rate_to_vnd * rate_from_vnd

def convert_currency(amount: float, from_curr: str, to_curr: str) -> float:
    """
    Utility function to convert amount.
    """
    rate = get_exchange_rate(from_curr, to_curr)
    return amount * rate