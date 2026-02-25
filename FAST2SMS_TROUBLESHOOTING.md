# Fast2SMS Integration - Troubleshooting Guide

## Current Status
✅ API Key configured in `.env` file
✅ SMS service updated with better error handling
✅ Logging added for debugging

## Your API Key
```
FAST2SMS_API_KEY=jtdHxAEIk01gbTo4PO5J3LqmU6YyBS78NpzMQnl9euwfDFVai24YFjwq
```

## Step 1: Test Fast2SMS API Directly

Run the test script to verify your API key works:

```bash
cd mykirana_backend
python test_fast2sms.py
```

This will:
1. Check if API key is loaded
2. Ask for a test phone number
3. Send a test SMS
4. Show the response from Fast2SMS

## Step 2: Restart Backend Server

After updating the `.env` file, you MUST restart the server:

```bash
cd mykirana_backend
# Stop the current server (Ctrl+C)
# Then restart:
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Or use the batch file:
```bash
cd mykirana_backend
start_server.bat
```

## Step 3: Check Server Logs

When you try to send OTP from the app, watch the server console for these logs:

```
📤 Sending OTP to 8446117247 via Fast2SMS...
📤 API Key: jtdHxAEIk0...ai24YFjwq
📥 Fast2SMS Response Status: 200
📥 Fast2SMS Response: {"return":true,"request_id":"..."}
✅ OTP sent to 8446117247
```

## Common Issues & Solutions

### Issue 1: "Expecting value: line 1 column 1"
**Cause**: Fast2SMS returned empty or invalid response
**Solution**: Already fixed - OTP is still generated and logged to console

### Issue 2: API Key Not Working
**Possible Causes**:
- API key expired or invalid
- Account balance is zero
- API key doesn't have SMS permissions

**Check**:
1. Login to Fast2SMS dashboard
2. Check account balance
3. Verify API key is active
4. Check API permissions

### Issue 3: Phone Number Format
**Correct Format**: 10 digits without +91
- ✅ Good: `8446117247`
- ❌ Bad: `+918446117247`
- ❌ Bad: `91 8446117247`

The code now automatically removes +91 and spaces.

### Issue 4: Server Not Restarted
**Solution**: Always restart the backend server after changing `.env` file

## Fast2SMS API Documentation

**Endpoint**: `https://www.fast2sms.com/dev/bulkV2`

**Headers**:
```
authorization: YOUR_API_KEY
Content-Type: application/x-www-form-urlencoded
```

**Payload**:
```
route: v3
sender_id: TXTIND
message: Your message here
language: english
flash: 0
numbers: 10-digit phone number
```

**Success Response**:
```json
{
  "return": true,
  "request_id": "abc123",
  "message": ["SMS sent successfully"]
}
```

**Error Response**:
```json
{
  "return": false,
  "message": "Error description"
}
```

## Testing Checklist

- [ ] API key is in `.env` file
- [ ] Backend server restarted after `.env` change
- [ ] Run `test_fast2sms.py` to verify API key
- [ ] Check Fast2SMS account balance
- [ ] Try sending OTP from app
- [ ] Check server console logs
- [ ] If SMS fails, check console for OTP code

## Fallback: Console OTP

Even if SMS fails, the OTP is:
1. Generated and saved to database
2. Logged to server console
3. User can still login with it

Look for this in server logs:
```
📱 OTP for +918446117247: 123456 (SMS failed but OTP generated)
```

## Next Steps

1. **Test the API key**: Run `python test_fast2sms.py`
2. **Restart server**: Stop and start the backend
3. **Try OTP**: Send OTP from the app
4. **Check logs**: Watch server console for detailed logs
5. **Report back**: Share the Fast2SMS response from logs

## Files Modified
- `mykirana_backend/.env` - Updated API key
- `mykirana_backend/app/services/sms_service.py` - Better error handling & logging
- `mykirana_backend/test_fast2sms.py` - New test script
