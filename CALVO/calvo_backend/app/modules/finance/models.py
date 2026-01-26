# File: app/modules/finance/models.py
# Purpose: Define database schemas for Financial operations.
# Language: English

from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
from datetime import datetime

class Account(Base):
    """
    Represents a user's financial account (Whitelist).
    """
    __tablename__ = "accounts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    institution_name = Column(String, index=True)
    
    # Current balance of the account
    balance = Column(Float, default=0.0)
    
    # Default currency for this account (e.g., VND for MBBank)
    currency = Column(String, default="VND") 
    
    transactions = relationship("Transaction", back_populates="account")

class Transaction(Base):
    """
    Records money flow based on the new Schema requirements.
    """
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, index=True)
    account_id = Column(Integer, ForeignKey("accounts.id"))
    
    # Amount is always absolute (positive float). Flow is determined by type.
    amount = Column(Float)
    currency = Column(String, default="VND")
    
    # Explicit type: DEPOSIT (In) or WITHDRAW (Out)
    type_of_transaction = Column(String) 
    
    # Alert Flag: Triggered if amount > threshold or % of balance
    is_over_budget_alert = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.now)
    
    account = relationship("Account", back_populates="transactions")