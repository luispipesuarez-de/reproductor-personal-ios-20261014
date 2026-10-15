import Foundation

struct QueueEntry: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let video: Video

    init(id: UUID = UUID(), video: Video) {
        self.id = id
        self.video = video
    }
}

// Compile-only interface for the assertion-based RED run of Task 3.
struct PlaybackQueue: Equatable {
    private(set) var entries: [QueueEntry]
    private(set) var currentIndex: Int?
    var current: QueueEntry? { nil }

    init(entries: [QueueEntry] = [], currentIndex: Int? = nil) {
        self.entries = entries
        self.currentIndex = currentIndex
    }

    mutating func append(_ video: Video) {}
    mutating func remove(id: UUID) {}
    mutating func next() -> QueueEntry? { nil }
    mutating func previous() -> QueueEntry? { nil }
}
