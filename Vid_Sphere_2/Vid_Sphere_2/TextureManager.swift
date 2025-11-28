import Foundation
import RealityKit
import UIKit

actor TextureManager {
    static let shared = TextureManager()
    private var cache: [URL: TextureResource] = [:]
    
    func loadTexture(from url: URL) async -> TextureResource? {
        if let cached = cache[url] { return cached }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
            try data.write(to: tempURL)
            
            let texture = try await MainActor.run {
                try TextureResource.load(contentsOf: tempURL)
            }
            
            cache[url] = texture
            return texture
        } catch {
            return nil
        }
    }
}
