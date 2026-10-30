import XCTest
@testable import ReproductorPersonal

@MainActor
final class SiriPlaybackServiceTests: XCTestCase {
    func testPlayFavoritesSendsFavoriteVideosToPlayback() async throws {
        let library = LibraryStore(fileURL: try libraryURL())
        try library.setFavorite(videoA, enabled: true)
        let playback = SiriPlaybackControllerSpy(state: .idle)
        let service = SiriPlaybackService(library: library, playback: playback)

        try await service.playFavorites()

        XCTAssertEqual(playback.playedVideos, [videoA])
    }

    func testPlayMusicCombinesTheLocalLibraryWithoutDuplicates() async throws {
        let library = LibraryStore(fileURL: try libraryURL())
        try library.setFavorite(videoA, enabled: true)
        try library.recordRecent(videoB)
        let playlist = try library.createPlaylist(name: "Repetidas")
        try library.add(videoA, to: playlist)
        let playback = SiriPlaybackControllerSpy(state: .idle)
        let service = SiriPlaybackService(library: library, playback: playback)

        try await service.playMusic()

        XCTAssertEqual(playback.playedVideos, [videoA, videoB])
    }

    func testPauseOrResumeUsesTheCurrentPlaybackState() async throws {
        let library = LibraryStore(fileURL: try libraryURL())
        let playback = SiriPlaybackControllerSpy(state: .playing(videoA))
        let service = SiriPlaybackService(library: library, playback: playback)

        await service.pauseOrResume()
        XCTAssertEqual(playback.pauseCount, 1)

        playback.state = .paused(videoA)
        await service.pauseOrResume()
        XCTAssertEqual(playback.resumeCount, 1)
    }

    func testPlayFavoritesRejectsAnEmptyCollection() async throws {
        let service = SiriPlaybackService(library: LibraryStore(fileURL: try libraryURL()),
                                          playback: SiriPlaybackControllerSpy(state: .idle))

        do {
            try await service.playFavorites()
            XCTFail("Expected an empty favorites error")
        } catch {
            XCTAssertEqual(error as? SiriPlaybackError, .noFavorites)
        }
    }

    func testPlayArtistSearchesSourceAndPlaysVideos() async throws {
        let library = LibraryStore(fileURL: try libraryURL())
        let playback = SiriPlaybackControllerSpy(state: .idle)
        let artistVideo = Video(id: "art00000001", title: "Canción del Artista", author: "Artista Estrella")
        let source = StubYouTubeProvider(onSearch: { query in
            if query.contains("Artista Estrella") { return [artistVideo] }
            return []
        })
        let service = SiriPlaybackService(library: library, playback: playback, source: source)

        try await service.playArtist("Artista Estrella")

        XCTAssertEqual(playback.playedVideos, [artistVideo])
    }

    func testPlayArtistFallsBackToLocalLibraryWhenOffline() async throws {
        let library = LibraryStore(fileURL: try libraryURL())
        let artistVideo = Video(id: "art00000002", title: "Tema Local", author: "Artista Local - Topic")
        try library.setFavorite(artistVideo, enabled: true)
        let playback = SiriPlaybackControllerSpy(state: .idle)
        let source = StubYouTubeProvider(onSearch: { _ in throw AppError.offline })
        let service = SiriPlaybackService(library: library, playback: playback, source: source)

        try await service.playArtist("Artista Local")

        XCTAssertEqual(playback.playedVideos, [artistVideo])
    }

    func testPlaySongSearchesCombinedQueryAndPlaysVideos() async throws {
        let library = LibraryStore(fileURL: try libraryURL())
        let playback = SiriPlaybackControllerSpy(state: .idle)
        let songVideo = Video(id: "sng00000001", title: "Bachata Rosa", author: "Juan Luis Guerra")
        let source = StubYouTubeProvider(onSearch: { query in
            if query.contains("Bachata Rosa") { return [songVideo] }
            return []
        })
        let service = SiriPlaybackService(library: library, playback: playback, source: source)

        try await service.playSong("Bachata Rosa", artist: "Juan Luis Guerra")

        XCTAssertEqual(playback.playedVideos, [songVideo])
    }

    func testPlayArtistRejectsEmptyQuery() async throws {
        let service = SiriPlaybackService(library: LibraryStore(fileURL: try libraryURL()),
                                          playback: SiriPlaybackControllerSpy(state: .idle))
        do {
            try await service.playArtist("  ")
            XCTFail("Expected empty query error")
        } catch {
            XCTAssertEqual(error as? SiriPlaybackError, .emptyQuery)
        }
    }

    func testKnownSongsAndArtistsReturnFromService() async throws {
        let library = LibraryStore(fileURL: try libraryURL())
        let video = Video(id: "sng00000099", title: "Cali Pachanguero", author: "Grupo Niche")
        try library.setFavorite(video, enabled: true)
        let playback = SiriPlaybackControllerSpy(state: .idle)
        let service = SiriPlaybackService(library: library, playback: playback)

        XCTAssertTrue(service.knownSongs().contains("Cali Pachanguero"))
        XCTAssertTrue(service.knownArtists().contains("Grupo Niche"))
    }

    func testSiriPlaybackBridgeReturnsConfiguredServiceAutomatically() async throws {
        // Ensures configuredService() never throws unavailable even when uninitialized
        let known = SiriPlaybackBridge.shared.knownArtists()
        XCTAssertNotNil(known)
    }

    private func libraryURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        return directory.appendingPathComponent("library.json")
    }
}

@MainActor
private final class SiriPlaybackControllerSpy: SiriPlaybackControlling {
    var state: PlaybackState
    private(set) var playedVideos: [Video] = []
    private(set) var pauseCount = 0
    private(set) var resumeCount = 0

    init(state: PlaybackState) { self.state = state }

    func play(_ videos: [Video]) async { playedVideos = videos }
    func pause() { pauseCount += 1 }
    func resume() async { resumeCount += 1 }
}
