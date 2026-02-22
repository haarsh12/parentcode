from sqlmodel import SQLModel, Field
from typing import Optional
from datetime import datetime

# 1. Base Model (Fields every table should have)
class TimestampModel(SQLModel):
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

# 2. User Model (The Shop Owner)
class User(TimestampModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    phone_number: str = Field(index=True, unique=True)  # This is phone1 - READ ONLY
    shop_name: Optional[str] = None
    owner_name: Optional[str] = None
    address: Optional[str] = None
    phone2: Optional[str] = None  # Secondary phone number (EDITABLE)
    is_active: bool = Field(default=True)
    role: str = Field(default="owner")

# 3. OTP Model (Temporary codes for login)
class OTP(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    phone_number: str = Field(index=True)
    otp_code: str
    expires_at: datetime
    is_used: bool = Field(default=False)

# 4. Item Model (Your Inventory) - MODIFIED FOR MULTI-LANGUAGE SUPPORT
class Item(TimestampModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    
    # NEW: Store the master list ID from frontend (e.g., "101", "202", "FB1")
    # This allows us to match items between frontend and backend uniquely
    master_id: str = Field(index=True)
    
    # NEW: Store all names as a JSON string array
    # Example: '["Chawal", "Rice", "चावल", "तांदूळ"]'
    # This replaces the old 'name' and 'hindi_name' fields
    names: str  # JSON string containing array of names
    
    category: str = Field(index=True)     # e.g., "Anaj", "Dal", "Masale"
    price: float                          # e.g., 0.0 (unset) or 45.0 (set by user)
    unit: str                             # e.g., "kg", "litre", "plate"
    owner_id: Optional[int] = Field(default=None, foreign_key="user.id")