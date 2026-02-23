package com.example.snapbill_frontend

import android.content.Context
import android.media.AudioManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.snapbill/audio"
    private var audioManager: AudioManager? = null
    private var originalNotificationVolume: Int = 0
    private var originalSystemVolume: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        
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
        try {
            audioManager?.let { am ->
                // Save original volumes
                originalNotificationVolume = am.getStreamVolume(AudioManager.STREAM_NOTIFICATION)
                originalSystemVolume = am.getStreamVolume(AudioManager.STREAM_SYSTEM)
                
                // Mute notification sounds (speech recognition beeps use this stream)
                am.setStreamVolume(
                    AudioManager.STREAM_NOTIFICATION,
                    0,
                    0  // No flags - silent change
                )
                
                // Mute system sounds
                am.setStreamVolume(
                    AudioManager.STREAM_SYSTEM,
                    0,
                    0  // No flags - silent change
                )
                
                android.util.Log.d("VoiceService", "🔇 System sounds MUTED")
            }
        } catch (e: Exception) {
            android.util.Log.e("VoiceService", "❌ Failed to mute: ${e.message}")
        }
    }

    private fun unmuteSystemSounds() {
        try {
            audioManager?.let { am ->
                // Restore original volumes
                am.setStreamVolume(
                    AudioManager.STREAM_NOTIFICATION,
                    originalNotificationVolume,
                    0  // No flags - silent change
                )
                
                am.setStreamVolume(
                    AudioManager.STREAM_SYSTEM,
                    originalSystemVolume,
                    0  // No flags - silent change
                )
                
                android.util.Log.d("VoiceService", "🔊 System sounds UNMUTED")
            }
        } catch (e: Exception) {
            android.util.Log.e("VoiceService", "❌ Failed to unmute: ${e.message}")
        }
    }
}

