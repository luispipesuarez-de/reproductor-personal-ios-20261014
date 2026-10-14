import AVFoundation
import Combine

enum PlaybackState: Equatable {
    case idle
    case loading(Video)
    case playing(Video)
    case paused(Video)
    case failed(video: Video?, message: String)
}

@MainActor
final class PlaybackController: ObservableObject {
    let player: AVQueuePlayer
    @Published private(set) var state: PlaybackState = .idle

    init(source: any YouTubeProviding, player: AVQueuePlayer = AVQueuePlayer()) {
        self.player = player
    }

    func play(_ video: Video) async {}
    func pause() {}
    func resume() async {}
}
