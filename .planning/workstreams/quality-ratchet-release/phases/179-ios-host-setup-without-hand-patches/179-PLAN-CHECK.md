## ISSUES FOUND

**Phase:** 179 — iOS Host Setup Without Hand Patches  
**Plans checked:** 4  
**Issues:** 0 blockers, 0 warnings, 3 info

### Prior findings disposition

- **Research-resolution blocker — resolved at planning level.** `179-RESEARCH.md` now has `## Open Questions (RESOLVED)` and four individually marked `RESOLVED (planning)` decisions. The answers identify the config keys and test-ID suffixes, bounded project migration, the selected Phoenix reference host with absent runtime credentials and a fail-closed feasibility gate, and the actual shell/proof target paths. The separate `## Execution Observations Pending` section explicitly says none of those host or Xcode outcomes has been observed. This resolves planning ambiguity without promoting an execution result.
- **Xcode expectation-source blocker — resolved.** 179-03 Task 2 now derives expected settings independently from the original host declaration retained in memory (and supplies the declared-host check through an in-memory pipe). It requires actual effective settings for five targets × Debug/Release × simulator/device SDK classes, and negative controls for coherent xcconfig-plus-metadata corruption and PBX masking. Generated settings and metadata are used for ownership/location, not as the expected-value oracle.

### Coverage summary

| Requirement | Plans | Status |
|---|---|---|
| IOS-01 | 179-01, 179-02, 179-03, 179-04 | Covered by host config/generation, ownership/check/recovery, proof projection and maintainer guidance/gates |
| IOS-02 | 179-01, 179-03, 179-04 | Covered by shell and proof identity/signing projection and the independent effective-settings matrix |
| IOS-03 | 179-01, 179-02, 179-04 | Covered by host-derived manifest/activation, invalid-input and interrupted-generation denial/recovery, and documentation/gates |

All eight locked decision groups are carried into executable task actions or acceptance criteria. Deferred Phase 180 behavior, physical-device/adopter promotion, Android expansion, release work, new dependencies, new CI lanes, and generic storage/runtime scope remain excluded. The task actions place config, route compilation, Xcode resolution, filesystem ownership, and diagnostics in the tiers described by the research responsibility map. New/changed files reference the analogs in `179-PATTERNS.md` or its read-first material.

### Plan mechanics and bounded scope

- All four `verify.plan-structure` results are valid. Each plan has two tasks; every task has files, action, automated verify, and measurable done criteria. The eight executable commands have stated failing directions in their `<fails_when>` elements; the supplied failure probe reports 0 blockers and 0 warnings. The supplied path probe reports eight `outside_root` warnings, retained below as an accepted qualified-candidate exception.
- Dependencies form four sequential waves: 179-01 → 179-02 → 179-03 → 179-04. No missing references, cycles, same-wave pairs, or undeclared coupling were found.
- Plans list 7, 7, 8, and 8 modified files, respectively, with two tasks each. Estimates are 29,000, 32,000, 28,000, and 18,000 tokens, each marked low confidence because calibration has no completed-phase actuals. Estimates are provisional, not execution evidence.
- Key links connect the ordinary host declaration to canonical route resources and effective Xcode settings, managed-output ownership to recovery/build denial, proof configuration to its targets, and canonical guide owners to rendered documentation.
- Nyquist planning is complete for the eight tasks: each has an automated command and a failing direction, with test creation owned before first use. `179-VALIDATION.md` correctly remains draft, with Wave 0 and Nyquist sign-off pending execution. This review did not run an application, build, test, generation, or repository verifier.
- The pinned source snapshot was inspected read-only and is clean at HEAD `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, tree `12a0f1bf3c32ecdde0326f4a288b597b11e33b06`.

### Advisories (info)

**1. [verify_command_path_resolvability] The qualified independent-candidate exception remains explicit.**
- Plans: 179-01–179-04
- Required property: Automated commands run only in the selected, qualified independent candidate.
- Evidence: The supplied path probe reports eight `outside_root` warnings for `/private/tmp/crosswake-phase179-impl`. Each plan requires candidate existence, realpath, Git top-level, and source-base checks before commands; the first tracer owns candidate creation and provenance. This is an accepted D-02/D-21 exception after qualification, not authorization to fall back to the recovery checkout.
- Example fix (non-binding): Retain each pre-command qualification gate and its result during execution.

**2. [scope_sanity] Estimate confidence is low because calibration has no phase actuals.**
- Plans: 179-01–179-04
- Required property: Estimate confidence is disclosed when project calibration is unavailable.
- Evidence: The four estimates are marked `confidence: low`; each is below the stated 100,000-token budget. The plans have two tasks apiece and at most eight listed modified files. Treat estimates as provisional and use task/file counts as the stronger scope signal.
- Example fix (non-binding): Record actuals after execution for future calibration; no plan change is required.

**3. [research_resolution] Runtime observations and retained probe classifications remain pending.**
- Plans: phase-level
- Required property: Planned evidence and unresolved probe classifications remain visibly pending until observed or classified.
- Evidence: `179-RESEARCH.md` separates planning resolutions from pending real-host, generated-path, Xcode-matrix, recovery, and migration observations. `179-VALIDATION.md` records IOS-01/02/03 as unclassified/unresolved in the spec-less probe and descriptor-less prohibitions as flagged-unverified. The plans neither convert these statuses to passes nor claim generated host, Xcode, signing, installation, physical-device, or adopter results.
- Example fix (non-binding): Preserve these statuses through execution and report actual outcomes and causes; no planning-stage test run is required.

### Structured Issues

```yaml
issues:
  - plan: null
    dimension: verify_command_path_resolvability
    severity: info
    required_property: "Automated commands run only in the selected, qualified independent candidate"
    description: "The supplied path probe reports eight outside_root warnings for /private/tmp/crosswake-phase179-impl. Each plan requires existence, realpath, Git top-level, and source-base checks before commands, with candidate creation/provenance owned by 179-01. The warnings remain an accepted D-02/D-21 exception after qualification and do not permit recovery-checkout fallback."
    fix_hint: "Retain each pre-command qualification gate and its result during execution."
  - plan: null
    dimension: scope_sanity
    severity: info
    required_property: "Estimate confidence is disclosed when project calibration is unavailable"
    description: "The four estimates are 18,000–32,000 tokens and each declares low confidence because calibration has no completed-phase actuals. Each plan has two tasks and no more than eight listed modified files."
    fix_hint: "Treat estimates as provisional and use task/file counts as the stronger scope signal."
  - plan: null
    dimension: research_resolution
    severity: info
    required_property: "Planned evidence and unresolved probe classifications remain visibly pending until observed or classified"
    description: "The research marks all four planning questions RESOLVED (planning), while a separate section leaves real-host, generated-path, Xcode-matrix, recovery, and migration observations pending. VALIDATION.md preserves IOS-01/02/03 as unclassified/unresolved in the spec-less probe and descriptor-less prohibitions as flagged-unverified; no plan promotes them to passes."
    fix_hint: "Preserve these statuses through execution and report actual outcomes and causes."
```

### Recommendation

Advisory only — no revision required. The earlier blocker findings are resolved. The remaining items are explicit execution constraints or provisional evidence; they do not prevent the plans from achieving the Phase 179 goal if their required gates pass. No plan-stage execution result is claimed.
