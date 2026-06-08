# Thread: Adoption Evidence Demo App
Opened: 2026-06-06

## Context
The user raised a critical point: we are blocked on adoption evidence. While the core substrate is strong (up to v5.0 standalone shells), the `examples/phoenix_host` is a proof/test harness, not a realistic demo.

## Goal
Build a realistic demo app (e.g., a realistic domain, persona, rich seeds/fixtures, click-around UI) that exercises install, onboarding, and happy-path JTBDs. Automate the E2E testing (shift-left CI/CD) to build bulletproof confidence before seeking real adopters.

## Impact
This shifts focus from building more core features to proving DX/UX and integration in a product-shaped environment, serving as the ultimate "done" check for the core library.