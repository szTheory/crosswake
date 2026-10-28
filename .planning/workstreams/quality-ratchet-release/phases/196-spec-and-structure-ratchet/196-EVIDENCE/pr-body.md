## What this changes

Phase 196 of v28.0 (Truth and Release Train) hardens the offline, policy and bridge specs that the first adopter and later parity work consume, so they can no longer pass by asserting nothing, and adds ratchets that fail when module structure regresses. It covers SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03 and the accepted GR-06 grammar debt carried from Phase 195.

The branch contains a few genuine library behavior fixes, so the title is a `fix` and each commit carries its own conventional type for release-please.

## Behavior and limits

**SPEC-01, vectors and evidence cannot be vacuous.** The evidence-manifest and Threadline clean-room tests fail when generated evidence is requested but absent, instead of passing empty. Elixir, Swift and Kotlin vector-consuming tests assert the loaded vector count equals a pinned expectation and fail when a vector file is removed. Limit: the optional manifest and Threadline lanes stay visible optional skips unless explicitly enabled, and a skip is never credited as proof.

**SPEC-02, delta-only absence guard.** `script/check_absence_is_not_success.exs` analyzes collection assertions with an AST pass and fails on a new collection assertion without a non-empty check, a `for` over a glob without a cardinality check, and a literal `assert true`, each with a negative control. The default mode is now enforce, recaptured on actual main before any caller used it, with a delta of 0 on the repository. Known sites are fixed or recorded with cited overrides, and the Phase 170 ledger was regenerated rather than retired.

**SPEC-03, boundary specs.** `Journal.scope_ref!/1` is specified at 15, 16, 128 and 129 characters, with newline injection rejected and the input never echoed. `SafeObservation.new/1` is specified at measurement 0, 1_000_000 and 1_000_001, with adversarial strings in every field never surviving. Two real fixes came out of this: `SafeObservation` and `Offline.Runtime.activate/2` now anchor with `\A...\z`, so a trailing line end is rejected. Other `^...$` identifier patterns outside the offline boundary are recorded as a deferred item, not widened here.

**SPEC-05, finite policy product.** The route-policy option product is enumerated exhaustively against a hand-written verdict table. Compiler error assertions pin `{key, route_id}` pairs, `Compiler.validation_key/1` never returns `nil` for a compiler error, and structured diagnostics keep their route attribution.

**ARCH-01, compile cycle.** The `bridge/contract`, `bridge/denial`, `manifest/types` and `shell/denial` cycle is broken (the wire version now has a single owner module). A test fails on any compile-label xref cycle and on an all-cycles count above the committed baseline.

**ARCH-02, bare rescue.** The three bare `rescue _ ->` clauses in `bridge.ex` now return explicit location-diagnostic outcomes. An AST test fails on a bare rescue in the `bridge`, `policy`, `router`, `offline`, `manifest` and `compatibility` modules; two reviewed exceptions are recorded with their reasons and fail closed.

**ARCH-03, runtime dependencies.** A test compares each package's runtime direct deps, evaluated in isolated Mix contexts, to a committed list with a one-line justification each. Adding a dependency requires editing that list.

**Shallow checkouts.** The rescue and dependency ratchet tests re-read their subjects at the actual-main commit their receipts pin. They now do so through `Crosswake.Test.GitObjectAt.read!/3`, which fetches only that one commit when a CI checkout lacks it and raises, never skips, if it is still unreadable. Five controls cover the present, shallow-fetched, unfetchable, missing-path and malformed-pin cases.

**GR-06, workflow grammar.** The existing `test/js/ci_secret_masking.test.mjs` grammar census now executes bounded grammar families and keeps denied statements conserved, with a real-tree census. No second analyzer was added.

## Validation

A 40-child candidate run on local head `d76d1507` (which contains main at `4ebe37fe`) produced a pass verdict: core suite 2920 tests, 0 failures; Swift package suite 89 tests, 0 failures; Android JVM package suite 12 tests, 0 failures; node suite 344 tests, 0 failures; the enabled manifest lane ran 11 tests and the enabled Threadline lane 5 tests with none excluded. An internal review ran three iterations plus a delta amendment with no open high or critical finding. Two earlier runs on the same bytes each failed one child (the example host stage, then the core suite) and both children passed when re-run alone; their records are retained in the phase evidence and the cause was not observed.

Native proof is JVM-hermetic and Swift-package only. No emulator, device or feature-breadth claim is made.

Crosswake CI is reported on this PR's head commit. GitHub also tests a synthetic merge commit, which is reported separately and is not head proof.

## Scope kept out

No Muex dependency is added, and the mutation tool stays outside recurring CI. Prior planning history and the two preserved Phase 195 receipts are retained. No release, publish or tag is part of this PR; Phase 199 owns the release.

## SPEC-04 disposition

SPEC-04 (Muex pilot) moved intact to v29.0 by recorded roadmap change; both attempts and the 5/5 accepted controls are preserved, and no adopt/drop verdict was made.

🤖 Generated with [Claude Code](https://claude.com/claude-code)