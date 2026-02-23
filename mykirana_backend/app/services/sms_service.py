"""
SMS Service using Fast2SMS
Handles OTP and Bill sharing via SMS
"""
import os
import logging
import requests

logger = logging.getLogger("sms")

# Fast2SMS Configuration
FAST2SMS_API_KEY = os.getenv("FAST2SMS_API_KEY")


class SMSService:
    def __init__(self):
        if FAST2SMS_API_KEY:
            self.api_key = FAST2SMS_API_KEY
            logger.info("✅ Fast2SMS Service initialized")
        else:
            self.api_key = None
            logger.warning("⚠️ Fast2SMS API key not found - SMS will be mocked")
    
    def send_otp(self, phone_number: str, otp: str):
        """Send OTP via SMS using Fast2SMS"""
        if not self.api_key:
            logger.warning(f"SMS MOCK → {phone_number} OTP={otp}")
            return True
        
        try:
            message = f"Your SnapBill OTP is: {otp}. Valid for 5 minutes."
            
            url = "https://www.fast2sms.com/dev/bulkV2"
            
            payload = {
                "route": "v3",
                "sender_id": "TXTIND",
                "message": message,
                "language": "english",
                "flash": 0,
                "numbers": phone_number
            }
            
            headers = {
                "authorization": self.api_key,
                "Content-Type": "application/x-www-form-urlencoded",
                "Cache-Control": "no-cache"
            }
            
            response = requests.post(url, data=payload, headers=headers)
            result = response.json()
            
            if result.get("return"):
                logger.info(f"✅ OTP sent to {phone_number}")
                return True
            else:
                logger.error(f"❌ Fast2SMS error: {result.get('message')}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Failed to send OTP: {e}")
            return False


def send_sms_bill(to_number: str, message: str) -> dict:
    """
    Send bill via Fast2SMS
    
    Args:
        to_number: Phone number (10 digits)
        message: Bill text to send
    
    Returns:
        dict with success status and message ID or error
    """
    
    if not FAST2SMS_API_KEY:
        logger.warning("⚠️ Fast2SMS not configured - SMS mocked")
        print(f"📱 MOCK SMS to {to_number}:")
        print(message)
        return {
            "success": True,
            "message_id": "MOCK_MSG_12345",
            "error": None
        }
    
    try:
        url = "https://www.fast2sms.com/dev/bulkV2"
        
        payload = {
            "route": "v3",
            "sender_id": "TXTIND",
            "message": message,
            "language": "english",
            "flash": 0,
            "numbers": to_number
        }
        
        headers = {
            "authorization": FAST2SMS_API_KEY,
            "Content-Type": "application/x-www-form-urlencoded",
            "Cache-Control": "no-cache"
        }
        
        response = requests.post(url, data=payload, headers=headers)
        result = response.json()
        
        if result.get("return"):
            logger.info(f"✅ Bill SMS sent to {to_number}")
            return {
                "success": True,
                "message_id": result.get("request_id"),
                "error": None
            }
        else:
            logger.error(f"❌ Fast2SMS error: {result.get('message')}")
            return {
                "success": False,
                "message_id": None,
                "error": result.get("message")
            }
        
    except Exception as e:
        logger.error(f"❌ Fast2SMS error: {e}")
        return {
            "success": False,
            "message_id": None,
            "error": str(e)
        }

