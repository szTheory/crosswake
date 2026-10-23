# Phase 170: Vacuous Assertion Remediation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-16
**Phase:** 170-vacuous-assertion-remediation
**Areas discussed:** Ledger shape & drift-resistance, Audited set boundary, Fix shape & "empty now fails" proof, VAC-03 taxonomy checklist mechanism
**Mode:** advisor (USER-PROFILE.md present; calibration tier `minimal_decisive`), four parallel `gsd-advisor-researcher` agents, one synthesized recommendation set presented for a single lock decision at the maintainer's explicit request.

---

## Audited set boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Classify exactly the 173 | Record the 131 `any?` sites as safe-by-construction; seed the 47 `refute Enum.any?` sites for a later milestone; remediate within the 42 | |
| Classify 173 + fold in the 47 | 220 rows, one coherent set; restate SC#1's arithmetic per Phase 169's precedent | ✓ |
| Redefine the set semantically | Derive "every collection assertion whose empty case is not a failure" programmatically; satisfy 173 as a subset mapping | |
| Widen to the full vacuity family | Add `Enum.each` without count assertions, `for` comprehensions, `Enum.reduce` boolean accumulators, unforced `Stream` chains | |

**User's choice:** Fold in the 47 (D-01, D-02, D-03).
**Notes:** Decided on blast radius rather than count. Three of the 47 unflagged `refute Enum.any?` sites are in `crosswake_release_status_test.exs`, `coordinate_test.exs` and `mirror_test.exs` — release-graph test files gating Phase 175's irreversible publish. Widening stops at 220: PITFALLS.md maps Shapes B–F to Phases 171/173/174, and `Enum.filter |> Enum.all?` has zero occurrences in this repo. ROADMAP text is deliberately left unedited, following Phase 169's handling of its own two wrong success criteria.

---

## Ledger shape & drift-resistance

| Option | Description | Selected |
|--------|-------------|----------|
| Static `file:line` markdown table | Hand-typed table plus a test re-resolving each citation via the existing stale-citation machinery | rejected outright |
| Regenerable inventory + snapshot, line-keyed | Script emits the live set; committed snapshot; test asserts exact equality | |
| Regenerable inventory + snapshot, content-hash-keyed | Same mechanism, rows keyed by hash of `{enclosing test name, normalized assertion expression}`; `file:line` as display only | ✓ |
| Inline structured annotations | Classification carried as code comments at each call site, harvested by a scanner | |

**User's choice:** Content-hash-keyed regenerable inventory plus committed snapshot (D-04 through D-08).
**Notes:** The static table was rejected without a genuine hearing — it is this milestone's target defect restated as a deliverable, and this repo already shipped its stale-citation version (`absence.open_finding_citation_resolves` exists because of it). In-repo ancestor is one phase old: Phase 169's D-04 `release.scanner.roster_exact`. External precedent for content-hash keys: `.sobelow-skips` fingerprints, PHPStan/Psalm baselines. Five classification buckets defined (D-07), including `safe-cardinality-pinned` — added specifically because site reads proved the 6-line guard heuristic has false negatives. The critical line drawn at D-06: the ledger test asserts the *ledger is complete*, never that every site is guarded — that second assertion is VACG-01 and stays deferred.

---

## Fix shape & "empty now fails" proof

**Sub-decision 1 — rewrite idiom**

| Option | Description | Selected |
|--------|-------------|----------|
| `refute Enum.empty?(collection)` | One line before each confirmed-vacuous assertion, uniform regardless of collection origin | ✓ |
| `assert [_ \| _] = collection` | Pattern-match shape assertion | |
| `assert Enum.count(coll) == expected_n` | Strictly stronger; asserts exact expected cardinality | partial |
| Shared custom ExUnit assertion macro | Makes non-emptiness intrinsic and un-forgettable at new call sites | |
| `Enum.each(coll, &assert(...))` + count | Also fixes the boolean-collapse failure message | deferred |

**Sub-decision 2 — the proof**

| Option | Description | Selected |
|--------|-------------|----------|
| One regression test per site | ~29 bespoke empty-input tests | |
| Shared mutation-style harness | Substitute-empty-and-assert-fails across the set | partial |
| Itemized structural proof | Assert the guard exists and matches the assertion's argument expression | ✓ (bulk) |
| Hybrid | Structural for the bulk plus real empty-input regressions at high-blast-radius sites | ✓ |

**User's choice:** `refute Enum.empty?` uniformly (D-09), with exact-count used only where sibling assertions already establish cardinality; hybrid proof (D-12, D-13, D-14).
**Notes:** The custom macro was rejected because it solves "a future contributor forgets the guard" — precisely VACG-01's job — duplicating deferred work in a harder-to-remove form. Per-site regression tests everywhere were costed against the real sites and rejected: most collections cannot be forced empty without fabricating structs and fixture files that no longer exercise real code, so the test would assert a property of the harness. The structural half also catches guard-checks-the-wrong-variable, which a runtime test misses. Both proof mechanisms stay closed-world over this audit's fixed list and never enter `check_absence_is_not_success.exs` or the required-check registry, so SC#3 holds by construction.

---

## VAC-03 taxonomy checklist mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown checklist document | `docs/VACUITY-TAXONOMY-CHECKLIST.md` referenced by each phase's close ritual | |
| PR template / CONTRIBUTING item | Fires on diffs touching `.github/workflows/` or `script/check_*` | |
| Advisory non-blocking scanner | Enumerates newly-added checks in a diff, pre-populates the six shapes for the reviewer | |
| Required VERIFICATION.md section | `vacuity_taxonomy` per phase, applied by the phase-close verifier, with explicit null-statement | ✓ |

**User's choice:** Required `vacuity_taxonomy` section in each phase's VERIFICATION.md (D-15 through D-21).
**Notes:** The PR template cannot reach the already-merged Phase 169, this repo has no PR-template convention today, and an un-required checkbox carries no evidentiary weight. The decisive insight was finding the checklist analogue of Phase 169's ROSTER/DONE sentinel: a phase adding no new checks must *state that explicitly* rather than omitting the section, so "nothing to check" and "we forgot" are never indistinguishable. Applied by the phase-close verifier, not the executor at plan time (a check's shape can still change) and not a PR reviewer (nothing durably records that across six phases). Taxonomy content single-sourced at PITFALLS.md; VERIFICATION.md links, never copies. The field outlives v23.0 — VACG-01 supersedes only Shape A of six.

---

## Claude's Discretion

- Snapshot file serialization format and location, provided it diffs legibly and the ledger test reads it back without re-deriving classifications.
- Exact normalization applied before hashing (D-05), provided pure reformatting produces no churn and a genuine expression change always does.
- Whether the itemized structural test lives in `test/crosswake/proof/` alongside the `phaseNN_*` corpus or beside the inventory script.
- Plan decomposition and wave ordering — classification, rewrites, proof tests and the VAC-03 template change are separable.
- Whether the retroactive Phase 169 addendum is its own file or a section in a phase-170 artifact.

## Deferred Ideas

- **`Enum.all?`'s boolean-collapse failure message** — real DX defect aligned with the milestone's legibility thesis, but roughly doubles the diff and changes short-circuit semantics for a concern VAC-01/VAC-02 do not ask for. Capture as its own seed.
- **VACG-01** — already tracked under Future Requirements; its absence from this milestone is success criterion #3. Absorbs the inventory's detection core when it lands.
- **ROADMAP SC#1 / REQUIREMENTS VAC-01 text amendment** (173 → 220) — recorded in ground truth; the text edit is a separate call.
- **PR template / CONTRIBUTING checklist item** — acceptable later as a supplementary reminder, never as the primary surface.
- **Vacuity Shapes B–F** — owned by Phases 171, 173, 174 and the cross-cutting checklist.
