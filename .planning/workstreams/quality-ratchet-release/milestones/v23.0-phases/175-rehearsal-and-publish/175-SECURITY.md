---
phase: "175"
slug: "rehearsal-and-publish"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-09-25"
---

# Phase 175 — Security


## Plan 148 Current Disposition — 2026-10-11T19:58:54.127798+00:00

- Current blocking high findings: **0**. The existing116-row audit contains98 verified mitigations,6 accepted historical high limitations and12 open lower findings. `threats_open: 0` denotes the configured high blocking threshold, not zero total findings.
- REL-17 forward controls passed on actual core 0.2.11 and separate Chimeway 0.1.2 gates and ordinary runs. Fresh exact source/CI/policy/registry facts, protected merges and all six conditions are retained; field/path mutations and98 scanner controls passed.
- Chimeway115 stopped before credentials/Hex because its checkout could not prove ancestry. Repair #233 adds full history to all five existing companion jobs and proves15 depth mutations fail closed. New235 uses its own receipt and one-use binding; the old consumed operation remains stopped.
- The original SC-1/REL-10 breach, six accepted historical findings and12 lower findings remain unchanged. No claim of retroactive compliance or total threat-row re-audit is made.

The dated hold language below is historical. The current forward disposition is in `175-KNOWN-RELEASE-BLOCKER.md`; a future operation still requires a fresh passing gate.

> Refreshed after the Phase 175 forward-guard audit and maintainer disposition. Of 116 plan-scoped
> threat rows, 98 mitigations were verified, six historical evidence gaps are accepted only as
> immutable past events, and twelve low/medium findings remain open below the configured high
> block threshold. No new release is authorized by this disposition.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Candidate CI artifact -> receipt builder | CI and rehearsal artifacts become canonical approval evidence. | Release metadata, package manifests, clean-room result bytes; no adopter data |
| Rehearsal workflows -> registry/mirror state | Credentialed rehearsals establish authority without publishing or changing external state. | Run identity, package and mirror metadata; credentials remain in workflow secrets |
| Historical approval evidence -> protected publication | A human-approved candidate and gate-time repository state authorize irreversible publication. | Candidate identity, CI/run evidence, approval and branch-protection evidence |

## Current Receipt Findings

| Threat ID | Severity | Finding | Mitigation | Status |
|-----------|----------|---------|------------|--------|
| T-175-24-01 | critical | Claimed clean-room digest was not compared with artifact bytes. | Builder reads the clean-room JSON, hashes its bytes, and compares to the CI receipt digest; mismatch test fails closed. | closed |
| T-175-24-02 | high | Exact roster omitted the uploaded clean-room artifact. | Exact roster now requires all eight files; workflow checks the downloaded file; symlinks and non-regular entries fail closed. | closed |
| T-175-24-04 | high | Receipt provenance did not bind actual clean-room bytes. | `candidate.cleanroom` proof binds the file digest; attestation workflow independently compares it with the downloaded file. | closed |

## Forward Release Guard — 2026-09-26

The approved-release guard now invokes `script/check_release_runbook_ancestry.sh` against the exact
first-parent base, approved release-PR head, and merge OID before it emits approval outputs. A
missing commit, invalid object, missing runbook path, or non-ancestor result fails the guard, so the
downstream Release Please and publication jobs cannot proceed. `release.approval.runbook_ancestry_guard`
asserts this contract in the release-workflow integrity checker, and a mutation test removes the
invocation and requires CI to report failure.

This closes a recurring process-control gap for future releases; it does not repair PR #147. The
historical check accidentally relied on divergent local checkout state, and Phase 175's retained
evidence confirms the published base, head, and merge lacked the runbook. The audit recorded
T-175-40b and T-175-35 through T-175-39 as open because required historical facts were unavailable.
The maintainer later accepted only those historical limitations and imposed REL-17 as a hard stop
on future releases. No application data exposure was identified by this audit.

### Post-Guard Audit Evidence — 2026-09-26

| Control | Evidence | Result |
|---------|----------|--------|
| Exact release objects checked before approval outputs | `.github/workflows/release-please.yml:100-102` | Verified |
| Fixed runbook SHA, exact object targets, and guard ordering | `script/check_release_workflow_integrity.exs:1515-1536` | Verified |
| Helper rejects invalid objects, missing runbook, and non-ancestor lineage | `script/check_release_runbook_ancestry.sh:19-52` | Verified |
| Wired-workflow positive case and removed-guard mutation case | `test/crosswake/proof/phase 175_runbook_ancestry_test.exs:111-145` | Verified in test source |

The mitigation is effective for future runs; this evidence does not close the historical T-175-40b
finding.

## Accepted Historical Evidence Gaps

The maintainer explicitly chose to preserve the six historical findings as a known release blocker
instead of leaving Phase 175 permanently stuck on evidence that cannot be recreated. Acceptance is
limited to the fact that the past Gate 1 record is incomplete or noncompliant; it does not claim the
past release was compliant and does not accept the same gap for any future release.

**Release hold:** no new linked release, release recovery, or companion publication may be
authorized until REL-17 is implemented and its exact current-run evidence passes. Until that guard
is complete, the existing Gate 2 requirement remains a manual hard stop. REL-17 requires one
fail-closed, mutation-tested path to verify the six conditions against fresh exact release objects.
The forward ancestry control already covers T-175-40b for future runs; the other evidence fields
must also be required and bound before the issue can close.

| Threat ID | Category | Severity | Accepted historical fact | Future-release condition |
|-----------|----------|----------|---------------------------|--------------------------|
| T-175-35 | Spoofing | high | The historical Gate 1 record lacks its leg-specific Hex run identifier. | Fresh run ID bound to the exact candidate and leg. |
| T-175-36 | Tampering | high | The immediate historical pre-merge identity, CI, and required-check recheck is not evidenced. | Fresh base/head/merge, CI, and required-check policy recheck before authorization. |
| T-175-37 | Repudiation | high | The historical gate lacks its raw registry response and nonempty parse. | Exact response and parse retained in the candidate evidence bundle. |
| T-175-38 | Elevation of Privilege | high | The historical record does not prove normal protected merge or refusal of administrative bypass. | Protected merge-path evidence and bypass refusal checked for the exact merge. |
| T-175-39 | Repudiation | high | The matching historical Hex response-table row is absent. | Matching row is required and bound to the exact Hex run. |
| T-175-40b | Repudiation | high | PR #147 base, head, and merge lacked the required runbook ancestor. | Existing exact-object ancestry guard remains required. |

These are recorded as accepted historical exceptions, not as successful mitigations.

## Previously Blocking Historical Threats — Dispositioned

| Threat ID | Category | Severity | Finding and evidence | Status |
|-----------|----------|----------|---------------------|--------|
| T-175-35 | Spoofing | high | Required leg-specific Hex run identifier was not preserved as the Gate 1 response (`175-07-PLAN.md`, `175-07-SUMMARY.md:37`). | closed — accepted historical exception; future release held by REL-17 |
| T-175-36 | Tampering | high | Immediate pre-merge head/base/merge, CI, and required-check policy recheck was not evidenced (`175-07-PLAN.md:370`, `175-VALIDATION.md:104`). | closed — accepted historical exception; future release held by REL-17 |
| T-175-37 | Repudiation | high | Required raw registry response and nonempty parse were not preserved; separate publication verification does not satisfy that artifact requirement (`175-07-PLAN.md:371`, `175-VALIDATION.md:105`). | closed — accepted historical exception; future release held by REL-17 |
| T-175-38 | Elevation of Privilege | high | Normal protected path and refusal of administrative bypass were not evidenced for the historical publication (`175-07-PLAN.md:372`, `175-VALIDATION.md:104`). | closed — accepted historical exception; future release held by REL-17 |
| T-175-39 | Repudiation | high | The matching Hex response-table row was not recorded at the historical gate (`175-07-PLAN.md:373`). | closed — accepted historical exception; future release held by REL-17 |
| T-175-40b | Repudiation | high | PR #147 base, head, and merge lacked the required runbook ancestor `d3401e…`; a later merge cannot repair this lineage (`175-07-PLAN.md:375`, `175-07-SUMMARY.md:41-47`). | closed — accepted historical exception; future release held by REL-17 |

## Nonblocking Open Findings

These findings are below the configured high-severity block threshold. They remain open until a
maintainer explicitly accepts them or supplies additional evidence.

| Threat ID | Severity | Rationale recorded in plan | Status |
|-----------|----------|-----------------------------|--------|
| T-175-04 | low | `.github` filesystem walk does not follow symlink entries; no repository symlinks were observed; read-only use. | open |
| T-175-10 | low | Weekly Dependabot GitHub Actions updates provide a pin-refresh path. | open |
| T-175-SC (Plan 175-11) | low | No npm, pip, or cargo install was added. | open |
| T-175-SC (Plan 175-12) | low | No npm, pip, or cargo install was added. | open |
| T-175-13-05 | medium | Stale or incomplete evidence fails closed and returns to Plan 12; delay is preferred over uncertain publish authority. | open |
| T-175-13-SC | low | No npm, pip, or cargo install was added; package-legitimacy check is inapplicable. | open |
| T-175-14-SC | low | No npm, pip, or cargo install was added. | open |
| T-175-18-SC | low | No package installation was added. | open |
| T-175-19-SC | low | No npm, pip, or cargo install was added. | open |
| T-175-20-SC | low | No npm, pip, or cargo install was added. | open |
| T-175-24-SC | low | No npm, pip, cargo, or new Mix dependency installation was added. | open |
| T-175-25-SC | low | No npm, pip, cargo, or new Mix dependency installation was added. | open |

## Audit Trail

| Audit Date | Threats Total | Closed | Open | Blocking Open | Result |
|------------|---------------|--------|------|---------------|--------|
| 2026-09-25 | 116 | 98 | 18 | 6 | OPEN_THREATS |
| 2026-09-26 | 116 | 98 | 18 | 6 | OPEN_THREATS — all 18 previously open findings rechecked |
| 2026-09-26 (post-guard) | 116 | 98 | 18 | 6 | OPEN_THREATS — guard wiring verified; historical blockers unchanged |
| 2026-09-26 (maintainer disposition) | 116 | 104 | 12 | 0 | VERIFIED WITH ACCEPTED HISTORICAL EXCEPTIONS — future release held by REL-17 |

## Accepted Risks Log

| Threat ID(s) | Scope accepted | Required constraint | Decision |
|--------------|----------------|---------------------|----------|
| T-175-35 through T-175-40b | Inability to prove or repair the already-completed historical Gate 1 events; no claim of historical compliance is made. | No future linked release, recovery, or companion publication until REL-17's fail-closed evidence gate is implemented and satisfied. | Accepted by maintainer instruction on 2026-09-26 to record the issue as a future release blocker. |

### Recheck of Previously Open Findings — 2026-09-26

| Threat ID(s) | Recheck evidence | Result |
|--------------|------------------|--------|
| T-175-35 | The Plan 175-07 and summary require a leg-specific Gate 1 response; the retained Phase 175 records do not contain the required Gate 1 run identifier. | open at audit — high; accepted later only as a past-event evidence limitation; future release held by REL-17 |
| T-175-36 | Plan 175-07 requires immediate pre-merge identity, CI, and required-check rechecks; `175-VALIDATION.md` records the historical gate as noncompliant and the retained publish-leg record does not supply those checks. | open at audit — high; accepted later only as a past-event evidence limitation; future release held by REL-17 |
| T-175-37 | The retained Plan 175-07 artifacts do not include the required raw registry response and nonempty parse from the gate; later publication confirmation is a different artifact. | open at audit — high; accepted later only as a past-event evidence limitation; future release held by REL-17 |
| T-175-38 | Plan 175-07 requires the normal protected merge path and refusal of administrative bypass; the historical gate artifacts do not establish that condition. | open at audit — high; accepted later only as a past-event evidence limitation; future release held by REL-17 |
| T-175-39 | Plan 175-07 requires the matching Hex response-table row to be recorded at the gate; it is absent from the retained Gate 1 record. | open at audit — high; accepted later only as a past-event evidence limitation; future release held by REL-17 |
| T-175-40b | `175-07-SUMMARY.md` records that the required runbook commit was not an ancestor of PR #147 base, head, or merge, and the runbook file was absent from those objects. | open at audit — high; accepted later only as a past-event evidence limitation; future release held by REL-17 |
| T-175-04 | Plan 175-01 records the `withFileTypes` non-following rationale, a read-only walk, and no observed `.github` symlinks. No accepted-risk entry exists in this file, as required for an `accept` disposition. | remains open — low; rationale verified, acceptance not recorded |
| T-175-10 | Plan 175-02 and `.github/dependabot.yml` document weekly GitHub Actions pin updates. No accepted-risk entry exists in this file, as required for an `accept` disposition. | remains open — low; update path verified, acceptance not recorded |
| T-175-13-05 | Plan 175-13 and its summary document fail-closed handling of stale or incomplete evidence and return to the preceding evidence plan. The register disposition is `accept`, and no accepted-risk entry exists here. | remains open — medium; fail-closed behavior documented, acceptance not recorded |
| T-175-SC (Plans 175-11, 175-12, 175-13, 175-14, 175-18, 175-19, 175-20, 175-24, 175-25) | The nine completed plan scopes and summaries describe no npm, pip, or cargo installation. Each register row is an `accept` disposition; no accepted-risk entry exists here. | remain open — low; inapplicability confirmed, acceptance not recorded |

The phase has 21 completed plan summaries and 116 corresponding threat rows. Summary threat flags reviewed during the audit map to declared threat IDs; no unregistered threat flag was found. The six historical evidence gaps are accepted only as past events and remain a future-release blocker under REL-17. The 12 low/medium findings remain open below the configured block threshold. No historical evidence was recreated and no external state was changed.

The current implementation closes T-175-24-01, T-175-24-02, and T-175-24-04. It does not alter
historical publication evidence. No external state was changed during this audit or repair.

## Sign-Off

- [x] Current receipt findings rechecked against implementation
- [x] Historical high-severity findings remain explicitly recorded and accepted only as past events
- [x] Lower-severity findings are not represented as accepted
- [x] Security gate resolved by explicit maintainer disposition with a future-release hold
- [x] `threats_open: 0` at configured `block_on: high`
