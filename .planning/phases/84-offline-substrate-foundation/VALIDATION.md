# Phase 84 Validation Strategy

## Overview
This phase introduces the foundational `ContentPack` struct for offline assets, along with test validations ensuring the manifest compiler correctly extracts pack requirements from route policies. Validation centers around structural correctness, encoding behavior, and manifest generation logic.

## Test Suite
The test suite consists of automated unit tests:

1. **ContentPack Struct Validation (`test/crosswake/offline/content_pack_test.exs`)**:
   - Ensures valid keys (`id`, `version`, `kind`) can successfully initialize a `ContentPack`.
   - Validates proper JSON serialization of the struct via `Jason.Encoder`, guaranteeing that `assets` and `data_payloads` encode accurately for client download.

2. **Route Policy and Manifest Builder Integration (`test/crosswake/policy/route_test.exs`, `test/crosswake/manifest/builder_test.exs`)**:
   - Confirms that routes defined with `offline: :local_first` and explicitly specified `packs` are successfully validated by the schema.
   - Verifies that `Crosswake.Manifest.Builder` correctly processes local_first routes, accurately exposing `packs` in the route entry and ensuring they are populated in the top-level `pack_registry`.

## Verification Strategy
Verification is entirely automated via unit testing.

### Execution
Run the following commands to execute the test suite:
```bash
mix test test/crosswake/offline/content_pack_test.exs
mix test test/crosswake/policy/route_test.exs
mix test test/crosswake/manifest/builder_test.exs
```

### Acceptance Criteria
- All tests pass, demonstrating that offline asset bundles can be serialized for client consumption.
- The manifest builder successfully maps offline dependencies, proving clients can discover required asset bundles.
