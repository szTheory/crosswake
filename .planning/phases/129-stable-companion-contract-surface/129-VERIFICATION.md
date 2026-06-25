---
phase: 129-stable-companion-contract-surface
verified: 2026-06-25T00:00:00Z
status: passed
score: 4/4
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 129: Stable Companion Contract Surface — Verification Report

**Phase Goal:** Extension authors and extracted packages can depend on a documented, semver-governed public companion-contract surface — before any code moves out of core
**Verified:** 2026-06-25
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A developer browsing hexdocs sees a "Companion Contract" group listing exactly the 5 contract modules — each with a non-false `@moduledoc` and a stability note | VERIFIED | `mix.exs` lines 121–127: full-name atom list `[Crosswake.Companion, Crosswake.Companion.State, Crosswake.Compatibility.Finding, Crosswake.Compatibility.Target, Crosswake.Manifest.Types.RouteEntry]` under `"Companion Contract"` key; all 5 modules carry real `@moduledoc` with `## Stability` section; `@moduledoc since: "0.1.0"` confirmed on the 4 promoted struct types |
| 2 | A reader can open `guides/companion_contract.md` and find the complete enumeration of the public surface; everything else explicitly labeled private or patch-volatile | VERIFIED | File exists; 5-row Contract Surface table present; Stability Tiers section defines "Public stable" and "Private (`@moduledoc false`)"; "What Is Not Contract" section explicitly lists Denial, other Manifest.Types nested modules, and parent Compatibility as internal |
| 3 | `Crosswake.Shell.Denial` is absent from the companion contract guide and from the "Companion Contract" hexdocs group | VERIFIED | `Crosswake.Shell.Denial` not in the `mix.exs` "Companion Contract" group (confirmed by reading lines 121–127); guide's "What Is Not Contract" section explicitly names Denial and prohibits `Denial.reasons/0`; freeze test assertion 4 ("Denial absent") passes |
| 4 | A merge-blocking test asserts no behaviour-callback signatures changed and each contract type carries a non-false `@moduledoc` | VERIFIED | `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` exists, is untagged (`async: true`), runs 7 assertions — all pass: callback MapSet equality freeze, moduledoc non-hidden loop, typedoc on t/0 loop, Denial absent, Finding present, contract module-set frozen exactly, guide exists. `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` → 7 tests, 0 failures |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | Merge-blocking freeze proof test, untagged, async: true, 7 assertions | VERIFIED | Exists; untagged; `async: true`; `@expected_callbacks` MapSet of 6 tuples; `@expected_contract_modules` MapSet of 5 modules; `contract_modules/0` reads from `Mix.Project.config()[:docs][:groups_for_modules]`; all 7 tests pass |
| `guides/companion_contract.md` | Diataxis reference guide, 5-row surface table, Denial prohibition, extras-registered | VERIFIED | Exists; reference banner cross-links companions.md and compatibility.md; 5-row Contract Surface table; Stability Tiers; What Is Not Contract (Denial named, `Denial.reasons/0` prohibition stated); Declaring Compatibility cross-link; Telemetry Events section; registered in `mix.exs` extras at line 109 |
| Promoted `@moduledoc` on State, Finding, Target, RouteEntry | 4 structs: real moduledoc + `## Stability` + `@moduledoc since: "0.1.0"` + `@typedoc on t/0` | VERIFIED | `lib/crosswake/companion/state.ex`: `@moduledoc since: "0.1.0"` line 18; `lib/crosswake/compatibility/compatibility.ex`: both Finding (line 77) and Target (line 31) carry `@moduledoc since: "0.1.0"` and `@typedoc`; `lib/crosswake/manifest/types.ex`: RouteEntry `@moduledoc since: "0.1.0"` line 229 and `@typedoc` line 256; none of these 4 modules retain `@moduledoc false` |
| `mix.exs` docs/0 ExDoc config | "Companion Contract" groups_for_modules (full-name atoms, no regex) + "Extension Authors" groups_for_extras + extras registration | VERIFIED | Lines 121–127: `"Companion Contract"` full-name atom list, no regex; lines 157–159: `"Extension Authors"` entry containing `"guides/companion_contract.md"`; line 109: extras registration |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `contract_modules/0` in freeze test | `mix.exs` "Companion Contract" group | `Mix.Project.config()[:docs][:groups_for_modules] \|> Keyword.get(:"Companion Contract", [])` | WIRED | Single source of truth confirmed (D-15); both the freeze test module-set assertion and the moduledoc loop read from `mix.exs`, not a third hardcoded copy |
| `guides/companion_contract.md` | `mix.exs` extras | Added to extras list at line 109 in same commit as file creation (bbd2449) | WIRED | Orphan-guard satisfied; `test/crosswake/hex_page_test.exs` confirms "Extension Authors" group present (9 tests, 0 failures) |
| `guides/companions.md` | `guides/companion_contract.md` | Forward cross-link sentence at line 7 of companions.md | WIRED | "For a concise enumeration of the stable public surface that companion packages may depend on under semver, see Companion Contract" |
| `test/crosswake/hex_page_test.exs` | `mix.exs` groups_for_modules / groups_for_extras | Membership loop guards `:"Companion Contract"` (line 122) and `:"Extension Authors"` (line 136) | WIRED | 9 tests, 0 failures |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 7 freeze proof assertions pass | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | 7 tests, 0 failures | PASS |
| Hex page test guards new groups | `mix test test/crosswake/hex_page_test.exs` | 9 tests, 0 failures | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| SEAM-01 | 129-01, 129-02 | 5 contract modules carry non-false `@moduledoc`/`@typedoc` and stability note | SATISFIED | All 5 modules confirmed; 4 struct types have `@moduledoc since: "0.1.0"` + `@typedoc on t/0`; freeze test assertions 1–3 pass |
| SEAM-02 | 129-02 | `guides/companion_contract.md` enumerates exactly the public surface; non-contract modules labeled private | SATISFIED | Guide exists, 5-row table present, Private tier defined, "What Is Not Contract" section lists Denial + internal modules |
| SEAM-03 | 129-01, 129-02 | `Crosswake.Shell.Denial` absent from companion surface; companions return `Finding`, never `Denial` | SATISFIED | Denial absent from mix.exs group; guide explicitly prohibits `Denial.reasons/0`; denial.ex carries steering note; freeze test assertions 4–5 pass |
| SEAM-04 | 129-02 | Hexdocs "Companion Contract" groups_for_modules group present | SATISFIED | Full-name atom list in mix.exs; "Extension Authors" extras group present; hex_page_test guards both |

SEAM-05 (second companion extraction checklist) is correctly deferred to Phase 132 and is not in scope for this phase.

### Anti-Patterns Found

No debt markers (`TBD`, `FIXME`, `XXX`) found in any file modified by this phase. No stub patterns detected in phase deliverables.

### Human Verification Required

None. All success criteria are programmatically verifiable and confirmed.

---

_Verified: 2026-06-25_
_Verifier: Claude (gsd-verifier)_
