# Phase 116: Proof Debt And Release Truth - Context

**Gathered:** 2026-06-18T18:49:46Z
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 116 makes the public proof path clean and current before it becomes adopter evidence. It resolves or explicitly excludes known example-host proof debt, reconciles public docs and release prose to `crosswake 0.1.2` release truth, and adds a cheap drift guard so stale current-version and deferred-standalone-shell claims cannot return.

This phase is truth repair and guardrail work. It is not the full quick-start rewrite, not native evidence classification, not collateral capture, and not new capability breadth.

</domain>

<decisions>
## Implementation Decisions

### TODO-001 Disposition

- **D-01:** Default Phase 116 planning to fixing both known `TODO-001` debts in `examples/phoenix_host`: Flashcards field/API drift and Chimeway registry test nondeterminism. A public proof path should not depend on known failing or flaky example-host tests.
- **D-02:** Flashcards is straightforward drift, not a product redesign. Tests and fixtures currently use `front`/`back`; the schema accepts `front_text`/`back_text`. Planners should reconcile tests/fixtures to the current schema/context source of truth.
- **D-03:** Chimeway should first be repaired with narrow test-data isolation: unique values across the full unique index shape, cleanup/reset for persistent SQLite state where needed, and `async: false`/sequential behavior for DB-writing SQLite tests. Do not widen Phase 116 into a generic Chimeway behavior rewrite.
- **D-04:** Fallback only if Chimeway repair expands beyond fixture/test isolation: fix Flashcards, then explicitly exclude the Chimeway registry test from public proof commands with a narrow reason and a follow-up debt note. Do not exclude Flashcards; it is part of the adoption/offline exemplar.
- **D-05:** Do not use "exclude both tests" as the Phase 116 strategy. That would keep the proof path technically honest but leave the core example host embarrassing and fragile for Phase 118.

### Release-Truth Wording

- **D-06:** Use a hybrid release-truth policy. Public docs should state exact live facts where trust depends on them: `crosswake 0.1.2` is current on Hex; generated native dependencies resolve to the Crosswake package version; v11.0 published the lockstep native shell cores.
- **D-07:** Use derived wording where future releases should not require narrative churn: "the Crosswake package version", "Hex-matched version", "the current package version", and "version-matched generated coordinates" are preferred for generator/support prose.
- **D-08:** Keep historical `0.1.0` examples only when they are explicitly labeled as historical fixture or baseline truth. Any checked-in artifact presented as current adopter proof must be regenerated, relabeled, or removed from the public proof path.
- **D-09:** `CHANGELOG.md` should return to conventional release semantics: `[Unreleased]` means future unreleased changes, and `[0.1.2]` is a released entry dated to the actual publish. It must no longer say latest Hex remains `0.1.0` or that `0.1.2` is pending.
- **D-10:** Do not put release-please markers broadly through prose or historical fixtures. Use release automation for narrow machine-owned version fields; rely on tests/guards for narrative truth.

### Drift Guard Shape

- **D-11:** Add an idiomatic ExUnit docs-contract guard as the primary Phase 116 drift mechanism. It should run in the normal local/CI Elixir test surface and fail with clear messages when public docs reintroduce stale release-truth claims.
- **D-12:** The guard should derive the current package version from `Application.spec(:crosswake, :vsn)` or `mix.exs` rather than hardcoding `0.1.2` as the only acceptable future value.
- **D-13:** The initial guard scope is intentionally narrow and semantic: stale current-release claims (`latest Hex remains 0.1.0`), `0.1.2 pending/unreleased` claims after release, unlabelled `0.1.0` current-baseline claims, and stale "standalone public shell packages are deferred" prose.
- **D-14:** Use small scanner-style helpers inside ExUnit if that keeps patterns readable, but avoid an independent shell script as the first implementation unless planning finds a clear need to run outside Mix.
- **D-15:** Keep `mix crosswake.doctor --check-publish` / `PublishReadiness` as a follow-on integration point after the cheap docs-contract guard exists. Keep ExDoc build checks as package/docs smoke; they do not replace semantic stale-claim detection.

### Phase 116 Boundary Vs Phase 118

- **D-16:** Phase 116 should make minimal front-door safety edits where public readers would otherwise hit known-bad instructions. It should stop README/ExDoc/guide-map surfaces from routing adopters into `mix setup`, port `4000`, wrong iOS paths, `Crosswake.mutate`, or bridge-owned offline mutation authority as current proof.
- **D-17:** Do not pull the full Phase 118 quick-start/adoption rewrite into Phase 116. Phase 118 owns command-verified `examples/QUICK_START.md`, full `guides/adoption.md` v12 offline rewrite, and DRIFT-02 guard coverage.
- **D-18:** Temporary Phase 116 microcopy should be explicit and low-drama: "current verified proof", "under Phase 118 rewrite", "excluded from public proof path because...", "advisory native evidence", "local-development proof", and "published-coordinate proof" are preferred labels.
- **D-19:** Phase 116 may cite generated clean-room/published-coordinate proof from v11, but must not describe checked-in iOS/Android hosts as published-coordinate proof until Phase 119 settles native evidence classification.

### Prompt, Brand, Persona, And JTBD Inputs

- **D-20:** Treat `brandbook/BRAND-SPEC.md` v1.0 and generated token sources as current brand truth. `prompts/crosswake-brand-book.md` is historical seed material and is superseded where it conflicts.
- **D-21:** The target reader for Phase 116 is a skeptical Phoenix SaaS adopter asking "is this real and runnable?" The Phase 116 proof path should emphasize current install truth, route ownership, and evidence labels, not capability breadth.
- **D-22:** Use careful maintainer voice: precise, short, example-heavy, and candid. Avoid "magic", "just works", "native mobile with no native work", "everything works offline", and any prose that hides runtime ownership or proof class.

### Claude's Discretion

Downstream agents may choose the exact ExUnit helper structure and assertion wording, but must preserve the decisions above: narrow semantic guard first, current-version derived where possible, explicit fixture labels where old versions remain, and no full Phase 118 scope absorption.

### Folded Todos

- **TODO-001: Pre-existing test failures in `examples/phoenix_host`** — Folded into Phase 116 despite `todo.match-phase` returning no matches, because `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, and the todo file explicitly link it to Phase 116 / PROOF-01. Planning should resolve it or narrowly exclude residual Chimeway flake from public proof with an explicit reason.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope And Requirements

- `.planning/PROJECT.md` — Current milestone thesis, v13 proof-path constraints, and core Crosswake decisions.
- `.planning/REQUIREMENTS.md` — Phase 116 requirements: PROOF-01, REL-TRUTH-01, DRIFT-01.
- `.planning/ROADMAP.md` — Phase 116 success criteria and planned plan split.
- `.planning/STATE.md` — Current position, TODO-001 linkage, public docs drift, native host drift, and proof-path blockers.
- `.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md` — Concrete example-host test debt to resolve or explicitly exclude.

### v13 Research

- `.planning/research/v13-proof-path-docs.md` — Primary repo-truth research for proof-path docs, release truth, quick-start drift, and native host ambiguity.
- `.planning/research/v13-collateral-ci.md` — Browser/native evidence posture and artifact/truth constraints; useful for avoiding Phase 120 scope creep.
- `.planning/research/v13-support-truth-guides.md` — Support-vocabulary and guide framing context; useful for Phase 116 microcopy labels.

### Prompt And Product Context

- `prompts/crosswake-elixir-oss-dna.md` — Maintainer OSS house style: install truth, proof lanes, release truth, support matrices, and docs contracts.
- `prompts/crosswake-gsd-project-brief.md` — Project thesis and non-goals; preserves route-policy architecture.
- `prompts/crosswake-research-synthesis.md` — Stable architecture story and anti-patterns to preserve.
- `prompts/crosswake-integrations-and-companions.md` — Integration classification boundaries; prevents companion/capability scope creep.
- `brandbook/BRAND-SPEC.md` — Current ratified brand, voice, release-note tone, proof-label copy posture, and accessibility/design-token truth.
- `guides/adopter_profiles.md` — Current adopter profiles and proof posture for Phoenix SaaS, selective native, and local-first study flows.
- `guides/user_flows.md` — JTBD framing and route-owner mental model for public-facing copy.

### Public Docs And Release Surfaces

- `README.md` — Current baseline drift (`0.1.0`) and guide-map/front-door surface.
- `CHANGELOG.md` — Current release-truth drift: `0.1.2` pending/unreleased and latest Hex `0.1.0` prose.
- `examples/QUICK_START.md` — Known stale first-run instructions; Phase 116 should stop public routing into known-bad commands without doing the full Phase 118 rewrite.
- `guides/adoption.md` — Known fictional `Crosswake.mutate` / bridge-owned offline mutation language; Phase 116 should prevent this from being treated as current proof.
- `guides/install.md` — Contains stale deferred standalone-shell prose.
- `guides/native_shell.md` — Contains stale deferred standalone-shell prose.
- `guides/compatibility.md` — Contains stale deferred standalone-shell prose.
- `guides/support_matrix.md` — Canonical support matrix and release/native proof vocabulary context.
- `mix.exs` — Current package version, ExDoc extras list, package files, and docs source refs.

### Tests, Guards, And Example-Host Debt

- `test/crosswake/guides/release_boundaries_test.exs` — Existing docs-contract style test; currently asserts the stale deferred standalone-shell prose and should be updated/reoriented.
- `test/crosswake/doctor/publish_readiness_test.exs` — Existing publish-readiness coverage; useful as a follow-on integration point.
- `lib/crosswake/doctor/publish_readiness.ex` — Existing structured publish-readiness diagnostics; do not overload before the cheap docs-contract guard exists.
- `examples/phoenix_host/test/crosswake_example/flashcards_test.exs` — Failing deterministic test that still uses old `front`/`back` fields.
- `examples/phoenix_host/test/support/flashcards_fixtures.ex` — Failing fixture source that still emits old `front`/`back` attrs.
- `examples/phoenix_host/lib/crosswake_example/flashcards.ex` — Current Flashcards context with `upsert_progress/1`.
- `examples/phoenix_host/lib/crosswake_example/flashcards/card.ex` — Current `front_text`/`back_text` schema source of truth.
- `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` — Flaky/nondeterministic registry test; unique refs are incomplete because `installation_ref` is still fixed and persistent DB state can collide.
- `examples/phoenix_host/mix.exs` — Example host aliases and test setup; no `mix setup` alias exists.
- `examples/phoenix_host/config/config.exs` — Example host default port is `4002`.
- `examples/phoenix_host/playwright.config.ts` — Existing deterministic Playwright posture and port `4002`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `test/crosswake/guides/release_boundaries_test.exs`: Existing ExUnit docs-contract pattern for guide text. Reuse or replace this pattern for release-truth drift checks.
- `lib/crosswake/doctor/publish_readiness.ex`: Structured diagnostics surface for future release-truth reporting; useful after the primary ExUnit guard exists.
- `mix.exs`: Provides current package version and ExDoc/public-extra list. Drift guards should derive current version from this or `Application.spec(:crosswake, :vsn)`.
- `examples/phoenix_host/playwright.config.ts`: Existing proof path uses port `4002`, one worker, retries in CI, blocked service workers, and DB reset before server start.

### Established Patterns

- Docs-contract tests are an accepted Crosswake proof style; Phase 96 and current guide tests treat docs as executable contract, not cleanup.
- Required-vs-advisory proof split is already a Crosswake pattern from brand and E2E work: deterministic structural checks block merges; environment-sensitive native/device evidence stays advisory unless promoted.
- Release truth is part of the product contract. v11/v12 established clean-room proof, lockstep publishing, and structural honesty guards; Phase 116 should extend that posture to public prose.
- SQLite example-host tests need conservative isolation. Official Ecto/ExUnit guidance supports unique per-test data and non-async/shared behavior for DB-writing tests that cannot run safely concurrently.

### Integration Points

- Public docs affected by Phase 116 are included in package docs through `mix.exs` extras, so README/CHANGELOG/guides drift is public HexDocs drift.
- `TODO-001` resolution connects directly to proof commands and Phase 118 quick-start work; do not leave future public proof paths dependent on known failures.
- Native host coordinate truth is adjacent but not Phase 116 ownership. Phase 116 should avoid overclaiming checked-in native hosts and leave classification to Phase 119.

</code_context>

<specifics>
## Specific Ideas

- Subagent-backed recommendation: fix both `TODO-001` debts by default; narrowly exclude only Chimeway if its repair exceeds fixture/test isolation.
- Subagent-backed recommendation: hybrid release wording with exact `0.1.2` facts where trust requires them and derived "package version" wording in reusable prose.
- Subagent-backed recommendation: ExUnit docs-contract guard first; PublishReadiness and ExDoc smoke are complements, not replacements.
- Subagent-backed recommendation: minimal front-door safety edits in Phase 116; full quick-start/adoption rewrite remains Phase 118.
- Current external release truth verified during discussion: Hex shows `crosswake` `0.1.2` as current; the iOS SwiftPM mirror has tag `v0.1.2`. Maven metadata should be checked again by the planner if implementation depends on exact registry assertions.
- Ecosystem lesson applied: Phoenix/Oban-style docs favor exact commands and verification steps; Hotwire Native is useful for route/path and bridge/native distinction; Capacitor is a cautionary plugin-first comparison that Crosswake should not drift toward.
- Brand/JTBD lesson applied: write for a skeptical Phoenix SaaS developer who values proof, precise route ownership, and no "magic" claims.

</specifics>

<deferred>
## Deferred Ideas

- Full command-verified `examples/QUICK_START.md` rewrite and `guides/adoption.md` v12 offline rewrite remain Phase 118.
- Native evidence classification for checked-in iOS/Android hosts remains Phase 119.
- Browser/native screenshot/video/artifact packaging remains Phase 120.
- Broad example-host DB harness or DataCase-style cleanup is deferred unless the narrow `TODO-001` repair cannot be made durable without it.
- PublishReadiness integration for release-truth drift is a good follow-on after the cheap ExUnit docs-contract guard exists.

</deferred>

---

*Phase: 116-Proof Debt And Release Truth*
*Context gathered: 2026-06-18T18:49:46Z*
