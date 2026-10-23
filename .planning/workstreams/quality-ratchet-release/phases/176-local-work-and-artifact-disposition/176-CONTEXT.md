# Phase 176: Local Work and Artifact Disposition - Context

**Gathered:** 2026-10-11
**Status:** Ready for planning
**Workstream:** quality-ratchet-release

<domain>
## Phase Boundary

Account for every tracked modification and non-ignored untracked file in the recovery checkout against named merged source commits. Assign each path a disposition, preserve unique work, verify its recovery, and distinguish source/contracts from residue using the existing artifact policy. This implements MAINT-01, MAINT-02, and MAINT-04.

Phase176 does not require a clean recovery checkout or deletion. Phase177 owns supported-path retirement, bounded maintenance changes, corrected instructions, and GitHub queue reconciliation. Phase178 owns the exact clean source checkout, complete repository verification, and CI bound to that source. Historical v23 verdicts, the REL-10 breach, and the parked adopter gate remain intact. No package release or new capability is selected.

</domain>

<decisions>
## Implementation Decisions

### Discussion mandate and inspected baseline

- **D-01:** The user selected all three areas and delegated a coherent recommendation set, including parallel primary-source research, relevant project prompts, ecosystem lessons, tradeoffs, and an adversarial pass. Adopt the recommendations below without another preference questionnaire. This settles discussion choices; it does not grant unbounded execution, deletion, publication, or Git authority.
- **D-02:** The discussion observed checkout `recovery/phase-175-orchestrator-2026-09-27`, HEAD `d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377`, with 48 tracked modifications and 54 non-ignored untracked files before discussion artifacts. These are scope observations, not a completed inventory, merged-code comparison, or recovery proof. Execution must enumerate its fresh baseline, including later planning changes, rather than enforce the old counts.

### Complete inventory and comparison

- **D-03:** Maintain one dated phase-local inventory, with a concise human rendering and machine-readable evidence where useful. Record the canonical inspected checkout, HEAD, relevant index state, and exact committed trees used for comparison. Establish which commits actually merged; moving branch names, release numbers, stale local refs, or an older green run are insufficient. Keep private filesystem pointers out of committed evidence.
- **D-04:** Enumerate staged, unstaged, deleted, renamed, type/mode-changed, and non-ignored untracked paths with NUL-safe Git output, such as `git --no-optional-locks status --porcelain=v1 -z --untracked-files=all`. Parse rename records correctly and preserve both paths. Record unmerged entries, gitlinks/submodule state, unusual filenames, unreadable paths, and classification failures explicitly. Never silently skip a record or assume every record is a text file.
- **D-05:** Give every required path exactly one of the roadmap's five dispositions: **retain**, **already merged**, **ship as bounded maintenance**, **preserve outside the working source**, or **remove as proven transient**. Include reason, comparison or policy basis, recovery outcome where applicable, and the next owner/action. Uncertain or unreadable work is retained with its limitation explained; uncertainty never grants removal authority. No sixth “mixed” status is needed.
- **D-06:** Use path rows for complete coverage and subordinate behavior/hunk records for partial merges. A path with merged and unique changes remains **retain** until its remaining work has an evidenced bounded disposition. Compare linked source, tests, scripts, workflows, generated outputs, and evidence as independently accountable paths grouped around the same invariant. Matching names, line counts, patch IDs, tests, or similar text only aid triage.
- **D-07:** Distinguish exact byte/mode/type equality from reviewed semantic equivalence. An **already merged** claim names the exact merged commit and its supporting comparison. If local text differs despite equivalent behavior, preserve the differing bytes; semantic equivalence does not make exact local work recoverable. Bound investigation to direct ownership edges. Phase177 retains the full supported-caller and dynamic-entrypoint retirement gate; Phase176 must not label uncertain code dead prematurely.

### Recovery location, privacy, and proof

- **D-08:** Adopt hybrid preservation: keep the sanitized inventory, dispositions, safe provenance, and recovery results in the phase record; keep raw recoverable bytes in a private durable archive outside every working source checkout and outside git. Reuse the v23 original-artifact manifest/verification pattern where appropriate, without copying its historical content into a new authority store.
- **D-09:** Use a maintainer-controlled persistent location with owner-only access where supported (`0700` directories and `0600` archive/manifest files). Prefer existing protected local storage; introduce no backup service, encryption dependency, credential flow, or unreviewed sync destination. Temporary directories are restore scratch and never count as durable preservation. Do not claim external backup coverage unless it is established. If durable authorized storage is unavailable, keep source intact and report the blocked preservation step.
- **D-10:** Preserve exact changed/untracked bytes and the metadata needed to reconstruct file kind, executable mode, deletions, symlinks, and staged versus unstaged content. A file snapshot is the recovery authority; binary-capable full-index patches may aid reconstruction. A Git bundle is optional only for relevant unique local commits/refs; it cannot substitute for uncommitted or untracked material. Do not archive the whole repository history, global temporary state, or unrelated credentials.
- **D-11:** Keep raw diffs, archive contents, sensitive digests/sizes, symlink targets, credential contents, private absolute paths, and unsafe filenames out of proof, logs, and committed artifacts. Safe repository-relative paths can identify ordinary source rows; use opaque row IDs for sensitive paths, with their mapping only in the private manifest. Never follow symlinks to copy unrelated targets. Known secret-bearing material stays in its existing protected location unless separately authorized preservation can handle it safely; report its metadata/limitation without reading or printing values.
- **D-12:** Verify preservation through read-back and restoration into fresh isolated scratch. Compare actual restored content/type/mode/link metadata and reconstructed staged/unstaged state against the captured manifest. Preserve link identity rather than flattening its target. Include deleted/type-changed and binary cases where present. A successful copy command, patch creation, or archive listing alone is insufficient recovery evidence. These are automated assertions, not human UAT.
- **D-13:** Keep recovery material through Phase178 and until all affected dispositions are reconciled. Material still designated **preserve outside the working source** remains retained. Do not automatically expire or delete the recovery archive at milestone close; its later retirement needs a concrete, separately scoped decision. Store absolute recovery pointers and sensitive metadata only in the private manifest.

### Artifact authority and cleanup timing

- **D-14:** Use `script/repository_artifact_policy.json` as the existing owner of ignored transient families, intentionally tracked source/contracts, forbidden tracked residue, safe fixtures, and generated-output declarations. `.gitignore` is a convention layer; global ignores and `.git/info/exclude` are not repository policy. Ignored, obsolete, forbidden to track, and disposable are separate facts.
- **D-15:** `.tmp/` and `.planning/tmp/` do not inherit the policy's root `tmp/` rule. Old red-test output, orchestration state, numbered tag-apply experiments, debug records, and locks are not disposable because of their names or age. Inspect provenance and usage, preserve unique material, and retain uncertainty. Do not hide unique source under a new broad ignore rule to obtain clean status.
- **D-16:** Each generated-contract row names its existing canonical source, regeneration argv, outputs, and drift-check owner. Reuse `mix crosswake.contract.gen`, its `--dev` form, and `mix crosswake.docs.sync` where declared. Preserve existing changed bytes before any regeneration, and run potentially writing regeneration in isolated scratch. A generated projection cannot replace its source or justify direct hand-editing. Do not add a competing registry.
- **D-17:** Complete Phase176 with the inventory, five-disposition record, verified private recovery, and generated-contract ownership map. A disposition describes what should happen and its owner; it does not claim that a removal or maintenance change has executed. No deletion or source cleanup is required for this phase to pass. Keep the recovery checkout intact apart from scoped planning/evidence writes, with no staging, commits, branch switching, or worktree changes in it.
- **D-18:** If an execution plan includes optional cleanup, it is limited to exact invocation-created, policy-recognized scratch whose ownership and permitted write scope are proven. Recovery comes before any unique-byte removal. Recheck path containment, kind, relevant hashes, and baseline immediately before and after the grouped action; changed or escaped paths stop the remaining actions and require re-inventory. No recursive blanket cleanup, `git clean`, broad reset/restore, or retry of uncertain delivery. Existing user-owned leftovers are not invocation-owned scratch.
- **D-19:** Preserve historical artifacts and their verdicts; link to archived evidence instead of rewriting it. Phase175 remains archived at 8/9 with REL-10 breached; Phase174 remains the last fully passed phase. Do not consume or revive old approval bindings or use Phase175 release authority for maintenance deletion, merges, or publication. No adopter support promotion, Android breadth, or new companion/native/sync surface follows from cleanup.

### Maintainer experience and verification cost

- **D-20:** The maintainer's job is to learn what changed, where it belongs, how to recover it, and what happens next. Start output with coverage, findings, unknowns and their cause, whether anything was changed/removed, and the next action. Keep detailed comparison/recovery internals in linked artifacts. Use ordinary purpose-led text, safe escaped path display, textual outcomes, and one concrete correction; do not require hash copying or a prompt per read/parser/bookkeeping step.
- **D-21:** This is repository maintenance, not a runtime feature. Use Git and existing standard-library helpers and supported Mix commands. Prefer a small local evidence routine to a new dependency, Mix API, workflow, dashboard, or cleanup framework. Plug/Ecto/Phoenix runtime abstractions and product UI design are unnecessary here; preserve their supported contracts and host ownership.
- **D-22:** Verification should protect this phase's actual promises: path coverage, exact-source comparisons, declared policy mapping, privacy-safe rendering, and recovery. Exercise any new helper using the installed Git/subprocess return shapes and a temporary local fixture, with actual unusual-path, rename, staged/unstaged, binary, symlink/mode, and changed-baseline cases relevant to its behavior. Do not add tests that merely mirror a one-time implementation or promote a reconciliation lane into permanent CI. Reuse existing recurring artifact/drift guards.
- **D-23:** Hand Phase177 a bounded list of useful unique source units, uncertain candidates, known residue, and exact actions supported by the inventory. Keep source promotion/retirement there. Phase178 verifies the selected exact source with the existing complete facade and matching hosted CI; a dirty recovery checkout is not its proof target. Correct stale active instructions there, including PROJECT.md's “No new scope is selected” paragraph now that v24 scope is approved.

### Agent discretion

- Exact phase-local evidence filenames, row IDs, rendering, recovery layout, and bounded inspection order, using existing schemas/patterns where useful and no new permanent public contract.
- Exact persistent private storage root within available authorized filesystem scope; do not turn storage selection into a new preference interview. Lack of a safe permitted root blocks removal rather than forcing a temporary copy to qualify as durable.
- Group routine inspections and checks by the outcome they support. No additional owner preference remains unresolved in this discussion. Any genuinely missing execution authority, credential, or external trust action must be handled at its concrete boundary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read applicable references before planning or implementing.**

### Scope and workstream authority

- `AGENTS.md` — privacy, workstream routing, recovery-checkout constraints, automation, and non-transferable release authority.
- `.planning/PROJECT.md` — Phoenix-first thesis and project history; its stale next-milestone paragraph does not override approved v24 scope.
- `.planning/workstreams/quality-ratchet-release/v24.0-SCOPE.md` — approved eight-requirement maintenance scope and execution limits.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — MAINT-01, MAINT-02, MAINT-04 and later-phase ownership.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase176 success criteria and Phase177/178 boundaries.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — current handoff; do not return to completed discussion.
- `.planning/seeds/SEED-012-post-0-2-1-repository-operational-hygiene-closeout.md` — low-churn hygiene rationale; historical versions/paths are not current authority.

### Governing boundaries and historical provenance

- `.planning/ADR-FIRST-B2C-ADOPTER.md` — infrastructure framing, privacy, stop list, and executable verification.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — priorities and frozen surface boundaries.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — sanitized route and physical-proof promotion rules.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked external gate, unchanged.
- `.planning/workstreams/quality-ratchet-release/milestones/v22.0-phases/166-clean-checkout-engineering-quality/166-CONTEXT.md` — artifact policy, invocation ownership, dynamic caller review, and exact-checkout verification.
- `.planning/workstreams/quality-ratchet-release/milestones/v22.0-phases/167-documentation-and-pull-request-reconciliation/167-CONTEXT.md` — executable sources, generated projections, and immutable historical provenance.
- `.planning/workstreams/quality-ratchet-release/milestones/v23.0-closeout/original-artifacts.json` — preserved-original manifest precedent.
- `.planning/workstreams/quality-ratchet-release/milestones/v23.0-closeout/pre-close-artifact-audit.json` — dated historical findings; not a current inventory.
- `.planning/workstreams/quality-ratchet-release/milestones/v23.0-phases/175-rehearsal-and-publish/175-LEARNINGS.md` — spent attempts and adapter/output-shape lessons.

### Existing implementation owners

- `script/repository_artifact_policy.json` — artifact classes, exact safe fixtures, generated sources/commands/outputs.
- `.gitignore` — familiar ignore conventions; it does not alone establish deletion safety.
- `script/verify_repository.sh` — established complete/focused repository facade.
- `script/verify_repository.mjs` — existing snapshot, containment, restoration, and cleanliness seams.
- `script/repository_verification_stages.json` — existing stage definitions; no replacement runner is selected.
- `lib/mix/tasks/crosswake.contract.gen.ex` — contract generator owner.
- `lib/mix/tasks/crosswake.docs.sync.ex` — generated-document owner.
- `mix.exs` — package surface and supported Mix aliases; package relevance is not inferred from filenames.
- `.planning/workstreams/quality-ratchet-release/MILESTONES.md` — archived source/release identities to investigate, not permission to replay a release.

### Project research and operator voice

- `prompts/crosswake-elixir-oss-dna.md` — install truth, explicit ownership, named proof, small dependency surfaces.
- `prompts/crosswake-research-synthesis.md` — architectural thesis; current ADR and brand spec supersede older scope/brand suggestions.
- `prompts/crosswake-gsd-project-brief.md` — diagnostics and proof as product.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — follow values, owners, failure semantics, and executable source.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — ecosystem/packaging lessons only; broad historical product scope remains inactive.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — narrow boundaries and lightweight tooling; historical architecture sketches are not cleanup authority.
- `brandbook/BRAND-SPEC.md` — current precise, calm, actionable voice and accessible textual status; use instead of the old prompt brandbook.

Primary-source research links and comparisons are retained in the human discussion log. No external specification expands Phase176's scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- The artifact policy already names three classes and two generated-contract records; reuse its owners and commands.
- The repository verifier already handles stable status, invocation-owned cleanup, and generated-output restoration. Reuse relevant bounded pieces without rerunning the complete gate on the dirty recovery checkout.
- The v23 closeout retains original-artifact manifests and historical verdicts; reuse the preservation pattern without duplicating a live truth store.

### Established Patterns

- Explicit fail-closed ownership, source-bound proof, generated projections, and separate historical provenance.
- Standard Git/stdlib tooling with exact source identities, safe output, and no new dependencies for one-time maintenance.
- Dynamic Mix, shell, workflow, and generated callers require more than literal static searches before retirement.

### Integration Points

- Inventory and recovery evidence belong to this workstream's Phase176 directory; private payload stays outside git/source.
- Phase177 consumes dispositions for bounded maintenance and supported-caller review.
- Phase178 uses the existing facade and CI authority on the final approved exact source.

</code_context>

<specifics>
## Specific Ideas

Three parallel researchers compared preservation, source disposition, and cleanup timing, followed by an adversarial refinement of their combined recommendation. Primary Git, Mix/Hex, Phoenix, and Cargo documentation informed the tradeoffs. Conclusions are project decisions, not claims that the local changes have already merged or been backed up.

The useful cross-ecosystem lesson is to verify materialized source, not merely successful packaging/copying: rehearse recovery now; reserve full final-source proof for Phase178. Cargo's package behavior is not an archive recipe because its treatment of symlinks differs from exact local recovery. Hex package membership is also distinct from repository recovery coverage.

Illustrative output: “The inventory covers every changed path. Two comparisons remain unresolved, so those files stay in place. No source files were removed. The next step is the recorded Phase177 maintenance handoff.” Use actual results during execution, never these example counts as evidence.

</specifics>

<deferred>
## Deferred Ideas

- Phase177: actual supported-path retirement/shipping, dynamic caller proof, active instruction repair, and open GitHub PR/issue reconciliation.
- Phase178: complete clean-checkout verification, final-source CI, and source identity agreement.
- Recovery-archive retirement requires a later concrete scoped decision; it is not automatic milestone cleanup.
- Runtime feature breadth, product UI, new dependencies/frameworks/standing CI lanes, release publication, and adopter/Android promotion remain outside v24 scope.

</deferred>

---

*Phase: 176-Local Work and Artifact Disposition*
*Context gathered: 2026-10-11*
