---
phase: 111
slug: generator-rewire-clean-room-proof-release
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-14
---

# Phase 111 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `111-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir stdlib) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Doctor gate** | `mix crosswake.doctor --check-publish` |
| **Estimated runtime** | ~15 seconds (unit) / ~30 min (clean-room CI, post-release only) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/crosswake_gen_shell_test.exs`
- **After every plan wave:** Run `mix test --exclude requires_example_host && mix crosswake.doctor --check-publish`
- **Before `/gsd:verify-work`:** Full suite green + `--check-publish` green + Hex 0.1.2 verified on hex.pm; clean-room CI jobs green
- **Max feedback latency:** ~30 seconds (unit + doctor). Clean-room CI (PROOF-01) is release-time-only — not a per-commit signal.

---

## Per-Task Verification Map

> Populated during planning once task IDs exist. Requirement→signal mapping is locked below (from RESEARCH § Validation Architecture).

| Req ID | Behavior | Test Type | Automated Command | File Exists | Status |
|--------|----------|-----------|-------------------|-------------|--------|
| GEN-01 | Generated coordinates carry `Application.spec(:crosswake)[:vsn]` — no literal version | unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ add assertions | ⬜ pending |
| GEN-01 | Nil-guard raises a helpful error when version is nil | unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ add test case | ⬜ pending |
| GEN-02 | iOS non-local: `szTheory` org, `upToNextMajorVersion`/`from:`, `@version` | unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ add assertions | ⬜ pending |
| GEN-02 | Android non-local: `io.github.sztheory:crosswake-shell-core-android:@version` | unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ add assertions | ⬜ pending |
| GEN-02 | `--local` branch still emits local refs (regression guard) | unit | `mix test test/mix/tasks/crosswake_gen_shell_test.exs` | ✅ existing | ⬜ pending |
| PROOF-01 | `swift build` exits 0 on macOS runner with published dep | CI (post-release) | `clean-room-proof-ios` job | ❌ W0 (new job) | ⬜ pending |
| PROOF-01 | `gradle build` exits 0 on ubuntu runner with published dep | CI (post-release) | `clean-room-proof-android` job | ❌ W0 (new job) | ⬜ pending |
| PROOF-02 | `--check-publish` fails on wrong iOS org / local leak | unit + doctor | `mix crosswake.doctor --check-publish` | ❌ W0 (new ReadinessCheck) | ⬜ pending |
| PROOF-02 | `--check-publish` fails on wrong Android GAV / local leak | unit + doctor | `mix crosswake.doctor --check-publish` | ❌ W0 (new ReadinessCheck) | ⬜ pending |
| PROOF-02 | `--check-publish` passes when coordinates are correct | unit + doctor | `mix crosswake.doctor --check-publish` | ❌ W0 (new ReadinessCheck) | ⬜ pending |
| DOCS-01 | `guides/adoption.md` in `@allowed_docs`; parity check passes | doctor | `mix crosswake.doctor --check-publish` | ✅ whitelist add | ⬜ pending |
| DOCS-01 | `CHANGELOG.md` has `## [0.1.2]`; no false-shipped-claims | doctor | `mix crosswake.doctor --check-publish` | ✅ edit | ⬜ pending |
| REL-01 | Hex 0.1.2 published | CI (release) | `publish-hex` job Hex.pm poll | ✅ existing | ⬜ pending |
| REL-01 | iOS mirror tag + Android Maven artifact at 0.1.2 | CI (release) | `publish-ios-core` / `publish-android-core` jobs | ✅ existing (Phase 110) | ⬜ pending |
| REL-01 | `release-as` pin removed post-cut | manual | `grep "release-as" release-please-config.json` returns no match | ✅ file edit | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `clean-room-proof-ios` job — covers PROOF-01 (iOS); release-time-only
- [ ] `clean-room-proof-android` job — covers PROOF-01 (Android); release-time-only
- [ ] `generator_coordinate_parity_check/1` in `lib/crosswake/doctor/publish_readiness.ex` — covers PROOF-02
- [ ] New coordinate assertions + nil-guard test case in `crosswake_gen_shell_test.exs` — covers GEN-01/GEN-02

*Existing test infrastructure in `crosswake_gen_shell_test.exs` already renders the generator into a tmp dir — assertions slot in; no new test file required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Clean-room lane green at the real 0.1.2 cut | PROOF-01 | Requires live published artifacts that only exist after the coordinated release fires | Trigger the 0.1.2 release; confirm `clean-room-proof-ios` + `clean-room-proof-android` jobs exit 0 |
| Hex 0.1.2 + iOS tag + Maven artifact all live at 0.1.2 | REL-01 | Cross-registry propagation observable only post-publish | Verify hex.pm, the mirror tag, and Maven Central all show 0.1.2 |
| `release-as` pin removed after cut | REL-01 | Sequenced after the cut completes (D-04) | Confirm the `chore:` removal commit landed and `release-as` is absent |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (unit + doctor)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
