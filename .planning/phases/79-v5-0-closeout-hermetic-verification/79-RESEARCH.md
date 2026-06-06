# Phase 79: v5.0 Closeout & Hermetic Verification - Research

**Researched:** 2026-06-05
**Domain:** CI/CD Pipeline Verification and Milestone Closeout
**Confidence:** HIGH

## Summary

This phase implements the final verification gate for the v5.0 standalone shell packages. The goal is to prove that the extracted SPM and Maven core libraries compile cleanly, resolve via `--local` path overrides during generation, and run hermetically in CI without breaking existing archetype lanes. 

We will introduce a dedicated `.github/workflows/phase79-proof.yml` workflow to handle these tests, utilizing existing bash verification scripts but wrapping them with environment variables (`CROSSWAKE_IOS_PROJECT_ROOT`, `CROSSWAKE_ANDROID_PROJECT_ROOT`, and `CROSSWAKE_ANDROID_CONNECTED_TESTS=0`) to ensure fast, deterministic, emulator-free execution. Additionally, we must update the `closeout.verify` Mix task logic in `lib/crosswake/planning/closeout_verifier.ex` to successfully recognize Phase 79 as the PROOF-01 validation holder.

**Primary recommendation:** Generate the `--local` shells explicitly within the GitHub action steps, and pass the resulting generated project path to the `verify_generated_*_shell.sh` scripts, rather than attempting to mutate the bash scripts to have `--local` awareness.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Create a dedicated `phase79-proof.yml` workflow for v5.0 E2E tests, rather than overloading the existing generic `phase75-closeout-gate.yml`.
- **D-02:** This aligns with the established Crosswake DNA (e.g., `phase23-proof.yml`, `phase34-proof.yml`) of using a named verification lane for specific architectural milestones. It keeps the merge-blocking PR lane explicitly tied to v5.0's scaffold logic without tangling it in older milestone legacy checks.
- **D-03:** Stick to faster JVM hermetic unit tests for the core libraries within the CI proof lane.
- **D-04:** This follows the successful decision from Phase 18 ("Split proof lanes by evidence class when emulator/device proof slows iteration") where Android JVM bridge truth closed quickly in CI once separated from emulator-backed connected tests. Emulators introduce unacceptable flakiness and setup time for a standard PR check. The merge-blocking lane must run reliably.
- **D-05:** Use the `--local` flag path overrides to resolve dependencies during E2E CI proof, as mandated by Phase 78's D-02 decision.
- **D-06:** Do NOT build a mock SPM/Maven registry. A mock registry introduces unnecessary infrastructure overhead and flakiness. Relying on `--local` correctly verifies that the generator can resolve the local packages during CI, which is exactly what maintainers need to iterate safely before official publishing.

### the agent's Discretion
- The resulting GitHub workflow should be fast and explicitly named to make PR diagnostics easy.
- Focus on great developer ergonomics (DX): CI errors should clearly indicate if the SPM or Maven artifact failed to compile locally vs if the generated app failed to integrate it.

### Deferred Ideas (OUT OF SCOPE)
- Device/Emulator E2E connected tests for the Android scaffold. The emulator checks will remain advisory or manually run for now to protect CI velocity.
- Official package publishing (Hex, SPM, Maven). Publishing is deferred to the formal release phase once v5.0 is closed out.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | All v5.0 core extraction and API standardization changes must run hermetically in CI, ensuring existing E2E and archetype proof lanes continue to pass against the new standalone libraries. | `phase79-proof.yml` will use `mix crosswake.gen.shell --local` followed by bash verification scripts to prove SPM and Maven artifact hermetic integrity. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Verification Orchestration | CI / CD (GitHub Actions) | — | GitHub Actions defines the execution environment, runs PR checks, and manages workflow logic [VERIFIED: codebase]. |
| Dependency Path Overrides | Tooling / CLI (Mix) | — | The `mix crosswake.gen.shell` task natively supports `--local` overrides, avoiding the need for mock package servers [VERIFIED: codebase grep]. |
| Native Test Execution | Bash Scripts | — | `./script/verify_generated_ios_shell.sh` and `./script/verify_generated_android_shell.sh` abstract `xcodebuild` and `gradle` complexity, keeping CI YAML clean [VERIFIED: codebase]. |
| Milestone Truth Verification | Tooling / CLI (Mix) | — | `mix closeout.verify` via `CloseoutVerifier` evaluates `.planning/REQUIREMENTS.md` compliance [VERIFIED: codebase grep]. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| GitHub Actions | v6 / v1 | CI Pipeline | Crosswake DNA dictates CI lane execution via GH actions [VERIFIED: `.github/workflows`]. |
| Elixir / Mix | 1.19.5 / OTP 27.3 | Task runner | Crosswake core language; runs generators and closeout verifier [VERIFIED: `mix.exs`]. |
| Bash | native | Workflow integration | Existing hermetic test runner wrappers [VERIFIED: `script/`]. |

## Package Legitimacy Audit

> No external packages are introduced in this phase.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | — | — | — | — | — | Approved |

## Architecture Patterns

### CI Lane Structure Pattern
**What:** We create a dedicated pipeline (`phase79-proof.yml`) rather than appending to existing generic checks.
**When to use:** For distinct architectural milestones where PR verification must isolate new failure domains (like SPM `--local` fetching).
**Example:**
```yaml
# Source: Adapted from phase34-proof.yml [VERIFIED: codebase grep]
name: Phase 79 Proof
on:
  pull_request:
  push:
    branches:
      - main
jobs:
  merge-blocking-v5-proof:
    runs-on: macos-15
    steps:
      - name: Generate iOS Shell with Local Path
        run: mix crosswake.gen.shell ios --target tmp/ios_shell --local
      - name: Verify iOS Build
        env:
          CROSSWAKE_IOS_PROJECT_ROOT: tmp/ios_shell/native/ios/crosswake_shell
          CROSSWAKE_IOS_LAUNCH_SIMULATOR: 0
        run: ./script/verify_generated_ios_shell.sh
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Modifying `verify_generated_ios_shell.sh` to hardcode `--local`. This breaks the script for developers testing production/hex paths. Instead, generate the shell via `mix` explicitly with `--local` and pass the resulting path via `CROSSWAKE_IOS_PROJECT_ROOT` to the script.
- **Anti-pattern:** Running Android connected tests (emulators) in the merge-blocking PR queue. Instead, set `CROSSWAKE_ANDROID_CONNECTED_TESTS=0` to enforce JVM tests.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CI Xcode Building | A custom `xcodebuild` step in YAML | `./script/verify_generated_ios_shell.sh` | The script already handles derived data, fallback checking, and scheme discovery reliably [VERIFIED: codebase]. |
| Dependency overriding | Mock SPM/Maven servers | `mix crosswake.gen.shell --local` | Mock registries introduce network flakiness. The `--local` flag natively modifies package specs to use the local monorepo path. |

## Runtime State Inventory

> This phase adds a CI pipeline and adjusts a Mix task validator. No renaming, refactoring, or runtime state migration is occurring.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified by phase scope | none |
| Live service config | None — verified by phase scope | none |
| OS-registered state | None — verified by phase scope | none |
| Secrets/env vars | None — verified by phase scope | none |
| Build artifacts | None — verified by phase scope | none |

## Common Pitfalls

### Pitfall 1: Simulator failures blocking iOS builds
**What goes wrong:** `xcodebuild test` attempts to boot a simulator, which fails on some headless CI runners.
**Why it happens:** Headless environments sometimes lack pseudo-terminal setup.
**How to avoid:** Set `CROSSWAKE_IOS_LAUNCH_SIMULATOR=0` and `CROSSWAKE_IOS_BUILD_FOR_TESTING=1` to ensure we just build the hermetic app.

### Pitfall 2: Android Emulator flakiness
**What goes wrong:** The Android E2E job timeouts or fails randomly.
**Why it happens:** Hardware acceleration isn't cleanly available on all CI runners, and emulator booting takes 3-10 minutes.
**How to avoid:** Set `CROSSWAKE_ANDROID_CONNECTED_TESTS=0` environment variable for the `verify_generated_android_shell.sh` script, which isolates it to JVM tests.

### Pitfall 3: `mix closeout.verify` false negatives on PROOF-01
**What goes wrong:** The v5.0 milestone doesn't close out properly even when PROOF-01 is complete.
**Why it happens:** `lib/crosswake/planning/closeout_verifier.ex` has a hardcoded regex expecting PROOF-01 to be tied to Phase 75.
**How to avoid:** Update `lib/crosswake/planning/closeout_verifier.ex` to support Phase 79, e.g., `Regex.match?(~r/\|\s*(PROOF-01)\s*\|\s*Phase (75|79)\s*\|\s*Pending\s*\|/, requirements)`.

## Code Examples

### Generating Local Overrides in CI
```bash
# Source: Derived from script capabilities [VERIFIED: codebase]
# Step 1: Explicitly generate shell locally
mix crosswake.gen.shell android --target tmp/android_shell --local

# Step 2: Inform the verify script to test the generated project
export CROSSWAKE_ANDROID_PROJECT_ROOT="tmp/android_shell/native/android/crosswake_shell"
export CROSSWAKE_ANDROID_CONNECTED_TESTS=0

# Step 3: Run the script
./script/verify_generated_android_shell.sh
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Appending to generic proof gates | Named proof lanes (`phase79-proof.yml`) | Phase 23+ | Keeps PR checks tightly scoped to the architecture they verify. |
| Emulators in PR queue | JVM unit tests only | Phase 18+ | Saves 5-10m per PR, zero UI flakiness, purely hermetic truth. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None | All claims verified | none |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| xcodebuild | iOS Script | ✓ | native (macOS runner) | — |
| gradle | Android Script | ✓ | native | — |
| elixir | Mix tasks | ✓ | 1.19.5 (erlef/setup-beam) | — |

**Missing dependencies with no fallback:**
- none

**Missing dependencies with fallback:**
- none

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | GitHub Actions + Bash |
| Config file | `.github/workflows/phase79-proof.yml` |
| Quick run command | `mix test` (for Mix tasks) |
| Full suite command | GitHub CI runs automatically |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 | Verify SPM/Maven `--local` integration | integration | `./script/verify_generated_*` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `.github/workflows/phase79-proof.yml` — missing workflow file.
- [ ] `lib/crosswake/planning/closeout_verifier.ex` — needs `Phase 79` logic fix for `PROOF-01`.

## Security Domain

> security_enforcement is implicitly enabled. This is a CI pipeline phase; no live surfaces are altered.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | — |
| V6 Cryptography | no | — |

### Known Threat Patterns for GitHub Actions

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CI configuration injection | Tampering | Check out specific commits, require PR approvals before CI runs |

## Sources

### Primary (HIGH confidence)
- `.github/workflows/phase34-proof.yml` - Reference CI layout.
- `script/verify_generated_ios_shell.sh` - Input ENV requirements.
- `lib/crosswake/planning/closeout_verifier.ex` - Found Phase 75 constraint.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Verified exact bash scripts and Elixir dependencies exist.
- Architecture: HIGH - Verified `phase34-proof.yml` standard structure.
- Pitfalls: HIGH - Traced hardcoded PROOF-01 checks directly in `closeout_verifier.ex`.

**Research date:** 2026-06-05
**Valid until:** 2026-07-05
