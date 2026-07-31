# Deferred Items

- `mix test test/crosswake/planning/first_adopter_context_test.exs` currently fails because the
  executor-start update to `.planning/STATE.md` replaces the planning-stage
  `$gsd-discuss-phase 158` next action with `$gsd-execute-phase 158`. This is pre-existing to
  Plan 158-01's route-contract changes and should be reconciled by the phase's planning-state work.
