import XCTest
@testable import ReproductorPersonal

final class LyricsServiceTests: XCTestCase {
    func testCleanSongTitleRemovesYouTubeBoilerplate() {
        let cleaned1 = LyricsService.cleanSongTitle("Juan Luis Guerra - Bachata Rosa (Video Oficial)", artistName: "Juan Luis Guerra")
        XCTAssertEqual(cleaned1, "Bachata Rosa")

        let cleaned2 = LyricsService.cleanSongTitle("La Bilirrubina [Official Audio]", artistName: "Juan Luis Guerra")
        XCTAssertEqual(cleaned2, "La Bilirrubina")

        let cleaned3 = LyricsService.cleanSongTitle("Burbujas de Amor (Letra / Lyrics)", artistName: "Juan Luis Guerra")
        XCTAssertEqual(cleaned3, "Burbujas de Amor")
    }

    func testParseLRCExtractsTimestampsAndSortedLines() {
        let sampleLRC = """
        [00:05.10] Entrada musical
        [00:15.50] Primera línea cantada
        [00:22.00] Segunda línea cantada
        """
        let lines = LyricsService.parseLRC(sampleLRC)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].timestamp, 5.1, accuracy: 0.01)
        XCTAssertEqual(lines[0].text, "Entrada musical")
        XCTAssertEqual(lines[1].timestamp, 15.5, accuracy: 0.01)
        XCTAssertEqual(lines[2].timestamp, 22.0, accuracy: 0.01)
    }

    func testActiveLineIndexReturnsCorrectCurrentLine() {
        let lines = [
            LyricsLine(timestamp: 5.0, text: "A"),
            LyricsLine(timestamp: 15.0, text: "B"),
            LyricsLine(timestamp: 25.0, text: "C")
        ]
        let data = LyricsData(plainLyrics: "A\nB\nC", syncedLines: lines)

        XCTAssertNil(data.activeLineIndex(for: 2.0))
        XCTAssertEqual(data.activeLineIndex(for: 5.0), 0)
        XCTAssertEqual(data.activeLineIndex(for: 10.0), 0)
        XCTAssertEqual(data.activeLineIndex(for: 15.0), 1)
        XCTAssertEqual(data.activeLineIndex(for: 20.0), 1)
        XCTAssertEqual(data.activeLineIndex(for: 30.0), 2)
    }

    func testDismissPlaybackClearsStateAndQueue() async {
        let video = Video(id: "vid001", title: "Test", author: "Author")
        let source = StubYouTubeProvider()
        let controller = await PlaybackController(source: source, dislikedIDs: { [] })

        await controller.play(video)
        await controller.dismissPlayback()

        let state = await controller.state
        let queueCount = await controller.queue.entries.count
        XCTAssertEqual(state, .idle)
        XCTAssertEqual(queueCount, 0)
    }
}
