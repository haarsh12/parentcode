import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // 🚀 PRODUCTION - Render Backend
  static const String _productionUrl = "https://parentcode-backend.onrender.com";

  // 🧪 LOCAL DEVELOPMENT URLs (for testing)
  static const String _emulatorUrl = "http://10.0.2.2:8000";
  static const String _realDeviceUrl = "http://10.28.43.207:8000";
  static const String _localUrl = "http://localhost:8000";

  static String get baseUrl {
    // ✅ ALWAYS USE PRODUCTION (Render) - Comment this line to use local
    return _productionUrl;

    // 🧪 DEVELOPMENT MODE - Uncomment below for local testing
    /*
    if (kReleaseMode) {
      return _productionUrl;
    }

    if (Platform.isAndroid) {
      return _realDeviceUrl;  // Real phone
      // return _emulatorUrl;  // Emulator
    }

    return _localUrl;  // Web/Windows
    */
  }
}
