---
phase: 182-loopback-origin-for-local-ios-host
plan: 02
subsystem: ios-host-generation
tags: [origin_mode, local_loopback, info-plist, reconcile, check, fail-closed]
requires: ["182-01"]
provides:
  - "Crosswake.Shell.IOSHostOriginMode: bounded reconcile of the Crosswake-owned Info.plist block"
  - "ManagedOutputs.read_origin_plist/1 and write_origin_plist/3"
  - "gen.shell reconcile on every ios generation; --check/--diff origin-mode drift; D-13 line; README banner"
affects: [182-03]
key-files:
  created:
    - lib/crosswake/shell/ios_host_origin_mode.ex
    - test/crosswake/shell/ios_host_origin_mode_test.exs
  modified:
    - lib/crosswake/shell/managed_outputs.ex
    - lib/mix/tasks/crosswake.gen.shell.ex
    - test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs
status: complete
commits: 2
plan_head_before: bfd470d7535c6b77b85e636981d87a1936d5e775
plan_head_after: ecc2450eebef0167c1867b07eaa47f315e3632b9
actuals:
  tokens: 45000
  tasks: 2
  commits: 2
---

# Phase 182 Plan 02: Info.plist reconcile and mode-drift check Summary

Switching the declaration between production and local loopback now adds or removes exactly the Crosswake local-networking block in the generated Info.plist, and `mix crosswake.gen.shell ios --check` tells the truth about it. Returning to HTTPS restores the production golden byte for byte.

## What was checked and what happened

- Candidate binding (CHECK182) passed before any edit; all work and commits are in `/private/tmp/crosswake-phase182-impl` on `phase182-impl`.
- Task 1 verify (verbatim): exit 0, 4 tests, 0 failures at that point.
- Task 2 verify (verbatim, including freeze checks, template grep gate, the D-09 string gate and the ExUnit ownership script): exit 0 on the second run; shell plus mix-task suites 295 tests, 0 failures (4 excluded by the plan's default exclusions). The new tests: 17 pure tests and 13 gen.shell origin-mode tests (the 182-01 production manifest test still passes unchanged).
- The first Task 2 run failed only at the literal-string gate because the drift message used an interpolated repair; I made the message literal and re-ran the whole verify.

## The reconcile decision in plain words (D-23)

Info.plist is still written once by `ensure_file/2` and stays host-owned; it is not a managed output and `@paths` still has three entries. A new pure module owns only the exact Crosswake block (ATS dict with just `NSAllowsLocalNetworking`, plus `CrosswakeOriginMode local_loopback`). On every `gen.shell ios` run, including the legacy path with no `:ios_host`, the generator reads the plist, computes the wanted bytes for the declared mode (nil when nothing is declared), and replaces the file atomically through a ManagedOutputs sibling pair only if the bytes differ. A local-generated target regenerated after `:ios_host` is removed loses exactly the block and equals the production golden. File permissions are preserved on rewrite.

## Production-host exception as implemented (D-23)

- No declared mode: a host-owned `NSAppTransportSecurity` dict without the `CrosswakeOriginMode` marker is left untouched (no refusal, no write), even if it contains an arbitrary-loads or exception-domain key. `--check`/`--diff` report no drift for it.
- Local mode declared: the same host-owned dict, any other ATS shape, any forbidden ATS key, or a missing or duplicated `LSRequiresIPhoneOS` anchor makes generation raise `blocked; cause: info_plist_conflict` with a repair, bytes unchanged.
- A `CrosswakeOriginMode` key in any non-exact shape is a conflict in both modes.
- Repair path: remove or merge the host dict by hand, then rerun `mix crosswake.gen.shell ios`.

## --check, --diff, D-13 and README

- `--check` compares the plist against the declaration before the managed-output check. A mismatch prints `blocked; cause: origin mode changed; repair: rerun mix crosswake.gen.shell ios` and raises; `--diff` prints `needs-attention` with the same cause and does not raise. Declared local with a missing or unreadable plist is a mismatch; declared nothing with a missing plist is not.
- A current local build prints exactly one extra line starting `origin mode: local loopback (<canonical origin>); Simulator only; ...`; production prints none. The freshness result and exit status are unchanged.
- README banner is added only on first creation in local mode via `shell_readme/2`; production README bytes are unchanged and `README.md.eex` is untouched. The managed metadata, manifest and activation schema gained no mode field.

## Commits (in candidate phase182-impl)

- 9a17c54 feat(182-02): reconcile the Crosswake Info.plist block with the declared origin mode
- ecc2450 test(182-02): cover conflict refusal, mode drift, D-13 line, README banner and forbidden keys

Candidate head `ecc2450eebef0167c1867b07eaa47f315e3632b9`, tree `2b87c083f8379f1c18b482ba09f1715eb1301174`.

## Deviations from Plan

- **TDD ordering:** Task 2 is marked `tdd="true"`, but I wrote the Task 1 implementation first and the Task 2 behavior tests after the pure module already satisfied them, so no separate RED commit exists. The tests were still written to the plan's behavior bullets and all pass. No RED evidence is claimed.
- **Reconcile placement:** the reconcile runs right after `render_ios_templates` and before fixture writes and the managed publish, so a refusal leaves no half-written fixtures.
- `lib/crosswake/shell/shell_package.ex` has a pre-existing formatting difference; it was not touched.

## Known Stubs

None.

## Threat Flags

None beyond the plan's threat model (T-182-06 through T-182-09, T-182-27 are covered by the round-trip, legacy-path, refusal, missing-plist and production-host tests).

## Boundary state

Recovery checkout HEAD `d0f3e2f1` with an empty index; no Git write there. Phase 180 clone HEAD `12f84cd` with its 21 dirty paths untouched; Phase 181 clone untouched. Candidate working tree clean after the second commit.

## Next action

Execute 182-03.

## Self-Check: PASSED
