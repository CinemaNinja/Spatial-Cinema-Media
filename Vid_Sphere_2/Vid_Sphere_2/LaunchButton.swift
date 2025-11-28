import SwiftUI

struct LaunchButton: View {
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow

    var body: some View {
        ZStack {
            // Subtle background gradient
            LinearGradient(colors: [.black.opacity(0.8), .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 35) {
                VStack(spacing: 10) {
                    Text("SPATIAL CINEMA")
                        .font(.system(size: 50, weight: .light, design: .serif))
                        .foregroundStyle(.white)
                        .kerning(4) // Cinematic letter spacing
                        .lineLimit(1)
                        .minimumScaleFactor(0.5) // Never cut off
                    
                    Text("IMMERSIVE LIBRARY")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.gray)
                        .kerning(6)
                }
                
                Button(action: {
                    Task {
                        await openImmersiveSpace(id: "CinemaSpace")
                        dismissWindow(id: "Launcher")
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "visionpro")
                        Text("ENTER THEATER")
                    }
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 15)
                }
                .glassBackgroundEffect()
                .buttonBorderShape(.capsule)
            }
            .padding(60)
        }
    }
}
