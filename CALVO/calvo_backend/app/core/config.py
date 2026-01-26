# File: app/core/config.py
# Purpose: Centralized configuration management.

import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv
load_dotenv()


class Settings(BaseSettings):
    # App Info
    PROJECT_NAME: str = "Calvo AI Backend"
    VERSION: str = "4.0.0"
    
    # Database
    # We use SQLite for the Hackathon demo (easy to setup)
    DATABASE_URL: str = "sqlite:///./calvo.db"
    
    # API Keys (Loaded from .env)
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    OPIK_API_KEY: str = os.getenv("OPIK_API_KEY", "")
    OPIK_PROJECT_NAME: str = os.getenv("OPIK_PROJECT_NAME", "Calvo-Hackathon")

    class Config:
        case_sensitive = True

# Instantiate settings to be imported elsewhere
settings = Settings()