---
phase: 162
slug: physical-iphone-adoption-proof
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-04
---

# Phase 162 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. A simulator can exercise regressions but can never promote the physical-iPhone proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix, Playwright, XCTest, and XCUITest |
| **Config file** | `mix.exs`, `package.json`, and generated iOS proof target configuration |
| **Quick run command** | Focused Mix, Playwright, and iOS target tests selected by the task |
| **Full suite command** | Phoenix host browser corpus, Mix suite, package tests, then the signed physical-iPhone XCUITest driver |
| **Estimated runtime** | Under 10 minutes without device setup; physical proof duration is host/device dependent |

---

## Sampling Rate

- **After every task commit:** Run the affected ExUnit, Playwright, or XCTest/XCUITest slice.
- **After every plan wave:** Run the existing fast suite plus the generated proof-lane check.
- **Before `$gsd-verify-work`:** A fresh signed physical-iPhone run must pass every fixed assertion, promotion verification must succeed, and the final retained artifact scan must be clean.
- **Max feedback latency:** 10 minutes, excluding bounded signing/device-connection prerequisites.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirements | Threat Coverage | Secure Behavior | Test Type | Automated Command | Fixture / Generated-Test Dependency | Status |
|---------|------|------|--------------|-----------------|-----------------|-----------|-------------------|-------------------------------------|--------|
| 162-01-01 | 162-01 | 1 | DEVICE-01–07 | T-162-01, T-162-02, T-162-03, T-162-05 | The production command returns one non-echoing `blocked` result and performs no reset, run, staging, or promotion when TODO-002, physical destination, signing, host, media, or backend authority is unavailable. | ExUnit + blocked CLI contract | `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/mix/tasks/crosswake/proof_lane/physical_iphone_test.exs --max-failures 1 && output=$(mix crosswake.proof_lane.physical_iphone --preflight-only --json 2>&1); status=$?; test "$status" -ne 0; jq -e '.outcome == "blocked" and (.rule_id | type == "string") and (keys | sort == ["outcome","rule_id"])' <<<"$output" >/dev/null` | Task creates both ExUnit files and the Mix command before running the command; current external state is expected to exercise the blocked path. | ⬜ pending |
| 162-01-02 | 162-01 | 1 | DEVICE-01–07 | T-162-04, T-162-05 | The fixed physical-only assertion manifest assigns each assertion to exactly one device-local or backend-authority owner and rejects identifying runtime precision. | ExUnit + pure contract probe | `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs --max-failures 1 && mix run -e 'alias Crosswake.ProofLane.PhysicalIphoneContract, as: C; true = C.device_class() == :physical_iphone; true = Enum.all?(C.assertions(), &(&1.owner in [:device_local, :backend_authority]))'` | Depends on `physical_iphone_contract.ex` and its tests created in 162-01-02. | ⬜ pending |
| 162-02-01 | 162-02 | 2 | DEVICE-02–05 | T-162-06, T-162-08, T-162-09 | Generated Phoenix fixtures require real request-bound admission and closed non-sensitive authority observations; malformed callbacks cannot fabricate passes. | ExUnit template contract + Phoenix host proof | `mix test test/crosswake/proof_lane/template_contract_test.exs --max-failures 1 && bash script/verify_phoenix_host_proof_lane.sh` | Uses the generated host test and adapter templates modified by 162-02-01; depends on Plan 162-01 assertion IDs. | ⬜ pending |
| 162-02-02 | 162-02 | 2 | DEVICE-02–05 | T-162-06, T-162-07, T-162-08, T-162-10 | The example host proves current-session admission, one scoped transactional effect, duplicate idempotency, retained reject/conflict, scope fencing, and independent entry/replay gate denial. | Phoenix integration + TypeScript compile | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/physical_iphone_authority_test.exs --max-failures 1 && npx tsc --noEmit) && bash script/verify_phoenix_host_proof_lane.sh` | Task creates `physical_iphone_authority_test.exs`; uses Plan 162-01's closed assertion contract and the existing Phoenix proof script. | ⬜ pending |
| 162-03-01 | 162-03 | 3 | DEVICE-01–05 | T-162-11, T-162-13, T-162-14, T-162-15 | Generated driver contracts preserve one uninterrupted offline-submit/terminate/relaunch/replay lifetime and reject simulator/default-adapter promotion. The reference adapter remains advisory only. | ExUnit template/verifier + advisory simulator regression | `mix test test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs --max-failures 1 && jq -e '.outcome == "passed" and .scope == "pack_audio_prerequisite"' < <(bash script/verify_generated_ios_shell.sh --proof-lane --reference-pack-adapter) >/dev/null` | Task extends existing generated Swift driver, XCTest, and XCUITest templates; advisory output is a regression dependency, never DEVICE proof. | ⬜ pending |
| 162-03-02 | 162-03 | 3 | DEVICE-01–05 | T-162-11, T-162-12, T-162-13, T-162-15 | Runner unit tests require physical selection, owner-disjoint complete reports, stable sanitized failures, and cleanup of invocation-owned raw output. | ExUnit runner/preflight + formatter | `mix test test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs test/crosswake/proof_lane/physical_iphone_preflight_test.exs --max-failures 1 && mix format --check-formatted lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` | Uses injected process/report fixtures in the Plan 162-01 test files; actual device execution remains gated by the external prerequisites below. | ⬜ pending |
| 162-04-01 | 162-04 | 4 | DEVICE-03–05 | T-162-16, T-162-17, T-162-18 | Real IndexedDB/replay behavior maps only to the four locked learner states, retains work, hides sensitive mechanics, and exposes recovery only for a validated destination. | Playwright + ExUnit status contract | `(cd examples/phoenix_host && npm run proof:offline-island -- --grep "study status" && npm run proof:offline-island -- --grep "recovery" && npm run proof:offline-island -- --grep "account switch" && npm run proof:offline-island -- --grep "feature disablement") && mix test test/crosswake/offline/status_test.exs --max-failures 1` | Task adds the browser cases and status test against the existing Phoenix host proof corpus. | ⬜ pending |
| 162-04-02 | 162-04 | 4 | DEVICE-03–05 | T-162-18, T-162-19, T-162-20 | Generated UI contracts cover Accessibility XXXL wrapping/scrolling, 44pt controls, focus, single announcements, Reduce Motion, semantic appearance, and no retained UI artifacts. | ExUnit template contract + Playwright accessibility slice | `mix test test/crosswake/proof_lane/template_contract_test.exs --max-failures 1 && (cd examples/phoenix_host && npm run proof:offline-island -- --grep "accessibility" && npm run proof:offline-island -- --grep "study status")` | Task extends the existing generated XCUITest template; the physical driver consumes these selectors later, while this command checks the generated/browser contract. | ⬜ pending |
| 162-05-01 | 162-05 | 5 | DEVICE-06–07 | T-162-21, T-162-22, T-162-23, T-162-24 | Canonical evidence accepts only a complete physical manifest and approved sanitized hashes, rejects sensitive/noncanonical/simulator candidates, and publishes no-replace. | ExUnit evidence and proof-lane regression | `mix test test/crosswake/proof_lane/evidence_test.exs --max-failures 1 && mix test test/crosswake/proof_lane --exclude physical_device --max-failures 1` | Task extends the existing evidence test file; `--exclude physical_device` deliberately validates deterministic contracts without claiming a device pass. | ⬜ pending |
| 162-05-02 | 162-05 | 5 | DEVICE-06–07 | T-162-21, T-162-22, T-162-23, T-162-24, T-162-25, T-162-26 | Only a fresh complete physical run may publish the fixed redacted artifact and unlock the narrow one-flow/one-runtime support wording and seals. | Signed physical XCUITest + Phoenix + evidence/docs/API seal | `jq -e '.outcome == "passed" and .device_class == "physical_iphone"' < <(mix crosswake.proof_lane.physical_iphone --run --promote --json) >/dev/null && mix run -e 'alias Crosswake.ProofLane.Evidence; :ok = Evidence.check(".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone")' && mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/proof_lane/evidence_test.exs --max-failures 1 && mix crosswake.support_matrix.gen --check && test "$(tr -d '\r\n' < .planning/phases/162-physical-iphone-adoption-proof/COVERAGE.md)" = "No external API integration: Phase 162 composes existing first-party Phoenix, Ecto, Playwright, XCTest, XCUITest, and host-owned proof seams only; it adds no external API, SDK, or service." && grep -Eq '"passed": true' < <(node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs check api-coverage.verify-pre .planning/phases/162-physical-iphone-adoption-proof)` | Non-passing blocked prerequisite until TODO-002 has an eligible sanitized row, the generated lane is current, a runnable signed host/backend and required fixture/media/authority controls exist, and one selected physical iPhone is connected. No simulator, unit test, or advisory run substitutes. | ⬜ blocked on external prerequisites |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Resolution and External-Prerequisite Gate

No separate Wave 0 scaffold is missing. Each behavior-producing task is TDD-scoped and creates or
extends its named test/fixture before production behavior; the table above records the exact
generated dependency and runnable command for all ten tasks.

The physical command in 162-05-02 is intentionally **not passing and not substitutable** in the
current environment. It must remain blocked until all of the following are simultaneously true:

- TODO-002 contains an eligible validated sanitized route row;
- the generated proof lane is current;
- a runnable signed adopter host/backend provides the required fixture, pack/media, replay,
  rejection/conflict, scoped-session, and entry/replay feature-gate controls; and
- one physical iPhone is connected and selected without retaining its identifier.

Plan 162-01's blocked preflight is the required executable result while any prerequisite is absent.
Simulator, advisory reference-adapter, injected unit, browser, and contract-test results preserve
feedback continuity but cannot promote DEVICE-01–07 or mark 162-05-02 green.

---

## Manual-Only Verifications

All behavior evaluation is automated. A human may only perform unavoidable physical-device connection, signing, or external host-credential setup; the generated driver and verifier determine outcomes.

---

## Validation Sign-Off

- [x] All ten actual tasks have a concrete `<automated>` command and an explicit fixture/generated-test dependency.
- [x] Sampling continuity: every task has an automated verification command.
- [x] DEVICE-01–07 and T-162-01–T-162-26 are mapped to their owning tasks.
- [x] No watch-mode flags.
- [x] Feedback latency is bounded by the generated driver and explicitly excludes prerequisite setup time.
- [x] `nyquist_compliant: true` is set without treating blocked physical execution as passing evidence.

**Approval:** executable map ready; physical run and promotion remain blocked on the listed external prerequisites.
