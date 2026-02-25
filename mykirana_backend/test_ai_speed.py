"""
Quick test script to verify AI response speed
Run this to check if optimizations are working
"""
import time
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import after loading env
from app.services.ai_service import AIService
from app.db.models import Item

def create_mock_inventory():
    """Create mock inventory for testing"""
    mock_items = []
    
    # Common items
    items_data = [
        (["Aata", "Wheat", "Gehun"], 50, "kg"),
        (["Chawal", "Rice", "Basmati"], 80, "kg"),
        (["Daal", "Lentils", "Masoor"], 120, "kg"),
        (["Chini", "Sugar"], 45, "kg"),
        (["Namak", "Salt"], 20, "kg"),
        (["Tel", "Oil", "Cooking Oil"], 150, "litre"),
        (["Doodh", "Milk"], 60, "litre"),
        (["Anda", "Egg"], 6, "piece"),
        (["Roti", "Chapati"], 5, "piece"),
        (["Sabun", "Soap"], 30, "piece"),
    ]
    
    for idx, (names, price, unit) in enumerate(items_data):
        item = type('Item', (), {
            'id': idx + 1,
            'names': names,
            'price': price,
            'unit': unit,
            'owner_id': 1
        })()
        mock_items.append(item)
    
    return mock_items

def test_ai_speed():
    """Test AI response speed with various queries"""
    
    print("\n" + "="*60)
    print("🚀 AI SPEED TEST - Ultra-Fast Optimization")
    print("="*60 + "\n")
    
    # Initialize AI service
    ai_service = AIService()
    inventory = create_mock_inventory()
    
    # Test queries
    test_queries = [
        "ek kilo Aata",
        "do kilo chawal",
        "ek kilo Aata do kilo chawal",
        "teen kilo daal ek litre tel",
        "paanch anda das roti",
    ]
    
    total_time = 0
    success_count = 0
    
    for idx, query in enumerate(test_queries, 1):
        print(f"\n📝 Test {idx}: '{query}'")
        print("-" * 60)
        
        start = time.time()
        try:
            result = ai_service.process_voice_command(query, inventory)
            elapsed = time.time() - start
            total_time += elapsed
            
            if result.get('type') == 'BILL':
                success_count += 1
                items_count = len(result.get('items', []))
                print(f"✅ SUCCESS: {items_count} items detected")
                print(f"⏱️  Response Time: {elapsed:.3f}s")
                
                if elapsed < 0.5:
                    print("🚀 BLAZING FAST! (<0.5s)")
                elif elapsed < 1.0:
                    print("⚡ FAST! (<1s)")
                elif elapsed < 2.0:
                    print("✓ Good (<2s)")
                else:
                    print("⚠️  SLOW (>2s) - Check network/API")
                    
            else:
                print(f"⚠️  ERROR: {result.get('msg', 'Unknown error')}")
                print(f"⏱️  Response Time: {elapsed:.3f}s")
                
        except Exception as e:
            elapsed = time.time() - start
            print(f"❌ FAILED: {str(e)[:100]}")
            print(f"⏱️  Response Time: {elapsed:.3f}s")
    
    # Summary
    print("\n" + "="*60)
    print("📊 SUMMARY")
    print("="*60)
    print(f"Total Tests: {len(test_queries)}")
    print(f"Successful: {success_count}")
    print(f"Failed: {len(test_queries) - success_count}")
    print(f"Average Response Time: {total_time / len(test_queries):.3f}s")
    
    if total_time / len(test_queries) < 0.5:
        print("\n🎉 EXCELLENT! AI is BLAZING FAST! ⚡⚡⚡")
    elif total_time / len(test_queries) < 1.0:
        print("\n✅ GOOD! AI is responding quickly! ⚡")
    elif total_time / len(test_queries) < 2.0:
        print("\n✓ OK! AI is responding reasonably fast.")
    else:
        print("\n⚠️  SLOW! Check network connection or API quota.")
    
    print("\n" + "="*60 + "\n")

if __name__ == "__main__":
    # Check if API key is set
    if not os.getenv("GEMINI_API_KEY"):
        print("\n❌ ERROR: GEMINI_API_KEY not found in .env file!")
        print("Please add your API key to .env file.\n")
        exit(1)
    
    test_ai_speed()
