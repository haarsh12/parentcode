# Fast2SMS - Correct API Setup ✅

## What Was Wrong Before
- ❌ Using `/dev/bulkV2` with POST method and `route: v3`
- ❌ Wrong endpoint for OTP sending
- ❌ Requires DLT templates and sender ID approval

## What's Correct Now
- ✅ Using `/dev/otp` endpoint for OTP (GET method)
- ✅ Using `route: otp` for transactional OTP
- ✅ No DLT template required for OTP route
- ✅ Proper error handling and logging

## API Configuration

### OTP API (For Login/Registration)
```python
url = "https://www.fast2sms.com/dev/otp"
method = GET  # Important: Use GET, not POST

headers = {
    "authorization": "YOUR_API_KEY"
}

params = {
    "variables_values": "123456",  # The OTP code
    "route": "otp",
    "numbers": "8446117247"  # 10 digits, no +91
}
```

### Bulk SMS API (For Bill Sharing)
```python
url = "https://www.fast2sms.com/dev/bulkV2"
method = GET  # Also uses GET

headers = {
    "authorization": "YOUR_API_KEY"
}

params = {
    "route": "q",  # Quick transactional route
    "message": "Your bill message here",
    "language": "english",
    "flash": 0,
    "numbers": "8446117247"
}
```

## Key Differences

### OTP API vs Bulk API

| Feature | OTP API | Bulk API |
|---------|---------|----------|
| Endpoint | `/dev/otp` | `/dev/bulkV2` |
| Method | GET | GET |
| Route | `otp` | `q` (quick) or `v3` |
| Use Case | Login/Registration OTP | Bill sharing, notifications |
| DLT Required | No | Yes (for promotional) |
| Template | Auto-generated | Custom message |

## Your Current Setup

### API Key
```
FAST2SMS_API_KEY=jtdHxAEIk01gbTo4PO5J3LqmU6YyBS78NpzMQnl9euwfDFVai24YFjwq
```

### Files Updated
1. `mykirana_backend/app/services/sms_service.py` - Uses correct OTP API
2. `mykirana_backend/test_fast2sms.py` - Test script with correct API
3. `mykirana_backend/.env` - API key configured

## How to Test

### Step 1: Test API Key
```bash
cd mykirana_backend
python test_fast2sms.py
```

Enter your phone number (10 digits) and check if SMS arrives.

### Step 2: Restart Backend
```bash
cd mykirana_backend
# Stop current server (Ctrl+C)
start_server.bat
```

### Step 3: Try OTP from App
1. Open app
2. Enter phone number
3. Click "Send OTP"
4. Watch server console for logs

## Expected Server Logs

### Success Case
```
📤 Sending OTP to 8446117247 via Fast2SMS OTP API...
📤 API Key: jtdHxAEIk0...ai24YFjwq
📤 Using GET method with /dev/otp endpoint
📥 Fast2SMS Response Status: 200
📥 Fast2SMS Response: {"return":true,"request_id":"abc123","message":["SMS sent successfully"]}
✅ OTP sent successfully to 8446117247
   Message ID: abc123
```

### Failure Case (But OTP Still Works)
```
📤 Sending OTP to 8446117247 via Fast2SMS OTP API...
📥 Fast2SMS Response Status: 200
📥 Fast2SMS Response: {"return":false,"message":"Insufficient balance"}
❌ Fast2SMS error: Insufficient balance
📱 OTP for +918446117247: 123456 (SMS failed but OTP generated)
```

Even if SMS fails, the OTP is generated and logged. User can still login!

## Common Fast2SMS Issues

### 1. Empty Response
**Symptom**: Response text is empty
**Cause**: Wrong endpoint or route
**Solution**: Now using correct `/dev/otp` endpoint

### 2. Invalid Route
**Symptom**: `{"return":false,"message":"Invalid route"}`
**Cause**: Using `route: v3` without DLT approval
**Solution**: Now using `route: otp` for OTP

### 3. Insufficient Balance
**Symptom**: `{"return":false,"message":"Insufficient balance"}`
**Cause**: Account balance is zero
**Solution**: Recharge Fast2SMS account

### 4. Invalid Authorization
**Symptom**: `{"return":false,"message":"Invalid authorization key"}`
**Cause**: Wrong API key
**Solution**: Check API key in Fast2SMS dashboard

## Fast2SMS Dashboard Checks

1. **Login**: https://www.fast2sms.com/
2. **Check Balance**: Dashboard → Wallet
3. **Check API Key**: Dashboard → Dev API → API Keys
4. **Check Logs**: Dashboard → Reports → SMS Logs
5. **Check Routes**: Dashboard → Dev API → Routes

## Phone Number Format

### Correct Format
- ✅ `8446117247` (10 digits)
- ✅ `9876543210` (10 digits)

### Wrong Format
- ❌ `+918446117247` (with country code)
- ❌ `91 8446117247` (with space)
- ❌ `08446117247` (with leading zero)

The code automatically cleans phone numbers, but best to use 10 digits.

## Testing Checklist

- [ ] API key in `.env` file
- [ ] Backend server restarted
- [ ] Run `python test_fast2sms.py`
- [ ] Check Fast2SMS account balance
- [ ] Try OTP from app
- [ ] Check server console logs
- [ ] Verify OTP is logged even if SMS fails

## Next Steps

1. **Restart Backend Server** (MUST DO!)
   ```bash
   cd mykirana_backend
   start_server.bat
   ```

2. **Test API Key**
   ```bash
   python test_fast2sms.py
   ```

3. **Try OTP from App**
   - Watch server console
   - Look for OTP in logs if SMS fails

4. **Check Fast2SMS Dashboard**
   - Verify balance
   - Check SMS logs
   - Confirm API key is active

## Status: READY TO TEST ✅

All code is updated with correct Fast2SMS OTP API. Just restart the server and test!
