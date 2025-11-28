import Foundation
import SwiftUI
import RealityKit

struct VideoTileData: Identifiable {
    let id: Int
    let position: SIMD3<Float>
    let imageURL: URL
    let videoURL: URL
}

struct GoldenSpiralMath {
    static func generateTiles(count: Int, radius: Float) -> [VideoTileData] {
        var tiles: [VideoTileData] = []
        let phi = Float.pi * (3.0 - sqrt(5.0)) // Golden Angle
        
        // CONFIGURATION
        let assetCount = 4
        let baseURL = "https://raw.githubusercontent.com/CinemaNinja/Spatial-Cinema-Media/main"
        
        for i in 0..<count {
            let y = 1 - (Float(i) / Float(count - 1)) * 2
            let radiusAtY = sqrt(1 - y * y)
            let theta = phi * Float(i)
            
            let x = cos(theta) * radiusAtY
            let z = sin(theta) * radiusAtY
            
            let position = SIMD3<Float>(x * radius, y * radius, z * radius)
            let index = (i % assetCount) + 1
            
            let imageURL = URL(string: "\(baseURL)/img\(index).jpg")!
            let videoURL = URL(string: "\(baseURL)/vid\(index).mov")!
            
            tiles.append(VideoTileData(
                id: i,
                position: position,
                imageURL: imageURL,
                videoURL: videoURL
            ))
        }
        return tiles
    }
}
