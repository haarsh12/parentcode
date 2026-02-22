import google.generativeai as genai
import os
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("❌ API Key not found!")
else:
    print(f"✅ Using API Key: {api_key[:5]}...")
    genai.configure(api_key=api_key)

    print("\n🔍 LISTING AVAILABLE MODELS FOR THIS KEY:")
    print("-" * 40)
    try:
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                print(f"🌟 {m.name}")
    except Exception as e:
        print(f"❌ Error listing models: {e}")
    print("-" * 40)