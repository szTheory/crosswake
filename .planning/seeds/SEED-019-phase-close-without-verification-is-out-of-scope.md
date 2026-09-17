---
id: SEED-019
title: A phase that closes with no VERIFICATION.md falls out of the convention check's scope instead of failing it
status: dormant
severity: medium
trigger_when: >-
  Surface when hardening proof quality, when an executor dies mid-phase and the
  orchestrator flow is interrupted, or when adding any check whose scope is
  derived from the presence of the artifact it means to police. NOT blocking.
created: 2026-09-17
related: [SEED-018, TODO-009]
---

# SEED-019: the phase-close convention check cannot see a phase that closed with nothing

## The finding

`test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` enforces that every
closed phase records a `## Vacuity Taxonomy` section. It derives the set of phases it
applies to from `phase_dirs_with_verification/0`:

```elixir
|> Enum.filter(fn dir ->
  dir |> Path.join("*-VERIFICATION.md") |> Path.wildcard() |> case do
    [] -> false
    _ -> true
  end
end)
```

A phase directory with **no** `VERIFICATION.md` at all therefore returns `false` and
drops out of the roster. The check is green not because the phase complied, but because
the check declined to look at it.

This is one level up from SEED-018. There, an assertion examined an empty collection and
passed. Here, the *scope selector* silently empties, and the assertion never runs at all.
The module's own docstring is explicit that completeness must be a POSITIVE assertion,
never an inference from absence — that discipline is applied to the taxonomy section
within a phase, but not to the existence of the phase's verification artifact.

## How it actually fired

Phase 171 (Version/Authority Split) merged as `501e4410` via PR #178 with 49/49 CI checks
green and **no `VERIFICATION.md`**. Both the 171-03 and 171-05 executors died mid-run
(an `ENOTFOUND` API death and a stream-watchdog termination), and the phase-close step
of the orchestrator flow went with them. Nothing failed. Nothing warned.

It was caught by reading the test's scoping predicate while investigating something else —
not by any check in the repository.

## Measured scope of the gap (2026-09-17)

Counted across every live phase directory under `.planning/workstreams/*/phases/`:

```
phase dirs carrying at least one *-SUMMARY.md : 11
of those, missing *-VERIFICATION.md           : 1
```

The one survivor is `first-b2c-adopter-readiness/phases/163.1-close-gap-v21-physical-adopter-composition`:
all three of its plans are checked off in that workstream's ROADMAP, but the phase has no
`VERIFICATION.md`. That workstream is parked on an external dependency, so this may be an
in-flight phase rather than a defect — it is recorded here as a weaker instance, not as a
confirmed one.

Phase 171 was the second instance and is now closed: its `VERIFICATION.md` landed in
`5e89462d`, which brought 171 into the convention check's scope for the first time. The
check still passes (7 tests, 0 failures) — this time because the record genuinely exists.

So the present count of confirmed instances is **0**, and that is exactly why this is a
seed and not a phase: the defect is in the shape of the guard, not in the current tree.

## The remediation shape

A positive roster assertion that does not derive its own scope from the artifact it
polices. Two candidate sources of truth, either of which is independent of the
`VERIFICATION.md` glob:

1. Every phase whose ROADMAP entry is checked `[x]` must have a `VERIFICATION.md`.
2. Every phase directory containing at least one `*-SUMMARY.md` (i.e. work was executed)
   must have a `VERIFICATION.md`, or be explicitly listed as in-flight.

Option 2 has the better failure direction — a dead executor leaves SUMMARY files behind,
so the evidence that work happened is exactly the evidence that triggers the check.

Whichever is chosen, it needs the same non-vacuity proof every check in this milestone
carries: extract the predicate as a pure function over a directory listing so a synthetic
fixture can prove it returns `false`, rather than resting on a currently-compliant tree.

## Why this is not urgent

No unverified phase is currently sealed. The cost of the gap is bounded by how often an
executor dies mid-phase — twice in phase 171 alone, which is why it is worth recording
rather than forgetting.
