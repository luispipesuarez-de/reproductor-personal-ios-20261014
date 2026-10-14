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
            if let resource = try? YouTubeMapping.resource(
                hlsURL: response.videoInfos.streamingURL, combinedURLs: [], expiresAt: expiresAt
            ) {
                guard needsProcessing(resource.url) else { return resource }
                let player = try await webPlayer(videoID: videoID)
                var carrier: any AdaptiveDownloadFormat = VideoDownloadFormat(url: resource.url)
                try player.processDownloadFormatURL(item: &carrier)
                guard let url = carrier.url else { throw AppError.resolutionFailed }
                let decoded = player.decodeNParameterInHLSManifestURL(url.absoluteString)
                // The dependency returns the input on an HLS solver failure.
                // Do not announce an encrypted manifest as ready for playback.
                if url.path.contains("/n/"), decoded == url { throw AppError.resolutionFailed }
                return try YouTubeMapping.resource(hlsURL: decoded, combinedURLs: [], expiresAt: expiresAt)
            }

            let candidates = response.defaultFormats.filter {
                $0 is VideoDownloadFormat && $0.mimeType == "video/mp4" && [18, 22, 37].contains($0.itag)
            }
            let requiresPlayer = candidates.contains {
                $0.signatureCipher != nil || $0.url.map(needsProcessing) == true
            }
            let player = requiresPlayer ? try await webPlayer(videoID: videoID) : nil
            var combinedURLs: [URL] = []
            // Only the default (muxed) formats, never adaptive video-only/audio-only tracks.
            // These itags are H.264 + AAC in MP4, supported by the minimum iOS version.
            for var format in candidates {
                if let player {
                    do { try player.processDownloadFormatURL(item: &format) }
                    catch { continue }
                } else if format.signatureCipher != nil {
                    continue
                }
                if let url = format.url { combinedURLs.append(url) }
            }
            return try YouTubeMapping.resource(
                hlsURL: nil, combinedURLs: combinedURLs, expiresAt: expiresAt
            )
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
