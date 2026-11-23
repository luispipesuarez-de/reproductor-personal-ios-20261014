import Combine
import Foundation

enum SearchState: Equatable {
    case idle
    case loading(query: String)
    case results(query: String, videos: [Video])
    case empty(query: String)
    case failed(query: String, message: String)
}

enum SearchDurationFilter: String, CaseIterable, Identifiable {
    case all
    case underFourMinutes
    case fourToTwentyMinutes
    case overTwentyMinutes

    var id: Self { self }

    var title: String {
        switch self {
        case .all: return "Todos"
        case .underFourMinutes: return "<4m"
        case .fourToTwentyMinutes: return "4-20m"
        case .overTwentyMinutes: return ">20m"
        }
    }

    func includes(_ video: Video) -> Bool {
        guard let seconds = video.durationSeconds else { return self == .all }
        switch self {
        case .all: return true
        case .underFourMinutes: return seconds < 240
        case .fourToTwentyMinutes: return (240...1_200).contains(seconds)
        case .overTwentyMinutes: return seconds > 1_200
        }
    }
}

enum SearchCategoryFilter: String, CaseIterable, Identifiable {
    case all
    case songs
    case artists
    case albums

    var id: Self { self }

    var title: String {
        switch self {
        case .all: return "Todo"
        case .songs: return "Canciones"
        case .artists: return "Artistas"
        case .albums: return "Álbumes"
        }
    }

    var musicFilter: MusicSearchFilter? {
        switch self {
        case .all: return nil
        case .songs: return .songs
        case .artists: return .artists
        case .albums: return .albums
        }
    }
}

@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var state: SearchState = .idle
    @Published private(set) var durationFilter: SearchDurationFilter = .all
    @Published private(set) var categoryFilter: SearchCategoryFilter = .all
    @Published private(set) var isLoadingMore = false
    private(set) var lastQuery: String = ""
    let source: any YouTubeProviding
    private var originalResults: [Video] = []
    private var musicArtists: [ArtistSummary] = []
    private var musicAlbums: [AlbumSummary] = []
    private var usedMusicCatalog = false
    private var filterCache: [SearchCategoryFilter: MusicSearchResult] = [:]
    private var continuations: [SearchCategoryFilter: String] = [:]
    private var requestID = UUID()
    private let debounceNanoseconds: UInt64
    private var debounceTask: Task<Void, Never>?

    init(source: any YouTubeProviding, debounceNanoseconds: UInt64 = 400_000_000) {
        self.source = source
        self.debounceNanoseconds = debounceNanoseconds
    }

    deinit { debounceTask?.cancel() }

    var showsDurationFilter: Bool { !originalResults.isEmpty }
    var showsCategoryFilter: Bool { !originalResults.isEmpty || !musicArtists.isEmpty || !musicAlbums.isEmpty }
    var canLoadMore: Bool { continuations[categoryFilter] != nil }

    var filteredArtists: [ArtistSummary] {
        if let cached = filterCache[.artists], !cached.artists.isEmpty {
            return cached.artists
        }
        if !musicArtists.isEmpty {
            return musicArtists
        }
        return originalResults.groupedArtists(matching: lastQuery)
    }

    var filteredAlbums: [AlbumSummary] {
        if let cached = filterCache[.albums], !cached.albums.isEmpty {
            return cached.albums
        }
        if !musicAlbums.isEmpty {
            return musicAlbums
        }
        return originalResults.groupedAlbums(forArtist: lastQuery)
    }

    func setDurationFilter(_ filter: SearchDurationFilter) {
        durationFilter = filter
        switch state {
        case .results(let query, _), .empty(let query): publishResults(query: query)
        default: break
        }
    }

    func setCategoryFilter(_ filter: SearchCategoryFilter) {
        categoryFilter = filter
        switch state {
        case .results(let query, _), .empty(let query):
            if usedMusicCatalog, let musicFilter = filter.musicFilter, filterCache[filter] == nil {
                let currentRequest = requestID
                Task { [weak self] in
                    await self?.fetchFiltered(query: query, category: filter, musicFilter: musicFilter, request: currentRequest)
                }
            }
            publishResults(query: query)
        default: break
        }
    }

    func loadMore() async {
        guard let token = continuations[categoryFilter], !isLoadingMore else { return }
        let query = lastQuery
        let category = categoryFilter
        let currentRequest = requestID
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let next = try await source.musicSearch(query: query, filter: category.musicFilter, continuation: token)
            guard requestID == currentRequest, !Task.isCancelled else { return }
            continuations[category] = next.continuation
            switch category {
            case .artists:
                var existing = filterCache[.artists] ?? MusicSearchResult(artists: musicArtists)
                let seen = Set(existing.artists.map(\.id))
                existing.artists.append(contentsOf: next.artists.filter { !seen.contains($0.id) })
                existing.continuation = next.continuation
                filterCache[.artists] = existing
                musicArtists = existing.artists
                objectWillChange.send()
            case .albums:
                var existing = filterCache[.albums] ?? MusicSearchResult(albums: musicAlbums)
                let seen = Set(existing.albums.map(\.id))
                existing.albums.append(contentsOf: next.albums.filter { !seen.contains($0.id) })
                existing.continuation = next.continuation
                filterCache[.albums] = existing
                musicAlbums = existing.albums
                objectWillChange.send()
            case .songs, .all:
                let combined = Self.orderedByAuthenticity(next.songs + next.videos)
                let seen = Set(originalResults.map(\.id))
                originalResults.append(contentsOf: combined.filter { !seen.contains($0.id) })
                if category == .songs {
                    var cached = filterCache[.songs] ?? MusicSearchResult(songs: originalResults)
                    let cachedSeen = Set(cached.songs.map(\.id))
                    cached.songs.append(contentsOf: next.songs.filter { !cachedSeen.contains($0.id) })
                    cached.continuation = next.continuation
                    filterCache[.songs] = cached
                }
                publishResults(query: query)
            }
        } catch {
            // Al paginar conservamos lo ya cargado.
        }
    }

    func loadArtistCatalog(for artistName: String) async throws -> ArtistCatalog {
        try await source.artistCatalog(for: artistName)
    }

    func loadAlbumTracks(for album: AlbumSummary) async throws -> [Video] {
        try await source.albumTracks(for: album)
    }

    func queryChanged(_ query: String) {
        debounceTask?.cancel()
        requestID = UUID()
        let token = requestID
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        lastQuery = trimmed
        guard trimmed.count >= 2 else { clearResults(); state = .idle; return }
        clearResults()
        state = .loading(query: trimmed)
        debounceTask = Task { [weak self, debounceNanoseconds] in
            do { try await Task.sleep(nanoseconds: debounceNanoseconds) }
            catch { return }
            guard let self, !Task.isCancelled, self.requestID == token else { return }
            await self.perform(query: trimmed, request: token)
        }
    }

    func submit(query: String) async {
        debounceTask?.cancel()
        debounceTask = nil
        let currentRequest = UUID()
        requestID = currentRequest
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        lastQuery = trimmed
        guard !trimmed.isEmpty else { clearResults(); state = .idle; return }
        clearResults()
        state = .loading(query: trimmed)
        await perform(query: trimmed, request: currentRequest)
    }

    private func clearResults() {
        originalResults = []
        musicArtists = []
        musicAlbums = []
        usedMusicCatalog = false
        filterCache = [:]
        continuations = [:]
    }

    private func perform(query: String, request currentRequest: UUID) async {
        do {
            async let baseTask = try? source.musicSearch(query: query, filter: nil, continuation: nil)
            async let songsTask: MusicSearchResult? = categoryFilter == .all
                ? (try? source.musicSearch(query: query, filter: .songs, continuation: nil))
                : nil

            let baseMusic = await baseTask
            let songsMusic = await songsTask
            let music: MusicSearchResult?
            if let baseMusic, !baseMusic.isEmpty {
                music = baseMusic
            } else if let songsMusic, !songsMusic.isEmpty {
                music = songsMusic
            } else {
                music = nil
            }

            if let music {
                guard requestID == currentRequest else { return }
                guard !Task.isCancelled else { state = .idle; return }
                usedMusicCatalog = true
                let combinedSongs = (songsMusic?.songs ?? []) + music.songs + music.videos
                originalResults = Self.orderedByAuthenticity(combinedSongs)
                var artists: [ArtistSummary] = []
                var seenArtists: Set<String> = []
                for artist in ([music.topArtist].compactMap { $0 } + music.artists) {
                    if seenArtists.insert(artist.id).inserted { artists.append(artist) }
                }
                musicArtists = artists
                musicAlbums = music.albums
                if let songsMusic, !songsMusic.songs.isEmpty {
                    filterCache[.songs] = songsMusic
                    continuations[.songs] = songsMusic.continuation
                    continuations[.all] = songsMusic.continuation ?? music.continuation
                } else {
                    continuations[.all] = music.continuation
                }
                if let activeFilter = categoryFilter.musicFilter {
                    await fetchFiltered(query: query, category: categoryFilter, musicFilter: activeFilter, request: currentRequest)
                }
                publishResults(query: query)
                return
            }

            let videos = try await source.search(query: query).prioritizingSongs()
            guard requestID == currentRequest else { return }
            guard !Task.isCancelled else { state = .idle; return }
            usedMusicCatalog = false
            originalResults = videos
            publishResults(query: query)
        } catch {
            guard requestID == currentRequest else { return }
            guard !Task.isCancelled else { state = .idle; return }
            state = .failed(query: query, message: AppError.classify(error).localizedDescription)
        }
    }

    private func fetchFiltered(query: String, category: SearchCategoryFilter, musicFilter: MusicSearchFilter, request currentRequest: UUID) async {
        guard let result = try? await source.musicSearch(query: query, filter: musicFilter, continuation: nil) else { return }
        guard requestID == currentRequest, !Task.isCancelled else { return }
        filterCache[category] = result
        continuations[category] = result.continuation
        if category == .songs, !result.songs.isEmpty {
            publishResults(query: query)
        } else {
            objectWillChange.send()
        }
    }

    private func publishResults(query: String) {
        let sourceVideos: [Video]
        if categoryFilter == .songs, let cachedSongs = filterCache[.songs]?.songs, !cachedSongs.isEmpty {
            sourceVideos = Self.orderedByAuthenticity(cachedSongs)
        } else {
            sourceVideos = (categoryFilter == .songs) ? originalResults.filter { !$0.isLongVideo } : originalResults
        }
        let filtered = sourceVideos.filter(durationFilter.includes)
        let hasCategoryItems = (categoryFilter == .artists && !filteredArtists.isEmpty)
            || (categoryFilter == .albums && !filteredAlbums.isEmpty)
        state = (filtered.isEmpty && !hasCategoryItems) ? .empty(query: query) : .results(query: query, videos: filtered)
    }

    private static func orderedByAuthenticity(_ videos: [Video]) -> [Video] {
        var seen: Set<String> = []
        let unique = videos.filter { seen.insert($0.id).inserted }
        var buckets: [[Video]] = [[], [], [], []]
        for video in unique {
            let tier = TrackAuthenticity.assess(video).tier.rawValue
            buckets[tier].append(video)
        }
        return buckets.flatMap { $0 }
    }
}
