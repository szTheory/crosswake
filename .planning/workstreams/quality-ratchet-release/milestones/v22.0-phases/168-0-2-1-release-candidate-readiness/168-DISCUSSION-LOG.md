# Phase 168: 0.2.1 Release Candidate Readiness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-12
**Phase:** 168-0-2-1-release-candidate-readiness
**Areas discussed:** Candidate identity and handoff landing, clean-room companion proof, release-train approval, iOS mirror authority and operator DX

---

## Candidate Identity and Handoff Landing

| Option | Description | Selected |
|--------|-------------|----------|
| Refreshed Release Please head plus tree-identical merge | Bind the exact refreshed #57 head/tree/base and prove the tagged merge commit has the same tree. | ✓ |
| Merge before approval | Land release-version changes first, then approve publication through a second protected environment. | |
| One multi-PR release controller | Capture core and all companion PRs beneath one orchestration approval. | |
| Release branch or RC tag | Establish a second stable candidate reference outside the Release Please head. | |

**User's choice:** Accept and lock the complete research-backed recommendation packet.
**Notes:** Land and prove the five exact Phase 167 closeout blobs first, fix marker-query
truncation before consuming it, refresh #57, bind the future exact head/tree/base and all proof
inputs, invalidate on drift, merge with exact-head matching, and require parent plus tree identity
before publication. Do not create a competing RC authority.

---

## Clean-Room Companion Proof

| Option | Description | Selected |
|--------|-------------|----------|
| Current-published-only preflight | Run the real Hex graph before approval; useful for calibration but proves old bytes. | calibration only |
| Candidate tarball/unpacked payload proof | Build and inspect exact candidate packages, then consume unpacked payloads in a generated Phoenix host. | ✓ prepublish |
| Ephemeral signed Hex repository | Exercise the Hex SCM before publication through a temporary registry and pinned closure. | |
| Candidate-local plus public-registry proof | Block payload/host defects before approval, then prove exact public resolution and compare bytes after publication. | ✓ overall |
| Publish then prove | Test only what adopters resolve, after the immutable write. | |

**User's choice:** Accept and lock the complete research-backed recommendation packet.
**Notes:** Use a two-stage proof. Counter the unavoidable unpacked-path dependency blind spot with
explicit tarball file/metadata/floor/digest assertions. Keep the real generated-host journey,
idempotent install, warnings-as-errors compile, runtime config, router/public-seam smoke, doctor,
negative controls, isolated homes/builds, and closed five-companion profile matrix. Reject a local
Hex registry because its transitive repository closure and lifecycle add harness risk.

---

## Release-Train Approval

| Option | Description | Selected |
|--------|-------------|----------|
| One exact approval for linked 0.2.1 core/native train | Approve only Hex/iOS/Android 0.2.1 through refreshed #57. | ✓ |
| Include companion PRs in the same approval | Merge #115, #146, and #147 as one larger release train. | |
| Protected-environment publication approval | Merge release changes first, then approve secrets/publication separately. | |
| Independent serial approvals | Treat every independently versioned release proposal as its own future immutable decision. | ✓ for companions after core |

**User's choice:** Accept and lock the complete research-backed recommendation packet.
**Notes:** The one Phase 168 approval is #57 only. Companion PRs remain open and independently
versioned, then receive fresh serial evaluation after the linked rollup. Publication is a
fail-closed DAG, not a transaction; partial public state is retained and recovered from exact refs
without moving tags or silently replacing packages.

---

## iOS Mirror Authority and Operator DX

| Option | Description | Selected |
|--------|-------------|----------|
| Harden current backfill only | Preserve the release-tag-bound script and fragmented readiness evidence. | |
| Baseline, candidate rehearsal, and normal publication stages | Verify 0.2.0 as a credential-free no-op, rehearse absent 0.2.1 authority from the exact candidate, then publish through fast-forward immutable refs. | ✓ |
| Protected-environment rehearsal and publication | Use native reviewer gates for both credential access and external writes. | |
| GitHub App credential migration | Replace the bounded single-repository deploy key immediately. | deferred |

**User's choice:** Accept and lock the complete research-backed recommendation packet.
**Notes:** Public mirror `main` and `v0.2.0` already match the expected split, so do not claim a
missing backfill. Candidate mode must work before component tags exist, exercise the real deploy
key through dry-run, and distinguish absent, conflicting, and unreachable refs. Normal publication
is fast-forward plus immutable tag only; force-with-lease is recovery-only. Present one
answer-first Mix command with deterministic JSON and accessible Markdown/terminal projections.

---

## the agent's Discretion

- Exact internal modules and files beneath `mix crosswake.release.candidate`.
- Exact evidence filenames, JSON field order, and Markdown layout within the accepted stable
  identity, status, privacy, and remediation contracts.
- Safe matrix parallelism and cache use that cannot weaken isolation or proof identity.
- Ordering of independent postapproval registry children without claiming transactionality.

## Deferred Ideas

- Serial companion release evaluation after the linked 0.2.1 rollup.
- GitHub App migration absent a demonstrated credential-policy need.
- Signed artifact attestations or a claimed SLSA level.
- Release dashboard/UI, generic orchestration, staging registry, Android breadth, and adopter
  activation.
