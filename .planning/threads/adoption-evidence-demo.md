# Thread: Adoption Evidence Demo App
Opened: 2026-06-06

## Context
The user raised a critical point: we are blocked on adoption evidence. While the core substrate is strong (up to v5.0 standalone shells), the `examples/phoenix_host` is a proof/test harness, not a realistic demo.

## Goal
Build a realistic demo app (e.g., a realistic domain, persona, rich seeds/fixtures, click-around UI) that exercises install, onboarding, and happy-path JTBDs. Automate the E2E testing (shift-left CI/CD) to build bulletproof confidence before seeking real adopters.

## Impact
This shifts focus from building more core features to proving DX/UX and integration in a product-shaped environment, serving as the ultimate "done" check for the core library.

## 2026-06-18 Next-Step Assessment

Crosswake is strong, but not yet confidence-complete for a skeptical Phoenix SaaS adopter. The route-policy substrate, published install path, diagnostics/support truth, and real offline proof are substantive. The highest-leverage next wedge is **v13.0 Adopter Confidence & Native Evidence**: make the proof path runnable, current, visual, and honest.

### What is real today

- The v12 offline proof is real: Playwright clicks the `/offline` UI offline, verifies IndexedDB outbox contents, triggers the app-owned reconnect flush, asserts Ecto state, and checks idempotency.
- The v11 release proof is real: `crosswake 0.1.2` is live on Hex, Maven Central, and the SwiftPM mirror; generated shells resolve published, version-matched coordinates in clean-room CI.
- The three canonical adopter lanes are structurally real: Phoenix SaaS Portal, Selective Native Flow, and Local-First Study Flow are represented in route policy, guides, proof tests, and the example host.

### Confidence gaps to close before more feature breadth

- Public docs drift: README says `0.1.0`; CHANGELOG still frames `0.1.2` as pending; `examples/QUICK_START.md` has a stale iOS project path and undefined `mix setup`; `guides/adoption.md` still teaches generic bridge mutation rather than the v12 app-owned IndexedDB outbox/reconnect proof.
- Checked-in native host drift: generator/release proof uses published coordinates, but checked-in iOS/Android hosts do not clearly prove the same public install story.
- Local proof debt: `TODO-001` records deterministic `FlashcardsTest` drift and flaky Chimeway registry tests in the example host. This should be first-phase or precondition work for public proof.
- Collateral gap: there are no durable screenshots, videos, or uploaded artifacts showing the Phoenix host, iPhone simulator, and Android emulator exercising the core paths.

### Next milestone shape

Treat `GUIDE-01` as an adopter-confidence package:

1. Fix proof-path drift and local example-host test debt.
2. Reconcile checked-in native hosts with the published-coordinate story or label them local-development proof.
3. Capture iPhone simulator and Android emulator evidence for launch plus route activation.
4. Show at least one LiveView, bridge, offline-island, and native-screen path in screenshots/short recordings.
5. Publish route-policy, troubleshooting/rough-edges, web-to-mobile migration, and ExDoc guide links that point adopters to the proof without internal phase archaeology.

### Done-band judgment

Use **80-89% strong, meaningful wedges remain** until v13 closes. The remaining delta is not foundational substrate; it is adopter trust, public proof execution, and seeing-is-believing collateral. Additional capability breadth before that is likely lower leverage.
