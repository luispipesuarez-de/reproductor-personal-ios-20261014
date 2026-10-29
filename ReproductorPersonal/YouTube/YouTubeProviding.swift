import Foundation

protocol YouTubeProviding: Sendable {
    func search(query: String) async throws -> [Video]
    func resolve(videoID: String) async throws -> PlaybackResource
    func recommendations(seed: RecommendationSeed, continuation: String?) async throws -> RecommendationPage
    func artistCatalog(for artistName: String) async throws -> ArtistCatalog
    func albumTracks(for album: AlbumSummary) async throws -> [Video]
}

extension YouTubeProviding {
    func artistCatalog(for artistName: String) async throws -> ArtistCatalog {
        let trimmed = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        async let songsSearch = search(query: "\(trimmed) canciones oficiales audio")
        async let albumsSearch = search(query: "\(trimmed) álbum completo oficial")
        let rawSongs = (try? await songsSearch) ?? []
        let rawAlbums = (try? await albumsSearch) ?? []
        let combined = rawSongs + rawAlbums
        let songs = (rawSongs.isEmpty ? combined : rawSongs).prioritizingSongs()
        let albums = combined.groupedAlbums(forArtist: trimmed)
        let thumb = songs.first?.thumbnailURL ?? rawAlbums.first?.thumbnailURL
        return ArtistCatalog(artistName: trimmed, thumbnailURL: thumb, songs: songs, albums: albums)
    }

    func albumTracks(for album: AlbumSummary) async throws -> [Video] {
        if album.tracks.count > 1 { return album.tracks }
        let fetched = (try? await search(query: "\(album.artistName) \(album.title) canciones audio").prioritizingSongs()) ?? []
        return fetched.isEmpty ? album.tracks : fetched
    }
}
