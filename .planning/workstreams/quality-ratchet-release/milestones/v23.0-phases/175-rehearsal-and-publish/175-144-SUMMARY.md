---
phase: 175-rehearsal-and-publish
plan: 144
subsystem: release-runner
requirements_completed: []
key-files:
  created: [script/release_candidate/plan144_tag_apply.mjs, lib/crosswake/release_candidate/plan144_tag_apply.ex]
  modified: [lib/mix/tasks/crosswake.release.mirror_tag_026.ex]
---

# Plan144: Production credential repair

The offline reproduction showed that the original runner rejects an absent token variable before any network or subprocess call. The successful preflight uses the configured noninteractive credential helper. The old runner also substitutes a username that cannot satisfy the preflight identity check.

Created a separate versioned runner using the existing configured GCM helper, preserving its supplied username. Startup helper operations are counted once even if a later read fails. Unavailable credentials produce BLOCKED with zero remote, tag and CI operations. Full current checks, durable intent, single-use choice, exact create-only push and terminal no-retry behavior remain enforced.

## Audit results

- Seven Node tests passed, including the production entry point with network and remote process boundaries denied and the token variable absent.
- Fourteen focused Elixir tests passed across the original and new runners.
- Original Plan142 Node/Elixir and Plan105 collector hashes match the saved baseline.
- No historical attempt was replayed; no actual helper, GitHub request, tag, CI or publication operation occurred. No staging, commits or worktrees.

## Next action

Last completed phase: 174. Phase175 remains incomplete. Plan144 local repair is complete. Continue with a separately reviewed fresh Plan145 card; previous approval does not transfer. Release requirements and held plans remain unchanged. No adopter work reopens.

## Self-Check: PASSED
