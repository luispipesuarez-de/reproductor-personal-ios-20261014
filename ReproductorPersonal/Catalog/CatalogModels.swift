import Foundation

/// Artista tal como lo expone el catálogo (nombre + identificador de canal/artista `UC…`).
struct ArtistRef: Codable, Equatable, Hashable, Sendable {
    let name: String
    let browseID: String?

    init(name: String, browseID: String? = nil) {
        self.name = name
        self.browseID = browseID
    }
}

/// Álbum al que pertenece una pista (`MPREb_…`).
struct AlbumRef: Codable, Equatable, Hashable, Sendable {
    let title: String
    let browseID: String?

    init(title: String, browseID: String? = nil) {
        self.title = title
        self.browseID = browseID
    }
}

/// Tipo de pista según el catálogo de YouTube Music.
/// - `atv`: pista de catálogo (audio entregado por sello o distribuidor).
/// - `omv`: videoclip oficial.
/// - `ugc`: contenido subido por usuarios.
enum MusicVideoType: String, Codable, Equatable, Sendable {
    case atv, omv, ugc, other

    init(youTubeMusicValue value: String?) {
        switch value {
        case "MUSIC_VIDEO_TYPE_ATV": self = .atv
        case "MUSIC_VIDEO_TYPE_OMV": self = .omv
        case "MUSIC_VIDEO_TYPE_UGC": self = .ugc
        default: self = .other
        }
    }
}

/// De dónde salió el metadato de un `Video`.
enum CatalogSource: String, Codable, Equatable, Sendable {
    case youtubeMusic, youtubeWeb
}
