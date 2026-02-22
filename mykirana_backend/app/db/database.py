from sqlmodel import SQLModel, create_engine, Session
from app.db.models import User, OTP, Item  # <--- ADD THIS LINE
from dotenv import load_dotenv  # <--- NEW IMPORT
import os

# 0. Load the password FIRST
load_dotenv()  # <--- NEW LINE

# 1. Get the URL from .env
DATABASE_URL = os.getenv("DATABASE_URL")

# 2. Fix for Supabase
if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# 3. Create the Engine
# echo=True means "Print all SQL commands to the terminal" (Great for debugging)
if DATABASE_URL is None:
    raise ValueError("DATABASE_URL is not set. Please check your .env file.")

engine = create_engine(DATABASE_URL, echo=True)

# 4. Function to create tables (Run this when app starts)
def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

# 5. Dependency (We use this in every API endpoint to get a DB session)
def get_session():
    with Session(engine) as session:
        yield session