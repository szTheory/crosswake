# Phase 149 Deferred Items

## 149-02 Out-of-Scope Verification Findings

- `cd examples/phoenix_host && mix test` previously failed on intentionally RED Wave 0 contracts owned by later Phase 149 plans:
  - `:approval_schema_persistence` and `:approval_context_workflow` require approval persistence/context functions from plan 149-04/149-06.
  - `:approval_queue_live` and `:approval_detail_live` require AdminPilot LiveView UI states from plan 149-05/149-06.
- `:diagnostics_route_rows` and `:diagnostics_enrichment` were resolved by plan 149-03.
- Regression check passed for all non-deferred tests with:
  `cd examples/phoenix_host && mix test --exclude approval_schema_persistence --exclude approval_context_workflow --exclude approval_queue_live --exclude approval_detail_live`

## 149-04 Out-of-Scope Verification Findings

- Plan 149-04 resolved the approval persistence/context contracts:
  - `:approval_schema_persistence`
  - `:approval_context_workflow`
- `cd examples/phoenix_host && mix test` now fails only on intentionally RED Wave 0 LiveView contracts owned by later Phase 149 plans:
  - `:approval_queue_live` requires AdminPilot approval queue loading/status/support UI states from plan 149-05/149-06.
  - `:approval_detail_live` requires AdminPilot approval detail server-authority, disabled/success, and bridge-absent render states from plan 149-06.
- Regression check for this plan should exclude only the remaining later-plan LiveView tags:
  `cd examples/phoenix_host && mix test --exclude approval_queue_live --exclude approval_detail_live`

## 149-05 Out-of-Scope Verification Findings

- Plan 149-05 resolved the shared AdminPilot shell, context-page rendering, inline diagnostics, scoped CSS, and non-approval page posture contracts.
- `cd examples/phoenix_host && mix test` still fails only on intentionally RED Wave 0 approval workflow LiveView contracts owned by plan 149-06:
  - `:approval_queue_live` requires AdminPilot approval queue loading/status/support UI states.
  - `:approval_detail_live` requires AdminPilot approval detail server-authority, disabled/success, and bridge-absent render states.
- Regression check for plan 149-05 passed with:
  `cd examples/phoenix_host && mix test --exclude approval_queue_live --exclude approval_detail_live`
