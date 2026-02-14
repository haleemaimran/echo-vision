import SwiftUI

struct SettingsView: View {
    @AppStorage("speechRate") private var speechRate: Double = 0.5
    @AppStorage("announceDistance") private var announceDistance = true
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("largeTextMode") private var largeTextMode = false
    @AppStorage("highContrastMode") private var highContrastMode = false
    
    // For testing speech
    @State private var testingSpeech = false
    
    var body: some View {
        NavigationView {
            Form {
                // Speech Settings
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Speech Rate")
                                .font(largeTextMode ? .body : .subheadline)
                            
                            Spacer()
                            
                            Text(speechRateLabel)
                                .font(largeTextMode ? .body : .subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $speechRate, in: 0.3...0.7, step: 0.05)
                            .accessibilityLabel("Speech rate")
                            .accessibilityValue(speechRateLabel)
                        
                        HStack {
                            Text("Slower")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Faster")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    // Test Speech Button
                    Button(action: testSpeech) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Test Speech Rate")
                            
                            Spacer()
                            
                            if testingSpeech {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    }
                    .disabled(testingSpeech)
                    
                } header: {
                    Text("Speech")
                        .font(largeTextMode ? .body : .subheadline)
                } footer: {
                    Text("Adjust how fast announcements are spoken. Current: \(speechRateLabel)")
                        .font(largeTextMode ? .footnote : .caption)
                }
                
                // Detection Settings
                Section {
                    Toggle("Announce Distance", isOn: $announceDistance)
                        .font(largeTextMode ? .body : .subheadline)
                    
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        .font(largeTextMode ? .body : .subheadline)
                } header: {
                    Text("Detection")
                        .font(largeTextMode ? .body : .subheadline)
                } footer: {
                    Text("Distance announcements help you know how far objects are. Haptic feedback provides tactile confirmation.")
                        .font(largeTextMode ? .footnote : .caption)
                }
                
                // Accessibility Settings
                Section {
                    Toggle("Large Text", isOn: $largeTextMode)
                        .font(largeTextMode ? .body : .subheadline)
                    
                    Toggle("High Contrast", isOn: $highContrastMode)
                        .font(largeTextMode ? .body : .subheadline)
                } header: {
                    Text("Accessibility")
                        .font(largeTextMode ? .body : .subheadline)
                } footer: {
                    Text("Large text increases font sizes throughout the app. High contrast mode uses colors optimized for colorblindness and low vision.")
                        .font(largeTextMode ? .footnote : .caption)
                }
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                            .font(largeTextMode ? .body : .subheadline)
                        Spacer()
                        Text("1.0.0")
                            .font(largeTextMode ? .body : .subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                                .font(largeTextMode ? .body : .subheadline)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/support")!) {
                        HStack {
                            Text("Support")
                                .font(largeTextMode ? .body : .subheadline)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                        .font(largeTextMode ? .body : .subheadline)
                }
                
                // Reset Section
                Section {
                    Button(role: .destructive, action: resetToDefaults) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                                .font(largeTextMode ? .body : .subheadline)
                        }
                    }
                } header: {
                    Text("Reset")
                        .font(largeTextMode ? .body : .subheadline)
                } footer: {
                    Text("This will reset all settings to their default values.")
                        .font(largeTextMode ? .footnote : .caption)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Computed Properties
    
    private var speechRateLabel: String {
        switch speechRate {
        case 0.3..<0.4:
            return "Very Slow"
        case 0.4..<0.45:
            return "Slow"
        case 0.45..<0.55:
            return "Normal"
        case 0.55..<0.65:
            return "Fast"
        case 0.65...0.7:
            return "Very Fast"
        default:
            return "Normal"
        }
    }
    
    // MARK: - Methods
    
    private func testSpeech() {
        testingSpeech = true
        
        let testText = "This is a test of the speech rate. You can adjust the speed in settings."
        SpeechManager.shared.speak(testText)
        
        // Reset button after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            testingSpeech = false
        }
    }
    
    private func resetToDefaults() {
        withAnimation {
            speechRate = 0.5
            announceDistance = true
            hapticFeedback = true
            largeTextMode = false
            highContrastMode = false
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Announce reset
        SpeechManager.shared.speak("Settings reset to defaults")
    }
}

#Preview {
    SettingsView()
}
