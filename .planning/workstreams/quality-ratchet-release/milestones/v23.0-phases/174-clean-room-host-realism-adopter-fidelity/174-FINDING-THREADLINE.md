# Finding: crosswake_threadline clean-room failure

**Status: GREEN, as of this phase's own run. Root cause named below, not assumed.**

## Versions run

`crosswake_threadline` has exactly one published release on Hex.pm: `0.1.0`, inserted
2026-07-04T17:35:01Z. That single version is simultaneously "the version that failed on
2026-07-03" and "the version an adopter would get today" — there is no distinction to draw for
this companion, unlike a package with multiple releases. Confirmed via
`https://hex.pm/api/packages/crosswake_threadline` (`latest_version: "0.1.0"`, one entry in
`releases`).

## How it was run

Local invocation of the harness this phase's sibling plan (174-01) repaired, against the live
published package:

```bash
ASDF_ELIXIR_VERSION=1.19.5-otp-27 ASDF_ERLANG_VERSION=27.3 \
  bash script/verify_companion_cleanroom.sh crosswake_threadline 0.1.0
```

CI dispatch was not available for this run: plan 174-04 established that
`clean-room-proof-rehearsal.yml` cannot be dispatched from this feature branch (GitHub refuses
`workflow_dispatch` for a workflow not yet on the default branch — verbatim refusal recorded in
`174-CLEANROOM-EVIDENCE.md`), and the release-lane's own `clean-room-proof-threadline` job has
never executed in this repository's history (every `clean-room-proof-*` job across the last 60
`release-please.yml` runs is `skipped`). The local invocation is therefore the only run obtainable
in this phase, exactly as plan 174-01 established for rindle. Full combined output captured to
`evidence/174-threadline-run.log` (785 lines) by redirecting stdout+stderr to the file and reading
the command's own exit status directly (not through a pipeline).

## Observed outcome

Exit code `0`. The harness's own terminal line:

```
[crosswake] OK: verify_companion_cleanroom: package=crosswake_threadline version=0.1.0 core_floor=~> 0.2 selected_core=0.2.1 profile=threadline-observer state=passed
```

Step-by-step: Hex metadata resolved, throwaway host created, deps installed, compiled with
`--warnings-as-errors`, router compiled, Step 5's inline smoke test (the three module-shipment
canaries substituted for the companion-behaviour assertions threadline does not implement) ran
**4 tests, 0 failures**, Step 6.5's `mix crosswake.install` completed, and Step 7's
`mix crosswake.doctor --router CleanRoomHost.Router` reached `state=doctor-green` with no
`manifest_contract` finding anywhere in the log (`grep -c manifest_contract` on the captured log
returns 0).

## Named root cause

**Harness-side, and it is the same defect TODO-011 diagnosed for rindle — not a separate
threadline-specific bug.**

Prior to this phase's plan 174-01 (commit `d04397a4`), the legacy positional path's Step 4 wrote
an unconditional, profile-independent router stub:

```elixir
defmodule CleanRoomHost.Router do
  use Phoenix.Router
  # minimal router stub — no routes required for doctor smoke (Open Question 1)
end
```

This block ran for **every** `PACKAGE` value — it is not gated by a `case`/`if` on the profile,
unlike the module-shipment canary logic that IS threadline-specific. Step 7's
`mix crosswake.doctor --router CleanRoomHost.Router` invocation is likewise unconditional. A
router with zero routes compiles to a manifest with no `:routes` section, which is exactly the
`manifest_contract (manifest_invalid)` failure TODO-011 root-caused for rindle at
`lib/crosswake/doctor/doctor.ex:1904-1948`. Because threadline runs through the identical Step 4
→ Step 7 code path as rindle — sharing the same unconditional router-then-doctor sequence, with
only the intervening Steps 5/6 differing by profile — a routeless router would have produced the
identical `manifest_contract` block for threadline that it produced for rindle. This is a
structural fact about the pre-174-01 script, verified here directly against
`d04397a4~1:script/verify_companion_cleanroom.sh`, not a guess about what a shared code path might
have done.

Plan 174-01's fix (a real `CleanRoomHost.Router` route carrying `metadata: %{crosswake: [...]}`,
plus the new Step 6.5 `mix crosswake.install` call) is likewise unconditional — it was written to
repair rindle's failure specifically, but it applies to every profile that reaches Step 4/Step 7,
threadline included. That is the **specific mechanism**: the fix is in shared, profile-independent
code, and this phase's run demonstrates the shared fix closed threadline's path through the same
gate, not merely that threadline "probably" benefited.

## What this finding does NOT claim

The original 2026-07-03 failing run (release-please run `28714131245`) is older than the default
log retention window and its log could not be retrieved for direct comparison — this finding does
not claim to have read that log and confirmed the failure text was `manifest_contract`. What it
claims, and can support, is narrower and fully evidenced: (1) the pre-174-01 script's Step 4/Step 7
sequence was structurally identical for every profile, so a routeless-router failure at Step 7
would necessarily have reproduced for threadline exactly as it did for rindle; (2) this phase's own
run, on the repaired harness, is green with zero `manifest_contract` occurrences. If the original
2026-07-03 failure was in fact something else entirely (a true "module-shipment variant" distinct
from the routeless-router defect), that alternate cause is not ruled out by this finding — only
that whatever it was, the harness as it exists today after 174-01 does not reproduce it, and the
one class of failure this reasoning does account for (the shared manifest_contract defect) is
independently verified fixed.

## Harness-side vs. package-side

**Harness-side.** `crosswake_threadline 0.1.0` itself resolved from Hex, compiled clean under
`--warnings-as-errors`, and passed its module-shipment smoke test (4/4) — nothing in this run
implicates the published package.

---
See also: `174-FINDING-SIGRA.md` (sibling finding — separate companion, separate root cause).
