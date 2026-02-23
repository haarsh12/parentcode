import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // 1. ANDROID EMULATOR (Standard IP)
  static const String _emulatorUrl = "http://10.0.2.2:8000";

  // 2. REAL PHYSICAL DEVICE (Your Correct IP)
  static const String _realDeviceUrl = "http://10.84.59.207:8000";

  static String get baseUrl {
    if (kReleaseMode) {
      return "https://api.yourdomain.com"; // Future AWS URL
    }

    if (Platform.isAndroid) {
      // UNCOMMENT the line below if using your REAL PHONE connected via USB/WiFi
      return _realDeviceUrl;

      // UNCOMMENT the line below if using the ANDROID EMULATOR on screen
      // return _emulatorUrl;
    }

    // Web/Windows default
    return "http://localhost:8000";
  }
}
