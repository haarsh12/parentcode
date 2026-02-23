import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var audioSession: AVAudioSession?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let audioChannel = FlutterMethodChannel(name: "com.snapbill/audio",
                                                binaryMessenger: controller.binaryMessenger)
        
        audioSession = AVAudioSession.sharedInstance()
        
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
            guard let audioSession = audioSession else { return }
            
            // Configure audio session to suppress system sounds
            try audioSession.setCategory(
                .playAndRecord,
                mode: .default,
                options: [
                    .duckOthers,           // Lower other audio
                    .defaultToSpeaker,     // Use speaker
                    .allowBluetooth,       // Allow bluetooth
                    .mixWithOthers         // Mix with other audio
                ]
            )
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Disable system sounds for speech recognition
            try audioSession.setMode(.voiceChat)
            
            print("🔇 iOS system sounds MUTED")
        } catch {
            print("❌ Could not mute iOS sounds: \(error.localizedDescription)")
        }
    }
    
    private func unmuteSystemSounds() {
        do {
            guard let audioSession = audioSession else { return }
            
            // Restore normal audio session
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            
            print("🔊 iOS system sounds UNMUTED")
        } catch {
            print("❌ Could not unmute iOS sounds: \(error.localizedDescription)")
        }
    }
}
