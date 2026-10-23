# Phase 175 Plan 70 Local Diagnosis

## Recorded Plan70 facts

The retained [Plan70 summary](175-70-SUMMARY.md), under **Collection Outcome**, reports exactly one collector invocation and captured exit status `1`. It reports the local inspector disposition as `TERMINAL_FAILURE`; the Plan70 artifact is absent. The summary explicitly says it does not establish a source-specific status, source count, request count, whether or how many GitHub reads occurred, or the underlying cause.

The retained [four-event lifecycle](evidence/175-plan70-source-outcomes.lifecycle.jsonl) records, in sequence, `task-entry`, `reservation`, `collection-intent`, and `collection-failed`. Its terminal event is classified `UNKNOWN` and has the generic reason code `collection_failed`. That reason records a terminal state only; it does not identify a source stage or explain why collection failed. The Plan70 artifact at `evidence/175-plan70-source-outcomes.json` is absent. The original [Plan70 plan](175-70-PLAN.md) describes the intended contract and is not evidence of which code path executed.

The summary's one invocation and exit status are retained historical claims; the lifecycle independently supports only its four recorded events and terminal UNKNOWN. Neither establishes request occurrence or count.

Plan70 cause: UNKNOWN

Plan70 request occurrence/count: UNKNOWN

Plan55 remains UNKNOWN; REL-13/REL-17 remain OPEN; candidate readiness BLOCKED; merge-policy UNKNOWN; release hold ACTIVE; Plans 175-45..48 blocked; Phase 175 incomplete.

REL-13: OPEN; REL-17: OPEN; candidate readiness: BLOCKED; merge-policy: UNKNOWN; release hold: ACTIVE

## Current implementation paths

These are possible behaviors of the current, already-dirty worktree source. They are not findings about the consumed Plan70 invocation.

- **Entry and terminal handling:** `collect_plan70_exact_head!/2` reserves the local lifecycle before entering `plan70_collect_reserved!/5`; the wrapper and reserved collector convert rescue/catch paths to a generic UNKNOWN stop and attempt to close an unfinished lifecycle (`lib/crosswake/release_candidate/ios_tag_source_runner.ex:6923-7004`). `plan70_close_unknown_attempt!/3` appends only a bounded `collection-failed` event when its current preconditions permit it (`.../ios_tag_source_runner.ex:7546-7574`).
- **Request and source boundary:** the current default callback is private `plan68_live_request/1`, which delegates to `decode_gh_json/2`; that wrapper uses `System.cmd/3` and bounds JSON parsing/output (`.../ios_tag_source_runner.ex:1507-1528, 8420`). Each response passes through `plan70_safe_request/2` and `plan70_source/3`, which map raised/thrown requests and normalization failures to a safe unavailable result. `plan70_collect_remaining/2` preserves completed rows and stops dependent stages after a failed stage; a CLOSED initial PR skips those dependent stages (`.../ios_tag_source_runner.ex:7104-7207`).
- **Artifact and local inspection:** `validate_plan70_artifacts!/1` checks a validated artifact against its lifecycle; `plan70_local_disposition/1` distinguishes a valid pair, a terminal failure with no artifact, no paths, or uncertainty (`.../ios_tag_source_runner.ex:7007-7091`). `validate_plan70_source_outcomes!/2` checks the exact schema, source invariants, digest, bounded size, and held status fields (`lib/crosswake/release_candidate/ios_tag_source_evidence.ex:1675-1705`). The projection and text renderer emit bounded status/source rows and a single next action (`.../ios_tag_source_evidence.ex:1902-1939`).
- **Existing process collector:** the runner's separate `collect/8` helper invokes `script/release_candidate/ios_tag_source_collector.mjs` over a Node child-process boundary (`.../ios_tag_source_runner.ex:6498-6533`). The script validates a closed request shape and operation allowlist, limits input/output, and projects process outcomes without raw stderr (`script/release_candidate/ios_tag_source_collector.mjs:1-23, 49-71, 73-155`). The current Plan70 callback path above does not call this helper. This adjacent implementation therefore does not establish which path a removed temporary Plan70 Mix entrypoint selected.
- **Fake coverage:** the runner tests exercise a CLOSED initial PR with dependent requests stopped, failures injected at each of the eight source stages, and a complete fake source sequence (`test/crosswake/release_candidate/ios_tag_source_runner_test.exs:2437-2607`). The evidence tests exercise a CLOSED initial candidate and reject promotion of it to PROVEN (`test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:818-864`). These tests use injected fake callbacks and local fixtures; they demonstrate current code behavior under those fixtures, not which code or requests ran in the consumed invocation.

## Historical attribution boundary

The execution-time Plan70 Mix entrypoint is absent, and the shared runner/evidence files were already dirty before the Plan70 invocation. Current source branches and fake tests cannot identify the exact code path selected then. The retained lifecycle provides a terminal event only; it contains no source-stage result or request observation. No separate retained local artifact establishes a concrete cause or request count.

Plan70 cause: UNKNOWN

Plan70 request occurrence/count: UNKNOWN

**Next action:** If another remote observation is still needed after this local diagnosis, first hold a separate discussion, create a fresh plan, and obtain independent review. D-95 also requires a unique attempt ID, versioned schema and exclusive artifact/lifecycle paths, endpoint-minimum permissions, bounded pagination, and at most one collector invocation. These are future prerequisites only; this diagnosis grants no remote-read, CI, merge, tag, recovery, registry, publication, or release authority.

Plan55 remains UNKNOWN; REL-13/REL-17 remain OPEN; candidate readiness BLOCKED; merge-policy UNKNOWN; release hold ACTIVE; Plans 175-45..48 blocked; Phase 175 incomplete.

REL-13: OPEN; REL-17: OPEN; candidate readiness: BLOCKED; merge-policy: UNKNOWN; release hold: ACTIVE
