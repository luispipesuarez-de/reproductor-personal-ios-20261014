import Foundation

struct Video: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let author: String
    var thumbnailURL: URL?
    var durationText: String?
    private var officialChannel: Bool?
    // Metadatos de catálogo: todos opcionales para que las bibliotecas guardadas antes sigan decodificando.
    var channelID: String?
    var artistRefs: [ArtistRef]?
    var album: AlbumRef?
    var musicVideoType: MusicVideoType?
    var catalogSource: CatalogSource?

    init(id: String, title: String, author: String, thumbnailURL: URL? = nil, durationText: String? = nil, officialChannel: Bool? = nil,
         channelID: String? = nil, artistRefs: [ArtistRef]? = nil, album: AlbumRef? = nil,
         musicVideoType: MusicVideoType? = nil, catalogSource: CatalogSource? = nil) {
        self.id = id
        self.title = title
        self.author = author
        self.thumbnailURL = thumbnailURL
        self.durationText = durationText
        self.officialChannel = officialChannel
        self.channelID = channelID
        self.artistRefs = artistRefs
        self.album = album
        self.musicVideoType = musicVideoType
        self.catalogSource = catalogSource
    }

    var isPreferredSong: Bool { songPriority == 0 }
    var isLongVideo: Bool {
        guard let seconds = durationSeconds else { return false }
        return seconds > 600
    }
    var isOfficialChannel: Bool { officialChannel == true }
    var containsSoulReference: Bool { Self.normalizedCatalogText(title + " " + author).contains("soul") }

    /// Señales de canal oficial presentes en el nombre. YouTube muestra la verificación como una insignia
    /// que YouTubeKit no extrae, así que esto es solo una pista, nunca una garantía.
    /// La nota musical (♪♫♬) ya no cuenta: la usan igualmente canales de fans o de contenido generado.
    static func isOfficialChannelName(_ author: String) -> Bool {
        let normalized = normalizedCatalogText(author).trimmingCharacters(in: .whitespacesAndNewlines)
        let hasVerificationMark = author.contains(where: { "✓✔☑".contains($0) })
        return hasVerificationMark
            || normalized == "topic" || normalized.hasSuffix(" - topic")
            || normalized.hasSuffix("vevo")
    }

    fileprivate var songPriority: Int {
        guard let seconds = durationSeconds else { return 1 }
        if (180...600).contains(seconds) { return 0 }
        return seconds >= 3600 ? 2 : 1
    }

    var durationSeconds: Int? {
        guard let parts = durationText?.split(separator: ":", omittingEmptySubsequences: false),
              (2...3).contains(parts.count) else { return nil }
        var seconds = 0
        for (index, part) in parts.enumerated() {
            guard !part.isEmpty, part.utf8.allSatisfy({ (48...57).contains($0) }),
                  let value = Int(part), index == 0 || value < 60 else { return nil }
            let (scaled, multiplicationOverflow) = seconds.multipliedReportingOverflow(by: 60)
            let (total, additionOverflow) = scaled.addingReportingOverflow(value)
            guard !multiplicationOverflow, !additionOverflow else { return nil }
            seconds = total
        }
        return seconds
    }

    private static func normalizedCatalogText(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    var canonicalArtistName: String {
        var clean = author
        let removePatterns = [
            " - Topic", "- Topic", " Topic", "VEVO", "Vevo",
            "Official", "Oficial", "Canal Oficial", "Official Channel",
            "✓", "✔", "☑", "♪", "♫", "♬"
        ]
        for pattern in removePatterns {
            clean = clean.replacingOccurrences(of: pattern, with: "", options: .caseInsensitive)
        }
        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasSuffix("-") {
            clean = clean.dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return clean.isEmpty ? author : clean
    }

    var isLikelyFullAlbumOrCompilation: Bool {
        let lower = title.lowercased()
        let albumKeywords = ["album", "álbum", "disco completo", "full album", " ep ", " ep)"]
        if albumKeywords.contains(where: { lower.contains($0) }) { return true }
        guard let seconds = durationSeconds else { return false }
        return seconds >= 900 && seconds <= 7200
    }

    var inferredAlbumTitle: String {
        let lower = title.lowercased()
        if let range = lower.range(of: "album:") ?? lower.range(of: "álbum:") {
            let extracted = String(title[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !extracted.isEmpty { return extracted }
        }
        if let open = title.firstIndex(of: "("), let close = title[open...].firstIndex(of: ")") {
            let inside = String(title[title.index(after: open)..<close]).trimmingCharacters(in: .whitespacesAndNewlines)
            if inside.lowercased().contains("album") || inside.lowercased().contains("álbum") || inside.lowercased().contains("disco") {
                return inside
            }
        }
        return title
    }
}

enum ReleaseType: String, Equatable, Sendable {
    case album, single, ep, other

    /// Interpreta la etiqueta del subtítulo de un lanzamiento («Álbum», «Single», «EP», «Sencillo»…).
    init(label: String?) {
        let text = (label ?? "")
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.contains("single") || text.contains("sencillo") { self = .single }
        else if text == "ep" || text.hasPrefix("ep ") { self = .ep }
        else if text.contains("album") { self = .album }
        else { self = .other }
    }
}

struct ArtistSummary: Identifiable, Equatable, Sendable {
    var id: String { browseID ?? normalizedName }
    let name: String
    let normalizedName: String
    let thumbnailURL: URL?
    let isOfficial: Bool
    let sampleVideos: [Video]
    /// Identificador de artista del catálogo (`UC…`) cuando existe.
    var browseID: String? = nil
}

struct AlbumSummary: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let artistName: String
    let thumbnailURL: URL?
    let tracks: [Video]
    /// Identificador de álbum del catálogo (`MPREb_…`) cuando existe.
    var browseID: String? = nil
    var releaseType: ReleaseType? = nil
    var year: String? = nil
}

struct ArtistCatalog: Equatable, Sendable {
    let artistName: String
    let thumbnailURL: URL?
    let songs: [Video]
    let albums: [AlbumSummary]
    var singles: [AlbumSummary] = []
    var channelID: String? = nil
    var radioPlaylistID: String? = nil
    var allSongsBrowseID: String? = nil
    /// Token para pedir más canciones de `allSongsBrowseID`.
    var songsContinuation: String? = nil
    /// `true` si alguna sección no pudo cargarse y el catálogo puede estar incompleto.
    var isPartial: Bool = false
}

extension Array where Element == Video {
    func groupedArtists(matching query: String? = nil) -> [ArtistSummary] {
        var map: [String: [Video]] = [:]
        var order: [String] = []
        for video in self {
            let canonical = video.canonicalArtistName
            let norm = canonical.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            if map[norm] == nil {
                order.append(norm)
                map[norm] = []
            }
            map[norm]?.append(video)
        }

        let summaries = order.compactMap { norm -> ArtistSummary? in
            guard let videos = map[norm], let first = videos.first else { return nil }
            let name = first.canonicalArtistName
            let thumb = videos.compactMap(\.thumbnailURL).first
            let isOfficial = videos.contains(where: \.isOfficialChannel)
            return ArtistSummary(
                name: name,
                normalizedName: norm,
                thumbnailURL: thumb,
                isOfficial: isOfficial,
                sampleVideos: videos
            )
        }

        if let query = query?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let normQuery = query.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            return summaries.sorted { a, b in
                let aExact = a.normalizedName == normQuery
                let bExact = b.normalizedName == normQuery
                if aExact != bExact { return aExact }
                let aStarts = a.normalizedName.hasPrefix(normQuery)
                let bStarts = b.normalizedName.hasPrefix(normQuery)
                if aStarts != bStarts { return aStarts }
                if a.isOfficial != b.isOfficial { return a.isOfficial }
                return a.sampleVideos.count > b.sampleVideos.count
            }
        }
        return summaries
    }

    func groupedAlbums(forArtist artistName: String? = nil) -> [AlbumSummary] {
        var albums: [AlbumSummary] = []
        var seenIDs: Set<String> = []

        let filtered = artistName != nil ? filter {
            let normArtist = artistName!.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            let normAuthor = $0.canonicalArtistName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            return normAuthor == normArtist || normAuthor.contains(normArtist) || normArtist.contains(normAuthor)
        } : self

        let fullAlbums = filtered.filter(\.isLikelyFullAlbumOrCompilation)
        for video in fullAlbums where seenIDs.insert(video.id).inserted {
            albums.append(AlbumSummary(
                id: video.id,
                title: video.inferredAlbumTitle,
                artistName: video.canonicalArtistName,
                thumbnailURL: video.thumbnailURL,
                tracks: [video]
            ))
        }

        let nonFull = filtered.filter { !$0.isLikelyFullAlbumOrCompilation }
        var byAlbumName: [String: [Video]] = [:]
        for video in nonFull {
            let albumTitle = video.inferredAlbumTitle
            if albumTitle != video.title {
                byAlbumName[albumTitle, default: []].append(video)
            }
        }

        for (albumTitle, tracks) in byAlbumName where tracks.count >= 2 {
            let albumID = "album-\(tracks.first?.id ?? UUID().uuidString)"
            if seenIDs.insert(albumID).inserted {
                albums.append(AlbumSummary(
                    id: albumID,
                    title: albumTitle,
                    artistName: tracks.first?.canonicalArtistName ?? (artistName ?? ""),
                    thumbnailURL: tracks.first?.thumbnailURL,
                    tracks: tracks
                ))
            }
        }

        if albums.isEmpty && !filtered.isEmpty {
            let artist = artistName ?? filtered.first?.canonicalArtistName ?? "Artista"
            albums.append(AlbumSummary(
                id: "collection-\(artist)",
                title: "Éxitos de \(artist)",
                artistName: artist,
                thumbnailURL: filtered.first?.thumbnailURL,
                tracks: Array(filtered.prefix(12))
            ))
        }

        return albums
    }
}

extension Array where Element == Video {
    func prioritizingSongs() -> [Video] {
        // Preserve provider relevance within each catalog-quality and official-channel group.
        var groups: [[Video]] = [[], [], []]
        for video in self { groups[video.songPriority].append(video) }
        return groups.flatMap { $0.prioritizingOfficialChannels() }
    }

    func prioritizingOfficialChannels() -> [Video] {
        filter(\.isOfficialChannel) + filter { !$0.isOfficialChannel }
    }
}

struct PlaybackResource: Equatable, Sendable {
    let url: URL
    let expiresAt: Date?
}
