import AVFoundation
import Combine

enum PlaybackState: Equatable {
    case idle
    case loading(Video)
    case playing(Video)
    case paused(Video)
    case failed(video: Video?, message: String)

    var video: Video? {
        switch self {
        case .loading(let video), .playing(let video), .paused(let video): return video
        case .failed(let video, _): return video
        case .idle: return nil
        }
    }

    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }
}

@MainActor
final class PlaybackController: ObservableObject {
    let player: AVQueuePlayer
    @Published private(set) var state: PlaybackState = .idle
    private let source: any YouTubeProviding
    private var requestID = UUID()
    private var selectedVideo: Video?
    private var timeObservation: NSKeyValueObservation?
    private var itemObservation: NSKeyValueObservation?

    init(source: any YouTubeProviding, player: AVQueuePlayer = AVQueuePlayer()) {
        self.source = source
        self.player = player
        player.actionAtItemEnd = .pause
        player.audiovisualBackgroundPlaybackPolicy = .continuesIfPossible
        timeObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
            Task { @MainActor [weak self] in self?.updateNativeState() }
        }
    }

    func play(_ video: Video) async {
        let currentRequest = UUID()
        requestID = currentRequest
        selectedVideo = video
        itemObservation = nil
        player.pause()
        player.removeAllItems()
        state = .loading(video)
        do {
            let resource = try await source.resolve(videoID: video.id)
            guard requestID == currentRequest else { return }
            guard !Task.isCancelled else { pause(); return }
            try AudioSessionController.configure()
            let item = AVPlayerItem(url: resource.url)
            itemObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
                Task { @MainActor [weak self, weak observed] in
                    guard let self, let observed, self.player.currentItem === observed else { return }
                    self.updateNativeState()
                }
            }
            player.insert(item, after: nil)
            player.play()
        } catch {
            guard requestID == currentRequest else { return }
            guard !Task.isCancelled else { pause(); return }
            fail(error)
        }
    }

    func pause() {
        requestID = UUID()
        player.pause()
        guard let video = selectedVideo else { return }
        if case .failed = state { return }
        state = .paused(video)
    }

    func resume() async {
        guard let video = selectedVideo else { return }
        guard let item = player.currentItem, item.status != .failed else {
            await play(video)
            return
        }
        let currentRequest = UUID()
        requestID = currentRequest
        do {
            try AudioSessionController.configure()
            let duration = item.duration.seconds
            if duration.isFinite, duration > 0, player.currentTime().seconds >= duration {
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in continuation.resume() }
                }
            }
            guard requestID == currentRequest, player.currentItem === item, !Task.isCancelled else { return }
            state = .loading(video)
            player.play()
        } catch {
            guard requestID == currentRequest else { return }
            fail(error)
        }
    }

    private func updateNativeState() {
        guard let video = selectedVideo, let item = player.currentItem else { return }
        if case .failed = state { return }
        if item.status == .failed { fail(item.error ?? AppError.unavailable); return }
        guard item.status == .readyToPlay else { return }
        switch player.timeControlStatus {
        case .playing: state = .playing(video)
        case .paused: state = .paused(video)
        case .waitingToPlayAtSpecifiedRate: state = .loading(video)
        @unknown default: state = .loading(video)
        }
    }

    private func fail(_ error: Error) {
        player.pause()
        state = .failed(video: selectedVideo, message: AppError.classify(error).localizedDescription)
    }
}
