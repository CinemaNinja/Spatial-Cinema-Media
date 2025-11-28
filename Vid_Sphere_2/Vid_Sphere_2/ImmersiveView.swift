import SwiftUI
import RealityKit
import AVKit
import Combine
import QuartzCore

struct ImmersiveView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @State private var tileEntities: [Int: ModelEntity] = [:]
    @State private var sphereRoot = Entity()
    
    // Config
    let sphereRadius: Float = 4.0
    let tileCount: Int = 80
    let cinemaPosition = SIMD3<Float>(0, 1.6, -2.0)
    
    // Fix: Look at eye level (1.6) to ensure the screen is vertical (no tilt)
    let lookTarget = SIMD3<Float>(0, 1.6, 0)
    
    let baseMaterial = SimpleMaterial(color: .gray, isMetallic: false)
    
    var body: some View {
        RealityView { content, attachments in
            sphereRoot.name = "SphereRoot"
            content.add(sphereRoot)
            
            // 1. Invisible Backdrop (The Void Clicker)
            let wallMesh = MeshResource.generatePlane(width: 20.0, height: 20.0)
            let wallMat = OcclusionMaterial()
            let wallEntity = ModelEntity(mesh: wallMesh, materials: [wallMat])
            wallEntity.name = "Backdrop"
            wallEntity.position = SIMD3<Float>(0, 1.6, -5.0)
            wallEntity.look(at: .zero, from: wallEntity.position, relativeTo: nil)
            wallEntity.generateCollisionShapes(recursive: false)
            wallEntity.components.set(InputTargetComponent())
            sphereRoot.addChild(wallEntity)
            
            // 2. Generate Tiles
            let tiles = GoldenSpiralMath.generateTiles(count: tileCount, radius: sphereRadius)
            
            for tileData in tiles {
                let mesh = MeshResource.generateBox(width: 0.8, height: 0.45, depth: 0.05)
                let entity = ModelEntity(mesh: mesh, materials: [baseMaterial])
                entity.name = "Tile_\(tileData.id)"
                
                entity.position = tileData.position
                // Fix: Force Up vector to keep tiles upright
                entity.look(at: .zero, from: tileData.position, upVector: [0, 1, 0], relativeTo: nil)
                
                entity.generateCollisionShapes(recursive: false)
                entity.components.set(InputTargetComponent())
                entity.components.set(HoverEffectComponent())
                
                tileEntities[tileData.id] = entity
                sphereRoot.addChild(entity)
                
                // Load GitHub Images
                Task(priority: .background) {
                    if let texture = await TextureManager.shared.loadTexture(from: tileData.imageURL) {
                        var mat = SimpleMaterial()
                        mat.color = .init(texture: .init(texture))
                        mat.roughness = 0.5
                        await MainActor.run { entity.model?.materials = [mat] }
                    }
                }
            }
            
            // 3. ADD EXIT BUTTON
            if let exitButton = attachments.entity(for: "ExitButton") {
                // Position: Low (0.6m), Forward (1.0m)
                exitButton.position = SIMD3<Float>(0, 0.6, -1.0)
                
                // --- FIX: REMOVED ROTATION ---
                // The default orientation is correct. Removing the flip fixes the mirrored text.
                // exitButton.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                
                sphereRoot.addChild(exitButton)
            }
            
        } update: { content, attachments in }
        attachments: {
            // 4. SWIFTUI BUTTON DEFINITION
            Attachment(id: "ExitButton") {
                Button(action: {
                    Task {
                        await dismissImmersiveSpace()
                        openWindow(id: "Launcher")
                    }
                }) {
                    Label("Exit Cinema", systemImage: "xmark")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(12)
                }
                .glassBackgroundEffect()
            }
        }
        
        // --- MASTER ANIMATION CONTROLLER ---
        .onChange(of: appModel.selectedTileID) { oldID, newID in
            
            // 1. DISMISS OLD TILE (Reverse Flip)
            if let old = oldID, let oldEntity = tileEntities[old] {
                let tiles = GoldenSpiralMath.generateTiles(count: tileCount, radius: sphereRadius)
                let originalPos = tiles[old].position
                
                let directionToCenter = simd_normalize(-originalPos)
                let rotationToCenter = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: directionToCenter)
                
                oldEntity.stopAllAnimations()
                
                Task {
                    // Waypoint 1: Halfway + Twist
                    let midPos = (oldEntity.position + originalPos) / 2
                    let flipRot = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                    let midRot = oldEntity.transform.rotation * flipRot
                    let midTransform = Transform(scale: .init(repeating: 1.5), rotation: midRot, translation: midPos)
                    
                    oldEntity.move(to: midTransform, relativeTo: nil, duration: 0.25, timingFunction: .linear)
                    
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    
                    // Waypoint 2: Home
                    let finalTransform = Transform(scale: .one, rotation: rotationToCenter, translation: originalPos)
                    oldEntity.move(to: finalTransform, relativeTo: nil, duration: 0.25, timingFunction: .easeOut)
                    
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    
                    // Restore Texture
                    if let texture = await TextureManager.shared.loadTexture(from: tiles[old].imageURL) {
                        var mat = SimpleMaterial()
                        mat.color = .init(texture: .init(texture))
                        await MainActor.run { oldEntity.model?.materials = [mat] }
                    } else {
                        await MainActor.run { oldEntity.model?.materials = [baseMaterial] }
                    }
                    await performLandingWobble(entity: oldEntity, originalTransform: finalTransform)
                }
            }
            
            // 2. OPEN NEW TILE (Forward Flip)
            if let new = newID, let newEntity = tileEntities[new] {
                // Fix: Calculate Rotation looking at Eye Level (1.6) to prevent tilt
                let directionToUser = simd_normalize(lookTarget - cinemaPosition)
                let rotationToUser = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: directionToUser)
                
                newEntity.stopAllAnimations()
                
                Task {
                    // Waypoint 1: Halfway + Twist
                    let startPos = newEntity.position
                    let midPos = (startPos + cinemaPosition) / 2
                    let flipRot = simd_quatf(angle: .pi, axis: [1, 0, 0])
                    let midRot = rotationToUser * flipRot
                    let midTransform = Transform(scale: .init(repeating: 1.5), rotation: midRot, translation: midPos)
                    
                    newEntity.move(to: midTransform, relativeTo: nil, duration: 0.35, timingFunction: .linear)
                    
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    
                    // Waypoint 2: Center + Complete Twist
                    let finalTransform = Transform(scale: .init(repeating: 2.5), rotation: rotationToUser, translation: cinemaPosition)
                    newEntity.move(to: finalTransform, relativeTo: nil, duration: 0.35, timingFunction: .easeOut)
                    
                    // Use Shared Material
                    await MainActor.run { newEntity.model?.materials = [appModel.sharedVideoMaterial] }
                }
            }
        }
        .onDisappear { appModel.stopVideo() }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    guard let entity = value.entity as? ModelEntity else { return }
                    
                    if entity.name.hasPrefix("Tile_") {
                        let components = entity.name.split(separator: "_")
                        guard components.count > 1, let id = Int(components[1]) else { return }
                        
                        if appModel.selectedTileID != id {
                            let tiles = GoldenSpiralMath.generateTiles(count: tileCount, radius: sphereRadius)
                            appModel.selectTile(id: id, url: tiles[id].videoURL)
                        }
                    } else if entity.name == "Backdrop" {
                        if appModel.isCinemaMode {
                            appModel.dismissSelection()
                        }
                    }
                }
        )
    }
    
    @MainActor
    func performLandingWobble(entity: ModelEntity, originalTransform: Transform) async {
        var popTransform = originalTransform
        popTransform.scale = SIMD3<Float>(repeating: 1.15)
        entity.move(to: popTransform, relativeTo: nil, duration: 0.1, timingFunction: .easeOut)
        try? await Task.sleep(nanoseconds: 100_000_000)
        entity.move(to: originalTransform, relativeTo: nil, duration: 0.25, timingFunction: .easeInOut)
    }
}
