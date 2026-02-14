import AVFoundation
import Combine
import SwiftUI

class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    // AppStorage for speech rate (synced with SettingsView)
    @AppStorage("speechRate") private var storedSpeechRate: Double = 0.5
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
            print("✅ Audio session configured")
        } catch {
            print("❌ Audio session error: \(error)")
        }
    }
    
    func speak(_ text: String, pan: Float = 0.0, priority: Priority = .normal) {
        print("🔊 SPEAK CALLED: '\(text)'")
        print("🎚️ Speech rate: \(storedSpeechRate)")
        
        if priority == .critical {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Use the rate from settings (0.3 to 0.7 range)
        // AVSpeechUtterance rate: 0.0 = very slow, 0.5 = normal, 1.0 = very fast
        utterance.rate = Float(storedSpeechRate)
        utterance.volume = 1.0
        
        DispatchQueue.main.async {
            print("🎤 Starting synthesizer with rate: \(utterance.rate)")
            self.synthesizer.speak(utterance)
        }
    }
    
    func stop() {
        print("⏹️ Stopping speech")
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    enum Priority {
        case low, normal, high, critical
    }
}

extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("✅ Speech ACTUALLY started: '\(utterance.speechString)' at rate \(utterance.rate)")
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("✅ Speech finished")
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
