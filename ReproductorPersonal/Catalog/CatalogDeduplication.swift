import Foundation

/// Agrupa versiones duplicadas de la misma canción (por ejemplo, álbum original frente a sencillo o recopilación),
/// conservando la pista de catálogo del álbum original y sin mezclar grabaciones en directo.
enum CatalogDeduplication {
    private static let liveMarkers = ["en vivo", "en directo", "live", "concierto", "unplugged", "acustico"]
    private static let compilationKeywords = ["grandes exitos", "greatest hits", "golden hits", "best of", "coleccion", "collection", "anthology"]

    static func deduplicate(_ videos: [Video]) -> [Video] {
        var groups: [[Video]] = []
        var keyToIndex: [String: Int] = [:]

        for video in videos {
            let key = deduplicationKey(for: video)
            if let existingIndex = keyToIndex[key] {
                groups[existingIndex].append(video)
            } else {
                keyToIndex[key] = groups.count
                groups.append([video])
            }
        }

        return groups.compactMap { pickBest(from: $0) }
    }

    static func deduplicationKey(for video: Video) -> String {
        let foldedTitle = fold(video.title)
        let artistKey: String
        if let id = video.artistRefs?.first?.browseID, !id.isEmpty {
            artistKey = id
        } else {
            artistKey = fold(video.canonicalArtistName).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if isLiveVersion(foldedTitle) {
            return "\(artistKey)|live|\(normalizeSpaces(foldedTitle))"
        }
        let baseTitle = stripEditionSuffixes(foldedTitle)
        return "\(artistKey)|studio|\(baseTitle)"
    }

    private static func pickBest(from group: [Video]) -> Video? {
        guard group.count > 1 else { return group.first }
        return group.min { a, b in
            let scoreA = rankScore(a)
            let scoreB = rankScore(b)
            return scoreA < scoreB
        }
    }

    private static func rankScore(_ video: Video) -> Int {
        let tierScore = TrackAuthenticity.assess(video).tier.rawValue * 10
        let typeScore: Int
        switch video.musicVideoType {
        case .atv: typeScore = 0
        case .omv: typeScore = 2
        case .ugc: typeScore = 5
        case .other, nil: typeScore = 4
        }
        let albumTitle = fold(video.album?.title ?? "")
        let isCompilation = compilationKeywords.contains { albumTitle.contains($0) }
        let compilationPenalty = isCompilation ? 1 : 0
        return tierScore + typeScore + compilationPenalty
    }

    private static func isLiveVersion(_ foldedTitle: String) -> Bool {
        let padded = " " + normalizeSpaces(foldedTitle) + " "
        return liveMarkers.contains { padded.contains(" \($0) ") || padded.contains("(\($0)") }
    }

    private static func stripEditionSuffixes(_ foldedTitle: String) -> String {
        var text = foldedTitle
        // Elimina paréntesis/corchetes de edición (Remastered, Versión, Radio Edit, Audio, Official…).
        let parenPattern = #"\s*[\(\[](?:[^)\]]*(?:remaster|version|radio edit|edit|audio|official|oficial|single|album|bonus|feat\.?|ft\.?)[^)\]]*)[\)\]]"#
        text = text.replacingOccurrences(of: parenPattern, with: "", options: .regularExpression)
        let dashPattern = #"\s*-\s*(?:(?:\d{4}\s*)?remaster(?:ed)?|radio edit|version.*|audio.*)$"#
        text = text.replacingOccurrences(of: dashPattern, with: "", options: .regularExpression)
        return normalizeSpaces(text)
    }

    private static func normalizeSpaces(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
