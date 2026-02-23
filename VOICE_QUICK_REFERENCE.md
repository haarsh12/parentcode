# Premium Voice System - Quick Reference

## Quick Start

### Initialize Service
```dart
final voiceService = PremiumVoiceService();
await voiceService.initialize();

voiceService.setContext(
  inventory: inventoryList,
  userId: userId,
);
```

### Use Voice Orb
```dart
PremiumVoiceOrb(
  isActive: voiceService.isActive,
  isProcessing: voiceService.isProcessing,
  audioLevel: voiceService.audioLevel,
  onTap: () => voiceService.isActive 
    ? voiceService.stopListening() 
    : voiceService.startListening(),
)
```

### Handle Callbacks
```dart
voiceService.onBillUpdate = (updates) {
  // Add items to bill
};

voiceService.onResponse = (response) {
  // Show AI response
};
```

## Key Properties

### PremiumVoiceService

| Property | Type | Description |
|----------|------|-------------|
| `isActive` | `bool` | Is currently listening |
| `isProcessing` | `bool` | Is processing transcript |
| `isSpeaking` | `bool` | Is speaking response (TTS) |
| `audioLevel` | `double` | Current audio level (0.0-1.0) |
| `liveTranscript` | `String` | Current speech chunk |
| `fullTranscript` | `String` | Accumulated + live text |

### PremiumVoiceOrb

| Property | Type | Description |
|----------|------|-------------|
| `isActive` | `bool` | Show active state |
| `isProcessing` | `bool` | Show processing state |
| `audioLevel` | `double` | Audio level for animation |
| `onTap` | `VoidCallback` | Tap handler |
| `size` | `double` | Orb size (default: 140) |

## Methods

### PremiumVoiceService

```dart
// Initialize
await voiceService.initialize();

// Set context
voiceService.setContext(inventory: [...], userId: 1);

// Start listening
await voiceService.startListening();

// Stop listening
await voiceService.stopListening();

// Listen to changes
voiceService.addListener(() { /* ... */ });
voiceService.removeListener(callback);
```

## Backend Endpoints

### Process Query
```http
POST /voice/process-query
Content-Type: application/json

{
  "transcript": "200 Rs ka chawal kitna?",
  "user_id": 1,
  "inventory": [...]
}
```

Response:
```json
{
  "success": true,
  "answer": "Chawal ka price hai 50 rupaye per kg",
  "continue_listening": false,
  "mode": "query"
}
```

### Process Billing
```http
POST /voice/process-billing
Content-Type: application/json

{
  "transcript": "2 kg chawal aur 1 kg dal",
  "user_id": 1,
  "inventory": [...]
}
```

Response:
```json
{
  "success": true,
  "bill_updates": [
    {
      "name": "Chawal",
      "quantity": 2.0,
      "unit": "kg",
      "price": 50.0,
      "total": 100.0
    }
  ]
}
```

## Configuration Constants

```dart
// In premium_voice_service.dart
static const int silenceTimeoutSeconds = 40;
static const int audioLevelDecayMs = 100;

// In premium_voice_orb.dart
duration: const Duration(milliseconds: 2000),  // Breathing
duration: const Duration(milliseconds: 1200),  // Pulse
duration: const Duration(seconds: 8),          // Rotation
```

## Color Scheme

| State | Color | Hex |
|-------|-------|-----|
| Idle | Gray | `#E0E0E0` |
| Active | Green | `#4CAF50` |
| Processing | Blue | `#2196F3` |

## Common Patterns

### Full Screen Implementation
```dart
class MyVoiceScreen extends StatefulWidget {
  @override
  State<MyVoiceScreen> createState() => _MyVoiceScreenState();
}

class _MyVoiceScreenState extends State<MyVoiceScreen> {
  late PremiumVoiceService _voiceService;

  @override
  void initState() {
    super.initState();
    _voiceService = PremiumVoiceService();
    _voiceService.initialize();
    _voiceService.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onUpdate);
    _voiceService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PremiumVoiceOrb(
          isActive: _voiceService.isActive,
          isProcessing: _voiceService.isProcessing,
          audioLevel: _voiceService.audioLevel,
          onTap: _toggleVoice,
        ),
      ),
    );
  }

  void _toggleVoice() {
    if (_voiceService.isActive) {
      _voiceService.stopListening();
    } else {
      _voiceService.startListening();
    }
  }
}
```

### Modal Implementation
```dart
void showVoiceModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PremiumVoiceScreen(),
  );
}
```

### Floating Button Implementation
```dart
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PremiumVoiceScreen()),
    );
  },
  child: Icon(Icons.mic),
)
```

## Debugging

### Enable Verbose Logging
```dart
// In premium_voice_service.dart
debugPrint('🎙️ Listening started');
debugPrint('📝 Accumulated: $_accumulatedText');
debugPrint('❓ Processing query: $query');
debugPrint('📤 Sending on timeout: $text');
```

### Check State
```dart
print('Active: ${voiceService.isActive}');
print('Processing: ${voiceService.isProcessing}');
print('Audio Level: ${voiceService.audioLevel}');
print('Transcript: ${voiceService.fullTranscript}');
```

### Monitor Backend
```bash
# Watch backend logs
cd mykirana_backend
tail -f logs/app.log

# Test endpoint
curl -X POST http://localhost:8000/voice/process-query \
  -H "Content-Type: application/json" \
  -d '{"transcript":"test","user_id":1,"inventory":[]}'
```

## Performance Tips

1. **Reuse Service**: Use singleton pattern (already implemented)
2. **Dispose Properly**: Always call `removeListener()` and `stopListening()`
3. **Batch Updates**: Use `notifyListeners()` sparingly
4. **Optimize Animations**: Reduce complexity if needed
5. **Cache Inventory**: Don't fetch on every request

## Common Issues

| Issue | Solution |
|-------|----------|
| No microphone permission | Check AndroidManifest.xml / Info.plist |
| Voice stops after 30s | Check auto-restart logs |
| Poor performance | Reduce animation complexity |
| Backend errors | Check AI service configuration |
| No audio feedback | This is intentional (silent mode) |

## Testing Checklist

- [ ] Tap to start listening
- [ ] Speak for 60+ seconds continuously
- [ ] Wait 40 seconds for timeout
- [ ] Ask a question (auto-stop)
- [ ] Add billing items
- [ ] Check animations are smooth
- [ ] Verify no audio feedback
- [ ] Test manual stop
- [ ] Test error recovery
- [ ] Test on different devices

## Resources

- Full Documentation: `PREMIUM_VOICE_SYSTEM.md`
- Migration Guide: `VOICE_MIGRATION_GUIDE.md`
- Source Code: `lib/services/premium_voice_service.dart`
- Widget Code: `lib/widgets/premium_voice_orb.dart`
- Screen Code: `lib/screens/premium_voice_screen.dart`
- Backend Code: `app/api/voice.py`
