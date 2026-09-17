# Phase 173: Recovery-Path Proof Convergence - Research

**Researched:** 2026-09-17
**Domain:** GitHub Actions workflow composition (`workflow_call`/`workflow_dispatch`), fail-closed
CI aggregation, release-proof durability
**Confidence:** MEDIUM (structural findings HIGH; org/account-level constraint findings HIGH via
direct API query; GitHub Actions `workflow_call` semantics MEDIUM — sourced from official docs but
not independently exercised in this repo's Actions instance this session)

## Summary

The orchestrator's framing in `<orchestrator_findings>` #3 is correct and load-bearing: a publish
that goes through `.github/workflows/hex-publish.yml` never enters `release-please.yml` at all, so
there is no `needs:` edge to point at a recovery-path job — the recovery path currently has **no
job to `needs:`, and no publication-record artifact of any kind**. I verified directly that neither
lane writes a post-publish receipt today: `publish-hex` (release-please.yml:225) and `publish`
(hex-publish.yml, the recovery job) both end at `guarded_hex_publish.sh` with no
`upload-artifact` step following it, and `guarded_hex_publish.sh` itself writes no JSON receipt
(confirmed by reading the full 355-line script). The `phase168-candidate-receipt-*` /
`phase168-candidate-ci-*` artifacts that DO exist are **pre-merge approval receipts** (consumed by
`approved-release-guard`, before any publish happens) — not a post-publish signal, and not a
template that already fits Success Criterion 1 without a new emitter.

This changes the phase's shape from "wire an existing signal into a `needs:` list" to "author a
new publication-record emitter used identically by both lanes, then gate on it." The cleanest
mechanism for "identically" is a `workflow_call` reusable workflow: extract `exact-public-proof`'s
body into its own workflow file with `on: workflow_call:`, keep it as a `needs:`-gated job inside
`release-please.yml` for the ordinary path, and add a new job to `hex-publish.yml`'s `publish` /
`recover-android-core` jobs (`needs: [publish]`, `if: always()`) that calls the same reusable
workflow after recovery-publish success. Both callers pass `{package, version, approved_head}` and
both write the same receipt shape before invoking the shared proof body — this is what makes the
two fixtures (ordinary graph, recovery graph) "identical" in a checkable sense rather than merely
similarly named.

Separately, and independent of the `workflow_call` question: this is a **public** repository
(`gh api repos/szTheory/crosswake` → `"private": false`), which caps `retention-days` at **90**,
not 400 — GitHub's docs are explicit that the 400-day ceiling is a *private*-repository-only
figure. The roadmap's flagged assumption ("up to 400 days, org policy permitting") is refuted for
this repo, not merely unconfirmed. This makes the roadmap's alternative — a durable, committed
release-ledger entry — the correct default for Success Criterion 4, not a fallback: even a 90-day
maximum does not "outlive retention" in any durable sense for a project with a multi-year horizon.

**Primary recommendation:** Extract `exact-public-proof` into a `workflow_call` reusable workflow
consumed by both `release-please.yml` (ordinary path, unchanged trigger shape) and a new job in
`hex-publish.yml` (recovery path, triggered after `publish`/`recover-android-core` succeeds); have
both lanes write an identically-shaped publication-record artifact `{package, version,
approved_head, ref, published_at}` before calling it; make the reusable workflow's own first step
assert that record's presence and hard-fail (not skip) when it is absent; and satisfy Success
Criterion 4 with a committed release-ledger file (JSON or Markdown row per release) rather than
raising `retention-days`, since 90 days is this repo's real ceiling.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Publication-record emission (write receipt after Hex/iOS/Android publish) | CI/CD (GitHub Actions job) | — | The only tier that observes a live publish outcome in either lane; must live beside `guarded_hex_publish.sh` / `android_publication.sh` |
| Publication-record verification (`exact-public-proof`'s new first step) | CI/CD (GitHub Actions job, shared) | — | Must be identical code path for both lanes — a reusable `workflow_call` body, not duplicated YAML |
| Fail-closed rollup semantics (`skipped` != success) | Elixir (`lib/crosswake/release_candidate/workflow.ex`) | CI/CD (`linked-release-rollup` job) | Already implemented and tested here (`rollup!/1`); Criterion 3 is "don't regress this," not "build it" |
| Durable proof-outcome record (Criterion 4) | Git-committed ledger file | CI/CD (writes the commit) | A committed file in the repo is the only tier that survives artifact retention entirely; CI's role is limited to producing the commit |
| Recovery-path trigger authority (who may invoke `hex-publish.yml`) | CI/CD (`workflow_dispatch` input validation, already present) | — | Out of scope for this phase — Phase 173 does not change who can dispatch recovery, only what happens after a successful one |

## Architectural Responsibility Map — reasoning note

This phase is 100% inside the CI/CD tier; there is no browser/frontend/database tier in play. The
map above is included to make explicit that the "publication-record signal" (Criterion 1) and the
"proof body" (Criterion 2) are two *different* artifacts that must not be collapsed into one job —
conflating them would put a network-durability problem (does a receipt exist) and a
compute-durability problem (did the byte-exact rebuild pass) behind the same failure message,
which would made a future debugging session unable to tell "record missing" from "proof failed"
apart — exactly the diagnostic-legibility defect class Phase 169 of this same milestone exists to
fix.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| XPUB-04 | `exact-public-proof` runs on a publication-record signal satisfied identically by the ordinary and the recovery publish path | See "Reusable-workflow composition" and "Publication-record signal" sections below; no such signal exists in either lane today (verified by reading both publish jobs and `guarded_hex_publish.sh` end-to-end) |
| XPUB-05 | A missing publication record fails the proof hard; it is never expressed as a skipped job | See "Turning a skip into a failure" section; existing `native-release-rollup` job (release-please.yml:838-975) is the closest in-repo precedent for a job-level `exit 1` on a bad state, reached via `if: always()` + internal assertion rather than a job-level `if:` skip |
| XPUB-06 | The proof result outlives its 14-day artifact retention — durably recorded in-repo or with retention raised | See "Retention" section; repo confirmed public, so raised retention tops out at 90 days, not 400 — recommend the committed-ledger alternative |
| XPUB-07 | The fail-closed rollup semantics are preserved verbatim — `skipped` still counts as not-success | See "Non-vacuity" section; `Workflow.rollup!/1` (`lib/crosswake/release_candidate/workflow.ex:39-44`) already treats `skipped` as `!= "success"`, and `test/crosswake/release_candidate/workflow_test.exs` ("every child failure preserves exact prior public success as PARTIAL") already exercises this for `exact_public` as the *failed* child, but not yet for `exact_public: "skipped"` while every other child is `"success"` — that specific case is the gap this phase's test must close |
</phase_requirements>

## A. Reusable-workflow composition (`workflow_call`)

`[CITED: https://docs.github.com/en/actions/using-workflows/reusing-workflows]`

- A reusable workflow is any workflow file under `.github/workflows/` whose top-level `on:` includes
  `workflow_call:`. A caller invokes it with `uses: ./.github/workflows/<file>.yml` (same-repo
  relative path) as the **entire body of a job** — not a step. `[CITED]`
- **Multiple callers:** the docs describe the calling syntax generically (by path + optional ref)
  with no restriction to one caller — any number of workflow files in the same or other repos may
  `uses:` the same reusable workflow. I could not find an explicit "N callers" ceiling stated in the
  docs; treat "an arbitrary number of callers is fine" as `[CITED]` (implied by the syntax, not a
  quoted limit) rather than `[VERIFIED]`.
- **`needs:`/`if:` across the boundary:** a caller job that itself calls a reusable workflow behaves,
  from the perspective of *other* jobs in the same caller file, like any other job: its aggregate
  result (success/failure/skipped) is what a downstream `needs:` sees, and its declared `outputs:`
  are read via `needs.<job_id>.outputs.<name>` exactly as for a non-reusable job. `[CITED]` The docs
  do not describe a way for the caller to see *per-job* results *inside* the called workflow — only
  the called workflow's own aggregate. This matters for Criterion 2: if the reusable workflow's
  *internal* first step fails, the calling job's own result is `failure`, which is what propagates
  to `needs:` — good, this is exactly the shape XPUB-05 wants, and it requires no new mechanism
  beyond an ordinary failing step inside the reusable workflow body.
- **Nesting depth:** "You can connect a maximum of ten levels of workflows – that is, the top-level
  caller workflow and up to nine levels of reusable workflows." `[CITED]` This phase needs at most
  one level of nesting (caller → `exact-public-proof.yml`), far under the ceiling.
- **Secrets:** `secrets: inherit` passes all of the caller's secrets through implicitly; otherwise
  secrets must be listed explicitly under the calling job's `secrets:` key and are not visible to
  further-nested reusable workflows unless re-passed. `[CITED]` `exact-public-proof`'s current body
  reads `github.token` only (no repo secret) — confirmed by reading its steps (release-please.yml
  lines 724-770) — so this phase's extraction does not need `secrets: inherit`; explicit
  `permissions:` on the reusable workflow's own jobs is what matters instead (it already declares
  `actions: read` / `contents: read`).
- **Distinguishing failed-vs-skipped through the boundary:** not separately documented beyond the
  general job-result semantics above. Because the called workflow's *own* internal jobs can still
  independently be `skipped` (e.g. a matrix branch), the aggregate the caller sees is whatever
  GitHub computes for that internal job graph — the same ambiguity XPUB-05 exists to close applies
  *inside* the reusable workflow too, not just at the top level. Concretely: if the reusable
  workflow's proof job's own `if:` still gates on `needs.*` in a way that can silently skip, wrapping
  it in `workflow_call` does not fix XPUB-05 by itself — the internal fix (assert-and-fail rather
  than gate-and-skip, see section B) is still required.

**Consequence for this phase's design:** `workflow_call` is confirmed as the correct mechanism to
satisfy "demonstrated identically from a fixture representing the ordinary graph and one
representing `workflow_dispatch` recovery" (Criterion 1) — both fixtures can `uses:` the identical
file. But `workflow_call` does not, by itself, solve Criterion 2 (skip-vs-fail); that still requires
the pattern in section B applied *inside* the reusable workflow body.

## B. Turning a skip into a failure

Four candidate shapes, evaluated against this repo's own existing conventions (all four patterns
are already present somewhere in this codebase — the phase should reuse one, not invent a fifth):

| Shape | Mechanism | Existing precedent in this repo | Tradeoff |
|---|---|---|---|
| 1. `if: always()` guard job asserting on `needs.*.result` | A separate job that always runs, reads upstream `.result` strings, and `exit 1`s on a bad combination | `native-release-rollup` (release-please.yml:838-975): `if: ${{ always() }}`, reads `needs.publish-ios-core.result` etc. into shell vars, computes a state machine, and does `exit 1` when `native_core != "complete"` while something was released. This is the load-bearing in-repo precedent. | Requires the asserting job to be a *separate* job from the thing being asserted about (a job cannot gate on its own result). Composes cleanly with `workflow_call` — the reusable workflow's *last* job can be this shape. |
| 2. Move the condition from job-level `if:` into a failing step | Job runs unconditionally (or with a coarse "is this applicable at all" `if:`); the record-presence check is a `run:` step that `exit 1`s if the record is absent, rather than the whole job being skipped by `if:` | `approved-release-guard`'s own `guard` step (release-please.yml:29-99) — the entire job runs unconditionally, and `emit_output "linked_release=false"` plus `exit 0` early-returns are used for *legitimate* non-applicability, while every other failure mode in that same step is a bare `[ cond ]` that trips `set -euo pipefail` and fails the job. This is the closest existing precedent for "distinguish real not-applicable from a defect," and is the shape recommended for `exact-public-proof`'s redesign (see "Recommended approach"). | Requires care to keep "not a linked release at all" (legitimate skip-equivalent) distinguishable from "linked release but record missing" (must be a hard failure) — solved by making only the *first* an early-`exit 0`-with-marker and the *second* a bare failing assertion, mirroring `approved-release-guard`'s own two-tier logic. |
| 3. Required-status-check registration (branch protection) | Mark the job as a required status check in repository settings so its absence blocks the PR/merge regardless of `if:` | No in-repo precedent found (branch protection config is not visible from the checked-out tree; would need to be verified via `gh api repos/.../branches/main/protection`, which is out of this phase's file scope). Also does not apply here at all: `exact-public-proof` runs on `push`-triggered release-please.yml AFTER merge, and on `workflow_dispatch` for recovery — neither is a PR check, so "required status check" registration is the wrong lever for a post-merge/post-dispatch proof. | Rejected: wrong trigger class for this job. |
| 4. Rollup assertion (aggregate multiple children, fail on any non-success) | `Workflow.rollup!/1` / `linked-release-rollup` job | Already exists and already treats `exact_public: "skipped"` as `!= "success"` (see section E) — this is the *downstream* backstop, not a substitute for fixing `exact-public-proof` itself. Criterion 3 is explicitly "keep this working," not "use this instead of B." | Not a replacement for shapes 1/2 — the rollup only sees the recovery path's `exact-public-proof` result *if that job is even wired into the recovery graph in the first place*, which is precisely what Criterion 1 must add. |

**Recommendation:** Combine shapes 1 and 2. Inside the (now-reusable) `exact-public-proof` workflow:
a first step determines applicability using the same two-tier pattern as `approved-release-guard`
(early, marked, `exit 0` for "not a linked release at all" / not this phase's concern; everything
else proceeds); a second step requires the publication-record artifact to exist for the exact
`{package, version, approved_head}` triple and does a bare failing assertion (no `||true`, no
`continue-on-error`) if it does not. The job's own `if:` at the YAML level should be reduced to
`if: always()` (or removed entirely, letting the internal steps carry all the logic) precisely so
that a missing record surfaces as `failure`, not the current `skipped`.

## C. Publication-record signal — what exists vs. what must be built

**Nothing that already fits exists.** I read both publish paths end-to-end:

- `publish-hex` (release-please.yml:225-267) → `guarded_hex_publish.sh crosswake <version> <tag> --approved-head ... --approved-tree ... --merge-oid ... --candidate-receipt ... --expected-version ...` → no step after it; no `upload-artifact`.
- `publish` (hex-publish.yml recovery job) → same helper script, same arguments shape, sourced from `workflow_dispatch` `inputs.*` instead of `needs.*.outputs.*` → likewise no artifact step after it.
- `guarded_hex_publish.sh` itself (355 lines, read in full): does version/identity validation, treats
  an exact already-live Hex release as success, calls `mix hex.publish`, polls for the exact release
  — and writes **no JSON output file** anywhere in its body (`grep -n "receipt\|json\|write"` returns
  only argument-parsing and preflight-request tempfiles, not an emitted receipt).

The nearest existing *artifact* is `phase168-candidate-receipt-${approved_head}` /
`phase168-candidate-ci-${approved_head}`, produced by the trusted iOS mirror workflow and by
Crosswake CI respectively, and consumed by `approved-release-guard` (release-please.yml:29-99) via
`gh run download`. Its JSON shape (read from the `jq -e` assertions in that job) is:

```
{state, identity:{bound:{head,tree,base,run:{id}}, observed}, external_state:{changed, publication},
 credentials:{exercised, mirror_write_authority}}
```

This is a **pre-merge approval receipt** — it exists to prove the candidate was clean *before*
Release Please opens/merges the release PR, and its `external_state.publication` field is asserted
to equal `"NONE"` (i.e., it specifically proves nothing was published yet). It is the wrong artifact
to extend for a post-publish signal — reusing it would invert its meaning. `[VERIFIED:
.github/workflows/release-please.yml:99-118 — jq assertion `.external_state.publication == "NONE"`]`

**What must be built (new, not reused):** a post-publish receipt, written by both `publish-hex` (and
its per-platform siblings for iOS/Android where XPUB scope requires it) and by `hex-publish.yml`'s
recovery `publish`/`recover-android-core` jobs, immediately after `guarded_hex_publish.sh` /
`android_publication.sh` returns success. Minimal shape, modeled on the existing receipt
conventions already used elsewhere in this workflow family (`schema_version`, exact hex fields, no
free-text):

```json
{
  "schema_version": "1.0.0",
  "package": "crosswake",
  "version": "0.2.1",
  "approved_head": "<40-hex>",
  "ref": "<tag or exact SHA that was actually checked out and published>",
  "path": "ordinary | recovery",
  "run_id": "<github.run_id>",
  "published_at": "<UTC ISO-8601>"
}
```

Upload via `actions/upload-artifact` under a deterministic name
(`publication-record-<package>-<approved_head>`), mirroring the existing
`phase168-candidate-receipt-<head>` naming convention so `exact-public-proof`'s new first step can
`gh run download --name` it the same way `approved-release-guard` already does for the pre-merge
receipt (i.e., the tooling pattern already exists in this repo; only the emitter is new).

## D. Retention

`[VERIFIED: gh api repos/szTheory/crosswake --jq '{private,visibility}']` → `{"private": false,
"visibility": "public"}`. Crosswake is a public GitHub repository.

`[CITED: web search summarizing docs.github.com/en/organizations/.../configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization]`:
- Default retention: 90 days.
- **Public repositories: the configurable range is 1–90 days.**
- **Private repositories: the configurable range is 1–400 days**, further capped by any managing
  organization/enterprise policy.
- `retention-days` in `actions/upload-artifact@v4` can be set per-artifact but cannot exceed
  whatever ceiling applies to the repository (public → 90).

This **refutes** the roadmap's flagged "up to 400 days, org policy permitting" for this repo
specifically: the 400-day figure is real, but it is gated on private-repo status, which crosswake
does not have. `[CITED, positive constraint — this is a declared range, not a governed absence]`

The account is a personal user account, not an organization (`gh api orgs/szTheory` → 404; owner
type `User`), so there is no org-level Actions settings page to check separately — the applicable
ceiling is the repository-level public-repo cap (90 days), full stop. `retention-days: 90` is the
maximum honest value to write into the `exact-public-proof` upload step; anything higher than 90
would either be silently clamped by GitHub or (per some reports) rejected — I did not find and did
not test which of the two GitHub actually does, so treat "what exactly happens if you write 400 on
a public repo" as **UNVERIFIED** (see Open Questions). Either way, 90 days is not "outlives
retention" for a repository that expects a multi-year lifetime, so raising `retention-days` is not
a sufficient fix for XPUB-06 on its own.

**Recommended alternative (matches the roadmap's own suggested alternative):** a durable,
git-committed release-ledger file — e.g. `docs/release-ledger/<version>.json` or an appended row in
a single `RELEASE-LEDGER.md`/`.jsonl` — written by a CI step as a normal commit (or via a
`pull_request` / direct-commit-to-main step with the repo's existing bot-commit conventions) once
`exact-public-proof` passes. This survives indefinitely (git history), requires no artifact
retention setting at all, and gives Criterion 4's own acceptance test ("confirmed by inspecting the
committed record after the retention window would otherwise have expired") a trivial, deterministic
way to pass: `git log`/`cat` the ledger file, no waiting 90 days required to prove the property
holds architecturally.

## E. Non-vacuity — a falsifiable test per Success Criterion

Both named traps apply here and were checked directly:

- **SEED-019 (scope-selector vacuity):** if this phase's new "does the publication record exist"
  check derives its roster of packages/paths to check from the artifact it is verifying (e.g.,
  "check every package listed in the receipt" rather than "check every package the release actually
  touched"), a receipt that's missing an entry for one package would silently exclude that package
  from scrutiny rather than failing. **Mitigation:** the roster of packages/platforms to check must
  come from `needs.release-please.outputs.paths_released` (or the approved-manifest, an independent
  source), never from the publication-record artifact's own contents.
- **SEED-020 (column-scope vacuity):** if the new check reads the record but asserts against the
  wrong field (e.g., confirms the artifact exists but never actually compares its `version`/
  `approved_head` fields against the run's own `needs.approved-release-guard.outputs.*`), the
  assertion runs against a real non-empty subject but proves nothing. **Mitigation:** the
  non-vacuity test must include a fixture where the record exists but with a *mismatched* version or
  head, and assert the job still fails — not just a fixture where the record is entirely absent.

Falsifiable test per criterion:

1. **Criterion 1 (needs: satisfied identically):** two workflow-integrity fixtures (see section F) —
   one modeling `release-please.yml`'s post-publish graph, one modeling `hex-publish.yml`'s recovery
   graph — both asserting the same reusable-workflow `uses:` target and the same publication-record
   step sequence exists in both. A mutation that deletes the record-writing step from only the
   recovery fixture must turn its half of the test red while the ordinary fixture stays green
   (proves the test actually distinguishes the two graphs rather than trivially passing on both).
2. **Criterion 2 (missing record -> failed, not skipped):** an integration-level Elixir test (or a
   local-mode invocation of whatever script backs the new "assert record present" step) run twice:
   once with a receipt file present (asserts job would proceed / exit 0) and once with it absent
   (asserts exit code is non-zero AND the emitted message names "record missing" specifically, not a
   generic error) — mirroring the existing pattern in `check_release_workflow_integrity.exs` of
   invoking real script logic against fixture inputs rather than only grepping YAML text.
3. **Criterion 3 (rollup fail-closed unchanged):** extend
   `test/crosswake/release_candidate/workflow_test.exs` with the missing case identified in the
   Phase Requirements table above — `exact_public: "skipped"` while `hex`, `ios_mirror`, `android`,
   `ios_public_proof`, `android_public_proof` are all `"success"` — and assert `result.state ==
   "PARTIAL"` (never `"COMPLETE"`). This is the exact combination the current test suite does not yet
   cover (today's "every child failure" test only ever sets `exact_public` to `"failed"`, at the last
   iteration of its loop, with everything after it — nothing — also skipped; it never covers
   "everything else succeeded, only exact_public came back skipped").
4. **Criterion 4 (durable evidence):** a test that writes a ledger entry, then independently reads it
   back via a fresh `git show <commit>:<path>` (not via the same process's in-memory state) and
   asserts the fields match — demonstrating the record does not depend on the artifact store at all.
   A mutation that deletes the ledger-write step must turn this test red.

## F. Fixture strategy — can this be proven without a live publish?

Yes, and this repo already has the exact machinery needed, extended rather than invented:

- `script/check_release_workflow_integrity.exs` is a pure static/text checker over YAML files, and
  its `run/2` entry point (`script/check_release_workflow_integrity.exs:106`) already accepts
  environment-variable overrides for every file path it reads —
  `RELEASE_WORKFLOW_PATH`, `HEX_PUBLISH_WORKFLOW_PATH`, `GUARDED_HEX_PUBLISH_PATH`,
  `CLEANROOM_SCRIPT_PATH`, `RELEASE_PLEASE_CONFIG_PATH`, `RELEASE_PLEASE_MANIFEST_PATH`,
  `CROSSWAKE_CI_WORKFLOW_PATH`, etc. `[VERIFIED: script/check_release_workflow_integrity.exs:106-160]`
  This means a fixture "ordinary graph" and fixture "recovery graph" can each be a small standalone
  YAML file under (e.g.) `test/fixtures/release_workflow/`, pointed at via these env vars, and
  exercised by `mix test` / `elixir script/check_release_workflow_integrity.exs` with no live GitHub
  Actions run at all — this is exactly how `release-candidate-fixtures`
  (`.github/workflows/crosswake-ci.yml:136-163`) already runs the checker today (against the real
  files, not fixtures, in the current CI job — but the override mechanism the checker exposes is
  fixture-ready and unused elsewhere in the repo so far).
- `release-candidate-fixtures` (crosswake-ci.yml) is the hermetic, always-runs lane: `mix test
  test/crosswake/release_candidate ... && elixir script/check_release_workflow_integrity.exs`. It
  has no network/credential dependency and is the natural home for this phase's new structural
  tests.
- `release-as-staleness-proof` (`crosswake-ci.yml:435`) is unrelated to this phase's needs — it
  checks `release-as:` pins against published tags via `./script/check_release_as_staleness.sh`, a
  different concern (stale version pins in `release-please-config.json`), not job-graph shape. It
  does not extend to this phase; it was checked and ruled out rather than assumed irrelevant.

**Important limit on what static fixtures can prove:** `check_release_workflow_integrity.exs` reads
job blocks as **text** (`job_block/2`, `includes?/2` grep-style helpers) — it can prove "this
`needs:`/`if:`/step exists in this YAML shape" but cannot execute GitHub's own scheduler to observe
whether a real run reports `skipped` vs `failed`. That distinction is GitHub Actions' own runtime
behavior, not something a local Elixir script can execute. For genuine non-vacuity on Criterion 2's
runtime claim ("the job's result is `failed`, not `skipped`"), the phase needs **one real
`workflow_dispatch` observation** — e.g., a scoped test dispatch of the (new) recovery-path proof
job with a deliberately-absent record, then `gh run view --json jobs` to confirm the job's own
`conclusion` is `failure` and not `skipped`. This cannot be faked by a static fixture without
risking a Shape-B-flavored vacuity of its own (a text assertion that the YAML *should* fail
open, standing in for evidence that it *actually does*). Static fixtures should carry the bulk of
the proof surface (fast, hermetic, PR-blocking); one live dispatch observation should be the
capstone non-vacuity evidence for Criterion 2 specifically, recorded in `173-VERIFICATION.md`'s
`non_vacuity_evidence` field per the milestone's vacuity-taxonomy convention.

## Recommended approach

1. Extract `exact-public-proof`'s body into a new reusable workflow file, e.g.
   `.github/workflows/exact-public-proof.yml`, `on: workflow_call:` with inputs
   `package`, `version`, `approved_head`, `merge_oid` (or equivalent) and no `secrets:` (it needs
   none beyond `github.token`, already ambient).
2. In `release-please.yml`, replace the current `exact-public-proof` job body with a `uses:` call to
   the new reusable workflow, keeping its existing `needs:` list on the publish/clean-room jobs
   (ordinary path is otherwise unchanged).
3. Add a post-publish "write publication record" step to `publish-hex` (and, if XPUB scope requires
   it for this phase, `publish-ios-core`/`publish-android-core`) and to `hex-publish.yml`'s
   `publish`/`recover-android-core` jobs — identical JSON shape, uploaded as
   `publication-record-<package>-<approved_head>`.
4. Add a new job to `hex-publish.yml`: `needs: [publish]`, `if: always() && needs.publish.result ==
   'success'`, that `uses:` the same reusable `exact-public-proof.yml`, passing the recovery
   `workflow_dispatch` inputs as its call inputs.
5. Inside `exact-public-proof.yml`'s own job: replace the job-level `if:` gate with `if: always()`;
   move the "is this even applicable" check and the "does the publication record exist for this
   exact triple" check into the first two steps, using the two-tier early-`exit 0`-vs-bare-assertion
   pattern already used by `approved-release-guard`. A missing record must be a bare failing
   assertion (no gate hides it as a skip).
6. Leave `Workflow.rollup!/1` and `linked-release-rollup` untouched (Criterion 3 explicitly wants
   this), but add the missing test case identified in section E.3.
7. For Criterion 4, add a committed release-ledger write step (new file or appended row) rather than
   raising `retention-days` past its already-adequate current value of 14 — 14 vs. 90 is not the
   axis that matters once the artifact is not the durable copy of record.
8. Non-vacuity evidence: static fixtures (section F) for Criteria 1 and most of 3; one real
   `workflow_dispatch` observation of the new recovery-path job with a deliberately-missing record,
   captured via `gh run view --json jobs`, for Criterion 2's runtime claim specifically.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-workflow job reuse | A second copy of `exact-public-proof`'s steps pasted into `hex-publish.yml` | `workflow_call` reusable workflow | Two copies of the same proof body will drift (this milestone's own repeated failure mode — see PITFALLS.md Pitfall 4, and SEED-020's analogous "two representations of the same fact, one goes stale") |
| "Did the record exist" check | A bespoke `if:` YAML expression comparing artifact-list JSON inline | A dedicated script/step with `gh api .../actions/artifacts` + `jq -e`, mirroring `approved-release-guard`'s existing pattern | The existing job already solves "does exactly one unexpired artifact named X exist" correctly and defensively (`length == 1`, not just `>= 1`) — copy that idiom rather than reinventing a looser one |
| Durable proof-outcome storage | A second artifact with `retention-days: 90` treated as "durable enough" | A git-committed ledger file | 90 days is this repo's real ceiling (public repo) and is not durable on this project's timescale |

## Common Pitfalls

### Pitfall 1: Treating `workflow_call` extraction as sufficient by itself
**What goes wrong:** Wrapping `exact-public-proof` in `workflow_call` without also fixing its
internal `if:`-based skip logic leaves Criterion 2 unsatisfied — the reusable workflow can still
report `skipped` to its caller if its own internal job-level `if:` still gates on `needs.*`.
**Why it happens:** `workflow_call` solves "callable from two places" (Criterion 1) and is easy to
conflate with "fails instead of skips" (Criterion 2), which is a separate, orthogonal fix.
**How to avoid:** Treat sections A and B of this document as two separate, both-required changes.
**Warning signs:** A PR that touches only workflow file structure (moving YAML into a new file) with
no change to the `if:`/step logic inside it.

### Pitfall 2: Reusing the pre-merge candidate receipt as the post-publish signal
**What goes wrong:** `phase168-candidate-receipt-*` asserts `external_state.publication == "NONE"`
— extending it to also carry a post-publish state would require flipping that same field's meaning
depending on when it's read, silently breaking `approved-release-guard`'s own assertion.
**Why it happens:** It's the only artifact in the codebase with a similar name/shape, so it's
tempting to extend rather than add a second, purpose-built artifact.
**How to avoid:** Build a distinct, post-publish-only receipt (section C) with its own name prefix.
**Warning signs:** Any diff that adds fields to the `candidate-receipt.json` schema or to the
`approved-release-guard` job's `jq -e` assertions as part of this phase.

### Pitfall 3: Assuming 400-day retention is available because "GitHub docs mention 400"
**What goes wrong:** Setting `retention-days: 400` (or any value over 90) on a public repo's
artifact either gets silently clamped or rejected at workflow-parse time — either way, Criterion 4's
acceptance bar ("confirmed by inspecting the committed record after the retention window would
otherwise have expired") cannot be met by this path at all for this repo.
**Why it happens:** The 400-day figure is the most commonly cited number in GitHub Actions
documentation and blog posts, without the public/private qualifier being equally prominent.
**How to avoid:** Use the committed-ledger approach (section D) as the primary mechanism; do not
spend implementation effort tuning `retention-days` beyond a reasonable value (the current 14 is
already fine as a *fast-path* signal, independent of the ledger).
**Warning signs:** A plan task titled "raise retention-days to 400" or similar.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Single monolithic `exact-public-proof` job living only in `release-please.yml` | Reusable `workflow_call` body invoked from both the ordinary and recovery workflows | This phase | Recovery-path publishes gain the same byte-exact proof coverage the ordinary path already has |
| No post-publish receipt in either lane | A purpose-built `publication-record-<package>-<approved_head>` artifact, written by both lanes | This phase | Gives `exact-public-proof` something concrete to `needs:`/assert against regardless of which lane produced it |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | An arbitrary number of caller workflows may `uses:` the same reusable workflow with no documented hard limit | A | If GitHub silently imposes an undocumented cap, the two-caller design (release-please.yml + hex-publish.yml) would still be far under any plausible limit — low risk |
| A2 | Writing `retention-days` above the repo's ceiling (90, public) either clamps or errors, but which one was not tested | D | If it silently clamps, a plan that "sets retention-days: 400 to be safe" produces no error and a false sense of durability; the committed-ledger recommendation sidesteps this either way |
| A3 | `guarded_hex_publish.sh` and `android_publication.sh` can have a receipt-writing step appended without disturbing their existing exit-code/idempotency behavior (e.g., "already published, treat as success") | C | If the already-live-success path exits before a hypothetical in-script receipt write, the receipt step must live in the *workflow* YAML (as a separate step after the script call), not inside the script itself — this is reflected in the Recommended Approach, which places the write as a separate workflow step, not a script-internal change |

**If this table is empty:** N/A — see rows above.

## Open Questions

1. **Does GitHub reject or silently clamp `retention-days` values above a public repo's 90-day
   ceiling?**
   - What we know: the ceiling itself (90 for public, 400 for private) is documented.
   - What's unclear: the exact failure mode of specifying a too-high value in `actions/upload-artifact@v4`'s `with.retention-days`.
   - Recommendation: irrelevant to the final design if the committed-ledger approach is adopted (recommended); if the team still wants a artifact-only fallback, verify empirically with one real workflow run before relying on any specific clamp behavior.

2. **Should the per-platform publish jobs (`publish-ios-core`, `publish-android-core`) also get a
   publication-record step in this phase, or is Hex-only sufficient for XPUB-04's first cut?**
   - What we know: `exact-public-proof`'s `needs:` list already includes all three publish jobs plus
     both clean-room proofs for the ordinary path; XPUB scope language says "package, version" (singular "package"), which reads Hex-centric.
   - What's unclear: whether the recovery path's iOS/Android recovery jobs (`recover-android-core` in `hex-publish.yml`) are in this phase's scope or a later phase's (Phase 174, "Clean-Room Host Realism," is the next phase and may own native-platform recovery specifically).
   - Recommendation: scope this phase's implementation to the Hex recovery lane first (it's the one named "recovery" in `hex-publish.yml`'s own `operation: recovery` choice, and is the lane the roadmap's Success Criteria most directly describe), and flag native-platform recovery convergence as a candidate follow-up for Phase 174 rather than silently expanding this phase's surface.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` CLI (authenticated) | Verifying repo visibility, artifact listing, and (later) a real workflow_dispatch observation for Criterion 2 | Yes | (ambient in this session) | — |
| GitHub Actions (`workflow_call`) | Core mechanism for Criterion 1 | Yes — standard GitHub.com feature, no opt-in required | — | — |
| Elixir/`mix` toolchain | Running `test/crosswake/release_candidate/*` and `check_release_workflow_integrity.exs` fixtures | Not probed this session (no `mix`/`elixir` invocation was run) | — | Assume available; every prior phase in this milestone depends on it and none flagged it missing |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`), plus a standalone Elixir script (`elixir script/check_release_workflow_integrity.exs`) for structural YAML checks |
| Config file | `mix.exs` / `test/test_helper.exs` (not modified by this phase) |
| Quick run command | `mix test test/crosswake/release_candidate --max-cases 1 && elixir script/check_release_workflow_integrity.exs` |
| Full suite command | `mix test` (full 1861+ test suite per Phase 172's verification record) |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| XPUB-04 | Both lanes' fixtures satisfy the same `needs:`/`uses:` shape | unit (text-fixture) | `elixir script/check_release_workflow_integrity.exs` against two fixture files via env-var override | ❌ Wave 0 — new fixture files and new roster checks needed |
| XPUB-05 | Missing record -> job `failure`, not `skipped` | unit + one live dispatch | `mix test test/crosswake/release_candidate/workflow_test.exs` (script-level assertion) + one real `gh workflow run` / `gh run view --json jobs` | ❌ Wave 0 — new assertion script and one manual dispatch |
| XPUB-06 | Ledger entry survives independent of artifact retention | unit | new test reading a committed ledger fixture via `git show` or plain file read | ❌ Wave 0 |
| XPUB-07 | `exact_public: "skipped"` with all-else `"success"` still yields `"PARTIAL"` | unit | `mix test test/crosswake/release_candidate/workflow_test.exs` | ❌ Wave 0 — new test case in an existing file |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/release_candidate --max-cases 1 && elixir script/check_release_workflow_integrity.exs`
- **Per wave merge:** full `mix test`
- **Phase gate:** full suite green, plus the one live `workflow_dispatch` observation recorded in `173-VERIFICATION.md`, before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] Fixture YAML files for "ordinary graph" and "recovery graph" under a new `test/fixtures/release_workflow/` (or similar) directory, wired via `check_release_workflow_integrity.exs`'s existing env-var overrides
- [ ] New/extended `test/crosswake/release_candidate/workflow_test.exs` case: `exact_public: "skipped"` with all other children `"success"` -> `"PARTIAL"`
- [ ] New test(s) covering the publication-record presence/absence assertion script
- [ ] New test covering the committed release-ledger read-back

*(No existing test infrastructure gap beyond the above — the framework itself, `mix test` +
`check_release_workflow_integrity.exs`'s env-var-override design, already covers this phase's needs
architecturally.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | This phase does not touch who may trigger recovery (`workflow_dispatch` input validation is pre-existing and unchanged) |
| V3 Session Management | No | N/A |
| V4 Access Control | Marginal | The new reusable workflow's `permissions:` block must stay minimal (`actions: read`, `contents: read` — matching the current `exact-public-proof` job) and must NOT gain `secrets: inherit` unless a genuine need is found (none identified this session) |
| V5 Input Validation | Yes | The publication-record artifact's fields (`package`, `version`, `approved_head`) must be validated with the same strict exact-hex/exact-semver patterns already used throughout `hex-publish.yml` (`grep -Eq '^[0-9a-f]{40}$'` etc.) — copy the existing idiom, do not loosen it |
| V6 Cryptography | No | N/A — no new cryptographic operation introduced |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| A forged/replayed publication-record artifact used to fool `exact-public-proof` into passing without a real publish | Spoofing | Bind the record to the exact `{package, version, approved_head}` triple already authenticated by `approved-release-guard` / the `workflow_dispatch` input validation in `hex-publish.yml`; do not accept a record whose fields don't match the calling job's own trusted inputs |
| A `workflow_call` reusable workflow granted `secrets: inherit` when it does not need any secret | Elevation of Privilege | Omit `secrets:` entirely on the new reusable workflow (confirmed it needs none — reads only `github.token`, which is ambient) |

## Sources

### Primary (HIGH confidence)
- Direct repository reads this session: `.github/workflows/release-please.yml`,
  `.github/workflows/hex-publish.yml`, `.github/workflows/crosswake-ci.yml`,
  `script/check_release_workflow_integrity.exs`, `script/guarded_hex_publish.sh`,
  `lib/crosswake/release_candidate/workflow.ex`,
  `test/crosswake/release_candidate/workflow_test.exs`,
  `.planning/seeds/SEED-019-*.md`, `.planning/seeds/SEED-020-*.md`,
  `.planning/research/v23/PITFALLS.md` (Pitfall 4), `.planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md`,
  `.planning/workstreams/quality-ratchet-release/phases/172-per-package-proof-scope/172-VERIFICATION.md`
- Direct `gh api` queries this session: `repos/szTheory/crosswake` (visibility), `orgs/szTheory`
  (account type), `repos/szTheory/crosswake/actions/artifacts` (artifact shape/expiry sample)

### Secondary (MEDIUM confidence)
- `[CITED: docs.github.com/en/actions/using-workflows/reusing-workflows]` — `workflow_call`
  mechanics, nesting limit, secrets inheritance, output access (via WebFetch of the official page)
- `[CITED: docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization]`
  — public vs. private retention ceilings (via WebSearch summary of the official page; not
  independently re-fetched page-by-page this session)

### Tertiary (LOW confidence)
- None relied upon for load-bearing claims in this document.

## Metadata

**Confidence breakdown:**
- Standard stack / mechanism choice (`workflow_call`): MEDIUM — sourced from official docs, not
  independently exercised against a live dispatch in this repo this session
- Retention ceiling (90 vs. 400): HIGH — directly confirmed via `gh api` that the repo is public, and the public/private ceiling split is an explicit, positive documented constraint (not an absence)
- Publication-record signal absence: HIGH — verified by reading both publish jobs and the full 355-line `guarded_hex_publish.sh` end-to-end
- Rollup fail-closed behavior (Criterion 3 baseline): HIGH — read `Workflow.rollup!/1` source directly and the existing test file that exercises it

**Research date:** 2026-09-17
**Valid until:** 2026-10-17 (30 days — GitHub Actions platform features change; re-verify `workflow_call` nesting/secrets rules if the phase is replanned significantly later than this window)
