import Foundation
import XCTest
@testable import ReproductorPersonal

@MainActor
final class RadioPolicyTests: XCTestCase {
    private let artist = [ArtistRef(name: "Juan Luis Guerra", browseID: "UCjlg")]
    private let otherArtist = [ArtistRef(name: "Fonseca", browseID: "UCfonseca")]

    private func makeVideo(_ id: String, title: String = "Tema", author: String = "Canal",
                           duration: String = "3:30", type: MusicVideoType? = nil,
                           refs: [ArtistRef]? = nil, channelID: String? = nil,
                           source: CatalogSource? = .youtubeMusic) -> Video {
        Video(id: id, title: title, author: author, durationText: duration,
              channelID: channelID, artistRefs: refs, musicVideoType: type, catalogSource: source)
    }

    func testOfficialFirstExcludesAICoverAndSuspiciousTracks() async throws {
        let ai = makeVideo("ai000000001", title: "Bachata Rosa (AI Cover)", type: .atv, refs: artist)
        let karaoke = makeVideo("kar00000001", title: "Karaoke Bachata", author: "Karaoke Hits")
        let valid = makeVideo("atv00000001", title: "Quisiera", type: .atv, refs: artist)

        let session = RadioSession(
            source: StubYouTubeProvider(onRecommendations: { _, _ in
                RecommendationPage(videos: [ai, karaoke, valid], continuation: nil)
            }),
            policy: .officialFirst()
        )
        session.reset(seed: .video("seed0000000"))
        let batch = try await session.batch(excluding: [], limit: 10)
        XCTAssertEqual(batch.map(\.id), [valid.id])
    }

    func testOfficialFirstAcceptsVerifiedCatalogFromTwoMinutesButRejectsShortUGC() async throws {
        let shortATV = makeVideo("atv15000001", title: "Sencillo Corto", duration: "2:30", type: .atv, refs: artist)
        let shortUGC = makeVideo("ugc15000001", title: "Video Corto", duration: "2:30", type: .ugc, refs: artist)

        let session = RadioSession(
            source: StubYouTubeProvider(onRecommendations: { _, _ in
                RecommendationPage(videos: [shortUGC, shortATV], continuation: nil)
            }),
            policy: .officialFirst(allowUnknownFallback: { true })
        )
        session.reset(seed: .video("seed0000000"))
        let batch = try await session.batch(excluding: [], limit: 10)
        XCTAssertEqual(batch.map(\.id), [shortATV.id])
    }

    func testUnknownFallbackExcludesYouTubeWebAndOnlyActivatesWhenAllowed() async throws {
        let webUnknown = makeVideo("web00000001", title: "Video Web", author: "Alguien", source: .youtubeWeb)
        let ytmUnknown = makeVideo("ytm00000001", title: "Video YTM", author: "Canal", type: .ugc, source: .youtubeMusic)

        let strict = RadioSession(
            source: StubYouTubeProvider(onRecommendations: { _, _ in
                RecommendationPage(videos: [webUnknown, ytmUnknown], continuation: nil)
            }),
            policy: .officialFirst(allowUnknownFallback: { false })
        )
        strict.reset(seed: .video("seed0000000"))
        let strictBatch = try await strict.batch(excluding: [], limit: 10)
        XCTAssertTrue(strictBatch.isEmpty)

        let relaxed = RadioSession(
            source: StubYouTubeProvider(onRecommendations: { _, _ in
                RecommendationPage(videos: [webUnknown, ytmUnknown], continuation: nil)
            }),
            policy: .officialFirst(allowUnknownFallback: { true })
        )
        relaxed.reset(seed: .video("seed0000000"))
        let relaxedBatch = try await relaxed.batch(excluding: [], limit: 10)
        XCTAssertEqual(relaxedBatch.map(\.id), [ytmUnknown.id])
    }

    func testBlockedChannelsAndArtistsAreExcludedFromRadio() async throws {
        let blockedByID = makeVideo("blk00000001", title: "Tema 1", type: .atv,
                                    refs: [ArtistRef(name: "Bloqueado", browseID: "UCblocked")])
        let allowed = makeVideo("ok000000001", title: "Tema 2", type: .atv, refs: artist)

        let session = RadioSession(
            source: StubYouTubeProvider(onRecommendations: { _, _ in
                RecommendationPage(videos: [blockedByID, allowed], continuation: nil)
            }),
            policy: .officialFirst(blockedChannelIDs: { ["UCblocked"] })
        )
        session.reset(seed: .video("seed0000000"))
        let batch = try await session.batch(excluding: [], limit: 10)
        XCTAssertEqual(batch.map(\.id), [allowed.id])
    }

    func testArtistSeedPrioritizesMatchingArtistAndCapsConsecutiveOthers() async throws {
        let m1 = makeVideo("m1000000001", title: "Propia 1", type: .atv, refs: artist)
        let m2 = makeVideo("m2000000001", title: "Propia 2", author: "Juan Luis Guerra - Topic")
        let o1 = makeVideo("o1000000001", title: "Otro 1", type: .atv, refs: otherArtist)
        let o2 = makeVideo("o2000000001", title: "Otro 2", type: .atv, refs: otherArtist)
        let o3 = makeVideo("o3000000001", title: "Otro 3", type: .atv, refs: otherArtist)
        let o4 = makeVideo("o4000000001", title: "Otro 4", type: .atv, refs: otherArtist)

        let session = RadioSession(
            source: StubYouTubeProvider(onRecommendations: { _, _ in
                RecommendationPage(videos: [o1, o2, o3, o4, m2, m1], continuation: nil)
            }),
            policy: .officialFirst()
        )
        session.reset(seed: .artist(channelID: "UCjlg", name: "Juan Luis Guerra", radioPlaylistID: nil))
        let batch = try await session.batch(excluding: [], limit: 10)
        XCTAssertEqual(batch.first?.id, m1.id)
        // m2 (officialChannel) está después de o1..o4 (verifiedCatalog); el límite de 3 seguidos debe devolver a m2 antes que a o4.
        let m2Index = try XCTUnwrap(batch.firstIndex(where: { $0.id == m2.id }))
        let o4Index = try XCTUnwrap(batch.firstIndex(where: { $0.id == o4.id }))
        XCTAssertLessThan(m2Index, o4Index)
    }

    func testLegacyVideoSeedJSONStillDecodesAndArtistSeedRoundTrips() throws {
        let legacy = #"{"video":{"_0":"aaaaaaaaaaa"}}"#
        let decoded = try JSONDecoder().decode(RecommendationSeed.self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded, .video("aaaaaaaaaaa"))

        let artistSeed = RecommendationSeed.artist(channelID: "UCjlg", name: "Juan Luis Guerra", radioPlaylistID: "RDEM123")
        let roundTrip = try JSONDecoder().decode(RecommendationSeed.self, from: JSONEncoder().encode(artistSeed))
        XCTAssertEqual(roundTrip, artistSeed)
    }

    func testYouTubeClientRadioUsesYouTubeMusicFixtureAndExcludesSeed() async throws {
        let radioData = try fixtureData("ytm-radio")
        let music = YouTubeMusicClient { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (radioData, response)
        }
        let client = YouTubeClient(music: music)
        let page = try await client.recommendations(seed: .video("2i2d7RjsEfs"), continuation: nil)
        XCTAssertFalse(page.videos.isEmpty)
        XCTAssertFalse(page.videos.contains(where: { $0.id == "2i2d7RjsEfs" }))
        XCTAssertTrue(page.videos.allSatisfy { $0.musicVideoType == .atv })
        XCTAssertNotNil(page.continuation)
    }

    func testDiscoveryExcludesSuspiciousTracks() async {
        let ai = makeVideo("ai000000001", title: "Éxito (AI Cover)", type: .atv, refs: artist)
        let clean = makeVideo("ok000000001", title: "Éxito Real", type: .atv, refs: artist)
        let model = DiscoveryViewModel(source: StubYouTubeProvider(onRecommendations: { _, _ in
            RecommendationPage(videos: [ai, clean], continuation: nil)
        }))
        await model.refresh(favorites: [videoA], likes: [], dislikedIDs: [], recent: [])
        guard case .ready(let recommended, let discover) = model.state else { return XCTFail("Expected ready") }
        XCTAssertEqual(recommended.map(\.id), [clean.id])
        XCTAssertEqual(discover.map(\.id), [clean.id])
    }

    func testSiriPlayArtistAndPlaySongUseMusicSearchWhenAvailable() async throws {
        let libraryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("lib.json")
        try FileManager.default.createDirectory(at: libraryURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: libraryURL.deletingLastPathComponent()) }
        let library = LibraryStore(fileURL: libraryURL)
        let playback = SiriSpy()

        let tribute = ArtistSummary(name: "Shakira Tributo", normalizedName: "shakira tributo", thumbnailURL: nil, isOfficial: true, sampleVideos: [], browseID: "UCtrib")
        let real = ArtistSummary(name: "Shakira", normalizedName: "shakira", thumbnailURL: nil, isOfficial: true, sampleVideos: [], browseID: "UCshak")
        let song1 = makeVideo("sh000000001", title: "Ojos Así", type: .atv, refs: [ArtistRef(name: "Shakira", browseID: "UCshak")])
        let aiSong = makeVideo("ai000000002", title: "Ojos Así (AI Cover)", type: .atv, refs: [ArtistRef(name: "Shakira", browseID: "UCshak")])

        let provider = MusicSearchStub(
            searchResult: MusicSearchResult(songs: [aiSong, song1], artists: [tribute, real]),
            catalog: ArtistCatalog(artistName: "Shakira", thumbnailURL: nil, songs: [song1], albums: [], channelID: "UCshak", radioPlaylistID: "RDEMshak")
        )
        let service = SiriPlaybackService(library: library, playback: playback, source: provider)

        try await service.playArtist("Shakira")
        XCTAssertEqual(playback.playedVideos, [song1])
        XCTAssertEqual(playback.playedSeed, .artist(channelID: "UCshak", name: "Shakira", radioPlaylistID: "RDEMshak"))

        try await service.playSong("Ojos Así", artist: "Shakira")
        XCTAssertEqual(playback.playedVideos, [song1])
    }

    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }
}

@MainActor
private final class SiriSpy: SiriPlaybackControlling {
    var state: PlaybackState = .idle
    var playedVideos: [Video] = []
    var playedSeed: RecommendationSeed?
    func play(_ videos: [Video]) async { playedVideos = videos; playedSeed = nil }
    func play(_ videos: [Video], seed: RecommendationSeed?) async { playedVideos = videos; playedSeed = seed }
    func pause() {}
    func resume() async {}
}

private struct MusicSearchStub: YouTubeProviding {
    let searchResult: MusicSearchResult
    let catalog: ArtistCatalog
    func search(query: String) async throws -> [Video] { [] }
    func resolve(videoID: String) async throws -> PlaybackResource { throw AppError.unavailable }
    func recommendations(seed: RecommendationSeed, continuation: String?) async throws -> RecommendationPage { RecommendationPage(videos: [], continuation: nil) }
    func musicSearch(query: String, filter: MusicSearchFilter?, continuation: String?) async throws -> MusicSearchResult { searchResult }
    func artistCatalog(artistID: String) async throws -> ArtistCatalog { catalog }
}
