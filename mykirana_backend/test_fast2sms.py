"""
Test Fast2SMS API Integration
Run this to verify your API key and SMS sending works
"""
import os
import requests
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

FAST2SMS_API_KEY = os.getenv("FAST2SMS_API_KEY")

def test_fast2sms():
    print("=" * 60)
    print("Fast2SMS API Test")
    print("=" * 60)
    
    if not FAST2SMS_API_KEY:
        print("❌ ERROR: FAST2SMS_API_KEY not found in .env file")
        return
    
    print(f"✅ API Key found: {FAST2SMS_API_KEY[:10]}...{FAST2SMS_API_KEY[-10:]}")
    print()
    
    # Test phone number (replace with your actual number)
    test_phone = input("Enter test phone number (10 digits, no +91): ").strip()
    
    if len(test_phone) != 10 or not test_phone.isdigit():
        print("❌ Invalid phone number. Must be 10 digits.")
        return
    
    print(f"\n📤 Sending test OTP to {test_phone}...")
    
    # Use bulk API with OTP route (GET method) - as shown in Fast2SMS dashboard
    url = "https://www.fast2sms.com/dev/bulkV2"
    
    params = {
        "authorization": FAST2SMS_API_KEY,
        "route": "otp",
        "variables_values": "123456",  # The OTP code
        "numbers": test_phone,
        "flash": "0"
    }
    
    print(f"\n📤 Request URL: {url}")
    print(f"📤 Parameters: {params}")
    
    try:
        # Use GET method
        response = requests.get(url, params=params, timeout=10)
        
        print(f"\n📥 Response Status: {response.status_code}")
        print(f"📥 Response Headers: {dict(response.headers)}")
        print(f"📥 Response Body: {response.text}")
        print()
        
        if response.status_code == 200:
            try:
                result = response.json()
                if result.get("return"):
                    print("✅ SUCCESS! SMS sent successfully")
                    print(f"   Message ID: {result.get('request_id')}")
                else:
                    print(f"❌ FAILED: {result.get('message')}")
            except ValueError:
                print("⚠️  Response is not valid JSON")
                print(f"   Raw response: {response.text}")
        else:
            print(f"❌ HTTP Error: {response.status_code}")
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_fast2sms()
