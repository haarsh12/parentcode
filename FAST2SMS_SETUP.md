# Fast2SMS Setup Guide

## What Changed

Removed Twilio dependency and switched to Fast2SMS for OTP and bill sharing.

## Files Updated

1. **`app/services/sms_service.py`**
   - Removed Twilio import
   - Added Fast2SMS implementation
   - Uses `requests` library

2. **`.env`**
   - Removed Twilio credentials
   - Added `FAST2SMS_API_KEY` configuration

3. **`requirements.txt`**
   - Removed `twilio`
   - Added `google-generativeai` (for AI service)

## Setup Steps

### Step 1: Get Fast2SMS API Key

1. Go to https://www.fast2sms.com/
2. Sign up / Login
3. Go to Dashboard → API Keys
4. Copy your API key

### Step 2: Update .env File

Open `mykirana_backend/.env` and add your Fast2SMS API key:

```env
FAST2SMS_API_KEY=your_actual_api_key_here
```

Replace `your_actual_api_key_here` with your real API key from Fast2SMS.

### Step 3: Start Backend

```bash
cd mykirana_backend
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Testing

### Test OTP
```bash
# The OTP will be sent via Fast2SMS
curl -X POST http://localhost:8000/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone_number": "9876543210"}'
```

### Test Bill Sharing
```bash
# The bill will be sent via Fast2SMS
curl -X POST http://localhost:8000/sms/share-bill \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "9876543210",
    "bill_items": [...],
    "total": 500
  }'
```

## Mock Mode (No API Key)

If you don't have a Fast2SMS API key yet, the system will work in **mock mode**:
- OTP will be printed in console logs
- Bill SMS will be printed in console logs
- No actual SMS will be sent

This is useful for development and testing.

## Fast2SMS API Details

### Endpoint
```
POST https://www.fast2sms.com/dev/bulkV2
```

### Headers
```
authorization: YOUR_API_KEY
Content-Type: application/x-www-form-urlencoded
```

### Payload
```
route: v3
sender_id: TXTIND
message: Your message here
language: english
flash: 0
numbers: 9876543210
```

### Response
```json
{
  "return": true,
  "request_id": "abc123",
  "message": ["SMS sent successfully"]
}
```

## Troubleshooting

### Error: "No module named 'twilio'"
**Solution**: Already fixed! Twilio has been removed from the code.

### Error: "Fast2SMS API key not found"
**Solution**: Add `FAST2SMS_API_KEY` to your `.env` file.

### SMS not sending
**Check**:
1. API key is correct in `.env`
2. Fast2SMS account has credits
3. Phone number is valid (10 digits)
4. Check console logs for error messages

### Mock mode always active
**Check**: Verify `FAST2SMS_API_KEY` is set in `.env` and backend was restarted.

## Cost Comparison

### Fast2SMS
- ✅ Indian service (better for India)
- ✅ Cheaper rates
- ✅ No international fees
- ✅ Easy setup
- ✅ Good for OTP

### Twilio (Removed)
- ❌ International service
- ❌ Expensive for India
- ❌ Complex setup
- ❌ Overkill for simple OTP

## Conclusion

Your backend now uses Fast2SMS instead of Twilio. This is:
- More cost-effective for Indian users
- Simpler to set up
- Better suited for OTP and bill sharing

Just add your Fast2SMS API key to `.env` and you're good to go!
