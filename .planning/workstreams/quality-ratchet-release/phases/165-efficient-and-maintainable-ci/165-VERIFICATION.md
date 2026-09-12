---
phase: 165-efficient-and-maintainable-ci
verified: 2026-09-09T03:59:16Z
status: passed
score: 55/55 must-haves verified
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 33
  total: 33
  not_honored: []
human_verification: []
---

# Phase 165: Efficient and Maintainable CI Verification Report

**Phase Goal:** Maintainers receive faster, cheaper CI feedback without losing named proof or authoritative results.
**Verified:** 2026-09-09T03:59:16Z
**Status:** passed
**Re-verification:** No — initial goal-backward verification

## Goal Achievement

The phase goal is achieved. The verifier independently ran the recurring Phase 165 gate, inspected the final workflow and policy graph, re-read live branch protection, checked the immutable remote source, validated both evidence snapshots, and reconstructed the live cancellation outcome from GitHub run records. The final topology uses one pull-request workflow, one app-bound required result, 44 literal proof leaves, one classifier control node, and no compatibility-only authority.

The efficiency claim is deliberately narrow. The live documentation probe ran one applicable proof leaf rather than the 44-leaf executable graph, duplicate recurring push proof is absent, pure work is placed on Linux, and obsolete lower runs are cancelled. The retained before/after timing cohorts do **not** support a causal performance claim; unavailable or non-comparable observations remain `not_measured`, and exact job queue time remains `not_exposed`.

### Observable Truths

The five ROADMAP success criteria and all 55 PLAN truths were merged and checked. Repeated plan truths are shown as contract groups below; the score counts every individual PLAN truth once, with ROADMAP restatements deduplicated.

| Truth group | PLAN truths | Status | Evidence |
| --- | ---: | --- | --- |
| Canonical baseline and evidence edge semantics | 1–3, 9–13 | ✓ VERIFIED | `baseline.json` predates topology commits; both snapshots validate; the monitor self-test exercises singleton, zero/reversed timestamps, ordering, unavailable cohorts, integer units, and `not_exposed` queue semantics. |
| Fail-closed documentation classification | 4–8, 14, 30, 32, 35, 38, 41 | ✓ VERIFIED | Six classifier self-tests passed, including NUL/status/SHA/path adversaries, shallow-history acquisition, ordering, mixed/empty input, and focused public-doc scheduling. Live PR #140 recorded `documentation_only`, one active documentation leaf, 43 explicit skips, and a successful umbrella. |
| Exact literal proof graph and closed umbrella | 15–18, 28, 31, 33–34, 39, 42–43, 45, 51, 55 | ✓ VERIFIED | Manifest validator and maximum-shape tests passed. Final manifest has 44 proof leaves + one `classify-change` control; workflow static `needs` is the same set. Compatibility rows are zero. Live executable PR #141 recorded all 44 leaves active and a successful umbrella. |
| Monotonic trusted cancellation | 19–24, 46 | ✓ VERIFIED | Four selector behavioral tests passed. Controller is `workflow_run: requested`, default-branch sourced, no PR checkout, `actions: write` only. Live API records show run `34282293939` cancelled, newer same-workflow/same-probe-branch run `34282374655` terminal `success`, and controller run `34282377278` terminal `success`; its log selected only lower ID `34282293939`. |
| Runner, cache, timeout, and release trust | 25–27, 36–37 | ✓ VERIFIED | Twenty-six integrity tests passed, including runner placement, one-dimension cache-identity misses, positive job timeouts, no assertion retries, frozen Android posture, and unchanged release/recovery authority. |
| Single PR authority and separated trust boundaries | 29, 40 | ✓ VERIFIED | Producer/trigger inventory passed: Crosswake CI is pull-request only; release, publish/recovery, scheduled, manual, and advisory workflows remain separate. |
| Exact staged required-check retirement | 44, 47–50 | ✓ VERIFIED | The digest-bound proposal and explicit `approve-exact-retirement` record exist. Live target audit now reports strict protection with exactly `{context: Crosswake CI, app_id: 15368}`; all 27 legacy contexts are absent. |
| Exact final source and honest comparison | 52–54 | ✓ VERIFIED | Remote `main` and `final-remote-default-source.json` both resolve to `0b59224bbabc3f0b40038d0c1c4dc7ecae81de4c`; workflow and manifest digests reverified. Comparison contains counts, runners, delay, execution, critical path, runner-seconds, cache outcomes, sample counts/ranges, and closed unavailable states without a causal claim. |

**Score:** 55/55 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/ci_monitor.cjs` | Evidence capture/validation/comparison, live probes, final-source and immutable-action checks | ✓ VERIFIED | 1,524 substantive lines; commands are dispatched and exercised by self-tests, ExUnit, exact-source verification, and evidence validation. |
| `script/classify_ci_change.py` | NUL-safe binary documentation classifier | ✓ VERIFIED | 395 substantive lines; workflow invokes it with validated base/merge objects; six self-tests passed. |
| `script/ci_leaf_manifest.json` + `script/check_ci_leaf_manifest.py` | Exact leaf/control/needs/producer authority | ✓ VERIFIED | 44 leaves, one control, zero compatibility rows; production and mutation fixtures passed. |
| `.github/workflows/crosswake-ci.yml` | Sole recurring PR proof workflow and checkout-free umbrella | ✓ VERIFIED | 1,520 lines; PR-only trigger, read-only contents permission, PR-number concurrency, 44 literal leaves, and exact static umbrella dependencies. |
| `.github/workflows/cancel-obsolete-crosswake-ci.yml` + selector | Trusted monotonic cancellation | ✓ VERIFIED | Requested-event controller uses default-branch policy and only Actions write; selection and live outcome are behaviorally proven. |
| Setup composites and portable Android helper | Complete cache identity and correct runner placement | ✓ VERIFIED | Official actions are immutable-SHA pinned; Android JVM setup is separate from optional device provisioning. |
| `script/required_check_policy.json` and required-check scripts | App-bound target authority and exact retirement | ✓ VERIFIED | Policy binds `Crosswake CI` to app ID 15368; live response is strict and exactly mirrored. |
| `script/check_phase165_efficient_ci.sh` | One recurring credential-free contract gate | ✓ VERIFIED | 78-line fail-fast composition; completed successfully in this verification. |
| Phase evidence directory | Baseline, live observations, proposal, exact final source, after snapshot, comparison | ✓ VERIFIED | All artifacts exist and validate. Final evidence binds the current remote tip and contains closed `not_measured`/`not_exposed` results rather than invented data. |
| Phase 165 test suites and adversarial fixtures | Behavioral proof for CIP-01 through CIP-07 | ✓ VERIFIED | 14 policy, 26 integrity, and 9 evidence ExUnit tests passed, plus Python self-tests and negative fixtures. |

The generic artifact helper reported false negatives for PLAN entries written as phase-relative `evidence/...` paths and raised `EISDIR` for the intentional classifier fixture directory. Direct inspection resolved those plan-path limitations: every referenced evidence file and the substantive fixture corpus exists in the phase directory.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| GitHub PR diff | classifier | validated base and synthetic-merge commit objects | ✓ WIRED | Workflow performs full-history checkout/object checks, defaults to full proof, then invokes classifier by argv. |
| Classifier outputs | literal leaf conditions | closed classification and scheduled-family outputs | ✓ WIRED | Public docs schedule documentation, brand structural, collateral, Hex-page, and Threadline owners; invalid/mixed inputs schedule full proof. |
| Manifest | workflow jobs and umbrella | exact IDs, display names, remediation, irrelevance, static `needs` | ✓ WIRED | Bidirectional validator and mutation fixtures passed; 44 + 1 exact. |
| Requested workflow run | trusted controller | GitHub event JSON → pure strict-lower selector → bounded cancel | ✓ WIRED | Controller does not checkout PR code; historical API/log evidence confirms lower-only cancellation and newer terminal success. |
| Cache/setup identity | proof leaves | repository composites and official setup actions | ✓ WIRED | Integrity tests mutate compatibility dimensions independently and assert misses. |
| Required-check policy | live branch protection | normalized `.checks` authority with exact `.contexts` mirror | ✓ WIRED | Live target is strict and exactly app-bound to GitHub Actions app 15368. |
| Final source record | after evidence | current-tip equality and exact remote workflow/manifest digests | ✓ WIRED | Independent final-source command passed at SHA `0b59224b…`. |
| Baseline + after JSON | generated comparison | canonical matched-criteria comparison | ✓ WIRED | Both JSON files validate; Markdown explicitly declines unmatched/criteria-mismatched comparisons. |

### Data-Flow Trace (Level 4)

This is an infrastructure phase; no rendered application data is involved. The relevant operational data flows are nevertheless end-to-end:

| Artifact | Data | Source | Produces real data | Status |
| --- | --- | --- | --- | --- |
| Classifier | diff records | validated Git object graph | Yes — closed classification/family outputs | ✓ FLOWING |
| Umbrella | leaf/control results | GitHub `needs` object | Yes — one merge conclusion | ✓ FLOWING |
| Cancellation controller | workflow/run identity | trusted `workflow_run` event + paginated API | Yes — strict-lower cancellation set | ✓ FLOWING |
| Required-check audit | strict/check/app authority | live GitHub branch-protection API | Yes — exact target validation | ✓ FLOWING |
| Evidence monitor | run/job/check observations | GitHub Actions API | Yes — sanitized canonical aggregates | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
| --- | --- | --- | --- |
| Complete recurring contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 script/check_phase165_efficient_ci.sh` | All sections passed; 14 + 26 + 9 ExUnit tests, workflow syntax, policy self-tests, producer and authority checks | ✓ PASS |
| Immutable landed source | `PHASE165_FINAL_REMOTE_DEFAULT_SHA=0b59224b… node scripts/ci_monitor.cjs verify-final-remote-default-source --source …/final-remote-default-source.json` | Exact current remote SHA and both blob digests verified | ✓ PASS |
| Live app-bound authority | `script/check_required_checks_registered.sh --policy script/required_check_policy.json --state target --live` | strict exact target, unique producer | ✓ PASS |
| Action supply-chain immutability | `node scripts/ci_monitor.cjs check-actions` | 100 uses, zero mutable third-party references | ✓ PASS |
| Evidence schemas | `node scripts/ci_monitor.cjs validate-evidence` on baseline and after | Both valid | ✓ PASS |
| Monotonic cancellation | read-only GitHub API/log inspection of runs 34282293939, 34282374655, 34282377278 | lower cancelled, selected lower only, newer terminal success | ✓ PASS |

### Probe Execution

No conventional `scripts/**/tests/probe-*.sh` files are declared. Phase 165's probes are monitor commands and committed live evidence rather than shell probe files. The verifier reran the non-mutating final-source and live-authority probes and independently re-read the historical documentation/full/cancellation runs. No external state was changed.

### Requirements Coverage

| Requirement | Source plans | Status | Evidence |
| --- | --- | --- | --- |
| CIP-01 — Linux for pure/JVM proof; macOS only for Apple tooling | 04, 08 | ✓ SATISFIED | Runner-placement integrity contracts pass; frozen Android/advisory boundaries preserved. |
| CIP-02 — no overlapping push/superseded PR work | 03, 05–13 | ✓ SATISFIED | One PR workflow, no equivalent generic push proof, live strict-lower cancellation, newer terminal success. |
| CIP-03 — complete compatible cache identity | 04 | ✓ SATISFIED | BEAM/Gradle/Swift one-dimension miss tests and official setup contracts pass. |
| CIP-04 — bounded timeouts and monotonic concurrency | 03, 04, 09, 10, 12 | ✓ SATISFIED | Every job bounded; assertion retry rejected; controller behavior proven locally and live. |
| CIP-05 — always-visible focused documentation gate | 01, 02, 05–10, 12 | ✓ SATISFIED | Live docs probe has successful Crosswake CI with one active doc leaf; current classifier tests also cover the complete public-doc focused family after review repair. |
| CIP-06 — reproducible before/after evidence | 01, 09, 13 | ✓ SATISFIED | Canonical JSON/Markdown, exact sources, counts/runners/timing/cache fields, sample medians/ranges, and honest unavailable states validate. |
| CIP-07 — consolidated orchestration without erased proof | 01–03, 05–13 | ✓ SATISFIED | 44 literal leaves remain named/actionable behind one exact umbrella; zero compatibility rows; unique producers and immutable actions pass. |

No Phase 165 requirement is orphaned: all seven roadmap requirements appear in PLAN frontmatter and in the workstream traceability table.

### Prohibition Verification

All 23 PLAN prohibitions were checked through negative fixtures, structural tests, live inspection, or exact artifact inspection. None remains merely judgment-based: malformed/mixed classification, privacy fields, unsupported timing claims, dynamic/opaque proof, cross-authority cancellation, assertion retries, Android expansion, cache-key leakage, release-trust collapse, advisory promotion, hidden required checks, inferred retirement approval, broadened retirement, and proof deletion are all absent or rejected by wired automation.

### Test Quality Audit

| Test surface | Linked requirements | Active | Skipped | Circular | Strongest assertion | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| `phase165_ci_policy_test.exs` | CIP-05, CIP-07 | 14 | 0 | No | Behavioral/value | ✓ SUFFICIENT |
| `phase165_ci_integrity_test.exs` | CIP-01–05, CIP-07 | 26 | 0 | No | Behavioral/value | ✓ SUFFICIENT |
| `phase165_evidence_test.exs` | CIP-02, CIP-06, CIP-07 | 9 | 0 | No | Behavioral/value | ✓ SUFFICIENT |
| Python classifier/selector/manifest/aggregator self-tests | CIP-02, CIP-04, CIP-05, CIP-07 | 23 | 0 | No | Behavioral/value + negative mutations | ✓ SUFFICIENT |
| Live GitHub observations | CIP-02, CIP-04, CIP-05, CIP-07 | 3 probe flows | 0 | No | End-to-end service outcomes | ✓ SUFFICIENT |

**Disabled requirement tests:** 0. **Circular expected-value generation:** 0. **Insufficient assertions:** 0. Fixture writers create isolated inputs and outputs; expected policy values are independently declared and mutation-tested rather than generated by the implementation under test.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| Phase implementation and linked tests | No unreferenced `TBD`, `FIXME`, or `XXX`; no disabled requirement test; no placeholder implementation | — | None |

The `XXXXXX` strings found in required-check scripts are `mktemp` templates, not debt markers.

### Decision Coverage

All 33 trackable `165-CONTEXT.md` decisions are honored by shipped artifacts. The configured decision-coverage verifier returned `honored: 33`, `total: 33`, with no unhonored decision.

### Disconfirmation Pass

- **Potential partial requirement checked:** CIP-06 does not have matched PR timing cohorts. The implementation does not conceal this: both PR cohorts are `not_measured`, the main cohort comparison is `criteria_mismatch`, exact queue time is `not_exposed`, and the report makes no causal improvement claim. This satisfies D-25 through D-30's closed-unavailable contract.
- **Potential misleading test checked:** the historical live cancellation evidence is schema v1 and stores booleans rather than the newer correlation fields. The verifier therefore did not rely on those booleans alone; GitHub API records and controller logs independently confirmed the lower/newer/controller outcomes. Current schema-v2 capture code and negative tests require controller/source/selection correlation and terminal newer authority for future captures.
- **Potential uncovered error path checked:** wrong/missing required-check app IDs, duplicate/mismatched context mirrors, mutable action references, malformed classifier inputs, incomplete cancellation pagination, and missing/extra manifest members all have active fail-closed negatives.

### Human Verification Required

N/A — infrastructure/CI phase with no user-facing product surface. All assertions are automated or were verified by artifact/API inspection. The sole irreversible human trust decision was completed in Plan 165-11 and is durably bound to proposal digest `55bf0c829e1933ac596585979145073beacc9f03a2c0f5bf6e03b3dfb75b3e51`.

### Gaps Summary

No blocking or warning gaps. No deferred Phase 165 gap maps to later phases. Phase 166's clean-checkout quality scope remains separate and was not used to excuse any Phase 165 contract.

---

_Verified: 2026-09-09T03:59:16Z_
_Verifier: the agent (gsd-verifier)_
