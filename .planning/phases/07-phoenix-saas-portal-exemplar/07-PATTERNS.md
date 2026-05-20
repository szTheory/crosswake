# Phase 7: Phoenix SaaS Portal Exemplar - Patterns

**Mapped:** 2026-05-17
**Scope:** Planning-relevant patterns only for the Phase 7 SaaS lane
**Sources analyzed:** 11

Use these patterns to plan the Phase 7 SaaS exemplar inside the shared example host. They capture reusable repository conventions and the main anti-patterns to avoid. This phase should extend existing Crosswake proof and guide surfaces, not invent new product or infrastructure layers.

## Reusable Patterns

### Pattern 1: Extend the shared example host, do not fork a new sample app

**Why it matters**

Phase 6 already locked the artifact class: one Phoenix host plus paired iOS and Android proof hosts. Phase 7 work should stay inside that shared surface.

**Copy from**

- [examples/phoenix_host/README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:3)
- [examples/phoenix_host/README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:14)
- [examples/phoenix_host/README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:27)

**Apply in Phase 7**

- Add the SaaS lane under `CrosswakeExample.SaaSPortal.*`.
- Keep route, module, fixture, and proof isolation inside `examples/phoenix_host`.
- Reuse generic account-style fixtures instead of introducing a separate app or polished template.

**Anti-pattern**

- New standalone SaaS sample app, starter-app framing, or a kitchen-sink host that mixes all exemplar concerns together.

---

### Pattern 2: Group SaaS routes under one Crosswake-managed router scope with shared defaults

**Why it matters**

The example host and router fixtures already model the repo’s preferred pattern: one `scope`, one `crosswake_defaults` block, then route-local overrides only where needed.

**Copy from**

- [examples/phoenix_host/lib/crosswake_example/router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:30)
- [examples/phoenix_host/lib/crosswake_example/router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:31)
- [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:39)

**Apply in Phase 7**

- Put the SaaS slice in one router group, likely `/saas`.
- Set shared defaults once for the group: `runtime: :live_view`, `offline: :cached_read_only`, `security: :standard`.
- Override per route only when the contract truly changes.
- Keep the route set within the locked 4-6 route budget.

**Anti-pattern**

- Repeating full Crosswake metadata on every route when defaults would do.
- Mixing SaaS routes across unrelated scopes or runtime classes.
- Letting Phase 7 drift into `:native_screen` or `:offline_island` ownership.

---

### Pattern 3: Keep auth host-owned and layered in ordinary Phoenix places

**Why it matters**

Phase 7 explicitly chose ordinary Phoenix session auth instead of a Crosswake auth abstraction. The repo reinforces this with a host-owned policy entrypoint and repeated guidance that generated host code remains app-owned.

**Copy from**

- [examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex:2)
- [examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex:5)
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:13)
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:33)
- [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md:17)

**Apply in Phase 7**

- Treat auth modules, plugs, `live_session`, and `on_mount` hooks as example-host code, not Crosswake library surface.
- Keep one authenticated account boundary and one lightweight role split.
- Enforce authz in more than one place: router/session setup, LiveView mount boundary, and the approval action itself.
- Keep fixture auth realistic but small.

**Anti-pattern**

- Introducing `Crosswake.Auth`, token choreography, or shell-specific auth abstractions.
- Treating route policy as authorization.
- Expanding into SSO, OAuth, MFA, passkeys, org switching, or vendor auth guidance.

---

### Pattern 4: LiveView remains the product owner; native affordance stays secondary

**Why it matters**

The SaaS lane is supposed to prove a Phoenix-owned product slice, not a wrapper with scattered native authority.

**Copy from**

- [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md:23)
- [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md:39)
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:14)
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:16)

**Apply in Phase 7**

- Model the main flow as authenticated `:live_view` routes inside the shell.
- Keep approval decisions server-authoritative.
- Use the native affordance only at a low-frequency confirmation moment, not as a control loop or navigation primitive.

**Anti-pattern**

- Native-owned approval flow.
- Continuous client authority or app-local state machines driving the product workflow.
- “Generic mobile wrapper” framing.

---

### Pattern 5: Capability use must be manifest-backed, typed, and route-local

**Why it matters**

The repo’s bridge contract and registry are explicit: the bridge exposes a narrow command set and allows usage only when the active route declared the capability.

**Copy from**

- [lib/crosswake/bridge/contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex:2)
- [lib/crosswake/bridge/contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex:11)
- [lib/crosswake/bridge/contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex:24)
- [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex:11)
- [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex:55)
- [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex:81)
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:107)

**Apply in Phase 7**

- Use `haptics.impact` as the one primary SaaS capability.
- Declare it only on the route that actually needs it.
- Keep the interaction request/reply-only and tied to the active route id.
- If `app.info.get` appears at all, keep it supporting and secondary.

**Anti-pattern**

- Generic bridge bus or ad hoc JS/native messaging.
- Declaring broad capability sets “just in case”.
- Making file, transfer, or capture capabilities the center of the SaaS lane.

---

### Pattern 6: Denials and unsupported routes stay visible and explicit

**Why it matters**

Crosswake’s shell contract is fail-closed. Phase 7 should inherit that vocabulary instead of inventing graceful-but-misleading fallback behavior.

**Copy from**

- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:45)
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:49)
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:53)
- [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md:43)

**Apply in Phase 7**

- Keep `route unavailable` as the primary failure vocabulary for this lane.
- Plan proof and docs around denied deep links, unsupported routes, or inactive routes landing on explicit denial surfaces.
- Do not promise fallback WebView behavior when activation or capability checks fail.

**Anti-pattern**

- Silent degradation into a generic container.
- Reframing denial as a best-effort compatibility fallback.

---

### Pattern 7: Extend proof by layering assertions onto the existing scripts and tests

**Why it matters**

The repo already has the extension pattern: contract script plus ExUnit test, layered on top of the existing Phase 5 example-host proof entrypoint.

**Copy from**

- [examples/phoenix_host/README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:91)
- [script/verify_adopter_profile_contract.sh](/Users/jon/projects/crosswake/script/verify_adopter_profile_contract.sh:8)
- [script/verify_adopter_profile_contract.sh](/Users/jon/projects/crosswake/script/verify_adopter_profile_contract.sh:87)
- [script/verify_phase5_example_hosts.sh](/Users/jon/projects/crosswake/script/verify_phase5_example_hosts.sh:8)
- [test/crosswake/proof/adopter_profile_contract_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/adopter_profile_contract_test.exs:31)
- [test/crosswake/proof/phase5_proof_lane_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase5_proof_lane_test.exs:6)
- [test/crosswake/proof/phase5_proof_lane_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase5_proof_lane_test.exs:49)

**Apply in Phase 7**

- Add SaaS-lane assertions to the checked-in host proof posture instead of replacing it.
- Verify route ids, runtime ownership, and the bounded capability declaration from the manifest or source.
- Keep the existing `script/verify_phase5_example_hosts.sh` entrypoint in the proof chain.
- Prefer small contract scripts and focused ExUnit proof tests over a new proof framework.

**Anti-pattern**

- Separate SaaS-only proof harness.
- Proof that ignores the shared iOS and Android host alignment.
- Publishing support claims without corresponding script or test coverage.

---

### Pattern 8: Docs should describe the SaaS boundary and then link back to canonical truth

**Why it matters**

The repo already centralizes support truth and shell truth in dedicated guides. Phase 7 docs should explain what the SaaS lane pressures without duplicating support-matrix detail.

**Copy from**

- [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md:8)
- [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md:47)
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:72)
- [examples/phoenix_host/README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:97)
- [script/verify_adopter_profile_contract.sh](/Users/jon/projects/crosswake/script/verify_adopter_profile_contract.sh:92)

**Apply in Phase 7**

- Add lane-specific docs that explain supported, degraded, and deferred SaaS boundaries.
- Link back to `guides/native_shell.md`, `guides/install.md`, and `guides/support_matrix.md` for canonical shell, proof, and support status detail.
- Keep exact generated-shell proof hook names out of adopter-profile prose when the current contract says not to duplicate them there.

**Anti-pattern**

- Duplicating the support matrix inside the SaaS guide.
- Turning docs into capability demos instead of boundary truth.

## Integration Points

- `examples/phoenix_host/lib/crosswake_example/router.ex`: add the SaaS route group and route-local Crosswake metadata.
- `examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex`: keep using the host-owned policy entrypoint rather than inventing a separate SaaS policy layer.
- `examples/phoenix_host/README.md`: extend the shared-host lane contract only where Phase 7 needs additional SaaS-lane specifics.
- `guides/adopter_profiles.md`: keep the public SaaS framing aligned with the implemented route set and non-goals.
- `guides/native_shell.md`: remain consistent with fail-closed activation, denial UI, and bounded bridge language.
- `script/verify_phase5_example_hosts.sh` and `test/crosswake/proof/phase5_proof_lane_test.exs`: extend the base proof posture.
- `script/verify_adopter_profile_contract.sh` and `test/crosswake/proof/adopter_profile_contract_test.exs`: add SaaS-lane contract assertions only if they preserve the existing shared-host scaffold pattern.

## Anti-Patterns To Block In Planning

- New Crosswake auth subsystem or shell-aware auth abstraction.
- More than one meaningful native affordance for the SaaS lane.
- Packs, transfers, offline islands, or native capture becoming the main SaaS story.
- Separate exemplar app instead of a shared-host lane.
- Route policy used as a replacement for Phoenix authz.
- Silent fallback to generic WebView behavior when activation or capability checks fail.
- Doc duplication that forks support truth from `guides/support_matrix.md`.
- Proof work that bypasses the checked-in example hosts or invents a parallel verification stack.

## Planning Notes

- The closest concrete repo analog for Phase 7 route structure is the current example-host router plus the router fixtures, not an existing auth slice.
- For auth-specific implementation, the repo provides constraint direction rather than code to copy verbatim: ordinary Phoenix session auth, `live_session`, `on_mount`, and host-owned plugs are the intended fit.
- The strongest Phase 7 plan will keep Phoenix ownership obvious, capability use narrow, and proof/doc changes incremental.
