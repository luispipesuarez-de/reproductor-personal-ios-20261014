import Foundation
import XCTest
@testable import ReproductorPersonal

@MainActor
final class CatalogSearchAndLibraryTests: XCTestCase {
    func testSearchByAlbumTitleReturnsAlbumsFromMusicCatalog() async {
        let album = AlbumSummary(id: "MPREb_bachata", title: "Bachata Rosa", artistName: "Juan Luis Guerra",
                                 thumbnailURL: nil, tracks: [], browseID: "MPREb_bachata", releaseType: .album, year: "1990")
        let song = Video(id: "s1000000001", title: "Bachata Rosa", author: "Juan Luis Guerra", durationText: "4:18",
                         artistRefs: [ArtistRef(name: "Juan Luis Guerra", browseID: "UCjlg")],
                         musicVideoType: .atv, catalogSource: .youtubeMusic)

        let vm = SearchViewModel(source: StubMusicSearchProvider(
            onMusicSearch: { _, _, _ in MusicSearchResult(songs: [song], albums: [album]) }
        ))
        await vm.submit(query: "Bachata Rosa")
        vm.setCategoryFilter(.albums)

        XCTAssertEqual(vm.filteredAlbums.map(\.id), ["MPREb_bachata"])
    }

    func testSearchLoadMoreAppendsWithoutDuplicates() async {
        let s1 = Video(id: "s1000000001", title: "Tema 1", author: "Artista", durationText: "3:30", musicVideoType: .atv, catalogSource: .youtubeMusic)
        let s2 = Video(id: "s2000000002", title: "Tema 2", author: "Artista", durationText: "3:40", musicVideoType: .atv, catalogSource: .youtubeMusic)

        let vm = SearchViewModel(source: StubMusicSearchProvider(
            onMusicSearch: { _, _, cont in
                if cont == nil { return MusicSearchResult(songs: [s1], continuation: "page-2") }
                return MusicSearchResult(songs: [s1, s2], continuation: nil)
            }
        ))
        await vm.submit(query: "Artista")
        XCTAssertTrue(vm.canLoadMore)
        await vm.loadMore()
        XCTAssertFalse(vm.canLoadMore)
        guard case .results(_, let videos) = vm.state else { return XCTFail("Expected results") }
        XCTAssertEqual(videos.map(\.id), [s1.id, s2.id])
    }

    func testYouTubeClientAlbumTracksReturnsOrderedATVTracksFromFixture() async throws {
        let albumData = try fixtureData("ytm-album")
        let music = YouTubeMusicClient { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (albumData, response)
        }
        let client = YouTubeClient(music: music)
        let tracks = try await client.albumTracks(albumID: "MPREb_wX4449DSyFX")
        XCTAssertEqual(tracks.count, 8)
        XCTAssertTrue(tracks.allSatisfy { $0.musicVideoType == .atv })
    }

    func testDeduplicationMergesEditionsPrefersOriginalAlbumAndKeepsLiveSeparate() {
        let artist = [ArtistRef(name: "Juan Luis Guerra", browseID: "UCjlg")]
        let compilation = Video(id: "v1000000001", title: "Bachata Rosa (2025 Remastered)", author: "JLG",
                                artistRefs: artist,
                                album: AlbumRef(title: "Grandes Éxitos", browseID: "MPREb_ge"),
                                musicVideoType: .atv)
        let original = Video(id: "v2000000002", title: "Bachata Rosa", author: "JLG",
                             artistRefs: artist,
                             album: AlbumRef(title: "Bachata Rosa", browseID: "MPREb_br"),
                             musicVideoType: .atv)
        let singleEdit = Video(id: "v3000000003", title: "Bachata Rosa (Radio Edit)", author: "JLG",
                               artistRefs: artist, musicVideoType: .atv)
        let live = Video(id: "v4000000004", title: "Bachata Rosa (En Vivo)", author: "JLG",
                         artistRefs: artist, musicVideoType: .atv)

        let deduped = CatalogDeduplication.deduplicate([compilation, original, singleEdit, live])
        XCTAssertEqual(deduped.map(\.id), [original.id, live.id])
    }

    func testGroupedAlbumsAvoidsLookalikeSubstringAndFallsBackOnAlbumQuery() {
        let mana = Video(id: "m1000000001", title: "Rayando el Sol (Album)", author: "Maná")
        let fans = Video(id: "m2000000002", title: "Mix (Album)", author: "Manáfans")
        let albumsForMana = [mana, fans].groupedAlbums(forArtist: "Maná")
        XCTAssertEqual(albumsForMana.map(\.id), [mana.id])

        // Consulta por título de álbum: no coincide con el autor, así que agrupa sin descartar todo.
        let byAlbumTitle = [mana].groupedAlbums(forArtist: "Dónde Jugarán los Niños")
        XCTAssertEqual(byAlbumTitle.map(\.id), [mana.id])
    }

    func testPartialSearchDeepPropagatesIsPartialInLegacyCatalog() async throws {
        struct PartialProvider: YouTubeProviding {
            func search(query: String) async throws -> [Video] { [] }
            func resolve(videoID: String) async throws -> PlaybackResource { throw AppError.unavailable }
            func recommendations(seed: RecommendationSeed, continuation: String?) async throws -> RecommendationPage {
                RecommendationPage(videos: [], continuation: nil)
            }
            func searchDeepWithStatus(query: String, maxPages: Int) async throws -> (videos: [Video], isPartial: Bool) {
                ([videoA], true)
            }
        }
        let catalog = try await PartialProvider().artistCatalog(for: "Artista")
        XCTAssertTrue(catalog.isPartial)
        XCTAssertEqual(catalog.songs, [videoA])
    }

    func testLibraryStoreLoadsLegacySnapshotAndPersistsBlockedChannels() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("library.json")

        let legacyJSON = #"{"schemaVersion":1,"favorites":[],"playlists":[],"recent":[]}"#
        try Data(legacyJSON.utf8).write(to: file)

        let store = LibraryStore(fileURL: file)
        try store.load()
        XCTAssertTrue(store.snapshot.blockedChannels.isEmpty)

        let target = Video(id: "blk00000001", title: "Tema", author: "Canal Imitador", channelID: "UCbad")
        try store.setChannelBlocked(for: target, blocked: true)
        XCTAssertTrue(store.isChannelBlocked(target))
        XCTAssertEqual(store.blockedChannelIDs, ["UCbad"])

        let reopened = LibraryStore(fileURL: file)
        try reopened.load()
        XCTAssertEqual(reopened.blockedChannelIDs, ["UCbad"])

        try reopened.unblockChannel(id: "UCbad")
        XCTAssertTrue(reopened.blockedChannelIDs.isEmpty)
    }

    func testOfficialOnlySettingMapsToUnknownFallbackPolicy() {
        XCTAssertFalse(CatalogSettings.policy(officialOnly: true).allowUnknownFallback())
        XCTAssertTrue(CatalogSettings.policy(officialOnly: false).allowUnknownFallback())
    }

    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }
}

private struct StubMusicSearchProvider: YouTubeProviding {
    var onMusicSearch: @Sendable (String, MusicSearchFilter?, String?) async throws -> MusicSearchResult

    func search(query: String) async throws -> [Video] { [] }
    func resolve(videoID: String) async throws -> PlaybackResource { throw AppError.unavailable }
    func recommendations(seed: RecommendationSeed, continuation: String?) async throws -> RecommendationPage {
        RecommendationPage(videos: [], continuation: nil)
    }
    func musicSearch(query: String, filter: MusicSearchFilter?, continuation: String?) async throws -> MusicSearchResult {
        try await onMusicSearch(query, filter, continuation)
    }
}
