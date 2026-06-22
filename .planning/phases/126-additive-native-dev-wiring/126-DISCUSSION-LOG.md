# Phase 126: Additive Native Dev Wiring - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-22
**Phase:** 126-additive-native-dev-wiring
**Areas discussed:** iOS Dev variant mechanism, Android dev flavor mechanism, Dev fixture source & generation, Proof-posture guard + CLI docs

---

The file structure was pre-locked by the v15.0 roadmap decisions (iOS `Dev` scheme +
`Info-Dev.plist` + dev fixture; Android `dev` flavor + `network_security_config_dev.xml` +
`src/dev/assets/*` + non-autoVerify intent-filter). Discussion focused entirely on the
**mechanism** for each, all coupled to the "never mutate the proof fixtures" invariant.

The maintainer selected all four areas and requested the research-then-recommend pattern:
parallel subagents weighing pros/cons/tradeoffs, ecosystem idiom, cross-framework lessons,
and DX, synthesized into one coherent recommendation set. Four Sonnet research subagents ran
in parallel; their reports were reconciled (conflicts noted below) into D-01..D-16 in CONTEXT.md.

## iOS Dev variant mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| `Debug-Dev` build configuration + `Dev` scheme (single target) | xcconfig/config override of INFOPLIST_FILE; Run Script copies dev fixture for Debug-Dev only | ✓ |
| Second app target (`CrosswakeShellDev`) | Fully isolated target, distinct bundle id | |
| `#if DEBUG` Swift conditional | Switch URL/fixture in code | |
| Runtime env var / launch argument | Read server URL at runtime | |

**User's choice:** Research-backed recommendation accepted (single target + `Debug-Dev` config + `Dev` scheme).
**Notes:** Second target rejected (doubles pbxproj, dual target membership maintenance). `#if DEBUG` structurally impossible — ATS / WKAppBoundDomains are plist keys, fixture is a bundle resource. Core loads a hardcoded `route_activation.json`, so a Debug-Dev-guarded Run Script copy phase is used (no library API change). Scheme named `Dev` to match ROADMAP success criterion.

## Android dev flavor mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| `prod` + `dev` product flavors + `src/dev/` overlay | flavor source set overrides asset; manifest overlay via `tools:replace`; applicationIdSuffix `.dev` | ✓ |
| `debug` build type only (`src/debug/`) | Cleartext/fixture in shared debug build | |
| `buildConfigField` URL constant | Switch URL in Kotlin | |
| `manifestPlaceholders` for networkSecurityConfig | Pass config as a placeholder | |

**User's choice:** Research-backed recommendation accepted (two-flavor `prod`/`dev` overlay).
**Notes:** CONFLICT RESOLVED — one researcher proposed a `main` flavor; rejected because `main` is a reserved source-set name. `debug`-build-type approach rejected (cleartext + dev fixture would leak into the proof debug build; can't coexist). Key blast radius flagged: declaring flavors renames all existing variants — CI/proof Gradle + adb invocations must migrate to `prod*` names (D-10).

## Dev fixture source & generation

| Option | Description | Selected |
|--------|-------------|----------|
| Generated via `mix crosswake.contract.gen --dev` | Single source of truth; idempotent; committed; tagged `--dev` | ✓ |
| Hand-authored sibling files | Zero generator change | |
| Config-profile (`config_env()`) | Env-aware generation | |
| Separate `crosswake.contract.gen.dev` task | New task | |
| Post-generation `sed` patch script | Patch prod fixture URL | |

**User's choice:** Research-backed recommendation accepted (generated, `--dev` flag).
**Notes:** Hand-authoring rejected — silently rots when the contract bumps. Generation keeps `bridge_protocol_version` single-sourced from `Crosswake.Bridge.Contract.version()`; only url/origin/correlation_id diverge. Dev fixtures committed and tagged `"_generated_by": "mix crosswake.contract.gen --dev"`. Default no-flag run must not touch them; drift test gets a separate `@dev_generated_json_paths` list.

## Proof-posture guard + CLI docs

| Option | Description | Selected |
|--------|-------------|----------|
| New `native_dev_wiring_test.exs` in guides dir + section in QUICK_START.md | Source-derived posture guard + minimal copy-paste commands | ✓ |
| Put guard in contract/ or proof/ dir | Different test categorization | |
| New `guides/native_dev.md` doc | Standalone guide | |
| Commands in host READMEs | Near the code | |
| Byte-level file equality guard | Hash/compare prod fixtures | |

**User's choice:** Research-backed recommendation accepted (guides-dir guard + QUICK_START section).
**Notes:** Guard is source-derived (port from runtime.exs), JSON key-lookup not text-grep, with synthetic anti-vacuity regression cases. Closes a gap: the existing QUICK_START port scanner only matches `localhost:` prefix, missing `10.0.2.2:4700`. Docs go in QUICK_START.md, NOT a new guides file (Phase 128 owns `guides/see_it_run.md`) and NOT the minimal host READMEs. Honest `advisory native` labeling; brand voice; caveats next to triggering commands.

## Claude's Discretion

- Exact pbxproj UUIDs / insertion points; `Configs/Dev.xcconfig` vs inline `INFOPLIST_FILE`.
- Simulator model named in docs.
- Whether `--dev` later accepts `--backend-url` (deferred; hardcode 4700/localhost/10.0.2.2 now).
- Inline `JAVA_HOME=openjdk@17` guidance in the Android command (recommended per project memory).

## Deferred Ideas

- `bin/see-it-run.sh` / banner → Phase 127.
- `guides/see_it_run.md` + screenshots + screen recording + README routing + `see_it_run_test.exs` → Phase 128.
- `--dev --backend-url` parametrization.
- Dockerizing the Android emulator — out of scope (REQUIREMENTS).
