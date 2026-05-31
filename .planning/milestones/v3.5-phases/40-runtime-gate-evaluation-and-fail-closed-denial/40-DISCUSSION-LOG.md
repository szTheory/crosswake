# Phase 40: Runtime Gate Evaluation And Fail-Closed Denial - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 40-runtime-gate-evaluation-and-fail-closed-denial
**Areas discussed:** Decision.t() for fallback route, OpenFeature details shape, Proof strategy

---

## Decision.t() for Fallback Route

| Option | Description | Selected |
|--------|-------------|----------|
| `transition: {:redirect, route_id}` | Extend existing transition field with tagged tuple. Single dispatch point for caller. No new struct fields. | ✓ |
| New `fallback_route_id` field | Add `fallback_route_id: String.t() \| nil` to Decision. Transition stays `:halt`. | |
| Denial recovery map | Put `%{fallback_route: "home"}` in `denial.recovery`. No struct change. | |
| You decide | Planner discretion. | |

**User's choice:** Research all options deeply, then single opinionated recommendation.

**Research findings (subagent):**
- `evaluated_at` is NOT in the OpenFeature 1.x spec — it is a Crosswake-owned extension
- Option B allows contradictory state (`transition: :halt` + `fallback_route_id: "home"`)
- Option C conflates machine-routing instructions with human-readable recovery hints (nil-safety chain at call site)
- Option A mirrors the existing `RouteEntry.on_unavailable: {:fallback_phoenix, atom()}` shape in the same codebase — intentional symmetry
- Guardian, LetMe, FunWithFlags all return a single authoritative result token

**Notes:** Unanimous subagent recommendation: Option A. User accepted.

---

## OpenFeature Details Shape

| Option | Description | Selected |
|--------|-------------|----------|
| RouteGate stamps `evaluated_at` | `DateTime.utc_now() \|> DateTime.to_iso8601()` called in RouteGate. No companion contract change. | ✓ |
| Companion provides via Finding | Companion encodes timestamp in `finding.subject` or similar. | |
| nil in Phase 40 | Skip `evaluated_at` until Phase 42+. | |

**User's choice:** Research all options deeply, then single opinionated recommendation.

**Research findings (subagent):**
- `evaluated_at` is not in OpenFeature spec — Crosswake-owned extension, RouteGate is the right owner
- `DateTime.utc_now()` → ISO8601 string keeps `Denial.to_map/1` simple; consistent with Ecto/Phoenix conventions
- `variant: "off"` is the correct conventional OpenFeature binary flag value — not nil
- `reason: "DISABLED"` is the exact OpenFeature standard string for a flag-is-off denial
- Phase 42+ companions supply real reason/variant via `finding.subject` — no Finding struct change needed in Phase 40

**Notes:** Unanimous subagent recommendation: RouteGate stamps, `"off"` for variant, `"DISABLED"` for reason. User accepted.

---

## Proof Strategy

### Proof file

| Option | Description | Selected |
|--------|-------------|----------|
| New `phase40_gate_evaluation_test.exs` | Per-phase proof file convention. Clear SC#1–4 traceability. | ✓ |
| Extend phase39 proof file | Add to existing `phase39_route_policy_gating_test.exs`. | |
| You decide | Planner discretion. | |

**User's choice:** New phase40 proof file.

### Fixture companions

| Option | Description | Selected |
|--------|-------------|----------|
| Module-level fixtures + `Application.put_env` in `setup_all` | Inline test modules + `put_env`; mirrors Phase 38 pattern; `async: false`. | ✓ |
| Separate test support file | `test/support/gate_fixture_companion.ex` — reusable across phases. | |
| You decide | Planner discretion. | |

**User's choice:** Module-level fixtures + `Application.put_env`.

### Proof scope

| Option | Description | Selected |
|--------|-------------|----------|
| SC#1–4 all four success criteria | Full GATE-03/GATE-04 coverage: gate_denied details, kill switch short-circuit, unavailability posture, no network calls. | ✓ |
| SC#1–2 only in Phase 40 | Defer unavailability posture and network assertion to Phase 41. | |
| You decide | Planner discretion. | |

**User's choice:** All SC#1–4 in Phase 40.

---

## Claude's Discretion

- Exact `finding_to_denial/2` extension strategy — RouteGate may produce `Denial.t()` directly or use new Finding axes; planner decides which is cleaner
- Telemetry span implementation detail (`:telemetry.span/3` vs direct emit)
- Whether gate evaluation follows a `prepend_gate_evaluation_findings/3` function or an inline step

## Deferred Ideas

- Doctor visibility for `{:fallback_phoenix}` posture → Phase 41
- Companion-supplied reason/variant via `finding.subject` → Phase 42
- `Finding.flag_variant` dedicated field → Phase 42 if needed
- Multiple companion denial accumulation → Phase 42+
- `crosswake_openfeature` adapter → v3.6+
