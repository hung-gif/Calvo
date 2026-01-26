# File: app/core/database.py
# Purpose: Database connection session handling.

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.core.config import settings

# 1. Create Engine
# connect_args={"check_same_thread": False} is required for SQLite
engine = create_engine(
    settings.DATABASE_URL, 
    connect_args={"check_same_thread": False}
)

# 2. Create Session Factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 3. Base Class for Models
Base = declarative_base()

# Dependency to get DB session in API endpoints
def get_db():
    db = SessionLocal()
    try:
        # BREAKPOINT: Log database access if needed for debugging
        yield db
    finally:
        db.close()