# Phase 165: Efficient and Maintainable CI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-28
**Phase:** 165-efficient-and-maintainable-ci
**Areas discussed:** Trigger and merge policy, Proof and gate consolidation, Change classification,
Reproducible efficiency evidence

---

## Trigger and merge policy

| Option | Description | Selected |
|--------|-------------|----------|
| Full PR plus full `push: main` | Conventional Phoenix/Ecto/Plug/LiveView posture, but repeats equivalent proof and scarce native work. | |
| Authoritative PR plus slim `push: main` | Test the synthetic merge result once; reserve main for release, audits, and a slim canary. | ✓ |
| Cheap PR plus full `merge_group` | Strongest eventual queue model, but unavailable to the current user-owned repository and requires a governance change. | |

**User's choice:** Adopt the researched recommendation package.
**Notes:** PR proof becomes authoritative only after strict branch/no-bypass authority is verified.
Cancellation is scoped by PR number and monotonic run identity; release/main/recovery work is never
cancelled. Merge queue is deferred until organization ownership and demonstrated pressure.

---

## Proof and gate consolidation

| Option | Description | Selected |
|--------|-------------|----------|
| One umbrella required gate | One branch-protection contract over literal named leaves, with exact manifest and explicit irrelevance. | ✓ |
| A few purpose gates | Separate core/browser/native/governance contexts with repeated rollup policy. | |
| Preserve granular required contexts | Lowest initial migration risk but retains policy drift, noise, and skipped-required false-green risk. | |
| Dynamic proof matrix | Compact for homogeneous shards but unsuitable for heterogeneous proof identity. | |

**User's choice:** Adopt the researched recommendation package.
**Notes:** Migrate green-first with old contexts retained until the umbrella is observed, registered,
and verified. Named proof leaves, logs, and artifacts remain visible. Release, scheduled, recovery,
and advisory workflows stay separate by trust boundary.

---

## Change classification

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow docs-only allowlist | Simple fail-closed policy: only proven documentation-only changes skip unrelated proof. | ✓ |
| Fine-grained domain mapping | Greater possible savings with substantially higher ownership-drift risk. | |
| Workflow-level path filters | Avoids starting workflows but leaves filtered required contexts pending. | |
| Classifier plus conditional leaves and rollup | Always-visible execution topology that makes explicit irrelevance machine-checkable. | ✓ |

**User's choice:** Adopt the researched recommendation package.
**Notes:** The selected policy and topology are complementary: a first-party, NUL-safe classifier
uses a narrow docs-only allowlist; everything malformed, mixed, unknown, or executable gets full
proof. Job-level conditions prevent runner allocation, and the umbrella independently validates
every skip.

---

## Reproducible efficiency evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Historical seed narrative | Useful origin evidence but stale as a current baseline. | |
| One fresh snapshot | Current but too sensitive to cache and queue variance. | |
| Matched before/after cohorts | Exact run provenance, comparable change classes, and median/range reporting. | ✓ |
| Permanent metrics workflow/dashboard | Longitudinal but creates new operational surface and flaky threshold pressure. | |

**User's choice:** Adopt the researched recommendation package.
**Notes:** Retain sanitized canonical JSON and generated Markdown as phase-local evidence. GitHub's
missing per-job queued timestamp is labeled `not exposed`; timing remains descriptive until stable
history exists. Only recurring structural contracts are promoted into CI.

---

## the agent's Discretion

- Exact filenames and internal decomposition of the one PR orchestration workflow, composites,
  scripts, leaf manifest, and evidence schema.
- Exact documentation-only allowlist after a full repository inventory, within the full-proof
  default and bounded relevant-doc checks.
- Exact matched-cohort sample size, provided selection and missing-data rules are explicit and
  results report sample counts plus median/range.
- Exact literal umbrella name, provided it is stable, unique, purpose-oriented, and migrated
  green-first.

## Deferred Ideas

- Merge queue after organization ownership and demonstrated merge pressure.
- Fine-grained per-domain selective CI only if Phase 165 evidence proves the extra complexity earns
  its keep.
- Permanent CI performance SLO/dashboard only with stable history and a named owner.
- Unified local clean-checkout command in Phase 166.
- Custom CI UI or presentation polish outside this infrastructure phase.
