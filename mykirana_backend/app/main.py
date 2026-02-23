from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.db.database import create_db_and_tables
from app.api import auth, items, voice, voice_inventory, sms_share

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Startup: Checking database connection...")
    create_db_and_tables()
    print("Startup: Database check complete.")
    yield
    print("Shutdown: Closing connections...")

app = FastAPI(lifespan=lifespan, title="SnapBill API")

app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(items.router, prefix="/items", tags=["Inventory"])
app.include_router(voice.router, prefix="/voice", tags=["Voice AI"])
app.include_router(voice_inventory.router, prefix="/inventory", tags=["Voice Inventory"])
app.include_router(sms_share.router, prefix="/sms", tags=["SMS Sharing"])

@app.get("/")
def health_check():
    return {"status": "active", "system": "SnapBill Backend"}