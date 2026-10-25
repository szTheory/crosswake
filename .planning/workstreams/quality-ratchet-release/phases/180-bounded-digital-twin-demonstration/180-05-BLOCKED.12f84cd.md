---
phase: 180-bounded-digital-twin-demonstration
plan: 05
subsystem: example-host generated iOS shell
status: blocked
requirements: [TWIN-01, TWIN-02, TWIN-04]
requirements_completed: []
plan_head_before: 12f84cd950d4574921767df823faed6797c17c26
plan_head_after: 12f84cd950d4574921767df823faed6797c17c26
actuals:
  tokens: 0
  tasks: 0
  commits: 0
blocked_prerequisite: TW-T02-01
---

# Phase 180 Plan 05: Generated iOS host for the twin - BLOCKED, not executed

## What happened, in plain terms

The gate check passed, so I started Task 1. Task 1 needs the generated iOS app to be
frozen at the fixed local address `http://127.0.0.1:4790`. I checked whether the existing
generator can do that, and it cannot. The plan says that in this case I must record the
prerequisite as blocked and stop without changing the generator, so I did. No source
file, project file, simulator or identity record was changed. Zero tasks ran and zero
requirements are complete.

## What was checked

- GATE_CHECK ran first and exited 0 (verdict `existing_path_supported`, decision
  `not_required`, 180-04 summary present and not retired).
- I called the generator's declaration validator (`Crosswake.Shell.IOSHostConfig.normalize/1`)
  with the exact planned values (origin `http://127.0.0.1:4790`). It refused with:
  "invalid origin; use an absolute HTTPS origin without credentials, path, query, or
  fragment". The validator in `lib/crosswake/shell/ios_host_config.ex` only accepts
  `https://` origins (and rejects hosts containing "example").
- The other route, legacy `mix crosswake.gen.shell ios --local` (no declaration), does
  not take an origin at all. It writes the built-in placeholder
  `https://example.crosswake.invalid` (`Types.default_origin/0`). It also cannot be
  used with `--check`, which requires the declaration. `--local` only chooses a local
  package reference, not a local origin.
- So no supported mode puts `http://127.0.0.1:4790` into the generated manifest and
  activation, and D-14 forbids the runner or this plan from changing it afterwards.

## What changed

Nothing in the candidate. The only side effect was compiling `examples/phoenix_host`
into its ignored `_build` directory while running the validator. No simulator
`crosswake-phase180-unit` was created (Task 1 had not reached that step), so there is
nothing to delete. `180-IDENTITY.json` still holds only the 180-04 media record.
Recovery checkout: nothing staged, only this file written.

## Unknown

Whether a small separately authorized change to the generator (allow a loopback HTTP
origin in a clearly local/dev-only mode) is acceptable. That is a core-seam change, an
architectural decision (deviation Rule 4), not something this plan may do. Phase 179
documents loopback only as a flagged assumption; I found no loopback mode in its docs
or code.

## Next action

A person decides one of:
1. Authorize a narrow generator change (local/dev loopback HTTP origin, plus matching
   App Transport Security posture already planned: `NSAllowsLocalNetworking` only), then
   re-run 180-05 from Task 1 (the gate would need a fresh rerun for the changed core,
   per the plan's execution boundary).
2. Serve the twin over HTTPS at a fixed local origin (needs a trusted certificate
   story), and change D-14 and plan 180-05 accordingly.
3. Defer TWIN-01/02/04 media-side proof.

Tasks 2 and 3 (study WebView, installer, audio delegate) depend on Task 1 and were not
started. Also still open from 180-04: the island contract uses route id `study-session`
while the router id is `offline-study`; it did not affect this plan because it stopped
earlier.

## Deviations from Plan

None in the work done. The stop itself is the plan's own specified outcome for this case.

## Self-Check: PASSED

- Candidate git status shows no iOS or config changes: confirmed.
- Recovery checkout staged files: 0.
- Simulator named phase180: none exists.
