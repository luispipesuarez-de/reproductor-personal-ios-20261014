import AppIntents

@available(iOS 16.0, *)
struct ReproductorAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: PlaySavedArtistIntent(),
                    phrases: [
                        "Reproduce \(\.$artist) en \(.applicationName)",
                        "Reproduce a \(\.$artist) en \(.applicationName)",
                        "Pon \(\.$artist) en \(.applicationName)",
                        "Pon a \(\.$artist) en \(.applicationName)",
                        "Pon música de \(\.$artist) en \(.applicationName)",
                        "Escuchar a \(\.$artist) en \(.applicationName)",
                        "Quiero escuchar a \(\.$artist) en \(.applicationName)"
                    ],
                    shortTitle: "Reproducir artista",
                    systemImageName: "person.wave.2.fill")

        AppShortcut(intent: PlaySongEntityIntent(),
                    phrases: [
                        "Reproduce la canción \(\.$song) en \(.applicationName)",
                        "Pon la canción \(\.$song) en \(.applicationName)",
                        "Reproduce \(\.$song) en \(.applicationName)",
                        "Pon \(\.$song) en \(.applicationName)",
                        "Escuchar \(\.$song) en \(.applicationName)"
                    ],
                    shortTitle: "Reproducir canción",
                    systemImageName: "music.note")

        AppShortcut(intent: PlayArtistIntent(),
                    phrases: [
                        "Reproduce un artista en \(.applicationName)",
                        "Pon un artista en \(.applicationName)",
                        "Buscar artista en \(.applicationName)"
                    ],
                    shortTitle: "Buscar artista",
                    systemImageName: "music.mic")

        AppShortcut(intent: PlaySongIntent(),
                    phrases: [
                        "Busca una canción en \(.applicationName)",
                        "Pon una canción específica en \(.applicationName)"
                    ],
                    shortTitle: "Buscar canción",
                    systemImageName: "music.note.list")

        AppShortcut(intent: PlayFavoritesIntent(),
                    phrases: [
                        "Reproduce mis favoritos en \(.applicationName)",
                        "Pon mis favoritos en \(.applicationName)"
                    ],
                    shortTitle: "Favoritos",
                    systemImageName: "heart.fill")

        AppShortcut(intent: PauseOrResumeIntent(),
                    phrases: [
                        "Pausa o reanuda la música en \(.applicationName)",
                        "Pausa la música en \(.applicationName)",
                        "Reanuda la música en \(.applicationName)"
                    ],
                    shortTitle: "Pausar o reanudar",
                    systemImageName: "playpause.fill")

        AppShortcut(intent: PlayMusicIntent(),
                    phrases: [
                        "Reproduce mi música en \(.applicationName)",
                        "Pon mi música en \(.applicationName)"
                    ],
                    shortTitle: "Mi música",
                    systemImageName: "music.note")
    }
}
