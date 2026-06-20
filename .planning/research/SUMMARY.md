# Project Research Summary — v14.0 Runtime Contract Confidence

**Synthesized:** 2026-06-20 from STACK.md, ARCHITECTURE.md, NATIVE-TESTING.md, FEATURES.md, PITFALLS.md
**Confidence:** HIGH — every claim grounded in direct repo inspection plus external precedent (Phoenix Channels `vsn`, protobuf/`buf`, Stripe API versioning, Hotwire Native, JSON Schema/CommonMark conformance suites).

## The Problem (confirmed in code)

The bridge/runtime protocol version is hand-authored in ~8 places and has drifted:

- `Crosswake.Bridge.Contract` → `@version "1.1.0"` (`lib/crosswake/bridge/contract.ex:10`)
- `Crosswake.Manifest.Types` → `@bridge_protocol_version/@manifest_schema_version/@native_runtime_version "1.0.0"` (`lib/crosswake/manifest/types.ex:651-653`)
- `lib/crosswake/shell/fixtures.ex:82-83` + iOS `route_activation.json` fixtures → `"1.0.0"`
- One silent Kotlin fallback literal: `ActivationCoordinator.kt:594` `?: "1.0.0"`

Native bridge code does **exact** equality (`BridgeChannel.swift:182`, Kotlin equivalent) but reads the *expected* version from the manifest/compatibility JSON at runtime — so it is mostly version-agnostic; the drift surface is Elixir defaults + JSON fixtures + docs + the one Kotlin fallback. Meanwhile Elixir's `compatible_version?/2` already negotiates by `>=` floor. **Elixir negotiates; native demands exact match. They disagree.**

## Convergent Recommendation (one coherent design)

### 1. Canonical source — Elixir is the authority, generate the rest
- Collapse the three Elixir sources into ONE compile-time authority for the bridge protocol version (and keep the three axes — manifest schema / bridge protocol / native runtime — explicit but each with a single source). Phoenix's own channels `vsn` precedent: the Elixir module is the server authority.
- Reach the non-Elixir surfaces (JSON fixtures, generated shell templates, native test vectors, a docs snippet) with a **committed canonical artifact + `mix crosswake.contract.gen` codegen + commit the generated output + `git diff --exit-code` in CI**. This is the `go generate` / `buf generate` / Crosswake's own `brand-structural` + `generator_coordinate_parity` discipline — zero new mental model.
- Kill the Kotlin `?: "1.0.0"` fallback; native must read the value, never assume it.
- **Resolve the `1.1.0` vs `1.0.0` value itself** as part of consolidation (decide the true current protocol version; the published 0.1.x adopter contract must not silently break).

### 2. Drift guards — deterministic, merge-blocking, browser-free
- A pure-Elixir **single-reader ExUnit test**: read the one canonical value, assert every derived surface (JSON fixtures, generated templates, docs snippet, native test vectors) equals it by file read/parse. No Xcode/Gradle needed → merge-blocking. Exact precedents already in repo (`quick_start_adoption_drift_test.exs`, `phase96_threadline_docs_contract_test.exs`).
- Plus **generate-and-diff** so a hand-edited fixture can't survive even if an assertion is suppressed.
- A **`contract_version_parity` doctor check**, sibling to `generator_coordinate_parity`.
- Wire into the existing `merge-blocking-*` aggregator + branch-protection registration. Native-toolchain checks stay **advisory** (required-vs-advisory split).
- Failure-message contract: name the ONE place to edit and the exact regenerate command (principle of least surprise). Avoid vacuous/empty-glob asserts (v12 closeout lesson) and green-but-fabricated proof (v6/v8 lesson).

### 3. Native package behavioral proof — shared golden vectors
- Both packages have only ~1 test file today. Add real tests for the **six behaviors**: activation success/failure, bridge denial, capability allowlist, active-route check, pack-version check, delegate/escape-hatch.
- Most seams already exist (`evaluate()` public on iOS; Android `evaluateForTesting()`; injected `manifestLoader`/`requestLoader`; `PackStore.inMemory()`) — this is writing tests, not restructuring source.
- **One committed `bridge_contract_vectors.json` loaded by all three suites** (Elixir + Swift XCTest + Kotlin JUnit) → a version bump fails all three simultaneously. This is the cross-language conformance-suite pattern (protobuf/JSON-Schema/OTEL).
- Run XCTest on `macos-latest` (no simulator), Kotlin on JVM JUnit (no emulator). Decide which lanes are merge-blocking (deterministic JVM) vs advisory (macOS native), consistent with house split.

### 4. Compatibility semantics & adopter truth — keep `>=`, communicate clearly
- **Recommended fork resolution: keep the `>=` min-version floor, do NOT keep native exact-match.** Exact-match is the footgun that produced the denial; Postgres wire, TLS 1.3, and Phoenix Channels `vsn` all abandoned it. Make the native check negotiate by floor like Elixir already does (or, if deferring the native-comparison change, at minimum make canonical-source agreement render exact-match harmless and document the constraint).
- Map each axis to a rebuild class: additive/minor (new optional command or field) = **core-only, no rebuild**; breaking/major (remove command, rename denial reason, add required field, change type) = **native rebuild required**; any native-binary change = rebuild required; Elixir-only narrowing = **compat-bump only**.
- Doctor finding must name the **change class + full action sequence** (gen.shell → rebuild → resubmit App Store/Play Store → coordinated deploy) + the denial reason seen in logs + a docs link. Front-load the action in microcopy: "Your native shell must be rebuilt and resubmitted to the App Store / Play Store."
- Four cooperating surfaces: changelog upgrade-impact label, support-matrix per-axis table, runtime doctor finding, compatibility-guide decision table (answer first, prose after).

## Phase Ordering (non-negotiable — registry immutability + lockstep release)

1. **Canonical source** (consolidate Elixir authority, resolve the version value, codegen + kill Kotlin fallback).
2. **Drift guards** (single-reader test + generate-and-diff + doctor check + aggregator/branch-protection).
3. **Native behavioral proof** (six behaviors, shared vectors, CI lanes).
4. **Compatibility semantics + adopter docs/doctor truth** (negotiation decision, axis→rebuild map, support matrix, guide, microcopy).
5. Any release/publish happens only after 1–4 are green on `main`.

## Anti-Scope (write into requirements explicitly)

Coherence work only. NOT: new bridge commands/capabilities, an IDL/protobuf redesign, envelope restructuring, breaking the published 0.1.x adopter contract, or promoting simulator/device native evidence to merge-blocking support truth. Over-engineering a full codegen pipeline when a small committed canonical file + diff-check suffices is itself a footgun.

## Sources
- Phoenix Channels `vsn` negotiation — https://hexdocs.pm/phoenix/writing_a_channels_client.html
- Buf breaking-change detection — https://buf.build/docs/breaking/
- Stripe API versioning — https://stripe.com/blog/api-versioning ; mobile SDK versioning — https://docs.stripe.com/sdks/mobile-sdk-versioning
- Protocol Buffers conformance + proto3 compat — https://protobuf.dev/programming-guides/proto3/
- JSON Schema Test Suite — https://github.com/json-schema-org/JSON-Schema-Test-Suite ; CommonMark spec — https://github.com/commonmark/commonmark-spec
- PostgreSQL wire protocol — https://www.postgresql.org/docs/current/protocol-overview.html ; RFC 8446 TLS 1.3 — https://datatracker.ietf.org/doc/html/rfc8446
- Elixir compatibility & deprecations — https://hexdocs.pm/elixir/compatibility-and-deprecations.html
- Full detail: `.planning/research/STACK.md`, `ARCHITECTURE.md`, `NATIVE-TESTING.md`, `FEATURES.md`, `PITFALLS.md`
