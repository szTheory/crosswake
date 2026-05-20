# Phase 11 Validation

**Validated:** 2026-05-19
**Phase:** 11-capability-taxonomy-and-contract-rubric
**Status:** Ready for execution planning gate

## Gate Summary

- Phase context exists and is locked in `11-CONTEXT.md`.
- Phase research exists in `11-RESEARCH.md`.
- Phase pattern map exists in `11-PATTERNS.md`.
- Three executable plan artifacts exist: `11-01-PLAN.md` through `11-03-PLAN.md`.
- Phase validation strategy exists in `11-VALIDATION.md`.
- Roadmap and state surfaces reflect the planned Phase 11 execution path.

## Validation Strategy

### Wave 1: Taxonomy and ownership rubric

- Verify guide inventory and shell-activation wording with `rg` against `guides/capabilities.md`, `guides/bridge.md`, and `guides/native_shell.md`.
- Run `mix test test/crosswake/guides/capabilities_test.exs`.

### Wave 2: Manifest and typed support truth

- Run `mix test test/crosswake/manifest/manifest_test.exs test/crosswake/manifest/validator_test.exs`.
- Run `mix test test/crosswake/bridge/registry_test.exs test/crosswake/support_matrix/support_matrix_test.exs`.
- Confirm support-matrix family posture is derived from manifest capability entries rather than a second handwritten ledger.

### Wave 3: Rendered classifications and parity

- Run `mix test test/crosswake/guides/capabilities_test.exs test/crosswake/support_matrix/renderer_test.exs`.
- Confirm the rendered `guides/support_matrix.md` capability-family section matches the public classification set for `core`, `companion`, `example/docs-only`, and `defer`.

## Nyquist Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Locked taxonomy and ownership decisions traced to tasks | pass | `11-01-PLAN.md` through `11-03-PLAN.md` cite `D-01` through `D-29` directly in task actions |
| Every plan task has automated verification | pass | All tasks include `rg` or `mix test` verification commands |
| Validation samples every wave | pass | Each wave has at least one focused automated test command |
| Manifest-first support derivation is protected | pass | Plans require support output to derive from manifest capability registry metadata |
| Public taxonomy claims are mechanically checked | pass | Doc-contract and renderer tests cover inventory and classification parity |

## Remaining Execution Risks

- The support-matrix derivation work must stay manifest-primary and avoid accidentally creating a second handwritten capability ledger in `Crosswake.SupportMatrix` or `Renderer`.
- Existing command-shaped bridge commands, especially `files.pick`, must remain explicit compatibility surfaces and not be mislabeled as public semantic families.
- Public guide and generated-guide parity can still drift if execution narrows the rendered example set without updating the capability guide tests in the same wave.

## Validation Verdict

Phase 11 is valid for execution planning. The plans should proceed in sequence: publish the ownership-first taxonomy, move capability-family support truth into manifest-derived canonical state, then publish generated support classifications and exemplar-aligned package/defer guidance.
