# Wave 0 Exit Verdict

This is Phase 175's D-28 exit record. It gates Wave 1 (the publish waves) per D-22: no Wave 1
task begins until this record's Row 5 reads **met** with a named merge commit. Every row below
cites a command re-run this session (not re-read from a prior summary) or a specific evidence
artifact on disk.

## Section 1 — The five exit verdicts

| # | Criterion | Verdict | Deciding evidence |
|---|---|---|---|
| 1 | Derived scope parity — the no-argument `check-actions` run reports `files=` equal to a freshly globbed `.github/workflows/*.yml` + `.github/actions/**/action.yml` count | **met** | `node scripts/ci_monitor.cjs check-actions` (re-run this session) reports `files=27`. Freshly computed this session: `ls .github/workflows/*.yml \| wc -l` → 25, `find .github/actions -name action.yml \| wc -l` → 2, sum → 27. Observed 27 == expected 27. The expected number was computed directly from the working tree at verification time, not copied from any plan or SUMMARY.md. |
| 2 | Zero mutable refs over the full scope | **met** | Same re-run: `node scripts/ci_monitor.cjs check-actions` → summary line `files=27 actions=252 mutable_refs=0`, exit status `0` (checked directly via `$?`, not through a pipeline). Matches the recorded `evidence/175-check-actions-full-scope.log`, whose appended tail lines read `observed_exit_status=0` and `freshly_computed_expected_file_count=27`. |
| 3 | The cardinality assertion has been exercised against a deliberate regression | **met** | `node scripts/ci_monitor.cjs test-check-actions-scope` (re-run this session), exit `0`: `case=narrowed expected=27 actual=3 outcome=red` and `case=control expected=27 actual=27 outcome=green`. Matches `evidence/175-scope-gate-regression.log` verbatim (`case=narrowed expected=27 actual=3 outcome=red`, `case=control expected=27 actual=27 outcome=green`, `exit_status=0`). The narrowed case is a genuine proper-subset (3 of 27 files); the control is the full 27-file scope compared against itself. |
| 4 | Diff confinement | **met, against `origin/main` — see note below** | `git diff --name-only origin/main...HEAD` (re-run this session) lists exactly: `scripts/ci_monitor.cjs`; the ten workflow files carrying mutable refs (`required-checks-audit.yml`, `see-it-run-collateral.yml`, `native-collateral-advisory.yml`, `phase68-proof.yml`, `phase45-proof.yml`, `phase43-proof.yml`, `phase132-proof.yml`, `phase130-proof.yml`, `phase34-proof.yml`, `phase23-proof.yml`); the two evidence logs under `evidence/`; this record; and this phase's own planning artifacts (`175-*-PLAN.md`, `175-CONTEXT.md`, `175-DISCUSSION-LOG.md`, `175-PATTERNS.md`, `175-RESEARCH.md`, `175-VALIDATION.md`, `ROADMAP.md`, `STATE.md`). Count of already-pinned publish workflows appearing (`release-please.yml`, `hex-publish.yml`, `ios-mirror-backfill.yml`, `exact-public-proof.yml`): **0**. No CI redesign present — every touched workflow's diff is `uses:` pin lines only, per 175-02-SUMMARY.md's own per-file accounting. |
| 5 | Landed as its own pull request, CI fully green, merged | **not met** | No pull request exists yet for this work. Verified this session: `git status -sb` reports local `main` is `ahead 13` of `origin/main`, and `gh pr list --state all` shows no open or merged PR containing the 175-01/175-02 commits (`2b8e3025`, `d368b945`, `dddc88f7`, `91c3fdb7`, plus their `docs(175-*)` companions) — the commits exist only on the local `main` branch and have not been pushed to any branch, so there is nothing yet to merge. Task 2's checkpoint is where this closes, per this plan's own design. |

**Note on Row 4's base.** D-28 criterion 4 says "changes confined to... against the pull request
base." No pull request exists yet (Row 5), so there is no PR diff to read. `origin/main` is the
only comparable base available at verification time, and it is the correct one: it is what a
future PR's base would be. If a PR is opened from a different point (e.g. a squash, or a rebase
onto a moved `origin/main`), Row 4 must be re-checked against that PR's actual diff before Row 5
is marked met — this row's "met" verdict is scoped to the diff as measured against `origin/main`
right now, not a promise about whatever diff a not-yet-created PR ends up presenting.

## Section 2 — Vacuity-taxonomy row for the scope-cardinality gate (VAC-03)

| Check ID | Shape | Non-vacuity evidence (measured) |
|---|---|---|
| `assertFullScope` (`scripts/ci_monitor.cjs`, invoked by `checkActions()`'s no-argument default-scope path) | A — a predicate (`actual.every(...)` plus a proper-subset/empty-expected check) over a runtime-derived, possibly-empty collection (the discovered `.github/workflows/*.yml` + `.github/actions/**/action.yml` file list), matching Pitfall 4 Shape A in `.planning/research/v23/PITFALLS.md` exactly: "`Enum.all?`/`Enum.any?` on a runtime-derived, possibly-empty collection." | Re-run this session, `node scripts/ci_monitor.cjs test-check-actions-scope`: the narrowed case (`expected=27 actual=3`) is observed turning red (`outcome=red`), and the equal-scope control (`expected=27 actual=27`) is observed staying green (`outcome=green`), exit `0`. This is the specific narrowed-scope case the gate was exercised against — 3 of 27 files, a genuine proper subset, not an edge case of 0 or 26. |

**Why this stays separate from PR #173's `check_absence_is_not_success.exs` (D-26, one line).**
#173's family is "the assertion is a no-op on the value it looked at" — a check that runs and
always passes regardless of what it inspects; this gate's family is "the assertion is correct but
the *set of things it looked at* was truncated" — `check-actions`'s per-line mutability check was
never wrong about any line it read, it simply never received 24 of the 27 files it claimed to
audit. Same pathology (a green result asserting nothing about the part of reality that mattered),
structurally different failure mode (a no-op comparison vs. a truncated input set), and #173's
two guards (`absence.mutation_control_asserts_change`, `absence.open_finding_citation_resolves`)
verifiably do not inspect scan scope at all — confirmed by 175's own D-26 research, not
re-asserted here without a source.

## Section 3 — The two D-29 SEED candidates

| # | SEED | Statement |
|---|---|---|
| 1 | [`SEED-022`](../../../seeds/SEED-022-sha-pin-provenance-audit.md) | Auditing whether the 8 SHAs freshly resolved by 175-02 (and, by extension, the pre-existing pins reused verbatim) are themselves correct, latest, or uncompromised — pinning proves reproducibility, not correctness, and every resolution this phase made was trusted from a single API call with no independent cross-check. Outside Wave 0 per D-29: Wave 0's mandate was stopping scope truncation and stopping mutable refs, not auditing the provenance of every commit hash ever written into CI config. |
| 2 | [`SEED-023`](../../../seeds/SEED-023-extend-scope-cardinality-gate.md) | Extending `assertFullScope` (or an equivalent) to other filesystem-derived-scope checks in the repository beyond `check-actions` — the guard was deliberately written reusable (D-25) but has exactly one caller today, and no systematic sweep has classified which other checks share `check-actions`'s truncation risk versus `check_release_workflow_integrity.exs`'s deliberately-declared-selector shape. Outside Wave 0 per D-29: Wave 0's mandate was the one concretely identified defect, not a repository-wide audit. |

Both are filed as SEED files under `.planning/seeds/` (not prose alone), each following the
project's standard SEED frontmatter (`id`, `title`, `status: dormant`, `severity`,
`trigger_when`, `created`, `related`).

---

*Phase: 175-rehearsal-and-publish*
*Record authored: 2026-09-18*
*Row 5 pending: Task 2's human checkpoint*
