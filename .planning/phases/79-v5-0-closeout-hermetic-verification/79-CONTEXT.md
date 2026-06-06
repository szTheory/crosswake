# Phase 79: v5.0 Closeout & Hermetic Verification - Context

**Gathered:** 2026-06-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Hermetic verification and closeout of the v5.0 standalone shell packages. This ensures that the extracted SPM/Maven core libraries and the newly created `mix crosswake.gen.shell` scaffolds work end-to-end, without breaking existing archetype lanes.

</domain>

<decisions>
## Implementation Decisions

### CI Lane Structure
- **D-01:** Create a dedicated `phase79-proof.yml` workflow for v5.0 E2E tests, rather than overloading the existing generic `phase75-closeout-gate.yml`.
- **D-02:** This aligns with the established Crosswake DNA (e.g., `phase23-proof.yml`, `phase34-proof.yml`) of using a named verification lane for specific architectural milestones. It keeps the merge-blocking PR lane explicitly tied to v5.0's scaffold logic without tangling it in older milestone legacy checks.

### Android Verification Strategy
- **D-03:** Stick to faster JVM hermetic unit tests for the core libraries within the CI proof lane.
- **D-04:** This follows the successful decision from Phase 18 ("Split proof lanes by evidence class when emulator/device proof slows iteration") where Android JVM bridge truth closed quickly in CI once separated from emulator-backed connected tests. Emulators introduce unacceptable flakiness and setup time for a standard PR check. The merge-blocking lane must run reliably.

### Artifact Publishing Verification
- **D-05:** Use the `--local` flag path overrides to resolve dependencies during E2E CI proof, as mandated by Phase 78's D-02 decision.
- **D-06:** Do NOT build a mock SPM/Maven registry. A mock registry introduces unnecessary infrastructure overhead and flakiness. Relying on `--local` correctly verifies that the generator can resolve the local packages during CI, which is exactly what maintainers need to iterate safely before official publishing.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone posture
- `.planning/PROJECT.md` - Crosswake thesis, explicit runtime boundaries, and native abstraction limits.
- `.planning/REQUIREMENTS.md` - PROOF-01 traceability for v5.0 closeout.
- `.planning/ROADMAP.md` - Phase 79 goal and verification boundaries.
- `.planning/phases/78-automated-host-scaffold-generation/78-CONTEXT.md` - Context ensuring `--local` usage and scaffold requirements.

### Architectural Research & Guidelines
- `prompts/crosswake-elixir-oss-dna.md` - Core house style, specifically "Proof lanes are part of the product" and "Split merge-blocking hermetic lanes from advisory device/store/provider lanes."

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/mix/tasks/closeout.verify.ex` - The standard task for validating milestones which should execute cleanly for v5.0.
- `script/verify_generated_ios_shell.sh` - Bash script providing the blueprint for how to scaffold the `--local` iOS package during proof.
- `script/verify_generated_android_shell.sh` - Bash script for Android shell generation which should be used with `RUN_CONNECTED_TESTS=0` for JVM tests.

### Established Patterns
- `.github/workflows/phaseX-proof.yml` (e.g. `phase34-proof.yml`) — the pattern for dedicated milestone proof CI workflows.

### Integration Points
- Connecting the new SPM/Maven validation into a new `phase79-proof.yml` GitHub action.
- Wiring `mix closeout.verify` to recognize v5.0 completion requirements.

</code_context>

<specifics>
## Specific Ideas

- The resulting GitHub workflow should be fast and explicitly named to make PR diagnostics easy.
- Focus on great developer ergonomics (DX): CI errors should clearly indicate if the SPM or Maven artifact failed to compile locally vs if the generated app failed to integrate it.

</specifics>

<deferred>
## Deferred Ideas

- Device/Emulator E2E connected tests for the Android scaffold. The emulator checks will remain advisory or manually run for now to protect CI velocity.
- Official package publishing (Hex, SPM, Maven). Publishing is deferred to the formal release phase once v5.0 is closed out.

</deferred>

---

*Phase: 79-v5-0-closeout-hermetic-verification*
*Context gathered: 2026-06-05*