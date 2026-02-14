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
    private var previousFrameBrightness: Float = 0
    
    // NEW: Auto-announcement system
    private var autoAnnounceTimer: Timer?
    private var lastAnnouncedDetections: Set<String> = []
    private var detectionStabilityCounter: [String: Int] = [:]
    private let stabilityThreshold = 3 // Object must appear in 3 consecutive frames
    private let autoAnnounceInterval: TimeInterval = 4.0 // 4 seconds
    
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
        
        // Start auto-announcement timer
        startAutoAnnouncement()
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.stopRunning()
            print("📹 Camera session stopped")
        }
        
        // Stop auto-announcement
        stopAutoAnnouncement()
    }
    
    // MARK: - Auto-Announcement System
    
    private func startAutoAnnouncement() {
        stopAutoAnnouncement() // Clear any existing timer
        
        autoAnnounceTimer = Timer.scheduledTimer(withTimeInterval: autoAnnounceInterval, repeats: true) { [weak self] _ in
            self?.autoAnnounceDetections()
        }
    }
    
    private func stopAutoAnnouncement() {
        autoAnnounceTimer?.invalidate()
        autoAnnounceTimer = nil
    }
    
    private func autoAnnounceDetections() {
        guard !speechManager.isSpeaking else { return }
        
        // Check camera conditions
        if !isCameraStable {
            speechManager.speak("Please hold camera still", priority: .low)
            return
        }
        
        if lightingQuality == .tooDark {
            speechManager.speak("Too dark. Please turn on lights", priority: .normal)
            return
        }
        
        // Get stable detections (appeared in multiple frames)
        let stableDetections = getStableDetections()
        
        if stableDetections.isEmpty {
            return // Don't announce if nothing detected
        }
        
        // Build smart announcement
        announceIntelligently(stableDetections)
    }
    
    private func getStableDetections() -> [DetectionResult] {
        // Only announce detections that have been stable for multiple frames
        return detections.filter { detection in
            let key = detection.label
            let count = detectionStabilityCounter[key] ?? 0
            return count >= stabilityThreshold
        }
    }
    
    // MARK: - Intelligent Announcement
    
    private func announceIntelligently(_ detections: [DetectionResult]) {
        // Deduplicate and group detections
        let grouped = groupDetections(detections)
        
        // PRIORITY 1: HAZARDS (Critical)
        if !grouped.hazards.isEmpty {
            announceHazards(grouped.hazards)
            return
        }
        
        // Build announcement for normal objects
        var announcements: [String] = []
        
        // PRIORITY 2: Personal items
        if !grouped.personalItems.isEmpty {
            announcements.append(contentsOf: announcePersonalItems(grouped.personalItems))
        }
        
        // PRIORITY 3: Everyday objects (deduplicated and grouped)
        if !grouped.everydayObjects.isEmpty {
            announcements.append(contentsOf: announceEverydayObjects(grouped.everydayObjects))
        }
        
        // PRIORITY 4: Scene context
        if !currentScene.isEmpty && grouped.everydayObjects.isEmpty {
            let scene = currentScene.replacingOccurrences(of: "_", with: " ")
            announcements.append("You are in a \(scene)")
        }
        
        // PRIORITY 5: Lighting warning (at the end)
        if lightingQuality == .dim {
            announcements.append("Lighting is dim")
        }
        
        // Speak all announcements with pauses
        if !announcements.isEmpty {
            speakSequence(announcements)
        }
    }
    
    // MARK: - Detection Grouping
    
    struct GroupedDetections {
        var hazards: [DetectionResult] = []
        var personalItems: [DetectionResult] = []
        var everydayObjects: [DetectionResult] = []
    }
    
    private func groupDetections(_ detections: [DetectionResult]) -> GroupedDetections {
        var grouped = GroupedDetections()
        
        // Deduplicate by label + direction
        var seen: Set<String> = []
        
        for detection in detections {
            let key = "\(detection.label)-\(detection.direction.rawValue)"
            
            // Skip if already announced recently
            if lastAnnouncedDetections.contains(key) {
                continue
            }
            
            // Skip duplicates in same detection cycle
            if seen.contains(detection.label) {
                continue
            }
            seen.insert(detection.label)
            
            // Categorize
            if isHazard(detection.label) {
                grouped.hazards.append(detection)
            } else if detection.label.starts(with: "my_") {
                grouped.personalItems.append(detection)
            } else {
                grouped.everydayObjects.append(detection)
            }
        }
        
        return grouped
    }
    
    private func isHazard(_ label: String) -> Bool {
        let hazards = ["Stairs", "Knife", "Ladder", "stairs", "knife", "ladder", "wet floor", "fire"]
        return hazards.contains(label)
    }
    
    // MARK: - Announcement Builders
    
    private func announceHazards(_ hazards: [DetectionResult]) {
        for hazard in hazards.prefix(2) { // Max 2 hazards at once
            let warning = buildHazardAnnouncement(hazard)
            speechManager.speak(warning, priority: .critical)
            
            // Remember announced
            let key = "\(hazard.label)-\(hazard.direction.rawValue)"
            lastAnnouncedDetections.insert(key)
        }
    }
    
    private func announcePersonalItems(_ items: [DetectionResult]) -> [String] {
        return items.prefix(2).map { item in
            let cleanLabel = item.label
                .replacingOccurrences(of: "my_", with: "your ")
                .replacingOccurrences(of: "_", with: " ")
            
            let key = "\(item.label)-\(item.direction.rawValue)"
            lastAnnouncedDetections.insert(key)
            
            return "\(cleanLabel), \(item.direction.rawValue)"
        }
    }
    
    private func announceEverydayObjects(_ objects: [DetectionResult]) -> [String] {
        // Group by spatial relationship
        let byDirection = Dictionary(grouping: objects) { $0.direction }
        
        var announcements: [String] = []
        
        // Announce objects on the same surface together
        for (direction, items) in byDirection {
            let labels = items.map { $0.label }
            
            if labels.count == 1 {
                // Single object
                let label = labels[0]
                let article = getArticle(for: label)
                announcements.append("There is \(article) \(label) \(direction.rawValue)")
                
                let key = "\(label)-\(direction.rawValue)"
                lastAnnouncedDetections.insert(key)
            } else if labels.count == 2 {
                // Two objects together
                let first = labels[0]
                let second = labels[1]
                announcements.append("\(first.capitalized) and \(second) \(direction.rawValue)")
                
                for label in labels {
                    let key = "\(label)-\(direction.rawValue)"
                    lastAnnouncedDetections.insert(key)
                }
            } else {
                // Multiple objects - group them
                let objectList = labels.prefix(3).joined(separator: ", ")
                announcements.append("\(objectList) \(direction.rawValue)")
                
                for label in labels {
                    let key = "\(label)-\(direction.rawValue)"
                    lastAnnouncedDetections.insert(key)
                }
            }
        }
        
        return Array(announcements.prefix(2)) // Max 2 spatial groups
    }
    
    private func buildHazardAnnouncement(_ hazard: DetectionResult) -> String {
        let article = getArticle(for: hazard.label)
        return "Warning! Be careful of \(article) \(hazard.label) \(hazard.direction.rawValue)"
    }
    
    private func getArticle(for word: String) -> String {
        let vowels = ["a", "e", "i", "o", "u"]
        return vowels.contains(String(word.prefix(1).lowercased())) ? "an" : "a"
    }
    
    // MARK: - Speech Sequence
    
    private func speakSequence(_ announcements: [String]) {
        guard !announcements.isEmpty else { return }
        
        // Combine into natural sentences
        let combined = combineIntoSentences(announcements)
        
        for (index, text) in combined.enumerated() {
            let delay = Double(index) * 2.0 // 2 second pause between sentences
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.speechManager.speak(text, priority: .normal)
            }
        }
        
        // Clear announced detections after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            self?.lastAnnouncedDetections.removeAll()
        }
    }
    
    private func combineIntoSentences(_ announcements: [String]) -> [String] {
        // Combine short announcements into natural sentences
        var result: [String] = []
        var current = ""
        
        for announcement in announcements {
            if current.isEmpty {
                current = announcement
            } else if current.count + announcement.count < 100 {
                current += ". " + announcement
            } else {
                result.append(current)
                current = announcement
            }
        }
        
        if !current.isEmpty {
            result.append(current)
        }
        
        return result
    }
    
    // MARK: - Manual Announcement (Button Press)
    
    func announceDetections() {
        print("🔘 ANNOUNCE BUTTON PRESSED")
        
        if !isCameraStable {
            speechManager.speak("Please hold camera still")
            return
        }
        
        if lightingQuality == .tooDark {
            speechManager.speak("Lighting is too dim. Please turn on lights or move to brighter area")
            return
        } else if lightingQuality == .dim {
            speechManager.speak("Warning: Dim lighting may affect detection")
        }
        
        guard !detections.isEmpty else {
            speechManager.speak("No objects detected. Try moving camera closer or improving lighting")
            return
        }
        
        // Use same intelligent announcement
        announceIntelligently(detections)
    }
    
    // MARK: - Camera Analysis
    
    private func analyzeCameraMotion(from pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        
        let centerRect = CGRect(
            x: extent.width * 0.4,
            y: extent.height * 0.4,
            width: extent.width * 0.2,
            height: extent.height * 0.2
        )
        
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: centerRect) {
            let brightness = calculateBrightness(cgImage)
            let brightnessDiff = abs(brightness - previousFrameBrightness)
            
            DispatchQueue.main.async {
                self.isCameraStable = brightnessDiff < 0.15
                
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
        
        analyzeCameraMotion(from: pixelBuffer)
        
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        mlModels.detectWithPriority(in: pixelBuffer) { [weak self] detections, scene in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.detections = detections
                self.currentScene = scene ?? ""
                
                // Update stability counter for auto-announcement
                self.updateStabilityCounter(detections)
            }
        }
    }
    
    private func updateStabilityCounter(_ detections: [DetectionResult]) {
        let currentLabels = Set(detections.map { $0.label })
        
        // Increment counter for detected objects
        for label in currentLabels {
            detectionStabilityCounter[label, default: 0] += 1
        }
        
        // Decrement counter for objects not detected
        for (label, count) in detectionStabilityCounter {
            if !currentLabels.contains(label) {
                detectionStabilityCounter[label] = max(0, count - 1)
            }
        }
        
        // Remove entries with 0 count
        detectionStabilityCounter = detectionStabilityCounter.filter { $0.value > 0 }
    }
}
