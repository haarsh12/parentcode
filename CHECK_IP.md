# Backend Connection Issue - SOLUTION

## Problem
Your app shows: `Connection Error: address = 192.168.205.207, port = 41046`
But your backend is running on: `http://0.0.0.0:8000`

## Root Cause
Your computer's IP address has changed OR your phone and computer are on different networks.

## Solution Steps

### Step 1: Find Your Computer's Current IP Address

**On Windows:**
1. Open Command Prompt (cmd)
2. Type: `ipconfig`
3. Look for "IPv4 Address" under your WiFi adapter
4. It will look like: `192.168.x.x` or `10.x.x.x`

**Example Output:**
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

### Step 2: Update Config File

Open: `snapbill_frontend/lib/core/config.dart`

Change line 8 to your NEW IP address:
```dart
static const String _realDeviceUrl = "http://YOUR_NEW_IP:8000";
```

For example, if your IP is `192.168.1.100`:
```dart
static const String _realDeviceUrl = "http://192.168.1.100:8000";
```

### Step 3: Restart the App

1. Stop the app completely
2. Run: `flutter run`
3. Test the connection

## Alternative: Use ngrok (If IP keeps changing)

If your IP address changes frequently, use ngrok:

1. Download ngrok: https://ngrok.com/download
2. Run: `ngrok http 8000`
3. Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`)
4. Update config:
```dart
static const String _realDeviceUrl = "https://abc123.ngrok.io";
```

## Checklist

- [ ] Computer and phone on SAME WiFi network
- [ ] Backend running on `http://0.0.0.0:8000`
- [ ] Firewall allows port 8000
- [ ] Config file has correct IP address
- [ ] App restarted after config change

## Quick Test

After updating the IP, test in browser on your phone:
- Open Chrome on your phone
- Go to: `http://YOUR_NEW_IP:8000/docs`
- If it loads, the connection works!

## Current Status

Backend: ✅ Running on `http://0.0.0.0:8000`
Frontend: ❌ Trying to connect to `192.168.205.207:8000`

**Action Required**: Update IP address in config.dart
