from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
from sqlmodel import Session, select, func, and_
from datetime import datetime, timedelta
from app.db.database import get_session
from app.db.models import Item, Bill, SaleItem
from app.services.ai_service import AIService
from app.api.items import get_current_user # Re-use the login logic
import json

router = APIRouter()
ai_service = AIService()

class VoiceRequest(BaseModel):
    text: str

class PremiumVoiceRequest(BaseModel):
    transcript: str
    user_id: int
    inventory: List[Dict[str, Any]]

@router.post("/process")
def process_voice(
    request: VoiceRequest,
    session: Session = Depends(get_session),
    user_id: int = Depends(get_current_user)
):
    """
    Enhanced endpoint - Receives text -> Fetches Inventory + Analytics -> Calls AI -> Returns Response
    """
    # 1. Get THIS user's inventory
    statement = select(Item).where(Item.owner_id == user_id)
    inventory = session.exec(statement).all()
    
    # 2. Get Dashboard Analytics (Last 30 days)
    dashboard_data = _get_dashboard_data(session, user_id, days=30)
    
    # 3. Get Recent Bills (Last 10)
    recent_bills = _get_recent_bills(session, user_id, limit=10)
    
    # 4. Call the AI Service with full context
    ai_response = ai_service.process_voice_command(
        request.text, 
        inventory,
        dashboard_data=dashboard_data,
        recent_bills=recent_bills
    )
    
    return ai_response

def _get_dashboard_data(session: Session, user_id: int, days: int = 30) -> Dict[str, Any]:
    """Get dashboard analytics for AI context"""
    try:
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)
        
        # Total revenue
        revenue_stmt = select(func.sum(Bill.total_amount)).where(
            and_(Bill.owner_id == user_id, Bill.bill_date >= start_date)
        )
        total_revenue = session.exec(revenue_stmt).first() or 0.0
        
        # Total bills
        bills_stmt = select(func.count(Bill.id)).where(
            and_(Bill.owner_id == user_id, Bill.bill_date >= start_date)
        )
        total_bills = session.exec(bills_stmt).first() or 0
        
        # Average bill value
        avg_bill_value = total_revenue / total_bills if total_bills > 0 else 0.0
        
        # Total inventory
        inventory_stmt = select(func.count(Item.id)).where(Item.owner_id == user_id)
        total_inventory = session.exec(inventory_stmt).first() or 0
        
        # Top selling items
        top_items_stmt = select(
            SaleItem.item_name,
            SaleItem.unit,
            func.sum(SaleItem.quantity).label('total_quantity'),
            func.count(SaleItem.id).label('times_sold')
        ).where(
            and_(SaleItem.owner_id == user_id, SaleItem.sale_date >= start_date)
        ).group_by(SaleItem.item_name, SaleItem.unit).order_by(
            func.sum(SaleItem.quantity).desc()
        ).limit(5)
        
        top_items = session.exec(top_items_stmt).all()
        
        # Category breakdown
        category_stmt = select(
            SaleItem.item_category,
            func.sum(SaleItem.total_price).label('total_sales'),
            func.sum(SaleItem.quantity).label('total_quantity')
        ).where(
            and_(SaleItem.owner_id == user_id, SaleItem.sale_date >= start_date)
        ).group_by(SaleItem.item_category)
        
        categories = session.exec(category_stmt).all()
        
        # Peak hours
        peak_hours_stmt = select(
            SaleItem.hour_of_day,
            func.count(SaleItem.id).label('sales_count'),
            func.sum(SaleItem.total_price).label('total_sales')
        ).where(
            and_(SaleItem.owner_id == user_id, SaleItem.sale_date >= start_date)
        ).group_by(SaleItem.hour_of_day).order_by(SaleItem.hour_of_day)
        
        peak_hours = session.exec(peak_hours_stmt).all()
        
        # Peak day
        day_stmt = select(
            func.extract('dow', Bill.bill_date).label('day_of_week'),
            func.count(Bill.id).label('bill_count'),
            func.sum(Bill.total_amount).label('total_sales')
        ).where(
            and_(Bill.owner_id == user_id, Bill.bill_date >= start_date)
        ).group_by('day_of_week').order_by(func.sum(Bill.total_amount).desc())
        
        days_data = session.exec(day_stmt).all()
        peak_day = days_data[0] if days_data else None
        
        day_names = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
        
        return {
            "summary": {
                "total_revenue": round(total_revenue, 2),
                "total_bills": total_bills,
                "average_bill_value": round(avg_bill_value, 2),
                "total_inventory_items": total_inventory
            },
            "top_selling_items": [
                {
                    "name": item[0],
                    "unit": item[1],
                    "quantity": float(item[2]),
                    "times_sold": item[3]
                }
                for item in top_items
            ],
            "category_breakdown": [
                {
                    "category": cat[0],
                    "total_sales": float(cat[1]),
                    "quantity": float(cat[2]),
                    "percentage": round((float(cat[1]) / total_revenue * 100) if total_revenue > 0 else 0, 1)
                }
                for cat in categories
            ],
            "peak_hours": [
                {
                    "hour": int(hour[0]),
                    "sales_count": hour[1],
                    "total_sales": float(hour[2])
                }
                for hour in peak_hours
            ],
            "peak_day": {
                "day": day_names[int(peak_day[0])] if peak_day else "N/A",
                "bill_count": peak_day[1] if peak_day else 0,
                "total_sales": float(peak_day[2]) if peak_day else 0.0
            } if peak_day else None
        }
    except Exception as e:
        print(f"Error getting dashboard data: {e}")
        return {}

def _get_recent_bills(session: Session, user_id: int, limit: int = 10) -> List[Dict[str, Any]]:
    """Get recent bills for AI context"""
    try:
        statement = select(Bill).where(
            Bill.owner_id == user_id
        ).order_by(Bill.bill_date.desc()).limit(limit)
        
        bills = session.exec(statement).all()
        
        return [
            {
                "id": bill.id,
                "total_amount": bill.total_amount,
                "total_items": bill.total_items,
                "items": json.loads(bill.items_json) if bill.items_json else [],
                "customer_name": bill.customer_name or "Walk-in",
                "bill_date": bill.bill_date.strftime("%Y-%m-%d %H:%M") if bill.bill_date else ""
            }
            for bill in bills
        ]
    except Exception as e:
        print(f"Error getting recent bills: {e}")
        return []

@router.post("/process-query")
def process_query(request: PremiumVoiceRequest):
    """
    Process a query (question) from the user
    Returns answer and whether to continue listening
    """
    try:
        # Detect query type
        transcript_lower = request.transcript.lower()
        
        # Check if it's a price query
        if any(word in transcript_lower for word in ['kitna', 'price', 'rate', 'cost', 'kya hai']):
            # Extract item name from query
            item_name = _extract_item_from_query(transcript_lower)
            
            if item_name:
                # Find item in inventory
                matching_item = None
                for item in request.inventory:
                    if any(item_name in name.lower() for name in item.get('names', [])):
                        matching_item = item
                        break
                
                if matching_item:
                    answer = f"{matching_item['names'][0]} ka price hai {matching_item['price']} rupaye per {matching_item['unit']}"
                    
                    # Check if query includes billing intent
                    if any(word in transcript_lower for word in ['de do', 'dena', 'chahiye', 'add']):
                        # Continue listening for billing
                        return {
                            "success": True,
                            "answer": answer,
                            "continue_listening": True,
                            "mode": "billing"
                        }
                    else:
                        # Just answer, stop listening
                        return {
                            "success": True,
                            "answer": answer,
                            "continue_listening": False,
                            "mode": "query"
                        }
                else:
                    answer = f"{item_name} inventory mein nahi hai"
                    return {
                        "success": True,
                        "answer": answer,
                        "continue_listening": False,
                        "mode": "query"
                    }
        
        # Generic query - use AI
        answer = "Kripya apna sawal dobara puchiye"
        return {
            "success": True,
            "answer": answer,
            "continue_listening": False,
            "mode": "query"
        }
        
    except Exception as e:
        print(f"Query processing error: {e}")
        return {
            "success": False,
            "error": str(e),
            "continue_listening": False
        }

@router.post("/process-billing")
def process_billing(request: PremiumVoiceRequest):
    """
    Process billing transcript
    Returns bill updates
    """
    try:
        # Use AI service to parse billing items
        inventory_items = []
        for item_data in request.inventory:
            # Create mock Item objects for AI service
            item = type('Item', (), {
                'id': item_data.get('id'),
                'names': item_data.get('names', []),
                'price': item_data.get('price'),
                'unit': item_data.get('unit'),
                'category': item_data.get('category', '')
            })()
            inventory_items.append(item)
        
        # Process with AI
        ai_response = ai_service.process_voice_command(request.transcript, inventory_items)
        
        # Extract bill items
        bill_updates = []
        if ai_response.get('success') and 'bill' in ai_response:
            for item in ai_response['bill']:
                bill_updates.append({
                    'name': item.get('item_name'),
                    'quantity': item.get('quantity', 1.0),
                    'unit': item.get('unit', ''),
                    'price': item.get('price_per_unit', 0.0),
                    'total': item.get('total_price', 0.0)
                })
        
        return {
            "success": True,
            "bill_updates": bill_updates,
            "total_items": len(bill_updates)
        }
        
    except Exception as e:
        print(f"Billing processing error: {e}")
        return {
            "success": False,
            "error": str(e),
            "bill_updates": []
        }

def _extract_item_from_query(query: str) -> Optional[str]:
    """Extract item name from query"""
    # Remove common query words
    remove_words = ['kitna', 'kya', 'hai', 'ka', 'ki', 'ke', 'price', 'rate', 'cost', 'batao', 'bata', 'do']
    
    words = query.split()
    item_words = [w for w in words if w not in remove_words and len(w) > 1]
    
    if item_words:
        return ' '.join(item_words)
    
    return None