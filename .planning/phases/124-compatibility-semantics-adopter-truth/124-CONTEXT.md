# Phase 124: Compatibility Semantics & Adopter Truth - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Final v14.0 phase. Two coupled deliverables:

1. **Reconcile compatibility negotiation to a single `>=` min-version-floor semantics across Elixir AND native** — kill the native exact-equality (`==`) footgun so an additive protocol/runtime bump no longer silently denies a valid request from an older shell. Elixir already floors; this phase brings native into line.
2. **Tell adopters the truth about upgrade cost** — derive a rebuild decision table, doctor action-sequence guidance, and changelog upgrade-impact labels from ONE canonical taxonomy, so an adopter can answer "do I have to rebuild and resubmit my app?" without reading a diff.

Covers requirements **COMPAT-01 through COMPAT-05**.

**The unifying architecture:** all of COMPAT-02/04/05 derive from the single change-class taxonomy that already ships in `Crosswake.SupportMatrix.change_class_entries/0` (four classes: `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, `native or companion rebuild required`). The rebuild decision table, the doctor guidance finding, and the changelog label vocabulary are all **consumers** of that one source — no parallel taxonomies, no minted synonyms. This is the milestone's drift-elimination thesis applied one level up from version literals to change-class semantics.

**Not in this phase:** changing the bridge protocol/envelope shape, adding bridge commands, restructuring the manifest, or any native-package publish (deferred until all v14.0 phases are green on main, then the publish step). No new version-axis values are introduced; current axes stay manifest_schema `1.0.0` / bridge_protocol `1.1.0` / native_runtime `1.0.0`.

</domain>

<decisions>
## Implementation Decisions

### A. Floor-negotiation semantics (COMPAT-01)

- **D-01: Direction = `shell_provides >= manifest_demands`.** Native must mirror Elixir's `compatible_version?(target, compatibility)` (compatibility.ex:616) exactly: the value the shell *provides* must be `>=` the floor the manifest/request *demands*. Worked examples: shell@1.2.0 serving request@1.1.0 → **allow** (the fix the roadmap wants); shell@1.1.0 facing demand@1.2.0 → **deny** (fail-closed — shell genuinely lacks the feature). This direction is what keeps the change fail-closed.

- **D-02: Floor ALL THREE version axes, not just bridge protocol.** Convert `bridge_protocol_version`, `native_runtime_version`, AND `manifest_schema_version` native checks from `==` to `>=` floor. **Rationale (corrects roadmap's literal "bridge protocol only" wording):** Elixir *already* floors all three (`compatibility.ex:283` schema, `:308` bridge, `:333` runtime). Leaving native `native_runtime_version` on `==` would make **native stricter than Elixir** — i.e., a NEW drift, the exact opposite of COMPAT-01's "reconcile to a single semantics" intent. Protocol **NAME** (`crosswake.bridge`) stays exact `==` — it is an identifier, not a version (no ordering relation).

- **D-03: FOUR native fix sites, not two.** The exact-match check exists at BOTH `BridgeChannel` (per-request) AND `ActivationCoordinator` (route activation), on EACH platform. Known sites: `BridgeChannel.swift:182-186`, `BridgeChannel.kt:101`, `ActivationCoordinator.kt:333` (+ the iOS `ActivationCoordinator` equivalent). **The "provides" and "demands" fields differ per site** (in `ActivationCoordinator`, demands come from `request`, provides from `manifest`/`session`; in `BridgeChannel`, demands come from the manifest-echoed `request`, provides from `session`). The planner must write each comparison so "provides ≥ demands" holds at that specific site — do NOT blind-copy one expression to the other.

- **D-04: Hand-port semver — ZERO native dependencies.** Port Elixir's `normalize_version/1` (split on `.`, zero-pad `"1"`→`"1.0.0"`, `"1.1"`→`"1.1.0"`) + a tri-state compare into a tiny `SemVer` helper (~30 LOC) in EACH native package. **Reject** adding swift-semver / a Kotlin semver lib: these are adopter-visible deps on published SwiftPM/Maven packages, and a third-party lib's semantics may not match Elixir's lenient zero-padding → new drift. The native port MUST replicate Elixir's **fail-closed fallback** (`provides == demands` on unparseable input, compatibility.ex:622-623) — deny rather than throw or allow on malformed versions.

- **D-05: Pin the port with behavioral conformance vectors.** Add new floor vectors to the canonical `bridge_contract_vectors.json` (via the Phase-121 gen task) exercising the floor BOTH ways (shell-newer→allow, shell-older→deny) so the cross-language Swift/Kotlin port is *behaviorally proven equal to Elixir*, not assumed. Drive them through BOTH native check sites in the NTEST harness. This extends Phase 123's vector model; it does not replace it.

- **D-06: Fold capability-version + pack-version floors into this phase (USER-CONFIRMED scope).** The native capability-version (`BridgeChannel.swift:215`, `:kt:130`, `installedVersion == requiredVersion`) and pack-version checks use the SAME raw-`==` bug while Elixir floors them (`compatibility.ex:373`, `:585`). User chose **"Fold in"** — convert these to `>=` floor in the same `SemVer` helper, with their own conformance vectors. This makes COMPAT-01 a clean sweep of EVERY native exact-match version footgun, leaving zero residual Elixir-vs-native drift. (Slightly exceeds COMPAT-01's literal axis wording — intentional and approved.)

### B. Rebuild-class taxonomy + decision table (COMPAT-02, COMPAT-03)

- **D-07: Do NOT add or rename change classes — the 4-class taxonomy already ships.** `Crosswake.SupportMatrix.change_class_entries/0` (support_matrix.ex:771-812) already defines all four classes including `compatibility-bump only` (the one the roadmap thought was missing). The real gap is: (a) no axis-change-type→class **mapping** table, and (b) compatibility.md is prose-first. Reconcile the roadmap's "3 rebuild classes" by **mapping**, not renaming: the 3 rebuild outcomes (`no-rebuild` / `compat-bump-only` / `native-rebuild`) are a derived view where `docs-only` + `core-only` both collapse to `no-rebuild`.

- **D-08: Canonical source = a new `Crosswake.SupportMatrix.rebuild_decision_table/0`** (list of structs: `axis`, `change_kind`, `rebuild_class`, `adopter_action`, `denial_signal`, `guide_anchor`). The **Renderer emits it into a new `## Rebuild Decision Table` section of `guides/support_matrix.md`**, placed right after `## Change Classes`. **It is auto-covered by the existing phase52 byte-parity merge-blocking guard** (`test/crosswake/proof/phase52_operator_truth_test.exs:151-159` asserts `support_matrix.md == Renderer.render(canonical())`) — NO new guard needed for support_matrix.md. **Reject** authoring a markdown table by hand inside support_matrix.md (instantly breaks the byte-parity guard) and **reject** generating it via `mix crosswake.contract.gen` (wrong generator boundary — that task is bridge-version-derived fixtures; rebuild mapping is SupportMatrix truth).

- **D-09: The load-bearing axis mapping (lock these rows).**
  | Axis | Additive (minor) | Breaking (major) |
  |---|---|---|
  | `manifest_schema_version` | `compat-bump-only` | `native-rebuild` |
  | `bridge_protocol_version` | `compat-bump-only` | `native-rebuild` |
  | `native_runtime_version` | **`native-rebuild`** (no additive-without-rebuild row — it lives in the binary) | `native-rebuild` |
  | capability required-version | `compat-bump-only` if core-owned; `native-rebuild` if native_screen/companion | `native-rebuild` |
  | docs / wording | `no-rebuild` (`docs-only`) | n/a |
  | core Elixir behavior inside shipped axes | `no-rebuild` (`core-only`) | → forces an axis bump (see axis rows) |

  The asymmetry MUST be stated in the doc: `manifest_schema`/`bridge_protocol` additive moves are `compat-bump-only` *precisely because* D-01/D-02 made the native floor `>=`. `native_runtime` has no such row.

- **D-10: compatibility.md leads with a JTBD decision table, prose demoted below it.** New lead section `## Do I need to rebuild? (start here)` with columns `Change type | Axis touched | Rebuild class | Adopter action | Denial signal if you skip it | Guide anchor`. The `Denial signal` column ties each skipped action to the concrete fail-closed denial code the shell emits (`compatibility_mismatch`, `inactive_route`, `undeclared_capability`, `pack_incompatible`) — this is the non-vacuous "what breaks if you ignore this" column and Crosswake's differentiator over prose-only upgrade guides. The table **mirrors** the canonical `rebuild_decision_table/0` (uses the rebuild-class column header, NOT a support-status header) — it does NOT duplicate the support matrix. Preserve existing sections (`## Compatibility Axes`, `## Companion Compatibility Contract`, `## Release Choreography`, runtime-line rules) and their cross-references; respect the existing "no second support matrix" boundary that `adopter_profiles_test` enforces.

- **D-11: New `test/crosswake/guides/compatibility_test.exs`** mirroring the `adopter_profiles_test` idiom (`File.read!` + `count_occurrences` of a locked joined header + presence asserts). Two assertions are the teeth: (1) **table-before-first-prose ordering** (`String.index(table_header) < String.index("Crosswake keeps runtime ownership")`) — enforces decision-table-first, the criterion most likely to silently regress; (2) **mirror-agrees-with-renderer** (each rebuild-class name in compatibility.md also appears in `Renderer.render(canonical())`) — the anti-drift assertion. Plus: all three axes present in the table region, all three rebuild-class names present, the `native_runtime`→`native-rebuild` asymmetry locked, and a `refute` of any support-status table header. Also extend phase52 to assert the new `## Rebuild Decision Table` section is present in rendered output.

### C. Doctor mismatch guidance (COMPAT-04)

- **D-12: NEW advisory check `compatibility_rebuild_guidance`** in `lib/crosswake/doctor/publish_readiness.ex`, added to `build_checks/0`. Do **NOT** extend `contract_version_parity_check` — it keeps its single responsibility (committed-surface drift detection + the one merge-blocking `:error` voice).

- **D-13: Honest two-tier severity (NEVER `:error`).** Static **advisory** baseline always present: full change-class taxonomy + `compatibility_mismatch` denial vocabulary + ordered action sequence + `guides/compatibility.md` link, with explicit microcopy stating *"doctor cannot observe a live shell's denial — this is guidance, not a detected failure."* **Elevates to `:warning`** only when it shares `contract_version_parity_check`'s committed-surface drift detection (name the detected class: `native or companion rebuild required`). It must never claim it saw a live denial, and never re-block (parity check owns the blocking voice). This honors the project's honest-evidence DNA: advise what you can't prove; claim only what you detected.

- **D-14: Single-source the action sequence.** Derive per-class guidance from `SupportMatrix.change_class_entries/0` `.adopter_action`; add ONE `action_sequence_for/1` that expands the `native or companion rebuild required` class into the discrete ordered steps (regenerate shell → rebuild native app → resubmit App Store/Play Store → coordinated deploy). Per-class subset is then correct for free: `docs-only`/`core-only` → no rebuild/resubmit; `compat-bump-only` → coordinated core redeploy but no native rebuild; `native-rebuild` → full 4 steps. **Extract `contract_version_parity_errors/1`** from the existing parity check so detector and adviser share one detection function (can never disagree).

- **D-15: Output shape.** Numbered imperative prose (`1) … 2) …`) in `message`/`hint` for humans; ordered `details.active_action_sequence` + `details.change_class_guidance` arrays for machines (the existing `JSONFormatter` passes `details` through — no formatter changes needed). `docs_reference: "guides/compatibility.md"`. Microcopy per flutter/brew-doctor lesson: emit the literal next command (`mix crosswake.contract.gen`) then the ordered steps.

### D. Changelog upgrade-impact label (COMPAT-05)

- **D-16: `### Upgrade Impact` subsection, FIRST under each `## [version]` heading** (before `### Added`/`### Notes`). Keep-a-Changelog-native (per-release category, not per-line tags); answers the JTBD at the top of each entry; cleanest grep target. Note: release-please IS wired but runs `skip-changelog: true`, so CHANGELOG stays hand-authored — the label is a hand-authoring + docs-contract concern only (no conventional-commit footer pipeline).

- **D-17: Worst-case headline + per-bullet exceptions when mixed.** The subsection headlines the release's HIGHEST-impact change class (fail-safe toward "rebuild"); when a release bundles multiple classes, it then enumerates which bullets are actually lower-impact. A release mixing core-only + rebuild changes MUST headline `native or companion rebuild required` and list the core-only exceptions.

- **D-18: Reuse the 4 canonical change-class strings VERBATIM** — no minted short tokens (a second synonym set is exactly the desync to avoid). The strings: `docs-only`, `core-only/no native rebuild`, `compatibility-bump only`, `native or companion rebuild required`. Keep `lib/crosswake/runtime_line/rebuild_policy.ex`'s finer atoms (`:ota_safe`, `{:rebuild_required, _}`) OUT of the CHANGELOG — different axis, do not cross the streams.

- **D-19: Honest enforcement (extend `test/crosswake/guides/release_boundaries_test.exs`).** Two checks, each only asserting what is mechanically decidable: (1) **structural** — every non-historical `## [x.y.z]` release has exactly one `### Upgrade Impact` block (reuse the existing `historical_changelog_line?/1` exemption for old entries — retro-labeling `[0.1.2]`/`[0.1.0]` is optional); (2) **vocabulary/legend parity** — any impact label present is drawn from the locked 4-string set AND those strings still exist verbatim in support_matrix.md's Change Classes table (share the SAME locked list the guides test uses, so a rename breaks guide test + changelog test together). **Do NOT** attempt to detect "this entry touches the contract but lacks a label" — unprovable from prose, guaranteed to cry wolf. Intent gate (choosing the correct class) is a human review gate, documented in a new `CONTRIBUTING.md`.

### Claude's Discretion
- Exact native `SemVer` helper file names/locations and method signatures; whether the floor comparison is expressed as `compare(...) != .orderedAscending` vs a `>=` operator overload (provided it matches Elixir's tri-state + fail-closed fallback); the precise new vector ids/descriptions and how many floor vectors per axis (provided both allow + deny directions are proven for every floored axis incl. capability/pack per D-06); the exact `RebuildDecisionEntry`/struct field names and Renderer section formatting (provided phase52 byte-parity holds); the exact column ordering/wording of the compatibility.md JTBD table (provided D-10's columns + denial-signal column + table-first ordering hold); the `compatibility_rebuild_guidance` check's exact `code`/`category`/`details` keys (provided D-12..D-15 hold); the precise `### Upgrade Impact` wording template and whether to retro-label historical CHANGELOG entries (D-19 makes it optional); whether CONTRIBUTING.md is new or a section added to an existing contributor doc — all planner/researcher discretion, provided D-01..D-19 hold.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone planning
- `.planning/ROADMAP.md` — Phase 124 goal + success criteria 1–5 (floor semantics; per-axis rebuild-class mapping in one source guarded by docs-contract test; decision-table-first support matrix + compatibility guide; doctor action-sequence; changelog upgrade-impact label). **Note:** SC-1 literal wording names only bridge protocol; D-02 floors all three axes for Elixir symmetry (documented deviation — correct read of "reconcile to a single semantics").
- `.planning/REQUIREMENTS.md` — COMPAT-01..05 definitions; phase-ordering note (compat after native-proof, before publish-last).
- `.planning/phases/121-canonical-contract-source/121-CONTEXT.md` — canonical = the Elixir constant `Crosswake.Bridge.Contract.version()` (`1.1.0`); gen task = `mix crosswake.contract.gen`. Authoritative over older research where they conflict.
- `.planning/phases/122-drift-guards/122-CONTEXT.md` — GUARD-* parse-assert + generate-and-diff + register-script pattern; the doctor finding sibling pattern (`contract_version_parity`).
- `.planning/phases/123-native-package-behavioral-proof/123-CONTEXT.md` — the `bridge_contract_vectors.json` vector model + `session_override`/`request_override` schema + native test harness this phase EXTENDS with floor vectors (D-05/D-06); the hermetic-blocking / native-advisory CI split.

### Research (read for principles; treat older CI/version-constant claims as superseded by 121–123 reality)
- `.planning/research/REC-VERSIONING.md` — three-axis version model + floor-vs-exact rationale (COMPAT-01).
- `.planning/research/REC-CHANGELOG.md` — directly relevant to COMPAT-05 label format.
- `.planning/research/ARCHITECTURE.md` — three-axis model; native version fields are manifest-derived (not constants); generate-and-diff discipline.
- `.planning/research/v13-support-truth-guides.md` — the support-matrix-as-generated-from-code + docs-contract-test pattern (COMPAT-02/03).
- `.planning/research/v13-proof-path-docs.md` — doctor proof-path / honest-evidence framing (COMPAT-04).
- `.planning/research/PITFALLS.md` — anti-vacuous / parse-not-grep / honest-detection (shapes all docs-contract + doctor decisions).
- `prompts/crosswake-elixir-oss-dna.md` — DX/values (single-source-of-truth, dependency minimalism, honest evidence) that drove D-04/D-08/D-13/D-18.

### COMPAT-01 — code to change (floor reconciliation)
- `lib/crosswake/compatibility/compatibility.ex` — `compatible_version?/2` (:616) + `normalize_version/1` (:625) = the canonical floor + fail-closed fallback (:622-623) to port; axis validators `validate_manifest_schema` (:283), `validate_bridge_protocol` (:308), `validate_native_runtime` (:333) confirm Elixir already floors all three; capability/pack floors at :373/:585 (D-06).
- `lib/crosswake/bridge/contract.ex:10` — `@version "1.1.0"`, the version authority.
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift:181-186` (version/runtime `==`), `:215` (capability `==`) — convert to floor; add `SemVer` helper.
- `packages/crosswake-shell-core-android/.../BridgeChannel.kt:101` (version/runtime `==`), `:130` (capability `==`) — convert to floor; add `SemVer` helper.
- `packages/crosswake-shell-core-android/.../ActivationCoordinator.kt:333` + the iOS `ActivationCoordinator.swift` equivalent — the SECOND fix site per platform (D-03).
- `lib/mix/tasks/crosswake.contract.gen.ex` — extend the vector set with floor + capability/pack vectors (D-05/D-06); `test/fixtures/bridge_contract_vectors.json` + the native copies are regenerated outputs.

### COMPAT-02/03 — rebuild decision table
- `lib/crosswake/support_matrix/support_matrix.ex:771-812` — `change_class_entries/0` (the canonical 4-class taxonomy); add `rebuild_decision_table/0` near it.
- `lib/crosswake/support_matrix/renderer.ex` (~:57 `render/1`, `change_class_section/1` ~:155) — add the `## Rebuild Decision Table` section.
- `test/crosswake/proof/phase52_operator_truth_test.exs:151-159` — the byte-parity merge-blocking guard that auto-covers the new section.
- `guides/support_matrix.md` (Change Classes table ~:124) — gains the rendered section.
- `guides/compatibility.md` — restructure decision-table-first (lead prose at :1-7 moves down; prose-only "rebuild" content ~:66-84 replaced by the JTBD table).
- `test/crosswake/guides/adopter_profiles_test.exs` — the docs-contract test idiom to mirror; enforces the "no second support matrix" boundary.
- New: `test/crosswake/guides/compatibility_test.exs`.

### COMPAT-04 — doctor guidance
- `lib/crosswake/doctor/publish_readiness.ex` — `generator_coordinate_parity_check` (~:537) + `contract_version_parity_check` (~:594) siblings to mirror; `result_check/1` helper; `ReadinessCheck` carries a `rebuild_requirement` map field. Add `compatibility_rebuild_guidance_check`, `action_sequence_for/1`, extract `contract_version_parity_errors/1`, `alias Crosswake.Shell.Denial`.
- `lib/crosswake/doctor/check.ex` — the `%Check{}` struct (severity/code/message/hint/check/details).
- `lib/crosswake/doctor/doctor.ex`, `lib/mix/tasks/crosswake.doctor.ex`, the `Formatter`/`JSONFormatter` under `lib/crosswake/doctor/` — finding rendering (no changes needed; details pass through).
- `lib/crosswake/shell/denial.ex` — `reasons/0` = the denial vocabulary (`compatibility_mismatch`, etc.).
- `lib/crosswake/runtime_line/rebuild_policy.ex` — the manifest-derivation classifier; docstring confirms it is "doctor input, NOT a release-gate oracle" (reinforces D-13's advise-don't-claim).

### COMPAT-05 — changelog label
- `CHANGELOG.md` — Keep-a-Changelog, hand-authored; add `### Upgrade Impact` blocks.
- `test/crosswake/guides/release_boundaries_test.exs` — already locks the 4 change-class strings (~:28-47) and has CHANGELOG helpers (`stale_package_versions/1`, `historical_changelog_line?/1`); extend with the two D-19 assertions.
- `.github/workflows/release-please.yml` + `release-please-config.json` — confirm `skip-changelog: true` (CHANGELOG is hand-authored).
- New (or extended): `CONTRIBUTING.md` — the human intent-gate convention.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Elixir floor logic is the spec to port** — `compatible_version?/2` + `normalize_version/1` are ~25 lines; the Swift/Kotlin ports are faithful translations, behaviorally pinned by new vectors.
- **The change-class taxonomy already ships** (`change_class_entries/0`) with all four classes — COMPAT-02/04/05 consume it, they don't define it.
- **The byte-parity generated-docs pattern** (`SupportMatrix → Renderer → support_matrix.md`, guarded by phase52) is the single-source machinery the rebuild decision table plugs into for free.
- **Doctor sibling checks** (`contract_version_parity_check`, `generator_coordinate_parity_check`) are near-copy-paste templates for the new advisory check; `ReadinessCheck.rebuild_requirement` already exists for structured rebuild metadata.
- **The Phase-123 vector harness** (`bridge_contract_vectors.json` + native suites) extends to prove the floor across languages.

### Established Patterns
- **One canonical source → generated/mirrored surfaces → docs-contract or byte-parity test.** Applied to the rebuild decision table (D-08), the compatibility.md mirror (D-11), and the changelog vocabulary (D-19).
- **Honest evidence:** claim only what you detect; advise the rest. Drives D-13 (doctor never claims a live denial it can't see) and D-19 (no "touches the contract" intent-detection).
- **Hermetic-blocking, native-advisory.** Floor changes are proven by hermetic Elixir vector tests (blocking) + native suites (Android blocking JVM / iOS advisory) per Phase 123 topology — no new CI gate expected; existing lanes cover it.
- **Single-source-or-it-drifts:** every version literal lives once; D-04 refuses native semver deps and D-18 refuses minted changelog tokens for the same reason.

### Integration Points
- `mix crosswake.contract.gen` → vector set grows (floor + capability/pack vectors); GUARD-02 generate-and-diff auto-covers the new outputs.
- `Crosswake.SupportMatrix` → gains `rebuild_decision_table/0`; Renderer → gains a section; phase52 guard → auto-covers it.
- `guides/compatibility.md` → restructured decision-table-first; new `compatibility_test.exs` guards it; the rebuild-class names mirror the renderer output.
- `mix crosswake.doctor` → gains an advisory `compatibility_rebuild_guidance` finding (warning on detected drift); shares the parity check's detector.
- `CHANGELOG.md` → gains `### Upgrade Impact`; `release_boundaries_test.exs` guards structure + vocabulary; `CONTRIBUTING.md` documents the intent gate.

</code_context>

<specifics>
## Specific Ideas

- **Headline guarantee (COMPAT-01):** "additive bump no longer denies a valid older-shell request" is achieved specifically by the `provides >= demands` direction (D-01). The fail-closed safety property and the bugfix are the SAME comparison read in opposite directions — get the direction wrong (request >= session) and you fail OPEN (older shell accepts requests for features it lacks).
- **The `Denial signal` column** in the compatibility.md JTBD table is the differentiator: Crosswake fails closed with NAMED denial codes, so "what breaks if you skip this action" is concrete (`compatibility_mismatch`, `pack_incompatible`, …), not the prose hand-waving of Stripe/Ember upgrade guides.
- **Worst-case-wins changelog headline (D-17):** a mixed release headlines `native or companion rebuild required` and enumerates the core-only exceptions — honest toward "rebuild," never under-reporting.
- **`native_runtime_version` has no additive-without-rebuild row (D-09):** it ships in the binary; every move is `native-rebuild`. This asymmetry is load-bearing and must be explicit in the doc + locked by the test.

</specifics>

<deferred>
## Deferred Ideas

- **Pre-release / build-metadata version semantics** (`1.1.0-rc.1`, `+build`) for the contract axes are unspecified today. Either the native port matches Elixir's `Version.compare` behavior, or the planner declares these axes are always plain `MAJOR.MINOR.PATCH` and rejects pre-release at the contract level (recommend a conformance vector or an explicit non-goal — flagged for planner, not a new capability).
- **Pre-publish fixture-verification gate** (`mix crosswake.contract.verify_published_fixtures` blocking native-package publish on divergence) — belongs to the v14.0 publish step after all four phases are green.
- **Auto-deriving the changelog label from commit/diff analysis** (conventional-commits `BREAKING CHANGE:` pipeline) — explicitly out; `skip-changelog: true` + the human intent-gate is the honest boundary. Future automation only.
- **Outstanding milestone carry-overs (not this phase):** MIRROR_PUSH_TOKEN scope still unexercised; 2 unrun `register-*-gate.sh` branch-protection PATCHes (human/harness-gated); 4 pre-existing docs-debt `mix test` failures (CHANGELOG/guides/mix.exs) — candidates to clean up during this phase's CHANGELOG/guide work if convenient, but not in COMPAT scope.

None of these are scope creep into 124 — they are later-ordered steps or planner research-flags.

</deferred>

---

*Phase: 124-compatibility-semantics-adopter-truth*
*Context gathered: 2026-06-20*
