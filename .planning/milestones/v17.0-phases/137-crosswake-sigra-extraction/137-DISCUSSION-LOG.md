# Phase 137: crosswake_sigra Extraction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-01
**Phase:** 137-crosswake_sigra Extraction
**Areas discussed:** Finding refactor shape, Auth axis + sanitize, Irreversible publish gate, Test split + clean-room

**Method:** User selected all four gray areas and directed a deep multi-lens research pass
(Elixir/OTP idiom, ecosystem precedent incl. cross-language, SWE/architecture, DevOps/SRE,
API-consumer/JTBD, DX, footguns) → one coherent one-shot recommendation. Executed as a
first round of 4 parallel research subagents (one per area) + a second round: one adversarial
code-verified audit subagent (the API/DX-lens agent was interrupted and deprioritized). The
audit produced three code-verified must-fixes folded into the final decisions.

---

## Finding refactor shape

| Option | Description | Selected |
|--------|-------------|----------|
| (a) One `%Finding{}` type end-to-end | Evaluator + ceremony both deal in `Finding`; callback returns `{:deny, Finding.t()}`; core translates | ✓ |
| (b) Internal sigra step-up struct, convert to Finding at outer boundary | Extra internal type / dual translation layer | |
| (c) Package-local Denial shim | Re-imports a Denial-shaped type; defeats the boundary + trips the AST guard | |

**User's choice:** (a) — locked as D-137-A.
**Notes:** Blast radius verified narrow (2 files, 2 `Denial.new` sites). Idiom precedent:
Phoenix/Ecto/Ash boundary structs. Audit surfaced the load-bearing sub-decision: the
`Companion.evaluate_auth/3` callback return type must change from `Denial.t()` to `Finding.t()`
and `RouteGate.prepend_auth_evaluation_denials/4` must call `finding_to_denial/2` (else a raw
`Finding` is pushed into a `[Denial.t()]` list). `Finding` gains optional `:code` + `:details`
fields — verified non-breaking (`@enforce_keys` = `[:axis, :message]`; no exhaustive matches).

---

## Auth axis + sanitize

| Option | Description | Selected |
|--------|-------------|----------|
| One `:auth` axis, code sub-classification, sanitize at source | `:auth → :step_up_required`; codes carry `auth.step_up.*` etc.; scrub inside sigra at Finding construction | ✓ |
| Multiple auth axes (`:auth_step_up`, `:auth_handoff`, …) | Explodes `finding_to_denial/2`; breaks the code-based ceremony match | |
| Sanitize in core `finding_to_denial/2` | Impossible post-extraction — `DenialCodes` lives in the package | |

**User's choice:** single `:auth` axis + sanitize-at-source — locked as D-137-B.
**Notes:** Audit found a real bug: the unconditional `Map.merge(base_details(finding), details)`
at `compatibility.ex:186-191` would inject `axis: :auth` into sanitized details — the `:auth`
clause must guard that merge like the existing `:pack_version` special-case. Defense-in-depth
layering with the D-136-A baseline denylist confirmed intentional (source scrub + sink scrub).
Generic `message`/`hint` mandatory (they bypass sanitize). Precedent: Sentry/Phoenix/OTel
scrub-at-source-and-sink; OAuth/OIDC single-reason + structured sub-code.

---

## Irreversible publish gate

| Option | Description | Selected |
|--------|-------------|----------|
| Release-PR merge IS the human gate; fold admin required-checks as task #1 | No extra approval; register_required_checks run after clean-room green-once on main | ✓ |
| Add explicit manual approval before `hex.publish` | Redundant with dry-run + clean-room; violates 0-recurring-intervention principle | |
| Keep admin required-checks registration separate from phase 137 | Leaves a window where the new lane exists but isn't blocking | |

**User's choice:** Release-PR-merge-as-gate + fold-in — locked as D-137-C.
**Notes:** Idiom = release-please Release-PR model (rulestead/rindle precedent). Auth companion
does not raise the bar — bad version is patch-recoverable; only name/version coordinate is
irreversible and that's gated. Audit scope-correction: the `release-please.yml` change is
~100 lines mirroring rulestead (new outputs + `publish-hex-sigra` + `clean-room-proof-sigra` +
extended cleanup/failure jobs), NOT a one-liner. `release-as: "0.1.0"` one-shot + auto-cleanup.
Green-first ordering avoids the required-check "waiting for status" deadlock.

---

## Test split + clean-room

| Option | Description | Selected |
|--------|-------------|----------|
| SC#1→package / SC#5→core; split phase54; clean-room registers sigra + asserts via RouteGate | handoff/telemetry/contracts/step_up → package; phase46 → core; phase54 split | ✓ |
| Move phase54 wholesale | Loses the `SupportMatrix.auth_contract_truth()` core-state assertion | |
| Assert bare `Evaluator → %Denial{}` in clean-room | Wrong post-refactor — sigra emits `Finding`, not `Denial` | |

**User's choice:** split-and-RouteGate-assert — locked as D-137-D.
**Notes:** Audit fix ③ (vacuity): the clean-room test MUST
`Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])` in setup —
registration is Application-env based and the package can't self-register — else the denial is
`:dependency_missing` (fail-closed), not `:step_up_required`, and the assertion is vacuous/red.
Drive `RouteGate.evaluate/4` (public) and assert the translated `Denial{reason:
:step_up_required}`, proving the full boundary. Add `StubSigraAbsentCompanion` in core.

---

## Claude's Discretion

- `crosswake_sigra` starting `@version` (`0.1.0` one-shot, follow rindle) + mix.exs metadata —
  clone the rindle package block.
- Optional brand-voice refinement of step-up/handoff denial microcopy against `BRAND-SPEC.md`.

## Deferred Ideas

- DX/microcopy polish of denial `message`/`hint` (the API/DX research lens was interrupted /
  deprioritized this session) — opportunistic during planning.
- Chimeway (138) clean-room must NOT install `crosswake_sigra` (vacuity guard) — noted for 138.
