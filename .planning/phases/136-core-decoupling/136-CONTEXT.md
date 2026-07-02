# Phase 136: Core Decoupling - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Invert all four compile-time core→companion coupling sites onto the runtime `:companions`
registry seam so `crosswake` core compiles and operates `--warnings-as-errors` with **no**
companion package present. Pure refactor; zero publish risk; high refactor risk.

The four sites (from research spine, `.planning/research/v17-companion-family-completion.md`):
- `lib/crosswake/telemetry.ex:145,289` — `Sigra.Telemetry.event_names()` ++ `Chimeway.Telemetry.event_names()` and forbidden-metadata-keys aggregation (`build_reserved_events/0`).
- `lib/crosswake/compatibility/route_gate.ex:9,258` — `alias …Sigra.Evaluator`; `evaluate_route_auth/3` on route-activation path.
- `lib/crosswake/support_matrix/support_matrix.ex:16,226-227,266-269` — `Sigra.Telemetry`, `Sigra.DenialCodes.codes()`, `Chimeway.Telemetry`.
- `lib/crosswake/doctor/doctor.ex:792,797` — `Sigra.DenialCodes.codes()` / `allowed_detail_keys()`.

**In scope:** decoupling only — invert references onto the registry, extend the `Companion`
behaviour (D-1/D-2 callbacks), add the core baseline PII denylist (D-5), extend AST guards to
all core `lib/`. **Out of scope:** extracting any companion package (Phases 137-139), claiming
Hex names, the `Finding`-boundary refactor (Phase 137, see Decisions §2), publishing.

Requirements: **DECOUPLE-01..06** (see `.planning/REQUIREMENTS.md`). Design spine **D-1..D-9**
is LOCKED — this discussion resolved only the four genuinely-open gray areas beneath it.

</domain>

<decisions>
## Implementation Decisions

The milestone research already locked the mechanism (D-1: optional `@behaviour` callbacks +
runtime `Enum.flat_map` over `Application.get_env(:crosswake, :companions, [])` guarded by
`function_exported?/3`; the PromEx pattern. `get_env` **never** `compile_env`. No new
process/ETS/`@before_compile` accumulation). The four decisions below resolve what the spine
left open. They were derived from parallel ecosystem research (Sentry/Phoenix/OTel PII
scrubbing; Ash/Broadway/Oban package-split staging; `boundary`/`mix xref`/AST enforcement;
PromEx/Oban telemetry-contract testing) and are mutually coherent — fail-closed
defense-in-depth, one-axis-of-change-per-phase, stdlib-only enforcement, count-independent
tests, inspectable public contract.

### D-136-A — Core baseline PII forbidden-metadata-key denylist (D-5 / DECOUPLE-05)
- **Exactly 10 hardcoded atoms**, owned by core, always applied regardless of companion presence:
  ```elixir
  @baseline_forbidden_keys [
    # auth tokens — catastrophic if leaked from any event / any companion
    :access_token, :refresh_token, :id_token, :authorization_code, :token,
    # identity anchors — cross-event re-identification
    :session_ref, :subject_ref, :actor_id,
    # direct PII — GDPR/CCPA; appears in core route events
    :ip, :email
  ]
  ```
- **Matching rule: exact-atom `MapSet` membership. NOT substring/regex.** Telemetry metadata
  keys are bounded, low-cardinality, developer-defined atoms (unlike HTTP params, where
  Phoenix's substring filter is correct). Substring matching would (a) silently drop metric
  keys like `:notification_token_count`, and (b) invite the atom/string-mismatch footgun where
  `Map.drop(meta, ["token"])` silently no-ops against `:token`.
- **Layering:** `MapSet.union(@baseline_forbidden_keys, MapSet.new(companion_keys))` where
  `companion_keys` is the runtime aggregation of each registered companion's
  `forbidden_metadata_keys/0`. Built **once and captured in the handler closure at
  `attach_default_logger/1`** — never re-aggregated per event (D-5 cache directive).
- **Public API:** expose `Crosswake.Telemetry.baseline_forbidden_metadata_keys/0` so adopters
  can audit/test what core always scrubs. Semver contract (document explicitly): adding a key =
  minor (stricter safety); removing a key = major (weaker safety).
- **Deliberately excluded from the baseline** (companion-owned, meaningless in core events):
  PKCE verifier, nonce, credential IDs, device/user-agent, org_id, push tokens
  (APNS/FCM/device/registration), raw payloads, notification content, return-to fields,
  `:actor_ref`. Companions keep their fuller lists; baseline is the always-on floor.

### D-136-B — `evaluate_auth/3` returns `Denial.t()` in 136; `Finding` refactor is Phase 137 (D-2 / D-4)
- New **dedicated** optional callback pair `evaluate_auth/3` + `auth_authority?/0` (D-2 — never
  overload `route_gated?/2`). In Phase 136 the contract is:
  ```elixir
  @callback evaluate_auth(route :: RouteEntry.t(), auth_context :: map(), opts :: keyword()) ::
              {:allow, map()} | {:deny, Crosswake.Shell.Denial.t()}
  @callback auth_authority?() :: boolean()
  ```
- Core's `prepend_auth_evaluation_denials/4` stays a **direct passthrough** of the `Denial.t()`
  — zero type-translation layer added. Remove `alias …Sigra.Evaluator` (route_gate.ex:9);
  **keep** the `Denial` import; dispatch through the registry via `function_exported?/3`.
- **Do NOT pull the D-4 `Finding`-boundary refactor forward into 136.** Codebase evidence:
  `StepUpCeremony.evaluate_or_issue/3` pattern-matches `%Denial{reason: :step_up_required,
  code: code}` directly (a semantic branch, not cosmetic), and `DenialCodes.sanitize_details/1`
  runs inside sigra's `deny/4` before `Denial.new`. Moving these belongs with extraction, where
  the system is still one compile unit and the full suite runs pre-publish.
- **Explicit Phase-137 prerequisites (NOT 136), recorded so 137's discuss/plan owns them:**
  1. Add an `:auth` clause to `Finding` / `finding_to_denial/2` — today an `:auth` axis falls
     through to `:compatibility_mismatch` (semantically wrong). Map `axis: :auth` →
     `reason: :step_up_required`, propagating code + sanitized details.
  2. Re-point the `StepUpCeremony` `%Denial{}` match onto `Finding` fields (or shim).
  3. Move `DenialCodes.sanitize_details/1` to run at the companion-package boundary.
  4. Audit **all** `Denial.new` call sites across sigra sub-modules (`evaluator`, `handoff`,
     `step_up_ceremony`, `auth_return`) — deeper than the surface files suggest.

### D-136-C — AST `__aliases__` prefix-walk guard, stdlib-only (DECOUPLE-06)
- Extend the existing `lib/crosswake/companion_guard.ex` (`Code.string_to_quoted` +
  `Macro.prewalk` over `{:__aliases__, _, parts}`). Prose (`companion.ex` moduledoc "sigra for
  auth"), comments, and telemetry atom-lists (`[:crosswake, :threadline, :request]`) pass **by
  construction** — none are `__aliases__` nodes. **No allowlist needed.** Chosen over `mix xref`
  (misses alias-only refs like route_gate.ex:9), the `boundary` hex lib (new dep, over-calibrated
  for a frozen banned-set), and grep/regex (brittle, allowlist debt).
- **Two surgical fixes flagged by research (both required):**
  1. **Exact-match → prefix containment.** Current guard uses `parts in @banned_alias_parts`
     (exact list equality), which **silently misses child modules** — `Sigra.Evaluator`,
     `Sigra.Telemetry`, `Sigra.DenialCodes`, `Chimeway.Telemetry` would all pass while
     violating. Replace with `Enum.any?(@banned_alias_parts, &List.starts_with?(parts, &1))`.
     (The guard's own comment already claims "prefix match" — the code doesn't do it yet.)
  2. **Scope.** Walk `lib/**/*.ex` **minus** `lib/crosswake/companions/**/*.ex` (in-tree
     companions legitimately self-reference; the exclusion becomes a no-op once each extracts).
- Add `Sigra` + `Chimeway` to the banned set. Failure message names the matched banned prefix +
  file/line + the `:companions` registry-seam hint (contributor DX).

### D-136-D — reserved-events test: shape assertion + keep stub-seeded merge test (D-6)
- **Drop** `length(reserved_events) >= 24` and its `stable_id_message` block (core no longer
  statically owns the 14+10 companion counts after inversion).
- **Add** a count-independent **shape assertion** on the `:reserved` tier: every entry matches
  `%{event: [_ | _], tier: :reserved, measurements: list, metadata: list}` (non-empty atom-list
  event; no PII keys). Passes cleanly with **zero** companions registered (reserved set
  legitimately empty — coheres with the fail-closed no-companion success criterion).
- **Keep** the existing stub-seeded `:active`-event membership test (already count-independent)
  as the aggregation-mechanism proof, and the `refute MapSet.member?(active_prefixes, event)`
  no-overlap invariant. **No magic numbers anywhere.** Per D-6, each companion package owns its
  own Side-A "declared ⇔ emitted" proof; core's test only validates shape + merge.

### Claude's Discretion
- Exact helper names / module placement for the runtime aggregation functions
  (`support_matrix.ex` `@auth_contract_truth` / `@notification_support_truth` module attributes
  → `def` runtime helpers per the footgun register — mechanism is planner's).
- Precise wording of guard failure messages and public `@doc` text.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design spine & requirements (authoritative)
- `.planning/research/v17-companion-family-completion.md` — **LOCKED design spine D-1..D-9**,
  the two reframings (chimeway↔sigra AuthContext is a myth; core-decoupling must land green
  first), and the footgun/risk register. Read D-1, D-2, D-3, D-4, D-5, D-6 and the footgun list.
- `.planning/REQUIREMENTS.md` — DECOUPLE-01..06 (this phase's requirements).
- `.planning/ROADMAP.md` §"Phase 136: Core Decoupling" — goal + 5 success criteria.

### Coupling sites & seam (code to modify)
- `lib/crosswake/companion.ex` — the `Companion` behaviour; existing optional
  `telemetry_events/0` callback + `@optional_callbacks` (extend here with `forbidden_metadata_keys/0`,
  `denial_codes/0`, `evaluate_auth/3`, `auth_authority?/0`).
- `lib/crosswake/telemetry.ex` — `build_reserved_events/0` (~L143), forbidden-key aggregation
  (~L280-320), `attach_default_logger/1` (cache point), existing runtime companion iteration (~L59).
- `lib/crosswake/compatibility/route_gate.ex` — `Evaluator` alias (L9), `prepend_auth_evaluation_denials` (~L250-262), registry read (~L103).
- `lib/crosswake/support_matrix/support_matrix.ex` — L16/226-227/266-269; module attributes to convert (~L668-686).
- `lib/crosswake/doctor/doctor.ex` — L792/797; registry reads (~L565, L635).
- `lib/crosswake/companion_guard.ex` — the AST guard to extend (exact→prefix; scope; banned set).
- `lib/crosswake/compatibility/finding.ex`, `lib/crosswake/shell/denial.ex` — the two denial
  types (Finding = companion-public, Denial = core-private); `:auth` axis work is Phase 137.
- Companion telemetry sources (for the union reference, NOT to couple to):
  `lib/crosswake/companions/sigra/telemetry.ex`, `…/chimeway/telemetry.ex`.

### Project vision / DX (context)
- `prompts/crosswake-elixir-oss-dna.md`, `prompts/crosswake-research-synthesis.md`,
  `prompts/crosswake-brand-book.md` — safety-first / fail-closed / great-DX posture that the
  four decisions above cohere with.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Runtime registry iteration pattern** already shipped (Phase 129): `telemetry.ex:59`,
  `route_gate.ex:103`, `support_matrix.ex:686`, `doctor.ex:565/635` all read
  `Application.get_env(:crosswake, :companions, [])` at call time. New inversions copy this
  shape (`Enum.flat_map` + `function_exported?/3`) — no new infra.
- **Optional-callback precedent:** `telemetry_events/0` + `@optional_callbacks telemetry_events: 0`
  in `companion.ex:141-143` is the exact template for the four new optional callbacks.
- **AST guard skeleton:** `companion_guard.ex` already walks aliases and CI-wires the check
  (phase130 proof) — extend, don't rebuild.

### Established Patterns
- **`get_env` not `compile_env`** (EXTRACT-04 stale-beam guard) — keep `function_exported?` /
  `Code.ensure_loaded?` in function bodies, never module-eval.
- **Module-attribute footgun:** `support_matrix.ex` `@auth_contract_truth` /
  `@notification_support_truth` call companion functions at module-eval time → must become
  `def` runtime helpers (stale-beam trap).

### Integration Points
- `attach_default_logger/1` is where the merged forbidden-key `MapSet` must be built + cached.
- `prepend_auth_evaluation_denials/4` is the single auth call-site to indirect through the registry.

</code_context>

<specifics>
## Specific Ideas

- User explicitly wanted a research-backed, coherent, one-shot decision set (not sequential
  questions) — delivered via 4 parallel ecosystem-research subagents; decisions above are the
  synthesized recommendations, all locked.
- Ecosystem "copy" list (from research): PromEx plugin aggregation, Sentry default scrub keys,
  `:telemetry.attach_many` by event-name, Ash/Broadway/Oban independent per-package versioning.
  "Avoid" list: Guardian fail-open `VerifyHeader`, substring scrubbing of atom keys, `mix xref`
  for alias-only boundary checks, magic-number telemetry-count assertions.

</specifics>

<deferred>
## Deferred Ideas

- **Finding-boundary refactor for sigra auth** (D-4) — the `:auth` axis on `Finding` /
  `finding_to_denial/2`, StepUpCeremony match re-point, `sanitize_details` move to package
  boundary, and full `Denial.new` call-site audit. **→ Phase 137 (crosswake_sigra Extraction).**
- Per-companion Side-A "declared ⇔ emitted" telemetry contract tests (D-6) — each companion
  package owns its own. **→ Phases 137-140.**
- `Crosswake.Live.Threadline` Phoenix-dep-optional consideration (D-7). **→ Phase 139.**

None of the above is scope creep — all are explicitly sequenced later in the v17.0 roadmap.

</deferred>

---

*Phase: 136-core-decoupling*
*Context gathered: 2026-06-30*
