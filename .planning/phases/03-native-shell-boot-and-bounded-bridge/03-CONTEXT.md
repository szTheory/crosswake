# Phase 3: Native Shell Boot And Bounded Bridge - Context

**Gathered:** 2026-05-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 3 proves that real iOS and Android shells can boot from the Phase 2 manifest, resolve app entry and route activation from explicit route truth, host declared `:live_view` routes inside bounded native web containers, and execute only a small typed bridge surface under strict capability, route, origin, and compatibility checks. This phase does not yet broaden into offline islands, packs, broad native capability breadth, or native-screen-heavy product surfaces beyond the minimum explicit seams needed to keep route ownership honest.

</domain>

<decisions>
## Implementation Decisions

### Shell scaffold shape
- **D-01:** Phase 3 should build a thin but real shell, not a placeholder wrapper and not a broad future-heavy chassis.
- **D-02:** The first shell must include native app boot, manifest loading, compatibility gating, route resolution, native navigation structure, deep-link/app-entry handling, bounded LiveView hosting, and a built-in diagnostics surface.
- **D-03:** The first shell must not prebuild speculative Phase 4/5 surfaces such as offline-island hosts, pack management UI, broad operator consoles, or native-screen registries beyond the seams directly required for Phase 3.
- **D-04:** Shell UX should make route truth visible: explicit unsupported/unavailable screens are part of the product contract, not cleanup work.

### Route activation and LiveView container
- **D-05:** Route activation should be manifest-first and native-first: app launch, universal/app links, notifications, and in-app navigation all normalize into a typed route activation request before any web container loads content.
- **D-06:** The shell should resolve the requested route against the bundled or cached manifest, run compatibility and allowlist checks, and only then mount the declared runtime.
- **D-07:** Declared `:live_view` routes should open inside a bounded same-origin `WKWebView`/Android `WebView` container after manifest, origin, runtime, and capability checks pass.
- **D-08:** Crosswake should not use a WebView-first bootstrap where in-page JavaScript asks the shell to hand off later. That approach drifts toward generic-wrapper behavior and checks route safety too late.
- **D-09:** Crosswake should not introduce a separate Hotwire-style path-rule or presentation overlay in Phase 3. Route ownership and primary activation truth stay in the Crosswake manifest; presentation defaults may live in shell code or minimal manifest-backed metadata, but not in a second routing system.
- **D-10:** Unsafe or unsupported routes must never silently fall back to a generic container. They should land on an explicit native denial or recovery surface, with only narrow safe fallback behavior when policy allows it.

### Bridge contract and first capability set
- **D-11:** The Phase 3 bridge should stay semantic, typed, versioned, request/reply-only, and low-frequency. It must not become a generic message bus, navigation authority, or render/state synchronization channel.
- **D-12:** Bridge command naming should stay noun-first and explicit, such as `app.info.get`, `haptics.impact`, and `files.pick`, rather than plugin-style raw method dispatch.
- **D-13:** The first bridge capability set should be small but useful: `app.info.get`, `haptics.impact`, and `files.pick`.
- **D-14:** The first capability set should deliberately exclude permission-heavy, camera-adjacent, clipboard, share-sheet, and other broad plugin surfaces until later phases prove where native-screen or adapter ownership is the better fit.
- **D-15:** Every bridge request must carry enough typed context for enforcement, including route identity, origin, capability/command identity, version identity, and correlation identity for request/reply handling.
- **D-16:** Capability allowlists and capability versions should come directly from manifest truth and route declarations, not from ad hoc native registration alone.

### Capability denial and failure behavior
- **D-17:** Crosswake should fail closed by default on route activation and capability execution.
- **D-18:** The shell should provide one standardized denial surface for route activation failures and one typed denial envelope for bridge failures, sharing the same reason vocabulary.
- **D-19:** Denial reasons should be stable and product-level, covering at least compatibility mismatch, undeclared or unavailable capability, origin denied, and inactive route. Debug surfaces may include deeper axis detail and hints; release-user copy should stay calm and support-oriented.
- **D-20:** Deep links should be checked before runtime boot. If denied, the shell should open a Crosswake-owned route-unavailable screen with only safe actions such as retry, open a declared safe fallback route, or update the app.
- **D-21:** In-app navigation failures should keep the current route stable and present denial UI as an interrupting native surface rather than partially navigating into the wrong runtime.
- **D-22:** Bridge denials must never execute side effects and must be easy to assert in tests and surface in diagnostics.

### Native packaging and generator posture
- **D-23:** Phase 3 should generate real host-owned native app projects, not placeholder text files and not regeneratable pseudo-owned native directories.
- **D-24:** iOS should use a real Xcode app target/project baseline. Crosswake may also generate a local reusable shell library or package, but not `Package.swift` executable targets as the primary app build system.
- **D-25:** Android should use a real Gradle/Android Studio app module baseline, optionally with a local reusable library module for Crosswake-owned runtime code.
- **D-26:** Crosswake’s public posture should be scaffold once, then patch-or-doc upgrades. Do not imply that the library safely re-owns or regenerates host-edited native apps after initial generation.
- **D-27:** Proof lanes should build the same class of host-owned native app artifact that adopters ship, so support claims reflect real installation paths rather than internal-only demo topology.

### Decision delegation posture
- **D-28:** Shift decisions left within GSD by default for this phase. Researcher, planner, and implementer agents should make principled decisions without re-asking unless a choice materially changes the public product contract, support claims, compatibility policy, security posture, route-runtime taxonomy, or the host-owned-vs-library-owned ownership model.
- **D-29:** Internal implementation details such as exact module splits, native file organization, navigation stack implementation details, serialization helpers, fixture shape, and diagnostics presentation polish are agent discretion as long as they preserve the decisions above.

### the agent's Discretion
- Exact shell module and file boundaries on iOS and Android.
- Exact diagnostics screen layout and copy treatment in debug vs release builds.
- Exact typed field names for bridge envelopes, provided the semantic contract and enforcement posture stay intact.
- Exact presentation defaults for pushing or replacing LiveView-backed screens, so long as route ownership does not move out of the manifest-driven activation path.

</decisions>

<specifics>
## Specific Ideas

- Hotwire Native is the strongest positive shape reference for Phase 3 shell boundaries: native navigation shell, bounded bridge components, and explicit native screens as escape hatches. Crosswake should borrow the discipline, not the rules-first path-configuration contract.
- Expo’s runtime-version posture is a strong compatibility lesson: native-runtime identity must change when shipped native behavior changes. Crosswake should keep that compatibility honesty and avoid covert behavior expansion through config drift.
- Tauri’s capability scoping is the best adjacent lesson for allowlists and per-surface trust. Capability access should be explicit and bounded, not globally available to every web surface.
- Capacitor is the clearest cautionary example for plugin sprawl. Crosswake should avoid reading as “Phoenix in a wrapper with plugins.”
- Phoenix LiveView hooks remain the right idiomatic seam for low-frequency bridge interaction. They are not a reason to move route activation or navigation authority into page JavaScript.
- The desired developer experience is strong install truth, clear ownership boundaries, explicit rough-edge visibility, and mobile shells that feel real enough to trust without pretending Crosswake already solved offline breadth or native-screen breadth.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Core planning context
- `.planning/PROJECT.md` — project thesis, constraints, non-goals, and OSS posture
- `.planning/REQUIREMENTS.md` — Phase 3 requirements and v1 scope boundaries
- `.planning/ROADMAP.md` — Phase 3 goal and success criteria
- `.planning/STATE.md` — current project position and known Phase 3 concerns

### Prior phase decisions
- `.planning/phases/01-route-policy-foundation/01-CONTEXT.md` — locked route-policy, ownership, and host-owned generator decisions
- `.planning/phases/02-manifest-truth-and-compatibility/02-CONTEXT.md` — locked manifest, compatibility, fail-closed, and support-posture decisions

### Stable project research
- `.planning/research/SUMMARY.md` — architecture and roadmap rationale across the project
- `.planning/research/ARCHITECTURE.md` — runtime-host, route-activation, bridge, and diagnostics system shape

### Prompt lineage and product guidance
- `prompts/crosswake-research-synthesis.md` — synthesized project direction and architectural guardrails
- `prompts/crosswake-gsd-project-brief.md` — authoritative product brief, route/runtime positioning, and support posture
- `prompts/crosswake-brand-book.md` — terminology, positioning, and anti-drift messaging constraints
- `prompts/crosswake-elixir-oss-dna.md` — install truth, generated-code ownership, proof-lane expectations, and maintainer OSS style
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — route/runtime architecture lessons and cross-ecosystem cautions
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — refined manifest, shell, and bridge guidance
- `prompts/elixir-mobile-oss-lib-deep-research.md` — broader ecosystem framing and cautionary examples

### Current implementation anchors
- `lib/mix/tasks/crosswake.gen.shell.ex` — current shell generator posture and host-owned scaffold baseline
- `test/mix/tasks/crosswake_gen_shell_test.exs` — expected generator ownership and fixture behavior
- `lib/crosswake/manifest/types.ex` — typed manifest contract consumed by shells
- `lib/crosswake/manifest/builder.ex` — route-first manifest assembly and route-entry truth
- `lib/crosswake/compatibility/route_gate.ex` — current fail-closed route decision surface
- `lib/crosswake/doctor/doctor.ex` — operator-facing diagnostics posture
- `lib/crosswake/doctor/check.ex` — structured finding model for shared diagnostics vocabulary
- `lib/crosswake/doctor/formatter.ex` — human-readable diagnostics formatting baseline
- `lib/crosswake/doctor/json_formatter.ex` — machine-readable diagnostics output baseline
- `test/support/router_fixtures.ex` — representative managed routes and capability declarations used by current tests

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.Manifest.Types` — already defines the manifest root, compatibility, capability registry, and route-entry shapes the shells should consume.
- `Crosswake.Manifest.Builder` — already compiles route-first entries and origin allowlists from policy truth.
- `Crosswake.Compatibility.RouteGate` — already establishes a deny-first route evaluation pattern that can feed native activation decisions and denial UX.
- `mix crosswake.gen.shell` — already codifies host-owned scaffold posture and should evolve into real native app generation rather than framework ownership.
- `Crosswake.Doctor` and related formatter modules — provide an existing structured-diagnostics model that Phase 3 denial and shell diagnostics should align with.
- `Crosswake.TestSupport.RouterFixtures` — already models realistic route classes (`:live_view`, `:offline_island`, `:native_screen`) and capability declarations for proof-oriented tests.

### Established Patterns
- Route-local policy remains the authoritative Phoenix-side source of truth.
- Compatibility and support posture are explicit, layered, and fail closed.
- Generated artifacts should stay reviewable and honest about ownership.
- Machine-readable structures are preferred over opaque strings for diagnostics and contract surfaces.

### Integration Points
- Generated iOS and Android shells should consume bundled manifest artifacts derived from the existing manifest pipeline.
- Native route activation should reuse manifest route entries plus `RouteGate`-style compatibility reasoning instead of inventing separate routing truth.
- Bridge enforcement should read route allowlists and capability registry data from the manifest contract.
- Shell denial surfaces and debug diagnostics should reuse the existing severity/reason/hint posture from doctor findings where practical.
- Phase 3 proof lanes should extend current router fixtures and manifest tests into shell-facing fixtures and route-activation scenarios.

</code_context>

<deferred>
## Deferred Ideas

- Separate path-rule or presentation overlay systems similar to Hotwire path configuration — deferred unless Phase 3 planning proves a minimal presentation metadata seam is unavoidable.
- Permission-heavy and broader plugin-style bridge capabilities such as camera, clipboard, share sheet, notifications, or generic permission brokers — defer to later native-screen, adapter, or companion-focused phases.
- Offline island hosts, journals, reconciliation UI, and pack-management UI — Phase 4 and Phase 5 work.
- Broad native-screen registries, device-heavy escape hatches, and media-heavy adapters — Phase 5 work.
- Regeneratable or continuously re-owned native project directories — deferred unless the product later takes a much more opinionated native-project-management posture.
- Companion/vendor integration abstractions — remain outside Phase 3 scope.

</deferred>

---

*Phase: 03-native-shell-boot-and-bounded-bridge*
*Context gathered: 2026-05-14*
