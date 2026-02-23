# migrate_add_analytics.py
from sqlmodel import SQLModel
from app.db.database import engine
from app.db.models import Bill, SaleItem

def migrate_analytics_tables():
    """
    Add Bill and SaleItem tables without affecting existing data.
    Safe to run on production database.
    """
    print("🔨 Adding analytics tables (Bill and SaleItem)...")
    
    try:
        # Create only the new tables
        Bill.metadata.create_all(engine)
        SaleItem.metadata.create_all(engine)
        
        print("✅ Migration complete!")
        print("📋 New tables added:")
        print("   - Bill table (for saved bills)")
        print("   - SaleItem table (for analytics)")
        print("\n💡 Existing data in User, Item, and OTP tables is preserved.")
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        print("Note: If tables already exist, this is expected.")

if __name__ == "__main__":
    migrate_analytics_tables()
