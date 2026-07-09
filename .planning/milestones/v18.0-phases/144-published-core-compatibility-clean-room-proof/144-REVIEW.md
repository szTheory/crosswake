---
phase: 144-published-core-compatibility-clean-room-proof
reviewed: 2026-07-08T13:58:46Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - script/verify_companion_cleanroom.sh
  - script/check_release_workflow_integrity.exs
  - test/crosswake/proof/phase142_release_integrity_test.exs
  - lib/mix/tasks/crosswake.doctor.ex
  - test/mix/tasks/crosswake_doctor_router_test.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 144: Code Review Report

**Reviewed:** 2026-07-08T13:58:46Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Reviewed the Phase 144 clean-room proof script, release-integrity scanner, doctor Mix task router-loading path, and associated ExUnit proof tests. The main release scanner and doctor-router behavior are directionally sound, but two robustness gaps remain: one test can pass while the happy-path doctor command exits non-zero, and one documented script override path interpolates unvalidated arguments into generated code.

Verification run during review:

- `elixir script/check_release_workflow_integrity.exs` - passed
- `mix test test/mix/tasks/crosswake_doctor_router_test.exs` - passed

## Narrative Findings (AI reviewer)

### Warnings

#### WR-01: Fresh-router happy path does not assert command success

**File:** `test/mix/tasks/crosswake_doctor_router_test.exs:37`

**Issue:** The fresh-router test discards `_exit_code` and only checks that the output includes `"Crosswake doctor report"` and omits the router-unavailable message. `mix crosswake.doctor` renders the report before raising when `report.status == :error`, so a regression that loads the router but exits non-zero for a new blocking doctor finding would still pass this test. That weakens PREF-02's proof that a freshly compiled clean-room router is accepted successfully.

**Fix:**

```elixir
{output, exit_code} =
  run_mix(target, ["crosswake.doctor", "--router", "CleanRoomHost.Router"])

assert exit_code == 0, output
assert output =~ "Crosswake doctor report"
refute output =~ "router module CleanRoomHost.Router"
```

#### WR-02: Engine override arguments are interpolated without validation

**File:** `script/verify_companion_cleanroom.sh:138`

**Issue:** `ENGINE_PACKAGE` and `ENGINE_MODULE` are documented positional overrides, but unlike `PACKAGE` and `VERSION`, they are not validated before being interpolated into generated `mix.exs` and smoke-test Elixir code. The current workflow passes fixed values, so this is not exposed through Release Please outputs, but the script's manual/recovery interface can be made to generate malformed or attacker-controlled clean-room code.

**Fix:** Restrict overrides to known engine pairs or validate both tokens before assigning them:

```bash
if [ "$_RAW_ENGINE_PKG" != "__crosswake_default__" ] &&
   [ -n "$_RAW_ENGINE_PKG" ] &&
   [ "$_RAW_ENGINE_PKG" != "none" ]; then
  case "${_RAW_ENGINE_PKG}:${_RAW_ENGINE_MOD:-}" in
    rulestead:Rulestead|rindle:Rindle) ;;
    *) fail "unsupported engine override '${_RAW_ENGINE_PKG}:${_RAW_ENGINE_MOD:-}'." \
      "Use the built-in package profile, 'none', or an allowlisted engine/module pair." ;;
  esac
fi
```

---

_Reviewed: 2026-07-08T13:58:46Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
