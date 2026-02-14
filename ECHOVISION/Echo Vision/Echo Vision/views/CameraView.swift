import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDetections = true
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewLayer(session: viewModel.captureSession)
                .ignoresSafeArea()
            
            // Camera guidance overlay (top indicators)
            VStack {
                HStack(spacing: 12) {
                    // Stability indicator
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
                    
                    // Lighting indicator
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
                }
                .padding(.top, 60)
                
                Spacer()
            }
            
            // Main UI overlay
            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .shadow(radius: 3)
                    }
                    .accessibilityLabel("Close camera")
                    
                    Spacer()
                    
                    // Scene indicator
                    if !viewModel.currentScene.isEmpty {
                        Text(viewModel.currentScene.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingDetections.toggle() }) {
                        Image(systemName: showingDetections ? "eye.fill" : "eye.slash.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .shadow(radius: 3)
                    }
                    .accessibilityLabel("Toggle detection overlay")
                }
                .padding()
                
                Spacer()
                
                // Detection overlay
                if showingDetections && !viewModel.detections.isEmpty {
                    DetectionOverlay(detections: viewModel.detections.filter { $0.label != "background" })
                        .padding()
                }
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: 16) {
                    // Detection count
                    let validCount = viewModel.detections.filter { $0.label != "background" }.count
                    if validCount > 0 {
                        Text("\(validCount) object\(validCount == 1 ? "" : "s") detected")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.6))
                            .cornerRadius(20)
                    }
                    
                    // Announce button
                    Button(action: {
                        print("🔘 BUTTON TAPPED!")
                        viewModel.announceDetections()
                        
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 60))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue)
                                .shadow(color: .black.opacity(0.3), radius: 10)
                            
                            Text("Announce")
                                .font(.callout.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
    
    // MARK: - Computed Properties (moved outside body)
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

// MARK: - Camera Preview
struct CameraPreviewLayer: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.session = session
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update if needed
    }
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

// MARK: - Detection Overlay
struct DetectionOverlay: View {
    let detections: [DetectionResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(detections.prefix(5)) { detection in
                HStack {
                    // Direction indicator
                    Image(systemName: directionIcon(for: detection.direction))
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(detection.label)
                            .font(.headline)
                        
                        Text("\(Int(detection.confidence * 100))% confident")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Hazard warning
                    if ["Stairs", "Knife", "Ladder"].contains(detection.label) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
    }
    
    private func directionIcon(for direction: DetectionResult.Direction) -> String {
        switch direction {
        case .left: return "arrow.left.circle.fill"
        case .center: return "circle.fill"
        case .right: return "arrow.right.circle.fill"
        }
    }
}
