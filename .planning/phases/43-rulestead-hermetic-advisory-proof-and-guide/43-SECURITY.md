---
phase: 43-rulestead-hermetic-advisory-proof-and-guide
slug: rulestead-hermetic-advisory-proof-and-guide
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-31
---

# Phase 43 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| CI workflow -> Hex registry | `mix deps.get` fetches normal package dependencies; the advisory lane conditionally fetches the optional `rulestead` dependency. | Build-time package metadata and source packages |
| Optional dep inclusion | `MIX_INCLUDE_RULESTEAD` controls whether `rulestead` enters the dependency tree. | CI environment variable into Mix dependency resolution |
| Guide prose -> live code | `guides/companions.md` describes shipped DSL symbols and companion APIs. | Documentation claims about public route-policy and companion contracts |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-43-01 | Tampering | Hermetic lane silently including rulestead through env bleed | mitigate | `.github/workflows/phase43-proof.yml` sets `MIX_INCLUDE_RULESTEAD` only on advisory job steps; the hermetic job has no env binding and runs `mix test --exclude requires_example_host --exclude advisory_only`. The Phase 42 hermetic proof still asserts `validate_dependency/0 == {:error, [:"Elixir.Rulestead"]}` and fails loudly if the optional dependency leaks in. | closed |
| T-43-02 | Tampering | rulestead supply-chain as optional dependency | accept | Accepted as a first-party szTheory dependency used only in advisory CI for Phase 43. The production path remains hermetic and the advisory lane is explicitly `continue-on-error: true`; promotion requires a future real `Rulestead.Snapshot` adapter, actual flag-read proof, stability evidence, and roadmap scope change. | closed |
| T-43-03 | Information disclosure | Committed `mix.lock` leaking a rulestead pin into hermetic state | mitigate | `mix.exs` includes `rulestead` only when `MIX_INCLUDE_RULESTEAD=1`; committed `mix.lock` contains zero `rulestead` entries (`grep -c rulestead mix.lock` -> `0`). | closed |
| T-43-04 | Repudiation/Tampering | Guide anchors drifting from live code | mitigate | `test/crosswake/guides/companions_test.exs` asserts the exact guide anchors (`gated_by`, `on_unavailable`, `kill_switch`, `MockFlagSource`, `fail-closed`) and live exports for `Crosswake.Companions.Rulestead.validate_dependency/0`, `MockFlagSource.set_flag/2`, and `Crosswake.SupportMatrix.gating_truth/0`. | closed |
| T-43-05 | Information disclosure | Guide implying unshipped rindle/sigra surfaces | mitigate | Phase 43 guide scope is limited to the companion intro plus rulestead section; `rg -n "rindle\|sigra" guides/companions.md` returns no guide matches. | closed |
| T-43-SC | Tampering | npm/pip/cargo installs | n/a | No npm, pip, or cargo installs are introduced by this phase; the only package addition is the conditional Hex `rulestead` dependency covered by T-43-02. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-43-01 | T-43-02 | `rulestead` is a first-party szTheory dependency used only in the advisory CI lane in this phase. It does not enter the committed hermetic lock or production path, and advisory-to-merge-blocking promotion is explicitly gated on future implementation and stability evidence. | agent | 2026-05-31 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-31 | 6 | 6 | 0 | agent |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-31
