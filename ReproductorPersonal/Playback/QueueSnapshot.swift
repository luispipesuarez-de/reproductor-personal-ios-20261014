import Foundation

struct QueueSnapshot: Codable, Equatable, Sendable {
    var entries: [QueueEntry]
    var currentIndex: Int?
    var progressSeconds: Double

    init(entries: [QueueEntry] = [], currentIndex: Int? = nil, progressSeconds: Double = 0) {
        self.entries = entries
        self.currentIndex = currentIndex
        self.progressSeconds = progressSeconds
    }
}
