# File: app/modules/finance/services.py
# Purpose: Business logic for processing transactions safely.
# Language: English

from datetime import datetime
from fastapi import Depends
from app.core.database import get_db
from sqlalchemy.orm import Session
from app.modules.finance.models import Account, Transaction
from app.modules.finance import currency_service
from app.modules.finance.budget_manager import BudgetManager



def process_transaction(db: Session = Depends(get_db), 
                        user_id: int = None, 
                        institution_name: str = "General", 
                        amount: float = 0.0, 
                        currency: str = "VND", 
                        transaction_type: str = "UNKNOWN",
                        received_at=None
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
        account = Account(
            user_id=user_id,
            institution_name=institution_name,
            balance=0.0,
            currency=currency 
        )
        db.add(account)
        db.commit()
        db.refresh(account)

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

    # Auto-generate transaction id
    last_transaction = db.query(Transaction).filter(Transaction.user_id == user_id).order_by(Transaction.id.desc()).first()
    new_transaction_id = 1 if not last_transaction else last_transaction.id + 1

    # 6. Save transaction history
    new_trans = Transaction(
        id = new_transaction_id,
        user_id=user_id,
        account_id=account.id,
        amount=amount,
        currency=currency,
        type_of_transaction=transaction_type,
        created_at=datetime.now(),
        account=account
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
        "new_balance": account.balance,
        "amount": amount,
        "created_at": received_at,
        "currency": currency,
        "type_of_transaction": transaction_type,
    }
