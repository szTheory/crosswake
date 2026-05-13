---
phase: 01-route-policy-foundation
verified: 2026-05-13T22:09:52Z
status: passed
score: 11/11 must-haves verified
overrides_applied: 0
---

# Phase 1: Route Policy Foundation Verification Report

**Phase Goal:** Phoenix developers can declare explicit runtime ownership and route constraints without ambiguity.
**Verified:** 2026-05-13T22:09:52Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Phoenix developers can label each route with the public Phase 1 runtime taxonomy. | ✓ VERIFIED | `Crosswake.Policy.Schema` only allows `:live_view`, `:offline_island`, and `:native_screen`, while explicitly rejecting reserved `:adapter` at [lib/crosswake/policy/schema.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/schema.ex:6) and [lib/crosswake/policy/schema.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/schema.ex:78). Tests lock this behavior at [test/crosswake/policy/schema_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/schema_test.exs:7) and [test/crosswake/policy/route_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/route_test.exs:18). Roadmap clarification explicitly reserves `adapter` in Phase 1 at [.planning/ROADMAP.md](/Users/jon/projects/crosswake/.planning/ROADMAP.md:32). |
| 2 | Crosswake-managed route policy requires `id` and `runtime`, with explicit defaults for offline, capabilities, packs, and sync. | ✓ VERIFIED | `Crosswake.Policy.Route` enforces `id` and `runtime` and merges defaults before schema validation at [lib/crosswake/policy/route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex:9) and [lib/crosswake/policy/route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex:22). Defaults are defined at [lib/crosswake/policy/defaults.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/defaults.ex:6). Tests cover required fields and default normalization at [test/crosswake/policy/schema_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/schema_test.exs:7) and [test/crosswake/policy/route_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/route_test.exs:8). |
| 3 | Phase 1 policy data normalizes into typed structs instead of leaking raw maps into later phases. | ✓ VERIFIED | `Route.new/1` and `Route.new!/1` return `%Crosswake.Policy.Route{}` after validation at [lib/crosswake/policy/route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex:22). Router metadata attaches compiled structs under `:crosswake_policy` at [lib/crosswake/policy/router_metadata.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/router_metadata.ex:11). Tests assert `%Route{}` round-trips through router introspection at [test/crosswake/router_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_test.exs:9). |
| 4 | Phoenix developers can declare Crosswake policy next to router routes instead of maintaining a separate registry. | ✓ VERIFIED | `Crosswake.Router` provides router-local `crosswake:` and `crosswake_defaults` macros at [lib/crosswake/router.ex](/Users/jon/projects/crosswake/lib/crosswake/router.ex:38) and [lib/crosswake/router.ex](/Users/jon/projects/crosswake/lib/crosswake/router.ex:47). Fixture routers author policy inline beside `get` and `live` routes at [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:44). |
| 5 | Scope defaults merge into route-level metadata without hiding explicit per-route ownership. | ✓ VERIFIED | Nested AST rewriting applies `crosswake_defaults` locally and merges route overrides with route precedence at [lib/crosswake/router/scope_defaults.ex](/Users/jon/projects/crosswake/lib/crosswake/router/scope_defaults.ex:19), [lib/crosswake/router/scope_defaults.ex](/Users/jon/projects/crosswake/lib/crosswake/router/scope_defaults.ex:64), and [lib/crosswake/policy/merge.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/merge.ex:6). Tests verify inherited defaults and route-local overrides at [test/crosswake/router_defaults_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_defaults_test.exs:9) and [test/crosswake/router_defaults_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_defaults_test.exs:24). |
| 6 | Phoenix developers can declare offline mode, required capabilities, pack dependencies, sync resources, and security sensitivity per route. | ✓ VERIFIED | Schema supports `offline`, `capabilities`, `packs`, `sync`, and `security` at [lib/crosswake/policy/schema.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/schema.ex:21). Fixture routes declare all of these axes at [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:69) and [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:85). Tests assert the normalized values at [test/crosswake/router_defaults_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_defaults_test.exs:12) and [test/crosswake/policy/route_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/route_test.exs:25). |
| 7 | Compiled Crosswake policy is attached to Phoenix route metadata so router introspection remains authoritative. | ✓ VERIFIED | `RouterMetadata.attach/2` stores raw `:crosswake` and compiled `:crosswake_policy` metadata at [lib/crosswake/policy/router_metadata.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/router_metadata.ex:11). `Crosswake.Router.__route_options__/3` wires attachment into route compilation at [lib/crosswake/router.ex](/Users/jon/projects/crosswake/lib/crosswake/router.ex:98). Tests confirm route metadata and `Phoenix.Router.route_info/4` expose the compiled policy at [test/crosswake/router_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_test.exs:9) and [test/crosswake/router_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_test.exs:26). |
| 8 | Invalid or internally inconsistent route policy fails at compile time with route-local, actionable error messages. | ✓ VERIFIED | `Crosswake.Policy.Compiler` normalizes routes, aggregates duplicate-id and semantic errors, and returns `Diagnostic` failures at [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:17), [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:41), and [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:52). `Diagnostic.format/1` includes route, helper, file/line, offending key, and fix hint at [lib/crosswake/policy/diagnostic.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/diagnostic.ex:17) and [lib/crosswake/policy/diagnostic.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/diagnostic.ex:34). Tests cover required metadata, duplicate ids, invalid enums, route context, and fix hints at [test/crosswake/policy/compiler_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compiler_test.exs:22) and [test/crosswake/policy/compile_error_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compile_error_test.exs:8). |
| 9 | Phase 1 compile-time checks are strict about declarative contradictions but do not claim environment truth. | ✓ VERIFIED | Semantic checks are limited to local route-policy contradictions in `Crosswake.Policy.Validator` at [lib/crosswake/policy/validator.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/validator.ex:38). There are no environment, shell, manifest, or filesystem compatibility checks in this phase; tests explicitly cover contradiction checks only at [test/crosswake/policy/compiler_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compiler_test.exs:39). |
| 10 | Incremental adoption gaps can warn without blocking compilation. | ✓ VERIFIED | `Compiler.compile/2` separates unmanaged routes, builds warnings, and emits them only on successful compilation at [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:22), [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:62), and [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:71). Warning formatting is defined at [lib/crosswake/policy/warning.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/warning.ex:15). Tests prove unmanaged routes warn without failure and that hard validation failures do not downgrade into warnings at [test/crosswake/policy/warning_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/warning_test.exs:12) and [test/crosswake/policy/warning_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/warning_test.exs:33). |
| 11 | Developers can bootstrap a host Phoenix app and host-owned iOS/Android shell workspaces with explicit ownership boundaries and honest Phase 1 limits. | ✓ VERIFIED | `mix crosswake.install` patches the host router, creates a host-owned policy module, and writes an install manifest at [lib/mix/tasks/crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:19), [lib/crosswake/install/patcher.ex](/Users/jon/projects/crosswake/lib/crosswake/install/patcher.ex:12), and [lib/crosswake/install/manifest.ex](/Users/jon/projects/crosswake/lib/crosswake/install/manifest.ex:13). `mix crosswake.gen.shell` generates iOS/Android shell skeletons with explicit Phase 1 boundaries at [lib/mix/tasks/crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:15), [priv/templates/crosswake/shell/ios/README.md.eex](/Users/jon/projects/crosswake/priv/templates/crosswake/shell/ios/README.md.eex:1), and [priv/templates/crosswake/shell/android/README.md.eex](/Users/jon/projects/crosswake/priv/templates/crosswake/shell/android/README.md.eex:1). Tests prove idempotent install behavior and shell ownership docs at [test/mix/tasks/crosswake_install_test.exs](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_install_test.exs:32) and [test/mix/tasks/crosswake_gen_shell_test.exs](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_gen_shell_test.exs:8). Docs align with the actual behavior at [guides/install.md](/Users/jon/projects/crosswake/guides/install.md:1). |

**Score:** 11/11 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/policy/route.ex` | Normalized route policy struct with required fields and public enums | ✓ VERIFIED | Exists, substantive, and used by router metadata and compiler normalization. |
| `lib/crosswake/policy/defaults.ex` | Canonical defaults for omitted route options | ✓ VERIFIED | Exists, substantive, and consumed by `Crosswake.Policy.Route`. |
| `lib/crosswake/policy/schema.ex` | NimbleOptions route-policy validation schema | ✓ VERIFIED | Exists, substantive, and consumed by `Route.new/1`. |
| `lib/crosswake/router.ex` | Router-adjacent DSL for `crosswake:` route metadata and defaults | ✓ VERIFIED | Exists, substantive, and used by fixture routers via `use Crosswake.Router`. |
| `lib/crosswake/policy/router_metadata.ex` | Metadata attach/fetch helpers | ✓ VERIFIED | Exists, substantive, and wired into route compilation and router tests. |
| `test/crosswake/router_test.exs` | Integration coverage for route-level declarations | ✓ VERIFIED | Exists, substantive, and passes in targeted test suite. |
| `lib/crosswake/policy/compiler.ex` | Route-policy compile pipeline | ✓ VERIFIED | Exists, substantive, and exercised by compiler and diagnostic tests. |
| `lib/crosswake/policy/validator.ex` | Semantic invariant checks | ✓ VERIFIED | Exists, substantive, and invoked from compiler. |
| `lib/crosswake/policy/diagnostic.ex` | Aggregated compile-time error formatting | ✓ VERIFIED | Exists, substantive, and formats compiler failures. |
| `lib/mix/tasks/crosswake.install.ex` | Idempotent host installer entrypoint | ✓ VERIFIED | Exists, substantive, and wired to patcher and manifest writer. |
| `lib/mix/tasks/crosswake.gen.shell.ex` | Native shell scaffold generator | ✓ VERIFIED | Exists, substantive, and generates both targets in tests. |
| `guides/install.md` | Install and ownership-boundary documentation | ✓ VERIFIED | Exists, substantive, and matches task behavior and Phase 1 limits. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/crosswake/policy/schema.ex` | `lib/crosswake/policy/route.ex` | validated option normalization into struct | ✓ WIRED | Realized in `Crosswake.Policy.Route.new/1`, which calls `Schema.validate/1` before `struct!` construction at [lib/crosswake/policy/route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex:22). |
| `lib/crosswake/policy/defaults.ex` | `lib/crosswake/policy/route.ex` | default merge before struct construction | ✓ WIRED | `Defaults.route/0` feeds `merged_options/1` before validation at [lib/crosswake/policy/route.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/route.ex:41). |
| `lib/crosswake/router.ex` | `lib/crosswake/policy/merge.ex` | scope defaults merged into route metadata | ✓ WIRED | `crosswake_defaults` delegates to `ScopeDefaults.apply/3`, which uses `Merge.route_defaults/2` at [lib/crosswake/router/scope_defaults.ex](/Users/jon/projects/crosswake/lib/crosswake/router/scope_defaults.ex:19) and [lib/crosswake/router/scope_defaults.ex](/Users/jon/projects/crosswake/lib/crosswake/router/scope_defaults.ex:68). |
| `lib/crosswake/router.ex` | `lib/crosswake/policy/router_metadata.ex` | compiled policy stored on Phoenix route metadata | ✓ WIRED | `__route_options__/3` calls `RouterMetadata.attach/2` at [lib/crosswake/router.ex](/Users/jon/projects/crosswake/lib/crosswake/router.ex:98). |
| `lib/crosswake/policy/compiler.ex` | `lib/crosswake/policy/validator.ex` | validated normalized routes before compiler emits metadata | ✓ WIRED | Compiler appends `Validator.validate/2` results before success/error return at [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:41). |
| `lib/crosswake/policy/validator.ex` | `lib/crosswake/policy/diagnostic.ex` | semantic failures rendered as actionable compile diagnostics | ✓ WIRED | Validator emits `Error` structs that compiler wraps in `Diagnostic.new/1`; `Diagnostic.format/1` renders them with context and hints at [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:52) and [lib/crosswake/policy/diagnostic.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/diagnostic.ex:34). |
| `lib/mix/tasks/crosswake.install.ex` | `lib/crosswake/install/patcher.ex` | router and host file patching with explicit markers | ✓ WIRED | Install task calls `Patcher.patch_router/2` and reports marker actions at [lib/mix/tasks/crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:41). |
| `lib/mix/tasks/crosswake.install.ex` | `lib/crosswake/install/manifest.ex` | machine-readable scaffold state persisted for later tooling | ✓ WIRED | Install task calls `Manifest.write/2` and stores marker metadata at [lib/mix/tasks/crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:47). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/crosswake/policy/router_metadata.ex` | `compiled` | Router-local `crosswake` metadata normalized through `Route.new!/1` | Yes | ✓ FLOWING |
| `lib/crosswake/policy/compiler.ex` | `compiled_routes` / `errors` / `warnings` | Real Phoenix route metadata or explicit route maps passed to `compile/2` | Yes | ✓ FLOWING |
| `lib/mix/tasks/crosswake.install.ex` | install manifest attributes | Real target paths, router patch results, and version data | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 1 source compiles cleanly | `mix compile` | `Generated crosswake app` | ✓ PASS |
| Phase 1 policy, router, compiler, and DX tests pass | `mix test test/crosswake/policy/schema_test.exs test/crosswake/policy/route_test.exs test/crosswake/router_test.exs test/crosswake/router_defaults_test.exs test/crosswake/policy/compiler_test.exs test/crosswake/policy/compile_error_test.exs test/crosswake/policy/warning_test.exs test/mix/tasks/crosswake_install_test.exs test/mix/tasks/crosswake_gen_shell_test.exs` | `22 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `ROUTE-01` | `01-01`, `01-02`, `01-03` | Phoenix developers can declare runtime ownership per route as LiveView, offline island, native screen, or adapter. | ✓ SATISFIED | Public Phase 1 taxonomy is implemented as `:live_view`, `:offline_island`, and `:native_screen`, with `adapter` explicitly reserved per roadmap clarification at [.planning/ROADMAP.md](/Users/jon/projects/crosswake/.planning/ROADMAP.md:32). Schema, router DSL, metadata, and tests cover the implemented contract at [lib/crosswake/policy/schema.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/schema.ex:6), [lib/crosswake/router.ex](/Users/jon/projects/crosswake/lib/crosswake/router.ex:38), and [test/crosswake/router_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_test.exs:26). |
| `ROUTE-02` | `01-01`, `01-02`, `01-03` | Phoenix developers can declare per-route offline policy, including unavailable, cached read-only, and local-first modes. | ✓ SATISFIED | Offline enums are defined at [lib/crosswake/policy/schema.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/schema.ex:7); defaults and nested scope behavior are verified at [test/crosswake/router_defaults_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_defaults_test.exs:9). |
| `ROUTE-03` | `01-01`, `01-02`, `01-03` | Phoenix developers can declare required capabilities, pack dependencies, sync resources, and security sensitivity per route. | ✓ SATISFIED | Schema supports these keys at [lib/crosswake/policy/schema.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/schema.ex:26). Router fixtures and tests prove declaration and normalization at [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex:69) and [test/crosswake/router_defaults_test.exs](/Users/jon/projects/crosswake/test/crosswake/router_defaults_test.exs:12). |
| `ROUTE-04` | `01-03` | Crosswake rejects invalid or internally inconsistent route policy declarations at compile time with actionable error messages. | ✓ SATISFIED | Compiler, validator, and diagnostic layers enforce this at [lib/crosswake/policy/compiler.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/compiler.ex:17), [lib/crosswake/policy/validator.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/validator.ex:49), and [lib/crosswake/policy/diagnostic.ex](/Users/jon/projects/crosswake/lib/crosswake/policy/diagnostic.ex:34). Negative-path tests pass at [test/crosswake/policy/compiler_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compiler_test.exs:22) and [test/crosswake/policy/compile_error_test.exs](/Users/jon/projects/crosswake/test/crosswake/policy/compile_error_test.exs:32). |
| `DX-01` | `01-04` | Crosswake provides generators or installers for host Phoenix setup and native shell bootstrap with clear ownership boundaries. | ✓ SATISFIED | Install and shell tasks exist and are tested at [lib/mix/tasks/crosswake.install.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.install.ex:19), [lib/mix/tasks/crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:15), [test/mix/tasks/crosswake_install_test.exs](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_install_test.exs:32), and [test/mix/tasks/crosswake_gen_shell_test.exs](/Users/jon/projects/crosswake/test/mix/tasks/crosswake_gen_shell_test.exs:8). Docs make boundaries explicit at [guides/install.md](/Users/jon/projects/crosswake/guides/install.md:1). |

All requirement IDs declared in Phase 1 plan frontmatter are accounted for in `.planning/REQUIREMENTS.md`, and no additional Phase 1 requirement IDs are orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/mix/tasks/crosswake.gen.shell.ex` | 104 | Placeholder shell source text | ℹ️ Info | Intentional and documented: Phase 1 only promises shell scaffolds, not runtime boot. |
| `priv/templates/crosswake/shell/ios/README.md.eex` | 17 | Placeholder source called out in docs | ℹ️ Info | Honest boundary documentation, not a hidden stub. |
| `priv/templates/crosswake/shell/android/README.md.eex` | 17 | Placeholder source called out in docs | ℹ️ Info | Honest boundary documentation, not a hidden stub. |

### Gaps Summary

No goal-blocking gaps found. Phase 1 delivers a typed route-policy contract, router-local authoring, compile-time validation with actionable diagnostics, and additive installer/generator tooling with explicit ownership boundaries. The only placeholder code is inside the intentionally narrow native shell scaffolds, and those limits are stated explicitly in the generated docs and install guide.

---

_Verified: 2026-05-13T22:09:52Z_
_Verifier: Claude (gsd-verifier)_
