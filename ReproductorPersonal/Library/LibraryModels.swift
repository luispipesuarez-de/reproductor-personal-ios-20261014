import Foundation

struct LocalPlaylist: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var videos: [Video]

    init(id: UUID = UUID(), name: String, videos: [Video] = []) {
        self.id = id
        self.name = name
        self.videos = videos
    }
}

struct BlockedChannel: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let name: String
    let isChannelID: Bool
}

struct LibrarySnapshot: Codable, Equatable, Sendable {
    var schemaVersion: Int = 1
    var favorites: [Video] = []
    var liked: [Video] = []
    var loved: [Video] = []
    var disliked: [Video] = []
    var hated: [Video] = []
    var playlists: [LocalPlaylist] = []
    var recent: [Video] = []
    var queue: QueueSnapshot?
    var customGenres: [String] = []
    var blockedChannels: [BlockedChannel] = []

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, favorites, liked, loved, disliked, hated, playlists, recent, queue, customGenres, blockedChannels
    }
}

private struct LossyArray<Element: Decodable>: Decodable {
    let elements: [Element]

    private struct AnyDecodable: Decodable {}

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var items: [Element] = []
        while !container.isAtEnd {
            if let item = try? container.decode(Element.self) {
                items.append(item)
            } else {
                _ = try? container.decode(AnyDecodable.self)
            }
        }
        self.elements = items
    }
}

extension LibrarySnapshot {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decode(Int.self, forKey: .schemaVersion)
        let favorites = (try values.decodeIfPresent(LossyArray<Video>.self, forKey: .favorites))?.elements ?? []
        let liked = (try values.decodeIfPresent(LossyArray<Video>.self, forKey: .liked))?.elements ?? []
        let loved = (try values.decodeIfPresent(LossyArray<Video>.self, forKey: .loved))?.elements ?? []
        let disliked = (try values.decodeIfPresent(LossyArray<Video>.self, forKey: .disliked))?.elements ?? []
        let hated = (try values.decodeIfPresent(LossyArray<Video>.self, forKey: .hated))?.elements ?? []
        let playlists = (try values.decodeIfPresent(LossyArray<LocalPlaylist>.self, forKey: .playlists))?.elements ?? []
        let recent = (try values.decodeIfPresent(LossyArray<Video>.self, forKey: .recent))?.elements ?? []
        // Una cola guardada incompatible nunca debe bloquear favoritos, listas ni preferencias.
        let queue = try? values.decodeIfPresent(QueueSnapshot.self, forKey: .queue)
        let customGenres = (try values.decodeIfPresent([String].self, forKey: .customGenres)) ?? []
        let blockedChannels = (try values.decodeIfPresent(LossyArray<BlockedChannel>.self, forKey: .blockedChannels))?.elements ?? []

        self.init(schemaVersion: version,
                  favorites: favorites,
                  liked: liked,
                  loved: loved,
                  disliked: disliked,
                  hated: hated,
                  playlists: playlists,
                  recent: recent,
                  queue: queue,
                  customGenres: customGenres,
                  blockedChannels: blockedChannels)
    }
}
