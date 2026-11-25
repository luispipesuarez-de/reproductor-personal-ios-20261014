import Combine
import Foundation

enum DiscoveryState: Equatable {
    case idle
    case loading
    case ready(recommended: [Video], discover: [Video])
    case failed(String)
}

@MainActor
final class DiscoveryViewModel: ObservableObject {
    @Published private(set) var state: DiscoveryState = .idle
    private let source: any YouTubeProviding
    private var requestID = UUID()

    init(source: any YouTubeProviding) { self.source = source }

    func refresh(favorites: [Video], recent: [Video]) async {
        await refresh(favorites: favorites, likes: [], dislikedIDs: [], recent: recent)
    }

    func refresh(favorites: [Video], likes: [Video], loved: [Video] = [], dislikedIDs: Set<String>, recent: [Video],
                 blockedChannelIDs: Set<String> = [], blockedArtistNames: Set<String> = []) async {
        requestID = UUID()
        let token = requestID
        var seedIDs: Set<String> = []
        let references: [Video]
        if !loved.isEmpty || !likes.isEmpty {
            references = loved + likes + favorites + recent
        } else {
            references = Array(recent.prefix(1)) + favorites + Array(recent.dropFirst())
        }
        let seeds = references.filter { !dislikedIDs.contains($0.id) && seedIDs.insert($0.id).inserted }.prefix(2)
        guard !seeds.isEmpty else { state = .idle; return }
        state = .loading
        let heard = Set(recent.map(\.id))
        var candidates: [Video] = []
        var seen: Set<String> = []
        do {
            for seed in seeds {
                var cursor: String?
                for _ in 0..<3 {
                    guard requestID == token, !Task.isCancelled else { return }
                    let page: RecommendationPage
                    do { page = try await source.recommendations(seed: RecommendationSeed.forVideo(seed), continuation: cursor) }
                    catch {
                        guard requestID == token, !Task.isCancelled else { return }
                        guard !candidates.isEmpty else { throw error }
                        break
                    }
                    guard requestID == token, !Task.isCancelled else { return }
                    let filtered = page.videos.filter { video in
                        guard !dislikedIDs.contains(video.id),
                              !isBlocked(video, ids: blockedChannelIDs, names: blockedArtistNames),
                              TrackAuthenticity.assess(video).tier != .suspicious else { return false }
                        return seen.insert(video.id).inserted
                    }
                    candidates.append(contentsOf: filtered)
                    cursor = page.continuation
                    if cursor == nil || candidates.filter({ $0.isPreferredSong && !heard.contains($0.id) }).count >= 12 { break }
                }
            }
            state = .ready(recommended: Array(variedAuthors(candidates).prioritizingSongs().prefix(12)),
                           discover: Array(variedAuthors(candidates.filter { !heard.contains($0.id) }).prioritizingSongs().prefix(12)))
        } catch {
            guard requestID == token, !Task.isCancelled else { return }
            state = .failed(AppError.classify(error).localizedDescription)
        }
    }

    private func isBlocked(_ video: Video, ids: Set<String>, names: Set<String>) -> Bool {
        if let cid = video.channelID, ids.contains(cid) { return true }
        if let refs = video.artistRefs, refs.contains(where: { $0.browseID.map(ids.contains) == true }) { return true }
        let name = video.canonicalArtistName
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return names.contains(name)
    }

    private func variedAuthors(_ videos: [Video]) -> [Video] {
        var authors: Set<String> = []
        var first: [Video] = []
        var repeated: [Video] = []
        for video in videos {
            if authors.insert(video.author.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()).inserted { first.append(video) }
            else { repeated.append(video) }
        }
        return first + repeated
    }
}
