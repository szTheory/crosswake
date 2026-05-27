---
phase: 21
status: clean
reviewed_on: 2026-05-27
scope:
  - examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_keys.ex
  - test/crosswake/proof/phase21_reconciliation_example_test.exs
  - examples/phoenix_host/README.md
verification:
  - mix test test/crosswake/proof/phase21_reconciliation_example_test.exs
---

## Findings

No outstanding issues in the requested focus files.

## Notes

- `reconciliation_keys.ex`: key generation now preserves case for opaque provider-issued fields (`provider_reference`, `evidence_ref`) via `opaque_component/1`, so the previous collision risk is resolved.
- `README.md`: guide links are now repository-relative (`../../guides/...`) rather than machine-local absolute paths.
- `phase21_reconciliation_example_test.exs`: includes explicit regression coverage for case-sensitive key distinctions and still validates correlation-id invariance.
- Fresh verification run: `mix test test/crosswake/proof/phase21_reconciliation_example_test.exs` (`8 tests, 0 failures`).
