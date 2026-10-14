import Foundation
import YouTubeKit

actor YouTubeClient: YouTubeProviding {
    private let model = YouTubeModel()

    func search(query: String) async throws -> [Video] {
        do {
            let response = try await SearchResponse.sendThrowingRequest(
                youtubeModel: model, data: [.query: query], useCookies: false
            )
            return YouTubeMapping.videos(from: response)
        } catch {
            throw AppError.classify(error)
        }
    }

    func resolve(videoID: String) async throws -> PlaybackResource {
        do {
            let response = try await VideoInfosWithDownloadFormatsResponse.sendThrowingRequest(
                youtubeModel: model, data: [.query: videoID], useCookies: false
            )
            let expiresAt = response.videoInfos.videoURLsExpireAt
            var decoder: PlayerProcessing.Player?
            var decoderAttempted = false
            var processingFailure: Error?
            if let resource = try? YouTubeMapping.resource(
                hlsURL: response.videoInfos.streamingURL, combinedURLs: [], expiresAt: expiresAt
            ) {
                if !needsProcessing(resource.url) { return resource }
                do {
                    decoderAttempted = true
                    let player = try await webPlayer(videoID: videoID)
                    decoder = player
                    var carrier: any AdaptiveDownloadFormat = VideoDownloadFormat(url: resource.url)
                    try player.processDownloadFormatURL(item: &carrier)
                    guard let url = carrier.url else { throw AppError.resolutionFailed }
                    let decoded = player.decodeNParameterInHLSManifestURL(url.absoluteString)
                    // This API silently returns the input when its HLS solver fails.
                    if url.path.contains("/n/"), decoded == url { throw AppError.resolutionFailed }
                    return try YouTubeMapping.resource(hlsURL: decoded, combinedURLs: [], expiresAt: expiresAt)
                } catch { processingFailure = error }
            }

            // Default formats are muxed. These itags contain native H.264 + AAC.
            let candidates = response.defaultFormats.filter {
                $0 is VideoDownloadFormat && $0.mimeType == "video/mp4" && [18, 22, 37].contains($0.itag)
            }
            let directURLs = candidates.compactMap { format -> URL? in
                guard format.signatureCipher == nil, let url = format.url, !needsProcessing(url) else { return nil }
                return url
            }
            if let direct = try? YouTubeMapping.resource(hlsURL: nil, combinedURLs: directURLs, expiresAt: expiresAt) {
                return direct
            }

            let encrypted = candidates.filter {
                $0.signatureCipher != nil || $0.url.map(needsProcessing) == true
            }
            if !encrypted.isEmpty, !decoderAttempted {
                do { decoder = try await webPlayer(videoID: videoID) }
                catch { processingFailure = error }
            }
            var processedURLs: [URL] = []
            if let decoder {
                for var format in encrypted {
                    do {
                        try decoder.processDownloadFormatURL(item: &format)
                        if let url = format.url { processedURLs.append(url) }
                    } catch { processingFailure = error }
                }
            }
            if let resource = try? YouTubeMapping.resource(hlsURL: nil, combinedURLs: processedURLs, expiresAt: expiresAt) { return resource }
            if let processingFailure { throw processingFailure }
            throw AppError.unavailable
        } catch is ResponseExtractionError {
            throw AppError.unavailable
        } catch {
            throw AppError.classify(error)
        }
    }

    private func webPlayer(videoID: String) async throws -> PlayerProcessing.Player {
        let response = try await VideoInfosResponse.sendThrowingRequest(
            youtubeModel: model, data: [.query: videoID], useCookies: false
        )
        guard let player = response.player else { throw AppError.resolutionFailed }
        return player
    }

    private func needsProcessing(_ url: URL) -> Bool {
        url.path.contains("/n/") || URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.contains(where: { $0.name == "n" }) == true
    }
}
