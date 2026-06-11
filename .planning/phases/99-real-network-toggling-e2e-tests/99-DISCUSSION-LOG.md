# Phase 99: Real Network-Toggling E2E Tests - Discussion Log

**Date:** 2026-06-11

## Area 1: Playwright Setup Location
- **Options presented:** Where should the Playwright dependencies and config live? (e.g., examples/phoenix_host/assets/package.json vs root package.json vs Elixir wrapper)
- **Selection:** `Other` (User requested deep research via subagent)
- **Notes:** Research indicated placing the setup at the root of `examples/phoenix_host` is the most idiomatic and respects OSS host-owned boundaries.

## Area 2: Ecto State Verification
- **Options presented:** How should the test assert that Ecto state was updated? (e.g., query a test-only API, check UI state, or direct DB query)
- **Selection:** `Other` (User requested deep research via subagent)
- **Notes:** Research favored a `MIX_ENV`-gated test-only verification API inside the Phoenix router to cleanly test state without leaking DB connections to Node.js or relying on brittle UI DOM assertions.

## Area 3: CI Server Lifecycle
- **Options presented:** How should the Playwright tests manage the Phoenix server lifecycle during the run?
- **Selection:** `Other` (User requested deep research via subagent)
- **Notes:** Research favored the Playwright `webServer` config block executing `MIX_ENV=test mix do ecto.drop, ecto.setup, phx.server` to guarantee parity between local developer runs and GitHub actions.

## Deferred Ideas
- None

## Claude's Discretion
- Exact naming of E2E verification routes and helpers as long as they fit the chosen architecture.
