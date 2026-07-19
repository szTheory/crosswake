# v20.0 Native Controls Pack 1 — Release Strategy

**Lens:** Packaging / release-engineering / SRE
**Researched:** 2026-07-12
**Confidence:** HIGH (release-graph mechanics, SEED verdicts) / MEDIUM (D1 product-shape call, which is a product decision this lens informs but does not own alone)

## 0. Facts on the ground (read before the recommendations)

These are load-bearing and change the recommendation from what the handoff assumed:

1. **The iOS SwiftPM mirror is STILL stale at `v0.1.2` today.** `gh api repos/szTheory/crosswake-shell-core-ios/tags` returns only `v0.1.2`. Core/Android are at `0.2.0` (`.release-please-manifest.json`). v18.0 (MIRR-01/02/03, Phase 145) shipped the **guardrails** — fail-fast preflight in `release-please.yml`, a decoupled native-proof DAG, and a verify-first backfill script (`script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0 [--apply]`) — but the **actual backfill push to the live mirror repo was never executed**, and `MIRROR_PUSH_TOKEN` was last set 2026-06-17, the same window as the original 403. There is no evidence it was rotated. **Treat SEED-003 as functionally OPEN, not closed by v18.**
2. **The vector-driven, simulator-free native proof lane already exists and is live today**, exactly as the prompt hoped: `test/fixtures/bridge_contract_vectors.json` (canonical, Elixir-generated) is consumed by `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift` (XCTest) and `packages/crosswake-shell-core-android/src/test/java/.../BridgeConformanceTest.kt` (JUnit), wired into `.github/workflows/native-behavioral-proof-gate.yml`. Composition already: `android-package-unit` (JVM, **merge-blocking**), `ios-package-unit` (Swift, **advisory** — macOS/Xcode toolchain instability, matches the v15 COLL-01 precedent), rolled up by an `alls-green` aggregator that is the **sole required check**. This is the pattern to extend, not invent.
3. **`bridge_contract_vectors.json`'s `commands` array already lists `share.invoke` and `notifications.token.get`** even though `guides/native_shell.md`'s "Bridge Boundary" section only documents 8 of the 10 declared commands. Share and notification-token-read are further along the contract than the docs currently admit — Pack 1 is not starting from zero on `share`.
4. **v18.0 (Phase 142) already built the exact-path-gating and per-component release graph** this milestone depends on (`RELG-01..03`, `paths_released` gating, independent companion versioning, `release-as` staleness auto-cleanup). v20 inherits a release pipeline that is materially safer than the one that caused the v17 sigra core-first-publish failure — but the ordering discipline itself must still be re-asserted per-milestone; the pipeline enforces gates, it does not enforce sequencing decisions made in a phase plan.
5. Support-truth vocabulary already distinguishes `Available today` / `Proof-backed example` / `Demo pressure` / `Advisory evidence` / `Future gap` / `Next-pack candidate` (152-V20-HANDOFF.md) and rebuild classes (`docs-only` / `core-only/no native rebuild` / `compatibility-bump only` / `native or companion rebuild required`, `guides/compatibility.md`). Both vocabularies already have room for "shipped web-rendered, native chrome deferred" without inventing new language.

---

## 1. D1 — Where does Pack 1 live?

### Tradeoff table

| Option | Ships in v20 | Adopter action | Support-truth honesty | Risk |
|---|---|---|---|---|
| (a) Core-only bounded-bridge hardening (declarations, contract, fallback, support truth; no native change) | Elixir-side only | None — no rebuild, no native release | Honest but incomplete: "native controls pack" that never touches native code for its whole first release reads as thin | Low technical risk; product-credibility risk if marketed as "native" |
| (b) Native shell increment (iOS+Android implement the commands) | Native + core | Mandatory native rebuild for every adopter who wants Pack 1 | Honest, but forces a rebuild-class release just to prove UI chrome that could ship value without one | Reintroduces every native-release risk (SEED-003, simulator gaps, mirror parity) on day one, for controls (alert/menu/toast) that don't strictly need it |
| **(c) Split — core declarations + web-rendered (LiveView) fallback ship first and independently; native chrome ships later as an explicit rebuild-class increment** | Core only in v20; native later | None for v20; optional rebuild for a later, separately labeled release | **Most honest of the three** — it matches Crosswake's own fail-closed/no-silent-fallback doctrine as long as the web-rendered path is documented as *the* v20 implementation, not a degraded stand-in for a native one that doesn't exist yet | Requires discipline in labeling so it doesn't read as bait-and-switch |

### Recommendation: **(c), split — with a control-by-control split, not a milestone-wide one**

This is not one binary choice across all of Pack 1 — the five candidates split naturally by whether a web-rendered implementation is honestly the *same capability* or a *lesser* one:

- **Alert/confirm, menu/action-button, toast/review-prompt** — these are UI chrome. A LiveView-rendered confirm dialog, action sheet, or toast is not a compromise stand-in for a native one; it is a complete, correct implementation of "show this affordance to the user, bounded to a route." Ship these under **core-only/no native rebuild** in v20. Native chrome (real `UIAlertController`/`UIMenu`/Android `AlertDialog`/Play In-App Review) is a legitimate *later* upgrade for adopters who want native look-and-feel, released and labeled independently.
- **Haptics** — already native, already shipped (`haptics.impact` is live in the bridge contract and proven in the AdminPilot showcase). No web equivalent exists or should be pretended to exist. Nothing to decide here for v20; it's a "harden what's already native," not a new native increment.
- **Share** — `share.invoke` is already declared in the contract vectors. `navigator.share()` gives a real, if narrower, web equivalent inside a WebView on current iOS/Android — so the same split applies: ship the web-capable path first, native `UIActivityViewController`/Android `Intent.ACTION_SEND` as a later strict upgrade.
- **`permissions.status` / `notification_token`** — already scoped by the handoff as read-only/evidence surfaces. No native increment implied; keep them exactly where the handoff put them.

**Net effect: v20 can ship all five Pack 1 affordances' *declarations and working implementations* with ZERO native shell change, ZERO SwiftPM/Maven rebuild, and ZERO adopter action.** That is not a lesser v20 — it is the correct sequencing of "prove the contract and ship value" before "commit to a native binary bump," and it defers every SEED-003-class release risk to a milestone that actually needs it.

**Is this bait-and-switch?** Only if mislabeled. It is not, provided:
- The capability map and support matrix state plainly: *"web-rendered (LiveView); native chrome not yet built"* — using the existing `Available today` / `Future gap` vocabulary, never a bare "supported" claim.
- The web-rendered path is not called a "fallback" in the sense of "degraded" — it is the *primary and only* v20 implementation, and it is bounded, fail-closed, and non-silent (consistent with `guides/native_shell.md`'s "no silent fallback" doctrine — the rule that doctrine protects is *don't silently degrade an existing native capability*, not *never ship web-first*).
- A later "native chrome" release is pre-named as its own increment (see §5) so nobody can claim v20 "was supposed to be native and wasn't."

This is the direct, product-informing answer this lens can give; the final product call belongs to the roadmap/product lens, but from a release-engineering standpoint, (c) split-by-control is the only option that lets v20 ship without inheriting SEED-003 and the native proof-lane fragility on day one.

---

## 2. D5 — Proof lane composition for v20

Given the D1 recommendation, v20's *default* path touches no native code, so the primary proof lane is the browser/LiveView route-tour path, not a new native lane. But the plan should pre-build the native lane now, dormant, so the later native-chrome increment doesn't start from zero. Recommended composition, named explicitly (no vacuous lanes — every lane below states what makes it FAIL):

| Lane | Blocking? | What it asserts | How it fails |
|---|---|---|---|
| `contract-drift-gate` (existing, extended) | **Merge-blocking** | The 5 new Pack 1 commands (or however many are added) are declared once in `bridge_contract_vectors.json` (generated via `mix crosswake.contract.gen`) and every generated artifact (docs snippet, route_activation.json, native fixture copies) is in sync with it | Fails if any declared command/denial-reason is added to the Elixir source but the generated JSON/docs are stale — this is the existing drift gate, just carries more vectors |
| `merge-blocking-native-behavioral-proof` → `android-package-unit` (existing) | **Merge-blocking** | New vectors for alert/confirm, menu, toast, review-prompt, share compile and pass against the Android JVM harness (`BridgeConformanceTest.kt`) even before real native chrome exists — because in v20 the "native" implementation IS the declare/deny/fallback contract, and that contract is provable hermetically today | Fails if a new vector's expected outcome/denial reason doesn't match what the JVM harness computes from the shared contract — proves the *contract*, not native UI, which is exactly right for v20's scope |
| `ios-package-unit` (existing) | **Advisory** (unchanged — do not flip this to blocking for v20; the Xcode-toolchain instability that made COLL-01 advisory in v15 has not been resolved and nothing in v20 changes that) | Same vectors against Swift (`BridgeConformanceTests.swift`) | Fails/flakes on the same known macOS/Xcode toolchain issues; kept advisory so it cannot deadlock PRs |
| **`browser-fallback-proof-pack1`** (NEW, modeled on `offline-sync-e2e-gate.yml`'s route-tour pattern) | **Merge-blocking** | For each Pack 1 control shipped as web-rendered (alert/confirm, menu, toast, review-prompt, share-via-`navigator.share`): a route-tour LiveView test drives the route, asserts the affordance renders, asserts route-ownership/fallback copy when the capability is undeclared, and asserts NO silent degradation | Fails if the LiveView-rendered control doesn't appear, doesn't fail closed when undeclared, or the support-matrix generator disagrees with what actually rendered |
| Generated-shell hermetic proofs (`script/verify_generated_ios_shell.sh`, `script/verify_generated_android_shell.sh`, `android-generated-shell-unit`) | **Merge-blocking** (existing, unchanged) | Generated host projects still compile/link against the (unchanged in v20) native runtime — proves v20 did NOT accidentally bump `native_runtime_version` | Fails if a Pack 1 change leaks into a generated template file, which would silently reclassify this as a native-rebuild release when it wasn't supposed to be one |
| `clean-room-proof-*` (existing per-companion, advisory) | **Advisory, unchanged** | Unrelated to Pack 1 unless a companion package changes | n/a for v20 unless scope grows |
| Native simulator/emulator capture (COLL-01-class) | **Do not add in v20.** | n/a | Explicitly OUT — the v15 hang/toolchain-wall reasons are unchanged; only revisit when the *native chrome* increment (§5, later milestone) actually needs simulator-level visual proof, and even then keep it advisory per the established hermetic-vs-advisory split |

**Rationale for the one new lane:** `browser-fallback-proof-pack1` is the honest analog of the existing native-behavioral-proof-gate, but for the code path v20 actually ships. It is what makes D1's "web-rendered is the real v20 implementation, not a stand-in" claim provable in CI rather than asserted in prose — mirroring the project's own rule that proof lanes, not documentation, carry support claims.

---

## 3. SEED-003 — iOS mirror push token

**Verdict: INCLUDE, and land it FIRST — before Phase 1 of v20, not folded into a later native-chrome phase.**

Reasoning:
- SEED-003 is not resolved by v18. The guardrail code exists; the live mirror is still stuck at `v0.1.2`. If v20 (or any *later* milestone that adds real native chrome per the D1 split) needs to cut a native release, that release **cannot reach iOS adopters** until `crosswake-shell-core-ios` has a `v0.2.0`+ tag — SwiftPM literally cannot resolve past what's tagged on the mirror.
- Because D1 recommends v20 itself ship with **zero native shell change**, SEED-003 does not block *this* milestone's release mechanically. But it is cheap, small, already-tooled, and it is a landmine for whichever milestone ships the native-chrome increment next. Fixing it now — while nothing depends on it — is strictly lower risk than fixing it under the pressure of a native release that's already cut and blocked.
- The root cause is almost certainly not a design problem: `github-actions[bot]`'s default `GITHUB_TOKEN` fundamentally cannot write to a second repository — that's a GitHub platform boundary, not a Crosswake bug. Real-world splitsh/monorepo-split precedent (`danharrin/monorepo-split-github-action`, the `splitsh-lite` action itself) confirms the standard fix is exactly what SEED-003 already prescribes: a **fine-grained PAT scoped to `Contents: read/write` on the single target repo**, stored as a secret, used in place of `GITHUB_TOKEN` for the cross-repo push. There is no deeper architectural alternative worth adopting here (a GitHub App installation token is marginally more rotate-able/auditable than a PAT but is materially more setup for a single-target-repo mirror — not worth it for one repo).
- Scope to include in v20, landed early (Phase 0/1, before any Pack 1 code):
  1. Rotate/verify `MIRROR_PUSH_TOKEN` as a fine-grained PAT with `Contents: read and write` on `szTheory/crosswake-shell-core-ios` only, confirm `git ls-remote` succeeds (the existing preflight in `release-please.yml`'s mirror job already checks this — use it to validate the new token before relying on it).
  2. Run `script/verify_ios_mirror_backfill.sh --version 0.2.0 --ref refs/tags/ios-core-v0.2.0 --apply` to actually push the missing `v0.2.0` tag to the mirror (the script already does the right verification: release-ref cross-check, manifest lockstep check, live Hex/Maven checks, before touching the public tag).
  3. Confirm `mix crosswake.release.status --live` (or the native-release-rollup artifact) reports iOS mirror state as current, not stale.
  4. **Do not** treat this as touching Pack 1 product code — it's pure release-infra, and it should land and merge independently of the Pack 1 feature phases so it isn't accidentally gated behind product review.

---

## 4. SEED-004 — clean-room proof harness

**Verdict: DEFER.**

Reasoning:
- v18.0 (Phase 144, PREF-01/02/03) already did the substantive fix: exact-version companion pin, derived core floor from real Hex metadata, lockfile postcondition assertions, and — critically — the doctor-router-loadability bug (Bug #3 in SEED-004, the actual open item) was fixed by making `mix crosswake.doctor --router` force-compile/reload before failing (`lib/mix/tasks/crosswake.doctor.ex`'s `compile_and_reload_router?/1`). That is exactly the fix SEED-004 asked for.
- The remaining SEED-004 line items (cosmetic quoted-atom warning, "consider promoting these proofs to required") are polish, not defects, and are unrelated to any surface Pack 1 touches: `verify_companion_cleanroom.sh` only runs for `crosswake_rulestead/rindle/sigra/chimeway/threadline` companion Hex publishes. **v20 (under the D1 split) publishes no companion, no core version bump with new native surface, and no native shell change** — so nothing in v20's release path exercises this harness at all.
- Carrying a cosmetic-only, non-blocking, unrelated-surface seed into a milestone is fine; forcing it into scope would be scope creep against the "v20 is a controls pack, not a release-ops pass" boundary the roadmap should hold (mirroring how v18 itself explicitly deferred DASH-01/SYNCP-01/NTV-01/SEED-002 as out-of-scope-for-integrity-milestone).

---

## 5. Release choreography for v20

Modeled on the v17 lesson (companions published against unpublished core → sigra publish failed at compile because the dress-rehearsal used a `path:` dependency and never caught the missing Hex floor). The core-first-ordering bug class was: *dependents were built/tested against a coordinate that wasn't live yet, and nothing in the dress-rehearsal used the real published coordinate.* v20 must not repeat this class, even though (under D1) it never touches native.

**Choreography, in order:**

1. **Phase 0 — SEED-003 backfill (release-infra only, no product code).** Land, verify iOS mirror is current at `v0.2.0`+. This is a merge to `main` through the existing release-please pipeline with **no version bump** (it's a mirror backfill, not a new release) — verified via `--apply` running once, out of band, by the maintainer, exactly as `script/verify_ios_mirror_backfill.sh` is designed to be run. Gate: `mix crosswake.release.status --live` shows iOS mirror == Android/core version before Phase 1 starts.
2. **Phase 1..N — Pack 1 feature phases (core-only, per D1).** Each phase: extend `bridge_contract_vectors.json` + regenerate via `mix crosswake.contract.gen`, implement the LiveView-rendered control + route-policy declaration, extend `browser-fallback-proof-pack1`, extend the (already-passing) Android/iOS behavioral-proof vectors for the new commands (these pass against the *contract*, not native chrome — see §2). No `native_runtime_version` bump. No `.release-please-manifest.json` touch to the iOS/Android package paths.
3. **Release cut.** Because this is `core-only/no native rebuild` (per `guides/compatibility.md`'s own table), release-please cuts a normal `crosswake` (root/Hex) version bump. `paths_released` will **not** contain `packages/crosswake-shell-core-ios` or `packages/crosswake-shell-core-android` — so `publish-ios-core`, `publish-android-core`, and both `clean-room-proof-ios/android` jobs correctly no-op (existing exact-path gating from Phase 142/RELG-01 already guarantees this; nothing new to build). This is the "core-first" ordering lesson already structurally enforced — v20 doesn't create a new dependent-package publish, so there's no "companion depends on unpublished core" class of bug to reproduce.
4. **Docs truth update (same PR or immediate follow-up).** `guides/compatibility.md` and `guides/native_shell.md`'s "Bridge Boundary" list gain the new commands with explicit `Available today (web-rendered)` labels; `guides/native_shell_upgrade.md` is NOT touched (no template version bump — no native template changed).
5. **Irreversible/one-way points to flag in the phase plan:** (a) the SEED-003 mirror tag push is irreversible/public once done — do it once, verified, in Phase 0, not repeatedly; (b) once Pack 1 commands are documented as `Available today (web-rendered)`, downgrading them later to `Future gap` would be a support-truth regression — treat the "ship web-first" label as a one-way door once adopters start depending on it.
6. **Deferred, named-but-not-scheduled: "Native Controls Pack 1 — Native Chrome" increment.** This is the *actual* native-rebuild-required release (real `UIAlertController`/`UIMenu`/native toast/native share sheet). When it's scoped: reuse the exact-path release graph (no changes needed), reuse `merge-blocking-native-behavioral-proof` (the vectors already exist from v20), and treat it as a normal `native or companion rebuild required` bump per the existing rebuild-class doctrine — with its own `native_shell_upgrade.md` entry and `RebuildPolicy.classify/2` verdict, exactly like Template Version 2's pattern.

---

## 6. Rebuild-class labeling and adopter communication for a native-controls release

Crosswake already has the right shape of mechanism (`RebuildPolicy.classify/2`, `guides/native_shell_upgrade.md`'s per-template-version changelog, `guides/compatibility.md`'s change-class table) — the only gap is that it's not yet been exercised for a *product feature* release, only for scaffolding/template churn. Recommendations:

- **v20 itself needs NO new rebuild-class messaging** beyond what already exists: it is `core-only/no native rebuild`, so the existing "Do I need to rebuild?" table already covers it truthfully (`update the Hex package and rerun core contract + doctor/support proof without rebuilding native shells`).
- **For the later native-chrome increment**, adopt the Expo "runtime version" lesson directly: Expo's `fingerprint` policy auto-derives whether a change touches the native runtime rather than trusting a manual flag, specifically because manual `appVersion`-only bumping causes silent runtime-version drift when someone forgets to bump on a native change. Crosswake's `native_runtime_version` axis is already the equivalent concept — the actionable improvement is to make `RebuildPolicy.classify/2` (or a CI check) **detect** native-template/runtime-affecting diffs automatically and fail closed if a change touches native code without also bumping `native_runtime_version`, rather than relying on the phase author to self-classify correctly. Consider this a candidate for a small v20-adjacent hardening task, not a blocker.
- **Labeling convention for the native-chrome release itself:** follow the existing `guides/native_shell_upgrade.md` per-template-version entry format — lead with the `RebuildPolicy.classify/2` verdict and named change-class atom, list exactly which generated files changed, and give the one-line "should you rebuild?" verdict before any prose. Do not invent new adopter-facing terminology; reuse `native or companion rebuild required` verbatim so it round-trips with `guides/compatibility.md`'s table.
- **Changelog/release-notes framing (from the Expo/Capacitor precedent):** state explicitly, in the release notes for the native-chrome bump, which *already-shipped* v20 commands are simply gaining native chrome (i.e., "no new capability, no new route-policy shape — the affordance you already use now renders with native chrome; declarations and route policy are unchanged") — this is what prevents the earlier web-first release from reading as a bait-and-switch: the release notes for the native follow-up should point back at the original web-rendered ship date and describe the native bump as *cosmetic-tier upgrade*, not "now it actually works."

---

## Sources

- `.github/workflows/release-please.yml` (publish/mirror/clean-room job graph, exact-path gating)
- `.github/workflows/native-behavioral-proof-gate.yml` (existing merge-blocking/advisory native lane split)
- `script/verify_companion_cleanroom.sh`, `script/verify_ios_mirror_backfill.sh`, `script/register_required_checks.sh`
- `.planning/seeds/SEED-003-ios-mirror-push-token.md`, `SEED-004-cleanroom-proof-harness.md` (read in full)
- `guides/compatibility.md`, `guides/native_shell.md`, `guides/native_shell_upgrade.md`, `guides/install.md`
- `.planning/milestones/v18.0-ROADMAP.md`, `v18.0-REQUIREMENTS.md` (what release integrity work already shipped)
- `lib/mix/tasks/crosswake.doctor.ex`, `crosswake.release.status.ex`
- `prompts/crosswake-elixir-oss-dna.md`
- `test/fixtures/bridge_contract_vectors.json`, iOS `BridgeConformanceTests.swift`, Android `BridgeConformanceTest.kt`
- `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md`
- Live checks: `gh api repos/szTheory/crosswake-shell-core-ios/tags` (confirms mirror stuck at v0.1.2), `gh secret list` (confirms `MIRROR_PUSH_TOKEN` unrotated since 2026-06-17), `.release-please-manifest.json` (confirms core/Android at 0.2.0)
- [Splitsh Lite Action — GitHub Marketplace](https://github.com/marketplace/actions/splitsh-lite-action)
- [danharrin/monorepo-split-github-action](https://github.com/danharrin/monorepo-split-github-action)
- [Fine-grained Personal Access Token permissions discussion](https://github.com/orgs/community/discussions/133558)
- [Expo runtime versions and updates](https://docs.expo.dev/eas-update/runtime-versions/)
