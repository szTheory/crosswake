# Phase 18: Operational Diagnostics and Enforcement - Research

**Researched:** 2026-05-21
**Domain:** Crosswake route-policy enforcement, doctor diagnostics, support-truth rendering, and proof posture for v3.1 capability families. [VERIFIED: codebase grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim phase constraints copied from `.planning/phases/18-operational-diagnostics-and-enforcement/18-CONTEXT.md`. [VERIFIED: codebase grep]

### Locked Decisions

#### Route-local enforcement posture
- **D-01:** Keep the public route-policy surface family-first for ordinary capabilities. Phoenix authors should continue declaring semantic family vocabulary such as `app_info`, `haptics`, `share`, `permissions.status`, and `notification_token`, not bridge transport ids.
- **D-02:** Keep enforcement internals command-aware and fail-closed. The bridge registry and shell dispatch path should continue validating the concrete bounded command at runtime even when the route policy stays semantic.
- **D-03:** Preserve `file_picker` as an explicit transfer-backed exception rather than a plain family-only capability. `files.pick` remains authorized only through a declared route-local `transfer_id` whose seam validates as `source: :native_picker` and fits the typed transfer contract.
- **D-04:** `deep_link` remains manifest-first activation truth, not a route-local bridge command. Phase 18 must not pull `deep_link` into the bounded bridge allowlist or make route capabilities responsible for external-entry authority.
- **D-05:** Route policy, manifest metadata, doctor guidance, and support docs should explain the model as: semantic family declaration for normal bounded capabilities, plus explicit transfer-backed authority where a family would otherwise imply ambient file power.
- **D-06:** Avoid exposing bridge command ids as the primary DSL truth. Command names may evolve or multiply; the public policy contract should stay stable and family-first unless a later phase intentionally ships a family with multiple materially different public operations.

#### Validator and denial semantics
- **D-07:** Policy validation should reject unknown or unsupported family vocabulary at compile time, while runtime bridge lookup should remain the fail-closed authority for concrete command, active-route, origin, compatibility, and transfer-seam checks.
- **D-08:** Runtime denials should keep route- and operator-facing reasons explicit rather than generic. Missing route declaration, missing transfer seam, wrong transfer intent, unsupported shell capability, incompatible runtime line, and external-entry denials should remain distinguishable in doctor and proof surfaces.
- **D-09:** `share` should be normalized into the same family-first enforcement story as other ordinary bounded capabilities. The system should not keep drifting between public family ids and command ids in ways that force adopters to think in protocol details.

#### Doctor severity model
- **D-10:** Keep a mixed blocking-and-advisory doctor posture. `mix crosswake.doctor` should block on contract, compatibility, rebuild-truth, and declared-support dishonesty; it should use warning or advisory findings for environment-sensitive or point-in-time operational state.
- **D-11:** Blocking findings should include at least: unsupported route/runtime usage, undeclared capability authority on a route, missing required transfer-backed declaration for `file_picker`, shell capability mismatches for declared core capabilities, missing static native permission/config prerequisites, missing required companion compatibility truth, and rebuild-sensitive runtime-line mismatches.
- **D-12:** Advisory or warning findings should include at least: pending environment-sensitive proof lanes, user-denied permission state snapshots, transient provider token unavailability, and missing local workstation tooling when the public contract can still be described honestly without claiming support has already been proven there.
- **D-13:** Doctor output should keep remediation copy concrete and next-step oriented. Findings should tell operators what to add, rerun, declare, or rebuild rather than only naming a failed check.
- **D-14:** Downstream planning may introduce an explicit doctor taxonomy table or helper module so severity assignment does not drift across capability families over time.

#### Support-matrix and proof-truth posture
- **D-15:** Support truth should become more explicit about three different things: platform baseline support, runtime-line or proof-lane verification state, and capability-family posture. Crosswake should not collapse those into one coarse label where doing so hides pending proof gaps.
- **D-16:** Keep baseline host/platform support claims where earlier proof still legitimately holds, but represent the unresolved Android Phase 17 JVM lane as `verification_required` at the relevant runtime or capability-proof layer until that proof actually runs.
- **D-17:** Advisory and companion-heavy families should be rendered distinctly from merge-blocking core family truth. `notification_token` in particular should not read as equally proven simply because it is implemented; its support posture must stay aligned with companion and proof-class constraints.
- **D-18:** Do not solve proof-truth gaps with caveat-only prose. If a support statement is materially weaker because proof is still pending, the status model or rendered structure should show that directly.
- **D-19:** Downstream agents may choose the smallest schema or rendering change that cleanly separates baseline support from capability-proof truth, but they should prefer explicit status structure over footnote sprawl.

#### Final integrated proof shape
- **D-20:** Use a layered proof strategy rather than one monolithic “everything in one story” acceptance flow.
- **D-21:** Keep contract and invariant checks in ExUnit-level manifest, validator, registry, doctor, and support-matrix tests. Those are the fast, merge-blocking truth anchors.
- **D-22:** Keep platform-specific shell tests targeted and capability-aware rather than trying to move all confidence into one expensive end-to-end lane.
- **D-23:** Add one narrow integrated acceptance slice for the bounded bridge families that belong together operationally: `app_info`, `haptics`, `share`, `permissions.status`, `notification_token`, and `file_picker`.
- **D-24:** Keep `deep_link` proven in an activation-first acceptance slice rather than forcing it into the bounded-bridge acceptance flow. This preserves the architecture boundary that external entry is shell activation truth, not bridge authority.
- **D-25:** The integrated proof should be believable and route-natural, not a synthetic demo lane that exists only to touch every capability in one user story. Preserve failure isolation and support honesty over demo neatness.

#### Delegation posture
- **D-26:** Shift ordinary implementation choices left within GSD for this phase. Researcher, planner, and implementer agents should not re-ask about exact helper names, formatter layout, test file names, or support-table column naming unless a choice would materially change public support claims, denial vocabulary, or route-owner boundaries.
- **D-27:** The only decisions worth escalating back to the user are ones that would materially widen capability authority, weaken fail-closed behavior, or overclaim public support before proof exists.

### Claude's Discretion

No separate `## Claude's Discretion` section exists in `18-CONTEXT.md`. [VERIFIED: codebase grep]

### Deferred Ideas (OUT OF SCOPE)

- Public route-policy declaration by concrete bridge command id remains deferred unless a later phase intentionally introduces multi-operation families that justify it.
- Broad capability-inspection UI or operator dashboards remain deferred; this phase should sharpen truth and diagnostics first.
- Any change that would make `file_picker` a generic filesystem authority rather than a transfer-backed seam remains explicitly deferred.
- Any attempt to widen `notification_token` into permission-request orchestration remains deferred.
- A single monolithic “all capabilities in one hero demo” proof lane remains deferred unless a future milestone needs it for a public showcase rather than support truth.
</user_constraints>

<phase_requirements>
## Phase Requirements

No canonical requirement description rows for `OPS-ALLOWLIST`, `OPS-DOCTOR`, or `OPS-SUPPORT` were found outside the Phase 18 roadmap entry, so the descriptions below are taken from the Phase 18 plan titles and goal. [VERIFIED: codebase grep]

| ID | Description | Research Support |
|----|-------------|------------------|
| OPS-ALLOWLIST | Add route-local allowlist enforcement for all new v3.1 capability keys in the policy engine. [VERIFIED: codebase grep] | Family-first DSL stays public, registry stays command-aware, and `file_picker` remains transfer-backed only. [VERIFIED: codebase grep] |
| OPS-DOCTOR | Extend `mix crosswake.doctor` to handle missing OS permissions and shell capability mismatches. [VERIFIED: codebase grep] | Doctor already has severity tiers, proof posture, release-policy snapshots, and shell artifact checks; Phase 18 should extend those rather than replace them. [VERIFIED: codebase grep] |
| OPS-SUPPORT | Update support truth and fail-closed verification for the seven v3.1 capability families. [VERIFIED: codebase grep] | Support matrix already derives capability rows from manifest metadata, but it currently collapses baseline and proof truth too coarsely for the pending Android lane. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 18 is not a greenfield capability phase. The core bounded-capability implementations already exist across `Crosswake.Policy.Validator`, `Crosswake.Manifest.Builder`, `Crosswake.Bridge.Registry`, the iOS/Android `BridgeChannel` implementations, and their tests. The planning problem is to make those seams operationally coherent: public family vocabulary in policy, concrete command enforcement in runtime lookup, explicit doctor findings, and support output that does not overclaim proof status. [VERIFIED: codebase grep][VERIFIED: mix test]

The highest-risk drift points are already visible. `guides/bridge.md` still lists an older bounded command set and omits `notifications.token.get` and `share.invoke`, while the registry and tests already allow both; `deep_link` is rendered in support truth as a capability-family row even though the phase context says it must stay activation-first and outside the bridge allowlist; and current doctor support posture is binary at the top level (`supported` vs `verification_required`) based only on shell proof hooks, which is too coarse for the pending Android Phase 17 lane and the advisory posture of `notification_token`. [VERIFIED: codebase grep]

The plan should therefore focus on truth consolidation, not new abstractions: tighten policy vocabulary normalization, make doctor severity and remediation deterministic, split baseline support from capability-proof state in support rendering, and add layered proof that keeps `deep_link` in activation tests and bounded families in bridge tests. [VERIFIED: codebase grep]

**Primary recommendation:** Use manifest-derived capability metadata as the single source of operational truth, then teach validator, doctor, support matrix, guides, and proof lanes to render that truth consistently and fail closed. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Public capability declaration (`app_info`, `haptics`, `share`, `permissions.status`, `notification_token`) | API / Backend | Frontend Server (SSR) | Route policy is compiled in Elixir and validated before runtime; public family vocabulary belongs to the host app contract, not to shell protocol details. [VERIFIED: codebase grep] |
| `file_picker` authority | API / Backend | Browser / Client | The route declares the transfer seam, but actual command execution is authorized only when a route-local `transfer_id` matches a typed inbound `native_picker` seam. [VERIFIED: codebase grep] |
| Concrete bridge command allowlisting | Frontend Server (SSR) | Browser / Client | `Crosswake.Bridge.Registry` resolves manifest-backed command entries and the native shells reject undeclared or incompatible commands before side effects run. [VERIFIED: codebase grep][VERIFIED: mix test] |
| `deep_link` entry authority | Frontend Server (SSR) | Browser / Client | Phase context and guides keep `deep_link` as manifest-first activation truth, not as a route-local bridge command. [VERIFIED: codebase grep] |
| Doctor diagnostics and release-truth rendering | API / Backend | — | `Crosswake.Doctor` and `Crosswake.SupportMatrix` are Elixir-side truth surfaces that inspect manifests, shells, proof hooks, and support metadata. [VERIFIED: codebase grep][VERIFIED: mix test] |
| Proof-lane execution for iOS/Android shells | Browser / Client | API / Backend | Shell tests prove capability behavior inside checked-in native hosts, while ExUnit remains the merge-blocking truth anchor for contract invariants. [VERIFIED: codebase grep][VERIFIED: mix test] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` project target; local runtime on this machine is OTP 28 / Elixir 1.19-compatible. [VERIFIED: codebase grep][VERIFIED: environment command] | Host language for policy compilation, manifest building, doctor checks, and support truth. [VERIFIED: codebase grep] | All Phase 18 operational surfaces are implemented in Elixir modules and exercised via ExUnit/Mix. [VERIFIED: codebase grep][VERIFIED: mix test] |
| Phoenix | `1.8.7` in `mix.lock`. [VERIFIED: codebase grep] | Route DSL substrate and host integration surface. [VERIFIED: codebase grep] | Route policy, managed router fixtures, and host-facing compile-time validation are Phoenix-first by project design. [VERIFIED: codebase grep] |
| Phoenix LiveView | `1.1.30` in `mix.lock`. [VERIFIED: codebase grep] | Test fixtures and server-owned route model. [VERIFIED: codebase grep] | The phase must preserve explicit server-owned route behavior rather than widen native authority. [VERIFIED: codebase grep] |
| Jason | `1.4.5` in `mix.lock`. [VERIFIED: codebase grep] | JSON formatting for doctor/install manifest/report surfaces. [VERIFIED: codebase grep] | Doctor and manifest tooling already use JSON artifacts and formatters; there is no need for a second encoding path. [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Mix / ExUnit | Built-in; local `mix` available. [VERIFIED: environment command] | Fast merge-blocking contract, registry, doctor, and support tests. [VERIFIED: mix test] | Use for validator, manifest, registry, doctor, and support-matrix invariants first. [VERIFIED: codebase grep] |
| Swift / Xcode | Swift 6.2 and Xcode 26.0.1 available locally. [VERIFIED: environment command] | iOS shell proof and targeted bridge behavior tests. [VERIFIED: codebase grep] | Use for iOS shell denial/allowlist coverage and the integrated bounded-family slice. [VERIFIED: codebase grep] |
| Android shell tests | Project has checked-in Android shell sources and tests, but local Java is missing. [VERIFIED: codebase grep][VERIFIED: environment command] | Android proof for bridge denials and final support truth. [VERIFIED: codebase grep] | Use in CI or a Java-enabled workstation until local Java exists. [VERIFIED: STATE.md][VERIFIED: environment command] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Family-first route DSL | Command-first route declarations | Rejected by phase decisions because it leaks transport details into the public host contract. [VERIFIED: codebase grep] |
| Manifest-derived support rows | Hand-maintained support tables per capability | Rejected because `SupportMatrix.capability_family_entries/1` already derives rows from manifest metadata and avoids duplicated truth. [VERIFIED: codebase grep] |
| Layered proof | One end-to-end hero scenario | Rejected because Phase 18 explicitly keeps `deep_link` in activation proof and bounded families in bridge proof to preserve boundary honesty. [VERIFIED: codebase grep] |

**Installation:**
```bash
mix deps.get
```

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix route policy DSL
  -> Policy.Validator compile-time family checks
  -> Manifest.Builder capability catalog + route entries + transfer seams
  -> SupportMatrix capability-family rows derived from manifest metadata
  -> Bridge.Registry runtime lookup
       -> capability path for app_info/haptics/share/permissions.status/notification_token
       -> transfer-backed path for files.pick via transfer_id + native_picker seam
  -> Native shell BridgeChannel / ActivationCoordinator
       -> allow or deny with explicit reason
  -> Doctor
       -> inspect manifest + shell artifacts + proof hooks + support posture
  -> Guides / support rendering
       -> publish baseline support, proof state, prerequisites, denial, fallback, rebuild truth
```

### Recommended Project Structure

```text
lib/crosswake/
├── policy/           # public route vocabulary and compile-time validation
├── manifest/         # manifest and capability metadata truth
├── bridge/           # command-aware runtime allowlist and request models
├── doctor/           # diagnostics, severity, remediation, formatting
└── support_matrix/   # canonical support and release-truth rendering

examples/
├── ios_shell_host/   # activation and bridge proof on iOS
└── android_shell_host/ # activation and bridge proof on Android

guides/               # public truth surfaces that must stay derived from code
test/                 # ExUnit truth anchors
```

### Pattern 1: Family-First DSL, Command-Aware Runtime
**What:** Keep route policy semantic and stable, but resolve concrete bounded commands only at registry/shell runtime. [VERIFIED: codebase grep]
**When to use:** All ordinary bounded capabilities in this phase. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: lib/crosswake/bridge/registry.ex
@capability_commands %{
  "app.info.get" => "app_info",
  "haptics.impact" => "haptics",
  "permissions.status" => "permissions.status",
  "notifications.token.get" => "notification_token",
  "files.pick" => "file_picker",
  "share.invoke" => "share"
}
```

### Pattern 2: Transfer-Backed Exception for `file_picker`
**What:** Treat `files.pick` as a runtime command that is only legal when a route declares a matching `transfer_id` with an inbound `native_picker` seam. [VERIFIED: codebase grep][VERIFIED: mix test]
**When to use:** Every `file_picker` plan task, including doctor/support wording and shell tests. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: lib/crosswake/bridge/registry.ex
defp file_picker_entry(route, command, payload) do
  transfer_id = payload_transfer_id(payload)

  case Enum.find(route.transfers, &(&1.id == transfer_id)) do
    %TransferSeam{} = transfer ->
      case Contracts.validate_picker_declaration(transfer_declaration(transfer)) do
        :ok -> {:ok, %Entry{command: command, capability: "file_picker", version: transfer.version, route_id: route.id}}
        {:error, _reason} -> {:error, :undeclared_capability}
      end

    nil -> {:error, :undeclared_capability}
  end
end
```

### Pattern 3: Manifest-Derived Support Truth
**What:** Capability support rows should be derived from `Manifest.Builder.capability_catalog/0`, not retyped in guides or doctor helpers. [VERIFIED: codebase grep]
**When to use:** Support-matrix rendering, doctor release-policy snapshots, and guide updates. [VERIFIED: codebase grep]
**Example:**
```elixir
# Source: lib/crosswake/support_matrix/support_matrix.ex
defp capability_family_entries(capability_registry) do
  capability_registry
  |> Enum.map(fn {_id, capability} -> capability end)
  |> Enum.filter(fn capability -> capability.id == capability.family end)
  |> Enum.map(fn %Capability{} = capability ->
    Types.new_capability_support_entry(
      family: capability.family,
      owner: capability.owner,
      package_class: capability.package_class,
      proof_class: capability.proof_class,
      rebuild: capability.rebuild,
      prerequisites: capability.prerequisites,
      denial: capability.denial,
      fallback: capability.fallback,
      guide: capability.guide
    )
  end)
end
```

### Anti-Patterns to Avoid

- **Command-first DSL drift:** Do not make Phoenix authors think in `app.info.get` or `notifications.token.get` names. [VERIFIED: codebase grep]
- **Treating `deep_link` as bridge authority:** Keep it in activation proof and support truth, not in route-local bridge allowlisting. [VERIFIED: codebase grep]
- **Using route capabilities alone for `file_picker`:** `files.pick` without `transfer_id` or with a non-`native_picker` seam must stay denied. [VERIFIED: mix test]
- **Footnote-only support honesty:** Pending proof must be represented structurally as `verification_required`, not buried in prose. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Capability prerequisites, denial, fallback, proof class, rebuild class | A second doctor-only or docs-only capability metadata table | `Crosswake.Manifest.Builder.capability_catalog/0` | The catalog already holds the operational truth that support rows derive from. [VERIFIED: codebase grep] |
| `file_picker` authorization | A generic picker allowlist or ambient filesystem permission model | `Registry.file_picker_entry/3` plus transfer contract validation | The transfer seam already encodes intent, source, verification, and media types. [VERIFIED: codebase grep][VERIFIED: mix test] |
| Support rendering truth | Manually edited markdown as the primary source | `Crosswake.SupportMatrix.canonical/1` and derived guide output | Hand-edited truth already shows drift from code in the bridge guide command list. [VERIFIED: codebase grep] |
| Final confidence | One giant end-to-end story | ExUnit invariants + targeted shell tests + one narrow bounded-family acceptance slice | Phase 18 decisions explicitly require layered proof and separate `deep_link` activation proof. [VERIFIED: codebase grep] |

**Key insight:** This phase should concentrate truth into existing metadata seams, not multiply bespoke enforcement lists. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Doc / Runtime Drift
**What goes wrong:** Guides describe an older bounded command set while registry/tests enforce a newer one. [VERIFIED: codebase grep]
**Why it happens:** Command lists are still duplicated in prose instead of being consistently derived or audited. [VERIFIED: codebase grep]
**How to avoid:** Treat manifest/support-matrix metadata and registry allowlists as canonical, then update guides and doctor fixtures from that truth. [VERIFIED: codebase grep]
**Warning signs:** `guides/bridge.md` omits `notifications.token.get` and `share.invoke` even though `Registry.allowed_commands/0` and tests include them. [VERIFIED: codebase grep][VERIFIED: mix test]

### Pitfall 2: Flattening Baseline Support and Proof State
**What goes wrong:** A platform or capability appears fully supported even when its current proof lane is still pending. [VERIFIED: codebase grep][VERIFIED: STATE.md]
**Why it happens:** Current top-level doctor support posture only flips between `supported` and `verification_required` from proof-hook status, while capability-family rows separately encode advisory vs merge-blocking posture. [VERIFIED: codebase grep]
**How to avoid:** Model baseline platform support, proof-lane verification state, and capability-family proof class as separate rendered dimensions. [VERIFIED: codebase grep]
**Warning signs:** Android Phase 17 remains pending because local Java is missing, yet the current guide still renders Android as `supported`. [VERIFIED: STATE.md][VERIFIED: environment command][VERIFIED: codebase grep]

### Pitfall 3: Treating `file_picker` Like a Normal Capability
**What goes wrong:** A plan adds only `file_picker` to route capabilities and forgets that runtime authorization depends on `transfer_id` plus a valid inbound `native_picker` seam. [VERIFIED: codebase grep][VERIFIED: mix test]
**Why it happens:** `file_picker` is represented as a family in public docs, but it is an intentional exception in enforcement. [VERIFIED: codebase grep]
**How to avoid:** Keep one explicit planner rule: every `files.pick` proof/doctor/support task must mention transfer-backed authorization. [VERIFIED: codebase grep]
**Warning signs:** `Registry.lookup/4` denies `files.pick` without payload, with the wrong transfer id, or when the seam is not picker-valid. [VERIFIED: mix test]

### Pitfall 4: Overloading `deep_link`
**What goes wrong:** `deep_link` gets planned as another bridge family instead of activation truth. [VERIFIED: codebase grep]
**Why it happens:** The support matrix currently renders a `deep_link` capability-family row with `owner: bounded_bridge`, which can mislead if copied mechanically into tasks. [VERIFIED: codebase grep]
**How to avoid:** Keep a separate planning branch for activation-first proof and support wording, even if `deep_link` remains present in the capability catalog. [VERIFIED: codebase grep]
**Warning signs:** Any proposed task that adds `deep_link` to `Registry.allowed_commands/0` or to bridge command docs is wrong for this phase. [VERIFIED: codebase grep]

## Code Examples

Verified patterns from the current codebase:

### Capability-Gated Runtime Lookup
```elixir
# Source: lib/crosswake/bridge/registry.ex
defp capability_entry(manifest, route, command, capability_id) do
  with %Capability{} = capability <-
         lookup_capability(manifest, capability_id) || {:error, :undeclared_capability},
       true <- capability_declared_on_route?(route, capability) || {:error, :undeclared_capability} do
    {:ok,
     %Entry{
       command: command,
       capability: capability.family,
       version: capability.version,
       route_id: route.id,
       allowlisted_origins: route.allowlisted_origins
     }}
  end
end
```

### Doctor Support Posture Today
```elixir
# Source: lib/crosswake/doctor/doctor.ex
defp support_posture(shells, manifest) do
  proof_statuses =
    Enum.into(shells, %{}, fn {platform, shell} ->
      {platform, shell.proof.status}
    end)

  blocking_platforms =
    proof_statuses
    |> Enum.flat_map(fn
      {_platform, :passed} -> []
      {platform, _other} -> [platform]
    end)

  %{
    status: if(blocking_platforms == [], do: :supported, else: :verification_required),
    blocking_platforms: blocking_platforms,
    proof_statuses: proof_statuses,
    release_policy: release_policy_snapshot(manifest)
  }
end
```

### Transfer Fixture Shape That `file_picker` Must Honor
```elixir
# Source: test/support/router_fixtures.ex
transfers: [
  [
    id: :lesson_import,
    intent: :import,
    source: :native_picker,
    verification: :required,
    media_types: ["application/pdf"]
  ]
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Public bridge command ids leaking into route declarations | Public family-first capability vocabulary with command-aware runtime lookup | Locked by Phase 18 decisions on 2026-05-21. [VERIFIED: codebase grep] | Keeps host API stable while allowing protocol evolution underneath. [VERIFIED: codebase grep] |
| Treating file picking as broad capability authority | Transfer-backed `files.pick` exception bound to `transfer_id` and `native_picker` seams | Established by Phase 17 context and current registry/tests on 2026-05-21. [VERIFIED: codebase grep][VERIFIED: mix test] | Prevents ambient filesystem authority drift. [VERIFIED: codebase grep] |
| One coarse support claim | Emerging split across support statuses, proof hooks, capability proof classes, and rebuild classes | Partially present today; Phase 18 must finish the separation. [VERIFIED: codebase grep] | Planning should prefer structural status fields over prose caveats. [VERIFIED: codebase grep] |

**Deprecated/outdated:**

- Manual command lists in docs that are not synced with registry/tests are outdated and should not be treated as canonical. [VERIFIED: codebase grep]
- Any reading of `deep_link` as route-local bridge authority is outdated relative to current phase decisions and shell guides. [VERIFIED: codebase grep]

## Open Questions

1. **Should Phase 18 solve the `deep_link` support-row ambiguity by changing schema, copy, or both?**
   - What we know: `deep_link` must stay activation-first, but support rendering currently shows it in the capability-family table as `bounded_bridge`. [VERIFIED: codebase grep]
   - What's unclear: whether the smallest honest fix is a wording change, a new owner label, or a separate activation-specific rendering path. [VERIFIED: codebase grep]
   - Recommendation: Plan this as an explicit design decision in the support-truth slice, because copying the current row forward will keep misleading downstream docs and diagnostics. [VERIFIED: codebase grep]

2. **Should doctor findings introduce a first-class taxonomy helper now or stay inline?**
   - What we know: Phase context permits a helper module/table, and current severity logic is scattered across shell/support/bridge findings. [VERIFIED: codebase grep]
   - What's unclear: whether Phase 18 scope is large enough to justify centralizing severity and remediation templates immediately. [VERIFIED: codebase grep]
   - Recommendation: Plan for a small helper only if it reduces duplicated severity/remediation logic across capability-specific checks; otherwise keep changes local to avoid abstraction churn. [VERIFIED: codebase grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | Validator, manifest, doctor, ExUnit proof | ✓ | Erlang/OTP 28 runtime present. [VERIFIED: environment command] | — |
| `mix` | Running doctor and ExUnit suites | ✓ | Mix available locally. [VERIFIED: environment command] | — |
| `swift` | iOS shell proof and targeted shell tests | ✓ | Swift 6.2. [VERIFIED: environment command] | — |
| `xcodebuild` | iOS shell build/test execution | ✓ | Xcode 26.0.1. [VERIFIED: environment command] | — |
| Java runtime (`java`, `javac`) | Android JVM proof and Gradle tasks | ✗ | Not installed locally. [VERIFIED: environment command] | Run Android proof in CI or on a Java-enabled workstation. [VERIFIED: STATE.md] |
| Android Gradle wrapper | Android shell tests | ✗ locally effective | Blocked by missing Java runtime. [VERIFIED: environment command] | Same as above. [VERIFIED: STATE.md] |

**Missing dependencies with no fallback:**
- None for Elixir-side planning and implementation. [VERIFIED: environment command]

**Missing dependencies with fallback:**
- Local Android proof is blocked by missing Java, but CI or another workstation can execute the Phase 17/18 Android lane honestly. [VERIFIED: STATE.md][VERIFIED: environment command]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This phase does not introduce auth/session primitives; it operates on route policy, support truth, and bounded native capability enforcement. [VERIFIED: codebase grep] |
| V3 Session Management | no | Session lifecycle is not the operational surface under change here. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Route-local capability declarations, allowlisted origins, active-route checks, pack compatibility checks, and explicit transfer seams are the access-control core. [VERIFIED: codebase grep][VERIFIED: mix test] |
| V5 Input Validation | yes | `Policy.Validator`, typed request modules, and transfer declaration validation enforce compile-time and runtime input boundaries. [VERIFIED: codebase grep][VERIFIED: mix test] |
| V6 Cryptography | no | No crypto surface is expanded in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Route capability escalation by undeclared bridge command | Elevation of Privilege | Keep `Registry.lookup/4` and shell dispatch fail-closed on undeclared or unsupported commands. [VERIFIED: codebase grep][VERIFIED: mix test] |
| Ambient file authority through picker misuse | Elevation of Privilege | Require `transfer_id` and `native_picker` declaration validation before `files.pick` executes. [VERIFIED: codebase grep][VERIFIED: mix test] |
| Origin spoofing or wrong-route execution | Spoofing / Tampering | Preserve origin allowlists and active-route identity checks in native bridge channels. [VERIFIED: codebase grep] |
| Support overclaim causing unsafe operator assumptions | Repudiation / Information Disclosure | Render `verification_required`, advisory proof classes, rebuild posture, prerequisites, denial, and fallback structurally. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/18-operational-diagnostics-and-enforcement/18-CONTEXT.md` - locked decisions, proof posture, support-truth posture, deferred scope. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` - Phase 18 goal, plan split, and phase-local requirement IDs. [VERIFIED: codebase grep]
- `.planning/STATE.md` - current blocker and honest Android proof status. [VERIFIED: codebase grep]
- `lib/crosswake/policy/validator.ex` - public capability vocabulary and compile-time validation seam. [VERIFIED: codebase grep]
- `lib/crosswake/manifest/builder.ex` - capability catalog, prerequisites, denial, fallback, proof class, rebuild class. [VERIFIED: codebase grep]
- `lib/crosswake/bridge/registry.ex` - command-aware allowlist, `file_picker` transfer-backed exception, runtime lookup behavior. [VERIFIED: codebase grep]
- `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/doctor/formatter.ex`, `lib/mix/tasks/crosswake.doctor.ex` - severity model, proof posture, report rendering, CLI behavior. [VERIFIED: codebase grep]
- `lib/crosswake/support_matrix/support_matrix.ex` and `guides/support_matrix.md` - current support rendering and derivation rules. [VERIFIED: codebase grep]
- `guides/bridge.md`, `guides/capabilities.md`, `guides/native_shell.md` - current public language and drift points. [VERIFIED: codebase grep]
- `test/crosswake/bridge/registry_test.exs`, `test/crosswake/doctor/doctor_test.exs`, `test/support/router_fixtures.ex` - verified behavior and proof anchors. [VERIFIED: mix test][VERIFIED: codebase grep]
- `examples/ios_shell_host/...` and `examples/android_shell_host/...` bridge channels/tests - native-shell enforcement shape and denial behavior. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- None. All substantive claims above were verified from project code, docs, tests, or direct environment commands in this session. [VERIFIED: codebase grep][VERIFIED: mix test][VERIFIED: environment command]

### Tertiary (LOW confidence)
- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions and tools were read from `mix.exs`, `mix.lock`, and local environment commands. [VERIFIED: codebase grep][VERIFIED: environment command]
- Architecture: HIGH - routing, manifest, registry, doctor, support, and shell boundaries are explicit in current code and phase decisions. [VERIFIED: codebase grep]
- Pitfalls: HIGH - every pitfall listed is grounded in current code, guide drift, state notes, or passing tests. [VERIFIED: codebase grep][VERIFIED: mix test]

**Research date:** 2026-05-21
**Valid until:** 2026-06-20 for project-internal structure; re-check before planning if Phase 17 Android proof status changes. [VERIFIED: STATE.md]
