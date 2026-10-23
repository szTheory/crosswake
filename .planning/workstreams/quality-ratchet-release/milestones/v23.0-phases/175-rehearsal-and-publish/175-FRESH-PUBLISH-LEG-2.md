# Phase 175 — Fresh Core Publish Leg 2: Partial Release Record

**Disposition:** `PARTIAL` — the authorized ordinary graph ran once and produced mixed immutable
public state. This is an incident record, not a success claim.

## Exact authority and merge

- Gate 2 authorization: `publish fresh core 35809832762` for PR #196 / `0.2.3` only.
- Approved candidate base/head/tree: `7a615cb0ddf2a55ef6ffab1c0c841ec3d92dea60` /
  `a8d86b29ee5731332ceac9abc176ecdc8262e7e1` /
  `873210c237fe0bdceca65b90f222dd93b0c8b595`.
- Protected merge OID: `4df029d3799d2db18003471019c42126878572f8` at
  `2026-09-23T17:50:45Z`.
- The merge has two parents; its second parent is the approved candidate head, its tree matches the
  approved candidate tree, and runbook commit
  `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8` is an ancestor.

## Ordinary release graph

Run [35898407350](https://github.com/szTheory/crosswake/actions/runs/35898407350) was the one
ordinary `Release Please` push run bound to the merge OID. It was not retried.

| Job | Conclusion | Recorded fact |
| --- | --- | --- |
| `release: approved-candidate merge guard` | `success` | Exact candidate-parent/tree/receipt guard passed. |
| `Release Please` | `success` | Ordinary release operation completed. |
| `Publish to Hex.pm` | `success` | The root Hex publish completed. |
| `Mirror iOS core to split repo` | `failure` | The ordinary mirror publication did not complete. |
| `Publish Android core to Maven Central` | `failure` | The ordinary Maven publication did not complete. |
| `Clean-room proof — iOS swift build` | `skipped` | Required upstream iOS publication was non-success. |
| `Clean-room proof — Android gradle build` | `skipped` | Required upstream Maven publication was non-success. |
| `release: exact-public artifact proof` | `skipped` | The three-coordinate proof did not run after the partial graph. |
| linked core release rollup | `failure` | Mixed required child outcomes are not success. |

Companion jobs are outside this linked-core record and were skipped. No recovery workflow,
individual registry job, historic run `35555386857`, bypass, direct push, tag replacement, or
registry retry was dispatched.

## Independent registry observations

Observed at `2026-09-23T18:07:44Z`, separately from GitHub job conclusions:

| Registry | Exact coordinate | Observation | Verdict |
| --- | --- | --- | --- |
| Hex | `crosswake@0.2.3` | Version present | Live and irreversible. |
| iOS mirror | `refs/tags/v0.2.3` | Tag absent; expected split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` not observed | Not published. |
| Maven Central | `io.github.sztheory:crosswake-shell-core-android:0.2.3` POM | HTTP `404` | Not publicly present. |

The historic `0.2.2` preparation was not retried. **REL-10 remains BREACHED** for historic Gate 1;
fresh runbook ancestry does not retroactively repair it.

## Required forward-recovery authority

The committed incident table requires a `PARTIAL` release to preserve the live Hex coordinate and
recover only a named missing coordinate from an exact approved reference. This plan grants no
individual retry authority. Maven's `404` establishes only public absence; any deployment state
must be investigated through its owning incident procedure before a recovery decision. The iOS
recovery path requires a newly reviewed exact identity for this transaction before it can move a
mirror ref. A new explicit forward-recovery decision is therefore required before any further
remote mutation.
