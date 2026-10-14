# Reproductor personal para iPhone — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Crear una app personal para iPhone con búsqueda interna de YouTube, reproducción de video y audio en segundo plano, cola y biblioteca local, y comprobar su funcionamiento en el teléfono.

**Architecture:** SwiftUI consume un módulo de acceso a YouTube, un controlador de reproducción con un único AVQueuePlayer y un almacén local de biblioteca. Las búsquedas y la extracción se realizan en el iPhone; un ejecutor macOS de GitHub Actions se usa únicamente para compilar, probar en simulador y generar el IPA. La integración con la cuenta de YouTube es una etapa posterior.

**Tech Stack:** Swift en modo de lenguaje 5, SwiftUI, AVFoundation, MediaPlayer, Foundation/Codable, XCTest, XcodeGen, GitHub Actions y AltStore Classic.

**Spec:** `docs/superpowers/specs/2026-10-14-reproductor-personal-ios-design.md`.

## Global Constraints

- «iOS 16 como versión mínima de la primera implementación.» Comprobar la versión real del iPhone antes de instalar.
- «El código y la documentación se editarán desde Windows.» Xcode y las pruebas de iOS se ejecutan en macOS; no anunciar compilación comprobada solo por inspeccionar archivos en Windows.
- «Pegar enlaces no es el flujo principal ni un requisito para escuchar música.» La app abre en Buscar y reproduce resultados seleccionados dentro de ella.
- «La primera etapa se limita a contenido público que pueda reproducirse sin autenticación.» La cuenta, suscripciones y listas de YouTube quedan para la segunda etapa.
- «Tampoco se activará un servicio remoto de extracción como sustituto de la resolución local.» La app consulta directamente YouTube y sus servidores de contenido.
- «La reproducción usará un único AVQueuePlayer». Su vida útil pertenece a la app, no a una vista de reproducción.
- «La biblioteca se almacenará mediante archivos JSON con Codable en el directorio privado de datos de la app. Las escrituras serán atómicas y se ejecutarán de forma ordenada.»
- «La biblioteca guarda referencias y metadatos, no archivos descargados de YouTube ni URLs temporales de reproducción.»
- «texto en español, compatibilidad con tamaños de letra del sistema y etiquetas accesibles para los controles.»
- «Con una cuenta gratuita de Apple, la instalación requiere renovación cada siete días». Documentar instalación, actualización y renovación con AltStore Classic.
- No publicar credenciales de Apple ni sesiones de YouTube en código, documentación, logs o GitHub. La primera compilación produce un IPA sin firmar.
- Fijar YouTubeKit inicialmente a la revisión `6532af39da4c1612b0a1af603792419d8fb0e67f`. Una actualización exige repetir el hito técnico; no depender de una rama que cambie automáticamente.

## Review Focus

1. Búsquedas que terminan fuera de orden: una respuesta antigua no sustituye resultados de una consulta nueva. Prueba en Task 2: `testOldSearchCannotReplaceNewResults`.
2. Resultados encontrados sin un flujo reproducible: mostrar contenido no disponible y mantener la app operable. Prueba en Task 1: `testMissingPlayableStreamReturnsUnavailable` y en Task 2: `testResolutionFailureDoesNotAnnouncePlaying`.
3. URL que caduca durante la escucha: resolver otra vez como máximo una vez por elemento y recuperar el progreso. Prueba en Task 3: `testExpiredResourceIsResolvedOnlyOnceAgain`.
4. La misma canción aparece dos veces en una cola: ambas posiciones tienen identidad propia y se pueden quitar de forma independiente. Prueba en Task 3: `testRepeatedVideoKeepsIndependentQueueEntries`.
5. Biblioteca dañada, versión desconocida o escritura fallida: conservar los bytes previos y no anunciar un guardado inexistente. Pruebas en Task 4: `testInvalidLibraryIsNotOverwritten` y `testFailedWriteKeepsPreviousSnapshot`.

---

## Estructura y convenciones

| Ruta | Responsabilidad |
| --- | --- |
| `project.yml` | Proyecto XcodeGen, targets de app/pruebas, esquema y revisión fija del paquete. |
| `.github/workflows/ios.yml` | Ejecución manual de pruebas y generación del IPA. |
| `scripts/ci.sh` | Generar proyecto, elegir simulador disponible, probar y empaquetar. |
| `ReproductorPersonal/App/` | Entrada, composición y navegación entre Buscar y Biblioteca. |
| `ReproductorPersonal/YouTube/` | Modelo Video, contrato del proveedor, mapeo y cliente YouTubeKit. |
| `ReproductorPersonal/Search/` | Estado de consultas y vista de resultados. |
| `ReproductorPersonal/Playback/` | Reproductor, cola, sesión de audio, comandos del sistema y sus vistas. |
| `ReproductorPersonal/Library/` | Modelos persistentes, guardado atómico y pantallas de biblioteca. |
| `ReproductorPersonal/Support/AppError.swift` | Errores comprensibles y sus mensajes en español. |
| `ReproductorPersonalTests/` | Pruebas de comportamiento con datos controlados y sin YouTube en vivo. |
| `ReproductorPersonalUITests/` | Pruebas del flujo Buscar, reproducción y Biblioteca. |
| `docs/instalacion-iphone.md` | Pasos de GitHub, AltStore, instalación y renovación. |
| `docs/verificacion-iphone.md` | Resultados reales del dispositivo y limitaciones observadas. |

Proyecto, esquema y target principal: `ReproductorPersonal`. Targets de pruebas: `ReproductorPersonalTests` y `ReproductorPersonalUITests`. Nombre visible: `Reproductor`. Identificador inicial: `personal.reproductor.ios`; AltStore gestiona la firma personal.

XcodeGen genera `ReproductorPersonal.xcodeproj` a partir de `project.yml`; el proyecto generado y `build/` se excluyen de Git. El script acepta dos comandos: `bash scripts/ci.sh test` y `bash scripts/ci.sh ipa`.

Para ejecutar CI desde Windows, crear y subir commits de trabajo en la rama de desarrollo antes de lanzar el workflow. Los pasos Commit al final de las tareas registran su cierre y las evidencias, sin exigir un commit vacío cuando el código ya esté guardado. Los tests fallidos deliberadamente pertenecen a esa rama de desarrollo, no a una entrega verificada.

Los tests usan dos videos sintéticos: `videoA`, id `aaaaaaaaaaa`, título `Canción A`, autor `Autor A`; y `videoB`, id `bbbbbbbbbbb`, título `Video B`, autor `Autor B`. Las URLs del mapeo pertenecen a `media.example.test`; las pruebas del reproductor nativo utilizan un archivo WAV local de prueba. Ninguno de estos datos demuestra reproducción real de YouTube.

## Task 1: Acceso tipado a YouTube con una compilación comprobable

**Files:**
- Create: `.gitignore`, `project.yml`, `.github/workflows/ios.yml`, `scripts/ci.sh`.
- Create: `ReproductorPersonal/App/ReproductorPersonalApp.swift`.
- Create: `ReproductorPersonal/YouTube/Video.swift`, `ReproductorPersonal/YouTube/YouTubeProviding.swift`, `ReproductorPersonal/YouTube/YouTubeClient.swift`, `ReproductorPersonal/YouTube/YouTubeMapping.swift`.
- Create: `ReproductorPersonal/Support/AppError.swift`.
- Test: `ReproductorPersonalTests/YouTubeMappingTests.swift`.
- Test fixtures: `ReproductorPersonalTests/Fixtures/search-mixed.json`, `ReproductorPersonalTests/Fixtures/stream-unavailable.json`.

**Interfaces:**
- Consumes: la especificación y la revisión fijada de b5i/YouTubeKit; no hay código de producto previo.
- Produces: `Video: Identifiable, Codable, Equatable, Sendable`, con `id: String`, `title: String`, `author: String`, `thumbnailURL: URL?`, `durationText: String?`.
- Produces: `PlaybackResource: Equatable, Sendable`, con `url: URL` y `expiresAt: Date?`.
- Produces: `protocol YouTubeProviding: Sendable` con `func search(query: String) async throws -> [Video]` y `func resolve(videoID: String) async throws -> PlaybackResource`.
- Produces: `actor YouTubeClient: YouTubeProviding` y `YouTubeMapping.videos(from response: SearchResponse) -> [Video]`.
- Produces: `YouTubeMapping.resource(hlsURL: URL?, combinedURLs: [URL], expiresAt: Date?) throws -> PlaybackResource`; el cliente filtra los candidatos combinados por pistas y compatibilidad nativa antes de llamar al mapeo.
- Produces: `AppError: Error, LocalizedError, Equatable`, casos `offline`, `unavailable`, `resolutionFailed`, `storageFailed`, `invalidPlaylistName`, `libraryIncompatible`.

- [ ] **Step 0: Crear la configuración mínima de pruebas.** Preparar el target de app con una entrada SwiftUI mínima, el target XCTest, el paquete fijado, el esquema y un workflow manual que ejecute `bash scripts/ci.sh test`. Esto permite correr RED desde Windows mediante el ejecutor macOS antes de escribir el comportamiento del cliente. `xcodegen generate --spec project.yml` debe generar el proyecto sin errores de configuración.
- [ ] **Step 1: Escribir pruebas fallidas de mapeo y selección de flujo.** `search-mixed.json` contiene un video, un canal, un anuncio y un resultado sin identificador; solo el video se mapea. Dar prioridad a HLS HTTPS; aceptar un flujo combinado HTTPS nativo cuando HLS falte; rechazar una página `/watch`, datos vacíos o un esquema distinto de HTTPS. Afirmaciones obligatorias:

```swift
// testSearchMapsOnlyVideos
XCTAssertEqual(mapped.map(\.id), ["aaaaaaaaaaa"])
// testHLSIsPreferredOverCombinedStream
XCTAssertEqual(resource.url, hlsURL)
// testMissingPlayableStreamReturnsUnavailable
XCTAssertThrowsError(try YouTubeMapping.resource(
    hlsURL: nil, combinedURLs: [], expiresAt: nil
)) { XCTAssertEqual($0 as? AppError, .unavailable) }
```

- [ ] **Step 2: Ejecutar las pruebas y confirmar RED.** En macOS ejecutar `bash scripts/ci.sh test`; debe fallar por los tipos o funciones de mapeo que aún faltan, no por una configuración rota.
- [ ] **Step 3: Implementar las interfaces y el cliente mínimo.** Buscar con SearchResponse y mapear resultados de tipo video. Resolver en el teléfono, obtener HLS o formatos combinados nativos con URLs ya descifradas; no entregar una URL SABR o solo metadatos como si AVPlayer pudiera reproducirlos. No inventar claves ni añadir extracción remota. Mapear los errores de red y de contenido a AppError.

Mensajes de `AppError.errorDescription`: `offline` → «Necesitas conexión a Internet. Intenta de nuevo.»; `unavailable` → «Este contenido no está disponible en esta versión.»; `resolutionFailed` → «No se pudo preparar este contenido. Intenta de nuevo.»; `storageFailed` → «No se pudieron guardar los cambios. Intenta de nuevo.»; `invalidPlaylistName` → «Escribe un nombre para la lista.»; `libraryIncompatible` → «No se pudo abrir tu biblioteca. Tus datos no se han modificado.»

- [ ] **Step 4: Completar el camino de compilación.** El workflow usa `workflow_dispatch`, `runs-on: macos-latest`, `actions/checkout@v6` y `actions/upload-artifact@v7`. Instala XcodeGen, imprime las versiones de Xcode/XcodeGen y ejecuta el script. Para tests, elegir el primer iPhone disponible de `xcrun simctl list devices available --json` y pasar su UDID a `xcodebuild test`; fallar expresamente si no existe. Para IPA, compilar Release para `generic/platform=iOS`, con firma desactivada, copiar el `.app` a `build/Payload/`, comprimir `build/ReproductorPersonal.ipa` y comprobar que contiene `Payload/ReproductorPersonal.app/Info.plist` y su ejecutable. Publicar resultados `.xcresult` e IPA como artefactos de la ejecución.
- [ ] **Step 5: Confirmar GREEN en macOS y registrar evidencias.** `bash scripts/ci.sh test` devuelve 0 y los tests de mapeo pasan; `bash scripts/ci.sh ipa` devuelve 0 y genera el paquete comprobado. Las lecturas o validaciones de YAML desde Windows no sustituyen estos resultados. Preparar un repositorio privado o usar el repositorio indicado por el usuario al ejecutar, sin solicitar tokens en el chat.
- [ ] **Step 6: Commit.** Incluir configuración, cliente, modelos, fixtures y tests; mensaje `feat: add local YouTube access and iOS build`.

## Task 2: Prototipo con búsqueda interna, video y audio al bloquear

**Files:**
- Create: `ReproductorPersonal/Search/SearchViewModel.swift`, `ReproductorPersonal/Search/SearchView.swift`.
- Create: `ReproductorPersonal/Playback/PlaybackController.swift`, `ReproductorPersonal/Playback/AudioSessionController.swift`, `ReproductorPersonal/Playback/PlayerView.swift`.
- Modify: `ReproductorPersonal/App/ReproductorPersonalApp.swift`, `project.yml`.
- Create: `docs/instalacion-iphone.md`.
- Test: `ReproductorPersonalTests/SearchViewModelTests.swift`, `ReproductorPersonalTests/PlaybackControllerTests.swift`.
- Test support: `ReproductorPersonalTests/Support/StubYouTubeProvider.swift`, `ReproductorPersonalTests/Support/TestAudioAsset.swift`.

**Interfaces:**
- Consumes: Video, PlaybackResource, AppError y YouTubeProviding de Task 1.
- Produces: `SearchState: Equatable`, casos `idle`, `loading(query: String)`, `results(query: String, videos: [Video])`, `empty(query: String)`, `failed(query: String, message: String)`.
- Produces: `@MainActor SearchViewModel: ObservableObject`, `init(source: any YouTubeProviding)`, `private(set) var state: SearchState` y `func submit(query: String) async`.
- Produces: `PlaybackState: Equatable`, casos `idle`, `loading(Video)`, `playing(Video)`, `paused(Video)`, `failed(video: Video?, message: String)`.
- Produces: `@MainActor PlaybackController: ObservableObject`, `init(source: any YouTubeProviding, player: AVQueuePlayer = AVQueuePlayer())`, `player: AVQueuePlayer`, `private(set) var state: PlaybackState`, `func play(_ video: Video) async`, `func pause()` y `func resume() async`.
- Produces: `AudioSessionController.configure() throws` y `PlayerView(player: AVQueuePlayer)`.
- Test support: `TestAudioAsset.makeSilenceFile(duration: TimeInterval = 60) throws -> URL` genera un WAV PCM local, que permite observar AVQueuePlayer sin peticiones de red; cada prueba elimina su propio archivo al terminar. El stub puede devolver ese recurso local y las pruebas esperan estados nativos con un plazo acotado.

- [ ] **Step 1: Escribir pruebas fallidas con un proveedor controlado.** El stub implementa las dos funciones de YouTubeProviding mediante closures asíncronas; para la prueba de orden, completar la consulta nueva antes que la vieja. Probar texto vacío sin petición, consulta recortada, resultados vacíos, error de resolución y dos selecciones que terminan fuera de orden. Afirmaciones:

```swift
// testOldSearchCannotReplaceNewResults
XCTAssertEqual(search.state, .results(query: "nueva", videos: [videoB]))
// testEmptyQueryMakesNoNetworkRequest
XCTAssertEqual(requestedQueries, [])
// testResolutionFailureDoesNotAnnouncePlaying
XCTAssertEqual(player.state, .failed(
    video: videoA, message: AppError.unavailable.localizedDescription
))
// testOldResolutionCannotReplaceNewSelection
XCTAssertEqual(selectedVideoID, "bbbbbbbbbbb")
```

- [ ] **Step 2: Confirmar RED.** Ejecutar `bash scripts/ci.sh test`; fallan los tests nuevos porque faltan los estados y el control de solicitudes vigentes.
- [ ] **Step 3: Implementar el flujo mínimo.** SearchView abre con el campo visible, envía al pulsar Buscar, muestra resultados con miniatura/metadatos y toca para reproducir. Usar tokens de solicitud o cancelación con comprobación de vigencia tanto en búsqueda como en preparación de reproducción. Mantener el controlador en la raíz de la app. Configurar AVAudioSession para `.playback`, declarar `UIBackgroundModes: [audio]` y permitir continuación audiovisual en segundo plano cuando corresponda. Publicar `playing` solo cuando el reproductor tenga evidencia de reproducción; publicar error cuando falle la preparación o el recurso.
- [ ] **Step 4: Verificar GREEN y generar el IPA del prototipo.** Ejecutar los dos comandos de CI, instalar con AltStore Classic y completar en el iPhone: búsqueda por texto, un video público con video/audio, una canción y bloqueo de pantalla. Anotar contenido probado, versión de iOS y resultado real. El IPA Release utiliza el proveedor real, no el stub.
- [ ] **Step 5: Aplicar el hito técnico de la especificación.** Si la extracción o el segundo plano fallan, investigar aquí y repetir la prueba; no ampliar la biblioteca hasta resolverlo. Si no se obtiene reproducción local estable, presentar la evidencia y revisar el diseño con el usuario antes de cambiar de vía. La instalación inicial la realiza el usuario en su teléfono con la guía y el IPA proporcionados.
- [ ] **Step 6: Commit.** Guardar prototipo, pruebas y guía; mensaje `feat: add in-app search and background playback prototype`.

## Task 3: Cola, controles del sistema y recuperación limitada

**Files:**
- Create: `ReproductorPersonal/Playback/PlaybackQueue.swift`, `ReproductorPersonal/Playback/QueueSnapshot.swift`, `ReproductorPersonal/Playback/SystemMediaControls.swift`.
- Modify: `ReproductorPersonal/Playback/PlaybackController.swift`, `ReproductorPersonal/Playback/AudioSessionController.swift`, `ReproductorPersonal/Playback/PlayerView.swift`.
- Test: `ReproductorPersonalTests/PlaybackQueueTests.swift`, `ReproductorPersonalTests/PlaybackRecoveryTests.swift`, `ReproductorPersonalTests/AudioInterruptionTests.swift`.

**Interfaces:**
- Consumes: cliente, estados y controlador de Task 2.
- Produces: `QueueEntry: Identifiable, Codable, Equatable`, con `id: UUID` y `video: Video`.
- Produces: `QueueSnapshot: Codable, Equatable`, con `entries: [QueueEntry]`, `currentIndex: Int?`, `progressSeconds: Double`.
- Produces: `PlaybackQueue`, `init(entries: [QueueEntry] = [], currentIndex: Int? = nil)`, `private(set) var entries: [QueueEntry]`, `private(set) var currentIndex: Int?`, `current: QueueEntry?`, `mutating func append(_ video: Video)`, `mutating func remove(id: UUID)`, `mutating func next() -> QueueEntry?`, `mutating func previous() -> QueueEntry?`.
- Extends PlaybackController: `func play(_ videos: [Video], startingAt index: Int = 0) async`, `func enqueue(_ video: Video)`, `func removeQueueEntry(id: UUID) async`, `func next() async`, `func previous() async`, `func seek(to seconds: Double)`, `func snapshot() -> QueueSnapshot`, `func restore(_ snapshot: QueueSnapshot)`.
- Internal event handlers: `func handlePlaybackFailure(entryID: UUID, progressSeconds: Double) async`, `func handleInterruption(ended: Bool, shouldResume: Bool)` y `func handleHeadphonesDisconnected()`; los observadores de producción y tests utilizan el mismo comportamiento.
- Produces: `SystemMediaControls.init(controller: PlaybackController)` y `func update(video: Video?, elapsed: Double, duration: Double?, isPlaying: Bool)`; sus comandos llaman al controlador anterior sin retenerlo mediante un ciclo.

- [ ] **Step 1: Escribir pruebas fallidas de cola, recuperación y eventos.** Dos ocurrencias de un mismo video reciben UUID distintos. Quitar una entrada anterior mantiene el contenido actual; quitar la actual pausa y deja seleccionada la siguiente disponible, o la anterior si era la última. Un índice restaurado inválido se convierte en ausencia de selección; el progreso negativo o no finito se normaliza a 0. Al finalizar la cola se pausa sin volver al inicio. Afirmaciones de los casos críticos:

```swift
// testRepeatedVideoKeepsIndependentQueueEntries
XCTAssertEqual(queue.entries.map(\.video.id), ["aaaaaaaaaaa", "aaaaaaaaaaa"])
XCTAssertNotEqual(queue.entries[0].id, queue.entries[1].id)
// testExpiredResourceIsResolvedOnlyOnceAgain
XCTAssertEqual(resolutionRequestsForEntry, 2) // inicial + una recuperación
XCTAssertEqual(recoverySeekSeconds, 42, accuracy: 0.1)
// testHeadphonesDisconnectPauses
XCTAssertEqual(player.state, .paused(videoA))
// testRestoreDoesNotStartAudio
XCTAssertEqual(nativePlayer.rate, 0)
```

- [ ] **Step 2: Confirmar RED.** Ejecutar `bash scripts/ci.sh test`; fallan las pruebas nuevas por ausencia de la cola y los manejadores de recuperación.
- [ ] **Step 3: Implementar la cola con un único reproductor.** El método `play(Video)` delega en el método de lista. Resolver el actual y preparar el siguiente cuando sea posible; comprobar vigencia al usar un recurso preparado. Observar final/error del elemento nativo y mantener la correspondencia con el UUID de la ocurrencia. Error de extracción del siguiente pausa y muestra el fallo; el usuario decide pasar o reintentar. Los reintentos automáticos se limitan a una recuperación de un recurso caducado; un error genérico de extracción no provoca un bucle.
- [ ] **Step 4: Integrar sesión y comandos del sistema.** Publicar título, autor, progreso y estado en MPNowPlayingInfoCenter. Añadir reproducción, pausa, siguiente, anterior y seek en MPRemoteCommandCenter. Retirar observadores y handlers al liberar sus propietarios. Pausar al desconectar auriculares; al acabar una interrupción reanudar únicamente si el sistema lo permite y el usuario no había pausado. La restauración no obtiene URLs ni reproduce hasta que el usuario pulse reproducir.
- [ ] **Step 5: Confirmar GREEN y probar el cambio automático bloqueado.** Ejecutar tests; después, en el iPhone, pasar por una cola de tres elementos con pantalla bloqueada y verificar los comandos, desconexión de auriculares e interrupción. Un test de cola pura no demuestra transición real en segundo plano.
- [ ] **Step 6: Commit.** Mensaje `feat: add playback queue and system media controls`.

## Task 4: Biblioteca local que conserva los datos

**Files:**
- Create: `ReproductorPersonal/Library/LibraryModels.swift`, `ReproductorPersonal/Library/LibraryStore.swift`.
- Modify: `ReproductorPersonal/Support/AppError.swift` solo si un mensaje existente necesita aclaración.
- Test: `ReproductorPersonalTests/LibraryStoreTests.swift`.

**Interfaces:**
- Consumes: Video y QueueSnapshot de tareas anteriores.
- Produces: `LocalPlaylist: Identifiable, Codable, Equatable`, con `id: UUID`, `name: String`, `videos: [Video]`.
- Produces: `LibrarySnapshot: Codable, Equatable`, con `schemaVersion: Int = 1`, `favorites: [Video]`, `playlists: [LocalPlaylist]`, `recent: [Video]`, `queue: QueueSnapshot?`.
- Produces: `@MainActor LibraryStore: ObservableObject`, `init(fileURL: URL)`, `private(set) var snapshot: LibrarySnapshot`, `func load() throws`, `func setFavorite(_ video: Video, enabled: Bool) throws`.
- Produces: `func createPlaylist(name: String) throws -> UUID`, `func renamePlaylist(id: UUID, name: String) throws`, `func deletePlaylist(id: UUID) throws`, `func add(_ video: Video, to playlistID: UUID) throws`, `func remove(at index: Int, from playlistID: UUID) throws`, `func recordRecent(_ video: Video) throws`, `func saveQueue(_ queue: QueueSnapshot) throws`.

- [ ] **Step 1: Escribir pruebas fallidas con archivos temporales.** Guardar/cargar listas, favoritos, recientes y cola; añadir dos veces el mismo favorito no duplica; una reproducción reciente mueve el contenido al inicio; quitar una posición de una lista no borra otras ocurrencias. Nombres se recortan y el nombre vacío se rechaza. Simular un archivo JSON inválido, `schemaVersion = 2` y escritura fallida utilizando una URL sin directorio escribible. Afirmaciones:

```swift
// testRoundTripPreservesLibraryAndQueue
XCTAssertEqual(reloaded.snapshot, originalSnapshot)
// testFavoriteIsNotDuplicated
XCTAssertEqual(store.snapshot.favorites.map(\.id), ["aaaaaaaaaaa"])
// testInvalidLibraryIsNotOverwritten
XCTAssertEqual(try Data(contentsOf: fileURL), originalBytes)
// testFailedWriteKeepsPreviousSnapshot
XCTAssertEqual(store.snapshot, previousSnapshot)
```

- [ ] **Step 2: Confirmar RED.** Ejecutar `bash scripts/ci.sh test`; faltan los modelos y las operaciones de almacenamiento.
- [ ] **Step 3: Implementar Codable y guardado atómico.** Usar Application Support y `library.json`. Serializar operaciones en MainActor; preparar una copia de la siguiente biblioteca, escribir con `.atomic` y publicar la copia solamente después de éxito. Al cargar una biblioteca inválida o de una versión no soportada, conservar el archivo y bloquear escrituras sobre él hasta una recuperación explícita; no reinicializarlo silenciosamente. No incluir PlaybackResource en el esquema persistente.
- [ ] **Step 4: Confirmar GREEN y comprobar orden de operaciones.** Ejecutar tests, incluidas dos modificaciones consecutivas que deben conservar ambos resultados. Verificar bytes previos y estado previo cuando falla una escritura.
- [ ] **Step 5: Commit.** Mensaje `feat: persist personal library and playback references`.

## Task 5: Buscar y Biblioteca como una sola experiencia

**Files:**
- Create: `ReproductorPersonal/App/RootView.swift`.
- Create: `ReproductorPersonal/Library/LibraryView.swift`, `ReproductorPersonal/Library/PlaylistView.swift`.
- Create: `ReproductorPersonal/Playback/MiniPlayerView.swift`, `ReproductorPersonal/Playback/QueueView.swift`.
- Modify: `ReproductorPersonal/App/ReproductorPersonalApp.swift`, `ReproductorPersonal/Search/SearchView.swift`, `ReproductorPersonal/Playback/PlayerView.swift`, `project.yml`.
- Test: `ReproductorPersonalUITests/PersonalPlayerFlowTests.swift`.
- Test support: `ReproductorPersonal/App/UITestYouTubeProvider.swift`, compilado únicamente en Debug.

**Interfaces:**
- Consumes: SearchViewModel, PlaybackController y LibraryStore con las interfaces ya definidas.
- Produces: `RootView(search: SearchViewModel, playback: PlaybackController, library: LibraryStore)` y vistas que reciben esas mismas instancias; no recrean reproductores.
- Produces: el modo `--ui-testing` solamente en Debug, que usa respuestas controladas y una biblioteca temporal. El IPA Release conserva siempre la integración real.

- [ ] **Step 1: Escribir pruebas de flujo fallidas.** Añadir identificadores accesibles `searchField`, `searchSubmit`, `result-<videoID>`, `miniPlayer`, `libraryTab`, `favoritesList`, `favorite-<videoID>` y `playlistNameField`. Buscar el contenido de prueba, seleccionar un resultado, guardarlo como favorito, crear una lista, añadir el resultado y volver a Buscar conservando el reproductor compacto. El estado vacío mantiene el buscador disponible; el estado de error añade Reintentar. Afirmaciones:

```swift
// testSearchToFavoriteAndPlaylist
XCTAssertTrue(app.otherElements["miniPlayer"].exists)
XCTAssertTrue(app.cells["favorite-aaaaaaaaaaa"].exists)
XCTAssertTrue(app.staticTexts["Mi lista"].exists)
// testSearchEmptyAndFailureStatesRemainOperable
XCTAssertTrue(app.buttons["Reintentar"].exists)
XCTAssertTrue(app.textFields["searchField"].isEnabled)
```

- [ ] **Step 2: Confirmar RED.** Ejecutar `bash scripts/ci.sh test` incluyendo el target UI; el flujo falla porque aún falta la biblioteca integrada.
- [ ] **Step 3: Implementar las pantallas y conectar datos.** Dos pestañas: Buscar y Biblioteca. Biblioteca contiene Favoritos, Listas y Recientes. Añadir acciones de favorito, lista y cola a resultados y reproducción actual. La raíz carga la biblioteca, restaura la cola sin iniciar audio y guarda referencias al cambiar de cola o pausar; guardar el progreso en esas transiciones y al pasar la app a segundo plano, evitando escribir cada segundo. Al confirmar que un elemento empezó a reproducirse, registrarlo en Recientes. Mostrar errores de guardado, red y reproducción en español con acciones aplicables.
- [ ] **Step 4: Confirmar GREEN y revisar accesibilidad.** Ejecutar pruebas unitarias/UI. Verificar manualmente tamaños de letra grandes, etiquetas VoiceOver, teclado y controles con una mano; asegurar que títulos largos y listas vacías siguen siendo utilizables. Mostrar solo estados y datos obtenidos: no anunciar éxito ni contenido reproducible por el hecho de haberlo encontrado en la búsqueda.
- [ ] **Step 5: Commit.** Mensaje `feat: connect search playback and personal library`.

## Task 6: Entrega instalable y pruebas reales de la primera etapa

**Files:**
- Create: `README.md`, `docs/verificacion-iphone.md`.
- Modify: `docs/instalacion-iphone.md`, `.github/workflows/ios.yml`, `scripts/ci.sh` únicamente si la verificación descubre un problema.
- Test: los targets unitarios/UI existentes y la prueba manual del dispositivo; no crear tests que reflejen solamente el texto de la guía.

**Interfaces:**
- Consumes: proyecto funcional de Tasks 1–5 y artefactos de GitHub Actions.
- Produces: IPA Release comprobado, guía de instalación/actualización/renovación y registro de resultados en el iPhone real.

- [ ] **Step 1: Ejecutar la verificación completa.** `bash scripts/ci.sh test` y `bash scripts/ci.sh ipa` deben devolver 0 en macOS. Guardar el enlace de ejecución, revisión de código, versiones de herramientas, resultados de tests y nombre del IPA. Cuando haya una modificación nueva, repetir los checks afectados; no reutilizar resultados anteriores para afirmar que pasó una revisión distinta.
- [ ] **Step 2: Instalar y comprobar el uso cotidiano.** El usuario realiza la instalación siguiendo la guía. Elegir desde el buscador tres canciones y dos videos públicos, uno de al menos quince minutos. Probar quince minutos de escucha bloqueada, cambios entre apps, una cola de tres elementos, controles del sistema, auriculares e interrupción. Registrar ausencia o presencia de anuncios observada, contenidos no disponibles y errores reales; no presentar datos sintéticos del simulador como resultados de YouTube.
- [ ] **Step 3: Comprobar la biblioteca y actualización.** Crear/renombrar/borrar una lista, añadir/quitar elementos, guardar/quitar favoritos y cerrar/abrir la app. Confirmar persistencia y restauración sin reproducción automática. Instalar una actualización con el mismo identificador y comprobar que conserva la biblioteca. Documentar la renovación cada siete días con AltServer.
- [ ] **Step 4: Cerrar pendientes con evidencia.** Corregir fallos encontrados y repetir la prueba específica. `docs/verificacion-iphone.md` identifica para cada criterio si pasó, falló o no se pudo probar y qué evidencia existe. Una fase sin reproducción verificada en el iPhone permanece incompleta, aunque el código esté escrito y los tests automáticos pasen.
- [ ] **Step 5: Commit y revisión final.** Mensaje `docs: record iPhone installation and validation`. Revisar el cambio completo contra la especificación, especialmente el proveedor real en Release, el segundo plano, reintentos limitados y conservación de la biblioteca. Informar resultados y limitaciones comprobadas.

## Cobertura de la especificación

| Sección de la especificación | Tareas que la implementan |
| --- | --- |
| Objetivo y decisiones acordadas | Tasks 1–2; el hito técnico determina si la vía local funciona. |
| Alcance funcional | Búsqueda/video en Task 2; cola/controles en Task 3; biblioteca en Tasks 4–5. |
| Experiencia de uso | Tasks 2 y 5, con pruebas de flujo y accesibilidad. |
| Arquitectura, extracción y persistencia | Tasks 1, 3 y 4. |
| Errores y límites | Tests de Tasks 1–5 y comprobaciones de Task 6. |
| Desarrollo, compilación e instalación | Configuración de Task 1, prototipo de Task 2 y entrega de Task 6. |
| Hitos y verificación | Hito 1 al terminar Task 2; hitos 2 y 3 al terminar Task 6. |
| Segunda etapa: cuenta | Registrada como siguiente trabajo; este plan conserva las listas locales y no añade autenticación anticipada. |

## Ejecución propuesta y dependencias

Orden: Task 1 → Task 2 → comprobación del hito técnico en el iPhone → Task 3 → Task 4 → Task 5 → Task 6.

Recomiendo ejecución **Native**, implementando las tareas en esta sesión: las interfaces dependen unas de otras, es un proyecto personal y la principal incertidumbre necesita una prueba real en el teléfono. La revisión independiente final se realiza según el flujo elegido. El usuario revisa este documento y elige Native o Subagent-driven antes de comenzar la implementación.

La compilación requiere una cuenta de GitHub con Actions disponible. La instalación y los resultados del dispositivo requieren participación del usuario; no hay una conexión de control del iPhone en esta sesión. Cuando se disponga de un IPA, pedir únicamente los resultados de la prueba concreta que falten.

## Referencias de implementación

- [Revisión inicial fijada de YouTubeKit](https://github.com/b5i/YouTubeKit/commit/6532af39da4c1612b0a1af603792419d8fb0e67f).
- [SearchResponse y sus resultados](https://github.com/b5i/YouTubeKit/blob/main/Sources/YouTubeKit/YouTubeResponseTypes/Search/SearchResponse.swift).
- [XcodeGen: especificación del proyecto, targets y paquetes](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md).
- [GitHub: acción de publicación de artefactos](https://github.com/actions/upload-artifact).
- [Apple: configuración de audio para reproducción](https://developer.apple.com/documentation/avfaudio/avaudiosession).
- [AltStore Classic: instalación desde Windows](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows).

## Revisión del plan

La autorrevisión documental cubre la correspondencia con la especificación, las interfaces entre las seis tareas y pruebas para los cinco riesgos indicados. El plan mantiene un alcance de primera etapa y registra la integración con la cuenta como trabajo posterior. La revisión documental no confirma que el proyecto compile ni que YouTube se reproduzca; esas comprobaciones pertenecen a la ejecución de Tasks 1, 2 y 6.
