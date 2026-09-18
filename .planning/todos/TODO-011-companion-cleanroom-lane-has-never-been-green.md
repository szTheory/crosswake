---
id: TODO-011
title: The post-publish companion clean-room lane has never passed, and it cannot pass as written
status: open
created: 2026-09-15
severity: high
surfaced_by: publishing crosswake_rindle 0.1.0 (release-please run 35007664428)
relates_to: SEED-014, SEED-017, PROOF-01, PROOF-02, D-15, D-16
---

# The companion clean-room proof lane has never been green

## Outcome

A companion publish is followed by a proof that actually exercises what an adopter does, and that
proof is either green or acted on. Today it is neither.

## What happened

Merging PR #146 published `crosswake_rindle 0.1.0` to Hex (confirmed live). The publish job
succeeded; the release-please run still reported **failure**, because
`clean-room-proof-rindle` failed.

This is not specific to rindle. Every companion clean-room run inspected has failed:

| Date | Companion | Job outcome | Cause |
|---|---|---|---|
| 2026-07-03 | `crosswake_threadline` | failure | (module-shipment variant; not diagnosed here) |
| 2026-08-09 | `crosswake_sigra` | failure | smoke test, `test/smoke_test.exs:21` |
| 2026-09-15 | `crosswake_rindle` | failure | `doctor` — `manifest_contract (manifest_invalid)` |

> **2026-09-18 (Phase 174 Plan 5):** the threadline row above is now diagnosed —
> `174-FINDING-THREADLINE.md`.
> **2026-09-18 (Phase 174 Plan 5):** the sigra row above is now diagnosed —
> `174-FINDING-SIGRA.md`.
> This table is left intact as the historical record and the independent roster source the
> `Crosswake.Proof.Phase174CompanionFindingsTest` mechanical check reads from.

The lane has essentially never been green, and the packages published anyway.

## Root cause of the rindle failure

Reproduced locally (`bash script/verify_companion_cleanroom.sh crosswake_rindle 0.1.0 rindle
Rindle`, with `ASDF_*` pinned). Steps 1-6 pass: the package resolves from Hex, compiles under
`--warnings-as-errors`, the router stub compiles, the public-seam smoke test passes 5/5. Step 7
runs `mix crosswake.doctor` and blocks:

```
[error] manifest_contract (manifest_invalid)
manifest is missing required top-level section :routes
hint: populate :routes before manifest serialization
```

The cause is the harness's own host, and it is self-documented. `verify_companion_cleanroom.sh`
Step 4 writes:

```elixir
defmodule CleanRoomHost.Router do
  use Phoenix.Router
  # minimal router stub — no routes required for doctor smoke (Open Question 1)
end
```

That comment records an assumption — *no routes required* — which `doctor` does not hold. The
manifest compiled from a routeless router has no `:routes` section, so `manifest_contract` blocks.
The harness also never runs `mix crosswake.install`, which `doctor` separately (and correctly)
flags as an advisory warning.

**`crosswake_rindle 0.1.0` itself is not implicated.** It resolved, compiled clean, registered, and
passed its smoke test. The failure is the proof host being too minimal to satisfy the contract the
proof asserts.

## Current status (2026-09-18, Phase 174 Plan 5)

All three rows in the failure table above now have a named root cause: rindle's is recorded in
this file (above); threadline's and sigra's are recorded in their own separate findings
(`174-FINDING-THREADLINE.md`, `174-FINDING-SIGRA.md`) per ROADMAP SC#5 / ROOM-05, which forbids
one finding covering more than one companion. Diagnosis is complete for all three. **This todo
stays `open`**: the repair decision this file asks for (make the clean-room host realistic vs.
narrow `doctor`'s route requirement) has been acted on for the harness paths threadline and
rindle share with the router-then-doctor sequence (Phase 174 Plan 1, commit `d04397a4`) and for
sigra's smoke-test template (commit `d16e475a`, pre-dating this phase), but the release-lane's own
`clean-room-proof-*` jobs have never executed in CI (confirmed in
`174-CLEANROOM-EVIDENCE.md`) — the lane's live green run is still the open item this todo tracks.

## Why this went unnoticed

`clean-room-proof-*` has `needs: publish-hex-*` (D-15 / PROOF-02), so the proof runs **after** the
one-way door. It cannot block a publish — by design, since a published package cannot be proven
before it is published. The consequence is that a red proof costs nothing at the moment it matters
and has to be acted on deliberately. Across three releases it was not.

## The decision this needs (do not guess it)

Two repairs are available and they are not equivalent:

1. **Make the clean-room host realistic** — declare a real Crosswake route and run
   `mix crosswake.install` before `doctor`. This makes the proof *stronger*: it would exercise what
   an adopter actually does. It is also more work and may surface further genuine failures.
2. **Scope `doctor`'s route requirement** so a registration-only clean room is not held to a full
   host contract. This makes the proof *narrower* and touches `doctor` semantics other phases
   depend on.

Recommended: **(1)**. A proof that skips the step an adopter performs is not worth the CI minutes,
and option (2) risks weakening a contract to make a harness pass — the same anti-pattern recorded
in TODO-009.

Whichever is chosen, the threadline and sigra failures above are separate causes and must be
diagnosed on their own; fixing the rindle cause will not turn the lane green by itself.

## Do not

- Do not mark the lane non-blocking or delete the failing jobs. A proof that has never passed is a
  finding, not noise.
- Do not weaken `doctor`'s `manifest_contract` check to accommodate the harness without deciding
  (2) deliberately.

## Breadcrumbs

- `script/verify_companion_cleanroom.sh` Step 4 (router stub, "Open Question 1"), Step 7 (doctor)
- `lib/crosswake/doctor/doctor.ex:380-401` — `Manifest.compile/2` error path into
  `manifest_compile_check/1`
- `lib/crosswake/doctor/doctor.ex:1904-1948` — the catch-all that emits `manifest_contract`
- `lib/crosswake/doctor/doctor.ex:234-277` — `load_install_manifest/1`, the advisory warning
- `.github/workflows/release-please.yml` — `clean-room-proof-rindle` and siblings, each
  `needs: publish-hex-*`
- release-please run 35007664428 (rindle), 31325689640 (sigra), 28714131245 (threadline)
- `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md` — the proof-lane fidelity seed this
  belongs to
