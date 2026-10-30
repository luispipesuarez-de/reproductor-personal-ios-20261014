import Foundation

protocol YouTubeProviding: Sendable {
    func search(query: String) async throws -> [Video]
    func searchDeep(query: String, maxPages: Int) async throws -> [Video]
    func resolve(videoID: String) async throws -> PlaybackResource
    func recommendations(seed: RecommendationSeed, continuation: String?) async throws -> RecommendationPage
    func artistCatalog(for artistName: String) async throws -> ArtistCatalog
    func albumTracks(for album: AlbumSummary) async throws -> [Video]
}

extension YouTubeProviding {
    func searchDeep(query: String, maxPages: Int = 3) async throws -> [Video] {
        try await search(query: query)
    }

    func artistCatalog(for artistName: String) async throws -> ArtistCatalog {
        let trimmed = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        async let topSongs = searchDeep(query: "\(trimmed) canciones oficiales", maxPages: 3)
        async let hits = searchDeep(query: "\(trimmed) grandes exitos", maxPages: 2)
        async let albums = searchDeep(query: "\(trimmed) album completo oficial", maxPages: 2)

        let rawTop = (try? await topSongs) ?? []
        let rawHits = (try? await hits) ?? []
        let rawAlbums = (try? await albums) ?? []

        var combined: [Video] = []
        var seenIDs: Set<String> = []
        for video in (rawTop + rawHits + rawAlbums) {
            if seenIDs.insert(video.id).inserted {
                combined.append(video)
            }
        }

        let songs = combined.prioritizingSongs()
        let groupedAlbums = combined.groupedAlbums(forArtist: trimmed)
        let thumb = songs.first?.thumbnailURL ?? rawAlbums.first?.thumbnailURL
        return ArtistCatalog(artistName: trimmed, thumbnailURL: thumb, songs: songs, albums: groupedAlbums)
    }

    func albumTracks(for album: AlbumSummary) async throws -> [Video] {
        if album.tracks.count > 1 { return album.tracks }
        let fetched = (try? await searchDeep(query: "\(album.artistName) \(album.title) canciones audio", maxPages: 2).prioritizingSongs()) ?? []
        return fetched.isEmpty ? album.tracks : fetched
    }
}
