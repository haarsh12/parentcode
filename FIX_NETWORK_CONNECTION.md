# 🌐 FIX NETWORK CONNECTION - GET PROPER IP ADDRESS

## ❌ PROBLEM IDENTIFIED

Your `ipconfig` output shows:
```
Autoconfiguration IPv4 Address. . : 169.254.48.116
```

This is an **APIPA address** (169.254.x.x), which means:
- ❌ Your computer is NOT properly connected to WiFi
- ❌ It couldn't get an IP address from the router
- ❌ Your phone can't connect to the backend

## ✅ SOLUTION

### Step 1: Fix WiFi Connection

#### Option A: Reconnect to WiFi
1. Open **Settings** → **Network & Internet** → **WiFi**
2. **Disconnect** from current WiFi
3. **Reconnect** to your WiFi network
4. Enter password if needed
5. Wait 10 seconds

#### Option B: Restart Network Adapter
1. Open **Command Prompt** as Administrator
2. Run these commands:
```bash
ipconfig /release
ipconfig /renew
```

#### Option C: Restart WiFi Adapter
1. Press `Win + X` → **Device Manager**
2. Expand **Network adapters**
3. Right-click your WiFi adapter
4. Click **Disable device**
5. Wait 5 seconds
6. Right-click again → **Enable device**

#### Option D: Restart Computer
- Sometimes the simplest solution works best
- Restart your computer
- Reconnect to WiFi

---

### Step 2: Get Your Proper IP Address

After fixing WiFi, run `ipconfig` again:

```bash
ipconfig
```

Look for **IPv4 Address** (NOT Autoconfiguration):
```
IPv4 Address. . . . . . . . . . . : 192.168.1.X
```

Common IP ranges:
- `192.168.1.X` (most common)
- `192.168.0.X`
- `10.0.0.X`
- `172.16.X.X`

**Example of CORRECT output:**
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.105
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . : 192.168.1.1
```

---

### Step 3: Update Config Files

Once you have a proper IP (e.g., `192.168.1.105`), update these files:

#### File 1: `snapbill_frontend/lib/services/api_client.dart`

Find this line:
```dart
static const String baseUrl = "http://10.84.59.207:8000";
```

Change to your NEW IP:
```dart
static const String baseUrl = "http://192.168.1.105:8000";
```

#### File 2: `snapbill_frontend/lib/core/config.dart`

Find this line:
```dart
static const String _realDeviceUrl = "http://10.84.59.207:8000";
```

Change to your NEW IP:
```dart
static const String _realDeviceUrl = "http://192.168.1.105:8000";
```

---

### Step 4: Verify Connection

#### A. Check if Backend is Running
```bash
cd mykirana_backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

#### B. Test from Browser
Open browser on your PC:
```
http://localhost:8000/docs
```

You should see the FastAPI documentation page.

#### C. Test from Phone Browser
1. Connect phone to SAME WiFi as PC
2. Open browser on phone
3. Go to: `http://192.168.1.105:8000/docs` (use YOUR IP)
4. You should see the FastAPI documentation page

If this works, your app will work too!

---

## 🔍 TROUBLESHOOTING

### Issue: Still Getting 169.254.x.x Address

**Possible Causes:**
1. WiFi router is not working properly
2. DHCP server is disabled on router
3. Network cable is unplugged (if using Ethernet)
4. WiFi adapter driver is outdated

**Solutions:**
1. Restart your WiFi router
2. Check router settings (enable DHCP)
3. Update WiFi adapter driver
4. Try different WiFi network

---

### Issue: Phone Can't Connect to Backend

**Checklist:**
- [ ] PC and phone on SAME WiFi network
- [ ] Backend is running (`uvicorn` command)
- [ ] Firewall allows port 8000
- [ ] Correct IP in config files
- [ ] IP is NOT 169.254.x.x

**Test Firewall:**
```bash
# Windows Firewall - Allow port 8000
netsh advfirewall firewall add rule name="FastAPI" dir=in action=allow protocol=TCP localport=8000
```

---

### Issue: IP Address Keeps Changing

**Solution: Set Static IP**

1. Open **Settings** → **Network & Internet** → **WiFi**
2. Click on your WiFi network
3. Click **Edit** under IP settings
4. Change from **Automatic (DHCP)** to **Manual**
5. Enable **IPv4**
6. Enter:
   - IP address: `192.168.1.105` (choose unused IP)
   - Subnet mask: `255.255.255.0`
   - Gateway: `192.168.1.1` (your router IP)
   - DNS: `8.8.8.8` (Google DNS)
7. Click **Save**

Now your IP won't change!

---

## 📱 QUICK REFERENCE

### Current Status:
- ❌ IP: `169.254.48.116` (INVALID - Autoconfiguration)
- ❌ Can't connect phone to backend

### Target Status:
- ✅ IP: `192.168.1.X` (VALID - From router)
- ✅ Phone can connect to backend

### Commands to Remember:
```bash
# Check IP
ipconfig

# Renew IP
ipconfig /release
ipconfig /renew

# Start backend
cd mykirana_backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# Test from phone browser
http://YOUR_IP:8000/docs
```

---

## ✅ FINAL CHECKLIST

Before running the app:
- [ ] WiFi is connected properly
- [ ] `ipconfig` shows valid IPv4 (NOT 169.254.x.x)
- [ ] Backend is running
- [ ] Config files updated with correct IP
- [ ] Phone and PC on same WiFi
- [ ] Firewall allows port 8000
- [ ] Tested from phone browser (http://YOUR_IP:8000/docs)

Once all checked, rebuild and run the app:
```bash
cd snapbill_frontend
flutter clean
flutter pub get
flutter run
```

---

## 🎯 EXPECTED RESULT

After fixing:
1. `ipconfig` shows: `IPv4 Address: 192.168.1.X`
2. Backend runs on: `http://0.0.0.0:8000`
3. Phone connects to: `http://192.168.1.X:8000`
4. App works perfectly!

Good luck! 🚀
