import Combine

enum SearchState: Equatable {
    case idle
    case loading(query: String)
    case results(query: String, videos: [Video])
    case empty(query: String)
    case failed(query: String, message: String)
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var state: SearchState = .idle

    init(source: any YouTubeProviding) {}
    func submit(query: String) async {}
}
