# Phase 14: Research

### Current State
1. **Support Matrix Renderer**: `lib/crosswake/support_matrix/renderer.ex` successfully extracts `capability_families`, `package_surfaces`, `release_boundaries`, and `change_classes` and renders them into the markdown support matrix. Capability entries already output `prerequisites`, `denial`, and `fallback` information.
2. **Doctor Output**: `lib/crosswake/doctor/formatter.ex` does *not* display the detailed support matrix tables (like `capability_families` and `package_surfaces`). The doctor CLI report stops at the summary level (`status`, `blocking_platforms`, and `release_policy`).
3. **Proof Verification**: `lib/crosswake/doctor/doctor.ex` evaluates platform proof hooks (e.g. `script/verify_generated_ios_shell.sh`). The support findings emit an `:error` if these hooks are missing or fail. 
4. **Merge-Blocking vs Advisory**: The `CapabilitySupportEntry` type defines `proof_class` as `:merge_blocking | :advisory`, but currently the `doctor.ex` pipeline doesn't seem to differentiate the output or exit codes based on these `proof_classes` for future capability checks, or doesn't expose them in the diagnostic report properly.
5. **Commerce Seams**: The "Phoenix-facing commerce seam vocabulary" is registered as a package surface in `support_matrix.ex`, but the UI doesn't specifically single out commerce other than rendering it into the matrix.

### Objectives for Plans
**14-01**: Extend `Crosswake.Doctor.Formatter` to output `capability_families`, `package_surfaces` (which includes the commerce seam), and `change_classes` if they're available in the `support_matrix` context.
**14-02**: Adjust `Crosswake.Doctor` to properly categorize and split `merge_blocking` proof checks from `advisory` proof checks. This will make it easier to add environment-sensitive proof (e.g. real device required or storefront credentials required) without breaking the CI build.
**14-03**: Create or update a guide with rebuild guidance, fallback behavior, reviewer/storefront notes, and rough-edge documentation. The `CapabilitySupportEntry` fields for `guide`, `fallback`, `denial` points to paths like `guides/capabilities.md` and `guides/compatibility.md`. We need to ensure these guides are written and contain the appropriate documentation.
