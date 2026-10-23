# Phase 187 discussion log

**Date:** 2026-10-16
**Mode:** advisor (minimal-decisive tier), three parallel research agents
**For human reference only.** Downstream agents read `187-CONTEXT.md`.

## Areas offered

| Area | Selected |
|------|----------|
| Unknown provenance: sentinel or refuse when the commit, version or template is unknown | yes |
| Offline check severity: error or warning for local_first without island_contract | yes |
| Deferral record home: CW-REQ-A/D | yes |

Owner instruction, given with the selection: fan out across all relevant lenses (security, product, technical, devops, Elixir idiom, an adversarial pass) and use primary sources where possible. Synthesize one coherent set of recommendations and follow it without further questions. Prefer copying code to adding a dependency.

## Scouting finding that framed the provenance area

`evidence.ex` `git_ref/1` accepts any 40- or 64-hex string, so the all-zero placeholder passes validation today. An "unknown" sentinel would be rejected, which would block every evidence write. The requirement's "explicit sentinel" therefore needs a validator change.

## Recommendations adopted

| Area | Options weighed | Adopted |
|------|-----------------|---------|
| Sentinel vs refuse | (A) closed sentinel set accepted, (B) refuse to write | A. Advisory evidence must not break non-git hosts. Sentinel evidence is never promotable, and physical evidence rejects sentinels (D-02, D-03). |
| Promotion of sentinel evidence | (A) never promotable, (B) promote with a warning | A (no silent degrade) |
| Value sources | Application.spec / gen.shell constant / host HEAD / device class | Host manifest template version first, then the constant. Host HEAD, with a dirty tree giving `git-unknown`. device_class stays `:unknown` (D-01, D-04). |
| Git access | System.cmd vs parsing `.git` | System.cmd with find_executable, no shell (D-05) |
| Validator strictness | all-zero only vs entropy heuristics | all-zero plus the exact sentinel allow-list (D-02) |
| Offline severity and scope | (A) error with the filter widened, (B) error with C8 scope, (C) warning | B (D-07, D-09) |
| Not claimed | (A) `:not_claimed` status plus an advisory finding, (B) `:supported` plus a flag | A. The atom already exists (D-08). |
| Unmanaged details | sorted, inspect'ed router vs raw | sorted unique paths, `inspect(module)` (D-10) |
| Compile-time rule | defer with a trigger vs implement now | defer, with observable triggers (D-12) |
| Deferral home | phase file plus pointers / seed only / ADR / requirements only | `187-DEFERRALS.md` plus pointers (D-13) |
| CW-REQ-A trigger | both readings / reading 1 only / not met | both readings, defer either way (D-14) |
| Machine check | none / verification-time structure check / ExUnit pin | verification-time structure check (D-16) |

## Adversarial notes kept

- A fake non-zero hash cannot be told apart from a real one. The defence is that evidence comes only from the task and that promotion requires known provenance, not an entropy check.
- The two offline-claim gaps that remain were recorded rather than silently ignored (D-09).
- The stop-list argument for CW-REQ-A is weak, because the ADR has no haptics entry. It was kept only as a secondary point.

## Deferred

See `187-CONTEXT.md` `<deferred>`.
