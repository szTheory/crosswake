---
phase: 143
slug: guarded-auto-publish-train
status: ready_for_execution
nyquist_compliant: true
wave_0_complete: true
wave_0_basis: embedded_in_execution_tasks
created: 2026-07-07
revised: 2026-07-07
---

# Phase 143 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

Wave 0 validation requirements are complete as a planning contract: every planned task now includes automated verification or creates the proof surface that later tasks consume. This does not claim the source changes already exist before execution; it means execution begins with concrete verification gates embedded in the task set.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| **Full suite command** | `mix verify` |
| **Estimated runtime** | ~60-180 seconds for focused proof; full verify depends on native/proof lanes |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` verification plus `elixir script/check_release_workflow_integrity.exs` when scanner-covered workflow semantics are touched.
- **After every plan wave:** Run `mix test test/crosswake/proof/phase142_release_integrity_test.exs` once Plan 03 has landed the Phase 143 proof IDs.
- **Before `/gsd:verify-work`:** Run `mix verify` and the focused release integrity proof.
- **Max feedback latency:** 180 seconds for the focused release proof.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 143-01-01 | 01 | 1 | AUTO-01, AUTO-03 | T-143-01, T-143-02, T-143-03, T-143-05, T-143-06 | Guarded helper verifies package map, package version identity, parsed Hex JSON, exact already-live state, no routine replacement, stable output keys, and fail-closed states before irreversible publish. | shell syntax + semantic text assertions + live registry probe recording | `bash -lc 'bash -n script/guarded_hex_publish.sh && test -x script/guarded_hex_publish.sh && grep -q "package_config" script/guarded_hex_publish.sh && for p in crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline; do grep -q "$p" script/guarded_hex_publish.sh; done && grep -Eq "python3?|python" script/guarded_hex_publish.sh && grep -Eq "import json|json\\.(load|loads)" script/guarded_hex_publish.sh && grep -q "\\[crosswake\\] OK" script/guarded_hex_publish.sh && grep -q "\\[crosswake\\] FAIL" script/guarded_hex_publish.sh && grep -q "GITHUB_OUTPUT" script/guarded_hex_publish.sh && for k in package version publish_state hex_release_url checked_sha; do grep -q "$k" script/guarded_hex_publish.sh; done && test "$(grep -v "^#" script/guarded_hex_publish.sh | grep -c -- "--replace" || true)" -eq 0'` plus Plan 01's `crosswake_rulestead`/`crosswake_rindle` HTTP-code probes | Planned new file | planned |
| 143-01-02 | 01 | 1 | AUTO-01, AUTO-03 | T-143-04 | Automatic Release Please Hex jobs call the helper for exactly six Hex packages while Phase 142 gates, proof dependencies, and non-canceling concurrency remain intact. | workflow semantic scanner | `bash -lc 'test "$(grep -v "^ *#" .github/workflows/release-please.yml | grep -c "script/guarded_hex_publish.sh")" -eq 6 && test "$(grep -v "^ *#" .github/workflows/release-please.yml | grep -c "mix hex.publish --yes" || true)" -eq 0 && elixir script/check_release_workflow_integrity.exs'` | Existing workflow | planned |
| 143-02-01 | 02 | 2 | AUTO-03 | T-143-07, T-143-08, T-143-11 | Manual recovery exposes package/ref/release_version inputs, rejects branch-shaped refs before checkout, and stays least-privilege. | workflow text assertions | `bash -lc 'test "$(grep -c "package:" .github/workflows/hex-publish.yml)" -ge 1 && test "$(grep -c "ref:" .github/workflows/hex-publish.yml)" -ge 1 && test "$(grep -c "release_version:" .github/workflows/hex-publish.yml)" -ge 1 && test "$(grep -c "inputs.tag" .github/workflows/hex-publish.yml || true)" -eq 0 && test "$(grep -c "contents: write" .github/workflows/hex-publish.yml || true)" -eq 0'` | Existing workflow | planned |
| 143-02-02 | 02 | 2 | AUTO-03 | T-143-09, T-143-10, T-143-12 | Manual recovery checks out an exact ref, prints the SHA, invokes the shared helper once, avoids direct Hex publish and routine replacement, and does not add concrete native recovery commands. | workflow command-line assertions | `bash -lc 'test "$(grep -v "^ *#" .github/workflows/hex-publish.yml | grep -c "script/guarded_hex_publish.sh")" -eq 1 && grep -q "git rev-parse HEAD" .github/workflows/hex-publish.yml && test "$(grep -v "^ *#" .github/workflows/hex-publish.yml | grep -c "mix hex.publish --yes" || true)" -eq 0 && test "$(grep -v "^ *#" .github/workflows/hex-publish.yml | grep -c -- "--replace" || true)" -eq 0 && cmd_text=$(awk '\''/^[[:space:]]*#/ {next} /^[[:space:]]*run:[[:space:]]*/ {in_run=1; print; next} in_run && /^[[:space:]]*[A-Za-z0-9_-]+:/ {in_run=0} in_run {print}'\'' .github/workflows/hex-publish.yml) && for forbidden in publishToMavenCentral splitsh-lite MIRROR_PUSH_TOKEN ORG_GRADLE_PROJECT_ "swift build" "./gradlew"; do if printf "%s\n" "$cmd_text" | grep -Fq "$forbidden"; then echo "[crosswake] FAIL: forbidden native recovery command in hex-publish.yml: $forbidden"; exit 1; fi; done'` | Existing workflow | planned |
| 143-03-01 | 03 | 3 | AUTO-01, AUTO-02, AUTO-03 | T-143-13, T-143-14, T-143-15, T-143-16, T-143-18, T-143-19 | Scanner has stable Phase 143 IDs for guarded auto publish, exact-ref recovery, package map completeness, no routine overwrite, proof continuation, lockstep core/native, independent companions, and honest floors. | semantic scanner | `elixir script/check_release_workflow_integrity.exs` | Existing scanner | planned |
| 143-03-02 | 03 | 3 | AUTO-01, AUTO-02, AUTO-03 | T-143-13, T-143-14, T-143-15, T-143-16, T-143-18, T-143-19 | ExUnit positive and negative fixtures prove the scanner catches direct publish, root-only recovery, mutable refs, missing package map, routine overwrite syntax, aggregate behavioral gates, and floor flattening. | ExUnit proof | `mix test test/crosswake/proof/phase142_release_integrity_test.exs` | Existing test file | planned |
| 143-03-03 | 03 | 3 | AUTO-01, AUTO-02, AUTO-03 | T-143-17, T-143-19 | Docs name the automatic publish boundary, exact-ref recovery, already-live OK/FAIL states, required-check boundary, mixed companion floors, and explicit Phase 144/145/146 boundaries. | docs contract grep | `bash -lc 'grep -q "Release Please Release PR merge" docs/COMPANION-PUBLISH-RUNBOOK.md && grep -q "manual recovery" docs/COMPANION-PUBLISH-RUNBOOK.md && grep -q "\\[crosswake\\] OK" docs/COMPANION-PUBLISH-RUNBOOK.md && grep -q "\\[crosswake\\] FAIL" docs/COMPANION-PUBLISH-RUNBOOK.md && grep -q "MUST NOT" docs/COMPANION-PUBLISH-RUNBOOK.md && combined=$(cat docs/COMPANION-PUBLISH-RUNBOOK.md guides/companion_compatibility.md) && for pair in "crosswake_rulestead:~> 0.1" "crosswake_rindle:~> 0.1" "crosswake_sigra:~> 0.2" "crosswake_chimeway:~> 0.2" "crosswake_threadline:~> 0.2"; do pkg=${pair%%:*}; floor=${pair#*:}; printf "%s\n" "$combined" | grep -Eq "${pkg}.*${floor}|${floor}.*${pkg}"; done && for phase in "Phase 144" "Phase 145" "Phase 146"; do printf "%s\n" "$combined" | grep -q "$phase"; done'` | Existing docs | planned |

---

## Wave 0 Requirements

- [x] Stable Phase 143 scanner IDs are planned in 143-03 Task 1 and verified by `elixir script/check_release_workflow_integrity.exs`.
- [x] Positive and negative Phase 143 fixtures are planned in 143-03 Task 2 and verified by `mix test test/crosswake/proof/phase142_release_integrity_test.exs`.
- [x] `crosswake_rulestead` and `crosswake_rindle` registry-state ambiguity is handled by 143-01 Task 1: re-probe, record HTTP codes, treat 404 as publish-required only when Release Please emits that package after version/ref validation, and fail closed if identity cannot be proven.
- [x] All seven planned tasks have task-level `<automated>` verification.

---

## Manual-Only Verifications

None required for planning compliance. Live Hex probes for `crosswake_rulestead` and `crosswake_rindle` are execution-time evidence recording in 143-01 Task 1, not a maintainer decision gate.

---

## Validation Sign-Off

- [x] All seven planned tasks have `<automated>` verify commands.
- [x] Sampling continuity: no three consecutive tasks lack automated verify.
- [x] Wave 0 validation requirements are embedded in execution tasks.
- [x] No watch-mode flags.
- [x] Feedback latency target is < 180s for focused release proof.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** ready for execution
