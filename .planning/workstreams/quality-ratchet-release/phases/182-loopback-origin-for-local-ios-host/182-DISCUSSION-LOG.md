# Phase 182: Loopback Origin for Local iOS Host - Discussion Log

> **Audit trail only.** Do not use this file as input to planning, research or execution agents. CONTEXT.md holds the decisions; this log keeps the alternatives that were considered.

**Date:** 2026-10-14
**Phase:** 182-loopback-origin-for-local-ios-host
**Areas discussed:** How the mode is switched on; What the generated app carries; How tools report it; Moving Phase 180 onto it

**How it ran:** The user selected all four areas and asked for a fan-out (their two boilerplate prompts plus "copy-paste over another dependency"). Each area went to its own `gsd-advisor-researcher` subagent (opus). An orchestrator adversarial pass then checked the subagents' claims against the candidate source, and the coherent recommendation set was followed automatically, as the user instructed.

---

## How the mode is switched on

| Option | Description | Selected |
|--------|-------------|----------|
| Optional `:ios_host` key `origin_mode: :local_loopback` | Mode sits next to the origin; every reader sees it; dev config only; refused under MIX_ENV=prod | ✓ |
| Generator CLI flag | Invisible to `--check`, doctor and the proof lane; conflicts with the rule that `:ios_host` refuses CLI overrides | |
| Inferred from an http loopback origin | Not explicit; the origin string silently becomes the switch | |
| Separate `:ios_host_local` declaration | Two sources of truth; duplicated identity | |

**User's choice:** Delegated: "fan out … synthesize a coherent set of recs … auto follow those".
**Notes:** Only `http://127.0.0.1[:port]` and `http://localhost[:port]` are allowed, with no rewriting between them. IPv6, LAN and https are rejected under the mode.

## What the generated app carries

| Option | Description | Selected |
|--------|-------------|----------|
| Generation-time mode: ATS `NSAllowsLocalNetworking` only plus a `CrosswakeOriginMode` marker; production plist byte-identical; proof lane refuses | Narrowest Apple key; one frozen identity | ✓ |
| Per-configuration Debug/Release plists | One tree produces two app identities | |
| `NSAllowsLocalNetworking` in every build | Weakens production; breaks success criterion 3 | |
| `NSAllowsArbitraryLoadsInWebContent` / `NSExceptionDomains` | Not authorized; IP literals not listable | |

**User's choice:** Delegated (as above).
**Notes:** No manifest or activation schema change. `WKAppBoundDomains` is deferred. A Simulator load check is mandatory because Apple's docs are ambiguous about 127.0.0.1.

## How tools report it

| Option | Description | Selected |
|--------|-------------|----------|
| Doctor `:warning` normally, `:error` / not_ready under `--check-publish`, plus a mode line in `--check` and inspect | Reuses existing severity and profile; no new taxonomy | ✓ |
| Doctor always fails | Breaks the local loop; trains people to ignore red | |
| Advisory only | Shows a non-production setup in the tone used for success | |
| New dev-profile/banner taxonomy | Against AGENTS "no new label taxonomy" | |

**User's choice:** Delegated (as above).
**Notes:** Detection uses generated outputs, so a stale state is caught. A mismatch is an error. Messages explain that 127.0.0.1 on an iPhone is the phone itself.

## Moving Phase 180 onto it

| Option | Description | Selected |
|--------|-------------|----------|
| Separate clone, then phase180 `fetch` + `checkout --detach` | Same SHA in both; git refuses any overwrite; Phase 181 precedent | ✓ |
| Same, with `merge --ff-only` | Adds nothing on a detached HEAD | |
| Build inside the phase180 dirty tree | Mixes evidence; staging footguns | |
| Patch file plus `git am`/`git apply` | SHA drift, or a mixed dirty set | |

**User's choice:** Delegated (as above).
**Notes:** The move is checked with before/after manifests and recorded in `182-CANDIDATE-MOVE.json`. The Phase 180 gate is rerun before 180-05.

## Adversarial pass corrections

- The researcher's `GENERATE_INFOPLIST_FILE = YES` claim was wrong for the app target, which uses a real managed Info.plist.
- The "host-owned Info.plist leaves a stale exception" concern is covered: Info.plist is managed, so `--check` drift catches it.
- The proposed activation-JSON marker was dropped to avoid a wire-schema change.

## Claude's Discretion

Module placement, template branching, test layout, the Simulator harness mechanism (it must observe an actual WebView load), and message polish.

## Deferred Ideas

- WKAppBoundDomains derivation
- IPv6 / LAN / physical-device local mode
- Per-configuration plists
- The 180 route-id mismatch (`study-session` vs `offline-study`)
