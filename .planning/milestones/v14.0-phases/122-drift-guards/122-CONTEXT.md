# Phase 122: Drift Guards - Context

**Gathered:** 2026-06-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the canonical bridge/runtime contract (single-sourced in Phase 121) impossible to silently re-diverge. Ship three guards over the surfaces that carry the contract version, plus the merge-blocking CI plumbing that enforces them:

1. **GUARD-01** — a pure-Elixir, browser/native-free, merge-blocking **ExUnit drift test** that reads each version-bearing committed surface via a **JSON parser (never a text grep)** and asserts it equals `Crosswake.Bridge.Contract.version()`, with a failure message naming the one file to edit and the exact regenerate command.
2. **GUARD-02** — a **generate-and-diff CI check** (`mix crosswake.contract.gen` followed by a working-tree diff) that fails when any *generated* contract artifact is hand-edited or stale.
3. **GUARD-03** — a `contract_version_parity` **doctor check** in `mix crosswake.doctor`, sibling to the existing `generator_coordinate_parity`, that reports drift to operators without reading CI logs.
4. **GUARD-04** — register the drift checks in the merge-blocking CI aggregator + branch protection via a committed script that **documents** the PATCH step (v12.0 script+document pattern), keeping native-toolchain checks advisory (required-vs-advisory split).

Covers requirements **GUARD-01 through GUARD-04**. This is coherence/guard work — no new contract surfaces, no version-value changes, no native `>=` reconciliation, no public-docs rewrite.

**Not in this phase:** native `>=` floor reconciliation and the compatibility guide/support-matrix/changelog labels (Phase 124); wiring `bridge_contract_vectors.json` into the Swift/Kotlin/Elixir *behavioral* test suites and the six native behaviors (Phase 123); any native-package publish (after all four phases green on main). Phase 122 *guards* the canonical artifacts Phase 121 produced; it does not extend or consume them behaviorally.

</domain>

<decisions>
## Implementation Decisions

The unifying rule behind A and B: **"Is there a deterministic generator that emits this value into this file?"** → **YES** ⇒ generate-and-diff (GUARD-02) is the authoritative owner. **NO** ⇒ parse-and-assert (GUARD-01) is the authoritative owner. This mirrors the dominant industry partition (Ecto's `mix ecto.migrations` semantic check vs `structure.sql` regenerate-diff; Cargo workspace cross-file version asserts where no generator exists; Kubernetes `verify-codegen` regenerate-diff for generated trees).

### A. Drift-test surface scope (GUARD-01)
- **D-01:** GUARD-01 parse-asserts these committed surfaces against `Crosswake.Bridge.Contract.version()`:
  - **Primary (load-bearing) — the two hand-maintained manifests:** `examples/ios_shell_host/Fixtures/crosswake_manifest.json` and `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` (each carries `bridge_protocol_version` at ~line 350). **These are NOT gen-task outputs** — no generator emits them, so generate-and-diff is structurally blind to them. They are exactly the drift class that required the manual 121-04 gap-closure. GUARD-01 is the *only* automated guard that catches them.
  - **Tripwire (redundant-by-design) — the three generated JSONs:** `examples/ios_shell_host/Fixtures/route_activation.json`, `examples/android_shell_host/app/src/main/assets/route_activation.json`, `test/fixtures/bridge_contract_vectors.json`. GUARD-02 is authoritative for these; GUARD-01 still asserts them so a developer gets a precise, human-readable `expected "1.1.0", got "1.0.0"` failure locally in `mix test` (and which file) *before* CI's opaque diff. The small overlap is a deliberate DX win, documented in-test as "GUARD-02 is the source of truth for generated files."
- **D-02:** **Exclude `docs/_contract_snippet.md` from the parse test.** It is markdown, not JSON; honoring the "JSON parser, not grep" rule most fully means *not* extracting a value from it at all. **GUARD-02's generate-and-diff owns it byte-exact.** Do NOT embed a fenced ```json block in it (that would create a *new* duplicated drift surface) and do NOT pull in a markdown AST parser. (Optional, planner's discretion: a thin ExUnit golden assertion `File.read!(snippet_path) == <generator's own render fn>` using the gen task's existing render helper — no snapshot lib — if a local tripwire for the snippet is wanted.)
- **D-03:** Scope both guards to the **committed source paths only.** Ignore `build/`, `intermediates/`, `app/build/`, and `.claude/worktrees/` copies found on disk — those are build artifacts / worktree copies, not source of truth.

### B. GUARD-01 vs GUARD-02 division of labor
- **D-04:** **GUARD-02 (generate-and-diff) is the authoritative owner of all four generator outputs** (`route_activation.json` ×2, `bridge_contract_vectors.json`, `docs/_contract_snippet.md`). It is byte-exact and exhaustive: it catches drift the semantic test never asserts on (whitespace, key ordering, the markdown table body). It proves "regenerated output == committed output."
- **D-05:** **GUARD-01 (parse-assert) is the authoritative owner of the two hand-maintained manifests** (where no generator exists) and a deliberate fast tripwire on the three generated JSONs. It proves "the version value in each committed surface == canonical." Failure modes stay unambiguous because *ownership is documented*: a manifest drift can only fail GUARD-01; a generated-file edit fails GUARD-02 (and GUARD-01 as a friendlier echo for the 3 JSONs).
- **D-06:** **Deterministic-output guardrails for GUARD-02 (prevent flaky CI — the #1 generate-and-diff footgun):**
  - Gate on **`git add -A && git diff --cached --exit-code`** (or `git add -N . && git diff --exit-code`), **never a bare `git diff --exit-code`** — plain `git diff` ignores untracked files, so a future gen-task that emits a *new* file would pass spuriously.
  - The gen task already sorts keys before emit and uses `write_if_changed` (deterministic); keep it that way. Add a one-line CI comment pointing at the sort invariant so a future maintainer does not "optimize" it away.
  - No timestamps / host paths in generated output (the static `_generated_by` / `_regenerate` strings are fine). Pin the Elixir/OTP toolchain in the gate job (matching existing jobs) so encoder output cannot shift across versions.

### C. Doctor check shape (GUARD-03)
- **D-07:** **Data source = read-only parse.** `contract_version_parity` reads and parses the committed surfaces (the two manifests + the JSON fixtures) from cwd and compares each parsed `bridge_protocol_version` to `Crosswake.Bridge.Contract.version()`. It **never** shells out to `mix crosswake.contract.gen` and **never** writes/regenerates. This mirrors the existing `generator_coordinate_parity` check (which reads committed templates) exactly: read-only, fast, deterministic, side-effect-safe in any operator checkout. Enumerate the surfaces explicitly, like the sibling enumerates its templates. Universal doctor precedent (`brew/npm/flutter doctor`, `cargo verify-project`, `terraform validate`) is *inspect, never mutate* — the mutating verb stays a separate command.
- **D-08:** **Severity = `:error` / `:merge_blocking`,** same as `generator_coordinate_parity`. Contract drift is a *deterministic correctness defect* (published surfaces literally disagree on a protocol version), not heuristic environmental noise — so the operator-facing check must tell the same truth as the ExUnit test and the CI diff. The redundancy across CI/test/doctor is the point (defense-in-depth, consistent verdict). `message` + `details` name the exact drifted file, its found version, and the expected `Contract.version()`; `hint` points at the fix verb `mix crosswake.contract.gen`. Green when all surfaces agree.

### D. CI topology & registration (GUARD-04)
- **D-09:** **New dedicated workflow `.github/workflows/contract-drift-gate.yml`** (purpose-named per domain), NOT folded into `merge-blocking-offline-sync-e2e`. Rationale: contract-drift is an orthogonal domain from offline-sync-e2e; a misleadingly-named aggregator would couple a flaky browser/native domain to a deterministic codegen domain and confuse failure attribution. Mirrors the established v12.0 "one purpose-named gate workflow per domain, single aggregator as the sole required check" idiom. Cost (one extra required context) is the intended, bounded cost of `alls-green`.
- **D-10:** Inside it, **two named sibling jobs** roll up to one aggregator:
  - `guard-01-contract-drift-test` — runs the GUARD-01 ExUnit drift test **as its own job** (e.g. `mix test test/.../contract_drift_test.exs`), NOT buried in a generic `mix test` lane, so a drift failure produces a precise red dot.
  - `guard-02-generate-and-diff` — runs `mix crosswake.contract.gen` then the `git add -A && git diff --cached --exit-code` gate, emitting a GitHub `::error::` annotation `"Generated contract surfaces are out of date. Run 'mix crosswake.contract.gen' and commit."` plus `git --no-pager diff --cached --stat`.
  - `merge-blocking-contract-drift` — aggregator using `re-actors/alls-green@release/v1`, `needs:` both, `if: always()`, `jobs: ${{ toJSON(needs) }}`. This aggregator job name is the **sole required status check** registered in branch protection. Both jobs are pure-Elixir/hermetic (no Xcode/Gradle) → eligible to be merge-blocking; native-toolchain checks stay advisory.
- **D-11:** **New `script/register-contract-gate.sh`,** a near-verbatim clone of `script/register-e2e-gate.sh`: requires `gh` admin scope; **refuses (exit 2) until `merge-blocking-contract-drift` has at least one successful run on `main`** (green-first guard — prevents the "Expected — Waiting for status" deadlock that freezes all PRs); granular `gh api -X PATCH` to `required_status_checks` preserving `strict:true` and using `unique_by(.context)` for idempotency (no old context to drop, so the OLD_CHECK var is empty/no-op). The green-first preflight must match on the **aggregator** job's conclusion, not a sibling. **Script + document the PATCH; do NOT auto-toggle branch protection** (historically human/harness-gated in this environment — v12.0 pattern).

### Failure-message contract (cross-cutting — applies to GUARD-01 and GUARD-03 messages)
- **D-12:** Every drift failure message follows the Crosswake house contract: name **(1) the canonical source** (`Crosswake.Bridge.Contract.version/0` at `lib/crosswake/bridge/contract.ex`, value), **(2) each drifted surface** with `actual` vs `expected`, **(3) the exact fix command `mix crosswake.contract.gen`.** Careful-maintainer voice, operational truth, no hype. **Use the real task name `mix crosswake.contract.gen`** — some pre-Phase-121 research docs cite a stale `mix crosswake.gen.fixtures`; that name was never shipped. Reject bare `ExUnit.AssertionError`-style messages ("left 1.0.0, right 1.1.0") — they don't say which file or what to run.

### Claude's Discretion
- Exact test file name/location for GUARD-01 (e.g. `test/crosswake/contract/contract_drift_test.exs` vs `test/crosswake/guides/...`), the precise module/function home of the `contract_version_parity` check within `publish_readiness.ex` (or a sibling doctor module), the precise `setup_all` vs per-test JSON-load shape, and the optional snippet golden assertion — all planner/researcher discretion provided D-01..D-12 hold.
- Exact CI job step ordering, cache keys (mirror the existing gate jobs keyed on `mix.lock`), and `allowed-skips`/`if: always()` wiring details — discretion, provided the aggregator is the sole required check and the two checks are hermetic.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone planning
- `.planning/ROADMAP.md` — Phase 122 goal, success criteria 1–4, milestone phase ordering and required-vs-advisory split rationale.
- `.planning/REQUIREMENTS.md` — GUARD-01..04 definitions and the phase-ordering non-negotiable note.
- `.planning/phases/121-canonical-contract-source/121-CONTEXT.md` — what Phase 121 *actually shipped* (canonical = the Elixir constant, NOT a `priv/contract/*.json`; gen task = `mix crosswake.contract.gen`). Authoritative over older research docs where they conflict.
- `.planning/phases/121-canonical-contract-source/121-VERIFICATION.md` — verified-complete state of the canonical source the guards protect.

### Research (read for principles; treat pre-121 implementation specifics as superseded by 121-CONTEXT)
- `.planning/research/PITFALLS.md` — drift-guard failure-message contract (Pitfall 3.3), parse-not-grep (3.1), assert-specific-values / anti-vacuous proof (3.4–3.5), file-level-over-build-level guards + flaky→advisory demotion (3.2), docs-must-not-outrun-proof (5.4). **NOTE:** its example fix commands say `mix crosswake.gen.fixtures` / reference `priv/contract/runtime_contract.json` — both stale; the shipped reality is `mix crosswake.contract.gen` and the Elixir constant (see D-12).
- `.planning/research/ARCHITECTURE.md` — generate-and-diff discipline, the "Failure Message Contract" target format, the merge-blocking-hermetic vs advisory-native split, and the `contract-drift-gate.yml` topology sketch. Same `gen.fixtures`/`priv/contract` staleness caveat applies.
- `.planning/research/STACK.md` — three-axis version model, "one obvious place to edit," `contract_version_parity` doctor-check sketch (adapt the data source to D-07: parse committed surfaces, not a `priv/contract` JSON).
- `.planning/research/SUMMARY.md` — convergent design (Elixir authority + gen + diff).

### Code to mirror / extend
- `lib/crosswake/doctor/publish_readiness.ex:536-577` — `generator_coordinate_parity_check/1`: the read-only, file-based, blocking parity-check idiom to clone for `contract_version_parity` (GUARD-03). Lines 504–533 show the advisory-severity precedent in the same module (not used here — D-08 picks `:error`).
- `lib/crosswake/doctor/doctor.ex:128-189` + `lib/mix/tasks/crosswake.doctor.ex` — how findings aggregate and how the task exits non-zero on any `:error` finding.
- `lib/crosswake/doctor/check.ex:1-19` — the `Check` finding struct shape (severity/code/message/hint/details).
- `lib/mix/tasks/crosswake.contract.gen.ex:33-36` — the four output paths GUARD-02 regenerates; `write_if_changed` + sorted-key emit (the determinism GUARD-02 relies on).
- `test/crosswake/guides/native_evidence_drift_test.exs`, `test/crosswake/guides/quick_start_adoption_drift_test.exs` — established ExUnit drift-test idiom (File.read! → parse/scan → collect `%{path, line, category, detail}` failures → `assert failures == [], <formatted message>`). Mirror this structure and the location-forward failure voice for GUARD-01.

### Code that defines the canonical value the guards assert against
- `lib/crosswake/bridge/contract.ex:10` (`@version "1.1.0"`), `version/0` (~line 105) — THE canonical bridge-protocol authority. GUARD-01/03 read `Crosswake.Bridge.Contract.version()` at runtime.
- `lib/crosswake/manifest/types.ex:652` — `@bridge_protocol_version Crosswake.Bridge.Contract.version()` (compile-time reference; cannot drift — *not* a guard target, it's proof the Elixir side is single-sourced).

### CI / registration to mirror (v12.0 pattern)
- `.github/workflows/offline-sync-e2e-gate.yml` — the sibling-jobs + single `re-actors/alls-green` aggregator topology (`merge-blocking-offline-sync-e2e`) to mirror for `contract-drift-gate.yml`.
- `script/register-e2e-gate.sh` — the green-first-guard + granular-PATCH + script-not-auto-toggle registration pattern to clone as `script/register-contract-gate.sh`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `generator_coordinate_parity_check/1` (`publish_readiness.ex:536-577`) — read-only, file-based, blocking parity check; direct template for `contract_version_parity`. Same `ReadinessCheck`/`result_check` shape, same `proof_class: :merge_blocking`.
- `mix crosswake.contract.gen` (`crosswake.contract.gen.ex`) — already hermetic, network-free, idempotent (`write_if_changed`), sorted-key JSON. GUARD-02 just re-runs it and diffs; no new generator work.
- The two `*_drift_test.exs` files — a working ExUnit drift-test scaffold (failure-collection + formatted-message pattern) to copy for GUARD-01.
- `re-actors/alls-green@release/v1` + `script/register-e2e-gate.sh` — the entire merge-blocking-gate + branch-protection-registration machinery already exists; Phase 122 instantiates a second copy for the contract domain.

### Established Patterns
- **Generate-and-commit-and-diff discipline** already in the repo (brand tokens, generator coordinates, now contract.gen) — GUARD-02 is "zero new mental model."
- **One purpose-named gate workflow per domain → one `alls-green` aggregator → that aggregator is the sole required status check** (v12.0). Phase 122 follows it verbatim.
- **Script + document branch-protection PATCH, never auto-toggle** (v12.0 / `register-e2e-gate.sh`), with a green-first refuse guard.
- **Parse-not-grep for every version guard** (PITFALLS 3.1) — locked project rule; GUARD-01 and GUARD-03 both decode JSON.

### Integration Points
- `contract_version_parity` plugs into the doctor findings aggregation (`doctor.ex`) so `mix crosswake.doctor` exits non-zero on drift.
- `contract-drift-gate.yml`'s `merge-blocking-contract-drift` aggregator becomes a new required status check (registered out-of-band via the script + documented PATCH).
- GUARD-01 runs in the normal `mix test` *invocation* but as a **dedicated CI job** so its red/green dot is isolated and individually attributable.
- The two hand-maintained `crosswake_manifest.json` files are the only contract surface with NO generator — GUARD-01 is their sole automated guardian; keep that explicit so a future contributor doesn't assume generate-and-diff covers them.

</code_context>

<specifics>
## Specific Ideas

- The 121-04 incident (manual alignment of both `crosswake_manifest.json` to bridge `1.1.0`) is the concrete drift class GUARD-01 exists to catch automatically going forward — the manifests are hand-maintained and unguarded until this phase.
- `git diff --exit-code` without `git add -A`/`-N` silently passes on newly-created untracked files — the canonical generate-and-diff footgun; D-06 closes it.
- "The check and the fix are the same tool" (cf. `mix format --check-formatted`) — GUARD-02's failure message must literally say `run mix crosswake.contract.gen and commit`, the same verb that fixes it.

</specifics>

<deferred>
## Deferred Ideas

- **Native `>=` min-version-floor reconciliation** (`BridgeChannel.swift:182`, `BridgeChannel.kt:101`) + compatibility guide / support-matrix / changelog upgrade-impact labels — Phase 124 / COMPAT-*.
- **Wiring `bridge_contract_vectors.json` into the Swift/Kotlin/Elixir behavioral test suites** and the six native behaviors — Phase 123 / NTEST-*.
- **Pre-publish fixture-verification gate** (`mix crosswake.contract.verify_published_fixtures` blocking native-package publish on version divergence — PITFALLS 2.4 registry-immutability footgun) — belongs to a publish phase after all four v14 phases are green; note for the v14 publish step, not Phase 122.
- **An ExUnit test asserting `Application.spec(:crosswake)[:vsn]` is NOT compared to `Contract.version()` anywhere** (PITFALLS 2.5 — Hex version vs bridge version independence) — a nice coherence guard, but out of GUARD-01..04 scope; capture for a future hardening pass if desired.

None of these are scope creep into 122 — they are explicitly-ordered later phases or post-milestone hardening.

</deferred>

---

*Phase: 122-drift-guards*
*Context gathered: 2026-06-20*
