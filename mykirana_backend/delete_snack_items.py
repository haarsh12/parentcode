"""
Script to delete all items in 'Snack' category from database
Run this once to clean up unwanted items
"""
from sqlmodel import Session, select, create_engine
from app.db.models import Item
from app.db.database import DATABASE_URL

# Create engine
engine = create_engine(DATABASE_URL, echo=True)

def delete_snack_items():
    with Session(engine) as session:
        # Find all items in Snack category
        statement = select(Item).where(Item.category == 'Snack')
        snack_items = session.exec(statement).all()
        
        print(f"\n📦 Found {len(snack_items)} items in 'Snack' category:")
        for item in snack_items:
            print(f"  - ID: {item.id}, Master ID: {item.master_id}, Names: {item.names}")
        
        if snack_items:
            confirm = input("\n⚠️  Delete all these items? (yes/no): ")
            if confirm.lower() == 'yes':
                for item in snack_items:
                    session.delete(item)
                session.commit()
                print(f"✅ Deleted {len(snack_items)} items from 'Snack' category")
            else:
                print("❌ Deletion cancelled")
        else:
            print("✅ No items found in 'Snack' category")

if __name__ == "__main__":
    delete_snack_items()
