# Project Research Summary

**Project:** Crosswake
**Milestone:** v23.0 "Release Pipeline Repair & Proof-Lane Truth"
**Domain:** Multi-registry OSS release engineering (Hex + SwiftPM mirror + Maven Central), repairing an existing approval-gated pipeline rather than building a new one.
**Researched:** 2026-09-15
**Confidence:** MEDIUM-HIGH overall — repo-internal findings (file/line citations) are HIGH; external comparator claims are MEDIUM; see Confidence Assessment.

This document DECIDES. Where the five research passes (STACK, FEATURES, ARCHITECTURE, PITFALLS, DX) offered more than one option, this file picks one and says why the other loses. Treat this as the input to roadmapping, not a menu.

---

## Executive Summary

Crosswake's release pipeline already has the hard parts most Hex libraries never build — an exact head/tree/base identity gate, a fail-closed rollup, a clean-room adopter-simulation harness, and a byte-exact post-publish digest proof. v23.0 is not "add supply-chain tooling"; it is "repair three architectural defects that all stem from the same root habit: a fact that should have been *derived* got hardcoded instead, and nobody built the thing that would catch it drifting." TODO-009 hardcodes a version literal into what should be a per-release identity check (repeated in 18 files, not just `release-please.yml`). TODO-011 lets a legacy, weaker clean-room implementation keep running in CI while a stronger one was already built 700 lines away and never wired in. TODO-012 makes the byte-exact proof assume a single linked six-package release when the project deliberately, correctly, ships five companions independently. All three are generalization bugs, not missing capability, and the fix in every case is to make an existing homegrown mechanism honest about scope — never to loosen what it proves, never to add OIDC/cosign/SLSA/GitHub-Environments machinery the registries in play (Hex, Maven, a plain git mirror) can't yet consume.

The recommended path: land a small, foundational "make failures legible" pair first (D6 diagnostic propagation + D5's structural successor check), because every subsequent fix's own CI failures will be read through that seam and it is cheap. Then land D1 (split version from authority) as the load-bearing structural change everything else depends on: it introduces a receipt-bound `approved_version` field, replacing four hardcoded `== '0.2.1'` job gates and two Elixir-side literal welds with a single, generalized equality (declared version == the version *this specific approved receipt* was captured for). D2 (per-package approved refs) and D3 (recovery-path proof convergence) both consume D1's generalized identity and can run afterward, largely in parallel. D4 (realistic clean-room host) is independent and should start early opportunistically since its two remaining false-negatives (threadline, sigra) are calendar-bound to reproduce. Only once the graph is version-generic, the proof lane is wired to run on every path including recovery, and the byte-exact scope matches how packages are actually versioned, should the milestone spend its one-way door: publishing 0.2.2 and the two held companion PRs through the repaired graph, in ascending blast-radius order, with a rehearsal-to-the-last-safe-step first.

The single highest-leverage, easiest-to-underweight risk is treating "the graph compiles/passes tests" as equivalent to "the milestone is done." The user has already fixed the exit criterion: this milestone ends only when 0.2.2 is actually shipped through the repaired graph AND the post-publication proof actually executes green for it. Every phase boundary below is drawn so that boundary is reachable without a last-minute scramble, and so the one genuinely irreversible step (the real publish) is preceded by everything that can be verified without crossing it.

---

## Key Findings

### Recommended Stack

Almost nothing new should be added to the toolchain (STACK.md's headline verdict, independently corroborated by PITFALLS.md and FEATURES.md's "Elixir-world comparators" section). `git subtree split` is already the correct, durable mirror-split mechanism (ships with git, deterministic, no segfaulting third-party binary) — remove all residual `splitsh-lite` references as cleanup. `mix hex.build`/`mix_hex_tarball`'s byte-exact comparison approach is already the right granularity and must not be weakened to a reachability check. Reusable GitHub Actions workflows (`on: workflow_call`) are the correct primitive for converging the ordinary and recovery publish paths onto one proof — no new GitHub feature needed, just a graph-shape fix.

**Explicitly rejected additions (NEVER for v23):** GitHub OIDC/`id-token` for Hex or Maven (neither registry has a trusted-publisher flow to federate to), GitHub Environments + required reviewers as a *replacement* for `approved-release-guard` (answers "did a human click," not "is this the exact approved head/tree/receipt" — a regression, not a generalization), `actions/attest-build-provenance`/cosign/SLSA (real future value once Hex/Maven consume attestations, which they don't; would refactor a system that currently works, off milestone-critical path), Hex package signing (doesn't exist on Hex.pm), npm-provenance-style adopter badges (no Hex.pm rendering surface — write-only).

**One durability gap worth fixing now:** `exact-public-proof`'s artifact retention is 14 days (`release-please.yml:759-764`). A "byte-exact proof, permanently demonstrable" undercuts itself if the evidence artifact expires in two weeks (contrast: Go's sumdb is append-only forever). Raise `retention-days` and/or commit the proof result summary into the repo (e.g. a release ledger file or a CHANGELOG entry) — cheap, and it is the honest analog of what the milestone is trying to prove.

### Expected Features / Scope

**Must land in v23.0 (table stakes for this repair):**
- Version-parametric release graph — any semver runs the full publish→proof→rollup graph without a workflow edit.
- Exact per-release identity binding preserved (not weakened) while it becomes version-generic.
- Post-publication proof runs on *every* publish path, ordinary or recovery — the single most important row in FEATURES.md's table, since Crosswake's only real release (0.2.1) shipped via recovery and the proof never ran.
- Byte-exact published-artifact verification, rescoped to per-package approved refs (mechanism stays; assumption of one shared ref goes).
- A realistic clean-room host that exercises install, not just compile.
- Failure messages that name the actual failing check, every time.
- Fail-closed rollup semantics preserved verbatim (this is the one property every other fix must not disturb).

**Differentiators already present and worth protecting, not just preserving:** the five-state rollup vocabulary (`BLOCKED`/`STALE`/`READY FOR APPROVAL`/`PARTIAL`/`COMPLETE`) instead of binary green/red; the "honest fallback" pattern (label a weaker proof as weaker — `reachable_and_compatible` vs `byte_exact` — never silently average them into one green check); recovery publications proving exactly as hard as ordinary ones.

**Explicitly deferred to a later hardening milestone, not v23:** adopter-facing provenance/attestation surfaces, a `diffoscope` side-channel for digest-mismatch triage, moving the iOS mirror's static deploy key to a short-lived GitHub App token (SEED-003-adjacent, real, but not blocking any of the three named defects).

### Architecture Approach

The existing graph shape is correct and unchanged: `approved-release-guard` → `release-please` → `publish-*` → `clean-room-proof-*` / `exact-public-proof` → `linked-release-rollup`, plus independent `publish-hex-<companion>` / `clean-room-proof-<companion>` lanes. Today this graph is parameterized by exactly one constant (`"0.2.1"`) injected across two axes that must be split apart: **which version is gated** (must generalize) and **which merge is authorized to publish** (must stay exact). D1-D6 below change what flows through the existing edges; none of them add a new top-level stage.

**Major components (new/modified only):**
1. `approved-release-guard` — gains an `approved_version` output, bound into the same receipt that already binds head/tree/base (D1).
2. `Crosswake.ReleaseCandidate.Workflow` — `@coordinates`/`@dependencies` become functions of version, not frozen module attributes (D1).
3. `verify_companion_cleanroom.sh` (matrix path) + `Crosswake.ReleaseCandidate.Cleanroom` — per-package `candidate_ref` instead of one shared ref (D2).
4. `exact-public-proof` job — `needs:` restructured to converge on a publication-record signal, satisfied by ordinary *or* recovery paths (D3).
5. `verify_companion_cleanroom.sh` (legacy path) — gains the matrix path's real-route host + a `mix crosswake.install` step (D4).
6. `check_release_workflow_integrity.exs` — retires the version-weld tripwire, adds a structural "no bare version literal in a publish gate" successor (D5).
7. `Crosswake.ReleaseStatus.scanner_ids_result/2` — propagates a failing check's own message instead of collapsing to "missing IDs" (D6).

### Critical Pitfalls (top 5, of 10 catalogued)

1. **Generalizing version while leaving authority as the only remaining gate.** Deleting the version literal without replacing the implicit "this is the approved merge" claim it accidentally also encoded turns `linked_release` into a rubber stamp for any version. Prevention: bind `approved_version` into the same exact receipt that already binds head/tree/base (D1) — never let "presence of *a* version" substitute for "the approved version."
2. **Weakening a guard to make a harness pass.** Two live temptations: narrowing `doctor`'s `manifest_contract`, and adjusting the version-weld tripwire's comparison instead of fixing the weld. Both are forbidden by the locked decisions and by TODO-009/011 themselves. Prevention: require a recorded decision artifact any time a guard's assertion changes; a companion test proving the *old* violation still fails.
3. **The right failure carrying the wrong explanation** — the confirmed, live PR #164 defect (see divergence #2 below). This is a true positive with a false diagnosis, structurally worse than a false green because it actively misdirects.
4. **Vacuous assertions / absence scored as success**, in six named shapes (bare `Enum.all?`/`any?` on possibly-empty collections; a job `needs:` something that silently skipped; `continue-on-error` on a lane feeding a one-way door; `if:` conditions that silently never match — exactly TODO-009's defect; a matrix expanding to zero entries; missing `set -e`/misused `grep -q`/`jq -e`). Every new check this milestone adds must be checked against this taxonomy.
5. **Using the first real 0.2.2 (plus held companion PRs #147/#115) as integration test #1 for repaired machinery.** Hex/SwiftPM/Maven are immutable one-way doors; there is no clean rollback. Prevention: rehearse to the last safe step (through `mix hex.build`, not `hex.publish`; through subtree extraction, not tag push) before the real publish, and sequence lowest-blast-radius (one companion) before highest (core 0.2.2).

---

## Divergences, Adjudicated

### 1. Clean-room path: backport vs. delete — **DECISION: backport, do not delete**

ARCHITECTURE.md and DX.md both independently converge on backporting the matrix path's `matrix_write_host` (real-route host, ~lines 388-412) into the legacy positional path; STACK.md's "delete and route all five jobs through the matrix path" is **rejected** for v23.0, for three concrete reasons:

- **The matrix path and the legacy path are not equivalent in scope today.** The legacy path is what release-please's live `clean-room-proof-*` jobs actually call, in a shape release-please's job wiring, environment variables, and per-companion argument passing already depend on. Deleting it means simultaneously rewriting the workflow's job-to-script contract *and* fixing the host realism *and* re-verifying five live CI jobs in one change — three independent failure surfaces collapsed into one diff, which is exactly the kind of oversized, hard-to-bisect change PITFALLS.md's Pitfall 2/8 warn against under time pressure.
- **"Two implementations kept in sync is the exact divergence class that caused this rot" is true, but the fix for *that* problem is scheduling a follow-up consolidation, not doing it inside the repair milestone under time pressure.** Backporting first gets both paths to parity (same host quality) with a small, reviewable diff; deleting the legacy path and repointing five jobs at the matrix path is a bigger structural migration better done once the repaired graph has already been proven correct against a live release. File "consolidate legacy and matrix clean-room paths into one implementation" as a seed for the milestone *after* v23.0, once D2/D4 have both landed and stabilized against a real release — do not attempt it in the same phase as the fix.
- **What makes backporting safe:** D4 (per DX.md/ARCHITECTURE.md's own step-by-step) is scoped to exactly the host-generation steps (4-7: router, install, doctor) and explicitly must NOT touch D2's manifest/`candidate_ref` logic in the matrix path (ARCHITECTURE.md's "Conflict 4" — D4 and D2 are near-disjoint regions of the same file and must be kept as separate plans even though they share it). Backporting a known-working host into the legacy path, verified by re-running each previously-failing companion independently (rindle expected to go green immediately; threadline/sigra treated as separately-diagnosed findings, not evidence D4 is wrong), is the lower-risk, smaller-blast-radius move that still closes TODO-011 for its primary named cause.

**Forbidden:** deleting the legacy path and rewiring release-please's job graph inside this milestone. That consolidation is real and correct eventually, but it is out of scope here — record it as a seed, not a v23.0 task.

### 2. The D6 diagnostic defect — ground truth accepted, and the incomplete-fix gap called out

Per the orchestrator's code-read (treated as ground truth, superseding PITFALLS.md's/ARCHITECTURE.md's/DX.md's own partial diagnoses): `scanner_ids_result(%{status: :failed, checks: checks}, required_ids)` (`lib/crosswake/release_status.ex:~823`) DOES compute `failing` across the full parsed check set — the weld failure IS present in it. It is discarded purely because the `cond` checks `missing != []` before `failing != []`, and `missing` wins. Causal chain: the scanner exits non-zero at the weld check → later checks never emit their `[crosswake] OK/FAIL` lines → their required IDs are absent from `checks` → `missing != []` fires first → the weld's own message never surfaces.

**The additional, no-researcher-caught defect, and why it changes the fix:** `scanner_ids_result/2` only ever returns ID *lists* (`missing`, `failing` as lists of IDs), never the check's `detail` string. Even if the `cond` ordering were reversed so `failing` won, the output would be the bare id `release.version_weld.gates_match_declared_version` — not the sentence explaining the release would publish nothing. **Fixing the `cond` ordering alone does not fix PR #164's message.** The real fix is two-part, and both parts must land together:

1. **Surface `detail` verbatim.** When any check ID in the *full* parsed set (not just the caller's `required_ids` subset) has `status: :error`, return its `detail` string, prefixed with its ID, regardless of whether that ID is one this particular `scanner_check` call's `required_ids` happened to ask about. (This also fixes the "version_weld isn't in `@workflow_path_gate_ids`" gap DX.md correctly identifies — the fix must not require the failing id to be in the caller's required set.)
2. **Distinguish "scanner terminated early" from "id was never defined."** Retain the scanner's raw output tail (or at least the point where the check list is known to be statically ordered) so a "missing" report can say *why* — "N checks after the last observed failure never ran" — rather than presenting absence as an unexplained new problem.

**Decision:** D6's phase deliverable is scoped to both parts, not just the `cond` reorder. DX.md's proposed before/after message text (Example Message #1) is the acceptance-test shape: the AFTER message must lead with the weld's own detail, name the consequence ("would SKIP... publish NOTHING"), and still report the downstream `release.workflow_path_gates: FAILED` label as a true secondary fact, never dropped. Land this early (Phase A) — it is the seam every later phase's own CI failures will be read through.

### 3. Weld footprint — DECISION: mandatory weld inventory as an explicit early task, recorded before D1's fix lands

TODO-009 scoped the weld to `release-please.yml`. The orchestrator's own verification found `0.2.1` across 18 files (8 `lib/` modules, 6 scripts, 4 workflows), and confirmed `lib/crosswake/release_candidate/cleanroom.ex:236` (`Map.fetch!(by_package, "crosswake").version == "0.2.1"`) is a **live comparison**, not a fixture or display string — ARCHITECTURE.md's D2 section independently corroborates this exact line as "a second, Elixir-side version weld" that must be removed alongside D1.

Not every one of the 18 hits is a gate, and treating them as uniformly load-bearing (or uniformly cosmetic) is itself a version of Pitfall 1's mistake — assuming a category based on shape ("it's a version string") rather than verifying function. **Decision: before D1's YAML/Elixir edits land, produce a weld inventory** classifying every one of the 18 hits into exactly one of:
- **live gate** — a comparison whose truth value controls whether a job/function proceeds (e.g. `cleanroom.ex:236`, the four `if:` conditions in `release-please.yml`) → must be fixed as part of D1/D2.
- **fixture** — a value inside a test file asserting against a known historical state (e.g. `phase168_release_version_weld_test.exs`'s pre-D1 fixture) → left alone or explicitly retained as a regression fixture per D5's non-vacuity proof #2.
- **docstring/comment** — prose describing a past state (e.g. `crosswake_rindle`'s stale "independently versioned from core 0.2.0" comment, PITFALLS.md's Pitfall 9) → hygiene fix, low priority, fold into whichever phase touches the file anyway.
- **display string** — a job *name*, artifact *name*, or log line that includes the version for human readability but does not gate anything (e.g. `"Guard exact approved 0.2.1 merge"`, `phase168-candidate-receipt-<head>` artifact naming) → rename to be version-parametric or version-agnostic (STACK.md and DX.md both flag this; DX.md additionally warns not to do a wholesale required-check rename — see below) but is not a correctness bug on its own.

**Where recorded:** this inventory should be written as a table in the phase plan that closes TODO-009 (Phase B below) — not as a separate research artifact, since it is itself an implementation task (grep + classify + link each row to the specific fix PR), and should be checked off row-by-row as each live-gate hit is fixed. A minimal acceptance criterion for that phase: **zero remaining "live gate" classifications reference a bare version literal**; fixture/docstring/display rows may remain open as tracked follow-up hygiene items, explicitly not blocking the phase.

### 4. Other cross-document contradictions, surfaced and resolved

- **STACK.md's "delete the legacy clean-room path" vs. ARCHITECTURE.md's D4 sequencing that treats the legacy path as the thing being repaired.** Resolved above (divergence #1) — backport wins.
- **DX.md's proposed wholesale CI-check-naming convention vs. ARCHITECTURE.md/PITFALLS.md's silence on check names.** DX.md itself already resolves this correctly and this SUMMARY adopts DX.md's scoping: **do not** do a wholesale rename of all ~22 required checks (real, previously-documented cost: a required-check rename that isn't paired with a branch-protection update permanently blocks PRs, per SEED-007's own findings). **Do** rename only the checks this milestone must edit anyway (the version-welded display strings identified in the weld inventory above, e.g. `"Guard exact approved 0.2.1 merge"` → `"release: approved-candidate merge guard"`) plus fix the 3 confirmed duplicate required-check names (a genuine safety hole — branch protection matches by string only) via `check_required_checks_registered.sh`'s uniqueness assertion. This is a small addition to Phase B/A, not a separate naming-migration phase.
- **STACK.md's "raise retention-days or commit a release ledger" as a NOW-cheap item vs. no other document scoping it into a phase.** Adopted as a small addition to whichever phase lands D3 (recovery convergence) or D1, since it touches the same `exact-public-proof` job — bundle it there rather than creating a standalone phase for one workflow-file tweak.
- **FEATURES.md's tri-state proof-strength vocabulary (`byte_exact` / `reachable_and_compatible` / `unproven`) vs. D2's manifest-schema-only framing in ARCHITECTURE.md.** These are complementary, not contradictory: D2's schema change (per-package `candidate_ref`) is the *mechanism* that makes byte-exact proof satisfiable per package; the tri-state vocabulary is the *reporting layer* for the residual case where even a per-package ref can't reproduce the published bytes (source has drifted past any usable ref). **Decision:** D2's phase must include the tri-state result type as part of its deliverable — a package whose per-package ref still can't reproduce byte-exact digests (this can happen even after D2, if a companion's source has drifted past *every* candidate ref, not just a shared one) must report `reachable_and_compatible`, not silently pass or silently fail closed with no explanation. This is a modest scope addition to D2's phase, not a new phase.
- **DX.md's proposed new Mix task flags (`--verify-recovery`, `--dry-run`, `--explain`) vs. ARCHITECTURE.md's D3 design (a publication-record artifact + reusable workflow).** Not contradictory — DX.md's CLI surface is the *operator-facing* consequence of D3's *mechanism*. Sequence: D3's publication-record + `workflow_call` convergence is the phase deliverable; the `mix crosswake.release.candidate --verify-recovery <ref>` CLI affordance DX.md proposes is a reasonable but optional refinement of the same phase — land it if D3's phase has budget, otherwise defer the CLI polish (not the underlying convergence) to a fast-follow, since the convergence itself is what closes TODO-009's second gap and the CLI flag is discoverability sugar on top of it.

---

## Implications for Roadmap

### Suggested Phase Structure

**Phase A — Make failures legible (D6 + D5's successor check).**
**Rationale:** Cheapest, fastest-to-verify, no release-graph behavior change, and every subsequent phase's own CI failures during development will be read through this seam. D5's successor check (`release.publish_gate.no_bare_version_literal`) is a pure syntax scan with no dependency on D1's identity plumbing, so it can be written and merged first — it will correctly and immediately FAIL against `main` today (the four bare-literal gates still exist), which is expected and becomes the acceptance criterion for Phase B, not a pre-check to satisfy first.
**Delivers:** `scanner_ids_result/2` propagates a failing check's own `detail` and distinguishes "never reached" from "never defined" (full D6 fix, both parts per divergence #2); a new structural workflow-integrity check that will fail against current `main` until Phase B lands.
**Addresses:** Table-stakes "a proof result the maintainer can act on without opening a log"; Differentiator "failure messages that name the actual failing check, every time."
**Avoids:** Pitfall 3 (right failure, wrong explanation).
**One-way-door note:** none. Fully reversible, safe to land standalone.

**Phase B — Split version from authority (D1) + retire the old tripwire (D5 retirement half) + weld inventory.**
**Rationale:** The structural prerequisite for everything else — D2, D3, and the retirement half of D5 all assume the graph already accepts arbitrary versions. **D5's structural check (from Phase A) and D1's fix must land atomically in this phase or in the same PR** — per ARCHITECTURE.md's explicit warning, if the check is merge-blocking before D1 lands it correctly fails against `main` forever, meaning D1 cannot land incrementally; do not create a green-CI window where the check exists but is toothless, and do not let a red-`main` interim exist either. Land the D5 structural check and D1's fix in the same PR (the check's own non-vacuity proof, running against a pre-D1 fixture of the workflow file, confirms it would have caught the original defect).
**Delivers:** `approved-release-guard` emits `approved_version` bound into the existing exact receipt; the four `if:` gates (`publish-hex`, `publish-ios-core`, `publish-android-core`, `exact-public-proof`) compare `release-please`'s version against `approved_version` instead of a literal; `Workflow.@coordinates` becomes a function of version; the `cleanroom.ex:236` Elixir-side weld is removed as the same defect class one layer down; the weld inventory (divergence #3) is completed and checked off; the old `release.version_weld.gates_match_declared_version` tripwire is deleted (not merely disabled).
**Addresses:** Table stakes "version-parametric release graph," "exact per-release identity binding."
**Avoids:** Pitfall 1 (generalizing version while leaving authority as sole gate) — the explicit mitigation IS this phase's deliverable.
**One-way-door note:** none directly, but this phase's correctness is the precondition for every subsequent one-way-door step later in the milestone.

**Phase C — Per-package approved refs + tri-state proof strength (D2).**
**Rationale:** Depends on Phase B's `approved_version` binding and the removed `cleanroom.ex:236` weld (same module, same test fixtures — sequence immediately after B).
**Delivers:** Manifest schema drops the `unique | length == 1` collapse on `candidate_ref`, each of the six package entries carries its own ref; `validate_approved_artifacts!/1` and the matrix `matrix_fetch_public_family` loop resolve per-package; the `reachable_and_compatible`/`byte_exact`/`unproven` tri-state result type ships for the residual case where even a per-package ref can't reproduce byte-exact digests.
**Addresses:** Table stakes "byte-exact published-artifact verification" (rescoped, not weakened); Differentiator "per-package byte-exact proof scoped to each package's own approved ref" and "the honest fallback when byte-exactness is structurally unattainable."
**Avoids:** Pitfall 7 (byte-exactness traps — non-determinism, tag/HEAD drift, no single ref reproducing all six); the anti-feature of loosening digest equality or force-linking the family.
**One-way-door note:** none — schema loosening, backward compatible with existing single-ref manifests.

**Phase D — Recovery-path proof convergence (D3), can run in parallel with C.**
**Rationale:** Depends only on Phase B's version-parity gate; touches a disjoint file set from Phase C (`needs:` graph + publish scripts vs. `cleanroom.ex`/manifest schema), so the two can proceed concurrently once B is merged.
**Delivers:** `exact-public-proof`'s `needs:` changes from "the ordinary publish jobs succeeded" to "a publication record exists for this exact `{package, version, approved_head}` triple," satisfied identically by the ordinary graph or a `workflow_dispatch`-triggered recovery job; a missing record is a **hard failure**, never a silent skip (the explicit anti-pattern this phase must not reintroduce — see "Conflicts" #3 in ARCHITECTURE.md); artifact-retention/durable-record fix (raise `retention-days` and/or commit a release-ledger entry) bundled here since it touches the same job.
**Addresses:** Table stakes "post-publication proof runs on every publish path" — FEATURES.md's single most important row.
**Avoids:** Pitfall 1's "recovery path skips proof" sub-case; Pitfall 4 Shape B (a job whose only gate is a bare `needs:` list).
**One-way-door note:** the recovery entrypoint itself touches the one genuinely dangerous, irreversible operation class (publish-adjacent). Keep everything constrained except the one genuinely unknowable input (per PITFALLS.md's anti-feature table), and gate identity checks before checkout/credential load.

**Phase E — Realistic clean-room host (D4), independent, start early/opportunistically.**
**Rationale:** Independent of B/C/D — only touches the legacy path's host-generation steps. Should start as early as Phase A/B, since diagnosing whether threadline/sigra's failures persist after the fix is calendar-bound (each only reproduces against a live Hex release) and should not wait on the identity-model work.
**Delivers:** Backport of the matrix path's real-route host (`matrix_write_host`) into the legacy positional path (per divergence #1's decision — backport, not delete); add the missing `mix crosswake.install` step before `doctor`; bring the legacy path's logging to the matrix path's `step=` grep-able parity.
**Addresses:** Table stakes "a realistic clean-room consumer proof"; Differentiator "a realistic clean-room host that proves the install step, not just the compile step."
**Avoids:** Pitfall 2 (weakening `doctor` instead of hardening the harness) — explicitly forbidden; Pitfall 8 (scope-narrowing under CI cost pressure) if only some companions get the fix.
**One-way-door note:** none. After landing, re-run each previously-failing companion (rindle expected green immediately; threadline/sigra treated as new, separately-diagnosed findings if still red — do not treat continued redness here as evidence D4 is wrong).

**Phase F — Rehearsal + the actual publish (0.2.2, then #147, then #115, ascending blast radius) + exit-criterion verification.**
**Rationale:** Everything above must be green before this phase opens. This is the one-way door the whole milestone exists to safely cross, and it must be its own phase/plan, never folded into the same plan as any of A-E (PITFALLS.md's Pitfall 5, explicit: "do not let 'the graph is fixed' and 'we shipped 0.2.2' land in the same phase/plan — force a checkpoint between them").
**Delivers:** A written retire/backfill runbook (Hex `mix hex.retire`, mirror re-tag-and-note, Maven retire-forward) authored *before* the first real publish, not improvised after; a dry-run through the last safe step (through `mix hex.build`, not `hex.publish`; through subtree extraction, not tag push) for all three legs; then the smallest-blast-radius companion (of #147 crosswake_rulestead 0.1.1 / #115 crosswake_chimeway 0.1.1 — whichever has fewer downstream consumers) published live as the fire-drill for the repaired clean-room lane; then core 0.2.2 through the full version-generalized graph; then the second held companion PR; and finally confirmation that `exact-public-proof` executed and passed for 0.2.2 (not just that it was wired to run).
**Addresses:** The milestone's own locked exit criterion.
**Avoids:** Pitfall 5 in full (using a real publish as integration test #1); Pitfall 6 (multi-registry partial-publication matrix — have the response table ready before, not derived live during, any partial failure).
**One-way-door note:** this phase contains multiple genuine one-way doors (Hex publish, mirror tag push, Maven upload). Nothing in this phase should be merged/executed without the retire/backfill runbook already committed to the repo.

### Phase Ordering Rationale

- **A before B, atomically with B where the check overlaps D1** — cheap wins first, then the load-bearing structural change, with the "would this have caught the original bug" non-vacuity proof required before B closes.
- **C and D both depend on B, and are otherwise disjoint file sets** — parallelizable once B merges, which shortens the critical path to F.
- **E is independent of B/C/D and calendar-sensitive** — start it as early as A, don't let it wait in a queue behind the identity-model work it doesn't need.
- **F strictly last, its own phase, never combined with A-E** — this is the one irreversible step; every prior phase exists specifically to make this phase boring.

### Research Flags

**Needs deeper research during planning (`/gsd-plan-phase --research-phase <N>`):**
- **Phase D (recovery convergence)** — the exact shape of a `workflow_dispatch`-triggered recovery job mirroring `android-publish-fire-drill`'s existing dispatch-only pattern needs confirmation against GitHub Actions' current `workflow_call`/`workflow_dispatch` composition rules before writing YAML; also confirm the current org-level `retention-days` cap (STACK.md flags this UNVERIFIED — "up to 400 days, org policy permitting").
- **Phase F (rehearsal + publish)** — confirm whether a scratch/throwaway Hex organization or `mix hex.publish --dry-run`-shaped mechanism is actually available for full-graph rehearsal beyond `mix hex.build`; this affects how much of the graph can be exercised before the real door.

**Standard patterns, skip phase research:**
- **Phase A** — pure Elixir refactor of an existing function plus a new pure-syntax scanner check; the pattern (`phase168_release_version_weld_test.exs`'s own coverage-test shape) already exists in the repo to copy.
- **Phase B** — the receipt-output pattern (`approved-release-guard.outputs.*`) is an established idiom already used identically for head/tree/base; extending it one field is mechanical.
- **Phase C** — schema loosening (removing a `unique | length == 1` collapse) with an established per-entry field already present in the manifest shape.
- **Phase E** — pure backport of an already-working, already-tested function (`matrix_write_host`) into a sibling code path in the same file.

---

## What NOT to Do

- **Do not relax byte-exact digest equality** to "resolves" or "compiles" anywhere in the pipeline, including inside D2's tri-state fallback (the fallback is a *separate, honestly-labeled* claim, never a redefinition of what "byte_exact" means).
- **Do not narrow `doctor`'s `manifest_contract` check** to accommodate a routeless clean-room stub. Fix the harness (D4), not the contract.
- **Do not weaken the D5/D6 tripwires to make CI green.** The version-weld tripwire is retired *because* the defect it catches becomes structurally impossible after D1 — not edited to keep passing under a new comparison.
- **Do not mark the clean-room proof lane advisory/non-blocking to escape a red state.** A proof that has never passed is a finding, not noise (TODO-011, locked).
- **Do not drop packages from the byte-exact scope, or force-link the five independent companions back into one candidate ref**, to make the manifest schema simpler. That re-creates the lockstep bottleneck companion extraction (Phase 141/16.0/17.0) deliberately tore apart — see FEATURES.md's Ecto/ecto_sql anti-feature analogy.
- **Do not add GitHub OIDC, cosign, GitHub Environments-as-authority-replacement, or a standalone SLSA initiative in this milestone.** All are either inapplicable to Hex/Maven today or answer a different question than the three named defects ask.
- **Do not delete the legacy clean-room path in this milestone** (divergence #1) — backport into it instead; file consolidation as a follow-up seed.
- **Do not do a wholesale rename of all ~22 required CI check names.** Rename only the version-welded display strings this milestone must edit anyway, plus fix the 3 confirmed duplicate names (a real branch-protection safety hole) via a uniqueness assertion in `check_required_checks_registered.sh`.
- **Do not land the D5 structural check and D1's fix as two separate PRs with a window between them** — either `main` goes permanently red (check merge-blocking before D1) or the check is meaninglessly advisory for that window. Land atomically.
- **Do not combine "the graph is fixed" (Phases A-E) with "we shipped 0.2.2" (Phase F) in the same plan.** Force the checkpoint.
- **Do not treat a still-red threadline or sigra clean-room run after D4 lands as evidence D4 failed** — TODO-011's own table names these as separate root causes (a module-shipment variant and a smoke-test assertion issue respectively); re-diagnose them as new findings.
- **Do not add the SEED-018 `absence.collection_assertion_non_empty` merge-blocking guard in this milestone** without first auditing the 173 existing unaudited sites — landing the guard first produces a wall of red that gets waived, teaching the team red is negotiable. Out of v23.0 scope; note it as a hazard if any new proof check in this milestone is tempted to skip straight to merge-blocking without the audit-then-guard sequencing.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Repo-internal findings (STACK.md's 18-file weld footprint claim, cross-verified by the orchestrator's own read) are HIGH. External claims about Hex/Maven OIDC absence, exact `hex`/`hex_core` reproducibility-fix version, and GitHub Actions artifact-retention org cap are explicitly flagged UNVERIFIED by STACK.md itself — confirm before writing a phase plan that depends on a specific retention-days number. |
| Features | HIGH | Grounded almost entirely in direct reads of TODO-009/011/012, SEED-017/004/014/018, and the runbook — cross-ecosystem comparator claims (cargo-dist, sumdb, npm provenance, Ecto/ecto_sql) are MEDIUM but each is cited for a specific mechanism, not a vague appeal to authority. |
| Architecture | HIGH | All six decision areas (D1-D6) are grounded in direct line-level reads of `release-please.yml`, `workflow.ex`, `cleanroom.ex`, `verify_companion_cleanroom.sh`, `release_status.ex`, and `check_release_workflow_integrity.exs`. Comparable-systems reasoning (cargo-dist, goreleaser, sigstore, Nix/Bazel) is explicitly flagged MEDIUM by ARCHITECTURE.md itself — recommend a follow-up `WebSearch` pass per named tool only if a written ADR needs citations, not before landing any phase. |
| Pitfalls | HIGH on repo-specific findings, MEDIUM on named-incident analogies | PITFALLS.md itself flags this split explicitly; the incident analogies (event-stream, CrowdStrike, Homebrew bottle drift) are pattern-matched from public record, not re-verified against Crosswake's own code, but are used only to justify *general* prevention shapes already independently derived from the repo reads. |
| DX / diagnostics | HIGH | No external web research was used for DX.md — grounded entirely in direct reads of the same source files as Architecture/Pitfalls, plus `brandbook/BRAND-SPEC.md` and the OSS-DNA prompt for voice/copy guidance. |

**Overall confidence:** HIGH on what needs to change and why; MEDIUM on a small set of externally-sourced specifics (see Gaps below) that should be confirmed during Phase B/D planning rather than assumed.

### Gaps to Address

- **Exact line numbers in `.github/workflows/release-please.yml` should be re-confirmed against the file at plan time**, not assumed from this research pass. PITFALLS.md explicitly worked from quoted excerpts rather than a full line-numbered read of the file in all cases; ARCHITECTURE.md's line citations (74-79, 223, 525, 571, 728, 566, 758-764, 793, 829) are HIGH confidence (read directly) but the file will have moved by the time Phase B's PR is authored, since Phase A lands first — re-grep before writing the diff.
- **Cross-ecosystem claims flagged MEDIUM by multiple researchers** (Hex.pm/Sonatype Central Portal OIDC absence, the exact `hex`/`hex_core` tarball-reproducibility fix version, GitHub Actions' current artifact-retention org-level cap) — none of these block any phase's *design*, but Phase D's retention-days change and Phase F's "is a dry-run/scratch-org publish mechanism actually available" both benefit from a 15-30 minute doc-verification pass before implementation, not before roadmapping.
- **Whether the weld inventory (divergence #3) surfaces any additional live-gate hits beyond the ones already named in this document** is genuinely open — the 18-file/8-module count is confirmed, but the orchestrator's classification of each hit into live-gate/fixture/docstring/display-string has not itself been exhaustively re-verified in this synthesis pass. Treat Phase B's weld-inventory table as the authoritative resolution, and do not assume this SUMMARY's examples (`cleanroom.ex:236`, the four `if:` gates) are the complete list of live gates.

---

## Sources

### Primary (HIGH confidence — repo-internal, read directly across the five research passes)
- `.planning/todos/TODO-009-release-graph-welded-to-0-2-1.md`, `TODO-011-companion-cleanroom-lane-has-never-been-green.md`, `TODO-012-exact-public-proof-assumes-a-linked-six-package-release.md`
- `.planning/seeds/SEED-003, SEED-004, SEED-007, SEED-013, SEED-014, SEED-017, SEED-018`
- `.github/workflows/release-please.yml`, `script/verify_companion_cleanroom.sh`, `script/check_release_workflow_integrity.exs`
- `lib/crosswake/release_candidate/workflow.ex`, `lib/crosswake/release_candidate/cleanroom.ex`, `lib/crosswake/release_status.ex`, `lib/crosswake/doctor/doctor.ex`
- `docs/COMPANION-PUBLISH-RUNBOOK.md`, `brandbook/BRAND-SPEC.md`, `prompts/crosswake-elixir-oss-dna.md`
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md`, `.planning/RETROSPECTIVE.md`, `.planning/PROJECT.md`

### Secondary (MEDIUM confidence — external, general knowledge, cited per specific mechanism not vague authority)
- `actions/attest-build-provenance` / GitHub artifact attestations docs (web-searched, not independently verified against org pins)
- `hexpm/hex` CHANGELOG (tarball reproducibility fix — exact version/date unverified)
- cargo-dist, goreleaser, Ecto/ecto_sql independent versioning, Maven Central staging model, Go module sumdb, npm provenance, PyPI trusted publishing, event-stream/CrowdStrike incident analogies — general industry knowledge, directionally reliable, not freshly re-verified this session.

---
*Research completed: 2026-09-15*
*Ready for roadmap: yes*
