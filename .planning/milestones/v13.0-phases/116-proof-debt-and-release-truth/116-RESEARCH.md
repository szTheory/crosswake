<user_constraints>
## User Constraints (from CONTEXT.md)

Source: `.planning/phases/116-proof-debt-and-release-truth/116-CONTEXT.md` [VERIFIED: file read]

### Locked Decisions

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

### the agent's Discretion

Downstream agents may choose the exact ExUnit helper structure and assertion wording, but must preserve the decisions above: narrow semantic guard first, current-version derived where possible, explicit fixture labels where old versions remain, and no full Phase 118 scope absorption.

### Folded Todos

- **TODO-001: Pre-existing test failures in `examples/phoenix_host`** — Folded into Phase 116 despite `todo.match-phase` returning no matches, because `.planning/STATE.md`, `.planning/REQUIREMENTS.md`, and the todo file explicitly link it to Phase 116 / PROOF-01. Planning should resolve it or narrowly exclude residual Chimeway flake from public proof with an explicit reason.

### Deferred Ideas (OUT OF SCOPE)

- Full command-verified `examples/QUICK_START.md` rewrite and `guides/adoption.md` v12 offline rewrite remain Phase 118.
- Native evidence classification for checked-in iOS/Android hosts remains Phase 119.
- Browser/native screenshot/video/artifact packaging remains Phase 120.
- Broad example-host DB harness or DataCase-style cleanup is deferred unless the narrow `TODO-001` repair cannot be made durable without it.
- PublishReadiness integration for release-truth drift is a good follow-on after the cheap ExUnit docs-contract guard exists.
</user_constraints>

# Phase 116: Proof Debt And Release Truth - Research

**Researched:** 2026-06-18 [VERIFIED: system date]  
**Domain:** Elixir/Phoenix docs-contract tests, release-truth docs, and example-host SQLite test isolation [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`; targeted source reads]  
**Confidence:** HIGH for repo-local findings; MEDIUM for external release-registry currentness because Maven was not rechecked in this session [VERIFIED: local source reads; `116-CONTEXT.md`]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | `TODO-001` is resolved or explicitly excluded from the public proof path; no public proof command depends on known failing/flaky example-host tests. | The targeted example-host run produced 5 failures in the two `TODO-001` files, and source inspection identifies Flashcards field drift plus Chimeway unique-index collisions as the repair targets. [VERIFIED: `mix test` in `examples/phoenix_host`; `.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md`; `examples/phoenix_host/test/...`] |
| REL-TRUTH-01 | Public release/docs truth agrees with `crosswake 0.1.2` or labels old fixture truth explicitly. | `mix.exs` declares `@version "0.1.2"`, while README/CHANGELOG/install/native/compatibility/adoption/quick-start surfaces still contain stale version, pending-release, deferred-shell, or fictional offline-authority language. [VERIFIED: `mix.exs`; `README.md`; `CHANGELOG.md`; `guides/*.md`; `examples/QUICK_START.md`; `rg` stale-claim scan] |
| DRIFT-01 | Cheap release-truth drift is mechanically guarded. | Existing docs-contract tests are green while asserting the stale "standalone public shell packages are deferred" phrase, so Phase 116 should reorient `release_boundaries_test.exs` into a negative stale-claim guard that derives the current package version. [VERIFIED: `test/crosswake/guides/release_boundaries_test.exs`; `mix test test/crosswake/guides/release_boundaries_test.exs ...`] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve the core thesis: Crosswake is Phoenix-first route policy and runtime contracts, not a universal UI framework. [VERIFIED: `AGENTS.md`]
- Keep runtime ownership explicit per route; do not collapse designs into generic WebView wrapper behavior or LiveView-driven native rendering. [VERIFIED: `AGENTS.md`]
- Bridge contracts must stay semantic, typed, versioned, and low-frequency; continuous client authority belongs in an offline island or native screen. [VERIFIED: `AGENTS.md`]
- Offline claims must distinguish cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: `AGENTS.md`]
- Diagnostics, support matrices, proof lanes, and rough-edge documentation are product surface. [VERIFIED: `AGENTS.md`]
- v1/v13 scope boundaries in `.planning/PROJECT.md` and `.planning/REQUIREMENTS.md` must be respected before adding integrations or native breadth. [VERIFIED: `AGENTS.md`; `.planning/PROJECT.md`; `.planning/REQUIREMENTS.md`]

## Summary

Phase 116 should be planned as a narrow proof-truth cleanup with three tracks: repair or narrowly exclude `TODO-001`, correct public release prose to current `0.1.2`/package-version truth, and add a cheap ExUnit docs-contract guard for stale release claims. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `116-CONTEXT.md`]

The strongest local evidence is direct: `mix.exs` is already `0.1.2`, ExDoc publishes README/CHANGELOG/guides as extras, and `rg` finds stale claims in README, CHANGELOG, `examples/QUICK_START.md`, `guides/adoption.md`, `guides/install.md`, `guides/native_shell.md`, `guides/compatibility.md`, and the current release-boundary test. [VERIFIED: `mix.exs`; `README.md`; `CHANGELOG.md`; `guides/*`; `examples/QUICK_START.md`; `test/crosswake/guides/release_boundaries_test.exs`; `rg` output]

The planner should not widen into Phase 118 quick-start/adoption rewrites, Phase 119 native host classification, or Phase 120 collateral. Phase 116 may add front-door safety labels where current public docs route users into known-bad commands or fictional authority, but command-verifying the full quick start remains later work. [VERIFIED: `116-CONTEXT.md`; `.planning/ROADMAP.md`]

**Primary recommendation:** Use the existing ExUnit/docs-contract style as the blocking guard, fix Flashcards directly, repair Chimeway with unique full-index fixture values plus cleanup where needed, and update only the minimal public surfaces needed to stop stale release/proof claims. [VERIFIED: source reads; targeted test run]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Flashcards proof debt repair | Example Phoenix host data/test tier | Docs/proof-command tier | The failure is schema/test drift in `examples/phoenix_host` and must be fixed before docs can advertise example-host proof. [VERIFIED: `flashcards_test.exs`; `flashcards_fixtures.ex`; `card.ex`; targeted test run] |
| Chimeway registry flake repair | Example Phoenix host data/test tier | SQLite persistence tier | The failure occurs in setup inserts against a unique index that includes `subject_ref`, `org_ref`, `installation_ref`, `provider`, `platform`, `environment`, and `app_identity_posture`; fixture isolation owns the repair. [VERIFIED: `registry_notification_open_test.exs`; migration/index grep; targeted test run] |
| Public release-truth correction | Docs/ExDoc tier | Package metadata tier | README, CHANGELOG, and guides are published through ExDoc extras, while `mix.exs` provides the package-version source of truth. [VERIFIED: `mix.exs`; `README.md`; `CHANGELOG.md`; `guides/*`] |
| Drift prevention | Test/CI tier | Docs tier | The desired guard is a normal ExUnit docs-contract test that fails on stale prose before it reaches HexDocs or public proof commands. [VERIFIED: `116-CONTEXT.md`; `test/crosswake/guides/release_boundaries_test.exs`] |
| PublishReadiness follow-on | Doctor diagnostics tier | Test/CI tier | `PublishReadiness` already has structured release/support checks, but Phase 116 context explicitly makes it a follow-on after the cheap guard exists. [VERIFIED: `lib/crosswake/doctor/publish_readiness.ex`; `116-CONTEXT.md`] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix / ExUnit | 1.19.5 on Erlang/OTP 28 | Root tests, docs-contract tests, example-host tests, and package-version introspection. | Already installed and used by the repo; ExUnit is the existing docs-contract and proof-lane test framework. [VERIFIED: `elixir --version`; `mix --version`; `test/**/*.exs`] |
| Phoenix | 1.8.7 locked | Host router/docs context and example host runtime. | Existing project and example-host dependency; no new framework is needed. [VERIFIED: `mix.lock`; `examples/phoenix_host/mix.lock`; `mix.exs`] |
| Phoenix LiveView | 1.1.30 locked | Existing route-owner proof context for Phoenix-owned routes. | Existing dependency and public baseline; Phase 116 only references the support/proof truth. [VERIFIED: `mix.lock`; `examples/phoenix_host/mix.lock`; `README.md`] |
| Ecto / Ecto SQL / Ecto SQLite3 | Ecto 3.13.6, Ecto SQL 3.13.5, Ecto SQLite3 0.23.0 in example host | Flashcards and Chimeway fixture persistence under the example host. | The failing proof debt is in the existing SQLite-backed example host; repair should use existing schemas/fixtures. [VERIFIED: `examples/phoenix_host/mix.lock`; targeted test run] |
| ExDoc | 0.40.3 locked | Publishes README/CHANGELOG/guides as package docs extras. | Release-truth drift in extras becomes public HexDocs drift; no separate docs engine is needed. [VERIFIED: `mix.lock`; `mix.exs`] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| Playwright | `@playwright/test` 1.60.0 installed in example host | Confirms existing proof-path port and future Phase 118/120 browser evidence posture. | Reference only for Phase 116 unless a public doc must avoid stale port/path claims; full quick-start proof remains Phase 118. [VERIFIED: `npm ls`; `examples/phoenix_host/playwright.config.ts`; `116-CONTEXT.md`] |
| `rg` | available in shell | Fast stale-claim and source-pattern discovery. | Use for guard discovery and planner scope checks; implementation guard should be ExUnit. [VERIFIED: successful `rg` scans] |
| `gsd-tools` | available for native query handlers; research-plan/classify-confidence handlers unavailable | GSD init/context lookup. | Use only native handlers such as `query init.plan-phase`; do not block Phase 116 on missing research-cache handlers. [VERIFIED: `gsd-tools query init.plan-phase 116`; failed `research-plan`/`classify-confidence` handler checks] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExUnit docs-contract guard | Shell script scanner | Shell scripts can run outside Mix, but Phase 116 context prefers idiomatic ExUnit first and current package version derivation is easier in Mix. [VERIFIED: `116-CONTEXT.md`] |
| Existing `PublishReadiness` integration | Primary release-truth guard | `PublishReadiness` is structured and useful, but context locks it as follow-on after a cheap docs-contract guard exists. [VERIFIED: `lib/crosswake/doctor/publish_readiness.ex`; `116-CONTEXT.md`] |
| Full quick-start command verification | Minimal front-door safety labels | Full command verification is Phase 118; Phase 116 should only prevent public routing into known-bad current instructions. [VERIFIED: `.planning/ROADMAP.md`; `116-CONTEXT.md`] |

**Installation:** No external package installation is expected for Phase 116. [VERIFIED: `116-CONTEXT.md`; existing lockfiles]

**Version verification:** Existing versions were verified from installed tool output and lockfiles; no new registry package should be added in this phase. [VERIFIED: `elixir --version`; `mix --version`; `mix.lock`; `examples/phoenix_host/mix.lock`; `npm ls`]

## Package Legitimacy Audit

> Not applicable: Phase 116 should not install external packages. [VERIFIED: `116-CONTEXT.md`; `.planning/ROADMAP.md`]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None | N/A | N/A | N/A | N/A | N/A | No install planned. [VERIFIED: research scope] |

**Packages removed due to [SLOP] verdict:** none. [VERIFIED: no package install planned]  
**Packages flagged as suspicious [SUS]:** none. [VERIFIED: no package install planned]

## Architecture Patterns

### System Architecture Diagram

```text
Phase 116 inputs
  |
  |-- TODO-001 + targeted example-host tests
  |     |
  |     |-- Flashcards: schema-aligned fixtures/tests -> example proof command can be clean
  |     |
  |     `-- Chimeway: unique full-index fixture data + cleanup -> deterministic registry test
  |
  |-- Public docs and ExDoc extras
  |     |
  |     |-- README / CHANGELOG / install / native_shell / compatibility / support_matrix
  |     |
  |     `-- minimal quick-start/adoption safety labels, not full rewrites
  |
  `-- Release-truth guard
        |
        |-- derive current version from Application.spec(:crosswake, :vsn)
        |-- scan public docs for stale current-version/deferred-shell claims
        `-- fail in normal ExUnit/CI when stale claims return
```

### Recommended Project Structure

```text
test/crosswake/guides/
  release_boundaries_test.exs      # update/reorient into Phase 116 release-truth guard

examples/phoenix_host/test/
  support/flashcards_fixtures.ex   # align fixture attrs with schema
  crosswake_example/flashcards_test.exs
  crosswake_example/chimeway/registry_notification_open_test.exs

guides/
  install.md
  native_shell.md
  compatibility.md
  support_matrix.md

README.md
CHANGELOG.md
examples/QUICK_START.md
guides/adoption.md
```

### Pattern 1: Version-Derived ExUnit Docs Guard

**What:** Put stale-claim scanning in an ExUnit test that reads public docs and derives the current package version from the application spec. [VERIFIED: `116-CONTEXT.md`; `mix.exs`]

**When to use:** Use for DRIFT-01 stale release-truth claims that are cheap to detect locally. [VERIFIED: `.planning/REQUIREMENTS.md`]

**Example:**

```elixir
# Source: existing ExUnit docs-contract style in test/crosswake/guides/release_boundaries_test.exs
defp current_version do
  Application.spec(:crosswake, :vsn) |> to_string()
end

test "public docs do not describe released package truth as pending" do
  version = current_version()

  public_docs = [
    "README.md",
    "CHANGELOG.md",
    "guides/install.md",
    "guides/native_shell.md",
    "guides/compatibility.md",
    "guides/support_matrix.md"
  ]

  for path <- public_docs do
    body = File.read!(path)

    refute body =~ "latest published Hex release remains `0.1.0`"
    refute body =~ "standalone public shell packages are deferred"
    refute Regex.match?(~r/#{Regex.escape(version)}.*(pending|unreleased)/i, body)
  end
end
```

### Pattern 2: Schema-Aligned Flashcards Fixture Repair

**What:** Treat `Card` schema fields as the source of truth and update tests/fixtures from `front`/`back` to `front_text`/`back_text`. [VERIFIED: `examples/phoenix_host/lib/crosswake_example/flashcards/card.ex`; targeted test run]

**When to use:** Use for PROOF-01 Flashcards deterministic drift; do not redesign the Flashcards product surface. [VERIFIED: `116-CONTEXT.md`]

**Example:**

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/flashcards/card.ex
valid_attrs = %{front_text: "front text", back_text: "back text", deck_id: deck.id}

assert {:ok, %Card{} = card} = CrosswakeExample.Flashcards.create_card(valid_attrs)
assert card.front_text == "front text"
assert card.back_text == "back text"
```

### Pattern 3: Chimeway Fixture Isolation Against the Full Unique Shape

**What:** Make every test-owned value in the unique index shape unique, including `installation_ref`, and clean persistent SQLite rows when needed. [VERIFIED: `registry_notification_open_test.exs`; migration/index grep; targeted test run]

**When to use:** Use for the registry notification-open test only; do not build a broad DataCase harness unless narrow repair fails. [VERIFIED: `116-CONTEXT.md`]

**Example:**

```elixir
# Source: examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs
setup do
  # If persistent SQLite rows collide, clean only the tables this test owns.
  Repo.delete_all(NotificationOpenIntentEvent)
  Repo.delete_all(NotificationOpenIntent)

  binding = %CrosswakeExample.Chimeway.TokenBinding{
    binding_ref: unique_ref("bnd"),
    subject_ref: unique_ref("sub"),
    org_ref: unique_ref("org"),
    installation_ref: unique_ref("install"),
    provider: :apns,
    platform: :ios,
    environment: :production,
    token_ref: unique_ref("tok"),
    token_fingerprint: unique_ref("fp")
  }

  {:ok, binding: Repo.insert!(binding)}
end
```

### Anti-Patterns to Avoid

- **Hardcoding `0.1.2` in drift checks:** Derive from `Application.spec(:crosswake, :vsn)` so future releases do not require rewriting guard literals. [VERIFIED: `116-CONTEXT.md`; `mix.exs`]
- **Network registry calls in normal tests:** Public release-truth guards should be cheap and deterministic; exact external registry checks belong at implementation/release time if a claim depends on them. [VERIFIED: `116-CONTEXT.md`; research scope]
- **Fixing docs while preserving stale tests:** `release_boundaries_test.exs` currently asserts the bad deferred-shell phrase, so docs edits must update the contract test. [VERIFIED: `test/crosswake/guides/release_boundaries_test.exs`]
- **Rewriting the whole quick start/adoption guide:** Phase 118 owns the full command-verified rewrite; Phase 116 should only prevent current public surfaces from routing readers into bad commands or fictional authority. [VERIFIED: `.planning/ROADMAP.md`; `116-CONTEXT.md`]
- **Promoting checked-in native hosts as published-coordinate proof:** Phase 119 owns native evidence classification; Phase 116 should cite v11 generated clean-room proof without overclaiming checked-in host truth. [VERIFIED: `.planning/ROADMAP.md`; `116-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release-truth drift detection | A separate custom shell scanner as the first guard | ExUnit docs-contract helper in `release_boundaries_test.exs` | It runs in the normal Mix test surface and can derive the package version directly. [VERIFIED: `116-CONTEXT.md`; existing test style] |
| Package version source of truth | Manual prose constants spread across docs | `Application.spec(:crosswake, :vsn)` or `mix.exs` version | The repo already uses release-please version metadata in `mix.exs`. [VERIFIED: `mix.exs`; `116-CONTEXT.md`] |
| Example-host test isolation | A generic DB harness rewrite | Narrow fixture uniqueness and cleanup for the two failing files | The phase context explicitly limits Chimeway repair to fixture/test isolation first. [VERIFIED: `116-CONTEXT.md`] |
| Public release readiness | New diagnostic subsystem | Existing `Crosswake.Doctor.PublishReadiness` as follow-on | The structured readiness report already exists and should not be overloaded before the cheap guard. [VERIFIED: `lib/crosswake/doctor/publish_readiness.ex`; `116-CONTEXT.md`] |
| Native evidence truth | Phase 116 native host rewrite/classifier | Phase 119 evidence-label decision | Native classification is explicitly deferred out of Phase 116. [VERIFIED: `.planning/ROADMAP.md`; `116-CONTEXT.md`] |

**Key insight:** This phase is about preventing known false proof and stale public claims from reaching adopters; custom infrastructure is lower value than updating existing proof lanes and docs-contract tests. [VERIFIED: `.planning/PROJECT.md`; `.planning/STATE.md`; `116-CONTEXT.md`]

## Common Pitfalls

### Pitfall 1: Green Root Tests Can Preserve Bad Release Truth

**What goes wrong:** The current root docs/readiness targeted test run passes while `release_boundaries_test.exs` still asserts "standalone public shell packages are deferred". [VERIFIED: `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs`; `test/crosswake/guides/release_boundaries_test.exs`]

**Why it happens:** The existing test was written before v11.0 made standalone public shell packages real. [VERIFIED: `.planning/PROJECT.md`; `test/crosswake/guides/release_boundaries_test.exs`]

**How to avoid:** Update the docs and the docs-contract test together; make the test assert absence of stale claims. [VERIFIED: `116-CONTEXT.md`]

**Warning signs:** A plan edits `guides/install.md`, `guides/native_shell.md`, or `guides/compatibility.md` but does not touch `release_boundaries_test.exs`. [VERIFIED: `rg` stale-claim scan]

### Pitfall 2: Chimeway "Unique" Fixture Data Is Not Unique Across the Actual Index

**What goes wrong:** `RegistryNotificationOpenTest` uses unique `binding_ref`, `subject_ref`, and `org_ref`, but keeps `installation_ref: "install_123"` and can collide under the token-binding unique index. [VERIFIED: `registry_notification_open_test.exs`; migration/index grep; targeted test run]

**Why it happens:** The unique index includes `installation_ref`, `provider`, `platform`, `environment`, and `app_identity_posture` in addition to subject/org refs. [VERIFIED: migration/index grep]

**How to avoid:** Generate unique `installation_ref` and clean persistent rows owned by the test where needed. [VERIFIED: `116-CONTEXT.md`; targeted test evidence]

**Warning signs:** `Ecto.ConstraintError` names `chimeway_token_bindings_subject_ref_org_ref_installation_ref_provider_platform_environment_app_identity_posture_index`. [VERIFIED: targeted test run]

### Pitfall 3: Flashcards List Tests Assume an Empty Persistent DB

**What goes wrong:** `list_decks/0 returns all decks` expects one deck but sees rows left by prior tests/runs. [VERIFIED: targeted test run]

**Why it happens:** The example host uses a persistent SQLite DB file and the `test` alias creates/migrates but does not drop/reset data before every targeted run. [VERIFIED: `examples/phoenix_host/mix.exs`; `examples/phoenix_host/config/config.exs`; targeted test run]

**How to avoid:** Scope assertions to unique fixture data or clean owned tables in setup; do not rely on global emptiness. [VERIFIED: targeted test run; existing cleanup pattern grep]

**Warning signs:** A test compares `list_decks() == [deck]` rather than filtering by the fixture id or cleaning the table. [VERIFIED: `flashcards_test.exs`]

### Pitfall 4: Changelog Release Semantics Stay Inverted

**What goes wrong:** `[0.1.2]` remains "Unreleased (pending next Hex publish)" even though Phase 116 context says public docs should treat `[0.1.2]` as released and `[Unreleased]` as future work. [VERIFIED: `CHANGELOG.md`; `116-CONTEXT.md`]

**Why it happens:** The changelog was staged before the live release and not reconciled after v11.0. [VERIFIED: `.planning/PROJECT.md`; `CHANGELOG.md`]

**How to avoid:** Make `[Unreleased]` empty/future-oriented, make `[0.1.2]` a dated released entry, and keep historical `0.1.0` mentions explicitly historical. [VERIFIED: `116-CONTEXT.md`]

**Warning signs:** Phrases such as "latest published Hex release remains `0.1.0`", "`0.1.2` pending", or "`0.1.2` unreleased" appear outside explicit historical context. [VERIFIED: `rg` stale-claim scan]

## Code Examples

Verified patterns from local sources:

### Docs-Contract Negative Scanner

```elixir
# Source: test/crosswake/guides/release_boundaries_test.exs and mix.exs
defp read_public_docs(paths) do
  Enum.map(paths, fn path -> {path, File.read!(path)} end)
end

test "public release docs do not regress to stale release truth" do
  version = Application.spec(:crosswake, :vsn) |> to_string()

  for {path, body} <- read_public_docs(@public_release_docs) do
    assert body =~ version or path in @historical_fixture_docs
    refute body =~ "latest published Hex release remains `0.1.0`"
    refute body =~ "standalone public shell packages are deferred"
  end
end
```

### Flashcards Schema Alignment

```elixir
# Source: examples/phoenix_host/lib/crosswake_example/flashcards/card.ex
def card_fixture(attrs \\ %{}) do
  {:ok, card} =
    attrs
    |> Enum.into(%{
      front_text: "some front text",
      back_text: "some back text"
    })
    |> CrosswakeExample.Flashcards.create_card()

  card
end
```

### Chimeway Unique Fixture Values

```elixir
# Source: examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs
defp unique_ref(prefix), do: "#{prefix}_#{System.unique_integer([:positive])}"

%CrosswakeExample.Chimeway.TokenBinding{
  binding_ref: unique_ref("bnd"),
  subject_ref: unique_ref("sub"),
  org_ref: unique_ref("org"),
  installation_ref: unique_ref("install"),
  provider: :apns,
  platform: :ios,
  environment: :production
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Docs said standalone public shell packages were deferred. | Generated non-local shells resolve SwiftPM/Maven coordinates at the Crosswake package version, and public docs must describe that as shipped release truth without overclaiming checked-in native hosts. | v11.0, shipped 2026-06-17. [VERIFIED: `.planning/PROJECT.md`; `guides/support_matrix.md`; `lib/crosswake/doctor/publish_readiness.ex`] | Phase 116 must remove deferred-shell prose from public docs and tests. [VERIFIED: `rg` stale-claim scan] |
| CHANGELOG treated `0.1.2` as pending/unreleased. | `[0.1.2]` should be a released entry and `[Unreleased]` should describe future work only. | v11.0 release closeout and Phase 116 context. [VERIFIED: `.planning/PROJECT.md`; `116-CONTEXT.md`] | Release-truth guard should catch pending/unreleased phrasing for the current package version. [VERIFIED: `116-CONTEXT.md`] |
| Offline adoption guide described a bridge-owned `Crosswake.mutate` sync engine. | v12 truth is app-owned IndexedDB outbox plus reconnect-triggered `/study/sync` and Ecto reconciliation. | v12.0, shipped 2026-06-18. [VERIFIED: `.planning/PROJECT.md`; `.planning/research/v13-support-truth-guides.md`; `guides/adoption.md`] | Phase 116 should stop treating that guide as current proof; full rewrite remains Phase 118. [VERIFIED: `116-CONTEXT.md`; `.planning/ROADMAP.md`] |

**Deprecated/outdated:**

- "Latest published Hex release remains `0.1.0`" is outdated public-release truth for current docs. [VERIFIED: `CHANGELOG.md`; `116-CONTEXT.md`]
- "`0.1.2` pending/unreleased" is outdated public-release truth for current docs. [VERIFIED: `CHANGELOG.md`; `116-CONTEXT.md`]
- "Standalone public shell packages are deferred" is outdated after v11.0. [VERIFIED: `.planning/PROJECT.md`; `rg` stale-claim scan]
- `Crosswake.mutate` as public offline mutation API is not current v12 proof truth. [VERIFIED: `guides/adoption.md`; `.planning/research/v13-support-truth-guides.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| None | All implementation recommendations are based on repo-local files, phase context, or targeted local command output. | All sections | N/A |

**If this table is empty:** All claims in this research were verified or cited; no user confirmation is needed before planning. [VERIFIED: source list below]

## Open Questions (RESOLVED)

1. **Does Phase 116 need to reverify Maven Central exact currentness?**
   - What we know: `116-CONTEXT.md` says Hex `crosswake` `0.1.2` and SwiftPM tag `v0.1.2` were verified during discussion, and says Maven metadata should be checked again if implementation depends on exact registry assertions. [VERIFIED: `116-CONTEXT.md`]
   - What's unclear: Maven Central exact latest/release metadata was not rechecked in this research session. [VERIFIED: no web/registry lookup performed]
   - Resolution: No planning blocker. Phase 116 should use derived "Crosswake package version" wording where possible; if an implementation task writes an exact Maven latest claim, it must verify Maven metadata at implementation time. [VERIFIED: `116-CONTEXT.md`]

2. **Should Chimeway be excluded instead of fixed?**
   - What we know: The context locks fix-first for Chimeway via narrow test-data isolation, with exclusion only if repair expands beyond that scope. [VERIFIED: `116-CONTEXT.md`]
   - What's unclear: Nothing blocking planning; the targeted failure points to fixture/index isolation, not product behavior. [VERIFIED: targeted test run]
   - Resolution: Plan a narrow repair first, then fallback to documented exclusion only if that repair fails during execution. [VERIFIED: `116-CONTEXT.md`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit/docs-contract tests and root package introspection | yes | 1.19.5 / Erlang OTP 28 | None needed. [VERIFIED: `elixir --version`] |
| Mix | Root and example-host tests | yes | 1.19.5 | None needed. [VERIFIED: `mix --version`] |
| Git | Research commit and source status | yes | 2.41.0 | None needed. [VERIFIED: `git --version`] |
| Node.js | Existing Playwright example-host tooling, mainly Phase 118/120 context | yes | 22.14.0 | Avoid Playwright in Phase 116 unless needed. [VERIFIED: `node --version`; `examples/phoenix_host/package.json`] |
| npm | Existing Playwright dependencies | yes | 11.1.0 | Avoid package changes in Phase 116. [VERIFIED: `npm --version`; `npm ls`] |
| `@playwright/test` | Existing example-host E2E proof context | yes | 1.60.0 installed | Not needed for primary Phase 116 guard. [VERIFIED: `npm ls @playwright/test`] |
| `gsd-tools` native handlers | Phase init/context metadata | yes | handler available for `query init.plan-phase` | Research-plan/classify-confidence handlers are unavailable; use explicit source tags and local command evidence. [VERIFIED: command outputs] |

**Missing dependencies with no fallback:**
- None for Phase 116 implementation. [VERIFIED: environment probes]

**Missing dependencies with fallback:**
- `gsd-tools query research-plan` and `query classify-confidence` are unavailable in this environment; the fallback is direct codebase/docs research with explicit provenance tags. [VERIFIED: command failures]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Elixir/Mix 1.19.5; Playwright 1.60.0 is present but not primary for Phase 116. [VERIFIED: `mix --version`; `npm ls`] |
| Config file | Root `mix.exs`; example host `examples/phoenix_host/mix.exs`; Playwright config `examples/phoenix_host/playwright.config.ts`. [VERIFIED: file reads] |
| Quick run command | `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs` [VERIFIED: command ran green before Phase 116 edits] |
| Example debt run command | `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs test/crosswake_example/chimeway/registry_notification_open_test.exs` [VERIFIED: command ran with 5 failures before repair] |
| Full suite command | `mix test --exclude requires_example_host` plus the repaired example-host targeted command. [VERIFIED: existing CI workflow patterns; example host scope] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PROOF-01 | Flashcards tests/fixtures use `front_text`/`back_text` and do not rely on dirty global DB state. | unit/integration | `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs` | yes. [VERIFIED: file read] |
| PROOF-01 | Chimeway registry notification-open tests use isolated fixture values and deterministic SQLite behavior. | integration | `cd examples/phoenix_host && mix test test/crosswake_example/chimeway/registry_notification_open_test.exs` | yes. [VERIFIED: file read] |
| REL-TRUTH-01 | README/CHANGELOG/guides no longer present stale current-release or deferred-shell claims. | docs-contract | `mix test test/crosswake/guides/release_boundaries_test.exs` | yes. [VERIFIED: file read] |
| REL-TRUTH-01 | Publish readiness remains structurally valid after changelog/release-truth changes. | unit/docs-contract | `mix test test/crosswake/doctor/publish_readiness_test.exs` | yes. [VERIFIED: command ran green before edits] |
| DRIFT-01 | Guard fails on stale current-version, unlabelled `0.1.0`, pending current version, and deferred-shell prose. | docs-contract | `mix test test/crosswake/guides/release_boundaries_test.exs` | yes, but existing assertions must be reoriented. [VERIFIED: file read] |

### Sampling Rate

- **Per task commit:** Run the most local test for the touched surface: `mix test test/crosswake/guides/release_boundaries_test.exs`, `mix test test/crosswake/doctor/publish_readiness_test.exs`, or the targeted example-host file. [VERIFIED: existing test structure]
- **Per wave merge:** Run `mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/doctor/publish_readiness_test.exs` and `cd examples/phoenix_host && mix test test/crosswake_example/flashcards_test.exs test/crosswake_example/chimeway/registry_notification_open_test.exs`. [VERIFIED: targeted command evidence]
- **Phase gate:** Root docs/readiness tests green, example-host `TODO-001` targeted tests green or Chimeway explicitly excluded with narrow public-proof note, and `rg` stale-claim scan has no forbidden current-proof hits. [VERIFIED: requirements and context]

### Wave 0 Gaps

- None for framework install or config; ExUnit tests already exist. [VERIFIED: `mix.exs`; test files]
- Existing `release_boundaries_test.exs` is a semantic gap because it asserts stale deferred-shell prose; Wave 1/2 tasks should update it as part of DRIFT-01. [VERIFIED: file read]

## Security Domain

Security enforcement is enabled because `.planning/config.json` does not explicitly set `workflow.security_enforcement` to `false`. [VERIFIED: `.planning/config.json`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct code change | Do not modify Sigra/auth authority semantics while editing support prose. [VERIFIED: AGENTS.md; `.planning/PROJECT.md`] |
| V3 Session Management | no direct code change | Keep session/native evidence wording backend-owned and avoid shell/WebView token-authority claims. [VERIFIED: AGENTS.md; `guides/support_matrix.md`] |
| V4 Access Control | yes, docs/proof wording | Preserve route-owner, route allowlist, capability allowlist, and fail-closed denial language. [VERIFIED: AGENTS.md; `guides/native_shell.md`; `guides/compatibility.md`] |
| V5 Input Validation | yes, local scanners/tests | Use local-file ExUnit checks with explicit allowlists; do not eval doc contents or accept external input. [VERIFIED: proposed ExUnit pattern; existing tests] |
| V6 Cryptography | no direct code change | Do not add custom crypto or token handling in this phase. [VERIFIED: phase scope] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Public docs overclaim released/native/offline support and cause unsafe adopter decisions. | Spoofing / Repudiation | Docs-contract tests that fail on stale current-version and deferred-shell claims. [VERIFIED: DRIFT-01; `116-CONTEXT.md`] |
| Example-host tests appear green only because public proof commands avoid known debt. | Repudiation | Fix Flashcards and Chimeway first, or narrowly exclude only Chimeway with explicit reason if repair exceeds scope. [VERIFIED: PROOF-01; `116-CONTEXT.md`] |
| Offline docs imply bridge-owned mutation authority. | Elevation of privilege / Tampering | Phase 116 safety labels and Phase 118 full rewrite must preserve app-owned outbox plus backend reconciliation truth. [VERIFIED: `guides/adoption.md`; `.planning/ROADMAP.md`] |
| Drift guard accidentally performs network registry checks in normal CI. | Denial of service / Supply chain exposure | Keep guard local and derived from package metadata; verify external registries only when exact implementation claims require it. [VERIFIED: `116-CONTEXT.md`; research scope] |

## Sources

### Primary (HIGH confidence)

- `AGENTS.md` - project constraints and proof/ownership rules. [VERIFIED: file read]
- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - v13/Phase 116 scope and requirements. [VERIFIED: file reads]
- `.planning/phases/116-proof-debt-and-release-truth/116-CONTEXT.md` - locked decisions, discretion, deferred scope. [VERIFIED: file read]
- `.planning/todos/TODO-001-phoenix-host-pre-existing-test-failures.md` - Flashcards and Chimeway debt source. [VERIFIED: file read]
- `.planning/research/v13-proof-path-docs.md`, `.planning/research/v13-collateral-ci.md`, `.planning/research/v13-support-truth-guides.md` - v13 repo-truth synthesis and scope fences. [VERIFIED: file reads]
- `mix.exs`, `mix.lock`, `examples/phoenix_host/mix.exs`, `examples/phoenix_host/mix.lock`, `examples/phoenix_host/config/config.exs`, `examples/phoenix_host/playwright.config.ts`, `examples/phoenix_host/package.json` - stack, version, docs extras, aliases, and port/tooling truth. [VERIFIED: file reads and version commands]
- `test/crosswake/guides/release_boundaries_test.exs`, `test/crosswake/doctor/publish_readiness_test.exs`, `lib/crosswake/doctor/publish_readiness.ex` - existing release/docs-contract and readiness surfaces. [VERIFIED: file reads and targeted tests]
- `examples/phoenix_host/test/crosswake_example/flashcards_test.exs`, `examples/phoenix_host/test/support/flashcards_fixtures.ex`, `examples/phoenix_host/lib/crosswake_example/flashcards.ex`, `examples/phoenix_host/lib/crosswake_example/flashcards/card.ex`, `examples/phoenix_host/test/crosswake_example/chimeway/registry_notification_open_test.exs` - `TODO-001` implementation targets. [VERIFIED: file reads and targeted test run]
- `README.md`, `CHANGELOG.md`, `examples/QUICK_START.md`, `guides/adoption.md`, `guides/install.md`, `guides/native_shell.md`, `guides/compatibility.md`, `guides/support_matrix.md` - public drift surfaces. [VERIFIED: file reads and `rg` stale-claim scan]

### Secondary (MEDIUM confidence)

- Local discussion/context statement that Hex `crosswake` `0.1.2` and SwiftPM tag `v0.1.2` were verified during discussion. [VERIFIED: `116-CONTEXT.md`; not rechecked externally in this session]

### Tertiary (LOW confidence)

- None used for implementation recommendations. [VERIFIED: no web/training-only source used]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Existing lockfiles and installed tool versions were read directly. [VERIFIED: `mix.lock`; `examples/phoenix_host/mix.lock`; command outputs]
- Architecture: HIGH - Phase scope, ownership tiers, and constraints come from project/phase planning docs and required source files. [VERIFIED: `.planning/*`; `116-CONTEXT.md`; source reads]
- Pitfalls: HIGH - Local command runs reproduced the example-host failures and root docs/readiness tests. [VERIFIED: command outputs]
- External release truth: MEDIUM - Hex/SwiftPM were verified during discussion per context; Maven exact metadata was not rechecked in this session and should be checked only if implementation writes exact Maven claims. [VERIFIED: `116-CONTEXT.md`]

**Research date:** 2026-06-18 [VERIFIED: system date]  
**Valid until:** 2026-07-18 for repo-local planning, or until the next Crosswake release changes current-version truth. [VERIFIED: release-truth scope]

**Research seam note:** `gsd-tools query research-plan` and `gsd-tools query classify-confidence` were unavailable in this environment, so this artifact uses direct source reads, local command evidence, and explicit provenance tags instead of cached research-plan digests. [VERIFIED: command outputs]
