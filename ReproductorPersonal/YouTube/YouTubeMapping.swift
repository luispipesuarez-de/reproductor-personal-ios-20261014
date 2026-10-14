import Foundation
import YouTubeKit

enum YouTubeMapping {
    static func videos(from response: SearchResponse) -> [Video] { [] }

    static func resource(hlsURL: URL?, combinedURLs: [URL], expiresAt: Date?) throws -> PlaybackResource {
        throw AppError.unavailable
    }
}
