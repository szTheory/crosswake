# Phase 65: Diagnostic Export Seam (Elixir) - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Define — in **pure Elixir, no native code** — the diagnostics-export contract that native shells will mirror in Phase 67: a typed, versioned envelope with native/web/bridge layer attribution and an explicit, tested redaction allowlist, delivered as a **fire-and-forget HTTP POST contract to a host-owned endpoint** (the Chimeway pattern), **not** a bounded-bridge command.

Satisfies four requirements (DIAG-01..04), one decision each:

1. **Fire-and-forget HTTP seam, not a bridge command** (DIAG-01): `Crosswake.Shell.DiagnosticExport` defines the POST-to-host-owned-endpoint contract with NO bounded-bridge command vocabulary added (asserted by proof).
2. **Typed, versioned envelope with layer attribution + fixtures** (DIAG-02): payloads carry native/web/bridge attribution and a stable schema, carrying `native_runtime_version` from the Phase 64 runtime-line contract.
3. **`sanitize/1` + tested redaction allowlist** (DIAG-03): reuses the v3.9 Chimeway/Sigra posture; forbids raw tokens, payloads, route params, and PII; verified by a merge-blocking allowlist test.
4. **Doctor + support-truth readiness, no overclaim** (DIAG-04): reports diagnostics-export readiness without implying a first-party crash-reporting service.

**In scope:** new `Crosswake.Shell.DiagnosticExport` module (contract + behaviour); typed `Envelope` + inner `NativeDiagnostic` structs (house contract style); `sanitize/1`; a transport `@callback` the host/native-shell implements; per-layer/per-exit-reason fixtures; `@diagnostic_export_support_truth` + accessor in `SupportMatrix`; one `:advisory` doctor check + posture rendering; the phase-65 merge-blocking hermetic proof lane (allowlist test + no-bridge-vocabulary + no-HTTP-dep assertions).

**Out of scope (later phases):** the actual native senders — iOS MetricKit / Android `ApplicationExitInfo` capture and the real HTTP transport — and any Elixir HTTP client dependency (Phase 67); generator templates / `ADOPT:` markers / Xcode 26 CI (Phase 66); advisory emulator lane + device-UAT (Phase 68); docs-contract parity gate, Android `:supported` promotion, closeout (Phase 69). This phase ships the **contract only**; `delivery`/transport stays deferred and host-owned.

</domain>

<decisions>
## Implementation Decisions

All four decisions were research-backed (4 parallel advisor researchers, `minimal_decisive` calibration) and locked as one coherent set. They add one new module, two typed structs, one behaviour callback, one `SupportMatrix` truth attribute + accessor, and one doctor check — all additive, no new dependency, no manifest schema change.

### 1. HTTP Seam Shape — LOCKED (behaviour-only contract, NO transport code, NO new dep) ⚠️ public API
- **D-01:** `Crosswake.Shell.DiagnosticExport` ships the **envelope contract + a transport `@callback`** the host/native-shell implements — mirroring `Crosswake.Companions.Chimeway.IntentConsumer` (a passive `@callback consume_intent/1` with no sender). Crosswake ships **no** Elixir HTTP-sending code.
- **D-02:** Behaviour shape (signature is planner discretion; preserve intent): `@callback export(Envelope.t()) :: :ok | {:error, term()}`. "Fire-and-forget" is a documented semantic of the POST contract (method, content-type, host-owned endpoint, no response awaited), not Elixir transport behavior. The real senders are native (MetricKit / `ApplicationExitInfo`) in Phase 67.
- **D-03:** **No HTTP client dependency** (Req/Finch/Mint/:httpc) is added to the published lib. Adding the first runtime HTTP dep + an Elixir-side sender would be a first-party-service claim the library does not own and contradicts the host-owned-authority DNA. (Considered and rejected — see Deferred.)
- **D-04:** **Proof assertions** (DIAG-01 / success criterion 1): (a) no `diagnostics.*` / `diagnostic_export.*` entry added to the bounded-bridge command vocabulary (`Bridge.Contract`); (b) no HTTP-client dep introduced (assert against mix deps / no `Req`/`Finch`/`HTTPoison` reference in the new module).

### 2. Envelope + Layer Attribution — LOCKED (stable typed outer + typed inner, manual to_map, no @derive) ⚠️ public API
- **D-05:** House contract style (mirror `bridge/contract.ex`, `native_escape/contract.ex`, `chimeway/contracts.ex`): `@protocol "crosswake.diagnostic"` (spelling = planner discretion) + own **`@schema_version`** string **distinct from** `bridge_protocol_version`; nested `defstruct` with `@enforce_keys`; `@type t`; `new_*` constructor with closed-enum validation (`validate_closed`/`validate_required_string`); **manual `to_map/1`** that stringifies + rejects nils. **Do NOT use `@derive Jason.Encoder`** (matches house style).
- **D-06:** **Outer `Envelope` required (enforce-keyed) fields:** `schema_version`, `layer`, `platform`, `native_runtime_version`, `kind`, `correlation_id`, `observed_at`. (Exact field spellings = planner discretion; preserve the set + semantics.)
- **D-07:** **`layer` closed enum:** `:native | :web | :bridge` — `:native` = shell runtime (MetricKit / `ApplicationExitInfo`); `:web` = LiveView/browser-observed; `:bridge` = bounded-bridge command evaluation faults. `platform` reuses the existing `:ios | :android | :web` pattern. `native_runtime_version` is sourced from the Phase 64 `Compatibility.native_runtime_version` axis (the depends-on link).
- **D-08:** **`kind` closed enum** of diagnostic event classes, e.g. `:crash | :termination | :hang | :cpu | :bridge_fault | :web_fault` (exact set = planner discretion; must be closed + exhaustive, not open-ended).
- **D-09:** **Inner `NativeDiagnostic` struct** models iOS↔Android divergence honestly via **typed codes**, not a normalized-crash-schema overclaim: `source` (`:metrickit | :app_exit_info`) + one **closed `exit_reason` atom enum spanning both platforms** (e.g. `:crash | :anr | :low_memory | :user_requested | :hang | :cpu_resource_limit | :abnormal_exit | :other`). **No opaque `raw_payload: map()` passthrough** (see §3 reconciliation).
- **D-10:** **Fixtures** under `test/fixtures/diagnostic/` (or the existing fixture convention the planner confirms), one per meaningful axis — e.g. `native_ios_crash`, `native_ios_metrickit_hang`, `native_android_anr`, `native_android_low_memory`, `web_liveview_fault`, `bridge_command_fault` — proven via `test/support/proof_assertions.ex` (`assert_normalized_json_fixture`). These are the canonical shapes Phase 67 native shells mirror and parity-lock against.

### 3. Redaction — LOCKED (allowlist-by-construction, fail-closed, no free-form text) ⚠️ public API
- **D-11:** **Allowlist-by-construction is the redaction.** The typed `Envelope`/`NativeDiagnostic` structs **cannot represent** forbidden data — only typed/enumerated fields exist. This is the strongest honest reading of DIAG-03's *"forbids raw tokens, payloads, route params, PII"*: the schema literally cannot hold them. It is also the true reading of "reuse the Chimeway/Sigra posture" — Chimeway enforces its allowlist **at construction** (`Keyword.take`/`safe_metadata/1` + `safe_value?`), not just at serialization.
- **D-12:** **No free-form crash text in the Elixir contract.** Stack traces, exception messages, OS termination descriptions are inherently un-allowlistable (a token/PII can sit anywhere inside an allowed free-form string) and are **host-owned, out of scope** for the Elixir envelope — exactly as `provider_response_body` is excluded from Chimeway. Free-form capture lives wherever the host wires its endpoint, not in Crosswake's typed payload. (Best-effort scrubbing of bounded crash text was considered and rejected — see Deferred.)
- **D-13:** **Envelope↔redaction tension reconciliation (IMPORTANT):** the envelope researcher proposed an opaque `raw_payload: map()` "safety valve"; the redaction researcher proposed no open map at all. **Redaction wins — drop `raw_payload`.** An opaque passthrough is precisely what could smuggle a token/PII and is what DIAG-03 forbids. *If* any bounded metadata map is introduced at all, it MUST pass the **same Chimeway key-allowlist + `safe_value?` guard** (atoms / non-neg ints / ≤128-byte strings, forbidden keys dropped) — **never a raw passthrough.** Default posture: typed codes only, no metadata map unless the planner finds a concrete need (user-confirmed: locked without one).
- **D-14:** **`sanitize/1` shape:** `@spec sanitize(map()) :: {:ok, Envelope.t()} | {:error, :redaction_failed}` — **fail-closed**: reject (`{:error, ...}`) on unexpected/invalid input; do NOT drop-and-continue. For a diagnostic export, silent partial data loss is worse than a rejected payload. (Note this is stricter than telemetry's drop-and-continue, by design.)
- **D-15:** **Merge-blocking allowlist test** (DIAG-03 / success criterion 3): reuse the Phase 58 idiom — `assert forbidden_key in forbidden_keys(); refute forbidden_key in allowed_keys()` — over the established forbidden set (`:token,:raw_token,:device_token,:registration_token,:apns_token,:fcm_token,:provider_payload,:raw_payload,:notification_title,:notification_body,:route_params,:actor_id,:subject_ref,:session_ref,:device_id,:ip,:user_agent,:email,:provider_response_body`), plus a fixture round-trip through `sanitize/1` asserting the output struct holds no field outside the declared allowed set.

### 4. Readiness Posture — LOCKED (mirror @notification_support_truth exactly) ⚠️ public API
- **D-16:** Add `@diagnostic_export_support_truth` module attribute + public `diagnostic_export_support_truth/0` accessor to `SupportMatrix`, mirroring `@notification_support_truth` / `notification_support_truth/0` exactly (single source for docs generation + future Phase 67 promotion). Entry carries: `surface`, `proof_class: :merge_blocking` (the allowlist proof), `action_class`, `docs_anchor`, `delivery_supported: false`, a `telemetry` sub-map (`status`, `event_names`, `metadata_keys`, `forbidden_metadata_keys`, `authority_source: :host_configured_endpoint`, `proof_class`), `deferred: [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture]`, and a prose `posture:` string.
- **D-17:** **`posture:` string draws the seam** (no overclaim): *"Diagnostics-export envelope and sanitize contract are shipped and merge-blocking allowlist proof is enforced; native MetricKit/ApplicationExitInfo transport is not shipped until Phase 67; the host owns the endpoint and the data — Crosswake is not a crash-reporting service."* (Prose = planner discretion; preserve the three separations: shipped-contract / deferred-native-transport / host-owns-data-not-a-service.)
- **D-18:** **One doctor check** (DIAG-04 / success criterion 4): severity **`:advisory`**, code `"diagnostic_export.contract_shipped"` (spellings = planner discretion). `:advisory` is correct because no config key is actionable in Phase 65, no native transport exists to misconfigure, and the finding is informational evidence the contract is present — not a remediation demand. Fires unconditionally (the contract is core, not capability-gated), mirroring how notification findings fire. Render an evidence/posture line consistent with the existing doctor support section.

### Claude's Discretion
- Exact module/struct/callback/function names and field spellings (`DiagnosticExport`, `Envelope`, `NativeDiagnostic`, `export/1` vs `post/2`, `sanitize/1`, `schema_version`, `@protocol` value) — preserve the locked semantics.
- Exact `layer` / `kind` / `exit_reason` / `source` atom spellings — preserve closed-enum exhaustiveness and the native/web/bridge + MetricKit/ApplicationExitInfo coverage.
- Whether a sub-module split (`DiagnosticExport.Contracts`, `.Redaction`) mirrors the Chimeway file layout or stays in one module — preserve construction-time allowlist enforcement.
- Fixture directory/naming and proof-lane file placement (follow existing `test/crosswake/proof/phaseNN_*` + `test/fixtures/` conventions).
- Exact `SupportMatrix` entry field population, `docs_anchor`, `check_ids`, and doctor render line — preserve the three-way readiness/deferred/not-a-service separation.
- Whether `sanitize/1`'s fail-closed guard lives in the constructor vs a dedicated function — preserve fail-closed semantics and the construction-time allowlist.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` — Crosswake thesis; v4.0 "Production Shell Runtime Line" goal + scope posture (shells stay checked-in proof artifacts; hermetic proof merge-blocking; host-owned authority; explicit out-of-scope: "First-party crash-reporting/push delivery guarantees").
- `.planning/REQUIREMENTS.md` — DIAG-01..04 (the 4 requirements this phase satisfies) and v4.0 out-of-scope boundaries.
- `.planning/ROADMAP.md` — Phase 65 goal + 4 success criteria; adjacent Phase 66 (generators instantiate this contract) and Phase 67 (native shells implement MetricKit/ApplicationExitInfo over the HTTP seam + the merge-blocking JVM lane) boundaries this phase defers to.
- `.planning/phases/64-runtime-line-policy-contract-support-truth-taxonomy/64-CONTEXT.md` — the immediately-prior phase; source of `native_runtime_version` on the envelope and the evidence-taxonomy / never-overclaim posture this phase reuses.

### Existing Crosswake code — integration surface (confirmed during scout)
- `lib/crosswake/companions/chimeway/intent_consumer.ex` — `@callback consume_intent/1`: the **exact behaviour-only, host-implements-transport precedent** for D-01/D-02 (passive callback, no sender).
- `lib/crosswake/companions/chimeway/contracts.ex` — `Crosswake.Companions.Chimeway.Contracts`: closed-enum + `normalize_attrs`/`build`/`validate_*` + manual `to_map/1` (no `@derive`) — the constructor/validation template for the new envelope (D-05).
- `lib/crosswake/bridge/contract.ex` + `lib/crosswake/native_escape/contract.ex` — `@protocol`/`@version` envelope house style; **`Bridge.Contract` command vocabulary** is what the proof asserts gained no `diagnostics.*` entry (D-04).
- `lib/crosswake/companions/chimeway/redaction.ex` — `@forbidden_public_token_keys` + `safe_metadata/1`: construction-time allowlist enforcement model (D-11/D-13).
- `lib/crosswake/companions/chimeway/telemetry.ex` — `@metadata_keys` (allowlist) + `@forbidden_metadata_keys` (denylist) + `metadata/1` cond block + `safe_value?` (atoms / non-neg ints / ≤128-byte strings): the dual-guard the bounded-metadata fallback must reuse; the canonical forbidden-key set (D-13/D-15).
- `lib/crosswake/companions/chimeway/denial_codes.ex` + `lib/crosswake/companions/sigra/denial_codes.ex` — `@allowed_detail_keys` + `Map.take/2`: pure-allowlist precedent (D-11).
- `lib/crosswake/shell/` (`activation.ex`, `denial.ex`, `fixtures.ex`) — the `Crosswake.Shell.*` namespace the new `DiagnosticExport` module joins; `Shell.Denial` shows the closed-reason-enum + `to_map/1` (nil/empty reject) style.
- `lib/crosswake/manifest/types.ex` — `Compatibility.native_runtime_version` (the Phase 64 axis the envelope carries) and the `RuntimeLineRow` struct just added in Phase 64.
- `lib/crosswake/support_matrix/support_matrix.ex` — `@notification_support_truth` + `notification_support_truth/0`: the exact shape to mirror for `@diagnostic_export_support_truth` (D-16/D-17), including `delivery_supported`, `telemetry` sub-map, `deferred`, `posture`.
- `lib/crosswake/companions/chimeway.ex` — `report_state/0` with `details: %{delivery_support: :not_shipped, ...}`: the "contract shipped, delivery deferred" readiness model.
- `lib/mix/tasks/crosswake.doctor.ex` + `lib/crosswake/doctor/doctor.ex` (+ Formatter / JSONFormatter) — `Check`/`Report` structs, severity `:error | :warning | :advisory`; where the `:advisory` `diagnostic_export.contract_shipped` finding + posture render land (D-18).

### Proof / test patterns
- `test/support/proof_assertions.ex` — `assert_normalized_json_fixture`, `assert_file_exact`, `assert_contains_exact` (envelope fixtures, D-10).
- `test/crosswake/companions/chimeway/telemetry_test.exs` — the allowlist-drop assertion idiom.
- `test/crosswake/proof/phase58_auth_diagnostics_closeout_test.exs` — the merge-blocking `assert forbidden in forbidden_list; refute forbidden in allowed_list` + support-truth lock idiom (D-15) and the `phaseNN_*` proof-lane file convention.

### Prompt corpus (house style — consulted during discussion)
- `prompts/crosswake-elixir-oss-dna.md` — honest support truth, NARROW additive public APIs, host-owned authority, advisory-until-promotion, no first-party service it doesn't own (primary reference for all four decisions, esp. D-01/D-03).
- `prompts/crosswake-brand-book.md` — anti-hype, boundary-aware positioning (supports D-17's "not a crash-reporting service" framing).

### External comparables checked during research (informed decisions; not project docs)
- Chimeway/IntentConsumer behaviour-only precedent vs. shipping a Req/Finch sender — the "first-party service / new-dep" footgun (informs D-01/D-03).
- MetricKit (iOS termination reasons, hang/CPU metrics) vs. Android `ApplicationExitInfo` (ANR, crash, low-memory, user-requested) shape divergence — informs the typed `exit_reason` enum over a false unified schema (D-09).
- Allowlist-by-construction vs. regex/entropy free-form scrubbing — the "incomplete-scrub leaks tokens embedded in stack traces/URLs" footgun (informs D-11/D-12).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Chimeway.IntentConsumer` `@callback` — the behaviour-only, no-transport template for the export seam (D-01/D-02).
- `Chimeway.Contracts` constructor/validation helpers (`validate_closed`, `validate_required_string`, `normalize_attrs`, `build`, manual `to_map/1`) — directly reusable for the envelope (D-05).
- `Chimeway.Telemetry` `safe_value?` + `@forbidden_metadata_keys` + the canonical forbidden-key set — reused verbatim by the redaction allowlist + merge-blocking test (D-13/D-15).
- `SupportMatrix.@notification_support_truth` + accessor — the exact data shape to clone for diagnostics-export truth (D-16/D-17).
- `Doctor` `Check`/`Report` structs + `:advisory` severity — the readiness finding (D-18).
- `test/support/proof_assertions.ex` fixture assertions — envelope fixtures (D-10).

### Established Patterns
- Contract module = `@protocol` + own version + `@enforce_keys` defstruct + closed-enum validation + manual `to_map/1` (no `@derive Jason.Encoder`).
- Redaction/allowlist enforced **at construction**, not just at serialization; fail-closed; low-cardinality; never leak.
- Support truth never overclaims; shipped-contract is reported distinctly from deferred-delivery; host owns authority/data.
- Hermetic merge-blocking proof lane per phase; narrow additive public API; no new runtime dependency on the published lib.

### Integration Points
- New: `lib/crosswake/shell/diagnostic_export.ex` — `Crosswake.Shell.DiagnosticExport` (contract + `@callback export/1` + `Envelope`/`NativeDiagnostic` structs + `sanitize/1`); optional `*/contracts.ex` / `*/redaction.ex` sub-modules at planner discretion.
- New fixtures: `test/fixtures/diagnostic/*.json` (per layer × exit-reason).
- Additive: `SupportMatrix.@diagnostic_export_support_truth` + `diagnostic_export_support_truth/0`.
- Additive: one `:advisory` doctor check + posture render in `crosswake.doctor` (+ Formatter/JSONFormatter parity).
- New proof: `test/crosswake/proof/phase65_*` asserting (a) merge-blocking allowlist (forbidden∉allowed + `sanitize/1` round-trip), (b) no `diagnostics.*` bridge-command vocabulary added, (c) no HTTP-client dep added, (d) support-truth/doctor readiness present + non-overclaiming, (e) envelope fixtures normalize.
- Downstream: Phase 66 generators emit host endpoint scaffolds from this contract; Phase 67 iOS/Android shells implement MetricKit/`ApplicationExitInfo` capture + the real HTTP POST mirroring this envelope + the merge-blocking JVM lane.

</code_context>

<specifics>
## Specific Ideas

- Behaviour shape, concrete: `@callback export(Envelope.t()) :: :ok | {:error, term()}`; "fire-and-forget" documented as POST semantics (no awaited response, host-owned endpoint), NOT Elixir transport.
- Outer envelope enforce-keyed fields: `schema_version`, `layer`, `platform`, `native_runtime_version`, `kind`, `correlation_id`, `observed_at`.
- `layer :: :native | :web | :bridge`; `platform :: :ios | :android | :web`; `kind :: :crash | :termination | :hang | :cpu | :bridge_fault | :web_fault`.
- Inner `NativeDiagnostic`: `source :: :metrickit | :app_exit_info`; `exit_reason :: :crash | :anr | :low_memory | :user_requested | :hang | :cpu_resource_limit | :abnormal_exit | :other`. **No `raw_payload` map.**
- `sanitize/1 :: {:ok, Envelope.t()} | {:error, :redaction_failed}` — fail-closed.
- `posture:` string separates: contract shipped + allowlist proof enforced / native transport deferred to Phase 67 / host owns endpoint + data, not a crash-reporting service.
- `deferred: [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture]`; `authority_source: :host_configured_endpoint`.
- Doctor finding: `:advisory`, `"diagnostic_export.contract_shipped"`, fires unconditionally.

</specifics>

<deferred>
## Deferred Ideas

- **Optional dep-gated Elixir reference sender** (Req/Finch + `Task` fire-and-forget) — considered and rejected for Phase 65 (adds first HTTP dep + first-party-service claim). Could be revisited as a separate optional companion package if Elixir-side telemetry push ever becomes a product requirement; not core.
- **Bounded free-form crash text / structured stack frames** (module:function/arity with no argument values, hard length cap, best-effort token scrub) — rejected for the Elixir contract: un-allowlistable contents, best-effort ≠ "forbids". Host-owned. Revisit only if device evidence in Phase 67 shows typed codes are insufficient AND a contract-enforced bound can be proven.
- **Per-platform fully-typed inner structs** (`MetricKitDiagnostic`/`AppExitInfoDiagnostic`) — deferred; over-specifies inner shape before Phase 67 device evidence confirms real MetricKit/`ApplicationExitInfo` fields. The single typed `exit_reason` enum is the honest Phase-65 shape.
- **Native MetricKit / `ApplicationExitInfo` capture + real HTTP transport + merge-blocking JVM lane** — Phase 67.
- **Host endpoint generator scaffolds / `ADOPT:` markers** — Phase 66.
- **Docs-contract parity gate + Android promotion + closeout** — Phase 69.

### Reviewed Todos (not folded)
None — `todo.match-phase 65` returned 0 matches.

</deferred>

---

*Phase: 65-Diagnostic Export Seam (Elixir)*
*Context gathered: 2026-06-04*
