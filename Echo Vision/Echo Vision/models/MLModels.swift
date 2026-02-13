import CoreML
import Vision

class MLModels {
    static let shared = MLModels()
    
    // Your trained models
    private var hazardDetector: VNCoreMLModel?
    private var personalItems: VNCoreMLModel?
    private var sceneClassifier: VNCoreMLModel?
    
    private init() {
        loadModels()
    }
    
    private func loadModels() {
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
            
        } catch {
            print("❌ Error loading models: \(error)")
        }
    }
    
    // Detect hazards (stairs, knives, obstacles) - YOUR CUSTOM MODEL
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
            
            let detections = results.map { observation in
                DetectionResult(
                    label: observation.labels.first?.identifier ?? "Unknown",
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox,
                    distance: nil,
                    direction: self.getDirection(from: observation.boundingBox)
                )
            }
            
            completion(detections)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    // Recognize personal items - YOUR CUSTOM MODEL
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
            
            let detections = results.prefix(3).map { observation in
                DetectionResult(
                    label: observation.identifier,
                    confidence: observation.confidence,
                    boundingBox: nil,
                    distance: nil,
                    direction: .center
                )
            }
            
            completion(detections)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    // Classify scene - YOUR CUSTOM MODEL
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
            
            completion(topResult.identifier)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
        try? handler.perform([request])
    }
    
    // Detect general objects - Using VNDetectObjectsRequest
//    func detectObjects(in image: CVPixelBuffer, completion: @escaping ([DetectionResult]) -> Void) {
//        // Use VNDetectObjectsRequest (available in all iOS versions)
//        let request = VNDetectObjectsRequest { (request: VNRequest, error: Error?) in
//            guard let results = request.results as? [VNDetectedObjectObservation] else {
//                // Fallback to hazard detector
//                self.detectHazards(in: image, completion: completion)
//                return
//            }
//            
//            let detections = results.map { observation in
//                DetectionResult(
//                    label: "Object",  // Generic label
//                    confidence: observation.confidence,
//                    boundingBox: observation.boundingBox,
//                    distance: nil,
//                    direction: self.getDirection(from: observation.boundingBox)
//                )
//            }
//            
//            completion(detections)
//        }
//        
//        let handler = VNImageRequestHandler(cvPixelBuffer: image, options: [:])
//        
//        do {
//            try handler.perform([request])
//        } catch {
//            // If detection fails, use hazard detector
//            detectHazards(in: image, completion: completion)
//        }
//    }
    // Detect general objects - Just use your hazard detector
    func detectObjects(in image: CVPixelBuffer, completion: @escaping ([DetectionResult]) -> Void) {
        // Your hazard detector can detect stairs, knives, ladders
        // This is MORE useful than Apple's generic object detection
        detectHazards(in: image, completion: completion)
    }
    
    // Helper: Determine direction from bounding box
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
