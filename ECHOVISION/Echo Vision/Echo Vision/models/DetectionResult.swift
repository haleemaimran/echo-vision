import Foundation
import CoreGraphics

struct DetectionResult: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect?
    let distance: Float?
    let direction: Direction
    
    enum Direction: String {
        case left = "on your left"
        case center = "in front"
        case right = "on your right"
    }
    
    var description: String {
        var text = label
        
        if let distance = distance {
            let distanceInt = Int(distance.rounded())
            text += ", \(distanceInt) feet away"
        }
        
        text += ", \(direction.rawValue)"
        
        return text
    }
}
