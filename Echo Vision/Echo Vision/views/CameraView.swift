import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingDetections = true
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(previewLayer: viewModel.previewLayer)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .accessibilityLabel("Close camera")
                    
                    Spacer()
                    
                    // Scene indicator
                    if !viewModel.currentScene.isEmpty {
                        Text(viewModel.currentScene)
                            .font(.caption.weight(.medium))
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
                    }
                    .accessibilityLabel("Toggle detection overlay")
                }
                .padding()
                
                Spacer()
                
                // Detection overlay
                if showingDetections {
                    DetectionOverlay(detections: viewModel.detections)
                        .padding()
                }
                
                // Bottom controls
                HStack(spacing: 40) {
                    // Scan button
                    Button(action: {
                        viewModel.announceDetections()
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 60))
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue)
                            
                            Text("Announce")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Announce detected objects")
                    .accessibilityHint("Double tap to hear what's around you")
                }
                .padding(.bottom, 40)
            }
            
            // Processing indicator
            if viewModel.isProcessing {
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.black.opacity(0.2))
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

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
