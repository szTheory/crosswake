# Crosswake Retrospective

## Milestone: v3.1 Native Capabilities and Bridge Expansion

**Shipped:** 2026-05-27
**Phases:** 4
**Plans:** 16

### What Was Built

- Base bounded bridge families for `haptics`, `share`, and `app_info`.
- System-context support for deep-link activation truth and read-only `permissions.status`.
- User-prompted `notification_token` and transfer-bound `file_picker` capability families.
- Family-first policy validation, doctor posture, and support-matrix proof status for v3.1 capability truth.
- A dedicated `Phase 18 Proof` GitHub Actions lane that passed Elixir proof slices, checked-in iOS shell proof, and Android JVM BridgeChannel proof.

### What Worked

- Keeping bridge commands semantic and low-frequency preserved Crosswake's route-ownership thesis while still reducing adopter native glue.
- Splitting Phase 17 by ownership surface let Elixir contracts settle before iOS and Android shell implementation details landed.
- Moving Android JVM proof into CI was the right closure path for this workstation, which still lacks a local Java runtime.

### What Was Inefficient

- The first Phase 18 CI workflow mixed JVM proof with emulator-backed connected proof, which made the lane too slow and opaque for iteration.
- The live `REQUIREMENTS.md` had drifted from milestone reality, so v3.1 closeout had to preserve v3.0 requirements separately and reconstruct v3.1 requirements from roadmap/context truth.

### Patterns Established

- Use separate evidence classes for proof lanes: fast contract/JVM proof for merge-blocking truth, emulator or device checks only where they prove a distinct runtime claim.
- Keep support matrix truth split into baseline platform support, repository proof status, and capability-family posture.
- Treat provider/token and file-picker flows as evidence/staging seams, not device-owned backend authority.

### Key Lessons

- CI timeout budgets should match iteration needs; long native lanes should expose useful progress or be split before they become blockers.
- Human-device UAT should remain explicit proof debt rather than being silently converted into repository support claims.
- Milestone requirements need to be rotated at milestone start so closeout does not have to infer scope from roadmap artifacts.

## Cross-Milestone Trends

| Trend | Evidence | Implication |
|-------|----------|-------------|
| Proof truth is part of product surface | v3.1 only closed once Phase 18 Proof passed | Future milestones should define proof lanes before final execution slices |
| Runtime ownership remains the strongest guardrail | v3.1 added capabilities without generic plugin semantics | Continue rejecting high-frequency bridge surfaces unless they move to native screens or offline islands |
| Environment-sensitive native proof needs lane design | Android JVM proof was fast after splitting from emulator proof | Keep merge-blocking and advisory native proof separate |
