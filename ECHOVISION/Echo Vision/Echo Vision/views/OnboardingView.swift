import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 1.5), value: currentPage)
            
            // Animated background orbs
            GeometryReader { geometry in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [backgroundOrbColor.opacity(0.5), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 250
                        )
                    )
                    .frame(width: 500, height: 500)
                    .offset(
                        x: isAnimating ? -100 : -200,
                        y: isAnimating ? 0 : 100
                    )
                    .blur(radius: 80)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [backgroundOrbColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(
                        x: geometry.size.width - (isAnimating ? 150 : 100),
                        y: geometry.size.height - (isAnimating ? 200 : 100)
                    )
                    .blur(radius: 60)
            }
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "waveform",
                        title: "Welcome to\nEchoVision",
                        description: "Experience the world through intelligent audio guidance and real-time object detection",
                        accentColor: Color.blue
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "hand.point.up.left.fill",
                        title: "Point\n& Listen",
                        description: "Simply aim your camera and tap to hear detailed descriptions with spatial audio",
                        accentColor: Color.purple
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "shield.lefthalf.filled",
                        title: "Stay\nProtected",
                        description: "Advanced AI prioritizes hazards to keep you safe and informed at all times",
                        accentColor: Color.green
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)
                
                // Continue/Get Started Button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    
                    if currentPage < 2 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Text(currentPage < 2 ? "Continue" : "Get Started")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Image(systemName: currentPage < 2 ? "arrow.right" : "checkmark")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white)
                            
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.3), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: buttonGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                
                // Skip button (only on first two pages)
                if currentPage < 2 {
                    Button(action: {
                        withAnimation {
                            hasCompletedOnboarding = true
                        }
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    // Dynamic colors based on current page
    private var gradientColors: [Color] {
        switch currentPage {
        case 0:
            return [
                Color(red: 0.0, green: 0.5, blue: 1.0),
                Color(red: 0.3, green: 0.3, blue: 0.9),
                Color(red: 0.1, green: 0.1, blue: 0.4)
            ]
        case 1:
            return [
                Color(red: 0.5, green: 0.2, blue: 1.0),
                Color(red: 0.4, green: 0.3, blue: 0.8),
                Color(red: 0.2, green: 0.1, blue: 0.4)
            ]
        case 2:
            return [
                Color(red: 0.0, green: 0.8, blue: 0.6),
                Color(red: 0.2, green: 0.6, blue: 0.8),
                Color(red: 0.1, green: 0.3, blue: 0.4)
            ]
        default:
            return [.blue, .purple, .indigo]
        }
    }
    
    private var backgroundOrbColor: Color {
        switch currentPage {
        case 0: return .blue
        case 1: return .purple
        case 2: return .green
        default: return .blue
        }
    }
    
    private var buttonGradient: [Color] {
        switch currentPage {
        case 0: return [Color(red: 0.0, green: 0.5, blue: 1.0), Color(red: 0.3, green: 0.2, blue: 0.8)]
        case 1: return [Color(red: 0.5, green: 0.2, blue: 1.0), Color(red: 0.8, green: 0.2, blue: 0.6)]
        case 2: return [Color(red: 0.0, green: 0.8, blue: 0.6), Color(red: 0.2, green: 0.6, blue: 0.9)]
        default: return [.blue, .purple]
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    
    @State private var iconScale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon with glassmorphic container
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                // Glass container
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: .black.opacity(0.15), radius: 30, y: 15)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(iconScale)
            }
            .accessibilityHidden(true)
            
            // Text content
            VStack(spacing: 20) {
                Text(title)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                Text(description)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                iconScale = 1.0
            }
            
            // Subtle breathing animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                iconScale = 1.05
            }
        }
    }
}

#Preview {
    OnboardingView()
}
