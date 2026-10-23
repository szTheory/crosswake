# Phase 177: Maintenance and Queue Reconciliation - Context

**Gathered:** 2026-10-12
**Status:** Ready for planning
**Workstream:** quality-ratchet-release

<domain>
## Phase Boundary

Keep supported maintenance and release entry points usable; retire only release behaviors whose obsolescence, replacement and callers are proven; give every open GitHub PR and issue a dated disposition and concrete next action; correct misleading active maintenance instructions. This implements MAINT-03, MAINT-05 and MAINT-06.

Phase176 is complete and supplies preservation and comparison inputs. Phase178 owns complete verification from an exact clean source commit and matching hosted CI. No release, GitHub queue mutation, adopter promotion, new capability or replacement verification system is selected. The recovery checkout remains protected; historical attempts and the REL-10 breach retain their meaning.

</domain>

<decisions>
## Implementation Decisions

### Discussion mandate and preservation input

- **D-01:** The user selected all three areas and delegated parallel primary-source research, tradeoff comparisons, applicable project prompts, expert-role/JTBD lenses, adversarial refinement and automatic adoption of a coherent recommendation set. Adopt the decisions below without another preference questionnaire. This authorizes discussion/planning artifacts, not remote queue writes, publication or broader Git authority.
- **D-02:** Consume Phase176's dated inventory as preservation evidence: 119 retained path rows, 170 restored units and 234 ownership edges. All rows still require semantic review; none is a proven-obsolete list or permission to discard unique work. Refresh relevant source facts at execution instead of enforcing historical counts. Do not repeat Phase176 or replace its frozen capture.
- **D-03:** Reconcile unique maintenance changes by bounded behavior/hunk ownership against exact merged source, including linked implementation, tests, scripts, workflows and generated outputs. Preserve differing bytes even where semantics prove equivalent. Give each carried candidate an evidence-backed disposition and owner/action; unresolved work stays retained with the precise missing fact. Keep private recovery material through Phase178 and unresolved preservation decisions.

### Supported commands and behavioral retirement

- **D-04:** Keep the existing supported generic release surface: `crosswake.release.status`, `crosswake.release.candidate`, `crosswake.release.receipt`, `crosswake.release.gate` and their actual supported callers. Maintain current exact-source, authorization, policy, denied-input and fail-closed guards. Do not generalize old one-use collectors into new release APIs.
- **D-05:** Retire behaviors, not files by age or plan number. For every candidate, record the task/mode or script entry point, purpose, owner, terminal-attempt or other obsolescence evidence, current support/exposure, callers, replacement, preservation and verification. Mixed modules can retain a useful reader while losing a proven-spent launcher. A replacement must cover the required job; naming a newer helper is insufficient.
- **D-06:** Caller review includes direct Mix discoverability/invocation, aliases and dynamically assembled `Mix.Task.run` names, mode dispatch/OptionParser branches, subprocess and shell indirection, workflows/actions/stage registrations, package membership, generated templates/guides, public documentation and tests. Package inclusion is an exposure signal, not proof of support; lack of literal references is not proof of unreachability. Bound review to actual ownership edges and retain uncertainty.
- **D-07:** Preserve local historical inspection and receipt/lifecycle schema validation where needed to read archived evidence. Before deleting a reader, exercise its retained or replacement reader against the preserved artifacts and confirm the original verdict remains observable. Historical references do not make spent launches supported; archived commands must not become executable authority again.
- **D-08:** Remove proven-spent prepare, decision, collection, launch and write routes only after replacement/caller checks. For an evidenced supported stale caller that needs a transition, use a narrow fail-closed tombstone with an actionable migration pointer. Do not introduce a tombstone merely because a caller might exist. A redirect is allowed only for a lossless, non-consuming read operation; it must never carry old attempt IDs, approval, candidate or write authority into another path.
- **D-09:** Rejected/retired modes fail before credential lookup, network access, subprocess launch, evidence writes or approval consumption. Keep explicit mode allowlists and reject unexpected positional values, invalid options and ambiguous duplicate identity selectors. Test the actual entry points and dependency return shapes, including real subprocess output in a temporary fixture where a production adapter is involved.
- **D-10:** Keep tests according to the enduring invariant they protect. Preserve or adapt fail-closed guard coverage to supported paths; retire only tests whose sole contract is the proven-spent invocation. Do not delete a guard along with its old implementation or produce green CI by shrinking its tested population.
- **D-11:** No retirement proven is a valid maintenance outcome: retained candidates need concrete reasons and next actions, while supported paths still need positive usable-path proof. MAINT-03 does not demand deletion for its own sake. Do not call a candidate retired before its source change and caller checks have actually passed.

### Delivery surface, verification and dependencies

- **D-12:** Keep source/index/branch/worktree state intact in this recovery checkout; only scoped planning/evidence and their active handoff writes belong here. Plan a qualified isolated source surface for bounded maintenance review/changes and a concrete source/patch handoff. Use permitted existing GSD isolation/delivery mechanisms; do not invent a worktree protocol or presume authority to stage, commit, merge or publish here. An unresolved delivery prerequisite must be named without blocking independent local research or inventory.
- **D-13:** Run potentially writing Mix checks, compilation, generation, package inspection and subprocess fixtures in the qualified isolated surface. Declare expected side effects and inspect before/after source/artifact state. A command advertised as read-only can still write caches or local receipts; do not exercise spent production collection/write modes for caller discovery.
- **D-14:** Reuse ordinary Mix, Git and existing stdlib helpers, artifact policy, verification facade and recurring guards. Prefer a small phase-local routine or copied bounded helper over a new dependency, framework, Mix API, registry, bot, dashboard or permanent reconciliation lane. No Plug/Ecto/Phoenix runtime abstraction or UI is needed for this maintenance job. Add recurring checks only for stable supported/denial contracts; keep one-time inventories and comparisons in phase evidence.

### Complete GitHub reconciliation

- **D-15:** Produce a fresh, dated inventory at execution of every open PR and issue. Enumerate separate object kinds with complete pagination; validate returned page counts/unique identities against endpoint counts, preserve issue/PR relationships, and distinguish unavailable access or incomplete reads from an empty queue. REST issue lists must distinguish PR objects; bounded searches/default CLI limits cannot establish completeness. Record the observation window and relevant source/head identities.
- **D-16:** Every object gets exactly one local disposition, rationale, accountable role, concrete next action, trigger/reopening condition, safe evidence reference and explicit release-proposal flag. Resolve roles from ownership evidence; do not invent a GitHub assignee. Use existing useful categories such as retain pending diagnosis, held for a separate release, verified resolved/superseded, or blocked by a named external gate. A vague 'defer' or 'investigate' without an object, fact to establish and action does not satisfy MAINT-05.
- **D-17:** This phase is record-only for GitHub: no comments, labels, assignment changes, closures, merges, force-runs or publication. Its local inventory can recommend a later concrete operation; only separately scoped authority can execute it after a fresh precheck. Phase175 standing release authority does not transfer. Do not close/reopen a release-please PR or adjust its lifecycle labels to make the queue look clean.
- **D-18:** Handle release proposals and dependency PRs separately. Hold a release proposal until a release is separately selected and fresh exact-candidate proof qualifies it. For a dependency PR with failing checks, name its current head/base and the failed check to diagnose; mergeability alone, age, bot authorship or older green CI do not resolve it. Dependency upgrades/merges are not implicit Phase177 queue work.
- **D-19:** Link generated failure issues to their exact run, attempted operation, local failure evidence, replacement and remaining unique findings. Do not infer resolution from title, age, bot generation or a later successful release. Preserve security findings and historical validation debt independently. Supersession requires the same work to be covered by a verified replacement with unique work preserved; duplicate representation is not safe-to-close evidence.
- **D-20:** GitHub pagination is not an atomic snapshot. Recheck the open-object roster and relevant changed metadata at the end of collection or record a bounded observation window and drift limitation; refresh changed objects before disposition/sign-off. Requery during execution. The discussion snapshot below is research context, not the executed/verified MAINT-05 artifact. Missing facts remain explicit and do not force another per-read permission loop.

### Active guidance and maintainer experience

- **D-21:** Correct existing active pointers and instructions with bounded edits instead of adding a consolidated runbook or rewriting history. Cover `.planning/PROJECT.md`'s stale milestone/active-scope statements, the workstream `.continue-here.md`, and the current STATE/ROADMAP handoff alongside affected public commands/paths. Keep one current handoff; move superseded active prose into history where needed. Preserve frozen phase artifacts, consumed attempts, Phase175's 8/9 and REL-10 breach, and the parked adopter gate.
- **D-22:** Keep pre-release operation guidance in `docs/COMPANION-PUBLISH-RUNBOOK.md` and incident recovery in `docs/RELEASE-INCIDENT-RESPONSE.md`. Use existing README links and Mix `@shortdoc`/`@moduledoc` discoverability. Follow executable capability/support owners and `mix crosswake.docs.sync` for generated guides; change canonical inputs before regenerating in isolation. Recheck runbook ancestry/integrity guards and affected renderings when those documents change.
- **D-23:** Write for the maintainer's task: what they can do, needed inputs/prerequisites, command, observable result, failure cause and one concrete correction/next action. Keep active supported commands separate from clearly marked historical provenance. Use calm, precise plain text and meaningful links; status must remain understandable without color or badges. No requirement to copy internal hashes or answer a new prompt for every read/parser/bookkeeping step. `brandbook/BRAND-SPEC.md` supersedes the old prompt brandbook; no visual redesign is selected.
- **D-24:** Preserve the privacy boundary in inspection, queue artifacts and evidence. Retain only necessary repository/run/source metadata and sanitized categories; do not collect raw adopter payloads, credentials, account/device identifiers, private archive pointers or revealing content. Do not search history or external sources to reidentify the adopter. Inspect queue bodies/logs only when needed for a specific disposition, with allowlisted safe extraction rather than copying raw contents.

### Completion and next owner

- **D-25:** Phase177 acceptance needs candidate/caller/replacement dispositions with supported behavior proof, complete dated queue accounting and actionable rows, and active command/path resolution with original history meaning preserved. Automated checks own assertions; no human UAT replaces an automatable claim. Carry unchanged retention/delivery limitations explicitly rather than silently passing an incomplete review.
- **D-26:** Phase178 verifies the selected exact final source through the existing complete repository facade and CI bound to the same commit. A dirty recovery checkout, an old green run, an isolated patch that has not been bound to a source commit, or a discussion snapshot cannot satisfy that gate. No Phase178 or requirement completion is claimed by this discussion.

### Agent discretion

- Exact inventory/report filenames, bounded inspection order, grouping of ownership edges and stdlib implementation details, using existing schemas where helpful and without a new public contract.
- Which specific behaviors meet the evidence-backed retirement gate; uncertainty means retain. Which narrow guards/tests need adaptation to preserve their existing contract.
- Routine local diagnosis, planning repairs and checks proceed within scope. Any genuinely missing credential, delivery authority or external trust action belongs at its concrete execution boundary.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read applicable references before planning or implementing.**

### Scope, handoff and preservation

- `AGENTS.md` — workstream, privacy, recovery-checkout and authorization limits.
- `.planning/workstreams/quality-ratchet-release/v24.0-SCOPE.md` — approved eight-requirement maintenance scope; no release selection.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — MAINT-03, MAINT-05, MAINT-06 and Phase178 boundary.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase177 goal and success criteria.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — current stage and exact next action.
- `.planning/workstreams/quality-ratchet-release/.continue-here.md` — stale active handoff to reconcile; not authoritative over current STATE/ROADMAP.
- `.planning/PROJECT.md` — thesis and history; stale active paragraphs need bounded reconciliation.
- `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-CONTEXT.md` — preservation and delivery decisions.
- `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json` — canonical sanitized retained rows, comparison and owner/action inputs.
- `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.md` — derived human rendering.
- `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-VERIFICATION.md` — captured scope/results; not a retirement verdict.
- `.planning/seeds/SEED-012-post-0-2-1-repository-operational-hygiene-closeout.md` — bounded hygiene rationale; historical versions/paths are provenance.

### Governing and historical boundaries

- `.planning/ADR-FIRST-B2C-ADOPTER.md` — infrastructure framing, privacy, frozen scope and automated proof.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — priorities and non-goals.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — route and physical-promotion rules.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked external gate remains unchanged.
- `.planning/workstreams/quality-ratchet-release/MILESTONES.md` — source/release identities and archive meaning.
- `.planning/workstreams/quality-ratchet-release/milestones/v23.0-REQUIREMENTS.md` — historical REL-10 breach.
- `.planning/workstreams/quality-ratchet-release/milestones/v23.0-phases/175-rehearsal-and-publish/175-LEARNINGS.md` — spent attempts, actual adapter shapes and operational lessons.
- `.planning/workstreams/quality-ratchet-release/milestones/v22.0-phases/167-documentation-and-pull-request-reconciliation/167-CONTEXT.md` — canonical owners, historical provenance and reconciliation precedent.

### Existing code and proof owners

- `mix.exs` — aliases, package exposure and dependency boundary.
- `lib/mix/tasks/crosswake.release.status.ex` — supported local/live status entry.
- `lib/mix/tasks/crosswake.release.candidate.ex` — exact-candidate evaluation.
- `lib/mix/tasks/crosswake.release.receipt.ex` — generic evidence receipt entry.
- `lib/mix/tasks/crosswake.release.gate.ex` — generic envelope/authorization gate.
- `lib/mix/tasks/crosswake.release.candidate_read.ex` — mixed Plan93 launcher and historical inspector candidate; no retirement established yet.
- `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` — mixed attempt-mode router; classify each behavior.
- `lib/crosswake/release_candidate/plan146_tag_apply.ex` — fixed-attempt authority example; preserve its invariant when retiring routes.
- `script/release_candidate/require_release_evidence.sh` — actual gate caller with dynamic dispatch.
- `.github/workflows/release-please.yml` — current release-proposal/publication ownership.
- `.github/workflows/ios-mirror-backfill.yml` — supported candidate caller and guard surface.
- `script/check_release_workflow_integrity.exs` — existing workflow integrity owner.
- `script/check_release_runbook_ancestry.sh` — existing source/runbook ancestry guard.
- `script/check_phase167_default_reconciliation.py` — bounded historical reconciliation precedent; fixed old identities are not current authority.
- `script/repository_artifact_policy.json` — generated/ignored/tracked/forbidden ownership, not deletion permission.
- `script/verify_repository.sh` — complete/focused verification facade.
- `script/verify_repository.mjs` — side-effect, restoration and cleanliness seams.
- `script/repository_verification_stages.json` — existing proof-stage ownership.
- `lib/mix/tasks/crosswake.docs.sync.ex` — source-owned guide rendering.
- `guides/capability_map.md` — generated capability rendering.
- `guides/support_matrix.md` — generated support rendering.
- `README.md` — existing public command/runbook navigation.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — pre-release operator guidance.
- `docs/RELEASE-INCIDENT-RESPONSE.md` — recovery operator guidance.

### Project prompts and current voice

- `prompts/crosswake-elixir-oss-dna.md` — idiomatic small Elixir library, install truth and DX.
- `prompts/crosswake-research-synthesis.md` — explicit ownership and narrow architecture; current ADR/brand supersede older scope/branding.
- `prompts/crosswake-gsd-project-brief.md` — proof and diagnostics as product surface.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — trace owners, values, failures and executable truth.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — relevant ecosystem/packaging lessons only.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — host ownership and lightweight seams only.
- `prompts/new elixir oss lib prompt.txt` — fan-out method and small-dependency preference; no new product mandate.
- `brandbook/BRAND-SPEC.md` — authoritative precise, calm, task-oriented voice and accessible status.

External primary-source comparisons and their limits are linked in the discussion log. They inform decisions; no external specification expands this phase's scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Generic release Mix tasks, guarded workflow/shell callers and integrity tests already provide the supported surface.
- Mixed attempt routers expose local inspectors alongside launch/decision/apply behaviors; retirement must split jobs safely.
- Phase176's sanitized inventory provides retained rows and ownership edges; raw recoverable bytes remain private.
- Existing artifact policy, complete verifier, docs sync and historical reconciliation patterns avoid new dependencies/authority stores.

### Established Patterns

- Explicit semantic/versioned ownership, exact-source evidence, backend authority, fail-closed denials and nontransferable attempt bindings.
- Mix task/module docs and existing public topic guides for discoverability; generated projections follow executable owners.
- Automation verifies claims; historical provenance remains separate from active instructions and mutable remote observations.

### Integration Points

- Phase177 records bounded retirement/maintenance and queue dispositions against Phase176's owner/actions.
- Existing supported task, workflow and generated-doc edges define the change surface; Phase178 owns final-source proof.
- Current STATE/ROADMAP and stale `.continue-here.md`/PROJECT active paragraphs require one coherent stage handoff.

</code_context>

<specifics>
## Specific Ideas

Three independent researchers covered command retirement, GitHub reconciliation and active instructions. A second adversarial pass tested mixed inspector/writer removal, package exposure, guard deletion, local side effects, queue cardinality/drift and authority transfer; it found no further material decision after the corrections above.

The metadata-only GitHub research observation at **2026-10-12 12:49:20–12:49:25 UTC** found **3 open PR objects and 20 open issue objects**; separate GraphQL connections and check-context connections reported complete pagination. These are 23 objects, not 23 independent workstreams. PR #236 is a release-please proposal; #210/#211 are dependency updates. All three were behind with failing check contexts. Logs were not retrieved, so causes are unknown. This is a discussion observation to refresh during execution, not completed queue triage.

The useful cross-ecosystem lessons are to define supported API boundaries before removal, preserve meaningful migration/inspection behavior, and avoid lifecycle-changing queue cleanup. Cargo/Go/Django comparisons inform tradeoffs; their exact deprecation schedules are not imposed on Crosswake.

</specifics>

<deferred>
## Deferred Ideas

- Remote queue mutations, dependency upgrades/merges and selection/publication of another release require separate scope.
- Complete clean-checkout verification and hosted CI bound to the final commit remain Phase178.
- Recovery archive retirement is not automatic milestone cleanup.
- New runbooks/navigation layers, dependencies, bots, permanent reconciliation CI and broad audits require a demonstrated recurring gap.
- Product UI, Android breadth, new native/companion/sync/storage capabilities and adopter promotion remain outside scope.

</deferred>

---

*Phase: 177-Maintenance and Queue Reconciliation*
*Context gathered: 2026-10-12*
