---
phase: "182"
slug: "loopback-origin-for-local-ios-host"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-14"
---

# Phase 182 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `182-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 27) for LOOP-01..04; bash harness for the Simulator check; `jq`/`git`/`shasum` assertions for LOOP-05 |
| **Config file** | `mix.exs`, `test/test_helper.exs` (in `/private/tmp/crosswake-phase182-impl`) |
| **Quick run command** | `cd /private/tmp/crosswake-phase182-impl && L=$(mktemp) && MIX_ENV=test mix test <touched test files> --seed 0 >"$L" 2>&1 && grep -Eq '(^|[^0-9])[1-9][0-9]* tests?, 0 failures' "$L"` |
| **Full suite command** | `cd /private/tmp/crosswake-phase182-impl && L=$(mktemp) && MIX_ENV=test mix test --seed 0 >"$L" 2>&1 && grep -Eq '(^|[^0-9])[1-9][0-9]* tests?, 0 failures' "$L"` plus `bash script/verify_loopback_origin_simulator.sh` (phase evidence, not CI) |
| **Estimated runtime** | quick ~10–20 s; full suite several minutes; harness ~1–3 min warm |

Never pipe a gate into `tail`; capture to a file, test `$?`, then grep.

---

## Sampling Rate

- **After every task commit:** the matching quick subset (single test file where possible)
- **After every plan wave:** the quick run over all Phase 182 test files
- **Before `/gsd-verify-work`:** full suite green, Simulator harness `passed`, production-plist golden byte-identical, overlap check empty
- **Max feedback latency:** 30 seconds for quick runs

---

## Per-Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists |
|-------------|----------|-----------|-------------------|-------------|
| LOOP-01 | no mode + `http` denied; unknown mode denied; `https` under mode denied; mode under prod denied; absent Mix → prod; struct literal without `origin_mode` still builds | unit | `MIX_ENV=test mix test test/crosswake/shell/ios_host_config_test.exs --seed 0` | extend |
| LOOP-02 | loopback allowlist accept/deny table (IPv6, 0.0.0.0, 127.x, LAN, .local, userinfo, suffix tricks, trailing dot, bad ports, path/query/fragment, newline); no echo; no rewrite | unit (table) | same file | extend |
| LOOP-03 | production Info.plist == golden; local ATS key set == `[NSAllowsLocalNetworking]` + marker; forbidden keys absent; reconcile round trip; host-edited ATS refused; `--check` drift + mode line | unit + task | `MIX_ENV=test mix test test/crosswake/shell/ios_host_origin_mode_test.exs test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs --seed 0` | ❌ W0 |
| LOOP-03 | Simulator WKWebView loads test-owned `http://127.0.0.1:<port>` page; `http://example.com/` still -1022; no Simulator → `blocked` | harness | `bash script/verify_loopback_origin_simulator.sh` → JSON `passed` | ❌ W0 |
| LOOP-04 | doctor warning / `--check-publish` error / mismatch error / leak guard; proof lane refusal; inspect line; renderer + guide drift | unit + task + docs drift | quick run over doctor, proof-lane, inspect, renderer, guide tests | ❌ W0 / extend |
| LOOP-05 | `182-CANDIDATE-MOVE.json` schema, overlap `[]`, heads/trees equal, carried path digests and modes unchanged, binary diff digest unchanged, pins unchanged, `gate_rerun_required: true` | script | `jq -e` over the JSON plus `git rev-parse` / `status --porcelain` / `shasum` comparisons | ❌ W0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/fixtures/shell/ios/Info.plist.production.golden` — captured from base `12f84cd` BEFORE editing the template
- [ ] `test/crosswake/shell/ios_host_origin_mode_test.exs` — block, inspect, reconcile, forbidden keys
- [ ] `test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs` — generation, `--check`, toggle round trip, README banner, host-edit refusal
- [ ] `test/crosswake/doctor/doctor_origin_mode_test.exs` — findings, paired control, publish, leak guard
- [ ] `script/verify_loopback_origin_simulator.sh` (+ listener) — D-17.7 harness with `passed|blocked|unavailable` JSON
- [ ] candidate-move verification commands (phase evidence, not CI)
- Framework install: none

---

## Manual-Only Verifications

All phase behaviors have automated verification. A missing Simulator/toolchain makes the harness result `blocked`, never `passed`.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
