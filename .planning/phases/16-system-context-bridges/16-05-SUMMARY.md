# 16-05 Summary

Aligned doctor output, generated support truth, and public guides with the shipped Phase 16 contract.

Key outcomes:
- Updated doctor posture checks and fixtures to recognize `permissions.status` and `external_entry_denied`.
- Regenerated `guides/support_matrix.md` from canonical support metadata.
- Updated public docs so `deep_link` stays inbound shell activation only and `permissions.status` is documented as read-only, `notifications`-only support.
- Kept support truth explicit about inactive routes versus routes that reject external entry.

Verification:
- `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/support_matrix/renderer_test.exs test/crosswake/guides/capabilities_test.exs`
