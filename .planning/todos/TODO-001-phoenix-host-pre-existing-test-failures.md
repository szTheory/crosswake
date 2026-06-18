---
id: TODO-001
title: Pre-existing test failures in examples/phoenix_host suite
status: open
created: 2026-06-17
surfaced_by: phase-112 (real-offline-outbox-flush)
relates_to: DEBT-01 (Phase 115), milestone v12.0 CI Honesty
---

# Pre-existing test failures in `examples/phoenix_host`

Surfaced during Phase 112 post-merge gate. **Not caused by Phase 112** — these
were masked because the example test suite could not compile until 112-02 added
`elixirc_paths` to `examples/phoenix_host/mix.exs` (so `test/support` loads).
Running `mix test` for the first time un-masked pre-existing debt.

None of these files were in Phase 112's scope fence (offline_study.js,
offline_html/index.html.heex, study_session_live.ex, mix.exs).

## 1. Deterministic — `CrosswakeExample.FlashcardsTest` (3 failures)

`examples/phoenix_host/test/crosswake_example/flashcards_test.exs` (last edited
in phase 86, `test(86-00)`). Schema/API field-name drift between the test and
the current Flashcards context/schema:

- `front` vs `front_text` (and likely `back` vs `back_text`)
- `create_progress` vs `upsert_progress`

Failing tests:
- `flashcards_test.exs:9` — `decks list_decks/0 returns all decks`
- `flashcards_test.exs:25` — `cards create_card/1 with valid data creates a card`
- `flashcards_test.exs:33` — `cards list_deck_cards/1 returns cards for a given deck`

Fix: reconcile the test (and any fixtures) with the current schema field names,
or fix the context if the schema is the source of truth.

## 2. Flaky — `CrosswakeExample.Chimeway.RegistryNotificationOpenTest`

Non-deterministic: identical `--seed 0` produced **6 failures one run, 3 the
next**. `Ecto.ConstraintError` on insert (e.g. `chimeway_token_bindings`,
`chimeway_notification_open_intents`) — points at test-isolation / non-unique
ref generation under the shared SQLite sandbox, not a real product bug.

Fix: make ref/fixture generation unique per test (or use the Ecto sandbox in
shared/async-safe mode) so the suite is deterministic.

## Why this matters (CI Honesty, v12.0)

A test suite that 404s on compile, then fails 3–6/18 once it runs, is exactly
the kind of dishonest-green this milestone targets. Candidate to fold into
Phase 115 DEBT-01 (ledger backlog) or address as a standalone fix before
milestone closeout.
