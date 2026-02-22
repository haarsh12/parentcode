# reset_database.py
from sqlmodel import SQLModel
from app.db.database import engine
from app.db.models import User, Item, OTP  # Import all models

def reset_database():
    """
    WARNING: This will DELETE ALL DATA in your database!
    Use only in development.
    """
    print("⚠️  WARNING: This will delete all existing data!")
    confirm = input("Type 'YES' to continue: ")
    
    if confirm != "YES":
        print("❌ Operation cancelled.")
        return
    
    print("🗑️  Dropping all tables...")
    SQLModel.metadata.drop_all(engine)
    
    print("🔨 Creating new tables with updated schema...")
    SQLModel.metadata.create_all(engine)
    
    print("✅ Database reset complete!")
    print("📋 New schema applied:")
    print("   - User table")
    print("   - Item table (with master_id and names fields)")
    print("   - OTP table")

if __name__ == "__main__":
    reset_database()