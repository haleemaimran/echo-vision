import Foundation
import CoreGraphics
import SwiftUI

struct DetectionResult: Identifiable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect?
    let distance: Float?
    let direction: Direction
    let modelSource: ModelSource  // NEW: Track which model detected this
    
    enum Direction: String {
        case left = "on your left"
        case center = "in front"
        case right = "on your right"
    }
    
    // NEW: Model source for color-coded bounding boxes
    enum ModelSource {
        case hazard           // RED boxes
        case indoorObstacles  // GREEN boxes
        case yolo             // YELLOW boxes
        case personal         // PURPLE (no box, just text)
        
        var color: Color {
            switch self {
            case .hazard:
                return .red
            case .indoorObstacles:
                return .green
            case .yolo:
                return .yellow
            case .personal:
                return .purple
            }
        }
        
        var name: String {
            switch self {
            case .hazard:
                return "Hazard"
            case .indoorObstacles:
                return "Obstacle"
            case .yolo:
                return "Object"
            case .personal:
                return "Personal"
            }
        }
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
    
    // For accessibility announcements
    var accessibilityDescription: String {
        let modelType = modelSource.name
        return "\(modelType): \(description)"
    }
}
