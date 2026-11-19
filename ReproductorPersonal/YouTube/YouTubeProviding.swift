import Foundation

protocol YouTubeProviding: Sendable {
    func search(query: String) async throws -> [Video]
    func searchDeep(query: String, maxPages: Int) async throws -> [Video]
    func searchDeepWithStatus(query: String, maxPages: Int) async throws -> (videos: [Video], isPartial: Bool)
    func resolve(videoID: String) async throws -> PlaybackResource
    func recommendations(seed: RecommendationSeed, continuation: String?) async throws -> RecommendationPage
    func artistCatalog(for artistName: String) async throws -> ArtistCatalog
    func albumTracks(for album: AlbumSummary) async throws -> [Video]

    func musicSearch(query: String, filter: MusicSearchFilter?, continuation: String?) async throws -> MusicSearchResult
    func artistCatalog(artistID: String) async throws -> ArtistCatalog
    func artistReleases(artistID: String, params: String) async throws -> [AlbumSummary]
    func albumTracks(albumID: String) async throws -> [Video]
    func playlistTracks(browseID: String, continuation: String?) async throws -> RecommendationPage
}

extension YouTubeProviding {
    func searchDeep(query: String, maxPages: Int = 3) async throws -> [Video] {
        try await search(query: query)
    }

    func musicSearch(query: String, filter: MusicSearchFilter?, continuation: String?) async throws -> MusicSearchResult {
        throw AppError.unavailable
    }

    func artistCatalog(artistID: String) async throws -> ArtistCatalog {
        throw AppError.unavailable
    }

    func artistReleases(artistID: String, params: String) async throws -> [AlbumSummary] {
        throw AppError.unavailable
    }

    func albumTracks(albumID: String) async throws -> [Video] {
        throw AppError.unavailable
    }

    func playlistTracks(browseID: String, continuation: String?) async throws -> RecommendationPage {
        throw AppError.unavailable
    }

    func searchDeepWithStatus(query: String, maxPages: Int = 3) async throws -> (videos: [Video], isPartial: Bool) {
        (try await searchDeep(query: query, maxPages: maxPages), false)
    }

    func artistCatalog(for artistName: String) async throws -> ArtistCatalog {
        let trimmed = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        async let topSongs = try? searchDeepWithStatus(query: "\(trimmed) canciones oficiales", maxPages: 3)
        async let hits = try? searchDeepWithStatus(query: "\(trimmed) grandes exitos", maxPages: 2)
        async let albums = try? searchDeepWithStatus(query: "\(trimmed) album completo oficial", maxPages: 2)

        let resTop = await topSongs
        let resHits = await hits
        let resAlbums = await albums

        if resTop == nil && resHits == nil && resAlbums == nil {
            throw AppError.unavailable
        }

        let rawTop = resTop?.videos ?? []
        let rawHits = resHits?.videos ?? []
        let rawAlbums = resAlbums?.videos ?? []
        let isPartial = (resTop == nil || resTop?.isPartial == true)
            || (resHits == nil || resHits?.isPartial == true)
            || (resAlbums == nil || resAlbums?.isPartial == true)

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
        return ArtistCatalog(artistName: trimmed, thumbnailURL: thumb, songs: songs, albums: groupedAlbums, isPartial: isPartial)
    }

    func albumTracks(for album: AlbumSummary) async throws -> [Video] {
        if album.tracks.count > 1 { return album.tracks }
        let fetched = (try? await searchDeep(query: "\(album.artistName) \(album.title) canciones audio", maxPages: 2).prioritizingSongs()) ?? []
        return fetched.isEmpty ? album.tracks : fetched
    }
}
