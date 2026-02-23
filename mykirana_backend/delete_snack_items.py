"""
Script to delete all items with empty IDs or in 'Snack' category from database
Run this once to clean up unwanted items
"""
from sqlmodel import Session, select, create_engine
from app.db.models import Item
from app.db.database import DATABASE_URL

# Create engine
engine = create_engine(DATABASE_URL, echo=True)

def delete_problematic_items():
    with Session(engine) as session:
        # Find all items in Snack category
        statement = select(Item).where(Item.category == 'Snack')
        snack_items = session.exec(statement).all()
        
        # Find all items with empty master_id
        statement2 = select(Item).where(Item.master_id == '')
        empty_id_items = session.exec(statement2).all()
        
        # Combine both lists
        all_problematic_items = list(snack_items) + list(empty_id_items)
        
        # Remove duplicates
        unique_items = {item.id: item for item in all_problematic_items}.values()
        
        print(f"\n📦 Found {len(unique_items)} problematic items:")
        for item in unique_items:
            print(f"  - DB ID: {item.id}, Master ID: '{item.master_id}', Category: {item.category}, Names: {item.names}")
        
        if unique_items:
            confirm = input("\n⚠️  Delete all these items? (yes/no): ")
            if confirm.lower() == 'yes':
                for item in unique_items:
                    session.delete(item)
                session.commit()
                print(f"✅ Deleted {len(unique_items)} problematic items")
            else:
                print("❌ Deletion cancelled")
        else:
            print("✅ No problematic items found")

if __name__ == "__main__":
    delete_problematic_items()
