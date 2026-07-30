---
phase: 154-the-control-contract-seam
plan: 08
subsystem: docs
tags: [guides, honest-claims, generated-docs, checkpoint, human-verification]

requires:
  - phase: 154-the-control-contract-seam
    provides: "Plan 03's Crosswake.Bridge facade, Bridge.Reply, and the :shell_unreachable denial reason"
  - phase: 154-the-control-contract-seam
    provides: "Plan 04's epoch tracking, resolve/2, and the server-armed reply backstop"
  - phase: 154-the-control-contract-seam
    provides: "Plan 05's CatalogGuard, the eight-string allowlist, and the D-16 option-b disposition carried by SEED-008"
  - phase: 154-the-control-contract-seam
    provides: "Plan 06's library-owned hook, install patcher, and the iOS return leg that is in-repo but not yet in adopters' hands"
  - phase: 154-the-control-contract-seam
    provides: "Plan 07's AdminPilot migration onto the seam, the evidence panel, and Bridge.dispatched/2"
provides:
  - "guides/bridge.md: reconnect semantics, dispatched/2, shell_unreachable in the denial list, and a Guarantee Strength table naming what is structural versus CI-caught"
  - "guides/compatibility.md: the shell_unreachable boundary (core-minted, no companion Finding axis) and the recorded D-16 disposition"
  - "guides/adopter_profiles.md: the attach requirement, stated per profile including the honest 'none today' case"
  - "guides/web_to_mobile_migration.md: the inline-script-to-seam migration, framed as CSP hardening, in four steps"
  - "SupportMatrix.Renderer: the guarantee-strength paragraph, so the regenerated matrix carries it too"
affects: [155, 156]

tech-stack:
  added: []
  patterns:
    - "When a mechanical negative gate forbids a token, rewrite the warning that names the token rather than deleting the warning — the teaching survives, the copyable token does not"
    - "Byte-generated guides are edited at the renderer and regenerated, never by hand"
    - "Guarantee strength gets a table with a 'true strength' column, so the weaker true form is structurally hard to omit"

key-files:
  created:
    - .planning/phases/154-the-control-contract-seam/154-08-SUMMARY.md
  modified:
    - guides/bridge.md
    - guides/compatibility.md
    - guides/adopter_profiles.md
    - guides/web_to_mobile_migration.md
    - guides/support_matrix.md
    - lib/crosswake/support_matrix/renderer.ex
  deleted: []

key-decisions:
  - "The sentence warning against an availability pre-check was rewritten rather than deleted. It named `available?/2` and `connected?/1`, which the plan's own negative gate counts as teaching the pre-check. The warning is the most valuable line in that section, so the fix was to keep the teaching and drop the tokens — not to weaken the guide to satisfy a grep."
  - "The structural-versus-CI-caught distinction landed in BOTH guides/bridge.md (a table, where adopters read) and guides/support_matrix.md via the renderer (beside the CTRL-05 enforce-keys claim, where the claim is actually made). The acceptance criterion only required one; putting it beside the claim is what T-154-34 is really asking for."
  - "guides/support_matrix.md was regenerated from SupportMatrix.Renderer, never hand-edited — renderer_test.exs asserts byte parity and is merge-blocking."
  - "CTRL-02 stays scoped in the guides as 'one typed denial at the adopter boundary'. The compatibility guide states the gap explicitly — eight fixed native strings plus five unbounded delegate seams — and cites SEED-008 as what a reviewer should point at if a future claim upgrades this to 'one vocabulary on the wire'."
  - "HRDN-01 is stated nowhere in the guides as 'the last inline-script allowance is gone'. The migration guide frames it as bridge dispatch no longer rendering a server-built payload into an inline script, because examples/phoenix_host/lib/crosswake_example/layouts.ex:25 still carries the standard Phoenix LiveSocket bootstrap as an inline module script."
  - "Bridge.dispatched/2 was documented even though the plan did not name it (Rule 2). It shipped as public API in Plan 07 and its own moduledoc warns it is not an availability predicate — leaving it undocumented in the seam guide is how a reader reinvents the pre-check the guide just forbade."

patterns-established:
  - "A 'true strength' column: the table forces the weaker form into a cell rather than letting prose round it up"

requirements-completed: []
requirements-partial: [CTRL-01, CTRL-02, CTRL-05, HRDN-01]

status: in-progress-checkpoint-open
---

# Phase 154 Plan 08: Honest-Claims Documentation Sweep Summary

Five guides now state the weaker true form of every Phase 154 claim — one push and one
reply clause with no pre-check, reconnect semantics named rather than left to assumption,
and the structural-versus-CI-caught line drawn where adopters read it. **The phase's human
verification gate (Task 2) is still open.**

## Status: Task 1 complete, Task 2 checkpoint OPEN

| Task | Type | Status | Commit |
|------|------|--------|--------|
| 1 — the honest-claims documentation sweep | auto | complete | `26720633` |
| 2 — human verification of the panel, doctor, and guard message | checkpoint:human-verify (gate=blocking) | **AWAITING HUMAN** | — |

Task 2 is the only thing between this plan and phase closure. Everything that does not
depend on the human's answer is done, committed, and green.

## What Task 1 changed

### `guides/bridge.md`

- **The pre-check warning was rewritten, not deleted.** It previously read "There is
  deliberately no `available?/2` or `connected?/1`" — the best sentence in that section,
  and the one the plan's negative acceptance gate counted as a violation. It now warns
  against a presence predicate without naming one. Same teaching, no copyable token.
- **Reconnect semantics got their own section**, stated as an imperative rather than a
  footnote: a reconnect is a fresh mount, a fresh `attach/1`, a fresh epoch; the previous
  epoch's in-flight table dies with the process; a late reply drops as foreign-epoch
  because delivering it would hand a new page a stale answer to a question it never posed.
  The recovery path — rebuild from assigns, do not resurrect the ask — is named, with
  Phase 155's generated fallback components as what ships the wiring.
- **`dispatched/2` documented** as the envelope read-back path, with its own moduledoc's
  warning carried across: it is not a presence predicate, and branching on it cannot skip
  the reply.
- **`shell_unreachable` added to the denial list** (it was missing) with its four failing
  moments and a pointer to the compatibility guide's boundary section.
- **A new "Guarantee Strength" section** with a three-row table whose middle column is
  literally headed "True strength": enforce-keys is `Structurally impossible to violate`;
  the bounded-bridge criteria are `CI-caught, not structural`, with D-45's point written
  out — the guard does not stop a maintainer adding forty controls one honest string at a
  time; and the one-typed-reply claim is scoped to the adopter boundary.

### `guides/compatibility.md`

- **`## The shell_unreachable Boundary`** — the 14th reason documented as core-minted with
  no companion `Finding` axis, and the reason a companion cannot honestly return it (a
  companion that ran far enough to form an opinion is by construction reachable). The four
  `details.failing_moment` values are listed with the operator-versus-adopter split.
- **The D-16 disposition recorded** as Plan 05's checkpoint resolved it: eight fixed
  out-of-vocabulary strings (enumerated and guarded, a ninth turns the gate red) plus five
  unbounded host-supplied delegate seams (explicitly non-mechanical); the server's
  permanent tolerance (unknown reason → `unavailable_capability`, raw preserved at
  `details.raw_reason`, no atom minted) and why it can never be removed; and SEED-008 as
  the tracker, named as what a reviewer should cite if a future claim inflates.
- **Failure Posture** gained the "no configuration in which a bridge push resolves to
  silence" line.

### `guides/adopter_profiles.md`

- **`## The Attach Requirement`** before the profiles, with the `mount/3` snippet, the
  `on_mount` ordering caveat, and the reason the error is loud rather than a silent no-op.
- **Per profile:** SaaS Portal attaches on the one approval-detail route; Selective Native
  Flow attaches on each `:live_view` route dispatching a transfer seam and explicitly not
  on the `:native_screen` route; Local-First Study Flow has **no attach step today** and
  the guide says so rather than inventing one for symmetry.
- Added to the SaaS Portal's degraded behavior: the desktop-browser case resolves to one
  typed `shell_unreachable` denial and the approval stands.

### `guides/web_to_mobile_migration.md`

- **`#### Migrating an existing hand-rolled bridge call`** — before/after code, framed as
  CSP hardening first because that is the honest headline benefit, in four steps (wire the
  hook, attach at mount, replace dispatch with `Crosswake.Bridge.push/3`, add one
  `handle_info/2` clause only if the control answers). Closes with the warning not to keep
  the old path as a fallback around the new one.
- The "after" claim is scoped to bridge dispatch, per 154-07's recorded decision — the
  guide does not claim the last inline-script allowance is gone, because
  `examples/phoenix_host/lib/crosswake_example/layouts.ex:25` still carries the standard
  Phoenix LiveSocket bootstrap as an inline module script.

### `guides/support_matrix.md` (generated) + `lib/crosswake/support_matrix/renderer.ex`

The guide is byte-generated and `renderer_test.exs` asserts byte parity as a merge-blocking
check, so the guarantee-strength paragraph was added to
`Renderer.interaction_class_legend_section/0` and the guide regenerated with
`Renderer.render(SupportMatrix.canonical())`. It sits directly beneath the CTRL-05
enforce-keys sentence — beside the claim rather than in a separate section — and links to
the bridge guide's table. The four locked change-class strings and the Phase 156 iOS reply
statement both survive untouched.

## Acceptance criteria (all mechanically verified)

| Criterion | Required | Actual |
|-----------|----------|--------|
| `grep -c 'shell_unreachable' guides/compatibility.md` | ≥ 1 | 4 |
| `grep -ci 'reconnect' guides/bridge.md` | ≥ 1 | 4 |
| `grep -c 'resolve' guides/bridge.md` | ≥ 1 | 12 |
| `grep -ci 'attach' guides/adopter_profiles.md` | ≥ 1 | 12 |
| `grep -c 'Crosswake.Bridge.push' guides/web_to_mobile_migration.md` | ≥ 1 | 2 |
| `grep -ci 'available?\|connected?'` across bridge / adopter_profiles / web_to_mobile | 0 all three | 0, 0, 0 |
| `grep -c 'compatibility-bump only' guides/support_matrix.md` | ≥ 1 | 5 |
| `grep -ci 'CI-caught\|caught in CI'` across support_matrix + bridge | ≥ 1 | 1 + 3 |
| `mix test test/crosswake/guides/` | exit 0 | pass |
| `mix docs` | exit 0 | exit 0 |

## Verification gate — real numbers

| Suite | Command | Result |
|-------|---------|--------|
| Core hermetic | `mix test` | **1236 tests, 0 failures** (61 excluded) — matches baseline exactly |
| Core compile | `mix compile --warnings-as-errors` | exit 0 |
| Guides + parity subset | `mix test test/crosswake/guides/ test/crosswake/proof/phase69_docs_contract_parity_test.exs test/crosswake/hex_page_test.exs test/crosswake/support_matrix/` | 246 tests, 0 failures (7 excluded) |
| Example host | `cd examples/phoenix_host && mix test` | **95 tests, 0 failures** — matches baseline |
| Example host compile | `cd examples/phoenix_host && mix compile --warnings-as-errors` | exit 0 |
| JS hook | `node --test "test/js/*.mjs"` | **22 tests, 0 failures** |
| Route tour | `cd examples/phoenix_host && npx playwright test route_tour.spec.ts` | **7 passed**, chromium |
| Docs | `mix docs` | exit 0 |

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] The pre-check warning tripped the plan's own negative gate.**
- **Found during:** Task 1, baseline grep before editing.
- **Issue:** `guides/bridge.md:70` read "There is deliberately no `available?/2` or
  `connected?/1`" — which is the *opposite* of teaching a pre-check, but matches the
  acceptance criterion's negative pattern and would have shipped a copyable token an
  adopter could search for.
- **Fix:** Rewrote the sentence to warn against a presence predicate without naming one,
  preserving the anti-pattern teaching in prose (not in a copyable code fence).
- **Files modified:** `guides/bridge.md`. **Commit:** `26720633`.

**2. [Rule 2 — Missing critical functionality] `shell_unreachable` was absent from the
bridge guide's denial list.**
- **Found during:** Task 1.
- **Issue:** The guide listed six denial reasons; the seam's own headline reason — the one
  every desktop-browser adopter receives on their first push — was not among them. A reader
  matching on the documented list would have no clause for the case they will hit first.
- **Fix:** Added it with its four failing moments and the core-minted boundary pointer.
- **Files modified:** `guides/bridge.md`, `guides/compatibility.md`. **Commit:** `26720633`.

**3. [Rule 2 — Missing critical functionality] `Bridge.dispatched/2` was undocumented.**
- **Found during:** Task 1, reading the shipped signatures.
- **Issue:** It shipped as public API in Plan 07 and its own moduledoc carries a warning
  that it is not an availability predicate. Public API with a misuse warning, absent from
  the seam guide, is how a reader reinvents the pre-check the same guide forbids.
- **Fix:** Documented in `guides/bridge.md` with the not-a-predicate warning carried across.
- **Files modified:** `guides/bridge.md`. **Commit:** `26720633`.

**4. [Rule 3 — Blocking] The checkpoint's verification recipe could not produce the panel.**
- **Found during:** Task 2 preparation.
- **Issue:** The plan says `mix phx.server` (i.e. `MIX_ENV=dev`). In dev the session
  defaults to `member-1`, whose role is `:member`, so clicking Approve returns
  `{:error, :forbidden}` and renders "Approver role required" — the evidence panel under
  test never appears. Separately the `/_e2e` scope is compile-time gated to
  `Mix.env() in [:test, :e2e]`, so dev has no way to become `approver-1`; and a freshly
  migrated DB has no approvals, so `/saas/approvals/approval-1` returns 500 until
  `/_e2e/showcase-reset` seeds it.
- **Fix:** No code change. The server was started in the environment Playwright itself
  uses (`MIX_ENV=test`, port 4700), seeded, and the corrected recipe is carried in the
  checkpoint. Documented here so the next reader does not rediscover it.
- **Files modified:** none.

**5. [Rule 3 — Blocking] `mix crosswake.doctor` at the repo root cannot run.**
- **Found during:** Task 2 preparation.
- **Issue:** The plan's step 7 says run doctor at the repo root. It exits 1 immediately
  with `pass --router Elixir.YourAppWeb.Router so doctor can compile Crosswake policy` —
  the core repo has no adopter router to inspect.
- **Fix:** No code change. Doctor was run against the example host's router instead, which
  is where the two Phase 154 findings actually appear. Corrected command in the checkpoint.
- **Files modified:** none.

### Deferred / not fixed

None. Nothing was found and left.

## Threat mitigations applied

| Threat | Disposition | How Task 1 satisfies it |
|--------|-------------|-------------------------|
| T-154-34 (spoofing guarantee strength) | mitigate | The weaker true form is written in a table with a "True strength" column in `guides/bridge.md`, and in the generated support matrix beside the CTRL-05 claim itself. Both name enforce-keys as the only structural part and everything else as CI-caught. |
| T-154-35 (examples teaching a pre-check) | mitigate | Zero pre-check tokens across all three adopter-facing guides, verified mechanically. Every seam example is one push; the fire-and-forget case is shown needing no reply clause at all. |
| T-154-36 (undocumented reconnect semantics) | mitigate | `guides/bridge.md` has a dedicated section stating non-durability as an imperative, with the epoch mechanism and the rebuild-from-assigns recovery path. |
| T-154-37 (panel content disclosure) | accept | Unchanged from Plan 07; the human checkpoint reviews it visually. |
| T-154-SC (package installs) | accept | Zero package-manager operations in this plan. |

## Known Stubs

None. No stub patterns, placeholder text, or unwired data sources were introduced.

## Threat Flags

None. This plan introduced no new network endpoints, auth paths, file access patterns, or
schema changes.

## Commits

| Commit | Type | What |
|--------|------|------|
| `26720633` | docs | Task 1 — the honest-claims documentation sweep across five guides plus the renderer |

## What remains

**Only the Task 2 human verification gate.** It is `gate="blocking"` and covers the four
judgements no harness can make: whether the evidence panel's copy reads as fail-closed
rather than broken, whether the two identity labels teach the route-policy-versus-wire
distinction, whether the doctor advisories read as actionable, and whether the catalog
guard's six-step recipe is genuinely followable.

Preparation done so the human only has to look and judge:

- The example host is **already running** at `http://localhost:4700` under `MIX_ENV=test`,
  seeded via `/_e2e/showcase-reset`.
- The panel was rendered headlessly in both light and dark and inspected — it renders
  correctly in both, and the reply row carries `role="status" aria-live="polite"
  aria-atomic="true"`.
- Doctor was run against the example host router; both Phase 154 findings are present and
  both are constructed at `:warning` severity. `Crosswake.Doctor`'s status rule
  (`doctor.ex:183`) is `Enum.any?(findings, &(&1.severity == :error))`, so **neither
  advisory can change doctor's exit status** — that half of step 7 is now proven
  mechanically rather than left to eyeballing.
- `CatalogGuard.assert_catalog_closed!/0` returns `:ok` against the real tree, and a
  synthetic broken source correctly yields
  `[dynamic_registration: :register_command, runtime_apply: :apply, atom_minting: :"String.to_atom"]`.

Once approved, this plan and Phase 154 close.

## Self-Check: PASSED

- `guides/bridge.md` — exists
- `guides/compatibility.md`, `guides/adopter_profiles.md`, `guides/web_to_mobile_migration.md`, `guides/support_matrix.md`, `lib/crosswake/support_matrix/renderer.ex` — all present in commit `26720633`
- `.planning/phases/154-the-control-contract-seam/154-08-SUMMARY.md` — exists
- Commit `26720633` — present in `git log`
