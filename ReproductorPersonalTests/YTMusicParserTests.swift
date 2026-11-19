import Foundation
import XCTest
@testable import ReproductorPersonal

final class YTMusicParserTests: XCTestCase {
    func testSearchAllParsesTopArtistSongsAndChips() throws {
        let result = YTMusicParser.parseSearch(try fixtureJSON("ytm-search-all"))
        XCTAssertEqual(result.topArtist?.browseID, "UCxtvuCXJMwEzD0_t8GbZcNg")
        XCTAssertFalse(result.songs.isEmpty)
        XCTAssertTrue(result.songs.allSatisfy { YTMusicParser.isValidVideoID($0.id) })
        XCTAssertTrue(result.songs.allSatisfy { $0.catalogSource == .youtubeMusic })
    }

    func testSearchSongsParsesArtistsAlbumDurationAndContinuation() throws {
        let result = YTMusicParser.parseSearch(try fixtureJSON("ytm-search-songs"))
        XCTAssertFalse(result.songs.isEmpty)
        XCTAssertNotNil(result.continuation)
        let first = try XCTUnwrap(result.songs.first)
        XCTAssertEqual(first.musicVideoType, .atv)
        XCTAssertTrue(first.artistRefs?.contains(where: { $0.browseID?.hasPrefix("UC") == true }) == true)
        XCTAssertTrue(first.album?.browseID?.hasPrefix("MPREb_") == true)
        XCTAssertNotNil(first.durationSeconds)
    }

    func testSearchAlbumsParsesMPREbIDsAndYears() throws {
        let result = YTMusicParser.parseSearch(try fixtureJSON("ytm-search-albums"))
        XCTAssertFalse(result.albums.isEmpty)
        XCTAssertTrue(result.albums.allSatisfy { $0.id.hasPrefix("MPREb_") })
        XCTAssertTrue(result.albums.contains(where: { $0.year != nil }))
    }

    func testSearchArtistsParsesUCBrowseIDs() throws {
        let result = YTMusicParser.parseSearch(try fixtureJSON("ytm-search-artists"))
        XCTAssertFalse(result.artists.isEmpty)
        XCTAssertTrue(result.artists.allSatisfy { $0.browseID?.hasPrefix("UC") == true })
    }

    func testArtistPageParsesHeaderRadioAndSections() throws {
        let page = YTMusicParser.parseArtistPage(try fixtureJSON("ytm-artist"), artistID: "UCxtvuCXJMwEzD0_t8GbZcNg")
        XCTAssertFalse(page.name.isEmpty)
        XCTAssertNotNil(page.radioPlaylistID)
        XCTAssertFalse(page.topSongs.isEmpty)
        XCTAssertNotNil(page.allSongsBrowseID)
        XCTAssertNotNil(page.albumsMore)
        XCTAssertNotNil(page.singlesMore)
    }

    func testArtistAlbumsAndSinglesParseFullReleases() throws {
        let artist = ArtistRef(name: "Juan Luis Guerra", browseID: "UCxtvuCXJMwEzD0_t8GbZcNg")
        let albums = YTMusicParser.parseReleases(try fixtureJSON("ytm-artist-albums"), artist: artist)
        let singles = YTMusicParser.parseReleases(try fixtureJSON("ytm-artist-singles"), artist: artist)
        XCTAssertFalse(albums.isEmpty)
        XCTAssertFalse(singles.isEmpty)
        XCTAssertTrue(albums.allSatisfy { $0.id.hasPrefix("MPREb_") })
        XCTAssertTrue(singles.allSatisfy { $0.id.hasPrefix("MPREb_") })
    }

    func testArtistSongsAndContinuationParseTrackLists() throws {
        let page1 = YTMusicParser.parseTrackList(try fixtureJSON("ytm-artist-songs"))
        XCTAssertFalse(page1.videos.isEmpty)
        XCTAssertNotNil(page1.continuation)
        XCTAssertTrue(page1.videos.allSatisfy { YTMusicParser.isValidVideoID($0.id) })

        let page2 = YTMusicParser.parseTrackList(try fixtureJSON("ytm-artist-songs-continuation"))
        XCTAssertFalse(page2.videos.isEmpty)
        XCTAssertTrue(page2.videos.allSatisfy { YTMusicParser.isValidVideoID($0.id) })
    }

    func testAlbumParsesOrderedATVTracks() throws {
        let parsed = YTMusicParser.parseAlbum(try fixtureJSON("ytm-album"), browseID: "MPREb_wX4449DSyFX")
        XCTAssertFalse(parsed.album.title.isEmpty)
        XCTAssertFalse(parsed.tracks.isEmpty)
        XCTAssertTrue(parsed.tracks.allSatisfy { $0.musicVideoType == .atv })
        XCTAssertTrue(parsed.tracks.allSatisfy { $0.album?.browseID == "MPREb_wX4449DSyFX" })
    }

    func testRadioAndContinuationParseTracksAndCursor() throws {
        let page1 = YTMusicParser.parseRadio(try fixtureJSON("ytm-radio"))
        XCTAssertFalse(page1.videos.isEmpty)
        XCTAssertNotNil(page1.continuation)
        XCTAssertTrue(page1.videos.allSatisfy { YTMusicParser.isValidVideoID($0.id) })
        XCTAssertTrue(page1.videos.allSatisfy { $0.musicVideoType == .atv })

        let page2 = YTMusicParser.parseRadio(try fixtureJSON("ytm-radio-continuation"))
        XCTAssertFalse(page2.videos.isEmpty)
        XCTAssertTrue(page2.videos.allSatisfy { YTMusicParser.isValidVideoID($0.id) })
    }

    func testMalformedOrEmptyJSONProducesEmptyResultsWithoutCrashing() {
        XCTAssertTrue(YTMusicParser.parseSearch(nil).isEmpty)
        XCTAssertTrue(YTMusicParser.parseSearch(["unexpected": [1, 2, 3]]).isEmpty)
        XCTAssertTrue(YTMusicParser.parseRadio(["bad": "shape"]).videos.isEmpty)
        XCTAssertTrue(YTMusicParser.parseReleases([:], artist: nil).isEmpty)
    }

    private func fixtureJSON(_ name: String) throws -> Any {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        let data = try Data(contentsOf: url)
        return try JSONSerialization.jsonObject(with: data)
    }
}
