import Foundation
import XCTest
@testable import ReproductorPersonal

final class YouTubeClientResolutionTests: XCTestCase {
    func testNativeHLSCanResolveWithoutAWebPlayer() async throws {
        XCTAssertTrue(URLProtocol.registerClass(NativePlaybackFixture.self))
        defer { URLProtocol.unregisterClass(NativePlaybackFixture.self) }
        let resource = try await YouTubeClient().resolve(videoID: "aaaaaaaaaaa")
        XCTAssertEqual(resource.url, URL(string: "https://media.example.test/native.m3u8"))
        XCTAssertGreaterThan(try XCTUnwrap(resource.expiresAt), Date().addingTimeInterval(30))
    }

    func testNativeCombinedMP4CanResolveWithoutAWebPlayer() async throws {
        XCTAssertTrue(URLProtocol.registerClass(CombinedPlaybackFixture.self))
        defer { URLProtocol.unregisterClass(CombinedPlaybackFixture.self) }
        let resource = try await YouTubeClient().resolve(videoID: "aaaaaaaaaaa")
        XCTAssertEqual(resource.url, URL(string: "https://media.example.test/native.mp4"))
    }

    func testSABROnlyResponseIsUnavailableForNativePlayer() async {
        XCTAssertTrue(URLProtocol.registerClass(SABRPlaybackFixture.self))
        defer { URLProtocol.unregisterClass(SABRPlaybackFixture.self) }
        do {
            _ = try await YouTubeClient().resolve(videoID: "aaaaaaaaaaa")
            XCTFail("SABR must not be passed to AVPlayer")
        } catch {
            XCTAssertEqual(error as? AppError, .unavailable)
        }
    }
}

// Intercept the third-party request at the URL loading boundary. No YouTube network
// access and no replacement of the client's actual resolution code.
private class NativePlaybackFixture: URLProtocol, @unchecked Sendable {
    class var playerJSON: String {
        #"{"playabilityStatus":{"status":"OK"},"videoDetails":{"videoId":"aaaaaaaaaaa"},"streamingData":{"hlsManifestUrl":"https://media.example.test/native.m3u8","expiresInSeconds":"60"}}"#
    }

    override class func canInit(with request: URLRequest) -> Bool {
        let host = request.url?.host ?? ""
        return host == "youtube.com" || host.hasSuffix(".youtube.com")
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) else { return }
        let body = url.path == "/youtubei/v1/player" ? type(of: self).playerJSON : "<html>No web player available</html>"
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private final class CombinedPlaybackFixture: NativePlaybackFixture, @unchecked Sendable {
    override class var playerJSON: String {
        #"{"playabilityStatus":{"status":"OK"},"videoDetails":{"videoId":"aaaaaaaaaaa"},"streamingData":{"formats":[{"itag":18,"mimeType":"video/mp4","fps":30,"url":"https://media.example.test/native.mp4"}]}}"#
    }
}

private final class SABRPlaybackFixture: NativePlaybackFixture, @unchecked Sendable {
    override class var playerJSON: String {
        #"{"playabilityStatus":{"status":"OK"},"videoDetails":{"videoId":"aaaaaaaaaaa"},"streamingData":{"serverAbrStreamingUrl":"https://media.example.test/sabr"}}"#
    }
}
