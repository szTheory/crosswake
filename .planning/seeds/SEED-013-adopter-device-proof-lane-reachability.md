---
id: SEED-013
status: dormant
planted: 2026-09-14
planted_during: quality-ratchet-release Phase 168
trigger_when: next milestone scoping after 0.2.1, or any milestone touching gen.shell, the proof lane, or adopter upgrade ergonomics
scope: small-to-medium
severity: contains one high-severity item (TODO-003)
---

# SEED-013: Make the device proof lane actually reachable by an adopter

## Why This Matters

This is the first signal from a real production adopter that reached a **physical-device** proof —
not a simulator run, not a dress rehearsal. Getting there required hand-patching Crosswake's
generated output in three places. Two of those patches make Crosswake's own **documented** proof
posture unreachable as generated.

The pattern across every item below is the same: **the Simulator hides it.** Signing is not
enforced, the host filesystem is shared, and app stdout lands in the `xcodebuild` log. Every one of
these defects is simulator-green and device-red, which means the repo's existing proof lanes cannot
catch them and an adopter discovers them late, with hardware in hand.

That is the frontier this seed is about: Crosswake's evidence posture is strong up to the
simulator boundary and untested past it.

## When to Surface

**Trigger:** next milestone scoping after 0.2.1, or any milestone touching `mix crosswake.gen.shell`,
the proof-lane templates, or adopter upgrade ergonomics.

The high-severity item (TODO-003) should not wait for this seed — it is already actionable.

## Scope Estimate

**Small-to-medium.** The signing work is template edits plus a generation-time flag. The rest is
documentation and one doctor finding.

## Contents

Tracked in full as todos; summarized here so the seed reads standalone.

| Item | Severity | Status | What |
|---|---|---|---|
| TODO-003 (CW-REQ-M3) | high | verified in-repo | Generated iOS test targets ship `CODE_SIGNING_ALLOWED/REQUIRED = NO` and empty `DEVELOPMENT_TEAM`, including both XCUITest targets. The runner is an app; it cannot install on hardware. Device proof lane is unreachable as generated. |
| TODO-004 (CW-REQ-M6) | low | verified in-repo | Stale `install_manifest.json` namespace is neither migrated nor re-derived after the 0.2.1 derivation fix; the error message points at `lib/` instead. |
| CW-REQ-M4 | low (downgraded) | see triage | Device-lane fixture access. |
| CW-REQ-M5 | low (downgraded) | see triage | Evidence emission from the test process. |
| CHANGELOG discipline | low | verified in-repo | `doctor`'s finding-set change is not named under Upgrade Impact. |

## Triage notes — where the adopter report overstated Crosswake's fault

Recorded deliberately, so a future planner does not re-open these as template defects.

- **CW-REQ-M4** (`#filePath` fixtures resolve a build-machine path, simulator-green / device-red).
  The `#filePath` pattern does **not** appear anywhere in `priv/templates/crosswake/`. This is the
  adopter's own pattern, not generated output. The residual ask is real but is a **documentation**
  ask: the proof-lane guide should say that device-lane fixtures must be bundled as target
  resources and read via `Bundle(for:).url(forResource:)`, because a source-relative path is
  simulator-only.

- **CW-REQ-M5** (evidence printed by the app under test never reaches `xcodebuild` from a device —
  produced a false `"result": "pass"` with null hardware facts). The adopter names this as their
  own defect, and the generated template is already correct:
  `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex`
  emits its markers (`PACK-MISSING-PROVIDER`, `PACK-INSTALL-READY`, …) from the **test** process.
  The residual ask is a single guide sentence making the *reason* explicit — only the test
  process's stdout is the `xcodebuild` log on every destination — since this is the file adopters
  copy the pattern from. A generated example that reads a fact back out of the accessibility tree
  and prints it from the test would make the right pattern the obvious one.

  **The interesting part is not the defect, it is the failure class:** a proof lane that reports
  `pass` while its hardware facts are null. Worth a look at whether Crosswake's evidence schema can
  fail closed on null-but-required facts rather than trusting a `result` field.

## CHANGELOG ask (confirmed-good item with a cost)

`mix crosswake.doctor`'s new posture — *automatic mode treats a host with no generated native
shell as not claiming native support, instead of failing on absent native proof hooks* — is
confirmed by the adopter as the right call. It removed four permanently-unfixable findings for a
host that structurally will never generate an Android shell.

But it **changes doctor's finding set**, so any adopter pinning an expected-findings register sees
it as drift and red CI. Theirs did, and it took reading the CHANGELOG to establish the drift was an
improvement rather than a regression.

Verified: the current `[Unreleased]` **Upgrade Impact** section is labeled *compatibility-bump only*
and covers `manifest_schema_version` 1.0.0 → 1.1.0 — it does **not** name the doctor finding-set
change. A sentence naming which finding codes stop being emitted for a host with no generated shell
turns a debugging session into a diff.

Generalize this: **a change to doctor's finding set is an upgrade-impacting change**, because
adopters pin finding registers. That belongs in the Upgrade Impact discipline, not just this once.

## Breadcrumbs

- `.planning/todos/TODO-003-generated-ios-test-targets-unsignable.md` — the high-severity item, with
  exact line numbers.
- `.planning/todos/TODO-004-stale-install-manifest-namespace-not-self-healed.md`
- `.planning/todos/TODO-005-adopter-identity-in-published-artifacts.md` — incidental finding from
  the same triage; unrelated to the proof lane but surfaced by it.
- `.planning/seeds/SEED-004-cleanroom-proof-harness.md` — the clean-room harness seed is the natural
  home for "does the generated project build and install on hardware", which is the check that would
  have caught TODO-003 before an adopter did.
- `.planning/ADR-FIRST-B2C-ADOPTER.md`, `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — adopter
  posture of record.

## Provenance

First B2C Adopter, 2026-09-14, against published Hex `crosswake 0.2.1` (verified against the fetched
package, not a working copy). Reproducible from a clean `mix crosswake.gen.shell ios`. Device proof
was a tethered current-generation iPhone with haptics. Adopter-side identifiers, commit SHAs, team
ids, and bundle identifiers are deliberately excluded.
