import Foundation

/// Convierte las respuestas anónimas de music.youtube.com (`search`, `browse`, `next`) en los modelos de la app.
/// Es puro y tolerante: lo desconocido se ignora y una respuesta vacía o inesperada produce resultados vacíos, nunca un fallo.
enum YTMusicParser {
    private static let artistPageTypes: Set<String> = ["MUSIC_PAGE_TYPE_ARTIST", "MUSIC_PAGE_TYPE_USER_CHANNEL"]
    private static let albumPageType = "MUSIC_PAGE_TYPE_ALBUM"

    // MARK: - Búsqueda

    static func parseSearch(_ root: Any?) -> MusicSearchResult {
        let json = JSONNode(root)
        var result = MusicSearchResult()
        var seenVideos: Set<String> = []
        var seenAlbums: Set<String> = []
        var seenArtists: Set<String> = []

        if let card = json.collect("musicCardShelfRenderer").first,
           let id = card["title"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string,
           isArtistEndpoint(card["title"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]) {
            let name = card["title"]["runs"].runsText
            let artist = artistSummary(name: name, id: id, thumbnails: card["thumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"])
            result.topArtist = artist
            seenArtists.insert(id)
        }

        for item in json.collect("musicResponsiveListItemRenderer") {
            if let video = listItemVideo(item) {
                guard seenVideos.insert(video.id).inserted else { continue }
                if video.musicVideoType == .atv { result.songs.append(video) } else { result.videos.append(video) }
            } else if let artist = searchArtist(item) {
                if seenArtists.insert(artist.id).inserted { result.artists.append(artist) }
            } else if let album = searchAlbum(item) {
                if seenAlbums.insert(album.id).inserted { result.albums.append(album) }
            }
        }
        result.continuation = continuationToken(json)
        return result
    }

    // MARK: - Página de artista

    static func parseArtistPage(_ root: Any?, artistID: String?) -> ParsedArtistPage {
        let json = JSONNode(root)
        var page = ParsedArtistPage()
        let header = json.collect("musicImmersiveHeaderRenderer").first
            ?? json.collect("musicVisualHeaderRenderer").first ?? JSONNode(nil)
        page.name = header["title"]["runs"].runsText
        page.thumbnailURL = thumbnail(header["thumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"])
            ?? thumbnail(header["foregroundThumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"])
        let radio = header["startRadioButton"]["buttonRenderer"]["navigationEndpoint"]["watchEndpoint"]
        page.radioPlaylistID = radio["playlistId"].string
        page.radioVideoID = radio["videoId"].string

        let artist = ArtistRef(name: page.name, browseID: artistID)
        let fallbackArtists = page.name.isEmpty ? [] : [artist]
        if let shelf = json.collect("musicShelfRenderer").first {
            page.topSongs = shelf["contents"].array.compactMap {
                listItemVideo($0["musicResponsiveListItemRenderer"], fallbackArtists: fallbackArtists)
            }
            page.allSongsBrowseID = shelf["title"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]["browseId"].string
        }

        for shelf in json.collect("musicCarouselShelfRenderer") {
            let headerNode = shelf["header"]["musicCarouselShelfBasicHeaderRenderer"]
            let title = fold(headerNode["title"]["runs"].runsText)
            let isAlbums = title.contains("album")
            let isSingles = title.contains("single") || title.contains("sencillo")
            guard isAlbums || isSingles else { continue }

            let moreEndpoint = headerNode["moreContentButton"]["buttonRenderer"]["navigationEndpoint"]["browseEndpoint"]
            let endpoint = moreEndpoint["browseId"].string != nil ? moreEndpoint : headerNode["title"]["runs"][0]["navigationEndpoint"]["browseEndpoint"]
            let link = endpoint["browseId"].string.map { BrowseLink(browseID: $0, params: endpoint["params"].string) }
            let items = shelf["contents"].array.compactMap { albumSummary(fromTwoRow: $0["musicTwoRowItemRenderer"], artist: artist) }

            if isAlbums, page.albums.isEmpty, page.albumsMore == nil { page.albums = items; page.albumsMore = link }
            else if isSingles, page.singles.isEmpty, page.singlesMore == nil { page.singles = items; page.singlesMore = link }
        }
        return page
    }

    /// Lista completa de álbumes o de sencillos y EP (`browse` con el `params` de «Ver todo»).
    static func parseReleases(_ root: Any?, artist: ArtistRef?) -> [AlbumSummary] {
        var seen: Set<String> = []
        return JSONNode(root).collect("musicTwoRowItemRenderer")
            .compactMap { albumSummary(fromTwoRow: $0, artist: artist) }
            .filter { seen.insert($0.id).inserted }
    }

    // MARK: - Álbum

    static func parseAlbum(_ root: Any?, browseID: String) -> ParsedAlbum {
        let json = JSONNode(root)
        let header = json.collect("musicResponsiveHeaderRenderer").first
            ?? json.collect("musicDetailHeaderRenderer").first ?? JSONNode(nil)
        let title = header["title"]["runs"].runsText
        let subtitleRuns = header["subtitle"]["runs"].array
        var artists = classify(runs: header["straplineTextOne"]["runs"].array).artists
        if artists.isEmpty { artists = classify(runs: subtitleRuns).artists }
        let cover = thumbnail(header["thumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"])
            ?? thumbnail(header["thumbnail"]["croppedSquareThumbnailRenderer"]["thumbnail"]["thumbnails"])

        let albumRef = AlbumRef(title: title, browseID: browseID)
        var seen: Set<String> = []
        var tracks: [Video] = []
        if let shelf = json.collect("musicShelfRenderer").first {
            tracks = shelf["contents"].array.compactMap {
                listItemVideo($0["musicResponsiveListItemRenderer"], fallbackArtists: artists, fallbackAlbum: albumRef, fallbackThumbnail: cover)
            }.filter { seen.insert($0.id).inserted }
        }
        let summary = AlbumSummary(id: browseID, title: title, artistName: artists.first?.name ?? "", thumbnailURL: cover, tracks: tracks,
                                   browseID: browseID, releaseType: ReleaseType(label: subtitleRuns.first?["text"].string),
                                   year: year(in: subtitleRuns))
        return ParsedAlbum(album: summary, tracks: tracks)
    }

    // MARK: - Listas de reproducción (canciones del artista) y su continuación

    static func parseTrackList(_ root: Any?, fallbackArtists: [ArtistRef] = []) -> RecommendationPage {
        let json = JSONNode(root)
        var seen: Set<String> = []
        let videos = trackListItems(json)
            .compactMap { listItemVideo($0["musicResponsiveListItemRenderer"], fallbackArtists: fallbackArtists) }
            .filter { seen.insert($0.id).inserted }
        return RecommendationPage(videos: videos, continuation: continuationToken(json))
    }

    private static func trackListItems(_ json: JSONNode) -> [JSONNode] {
        for key in ["musicPlaylistShelfRenderer", "musicPlaylistShelfContinuation", "musicShelfContinuation", "musicShelfRenderer"] {
            if let node = json.collect(key).first { return node["contents"].array }
        }
        return json.collect("continuationItems").first?.array ?? []
    }

    // MARK: - Radio (`next`)

    static func parseRadio(_ root: Any?) -> RecommendationPage {
        let json = JSONNode(root)
        let panel = json.collect("playlistPanelRenderer").first ?? json["continuationContents"]["playlistPanelContinuation"]
        var seen: Set<String> = []
        let videos = panel["contents"].array.compactMap { entry -> Video? in
            // Cuando existe versión alternativa, la pista llega envuelta; la contraparte (video) no se usa.
            let direct = entry["playlistPanelVideoRenderer"]
            let renderer = direct.exists ? direct : entry["playlistPanelVideoWrapperRenderer"]["primaryRenderer"]["playlistPanelVideoRenderer"]
            return panelVideo(renderer)
        }.filter { seen.insert($0.id).inserted }
        let token = panel["continuations"].array.first.flatMap {
            $0["nextRadioContinuationData"]["continuation"].string ?? $0["nextContinuationData"]["continuation"].string
        }
        return RecommendationPage(videos: videos, continuation: token)
    }

    // MARK: - Elementos

    /// Fila de lista (`musicResponsiveListItemRenderer`) que representa una pista reproducible.
    static func listItemVideo(_ item: JSONNode, fallbackArtists: [ArtistRef] = [], fallbackAlbum: AlbumRef? = nil,
                              fallbackThumbnail: URL? = nil) -> Video? {
        let columns = item["flexColumns"].array.map { $0["musicResponsiveListItemFlexColumnRenderer"]["text"]["runs"].array }
        guard let titleRuns = columns.first else { return nil }
        let overlayWatch = item["overlay"]["musicItemThumbnailOverlayRenderer"]["content"]["musicPlayButtonRenderer"]["playNavigationEndpoint"]["watchEndpoint"]
        let titleWatch = titleRuns.first?["navigationEndpoint"]["watchEndpoint"] ?? JSONNode(nil)
        guard let videoID = item["playlistItemData"]["videoId"].string ?? overlayWatch["videoId"].string ?? titleWatch["videoId"].string,
              isValidVideoID(videoID) else { return nil }

        let rawType = musicVideoType(overlayWatch) ?? musicVideoType(titleWatch)
        if rawType?.contains("PODCAST") == true { return nil }

        let detailRuns = Array(columns.dropFirst().joined())
            + item["fixedColumns"].array.flatMap { $0["musicResponsiveListItemFixedColumnRenderer"]["text"]["runs"].array }
        let details = classify(runs: detailRuns)
        let artists = details.artists.isEmpty ? fallbackArtists : details.artists
        let title = titleRuns.compactMap { $0["text"].string }.joined()

        return Video(id: videoID,
                     title: title.isEmpty ? "Video sin título" : title,
                     author: artists.isEmpty ? "Autor desconocido" : artists.map(\.name).joined(separator: ", "),
                     thumbnailURL: thumbnail(item["thumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"]) ?? fallbackThumbnail,
                     durationText: details.duration,
                     channelID: artists.first?.browseID,
                     artistRefs: artists.isEmpty ? nil : artists,
                     album: details.album ?? fallbackAlbum,
                     musicVideoType: rawType.map { MusicVideoType(youTubeMusicValue: $0) },
                     catalogSource: .youtubeMusic)
    }

    private static func panelVideo(_ renderer: JSONNode) -> Video? {
        guard let videoID = renderer["videoId"].string, isValidVideoID(videoID) else { return nil }
        let rawType = musicVideoType(renderer["navigationEndpoint"]["watchEndpoint"])
        if rawType?.contains("PODCAST") == true { return nil }
        let details = classify(runs: renderer["longBylineText"]["runs"].array)
        let title = renderer["title"]["runs"].runsText
        return Video(id: videoID,
                     title: title.isEmpty ? "Video sin título" : title,
                     author: details.artists.isEmpty ? "Autor desconocido" : details.artists.map(\.name).joined(separator: ", "),
                     thumbnailURL: thumbnail(renderer["thumbnail"]["thumbnails"]),
                     durationText: renderer["lengthText"]["runs"].array.first?["text"].string ?? details.duration,
                     channelID: details.artists.first?.browseID,
                     artistRefs: details.artists.isEmpty ? nil : details.artists,
                     album: details.album,
                     musicVideoType: rawType.map { MusicVideoType(youTubeMusicValue: $0) },
                     catalogSource: .youtubeMusic)
    }

    private static func searchArtist(_ item: JSONNode) -> ArtistSummary? {
        let endpoint = item["navigationEndpoint"]["browseEndpoint"]
        guard isArtistEndpoint(endpoint), let id = endpoint["browseId"].string else { return nil }
        let name = item["flexColumns"][0]["musicResponsiveListItemFlexColumnRenderer"]["text"]["runs"].runsText
        guard !name.isEmpty else { return nil }
        return artistSummary(name: name, id: id, thumbnails: item["thumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"])
    }

    private static func searchAlbum(_ item: JSONNode) -> AlbumSummary? {
        let endpoint = item["navigationEndpoint"]["browseEndpoint"]
        guard pageType(endpoint) == albumPageType, let id = endpoint["browseId"].string else { return nil }
        let title = item["flexColumns"][0]["musicResponsiveListItemFlexColumnRenderer"]["text"]["runs"].runsText
        guard !title.isEmpty else { return nil }
        let subtitle = item["flexColumns"][1]["musicResponsiveListItemFlexColumnRenderer"]["text"]["runs"].array
        return AlbumSummary(id: id, title: title, artistName: classify(runs: subtitle).artists.first?.name ?? "",
                            thumbnailURL: thumbnail(item["thumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"]),
                            tracks: [], browseID: id, releaseType: ReleaseType(label: subtitle.first?["text"].string),
                            year: year(in: subtitle))
    }

    private static func artistSummary(name: String, id: String, thumbnails: JSONNode) -> ArtistSummary {
        ArtistSummary(name: name, normalizedName: fold(name), thumbnailURL: thumbnail(thumbnails),
                      isOfficial: true, sampleVideos: [], browseID: id)
    }

    static func albumSummary(fromTwoRow item: JSONNode, artist: ArtistRef?) -> AlbumSummary? {
        guard let id = item["navigationEndpoint"]["browseEndpoint"]["browseId"].string, id.hasPrefix("MPREb_") else { return nil }
        let subtitle = item["subtitle"]["runs"].array
        return AlbumSummary(id: id, title: item["title"]["runs"].runsText,
                            artistName: classify(runs: subtitle).artists.first?.name ?? artist?.name ?? "",
                            thumbnailURL: thumbnail(item["thumbnailRenderer"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"]),
                            tracks: [], browseID: id, releaseType: ReleaseType(label: subtitle.first?["text"].string),
                            year: year(in: subtitle))
    }

    // MARK: - Utilidades

    private struct RunDetails {
        var artists: [ArtistRef] = []
        var album: AlbumRef?
        var duration: String?
    }

    /// Separa una fila de *runs* en artistas (enlaces a `UC…`), álbum (`MPREb_…`) y duración (`3:51`).
    private static func classify(runs: [JSONNode]) -> RunDetails {
        var details = RunDetails()
        for run in runs {
            let text = run["text"].string ?? ""
            let endpoint = run["navigationEndpoint"]["browseEndpoint"]
            if isArtistEndpoint(endpoint) {
                let ref = ArtistRef(name: text, browseID: endpoint["browseId"].string)
                if !details.artists.contains(ref) { details.artists.append(ref) }
            } else if pageType(endpoint) == albumPageType {
                if details.album == nil { details.album = AlbumRef(title: text, browseID: endpoint["browseId"].string) }
            } else if details.duration == nil, isDuration(text) {
                details.duration = text
            }
        }
        return details
    }

    private static func pageType(_ endpoint: JSONNode) -> String? {
        endpoint["browseEndpointContextSupportedConfigs"]["browseEndpointContextMusicConfig"]["pageType"].string
    }

    private static func isArtistEndpoint(_ endpoint: JSONNode) -> Bool {
        pageType(endpoint).map { artistPageTypes.contains($0) } ?? false
    }

    private static func musicVideoType(_ watchEndpoint: JSONNode) -> String? {
        watchEndpoint["watchEndpointMusicSupportedConfigs"]["watchEndpointMusicConfig"]["musicVideoType"].string
    }

    /// Token de continuación de cualquiera de los tres formatos; ignora los `reloadContinuationData` (filtros y orden).
    static func continuationToken(_ json: JSONNode) -> String? {
        if let token = json.collect("nextContinuationData").first?["continuation"].string { return token }
        if let token = json.collect("nextRadioContinuationData").first?["continuation"].string { return token }
        return json.collect("continuationItemRenderer").first?["continuationEndpoint"]["continuationCommand"]["token"].string
    }

    private static func thumbnail(_ thumbnails: JSONNode) -> URL? {
        for entry in thumbnails.array.reversed() {
            if let text = entry["url"].string, let url = URL(string: text), url.scheme == "https" { return url }
        }
        return nil
    }

    private static func year(in runs: [JSONNode]) -> String? {
        runs.compactMap { $0["text"].string }.first { text in
            text.count == 4 && text.unicodeScalars.allSatisfy { (48...57).contains($0.value) }
        }
    }

    static func isDuration(_ text: String) -> Bool {
        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        guard (2...3).contains(parts.count), parts.last?.count == 2 else { return false }
        return parts.allSatisfy { !$0.isEmpty && $0.unicodeScalars.allSatisfy { (48...57).contains($0.value) } }
    }

    static func isValidVideoID(_ id: String) -> Bool {
        id.utf8.count == 11 && id.utf8.allSatisfy { (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 || $0 == 95 }
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
