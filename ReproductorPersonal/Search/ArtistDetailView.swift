import SwiftUI

@MainActor
struct ArtistDetailView: View {
    let artistName: String
    var artistID: String? = nil
    let initialVideos: [Video]
    let source: any YouTubeProviding
    @ObservedObject var playback: PlaybackController
    @ObservedObject var library: LibraryStore
    let onPlay: () -> Void

    @State private var catalog: ArtistCatalog?
    @State private var isLoading = true
    @State private var isLoadingAllSongs = false
    @State private var showAllSongs = false
    @State private var errorMessage: String?

    private var artistSeed: RecommendationSeed {
        .artist(
            channelID: catalog?.channelID ?? artistID ?? "",
            name: (catalog?.artistName.isEmpty == false ? catalog?.artistName : nil) ?? artistName,
            radioPlaylistID: catalog?.radioPlaylistID
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                actionButtons
                if let catalog {
                    if catalog.isPartial {
                        partialBanner
                    }
                    if !catalog.albums.isEmpty {
                        releasesSection(title: "Álbumes", releases: catalog.albums)
                    }
                    if !catalog.singles.isEmpty {
                        releasesSection(title: "Singles y EPs", releases: catalog.singles)
                    }
                    songsSection(catalog.songs)
                } else if isLoading {
                    ProgressView("Cargando catálogo de \(artistName)…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                } else if let errorMessage {
                    Text(errorMessage).foregroundStyle(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(artistName)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(artistID ?? "")|\(artistName)") {
            await loadCatalog()
        }
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            let thumb = catalog?.thumbnailURL ?? initialVideos.compactMap(\.thumbnailURL).first
            AsyncImage(url: thumb) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.secondary.opacity(0.2))
                    .overlay(Image(systemName: "music.mic").font(.title).foregroundStyle(.secondary))
            }
            .frame(width: 88, height: 88)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text((catalog?.artistName.isEmpty == false ? catalog?.artistName : nil) ?? artistName)
                    .font(.title2)
                    .fontWeight(.bold)
                if let catalog {
                    let releaseCount = catalog.albums.count + catalog.singles.count
                    Text("\(catalog.songs.count) canciones · \(releaseCount) lanzamientos")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(initialVideos.count) canciones")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                let songs = catalog?.songs ?? initialVideos
                guard !songs.isEmpty else { return }
                onPlay()
                let seed = artistSeed
                Task { await playback.play(songs, startingAt: 0, seed: seed) }
            } label: {
                Label("Reproducir todo", systemImage: "play.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("playArtistAll")

            Button {
                let songs = catalog?.songs ?? initialVideos
                guard !songs.isEmpty else { return }
                onPlay()
                let seed = artistSeed
                Task { await playback.play(songs.shuffled(), startingAt: 0, seed: seed) }
            } label: {
                Label("Aleatorio", systemImage: "shuffle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("shuffleArtistAll")
        }
    }

    private var partialBanner: some View {
        HStack {
            Text("Algunos lanzamientos no se cargaron.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Reintentar") { Task { await loadCatalog() } }
                .font(.footnote.weight(.semibold))
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func releasesSection(title: String, releases: [AlbumSummary]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(releases) { album in
                        NavigationLink {
                            AlbumDetailView(album: album, source: source, playback: playback, library: library, onPlay: onPlay)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                AsyncImage(url: album.thumbnailURL) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Rectangle().fill(Color.secondary.opacity(0.15))
                                        .overlay(Image(systemName: "opticaldisc").foregroundStyle(.secondary))
                                }
                                .frame(width: 130, height: 130)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(album.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: 130, alignment: .leading)
                                if let year = album.year, !year.isEmpty {
                                    Text(year)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("albumCard-\(album.id)")
                    }
                }
            }
        }
    }

    private func songsSection(_ songs: [Video]) -> some View {
        let visible = showAllSongs ? songs : Array(songs.prefix(5))
        let hasMore = !showAllSongs && (songs.count > 5 || catalog?.songsContinuation != nil)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(showAllSongs ? "Canciones" : "Canciones populares")
                    .font(.headline)
                Spacer()
                if hasMore {
                    Button("Ver todas") {
                        showAllSongs = true
                        Task { await loadMoreSongsIfNeeded() }
                    }
                    .font(.subheadline)
                }
            }
            LazyVStack(spacing: 8) {
                ForEach(Array(visible.enumerated()), id: \.offset) { index, video in
                    HStack {
                        Button {
                            onPlay()
                            let seed = artistSeed
                            Task { await playback.play(songs, startingAt: index, seed: seed) }
                        } label: {
                            VideoRow(video: video)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("artistSong-\(video.id)")

                        VideoActionsMenu(video: video, library: library, playback: playback)
                    }
                }
                if showAllSongs && (isLoadingAllSongs || catalog?.songsContinuation != nil) {
                    if isLoadingAllSongs {
                        ProgressView().padding(.vertical, 8)
                    } else {
                        Button("Cargar más canciones") {
                            Task { await loadMoreSongsIfNeeded() }
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
        }
    }

    private func loadCatalog() async {
        isLoading = true
        errorMessage = nil
        do {
            var resolvedID = artistID
            if (resolvedID == nil || resolvedID?.isEmpty == true),
               let search = try? await source.musicSearch(query: artistName, filter: .artists, continuation: nil) {
                let target = Video.normalizedCatalogText(artistName).trimmingCharacters(in: .whitespacesAndNewlines)
                let candidates = [search.topArtist].compactMap { $0 } + search.artists
                resolvedID = candidates.first(where: { $0.normalizedName == target && $0.browseID != nil })?.browseID
                    ?? candidates.first(where: { $0.browseID != nil })?.browseID
            }

            let loaded: ArtistCatalog
            if let resolvedID, !resolvedID.isEmpty,
               let structured = try? await source.artistCatalog(artistID: resolvedID) {
                loaded = ArtistCatalog(
                    artistName: structured.artistName,
                    thumbnailURL: structured.thumbnailURL,
                    songs: CatalogDeduplication.deduplicate(structured.songs),
                    albums: structured.albums,
                    singles: structured.singles,
                    channelID: structured.channelID,
                    radioPlaylistID: structured.radioPlaylistID,
                    allSongsBrowseID: structured.allSongsBrowseID,
                    songsContinuation: structured.songsContinuation,
                    isPartial: structured.isPartial
                )
            } else {
                loaded = try await source.artistCatalog(for: artistName)
            }
            catalog = loaded
            isLoading = false
        } catch {
            isLoading = false
            let songs = initialVideos.prioritizingSongs()
            let albums = initialVideos.groupedAlbums(forArtist: artistName)
            catalog = ArtistCatalog(artistName: artistName, thumbnailURL: songs.first?.thumbnailURL, songs: songs, albums: albums, isPartial: !songs.isEmpty)
        }
    }

    private func loadMoreSongsIfNeeded() async {
        guard var current = catalog, let browseID = current.allSongsBrowseID,
              var token = current.songsContinuation, !isLoadingAllSongs, current.songs.count < 500 else { return }
        isLoadingAllSongs = true
        defer { isLoadingAllSongs = false }
        while current.songs.count < 500 {
            guard let page = try? await source.playlistTracks(browseID: browseID, continuation: token) else { break }
            let combined = CatalogDeduplication.deduplicate(current.songs + page.videos)
            current = ArtistCatalog(
                artistName: current.artistName,
                thumbnailURL: current.thumbnailURL,
                songs: Array(combined.prefix(500)),
                albums: current.albums,
                singles: current.singles,
                channelID: current.channelID,
                radioPlaylistID: current.radioPlaylistID,
                allSongsBrowseID: current.allSongsBrowseID,
                songsContinuation: page.continuation,
                isPartial: current.isPartial
            )
            catalog = current
            guard let nextToken = page.continuation, !page.videos.isEmpty else { break }
            token = nextToken
        }
    }
}

@MainActor
struct AlbumDetailView: View {
    let album: AlbumSummary
    let source: any YouTubeProviding
    @ObservedObject var playback: PlaybackController
    @ObservedObject var library: LibraryStore
    let onPlay: () -> Void

    @State private var tracks: [Video] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                actionButtons
                tracksSection
            }
            .padding()
        }
        .navigationTitle(album.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: album.id) {
            await loadTracks()
        }
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            AsyncImage(url: album.thumbnailURL) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.secondary.opacity(0.15))
                    .overlay(Image(systemName: "opticaldisc").font(.largeTitle).foregroundStyle(.secondary))
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(2)
                Text(album.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                let meta = [album.year, "\(tracks.count) temas"].compactMap { $0 }.joined(separator: " · ")
                Text(meta)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                guard !tracks.isEmpty else { return }
                onPlay()
                Task { await playback.play(tracks, startingAt: 0) }
            } label: {
                Label("Reproducir álbum", systemImage: "play.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("playAlbumAll")

            Button {
                guard !tracks.isEmpty else { return }
                onPlay()
                Task { await playback.play(tracks.shuffled(), startingAt: 0) }
            } label: {
                Label("Mezclar", systemImage: "shuffle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("shuffleAlbumAll")
        }
    }

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading && tracks.isEmpty {
                ProgressView("Cargando pistas…")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(Array(tracks.enumerated()), id: \.offset) { index, video in
                    HStack {
                        Text("\(index + 1)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 24, alignment: .leading)
                        Button {
                            onPlay()
                            Task { await playback.play(tracks, startingAt: index) }
                        } label: {
                            VideoRow(video: video)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("albumTrack-\(video.id)")

                        VideoActionsMenu(video: video, library: library, playback: playback)
                    }
                }
            }
        }
    }

    private func loadTracks() async {
        tracks = album.tracks
        isLoading = true
        if let browseID = album.browseID, !browseID.isEmpty,
           let fetched = try? await source.albumTracks(albumID: browseID), !fetched.isEmpty {
            tracks = fetched
        } else if let fetched = try? await source.albumTracks(for: album), !fetched.isEmpty {
            tracks = fetched
        }
        isLoading = false
    }
}
