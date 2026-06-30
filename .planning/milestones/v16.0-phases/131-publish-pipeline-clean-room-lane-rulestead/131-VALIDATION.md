---
phase: 131
slug: publish-pipeline-clean-room-lane-rulestead
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-26
validated: 2026-06-26
---

# Phase 131 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + shellcheck/bash for `script/verify_*.sh` + CI workflow validation |
| **Config file** | `packages/crosswake_rulestead/mix.exs` (companion test config); root `mix.exs` (core) |
| **Quick run command** | `cd packages/crosswake_rulestead && mix test` |
| **Full suite command** | `mix test` (core) + `bash script/verify_companion_package.sh crosswake_rulestead` |
| **Estimated runtime** | ~30–90 seconds (in-tree); clean-room + publish lanes run in CI only |

---

## Sampling Rate

- **After every task commit:** Run `{quick run command}`
- **After every plan wave:** Run `{full suite command}`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

> Planner fills this from RESEARCH.md `## Validation Architecture`. Note the
> irreversible-publish steps (`hex.publish`, post-publish clean-room) that can only
> be validated at publish time — mark these as Manual-Only / CI-only below.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 131-01-01 | 01 | 1 | EXTRACT-05 | T-131-05 | resolver emits Hex dep only under CROSSWAKE_RELEASE=1 | source | `cd packages/crosswake_rulestead && mix compile --warnings-as-errors && grep -q 'defp crosswake_dep' mix.exs` | ✅ | ✅ green |
| 131-01-02 | 01 | 1 | EXTRACT-05 | T-131-02/03 | companion NOT in linked-versions; outputs expose only public release metadata | config | `python3` assert config+manifest+aliases (see plan verify) | ✅ | ✅ green |
| 131-01-03 | 01 | 1 | EXTRACT-05 | T-131-01 | tarball dep-presence grep on hex_metadata.config | script | `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rulestead` | ✅ | ✅ green |
| 131-02-01 | 02 | 2 | EXTRACT-06 | T-131-04/05/06 | gate on rulestead_release_created; HEX_API_KEY no-echo; CROSSWAKE_RELEASE=1 | config (CI) | `python3+yaml` assert publish-hex-rulestead (see plan verify) | ✅ | ✅ green |
| 131-02-02 | 02 | 2 | PROOF-01 | T-131-07 | $VERSION semver-validated before curl; public-seam smoke only | script | `bash -n script/verify_companion_cleanroom.sh` + grep gates **(full run Manual-Only / CI-only — post-publish)** | ✅ | ✅ green |
| 131-03-01 | 03 | 3 | PROOF-02 | T-131-08 | needs:[release-please, publish-hex-rulestead] enforces post-publish ordering | config (CI) | `python3+yaml` assert clean-room-proof-rulestead needs graph | ✅ | ✅ green |
| 131-03-02 | 03 | 3 | PROOF-02 | T-131-09 | release-as left intact pre-cut; removal runbook documented | doc | `test -f 131-RELEASE-AS-REMOVAL.md` + release-as-intact assert | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing ExUnit infrastructure covers companion adapter behavior (`packages/crosswake_rulestead/test/` — 11 tests, 0 failures)
- [x] `script/verify_companion_package.sh` already present (Step 2 activated this phase; full run green Steps 1/2/3)
- [x] `script/verify_companion_cleanroom.sh` — NEW, locally syntax-checkable (`bash -n` green); full run is CI-only post-publish

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `crosswake_rulestead` live + resolvable on Hex | EXTRACT-06 / PROOF-02 | Irreversible publish — cannot be dry-run-validated in-tree | Merge companion Release PR; observe publish job green; `mix hex.info crosswake_rulestead` |
| Post-publish clean-room resolves published artifact | PROOF-02 | Requires the real Hex registry post-publish (propagation race) | CI `clean-room-proof-rulestead` job green |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none MISSING)
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-26 — all 7 task rows green locally; 2 irreversible publish/clean-room behaviors are Manual-Only / CI-only post-publish.

---

## Validation Audit 2026-06-26

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 7 per-task automated commands were executed locally and pass:
- `mix compile --warnings-as-errors` + `defp crosswake_dep` grep (131-01-01)
- release-please config/manifest/alias + not-in-linked-versions asserts (131-01-02)
- `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rulestead` — Steps 1/2/3 OK (131-01-03)
- `publish-hex-rulestead` job YAML asserts: gate, env, dry-run<publish, poll URL (131-02-01)
- `bash -n script/verify_companion_cleanroom.sh` + doctor/semver gate greps (131-02-02)
- `clean-room-proof-rulestead` needs-graph + thin-YAML asserts (131-03-01)
- runbook exists + `release-as` intact pre-cut assert (131-03-02)

Companion ExUnit suite: 11 tests, 0 failures. No tests generated — coverage was already complete via verification commands plus the existing ExUnit suite. The only behaviors without local automated proof (live Hex publish + post-publish clean-room resolve) are irreversible and remain Manual-Only / CI-only by design.
