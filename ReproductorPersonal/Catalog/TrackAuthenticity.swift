import Foundation

/// Nivel de confianza de una pista. Menor valor = más confiable.
enum AuthenticityTier: Int, Comparable, Sendable {
    case verifiedCatalog = 0   // pista de catálogo (ATV) o videoclip oficial (OMV) con artista identificado
    case officialChannel = 1   // canal «- Topic», VEVO, con marca de verificación o el propio canal del artista
    case unknown = 2           // sin señales a favor ni en contra
    case suspicious = 3        // marcadores de IA, covers, karaoke, imitaciones…

    static func < (lhs: AuthenticityTier, rhs: AuthenticityTier) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// Artista esperado (por ejemplo, el de la página en la que se pulsó «Reproducir todo»).
struct ArtistIdentity: Equatable, Sendable {
    let name: String
    let browseIDs: Set<String>

    init(name: String, browseIDs: Set<String> = []) {
        self.name = name
        self.browseIDs = browseIDs
    }
}

struct AuthenticityAssessment: Equatable, Sendable {
    let tier: AuthenticityTier
    /// `true` si la pista es del artista esperado, `false` si hay evidencia de otro artista, `nil` si no hay datos o no se esperaba ninguno.
    let matchesArtist: Bool?
    let reasons: [String]
}

/// Clasificador heurístico. **No verifica autenticidad**: solo combina las señales que exponen las fuentes
/// (tipo de pista, IDs de artista, nombre del canal y marcadores en el título). Reduce, no elimina, las pistas falsas.
enum TrackAuthenticity {
    private static let aiPhrases: [String] = [
        "ai cover", "ia cover", "cover ai", "cover ia", "cover con ia", "ai version", "version ia", "version con ia",
        "ai song", "ai generated", "ai generado", "generado con ia", "generada con ia", "generado por ia", "generada por ia",
        "hecho con ia", "hecha con ia", "ai voice", "voz ia", "voz con ia", "voz de ia", "ai remix",
        "con ia", "inteligencia artificial", "artificial intelligence", "suno", "suno ai", "udio", "udio ai"
    ]
    // Estos marcadores van entre paréntesis o corchetes: «ai» suelto es una palabra legítima (p. ej. «Ai Se Eu Te Pego»).
    private static let aiBracketMarkers = ["(ai)", "[ai]", "(ia)", "[ia]"]

    private static let imitationPhrases: [String] = [
        "cover", "covers", "tribute", "tributo", "karaoke", "imitador", "imitadora", "imitacion", "parodia", "parody",
        "estilo de", "in the style of", "type beat", "8d", "8d audio", "slowed", "sped up", "nightcore", "bass boosted"
    ]
    private static let imitationPatterns = [" (if|what if) [a-z0-9 ]{2,40} (sang|sings) ", " si [a-z0-9 ]{2,40} cantara "]

    static func assess(_ video: Video, expected: ArtistIdentity? = nil) -> AuthenticityAssessment {
        let combined = video.title + " " + video.author
        let padded = tokenized(combined)
        let raw = fold(combined)
        let matches = matchesArtist(video, expected)

        var aiHits = aiPhrases.filter { padded.contains(" \($0) ") }
        aiHits += aiBracketMarkers.filter { raw.contains($0) }
        if !aiHits.isEmpty {
            return AuthenticityAssessment(tier: .suspicious, matchesArtist: matches,
                                          reasons: aiHits.map { "marcador de IA: \($0)" })
        }

        let hasIdentifiedArtist = video.artistRefs?.contains { $0.browseID != nil } == true
        if hasIdentifiedArtist, video.musicVideoType == .atv {
            return AuthenticityAssessment(tier: .verifiedCatalog, matchesArtist: matches,
                                          reasons: ["pista de catálogo (ATV) con artista identificado"])
        }
        if hasIdentifiedArtist, video.musicVideoType == .omv {
            return AuthenticityAssessment(tier: .verifiedCatalog, matchesArtist: matches,
                                          reasons: ["videoclip oficial (OMV) con artista identificado"])
        }

        var imitationHits = imitationPhrases.filter { padded.contains(" \($0) ") }
        imitationHits += imitationPatterns.filter { padded.range(of: $0, options: .regularExpression) != nil }
        if !imitationHits.isEmpty {
            return AuthenticityAssessment(tier: .suspicious, matchesArtist: matches,
                                          reasons: imitationHits.map { "posible imitación o versión: \($0.trimmingCharacters(in: .whitespaces))" })
        }

        if let channelID = video.channelID, expected?.browseIDs.contains(channelID) == true {
            return AuthenticityAssessment(tier: .officialChannel, matchesArtist: matches, reasons: ["canal del artista esperado"])
        }
        if video.isOfficialChannel || Video.isOfficialChannelName(video.author) {
            return AuthenticityAssessment(tier: .officialChannel, matchesArtist: matches, reasons: ["canal oficial (Topic, VEVO o verificado)"])
        }
        return AuthenticityAssessment(tier: .unknown, matchesArtist: matches, reasons: ["sin señales de autenticidad"])
    }

    static func matchesArtist(_ video: Video, _ expected: ArtistIdentity?) -> Bool? {
        guard let expected else { return nil }
        let refs = video.artistRefs ?? []
        var ids = Set(refs.compactMap(\.browseID))
        if let channelID = video.channelID { ids.insert(channelID) }
        if !ids.isEmpty, !expected.browseIDs.isEmpty, !ids.isDisjoint(with: expected.browseIDs) { return true }

        let target = fold(expected.name).trimmingCharacters(in: .whitespacesAndNewlines)
        var names = refs.map { fold($0.name).trimmingCharacters(in: .whitespacesAndNewlines) }
        names.append(fold(video.canonicalArtistName).trimmingCharacters(in: .whitespacesAndNewlines))
        if !target.isEmpty, names.contains(target) { return true }

        // Con artistas identificados por el catálogo, no coincidir es evidencia de otro artista.
        if !refs.isEmpty { return false }
        // Sin catálogo solo se conoce quien subió el video; un nombre distinto tampoco coincide.
        let author = video.author.trimmingCharacters(in: .whitespacesAndNewlines)
        if author.isEmpty || author == "Autor desconocido" { return nil }
        return false
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    /// Texto en minúsculas, sin tildes, con todo lo que no sea letra o número reducido a un solo espacio y rodeado de espacios,
    /// de modo que `" cover "` solo coincida con la palabra completa (no con «discover»).
    private static func tokenized(_ text: String) -> String {
        var output = ""
        var lastWasSpace = true
        for scalar in fold(text).unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                output.unicodeScalars.append(scalar)
                lastWasSpace = false
            } else if !lastWasSpace {
                output.append(" ")
                lastWasSpace = true
            }
        }
        return " " + output.trimmingCharacters(in: .whitespaces) + " "
    }
}
