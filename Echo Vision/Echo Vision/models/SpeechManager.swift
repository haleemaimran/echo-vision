import AVFoundation
import Combine

class SpeechManager: NSObject, ObservableObject {
    static let shared = SpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    private override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String, pan: Float = 0.0, priority: Priority = .normal) {
        // Stop current speech if high priority
        if priority == .critical {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    enum Priority {
        case low, normal, high, critical
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension SpeechManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
    }
}
