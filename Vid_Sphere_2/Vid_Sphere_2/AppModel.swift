import SwiftUI
import RealityKit
import AVKit
import Combine

@MainActor
class AppModel: ObservableObject {
    @Published var selectedTileID: Int? = nil
    @Published var isCinemaMode: Bool = false
    
    let player = AVPlayer()
    // Shared material prevents "Tether" crashes
    let sharedVideoMaterial: VideoMaterial
    
    private var currentVideoURL: URL?
    
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        self.sharedVideoMaterial = VideoMaterial(avPlayer: player)
    }
    
    func loadVideo(url: URL) {
        guard url != currentVideoURL else {
            if player.timeControlStatus != .playing { player.play() }
            return
        }
        player.pause()
        currentVideoURL = url
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        player.play()
    }
    
    func selectTile(id: Int, url: URL) {
        withAnimation {
            selectedTileID = id
            isCinemaMode = true
        }
        loadVideo(url: url)
        player.rate = 1.0
    }
    
    func dismissSelection() {
        withAnimation {
            selectedTileID = nil
            isCinemaMode = false
        }
        player.pause()
    }
    
    func stopVideo() {
        player.pause()
    }
}
