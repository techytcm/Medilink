# api/index.py
import sys
import os

# Add the project root to the sys.path so Vercel can find your `app.py` and `backend` folder
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Import the Flask app instance from your app.py
from app import app

# Vercel requires the variable to be named `app