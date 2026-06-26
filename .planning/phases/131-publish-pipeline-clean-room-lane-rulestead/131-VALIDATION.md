---
phase: 131
slug: publish-pipeline-clean-room-lane-rulestead
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-26
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
| 131-01-01 | 01 | 1 | EXTRACT-05 | T-131-05 | resolver emits Hex dep only under CROSSWAKE_RELEASE=1 | source | `cd packages/crosswake_rulestead && mix compile --warnings-as-errors && grep -q 'defp crosswake_dep' mix.exs` | ✅ | ⬜ pending |
| 131-01-02 | 01 | 1 | EXTRACT-05 | T-131-02/03 | companion NOT in linked-versions; outputs expose only public release metadata | config | `python3` assert config+manifest+aliases (see plan verify) | ✅ | ⬜ pending |
| 131-01-03 | 01 | 1 | EXTRACT-05 | T-131-01 | tarball dep-presence grep on hex_metadata.config | script | `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rulestead` | ✅ | ⬜ pending |
| 131-02-01 | 02 | 2 | EXTRACT-06 | T-131-04/05/06 | gate on rulestead_release_created; HEX_API_KEY no-echo; CROSSWAKE_RELEASE=1 | config (CI) | `python3+yaml` assert publish-hex-rulestead (see plan verify) | ✅ | ⬜ pending |
| 131-02-02 | 02 | 2 | PROOF-01 | T-131-07 | $VERSION semver-validated before curl; public-seam smoke only | script | `bash -n script/verify_companion_cleanroom.sh` + grep gates **(full run Manual-Only / CI-only — post-publish)** | ✅ | ⬜ pending |
| 131-03-01 | 03 | 3 | PROOF-02 | T-131-08 | needs:[release-please, publish-hex-rulestead] enforces post-publish ordering | config (CI) | `python3+yaml` assert clean-room-proof-rulestead needs graph | ✅ | ⬜ pending |
| 131-03-02 | 03 | 3 | PROOF-02 | T-131-09 | release-as left intact pre-cut; removal runbook documented | doc | `test -f 131-RELEASE-AS-REMOVAL.md` + release-as-intact assert | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Existing ExUnit infrastructure covers companion adapter behavior (`packages/crosswake_rulestead/test/`)
- [ ] `script/verify_companion_package.sh` already present (Step 2 activates this phase)
- [ ] `script/verify_companion_cleanroom.sh` — NEW, locally runnable proof lane

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
