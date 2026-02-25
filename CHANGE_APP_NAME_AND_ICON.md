# Change App Name and Icon - Vyamit AI

## ✅ Changes Made

### 1. App Name Changed to "Vyamit AI"

Updated in all files:
- ✅ `snapbill_frontend/lib/services/printer_service.dart` - "VYAMIT AI" header on printed bills
- ✅ `snapbill_frontend/lib/services/printer_service.dart` - "Powered by Vyamit AI" footer
- ✅ `snapbill_frontend/lib/screens/bill_share_modal.dart` - "VYAMIT AI RECEIPT" in WhatsApp messages
- ✅ `snapbill_frontend/lib/screens/bill_share_modal.dart` - "Powered by Vyamit AI" in messages
- ✅ `snapbill_frontend/lib/screens/auth_selection_screen.dart` - "Welcome to Vyamit AI"
- ✅ `snapbill_frontend/android/app/src/main/AndroidManifest.xml` - Android app label
- ✅ `snapbill_frontend/ios/Runner/Info.plist` - iOS app display name

### 2. App Icon - MANUAL STEPS REQUIRED

You provided two icon images:
1. **Old icon**: Green shop/store icon (to be replaced)
2. **New icon**: Modern geometric logo with lime green and black shapes

#### Steps to Change Icon:

1. **Save the new icon image**:
   - Save your new icon (the geometric lime/black logo) as: `snapbill_frontend/assets/vyamit_icon.png`
   - Recommended size: 1024x1024 pixels (square)
   - Format: PNG with transparent background (if possible)

2. **Update pubspec.yaml**:
   ```yaml
   flutter_launcher_icons:
     android: "ic_launcher"
     ios: true
     image_path: "assets/vyamit_icon.png"  # Changed from mykiranaicon.png
     min_sdk_android: 21
     web:
       generate: true
       image_path: "assets/vyamit_icon.png"
       background_color: "#E8F5E9"
       theme_color: "#C6E377"  # Lime green from your logo
     windows:
       generate: true
       image_path: "assets/vyamit_icon.png"
       icon_size: 48
     macos:
       generate: true
       image_path: "assets/vyamit_icon.png"
   ```

3. **Generate new icons**:
   ```bash
   cd snapbill_frontend
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

### 3. Alternative: Quick Icon Update

If you want to keep the same filename:

1. **Replace the existing icon**:
   - Delete: `snapbill_frontend/assets/mykiranaicon.png`
   - Save your new icon as: `snapbill_frontend/assets/mykiranaicon.png`
   - Size: 1024x1024 pixels

2. **Regenerate icons**:
   ```bash
   cd snapbill_frontend
   flutter pub run flutter_launcher_icons
   flutter clean
   flutter run
   ```

### 4. Verify Changes

After rebuilding, check:
- ✅ App icon on home screen shows new logo
- ✅ App name shows "Vyamit AI" (not "Snapbill")
- ✅ Printed bills show "VYAMIT AI" header
- ✅ WhatsApp messages show "VYAMIT AI RECEIPT"
- ✅ Welcome screen shows "Welcome to Vyamit AI"

## 🎨 Icon Design Notes

Your new icon has:
- **Colors**: Lime green (#C6E377) and black (#1A1A1A)
- **Style**: Modern, geometric, abstract
- **Shape**: Four trapezoid shapes forming a square pattern

This is much more modern than the old shop icon!

## 📝 Additional Files to Check

If you want to search for any remaining "SnapBill" references:
```bash
cd snapbill_frontend
grep -r "SnapBill" lib/
grep -r "Snapbill" lib/
grep -r "snapbill" lib/
```

## 🚀 Final Steps

1. Save new icon as `assets/vyamit_icon.png` (1024x1024)
2. Update `pubspec.yaml` image_path (or replace existing file)
3. Run: `flutter pub run flutter_launcher_icons`
4. Run: `flutter clean && flutter pub get`
5. Run: `flutter run`

Done! Your app is now "Vyamit AI" with the new modern logo! 🎉
