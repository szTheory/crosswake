---
status: diagnosed
trigger: "quality-ratchet-release: Release Please run 36352732061 failed in approved-candidate merge guard before publishers; local post-merge REL-17 capture passes; diagnose without retrying publication"
created: 2026-09-27
updated: 2026-09-27
---

# Release Please Approved-Candidate Guard Run 36352732061

## Symptoms

- expected_behavior: The authorized, protected merge of candidate PR #215 should pass the exact approved-candidate guard and allow the single ordinary Release Please workflow to continue.
- actual_behavior: Run 36352732061 failed in `release: approved-candidate merge guard`; Release Please and all publishers were skipped. A separately captured local post-merge REL-17 envelope passed.
- error_messages: The failed step ended with exit code 1 and no specific REL-17 PASS/BLOCKED diagnostic. Its last visible output was three successful runbook ancestry checks for base `b5608a3dc0b013d83ac2b25768f1907873739b20`, head `0968fea84dc758c05b9b0161db2f221c9e778c3b`, and merge `998742856a37a97ae7247f6c532f9c154ea20885`.
- timeline: Candidate PR #215 / version 0.2.6 passed exact-head CI run 36346477576; normal protected merge completed at 2026-09-27T21:42:47Z; Release Please run 36352732061 failed at 21:43Z; an independent post-merge capture passed at 21:45:47Z.
- reproduction: Inspect existing workflow run 36352732061 and its exact merge guard; compare that execution path with the retained passing post-merge capture. Do not rerun or dispatch publication.

## Current Focus

- bug_class: Bohrbug (deterministic guard rejection for this merge)
- reasoning_checkpoint:
    hypothesis: A command after the guard's three runbook ancestry checks failed silently under `set -e`, likely in the artifact/receipt revalidation or live REL-17 gate invocation; the retained passing capture indicates a difference between the hosted workflow path and the separately invoked capture.
    confirming_evidence:
      - Run 36352732061 reached and passed all three ancestry checks, then exited 1 without a REL-17 diagnostic.
      - The retained post-merge REL-17 capture validates the same base, head, merge, receipt digest, leg run, and runbook ancestry.
      - The publisher jobs were skipped and post-run registry checks found no publication.
    falsification_test: Identify the exact first failing command from the run's captured step output and show that it is unrelated to receipt/artifact/REL-17 input or environment differences.
    fix_rationale: Diagnose the earliest divergent command before proposing a change; this session is diagnosis-only and publication authority is consumed.
    blind_spots: The repository worktree contains extensive pre-existing dirty Phase 175 changes. Preserve them. The local commit database does not currently contain the remote merge object; do not alter branch/worktree state to obtain it without need.
    candidate_causes:
      - config: the guard's candidate receipt or CI-artifact consistency checks reject the exact attestation despite the independently passing capture.
      - environment: the hosted workflow's GitHub API/artifact download result differs from the local capture inputs.
      - code: a post-ancestry shell check exits silently under `set -e` before the REL-17 Mix task emits a reason.
    and_gate: Unknown; locate the exact first failing command before selecting a root cause.
- hypothesis: The immutable merge trailer binds the linked-release authorization phrase to the iOS rehearsal run ID, while its structured leg_run_id and the guard require the Hex rehearsal run ID.
- test: In-memory examination of the existing receipt and CI artifact ZIPs, followed by the exact linked-release jq condition over the immutable merge message.
- expecting: All earlier artifact checks pass; the authorization equality returns false with jq exit 1.
- next_action: Report the confirmed diagnosis to the parent; keep the consumed Gate 2 and failed run unchanged.

## Evidence

- timestamp: 2026-09-27T21:43:22Z
  checked: Existing GitHub Actions run 36352732061 through `scripts/ci_monitor.cjs`.
  found: Only `release: approved-candidate merge guard` failed; its three runbook ancestry checks passed; Release Please, Hex, iOS, Maven, and exact-public jobs were skipped.
  implication: Failure occurs after ancestry validation and before any publisher.
- timestamp: 2026-09-27T21:45:47Z
  checked: Retained post-merge REL-17 capture and Gate 2 evidence.
  found: The exact protected merge, parents, tree, consumed authorization identity, candidate receipt, leg run, and runbook ancestry passed local live validation.
  implication: Candidate identity and merge provenance are not yet demonstrated as the cause; compare the workflow's additional artifact checks and execution environment.
- timestamp: 2026-09-27
  checked: Immutable merge message for 998742856a37a97ae7247f6c532f9c154ea20885 and workflow trailer predicate.
  found: Trailer authorization says `publish successor core 36348273033`; its `leg_run_id` is `36348273088`. The linked-release predicate requires `authorization == "publish successor core " + (leg_run_id|tostring)`.
  implication: The trailer predicate would fail if reached. Check all earlier post-ancestry receipt and CI predicates before calling it the first failure.
- timestamp: 2026-09-27
  checked: Existing remote receipt artifact 10941079991, CI artifact 10940702866, and their run metadata, inspected in memory without downloads to disk or workflow reruns.
  found: Receipt artifact is the one live named artifact, attestation run 36348696331 is successful workflow_dispatch `iOS mirror authority`, CI run 36346477576 is successful on the exact head, receipt SHA-256 is c51181d384661e77cf68935a6496b4c4bdf9e147854889027f64312dd5d6e9ba, receipt fields and bound/observed identity match, CI receipt SHA-256 matches the receipt's candidate.ci proof, and the two artifacts.json byte streams are identical (SHA-256 1ee167096decb820d5f1dd56ab0be453286ee23c455dc911c46abbd06795afed).
  implication: The workflow's silent receipt/CI predicates between ancestry and trailer validation evaluate true for the retained immutable artifacts. There is no artifact inconsistency explaining this exit.
- timestamp: 2026-09-27
  checked: The exact linked-release authorization equality from `.github/workflows/release-please.yml` over the protected merge message using `jq -e`.
  found: `authorization == ("publish successor core " + (leg_run_id|tostring))` prints false and exits 1. The actual phrase names 36348273033, the iOS rehearsal run; leg_run_id 36348273088 names the Hex rehearsal and the passing post-merge capture's operation identity.
  implication: `.github/workflows/release-please.yml` lines 235-262 contain the first failing silent command after the three ancestry checks. Shell `-e` exits before `require_release_evidence.sh`, so no REL-17 diagnostic appears.
- timestamp: 2026-09-27
  checked: `EvidenceGate.validate_authorization/4`, live authorization validation, and retained post-merge envelope.
  found: The independent capture checks a seven-key CONSUMED authorization object containing receipt digest, operation, leg_run_id, package, and head. It does not include or check the raw authorization phrase from the merge trailer.
  implication: The capture PASS and hosted guard failure are compatible; they evaluate different predicates over different representations of the same authorization.

## Eliminated

- hypothesis: Receipt artifact or CI artifact disagreement caused the first silent failure.
  evidence: Both retained artifact ZIPs satisfy the guard's identity, digest, CI proof, and byte-comparison predicates.
  timestamp: 2026-09-27
- hypothesis: The shared live REL-17 Mix gate rejected the merge.
  evidence: The preceding trailer jq condition itself returns exit 1; the run log has only the first ancestry trio, with no output from `require_release_evidence.sh`.
  timestamp: 2026-09-27

## Resolution

- root_cause: The authorized Gate 2 envelope and immutable merge trailer used `authorization: "publish successor core 36348273033"` (iOS rehearsal run) while `leg_run_id` was `36348273088` (Hex rehearsal run). The approved-candidate guard's exact linked-release phrase predicate requires the authorization number to equal leg_run_id, so its `jq -e` command exits 1 under shell `-e` before the live REL-17 gate or publishers.
- discrepancy_with_passing_capture: The separate post-merge REL-17 capture validated the compact CONSUMED authorization identity with leg_run_id 36348273088. That compact object excludes the raw authorization phrase; therefore its PASS does not imply the merge trailer passes the workflow's stricter phrase check.
- first_failing_check: `.github/workflows/release-please.yml:235` through `:262`, specifically the linked-release equality at `:255`.
- suggested_fix_direction: For a future separately authorized candidate, generate and validate the authorization phrase from the same operation-bound leg_run_id before protected merge. The consumed attempt remains PARTIAL; no retry, publication, or fix was performed in this diagnosis.
