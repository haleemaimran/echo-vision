import SwiftUI

struct HomeView: View {
    @State private var showCamera = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App icon
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityLabel("EchoVision logo")
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("EchoVision")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                        
                        Text("Navigate the world through sound")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .combine)
                    
                    Spacer()
                    
                    // Main action button
                    Button(action: {
                        showCamera = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            
                            Text("Start Exploring")
                                .font(.title3.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 32)
                    .accessibilityHint("Tap to open camera and start detecting objects")
                    
                    // Quick actions
                    HStack(spacing: 20) {
                        QuickActionButton(
                            icon: "camera.metering.multispot",
                            title: "Scan",
                            action: { showCamera = true }
                        )
                        
                        QuickActionButton(
                            icon: "mappin.and.ellipse",
                            title: "Remember",
                            action: { /* TODO */ }
                        )
                        
                        QuickActionButton(
                            icon: "book.fill",
                            title: "Read Text",
                            action: { /* TODO */ }
                        )
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showCamera) {
                CameraView()
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .foregroundColor(.primary)
        .accessibilityLabel(title)
    }
}
