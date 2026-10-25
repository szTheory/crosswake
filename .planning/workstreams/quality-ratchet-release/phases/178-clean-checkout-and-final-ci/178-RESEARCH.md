# Phase 178: Clean Checkout and Final CI - Research

**Researched:** 2026-10-12  
**Domain:** Exact-source repository verification, private local evidence, GitHub Actions proof identity  
**Confidence:** HIGH for checked-in verifier and workflow contracts; MEDIUM for mutable hosted CI and current execution environment

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Apply the user's earlier direction to consider all relevant areas, research with subagents, compare tradeoffs, stress-test the result, and automatically follow a coherent recommendation set. This is delegated discussion judgment, not a new user reply approving a GitHub operation. No preference questionnaire or automatic plan/execute chain is selected.
- **D-02:** Include all six completed Phase177 source edits: README.md; docs/COMPANION-PUBLISH-RUNBOOK.md; docs/RELEASE-INCIDENT-RESPONSE.md; test/crosswake/guides/release_boundaries_test.exs; test/crosswake/release_candidate/companion_receipt_test.exs; test/crosswake/release_candidate/evidence_gate_test.exs. Omitting one requires an evidence-backed disposition. Green proof for unchanged merged source cannot silently replace proof of these outputs.
- **D-03:** Preserve the recovery checkout's source bytes, HEAD, index, branch, and worktree arrangement. Scoped planning/evidence/handoff writes may occur here; source preparation, Mix, generation, package builds and Git source delivery must occur in a qualified independent surface. Do not stage, commit, reset, clean, switch branches or create a worktree in the protected checkout.
- **D-04:** Consume Phase177's source binding and exact private owner-bundle replay rather than reconstructing changes from the dirty recovery tree. Its attested base is d0dbdf7bf196cea167ced3c50cf620bf3cb2452b. Recheck canonical base/source facts during execution. If the proposed base changes, reconcile the six edits and bounded source delta explicitly, preserve unique bytes, and renew the binding; do not treat textual merge safety as semantic approval.
- **D-05:** Use a supported independent full-clone delivery mechanism, then a fresh clean exact-commit proof checkout. The existing Phase177 clone is a preparation surface with six modifications and ignored build outputs. Shared worktree data/refs or copied preparation caches do not establish independent clean-source proof. Verify repository identity, exact commit/tree, complete tracked/untracked candidate paths, and expected source bytes.
- **D-06:** Build a bounded local candidate commit in the qualified separate delivery surface as reversible execution preparation, with its base, six-file selection and resulting tree bound in the plan. This does not grant Git authority in the recovery checkout. Keep local commit construction distinct from remote proposal delivery and from the final runner-tested commit; this discussion performs none of them.
- **D-07:** Retain all 119 Phase176 captured rows and private recovery material through Phase178 and unresolved preservation decisions. The two historical reader comparisons remain unproven and preserved. Do not restore the absent old launchers, call them newly retired/equivalent, alter their archived verdicts, or include the private preservation archive in the source proposal.

### Complete local verification

- **D-08:** MAINT-07 requires one completed `script/verify_repository.sh --all` invocation from the selected exact clean commit. Account for all nine existing stages in manifest order: repository-preflight, root-proof, example-host-proof, browser-proof, ios-package-proof, android-package-proof, format-proof, warnings-proof, repository-cleanliness. Individual `--stage` runs are useful diagnosis, not a substitute completion gate.
- **D-09:** Prepare the toolchain according to the selected source's existing stage manifest and .tool-versions. Version rules include exact Node 22.14.0, npm 10.9.2, Elixir 1.19.5 and OTP27. The currently available Node26 is not an acceptable preflight substitute. Probe every declared prerequisite before the expensive run; missing, unsupported or skipped required tooling/stages remain non-passing. Reuse existing setup commands; do not weaken version rules to fit this machine.
- **D-10:** Resolve dependencies from the exact checkout's lockfiles, using locked Mix fetching and npm ci where supported by their existing owners. Do not copy Phase177 deps/build caches or bypass dependency checks. A private cache may accelerate retrieval only when package version, integrity and lock binding are verified. The Phase177 lazy_html mismatch is a concrete cache footgun, not permission to upgrade dependencies.
- **D-11:** Supply the facade's existing explicit private run-root/capture-root mechanism outside source so detailed logs and before/final status snapshots survive. Follow its validated root naming/parent and 0700/0600 modes. Default ephemeral logs are deleted; a summary without retained stage evidence is insufficient. Publish only allowlisted commands, source/run IDs, prerequisite versions, stage outcomes, counts, safe causes and remediation references. Raw subprocess logs remain private and are never copied wholesale into git or chat.
- **D-12:** Record HEAD, tree and index identity separately from NUL-delimited porcelain status before and after the full run. Require clean tracked/index/nonignored-untracked state, unchanged source identity, and no unexpected source mutation. Status alone omits ignored files and does not prove HEAD. Inspect ignored outputs through the existing artifact policy and declared owned-output rules; distinguish intentional build output from unexpected residue.
- **D-13:** Keep generated-contract regeneration and drift checks in the complete run. Use existing canonical sources/regeneration commands; do not reset generated changes merely to obtain clean status or waive a failed contract. The facade cleans only owned output roots created by that invocation; existing ignored roots are not proof of cleanliness. Never blanket-delete the preparation tree or private preservation material.
- **D-14:** Reuse ordinary Mix/ExUnit, companion lanes and the Phoenix host's current Playwright/Ecto SQLite isolation owners. Preserve the existing test/dev environment split, seeds, exclusions and subprocess contracts. Avoid concurrent runs sharing a host database, generated destinations or build directory. Existing Swift package and hermetic Android JVM/package checks remain required where the verifier names them; they do not add Android features/device proof or establish first-adopter physical support.

### Hosted CI and commit identity

- **D-15:** Reuse Crosswake CI, its existing classifier, leaf manifest, required control node and merge-blocking umbrella. Do not introduce a replacement verifier, new dispatch event, permanent reconciliation lane, dependency or dashboard to make this phase pass. Recheck the workflow and policy at the exact candidate source; a discussion roster is not executed CI evidence.
- **D-16:** Identify the actual commit checked out by the runner for the governed proof, with observed checkout provenance tied to run ID and attempt. A workflow-run or check-suite `head_sha`, PR badge, branch name, current merge ref, or green status alone cannot establish runner HEAD. Use the exact pinned workflow's checkout semantics plus retained allowlisted checkout evidence, corroborated by event/head/base and check metadata. Missing provenance is a named completion blocker, not an assumed SHA equality.
- **D-17:** The existing pull_request workflow normally tests GitHub's synthetic merge commit. That exact commit can be the final reviewed maintenance candidate without merging or publishing a package. Preserve/fetch its immutable object and run the complete local verifier from a fresh clean checkout of that same commit. Record it explicitly as an unmerged reviewed candidate; do not call it merged main. Tree equality alone does not replace the requirement's commit identity.
- **D-18:** Record source identity per job where checkout differs. In the inspected workflow, release-candidate-full-proof deliberately checks out the PR head; ordinary proof jobs use the merge checkout. Preserve that existing contract and name its head-specific evidence separately. It cannot substitute for local/hosted verification of the reviewed merge commit. If a required source contract is not covered, block completion rather than claiming every leaf tested the same SHA.
- **D-19:** Record canonical repository, workflow path/version, event, PR number when applicable, head/base SHAs, observed runner commit/tree, run ID/URL, suite/check identities, run attempt and observation time. Collect complete paginated jobs/checks for the bound attempt; recheck source/run/PR drift before acceptance. A current refs/pull/N/merge may have moved since the run, and previous attempts or older green runs cannot replace the selected source proof.
- **D-20:** Derive green from the existing governed graph and current required-check policy, including context/app identity where the policy specifies it. The inspected manifest has 46 proof leaves and classify-change as its control node; refresh that roster from selected source. Require control and umbrella success, every expected leaf accounted for, and only classifier/manifest-authorized skips. Missing jobs, unexpected skips, failures, neutral results, cancellations, incomplete metadata and inaccessible required policy are non-passing. Do not demand unrelated advisory jobs or enable frozen platform breadth.

### Failure handling, delivery authority and maintainer experience

- **D-21:** Fix demonstrated verification defects only within the bounded maintenance scope, in isolation, with meaningful regression coverage when needed. Prerequisite/network/permission failures get their actual safe cause and concrete next action. Do not shrink the test population, waive required stages, invent passed fixture fields, upgrade dependencies opportunistically or revive consumed release attempts. After any source change, bind a new candidate and rerun affected diagnosis plus the complete final-source gate; previous final proof is stale.
- **D-22:** Complete authorized local preparation, diagnosis, source review and verification before presenting any genuinely new remote operation. Prepare a concrete non-release maintenance proposal with exact repository/branch/base/head, diff, validation and action. Check existing session authority; when missing, ask once for that specific delivery scope. No routine read/precheck/parser/bookkeeping approval loops. No force/delete/admin bypass, release-please lifecycle change, merge, tag or publication is selected, and Phase175 standing release authority does not transfer.
- **D-23:** If proposal CI uses a different synthetic merge commit from the locally prepared candidate, preserve preliminary local proof and repeat `--all` on the actual runner-tested commit before closeout. Bound retries to observed causes; uncertain remote delivery requires read reconciliation, not an automatic duplicate write. Unavoidable credentials/external approvals remain exact last-mile gates, after independent work is finished.
- **D-24:** Report the maintainer's job plainly: what command ran, which source it checked, which stages/checks passed or failed, the cause, whether source changed, and the next action. Detailed lifecycle/digest bookkeeping belongs in linked artifacts. Automated assertions own UAT; no human confirmation substitutes for machine-checkable proof. Preserve Phase175's 8/9 and REL-10 breach and the parked adopter's sanitized-input/signed-device gates.
- **D-25:** Mark MAINT-07/08 complete only after their respective evidence passes and local/hosted source bindings agree. Until then preserve pending requirement status and an exact eligible GSD handoff. Final requirement proof is distinct from source merging, package shipping, v24 milestone archival and private archive retirement; none follows automatically from this discussion.

### the agent's Discretion

The planner may choose bounded evidence filenames, existing safe setup/cache paths, scheduling that avoids shared mutable resources, and a small phase-local stdlib evidence join where existing artifacts need reconciliation. Resolve minor implementation choices without another preference questionnaire. Keep the public command, prerequisite rules, source/policy guards and privacy boundary intact. No public API, Plug/Ecto/Phoenix architecture change or visual redesign is needed.

### Deferred Ideas (OUT OF SCOPE)

Remote maintenance delivery awaits a concrete scoped operation and authority check during execution. Release selection, merging, publication, lifecycle changes to other queue objects, milestone archival and private archive deletion are separate actions. New workflows/dependencies, a permanent reconciliation lane, broader audits, Android/mobile features, UI/brand polish and adopter promotion remain outside this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAINT-07 | Maintainer can run the existing repository verification command from an exact clean checkout and inspect its results and before/after Git status. [VERIFIED: `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:25`] | Existing facade, nine-stage manifest, private run-root/capture-root, status snapshots, exact tool probes, artifact policy, and meaningful verifier regression suite. |
| MAINT-08 | Maintainer can inspect green CI bound to the final source commit; results from an older or different commit do not satisfy this requirement. [VERIFIED: `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:26`] | Existing PR workflow, per-job checkout semantics, 46-leaf manifest, classifier control, merge-blocking umbrella, and retained observed runner checkout provenance. |
</phase_requirements>

## Summary

Phase 178 should carry the six Phase 177 edits through the already attested source binding into a bounded local candidate, then run the existing full verifier from a fresh, exact-commit checkout. Planning should model two distinct Git identities: the locally prepared candidate and the actual PR synthetic merge commit tested by hosted CI. The PR merge commit can be the unmerged reviewed candidate if the complete local run uses that same commit; the head-only release-candidate leaf remains its own named source contract. [CITED: `178-CONTEXT.md` D-02–D-06, D-08, D-16–D-18; `178-DISCUSSION-LOG.md` §Source selection and §Hosted CI]

The selected source was inspected read-only at the attested base `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, tree `12a0f1bf3c32ecdde0326f4a288b597b11e33b06`, with six working-tree modifications corresponding to the approved edits. Phase 177's source-binding and semantic-reconciliation artifacts remain the authority for exact owner-bundle replay; don't reconstruct patches from the dirty recovery checkout or include private preservation material. [VERIFIED: `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-08-SUMMARY.md:75-90,143`; `178-CONTEXT.md:22-27`]

**Primary recommendation:** Reuse the existing source-bound replay, `script/verify_repository.sh --all`, its retained private run-root mechanism, and the current Crosswake CI graph. Keep raw logs private; accept MAINT-07/08 only when all required local stages and governed CI checks bind to the observed runner-tested commit. No new package or verification framework is indicated. [CITED: `178-CONTEXT.md` D-08–D-20]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Candidate source assembly and commit identity | Repository / Git | Phase-local evidence | The candidate's base, six selected files, resulting tree, index and worktree must be explicit and independently reproducible. [CITED: `178-CONTEXT.md` D-02–D-06, D-12] |
| Complete local verification | Repository tooling | Local toolchain | The repo facade owns stage selection, prerequisite probes, stage outcomes, cleanup, generated-contract checks and status snapshots. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:440-569`] |
| Hosted proof and required-check policy | GitHub Actions | Phase-local evidence | Workflow jobs own execution; the classifier, leaf manifest, required control and umbrella own the expected graph and closed outcome semantics. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/.github/workflows/crosswake-ci.yml:13-30`; `/private/tmp/crosswake-177-source/crosswake/script/check_ci_leaf_manifest.py:22-79`] |
| Retained proof evidence | Private local filesystem | Phase evidence artifact | Detailed stage logs and raw Git snapshots can contain paths/output; retain them under private permissions and publish only an allowlisted projection. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:290-303,452-471,529-569`] |

## Standard Stack

### Core

| Tool | Required version | Purpose | Source of truth |
|------|------------------|---------|-----------------|
| Bash | 5.x or 3.2 (manifest regex) | Facade and repository scripts | `repository_verification_stages.json` |
| Git | 2.x or newer (manifest regex) | Candidate and exact checkout identity | `repository_verification_stages.json` |
| Node.js | exactly 22.14.0 | Facade, tests, scripts | `.tool-versions` and stage manifest |
| npm | exactly 10.9.2 | Lockfile installation for Phoenix host | Stage manifest |
| Elixir | 1.19.5 on OTP 27 | Mix/ExUnit and companion stages | `.tool-versions` and stage manifest |
| Erlang/OTP | 27 (`.tool-versions` pins 27.3) | BEAM runtime | `.tool-versions` and stage manifest |
| Swift / Xcode | Swift 5.9 or 6.x; Xcode 15+ | Existing iOS package proof | Stage manifest |
| Java / Gradle wrapper | Java 17; Gradle 8.7 | Existing hermetic Android JVM/package proof | Stage manifest |

The source-of-truth lines read this session say `.tool-versions` contains `"erlang 27.3"`, `"elixir 1.19.5-otp-27"`, and `"nodejs 22.14.0"` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/.tool-versions:1-3`]. The full-stage manifest's exact probe rules include `"version (5\\.|3\\.2)"`, `"git version [2-9]\\."`, `"^v22\\.14\\.0$"`, `"^10\\.9\\.2$"`, `"Elixir 1\\.19\\.5"`, and `"^27$"` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/repository_verification_stages.json:7-10,21-32,48-62`]. Use the manifest as the executable constraint; do not treat the broader CI setup as an override. The selected source requires `script/verify_repository.sh --all` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.sh:8-12`].

### Supporting

| Existing owner | Use | Lock / isolation rule |
|----------------|-----|-----------------------|
| Root Mix `verify` alias | Companion package tests plus core hermetic test partitions | Uses the existing fixed seed, tag exclusions, and companion lane ordering. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/mix.exs:67-93`] |
| Phoenix host Mix and Playwright | Example-host isolation matrix and browser suite | Preserve dev/test split and Playwright webServer ownership. Use `npm ci` with the tracked package lock. [CITED: `178-CONTEXT.md` D-10, D-14; npm ci documentation linked in `178-CONTEXT.md:145`] |
| Swift Package Manager and Gradle wrapper | Existing iOS and hermetic Android package checks | Keep Android connected tests disabled; these checks do not claim Android device support. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/repository_verification_stages.json:65-92`] |

No dependency addition or ecosystem refresh is selected. Resolve dependencies from the candidate's own lockfiles using the existing setup commands: root `mix local.hex --force`, `mix local.rebar --force`, and `MIX_ENV=test mix deps.get`; each of `packages/crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline` uses `MIX_ENV=test mix deps.get --check-locked`; the Phoenix host uses `MIX_ENV=dev mix deps.get`, `MIX_ENV=test mix deps.get`, `npm ci`, and `npx playwright install chromium`. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/capture_repository_verification_evidence.sh:155-160`; `/private/tmp/crosswake-177-source/crosswake/mix.exs:74-91`]

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing verifier and current CI graph | A replacement runner, new CI event, permanent reconciliation lane, or new dependency | Adds a second source of truth and broader maintenance surface without satisfying a requirement better. Rejected by locked D-15. [CITED: `178-CONTEXT.md:41`] |
| Fresh full clone and exact clean proof checkout | Shared worktree data/refs or copied preparation caches | Shared state does not establish independent clean-source proof; caches can carry stale or mismatched dependencies. Rejected by locked D-05 and D-10. [CITED: `178-CONTEXT.md:25,33`] |
| Observed runner checkout evidence | Workflow `head_sha`, check-suite SHA, branch name, badge, or current merge ref alone | Historical run evidence recorded distinct head and merge commits despite equal trees; these metadata fields cannot stand in for the actual job checkout. Rejected by locked D-16–D-19. [CITED: `178-CONTEXT.md:42-45,141`] |

**Installation:** No new packages. Follow the existing lockfile-based setup commands above; do not add dependencies or change lockfiles for this phase. [CITED: `178-CONTEXT.md` D-10, D-15]

## Package Legitimacy Audit

No new package is recommended or added. The selected setup resolves existing locked project dependencies through their current Mix/npm owners; package legitimacy review for a newly introduced package is therefore not applicable. [CITED: `178-CONTEXT.md` D-10, D-15]

## Architecture Patterns

### System Architecture Diagram

```text
Phase177 source binding + private owner bundle
        │ exact replay and six-file qualification
        ▼
Qualified separate delivery clone ── local bounded candidate commit
        │ immutable candidate commit/tree
        ├──────────────────────────────────────────┐
        ▼                                          ▼
Fresh clean exact-commit checkout           Existing pull_request workflow
        │ tool preflight                           │ synthetic merge checkout
        │ verifier --all                           ├─ 46 proof leaves
        │ nine manifest stages                     ├─ classify-change control
        │ private logs/status snapshots            └─ merge-blocking umbrella
        └────────────────────┬─────────────────────┘
                             ▼
       Join by observed commit, run/attempt, policy and complete results
                             │
                    pass or named blocker
```

The existing workflow is a `pull_request` workflow [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/.github/workflows/crosswake-ci.yml:6-8`]. `release-candidate-full-proof` explicitly checks out `github.event.pull_request.head.sha`, while ordinary proof jobs use the default event checkout; preserve and label those distinct identities. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/.github/workflows/crosswake-ci.yml:174-189`; CITED: `178-CONTEXT.md` D-17–D-18]

### Recommended Project Structure

No source structure change is needed. Keep only bounded Phase 178 evidence under `.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/`; keep private raw verifier logs and raw Git snapshots in a separate owner-only capture root outside the checkout. [CITED: `178-CONTEXT.md` D-03, D-11, D-24; `AGENTS.md` Sensitive Data Rules]

### Pattern 1: Replay and qualify the approved six-file candidate

**What:** Use Phase 177's complete source binding and exact private owner-bundle replay in an independent full clone. Bind the candidate base, exact six-file selection, complete tracked/untracked outputs and resulting tree. The selected base is `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, with tree `12a0f1bf3c32ecdde0326f4a288b597b11e33b06`; these are reproduced verbatim in the Phase 177 binding artifact and checked read-only in the selected clone. [VERIFIED: `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json` fields `baseCommit`, `baseTree`; current selected clone `git rev-parse HEAD HEAD^{tree}`; `177-08-SUMMARY.md:75-90`]

The exact approved path set is `"README.md"`, `"docs/COMPANION-PUBLISH-RUNBOOK.md"`, `"docs/RELEASE-INCIDENT-RESPONSE.md"`, `"test/crosswake/guides/release_boundaries_test.exs"`, `"test/crosswake/release_candidate/companion_receipt_test.exs"`, and `"test/crosswake/release_candidate/evidence_gate_test.exs"` [VERIFIED: `.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-CONTEXT.md:22`]. The preparation clone currently reports exactly those six modified paths; it is not the final clean proof checkout. [VERIFIED: selected independent clone read-only `git status --short`; `177-08-SUMMARY.md:143`]

**When to use:** Candidate construction and source qualification only. If the canonical base changes, explicitly reconcile all six edits and the bounded source delta, preserve unique bytes, and renew the source binding. [CITED: `178-CONTEXT.md` D-04–D-06]

**Avoid:** Rebuilding the edits from the recovery worktree, copying preparation caches, replaying the private preservation archive into source, or interpreting textual merge safety as semantic approval. [CITED: `178-CONTEXT.md` D-03–D-07]

### Pattern 2: One complete run with retained private evidence

**What:** Run `script/verify_repository.sh --all` once from a fresh checkout of the exact selected commit after probing all required tools. For retained evidence, set `CROSSWAKE_REPOSITORY_RUN_ROOT` to an existing private directory whose basename starts with `crosswake-repository-verify.` and whose parent is either the system temp directory or the matching `CROSSWAKE_REPOSITORY_CAPTURE_ROOT`. Create the parent and invocation directory with mode `0700`; the facade writes snapshots/logs with mode `0600`. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:290-303,452-471,529-569`; `/private/tmp/crosswake-177-source/crosswake/test/js/repository_verification.test.mjs:500-519`]

Example after setting a private capture directory variable to a real absolute path outside the checkout:

```bash
mkdir -m 700 "$CAPTURE_ROOT"
RUN_ROOT="$(mktemp -d "$CAPTURE_ROOT/crosswake-repository-verify.XXXXXX")"
chmod 700 "$RUN_ROOT"
CROSSWAKE_REPOSITORY_RUN_ROOT="$RUN_ROOT" \
  CROSSWAKE_REPOSITORY_CAPTURE_ROOT="$CAPTURE_ROOT" \
  script/verify_repository.sh --all
```

`CROSSWAKE_REPOSITORY_RUN_ROOT` and `CROSSWAKE_REPOSITORY_CAPTURE_ROOT` are the exact environment keys read by the production CLI [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:587-590`]. The retained root contains `"git-before.z"` and `"git-final.z"` status snapshots and `"logs"` stage records [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:460-461,529-530,556-564`; `test/js/repository_verification.test.mjs:500-519,624-638`]. Without an explicitly supplied run root, the facade removes its temporary root after the run [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:451-453,567-569`].

The root prefix is `"crosswake-repository-verify."`; the facade emits closed result strings including `"PASS"`, `"FAIL"`, and `"BLOCKED"` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:275-287,290-297,467-471,491-498,529-546`]. All nine full-run stage IDs are quoted verbatim in the manifest: `"repository-preflight"`, `"root-proof"`, `"example-host-proof"`, `"browser-proof"`, `"ios-package-proof"`, `"android-package-proof"`, `"format-proof"`, `"warnings-proof"`, `"repository-cleanliness"` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:14`; `/private/tmp/crosswake-177-source/crosswake/script/repository_verification_stages.json:5-129`].

**When to use:** A complete MAINT-07 evidence run; focused `--stage <purpose-id>` calls remain diagnosis only. A dirty baseline, missing/wrong-version tool, blocked stage, nonzero exit, signal, timeout, generated drift or changed final status is non-passing. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:467-471,481-498,529-569`; cited locked `178-CONTEXT.md` D-08–D-13]

### Pattern 3: Join hosted CI to observed checkout identity

**What:** Refresh `.github/workflows/crosswake-ci.yml`, `script/ci_leaf_manifest.json`, `script/classify_ci_change.py`, `script/check_ci_leaf_manifest.py` and current repository required-check policy at the exact candidate source. Record canonical repo, workflow path/version, event, PR number, head/base, observed checkout commit/tree per job, run ID/URL, attempt, suite/check identity, observation time, and paginated job/check outcomes. Derive pass from the current declared graph, required control, umbrella, and only manifest/classifier-authorized skips. [CITED: `178-CONTEXT.md` D-15–D-20; official GitHub workflow-run/check-suite/required-check sources referenced in `178-CONTEXT.md:145`]

Current source quotes `"classify-change"` as the required control, `"merge-blocking-crosswake-ci"` as the umbrella, and the validator's closed proof leaf roster contains 46 entries [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/check_ci_leaf_manifest.py:22-79`; `/private/tmp/crosswake-177-source/crosswake/script/ci_leaf_manifest.json` read this session]. The classifier must be inspected on the actual six-file candidate; tests in test paths make it unsafe to assume a docs-only shortcut. Do not claim all CI jobs used one SHA where `release-candidate-full-proof` uses the PR head. [VERIFIED: workflow lines above; CITED: `178-CONTEXT.md` D-16–D-20]

**Failure behavior:** Missing runner checkout evidence, inaccessible policy, missing jobs, unapproved skips, failed/neutral/cancelled checks, incomplete pagination, stale run attempts, or source drift means blocked/non-passing. Recheck the PR/run binding before acceptance; an old green run or tree-only equality cannot close either requirement. [CITED: `178-CONTEXT.md` D-16–D-20, D-23, D-25]

### Anti-Patterns to Avoid

- **Aggregating individual stage runs:** Only one successful `--all` invocation completes MAINT-07. [CITED: `178-CONTEXT.md` D-08]
- **Trusting `git status` alone:** Capture HEAD/tree/index separately and inspect ignored roots through artifact policy; porcelain status omits ignored files. [CITED: `178-CONTEXT.md` D-12]
- **Cleaning all ignored output:** The verifier removes only declared roots absent before this invocation. Preserve pre-existing ignored caches; investigate them under artifact policy. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:474-479,548-564`; `repository_artifact_policy.json:1-66`]
- **Copying raw logs into artifacts or chat:** Logs may contain command output or paths. Keep them private and publish allowlisted outcomes, safe causes and remediation references. [CITED: `178-CONTEXT.md` D-11; `AGENTS.md` Sensitive Data Rules]
- **Treating a run-level SHA as runner HEAD:** The historical run demonstrates the head and synthetic merge object can differ even when trees match. [CITED: `178-CONTEXT.md:141`]
- **Broadening platform meaning:** Existing Swift and Android JVM proof is a repo gate only; it does not add device proof, Android features or adopter support. [CITED: `178-CONTEXT.md` D-14, D-20; `AGENTS.md` Working Rules]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stage orchestration, exact tool preflight, bounded failure summaries | A new verifier or shell dispatcher | `script/verify_repository.sh --all` and the closed nine-stage manifest | Existing code already owns fixed argv, prerequisites, stage dependencies, output cleanup and result classification. [VERIFIED: `verify_repository.sh:8-24`; `verify_repository.mjs:198-243,440-569`] |
| Generated-contract drift | Manual regeneration/reset logic | Existing `repository-cleanliness` stage and artifact-policy canonical owners | It regenerates registered outputs, compares bytes, and restores snapshots while reporting drift. [VERIFIED: `verify_repository.mjs:346-389,391-403`; `repository_artifact_policy.json:104-133`] |
| CI expected-job graph | Handwritten job list in Phase 178 | Selected-source leaf manifest, classifier, structural validator and umbrella | They bind required leaves, control node, authorized irrelevance and closed aggregation semantics. [VERIFIED: `check_ci_leaf_manifest.py:22-79,403-471`] |
| Source-change inventory | Text-only diff over tracked files | Phase177 exact private owner-bundle replay and binding | The completed repair explicitly includes untracked bytes, replay verification and private digests; the public binding omits patch content. [VERIFIED: `177-08-SUMMARY.md:75-90,112-117`] |

**Key insight:** Completion depends on preserving source identity across the full chain: attested source base → exact candidate bytes → runner-observed checkout → fresh local full verification. A green summary attached to the wrong commit breaks that chain. [CITED: `178-CONTEXT.md` D-04–D-06, D-16–D-20, D-25]

## Common Pitfalls

### Dirty or incomplete source candidate

**What goes wrong:** A candidate can omit one approved file, include unrelated/private preservation material, or be tested from the six-modification preparation clone.  
**Why it happens:** Prior text diff/merge safety is mistaken for semantic selection.  
**How to avoid:** Bind the exact six path set, full tracked/untracked replay output, base and resulting tree; verify repository identity and use a fresh full clone for the final run.  
**Warning signs:** Source path count is inferred from a diff, bundle replay not repeated, or prepared clone's ignored build output is called clean proof. [CITED: `178-CONTEXT.md` D-02–D-07; `177-08-SUMMARY.md:75-90,112-117`]

### Wrong toolchain or dependency cache

**What goes wrong:** Preflight passes on an unsupported runtime, or stale copied caches resolve a different dependency than the candidate lockfile.  
**Why it happens:** The environment is optimized for convenience instead of the declared stage manifest and lockfiles.  
**How to avoid:** Probe all declared prerequisites before expensive work, use the supported setup path and exact versions, and fetch from candidate lockfiles without importing Phase177 build/deps directories.  
**Warning signs:** Node 26 is substituted for Node 22.14.0, stage skips are accepted, or the previously observed `lazy_html` cache mismatch causes a dependency upgrade. [CITED: `178-CONTEXT.md` D-09–D-10]

### False clean status

**What goes wrong:** The checkout appears unchanged while ignored outputs or a changed HEAD/index escape evidence.  
**Why it happens:** Porcelain status is treated as a complete repository identity check.  
**How to avoid:** Capture HEAD/tree/index separately, retain NUL-delimited before/final status, and inspect ignored output roots against the artifact policy and the manifest's invocation-owned cleanup rules.  
**Warning signs:** Only a final `git status --short` is stored, or a pre-existing ignored directory is removed wholesale. [CITED: `178-CONTEXT.md` D-11–D-13]

### CI green on another identity or incomplete graph

**What goes wrong:** A green badge/run/head SHA is reported as proof for a different synthetic merge commit or incomplete leaf set.  
**Why it happens:** Workflow-run metadata is assumed to describe every job's checkout, or dynamic skips are accepted without classifier/manifest authority.  
**How to avoid:** Retain observed checkout provenance per relevant job and run attempt, gather complete paginated checks/jobs, validate against current policy and graph, and repeat local `--all` on the exact runner-tested commit when it differs from the preliminary candidate.  
**Warning signs:** Equal trees are treated as equal commit identities, a former green run is reused, or `release-candidate-full-proof` is reported as merge-checkout proof. [CITED: `178-CONTEXT.md` D-16–D-20, D-23; `178-DISCUSSION-LOG.md` historical run counterexample]

## Code Examples

### Full verifier and retained output root

The public CLI accepts `"--all"`, `"--stage"` plus a registered purpose ID, or `"--self-test"` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.sh:8-24`]. Only the first closes the complete-run requirement. For detailed retained evidence, use the facade's exact keys `"CROSSWAKE_REPOSITORY_RUN_ROOT"` and `"CROSSWAKE_REPOSITORY_CAPTURE_ROOT"` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:587-590`]:

```bash
mkdir -m 700 "$CAPTURE_ROOT"
RUN_ROOT="$(mktemp -d "$CAPTURE_ROOT/crosswake-repository-verify.XXXXXX")"
chmod 700 "$RUN_ROOT"
CROSSWAKE_REPOSITORY_RUN_ROOT="$RUN_ROOT" \
  CROSSWAKE_REPOSITORY_CAPTURE_ROOT="$CAPTURE_ROOT" \
  script/verify_repository.sh --all
```

Before and after, separately record `git rev-parse HEAD`, `git rev-parse HEAD^{tree}`, a private hash of the Git index, and `git status --porcelain=v1 -z --untracked-files=all`; the status command's literal format/options are used by the facade [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.mjs:299-318`]. Treat raw status and logs as private because filenames and subprocess text can be sensitive. The six-file allowlist and source identities may be projected into phase evidence only after checking the privacy rules. [CITED: `178-CONTEXT.md` D-11–D-12; `AGENTS.md` Sensitive Data Rules]

### Existing contract regression suite

The verifier test file's source declares meaningful negative cases for exact tool versions, stage blocking, dirty full-run baseline, retained NUL snapshots, pre-existing output preservation, symlink/root containment, bounded remediation with secret redaction, generated-contract restoration and CI parity. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/test/js/repository_verification.test.mjs:188-209,500-519,533-685,791-847,849-999`]

## Project Constraints (from AGENTS.md)

- Resolve the intended workstream explicitly; this phase belongs to `quality-ratchet-release`; the parked adopter lane is not eligible until its external gate passes. [VERIFIED: `AGENTS.md:59-70`; quality `STATE.md`]
- Keep Crosswake infrastructure-first and bounded to the current maintenance requirements; do not expand adopter, Android, native UI, generic sync/storage or release scope. [VERIFIED: `AGENTS.md:21-52`; `REQUIREMENTS.md:34-45`]
- Preserve fail-closed behavior, explicit causes and privacy-safe evidence; raw offline payloads, credentials, account/device identifiers and tokens must not enter logs or proof. For this phase also keep raw subprocess logs private and publish only allowlisted metadata. [VERIFIED: `AGENTS.md:44-58`; cited `178-CONTEXT.md` D-11, D-24]
- Do not modify/stage/commit/reset/clean/switch branches/create worktrees in the protected recovery checkout; use an independent qualified source surface. [VERIFIED: `178-CONTEXT.md:23,25-26`]
- Default to automated proof for machine-checkable criteria; don't use human UAT as a substitute. Keep recurring CI only where it already protects a stable contract. [VERIFIED: `AGENTS.md:71-80`]
- At handoff, name the completed phase, active phase status and exact next command from this workstream state. Current state says Phase 177 completed, Phase 178 ready for planning, and `$gsd-plan-phase 178 --ws quality-ratchet-release`. [VERIFIED: `.planning/workstreams/quality-ratchet-release/STATE.md` current position and exact next action]

## Runtime State Inventory

Omit: this is source verification and CI identity work, not a rename, refactor or migration phase. [CITED: Phase 178 boundary in `178-CONTEXT.md:7-14`]

## Environment Availability

Execution-time availability was not probed in this research pass. The selected manifest declares the exact full-run prerequisites below; planning should schedule a read-only version/availability preflight before dependency setup and the expensive full run. [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/repository_verification_stages.json:5-129`; `[CITED: 178-CONTEXT.md D-09]`]

| Dependency | Required by | Required value | Availability in research | Fallback |
|------------|-------------|----------------|--------------------------|----------|
| bash, git, Node.js | repository-preflight | bash 5.x or 3.2; Git 2.x+; Node 22.14.0 | Not probed | Existing declared setup only; missing version blocks. |
| Elixir, Erlang | root/example-host/format/warnings | Elixir 1.19.5; OTP 27; `.tool-versions` pins OTP 27.3 | Not probed | Existing declared setup only; missing version blocks. |
| npm | browser-proof | 10.9.2 | Not probed | No alternate package install mode selected. |
| Swift, Xcode | ios-package-proof | Swift 5.9/6.x; Xcode 15+ | Not probed | Missing tools block the complete run. |
| Java, Gradle wrapper | android-package-proof | Java 17; Gradle 8.7 | Not probed | Missing tools block the complete run. |
| GitHub Actions and required-check policy | MAINT-08 | Current selected workflow/run, complete jobs/checks, accessible policy read | Mutable execution state; not checked in this pass | Missing checkout provenance or policy access blocks acceptance. |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node.js built-in `node:test`; Elixir ExUnit, companion Mix lanes, Playwright, SwiftPM and Gradle are invoked by the repository verifier. [VERIFIED: `test/js/repository_verification.test.mjs:1-8`; stage manifest] |
| Config file | `script/repository_verification_stages.json` and `script/repository_artifact_policy.json` |
| Quick run command | `node --test test/js/repository_verification.test.mjs` |
| Full suite command | `script/verify_repository.sh --all` from the exact clean source commit; retained private root required for full evidence |

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | Existing coverage? |
|--------|----------|-----------|-------------------|--------------------|
| MAINT-07 | Exact clean baseline; all prerequisites checked; all nine stages pass; before/final status and source identity remain bound | Full integration / source proof | `script/verify_repository.sh --all` with retained private run root | ✅ Facade and contract tests exist; final exact-commit run remains future phase execution. |
| MAINT-07 | Missing or wrong tool version blocks dependent stages; independent stages stay observable | Unit / integration | `node --test test/js/repository_verification.test.mjs` | ✅ Tests include exact missing/wrong-version probes and blocked-stage behavior. |
| MAINT-07 | Output cleanup and diagnostics are safe; private details stay out of summary | Integration / privacy regression | `node --test test/js/repository_verification.test.mjs` | ✅ Existing cases cover retained logs, dirty baselines, preserved caches, symlink escape, bounded causes and secret redaction. |
| MAINT-08 | Current CI graph accounts for all required leaves and control/umbrella outcomes; only authorized skips pass | Structural / negative control | `python3 script/check_ci_leaf_manifest.py --self-test` plus the current workflow's production validation command | ✅ Manifest validator and negative controls exist; selected candidate CI result not yet observed. |
| MAINT-08 | Hosted result is bound to exact observed runner checkout, run and attempt; local full proof uses that same commit | Evidence reconciliation | Phase-local stdlib join over retained local evidence and allowlisted paginated run/check/job metadata | Wave 0 if no join exists; use existing sources and avoid adding a dependency or permanent CI lane. |

Exact CLI self-test is `"--self-test"`, which runs `node --test test/js/repository_verification.test.mjs` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.sh:17-20`; `verify_repository.mjs:572-585`]. The CI graph validator accepts `"--self-test"` [VERIFIED: `/private/tmp/crosswake-177-source/crosswake/script/check_ci_leaf_manifest.py:699-716`]. Stage outcomes must remain closed to `"PASS"`, `"FAIL"`, and `"BLOCKED"` [VERIFIED: `verify_repository.mjs:275-287,491-498,529-546`]. A successful focused stage is useful diagnosis but does not satisfy the complete run. [CITED: `178-CONTEXT.md` D-08]

### Wave 0 Gaps

- [ ] Decide bounded Phase 178 evidence filenames and implement the permitted stdlib join only if existing source-bound artifacts cannot represent the final local/hosted identity join. [CITED: `178-CONTEXT.md` agent discretion]
- [ ] Resolve exact selected candidate and current workflow/policy source during execution; discussion data is not final acceptance. [CITED: `178-CONTEXT.md` D-15–D-20]
- [ ] Keep MAINT-07/08 pending until exact local and hosted evidence passes and source bindings agree. [VERIFIED: `REQUIREMENTS.md:25-26`; `178-CONTEXT.md:54`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | No new user authentication surface | Existing GitHub/API credentials remain in their authorized scopes; do not persist them in evidence. [CITED: `178-CONTEXT.md` D-19, D-22] |
| V3 Session Management | No application session surface | Not applicable to this repository verification task. |
| V4 Access Control | Yes, evidence file access | Restrict private capture/run roots and files to the owning user with the manifest-enforced `0700`/`0600` modes. [VERIFIED: `verify_repository.mjs:290-303,459-461,529-530`] |
| V5 Input Validation | Yes, CLI, manifest, artifact policy, evidence schemas | Keep fixed argv, closed record keys, exact stage inventory and safe repository-relative paths. [VERIFIED: `verify_repository.mjs:48-56,158-220,572-577`] |
| V6 Cryptography | No new cryptographic mechanism | Preserve existing checksum/lock integrity checks; do not invent a new evidence signature or use hashes as user-facing approval tokens. [CITED: `178-CONTEXT.md` D-10–D-12; `AGENTS.md` Working Rules] |

### Known Threat Patterns for Repository Verification

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Malicious or malformed stage arguments | Tampering / elevation | Closed purpose-ID CLI; fixed argv from manifest; reject arbitrary shell syntax. [VERIFIED: `verify_repository.sh:8-24`; `verify_repository.mjs:198-220,572-577`] |
| Path escape through run roots or owned output cleanup | Tampering | Require validated temp/capture parent, non-symlink paths and repository-contained owned outputs. [VERIFIED: `verify_repository.mjs:290-297,420-429`] |
| Secret/path leakage through raw child output | Information disclosure | Keep raw logs and status snapshots private; emit closed causes and remediation only; allowlist public evidence. [VERIFIED: `verify_repository.mjs:275-287,529-530`; CITED: `178-CONTEXT.md` D-11] |
| False-green due to incomplete or wrong-source CI | Spoofing / repudiation | Bind observed checkout provenance to workflow run and attempt; validate all required jobs/control/umbrella and current policy. [CITED: `178-CONTEXT.md` D-16–D-20] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No new packages are needed because locked source dependencies and existing verification owners cover the phase. | Standard Stack / Package Legitimacy Audit | A hidden implementation need would require package research and the package-legitimacy gate before adding it. |
| A2 | The Phase 177 binding and private owner-bundle replay remain available and valid for the exact candidate base at execution. | Architecture Pattern 1 | If unavailable or the base moved, source qualification and semantic reconciliation must be renewed before candidate acceptance. |
| A3 | The existing local run-root mechanism plus a phase-local evidence join can retain enough safe data to close both requirements. | Architecture Pattern 2 / Validation Architecture | If exact runner provenance or policy evidence cannot be collected, MAINT-08 remains blocked; do not infer commit equality. |

## Open Questions (RESOLVED)

The two design questions below have executable observation and fail-closed rules. Their commit, credential and live policy values have not been observed and remain execution-time facts, not planning assumptions marked passed.

1. **What exact source commit will hosted CI test after local candidate preparation and proposal delivery?**
   - What we know: Existing `pull_request` jobs use the synthetic merge checkout by default, while `release-candidate-full-proof` checks out the PR head. [VERIFIED: selected workflow lines 6-8, 174-189]
   - Resolution: Plan 178-05 observes the governed run ID/attempt and actual per-job checkout OID, fetches that immutable synthetic merge object, and runs the complete local verifier on that exact OID. The commit value is an execution-time fact still unobserved; absent or inconsistent provenance blocks acceptance. [CITED: `178-CONTEXT.md` D-17–D-23]
2. **Will the current required-check policy and workflow credential expose all needed read evidence?**
   - What we know: Policy, app/context identity and complete paginated job/check data are required inputs; a local higher-privilege read does not prove workflow access. [CITED: `178-CONTEXT.md` D-19–D-20; `AGENTS.md` final release-credential rule]
   - Resolution: Plan 178-03 reads base-branch protection required checks and the effective rules for the target base (including applicable repository and inherited organization rulesets), recording a successful empty effective-rule response if none apply. It checks required contexts and app/integration identity from both policy sources; any inaccessible or incomplete route blocks MAINT-08. Plan 178-05 refreshes them for the actual run. Credential access and policy contents remain execution-time facts still unobserved; a privileged local read does not establish workflow credential access. [CITED: `178-CONTEXT.md` D-19–D-20]

## Sources

### Primary / project source of truth

- `.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-CONTEXT.md` — 25 locked decisions, boundaries, exact candidate path set, and primary-source links.
- `.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-DISCUSSION-LOG.md` — advisor research, adversarial corrections, historical CI identity counterexample, and approved synthesis.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json` and `semantic-reconciliation.json` — source base/tree, exact replay handoff and row selection (private patch material is not reproduced here).
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-08-SUMMARY.md` and `177-VERIFICATION.md` — completed source qualification and distinct Phase 177 verification result.
- Attested read-only independent source: `/private/tmp/crosswake-177-source/crosswake/script/verify_repository.sh`, `verify_repository.mjs`, `repository_verification_stages.json`, `repository_artifact_policy.json`, `.tool-versions`, `mix.exs`, `.github/workflows/crosswake-ci.yml`, `script/ci_leaf_manifest.json`, `script/classify_ci_change.py`, `script/check_ci_leaf_manifest.py`, and `test/js/repository_verification.test.mjs`.

### Official documentation already approved in discussion

- [Git status](https://git-scm.com/docs/git-status) — index/worktree/untracked distinctions.
- [Mix `deps.get`](https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html) — lockfile-aware dependency fetching.
- [npm `ci`](https://docs.npmjs.com/cli/commands/npm-ci/) — installation from the package lock.
- [GitHub Actions pull request events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) — PR event and merge-ref behavior.
- [GitHub workflow runs API](https://docs.github.com/en/rest/actions/workflow-runs) and [check suites API](https://docs.github.com/en/rest/checks/suites) — run/check metadata to corroborate observed checkout evidence.
- [Troubleshooting required status checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks) — current-source and required-check semantics.
- [GitHub branch protection REST API](https://docs.github.com/en/rest/branches/branch-protection) — base-branch required-status-check contexts and checks with app identity.
- [GitHub rules REST API](https://docs.github.com/en/rest/repos/rules) — `GET /repos/{owner}/{repo}/rules/branches/{branch}` returns all active applicable repository and organization rules; `required_status_checks` carries context and optional integration ID. A successful empty array establishes no applicable active ruleset rule at that observation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — selected source `.tool-versions` and nine-stage manifest were read directly.
- Architecture: HIGH — facade, artifact policy, CI workflow and structural validator were read from the attested independent source.
- Hosted acceptance: MEDIUM — CI runs, PR refs and required-check policy are mutable and must be observed against the final candidate.
- Execution environment: MEDIUM — versions and accessibility were not probed because this assignment was research synthesis only.

**Research date:** 2026-10-12  
**Valid until:** Recheck workflow, leaf manifest and policy at candidate execution; tool and source facts remain valid only for the attested source revision.
