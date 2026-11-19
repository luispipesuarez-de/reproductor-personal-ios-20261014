import Foundation

/// Filtro de la búsqueda de YouTube Music. Los `params` son los de los chips que devuelve el propio servicio.
enum MusicSearchFilter: String, Equatable, Sendable {
    case songs, albums, artists, videos

    var params: String {
        switch self {
        case .songs: return "EgWKAQIIAWoSEAUQAxAJEAQQEBAKEA4QFRAR"
        case .albums: return "EgWKAQIYAWoSEAUQAxAJEAQQEBAKEA4QFRAR"
        case .artists: return "EgWKAQIgAWoSEAUQAxAJEAQQEBAKEA4QFRAR"
        case .videos: return "EgWKAQIQAWoSEAUQAxAJEAQQEBAKEA4QFRAR"
        }
    }
}

struct MusicSearchResult: Equatable, Sendable {
    var topArtist: ArtistSummary?
    var songs: [Video]
    var videos: [Video]
    var albums: [AlbumSummary]
    var artists: [ArtistSummary]
    var continuation: String?

    init(topArtist: ArtistSummary? = nil, songs: [Video] = [], videos: [Video] = [], albums: [AlbumSummary] = [],
         artists: [ArtistSummary] = [], continuation: String? = nil) {
        self.topArtist = topArtist
        self.songs = songs
        self.videos = videos
        self.albums = albums
        self.artists = artists
        self.continuation = continuation
    }

    var isEmpty: Bool { songs.isEmpty && videos.isEmpty && albums.isEmpty && artists.isEmpty && topArtist == nil }
}

/// Enlace de «Ver todo» de una sección de la página de artista.
struct BrowseLink: Equatable, Sendable {
    let browseID: String
    let params: String?
}

struct ParsedArtistPage: Equatable, Sendable {
    var name: String = ""
    var thumbnailURL: URL?
    var radioPlaylistID: String?
    var radioVideoID: String?
    var topSongs: [Video] = []
    var allSongsBrowseID: String?
    var albums: [AlbumSummary] = []
    var singles: [AlbumSummary] = []
    var albumsMore: BrowseLink?
    var singlesMore: BrowseLink?
}

struct ParsedAlbum: Equatable, Sendable {
    var album: AlbumSummary
    var tracks: [Video]
}
