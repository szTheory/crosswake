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
| 5 | Landed as its own pull request, CI fully green, merged | **met** | **PR #189** ("Phase 175 Wave 0: make the action-pin audit audit its real scope, then pin all 31 mutable refs") was opened from branch `gsd/phase-175-wave0`, cut at the tip of the 14 Wave-0 commits that had been sitting on local `main` with no PR (the human's explicit choice: one PR, all 14 commits, rather than one PR per plan). `gh pr view 189 --json statusCheckRollup` (re-run this session) reports 49 checks: 48 `SUCCESS`, 1 `SKIPPED` (`release-candidate-full-proof`, a pre-existing conditional skip unrelated to this change), 0 failures — `mergeStateStatus` reads `MERGED`. The four checks that could not run on a pull-request event (`phase68-proof`, `native-collateral-advisory`, `see-it-run-collateral`, and `required-checks-audit`, all `workflow_dispatch:`-only or push/schedule-only) were separately dispatched by the orchestrator against the PR branch before merge: `required-checks-audit` (run `35387460901`) succeeded; `phase68-proof` (run `35387453614`) succeeded; `native-collateral-advisory` (run `35387456198`) had its `ios-simulator-advisory` job succeed and its `android-emulator-advisory` job cancelled at 40m25s against its own 40-minute job timeout — step-level evidence from that cancelled run shows every pinned action resolving and succeeding (`actions/checkout@3d3c42e5...` success, `actions/setup-node@82076278...` success, `erlef/setup-beam@fc68ffb9...` success), and only the final "Capture Android emulator advisory evidence" step was cancelled; `see-it-run-collateral` (run `35387458593`) had its `web-and-gif` job succeed and its `native` job cancelled at 35m52s against its own 35-minute job timeout, the same class of expiry, not a pin failure. Both cancellations are recorded here as what they are — an unexercised advisory lane, not a demonstrated pass — rather than rounded up to "all green." PR #189 was **merged as a merge commit** (not squashed, to preserve the 175-01/175-02/175-03 commit lineage for GSD spot-checks): merge commit `c0774e29616272bc37b980ea76b6522224c5d4ad` (short `c0774e29`), confirmed this session via `git log --oneline main \| grep c0774e29` (present, exactly once) and `git status -sb` (`main...origin/main`, no divergence — the merge landed on `origin/main` and local `main` is synced to it). Post-merge, `node scripts/ci_monitor.cjs check-actions` (re-run this session, exit status read via `$?` directly, not through a pipeline) reports `EXIT=0`, `files=27 actions=252 mutable_refs=0`. Commit lineage survived the merge: `git log --oneline main --grep=175-01` -> 4, `--grep=175-02` -> 3, `--grep=175-03` -> 1 (this plan's own docs commit, added after this row). Diff confinement re-checked against the actual merge (`git diff --name-only c0774e29^1 c0774e29^2`, i.e. the PR's real content, not the `origin/main` stand-in Row 4 used before a PR existed): 33 paths — `scripts/ci_monitor.cjs`; the ten workflow files carrying mutable refs; the two evidence logs; this record and the rest of this phase's planning artifacts (`175-01` through `175-10` `-PLAN.md`/`-SUMMARY.md`, `175-CONTEXT.md`, `175-DISCUSSION-LOG.md`, `175-PATTERNS.md`, `175-RESEARCH.md`, `175-VALIDATION.md`) plus `ROADMAP.md`/`STATE.md`; zero already-pinned publish workflows present. |

**Note on Row 4's base.** Row 4's verdict above was recorded before a pull request existed, against
`origin/main` as the best available stand-in for a future PR base. Per that row's own caveat, it has
now been re-checked against PR #189's actual merge diff (`c0774e29^1..c0774e29^2`) as part of closing
Row 5 above, and the same "0 already-pinned publish workflows, no CI redesign" verdict holds against
the real diff, not just the stand-in.

**Additional finding, recorded but not gating Row 5 (adjacent to SEED-022, filed separately below
rather than folded into it).** `erlef/setup-beam@v1` now resolves, repo-wide, to two different
pinned SHAs: 31 pre-existing refs at `fc68ffb90438ef2936bbb3251622353b3dcb2f93` (a real upstream
commit from 2026-03-30, confirmed as genuine history, not fabricated — `175-02`'s own key-decisions
already recorded this as a pre-existing dual-SHA state it deliberately left untouched) and 10 refs
at `54075bcc5e249e4758d363f27d099f55d843f124`, of which 5 predate this PR (`crosswake-ci.yml`) and 5
were introduced by `175-02` across `phase68-proof.yml`, `phase45-proof.yml`, `phase43-proof.yml`,
`phase132-proof.yml`, `phase130-proof.yml`. Resolving the `v1` tag fresh this session
(`gh api repos/erlef/setup-beam/git/refs/tags/v1`, dereferenced via `git/tags/<sha>`) confirms
`54075bcc...` is exactly what `v1` points to today — so every ref this phase pinned is current, and
the `fc68ffb9...` refs elsewhere are "pinned but drifted," not wrong at the time they were written.
This is a variant of SEED-022's "pinned SHAs are unaudited" framing (same root cause: nobody has
looked at whether a stale-but-valid pin should be refreshed) but a distinct symptom (two different
valid pins for one tag, coexisting in the same repo, rather than a single unaudited pin) — noted here
as a fact on the record; per this plan's Task 1 instructions, no new SEED is filed for it and
SEED-022 is left as originally worded.

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
*Row 5 closed 2026-09-18: PR #189 merged as `c0774e29616272bc37b980ea76b6522224c5d4ad`. Wave 1 is released.*
