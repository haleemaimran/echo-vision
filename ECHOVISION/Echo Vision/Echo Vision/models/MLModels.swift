import CoreML
import Vision

class MLModels {
    static let shared = MLModels()
    
    // Your trained models
    private var hazardDetector: VNCoreMLModel?
    private var personalItems: VNCoreMLModel?
    private var sceneClassifier: VNCoreMLModel?
    private var yolov8: VNCoreMLModel?
    
    // Confidence thresholds
    private let hazardConfidenceThreshold: Float = 0.6
    private let personalItemsThreshold: Float = 0.7
    private let yoloThreshold: Float = 0.5
    
    private init() {
        print("🔄 MLModels initializing...")
        loadModels()
    }
    

    
    
    private func loadModels() {
        print("📦 Loading models from bundle...")
        
        // ===== DEBUG: Show ALL files in bundle =====
        if let resourcePath = Bundle.main.resourcePath {
            print("📁 Bundle resource path: \(resourcePath)")
            
            do {
                let allFiles = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                
                // Filter for ML-related files
                let mlFiles = allFiles.filter { file in
                    file.contains(".mlmodel") ||
                    file.contains(".mlpackage") ||
                    file.lowercased().contains("yolo")
                }
                
                print("📄 ML files found in bundle:")
                if mlFiles.isEmpty {
                    print("   ❌ NO ML FILES FOUND!")
                } else {
                    for file in mlFiles.sorted() {
                        print("   ✅ \(file)")
                    }
                }
            } catch {
                print("❌ Error reading bundle: \(error)")
            }
        }
        // ===== END DEBUG =====
        
        do {
            // Load HazardDetector
            if let hazardURL = Bundle.main.url(forResource: "HazardDetector", withExtension: "mlmodelc") {
                let hazardModel = try MLModel(contentsOf: hazardURL)
                hazardDetector = try VNCoreMLModel(for: hazardModel)
                print("✅ HazardDetector loaded")
            }
            
            // Load PersonalObjectClassifier
            if let personalURL = Bundle.main.url(forResource: "PersonalObjectClassifier", withExtension: "mlmodelc") {
                let personalModel = try MLModel(contentsOf: personalURL)
                personalItems = try VNCoreMLModel(for: personalModel)
                print("✅ PersonalObjectClassifier loaded")
            }
            
            // Load SceneClassifier
            if let sceneURL = Bundle.main.url(forResource: "SceneClassifier", withExtension: "mlmodelc") {
                let sceneModel = try MLModel(contentsOf: sceneURL)
                sceneClassifier = try VNCoreMLModel(for: sceneModel)
                print("✅ SceneClassifier loaded")
            }
            
            // Load YOLOv8 - Try multiple variations
            var yoloLoaded = false
            
            // Try 1: yolov8n.mlpackage
            if let yoloURL = Bundle.main.url(forResource: "yolov8n", withExtension: "mlpackage") {
                print("📦 Found yolov8n.mlpackage, attempting to load...")
                let compiledURL = try MLModel.compileModel(at: yoloURL)
                let yoloModel = try MLModel(contentsOf: compiledURL)
                yolov8 = try VNCoreMLModel(for: yoloModel)
                print("✅ YOLOv8 loaded from yolov8n.mlpackage")
                yoloLoaded = true
            }
            
            // Try 2: yolov8n.mlmodelc (already compiled)
            if !yoloLoaded, let yoloURL = Bundle.main.url(forResource: "yolov8n", withExtension: "mlmodelc") {
                print("📦 Found yolov8n.mlmodelc, attempting to load...")
                let yoloModel = try MLModel(contentsOf: yoloURL)
                yolov8 = try VNCoreMLModel(for: yoloModel)
                print("✅ YOLOv8 loaded from yolov8n.mlmodelc")
                yoloLoaded = true
            }
            
            // Try 3: YOLOv8.mlpackage
            if !yoloLoaded, let yoloURL = Bundle.main.url(forResource: "YOLOv8", withExtension: "mlpackage") {
                print("📦 Found YOLOv8.mlpackage, attempting to load...")
                let compiledURL = try MLModel.compileModel(at: yoloURL)
                let yoloModel = try MLModel(contentsOf: compiledURL)
                yolov8 = try VNCoreMLModel(for: yoloModel)
                print("✅ YOLOv8 loaded from YOLOv8.mlpackage")
                yoloLoaded = true
            }
            
            if !yoloLoaded {
                print("⚠️ YOLOv8 not found - tried:")
                print("   - yolov8n.mlpackage")
                print("   - yolov8n.mlmodelc")
                print("   - YOLOv8.mlpackage")
            }
            
        } catch {
            print("❌ Error loading models: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }
    
    // Detect hazards
    func detectHazards(in image: CVPixelBuffer, completion: @escaping ([DetectionResult]) -> Void) {
        guard let model = hazardDetector else {
            completion([])
            return
        }
        
        let request = VNCoreMLRequest(model: model) { (request: VNRequest, error: Error?) in
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }
            
            let detections = results
                .filter { $0.confidence >= self.hazardConfidenceThreshold }
                .compactMap { observation -> DetectionResult? in
                    guard let label = observation.labels.first?.identifier else { return nil }
                    return DetectionResult(
                        label: label,
                        confidence: observation.confidence,
                        boundingBox: observation.boundingBox,
                        distance: nil,
                        direction: self.getDirection(from: observation.boundingBox)
                    )
                }
            
            if !detections.isEmpty {
                print("🚨 Hazards: \(detections.map { "\($0.label) \(Int($0.confidence * 100))%" })")
            }
            completion(detections)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    // Recognize personal items
    func recognizePersonalItems(in image: CVPixelBuffer, completion: @escaping ([DetectionResult]) -> Void) {
        guard let model = personalItems else {
            completion([])
            return
        }
        
        let request = VNCoreMLRequest(model: model) { (request: VNRequest, error: Error?) in
            guard let results = request.results as? [VNClassificationObservation] else {
                completion([])
                return
            }
            
            let detections = results
                .filter { $0.confidence >= self.personalItemsThreshold && $0.identifier != "background" }
                .prefix(3)
                .map { observation in
                    DetectionResult(
                        label: observation.identifier,
                        confidence: observation.confidence,
                        boundingBox: nil,
                        distance: nil,
                        direction: .center
                    )
                }
            
            if !Array(detections).isEmpty {
                print("👤 Personal items (≥70%): \(Array(detections).map { "\($0.label) \(Int($0.confidence * 100))%" })")
            }
            completion(Array(detections))
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    // Classify scene
    func classifyScene(in image: CVPixelBuffer, completion: @escaping (String?) -> Void) {
        guard let model = sceneClassifier else {
            completion(nil)
            return
        }
        
        let request = VNCoreMLRequest(model: model) { (request: VNRequest, error: Error?) in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                completion(nil)
                return
            }
            
            print("🏠 Scene: \(topResult.identifier) (\(Int(topResult.confidence * 100))%)")
            completion(topResult.identifier)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    // Detect with YOLOv8 (80 object classes from COCO)
    func detectWithYOLO(in image: CVPixelBuffer, completion: @escaping ([DetectionResult]) -> Void) {
        guard let model = yolov8 else {
            print("⚠️ YOLOv8 not loaded")
            completion([])
            return
        }
        
        let request = VNCoreMLRequest(model: model) { (request: VNRequest, error: Error?) in
            if let error = error {
                print("❌ YOLOv8 error: \(error)")
                completion([])
                return
            }
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }
            
            let detections = results
                .filter { $0.confidence >= self.yoloThreshold }
                .map { observation in
                    DetectionResult(
                        label: observation.labels.first?.identifier ?? "object",
                        confidence: observation.confidence,
                        boundingBox: observation.boundingBox,
                        distance: nil,
                        direction: self.getDirection(from: observation.boundingBox)
                    )
                }
            
            if !detections.isEmpty {
                print("🎯 YOLOv8: \(detections.map { "\($0.label) \(Int($0.confidence * 100))%" })")
            }
            completion(detections)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    // Main detection function - combines all models
    func detectObjects(in image: CVPixelBuffer, completion: @escaping ([DetectionResult]) -> Void) {
        var allDetections: [DetectionResult] = []
        let group = DispatchGroup()
        
        // 1. Check hazards (priority)
        group.enter()
        detectHazards(in: image) { hazards in
            allDetections.append(contentsOf: hazards)
            group.leave()
        }
        
        // 2. YOLOv8 for common objects (bottle, laptop, etc.)
        group.enter()
        detectWithYOLO(in: image) { yoloObjects in
            allDetections.append(contentsOf: yoloObjects)
            group.leave()
        }
        
        // 3. Personal items (high confidence only)
        group.enter()
        recognizePersonalItems(in: image) { personalItems in
            allDetections.append(contentsOf: personalItems)
            group.leave()
        }
        
        group.notify(queue: .main) {
            // Remove duplicates, sort by confidence
            let uniqueDetections = allDetections
                .sorted { $0.confidence > $1.confidence }
                .prefix(5)
            
            print("📊 Final detections: \(Array(uniqueDetections).map { "\($0.label) \(Int($0.confidence * 100))%" })")
            completion(Array(uniqueDetections))
        }
    }
    
    // Add this new function to MLModels class

    // PRIORITY DETECTION: Hazards → YOLO Objects → Personal Items → Scene
    func detectWithPriority(in image: CVPixelBuffer, completion: @escaping ([DetectionResult], String?) -> Void) {
        var finalDetections: [DetectionResult] = []
        var sceneResult: String?
        
        let group = DispatchGroup()
        
        // PRIORITY 1: Check for HAZARDS first (blocking - most important)
        group.enter()
        detectHazards(in: image) { hazards in
            if !hazards.isEmpty {
                // HAZARDS FOUND - This is critical!
                print("🚨 HAZARD DETECTED: \(hazards.map { $0.label })")
                finalDetections = hazards
                group.leave()
                
                // Still get scene for context but prioritize hazard announcement
                self.classifyScene(in: image) { scene in
                    sceneResult = scene
                }
                return
            }
            
            // No hazards - continue with normal detection
            group.leave()
            
            // PRIORITY 2: YOLO for general objects
            group.enter()
            self.detectWithYOLO(in: image) { yoloObjects in
                finalDetections.append(contentsOf: yoloObjects)
                group.leave()
            }
            
            // PRIORITY 3: Personal items (lower priority)
            group.enter()
            self.recognizePersonalItems(in: image) { personalItems in
                finalDetections.append(contentsOf: personalItems)
                group.leave()
            }
            
            // PRIORITY 4: Scene classification
            group.enter()
            self.classifyScene(in: image) { scene in
                sceneResult = scene
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Sort by confidence and limit
            let sorted = finalDetections
                .sorted { $0.confidence > $1.confidence }
                .prefix(5)
            
            print("📊 Priority detections: \(Array(sorted).map { "\($0.label) \(Int($0.confidence * 100))%" })")
            if let scene = sceneResult {
                print("🏠 Scene: \(scene)")
            }
            
            completion(Array(sorted), sceneResult)
        }
    }
    
    // Helper: direction from bounding box
    private func getDirection(from box: CGRect) -> DetectionResult.Direction {
        let centerX = box.midX
        
        if centerX < 0.33 {
            return .left
        } else if centerX > 0.67 {
            return .right
        } else {
            return .center
        }
    }
}
