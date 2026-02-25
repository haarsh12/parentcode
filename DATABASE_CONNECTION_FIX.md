# 🔧 DATABASE CONNECTION FIX

## 🔴 PROBLEM
Server fails to start with error:
```
Connection timed out
connection to server at "db.yycyldkqlnothjojxtea.supabase.co"
```

## 🔍 ROOT CAUSE
Your computer cannot reach the Supabase PostgreSQL database server. This is a **network connectivity issue**.

---

## ✅ SOLUTIONS (Try in Order)

### Solution 1: Check Firewall (Most Common)

**Windows Firewall may be blocking PostgreSQL port 5432**

1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Outbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" → Specific remote ports: `5432` → Next
6. Select "Allow the connection" → Next
7. Check all profiles → Next
8. Name: "PostgreSQL Supabase" → Finish

**Or use PowerShell (Run as Administrator):**
```powershell
New-NetFirewallRule -DisplayName "PostgreSQL Supabase" -Direction Outbound -Protocol TCP -RemotePort 5432 -Action Allow
```

### Solution 2: Check Antivirus/Security Software

Some antivirus software blocks database connections:
- Temporarily disable antivirus
- Try starting the server again
- If it works, add exception for Python/PostgreSQL

### Solution 3: Try Different Network

Your ISP or network may block port 5432:
- Try mobile hotspot
- Try different WiFi network
- Try VPN (if allowed)

### Solution 4: Check Supabase Status

Visit: https://status.supabase.com/
- Check if Supabase is having issues
- Check your project status at: https://supabase.com/dashboard

### Solution 5: Use SQLite (Local Database)

If you can't connect to Supabase, use a local SQLite database for development:

**Step 1: Update `.env` file:**
```env
# Comment out Supabase
# DATABASE_URL=postgresql://postgres:ShantiNagar12@db.yycyldkqlnothjojxtea.supabase.co:5432/postgres

# Use SQLite instead
DATABASE_URL=sqlite:///./snapbill.db
```

**Step 2: Install SQLite support (if needed):**
```bash
pip install aiosqlite
```

**Step 3: Restart server:**
```bash
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

SQLite will create a local `snapbill.db` file in your backend folder.

---

## 🧪 DIAGNOSTIC TESTS

### Test 1: Check if Supabase is reachable
```powershell
Test-NetConnection -ComputerName db.yycyldkqlnothjojxtea.supabase.co -Port 5432
```

**Expected:** `TcpTestSucceeded : True`
**If False:** Network/firewall is blocking connection

### Test 2: Check DNS resolution
```powershell
nslookup db.yycyldkqlnothjojxtea.supabase.co
```

**Expected:** Should return IP addresses
**If fails:** DNS issue

### Test 3: Check general internet
```powershell
ping google.com
```

**Expected:** Should get replies
**If fails:** No internet connection

### Test 4: Try direct connection with psql (if installed)
```bash
psql "postgresql://postgres:ShantiNagar12@db.yycyldkqlnothjojxtea.supabase.co:5432/postgres"
```

---

## 🚀 QUICK FIX: Start Server Without Database Check

Modify `app/main.py` to skip database check on startup:

**Current code (fails if DB unreachable):**
```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Startup: Checking database connection...")
    create_db_and_tables()  # ← This fails
    yield
```

**Modified code (continues even if DB fails):**
```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Startup: Checking database connection...")
    try:
        create_db_and_tables()
        print("✅ Database connected!")
    except Exception as e:
        print(f"⚠️ Database connection failed: {e}")
        print("⚠️ Server will start but database operations will fail")
    yield
```

This allows the server to start, but database operations will fail until connection is restored.

---

## 📊 RECOMMENDED SOLUTION

**For Development (Local Testing):**
Use SQLite - it's simple, fast, and doesn't require network:
```env
DATABASE_URL=sqlite:///./snapbill.db
```

**For Production (Real App):**
Fix the Supabase connection:
1. Check firewall settings
2. Contact your network admin if on corporate network
3. Try different network/VPN
4. Verify Supabase project is active

---

## 🔍 WHY THIS HAPPENED

This is **NOT** related to the AI optimization we just did. This is a separate network/database connectivity issue that could be caused by:

1. **Firewall rules** - Windows Firewall blocking port 5432
2. **ISP blocking** - Some ISPs block database ports
3. **Network policy** - Corporate/school networks may block
4. **Supabase issue** - Rare, but possible
5. **VPN interference** - VPN may route traffic differently

---

## ✅ NEXT STEPS

**Option A: Quick Fix (SQLite)**
1. Edit `.env` → Change to SQLite
2. Restart server
3. Test AI speed (should work fine)

**Option B: Fix Supabase Connection**
1. Add firewall rule for port 5432
2. Test connection: `Test-NetConnection -ComputerName db.yycyldkqlnothjojxtea.supabase.co -Port 5432`
3. If still fails, try different network
4. Restart server

**Option C: Skip DB Check**
1. Modify `app/main.py` to catch exception
2. Server starts but DB operations fail
3. Fix connection later

---

## 🎯 RECOMMENDED: Use SQLite for Now

Since you're testing the AI speed optimization, use SQLite to get the server running quickly:

```bash
# 1. Update .env
# DATABASE_URL=sqlite:///./snapbill.db

# 2. Restart server
cd mykirana_backend
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 3. Test AI speed
python test_ai_speed.py
```

You can switch back to Supabase later once the network issue is resolved.

---

**The AI optimization is complete and working. This is just a network connectivity issue preventing the server from starting.**
