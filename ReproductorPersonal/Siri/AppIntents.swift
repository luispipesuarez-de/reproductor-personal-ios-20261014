import AppIntents
import Foundation

@MainActor
protocol SiriPlaybackControlling: AnyObject {
    var state: PlaybackState { get }
    func play(_ videos: [Video]) async
    func play(_ videos: [Video], seed: RecommendationSeed?) async
    func startRadio(genre: String) async
    func pause()
    func resume() async
}

extension SiriPlaybackControlling {
    func play(_ videos: [Video], seed: RecommendationSeed?) async {
        await play(videos)
    }

    func startRadio(genre: String) async {}
}

extension PlaybackController: SiriPlaybackControlling {
    func play(_ videos: [Video]) async {
        await play(videos, startingAt: 0)
    }

    func play(_ videos: [Video], seed: RecommendationSeed?) async {
        await play(videos, startingAt: 0, seed: seed)
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
            if let search = try? await source.musicSearch(query: trimmed, filter: .artists, continuation: nil) {
                let target = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
                let candidates = [search.topArtist].compactMap { $0 } + search.artists
                let chosen = candidates.first(where: { $0.normalizedName == target && $0.browseID != nil })
                    ?? candidates.first(where: { $0.browseID != nil })
                if let artistID = chosen?.browseID,
                   let catalog = try? await source.artistCatalog(artistID: artistID),
                   !catalog.songs.isEmpty {
                    let seed = RecommendationSeed.artist(
                        channelID: artistID,
                        name: catalog.artistName.isEmpty ? trimmed : catalog.artistName,
                        radioPlaylistID: catalog.radioPlaylistID
                    )
                    await playback.play(catalog.songs, seed: seed)
                    return
                }
            }
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
            let musicQuery = [trimmedQuery, artist?.trimmingCharacters(in: .whitespacesAndNewlines)]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
            if let search = try? await source.musicSearch(query: musicQuery, filter: .songs, continuation: nil),
               !search.songs.isEmpty {
                let expected = artist?.trimmingCharacters(in: .whitespacesAndNewlines)
                let identity = (expected?.isEmpty == false) ? ArtistIdentity(name: expected!) : nil
                let nonSuspicious = search.songs.filter { TrackAuthenticity.assess($0, expected: identity).tier != .suspicious }
                let pool = nonSuspicious.isEmpty ? search.songs : nonSuspicious
                let chosen = pool.first(where: {
                    let assessment = TrackAuthenticity.assess($0, expected: identity)
                    return assessment.tier <= .officialChannel && (identity == nil || assessment.matchesArtist == true)
                }) ?? pool.first(where: {
                    identity == nil || TrackAuthenticity.assess($0, expected: identity).matchesArtist != false
                }) ?? pool.first
                if let chosen {
                    await playback.play([chosen])
                    return
                }
            }
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

    func playGenre(_ genre: String) async throws {
        let trimmed = genre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw SiriPlaybackError.emptyQuery }
        await playback.startRadio(genre: trimmed)
    }

    func knownGenres() -> [String] {
        try? library.load()
        return library.genres
    }

    func knownArtists() -> [String] {
        try? library.load()
        return library.allMusic.groupedArtists().map(\.name)
    }

    func knownSongs() -> [String] {
        try? library.load()
        return library.allMusic.map(\.title)
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
    func playGenre(_ genre: String) async throws { try await configuredService().playGenre(genre) }
    func knownGenres() -> [String] { configuredService().knownGenres() }

    func knownArtists() -> [String] {
        configuredService().knownArtists()
    }
    func knownSongs() -> [String] {
        configuredService().knownSongs()
    }
    func pauseOrResume() async throws {
        await configuredService().pauseOrResume()
    }

    private func configuredService() -> SiriPlaybackService {
        if let service { return service }
        let library = LibraryStore(fileURL: LibraryStore.defaultFileURL)
        let source = YouTubeClient()
        let policy = CatalogSettings.livePolicy(
            blockedChannelIDs: { library.blockedChannelIDs },
            blockedArtistNames: { library.blockedArtistNames }
        )
        let playback = PlaybackController(source: source, dislikedIDs: { library.negativeVideoIDs }, policy: policy)
        let newService = SiriPlaybackService(library: library, playback: playback, source: source)
        self.service = newService
        return newService
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
        let seeded = [
            "Juan Luis Guerra", "Grupo Niche", "Shakira", "Carlos Vives",
            "Marc Anthony", "Soda Stereo", "Maná", "Bad Bunny", "Karol G"
        ]
        let combined = Array(NSOrderedSet(array: saved + seeded)).compactMap { $0 as? String }
        return combined.map { ArtistAppEntity(id: $0, name: $0) }
    }
}

@available(iOS 16.0, *)
struct SongAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Canción")
    static var defaultQuery = SongEntityQuery()
    let id: String
    let title: String
    let artist: String?
    var displayRepresentation: DisplayRepresentation {
        if let artist, !artist.isEmpty {
            return DisplayRepresentation(title: "\(title)", subtitle: "\(artist)")
        }
        return DisplayRepresentation(title: "\(title)")
    }
}

@available(iOS 16.0, *)
struct SongEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [SongAppEntity] {
        identifiers.map { SongAppEntity(id: $0, title: $0, artist: nil) }
    }
    func entities(matching string: String) async throws -> [SongAppEntity] {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try await suggestedEntities() }
        return [SongAppEntity(id: trimmed, title: trimmed, artist: nil)]
    }
    func suggestedEntities() async throws -> [SongAppEntity] {
        let saved = await MainActor.run { SiriPlaybackBridge.shared.knownSongs() }
        let seeded = [
            "Bachata Rosa", "La Bilirrubina", "Cali Pachanguero", "Despacito",
            "La Bicicleta", "Vivir Mi Vida", "De Música Ligera", "Rayando el Sol"
        ]
        let combined = Array(NSOrderedSet(array: saved + seeded)).compactMap { $0 as? String }
        return combined.map { SongAppEntity(id: $0, title: $0, artist: nil) }
    }
}

@available(iOS 16.0, *)
struct PlaySongEntityIntent: AppIntent {
    static var title: LocalizedStringResource = "Reproducir canción"
    static var description = IntentDescription("Reproduce una canción específica con Siri.")
    static var openAppWhenRun = true

    @Parameter(title: "Canción")
    var song: SongAppEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPlaybackBridge.shared.playSong(song.title, artist: song.artist)
        return .result(dialog: "Reproduciendo \(song.title)")
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

@available(iOS 16.0, *)
struct GenreAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Género")
    static var defaultQuery = GenreEntityQuery()
    let id: String
    let name: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

@available(iOS 16.0, *)
struct GenreEntityQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [GenreAppEntity] {
        identifiers.map { GenreAppEntity(id: $0, name: $0) }
    }

    func entities(matching string: String) async throws -> [GenreAppEntity] {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try await suggestedEntities() }
        let known = await MainActor.run { SiriPlaybackBridge.shared.knownGenres() }
        let matches = known.filter { $0.localizedCaseInsensitiveContains(trimmed) }
        let names = matches.isEmpty ? [trimmed] : matches
        return names.map { GenreAppEntity(id: $0, name: $0) }
    }

    func suggestedEntities() async throws -> [GenreAppEntity] {
        let genres = await MainActor.run { SiriPlaybackBridge.shared.knownGenres() }
        return genres.map { GenreAppEntity(id: $0, name: $0) }
    }
}

@available(iOS 16.0, *)
struct PlaySavedGenreIntent: AppIntent {
    static var title: LocalizedStringResource = "Reproducir género"
    static var description = IntentDescription("Inicia una radio del género musical elegido.")
    static var openAppWhenRun = true

    @Parameter(title: "Género")
    var genre: GenreAppEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await SiriPlaybackBridge.shared.playGenre(genre.name)
        return .result(dialog: "Reproduciendo \(genre.name)")
    }
}

@available(iOS 16.0, *)
struct PlayGenreIntent: AppIntent {
    static var title: LocalizedStringResource = "Reproducir un género"
    static var description = IntentDescription("Busca y reproduce música de un género específico.")
    static var openAppWhenRun = true

    @Parameter(title: "Género", requestValueDialog: IntentDialog("¿Qué género quieres escuchar?"))
    var genre: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let target: String
        if let genre, !genre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            target = genre
        } else {
            target = try await $genre.requestValue("¿Qué género quieres escuchar?")
        }
        try await SiriPlaybackBridge.shared.playGenre(target)
        return .result(dialog: "Reproduciendo \(target)")
    }
}
