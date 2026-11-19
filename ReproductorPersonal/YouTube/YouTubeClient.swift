import Foundation
import YouTubeKit

actor YouTubeClient: YouTubeProviding {
    private let model = YouTubeModel()
    private let music: YouTubeMusicClient

    init(music: YouTubeMusicClient = YouTubeMusicClient()) {
        self.music = music
    }

    func musicSearch(query: String, filter: MusicSearchFilter?, continuation: String?) async throws -> MusicSearchResult {
        try await music.search(query: query, filter: filter, continuation: continuation)
    }

    func artistCatalog(artistID: String) async throws -> ArtistCatalog {
        let page = try await music.browseArtist(id: artistID)
        let artistRef = page.name.isEmpty ? nil : ArtistRef(name: page.name, browseID: artistID)
        let fallbackArtists = artistRef.map { [$0] } ?? []

        async let albumsTask: [AlbumSummary]? = {
            guard let link = page.albumsMore else { return page.albums }
            return try? await music.browseReleases(browseID: link.browseID, params: link.params, artist: artistRef)
        }()
        async let singlesTask: [AlbumSummary]? = {
            guard let link = page.singlesMore else { return page.singles }
            return try? await music.browseReleases(browseID: link.browseID, params: link.params, artist: artistRef)
        }()
        async let songsTask: RecommendationPage? = {
            guard let browseID = page.allSongsBrowseID else { return nil }
            return try? await music.browsePlaylist(id: browseID, continuation: nil, fallbackArtists: fallbackArtists)
        }()

        let resolvedAlbums = await albumsTask
        let resolvedSingles = await singlesTask
        let resolvedSongs = await songsTask

        let isPartial = (page.albumsMore != nil && resolvedAlbums == nil)
            || (page.singlesMore != nil && resolvedSingles == nil)
            || (page.allSongsBrowseID != nil && resolvedSongs == nil)

        let songs = (resolvedSongs?.videos.isEmpty == false) ? (resolvedSongs?.videos ?? []) : page.topSongs
        return ArtistCatalog(
            artistName: page.name,
            thumbnailURL: page.thumbnailURL,
            songs: songs,
            albums: resolvedAlbums ?? page.albums,
            singles: resolvedSingles ?? page.singles,
            channelID: artistID,
            radioPlaylistID: page.radioPlaylistID,
            allSongsBrowseID: page.allSongsBrowseID,
            songsContinuation: resolvedSongs?.continuation,
            isPartial: isPartial
        )
    }

    func artistReleases(artistID: String, params: String) async throws -> [AlbumSummary] {
        try await music.browseReleases(browseID: artistID, params: params, artist: nil)
    }

    func albumTracks(albumID: String) async throws -> [Video] {
        try await music.browseAlbum(id: albumID).tracks
    }

    func playlistTracks(browseID: String, continuation: String?) async throws -> RecommendationPage {
        try await music.browsePlaylist(id: browseID, continuation: continuation)
    }

    func recommendations(seed: RecommendationSeed, continuation: String?) async throws -> RecommendationPage {
        do {
            switch seed {
            case .video(let id), .track(let id, _, _):
                if let page = try? await music.radio(
                    videoID: continuation == nil ? id : nil,
                    playlistID: continuation == nil ? "RDAMVM\(id)" : nil,
                    continuation: continuation
                ) {
                    let filtered = page.videos.filter { $0.id != id }
                    if !filtered.isEmpty || page.continuation != nil {
                        return RecommendationPage(videos: filtered, continuation: page.continuation)
                    }
                }
                _ = try await anonymousVisitor(videoID: id)
                if let continuation {
                    let page = try await MoreVideoInfosResponse.RecommendedVideosContinuation.sendThrowingRequest(
                        youtubeModel: model, data: [.continuation: continuation], useCookies: false
                    )
                    return RecommendationPage(videos: YouTubeMapping.videos(from: page.results, candidatesOnly: true), continuation: page.continuationToken)
                }
                let page = try await MoreVideoInfosResponse.sendThrowingRequest(
                    youtubeModel: model, data: [.query: id], useCookies: false
                )
                return RecommendationPage(videos: YouTubeMapping.videos(from: page.recommendedVideos, candidatesOnly: true), continuation: page.recommendedVideosContinuationToken)

            case .artist(let channelID, let name, let radioPlaylistID):
                if let continuation,
                   let page = try? await music.radio(videoID: nil, playlistID: nil, continuation: continuation),
                   (!page.videos.isEmpty || page.continuation != nil) {
                    return page
                }
                if continuation == nil {
                    var targetPlaylistID = radioPlaylistID
                    var seedVideoID: String?
                    if targetPlaylistID == nil, !channelID.isEmpty,
                       let catalog = try? await artistCatalog(artistID: channelID) {
                        targetPlaylistID = catalog.radioPlaylistID
                        seedVideoID = catalog.songs.first?.id
                    }
                    if let targetPlaylistID,
                       let page = try? await music.radio(videoID: nil, playlistID: targetPlaylistID, continuation: nil),
                       (!page.videos.isEmpty || page.continuation != nil) {
                        return page
                    }
                    if let seedVideoID,
                       let page = try? await music.radio(videoID: seedVideoID, playlistID: "RDAMVM\(seedVideoID)", continuation: nil) {
                        let filtered = page.videos.filter { $0.id != seedVideoID }
                        if !filtered.isEmpty || page.continuation != nil {
                            return RecommendationPage(videos: filtered, continuation: page.continuation)
                        }
                    }
                }
                let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return RecommendationPage(videos: [], continuation: nil) }
                if let continuation {
                    let page = try await SearchResponse.Continuation.sendThrowingRequest(
                        youtubeModel: model, data: [.continuation: continuation], useCookies: false
                    )
                    return RecommendationPage(videos: YouTubeMapping.videos(from: page.results, candidatesOnly: true), continuation: page.continuationToken)
                }
                let page = try await SearchResponse.sendThrowingRequest(
                    youtubeModel: model, data: [.query: "\(trimmed) canciones oficiales"], useCookies: false
                )
                if let visitor = page.visitorData, !visitor.isEmpty { model.visitorData = visitor }
                return RecommendationPage(videos: YouTubeMapping.videos(from: page.results, candidatesOnly: true), continuation: page.continuationToken)

            case .genre(let genre):
                let trimmed = genre.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return RecommendationPage(videos: [], continuation: nil) }
                let excludesSoul = isMerengue(trimmed)
                if let result = try? await music.search(query: Self.genreQuery(for: trimmed), filter: .songs, continuation: continuation) {
                    let songs = result.songs.filter { !(excludesSoul && $0.containsSoulReference) }
                    if !songs.isEmpty {
                        return RecommendationPage(videos: songs, continuation: result.continuation)
                    }
                }
                if let continuation {
                    let page = try await SearchResponse.Continuation.sendThrowingRequest(
                        youtubeModel: model, data: [.continuation: continuation], useCookies: false
                    )
                    return RecommendationPage(videos: YouTubeMapping.videos(from: page.results, candidatesOnly: true, excludingSoul: excludesSoul), continuation: page.continuationToken)
                }
                let page = try await SearchResponse.sendThrowingRequest(
                    youtubeModel: model, data: [.query: Self.genreQuery(for: trimmed)], useCookies: false
                )
                if let visitor = page.visitorData, !visitor.isEmpty { model.visitorData = visitor }
                return RecommendationPage(videos: YouTubeMapping.videos(from: page.results, candidatesOnly: true, excludingSoul: excludesSoul), continuation: page.continuationToken)
            }
        } catch { throw AppError.classify(error) }
    }

    func search(query: String) async throws -> [Video] {
        do {
            let response = try await SearchResponse.sendThrowingRequest(
                youtubeModel: model, data: [.query: query], useCookies: false
            )
            if let visitor = response.visitorData, !visitor.isEmpty { model.visitorData = visitor }
            return YouTubeMapping.videos(from: response)
        } catch {
            throw AppError.classify(error)
        }
    }

    func searchDeep(query: String, maxPages: Int = 3) async throws -> [Video] {
        try await searchDeepWithStatus(query: query, maxPages: maxPages).videos
    }

    func searchDeepWithStatus(query: String, maxPages: Int = 3) async throws -> (videos: [Video], isPartial: Bool) {
        do {
            let initial = try await SearchResponse.sendThrowingRequest(
                youtubeModel: model, data: [.query: query], useCookies: false
            )
            if let visitor = initial.visitorData, !visitor.isEmpty { model.visitorData = visitor }
            var results = YouTubeMapping.videos(from: initial)
            var nextToken = initial.continuationToken
            var pagesFetched = 1
            var isPartial = false
            while let token = nextToken, pagesFetched < maxPages {
                do {
                    let nextPage = try await SearchResponse.Continuation.sendThrowingRequest(
                        youtubeModel: model, data: [.continuation: token], useCookies: false
                    )
                    let newVideos = YouTubeMapping.videos(from: nextPage.results, candidatesOnly: false)
                    if newVideos.isEmpty { break }
                    results.append(contentsOf: newVideos)
                    nextToken = nextPage.continuationToken
                    pagesFetched += 1
                } catch {
                    isPartial = true
                    break
                }
            }
            return (results, isPartial)
        } catch {
            throw AppError.classify(error)
        }
    }

    func resolve(videoID: String) async throws -> PlaybackResource {
        do {
            _ = try await anonymousVisitor(videoID: videoID)
            let response = try await VideoInfosWithDownloadFormatsResponse.sendThrowingRequest(
                youtubeModel: model, data: [.query: videoID], useCookies: false
            )
            let expiresAt = response.videoInfos.videoURLsExpireAt
            var decoder: PlayerProcessing.Player?
            var decoderAttempted = false
            var processingFailure: Error?
            if let resource = try? YouTubeMapping.resource(
                hlsURL: response.videoInfos.streamingURL, combinedURLs: [], expiresAt: expiresAt
            ) {
                if !needsProcessing(resource.url) { return resource }
                do {
                    decoderAttempted = true
                    let player = try await webPlayer(videoID: videoID)
                    decoder = player
                    var carrier: any AdaptiveDownloadFormat = VideoDownloadFormat(url: resource.url)
                    try player.processDownloadFormatURL(item: &carrier)
                    guard let url = carrier.url else { throw AppError.resolutionFailed }
                    let decoded = player.decodeNParameterInHLSManifestURL(url.absoluteString)
                    // This API silently returns the input when its HLS solver fails.
                    if url.path.contains("/n/"), decoded == url { throw AppError.resolutionFailed }
                    return try YouTubeMapping.resource(hlsURL: decoded, combinedURLs: [], expiresAt: expiresAt)
                } catch { processingFailure = error }
            }

            // Default formats are muxed. These itags contain native H.264 + AAC.
            let candidates = response.defaultFormats.filter {
                $0 is VideoDownloadFormat && $0.mimeType == "video/mp4" && [18, 22, 37].contains($0.itag)
            }
            let directURLs = candidates.compactMap { format -> URL? in
                guard format.signatureCipher == nil, let url = format.url, !needsProcessing(url) else { return nil }
                return url
            }
            if let direct = try? YouTubeMapping.resource(hlsURL: nil, combinedURLs: directURLs, expiresAt: expiresAt) {
                return direct
            }

            let encrypted = candidates.filter {
                $0.signatureCipher != nil || $0.url.map(needsProcessing) == true
            }
            if !encrypted.isEmpty, !decoderAttempted {
                do { decoder = try await webPlayer(videoID: videoID) }
                catch { processingFailure = error }
            }
            var processedURLs: [URL] = []
            if let decoder {
                for var format in encrypted {
                    do {
                        try decoder.processDownloadFormatURL(item: &format)
                        if let url = format.url { processedURLs.append(url) }
                    } catch { processingFailure = error }
                }
            }
            if let resource = try? YouTubeMapping.resource(hlsURL: nil, combinedURLs: processedURLs, expiresAt: expiresAt) { return resource }
            if response.videoInfos.serverAbrStreamingURL != nil {
                return try await nativeHLS(videoID: videoID)
            }
            if let processingFailure { throw processingFailure }
            throw AppError.unavailable
        } catch is ResponseExtractionError {
            throw AppError.unavailable
        } catch {
            throw AppError.classify(error)
        }
    }

    private func nativeHLS(videoID: String) async throws -> PlaybackResource {
        let visitor = try await anonymousVisitor(videoID: videoID)
        // Native HLS profile checked against public content on 2026-10-14.
        // Reference: yt-dlp/extractor/youtube/_base.py, VISIONOS client.
        let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
        let body: [String: Any] = [
            "context": ["client": [
                "clientName": "VISIONOS", "clientVersion": "1.02",
                "deviceMake": "Apple", "deviceModel": "RealityDevice17,1",
                "osName": "visionOS", "osVersion": "26.5.23O471",
                "userAgent": userAgent, "hl": model.selectedLocaleLanguageCode,
                "visitorData": visitor
            ]],
            "videoId": videoID, "contentCheckOk": true, "racyCheckOk": true
        ]
        var request = URLRequest(url: URL(string: "https://www.youtube.com/youtubei/v1/player?prettyPrint=false")!, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("101", forHTTPHeaderField: "X-Youtube-Client-Name")
        request.setValue("1.02", forHTTPHeaderField: "X-Youtube-Client-Version")
        request.setValue(visitor, forHTTPHeaderField: "X-Goog-Visitor-Id")
        let data = try await anonymousData(for: request)
        let response = try VideoInfosWithDownloadFormatsResponse.decodeData(data: data)
        return try YouTubeMapping.resource(
            hlsURL: response.videoInfos.streamingURL, combinedURLs: [],
            expiresAt: response.videoInfos.videoURLsExpireAt
        )
    }

    private func anonymousVisitor(videoID: String) async throws -> String {
        if !model.visitorData.isEmpty { return model.visitorData }
        // Saved entries can be opened before Search has initialized the client.
        // Use the existing API instead of the rate-limited watch-page bootstrap.
        let response = try await SearchResponse.sendThrowingRequest(
            youtubeModel: model, data: [.query: videoID], useCookies: false
        )
        guard let visitor = response.visitorData, !visitor.isEmpty else { throw AppError.unavailable }
        model.visitorData = visitor
        return visitor
    }

    private func anonymousData(for request: URLRequest) async throws -> Data {
        var request = request
        request.httpShouldHandleCookies = false
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw AppError.resolutionFailed
        }
        return data
    }

    private func webPlayer(videoID: String) async throws -> PlayerProcessing.Player {
        let response = try await VideoInfosResponse.sendThrowingRequest(
            youtubeModel: model, data: [.query: videoID], useCookies: false
        )
        guard let player = response.player else { throw AppError.resolutionFailed }
        return player
    }

    private func needsProcessing(_ url: URL) -> Bool {
        url.path.contains("/n/") || URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.contains(where: { $0.name == "n" }) == true
    }

    static func genreQuery(for genre: String) -> String {
        let trimmed = genre.trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalizedGenre(trimmed) {
        case "merengue": return "música merengue clásico éxitos oficiales"
        case "blues": return "classic blues music official audio hits"
        default: return "música \(trimmed) canciones"
        }
    }

    private func isMerengue(_ genre: String) -> Bool {
        Self.normalizedGenre(genre) == "merengue"
    }

    private static func normalizedGenre(_ genre: String) -> String {
        genre.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
