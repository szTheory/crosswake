# Phase 178: Clean Checkout and Final CI - Context

**Gathered:** 2026-10-12
**Status:** Ready for planning
**Workstream:** quality-ratchet-release

<domain>
## Phase Boundary

Implement MAINT-07 and MAINT-08: run the existing complete repository verifier from an exact clean source commit and establish green hosted CI for that same reviewed source. Carry the six completed Phase177 maintenance edits into the candidate. The maintainer must be able to reproduce the result without depending on the dirty recovery checkout.

Phase177 is complete at 8/8 plans and 27/27 independently verified truths. This discussion does not run Phase178 verification, select a release, merge a PR, authorize remote writes, retire private recovery material, or promote adopter/device support. The eight-requirement v24 scope and governing first-adopter ADR remain authoritative.

</domain>

<decisions>
## Implementation Decisions

### Discussion mandate and source selection

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

### Agent discretion

The planner may choose bounded evidence filenames, existing safe setup/cache paths, scheduling that avoids shared mutable resources, and a small phase-local stdlib evidence join where existing artifacts need reconciliation. Resolve minor implementation choices without another preference questionnaire. Keep the public command, prerequisite rules, source/policy guards and privacy boundary intact. No public API, Plug/Ecto/Phoenix architecture change or visual redesign is needed.

</decisions>

<canonical_refs>
## Canonical References

Downstream agents MUST resolve source references in the attested independent candidate, not assume the dirty recovery checkout contains that source version.

### Governing scope and handoff

- `AGENTS.md` — protected checkout, privacy, zero-human verification and exact workstream handoff.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — governing infrastructure decision and stop/reversal boundaries.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — stakeholder, proof, privacy and ownership lenses.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — route/support and physical-device non-promotion boundary.
- `.planning/PROJECT.md` — project thesis, active scope and verification posture.
- `.planning/workstreams/quality-ratchet-release/v24.0-SCOPE.md` — eight approved maintenance requirements; no release selected.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — MAINT-07/08 acceptance and pending traceability.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase178 goal and success criteria.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — sole changing exact next action.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked external gate.

### Preservation and completed maintenance inputs

- `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-CONTEXT.md` — preservation and artifact decisions.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-CONTEXT.md` — completed maintenance decisions and delivery limits.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-VERIFICATION.md` — passed 27/27 proof, distinct from Phase178.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json` — attested base/tree and exact private source-bundle handoff.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/semantic-reconciliation.json` — every retained row's source/preservation selection.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-07-SUMMARY.md` — acceptance snapshot and completed parent handoff.
- `.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-08-SUMMARY.md` — source qualification and bounded replay/privacy repairs.

### Existing source verification and CI owners

- `script/verify_repository.sh` and `script/verify_repository.mjs` — complete facade, outcomes, prerequisites, private run roots and cleanliness.
- `script/repository_verification_stages.json` — nine-stage order, command/env/tool/timeout and CI-owner rules.
- `script/repository_artifact_policy.json` — tracked contracts, ignored output, forbidden residue and regeneration owners.
- `mix.exs` — Mix verify and companion lane ownership.
- `.tool-versions` — expected toolchain.
- `.github/workflows/crosswake-ci.yml` — actual event/checkout semantics and governed umbrella.
- `script/ci_leaf_manifest.json` — required proof/control roster.
- `script/classify_ci_change.py` and `script/check_ci_leaf_manifest.py` — classification and graph validation.
- `script/check_example_host_isolation.sh` — existing environment/database/seed ownership.
- `test/js/repository_verification.test.mjs` — existing verifier contract regressions.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` and `docs/RELEASE-INCIDENT-RESPONSE.md` — supported preparation/incident boundaries.

### Applicable project research and voice

- `prompts/crosswake-elixir-oss-dna.md` — proof lanes as product, honest install/support boundaries, minimal dependencies and named commands.
- `prompts/crosswake-research-synthesis.md` — runtime ownership and scope context; later governing ADR overrides older expansion proposals.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — current source/proof authority and preservation lessons.
- `brandbook/BRAND-SPEC.md` — ratified calm, precise maintainer voice; supersedes prompts/crosswake-brand-book.md. No visual work selected.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

The repository facade already validates its manifest, probes tool versions, snapshots NUL-delimited Git status, checks generated contracts/artifact policy, isolates owned outputs, classifies failures and supports private evidence retention. Its existing nine stages and CI owners provide the gate; no replacement runner is needed.

The CI classifier, 46-leaf manifest, classify-change control and merge-blocking umbrella already distinguish scheduled proof from authorized irrelevance. Existing head-specific candidate proof must remain a separate source contract.

Phase177's complete source binding and private replay bundles supply the six maintenance files. Preserve its frozen acceptance and verification artifacts; they are dated historical inputs, not live Phase178 state writers.

### Established Patterns

Mix aliases own companion/core proof; the example-host isolation matrix and existing Playwright webServer own Phoenix/Ecto setup. Generated outputs follow canonical regeneration owners. Evidence uses closed outcomes, allowlisted metadata and private raw detail. One-time reconciliation stays phase-local.

### Integration Points

Bind source delivery to the existing clean verifier; join retained local stage results with observed checkout provenance and the existing CI graph at one exact source identity. STATE/ROADMAP own stage routing; PROJECT and continue-here link that handoff without copying changing commands.

</code_context>

<specifics>
## Research Synthesis and Remaining Execution Facts

Three independent advisor researchers covered source delivery, complete local verification and exact CI identity. An adversarial pass corrected suggestions to verify only the old base, aggregate separate stages as completion, require a merge/new CI event, or equate a check-suite SHA with runner HEAD. The coherent recommendation carries all six edits, uses a fresh full clone, runs the existing complete facade and binds existing PR proof to the actual tested commit.

A metadata-only canonical workflow read during this discussion exhausted one page with total/count 38 and confirmed Crosswake CI active at .github/workflows/crosswake-ci.yml (workflow ID 353403178). A researcher's earlier absent-workflow claim was contradicted by that complete read and is not an accepted fact. This catalog observation is not green CI for the maintenance candidate.

Historical run 38152560619 supplied a concrete counterexample: the workflow-run/check-suite SHA named the PR head while most observed job checkouts used a different synthetic merge commit. The trees matched, but commit identities differed. Raw logs were parsed in memory and not retained; only allowlisted source/run observations are recorded in the discussion log. This supports D-16/18 and is not candidate acceptance evidence.

Execution still must construct the candidate commit, qualify its toolchain, obtain any separately authorized proposal delivery, observe runner checkout provenance and required policy, obtain that exact commit object, and run local/hosted acceptance. None has passed merely because this context exists.

Useful primary-source constraints: [Git status](https://git-scm.com/docs/git-status) explains index/worktree/untracked parsing; [Mix deps.get](https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html) supplies locked fetching; [npm ci](https://docs.npmjs.com/cli/commands/npm-ci/) supplies lockfile installation; [GitHub PR workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows) distinguish merge and head checkout; [required-check troubleshooting](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks) explains latest-source and skipped-check behavior; [workflow runs](https://docs.github.com/en/rest/actions/workflow-runs) and [check suites](https://docs.github.com/en/rest/checks/suites) supply metadata to corroborate observed source provenance.

These are targeted implementation facts, not a reopened ecosystem research program. UI/graphic design and new API architecture are not applicable. Maintainer accessibility means readable plain text, explicit outcomes, meaningful links and no reliance on color or hash-copying chores.

</specifics>

<deferred>
## Deferred Ideas

Remote maintenance delivery awaits a concrete scoped operation and authority check during execution. Release selection, merging, publication, lifecycle changes to other queue objects, milestone archival and private archive deletion are separate actions. New workflows/dependencies, a permanent reconciliation lane, broader audits, Android/mobile features, UI/brand polish and adopter promotion remain outside this phase.

</deferred>

---

*Phase: 178-Clean Checkout and Final CI*
*Context gathered: 2026-10-12*

## Execution-time derived-contract correction

See [178-EXECUTION-REFINEMENT.md](178-EXECUTION-REFINEMENT.md). The first full run demonstrated stale line references from the six selected edits. The final candidate retains all six and adds two generated assertion snapshots with identical keys/shapes/buckets/expressions and frozen membership. This routine D-13 correction changes the exact delivery path count to eight; all remote authority, source/proof, privacy and non-promotion boundaries remain.
