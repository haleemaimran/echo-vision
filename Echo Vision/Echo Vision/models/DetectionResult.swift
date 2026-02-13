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
        case left = "left"
        case center = "center"
        case right = "right"
    }
    
    var description: String {
        var text = label
        
        if let distance = distance {
            text += ", \(Int(distance)) feet"
        }
        
        text += ", \(direction.rawValue)"
        
        return text
    }
}
