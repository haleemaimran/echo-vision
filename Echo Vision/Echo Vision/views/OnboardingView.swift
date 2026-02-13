
import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "waveform.circle.fill",
                        title: "Welcome to EchoVision",
                        description: "Navigate the world through sound and haptics"
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "camera.fill",
                        title: "Point and Listen",
                        description: "Point your camera and tap to hear what's around you"
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "exclamationmark.triangle.fill",
                        title: "Stay Safe",
                        description: "Get instant alerts for stairs, obstacles, and hazards"
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                Button(action: {
                    if currentPage < 2 {
                        currentPage += 1
                    } else {
                        hasCompletedOnboarding = true
                    }
                }) {
                    Text(currentPage < 2 ? "Continue" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}
