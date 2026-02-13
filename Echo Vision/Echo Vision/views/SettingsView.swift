import SwiftUI

struct SettingsView: View {
    @AppStorage("speechRate") private var speechRate: Double = 0.5
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("announceDistance") private var announceDistance = true
    
    var body: some View {
        NavigationView {
            List {
                Section("Audio") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Speech Rate")
                            .font(.headline)
                        
                        HStack {
                            Text("Slow")
                                .font(.caption)
                            
                            Slider(value: $speechRate, in: 0.3...0.7)
                                .accessibilityLabel("Speech rate slider")
                            
                            Text("Fast")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Toggle("Announce Distance", isOn: $announceDistance)
                }
                
                Section("Haptics") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        .accessibilityHint("Vibrate when detecting hazards")
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Support", destination: URL(string: "https://example.com/support")!)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
