# Phase 64: Runtime-Line Policy Contract & Support-Truth Taxonomy - Context

**Gathered:** 2026-06-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock — in **pure Elixir, no native code** — the runtime-line policy and support-truth taxonomy that prevents any downstream surface from overclaiming:

1. **Rebuild/OTA classification** (RLINE-01): a policy that classifies any change (across 8 change classes: bridge schema change, capability family add, permission add, entitlement add, SDK floor bump, privacy-manifest entry, push capability change, URL-scheme change) as OTA-safe or rebuild-required.
2. **`native_runtime_version`-only derivation** (RLINE-02): the rebuild/OTA decision derives ENTIRELY from the existing `compatibility.native_runtime_version` axis — **no new manifest JSON field, no `manifest_schema_version` bump** (asserted by a hermetic proof test).
3. **Rebuild & compatibility matrix** (RLINE-03): an operator-facing projection through `SupportMatrix` + `mix crosswake.doctor` mapping shell/runtime-line version → supported manifest/capability surface.
4. **Evidence taxonomy** (RLINE-04): support truth reports `:jvm_hermetic` distinctly from `:device_verified` and never labels CI-only evidence as device-verified.
5. **Android promotion criteria** (RLINE-05): explicit, documented criteria (required evidence, minimum consecutive passes, demotion trigger) for moving Android `:verification_required → :supported`.

**In scope:** New `Crosswake.RuntimeLine.RebuildPolicy` module; additive typed fields on `CapabilitySupportEntry`/`PromotionRuleEntry`; new `RuntimeLineRow` struct + `SupportMatrix.rebuild_matrix/1` projection; doctor human+JSON rendering of the matrix and evidence posture; two new criteria-as-data Android promotion rows; the phase-64 hermetic proof lane.

**Out of scope (later phases):** native shell code, generator templates, Xcode 26 CI (Phase 66); native shell implementation + the actual merge-blocking JVM-hermetic CI lane (Phase 67); device/emulator advisory lane + device-UAT (Phase 68); the docs-contract parity gate, the actual Android `:supported` flip, and closeout (Phase 69). Phase 64 **authors criteria-as-data only** — it does NOT flip Android `SupportEntry.status`; Android stays `:verification_required`.

</domain>

<decisions>
## Implementation Decisions

All four decisions were research-backed (4 parallel advisor researchers) and locked as one coherent set. They derive from the existing `native_runtime_version` axis and existing `SupportMatrix` data; they introduce one new module, one new struct, two new typed fields, and two promotion-rule data rows — all additive.

### 1. Rebuild-Policy Derivation — LOCKED (hybrid, derived from existing manifest data)
- **D-01:** New public module `Crosswake.RuntimeLine.RebuildPolicy` (name is planner discretion; preserve the `RuntimeLine` namespace). It does NOT maintain a full static duplicate of rebuild truth — it **derives** classification from the data that already owns it.
- **D-02:** **Capability-axis change classes** (`capability_family_add`, `bridge_schema_change`, `permission_add`, `entitlement_add`, `push_capability_change`, `url_scheme_change`) derive from the existing `Capability.rebuild` field:
  - `:native_required → {:rebuild_required, :native_shell}`
  - `:companion_required → {:rebuild_required, :companion_shell}`
  - `:none → :ota_safe`
- **D-03:** **System-level classes with no capability owner** (`sdk_floor_bump`, `privacy_manifest_entry`) map via a locked `@system_rebuild_classes` module attribute (closed set, ~2 entries, NOT runtime-configurable — new system classes go through a phase, not a config key).
- **D-04:** Public API (signatures are planner discretion; preserve intent):
  ```elixir
  @spec classify(change_class(), Capability.t() | nil) ::
          :ota_safe | {:rebuild_required, :native_shell | :companion_shell}
  @spec diff(Root.t(), Root.t()) :: [{change_class(), verdict()}]   # tooling/doctor input, NOT a release-gate oracle
  @spec rebuild_required?(Capability.rebuild()) :: boolean()         # public predicate the proof asserts against
  ```
- **D-05:** **`native_runtime_version`-derivation made provable** (RLINE-02 / success criterion 2) in the phase-64 hermetic proof test:
  - **Co-truth parity:** `classify/2` agrees with `SupportMatrix.action_classes()` `rebuild_required` for every action class (no bespoke fixture data).
  - **No-new-field assertion:** the `Compatibility` struct still has EXACTLY its current fields (`manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version`, `supported_manifest_sources`, `remote_updates`) and `manifest_schema_version` is unchanged.
- **D-06:** **Footguns to avoid:** (a) never classify by change-class label alone — key off the runtime context (`Capability.rebuild`), which is exactly the Expo EAS / CodePush "it's just JS → silent OTA break" failure mode; (b) never treat `:companion_required` as OTA-safe (it still needs a companion binary rebuild); (c) `diff/2` must not overclaim — it classifies, it does not know whether a binary with the new `native_runtime_version` already shipped.

### 2. Evidence Taxonomy Shape — LOCKED (orthogonal axis, NOT a refinement of `proof_class`) ⚠️ public API
- **D-07:** Add a NEW orthogonal axis, do NOT collapse into `proof_class`. `proof_class` keeps answering "does this block merge?" (`:merge_blocking | :advisory | :not_applicable`); the new field answers the different question "what evidence backs this claim?". Collapsing them is the badge-inflation / evidence-laundering footgun (SLSA provenance levels, Apple notarization vs real-device TestFlight, CI-vs-device test pyramid all keep these separate).
- **D-08:** Add typed `verification_method` to **`CapabilitySupportEntry`** (the **claim**), default `:none`. Add typed `required_verification_method` to **`PromotionRuleEntry`** (the **gate**). Keep the existing `evidence_class` STRING field as the human label for back-compat — do not break it.
- **D-09:** Tier enum (weakest→strongest provenance; stable atoms, exhaustive not open-ended):
  ```
  :none | :provider_advisory | :jvm_hermetic | :emulator_advisory | :device_verified
  ```
  iOS capability/shell entries that are currently device-backed = `:device_verified`; Android = `:jvm_hermetic` (CI-only JVM proof, no device lane this milestone).
- **D-10:** **CI-only-never-device invariant** (RLINE-04 / success criterion 4), two mechanical guarantees:
  - **Construction/validation:** no code path sets `:device_verified` without an explicit real-device evidence artifact; `SupportMatrix` validation rejects `:device_verified` on an entry whose evidence corpus is CI-only.
  - **Render:** the formatter renders `:jvm_hermetic` as `"jvm-hermetic (CI only)"` and prints `"device-verified"` ONLY for a genuine `:device_verified` — no implicit promotion in the formatter.
- **D-11:** Do NOT add `verification_method` to the per-platform baseline `SupportEntry` rows (`:phoenix`/`:ios`/`:android`/`:shells`) — the distinction does mechanical work on `CapabilitySupportEntry` + `PromotionRuleEntry` only.

### 3. Rebuild & Compatibility Matrix Projection — LOCKED (typed row list through `SupportMatrix`) ⚠️ public API
- **D-12:** New struct `Crosswake.Manifest.Types.RuntimeLineRow` (`@derive Jason.Encoder`, `@enforce_keys`), added to `SupportMatrix` as a `rebuild_matrix` field populated from a `@rebuild_matrix_rows` module attribute — same lifecycle/pattern as `@change_class_entries` / `@commerce_corridor_entries`. This fits the uniform list-of-typed-structs convention; a version-keyed map was rejected (breaks the convention, creates two independent serialization paths that can drift).
- **D-13:** Accessor `@spec rebuild_matrix(SupportMatrix.t()) :: [Types.RuntimeLineRow.t()]` mirroring `capability_families/1` exactly (1-arity, no options, no computed projection).
- **D-14:** **Granularity:** one row per **major runtime-line band** (`"1.x"`, `"2.x"`) — NOT per patch, NOT per capability family. Columns: `runtime_line`, `capability_surface` (`[String.t()]`), `change_class`, `ota_safe` (bool), `rebuild_required` (bool), `evidence_tier`.
- **D-15:** **Cross-seam reconciliation (IMPORTANT):** the matrix DISPLAYS the other two seams, it does NOT re-decide them.
  - `evidence_tier` reuses the **same `verification_method` enum from D-09** — do NOT invent a separate 3-value evidence enum on the row.
  - `rebuild_required` + the rebuild reason come straight from D-01..D-04 (`RebuildPolicy`).
- **D-16:** **Doctor rendering** (RLINE-03 / success criterion 3): a new `rebuild & compatibility matrix:` block UNDER the existing `release policy:` section (it's a projection of the same `native_runtime_version` axis), in BOTH human (`Doctor.Formatter`) and JSON (`Doctor.JSONFormatter`). Human/JSON parity is structural — both formatters traverse the same `[RuntimeLineRow.t()]` list (no independent serialization). Add an `evidence posture:` line so an operator sees `ios=device-verified  android=jvm-hermetic (CI only)` at a glance.

### 4. Android Promotion Criteria — LOCKED (extend `promotion_rules()` with two data rows, no new module) ⚠️ public API
- **D-17:** Extend `SupportMatrix.promotion_rules()` with TWO new `PromotionRuleEntry` rows (criteria-as-code is the established idiom; a dedicated contract module was rejected as over-engineered and fragmenting). Bind to the D-09 taxonomy via `required_verification_method`.
- **D-18:** **`shell.android.jvm_hermetic`** — what CI-only JVM evidence can honestly reach:
  - `required_verification_method: :jvm_hermetic`, `promotes_to: :merge_blocking`
  - `minimum_consecutive_passes: 3` (one above the existing iOS `1` and current Android advisory `2` — credible, attainable, not gameable by luck)
  - `freshness_window: "current release branch, within 30 CI runs"` (countable, no calendar that would lie in a sparse repo)
  - `failure_budget: "zero consecutive failures; single failure resets counter"` (only honest policy when CI-only JVM evidence can't be supplemented locally)
  - explicit `required_evidence` (verify script + JVM BridgeChannel proof + support-matrix parity + docs-contract parity), `required_platforms: ["android"]`, explicit `demotion_trigger`.
- **D-19:** **`shell.android.device_verified`** — explicitly GATED: `required_verification_method: :device_verified`; `demotion_trigger` prose states device/emulator proof is unavailable until Phases 67/68 and that jvm_hermetic promotion MUST NOT be read as device_verified. This is the "newly available vs widely available" (browser Baseline) / alpha→beta→GA (K8s) / stabilization (Rust) two-tier model.
- **D-20:** **Phase boundary (scope guardrail for the planner):** Phase 64 AUTHORS these criteria as data only. Android `SupportEntry.status` / `proof_status` stays `:verification_required` this phase. The merge-blocking jvm_hermetic CI lane lands in Phase 67; the actual `:supported` flip (only if criteria pass) is Phase 69. Do NOT promote Android in Phase 64.

### Claude's Discretion
- Exact module/struct/function names (`RebuildPolicy` vs `Policy`, `RuntimeLineRow`, accessor names, the `verification_method`/`required_verification_method` field spellings) — preserve the locked semantics above.
- Exact `change_class()` atom spellings and the `@system_rebuild_classes` representation — preserve the closed-set + 8-class coverage.
- Exact `PromotionRuleEntry` field population, `check_ids`, telemetry/check identifiers, and `demotion_trigger` prose — preserve honesty, the 3-pass / 30-run / zero-budget values, and the gating note.
- Test file placement and proof-lane naming (follow existing `test/crosswake/proof/phaseNN_*` conventions).
- Whether `verification_method` validation lives in a constructor guard vs a `SupportMatrix.validate/1` clause — preserve the structural CI-only-never-device guarantee.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/PROJECT.md` — Crosswake thesis, v4.0 "Production Shell Runtime Line" goal, scope posture (shells stay checked-in proof artifacts; hermetic proof merge-blocking; device/emulator/provider proof advisory; Android JVM evidence CI-only; backend-owned authority).
- `.planning/REQUIREMENTS.md` — RLINE-01..05 (the 5 requirements this phase satisfies) and the v4.0 out-of-scope boundaries.
- `.planning/ROADMAP.md` — Phase 64 goal + 5 success criteria, and adjacent Phase 65–69 boundaries (esp. the Phase 67 merge-blocking JVM lane and Phase 69 promotion/closeout this phase defers to).
- `.planning/STATE.md` — current position (Phase 64 of 69, first v4.0 phase) and deferred Nyquist validation-ledger tech debt routed here.

### Existing Crosswake code — integration surface (confirmed during scout)
- `lib/crosswake/manifest/types.ex` — `Compatibility` struct (the `native_runtime_version` axis; must gain NO new field); `CapabilitySupportEntry` (gains `verification_method`); `Capability.rebuild :: :none | :native_required | :companion_required` (the rebuild-derivation source of truth); add new `RuntimeLineRow` struct here.
- `lib/crosswake/compatibility/compatibility.ex` — `compatible_version?/2`, `validate_native_runtime/4`, the existing axes; reference for how `native_runtime_version` is compared.
- `lib/crosswake/support_matrix/support_matrix.ex` — statuses (`:supported|:verification_required|:unsupported`), `proof_class` (`:merge_blocking|:advisory|:not_applicable`), `CapabilitySupportEntry`, `PromotionRuleEntry` (gains `required_verification_method`; existing fields `evidence_class`, `required_evidence`, `minimum_consecutive_passes`, `freshness_window`, `failure_budget`, `required_platforms`, `demotion_trigger`, `change_class`, `action_class`), `action_classes()` (the co-truth source for the rebuild proof), existing `promotion_rules()` Android entries (`shell.android.generated_project`), `canonical/1`; add `rebuild_matrix` field + `@rebuild_matrix_rows` + `rebuild_matrix/1`.
- `lib/mix/tasks/crosswake.doctor.ex` + `Crosswake.Doctor.Formatter` + `Crosswake.Doctor.JSONFormatter` — the `support:` / `release_policy:` section carrying `native_runtime_version`; render the matrix + evidence posture here (human + JSON parity).
- Contract module patterns to mirror for the new public API: `lib/crosswake/bridge/contract.ex`, `lib/crosswake/commerce/contracts.ex`, `lib/crosswake/native_escape/contract.ex` (protocol/version envelope + typed structs house style).
- Proof-test patterns: `test/support/proof_assertions.ex` (`assert_normalized_json_fixture`, `assert_file_exact`, `assert_contains_exact`), `test/crosswake/proof/phase5_proof_lane_test.exs` (phase proof lane structure).

### Prompt corpus (research/vision — consulted during discussion)
- `prompts/crosswake-elixir-oss-dna.md` — maintainer house style: honest install/support truth, hermetic proof lanes, NARROW additive public APIs, advisory-until-promotion. (Primary house-style reference for all four decisions.)
- `prompts/crosswake-brand-book.md` — anti-hype, boundary-aware positioning (supports the never-overclaim evidence taxonomy).
- `prompts/crosswake-research-synthesis.md` — route-policy / runtime-boundary thesis, rebuild-vs-OTA framing.
- `prompts/elixir-mobile-oss-lib-deep-research.md` + `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — rebuild/OTA boundary, support-truth & DX lessons.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — mobile archetype / runtime-boundary pressure.

### External comparables checked during research (informed the decisions; not project docs)
- Expo EAS Update `runtimeVersion` policy + CodePush/AppCenter OTA rules — the "it's just JS → silent native-incompat OTA break" footgun (informs D-06).
- SLSA / in-toto provenance levels, Apple notarization vs real-device TestFlight, CI-vs-device test pyramid — evidence-provenance separation (informs D-07/D-10).
- Kubernetes alpha→beta→GA, Rust feature stabilization, browser "Baseline" newly-vs-widely-available, SLO burn-rate demotion, flaky-test quarantine — accumulated-evidence promotion gates (informs D-18/D-19).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Capability.rebuild` (`:none | :native_required | :companion_required`, enforce-keyed on `CapabilitySupportEntry`) — the source of truth `RebuildPolicy` derives capability-axis classification from. No new field needed.
- `SupportMatrix.action_classes()` (`ActionClassEntry` with `rebuild_required: boolean()`) — the co-truth validator the rebuild proof asserts against (no bespoke fixtures).
- `PromotionRuleEntry` already supports multi-entry, platform-specific, evidence-distinct rules (iOS/Android × StoreKit/Play Billing) — adding two Android shell rows follows the identical pattern.
- `@derive Jason.Encoder` + `to_map/1` + `new_*` + 1-arity accessor convention on `SupportMatrix` typed-row lists (`capability_families`, `change_classes`, `release_boundaries`) — the exact template for `RuntimeLineRow` + `rebuild_matrix/1`.
- `Doctor.Formatter` / `Doctor.JSONFormatter` section-rendering helpers (`format_change_classes/1`, `format_release_boundaries/1`) — the template for `format_rebuild_matrix/1` with structural human/JSON parity.

### Established Patterns
- Support truth never overclaims; CI/provider/device facts are evidence, backend/proof records are authority; advisory-until-promotion with explicit criteria.
- Criteria-as-code (`PromotionRuleEntry` data rows) over prose docs for promotion/demotion gates.
- Narrow additive public API on the shipped lib — new module + additive struct fields, no breaking signature changes, no manifest schema bump.
- Hermetic merge-blocking proof lanes per phase; human+JSON doctor parity by shared traversal.

### Integration Points
- New: `lib/crosswake/runtime_line/rebuild_policy.ex` (`classify/2`, `diff/2`, `rebuild_required?/1`).
- New struct: `Crosswake.Manifest.Types.RuntimeLineRow` in `lib/crosswake/manifest/types.ex`.
- Additive fields: `CapabilitySupportEntry.verification_method`, `PromotionRuleEntry.required_verification_method` (typed atoms from the D-09 enum), keep `evidence_class` string.
- `SupportMatrix`: `rebuild_matrix` field + `@rebuild_matrix_rows` + `rebuild_matrix/1`; two new `promotion_rules()` Android rows.
- `crosswake.doctor` + Formatter + JSONFormatter: `rebuild & compatibility matrix:` block + `evidence posture:` line under `release policy:`.
- New proof: `test/crosswake/proof/phase64_*` asserting (a) `classify` ↔ `action_classes()` parity, (b) no-new-field / unchanged `manifest_schema_version`, (c) CI-only-never-device render invariant, (d) Android promotion rows present + gated.
- Downstream: Phase 66 generators emit from these contracts; Phase 67 native shells mirror them + activate the merge-blocking JVM lane; Phase 69 the docs-contract parity gate + the actual Android `:supported` flip.

</code_context>

<specifics>
## Specific Ideas

- `RebuildPolicy` derivation rule, concrete: capability-axis change → `Capability.rebuild != :none ? {:rebuild_required, reason} : :ota_safe`; system-level (`sdk_floor_bump`, `privacy_manifest_entry`) → locked `@system_rebuild_classes`.
- Evidence enum verbatim: `:none | :provider_advisory | :jvm_hermetic | :emulator_advisory | :device_verified`. Android=`:jvm_hermetic`, iOS=`:device_verified` today.
- Doctor human sketch:
  ```
  release policy:
    native_runtime_version=1.0.0
    evidence posture: ios=device-verified  android=jvm-hermetic (CI only — no device proof)
    rebuild & compatibility matrix:
      runtime_line  ota_safe  rebuild_required  evidence_tier   capability_surface
      1.x           yes       no                jvm_hermetic    [app_info, haptics, permissions, files]
  ```
- Android promotion values: `minimum_consecutive_passes: 3`, `freshness_window: "current release branch, within 30 CI runs"`, `failure_budget: "zero consecutive failures; single failure resets counter"`.

</specifics>

<deferred>
## Deferred Ideas

- Native shell code, iOS/Android permission/entitlement + runtime-line generator templates, `ADOPT:` markers, placeholder/drift doctor checks, Xcode 26 CI — Phase 66.
- Native shell implementation mirroring these contracts, Android toolchain floor bumps (minSdk 30, compile/targetSdk 35), and the actual merge-blocking JVM-hermetic CI proof lane — Phase 67.
- Advisory emulator lane + capability-parity-locked device-UAT checklist (where `:emulator_advisory` / `:device_verified` evidence actually arrives) — Phase 68.
- Merge-blocking manifest↔shell↔guide↔doctor parity gate, guides parity-locked to live truth, the actual Android `:verification_required → :supported` promotion (only if criteria pass), `mix closeout.verify` — Phase 69.
- Diagnostic export seam (redaction allowlist + typed envelope, fire-and-forget HTTP) — Phase 65.
- Nyquist validation-ledger cleanup for Phases 59/60/62/63 (deferred tech debt routed to this milestone) — handle alongside v4.0 validation, not inside the Phase 64 contract work.

### Reviewed Todos (not folded)
None — no pending todos matched this phase (`todo.match-phase 64` returned 0).

</deferred>

---

*Phase: 64-Runtime-Line Policy Contract & Support-Truth Taxonomy*
*Context gathered: 2026-06-03*
