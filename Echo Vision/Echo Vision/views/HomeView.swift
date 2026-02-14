import SwiftUI

struct HomeView: View {
    @State private var showCamera = false
    @State private var isAnimating = false
    @State private var buttonPulse = false  // For button pulse animation
    @State private var buttonVisible = false  // For initial fade-in
    
    // Accessibility settings
    @AppStorage("largeTextMode") private var largeTextMode = false
    @AppStorage("highContrastMode") private var highContrastMode = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background with dynamic gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                // Animated orbs
                animatedOrbs
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Section
                        VStack(spacing: 24) {
                            Spacer()
                                .frame(height: 60)  // Reduced from 80
                            
                            // App Icon
                            appIconView
                            
                            // App Name and Tagline
                            VStack(spacing: 12) {
                                Text("EchoVision")
                                    .font(largeTextMode ? .system(size: 56, weight: .bold, design: .rounded) : .system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(textGradient)
                                
                                Text("Navigate indoor spaces safely")
                                    .font(largeTextMode ? .title2 : .title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(secondaryTextColor)
                            }
                            
                            Spacer()
                                .frame(height: 40)  // Reduced from 60
                            
                            // CTA Button
                            ctaButton
                            
                            Spacer()
                                .frame(height: 50)  // Reduced from 80
                        }
                        
                        // Features Grid
                        VStack(spacing: 20) {
                            Text("Features")
                                .font(largeTextMode ? .title : .title2)
                                .fontWeight(.semibold)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 32)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                FeatureCard(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Hazard Alerts",
                                    gradient: highContrastMode ? [Color.red, Color.red.opacity(0.8)] : [Color.red.opacity(0.8), Color.orange.opacity(0.6)],
                                    largeText: largeTextMode,
                                    highContrast: highContrastMode
                                )
                                
                                FeatureCard(
                                    icon: "eye.fill",
                                    title: "Object Detection",
                                    gradient: highContrastMode ? [Color.blue, Color.blue.opacity(0.8)] : [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                                    largeText: largeTextMode,
                                    highContrast: highContrastMode
                                )
                                
                                FeatureCard(
                                    icon: "building.2.fill",
                                    title: "Scene Context",
                                    gradient: highContrastMode ? [Color.green, Color.green.opacity(0.8)] : [Color.green.opacity(0.8), Color.mint.opacity(0.6)],
                                    largeText: largeTextMode,
                                    highContrast: highContrastMode
                                )
                                
                                FeatureCard(
                                    icon: "waveform",
                                    title: "Spatial Audio",
                                    gradient: highContrastMode ? [Color.purple, Color.purple.opacity(0.8)] : [Color.purple.opacity(0.8), Color.pink.opacity(0.6)],
                                    largeText: largeTextMode,
                                    highContrast: highContrastMode
                                )
                            }
                            .padding(.horizontal, 32)
                        }
                        .padding(.bottom, 40)
                        
                        // Research Credit Section
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "brain.head.profile")
                                    .font(.caption)
                                    .foregroundColor(secondaryTextColor.opacity(0.8))
                                
                                Text("Powered by Computer Vision Research")
                                    .font(largeTextMode ? .footnote : .caption2)
                                    .foregroundColor(secondaryTextColor.opacity(0.8))
                            }
                            
                            Text("Built on YOLOv8 object detection and indoor scene classification")
                                .font(largeTextMode ? .caption : .caption2)
                                .foregroundColor(secondaryTextColor.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 60)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    accessibilityMenu
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView()
            }
            .onAppear {
                // Animated gradient orbs
                withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
                
                // Initial fade-in animation for button
                withAnimation(.easeOut(duration: 0.6)) {
                    buttonVisible = true
                }
                
                // Fast pulse animation - grabs attention
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    buttonPulse = true
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: highContrastMode ? [
                Color.black,
                Color(red: 0.1, green: 0.1, blue: 0.2)
            ] : [
                Color(red: 0.0, green: 0.5, blue: 1.0),
                Color(red: 0.3, green: 0.2, blue: 0.8),
                Color(red: 0.1, green: 0.1, blue: 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var animatedOrbs: some View {
        GeometryReader { geometry in
            if !highContrastMode {
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
        }
    }
    
    private var appIconView: some View {
        ZStack {
            if !highContrastMode {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 150)
                    .blur(radius: 25)
            }
            
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(highContrastMode ? AnyShapeStyle(Color.white) : AnyShapeStyle(.ultraThinMaterial))                .frame(width: 110, height: 110)
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: highContrastMode ? [.black, .black] : [.white.opacity(0.6), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: highContrastMode ? 3 : 1
                        )
                }
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
            
            Image(systemName: "waveform")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: highContrastMode ? [.black, .black] : [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .accessibilityLabel("EchoVision logo")
    }
    
    private var ctaButton: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            showCamera = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(largeTextMode ? .title2 : .title3)
                    .fontWeight(.semibold)
                
                Text("Start Exploring")
                    .font(largeTextMode ? .title3 : .headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: largeTextMode ? 64 : 56)
            .foregroundStyle(buttonForegroundStyle)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(highContrastMode ? Color.yellow : .white)
                    
                    if !highContrastMode {
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
                .shadow(color: .black.opacity(buttonPulse ? 0.3 : 0.2), radius: buttonPulse ? 25 : 20, y: 10)
                //.scaleEffect(buttonPulse ? 1.08 : 0.98)  // Only background pulses
            }
        }
        .scaleEffect(buttonPulse ? 1.025 : 0.95)  // Only background pulses
        .opacity(buttonVisible ? 1.0 : 0.0)  // Fade in entire button on startup
        .padding(.horizontal, 32)
        .accessibilityHint("Double tap to open camera and start detecting obstacles")
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityMenu: some View {
        Menu {
            Button(action: {
                withAnimation {
                    largeTextMode.toggle()
                }
            }) {
                Label(
                    largeTextMode ? "Normal Text" : "Large Text",
                    systemImage: largeTextMode ? "textformat.size.smaller" : "textformat.size.larger"
                )
            }
            
            Button(action: {
                withAnimation {
                    highContrastMode.toggle()
                }
            }) {
                Label(
                    highContrastMode ? "Normal Colors" : "High Contrast",
                    systemImage: highContrastMode ? "circle.lefthalf.filled" : "circle.lefthalf.striped.horizontal"
                )
            }
        } label: {
            ZStack {
                // Background circle with proper edges
                Circle()
                    .fill(
                        highContrastMode
                        ? Color.black.opacity(0.5)
                        : Color.white.opacity(0.2)
                    )
                    .overlay {
                        Circle()
                            .strokeBorder(
                                highContrastMode
                                ? Color.white.opacity(0.4)
                                : Color.white.opacity(0.3),
                                lineWidth: 1
                            )
                    }
                    .frame(width: 44, height: 44)
                
                // Icon
                Image(systemName: "accessibility")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(
                        highContrastMode
                        ? .white
                        : .indigo.opacity(0.99)
                    )
            }
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .accessibilityLabel("Accessibility settings")
    }
    
    // MARK: - Computed Properties
    
    private var primaryTextColor: Color {
        highContrastMode ? .white : .white
    }
    
    private var secondaryTextColor: Color {
        highContrastMode ? .white.opacity(0.9) : .white.opacity(0.8)
    }
    
    private var textGradient: LinearGradient {
        LinearGradient(
            colors: highContrastMode ? [.white, .white] : [.white, .white.opacity(0.95)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var buttonForegroundStyle: AnyShapeStyle {
        if highContrastMode {
            return AnyShapeStyle(Color.black)
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [Color(red: 0.0, green: 0.5, blue: 1.0), Color(red: 0.3, green: 0.2, blue: 0.8)],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let gradient: [Color]
    let largeText: Bool
    let highContrast: Bool
    
    var body: some View {
        VStack(spacing: 12) {  // Reduced from 16
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
                    .frame(width: 52, height: 52)  // Reduced from 56
                    .shadow(color: gradient[0].opacity(0.4), radius: 12, y: 6)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))  // Reduced from 24
                    .foregroundColor(.white)
            }
            
            // Title only (no description)
            Text(title)
                .font(largeText ? .body : .subheadline)
                .fontWeight(.semibold)
                .foregroundColor(highContrast ? .white : .white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .frame(height: largeText ? 120 : 105)  // Reduced from 140/120
        .padding(.vertical, 8)  // Reduced from 16
        .padding(.horizontal, 8)  // Reduced from 12
        .background {
            if highContrast {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.6))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
            } else {
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
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) feature")
    }
}

#Preview {
    HomeView()
}
