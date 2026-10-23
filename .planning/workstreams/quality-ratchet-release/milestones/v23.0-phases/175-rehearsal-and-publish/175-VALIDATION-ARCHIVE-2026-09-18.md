---
phase: 175
slug: rehearsal-and-publish
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-09-18
---

# Phase 175 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

This is an execution and evidence phase. Most of its verification is not a unit test — it is a live
registry response, a CI run conclusion, or a committed artifact field. That is deliberate: the phase's
own thesis is that a green check which never contacted the registry proves nothing. Where an automated
command is a `curl`, a `git ls-remote`, or a `gh run view`, that is the *correct* instrument, not a gap.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5-otp-27 / Erlang 27.3, pinned in `.tool-versions`), plus Node CLI checks (`scripts/ci_monitor.cjs`) and Elixir CI-hygiene scripts (`script/check_*.exs`) |
| **Config file** | `mix.exs` (root); companion packages carry their own `mix.exs` |
| **Quick run command** | `mix test test/crosswake/release_candidate --max-cases 1` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~45 s quick, several minutes full |

---

## Sampling Rate

- **After every task commit:** run that task's `<automated>` commands, plus
  `node scripts/ci_monitor.cjs check-actions` from Wave 2 onward and
  `elixir script/check_release_doc_version_literals.exs` from Wave 5 onward.
- **After every plan wave:** `mix test test/crosswake/release_candidate --max-cases 1`.
- **Before `/gsd-verify-work`:** `mix test` green, both hygiene checks exit 0, and every registry
  confirmation re-run live.
- **Max feedback latency:** 60 s for script and unit checks; a CI dispatch leg is bounded by its own run
  duration and is watched rather than polled blindly.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 175-01-01 | 01 | 1 | VAC-03 | T-175-01 / T-175-02 | A truncated audit scope cannot exit 0 | unit (CLI) | `node scripts/ci_monitor.cjs check-actions` + fresh-glob parity comparison | ✅ | ⬜ pending |
| 175-01-02 | 01 | 1 | VAC-03 | T-175-03 | The scope gate is proven fail-first | unit (CLI self-test) | `node scripts/ci_monitor.cjs test-check-actions-scope` | ❌ W1 creates it | ⬜ pending |
| 175-02-01 | 02 | 2 | VAC-03 | T-175-05 / T-175-06 / T-175-09 | Token-reading job loads no mutable third-party ref | config scan | `node scripts/ci_monitor.cjs check-actions <5 files>` | ✅ | ⬜ pending |
| 175-02-02 | 02 | 2 | VAC-03 | T-175-06 / T-175-08 | Zero mutable refs repo-wide, single SHA per tag | config scan | `node scripts/ci_monitor.cjs check-actions` (no args) | ✅ | ⬜ pending |
| 175-03-01 | 03 | 3 | VAC-03 | T-175-11 / T-175-12 | Five exit verdicts, none blank, scope parity freshly computed | structural | `test -s .../175-WAVE0-EXIT.md` + `check-actions` + `test-check-actions-scope` | ❌ W3 creates it | ⬜ pending |
| 175-03-02 | 03 | 3 | VAC-03 | T-175-13 / T-175-14 | Wave 0 merged green through the protected path | manual (human gate) | none — `checkpoint:human-verify`, see Manual-Only Verifications | N/A | ⬜ pending |
| 175-04-01 | 04 | 4 | REL-16 | T-175-17 / T-175-18 / T-175-19 | Matrix rows detect from registry evidence; no blank irreversibility cell | structural | invariant-sentence grep, outside-fence literal count, heading count, 15-row count | ❌ W4 creates it | ⬜ pending |
| 175-04-02 | 04 | 4 | REL-10 | T-175-16 | Recovery language matches real tool semantics | structural | heading grep, `unretire` grep, `un-resolve` grep, literal count | ✅ after 175-04-01 | ⬜ pending |
| 175-04-03 | 04 | 4 | REL-10 | T-175-20 / T-175-21 | Runbook SHA is a real ancestor of the exact remote publish graph, not divergent local state | structural (git) | fetch and match live PR base/head OIDs; `script/check_release_runbook_ancestry.sh <sha> <exact-oid>`; audit exact merge OID | ❌ W4 creates it | ❌ Gate 1 breach recorded 2026-09-19; local `HEAD` check passed while PR #147 base/head/merge excluded the runbook |
| 175-05-01 | 05 | 5 | DOC-04 | T-175-22 / T-175-23 | False section removed, not softened | structural | deletion-witness grep, invariant grep, literal count, heading-set count | ✅ | ⬜ pending |
| 175-05-02 | 05 | 5 | DOC-06 | T-175-28 | Durable split mechanism named; archived history untouched | structural | `git subtree split` count ≥ 3, literal count, `git status --porcelain` on archived milestones | ✅ | ⬜ pending |
| 175-05-03 | 05 | 5 | DOC-04, DOC-06 | T-175-24 / T-175-25 / T-175-26 / T-175-27 | Check proven red on an injected literal before being trusted | unit (script) + CI wiring | `elixir script/check_release_doc_version_literals.exs`, recorded fail-first log, CI step grep, `check_release_workflow_integrity.exs` | ❌ W5 creates it | ⬜ pending |
| 175-06-01 | 06 | 6 | REL-11 | T-175-29 / T-175-30 / T-175-32 | Hex rehearsal runs against the real candidate; fields asserted by value | CI run evidence | `gh run view <id> --json conclusion` + field greps on the evidence index | ❌ W6 creates it | ⬜ pending |
| 175-06-02 | 06 | 6 | REL-11 | T-175-31 / T-175-32 | iOS split computed, push dry-run, tag independently absent | CI run + live remote | `git ls-remote --tags` reachability + non-empty, PROVEN grep, 4× SHA count | ✅ after 175-06-01 | ⬜ pending |
| 175-06-03 | 06 | 6 | REL-11 | T-175-33 / T-175-34 | Maven coordinate validated then dropped, still free | CI run + live registry | live POM `curl` status capture + three-row verdict count | ✅ after 175-06-01 | ⬜ pending |
| 175-07-01 | 07 | 7 | REL-12 | T-175-35 | Gate 1 satisfied only by the Hex rehearsal run identifier | manual (human gate) | none — `checkpoint:decision`, see Manual-Only Verifications | N/A | ⬜ pending |
| 175-07-02 | 07 | 7 | REL-12 | T-175-36 / T-175-38 / T-175-39 / T-175-40b | Published tree equals rehearsed tree and exact remote ancestry is non-vacuous | CI run evidence | `gh run view <id> --json conclusion` + exact PR base/head/merge OIDs through `script/check_release_runbook_ancestry.sh` | ❌ W7 creates it | ❌ publish occurred, but runbook ancestry failed against merge `096371e3`; Gate 1 is noncompliant |
| 175-07-03 | 07 | 7 | REL-12 | T-175-37 / T-175-40 | Live registry confirms, empty release list fails | live registry | captured Hex JSON non-empty + `python3` parse asserting a non-empty release list | ❌ W7 creates it | ⬜ pending |
| 175-08-01 | 08 | 8 | REL-13 | T-175-42 / T-175-43 / T-175-47 | Gate 2 carries three separate irreversibility statements and the ancestor check | manual (human gate) | none — `checkpoint:decision`, see Manual-Only Verifications | N/A | ⬜ pending |
| 175-08-02 | 08 | 8 | REL-13 | T-175-41 / T-175-45 / T-175-46 / T-175-47 | Per-job conclusions recorded; tag lands on the rehearsed split SHA; runbook is reachable from exact remote base/head/merge OIDs | CI run + live remote | explicit-OID runbook guard, leg record non-empty, `git ls-remote` reachability | ❌ W8 creates it | ⬜ pending |
| 175-08-03 | 08 | 8 | REL-13 | T-175-44 / T-175-48 | Three registries confirmed independently, raw bodies captured | live registry | Hex JSON parse, mirror tag capture, Maven status capture — all non-empty | ❌ W8 creates it | ⬜ pending |
| 175-09-01 | 09 | 9 | REL-14 | T-175-49 / T-175-50 / T-175-51 / T-175-52 | Skipped ≠ passed; status and conclusion recorded separately | CI run evidence | `gh run view <id> --json jobs` + `python3` assertion on status and conclusion; ledger non-empty | ❌ W9 creates it | ⬜ pending |
| 175-09-02 | 09 | 9 | REL-14 | T-175-53 / T-175-54 | Rollup unmodified; six children enumerated | unit + structural | `git status --porcelain` on the rollup source, section-heading count, `mix test test/crosswake/release_candidate` | ✅ | ⬜ pending |
| 175-10-01 | 10 | 10 | REL-15 | T-175-55 | Gate 3 satisfied only by the live proof run identifier | manual (human gate) | none — `checkpoint:decision`, see Manual-Only Verifications | N/A | ⬜ pending |
| 175-10-02 | 10 | 10 | REL-15 | T-175-56 / T-175-57 | SC7 recorded as two independently evidenced facts; rollup untouched | live registry + structural | captured Hex JSON parse, `git status --porcelain` on the rollup source, `git cat-file -e <merge-sha>` | ❌ W10 creates it | ⬜ pending |
| 175-10-03 | 10 | 10 | REL-10..REL-16, DOC-04, DOC-06 | T-175-58 / T-175-59 / T-175-60 | Nine verdicts, no blanks, no reworded requirement; hygiene still green at close | structural + regression | requirement-id count ≥ 9, `REQUIREMENTS.md` text-diff guard, version-literal check, `check-actions` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 here is plan `175-01` — the broken-windows triage that gates every publish task (D-22, D-28). It
creates the two verification instruments the rest of the phase leans on:

- [ ] `node scripts/ci_monitor.cjs test-check-actions-scope` — the scope-cardinality self-test, proving
      the gate red on a narrowed scope and green on an equal-scope control (`175-01` Task 2).
- [ ] `.../evidence/175-scope-gate-regression.log` — the recorded demonstration of that red.
- [ ] `.../evidence/` — the phase evidence directory every later plan writes into.

No new ExUnit suite is required. The existing `test/crosswake/release_candidate` and
`test/crosswake/proof` suites already cover the *shape* of rehearsal and proof correctness; this phase's
job is to produce real-world evidence, not new unit coverage. `script/check_release_doc_version_literals.exs`
(`175-05`) is a new check and carries its own fail-first demonstration rather than an ExUnit wrapper,
following the convention of `script/check_absence_is_not_success.exs`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Wave 0 pull request merged green before Wave 1 opens | VAC-03 (D-22) | Merging into protected `main` is a human act in this repository; admin-bypass is refused | `175-03` Task 2: confirm the diff contains only the ten workflow files, `scripts/ci_monitor.cjs`, the evidence logs and the exit record; confirm every required check green, especially the six proof lanes whose refs changed; merge; re-run `check-actions` on `main`; record the merge commit SHA |
| Authorization of the first companion Hex publish | REL-12 (D-07, D-08) | A one-way registry mutation; no automated check may authorize it | `175-07` Task 1: reply `publish leg 1 <hex-rehearsal-run-id>` with the identifier read from `175-REHEARSAL-EVIDENCE.md` |
| Authorization of the three-registry core publish | REL-13 (D-07 through D-11) | Opens three one-way doors at once, one of them permanently (Maven) | `175-08` Task 1: reply `publish core <ios-rehearsal-run-id>` with the identifier read from `175-REHEARSAL-EVIDENCE.md` |
| Authorization of the second companion Hex publish | REL-15 (D-07, D-08, D-09) | A one-way registry mutation | `175-10` Task 1: reply `publish leg 3 <exact-public-proof-run-id>` with the identifier read from `175-PROOF-EVIDENCE.md` |

Each gate's typed-back value is a different named field, read from that leg's own evidence, so a gate
cannot be satisfied with what was typed at an earlier one (D-08). None of the three is auto-approvable;
`--no-reversibility-gates` must not be used for this phase (D-12).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or a recorded Manual-Only entry
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60 s for script and unit checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
