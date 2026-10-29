import SwiftUI

@MainActor
struct LibraryView: View {
    @ObservedObject var library: LibraryStore
    @ObservedObject var playback: PlaybackController
    @Binding var selectedTab: RootTab
    let onPlay: () -> Void
    @State private var creating = false
    @State private var name = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage { Section { Text(errorMessage) } }
                Section {
                    Button {
                        let videos = library.allMusic.shuffled()
                        onPlay()
                        Task { await playback.play(videos) }
                    } label: { Label("Mezclar mi música", systemImage: "shuffle").frame(minHeight: 44) }
                    .disabled(!hasMusic)
                    .accessibilityIdentifier("shuffleAllMusic")
                    NavigationLink {
                        LibraryVideosView(kind: .favorites, library: library, playback: playback, onPlay: onPlay)
                    } label: { Label("Favoritos", systemImage: "heart") }
                    .accessibilityLabel("Favoritos")
                    .accessibilityValue("\(library.snapshot.favorites.count) elementos")
                    NavigationLink {
                        LibraryVideosView(kind: .recent, library: library, playback: playback, onPlay: onPlay)
                    } label: { Label("Historial", systemImage: "clock") }
                    .accessibilityLabel("Historial")
                    NavigationLink {
                        LibraryArtistsView(library: library, playback: playback, onPlay: onPlay)
                    } label: { Label("Artistas", systemImage: "music.mic") }
                    .accessibilityLabel("Artistas")
                    .accessibilityIdentifier("openLibraryArtists")
                }
                Section("Listas") {
                    if library.snapshot.playlists.isEmpty {
                        Text("Crea una lista con el botón +. Después añade contenido desde Buscar.").foregroundStyle(.secondary)
                    }
                    ForEach(library.snapshot.playlists) { playlist in
                        NavigationLink {
                            PlaylistView(playlistID: playlist.id, library: library, playback: playback, onPlay: onPlay)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(playlist.name)
                                Text(playlist.videos.count == 1 ? "1 elemento" : "\(playlist.videos.count) elementos").font(.caption).foregroundStyle(.secondary)
                            }.padding(.vertical, 4)
                        }
                        .accessibilityLabel(playlist.name)
                    }
                }
            }
            .navigationTitle("Biblioteca")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Buscar") { selectedTab = .search }
                        .accessibilityIdentifier("openSearchTab")
                    Button("Biblioteca") { selectedTab = .library }
                        .disabled(selectedTab == .library)
                        .accessibilityIdentifier("openLibraryTab")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: { Image(systemName: "plus").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("Crear lista")
                        .accessibilityIdentifier("createPlaylist")
                }
            }
            .alert("Nueva lista", isPresented: $creating) {
                TextField("Nombre de la lista", text: $name).accessibilityIdentifier("playlistNameField")
                Button("Cancelar", role: .cancel) {}
                Button("Crear") {
                    do { _ = try library.createPlaylist(name: name); name = ""; errorMessage = nil }
                    catch { errorMessage = error.localizedDescription }
                }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var hasMusic: Bool {
        !library.snapshot.favorites.isEmpty || !library.snapshot.recent.isEmpty
            || library.snapshot.playlists.contains { !$0.videos.isEmpty }
    }
}

@MainActor
private struct LibraryVideosView: View {
    enum Kind { case favorites, recent }
    let kind: Kind
    @ObservedObject var library: LibraryStore
    @ObservedObject var playback: PlaybackController
    let onPlay: () -> Void

    private var videos: [Video] { kind == .favorites ? library.snapshot.favorites : library.snapshot.recent }

    var body: some View {
        List {
            if kind == .favorites, !videos.isEmpty {
                Button {
                    let shuffled = videos.shuffled()
                    onPlay()
                    Task { await playback.play(shuffled) }
                } label: { Label("Mezclar favoritos", systemImage: "shuffle").frame(minHeight: 44) }
            }
            if videos.isEmpty {
                Text(kind == .favorites ? "Guarda videos desde el menú de opciones de un resultado o de Ahora suena." : "Aquí aparecerá el contenido cuando empiece a reproducirse.")
                    .foregroundStyle(.secondary)
            }
            ForEach(videos) { video in
                HStack {
                    Button {
                        onPlay()
                        Task { await playback.play(video) }
                    } label: { VideoRow(video: video) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("\(kind == .favorites ? "favorite" : "recent")-\(video.id)")
                    VideoActionsMenu(video: video, library: library, playback: playback)
                }
            }
        }
        .accessibilityIdentifier(kind == .favorites ? "favoritesList" : "recentList")
        .navigationTitle(kind == .favorites ? "Favoritos" : "Historial")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@MainActor
private struct LibraryArtistsView: View {
    @ObservedObject var library: LibraryStore
    @ObservedObject var playback: PlaybackController
    let onPlay: () -> Void

    private var artists: [ArtistSummary] {
        library.allMusic.groupedArtists()
    }

    var body: some View {
        List {
            if artists.isEmpty {
                Text("Aquí aparecerán los artistas según la música que guardes en favoritos, listas o historial.")
                    .foregroundStyle(.secondary)
            }
            ForEach(artists) { artist in
                NavigationLink {
                    ArtistDetailView(
                        artistName: artist.name,
                        initialVideos: artist.sampleVideos,
                        source: playback.source,
                        playback: playback,
                        library: library,
                        onPlay: onPlay
                    )
                } label: {
                    HStack(spacing: 12) {
                        AsyncImage(url: artist.thumbnailURL) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color.secondary.opacity(0.2))
                                .overlay(Image(systemName: "music.mic").foregroundStyle(.secondary))
                        }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(artist.name).font(.headline)
                            Text("\(artist.sampleVideos.count) canciones guardadas")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier("libraryArtist-\(artist.id)")
            }
        }
        .accessibilityIdentifier("libraryArtistsList")
        .navigationTitle("Artistas")
        .navigationBarTitleDisplayMode(.inline)
    }
}
