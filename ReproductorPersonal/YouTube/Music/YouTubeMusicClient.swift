import Foundation

/// Cliente anónimo sin cookies contra los endpoints `youtubei/v1/{search,browse,next}` de YouTube Music (`WEB_REMIX`).
/// No requiere claves de API ni suscripción. Si la fuente cambia o falla, el llamador debe recurrir al respaldo de YouTubeKit.
actor YouTubeMusicClient {
    static let defaultCountry = "AR"
    static let defaultClientVersion = "1.20261110.01.00"
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    private let country: String
    private let language: String
    private let clientVersion: String
    private let transport: Transport
    private let now: @Sendable () -> Date
    private var visitorData: String?
    private var browseCache: [String: (data: Data, expiresAt: Date)] = [:]
    private let cacheTTL: TimeInterval = 30 * 60
    private let maxCacheEntries = 50

    init(country: String = YouTubeMusicClient.defaultCountry,
         language: String? = nil,
         clientVersion: String = YouTubeMusicClient.defaultClientVersion,
         now: @escaping @Sendable () -> Date = Date.init,
         transport: Transport? = nil) {
        self.country = country
        self.language = language ?? Self.preferredLanguageCode()
        self.clientVersion = clientVersion
        self.now = now
        self.transport = transport ?? { request in try await URLSession.shared.data(for: request) }
    }

    // MARK: - API de alto nivel

    func search(query: String, filter: MusicSearchFilter?, continuation: String?) async throws -> MusicSearchResult {
        var body: [String: Any] = [:]
        if let continuation, !continuation.isEmpty {
            body["continuation"] = continuation
        } else {
            body["query"] = query
            if let filter { body["params"] = filter.params }
        }
        let json = try await post("search", body: body)
        return YTMusicParser.parseSearch(json)
    }

    func browseArtist(id: String) async throws -> ParsedArtistPage {
        let json = try await postBrowse(browseID: id, params: nil, continuation: nil)
        return YTMusicParser.parseArtistPage(json, artistID: id)
    }

    func browseReleases(browseID: String, params: String?, artist: ArtistRef?) async throws -> [AlbumSummary] {
        let json = try await postBrowse(browseID: browseID, params: params, continuation: nil)
        return YTMusicParser.parseReleases(json, artist: artist)
    }

    func browseAlbum(id: String) async throws -> ParsedAlbum {
        let json = try await postBrowse(browseID: id, params: nil, continuation: nil)
        return YTMusicParser.parseAlbum(json, browseID: id)
    }

    func browsePlaylist(id: String, continuation: String?, fallbackArtists: [ArtistRef] = []) async throws -> RecommendationPage {
        let json = try await postBrowse(browseID: continuation == nil ? id : nil, params: nil, continuation: continuation)
        return YTMusicParser.parseTrackList(json, fallbackArtists: fallbackArtists)
    }

    func radio(videoID: String?, playlistID: String?, continuation: String?) async throws -> RecommendationPage {
        var body: [String: Any] = [:]
        if let continuation, !continuation.isEmpty {
            body["continuation"] = continuation
        } else {
            if let videoID, !videoID.isEmpty { body["videoId"] = videoID }
            if let playlistID, !playlistID.isEmpty { body["playlistId"] = playlistID }
            body["isAudioOnly"] = true
        }
        let json = try await post("next", body: body)
        return YTMusicParser.parseRadio(json)
    }

    // MARK: - Transporte HTTP y caché

    func postBrowse(browseID: String?, params: String?, continuation: String?) async throws -> [String: Any] {
        if continuation == nil, let browseID {
            let key = "\(browseID)|\(params ?? "")"
            if let cached = browseCache[key], cached.expiresAt > now(),
               let obj = try? JSONSerialization.jsonObject(with: cached.data) as? [String: Any] {
                return obj
            }
            let (obj, rawData) = try await postRaw("browse", body: browseBody(browseID: browseID, params: params, continuation: nil))
            storeInCache(key: key, data: rawData)
            return obj
        }
        return try await post("browse", body: browseBody(browseID: browseID, params: params, continuation: continuation))
    }

    func post(_ endpoint: String, body: [String: Any]) async throws -> [String: Any] {
        try await postRaw(endpoint, body: body).0
    }

    private func postRaw(_ endpoint: String, body: [String: Any]) async throws -> ([String: Any], Data) {
        guard let url = URL(string: "https://music.youtube.com/youtubei/v1/\(endpoint)?prettyPrint=false") else {
            throw AppError.resolutionFailed
        }
        var payload = body
        var clientContext: [String: Any] = [
            "clientName": "WEB_REMIX",
            "clientVersion": clientVersion,
            "hl": language,
            "gl": country
        ]
        if let visitorData, !visitorData.isEmpty {
            clientContext["visitorData"] = visitorData
        }
        payload["context"] = ["client": clientContext]

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.httpShouldHandleCookies = false
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("https://music.youtube.com", forHTTPHeaderField: "Origin")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        if let visitorData, !visitorData.isEmpty {
            request.setValue(visitorData, forHTTPHeaderField: "X-Goog-Visitor-Id")
        }

        do {
            let (data, response) = try await transport(request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw AppError.resolutionFailed
            }
            guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw AppError.resolutionFailed
            }
            if let rc = object["responseContext"] as? [String: Any],
               let visitor = rc["visitorData"] as? String, !visitor.isEmpty {
                visitorData = visitor
            }
            return (object, data)
        } catch {
            throw AppError.classify(error)
        }
    }

    private func browseBody(browseID: String?, params: String?, continuation: String?) -> [String: Any] {
        var body: [String: Any] = [:]
        if let continuation, !continuation.isEmpty {
            body["continuation"] = continuation
        } else {
            if let browseID { body["browseId"] = browseID }
            if let params { body["params"] = params }
        }
        return body
    }

    private func storeInCache(key: String, data: Data) {
        let current = now()
        browseCache = browseCache.filter { $0.value.expiresAt > current }
        if browseCache.count >= maxCacheEntries, let oldest = browseCache.min(by: { $0.value.expiresAt < $1.value.expiresAt })?.key {
            browseCache.removeValue(forKey: oldest)
        }
        browseCache[key] = (data: data, expiresAt: current.addingTimeInterval(cacheTTL))
    }

    private static func preferredLanguageCode() -> String {
        guard let first = Locale.preferredLanguages.first, !first.isEmpty else { return "es" }
        let code = first.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? "es"
        return code.isEmpty ? "es" : code.lowercased()
    }
}
