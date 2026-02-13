import SwiftUI
import AVFoundation
import Vision
import Combine

class CameraViewModel: NSObject, ObservableObject {
    @Published var detections: [DetectionResult] = []
    @Published var currentScene: String = ""
    @Published var isProcessing = false
    
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let mlModels = MLModels.shared
    private let speechManager = SpeechManager.shared
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
        }
    }
    
    func announceDetections() {
        guard !detections.isEmpty else {
            speechManager.speak("No objects detected")
            return
        }
        
        // Priority: Hazards first
        let hazards = detections.filter { ["Stairs", "Knife", "Ladder"].contains($0.label) }
        
        if !hazards.isEmpty {
            for hazard in hazards {
                speechManager.speak("Warning: \(hazard.description)", priority: .critical)
            }
        } else {
            // Announce top 3 objects
            for detection in detections.prefix(3) {
                let pan: Float = detection.direction == .left ? -0.7 : (detection.direction == .right ? 0.7 : 0.0)
                speechManager.speak(detection.description, pan: pan)
            }
        }
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isProcessing,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        // Detect hazards first (priority)
        mlModels.detectHazards(in: pixelBuffer) { hazards in
            if !hazards.isEmpty {
                DispatchQueue.main.async {
                    self.detections = hazards
                    self.isProcessing = false
                }
                return
            }
            
            // If no hazards, detect general objects
            self.mlModels.detectObjects(in: pixelBuffer) { objects in
                // Also classify scene
                self.mlModels.classifyScene(in: pixelBuffer) { scene in
                    DispatchQueue.main.async {
                        self.detections = objects
                        self.currentScene = scene ?? "Unknown"
                        self.isProcessing = false
                    }
                }
            }
        }
    }
}
