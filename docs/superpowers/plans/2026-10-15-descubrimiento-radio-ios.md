# Descubrimiento y radio continua — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrar historial visible, mezcla, portada del sistema, búsqueda al escribir, recomendaciones, descubrimiento y radio continua en la app existente.

**Architecture:** Reutilizar el proveedor anónimo, `PlaybackQueue`, un único `AVQueuePlayer` y la biblioteca JSON. Una sesión de radio acotada obtiene páginas y descarta resultados antiguos; el controlador decide cuándo insertarlas. La persistencia se conecta al flujo de reproducción y las secciones de descubrimiento viven dentro de Buscar.

**Tech Stack:** Swift 5, SwiftUI, Foundation, Combine, AVFoundation, MediaPlayer, UIKit/ImageIO, YouTubeKit `6532af39da4c1612b0a1af603792419d8fb0e67f`, XCTest, XcodeGen y GitHub Actions macOS.

**Spec:** `docs/superpowers/specs/2026-10-15-descubrimiento-radio-ios-design.md`.

**Execution:** Nativa, en esta conversación. El usuario revisó la especificación y pidió «aprobado todo el plan. ejecutalo». Este documento concreta las interfaces y comprobaciones de los tres bloques aprobados. No se atribuye al usuario la lectura de un documento técnico que todavía no existía cuando dio esa instrucción.

## Global Constraints

- iPhone 13 con iOS 26.2; mínimo de la aplicación iOS 16.
- Dos pestañas: Buscar y Biblioteca. Interfaz en español con Dynamic Type, VoiceOver y objetivos táctiles de al menos 44 puntos.
- Una instancia de `AVQueuePlayer`; ejecución de búsquedas y resolución desde el iPhone; mismos paquetes, sin servidor propio.
- Búsqueda automática después de aproximadamente 400 ms y al menos dos caracteres; envío manual inmediato.
- Continuación automática activada por defecto y desactivable por el usuario.
- Hasta tres fallos consecutivos de candidatos automáticos antes de detener el avance con aviso; los fallos de selección manual conservan Reintentar/Siguiente.
- Mantener la inicialización anónima que corrigió el favorito en frío en la compilación 5.
- Conservar archivos anteriores, metadatos y entradas manuales duplicadas. Al reabrir, recuperar en pausa.
- Guardar referencias y metadatos; ninguna URL temporal de reproducción ni archivo multimedia en la biblioteca.
- La compilación nueva se distinguirá de la 5 y solo se declarará instalada después de leer el número en el teléfono.

## Review Focus

1. Una búsqueda o radio anterior responde después de cambiar de consulta/género: su resultado se descarta.
2. Una miniatura grande, inválida o tardía: no bloquea la música ni sustituye la imagen de otro contenido.
3. Un JSON de la compilación 5 no tiene campos nuevos: se lee con valores por defecto y se conservan favoritos/listas/cola.
4. Todas las páginas contienen duplicados o fallos: la reposición termina con un límite y no borra la cola manual.
5. El usuario pausa, mezcla, inserta manualmente o vuelve atrás durante una reposición: se conserva su intención y la identidad del contenido actual.

## Estructura e interfaces compartidas

- `PlaybackLibraryPersistence.swift`: observar cambios coherentes del controlador, cargar/restaurar y guardar biblioteca/cola sin depender de una pantalla visible; exponer un error de almacenamiento para la interfaz.
- `RecommendationPage.swift`: `RecommendationSeed` (`.video(String)`, `.genre(String)`) y `RecommendationPage(videos: [Video], continuation: String?)`, todos Codable cuando se persistan y Sendable.
- `RadioSession.swift`: sesión en MainActor con semilla, cursor, candidatos pendientes y generación; consultas acotadas al proveedor existente.
- `DiscoveryViewModel.swift` y `DiscoveryView.swift`: selección Para ti/Por descubrir y su presentación dentro de Buscar.
- Ampliar los archivos actuales de cola, reproducción, proveedor, metadatos, búsqueda y biblioteca. Los tests nuevos se agrupan por esas responsabilidades.

La consulta nueva del proveedor será `recommendations(seed: RecommendationSeed, continuation: String?) async throws -> RecommendationPage`. Las implementaciones de prueba devolverán páginas controladas; las demás llamadas existentes a `search` y `resolve` se conservan.

---

### Task 1: Historial, persistencia de reproducción y mezcla

**Files:**
- Create: `ReproductorPersonal/Playback/PlaybackLibraryPersistence.swift`.
- Modify: `Playback/PlaybackQueue.swift`, `Playback/PlaybackController.swift`, `App/ReproductorPersonalApp.swift`, `App/RootView.swift`, `Library/LibraryStore.swift`, `Library/LibraryView.swift`, `Library/PlaylistView.swift`, `Playback/PlayerView.swift`, `Playback/QueueView.swift` under `ReproductorPersonal/`.
- Test: `ReproductorPersonalTests/PlaybackQueueTests.swift`, `LibraryStoreTests.swift`, new `PlaybackPersistenceTests.swift`; extend `ReproductorPersonalUITests/PersonalPlayerFlowTests.swift`.

**Interfaces:**
- Produce `PlaybackQueue.shuffleUpcoming()` and `shuffleUpcoming<R: RandomNumberGenerator>(using generator: inout R)` for deterministic checks; preserve entry UUIDs/current index/prefix.
- Produce `LibraryStore.allMusic: [Video]`, combining favorites, playlist items and recent by video ID in first-occurrence order.
- Produce `PlaybackController.shuffleUpcoming()` and an optional MainActor `onPlaybackChange: (() -> Void)?`, called after state/queue changes and explicit seeks.
- Produce `PlaybackLibraryPersistence(library: LibraryStore, playback: PlaybackController)`, `load()`, `save()`, `retry()`, and observable `errorMessage: String?`.

- [ ] **Step 1: Add failing behavior checks.**
  - `testShuffleKeepsCurrentPrefixAndEntryIdentities`: select index 1 in four entries, shuffle the suffix with a seeded generator; assert prefix/current UUID/index unchanged and suffix UUID set preserved.
  - `testAllMusicCombinesCollectionsWithoutDuplicateVideoIDs`: favorite A, list [A,B,A], recent [B,C] produces [A,B,C].
  - `testPlaybackRecordsHistoryWithoutRootView`: load persistence, play A then B through a local WAV; assert recent IDs [B,A], reload JSON and assert the same.
  - `testStorageFailureDoesNotStopCurrentAudio`: make the library path unwritable after load; state continues playing and persistence exposes an error.
  - UI: Historial exists and saved favorites still play after relaunch.
- [ ] **Step 2: Verify RED on macOS** using the existing public build copy and `bash scripts/ci.sh test`. Expected new missing interfaces/assertions fail; retain that run/log. Do not count unrelated compilation/network errors as the regression.
- [ ] **Step 3: Implement the interfaces and visible actions.** Move playback persistence out of RootView's view callbacks into the persistence object; keep scene-background save. Rename Recientes to Historial. Add Mezclar Favoritos/lista, Mezclar mi música and Mezclar cola using standard-library shuffle. Read-only storage errors remain visible. NowPlaying receives a read-only storage message rather than an unused binding.
- [ ] **Step 4: Verify GREEN** with the same XCTest command. Inspect current/progress retention, history on native playback and existing storage tests. No resolver changes.
- [ ] **Step 5: Commit** the task's source/tests and record verification in the execution ledger.

### Task 2: Miniatura en los controles del sistema

**Files:**
- Modify: `ReproductorPersonal/Playback/SystemMediaControls.swift`.
- Test: new `ReproductorPersonalTests/SystemMediaArtworkTests.swift`.

**Interfaces:**
- Keep `update(video:elapsed:duration:isPlaying:)` unchanged.
- Extend initialization with an optional injectable `artworkLoader: @Sendable (URL) async throws -> Data`; the default uses Foundation networking/cache.
- The current video ID and thumbnail URL identify an image load. Progress updates reuse its artwork.

- [ ] **Step 1: Add failing checks** `testLateArtworkDoesNotReplaceNewTrack`, `testProgressUpdateKeepsArtwork`, `testInvalidImageDoesNotRemoveMetadata`, `testOversizedArtworkIsRejected`. Use generated PNG data and the existing request gate helper; assert `MPMediaItemPropertyArtwork` and current title, not implementation counters alone.
- [ ] **Step 2: Verify RED** with `bash scripts/ci.sh test`; retain expected new artwork failures.
- [ ] **Step 3: Implement** one cancelable image task, HTTPS/image validation, maximum 4 MiB of downloaded data, a 15-second timeout and ImageIO thumbnail decoding up to 600 pixels. Publish `MPMediaItemArtwork` on MainActor only for the active key; clear the previous image when the key changes. Use native URL caching.
- [ ] **Step 4: Verify GREEN** and confirm no new download is started for each progress tick. Test invalid/oversized images through controlled data/network responses.
- [ ] **Step 5: Commit** source and focused tests.

### Task 3: Búsqueda mientras se escribe

**Files:**
- Modify: `ReproductorPersonal/Search/SearchViewModel.swift`, `Search/SearchView.swift`.
- Test: `ReproductorPersonalTests/SearchViewModelTests.swift`; extend UI search checks.

**Interfaces:**
- Produce `SearchViewModel.queryChanged(_ query: String)` and an injectable `debounceNanoseconds` initializer argument defaulting to `400_000_000`.
- Preserve `submit(query:) async`; it cancels pending debounce and sends immediately.

- [ ] **Step 1: Add failing checks** `testTypingSendsOnlyLatestDebouncedQuery`, `testClearingQueryInvalidatesInFlightResult`, `testManualSubmitDoesNotSendDuplicateDebouncedRequest`. Assert the provider's queries and final SearchState using gates/expectations; no arbitrary long waits.
- [ ] **Step 2: Verify RED** on macOS.
- [ ] **Step 3: Implement** cancellation plus the existing request-identity guard. Remove old rows immediately when the visible query changes; send live requests at two trimmed characters, preserve manual submission and return to idle on empty input. Keep keyboard focus during live results.
- [ ] **Step 4: Verify GREEN**, including existing old-query, empty, error and retry tests and a UI search without pressing Buscar.
- [ ] **Step 5: Commit** source/tests.

### Task 4: Proveedor de recomendaciones y descubrimiento

**Files:**
- Create: `ReproductorPersonal/YouTube/RecommendationPage.swift`, `Search/DiscoveryViewModel.swift`, `Search/DiscoveryView.swift`.
- Modify: `YouTube/YouTubeProviding.swift`, `YouTube/YouTubeClient.swift`, `YouTube/YouTubeMapping.swift`, `Search/SearchView.swift`, `App/ReproductorPersonalApp.swift`, `App/RootView.swift`, and existing stub/UI-test providers.
- Test: new `RecommendationTests.swift`, `DiscoveryViewModelTests.swift`, fixtures under `ReproductorPersonalTests/Fixtures/`; extend provider resolution tests.

**Interfaces:**
- Produce the seed/page types and provider method defined above.
- Produce `YouTubeMapping.videos(from results: [any YTSearchResult]) -> [Video]`; the existing SearchResponse mapping delegates to it.
- Produce `DiscoveryViewModel(source: any YouTubeProviding)`, `refresh(favorites: [Video], recent: [Video]) async`, published state with recommended/discover arrays.
- Initial genre choices: Salsa, Rock, Pop, Bachata, Merengue and Vallenato; custom genre text remains available.

- [ ] **Step 1: Add failing checks.** Related-video and search continuation fixtures map valid video IDs once and preserve cursors. A history [A] excludes A from Por descubrir. Repeated candidates across two seeds merge once; empty local data yields a useful initial state. A late refresh cannot overwrite a newer refresh.
- [ ] **Step 2: Verify RED** on macOS. Separately run a bounded anonymous network diagnostic for the existing salsa/rock samples and log sanitized counts/statuses only. Confirm the pinned dependency parses current related/continuation responses; investigate the adapter before proceeding if it does not.
- [ ] **Step 3: Implement.** For video seeds, initialize anonymous visitor context then use `MoreVideoInfosResponse`/its continuation with cookies disabled. For genre seeds, use SearchResponse and its continuation with a trimmed music/genre query. Follow at most three pages per candidate request; handle the initial related page being empty with a valid continuation. Discovery chooses at most two distinct local seeds and uses the same candidate mapping. Keep the package revision.
- [ ] **Step 4: Verify GREEN** plus fresh metadata-only network evidence. Present genres, Para ti and Por descubrir in SearchView's empty-query state, using existing rows/actions and refresh/retry states. Preserve direct song playback even if discovery fails.
- [ ] **Step 5: Commit** source/tests and sanitized diagnostic conclusions; do not publish personal listening data or diagnostic credentials.

### Task 5: Radio continua y prioridad manual

**Files:**
- Create: `ReproductorPersonal/Playback/RadioSession.swift`.
- Modify: `Playback/PlaybackQueue.swift`, `Playback/QueueSnapshot.swift`, `Playback/PlaybackController.swift`, stub/UI-test providers.
- Test: new `RadioSessionTests.swift`, `PlaybackRadioTests.swift`; extend queue/snapshot/recovery tests.

**Interfaces:**
- Produce `RadioSession(source:)`, `reset(seed: RecommendationSeed?)`, `batch(excluding: Set<String>, limit: Int) async throws -> [Video]`. It owns cursor, buffered candidates and generation; at most three page requests per batch.
- QueueEntry adds `isAutomatic: Bool` with decoding default false; QueueSnapshot adds `autoplayEnabled: Bool` default true and `radioSeed: RecommendationSeed?` default nil when reading legacy JSON.
- Produce queue operations to append automatic candidates, insert manual entries before pending automatic entries and remove only pending automatic entries.
- Produce controller methods `startRadio(genre: String) async`, `startRadio(from video: Video) async`, `setAutoplayEnabled(_ enabled: Bool)` and published status/message for radio actions.
- Keep normal play/next/previous signatures. Request batches of up to 10 candidates when at most two future elements remain. Keep at most 50 past queue entries after advancement; the library history retains their references.

- [ ] **Step 1: Add failing checks.**
  - Genre and song radio each advance beyond their initial candidate page using WAV audio.
  - `testManualEntryPrecedesPendingAutomaticEntries` checks order/UUIDs while the current item/progress remain unchanged.
  - `testChangingRadioDiscardsLatePage` and `testDisablingAutoplayDiscardsLatePage` use request gates.
  - `testDuplicateOnlyPagesStopAfterThreeRequests` returns the current ID forever and proves bounded completion.
  - `testThreeAutomaticPreparationFailuresStopButManualFailureDoesNotSkip` counts actual resolution attempts and checks state.
  - Legacy JSON without new keys loads the original IDs/progress; reloaded queue/radio remains paused.
- [ ] **Step 2: Verify RED** on macOS.
- [ ] **Step 3: Implement.** Controller owns replenishment/preparation outside views and awaits a pending refill at the end if needed. Explicit queue replacement resets the session; next/previous do not reset genre context. Playlist continuation starts from its last manual song. Manual insertion precedes automatic suggestions. Disabling cancels/invalidate tasks and removes only future automatic entries. Auto-only failure skipping is bounded at three. Preserve native interruption/pause intentions and current identity on shuffle.
- [ ] **Step 4: Verify GREEN** with existing native transport, interruption, expiry recovery, queue selection and persistence tests. Assert no more than one refill is active and old callbacks cannot append after replacement.
- [ ] **Step 5: Commit** source/tests.

### Task 6: Integrar acciones de radio y comprobar la experiencia

**Files:**
- Modify: `Search/DiscoveryView.swift`, `Search/SearchView.swift`, `Library/VideoActionsMenu.swift`, `Playback/PlayerView.swift`, `Playback/QueueView.swift`, UI-test provider and `PersonalPlayerFlowTests.swift`.

**Interfaces:**
- Consume the radio/controller/discovery methods above. Display current radio loading/error/retry state independently of playback failure.
- Add visible Continuar automáticamente control, Iniciar radio from a song, genre/custom-genre radio actions and shuffle actions. Keep two tabs.

- [ ] **Step 1: Add failing UI checks** for automatic results while typing, Historial, shuffle access, starting Salsa/Rock, disabling continuation and keeping a manually added song before suggestions. Retain relaunch/favorite regression.
- [ ] **Step 2: Verify RED** for the new missing controls/flows.
- [ ] **Step 3: Implement** native controls and labels, loading/error/empty states. Reuse existing row/menu patterns and 44-point hit areas. Provide custom genre entry. Keep Dynamic Type and visible playback controls with large text.
- [ ] **Step 4: Verify GREEN** with all unit/UI tests and inspect simulator screenshots of Search/discovery, Now Playing/queue and Library in normal/large text/dark mode. Use real network separately from controlled UI fixtures.
- [ ] **Step 5: Commit** the integrated UI/tests.

### Task 7: Revisión, IPA e instalación comprobable

**Files:**
- Modify: `project.yml`, `README.md`, `docs/estado-implementacion.md`, `docs/instalacion-iphone.md`, `docs/verificacion-iphone.md`.
- Delivery metadata and logs remain in ignored `build/`; only generic source/build files go to the existing public build copy.

- [ ] **Step 1: Review the whole diff** against this plan and spec, including the five Review Focus cases. Use the required independent code review once implementation is complete; fix material findings and rerun affected checks.
- [ ] **Step 2: Set build 6 and run integrated CI** with `package_ipa=true` in the existing public build repository. Require the complete XCTest suite and Release build to pass. Preserve actual run IDs/counts rather than predicting them.
- [ ] **Step 3: Verify artifact** ZIP/Info.plist/bundle ID/arm64/minimum iOS/background audio, absence of DEBUG test provider/audio from the Release executable and SHA-256. Back up build5 before replacing the canonical IPA. Inspect exported screenshots.
- [ ] **Step 4: Deliver and install** the new IPA over the existing app using the same Apple account. Authentication is performed by the user. Read installed metadata over the existing USB pairing to verify build6 before attributing physical results.
- [ ] **Step 5: Record physical observations** for artwork on lock screen/Control Center, genre/song radio with several locked transitions, shuffle/previous, library preservation and cold favorite. Leave any unobserved criterion open and preserve the execution ledger. Do not mark the whole stage complete from CI alone.

## Comandos de verificación y disciplina de entrega

En macOS: `bash scripts/ci.sh test`; para el IPA: `bash scripts/ci.sh ipa`. Desde Windows se usa el flujo `iOS` del repositorio público de compilación existente; los registros, datos personales y especificación permanecen privados. La copia pública debe coincidir con el código privado probado antes de despachar cada ejecución.

Para cada RED se conserva el commit/run y la causa esperada. Para cada GREEN se comprueba el resultado terminado, no solo que se haya iniciado el workflow. Los fallos ajenos al comportamiento bajo prueba se diagnostican antes de continuar. En Windows, los cambios de documentación se verifican con `git diff --check`; XCTest requiere macOS.

Self-review: el plan cubre las siete funciones, los valores de búsqueda/fallos, los cinco Review Focus y la migración desde build5. Las interfaces de radio/proveedor se definen una vez y se consumen con los mismos nombres. La ejecución nativa fue solicitada por el usuario; no se crea otro chat.
