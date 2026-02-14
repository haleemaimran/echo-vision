import SwiftUI

struct HomeView: View {
    @State private var showCamera = false
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient Background
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.5, blue: 1.0),
                        Color(red: 0.3, green: 0.2, blue: 0.8),
                        Color(red: 0.1, green: 0.1, blue: 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated gradient orbs
                GeometryReader { geometry in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.4), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(x: -100, y: isAnimating ? -50 : 50)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.purple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(x: geometry.size.width - 150, y: isAnimating ? geometry.size.height - 100 : geometry.size.height - 200)
                        .blur(radius: 50)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Section
                        VStack(spacing: 24) {
                            Spacer()
                                .frame(height: 80)
                            
                            // App Icon with glow effect
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                    .blur(radius: 20)
                                
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 110, height: 110)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.6), .white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    }
                                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                                
                                Image(systemName: "waveform")
                                    .font(.system(size: 56, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .accessibilityLabel("EchoVision logo")
                            
                            // App Name and Tagline
                            VStack(spacing: 12) {
                                Text("EchoVision")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.9)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                
                                Text("See the world through sound")
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                                .frame(height: 60)
                            
                            // CTA Button
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                showCamera = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                    
                                    Text("Start Exploring")
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
                                        colors: [Color(red: 0.0, green: 0.5, blue: 1.0), Color(red: 0.3, green: 0.2, blue: 0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                            }
                            .padding(.horizontal, 32)
                            .accessibilityHint("Tap to open camera")
                            
                            Spacer()
                                .frame(height: 80)
                        }
                        
                        // Features Grid
                        VStack(spacing: 20) {
                            Text("Features")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 32)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                FeatureCard(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Hazard Detection",
                                    description: "Real-time safety alerts",
                                    gradient: [Color.red.opacity(0.8), Color.orange.opacity(0.6)]
                                )
                                
                                FeatureCard(
                                    icon: "eye.fill",
                                    title: "Object Recognition",
                                    description: "Identify surroundings",
                                    gradient: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)]
                                )
                                
                                FeatureCard(
                                    icon: "building.2.fill",
                                    title: "Scene Understanding",
                                    description: "Know your environment",
                                    gradient: [Color.green.opacity(0.8), Color.mint.opacity(0.6)]
                                )
                                
                                FeatureCard(
                                    icon: "waveform",
                                    title: "Spatial Audio",
                                    description: "Hear object locations",
                                    gradient: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)]
                                )
                            }
                            .padding(.horizontal, 32)
                        }
                        .padding(.bottom, 60)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon container
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: gradient[0].opacity(0.4), radius: 12, y: 6)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeView()
}
