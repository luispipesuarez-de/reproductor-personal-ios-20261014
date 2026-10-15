import Combine
import Foundation

// Compile-only interfaces before the storage behavior's RED run.
@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var snapshot = LibrarySnapshot()
    init(fileURL: URL) {}
    func load() throws {}
    func setFavorite(_ video: Video, enabled: Bool) throws {}
    func createPlaylist(name: String) throws -> UUID { UUID() }
    func renamePlaylist(id: UUID, name: String) throws {}
    func deletePlaylist(id: UUID) throws {}
    func add(_ video: Video, to playlistID: UUID) throws {}
    func remove(at index: Int, from playlistID: UUID) throws {}
    func recordRecent(_ video: Video) throws {}
    func saveQueue(_ queue: QueueSnapshot) throws {}
}
