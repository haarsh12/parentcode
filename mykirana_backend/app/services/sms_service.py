"""
SMS Service using Twilio
Handles OTP and Bill sharing via SMS
"""
import os
import logging
from twilio.rest import Client

logger = logging.getLogger("sms")

# Twilio Configuration
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_PHONE_NUMBER = os.getenv("TWILIO_PHONE_NUMBER")


class SMSService:
    def __init__(self):
        if TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN:
            self.client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
            self.from_number = TWILIO_PHONE_NUMBER
            logger.info("✅ Twilio SMS Service initialized")
        else:
            self.client = None
            logger.warning("⚠️ Twilio credentials not found - SMS will be mocked")
    
    def send_otp(self, phone_number: str, otp: str):
        """Send OTP via SMS"""
        if not self.client:
            logger.warning(f"SMS MOCK → {phone_number} OTP={otp}")
            return True
        
        try:
            message = f"Your SnapBill OTP is: {otp}\nValid for 5 minutes."
            
            result = self.client.messages.create(
                body=message,
                from_=self.from_number,
                to=f"+91{phone_number}"
            )
            
            logger.info(f"✅ OTP sent to {phone_number}: {result.sid}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to send OTP: {e}")
            return False


def send_sms_bill(to_number: str, message: str) -> dict:
    """
    Send bill via Twilio SMS
    
    Args:
        to_number: Phone number (10 digits)
        message: Bill text to send
    
    Returns:
        dict with success status and message SID or error
    """
    
    if not TWILIO_ACCOUNT_SID or not TWILIO_AUTH_TOKEN:
        logger.warning("⚠️ Twilio not configured - SMS mocked")
        print(f"📱 MOCK SMS to {to_number}:")
        print(message)
        return {
            "success": True,
            "sid": "MOCK_SID_12345",
            "error": None
        }
    
    try:
        client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        
        # Format phone number
        formatted_number = f"+91{to_number}" if not to_number.startswith('+') else to_number
        
        # Send SMS
        result = client.messages.create(
            body=message,
            from_=TWILIO_PHONE_NUMBER,
            to=formatted_number
        )
        
        logger.info(f"✅ Bill SMS sent to {to_number}: {result.sid}")
        
        return {
            "success": True,
            "sid": result.sid,
            "error": None
        }
        
    except Exception as e:
        logger.error(f"❌ Twilio SMS error: {e}")
        return {
            "success": False,
            "sid": None,
            "error": str(e)
        }

