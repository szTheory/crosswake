---
id: SEED-008
status: planted
planted: 2026-07-29
planted_during: "Phase 154 the control contract seam (v20.0) — planted at Plan 05 Task 1 as the named, explicit disposition of D-16, after the catalog guard made the gap countable rather than anecdotal"
trigger_when: "Surface whenever the Phase 153 iOS mirror train unblocks and a native release becomes affordable; whenever a ninth out-of-vocabulary denial string is proposed and the CatalogGuard allowlist goes red; whenever CTRL-02 is claimed as 'one vocabulary on the wire' rather than 'one typed denial at the adopter boundary'; or before any milestone that promises adopters a closed denial contract."
scope: Medium
---

# SEED-008: Bound the native denial vocabulary — both halves

## Thesis (read this first)

**Thesis (one sentence):** Crosswake claims a closed denial vocabulary, and on the wire it is
not one — eight fixed native strings sit outside `Crosswake.Shell.Denial`'s fourteen, and five
public delegate seams let any adopter host mint an unbounded ninth — so the work is to shrink
the fixed set to zero *and* convert the five seams from bare `String` to bounded enums.

**The reframe that matters:** these are **two different problems wearing one label**. The eight
fixed strings are a *bounded, countable, mechanically-guarded* debt: `Crosswake.Bridge.CatalogGuard`
enumerates them, justifies each, and goes red on a ninth. The five delegate seams are
*unbounded and not mechanically guardable at all* — no static enumeration can constrain a public
`String` field an adopter fills in. Fixing the first is a rename. Fixing the second is a
**BREAKING** change to public adopter-implemented types on both platforms. Do not let the first
half's tractability imply the second half is nearly done.

**What already shipped, so nobody re-solves it:** the *runtime* answer landed in Phase 154 Plan
03. `Crosswake.Bridge`'s reply decoder (`lib/crosswake/bridge.ex:687`) resolves an unknown reason
string to `:unavailable_capability`, preserves the raw value at `details.raw_reason`, and neither
crashes nor grows the atom table. Asserted by `test/crosswake/bridge/push_test.exs:308`. That
tolerance is required under *every* disposition of this seed — already-shipped shell binaries
emit the old strings forever, so the decoder can never be removed even after both halves are
retired.

## You Are Here — Decided / Open / Where to look

**Decided (Phase 154 Plan 05, Task 1 — human decision, option-b with amendment)**
- Land the guard NOW as a merge-blocking structural test with an **enumerated, seeded
  allowlist**, not later and not never. Zero native release coupling: D-01 holds, and Phase 153's
  mirror train (still NO-GO at v0.1.2) is not on this critical path.
- The allowlist enumerates **eight** strings, not the four the plan text originally claimed.
  Research confirmed eight are emitted today; shipping a four-entry allowlist would have gone red
  on day one and been "fixed" by padding — the exact failure mode option-b's own cons warn about.
- Each entry carries an **individual inline justification** in the guard source plus this seed's
  id. Adding a ninth must cost a written explanation in review.
- The five-seam unbounded problem is named in the guard's moduledoc as an **explicit,
  separately-labelled NON-MECHANICAL exclusion** — a sixth honest-labelling line alongside the
  (a)–(f) criteria — stating plainly that it is not mechanically enforceable and is carried here.
- Rejected: option-a (fix the natives now) — one-way door, changes public adopter types, and
  couples 154 to the blocked mirror train. Rejected: option-c (defer with no assertion) — a gate
  with no test is not a gate, and D-16 rejects it on its face.

**Open (decide at seed activation)**
- **Ordering.** Half one (rename the eight) is affordable the moment a native release is
  affordable. Half two (five seams to enums) needs a major-version story for adopters. They do
  not have to ship together, and probably should not.
- **What the closed vocabulary gains.** Several of the eight have no honest closed-vocabulary
  home today: `invalid_payload` is a *parse* failure and every existing reason is a *policy*
  outcome; `picker_in_progress` is a concurrency refusal the vocabulary does not model;
  `file_staging_failed` is an I/O failure. Retiring those eight likely means **adding two or
  three reasons to `Crosswake.Shell.Denial`**, not mapping all eight onto existing ones. Decide
  which, and remember every addition is itself a wire-contract change.
- **Whether the example hosts count.** Five of the eight come from `examples/ios_shell_host/`.
  They are host-authored — but committed, shipping in this repo, and the adopter-facing sample.
  Fixing core and leaving the sample emitting out-of-vocabulary strings teaches the wrong thing.
- **Enum vs. sealed-class shape on Kotlin, and the `RawValue` escape hatch on Swift.** An enum
  with no escape hatch is the point; an enum with a `case other(String)` case is the current
  problem with extra ceremony.

**Where to look**
- `lib/crosswake/bridge/catalog_guard.ex` — `@out_of_vocabulary_denial_allowlist`, the eight
  entries with sites and justifications; the moduledoc's non-mechanical-exclusion section.
- `test/crosswake/proof/phase154_catalog_guard_test.exs` — the merge-blocking subset assertion,
  its non-vacuity proof, and the test that asserts this seed enumerates all eight.
- `lib/crosswake/shell/denial.ex` — the fourteen-reason closed vocabulary (`@reasons`).
- `lib/crosswake/bridge.ex:687` — the shipped decoder tolerance.

## Half one — the eight fixed out-of-vocabulary strings

Bounded, countable, guarded. Retire by renaming to closed-vocabulary reasons (or by adding the
two or three missing reasons and then renaming), then deleting the entry from the guard's
allowlist in the same PR.

| # | String | Source | Site(s) | Why the closed vocabulary could not answer |
|---|--------|--------|---------|--------------------------------------------|
| 1 | `notification_status_unavailable` | core iOS | `BridgeChannel.swift:286` | Cannot resolve authorization status without prompting, and `notification_token` is contractually prompt-free. No closed reason separates "cannot answer without prompting" from "capability unavailable". |
| 2 | `notification_authorization_required` | core iOS | `BridgeChannel.swift:292` | Authorization must be resolved before token snapshot lookup. Distinct from `step_up_required`, which is auth-level escalation, not an OS permission grant. |
| 3 | `invalid_payload` | core Android | `BridgeChannel.kt:273`, `:284` | Malformed server-push payload (missing `name` / missing `state`). The vocabulary has **no malformed-request reason at all** — every entry describes a policy outcome, not a parse failure. |
| 4 | `notification_setup_missing` | example iOS host | `CrosswakeShellApp.swift:113` | App delegate reports registration state `unconfigured`. |
| 5 | `notification_token_unavailable` | example iOS host | `CrosswakeShellApp.swift:114` | Registration configured but no provider-tagged token snapshot yet. Sibling branch of the same ternary as #4. |
| 6 | `picker_unavailable` | example iOS host | `CrosswakeShellApp.swift:58`, `LiveViewContainerViewController.swift:78` | The picker coordinator is not attached to a presented view controller. A host *wiring* state, not a manifest *declaration* state — `undeclared_capability` would be actively misleading. |
| 7 | `picker_in_progress` | example iOS host | `LiveViewContainerViewController.swift:67` | A second `files.pick` arrived while one is presented. A concurrency refusal the vocabulary does not model. |
| 8 | `file_staging_failed` | example iOS host | `LiveViewContainerViewController.swift:185` | Copy-first staging of the picked file threw. An I/O failure; the vocabulary carries no I/O-failure reason. |

**Retirement test:** when half one is done, `CatalogGuard.out_of_vocabulary_denial_allowlist/0`
returns `[]` and the proof test's `length(allowlist) == 8` assertion is updated to `== 0` in the
same PR. Do not soften the assertion to `<= 8`; a range is how a countable debt becomes an
uncountable one.

## Half two — the five unbounded host-supplied delegate seams

Not mechanically guardable. No static enumeration bounds a public `String` field an adopter host
fills in, so the guard names these and stops — it does not pretend to cover them.

| # | Seam | Location | Shape |
|---|------|----------|-------|
| 1 | notification-token delegate denial | `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/CrosswakeDelegates.kt:39` | `data class Denied(val reason: String, val message: String, val hint: String)` |
| 2 | files-pick result denial | `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/FilesPickResult.kt:7` | `data class Denied(val reason: String, ...)` |
| 3 | notification-token snapshot | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:128` | `case unavailable(reason: String, detail: [String: String])` |
| 4 | command result denial | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:133` | `case deny(reason: String, message: String, hint: String)` |
| 5 | duplicated example-host copy of #1 | `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/CrosswakeDelegates.kt:39` | `data class Denied(val reason: String, ...)` |

**Retirement path:** convert all five `String` reason fields to bounded enums (Kotlin `enum class`
/ Swift `enum`) generated from or checked against `Crosswake.Shell.Denial`'s vocabulary, with no
`other(String)` escape case.

**This is a BREAKING change.** It alters public, adopter-implemented types on **both** platforms:
every host that implements `NotificationTokenDelegate`, returns a `FilesPickResult`, or
constructs a `CommandResult` must be recompiled and edited. It therefore requires a major native
version, a migration note, and a released mirror — which is why it is **gated on the Phase 153
mirror train** and explicitly not done in Phase 154 (D-01: 154 is not blocked by the mirror push,
and must not become blocked by it).

## Breadcrumbs

- **The tolerance is permanent, the fix is not retroactive.** Every shell binary already in the
  field emits the old strings forever. The decoder tolerance at `lib/crosswake/bridge.ex:687`
  survives both halves' retirement. Do not delete it as "no longer needed".
- **The eight are the *statically extractable* set.** `CatalogGuard.extract_native_denial_reasons/1`
  recognises a reason literal only when it is lowercase with at least one underscore, and it
  extracts nothing when the reason argument is a variable — which is precisely half two. A
  single-word reason literal would slip past. Named in the guard's moduledoc, repeated here.
- **Cross-native enum drift, noticed in passing.** The iOS enum carries
  `connection.state.update` where the Kotlin enum carries `server.state.update` for what appears
  to be the same outbound connection-state fan-out. Both are exempt from orphan detection as
  outbound-only pushes, so the guard does not fire — but the two natives disagree on a wire
  string. Not this seed's problem; recorded so it is not rediscovered as a surprise.
- **CTRL-02's honest claim until this seed is worked** is "one typed denial at the adopter
  boundary", not "one vocabulary on the wire". The `Crosswake.Shell.Denial` struct really is the
  single typed shape every adopter sees, because the decoder normalises into it. What is not yet
  true is that the *native emitters* only ever speak the closed vocabulary.
