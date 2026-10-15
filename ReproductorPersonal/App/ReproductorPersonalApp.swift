import SwiftUI

@main
@MainActor
struct ReproductorPersonalApp: App {
    @StateObject private var search: SearchViewModel
    @StateObject private var playback: PlaybackController

    init() {
        let source: any YouTubeProviding
#if DEBUG
        source = ProcessInfo.processInfo.arguments.contains("--ui-testing") ? UITestYouTubeProvider() : YouTubeClient()
#else
        source = YouTubeClient()
#endif
        _search = StateObject(wrappedValue: SearchViewModel(source: source))
        _playback = StateObject(wrappedValue: PlaybackController(source: source))
    }

    var body: some Scene {
        WindowGroup {
            SearchView(search: search, playback: playback)
#if DEBUG
                .modifier(UITestAppearance())
#endif
        }
    }
}

#if DEBUG
private struct UITestAppearance: ViewModifier {
    @Environment(\.dynamicTypeSize) private var size
    private let arguments = ProcessInfo.processInfo.arguments
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(arguments.contains("--ui-testing") && arguments.contains("--ui-large-text") ? .accessibility3 : size)
            .preferredColorScheme(arguments.contains("--ui-testing") && arguments.contains("--ui-dark") ? .dark : nil)
    }
}
#endif
