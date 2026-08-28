---
phase: 155-host-owned-fallback-components
verified: 2026-07-30T19:30:00Z
status: passed
score: 23/23 must-haves sampled verified (all 7 plans; representative + exhaustive on the six flagged risk areas)
behavior_unverified: 0
overrides_applied: 0
re_verification: null
---

# Phase 155: Host-Owned Fallback Components Verification Report

**Phase Goal:** Adopters get generated, brand-tokenized fallback UI for bounded controls that
they own outright — never an importable component tier — and CI proves those fallbacks actually
render and fail closed rather than silently degrading.
**Verified:** 2026-07-30
**Status:** PASSED
**Re-verification:** No — initial verification

## Method

This verification did not trust SUMMARY.md claims. Every load-bearing claim below was
re-executed against the live tree: `mix run`, `mix test`, `node`, `curl` against a
locally-booted `MIX_ENV=test` Phoenix server, and `npx playwright test` (including deliberately
re-running each plan's own deliberate-break mutation controls and confirming clean restoration).
Git status was clean (only pre-existing `?? tmp/`) before and after.

## Goal Achievement — the Six Flagged Risk Areas

### 1. Anti-vacuity — `Crosswake.ComponentTierGuard`'s twin has teeth

- `mix run -e 'Crosswake.ComponentTierGuard.assert_no_component_tier!()'` → `:ok` against the
  real repo (re-run live, not read from a SUMMARY transcript).
- **Live mutation:** stripped every `attr :` line from the real shipped
  `priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex`, re-ran the same
  command → raised `[proof.fall_02.no_component_tier.components_exist_in_templates]` naming the
  exact template glob, with the five-step retirement recipe and "what you probably want instead"
  block. Restored the file from a backup; `git diff --stat` on the template was empty afterward
  — no persisted damage. This is the strongest possible evidence the anti-vacuity twin is not
  theater: the claim "components exist only as adopter-owned text" genuinely fails when they
  don't.
- `mix test test/crosswake/component_tier_guard_test.exs --warnings-as-errors` → 9 tests, 0
  failures. Test file carries no `@tag`/`@moduletag` (D-39: repo-root-only, untagged, confirmed).
- **Verdict: VERIFIED.**

### 2. Honest diagnostics (D-40) — the two doctor findings

- `native_controls_ui.stamp_drift` (`lib/crosswake/doctor/doctor.ex:2205-2213`): message text is
  "is stamped template_version=N, but this Crosswake ships template_version=M" — a version-integer
  comparison only, no content claim.
- `native_controls_ui.wiring` (`:2261-2266`): severity is `:advisory`; message text is literally
  "**could not find** a reference to..." (never "is not wired"), and the hint explicitly says
  "this check is a best-effort grep over source text and is never authoritative."
- **Exit-code independence, verified at the source, not asserted:** `doctor.ex:186` computes
  `status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok)` —
  `:advisory` and `:warning` findings (both of these are) can never flip `status` to `:error`,
  and `mix crosswake.doctor.ex:55` only halts nonzero `if report.status == :error`. The wiring
  finding literally cannot fail doctor's exit code by construction, not by convention.
- **Verdict: VERIFIED.**

### 3. No silent rewrite (T-155-13) — `patcher.ex`'s `:marker_stale` path

- Source-level: `ensure_endpoint_block/1`'s stale branch returns `{:ok, contents, [:marker_stale]}`
  where `contents` is the original, unmodified read — never `patched`. `normalize_block/1` only
  affects the *comparison*, never the returned value.
- `mix test test/mix/tasks/crosswake_install_test.exs --warnings-as-errors` → 7 tests, 0
  failures, including `assert File.read!(endpoint_path) == contents` on the stale-block case (two
  separate byte-equality assertions in the test file).
- **Verdict: VERIFIED.**

### 4. PROOF-01 — merge-blocking browser lane, actually wired and actually red-on-break

- CI wiring confirmed by reading `.github/workflows/offline-sync-e2e-gate.yml`: `e2e-proof` runs
  unfiltered `npx playwright test` (line 131, which necessarily includes the new spec) plus a
  named `Run native-controls fallback proof` step (line 138-140) for legibility only; no
  `continue-on-error` anywhere in the job; a failure-artifact upload was added
  (`if: failure()`, lines 146-155). `merge-blocking-offline-sync-e2e` (the one required check,
  GATE-01) lists `e2e-proof` in its `needs:` and rolls up via `re-actors/alls-green`, the
  project's standard pattern.
- `examples/phoenix_host/e2e/native_controls_fallback.spec.ts` is pinned in
  `script/check-e2e-honesty.mjs`'s `FILES` (line 60) and both new `.eex` templates are pinned in
  `brandbook/tools/check-consumer-drift.mjs`'s MANIFEST (lines 43-44).
- **Ran the spec live** (`MIX_ENV=test`, matching CI exactly): `npx playwright test
  e2e/native_controls_fallback.spec.ts` → **9/9 passed**. Ran the **full unfiltered suite**
  (matching the `e2e-proof` job's actual command) → **32/32 passed**, matching the reported
  claim exactly.
- **Independently re-ran the deliberate-break controls**, not trusting the SUMMARY transcript:
  - A1: `CROSSWAKE_PROOF_BREAK_FALLBACK=1 npx playwright test e2e/native_controls_fallback.spec.ts`
    → exactly 3 failed (absent-before/present-after, focus-trap, contrast), A2/A3's 6 stayed
    green — matches the documented mutation exactly.
  - Re-ran without the env var immediately after → 9/9 green again, `git status` clean — no
    persisted side effect.
- **Verdict: VERIFIED**, with direct re-execution evidence, not inference from SUMMARY prose.

### 5. One served `tokens.css`

- `find . -name tokens.css` (excluding `_build`/`deps`) shows no host-local copy remains under
  `examples/phoenix_host/`; the previously-ungated third copy is gone.
- All 12 stylesheet references across the reference host (`bridge_proof_live.ex`, `router.ex`,
  `layouts.ex`, both offline/learn-loop HEEx templates, both flashcards LiveViews, the e2e
  undeclared-control route, the showcase hub) point at `/crosswake/tokens.css` uniformly.
- **Live curl against a real `MIX_ENV=test` Phoenix boot:** `GET /crosswake/tokens.css` →
  `200`, real compiled CSS body (7285 bytes) containing `--cw-overlay-scrim`,
  `--cw-status-error-fg`, and the corrected `--cw-action-focus-ring` values. The generated
  offline layout (`priv/templates/crosswake/offline_ui/offline_root.html.heex.eex`) links the
  same URL, and the generator's own comment confirms it no longer copies `tokens.css` into the
  host.
- **Verdict: VERIFIED.**

### 6. D-35 stamp discipline

- `lib/mix/tasks/crosswake.gen.native_controls_ui.ex:63` — `@template_version 2`.
- Committed host output `examples/phoenix_host/lib/crosswake_example_web/components/crosswake_fallbacks.ex`
  line 1: `# crosswake:native-controls-ui template_version=2` — matches.
- `mix test test/crosswake/proof/phase155_native_controls_template_drift_test.exs
  --warnings-as-errors` → 2 tests, 0 failures (the checked-in SHA-256 hash matches the live
  templates; the non-vacuity glob assertion also passes).
- **Verdict: VERIFIED.**

## Broader Verification — All Seven Plans

| # | Truth (representative sample) | Status | Evidence |
|---|---|---|---|
| 1 | Generator writes both files with `@template_version` stamp, no-clobber on second run | ✓ VERIFIED | `mix test test/mix/tasks/crosswake.gen.native_controls_ui_test.exs` — 10 tests, 0 failures, incl. first-run/second-run/partial-tree/malformed-app cases |
| 2 | Generated CSS: zero theme logic, one `color-scheme` line, only `--cwfb-*` aliases (never bare `var(--cw-*)` in a declaration body) | ✓ VERIFIED | `grep -c 'var(--cw-'` = 15 = alias-block count exactly; no `prefers-color-scheme`/`[data-theme]` in the template |
| 3 | Panel background is `--cw-surface-inset`, not raised | ✓ VERIFIED | `--cwfb-surface: var(--cw-surface-inset)` at line 22 |
| 4 | `resolve/2` tolerant, `dispatched/2`/`push/3` stay strict; `UnknownCapabilityFamilyError` distinct from `UndeclaredCapabilityError` | ✓ VERIFIED | Source: `resolve/2` calls `maybe_fetch_state/1` (nil-safe); `dispatched/2` still calls `fetch_state!/1`. `mix test test/crosswake/bridge/push_test.exs --warnings-as-errors` — 49 tests, 0 failures |
| 5 | `--cw-status-error-fg` 6.02:1 both themes; `--cw-action-focus-ring` light corrected to wake-700, ≥3:1 SC 1.4.11; gate hole closed | ✓ VERIFIED | `node brandbook/tools/contrast.test.mjs` — 17/17 pass live, including the new focus-ring and destructive-pair assertion classes |
| 6 | Token cap enforced at 30, count is 29, group-exhaustiveness enforced | ✓ VERIFIED | `node brandbook/tools/compile-tokens.test.mjs` — 28/28 pass live |
| 7 | Two new `.eex` templates gated in drift MANIFEST, generated host files not policed | ✓ VERIFIED | `node brandbook/tools/check-consumer-drift.mjs` — 7/7 pass live; MANIFEST entries confirmed at lines 43-44 |
| 8 | `ComponentTierGuard` six rules, `root:` seam byte-for-byte production default, no bypass mechanism | ✓ VERIFIED | Source review + live `:ok` + live mutation-to-red (see Risk Area 1) |
| 9 | Destructive confirm: `role="alertdialog"`, no click-away, initial focus Cancel, filled danger button + border-left shape cue | ✓ VERIFIED | Template: `phx-click-away={if @tone == :neutral, ...}`; CSS: `.cw-fallback-action-danger { background-color: var(--cwfb-danger-bg); ...; border-left: 3px solid ...}` |
| 10 | Action menu: no APG `menu` role, `aria-expanded`+`aria-controls` (not `aria-haspopup`), destructive row last with gap band | ✓ VERIFIED | Template doc + markup reviewed directly; live spec assertion "no element on the page declares the APG menu role" passed |
| 11 | Button DOM order `[Cancel, Action]`, column-reverse narrow / row+flex-end wide | ✓ VERIFIED | CSS lines 132-143 match D-18 exactly |
| 12 | Zero new JavaScript shipped | ✓ VERIFIED | `git log --diff-filter=A --name-only` over the phase's commit range shows no added `.js`/`.mjs` files outside pre-existing tooling |
| 13 | ROADMAP/REQUIREMENTS carry D-44's corrected criterion-3 wording and D-48 non-claims; D-57 citation fix; D-56 correction note | ✓ VERIFIED | Grepped `.planning/ROADMAP.md`, `.planning/research/v20/UX-CONTRACT.md` directly — all three corrections present verbatim |
| 14 | `/_e2e/undeclared-control` lives inside the same compile guard as other `/_e2e` routes and is absent from a prod compile | ✓ VERIFIED | `MIX_ENV=prod mix phx.routes` run live — zero `/_e2e` matches |
| 15 | AUDIT.md token inventory honest (29/30, overlay group present) | ✓ VERIFIED | `brandbook/AUDIT.md:392,454-458` |

### Full Test Suite

```
$ mix test
1289 tests, 0 failures
```

`mix test --warnings-as-errors` aborts on warnings from exactly the three pre-existing,
phase-155-unrelated files named in the task brief
(`test/crosswake/offline/proof_lane_test.exs`, `test/crosswake/doctor/doctor_threadline_test.exs`,
`test/crosswake/proof/phase43_rulestead_advisory_test.exs`) — confirmed by re-running with
`--warnings-as-errors` and reading every `warning:` block's file reference. None trace to a
phase-155 file. `MIX_ENV=test mix compile --force --warnings-as-errors` at repo root is clean.

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| FALL-01 | ✓ SATISFIED | Generator scaffolds both surfaces as verbatim host-owned files with a stamp; second-run no-clobber verified live; one served `tokens.css` verified live |
| FALL-02 | ✓ SATISFIED | `ComponentTierGuard` proves nothing UI-shaped ships importable from `lib/`, and its anti-vacuity twin proves the templates genuinely carry the components — verified with a live mutation-to-red, not by reading the assertion |
| PROOF-01 | ✓ SATISFIED | Merge-blocking wiring confirmed in CI config; spec runs green (32/32) and correctly red under each of the three documented deliberate-break controls |

No orphaned requirements: `.planning/REQUIREMENTS.md`'s traceability table maps exactly FALL-01,
FALL-02, PROOF-01 to Phase 155, and all three are claimed across the seven plans'
`requirements:` frontmatter.

### Anti-Patterns Found

None. Scanned every phase-155-touched `lib/`, `priv/templates/`, and example-host file for
`TBD`/`FIXME`/`XXX`/`TODO`/placeholder language — zero debt markers. One `TODO` exists inside
the generator's **printed adopter guidance** (the paste-ready `handle_event` recipe), which is
intentional per D-06/D-08: it marks where the adopter fills in app-specific mutation logic, not
an unfinished Crosswake obligation.

### Deviations Judged

Read every SUMMARY's Deviations section. All eight test-path substitutions (155-02, 155-04
naming nonexistent `test/crosswake/bridge_test.exs` / `test/crosswake/install/patcher_test.exs`
/ `test/crosswake/doctor_test.exs`) extended real, established test files instead of creating
competing phantom files — each substitution was verified by directly running the real files'
test suites (bridge/push_test.exs: 49 passing; crosswake_install_test.exs +
doctor/doctor_test.exs: passing). None weakened the plan's intent; each preserved or exceeded the
literal acceptance criteria. The 155-07 plan-text discrepancies (Manifest.Builder catalog
citation, BRAND-SPEC §7 SUMMARY.md citation, D-56 characterization) were each independently
re-verified against the cited source and found to be accurate corrections, not scope-narrowing.

## Gaps Summary

None found. Every must-have sampled across all seven plans — including the six risk areas
explicitly flagged for this verification — was independently re-executed against the live tree
and passed. Where a plan's acceptance criteria described a live browser behavior (focus trap,
computed contrast, deliberate-break mutations), this verification ran the actual `npx playwright
test` commands rather than reading the SUMMARY's transcript. Where a plan described a structural
guard's teeth, this verification mutated the real shipped template and watched the guard raise
for the correct reason, then confirmed clean restoration.

---

*Verified: 2026-07-30*
*Verifier: Claude (gsd-verifier)*
