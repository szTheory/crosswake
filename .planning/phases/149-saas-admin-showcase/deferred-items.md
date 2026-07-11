# Phase 149 Deferred Items

## 149-02 Out-of-Scope Verification Findings

- `cd examples/phoenix_host && mix test` still fails on the intentionally RED Wave 0 contracts owned by later Phase 149 plans:
  - `:diagnostics_route_rows` and `:diagnostics_enrichment` require `CrosswakeExample.SaaSPortal.Diagnostics.route_policy_rows/1` from plan 149-03.
  - `:approval_schema_persistence` and `:approval_context_workflow` require approval persistence/context functions from plan 149-04/149-06.
  - `:approval_queue_live` and `:approval_detail_live` require AdminPilot LiveView UI states from plan 149-05/149-06.
- Regression check passed for all non-deferred tests with:
  `cd examples/phoenix_host && mix test --exclude diagnostics_route_rows --exclude diagnostics_enrichment --exclude approval_schema_persistence --exclude approval_context_workflow --exclude approval_queue_live --exclude approval_detail_live`
