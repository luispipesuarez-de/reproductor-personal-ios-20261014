import SwiftUI

@main
@MainActor
struct ReproductorPersonalApp: App {
    @StateObject private var search: SearchViewModel
    @StateObject private var playback: PlaybackController

    init() {
        let source = YouTubeClient()
        _search = StateObject(wrappedValue: SearchViewModel(source: source))
        _playback = StateObject(wrappedValue: PlaybackController(source: source))
    }

    var body: some Scene {
        WindowGroup { SearchView(search: search, playback: playback) }
    }
}
