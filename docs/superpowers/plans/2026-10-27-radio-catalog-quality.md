# Radio and Catalog Quality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure continuous radio queues only playable song-length tracks and improve genre discovery and ranking with official-channel signals.

**Architecture:** `Video` will expose the catalog predicates used by radio and ranking. `YouTubeMapping` will derive official-channel metadata and enforce the Merengue exclusion at the network boundary; `YouTubeClient` will centralize genre-specific search queries. `RadioSession` will retain only preferred songs in its buffer and return partial/empty batches once permitted pages are exhausted.

**Tech Stack:** Swift 5, SwiftUI, XCTest, YouTubeKit.

**Spec:** User-approved Phase 1 technical plan (2026-10-27).

## Global Constraints

- Radio accepts only preferred songs whose parsed duration is 180...600 seconds.
- Radio never queues unknown-duration, long, or fallback videos after preferred songs run out.
- Merengue query is `música merengue clásico éxitos oficiales` and excludes `soul` in title or author/channel.
- Blues query is `classic blues music official audio hits`.
- Official-channel priority recognizes verification notation, musical-note artists, Topic / ` - Topic`, and VEVO.
- No dependency upgrades or new dependencies.

## Review Focus

- A radio page containing only long or unknown videos must return an empty batch and no buffered fallback.
- A partial final batch must contain only 3–10 minute songs after all three permitted pages are examined.
- Case and diacritic variants of `Soul` in a Merengue title or author must be excluded.
- Generic videos must remain usable while otherwise equal official-channel videos rank first.
- Existing manual search behavior must keep long and unknown videos selectable.

---

### Task 1: Strict radio selection

**Files:**
- Modify: `ReproductorPersonal/Playback/RadioSession.swift`
- Test: `ReproductorPersonalTests/RadioSessionTests.swift`, `ReproductorPersonalTests/SongPreferenceTests.swift`

**Interfaces:**
- Consumes: `Video.isPreferredSong: Bool`, `RecommendationPage`.
- Produces: `RadioSession.batch(excluding:limit:) async throws -> [Video]` containing only preferred songs.

- [ ] **Step 1: Write failing tests** for long/unknown-only pages and for a final partial batch after the three-page scan.
- [ ] **Step 2: Run the focused radio tests** and verify that the old fallback behavior fails their assertions.
- [ ] **Step 3: Change `RadioSession.batch(excluding:limit:)`** to discard non-preferred videos before buffering and to return only preferred songs.
- [ ] **Step 4: Re-run focused radio tests** and verify they pass.

### Task 2: Genre-specific discovery and Merengue filtering

**Files:**
- Modify: `ReproductorPersonal/YouTube/Video.swift`, `ReproductorPersonal/YouTube/YouTubeMapping.swift`, `ReproductorPersonal/YouTube/YouTubeClient.swift`
- Test: `ReproductorPersonalTests/YouTubeMappingTests.swift`

**Interfaces:**
- Produces: `YouTubeClient.genreQuery(for: String) -> String`; mapping option that excludes soul-related Merengue videos.

- [ ] **Step 1: Write failing tests** for Merengue and Blues query strings and title/channel `soul` filtering.
- [ ] **Step 2: Run focused mapping tests** and verify the expected assertions fail.
- [ ] **Step 3: Add normalized genre query selection and a Merengue content predicate**, then apply it to the initial Merengue search mapping.
- [ ] **Step 4: Re-run focused mapping tests** and verify they pass.

### Task 3: Official-channel metadata and ranking

**Files:**
- Modify: `ReproductorPersonal/YouTube/Video.swift`, `ReproductorPersonal/YouTube/YouTubeMapping.swift`
- Test: `ReproductorPersonalTests/YouTubeMappingTests.swift`, `ReproductorPersonalTests/DiscoveryViewModelTests.swift`

**Interfaces:**
- Produces: `Video.isOfficialChannel: Bool` and `Array<Video>.prioritizingOfficialChannels() -> [Video]`.

- [ ] **Step 1: Write failing tests** for official metadata mapped from `Topic`, VEVO, music note, and verified notation, plus recommendation ranking.
- [ ] **Step 2: Run focused tests** and verify official videos are not yet prioritized.
- [ ] **Step 3: Add official-channel detection in `YouTubeMapping` and apply official priority before existing author variety/song priority in discovery results.**
- [ ] **Step 4: Re-run focused tests** and verify they pass.

### Task 4: Full regression verification

**Files:**
- Modify: only files from Tasks 1–3 as necessary.

- [ ] **Step 1: Run the complete unit suite** with `bash scripts/ci.sh test-unit` on macOS CI or a local Xcode environment.
- [ ] **Step 2: Inspect the diff against the phase requirements** and record any environment limitation separately from code results.
