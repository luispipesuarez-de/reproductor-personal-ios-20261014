import Foundation

struct LyricsLine: Identifiable, Equatable, Sendable {
    var id: Double { timestamp }
    let timestamp: Double
    let text: String
}

struct LyricsData: Equatable, Sendable {
    let plainLyrics: String
    let syncedLines: [LyricsLine]

    var isSynced: Bool { !syncedLines.isEmpty }

    func activeLineIndex(for elapsed: Double) -> Int? {
        guard isSynced else { return nil }
        var active: Int?
        for (index, line) in syncedLines.enumerated() {
            if line.timestamp <= elapsed {
                active = index
            } else {
                break
            }
        }
        return active
    }
}

actor LyricsService {
    static let shared = LyricsService()
    private var cache: [String: LyricsData] = [:]

    func fetchLyrics(for video: Video, duration: Double? = nil) async -> LyricsData? {
        let cacheKey = video.id
        if let cached = cache[cacheKey] { return cached }

        let cleanArtist = video.canonicalArtistName
        let cleanTitle = Self.cleanSongTitle(video.title, artistName: cleanArtist)

        if let direct = await requestLRCLIBDirect(trackName: cleanTitle, artistName: cleanArtist, duration: duration) {
            cache[cacheKey] = direct
            return direct
        }

        if let searched = await searchLRCLIB(query: "\(cleanArtist) \(cleanTitle)") {
            cache[cacheKey] = searched
            return searched
        }

        return nil
    }

    private func requestLRCLIBDirect(trackName: String, artistName: String, duration: Double?) async -> LyricsData? {
        var components = URLComponents(string: "https://lrclib.net/api/get")
        var queryItems = [
            URLQueryItem(name: "artist_name", value: artistName),
            URLQueryItem(name: "track_name", value: trackName)
        ]
        if let duration, duration > 10 {
            queryItems.append(URLQueryItem(name: "duration", value: String(Int(duration))))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { return nil }

        guard let data = try? await fetchData(from: url) else { return nil }
        return parseLRCLIBResponse(data)
    }

    private func searchLRCLIB(query: String) async -> LyricsData? {
        var components = URLComponents(string: "https://lrclib.net/api/search")
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components?.url else { return nil }

        guard let data = try? await fetchData(from: url) else { return nil }
        guard let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = array.first,
              let firstData = try? JSONSerialization.data(withJSONObject: first) else { return nil }
        return parseLRCLIBResponse(firstData)
    }

    private func fetchData(from url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("AparatoReproductor/1.0", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func parseLRCLIBResponse(_ data: Data) -> LyricsData? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let plain = (json["plainLyrics"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let syncedRaw = json["syncedLyrics"] as? String

        var parsedLines: [LyricsLine] = []
        if let syncedRaw {
            parsedLines = Self.parseLRC(syncedRaw)
        }

        if plain.isEmpty && parsedLines.isEmpty { return nil }
        return LyricsData(plainLyrics: plain, syncedLines: parsedLines)
    }

    static func parseLRC(_ lrc: String) -> [LyricsLine] {
        var lines: [LyricsLine] = []
        let rawLines = lrc.components(separatedBy: .newlines)
        for raw in rawLines {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("["), let closingBracket = trimmed.firstIndex(of: "]") else { continue }
            let timeString = String(trimmed[trimmed.index(after: trimmed.startIndex)..<closingBracket])
            let text = String(trimmed[trimmed.index(after: closingBracket)...]).trimmingCharacters(in: .whitespacesAndNewlines)

            let parts = timeString.split(separator: ":")
            if parts.count == 2, let minutes = Double(parts[0]), let seconds = Double(parts[1]) {
                let timestamp = minutes * 60 + seconds
                lines.append(LyricsLine(timestamp: timestamp, text: text))
            }
        }
        return lines.sorted { $0.timestamp < $1.timestamp }
    }

    static func cleanSongTitle(_ title: String, artistName: String) -> String {
        var clean = title

        let artistPrefix = "\(artistName) - "
        if clean.lowercased().hasPrefix(artistPrefix.lowercased()) {
            clean = String(clean.dropFirst(artistPrefix.count))
        }

        let regexPatterns = [
            #"\s*\([^)]*(?:video|audio|oficial|official|letra|lyrics|remaster|en vivo|live|hd)[^)]*\)"#,
            #"\s*\[[^\]]*(?:video|audio|oficial|official|letra|lyrics|remaster|en vivo|live|hd)[^\]]*\]"#,
            #"(?i)\s*(?:video oficial|official video|audio oficial|official audio)"#
        ]

        for pattern in regexPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                clean = regex.stringByReplacingMatches(in: clean, range: NSRange(clean.startIndex..., in: clean), withTemplate: "")
            }
        }

        clean = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("-") { clean = String(clean.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) }
        if clean.hasSuffix("-") { clean = String(clean.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines) }

        return clean.isEmpty ? title : clean
    }
}
