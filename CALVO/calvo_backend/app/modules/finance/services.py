# File: app/modules/finance/services.py
# Purpose: Business logic for processing transactions safely.
# Language: English

from sqlalchemy.orm import Session
from app.modules.finance.models import Account, Transaction
from app.modules.finance import currency_service
from app.modules.finance.budget_manager import BudgetManager

def process_transaction(
    db: Session,
    user_id: int,
    amount: float,
    currency: str,
    transaction_type: str = "UNKNOWN",  
    institution_name: str = "General"   
):
    """
    Safely processes a financial transaction with full business logic.
    """

    print(f"[Finance Service] Processing {transaction_type} {amount} {currency}")

    # 1. Reject unsafe AI output or invalid types
    if transaction_type == "UNKNOWN" or amount is None:
        return {
            "status": "ignored",
            "message": "Transaction type unclear or amount missing. Logged for review."
        }

    # 2. Find account
    query = db.query(Account).filter(Account.user_id == user_id)
    
    if institution_name != "General":
        query = query.filter(Account.institution_name == institution_name)
    
    account = query.first()

    if not account:
        print(f"[Finance][ERROR] Account not found for user {user_id}")
        return {"status": "error", "message": "Account not found."}

    # 3. Normalize currency (QUAN TRỌNG: Giữ tính năng này)
    normalized_amount = amount
    if currency != account.currency:
        try:
            normalized_amount = currency_service.convert_currency(amount, currency, account.currency)
        except Exception as e:
            print(f"[Finance][WARN] Currency conversion failed: {e}. Using original amount.")
            normalized_amount = amount

    # 4. Budget alert check
    is_alert = False
    if transaction_type == "WITHDRAW":
        is_alert = BudgetManager.check_over_budget(normalized_amount, account.balance)

    # 5. Update balance
    if transaction_type == "DEPOSIT":
        account.balance += normalized_amount
    elif transaction_type == "WITHDRAW":
        account.balance -= normalized_amount

    # 6. Save transaction history
    new_trans = Transaction(
        user_id=user_id,
        account_id=account.id,
        amount=amount,
        currency=currency,
        type_of_transaction=transaction_type,
        is_over_budget_alert=is_alert
    )

    db.add(new_trans)
    db.commit()
    db.refresh(new_trans) 
    db.refresh(account)  

    # AI suggestion
    ai_suggestion = None
    if is_alert:
        ai_suggestion = "Consider limiting spending for the rest of the day."

    print(f"[Finance][SUCCESS] New Balance: {account.balance} {account.currency}")

    return {
        "status": "success",
        "new_balance": account.balance,
        "account_currency": account.currency,
        "transaction_id": new_trans.id,
        "alert_triggered": is_alert,
        "ai_suggestion": ai_suggestion
    }