# Phase 78: Automated Host Scaffold Generation - Discussion Log

**Date:** 2026-06-05

## Discussion Summary

The user chose to discuss all three key gray areas for the automated host scaffold generation: Dependency Resolution, Permission Templating, and Glue Code Architecture. Rather than individual question-and-answer steps, the user requested a unified, one-shot recommendation covering all three areas, grounded in the Elixir/Phoenix ecosystem idioms, good developer ergonomics, and the project's architectural vision.

### Area: Dependency Resolution
- **Options Considered:** Local path overrides for dev vs default remote URL/versions.
- **Selection:** Remote SPM/Maven by default, with an undocumented `--local` flag (or workspace detection) for internal CI and testing.
- **Notes:** Mirrors Phoenix generators that use remote hex deps but allow path overrides for internal framework testing.

### Area: Permission Templating
- **Options Considered:** Aggressive (commented-out) capability blocks vs strict minimal boot capabilities.
- **Selection:** Minimal to boot.
- **Notes:** Avoids the "wall of text" antipattern. Generates only what is required to boot and relies on a prominent documentation link for extending capabilities, following the Phoenix philosophy of explicit extension via docs.

### Area: Glue Code Architecture
- **Options Considered:** Binding directly in the root UI (App/MainActivity) vs a dedicated Coordinator/ViewModel layer.
- **Selection:** Dedicated Coordinator/ViewModel layer.
- **Notes:** Aligns with Phase 77 decisions (reactive state) and Crosswake's thesis. Treats the native shell as a separate service (akin to a GenServer) that emits state to a dumb root view, ensuring the UI rendering and shell lifecycle are explicitly separated.

## User's Raw Input
> "discuss/consider all and for each of these... research using subagents, what is pros/cons/tradeoffs of each considering the example for each approach, what is idiomatic for elixir/plug/ecto/phoenix for this type of lib/app and in this ecosystem, lessons learned from other libs/apps in same space even from other languages/frameworks if thehy are popular successful, what did they do right that we should learn from, what did they do wrong/footguns we can learn from, great developer ergeonomics/dx emphasized... user friendly (if it's a lib or app), think deeply one-shot a perfect set of recommendations so i dont have to think..."

## Deferred Ideas
- automated app store / play store deployment workflows
- full hermetic CI proof of v5 (Phase 79)
