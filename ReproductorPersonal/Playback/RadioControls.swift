import SwiftUI

@MainActor
enum CatalogSettings {
    static let officialOnlyKey = "officialOnlyAutoplay"

    static var officialOnlyAutoplay: Bool {
        UserDefaults.standard.object(forKey: officialOnlyKey) as? Bool ?? true
    }

    static func policy(
        officialOnly: Bool,
        blockedChannelIDs: @escaping () -> Set<String> = { [] },
        blockedArtistNames: @escaping () -> Set<String> = { [] }
    ) -> CandidatePolicy {
        CandidatePolicy.officialFirst(
            allowUnknownFallback: { !officialOnly },
            blockedChannelIDs: blockedChannelIDs,
            blockedArtistNames: blockedArtistNames
        )
    }

    static func livePolicy(
        blockedChannelIDs: @escaping () -> Set<String> = { [] },
        blockedArtistNames: @escaping () -> Set<String> = { [] }
    ) -> CandidatePolicy {
        CandidatePolicy.officialFirst(
            allowUnknownFallback: { !officialOnlyAutoplay },
            blockedChannelIDs: blockedChannelIDs,
            blockedArtistNames: blockedArtistNames
        )
    }
}

@MainActor
struct RadioControls: View {
    @ObservedObject var playback: PlaybackController
    @AppStorage(CatalogSettings.officialOnlyKey) private var officialOnlyAutoplay = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let seed = playback.radioSeed {
                switch seed {
                case .genre(let genre): Text("Radio \(genre)").font(.headline)
                case .video, .track: Text("Radio desde una canción").font(.headline)
                case .artist(_, let name, _): Text("Radio de \(name)").font(.headline)
                }
            }
            Toggle("Continuar automáticamente", isOn: Binding(get: { playback.autoplayEnabled }, set: playback.setAutoplayEnabled))
                .frame(minHeight: 44)
                .accessibilityIdentifier("autoplayToggle")
            if playback.autoplayEnabled {
                Toggle("Solo grabaciones oficiales", isOn: $officialOnlyAutoplay)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("officialOnlyAutoplayToggle")
                switch playback.radioStatus {
                case .loading: ProgressView("Buscando más canciones…")
                case .failed(let message):
                    Text(message).foregroundStyle(.secondary)
                    retry
                case .exhausted:
                    if playback.queue.upcomingCount == 0 {
                        Text("No hay más sugerencias por ahora.").foregroundStyle(.secondary)
                        retry
                    }
                case .idle: EmptyView()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private var retry: some View {
        Button("Reintentar radio") { Task { await playback.retryRadio() } }.frame(minHeight: 44)
    }
}
