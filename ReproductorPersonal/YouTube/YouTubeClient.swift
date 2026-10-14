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
            let response = try await VideoInfosResponse.sendThrowingRequest(
                youtubeModel: model, data: [.query: videoID], useCookies: false
            )
            if let resource = try? YouTubeMapping.resource(
                hlsURL: response.streamingURL, combinedURLs: [], expiresAt: response.videoURLsExpireAt
            ) { return resource }

            var combinedURLs: [URL] = []
            // Only the default (muxed) formats, never adaptive video-only/audio-only tracks.
            // These itags are H.264 + AAC in MP4, supported by the minimum iOS version.
            for var format in response.defaultFormats {
                guard format is VideoDownloadFormat, format.mimeType == "video/mp4",
                      [18, 22, 37].contains(format.itag) else { continue }
                if let player = response.player {
                    do { try player.processDownloadFormatURL(item: &format) }
                    catch { continue }
                } else if format.signatureCipher != nil {
                    continue
                }
                if let url = format.url { combinedURLs.append(url) }
            }
            return try YouTubeMapping.resource(
                hlsURL: nil, combinedURLs: combinedURLs, expiresAt: response.videoURLsExpireAt
            )
        } catch is ResponseExtractionError {
            throw AppError.unavailable
        } catch {
            throw AppError.classify(error)
        }
    }
}
