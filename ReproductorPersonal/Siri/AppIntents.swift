import AppIntents
import Foundation

@MainActor
protocol SiriPlaybackControlling: AnyObject {
    var state: PlaybackState { get }
    func play(_ videos: [Video]) async
    func pause()
    func resume() async
}

extension PlaybackController: SiriPlaybackControlling {
    func play(_ videos: [Video]) async {
        await play(videos, startingAt: 0)
    }

    func resume() async {
        await resume(allowAutomaticSkip: false)
    }
}

enum SiriPlaybackError: Error, Equatable, LocalizedError {
    case unavailable
    case noFavorites
    case noMusic
    case emptyQuery
    case noResults(String)

    var errorDescription: String? {
        switch self {
        case .unavailable: return "Abre Aparato Reproductor e inténtalo otra vez."
        case .noFavorites: return "No tienes favoritos para reproducir."
        case .noMusic: return "No tienes música local para reproducir."
        case .emptyQuery: return "Dime qué artista o canción quieres escuchar."
        case .noResults(let query): return "No encontré resultados para \(query)."
        }
    }
}

@MainActor
final class SiriPlaybackService {
    private let library: LibraryStore
    private let playback: any SiriPlaybackControlling
    private let source: (any YouTubeProviding)?

    init(library: LibraryStore, playback: any SiriPlaybackControlling, source: (any YouTubeProviding)? = nil) {
        self.library = library
        self.playback = playback
        self.source = source
    }

    func playFavorites() async throws {
        try library.load()
        let favorites = library.snapshot.favorites
        guard !favorites.isEmpty else { throw SiriPlaybackError.noFavorites }
        await playback.play(favorites)
    }

    func playMusic() async throws {
        try library.load()
        let music = library.allMusic
        guard !music.isEmpty else { throw SiriPlaybackError.noMusic }
        await playback.play(music)
    }

    func playArtist(_ artistName: String) async throws {
        let trimmed = artistName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SiriPlaybackError.emptyQuery }

        if let source {
            let fetched = (try? await source.search(query: "\(trimmed) canciones oficiales").prioritizingSongs()) ?? []
            if !fetched.isEmpty {
                await playback.play(fetched)
                return
            }
        }

        try? library.load()
        let normQuery = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let localMatches = library.allMusic.filter { video in
            let normAuthor = video.canonicalArtistName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            return normAuthor.contains(normQuery) || normQuery.contains(normAuthor)
        }
        guard !localMatches.isEmpty else { throw SiriPlaybackError.noResults(trimmed) }
        await playback.play(localMatches)
    }

    func playSong(_ query: String, artist: String? = nil) async throws {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { throw SiriPlaybackError.emptyQuery }

        let fullQuery: String
        if let artist = artist?.trimmingCharacters(in: .whitespacesAndNewlines), !artist.isEmpty {
            fullQuery = "\(trimmedQuery) \(artist) cancion oficial"
        } else {
            fullQuery = "\(trimmedQuery) cancion oficial"
        }

        if let source {
            let fetched = (try? await source.search(query: fullQuery).prioritizingSongs()) ?? []
            if !fetched.isEmpty {
                await playback.play(fetched)
                return
            }
        }

        try? library.load()
        let normQuery = trimmedQuery.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        let localMatches = library.allMusic.filter { video in
            let normTitle = video.title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            let normAuthor = video.canonicalArtistName.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            return normTitle.contains(normQuery) || normAuthor.contains(normQuery)
        }
        guard !localMatches.isEmpty else { throw SiriPlaybackError.noResults(trimmedQuery) }
        await playback.play(localMatches)
    }

    func knownArtists() -> [String] {
        try? library.load()
        return library.allMusic.groupedArtists().map(\.name)
    }

    func pauseOrResume() async {
        if playback.state.isPlaying { playback.pause() }
        else { await playback.resume() }
    }
}

@MainActor
final class SiriPlaybackBridge {
    static let shared = SiriPlaybackBridge()
    private var service: SiriPlaybackService?

    func configure(library: LibraryStore, playback: PlaybackController, source: (any YouTubeProviding)? = nil) {
        service = SiriPlaybackService(library: library, playback: playback, source: source)
    }

    func playFavorites() async throws { try await configuredService().playFavorites() }
    func playMusic() async throws { try await configuredService().playMusic() }
    func playArtist(_ artistName: String) async throws { try await configuredService().playArtist(artistName) }
    func playSong(_ query: String, artist: String? = nil) async throws { try await configuredService().playSong(query, artist: artist) }
    func knownArtists() -> [String] {
        service?.knownArtists() ?? []
    }
    func pauseOrResume() async throws {
        guard let service else { throw SiriPlaybackError.unavailable }
        await service.pauseOrResume()
    }

    private func configuredService() throws -> SiriPlaybackService {
        guard let service else { throw SiriPlaybackError.unavailable }
        return service
    }
}

@available(iOS 16.0, *)
struct ArtistAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Artista")
    static var defaultQuery = ArtistEntityQuery()
    let id: String
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

@available(iOS 16.0, *)
struct ArtistEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [ArtistAppEntity] {
        identifiers.map { ArtistAppEntity(id: $0, name: $0) }
    }
    func entities(matching string: String) async throws -> [ArtistAppEntity] {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try await suggestedEntities() }
        return [ArtistAppEntity(id: trimmed, name: trimmed)]
    }
    func suggestedEntities() async throws -> [ArtistAppEntity] {
        let saved = await MainActor.run { SiriPlaybackBridge.shared.knownArtists() }
        return saved.map { ArtistAppEntity(id: $0, name: $0) }
    }
}

@available(iOS 16.0, *)
struct PlayArtistIntent: AppIntent {
    static var title: LocalizedStringResource = "Reproducir artista"
    static var description = IntentDescription("Busca y reproduce todas las canciones de un artista específico.")
    static var openAppWhenRun = true

    @Parameter(title: "Artista", requestValueDialog: IntentDialog("¿Qué artista quieres escuchar?"))
    var artist: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let target: String
        if let artist, !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            target = artist
        } else {
            target = try await $artist.requestValue("¿Qué artista quieres escuchar?")
        }
        try await SiriPlaybackBridge.shared.playArtist(target)
        return .result(dialog: "Reproduciendo a \(target)")
    }
}

@available(iOS 16.0, *)
struct PlaySavedArtistIntent: AppIntent {
    static var title: LocalizedStringResource = "Escuchar artista"
    static var openAppWhenRun = true

    @Parameter(title: "Artista")
    var artist: ArtistAppEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPlaybackBridge.shared.playArtist(artist.name)
        return .result(dialog: "Reproduciendo a \(artist.name)")
    }
}

@available(iOS 16.0, *)
struct PlaySongIntent: AppIntent {
    static var title: LocalizedStringResource = "Reproducir canción específica"
    static var description = IntentDescription("Busca y reproduce una canción específica y su artista.")
    static var openAppWhenRun = true

    @Parameter(title: "Canción", requestValueDialog: IntentDialog("¿Qué canción quieres escuchar?"))
    var song: String?

    @Parameter(title: "Artista (opcional)")
    var artist: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let targetSong: String
        if let song, !song.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            targetSong = song
        } else {
            targetSong = try await $song.requestValue("¿Qué canción o artista quieres escuchar?")
        }
        try await SiriPlaybackBridge.shared.playSong(targetSong, artist: artist)
        return .result(dialog: "Reproduciendo \(targetSong)")
    }
}

@available(iOS 16.0, *)
struct PlayFavoritesIntent: AppIntent {
    static var title: LocalizedStringResource = "Reproducir favoritos"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await SiriPlaybackBridge.shared.playFavorites()
        return .result()
    }
}

@available(iOS 16.0, *)
struct PauseOrResumeIntent: AppIntent {
    static var title: LocalizedStringResource = "Pausar o reanudar música"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await SiriPlaybackBridge.shared.pauseOrResume()
        return .result()
    }
}

@available(iOS 16.0, *)
struct PlayMusicIntent: AppIntent {
    static var title: LocalizedStringResource = "Reproducir mi música"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        try await SiriPlaybackBridge.shared.playMusic()
        return .result()
    }
}
