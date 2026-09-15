---
id: TODO-003
title: Generated iOS test targets ship unsignable — documented device proof lane cannot run
status: open
created: 2026-09-14
severity: high
surfaced_by: First B2C Adopter device-proof report (CW-REQ-M3), verified against this repo
relates_to: SEED-013, TODO-004, CW-REQ-M2 (--team-id)
---

# Generated iOS test targets ship unsignable

## Outcome

`xcodebuild test -destination 'platform=iOS,id=<UDID>'` succeeds against a generated shell on a
tethered device without the adopter hand-editing `project.pbxproj`.

## The defect (verified in this repo, 2026-09-14)

Every generated iOS target switches signing off, including the XCUITest targets:

- `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`
  - `CODE_SIGNING_ALLOWED = NO; CODE_SIGNING_REQUIRED = NO;` at lines
    274-275, 298-299, 315-316, 339-340, 363-364, 385-386
  - `DEVELOPMENT_TEAM = "";` at lines 318, 342
- `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex:72-77`
  — all six configurations, covering `CrosswakeProofLaneTests` and `CrosswakeProofLaneUITests`

An XCUITest runner is an app and must be signed to install on hardware. Install fails with
`MICodeSigningVerifier` / "`…UITests-Runner` cannot be installed".

## Why this went unnoticed

Simulator runs are unaffected — the Simulator does not enforce code signing. The failure only
appears on a physical device, i.e. late, with hardware in hand. This makes Crosswake's **own
documented** device proof lane unreachable as generated, for any adopter.

## Ask

Generated test targets should carry `CODE_SIGN_STYLE = Automatic` plus an adopter-supplied
`DEVELOPMENT_TEAM`, with `CODE_SIGNING_ALLOWED` / `CODE_SIGNING_REQUIRED = YES` on device-capable
configurations.

If signing-off is a deliberate hermetic-CI default, then the device lane needs a **generated,
documented** way to turn it on. Today the adopter hand-edits `project.pbxproj` — the one generated
file nobody should be hand-editing.

## Dependency

This needs a team id at generation time, which is exactly what CW-REQ-M2
(`mix crosswake.gen.shell --bundle-identifier / --team-id`) proposes. Sequence M2 first, or land
both together.

## Adopter workaround (do not ship this shape)

Set `CODE_SIGNING_ALLOWED`/`REQUIRED = YES`, `CODE_SIGN_STYLE = Automatic`, and a literal
`DEVELOPMENT_TEAM` on four test configurations by hand.
