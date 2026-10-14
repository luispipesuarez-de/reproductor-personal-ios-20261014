import SwiftUI

@MainActor
struct SearchView: View {
    @ObservedObject var search: SearchViewModel
    @ObservedObject var playback: PlaybackController
    @State private var query = ""
    @State private var showPlayer = false
    @State private var showLicense = false
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    TextField("Videos, canciones o artistas", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .focused($fieldFocused)
                        .onSubmit(submit)
                        .accessibilityLabel("Buscar videos y música")
                        .accessibilityIdentifier("searchField")
                    Button("Buscar", action: submit)
                        .frame(minHeight: 44)
                        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("searchSubmit")
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                content
            }
            .navigationTitle("Reproductor")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showLicense = true } label: { Image(systemName: "info.circle") }
                        .accessibilityLabel("Licencia de YouTubeKit")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let video = playback.state.video {
                    HStack(spacing: 16) {
                        Button { showPlayer = true } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(video.title).font(.headline).lineLimit(2)
                                Text(playbackCaption).font(.caption).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Abre el video y sus controles")
                        playbackButton
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.regularMaterial)
                    .accessibilityIdentifier("miniPlayer")
                }
            }
            .sheet(isPresented: $showPlayer) { playerSheet }
            .sheet(isPresented: $showLicense) { licenseSheet }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch search.state {
        case .idle:
            message(title: "Busca algo para escuchar", detail: "Escribe el título de un video, una canción o un artista.", symbol: "magnifyingglass")
        case .loading(let query):
            List {
                Text("Buscando «\(query)»…").foregroundStyle(.secondary)
                ForEach(0..<3) { _ in
                    VideoRow(video: Video(id: "", title: "Buscando contenido", author: "Autor"))
                        .redacted(reason: .placeholder)
                        .accessibilityHidden(true)
                }
            }.listStyle(.plain)
        case .results(_, let videos):
            List {
                ForEach(Array(videos.enumerated()), id: \.offset) { _, video in
                    Button {
                        fieldFocused = false
                        showPlayer = true
                        Task { await playback.play(video) }
                    } label: { VideoRow(video: video) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("result-\(video.id)")
                    .accessibilityHint("Reproduce este contenido")
                }
            }.listStyle(.plain)
        case .empty(let query):
            message(title: "No encontramos resultados", detail: "Prueba otro título o artista en lugar de «\(query)».", symbol: "magnifyingglass")
        case .failed(let query, let error):
            VStack(spacing: 16) {
                message(title: "No se pudo buscar", detail: error, symbol: "wifi.exclamationmark")
                Button("Reintentar") { Task { await search.submit(query: query) } }
                    .buttonStyle(.borderedProminent)
                    .frame(minHeight: 44)
                Spacer()
            }
        }
    }

    private func submit() {
        fieldFocused = false
        let submittedQuery = query
        Task { await search.submit(query: submittedQuery) }
    }

    private func message(title: String, detail: String, symbol: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol).font(.largeTitle).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(title).font(.title2).fontWeight(.semibold)
            Text(detail).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var playbackCaption: String {
        switch playback.state {
        case .loading: return "Preparando…"
        case .playing: return "Reproduciendo"
        case .paused: return "Pausado"
        case .failed: return "No se pudo reproducir"
        case .idle: return ""
        }
    }

    @ViewBuilder
    private var playbackButton: some View {
        if case .failed(let video, _) = playback.state {
            Button {
                if let video { Task { await playback.play(video) } }
            } label: { Image(systemName: "arrow.clockwise").font(.title2).frame(width: 44, height: 44) }
                .accessibilityLabel("Reintentar reproducción")
        } else {
            let canPause: Bool = {
                if case .loading = playback.state { return true }
                return playback.state.isPlaying
            }()
            Button {
                if canPause { playback.pause() }
                else { Task { await playback.resume() } }
            } label: { Image(systemName: canPause ? "pause.fill" : "play.fill").font(.title2).frame(width: 44, height: 44) }
                .accessibilityLabel(canPause ? "Pausar" : "Reanudar")
        }
    }

    private var playerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PlayerView(player: playback.player).aspectRatio(16 / 9, contentMode: .fit)
                        .background(Color.black)
                    if let video = playback.state.video {
                        Text(video.title).font(.title2).fontWeight(.semibold)
                        Text(video.author).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 16) {
                        playbackButton
                        Text(playbackCaption)
                        if case .loading = playback.state { ProgressView().accessibilityLabel("Preparando contenido") }
                    }
                    if case .failed(_, let message) = playback.state {
                        Text(message).foregroundStyle(.secondary).accessibilityIdentifier("playbackError")
                    }
                }.padding()
            }
            .navigationTitle("Ahora suena")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { showPlayer = false } }
            }
        }
    }

    private var licenseSheet: some View {
        NavigationStack {
            ScrollView {
                Text(licenseText).font(.footnote).textSelection(.enabled).padding()
            }
            .navigationTitle("YouTubeKit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Cerrar") { showLicense = false } }
            }
        }
    }

    private var licenseText: String {
        guard let url = Bundle.main.url(forResource: "YouTubeKit-LICENSE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "YouTubeKit — Antoine Bollengier. Licencia MIT. https://github.com/b5i/YouTubeKit"
        }
        return text
    }
}

private struct VideoRow: View {
    let video: Video
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !typeSize.isAccessibilitySize {
                AsyncImage(url: video.thumbnailURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.secondary.opacity(0.12)).overlay(Image(systemName: "play.rectangle").foregroundStyle(.secondary))
                }
                .frame(width: 108, height: 61)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(video.title).font(.headline).foregroundStyle(.primary).lineLimit(typeSize.isAccessibilitySize ? nil : 3)
                Text(video.author).font(.subheadline).foregroundStyle(.secondary)
                if let duration = video.durationText { Text(duration).font(.caption).foregroundStyle(.secondary) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}
