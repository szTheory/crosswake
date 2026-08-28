---
phase: 154-the-control-contract-seam
plan: 05
subsystem: bridge
tags: [elixir, ast-guard, structural-test, proof-lane, ctrl-04, proof-04, ctrl-02, seed]

# Dependency graph
requires:
  - phase: 154-the-control-contract-seam (154-02, 154-03)
    provides: "Capability.rebuild/interaction on the Manifest.Builder capability catalog
      (the attestation file this guard reads rather than duplicating), and the
      :shell_unreachable denial reason plus the reply decoder's unknown-string tolerance
      that makes the D-16 allowlist safe to defer"
provides:
  - "Crosswake.Bridge.CatalogGuard — the catalog line as a callable rule in lib/, not
    test/: eleven pure check_* predicates plus assert_catalog_closed!/0, callable from
    the proof lane and from doctor, so deleting the test does not delete the rule (D-43)"
  - "check_source/1 as a REPORT, not a short-circuit — a source violating six criteria
    reports all six, asserted as a set-completeness check so prewalk accumulation order
    is never load-bearing (D-46)"
  - "Bidirectional native command enum parity against BOTH native sources, with gap and
    orphan detection and an enumerated three-entry outbound-only exemption; an
    unlocatable enum block is a FAILURE, never a vacuous pass (Phase 134 carry-forward)"
  - "The D-16 disposition, landed: an eight-entry enumerated allowlist of shipping
    out-of-vocabulary native denial reasons, each with its sites, an individual inline
    justification, and the SEED-008 id. A NINTH turns the merge-blocking gate red."
  - "An explicit, separately-labelled NON-MECHANICAL exclusion naming all FIVE bare-String
    delegate seams, with a proof test asserting all five are named and that the guard
    states plainly it cannot enforce them"
  - "test/crosswake/proof/phase154_catalog_guard_test.exs — the merge-blocking PROOF-04
    gate, untagged, riding the existing hermetic lanes with zero new workflow files and
    zero new required checks (D-47)"
  - "D-56's frozen outcome-vocabulary guard over the bridge tree and the committed
    contract vectors, with its own non-vacuity and no-false-positive controls"
  - ".planning/seeds/SEED-008-native-denial-vocabulary.md — both halves of the deferral:
    the eight fixed strings and the five unbounded delegate seams"
  - "The three committed bridge_contract_vectors.json copies regenerated for
    :shell_unreachable, clearing a contract-drift-gate red that 154-03 left behind"
affects: [154-06, 154-07, 154-08, 155]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "The guard reads the attestation file that already exists (Manifest.Builder's
      capability catalog, via the public capability_registry/1 with an empty route list)
      rather than minting a second catalog — a second file here would be FIVE-way drift:
      new file, catalog, command list, capability-command map, and two native enums (D-42)"
    - "Balanced-delimiter scanning (a small string-aware paren/brace walker) rather than
      regex windows for extracting native denial reasons and enum blocks — this is what
      makes 'the FIRST reason-shaped literal inside a balanced deny( call' a precise rule
      instead of a heuristic, and what makes a variable-valued reason extract nothing
      rather than capturing a neighbouring prose literal"
    - "A reason literal is recognised only when lowercase AND containing at least one
      underscore. All 14 closed-vocabulary reasons and all 8 allowlist entries have that
      shape; the underscore requirement is what excludes detail-key literals like
      \"unconfigured\" that would otherwise have forced a ninth allowlist entry on day one"
    - "Allowlist LIVENESS as a first-class check: check_denial_allowlist_liveness/0 fails
      when an entry is no longer emitted at any declared site, so a fixed string cannot
      leave rot behind that makes the debt look larger than it is"
    - "Honest labelling asserted mechanically — the proof lane greps the guard's own
      moduledoc for MECHANICAL ONLY IN THE NEGATIVE / HYBRID / MECHANICAL BY PROXY /
      'does **not** stop', so the anti-overclaim requirement cannot silently rot out"

key-files:
  created:
    - lib/crosswake/bridge/catalog_guard.ex
    - test/crosswake/bridge/catalog_guard_test.exs
    - test/crosswake/proof/phase154_catalog_guard_test.exs
    - .planning/seeds/SEED-008-native-denial-vocabulary.md
  modified:
    - test/fixtures/bridge_contract_vectors.json
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json
    - packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json

decisions:
  - "D-16 resolved by the human as OPTION-B WITH AN AMENDMENT: land the guard now as a
    merge-blocking structural test with an enumerated, seeded allowlist of EIGHT (not
    four) strings; zero native release coupling so D-01 holds; the five-seam unbounded
    delegate problem named as a separately-labelled non-mechanical exclusion rather than
    pretended into the allowlist"
  - "The allowlist is exactly eight and the proof test asserts == 8, not <= 8 — a range is
    how a countable debt becomes an uncountable one"
  - "Three native enum cases (connection.state.update, server.event.push,
    server.state.update) are enumerated as outbound-only and exempt from orphan detection
    — they are server->shell pushes with no inbound bounded-bridge request seam"
  - "The contract-vector regen was committed SEPARATELY from Tasks 2 and 3, per the
    human's instruction, because it is pre-existing 154-03 drift and not this plan's work"

metrics:
  duration: ~55 min
  completed: 2026-07-29
status: complete
---

# Phase 154 Plan 05: The Catalog-Line Structural Guard Summary

`Crosswake.Bridge.CatalogGuard` makes CTRL-04 mechanically true for the plugin-catalog road and
honest in writing about the two criteria it cannot mechanise — plus the eight-string, seed-tagged
disposition of D-16 that the human chose deliberately rather than the executor discovering it.

## Task 1 — the D-16 checkpoint, resolved by the human

Recorded verbatim, because this plan exists to make the disposition explicit rather than
discovered.

> **Selected: option-b, with an amendment.**
>
> Land the guard now as a merge-blocking structural test with an enumerated, seeded allowlist.
> Zero native release coupling (D-01 holds — Phase 153's mirror train is still NO-GO at v0.1.2 and
> must not be coupled to). The runtime answer already shipped via Plan 03's decoder at
> `lib/crosswake/bridge.ex:687` (unknown string → `:unavailable_capability`, raw value preserved at
> `details.raw_reason`, no crash, no atom-table growth; asserted by
> `test/crosswake/bridge/push_test.exs:308`).
>
> **The amendment — this is binding and differs from the plan text:**
>
> 1. The plan says the allowlist enumerates FOUR known out-of-vocabulary strings. That is
>    factually short. Research confirmed **eight** strings are emitted today. The allowlist MUST
>    enumerate all eight, or the guard goes red on day one and gets "fixed" by padding — the exact
>    failure mode option-b's own cons warn about. Verify each against the source before writing it
>    in; if your own reading disagrees with this list, trust the source and say so in the summary.
>
>    Core libraries: `notification_status_unavailable` (`BridgeChannel.swift:286`),
>    `notification_authorization_required` (`BridgeChannel.swift:292`), `invalid_payload`
>    (`BridgeChannel.kt:271` and `:282`, two call sites).
>
>    Example/adopter hosts (host-supplied, but committed and shipping in this repo):
>    `notification_setup_missing`, `notification_token_unavailable`
>    (`CrosswakeShellApp.swift:113-116`), `picker_unavailable` (`CrosswakeShellApp.swift:58` and
>    `LiveViewContainerViewController.swift:78`), `picker_in_progress`
>    (`LiveViewContainerViewController.swift:67`), `file_staging_failed`
>    (`LiveViewContainerViewController.swift:154` — verify exact line).
>
>    Each entry gets an individual inline justification in the guard source plus the SEED-008 id,
>    per option-b's stated mitigation. The guard goes red on a NINTH.
>
> 2. **The unbounded host-supplied seam is NOT allowlistable and must not be pretended into the
>    allowlist.** It is five delegate seams wide, not one: `CrosswakeDelegates.kt:39`
>    (`data class Denied(val reason: String, ...)`), `FilesPickResult.kt:7`,
>    `BridgeChannel.swift:128` (`case unavailable(reason: String, detail:)`),
>    `BridgeChannel.swift:133` (`case deny(reason:message:hint:)`), and the duplicated example-host
>    copy at `examples/android_shell_host/.../CrosswakeDelegates.kt:39`. Any adopter host can mint
>    an arbitrary reason there, so no static enumeration can bound it.
>
>    Name this in the guard moduledoc as an **explicit, separately-labelled non-mechanical
>    exclusion** — a sixth honest-labelling line alongside the plan's (a)–(f) criteria, stating
>    plainly that this sub-assertion is NOT mechanically enforceable and is carried by SEED-008
>    rather than by the guard. Do not let the six-criteria block imply coverage it does not have.
>    The teaching heredoc's callout about the bare-string Kotlin delegate must enumerate all five
>    seams, not just the one.
>
> 3. SEED-008 carries BOTH halves: the eight-string allowlist (retire it by bounding the fixed
>    literals) AND the five-seam unbounded delegate problem (retire it by converting the public
>    `String` reason fields to bounded enums — note in the seed that this is a BREAKING change to
>    public adopter-implemented types on both platforms and is gated on the Phase 153 mirror train,
>    which is why it is not done in 154).

Options A and C were not selected. Option A (fix the natives now) was rejected as a one-way door
that changes public adopter-implemented types and couples 154 to the still-blocked mirror train,
contradicting D-01. Option C (defer with no assertion) was rejected on its face by D-16 and by this
project's own gate discipline: a gate with no test is not a gate.

### Source verification of the eight — three line corrections

The human's instruction was to trust the source over the list. All eight strings are real and
confirmed present. Three site references differ from the amendment text:

| Entry | Amendment said | Source says | Note |
|---|---|---|---|
| `invalid_payload` | `BridgeChannel.kt:271` and `:282` | **`:273` and `:284`** | Two call sites confirmed; both two lines later than stated. |
| `file_staging_failed` | `LiveViewContainerViewController.swift:154` (flagged "verify exact line") | **`:185`** | Line 154 is `undeclared_capability`, which IS in vocabulary. The human's own flag was correct to doubt it. |
| example Android delegate seam | `examples/android_shell_host/.../shell/core/CrosswakeDelegates.kt:39` | **`.../shell/CrosswakeDelegates.kt:39`** | The example-host copy has no `core` path segment. |

`notification_setup_missing` / `notification_token_unavailable` are at `CrosswakeShellApp.swift:113`
and `:114` — the two branches of one ternary, consumed by `.unavailable(reason:detail:)` at `:116`,
which matches the amendment's "113-116" range. The guard records the corrected lines.

The eight were independently re-derived, not merely accepted: a balanced-delimiter extractor was
run over the four native emission sources before any code was written, and it produced exactly the
human's eight and nothing else. The extractor initially also produced `"unconfigured"` — a
detail-key literal inside a `deny(request, reason: reason, ...)` call whose reason is a *variable*
(seam 4 of the five). Requiring at least one underscore in a reason-shaped literal removed it. Had
that false positive shipped, it would have forced a ninth allowlist entry on day one, which is
precisely the padding failure the amendment exists to prevent.

## Task 2 — `Crosswake.Bridge.CatalogGuard`

`lib/crosswake/bridge/catalog_guard.ex`, TDD (RED commit `1ef6e714`, GREEN commit `49a3744d`).

Eleven pure `check_*` predicates plus `assert_catalog_closed!/0`, mirroring `CompanionGuard`'s
`Code.string_to_quoted/2` + `Macro.prewalk/3` shape with no new dependency.

**The six criteria, labelled honestly in the moduledoc (D-44, D-45):**

| Criterion | Label | Mechanism |
|---|---|---|
| (a) route-local and declarable | MECHANICAL | `check_attestation/3`, bidirectional |
| (b) low-frequency | **MECHANICAL ONLY IN THE NEGATIVE** | `check_no_streaming_seam/1` proves no seam exists; it cannot prove nobody loops |
| (c) zero external SDK | MECHANICAL | AST allowlist walk over `alias`/`import`/`require`/`use` |
| (d) semantically bounded | MECHANICAL | literal command list, no `register_*`, no `apply`, no atom minting, bidirectional native enum parity |
| (e) fails closed | **HYBRID** | this phase asserts the declaration; Phase 155's PROOF-01 asserts it renders |
| (f) backend-authoritative | **MECHANICAL BY PROXY** | inherited from the frozen `Bridge.Reply` field set (Plan 03) |

Plus the amendment's sixth line, deliberately outside that block: the **non-mechanical exclusion**
naming all five bare-`String` delegate seams and stating in as many words that the sub-assertion is
"NOT mechanically enforceable" and is carried by SEED-008, not by the guard.

`check_source/1` is a report: a six-violation fixture returns all six criteria, asserted as a
`MapSet` equality so accumulation order is never load-bearing. An unparseable source fails closed
as `{:unparseable_source, _}` rather than passing.

The failure message keeps `[proof.ctrl_04.catalog_closed.<criterion>] subject= source= observed=
path= hint= posture=merge_blocking` on line 1, then a teaching heredoc: the Cordova plugin-catalog
precedent, an explicit restatement of what the gate does NOT do (D-45), the six-step recipe for
adding the next control, the five-seam callout, and the close — *"This gate does not exist to stop
the next control. It exists to make the next control look exactly like the existing ones."* (D-48).

## Task 3 — the PROOF-04 gate and SEED-008

`test/crosswake/proof/phase154_catalog_guard_test.exs` and
`.planning/seeds/SEED-008-native-denial-vocabulary.md`, commit `50edd4e6`.

31 tests, 34 `ProofAssertions.stable_id_message/7` calls, `async: true`, zero `@moduletag`, zero
new workflow files (40 before, 40 after; `git status --porcelain .github/workflows/` empty). The
last test in the file asserts the file itself carries no module tag, which is what makes the
no-new-workflow claim self-verifying (D-47).

**Four kinds of negative control (D-46):** the six-at-once completeness fixture plus an
order-independence assertion; one inline synthetic per mechanical sub-assertion (six of them); the
real-shipped-source positive controls on `builder.ex`, the whole bridge tree, and
`assert_catalog_closed!/0`; and attestation gap + orphan, both synthetic and against the real
command vocabulary.

**The native denial subset assertion is NON-VACUOUS** and proven so four ways: a synthetic
`"wallet_locked"` turns it red; the allowlist is asserted to be exactly eight with every entry
justified, sited and seed-tagged; `check_denial_allowlist_liveness/0` fails on a stale entry; and
a test greps the guard source for all five seam references plus the literal phrase "NOT
mechanically enforceable", so the honest labelling cannot rot out silently.

**D-56's outcome-vocabulary guard** scans the bridge tree and the committed vectors for
completion-claiming outcome values (`completed`/`accepted`/`shared`/`succeeded`), with a non-vacuity
control proving the scan detects one and a no-false-positive control proving it does not mistake
the vectors' `expected_outcome` assertion field for a wire outcome value. The typed `Outcome` sum
type remains Phase 157.

**SEED-008** carries both halves explicitly: the eight-string table with per-entry justification and
retirement test (`allowlist == []`, and update the proof assertion to `== 0`, never soften to
`<= 8`), and the five-seam table with the retirement path named as a **BREAKING** change to public
adopter-implemented types on both platforms, gated on the Phase 153 mirror train.

## Additional scope folded in — the contract-vector regen

Commit `77f59868`, deliberately separate from Tasks 2 and 3 because it is pre-existing 154-03 drift.

154-03 added `:shell_unreachable` to `Crosswake.Shell.Denial` (13 → 14 reasons) without
regenerating the three committed copies of `bridge_contract_vectors.json`, leaving
`contract-drift-gate.yml` red. `mix crosswake.contract.gen` produced a diff of exactly one added
line per file — `"shell_unreachable"` appended to `denial_reasons` in the canonical fixture, the
iOS test resource, and the Android test resource. Nothing else changed; `route_activation.json` and
`docs/_contract_snippet.md` were reported unchanged by the generator. No unexpected churn, so it
was committed rather than escalated.

## Deviations from Plan

### Auto-fixed / adjusted

**1. [Rule 1 — Bug] Three site line numbers in the human's amendment corrected against source.**
- **Found during:** Task 1 verification, before any code was written.
- **Issue:** `invalid_payload` at `:271`/`:282`, `file_staging_failed` at `:154`, and the example
  Android delegate path containing a `core` segment.
- **Fix:** Corrected to `:273`/`:284`, `:185`, and `.../shell/CrosswakeDelegates.kt:39`. The human
  explicitly instructed "trust the source and say so in the summary".
- **Files:** `lib/crosswake/bridge/catalog_guard.ex`, `.planning/seeds/SEED-008-native-denial-vocabulary.md`
- **Commit:** `49a3744d`, `50edd4e6`

**2. [Rule 2 — Missing critical functionality] Extractor underscore requirement.**
- **Found during:** Task 2 prototyping.
- **Issue:** A loose lowercase-token match captured `"unconfigured"` — a detail-key literal in a
  variable-valued `deny(...)` call — producing a false ninth out-of-vocabulary string.
- **Fix:** Reason-shaped literals must contain at least one underscore. The limitation (a
  single-word reason would slip past) is named in the guard's moduledoc rather than hidden.
- **Commit:** `49a3744d`

**3. [Rule 2 — Missing critical functionality] `check_denial_allowlist_liveness/0` added.**
- **Not in the plan.** An allowlist that only checks one direction rots: an entry whose string is
  later fixed stays forever, making the recorded debt look larger than the real debt and quietly
  widening the gate. The liveness check fails when an entry is no longer emitted at any declared
  site, so retiring an entry is forced to include deleting it.
- **Commit:** `49a3744d`

**4. [Rule 3 — Blocking] Outbound-only native enum exemption.**
- **Found during:** Task 2. The plan's bidirectional parity assertion would have gone red on day
  one: the iOS enum carries 12 cases and the Kotlin enum 12, against 10 Elixir commands. The extras
  are server→shell outbound pushes with no inbound bounded-bridge request seam.
- **Fix:** `@outbound_only_native_commands` — a three-entry enumerated exemption with a per-entry
  comment, not a pattern match. Enumerated so a fourth outbound command is still a review event.
- **Commit:** `49a3744d`

### Not fixed — recorded

**Cross-native enum drift.** The iOS enum carries `connection.state.update` where the Kotlin enum
carries `server.state.update`, apparently for the same outbound connection-state fan-out. Both are
outbound-only and therefore exempt from orphan detection, so the guard does not fire — but the two
natives disagree on a wire string. Fixing it means editing a native source, which is exactly the
D-01 coupling the Task 1 decision rejected. Recorded in SEED-008's Breadcrumbs so it is not
rediscovered as a surprise.

## Known Stubs

None. Every check ships wired to real sources, and the two checks that are currently green with no
subject in the tree (`check_no_atom_minting/1` and D-56's outcome scan, both of which find nothing
because the tree genuinely contains nothing) each carry an explicit non-vacuity control proving the
check fires on a synthetic violation.

## Threat Flags

None. This plan adds no network endpoint, auth path, file-access pattern, or schema change. It adds
one read-only AST/source scanner and one test file.

## Verification

| Check | Result |
|---|---|
| `mix test test/crosswake/bridge/catalog_guard_test.exs` | 50 tests, 0 failures |
| `mix test test/crosswake/proof/phase154_catalog_guard_test.exs` | 31 tests, 0 failures |
| `mix test` (full) | **1214 tests, 0 failures** (61 excluded) |
| `mix test --exclude requires_example_host --exclude advisory_only` | 1214 tests, 0 failures |
| `mix compile --warnings-as-errors --force` | exit 0 |
| `git status --porcelain .github/workflows/` | empty — no new workflow file |
| `ls .github/workflows/ \| wc -l` | 40, unchanged |
| `grep -c 'ProofAssertions.stable_id_message'` on the proof file | 34 (≥ 8 required) |
| `grep -cE '^\s*@moduletag\s+:'` on the proof file | 0 |

### Suite wall-clock against the Phase 153.1 baseline (D-47, T-154-22)

| Measurement | Value |
|---|---|
| Phase 153.1 CI time-to-green baseline | 5.8 min |
| Local hermetic suite, `mix test` (ExUnit-reported) | **42.5 s** (30.3 s async, 12.2 s sync) |
| Local hermetic suite, wall clock incl. compile | **43 s** |
| `mix test --exclude requires_example_host --exclude advisory_only`, ExUnit-reported | **40.0 s** |
| `mix test --exclude requires_example_host --exclude advisory_only`, wall clock | **41 s** |
| Cost of this plan's 81 new tests | ~0.2 s combined (both files finish in under 0.1 s each) |

The 5.8-minute figure is CI time-to-green (queue + runner + all lanes), not local suite time; the
local number is the component this plan could regress and it did not. 81 tests were added for
roughly two tenths of a second, entirely inside the existing hermetic step, with no new workflow
file and no new required check. The baseline is defended with measurement rather than assumption.

### Known flake, not hit

`test/crosswake/manifest/validator_test.exs` can fail on stale `crosswake-manifest-*.json` files in
`$TMPDIR` (see `deferred-items.md`). `$TMPDIR` was cleared before the full run as a precaution; the
flake did not occur and was not chased.

## TDD Gate Compliance

| Gate | Commit | Evidence |
|---|---|---|
| RED | `1ef6e714` `test(154-05): ...` | 50 tests, 50 failures — the module did not exist |
| GREEN | `49a3744d` `feat(154-05): ...` | 50 tests, 0 failures |
| RED (Task 3) | folded into `50edd4e6` | the proof file failed on `proof.ctrl_02.seed_008.exists` until SEED-008 was written; captured in-run rather than as a separate commit, since the human's hard constraint was one atomic commit per task |
| REFACTOR | none needed | no cleanup pass produced changes |

## Commits

| Commit | Type | Description |
|---|---|---|
| `1ef6e714` | test | RED: 50 failing predicate tests for `CatalogGuard` |
| `49a3744d` | feat | Task 2 — `Crosswake.Bridge.CatalogGuard` |
| `50edd4e6` | feat | Task 3 — PROOF-04 gate + SEED-008 |
| `77f59868` | chore | contract-vector regen for `shell_unreachable` (separate, per instruction) |

## Self-Check: PASSED

All five created files exist on disk and all four commit hashes resolve in `git log`.
