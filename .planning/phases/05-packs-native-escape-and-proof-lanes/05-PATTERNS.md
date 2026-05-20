# Phase 5: Packs, Native Escape, And Proof Lanes - Pattern Map

**Mapped:** 2026-05-17
**Focus:** route-policy-first extensions for packs, native escape seams, media/file transfer seams, and proof posture

## File Classification

| Likely File Touchpoint | Role | Data Flow | Closest Existing Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/policy/schema.ex` | model | request-response | itself | exact |
| `lib/crosswake/policy/route.ex` | model | request-response | itself | exact |
| `lib/crosswake/policy/validator.ex` | utility | request-response | itself | exact |
| `lib/crosswake/manifest/types.ex` | model | transform | itself | exact |
| `lib/crosswake/manifest/builder.ex` | service | transform | itself | exact |
| `lib/crosswake/manifest/validator.ex` | utility | request-response | itself | exact |
| `lib/crosswake/compatibility/compatibility.ex` | service | request-response | pack/version denial sections | role-match |
| `lib/crosswake/doctor/doctor.ex` | service | batch | Phase 3/4 posture sections | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | config | transform | itself | exact |
| `lib/crosswake/support_matrix/renderer.ex` | utility | transform | itself | exact |
| `script/verify_offline_contract.sh` | utility | batch | itself | exact |
| `script/verify_generated_ios_shell.sh` / `script/verify_generated_android_shell.sh` | utility | batch | themselves | exact |
| generated shell bridge/channel templates | component | request-response | `BridgeChannel.swift.eex` / `BridgeChannel.kt.eex` via doctor anchors | partial |
| generated shell activation templates | component | request-response | `ActivationCoordinator.swift.eex` / `ActivationCoordinator.kt.eex` via doctor anchors | partial |

## Main Reusable Anchors

### 1. Route policy extensions stay additive, typed, and normalized first
- `lib/crosswake/policy/schema.ex:10-53` is the pattern for adding DSL fields: declare a tight `NimbleOptions` schema, explicit enum/set validation, and `type_spec`.
- `lib/crosswake/policy/route.ex:9-20` and `:34-56` show the normalized contract shape: add new route fields to the struct, validate via `Schema`, then enforce cross-field invariants in a second pass.
- `lib/crosswake/policy/route.ex:63-84` is the key pattern for Phase 5 pack/media invariants: Crosswake allows schema validation first, then rejects combinations that violate runtime ownership truth.
- `lib/crosswake/policy/validator.ex:38-47` keeps semantic validation centralized after normalization. Follow the existing split: schema-level type checks in `Schema`, route-local semantic checks in `Validator`.

### 2. Manifest growth is route-first and typed end-to-end
- `lib/crosswake/manifest/types.ex:7-42` defines the root contract shared by manifest, doctor, and docs. Phase 5 additions should land here first if they are public contract.
- `lib/crosswake/manifest/types.ex:110-140` is the route-entry anchor. Existing pack support is route-local (`packs: []`), not a global blob.
- `lib/crosswake/manifest/builder.ex:21-38` is the canonical build path: derive support truth once, then emit `capability_registry` and `routes`.
- `lib/crosswake/manifest/builder.ex:51-73` shows the route-entry projection pattern. Phase 5 pack lifecycle data should likely be projected here from normalized route policy, not recomputed in shells.
- `lib/crosswake/manifest/validator.ex:59-118` is the manifest-side guardrail pattern: validate top-level truth, then validate each route against the registry and required fields.

### 3. Pack compatibility already exists as denial vocabulary; extend it instead of inventing a new failure surface
- `lib/crosswake/shell/activation.ex:13-36` and `:91-104` already treat `declared_pack_requirements` and `installed_packs` as first-class activation inputs.
- `lib/crosswake/compatibility/compatibility.ex:102-145` maps `:pack_version` failures to `:pack_incompatible` denial with shared recovery metadata.
- `lib/crosswake/compatibility/compatibility.ex:667-687` is the recovery pattern to copy: route denials carry explicit actions like `:retry`, `:update_app`, and optional safe fallback.
- `lib/crosswake/shell/fixtures.ex:13-28` and `:79-96` show how pack truth is exported into stable generated fixtures and denial fixtures.

### 4. Doctor/docs/support truth is canonical product surface, not commentary
- `lib/crosswake/doctor/doctor.ex:47-104` encodes platform posture as declarative file/content checks. This is the right shape for any new pack/native/media proof posture.
- `lib/crosswake/doctor/doctor.ex:106-131` shows the report assembly pattern: installer state, compiled manifest, shell posture, bridge posture, offline posture, support posture, one findings list.
- `lib/crosswake/support_matrix/support_matrix.ex:12-60` is the canonical support baseline. Statuses stay narrow: `:supported`, `:verification_required`, `:unsupported`.
- `lib/crosswake/support_matrix/support_matrix.ex:124-150` is the public-claim guardrail: support entries must stay narrow and proof-oriented.
- `lib/crosswake/support_matrix/renderer.ex:13-35` renders docs directly from canonical truth. Phase 5 support/docs should extend canonical data, not hand-author independent docs claims.

### 5. Proof lanes are explicit scripts plus repo-local docs assertions
- `script/verify_offline_contract.sh:8-16` is the current best analog for a hermetic repo-local proof lane: run a narrow test set, then `rg` for required docs posture strings.
- `test/crosswake/offline/proof_lane_test.exs:9-33` shows the contract-level proof pattern: assert manifest facts and doctor posture together.
- `test/crosswake/offline/proof_lane_test.exs:35-50` shows the docs-proof pattern: guides must contain the same narrow claims as support truth.
- `script/verify_generated_ios_shell.sh:15-18` and `:48-52`, plus `script/verify_generated_android_shell.sh:196-216`, are the generated-shell verification pattern: generate into a temp target, run real platform tooling, fail hard.

### 6. Existing native/media/file seams are intentionally narrow
- `lib/crosswake/bridge/contract.ex:9-12` fixes the bounded bridge command set at `app.info.get`, `haptics.impact`, and `files.pick`.
- `lib/crosswake/bridge/registry.ex:10-14` and `:44-69` show the manifest-backed allowlist pattern: command -> capability -> route declaration -> registry version.
- `guides/native_shell.md:47-54` and `:85-95` document the existing boundary: no silent fallback, no generic container behavior, and only the bounded file picker seam today.
- `test/support/router_fixtures.ex:69-75` and `:105-114` are the strongest native-screen analogs for Phase 5 planning: runtime `:native_screen`, sensitive security, route-local capability/packs/sync.

## Established Patterns To Reuse

- Add contract fields in this order: `policy/schema` -> `policy/route` -> `policy/validator` -> `manifest/types` -> `manifest/builder` -> `manifest/validator`.
- Keep runtime ownership explicit per route. Existing camera/native examples never hide a native flow inside a generic WebView fallback.
- Reuse existing denial vocabulary when possible. `pack_incompatible` already spans compatibility, activation, doctor fixtures, generated shells, and guides.
- Make proof posture canonical. Support claims should be derived from `SupportMatrix.canonical/1` and surfaced by doctor and rendered guides.
- Prefer one narrow proof lane per claim. The offline lane proves manifest truth, doctor truth, and docs truth in one bounded script.

## Likely Phase 5 File Touchpoints

- `lib/crosswake/policy/schema.ex`
- `lib/crosswake/policy/route.ex`
- `lib/crosswake/policy/validator.ex`
- `lib/crosswake/manifest/types.ex`
- `lib/crosswake/manifest/builder.ex`
- `lib/crosswake/manifest/validator.ex`
- `lib/crosswake/compatibility/compatibility.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/crosswake/support_matrix/support_matrix.ex`
- `lib/crosswake/support_matrix/renderer.ex`
- `guides/compatibility.md`
- `guides/support_matrix.md`
- `guides/native_shell.md`
- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`
- new Phase 5 repo-local proof script, likely mirroring `script/verify_offline_contract.sh`
- router fixtures and focused tests around native-screen pack/media routes

## No Close Analog Yet

| Missing Pattern | Evidence |
|---|---|
| explicit pack lifecycle contract (`install`, `available?`, `invalidate`) | current code only carries pack declarations/version checks and denial posture; no dedicated pack lifecycle module exists |
| explicit upload/download/media transfer contract | current public seam is bounded `files.pick`; there is no established upload/download contract module or proof lane |
| documented first native device-heavy escape beyond route classification | native-screen routing exists, but there is no first-class camera/media adapter contract yet |

## Planning Bias For Phase 5

- Extend existing route and manifest truth before adding shell-specific behavior.
- Treat packs like route-scoped contract data with typed lifecycle semantics, not opaque shell metadata.
- Keep the first native escape hatch narrow and named, closer to the `camera` test fixtures than to a generic adapter system.
- Make proof lanes prove docs and support posture, not just implementation behavior.
