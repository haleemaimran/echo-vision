import SwiftUI
import AVFoundation
import Vision
import Combine

class CameraViewModel: NSObject, ObservableObject {
    @Published var detections: [DetectionResult] = []
    @Published var currentScene: String = ""
    @Published var isProcessing = false
    @Published var isCameraStable = true
    @Published var lightingQuality: LightingQuality = .good
    
    enum LightingQuality {
        case good, dim, tooDark
    }
    
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let mlModels = MLModels.shared
    private let speechManager = SpeechManager.shared
    
    private var frameCount = 0
    private let processEveryNFrames = 30
    private var lastAnnouncedTime: Date?
    private var lastDetections: [String] = []
    private var previousFrameBrightness: Float = 0
    private var motionMagnitude: Float = 0
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("❌ Camera not available")
            return
        }
        
        // Enable auto-focus and exposure
        do {
            try camera.lockForConfiguration()
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            }
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }
            camera.unlockForConfiguration()
        } catch {
            print("⚠️ Could not configure camera: \(error)")
        }
        
        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        print("✅ Camera setup complete")
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
            print("📹 Camera session started")
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
            print("📹 Camera session stopped")
        }
    }
    
    // Announce with PRIORITY SYSTEM
    func announceDetections() {
        print("🔘 ANNOUNCE BUTTON PRESSED")
        
        // Check camera conditions first
        if !isCameraStable {
            speechManager.speak("Please hold camera still")
            return
        }
        
        if lightingQuality == .tooDark {
            speechManager.speak("Lighting is too dim. Please turn on lights or move to brighter area")
            return
        } else if lightingQuality == .dim {
            speechManager.speak("Warning: Dim lighting may affect detection")
            // Continue with detection
        }
        
        guard !detections.isEmpty else {
            speechManager.speak("No objects detected. Try moving camera closer or improving lighting")
            return
        }
        
        // PRIORITY 1: HAZARDS (Critical Safety)
        let hazards = detections.filter {
            ["Stairs", "Knife", "Ladder", "wet floor", "fire", "broken glass"].contains($0.label)
        }
        
        if !hazards.isEmpty {
            for hazard in hazards {
                let warning = buildHazardAnnouncement(hazard)
                speechManager.speak(warning, priority: .critical)
            }
            return  // Stop here if hazards found - don't announce other objects
        }
        
        // PRIORITY 2: General Objects (from YOLO)
        let yoloObjects = detections.filter {
            !$0.label.starts(with: "my_") && $0.label != "background"
        }
        
        // PRIORITY 3: Personal Items
        let personalItems = detections.filter { $0.label.starts(with: "my_") }
        
        // PRIORITY 4: Scene Context
        let sceneText = currentScene.isEmpty ? "" : currentScene.replacingOccurrences(of: "_", with: " ")
        
        // Build complete announcement
        var announcements: [(String, TimeInterval)] = []
        
        // Announce objects with spatial context
        for (index, obj) in yoloObjects.prefix(3).enumerated() {
            let announcement = buildObjectAnnouncement(obj)
            announcements.append((announcement, Double(index) * 1.5))
        }
        
        // Add personal items
        for (index, item) in personalItems.prefix(2).enumerated() {
            let cleanLabel = item.label
                .replacingOccurrences(of: "my_", with: "your ")
                .replacingOccurrences(of: "_", with: " ")
            let announcement = "\(cleanLabel), \(item.direction.rawValue)"
            announcements.append((announcement, Double(yoloObjects.count + index) * 1.5))
        }
        
        // Add scene at the end
        if !sceneText.isEmpty {
            let sceneAnnouncement = "You are in a \(sceneText)"
            announcements.append((sceneAnnouncement, Double(announcements.count) * 1.5))
        }
        
        // Speak all announcements with delays
        for (text, delay) in announcements {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.speechManager.speak(text)
            }
        }
        
        if announcements.isEmpty {
            speechManager.speak("No objects detected")
        }
    }
    
    private func buildHazardAnnouncement(_ hazard: DetectionResult) -> String {
        let article = ["a", "e", "i", "o", "u"].contains(hazard.label.lowercased().first ?? "c") ? "an" : "a"
        return "Warning! Be careful of \(article) \(hazard.label) \(hazard.direction.rawValue)"
    }
    
    private func buildObjectAnnouncement(_ obj: DetectionResult) -> String {
        let cleanLabel = obj.label.replacingOccurrences(of: "_", with: " ")
        
        // Add spatial context
        let spatial = obj.direction.rawValue
        
        // Add article
        let article = ["a", "e", "i", "o", "u"].contains(cleanLabel.lowercased().first ?? "c") ? "an" : "a"
        
        return "There is \(article) \(cleanLabel) \(spatial)"
    }
    
    // Check camera stability using motion detection
    private func analyzeCameraMotion(from pixelBuffer: CVPixelBuffer) {
        // Simple brightness-based motion detection
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        
        // Sample center region
        let centerRect = CGRect(
            x: extent.width * 0.4,
            y: extent.height * 0.4,
            width: extent.width * 0.2,
            height: extent.height * 0.2
        )
        
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: centerRect) {
            let brightness = calculateBrightness(cgImage)
            
            // Check motion (rapid brightness changes)
            let brightnessDiff = abs(brightness - previousFrameBrightness)
            motionMagnitude = brightnessDiff
            
            DispatchQueue.main.async {
                self.isCameraStable = brightnessDiff < 0.15  // Threshold
                
                // Check lighting
                if brightness < 0.2 {
                    self.lightingQuality = .tooDark
                } else if brightness < 0.4 {
                    self.lightingQuality = .dim
                } else {
                    self.lightingQuality = .good
                }
            }
            
            previousFrameBrightness = brightness
        }
    }
    
    private func calculateBrightness(_ image: CGImage) -> Float {
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalBrightness: Float = 0
        let pixelCount = width * height
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Float(pixelData[i])
            let g = Float(pixelData[i + 1])
            let b = Float(pixelData[i + 2])
            
            // Calculate perceived brightness
            let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            totalBrightness += brightness
        }
        
        return totalBrightness / Float(pixelCount)
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameCount += 1
        guard frameCount % processEveryNFrames == 0 else { return }
        
        guard !isProcessing,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Analyze camera conditions
        analyzeCameraMotion(from: pixelBuffer)
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        // Detect with PRIORITY order
        mlModels.detectWithPriority(in: pixelBuffer) { [weak self] detections, scene in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.detections = detections
                self.currentScene = scene ?? ""
            }
        }
    }
}
