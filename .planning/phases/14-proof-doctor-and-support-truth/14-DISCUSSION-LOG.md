# Phase 14: Discussion Log

### Gray Areas Addressed

1. **How should `mix crosswake.doctor` present the expanded capability-family and commerce-seam outputs?**
   - **Decision**: Extend `Crosswake.Doctor.Formatter.format_release_policy` or add a new formatter section `format_package_surfaces` to explicitly list `package_surfaces` and `change_classes` available in `report.support.release_policy`. This ensures the operator sees the explicit capability and commerce package boundaries at the CLI layer.

2. **How do we split merge-blocking proof from advisory environment-sensitive proof?**
   - **Decision**: Update `doctor.ex` to read the `proof_class` of a required or checked property. If a check originates from an `:advisory` proof class or a capability family with `proof_class: :advisory`, it should yield an `:advisory` or `:warning` severity in `Check`, rather than an `:error` which blocks CI. We might also need to inspect shell `proof` results. Currently, shell generation hooks are `:merge_blocking` because they verify the base runtime, but future companion/storefront claims might only be `:advisory` in standard CI.

3. **Where do we publish rebuild guidance, fallback behavior, reviewer/storefront notes?**
   - **Decision**: Ensure that `guides/capabilities.md` and `guides/compatibility.md` describe how the `prerequisites`, `denial`, and `fallback` fields dictate adopter action. Since `Renderer.ex` already exposes these fields in `SupportMatrix`, we simply need to ensure the guides contextualize them properly, answering "when a commerce capability fails closed, what is the exact fallback expectation?" and "what reviewer notes should adopters add when submitting their app?".

### Next Steps
1. Refactor `lib/crosswake/doctor/formatter.ex` to output capability families, package surfaces, and change classes.
2. Refactor `lib/crosswake/doctor/doctor.ex` to correctly handle `proof_class` mappings and split out `:advisory` findings from `:merge_blocking` findings so they don't break CI unless required.
3. Update `guides/capabilities.md`, `guides/commerce.md`, or `guides/compatibility.md` to fulfill the 14-03 requirements around rebuild, fallback, and storefront guidance.
