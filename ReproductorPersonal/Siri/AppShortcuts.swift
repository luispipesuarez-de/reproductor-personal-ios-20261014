import AppIntents

@available(iOS 16.0, *)
struct ReproductorAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: PlayArtistIntent(),
                    phrases: [
                        "Reproduce un artista en \(.applicationName)",
                        "Pon un artista en \(.applicationName)",
                        "Quiero escuchar un artista en \(.applicationName)"
                    ],
                    shortTitle: "Reproducir artista",
                    systemImageName: "music.mic")
        AppShortcut(intent: PlaySavedArtistIntent(),
                    phrases: [
                        "Reproduce \(\.$artist) en \(.applicationName)",
                        "Escuchar a \(\.$artist) en \(.applicationName)"
                    ],
                    shortTitle: "Artista directo",
                    systemImageName: "person.wave.2.fill")
        AppShortcut(intent: PlaySongIntent(),
                    phrases: [
                        "Busca una canción en \(.applicationName)",
                        "Reproduce una canción en \(.applicationName)",
                        "Pon una canción específica en \(.applicationName)"
                    ],
                    shortTitle: "Buscar canción",
                    systemImageName: "music.note.list")
        AppShortcut(intent: PlayFavoritesIntent(),
                    phrases: ["Reproduce mis favoritos en \(.applicationName)"],
                    shortTitle: "Favoritos",
                    systemImageName: "heart.fill")
        AppShortcut(intent: PauseOrResumeIntent(),
                    phrases: ["Pausa o reanuda la música en \(.applicationName)"],
                    shortTitle: "Pausar o reanudar",
                    systemImageName: "playpause.fill")
        AppShortcut(intent: PlayMusicIntent(),
                    phrases: ["Reproduce mi música en \(.applicationName)"],
                    shortTitle: "Mi música",
                    systemImageName: "music.note")
    }
}
