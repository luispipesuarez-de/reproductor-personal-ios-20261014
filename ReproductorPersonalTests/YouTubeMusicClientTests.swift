import Foundation
import XCTest
@testable import ReproductorPersonal

final class YouTubeMusicClientTests: XCTestCase {
    func testRequestsUseWebRemixArgentinaNoCookiesAndReuseVisitorData() async throws {
        let recorder = RequestRecorder()
        let client = YouTubeMusicClient(language: "es") { request in
            await recorder.append(request)
            let url = try XCTUnwrap(request.url)
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            let payload = #"{"responseContext":{"visitorData":"visitor-abc"}}"#
            return (Data(payload.utf8), response)
        }

        _ = try await client.post("search", body: ["query": "Juan Luis Guerra"])
        _ = try await client.post("next", body: ["videoId": "aaaaaaaaaaa"])

        let requests = await recorder.requests
        XCTAssertEqual(requests.count, 2)

        let first = requests[0]
        XCTAssertEqual(first.url?.absoluteString, "https://music.youtube.com/youtubei/v1/search?prettyPrint=false")
        XCTAssertEqual(first.httpMethod, "POST")
        XCTAssertFalse(first.httpShouldHandleCookies)
        XCTAssertEqual(first.value(forHTTPHeaderField: "Content-Type"), "application/json; charset=utf-8")
        XCTAssertNil(first.value(forHTTPHeaderField: "X-Goog-Visitor-Id"))

        let firstBody = try XCTUnwrap(first.httpBody.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] })
        let clientCtx = try XCTUnwrap((firstBody["context"] as? [String: Any])?["client"] as? [String: Any])
        XCTAssertEqual(clientCtx["clientName"] as? String, "WEB_REMIX")
        XCTAssertEqual(clientCtx["gl"] as? String, "AR")

        let second = requests[1]
        XCTAssertEqual(second.value(forHTTPHeaderField: "X-Goog-Visitor-Id"), "visitor-abc")
    }

    func testBrowseCacheAvoidsDuplicateNetworkCallsWithinTTL() async throws {
        let recorder = RequestRecorder()
        let clock = MutableClock()
        let client = YouTubeMusicClient(now: { clock.now }) { request in
            await recorder.append(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (Data("{}".utf8), response)
        }

        _ = try await client.browseArtist(id: "UCartist1")
        _ = try await client.browseArtist(id: "UCartist1")
        var count = await recorder.count
        XCTAssertEqual(count, 1)

        clock.now = clock.now.addingTimeInterval(31 * 60)
        _ = try await client.browseArtist(id: "UCartist1")
        count = await recorder.count
        XCTAssertEqual(count, 2)
    }

    func testYouTubeClientArtistCatalogCombinesArtistAlbumsSinglesAndAllSongsFromFixtures() async throws {
        let artistData = try fixtureData("ytm-artist")
        let albumsData = try fixtureData("ytm-artist-albums")
        let singlesData = try fixtureData("ytm-artist-singles")
        let songsData = try fixtureData("ytm-artist-songs")
        let expectedAlbumsCount = YTMusicParser.parseReleases(try JSONSerialization.jsonObject(with: albumsData), artist: nil).count
        let expectedSinglesCount = YTMusicParser.parseReleases(try JSONSerialization.jsonObject(with: singlesData), artist: nil).count

        let music = YouTubeMusicClient { request in
            let body = try XCTUnwrap(request.httpBody.flatMap { try JSONSerialization.jsonObject(with: $0) as? [String: Any] })
            let browseID = body["browseId"] as? String ?? ""
            let params = body["params"] as? String ?? ""
            let data: Data
            if browseID == "UCxtvuCXJMwEzD0_t8GbZcNg" { data = artistData }
            else if browseID.hasPrefix("MPAD"), params.contains("ARoCAQI") { data = albumsData }
            else if browseID.hasPrefix("MPAD"), params.contains("AhoCAQI") { data = singlesData }
            else if browseID.hasPrefix("VLOLAK5uy_") { data = songsData }
            else { data = Data("{}".utf8) }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (data, response)
        }

        let client = YouTubeClient(music: music)
        let catalog = try await client.artistCatalog(artistID: "UCxtvuCXJMwEzD0_t8GbZcNg")

        XCTAssertEqual(catalog.albums.count, expectedAlbumsCount)
        XCTAssertEqual(catalog.singles.count, expectedSinglesCount)
        XCTAssertFalse(catalog.songs.isEmpty)
        XCTAssertNotNil(catalog.radioPlaylistID)
        XCTAssertFalse(catalog.isPartial)
    }

    private func fixtureData(_ name: String) throws -> Data {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try Data(contentsOf: url)
    }
}

private actor RequestRecorder {
    private(set) var requests: [URLRequest] = []
    var count: Int { requests.count }
    func append(_ request: URLRequest) { requests.append(request) }
}

private final class MutableClock: @unchecked Sendable {
    var now = Date(timeIntervalSince1970: 1_700_000_000)
}
