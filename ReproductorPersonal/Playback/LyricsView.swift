import SwiftUI

@MainActor
struct LyricsView: View {
    let video: Video
    @ObservedObject var playback: PlaybackController
    @State private var lyricsData: LyricsData?
    @State private var isLoading = true
    @State private var currentLineIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Buscando letra…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let lyrics = lyricsData {
                if lyrics.isSynced {
                    syncedLyricsView(lyrics.syncedLines)
                } else if !lyrics.plainLyrics.isEmpty {
                    plainLyricsView(lyrics.plainLyrics)
                } else {
                    noLyricsView
                }
            } else {
                noLyricsView
            }
        }
        .task(id: video.id) {
            await loadLyrics()
        }
        .onChange(of: playback.elapsed) { elapsed in
            if let lyrics = lyricsData, lyrics.isSynced {
                currentLineIndex = lyrics.activeLineIndex(for: elapsed)
            }
        }
    }

    private func syncedLyricsView(_ lines: [LyricsLine]) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        let isActive = currentLineIndex == index
                        Text(line.text.isEmpty ? "♪" : line.text)
                            .font(isActive ? .title2 : .title3)
                            .fontWeight(isActive ? .bold : .medium)
                            .foregroundStyle(isActive ? Color.primary : Color.secondary.opacity(0.6))
                            .scaleEffect(isActive ? 1.05 : 1.0, anchor: .leading)
                            .animation(.spring(response: 0.3), value: isActive)
                            .id(index)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                playback.seek(to: line.timestamp)
                            }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
            }
            .onChange(of: currentLineIndex) { newIndex in
                if let newIndex {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }

    private func plainLyricsView(_ plain: String) -> some View {
        ScrollView {
            Text(plain)
                .font(.body)
                .lineSpacing(8)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
    }

    private var noLyricsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "quote.bubble")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Letra no disponible")
                .font(.headline)
            Text("No encontramos la letra para esta canción.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func loadLyrics() async {
        isLoading = true
        let data = await LyricsService.shared.fetchLyrics(for: video, duration: playback.duration)
        lyricsData = data
        isLoading = false
    }
}
