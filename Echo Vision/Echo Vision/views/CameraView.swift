import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDetections = true
    @State private var showAutoAnnounceIndicator = false
    
    var body: some View {
        ZStack {
            CameraPreviewLayer(session: viewModel.captureSession)
                .ignoresSafeArea()
            
            // Camera guidance overlay
            VStack {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: viewModel.isCameraStable ? "camera.fill" : "camera.shutter.button")
                            .foregroundColor(viewModel.isCameraStable ? .green : .orange)
                        
                        Text(viewModel.isCameraStable ? "Stable" : "Hold Still")
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    HStack(spacing: 4) {
                        Image(systemName: lightingIcon)
                            .foregroundColor(lightingColor)
                        
                        Text(lightingText)
                            .font(.caption2.weight(.medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    // Auto-announce indicator
                    if showAutoAnnounceIndicator {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.blue)
                            
                            Text("Auto")
                                .font(.caption2.weight(.medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .transition(.scale)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
            }
            
            // Main UI overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .shadow(radius: 3)
                    }
                    .accessibilityLabel("Close camera")
                    
                    Spacer()
                    
                    if !viewModel.currentScene.isEmpty {
                        Text(viewModel.currentScene.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingDetections.toggle()
                        }
                    }) {
                        Image(systemName: showingDetections ? "eye.fill" : "eye.slash.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .shadow(radius: 3)
                    }
                    .accessibilityLabel("Toggle detection overlay")
                }
                .padding()
                
                Spacer()
                
                // Enhanced detection overlay
                if showingDetections && !viewModel.detections.isEmpty {
                    EnhancedDetectionOverlay(detections: deduplicatedDetections)
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    let validCount = deduplicatedDetections.count
                    if validCount > 0 {
                        HStack(spacing: 12) {
                            Text("\(validCount) object\(validCount == 1 ? "" : "s")")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white)
                            
                            // Category breakdown
                            if hasHazards {
                                Label("Hazard", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                    
                    HStack(spacing: 20) {
                        // Manual announce button
                        Button(action: {
                            print("🔘 BUTTON TAPPED!")
                            viewModel.announceDetections()
                            
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "speaker.wave.3.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 10)
                                
                                Text("Announce Now")
                                    .font(.callout.weight(.semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Announce detected objects")
                        .accessibilityHint("Tap to hear what's in view")
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.startSession()
            
            // Show auto-announce indicator briefly
            withAnimation {
                showAutoAnnounceIndicator = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showAutoAnnounceIndicator = false
                }
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
    
    // Deduplicate detections for display
    private var deduplicatedDetections: [DetectionResult] {
        var seen: Set<String> = []
        return viewModel.detections.filter { detection in
            guard detection.label != "background" else { return false }
            
            let key = detection.label
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
    
    private var hasHazards: Bool {
        let hazards = ["Stairs", "Knife", "Ladder", "stairs", "knife", "ladder"]
        return deduplicatedDetections.contains { hazards.contains($0.label) }
    }
    
    private var lightingIcon: String {
        switch viewModel.lightingQuality {
        case .good: return "sun.max.fill"
        case .dim: return "sun.min"
        case .tooDark: return "moon.fill"
        }
    }
    
    private var lightingColor: Color {
        switch viewModel.lightingQuality {
        case .good: return .green
        case .dim: return .yellow
        case .tooDark: return .red
        }
    }
    
    private var lightingText: String {
        switch viewModel.lightingQuality {
        case .good: return "Good Light"
        case .dim: return "Dim"
        case .tooDark: return "Too Dark"
        }
    }
}

struct EnhancedDetectionOverlay: View {
    let detections: [DetectionResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(detections.prefix(5).enumerated()), id: \.element.id) { index, detection in
                DetectionCard(detection: detection, index: index)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
    }
}

struct DetectionCard: View {
    let detection: DetectionResult
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Direction indicator
            ZStack {
                Circle()
                    .fill(directionColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: directionIcon)
                    .font(.title3)
                    .foregroundColor(directionColor)
            }
            
            // Object info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(cleanLabel)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if isHazard {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(detection.direction.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(Int(detection.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isHazard ? Color.red : Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
    
    private var cleanLabel: String {
        detection.label
            .replacingOccurrences(of: "my_", with: "Your ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    private var isHazard: Bool {
        let hazards = ["Stairs", "Knife", "Ladder", "stairs", "knife", "ladder"]
        return hazards.contains(detection.label)
    }
    
    private var directionIcon: String {
        switch detection.direction {
        case .left: return "arrow.left"
        case .center: return "circle.fill"
        case .right: return "arrow.right"
        }
    }
    
    private var directionColor: Color {
        if isHazard {
            return .red
        }
        switch detection.direction {
        case .left: return .blue
        case .center: return .green
        case .right: return .orange
        }
    }
}

struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {}
}

class CameraPreviewUIView: UIView {
    var session: AVCaptureSession? {
        didSet {
            guard let session = session else { return }
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}

#Preview {
    CameraView()
}
