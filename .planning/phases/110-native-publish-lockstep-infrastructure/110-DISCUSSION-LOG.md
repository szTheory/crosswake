# Phase 110: Native Publish & Lockstep Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 110-native-publish-lockstep-infrastructure
**Areas discussed:** Version & first-publish sequencing, Manual credential ownership, Dry-run gate depth (PUB-03), Mirror repo bootstrap & protection
**Mode:** Advisor (minimal_decisive calibration) — deep parallel subagent research per area, decisive coherent recommendations.

---

## Version & first-publish sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| A | 110 = wire machinery + validated-upload→drop proof; first REAL lock-step publish (0.1.2) deferred to end of 111 | ✓ |
| B (canary) | Prerelease canary (0.1.2-rc.1) real-published in 110 to prove the pipeline | |
| C (0.1.1) | Real intermediate 0.1.1 lock-step publish in 110 | |
| D | Real 0.1.2 publish in 110 accepting still-broken gen.shell | |

**User's choice:** Option A (confirmed after deep research).
**Notes:** Decisive argument: lock-step means a real native publish forces a same-version Hex cut while `gen.shell` templates still emit broken coordinates → broken adopter scaffold. Canary rejected — SwiftPM `from:`/`upToNextMajor` and Hex `~>` exclude prereleases, Maven burns `-rc` permanently; proves nothing. Version target `0.1.2` per REL-01 (overrides natural-math `0.1.1`), via one-time `release-as` pin. Drift fix: revert `mix.exs` to `0.1.0`, baseline manifest at `0.1.0`, remove pin after the cut. 110 success criteria reinterpreted as machinery+proof (live artifacts land at 111's cut).

---

## Manual credential ownership

| Option | Description | Selected |
|--------|-------------|----------|
| A (pre-provision) | Human provisions all credentials out-of-band; plan asserts presence + fails fast | ✓ |
| B (gated checkpoint) | Executor pauses mid-run for human to provision, then resumes | |

**User's choice:** Option A (confirmed after deep research).
**Notes:** Non-interactive GSD executor can't do browser OAuth / TTY keygen; Maven immutability makes mid-run stalls dangerous; 12-factor "pipelines verify, humans provision." Critical footgun surfaced: GPG **primary-key-only** keypair (no signing subkey) to avoid Maven's "Invalid signature" rejection. 8-secret layout (Vanniktech in-memory convention, Sonatype user token). Namespace has no status API → validated-upload→drop is the namespace check. Deliverable: SETUP.md checklist + recovery notes.

---

## Dry-run gate depth (PUB-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A (local-only) | publishToMavenLocal + ~/.m2 assertions only | partial (prerequisite step) |
| B (local + validated-upload→drop) | Local asserts THEN Central Portal USER_MANAGED upload → poll VALIDATED → DROP | ✓ |

**User's choice:** Option B (confirmed after deep research), made a permanent lane.
**Notes:** Gap closed authoritatively — Central Portal immutability is scoped to PUBLISHED only; a VALIDATED deployment is droppable and frees the coordinate. Vanniktech 0.31.0: `publishToMavenCentral(CENTRAL_PORTAL)` defaults to USER_MANAGED; never `automaticRelease=true` on first publish; 0.31.0 doesn't log the deployment ID (fetch by name); `mavenCentralAutomaticPublishing` property doesn't exist in 0.31.0. Wire as a permanent `workflow_dispatch` fire-drill lane reused before every release.

---

## Mirror repo bootstrap & protection

| Option | Description | Selected |
|--------|-------------|----------|
| A (empty + CI seeds) | Empty public mirror repo; first CI run seeds it on 111's release | ✓ |
| B/C (manual seed) | Seed README+Package.swift, or a manual splitsh split, first | |

**User's choice:** Option A (confirmed after deep research).
**Notes:** Pushing split SHA to `refs/heads/main` on an empty remote is well-defined; SPI submission waits for first real tag. Tag immutability: load-bearing = no-`--force` CI + `releases_created` gate (git rejects non-ff tag updates by default); defense-in-depth = repository ruleset via `gh api .../rulesets` (`target: tag`, `non_fast_forward`+`deletion`) — free-tier, non-interactive, a different surface than the harness-blocked legacy UI. `--scratch` corrected OUT (no-op on stateless CI runners; PITFALLS.md was wrong).

---

## Claude's Discretion

- Exact CI job structure/step-ordering, new-action SHA-pins + `dependabot.yml`, and preflight/assertion script shapes — planner/executor's call within the locked decisions.
- POM field values and `build.gradle.kts` publish-block details follow STACK.md verbatim.

## Deferred Ideas

- GitHub Immutable Releases as a third tag-protection layer (only if mirror CI creates GH Release objects).
- Mirror landing-page README (write when mirror is first seeded in 111).
- All Phase 111 scope (template rewire, clean-room CI lane, `doctor --check-publish` parity check, doc reconciliation, the real 0.1.2 cut).
- Post-v11.0 future requirements (real device/emulator proof, onboarding/docs consolidation, companion extraction).
