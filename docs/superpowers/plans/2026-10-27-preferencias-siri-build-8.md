# Preferencias locales y Siri Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist likes and dislikes, apply them to automated discovery/radio, expose them in the player, and add iOS 16 Siri actions for local playback.

**Architecture:** `LibrarySnapshot` owns backwards-compatible preference data and `LibraryStore` enforces the exclusive rating invariant. Discovery and Radio receive only the ID sets they need to filter automated candidates. A narrow `SiriPlaybackService` bridges App Intents to the existing `PlaybackController` and library, keeping intent declarations thin and testable.

**Tech Stack:** Swift 5, SwiftUI, XCTest, AppIntents (iOS 16+).

**Spec:** `docs/superpowers/specs/2026-10-27-preferencias-siri-build-8-design.md`

## Global Constraints

- Keep iOS deployment target at 16.0 and add no dependencies.
- Preserve libraries written before `liked` and `disliked` existed.
- A disliked video must never occur in Discovery or a `RadioSession` batch.
- Siri must support Favoritos, pause/resume, and local music playback.

## Review Focus

- A legacy snapshot without preference fields decodes with empty collections.
- A video changing polarity does not remain in both collections.
- A disliked candidate already buffered before the next radio request is discarded.
- An empty Favorites or music library produces a useful intent error rather than starting an empty queue.
- Manual `PlaybackController.play(_:)` remains allowed for a disliked video.

---

### Task 1: Library preferences and controls

**Files:**
- Modify: `ReproductorPersonal/Library/LibraryModels.swift`, `ReproductorPersonal/Library/LibraryStore.swift`, `ReproductorPersonal/Library/VideoActionsMenu.swift`, `ReproductorPersonal/Playback/PlayerView.swift`
- Test: `ReproductorPersonalTests/LibraryStoreTests.swift`

- [ ] Write failing persistence and polarity tests.
- [ ] Run the focused library tests and observe missing APIs/fields.
- [ ] Add backwards-compatible preferences, exclusive setters, and visible toggle actions.
- [ ] Re-run the focused library tests.

### Task 2: Learning exclusions

**Files:**
- Modify: `ReproductorPersonal/Search/DiscoveryView.swift`, `ReproductorPersonal/Search/DiscoveryViewModel.swift`, `ReproductorPersonal/Playback/RadioSession.swift`, `ReproductorPersonal/Playback/PlaybackController.swift`, `ReproductorPersonal/App/ReproductorPersonalApp.swift`
- Test: `ReproductorPersonalTests/DiscoveryViewModelTests.swift`, `ReproductorPersonalTests/RadioSessionTests.swift`

- [ ] Write failing tests for like-first seeds and strict disliked filtering.
- [ ] Run focused discovery/radio tests and observe the unfiltered behavior.
- [ ] Pass preference IDs through the existing refresh/refill boundaries and filter buffered plus fetched candidates.
- [ ] Re-run focused tests.

### Task 3: Siri playback service and shortcuts

**Files:**
- Create: `ReproductorPersonal/Siri/AppIntents.swift`, `ReproductorPersonal/Siri/AppShortcuts.swift`
- Modify: `ReproductorPersonal/App/ReproductorPersonalApp.swift`
- Test: `ReproductorPersonalTests/SiriPlaybackServiceTests.swift`

- [ ] Write failing service tests for favorites, music, and pause/resume.
- [ ] Run them and observe missing Siri service symbols.
- [ ] Implement the actor-isolated service, App Intents, and shortcuts using the service bridge.
- [ ] Re-run focused tests.

### Task 4: Release metadata and documentation

**Files:**
- Modify: `project.yml`, `README.md`
- Create: `docs/cambios-compilacion-8.md`

- [ ] Set build number 8 and document behavior and device checks without unsupported verification claims.
- [ ] Generate the project and run the relevant unit suite plus a Release build when macOS/Xcode is available.
