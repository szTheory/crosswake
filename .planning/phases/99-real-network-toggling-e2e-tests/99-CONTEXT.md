# Phase 99: Real Network-Toggling E2E Tests - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

The offline sync reconciliation loop is verified via realistic browser network toggling (`page.context().setOffline(true)`) rather than faked `localStorage` behavior. This enforces the v6.0 offline-sync capabilities and establishes the "proof lane" for Crosswake's offline island philosophy.

</domain>

<decisions>
## Implementation Decisions

### Playwright Setup Location
- **D-01:** Place `package.json`, `playwright.config.ts`, and the `e2e/` directory at the root of `examples/phoenix_host`. The tests belong to the host application, keeping the end-to-end tooling strictly out of the OSS library root and separate from the Phoenix `assets/` frontend build pipeline.

### Ecto State Verification
- **D-02:** Use a `MIX_ENV`-gated test-only verification API. Playwright will hit a hidden Phoenix route (e.g., `/_e2e/sync-state/:id` inside `if Mix.env() in [:test, :e2e] do ... end`) to definitively prove the server reconciled the event in Ecto, avoiding brittle DOM-only assertions or leaking database knowledge into the Node.js test layer.

### CI Server Lifecycle
- **D-03:** Manage the Phoenix server lifecycle using Playwright's `webServer` configuration block with `workers: 1`. Playwright automatically drops, migrates, and boots `phx.server` via `MIX_ENV=test mix do ecto.drop, ecto.setup, phx.server`. This isolates the environment and guarantees local test runs behave identically to GitHub Actions.

### Claude's Discretion
- Exact naming of the E2E verification routes and specific helper abstractions in Playwright, so long as they adhere strictly to the D-01/D-02/D-03 architectural decisions.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Brand & OSS Identity
- `prompts/crosswake-brand-book.md` — Brand constraints: "operational truth over hype," "designed for maintainers who care about correctness."
- `prompts/crosswake-elixir-oss-dna.md` — OSS constraints: "Install truth is product truth," "Prefer a deterministic example-host path," "Explicit distinction between host-owned code and library-owned code."

### Code Surfaces
- `examples/phoenix_host/` — Target directory for all Playwright configurations.
- `examples/phoenix_host/lib/crosswake_example_web/router.ex` — Target for the `MIX_ENV`-gated test-only verification API.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None specifically for Playwright (new test harness).

### Established Patterns
- `examples/phoenix_host` is the canonical example app and proof artifact used for validating Crosswake architecture.

### Integration Points
- `playwright.config.ts` connects Playwright tests to the Elixir/Phoenix server via `webServer` block.
- Phoenix Router connects E2E state verification via a compile-time `MIX_ENV`-gated API scope.

</code_context>

<specifics>
## Specific Ideas

- The Playwright run experience should be idiomatic JS: `npm ci && npx playwright test`.
- Playwright should natively toggle the browser's context network mode with `page.context().setOffline(true)`.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 99-Real Network-Toggling E2E Tests*
*Context gathered: 2026-06-11*
