import random
import string
from datetime import datetime, timedelta
from sqlmodel import Session, select
from app.db.models import OTP

class OTPService:
    def generate_otp(self) -> str:
        """Generates a random 6-digit number"""
        return ''.join(random.choices(string.digits, k=6))

    def create_otp(self, session: Session, phone_number: str) -> str:
        """Generates OTP, saves to DB, and returns it"""
        
        # FIX: Sanitize phone
        clean_phone = phone_number.strip()

        # 1. Generate Code
        code = self.generate_otp()
        
        # 2. Set Expiry (5 minutes from now)
        expires_at = datetime.utcnow() + timedelta(minutes=5)
        
        # 3. Create Record
        otp_record = OTP(
            phone_number=clean_phone,
            otp_code=code,  
            expires_at=expires_at,
            is_used=False
        )
        
        # 4. Save to DB
        session.add(otp_record)
        session.commit()
        session.refresh(otp_record)
        
        return code

    def verify_otp(self, session: Session, phone_number: str, code: str) -> bool:
        """Checks if the OTP is valid and not expired"""
        
        # FIX: Sanitize phone
        clean_phone = phone_number.strip()

        # 1. Find the OTP in DB
        statement = select(OTP).where(
            OTP.phone_number == clean_phone,
            OTP.otp_code == code,
            OTP.is_used == False,
            OTP.expires_at > datetime.utcnow()
        )
        result = session.exec(statement).first()
        
        if not result:
            return False
            
        # 2. Mark as used so it can't be used again
        result.is_used = True
        session.add(result)
        session.commit()
        
        return True