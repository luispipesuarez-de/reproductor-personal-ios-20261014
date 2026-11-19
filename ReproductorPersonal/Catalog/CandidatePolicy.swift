import Foundation

/// Reglas de calidad y duración que aplican la radio y las recomendaciones.
struct CandidatePolicy: Sendable {
    var excludeSuspicious: Bool
    var allowUnknownFallback: @Sendable () -> Bool
    var allowVerifiedShortSongs: Bool
    var blockedChannelIDs: @Sendable () -> Set<String>
    var blockedArtistNames: @Sendable () -> Set<String>
    var minSeconds: Int
    var maxSeconds: Int

    /// Conserva el comportamiento histórico para no alterar las pruebas de regresión existentes.
    static let permissive = CandidatePolicy(
        excludeSuspicious: false,
        allowUnknownFallback: { true },
        allowVerifiedShortSongs: false,
        blockedChannelIDs: { [] },
        blockedArtistNames: { [] },
        minSeconds: 180,
        maxSeconds: 600
    )

    /// Política para uso real: prioriza catálogo verificado y canales oficiales, excluye marcadores de IA/imitación
    /// y permite sencillos oficiales de catálogo a partir de 120 s.
    static func officialFirst(
        allowUnknownFallback: @escaping @Sendable () -> Bool = { false },
        blockedChannelIDs: @escaping @Sendable () -> Set<String> = { [] },
        blockedArtistNames: @escaping @Sendable () -> Set<String> = { [] }
    ) -> CandidatePolicy {
        CandidatePolicy(
            excludeSuspicious: true,
            allowUnknownFallback: allowUnknownFallback,
            allowVerifiedShortSongs: true,
            blockedChannelIDs: blockedChannelIDs,
            blockedArtistNames: blockedArtistNames,
            minSeconds: 180,
            maxSeconds: 600
        )
    }

    func isBlocked(_ video: Video) -> Bool {
        let ids = blockedChannelIDs()
        if let channelID = video.channelID, ids.contains(channelID) { return true }
        if let refs = video.artistRefs, refs.contains(where: { $0.browseID.map(ids.contains) == true }) { return true }
        let names = blockedArtistNames()
        if !names.isEmpty {
            let canonical = fold(video.canonicalArtistName)
            if names.contains(canonical) { return true }
        }
        return false
    }

    func acceptsDuration(_ video: Video, tier: AuthenticityTier) -> Bool {
        guard let seconds = video.durationSeconds else { return false }
        let lower = (allowVerifiedShortSongs && tier == .verifiedCatalog) ? 120 : minSeconds
        return (lower...maxSeconds).contains(seconds)
    }

    private func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
