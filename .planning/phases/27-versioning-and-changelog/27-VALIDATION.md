---
phase: 27
slug: versioning-and-changelog
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual verification (Automated tests deferred to v3.4) |
| **Config file** | N/A |
| **Quick run command** | N/A |
| **Full suite command** | N/A |
| **Estimated runtime** | ~1 minute (Manual inspection) |

---

## Sampling Rate

- **After every task commit:** Verify modified files manually
- **Before `/gsd:verify-work`:** Ensure `CHANGELOG.md` strictly adheres to Keep-a-Changelog format and `mix.exs` is correctly configured.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| T-27-01 | 01 | 1 | LOG-01, LOG-02, LOG-03, LOG-04 | T-27-01 | CHANGELOG.md uses Keep-a-Changelog format, details capabilities in 0.1.0, and disambiguates planning milestones. | manual | `cat CHANGELOG.md | grep -q "## \[Unreleased\]" && cat CHANGELOG.md | grep -q "## \[0.1.0\]"` | ✅ Wave 0 | ⬜ pending |
| T-27-02 | 01 | 1 | VER-01 | — | mix.exs includes CHANGELOG.md in the docs extras list and compiles successfully. | manual | `grep -A 20 "defp docs do" mix.exs | grep -q "CHANGELOG.md" && mix compile` | ✅ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Create this VALIDATION.md file

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CHANGELOG.md structure verification | LOG-01, LOG-02, LOG-03, LOG-04 | Automated tests for pipeline parsing deferred to v3.4 | Open `CHANGELOG.md`. Confirm it has the `## Planning milestones vs Hex releases` preamble, an `## [Unreleased]` heading, and a `## [0.1.0]` heading with the exact capability bullets specified in 27-01-PLAN.md. Confirm it has link anchors at the bottom. |
| mix.exs HexDocs verification | VER-01 | Rendering docs locally is a manual step (automated checks are basic grep/compile) | Open `mix.exs`. Verify `@version` is `"0.1.0"`. Check that `"CHANGELOG.md"` is in the `extras` list inside `defp docs`. Run `mix docs` locally (if ex_doc is installed) to verify the changelog is included, or rely on `mix compile`. |

---

## Validation Sign-Off

- [x] All tasks have verification steps
- [x] Manual steps clearly documented (automated tests deferred to v3.4)
- [x] Feedback latency is acceptable for manual checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
