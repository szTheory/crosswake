# Phase 122: Drift Guards - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-20
**Phase:** 122-drift-guards
**Areas discussed:** Drift-test surface scope, GUARD-01 vs GUARD-02 split, Doctor check shape, CI topology & registration

**Mode:** User selected all four gray areas and requested deep subagent research per area (pros/cons/tradeoffs, ecosystem idioms, lessons from successful libs/tools, DX/least-surprise emphasis, our own prompts/ + research-dir constraints), then a single coherent one-shot recommendation. Four parallel research agents ran (three web-backed: surface-scope+split, doctor-check, CI-topology; one read-only digest of `.planning/research/*` + `prompts/*`). Findings converged; recommendations below were accepted as locked.

---

## Drift-test surface scope (A)

| Option | Description | Selected |
|--------|-------------|----------|
| Generated JSONs only | Parse-assert only the 3 gen outputs against canonical | |
| Strict split (manifests only in GUARD-01) | GUARD-01 covers only the 2 hand-maintained manifests; generated files left to GUARD-02 | partial |
| Authoritative-owner + tripwire overlap | GUARD-01 owns the 2 manifests (load-bearing) AND tripwires the 3 generated JSONs for friendly local failures; markdown snippet excluded | ✓ |

**User's choice:** Authoritative-owner split with deliberate tripwire overlap (D-01, D-02, D-03).
**Notes:** The two `crosswake_manifest.json` files carry `bridge_protocol_version: "1.1.0"` (line ~350) and are NOT gen-task outputs — generate-and-diff is structurally blind to them; they are the exact drift class that forced the manual 121-04 gap-closure, so GUARD-01 must own them. The markdown `docs/_contract_snippet.md` is excluded from the parse test (honors "JSON parser, not grep" most fully); GUARD-02 owns it byte-exact. Precedents: Ecto `mix ecto.migrations` vs `structure.sql`; cargo-workspace-version; graphql-code-generator #4253 (parse-assert on generated output is redundant against the generator → accept as cheap tripwire, not authority).

## GUARD-01 vs GUARD-02 split (B)

| Option | Description | Selected |
|--------|-------------|----------|
| Full overlap | Both guards cover all surfaces | |
| Strict zero-overlap | GUARD-01 manifests-only, GUARD-02 generated-only | |
| Generator-owns-output / no-generator-owns-asserts (+ documented tripwire) | Decision rule: generator exists ⇒ GUARD-02 authoritative; no generator ⇒ GUARD-01 authoritative; small documented overlap for DX | ✓ |

**User's choice:** Generator-presence decision rule (D-04, D-05) + deterministic-output guardrails (D-06).
**Notes:** GUARD-02 byte-exact owner of all 4 generator outputs; GUARD-01 authoritative owner of the 2 manifests + friendly tripwire on the 3 JSONs. Critical footgun closed: use `git add -A && git diff --cached --exit-code`, never bare `git diff --exit-code` (ignores untracked new files). Gen task already sorts keys + `write_if_changed` (deterministic).

## Doctor check shape (C)

| Option | Description | Selected |
|--------|-------------|----------|
| Regenerate-and-diff data source | Shell out to `mix crosswake.contract.gen` and compare | |
| Read-only parse data source | Parse committed surfaces, compare to `Contract.version()`; never write | ✓ |
| Severity :advisory | Operator-only soft signal; CI is the gate | |
| Severity :error/:merge_blocking | Same verdict as sibling `generator_coordinate_parity` | ✓ |

**User's choice:** Read-only parse (D-07) + `:error`/`:merge_blocking` severity (D-08).
**Notes:** Mirrors `generator_coordinate_parity_check` exactly (read-only, file-based, blocking). Universal doctor precedent is inspect-never-mutate (`brew/npm/flutter doctor`, `cargo verify-project`). Drift is a deterministic correctness defect, not heuristic noise (contrast brew's ignorable env warnings) → must tell the same truth as CI/test. `hint` points at the fix verb `mix crosswake.contract.gen`; the check stays pure.

## CI topology & registration (D)

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into existing aggregator | Add both checks to `merge-blocking-offline-sync-e2e` | |
| New dedicated gate workflow | New `contract-drift-gate.yml` + own `re-actors/alls-green` aggregator + new register script | ✓ |

**User's choice:** New dedicated `contract-drift-gate.yml` (D-09, D-10) + new `script/register-contract-gate.sh` (D-11).
**Notes:** Mirrors v12.0 "one purpose-named gate per domain, single aggregator as sole required check." Folding would couple an orthogonal flaky browser/native domain to a deterministic codegen domain and mislead failure attribution. Two named sibling jobs (`guard-01-contract-drift-test`, `guard-02-generate-and-diff`) → aggregator `merge-blocking-contract-drift` (the sole required context). GUARD-01 gets its own job, not buried in a generic `mix test` lane. Registration clones the green-first-refuse + granular-PATCH + script-not-auto-toggle pattern. Precedents: re-actors/alls-green adopters (aiohttp, attrs, pytest, pip-tools); Kubernetes verify-codegen; Terraform github_branch_protection as codified-not-clicked.

## Cross-cutting: failure-message contract (D-12)

Every drift failure names (1) the canonical source (`Crosswake.Bridge.Contract.version/0`), (2) each drifted surface with actual vs expected, (3) the exact fix command `mix crosswake.contract.gen`. Careful-maintainer voice (brand book). Correction logged: pre-Phase-121 research docs cite a stale `mix crosswake.gen.fixtures` / `priv/contract/runtime_contract.json` — neither shipped; the real canonical is the Elixir constant and the real task is `mix crosswake.contract.gen`.

---

## Claude's Discretion

- Exact GUARD-01 test file name/location, module/function home of `contract_version_parity`, JSON-load shape (`setup_all` vs per-test), and the optional snippet golden assertion.
- CI job step ordering, cache keys (mirror existing gate jobs on `mix.lock`), `allowed-skips`/`if: always()` wiring — provided the aggregator is the sole required check and both checks are hermetic.

## Deferred Ideas

- Native `>=` floor reconciliation + compatibility guide / support-matrix / changelog labels — Phase 124.
- Wiring `bridge_contract_vectors.json` into Swift/Kotlin/Elixir behavioral suites + six native behaviors — Phase 123.
- Pre-publish fixture-verification gate (`...verify_published_fixtures`, PITFALLS 2.4 registry-immutability) — post-milestone publish step.
- ExUnit guard asserting Hex `vsn` is never compared to `Contract.version()` (PITFALLS 2.5 independence) — optional future hardening, out of GUARD-01..04 scope.
