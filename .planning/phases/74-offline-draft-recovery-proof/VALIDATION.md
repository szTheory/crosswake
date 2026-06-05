# Phase 74 Validation Matrix

This document maps the Phase 74 requirements to their specific validation steps and the corresponding ExUnit test cases verifying their implementation.

## Requirement Coverage

### OFF-01: Offline-Island Capabilities
**Description:** The system must support degraded read-only caching and specific offline-island mutations without relying on universal sync, demonstrating draft ingestion and local mutation using the SyncController pattern.

| Validation Step | Test Case (in `phase74_offline_draft_recovery_proof_test.exs`) |
|-----------------|----------------------------------------------------------------|
| Prove a route explicitly marked as an offline island compiles with the correct `IslandContract` limits and `:local_first` policy. | "repo-local proof lane asserts the narrow cached and study-session offline posture" (Pattern analog from `proof_lane_test.exs`) |
| Prove draft ingestion and mutation works locally simulating the SyncController pattern on the `offline_island` route. | "simulates local draft ingestion and mutation using the SyncController pattern" |
| Prove route gates correctly identify the bounds between an offline island and a standard live view route. | "enforces local_first bounds and rejects generic sync" (Pattern analog from `phase73_auth_sensitive_admin_workflow_proof_test.exs`) |

### OFF-02: Compiler Enforcement of Offline Limits
**Description:** The compiler must reject invalid posture combinations, specifically preventing `:local_first` sync policies from being applied to `:live_view` runtimes, enforcing that generic LiveViews do not become implicit offline sync endpoints.

| Validation Step | Test Case (in `phase74_offline_draft_recovery_proof_test.exs`) |
|-----------------|----------------------------------------------------------------|
| Provide an invalid manifest with `runtime: :live_view` and `offline: :local_first` and assert compilation/validation failure. | "asserts Crosswake.Policy.Validator.validate rejects :local_first offline policy when paired with a :live_view runtime" |
| Validate a compliant `:live_view` route configured as `:cached_read_only` passes the policy validations successfully. | "evaluates a standard :live_view route with :cached_read_only, ensuring offline island logic is not applied universally" |

## Continuous Integration
Both OFF-01 and OFF-02 are guarded by automated CI workflows.
- **Workflow:** `.github/workflows/phase74-proof.yml`
- **Assertion:** The CI gate will explicitly fail if any of the above tests do not successfully evaluate the bounds or behavior of the offline-island draft states.
