---
phase: 180-bounded-digital-twin-demonstration
plan: 04
subsystem: example-host offline island, test-gated fault harness
tags: [offline-island, playwright, accessibility, e2e-guard, recovery]
requires:
  - phase: 180-01
    provides: gate verdict existing_path_supported (route_capabilities_list)
  - phase: 180-02
    provides: candidate checkout and decision binding
provides:
  - free-form answer entry and Play pronunciation action in the offline-study island
  - durable-state learner copy with a closed data-island-state attribute and a count-only outbox accessor
  - host-owned recovery destination GET /offline/review with confirmed Discard
  - test-gated TwinFaultController (fault preparation, reference media, decision counters, build identity)
  - frozen reference media identity in 180-IDENTITY.json
affects: [180-05, 180-06, 180-07]
requirements: [TWIN-03, TWIN-04]
requirements_completed: []
status: complete
plan_head_before: 12f84cd950d4574921767df823faed6797c17c26
plan_head_after: 12f84cd950d4574921767df823faed6797c17c26
actuals:
  tokens: 27000
  tasks: 3
  commits: 0
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/e2e/twin_fault_controller.ex
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/review.html.heex
    - examples/phoenix_host/e2e/offline_accessibility.spec.ts
    - examples/phoenix_host/e2e/offline_recovery.spec.ts
    - examples/phoenix_host/test/crosswake_example/e2e/twin_fault_controller_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/180-bounded-digital-twin-demonstration/180-IDENTITY.json
  modified:
    - examples/phoenix_host/priv/static/offline_study.js
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex
    - examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex
    - examples/phoenix_host/lib/crosswake_example/router.ex
    - examples/phoenix_host/lib/crosswake_example/e2e/replay_authority.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex
    - examples/phoenix_host/e2e/offline_sync.spec.ts
    - examples/phoenix_host/test/crosswake_example/page_title_test.exs
---

# Phase 180 Plan 04: Learner-visible island work and twin observation surfaces

## What happened, in plain terms

The study page in the example Phoenix app now lets a learner type a free-form answer, save it offline, and ask to hear the pronunciation. The page tells the learner the truth about where their answer is: saved on this device, waiting to send, sending, saved to your account, needs review, or temporarily unavailable. If the server rejects an answer or finds a conflict, the answer stays on the device, the page says "Needs review", and a link takes the learner to a new review page where they can try again or discard it. Discard always asks for confirmation first.

All three tasks ran with their verify commands copied word for word. All three exited 0. Nothing was committed in the candidate (by instruction), so everything described here is uncommitted work in `/private/tmp/crosswake-phase180-impl`. Nothing in the recovery checkout was staged, committed, or edited apart from `180-IDENTITY.json` and this summary.

Not done and not claimed: TWIN-03 and TWIN-04 are not marked complete. This plan only builds the web-layer pieces; iOS observation (180-05) and the producers (180-06) are separate plans.

## Verify results (verbatim commands, all exit 0)

| Task | Command result |
|------|----------------|
| 1 | Playwright chromium: 40 passed (offline_sync 29, offline_accessibility 11); no .png/.jpeg/.webm/.zip under the run dir |
| 2 | ExUnit: 24 tests, 0 failures (twin_fault_controller_test 10, plus replay_admission and sync_controller suites) |
| 3 | Playwright chromium: 49 passed (offline_recovery 9, offline_sync 29, offline_accessibility 11); no capture files |

Extra regression runs (not in the plan): the whole Playwright suite in the candidate passed 86 of 86 with captures off. The example-host ExUnit suite passes 165 of 167; the 2 failures are the pinned Phase180 feasibility tests, explained under deviations. Root-level isolation, CI-integrity, catalog and generator suites related to this code passed.

## Test counts per spec

- `offline_sync.spec.ts`: 23 original tests unchanged (diff is added lines only) plus 6 new = 29.
- `offline_accessibility.spec.ts` (new): 11, one per D-24 check (accessible name, status announcement, targets, focus, contrast in light/dark/no-preference, reflow at 320 px with 200% text, input visible, safe-area, keyboard, reduced motion, status meaning).
- `offline_recovery.spec.ts` (new): 9 (rejection, conflict, review page contents, Try again, Keep answer, Discard answer, survival across reload and fence, replay unavailable, review-page accessibility).
- `twin_fault_controller_test.exs` (new): 10.

## Frozen media identity (read by 180-05 and 180-06)

`180-IDENTITY.json` (schema `crosswake.phase180.identity/1`, candidate head 12f84cd9): `pronunciation.aiff`, 33706 bytes, SHA-256 `5d8b3f72beb26205032d764bc7979f5658c7c9f262427bce2d814f2bf0fabf5b`. It matches the tracked file and the bundle manifest. The controller test asserts these literal values.

## Route id observation (flagged assumption)

`OfflineController.index/2` builds its island contract with route id `study-session`, while the router id (and the Phase 181 probe) is `offline-study`. The island's audio request uses `offline-study`. I did not rename anything. The mismatch is still there for someone to decide on.

## Decisions and design notes for later plans

- Audio request: typed `host.study.audio.play`, protocol `crosswake.bridge` version `1.1.0`, `capability` equal to the command, `payload` has exactly `asset_key` ("pronunciation") and `correlation_id`. It is sent only when `window.crosswakeBridge.capabilities` lists the command and a transport exists (WebKit handler first, then injected object). The play button uses `aria-disabled` rather than `disabled` so it stays keyboard-reachable; "Audio unavailable" shows in an adjacent line. The reply landing pad is installed only on pages with the play button and never replaces an existing `__reply`.
- Declaration: `router.ex` already declared `host.study.audio.play` on the offline-study route in the candidate head (Phase 181 seam), so no declaration change was needed or made. The new review route declares no capability.
- Closed state attribute `data-island-state` sits on `#crosswake-study-status`. Values: saved_local, waiting, sending, saved_account, needs_review, unavailable, audio_unavailable, fenced, entry_disabled. After scope activation with an empty outbox it reads `saved_account` with no visible line (vacuously true; no copy claims a save). Before activation and after a fence it reads `fenced`.
- `window.crosswakeIsland.outboxCounts()` returns a promise of four integers: selected, free_form, active_scope_total, retained_total.
- Fault controller endpoints (all inside the one existing `/_e2e` guard): `POST /_e2e/twin/fault` (kinds replay_reject, replay_conflict, entry_disable, replay_disable, media_missing, media_corrupt, clear; optional integer `card_id`), `GET /_e2e/twin/media/pronunciation`, `GET /_e2e/twin/observe`, `GET /_e2e/twin/build`. The media route skips the JSON-only pipeline so native and browser audio stacks can fetch it.
- The run-owned table only exists after the first twin endpoint call. Decisions made before a first `POST fault (clear)` or `GET observe` are not counted. 180-06 must call one of them first. `clear` lifts faults only; counters are monotonic for the server run, so producers should compare before and after.
- Counter meanings: `admitted` counts accepted outcomes; `duplicate_delivery` counts any delivery that passed admission for an id already seen in this run; authority class counters count deliveries that passed admission.
- Prepared rejection and conflict are persisted `rejected` rows that the real Study uniqueness path then meets (same scope gives a rejected record; a different scope gives the real `scope_conflict`). The fault controller never writes an accepted row and never returns a canned allow. Entry and replay disablement make the real feature and domain owners deny, so no row is written.
- Build identity: SHA-256 of the lowercase hex MD5s of the app's modules, sorted and joined by newlines.
- Review page keeps no answer text, mutation id, or scope value in its DOM (tested). "Temporarily unavailable" is derived from a recorded disablement that lapses after five minutes so a stale record cannot hide Try again forever.

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 - Blocking] Playwright dependencies were missing in the candidate**
- Found during: Task 1 verify setup (no `node_modules` in the candidate, so `npx playwright` would download from the network).
- Fix: copied the already-installed `node_modules` from the recovery checkout (read-only source, same locked @playwright/test 1.60.0, integrity matched the lockfile) into the candidate's gitignored `node_modules`. No network install, no new package.

**2. [Rule 1 - Bug] Existing copy and tests pinned the old status text**
- Existing tests assert the legacy status labels ("Saved on this iPhone.", "Some saved answers need review." and so on) and one asserts exactly one announcement event per change. The D-23 copy therefore lives in an additional line inside the same status region (`#study-durable-copy`) and the legacy labels are unchanged. Result: both lines are visible together, which is slightly redundant for learners. A later copy pass could merge them if the old tests are retired.

**3. [Rule 1 - Bug] Real server rejection was classified as "blocked" by the browser**
- The server's persisted-rejected record has no `class`, and `halted: rejected` was not in the browser's allowed set, so a true rejection paused instead of reaching needs-review. The classifier now accepts that record and halt value.

**4. [Rule 1 - Bug] Free-form size check**
- The server limit is 4096 bytes (admission) not characters; one oversized batch would block the whole queue. The browser enforces bytes. The plan text said characters.

**5. [Rule 1 - Bug] Shared script on another page**
- `offline_study.js` is also loaded by the LearnLoop study page, which lacks the new controls. The first version threw there and failed four existing route-tour tests. The new listeners are now optional and the audio landing pad is only installed where the play button exists.

**6. [Rule 3 - Blocking] Page-title test enumerates all browser routes**
- Adding the review route made `page_title_test.exs` fail. I added the planned title for `offline-study-review` and a `/offline/review` title assertion. This file was not in the plan's file list.

**7. Small layout changes to existing markup**
- `#flashcard-container` now uses `box-sizing: border-box`, `h1` wraps long words, and small screens use 1rem side padding, so 200% text at 320 px does not overflow. Body padding also honors safe-area insets.

### Plan wording adjusted without a deviation of intent

- The link to the review page appears only when reviewable work exists (a real rejection or conflict marked work for review). An existing test requires no link after an authority denial, so the link is not shown on every attention state.
- `observe_result/2` computes the authority class itself (config says the E2E authority is the synthetic one) rather than taking it as a third argument.
- The plan's routing text says the review page lists "retained items"; both needs-review and still-waiting items are listed, with state words for each.

## Known issues left alone (out of scope)

- Two pinned Phase180 feasibility tests in `examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs` (gate checks G2 and G6) fail in the full example-host suite. They assert the pre-seam state (no route declares a host capability); the candidate head already contains the Phase 181 declaration. They fail with or without this plan's changes and I did not touch them. They are not in this plan's verify commands.
- The two accessibility checks for the review page confirm targets, contrast in three schemes, focus indicators and 200% reflow, but not the safe-area and shortened-viewport checks (those are on the island page, per the plan).

## Known Stubs

None. Fault controls only prepare state; no data is mocked into the learner UI.

## Threat Flags

None beyond the plan's register. New surfaces (twin endpoints) are compile-time guarded to test and e2e builds; a test asserts they appear only inside the single existing guard block.

## Commits

None. By instruction no commits were made in the candidate. The candidate working tree holds 8 modified and 5 new product files for this plan (plus the untracked 180-03 files), all uncommitted. `plan_head_before` and `plan_head_after` are both 12f84cd9 because no commit was made. The recovery checkout's staging area is empty.

## Self-Check: PASSED

- 180-IDENTITY.json exists and matches the tracked media file (size and SHA-256).
- All three task verify commands exit 0 as recorded above.
- `git -C <home>/projects/crosswake diff --cached --name-only` is empty.
