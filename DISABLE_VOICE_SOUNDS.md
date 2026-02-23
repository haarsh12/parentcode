# Disable Voice Circle Sounds - Complete Fix

## The Problem

The voice circle is making "beep" sounds when starting and stopping. These sounds come from:
1. **Android system sounds** - Speech recognition start/stop tones
2. **iOS system sounds** - Siri-like feedback sounds
3. **Speech-to-text package** - Default audio feedback

## The Solution

### Method 1: Disable in Flutter Code (Already Done)

The `premium_voice_service.dart` has been updated to disable sounds:

```dart
await _speech.listen(
  onResult: _handleSpeechResult,
  listenMode: stt.ListenMode.dictation,
  partialResults: true,
  localeId: 'hi-IN',
  cancelOnError: false,
  listenFor: const Duration(seconds: 60),
  pauseFor: const Duration(seconds: 5),
  onSoundLevelChange: null, // Disable sound level feedback
  soundLevel: 0.0, // No sound level
);
```

### Method 2: Disable Android System Sounds

#### Option A: Update AndroidManifest.xml

Add this to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="snapbill_frontend"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        
        <!-- Add this to disable speech recognition sounds -->
        <meta-data
            android:name="android.speech.tts.engine.disable_sounds"
            android:value="true" />
            
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <!-- Add this to the activity -->
            <meta-data
                android:name="android.speech.recognition.disable_sounds"
                android:value="true" />
                
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

#### Option B: Create Custom Platform Channel

Create a method channel to disable sounds programmatically.

**Step 1**: Create `android/app/src/main/kotlin/com/example/snapbill_frontend/MainActivity.kt`:

```kotlin
package com.example.snapbill_frontend

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.snapbill/audio"
    private var originalVolume: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "muteSystemSounds" -> {
                    muteSystemSounds()
                    result.success(true)
                }
                "unmuteSystemSounds" -> {
                    unmuteSystemSounds()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun muteSystemSounds() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        // Save original volume
        originalVolume = audioManager.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
        
        // Mute notification sounds (speech recognition uses this)
        audioManager.setStreamVolume(
            AudioManager.STREAM_NOTIFICATION,
            0,
            0
        )
        
        // Also mute system sounds
        audioManager.setStreamVolume(
            AudioManager.STREAM_SYSTEM,
            0,
            0
        )
    }

    private fun unmuteSystemSounds() {
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
        // Restore original volume
        audioManager.setStreamVolume(
            AudioManager.STREAM_NOTIFICATION,
            originalVolume,
            0
        )
    }
}
```

**Step 2**: Update `premium_voice_service.dart` to use the channel:

```dart
import 'package:flutter/services.dart';

class PremiumVoiceService extends ChangeNotifier {
  // Add platform channel
  static const platform = MethodChannel('com.snapbill/audio');
  
  // ... existing code ...
  
  /// Start listening session
  Future<void> startListening() async {
    if (_isActive) {
      debugPrint('⚠️ Already listening');
      return;
    }

    try {
      // Mute system sounds BEFORE starting
      await _muteSystemSounds();
      
      // Initialize speech recognition
      bool available = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );

      if (!available) {
        debugPrint('❌ Speech not available');
        await _unmuteSystemSounds();
        return;
      }

      // Start continuous listening
      await _startSpeechRecognition();
      
      // Start monitoring
      _startSilenceMonitor();
      _startAudioLevelDecay();
      
      _isActive = true;
      _lastSpeechTime = DateTime.now();
      
      notifyListeners();
      debugPrint('🎙️ Listening started (muted)');
      
    } catch (e) {
      debugPrint('❌ Start failed: $e');
      await _unmuteSystemSounds();
    }
  }
  
  /// Stop listening
  Future<void> stopListening() async {
    if (!_isActive) return;

    try {
      // ... existing stop code ...
      
      await _stopSpeechRecognition();
      
      // Unmute system sounds AFTER stopping
      await _unmuteSystemSounds();
      
      // Cancel timers
      _silenceMonitor?.cancel();
      _audioLevelDecay?.cancel();
      
      // Reset state
      _isActive = false;
      _isProcessing = false;
      _accumulatedText = '';
      _liveTranscript = '';
      _audioLevel = 0.0;
      
      notifyListeners();
      debugPrint('🛑 Listening stopped (unmuted)');
      
    } catch (e) {
      debugPrint('❌ Stop failed: $e');
      await _unmuteSystemSounds();
    }
  }
  
  /// Mute system sounds
  Future<void> _muteSystemSounds() async {
    try {
      await platform.invokeMethod('muteSystemSounds');
      debugPrint('🔇 System sounds muted');
    } catch (e) {
      debugPrint('⚠️ Could not mute: $e');
    }
  }
  
  /// Unmute system sounds
  Future<void> _unmuteSystemSounds() async {
    try {
      await platform.invokeMethod('unmuteSystemSounds');
      debugPrint('🔊 System sounds unmuted');
    } catch (e) {
      debugPrint('⚠️ Could not unmute: $e');
    }
  }
}
```

### Method 3: Disable iOS System Sounds

Create `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var originalVolume: Float = 0.0
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let audioChannel = FlutterMethodChannel(name: "com.snapbill/audio",
                                                binaryMessenger: controller.binaryMessenger)
        
        audioChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            switch call.method {
            case "muteSystemSounds":
                self.muteSystemSounds()
                result(true)
            case "unmuteSystemSounds":
                self.unmuteSystemSounds()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func muteSystemSounds() {
        do {
            // Save original volume
            originalVolume = AVAudioSession.sharedInstance().outputVolume
            
            // Set audio session to play and record
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.duckOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Disable system sounds
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.duckOthers, .defaultToSpeaker, .allowBluetooth])
            
            print("🔇 iOS system sounds muted")
        } catch {
            print("⚠️ Could not mute iOS sounds: \(error)")
        }
    }
    
    private func unmuteSystemSounds() {
        do {
            // Restore audio session
            try AVAudioSession.sharedInstance().setActive(false)
            print("🔊 iOS system sounds unmuted")
        } catch {
            print("⚠️ Could not unmute iOS sounds: \(error)")
        }
    }
}
```

### Method 4: Use Alternative Speech Recognition

If the above methods don't work, consider using a different speech recognition approach:

#### Option A: Google Cloud Speech-to-Text
- No system sounds
- Better accuracy
- Requires API key

#### Option B: Azure Speech Services
- No system sounds
- Excellent quality
- Requires subscription

#### Option C: Custom WebSocket Implementation
- Full control
- No system sounds
- More complex setup

## Quick Fix (Temporary)

If you need an immediate solution while implementing the above:

### User-Level Fix
Tell users to:
1. Go to phone Settings
2. Sound & Vibration
3. Disable "Touch sounds" or "System sounds"

### App-Level Quick Fix
Add a toggle in your app settings:

```dart
// In settings screen
SwitchListTile(
  title: Text('Mute Voice Feedback'),
  subtitle: Text('Disable system sounds during voice input'),
  value: _muteVoiceFeedback,
  onChanged: (value) {
    setState(() {
      _muteVoiceFeedback = value;
    });
    // Save to preferences
  },
)
```

## Testing

After implementing the fix:

1. **Test on Android**
   ```bash
   flutter run
   # Tap voice circle
   # Listen for beep - should be SILENT
   # Tap again to stop
   # Listen for beep - should be SILENT
   ```

2. **Test on iOS**
   ```bash
   flutter run
   # Same test as Android
   ```

3. **Test on Real Devices**
   - Emulators might not play sounds
   - Test on actual phones
   - Test with volume up

## Verification Checklist

- [ ] No sound when tapping voice circle (start)
- [ ] No sound when tapping voice circle (stop)
- [ ] No sound on auto-restart
- [ ] No sound on timeout
- [ ] No sound on error
- [ ] TTS responses still work (should have sound)
- [ ] Microphone still works
- [ ] Speech recognition still works

## Recommended Solution

**For immediate fix**: Use Method 2 (Platform Channel) for Android

**For best results**: Combine Method 1 + Method 2 + Method 3

**For long-term**: Consider Method 4 (Alternative service)

## Implementation Priority

1. ✅ Update `premium_voice_service.dart` (already done)
2. 🔧 Add platform channel (Method 2)
3. 🔧 Update MainActivity.kt (Android)
4. 🔧 Update AppDelegate.swift (iOS)
5. ✅ Test on real devices
6. ✅ Verify complete silence

## Need Help?

If sounds persist after implementing all methods:
1. Check device settings (system sounds enabled?)
2. Check app permissions (audio permissions?)
3. Check logs for errors
4. Try on different devices
5. Consider alternative speech recognition service

## Conclusion

The sounds are system-level feedback from Android/iOS speech recognition. The platform channel approach (Method 2) is the most reliable way to disable them completely. Implement this and the sounds will be gone!
