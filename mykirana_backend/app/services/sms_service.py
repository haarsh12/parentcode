"""import os

class SMSService:
    def send_otp(self, phone_number: str, otp: str):
        
        Sends an OTP to the given phone number.
        Currently prints to console for development.
        
        # In the future, we will put Fast2SMS code here.
        print(f"========================================")
        print(f"📲 [SMS MOCK] Sending OTP to {phone_number}")
        print(f"🔑 OTP CODE: {otp}")
        print(f"========================================")
        return True"""
import logging

logger = logging.getLogger("sms")

class SMSService:
    def send_otp(self, phone_number: str, otp: str):
        logger.warning(f"SMS MOCK → {phone_number} OTP={otp}")
