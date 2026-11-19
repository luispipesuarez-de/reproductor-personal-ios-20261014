import Foundation

enum RecommendationSeed: Codable, Equatable, Sendable {
    case video(String)
    case genre(String)
    case track(videoID: String, artistIDs: [String], artistNames: [String])
    case artist(channelID: String, name: String, radioPlaylistID: String?)

    var artistIdentity: ArtistIdentity? {
        switch self {
        case .artist(let channelID, let name, _):
            return ArtistIdentity(name: name, browseIDs: channelID.isEmpty ? [] : [channelID])
        case .track(_, let ids, let names):
            guard let first = names.first else { return nil }
            return ArtistIdentity(name: first, browseIDs: Set(ids))
        case .video, .genre:
            return nil
        }
    }

    static func forVideo(_ video: Video) -> RecommendationSeed {
        let refs = video.artistRefs ?? []
        let ids = refs.compactMap(\.browseID)
        let names = refs.map(\.name)
        if !ids.isEmpty || !names.isEmpty {
            return .track(videoID: video.id, artistIDs: ids, artistNames: names)
        }
        return .video(video.id)
    }
}

struct RecommendationPage: Equatable, Sendable {
    let videos: [Video]
    let continuation: String?
}
