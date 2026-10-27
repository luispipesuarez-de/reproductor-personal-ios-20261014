# Playback, Search, and Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make playback resolution instant when a valid resource is available, add local duration filtering, and polish tab navigation, keyboard dismissal, and paused mini-player dismissal.

**Architecture:** A main-actor `PlaybackResourceCache` owns valid resources and one task per in-flight video ID; `PlaybackController` uses it for current and prefetched items. `SearchViewModel` preserves each response's original result set and republishes a duration-filtered projection using `Video.durationSeconds`. `RootView` owns selected-tab state, while search/library receive a binding and the mini player owns only visual drag state.

**Tech Stack:** Swift 5, SwiftUI, AVFoundation, XCTest.

**Spec:** User-approved Phase 2 and 3 technical proposal (2026-10-27).

## Global Constraints

- Cache entries are reusable only while `PlaybackResource.expiresAt` is strictly after the current time; resources without an expiry are not retained.
- Concurrent resolutions for the same video ID share one underlying provider request; failed requests are never cached.
- Duration filters are `Todos`, `<4m`, `4-20m`, and `>20m`, use the `Video` duration parser, and never issue a new search request.
- The original ordered search response remains the source for every filter change.
- The tab selector is owned by `RootView` and both tab toolbars alter that shared state.
- Only a paused mini player is horizontally draggable; dismissal requires 70 pt and otherwise snaps back with a spring.
- The native AV queue player sets `automaticallyWaitsToMinimizeStalling = false`.
- No dependency upgrades or new dependencies.

## Review Focus

- A resource that expires exactly now must be re-resolved, while one expiring in the future must be reused (Task 1).
- Simultaneous current-item and prefetch requests for one video ID must make one provider request (Task 1).
- Unknown and malformed durations appear in `Todos` but in none of the finite duration ranges (Task 2).
- Changing filters after a zero-match filter restores the original ordered results without a network request (Task 2).
- Vertical drags and drags while playing must not dismiss or move the mini player (Task 4).

---

### Task 1: Expiring playback cache and immediate player configuration

**Files:**
- Create: `ReproductorPersonal/Playback/PlaybackResourceCache.swift`
- Modify: `ReproductorPersonal/Playback/PlaybackController.swift`
- Test: `ReproductorPersonalTests/PlaybackResourceCacheTests.swift`, `ReproductorPersonalTests/PlaybackControllerTests.swift`

**Interfaces:**
- Produces: `PlaybackResourceCache.resolve(videoID:source:) async throws -> PlaybackResource`.
- Consumes: `YouTubeProviding.resolve(videoID:)` and `PlaybackResource.expiresAt`.

- [ ] Write failing tests for an unexpired cache hit, expired resource re-resolution, shared concurrent resolution, and `AVQueuePlayer.automaticallyWaitsToMinimizeStalling == false`.
- [ ] Run the focused tests and confirm cache symbols/behavior are absent.
- [ ] Implement cache storage plus per-video in-flight tasks; route both current-item resolution and prefetch through it; configure the supplied player for immediate playback.
- [ ] Re-run the focused tests and confirm they pass.

### Task 2: Typed, local search duration filtering

**Files:**
- Modify: `ReproductorPersonal/YouTube/Video.swift`, `ReproductorPersonal/Search/SearchViewModel.swift`, `ReproductorPersonal/Search/SearchView.swift`
- Test: `ReproductorPersonalTests/SearchViewModelTests.swift`

**Interfaces:**
- Produces: `Video.durationSeconds: Int?`, `SearchDurationFilter`, and `SearchViewModel.setDurationFilter(_:)`.
- Consumes: the existing `SearchState.results(query:videos:)` projection.

- [ ] Write failing tests for each exact duration band, malformed/unknown durations, and switching from an empty filter result back to all results without another provider search.
- [ ] Run the focused search tests and confirm filter selection is unavailable.
- [ ] Expose the existing duration parser, preserve unfiltered response videos in the view model, publish filtered results, and render a typed SwiftUI picker above results.
- [ ] Re-run focused search tests and confirm they pass.

### Task 3: Shared tab selector and keyboard completion control

**Files:**
- Modify: `ReproductorPersonal/App/RootView.swift`, `ReproductorPersonal/Search/SearchView.swift`, `ReproductorPersonal/Library/LibraryView.swift`

**Interfaces:**
- Produces: `RootTab` selection binding passed to both tab roots.
- Consumes: `TabView(selection:)` and SwiftUI keyboard toolbar placement.

- [ ] Add `RootTab` plus a `@State` selection to `RootView`, tag both tab views, and pass its binding into Search and Library.
- [ ] Add a leading toolbar button in each screen to select the other tab, preserving the existing license and create-playlist actions.
- [ ] Add Search's keyboard toolbar `Listo` control, which clears the focused field.

### Task 4: Interactive paused mini-player dismissal

**Files:**
- Modify: `ReproductorPersonal/Playback/MiniPlayerView.swift`
- Test: `ReproductorPersonalTests/PausedPlaybackDismissalTests.swift`

**Interfaces:**
- Consumes: `PlaybackState.paused` and `PlaybackController.dismissPausedPlayback()`.

- [ ] Write a focused controller-level regression test that confirms the dismissal boundary remains restricted to paused playback.
- [ ] Run the focused test and confirm existing behavior protects active playback.
- [ ] Track horizontal drag translation only when paused; offset the mini player interactively, dismiss with the existing controller action after 70 pt, and spring back below threshold.
- [ ] Re-run the focused dismissal tests and confirm they pass.

### Task 5: Full regression verification

**Files:**
- Modify: only files from Tasks 1-4 as required by test failures.

- [ ] Run the complete unit suite with `bash scripts/ci.sh test-unit` on macOS/Xcode CI.
- [ ] In the current Windows environment, record the absence of Xcode tools rather than presenting an unrun iOS suite as passing.
- [ ] Inspect `git diff --check` and the final diff against every global constraint.
