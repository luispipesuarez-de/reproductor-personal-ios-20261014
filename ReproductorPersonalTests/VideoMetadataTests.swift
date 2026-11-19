import XCTest
@testable import ReproductorPersonal

final class VideoMetadataTests: XCTestCase {
    func testLegacyVideoJSONDecodesWithNilCatalogMetadata() throws {
        let json = #"{"id":"aaaaaaaaaaa","title":"Tema","author":"Artista","durationText":"3:30"}"#
        let video = try JSONDecoder().decode(Video.self, from: Data(json.utf8))
        XCTAssertEqual(video.id, "aaaaaaaaaaa")
        XCTAssertNil(video.channelID)
        XCTAssertNil(video.artistRefs)
        XCTAssertNil(video.album)
        XCTAssertNil(video.musicVideoType)
        XCTAssertNil(video.catalogSource)
    }

    func testCatalogMetadataSurvivesEncodeAndDecode() throws {
        let video = Video(id: "aaaaaaaaaaa", title: "Tema", author: "Artista", durationText: "3:30",
                          channelID: "UCcanal", artistRefs: [ArtistRef(name: "Artista", browseID: "UCartista")],
                          album: AlbumRef(title: "Disco", browseID: "MPREb_disco"),
                          musicVideoType: .atv, catalogSource: .youtubeMusic)
        let decoded = try JSONDecoder().decode(Video.self, from: JSONEncoder().encode(video))
        XCTAssertEqual(decoded, video)
        XCTAssertEqual(decoded.artistRefs?.first?.browseID, "UCartista")
        XCTAssertEqual(decoded.album?.browseID, "MPREb_disco")
        XCTAssertEqual(decoded.musicVideoType, .atv)
    }

    func testLibrarySnapshotSavedBeforeCatalogMetadataStillLoads() throws {
        let video = #"{"id":"aaaaaaaaaaa","title":"Tema","author":"Artista"}"#
        let json = #"{"schemaVersion":1,"favorites":[\#(video)],"playlists":[],"recent":[\#(video)]}"#
        let snapshot = try JSONDecoder().decode(LibrarySnapshot.self, from: Data(json.utf8))
        XCTAssertEqual(snapshot.favorites.map(\.id), ["aaaaaaaaaaa"])
        XCTAssertNil(snapshot.favorites.first?.artistRefs)
        XCTAssertTrue(snapshot.disliked.isEmpty)
    }

    func testMusicVideoTypeParsesYouTubeMusicValues() {
        XCTAssertEqual(MusicVideoType(youTubeMusicValue: "MUSIC_VIDEO_TYPE_ATV"), .atv)
        XCTAssertEqual(MusicVideoType(youTubeMusicValue: "MUSIC_VIDEO_TYPE_OMV"), .omv)
        XCTAssertEqual(MusicVideoType(youTubeMusicValue: "MUSIC_VIDEO_TYPE_UGC"), .ugc)
        XCTAssertEqual(MusicVideoType(youTubeMusicValue: "MUSIC_VIDEO_TYPE_PODCAST_EPISODE"), .other)
        XCTAssertEqual(MusicVideoType(youTubeMusicValue: nil), .other)
    }
}
