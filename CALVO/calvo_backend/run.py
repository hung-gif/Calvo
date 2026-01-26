# File: run.py
# Purpose: Single entry point to start the Calvo Server.
# Note: This file initializes the Uvicorn server with hot-reload enabled.

import uvicorn
import os
from dotenv import load_dotenv

# Load environment variables first
load_dotenv()

if __name__ == "__main__":
    print("🚀 [SYSTEM START] Calvo AI Backend is booting up...")
    
    # BREAKPOINT: Check if API Keys exist to prevent runtime crashes
    if not os.getenv("OPENAI_API_KEY"):
        print("❌ [CRITICAL ERROR] OPENAI_API_KEY is missing in .env file.")
        exit(1)
        
    print("✅ [CHECKPOINT] Environment loaded. Starting Uvicorn Server...")
    
    # Start the server (Host 0.0.0.0 allows external connections via Ngrok)
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)