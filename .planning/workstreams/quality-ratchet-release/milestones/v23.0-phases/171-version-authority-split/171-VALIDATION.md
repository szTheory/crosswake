---
phase: "171"
slug: "version-authority-split"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-17"
---

# Phase 171 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `171-RESEARCH.md` § "Validation Architecture".

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in), `mix test` |
| **Config file** | `mix.exs` (`elixirc_paths`, deps) — no separate ExUnit config file |
| **Quick run command** | `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs --max-cases 1` |
| **Full suite command** | `mix test --exclude requires_example_host` plus `elixir script/check_release_workflow_integrity.exs` |
| **Estimated runtime** | quick ~30s; full suite ~6-10 min |

The quick command mirrors the `release-candidate-fixtures` CI job's own invocation
(`.github/workflows/crosswake-ci.yml:151-156`), so a green local quick run means the same thing the
merge-blocking lane means.

---

## Sampling Rate

- **After every task commit:** `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs --max-cases 1`
- **After every plan wave:** `mix test --exclude requires_example_host` **and** `elixir script/check_release_workflow_integrity.exs`
- **Before `/gsd-verify-work`:** both green, PLUS the WELD-01 inventory table read to confirm zero
  remaining "live gate" rows carrying a bare version literal
- **Max feedback latency:** ~30 seconds (quick), ~10 minutes (wave)

**Note on the scanner's dual role.** `script/check_release_workflow_integrity.exs` is simultaneously a
*build artifact of this phase* (MSG-04 adds a check to it) and a *verification tool for this phase*
(WELD-03's fix must keep it green). Running it after every wave is therefore not optional belt-and-braces
— it is the only place the self-referential hazard in Pitfall 1 becomes visible.

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| WELD-01 | Weld inventory committed in-repo; all 18 files classified; zero "live gate" rows with a bare literal | structural (grep + table read) | `grep -rl '0\.2\.1' lib/ script/ .github/workflows/` cross-checked against the committed table | ❌ W0 (new doc artifact) |
| MSG-04 | New check fails on a bare version literal in a publish-gating `if:` | unit (scanner subprocess) | `mix test test/crosswake/proof/phase171_no_bare_version_literal_test.exs` | ❌ W0 |
| MSG-05 | Same check fails against a pre-repair fixture of the workflow file (non-vacuity proof) | unit (fixture mutation) | same file, dedicated case | ❌ W0 |
| WELD-02 | `approved-release-guard` emits `approved_version` alongside head/tree/base | integration (workflow-YAML structural assertion) | `mix test test/crosswake/proof/phase171_approved_version_output_test.exs` | ❌ W0 |
| WELD-03 | Zero bare-literal matches across the 4 publish-gating `if:` clauses | unit | covered by MSG-04's test re-run against the real, fixed `release-please.yml` | covered by MSG-04 |
| WELD-04 | `Crosswake.ReleaseCandidate.Workflow` derivation is version-parametric — two versions in, two results out | unit | `mix test test/crosswake/release_candidate/workflow_test.exs` | ✅ exists, new case |
| WELD-05 | `cleanroom.ex`'s `== "0.2.1"` conjunct no longer exists in source | unit + source assertion | `mix test test/crosswake/release_candidate/cleanroom_test.exs` | ✅ exists, new case |
| WELD-06 | A non-0.2.1 version runs the CLI entrypoint without error | unit | `mix test test/mix/tasks/crosswake_release_candidate_test.exs` | ✅ exists, new case |
| WELD-07 | Tripwire `release.version_weld.gates_match_declared_version` fully removed from roster and file | unit (negative/absence) | assertion in `phase171_no_bare_version_literal_test.exs` | ❌ W0 |
| WELD-08 | Identity gate (head/tree/base) stays exact after the version comparison generalizes | unit (fixture mutation) | `mix test test/crosswake/proof/phase171_identity_gate_unchanged_test.exs` | ❌ W0 |
| DOC-05 | New/changed copy qualifies "manifest" | review | N/A — phase-close reviewer reads the diff | N/A |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky — all rows ⬜ pending at plan time.*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase171_no_bare_version_literal_test.exs` — MSG-04, MSG-05, WELD-03, WELD-07.
      Reuse the `run/2` (System.cmd + env override) + `tmp_dir!/1` + `manifest_at!/2` fixture idiom from
      `test/crosswake/proof/phase168_release_version_weld_test.exs`.
- [ ] `test/crosswake/proof/phase171_approved_version_output_test.exs` — WELD-02, WELD-08.
- [ ] `test/crosswake/proof/phase171_identity_gate_unchanged_test.exs` — WELD-08 regression
      (may be folded into the file above if the fixtures are shared).
- [ ] No shared fixture/conftest module needed — the `tmp_dir!`/`on_exit` pattern is copied per-file in
      this repo, not centralized. Copying it matches the existing convention.
- [ ] No framework install — ExUnit ships with Elixir.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| "manifest" terminology qualified in new/changed copy | DOC-05 | A wording convention, not a runtime behavior — no assertion can distinguish good prose from bad | Phase-close reviewer reads the phase diff for every occurrence of "manifest" and confirms each is qualified (which manifest) |
| WELD-01 inventory rows are correctly classified | WELD-01 | The grep proves the file set is complete; it cannot prove a row's live-gate/fixture/docstring/display-string label is right | Reviewer reads each row against the quoted line and confirms the classification |

Everything else has automated verification.

---

## Vacuity Guard (milestone v23.0 convention)

Per `VERIFICATION-CONVENTIONS.md`, Phase 171's `171-VERIFICATION.md` MUST carry a `vacuity_taxonomy:`
frontmatter list and a `## Vacuity Taxonomy` body section covering every check this phase lands —
minimally `release.publish_gate.no_bare_version_literal`. `non_vacuity_evidence:` for that check is
already specified by success criterion #1: the pre-repair fixture it is demonstrated failing against.
A bare tick is non-compliant.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 600s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
