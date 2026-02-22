from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlmodel import Session, select
from app.db.database import get_session
from app.db.models import Item
from app.services.ai_service import AIService
from app.api.items import get_current_user # Re-use the login logic

router = APIRouter()
ai_service = AIService()

class VoiceRequest(BaseModel):
    text: str

@router.post("/process")
def process_voice(
    request: VoiceRequest,
    session: Session = Depends(get_session),
    user_id: int = Depends(get_current_user)
):
    """
    Receives text from the App -> Fetches Inventory -> Calls AI -> Returns Bill JSON
    """
    # 1. Get THIS user's inventory
    statement = select(Item).where(Item.owner_id == user_id)
    inventory = session.exec(statement).all()
    
    # 2. Call the AI Service
    ai_response = ai_service.process_voice_command(request.text, inventory)
    
    return ai_response