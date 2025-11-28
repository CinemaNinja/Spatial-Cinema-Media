import SwiftUI

@main
struct SpatialCinemaApp: App {
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup(id: "Launcher") {
            LaunchButton()
                .environmentObject(appModel)
        }
        .windowStyle(.plain)
        .defaultSize(width: 500, height: 400) // More room for the title

        ImmersiveSpace(id: "CinemaSpace") {
            ImmersiveView()
                .environmentObject(appModel)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
