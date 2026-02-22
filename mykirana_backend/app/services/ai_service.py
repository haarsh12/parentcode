import google.generativeai as genai
import os
import json
from app.db.models import Item
from typing import List
from google.api_core import client_options as client_options_lib

# 1. Configure Gemini
api_key = os.getenv("GEMINI_API_KEY")
if not api_key:
    print("\n❌ ERROR: GEMINI_API_KEY is missing!\n")
else:
    genai.configure(api_key=api_key, transport="rest")

class AIService:
    def __init__(self):
        # EXACT MODELS FROM YOUR LIST (Prioritizing Lite for better quota)
        self.candidate_models = [
            "gemini-2.0-flash-lite",      # Try this first (Lightweight & Fast)
            "gemini-flash-latest",        # Alias for the current stable flash
            "gemini-2.0-flash",           # Powerful but strict quota
            "gemini-2.0-flash-001"        # Alternative version
        ]

    def process_voice_command(self, user_text: str, inventory: List[Item]):
        print(f"\n🎤 Processing Voice: {user_text}")
        
        # CRITICAL: Filter inventory to only include items with price > 0
        filtered_inventory = [item for item in inventory if item.price > 0]
        
        print(f"📦 Total Inventory Items: {len(inventory)}")
        print(f"✅ Items with Price > 0: {len(filtered_inventory)}")
        
        # Prepare Inventory with names array support
        inventory_list = []
        for item in filtered_inventory:
            # Parse names from JSON string
            names_array = json.loads(item.names) if isinstance(item.names, str) else item.names
            
            inventory_list.append({
                "names": names_array,
                "price": item.price,
                "unit": item.unit,
                "category": item.category
            })
        
        inventory_json = json.dumps(inventory_list, ensure_ascii=False)

        prompt = f"""
        You are a custom AI for "SnapBill". Answer ONLY in Hindi in Latin Script  (Hinglish).
        
        INVENTORY (Only items with configured prices): {inventory_json}
        USER SAID: "{user_text}"

        TASKS:
        1. If item is in inventory (check all name variations), use that price.
        2. If item NOT in inventory, respond: "कृपया पहले [item name] की कीमत सेट करें।" (Please set price for [item name] first)
        3. Match quantities correctly (1 किलो, 2 लीटर, etc.)
        
        OUTPUT JSON:
        {{
          "type": "BILL" or "ERROR",
          "items": [ 
            {{"name": "ItemName", "qty_display": "1 kg", "rate": 50.0, "total": 50.0, "unit": "kg"}} 
          ],
          "msg": "Short response in Hindi",
          "should_stop": false
        }}
        
        If item price not set, return type: "ERROR" with appropriate Hindi message.
        """

        # AUTO-DISCOVERY LOOP
        last_error = ""
        for model_name in self.candidate_models:
            try:
                print(f"🔄 Trying model: {model_name}...")
                model = genai.GenerativeModel(model_name)
                response = model.generate_content(prompt)
                
                print(f"✅ SUCCESS! Model '{model_name}' worked.")
                clean_text = response.text.replace("```json", "").replace("```", "").strip()
                return json.loads(clean_text)
                
            except Exception as e:
                print(f"⚠️ {model_name} Failed: {e}")
                last_error = str(e)
                continue # Try the next model
        
        print(f"\n❌ ALL MODELS FAILED. Last Error: {last_error}\n")
        return {
            "type": "ERROR",
            "items": [],
            "msg": "सिस्टम त्रुटि: कृपया बाद में पुनः प्रयास करें।", 
            "should_stop": False
        }