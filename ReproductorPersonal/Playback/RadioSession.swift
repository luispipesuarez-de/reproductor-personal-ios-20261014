import Foundation

@MainActor
final class RadioSession {
    private let source: any YouTubeProviding
    private let policy: CandidatePolicy
    private var seed: RecommendationSeed?
    private var cursor: String?
    private var started = false
    private var buffer: [Video] = []
    private var generation = UUID()

    var hasMore: Bool { seed != nil && (!buffer.isEmpty || !started || cursor != nil) }

    init(source: any YouTubeProviding, policy: CandidatePolicy = .permissive) {
        self.source = source
        self.policy = policy
    }

    func reset(seed: RecommendationSeed?) {
        generation = UUID()
        self.seed = seed
        cursor = nil
        started = false
        buffer = []
    }

    func batch(excluding: Set<String>, limit: Int) async throws -> [Video] {
        try await batch(excluding: excluding, dislikedIDs: [], limit: limit)
    }

    func batch(excluding: Set<String>, dislikedIDs: Set<String>, limit: Int) async throws -> [Video] {
        guard let seed, limit > 0 else { return [] }
        let token = generation
        guard !Task.isCancelled else { throw CancellationError() }

        let expectedArtist = seed.artistIdentity
        var seen = excluding.union(dislikedIDs)
        buffer = buffer.filter { accept($0, dislikedIDs: dislikedIDs, expected: expectedArtist, seen: &seen) }

        var pages = 0
        while preferredCount(expected: expectedArtist) < limit,
              !started || cursor != nil, pages < 3 {
            guard generation == token, !Task.isCancelled else { throw CancellationError() }
            let page: RecommendationPage
            do { page = try await source.recommendations(seed: seed, continuation: cursor) }
            catch {
                guard generation == token, !Task.isCancelled else { throw CancellationError() }
                // Una prelectura opcional no debe descartar candidatos ya disponibles.
                guard !buffer.isEmpty else { throw error }
                break
            }
            guard generation == token, !Task.isCancelled else { throw CancellationError() }
            started = true
            cursor = page.continuation
            buffer.append(contentsOf: page.videos.filter { accept($0, dislikedIDs: dislikedIDs, expected: expectedArtist, seen: &seen) })
            pages += 1
        }
        guard generation == token, !Task.isCancelled else { throw CancellationError() }

        if !policy.excludeSuspicious {
            buffer = buffer.prioritizingSongs()
            let result = Array(buffer.prefix(limit))
            buffer.removeFirst(result.count)
            return result
        }

        let ranked = rank(buffer, expected: expectedArtist)
        let primary = ranked.filter { TrackAuthenticity.assess($0, expected: expectedArtist).tier <= .officialChannel }
        let eligible: [Video]
        if primary.count >= limit || !policy.allowUnknownFallback() {
            eligible = primary
        } else {
            let unknownFallback = ranked.filter { video in
                let assessment = TrackAuthenticity.assess(video, expected: expectedArtist)
                return assessment.tier == .unknown && video.catalogSource != .youtubeWeb && assessment.matchesArtist != false
            }
            eligible = primary + unknownFallback
        }

        let ordered = interleaveArtist(eligible, expected: expectedArtist, maxConsecutiveOther: 3)
        let result = Array(ordered.prefix(limit))
        let takenIDs = Set(result.map(\.id))
        buffer.removeAll { takenIDs.contains($0.id) }
        return result
    }

    private func accept(_ video: Video, dislikedIDs: Set<String>, expected: ArtistIdentity?, seen: inout Set<String>) -> Bool {
        guard !dislikedIDs.contains(video.id), !video.isLongVideo else { return false }
        if policy.excludeSuspicious {
            if policy.isBlocked(video) { return false }
            let assessment = TrackAuthenticity.assess(video, expected: expected)
            if assessment.tier == .suspicious { return false }
            if !policy.acceptsDuration(video, tier: assessment.tier) { return false }
        }
        return seen.insert(video.id).inserted
    }

    private func preferredCount(expected: ArtistIdentity?) -> Int {
        if !policy.excludeSuspicious {
            return buffer.filter(\.isPreferredSong).count
        }
        return buffer.filter { TrackAuthenticity.assess($0, expected: expected).tier <= .officialChannel }.count
    }

    private func rank(_ videos: [Video], expected: ArtistIdentity?) -> [Video] {
        // Conserva el orden relativo del proveedor dentro de cada nivel y coincidencia de artista.
        let assessed = videos.map { ($0, TrackAuthenticity.assess($0, expected: expected)) }
        let tiers: [AuthenticityTier] = [.verifiedCatalog, .officialChannel, .unknown]
        var output: [Video] = []
        for tier in tiers {
            let inTier = assessed.filter { $0.1.tier == tier }
            if expected != nil {
                output.append(contentsOf: inTier.filter { $0.1.matchesArtist == true }.map(\.0))
                output.append(contentsOf: inTier.filter { $0.1.matchesArtist != true }.map(\.0))
            } else {
                output.append(contentsOf: inTier.map(\.0))
            }
        }
        return output
    }

    private func interleaveArtist(_ videos: [Video], expected: ArtistIdentity?, maxConsecutiveOther: Int) -> [Video] {
        guard let expected else { return videos }
        var artistRemaining = videos.filter { TrackAuthenticity.matchesArtist($0, expected) == true }.count
        if artistRemaining == 0 { return videos }

        var result: [Video] = []
        var deferredOthers: [Video] = []
        var consecutiveOther = 0

        for video in videos {
            let isArtist = TrackAuthenticity.matchesArtist(video, expected) == true
            if isArtist {
                result.append(video)
                artistRemaining -= 1
                consecutiveOther = 0
            } else if consecutiveOther < maxConsecutiveOther || artistRemaining == 0 {
                result.append(video)
                consecutiveOther += 1
            } else {
                deferredOthers.append(video)
            }
        }
        result.append(contentsOf: deferredOthers)
        return result
    }
}
