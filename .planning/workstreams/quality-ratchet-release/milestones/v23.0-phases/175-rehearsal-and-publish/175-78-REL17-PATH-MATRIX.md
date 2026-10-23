# Phase 175 Plan 78 REL-17 Path Matrix

This is a sanitized local proof record. It does not grant publication authority. `PROVEN` refers
only to the cited local assertions; `UNKNOWN` cells remain open and cannot promote a release.

## Publisher Matrix

| publisher | leg_run | candidate_readiness | registry_response | protected_merge | response_row | runbook_ancestry | material_binding | real_shell_mix_capture_validator | zero_sink_negative | exact_sink_positive | workflow_presence_order | final_guard_execution |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| release_please_creation | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| core_hex | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| core_ios | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| core_maven | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| recovery_hex | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| recovery_maven | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| recovery_ios | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| legacy_ios | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| companion_rulestead | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| companion_rindle | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| companion_sigra | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| companion_chimeway | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |
| companion_threadline | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN | PROVEN | UNKNOWN | PROVEN | PROVEN | PROVEN | PROVEN | UNKNOWN |

## Condition Evidence

| condition | state | reference | process case |
| --- | --- | --- | --- |
| leg_run | PROVEN | P1 | Valid row control plus explicit failure and absent conclusion; each negative has zero sinks. |
| candidate_readiness | PROVEN | P1 | Valid row control plus failed and absent CI conclusion; each negative has zero sinks. |
| registry_response | PROVEN | P1 | Valid row control plus HTTP failure and empty response body; each negative has zero sinks. |
| protected_merge | PROVEN | P1 | Valid row control plus changed and absent parent list; each negative has zero sinks. |
| response_row | UNKNOWN | — | The live adapter derives this row from the same leg response and request identity. There is no independent process input to mutate without also changing `leg_run`; direct validator mutation does not prove this path per publisher. |
| runbook_ancestry | PROVEN | P1 | Valid row control plus failed ancestry lookup; each negative has zero sinks. |

## Material Binding

| binding | state | evidence and limit |
| --- | --- | --- |
| leg run ID | PROVEN | P1 mutates the returned run ID for every publisher row and asserts a blocked gate with zero sinks. |
| candidate PR, base, head, and tree | PROVEN | P1 mutates each fetched candidate identity independently for every publisher row and asserts zero sinks. |
| actual merge OID | PROVEN | P1 changes the fetched merge selector for every publisher row and asserts zero sinks. |
| current policy | PROVEN | P1 changes the fetched policy fingerprint for every publisher row and asserts zero sinks. |
| receipt digest, operation, and authorization text | UNKNOWN | Linked-release authorization mutations are covered by P1; the same independent binding was not exercised for every recovery and companion row. |
| candidate package and version | UNKNOWN | Workflow guards bind package/version at their caller boundary; the process harness does not independently vary those workflow inputs for each row. |
| source path and source digest | UNKNOWN | The shared validator has direct source-fact mutation coverage, but the process harness cannot alter the capture output between capture and validation. |
| runbook commit identity | UNKNOWN | Ancestry failure is exercised; a different valid runbook commit was not independently bound per row. |

## Path and Workflow Evidence

| publisher | workflow check | reference |
| --- | --- | --- |
| release_please_creation | release.rel17.release_creation_guard | P3 |
| core_hex | release.rel17.core_hex_job_guard | P2 |
| core_ios | release.rel17.core_ios_job_guard | P6 |
| core_maven | release.rel17.core_maven_job_guard | P7 |
| recovery_hex | release.rel17.recovery_hex_job_guard | P4 |
| recovery_maven | release.rel17.recovery_maven_job_guard | P4 |
| recovery_ios | release.rel17.recovery_ios_job_guard | P4 |
| legacy_ios | release.rel17.legacy_ios_job_guard | P4 |
| companion_rulestead | release.rel17.companion_rulestead_job_guard | P5 |
| companion_rindle | release.rel17.companion_rindle_job_guard | P5 |
| companion_sigra | release.rel17.companion_sigra_job_guard | P5 |
| companion_chimeway | release.rel17.companion_chimeway_job_guard | P5 |
| companion_threadline | release.rel17.companion_threadline_job_guard | P5 |

Workflow presence/order is PROVEN for the publisher rows with passing named scanner checks and matching mutation/order assertions; this structural result leaves final publisher-guard execution UNKNOWN.

`P1` executes the real `require_release_evidence.sh`, the real Mix live task, fresh live capture,
and the production validator with allowlisted fake providers. Valid controls produce exactly one
row-specific fake sink; changed and unknown condition cases produce no sink. The fake sink command
is invoked after the live shell gate, but the Hex, iOS, and Maven final publication scripts were
not executed end to end. Their presence and ordering are covered by the workflow scanner mutations;
runtime execution remains UNKNOWN.

The scanner's named structural checks and their matching mutation/order assertions passed locally. They do not establish execution of the real publisher workflows or their final guards.

## Assertion References

| reference | test assertion |
| --- | --- |
| P1 | `test/crosswake/proof/phase175_rel17_condition_paths_test.exs` — every publisher row passes its exact live context to only its fake sink |
| P2 | `test/crosswake/proof/phase175_rel17_publish_paths_test.exs` — removing each ordinary publisher job gate fails its named check |
| P3 | `test/crosswake/proof/phase175_rel17_publish_paths_test.exs` — moving the Release Please gate after its action fails the release-creation check |
| P4 | `test/crosswake/proof/phase175_rel17_recovery_paths_test.exs` — removing each recovery entry gate fails its dedicated scanner check |
| P5 | `test/crosswake/proof/phase175_rel17_wiring_test.exs` — removing any companion entry gate fails that package's named check |
| P6 | `test/crosswake/proof/phase175_rel17_wiring_test.exs` — independent iOS push mutations each fail the shared final-boundary check |
| P7 | `test/crosswake/proof/phase175_rel17_wiring_test.exs` — removing the Maven final gate fails its dedicated boundary check |
| P8 | `test/crosswake/proof/phase175_rel17_wiring_test.exs` — the full scanner declares and passes every REL-17 guard check |
| P9 | `test/crosswake/release_candidate/evidence_gate_test.exs` — each REL-17 condition and binding blocks when its source fact is changed |

## Required Dispositions

Plan55: UNKNOWN

Plan70: UNKNOWN

Plan76: UNKNOWN_UNVERIFIABLE; authorization CONSUMED

REL-13: OPEN

REL-17: OPEN

candidate readiness: BLOCKED

merge policy: UNKNOWN

release hold: ACTIVE

Plans175-45–175-48: HELD

Phase175: INCOMPLETE
