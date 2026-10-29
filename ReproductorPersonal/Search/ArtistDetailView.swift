import SwiftUI

@MainActor
struct ArtistDetailView: View {
    let artistName: String
    let initialVideos: [Video]
    let source: any YouTubeProviding
    @ObservedObject var playback: PlaybackController
    @ObservedObject var library: LibraryStore
    let onPlay: () -> Void

    @State private var catalog: ArtistCatalog?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                actionButtons
                if let catalog {
                    if !catalog.albums.isEmpty {
                        albumsSection(catalog.albums)
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
        .task(id: artistName) {
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
                Text(artistName)
                    .font(.title2)
                    .fontWeight(.bold)
                if let catalog {
                    Text("\(catalog.songs.count) canciones · \(catalog.albums.count) álbumes")
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
                Task { await playback.play(songs, startingAt: 0) }
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
                Task { await playback.play(songs.shuffled(), startingAt: 0) }
            } label: {
                Label("Aleatorio", systemImage: "shuffle")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("shuffleArtistAll")
        }
    }

    private func albumsSection(_ albums: [AlbumSummary]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Álbumes")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(albums) { album in
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Canciones")
                .font(.headline)
            LazyVStack(spacing: 8) {
                ForEach(Array(songs.enumerated()), id: \.offset) { index, video in
                    HStack {
                        Button {
                            onPlay()
                            Task { await playback.play(songs, startingAt: index) }
                        } label: {
                            VideoRow(video: video)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("artistSong-\(video.id)")

                        VideoActionsMenu(video: video, library: library, playback: playback)
                    }
                }
            }
        }
    }

    private func loadCatalog() async {
        isLoading = true
        errorMessage = nil
        do {
            let cat = try await source.artistCatalog(for: artistName)
            catalog = cat
            isLoading = false
        } catch {
            isLoading = false
            let songs = initialVideos.prioritizingSongs()
            let albums = initialVideos.groupedAlbums(forArtist: artistName)
            catalog = ArtistCatalog(artistName: artistName, thumbnailURL: songs.first?.thumbnailURL, songs: songs, albums: albums)
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
                Text("\(tracks.count) temas")
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
        if let fetched = try? await source.albumTracks(for: album), !fetched.isEmpty {
            tracks = fetched
        }
        isLoading = false
    }
}
