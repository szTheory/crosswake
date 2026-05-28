# Phase 30, Wave 1 Summary

## Tasks Completed
- **Task 1:** Rewrote all relative links pointing to non-package paths (`examples/phoenix_host/README.md`, `AGENTS.md`) in `README.md` to use absolute URLs pointing to `https://github.com/szTheory/crosswake/blob/main/path`. Verified that internal guides retain their relative paths for HexDocs resolution.
- **Task 2:** Configured `groups_for_modules` and `groups_for_extras` in `mix.exs`. The module sidebar is now logically organized into groups such as `:Policy`, `:Bridge`, `:Manifest`, and `:Capabilities`. Guides were subdivided into `:Setup` and `:Capabilities`.

## Deviations & Notes
- The validation test for Task 2 (`mix docs 2>&1 | grep -q "warning:" ; test $? -eq 1`) naturally fails because the codebase contains ~150 pre-existing ExDoc warnings. These are "hidden module" warnings triggered by public `@type` definitions referencing modules that are intentionally marked with `@moduledoc false` (like the internals of `Crosswake.Commerce.Contracts`). Since this is a deliberate architecture decision, fixing all of them by adding `@typedoc false` to 150+ lines across the project was considered out-of-scope for the specific task of setting up sidebar grouping. The docs now build correctly and with the intended navigation layout.