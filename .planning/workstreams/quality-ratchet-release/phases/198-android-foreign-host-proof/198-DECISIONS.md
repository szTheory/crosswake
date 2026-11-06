# Phase 198 Decisions

Written record of the decisions Phase 198 takes, so Success Criterion 2 ("decided in writing") is
met by a file and not by chat. Codename rule applies: the adopter is never named here.

## JSON stack (D-09)

Production keeps the platform `org.json` (zero runtime dependency). JVM unit tests use
`com.vaadin.external.google:android-json:0.0.20131108.vaadin1` (Apache-2.0, AOSP-derived, test
scope only, absent from the published POM) instead of the Crockford `org.json:json:20231013`
build, because the Crockford build rejects inputs that the platform library coerces. A
"non-string rejected" test that passes on the stricter library could be false on a phone.

Measured coercions under the AOSP-derived library (RESEARCH C18): `getString` returns the string
`null` for JSON null, the text of a number (`5`) and the JSON text of an object. Duplicate keys:
last wins. Comments and single-quoted keys parse. Trailing text after the object is ignored.
`[]` and `""` throw `JSONException`. Map values in `capabilities` and `payload` are also
coerced (`{"n":5}` gives `"5"`); that is characterized, not changed (D-11).

Rejected options:

- `kotlinx.serialization` in production: adds a runtime dependency and a published-POM change to fix a test-only gap; the production code already works on the platform library.
- Vendoring the AOSP `org.json` source: more maintenance surface than one pinned test coordinate for no gain in fidelity.

Revisit trigger: a demonstrated parity or security defect between the test library and the
platform library (v29 or later). Claim ceiling: JVM evidence only. Nothing here was run on a
device. The dead `kotlinx-serialization-json` dependency and Kotlin serialization compiler plugin
were removed from the core build (D-10); `androidx.webkit` stays because `BridgeChannel.kt`
imports it for `addWebMessageListener` (D-02).

## Envelope hardening (D-11)

The nine required fields of `BridgeRequestEnvelope(JSONObject)` (protocol, version, command,
capability, route_id, active_route_id, origin, native_runtime_version, correlation_id) must be
JSON strings. JSON null, numbers, booleans, objects and arrays are rejected. This matches the
Swift `Codable` `String` decoding on iOS. Map values stay stringified (characterized, not
changed). A malformed or rejected envelope is dropped silently on purpose: there is no
correlation id to echo, so no reply can be addressed to the caller. `BridgeChannel.parseBody`
and `BridgeChannel.listenerAllows` were extracted unchanged in behavior so the listener boundary
is testable on the JVM without a WebView.

## SemVer (open question 1)

`SemVer.parse` now accepts only digit-only components (`^[0-9]+$`); signs, whitespace and
overflowing components fail closed (overflow and unparseable input fall back to raw equality,
which denies unless the strings are byte-equal). The subtraction in `compare` became
`compareTo`, removing an accidental `Int` overflow.

Measured before and after (RESEARCH C6):

| Call | Before | After |
|---|---|---|
| `compatible("0.0.0", "-1.0.0")` | true | false |
| `compatible("+1.0.0", "1.0.0")` | true | false |
| `compatible("99999999999.0.0", "1.0.0")` | false | false |
| `compatible("abc", "abc")` | true | true |
| `compatible("1", "1.0")` | true | true |

Cross-platform divergence, stated plainly: the iOS reference
`packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/SemVer.swift` (`parse`, about
lines 48-53) parses components with Swift `Int(_:)`, which accepts a leading `+` or `-`. After
this phase Android denies `+1.0.0` and `-1.0.0` where iOS may still accept them. No shared
vector covers version parsing and D-12 forbids adding one in this phase, so the parity ledger
cannot show this divergence. Debt row (e) carries it.

## Overrides of CONTEXT

- (I-1) D-13 says to "update or retire" the Phase 196 `tests: 12` pin in `phase-evidence.mjs` (about line 533). This phase retires it by record only and does not edit the file, because Phase 196 candidate identities hash those tools whole (RESEARCH C11) and an edit would invalidate recorded Phase 196 evidence. Debt row (d) is that record. This is an explicit, recorded departure from the literal D-13 wording, not a silent one.
- (I-2) D-09 says to fix six `keys()` call sites in `BridgeConformanceTest.kt`. There are three (`.keys().asSequence()` near lines 85, 99 and 146), each followed by an `associateWith` line, which is why six line numbers were cited (RESEARCH C5). This phase edits the three real call sites. This is a factual correction of the count, not a change of D-09's intent.
- (I-3) Branch name. The plan text says to cut `feat/198-android-foreign-host-proof` from origin/main and cherry-pick only the Phase 198 planning commits. The dispatching orchestrator had already created `test/198-android-foreign-host-proof` from current origin/main (origin/main is an ancestor) and instructed the executor not to switch branches. Plan 01 therefore ran on `test/198-android-foreign-host-proof`; no cherry-pick was needed. The branch still starts from current origin/main, which is the intent of the AGENTS rule. The branch uses the `test/` conventional prefix, so release-please reads it the same way as other test work.

## Open items for the user

Four Phase 197 closeout commits (originally d81c110a UAT, 78805a06 phase completion with ROADMAP
and STATE updates, 01eecba2 validation strategy, 31a782dd security verification) existed only on
`docs/197-public-docs-truth` and were not on main (PR 268 merged as 8d9ac9ac before they were
written). The plan assumed the Phase 198 branch would deliberately omit them. The branch the
orchestrator provided already carries their equivalents under new hashes (67241beb UAT, 0932e36c
phase completion, 6580fd94 validation strategy, f8500948 security verification), so they will
reach main with the Phase 198 PR unless the user splits them out. Whether to keep them in the
Phase 198 PR or land them as a separate docs PR (which needs the user's one-use `allow` to merge)
is the user's decision. If a separate docs PR lands first, whichever PR merges second resolves
any ROADMAP or STATE conflict by keeping both sides' facts.

## Open-question resolutions

- (2) The floor checker is a separate step in `android-package-unit` running `python3 script/check_kotlin_test_floor.py --run` (Option A; the stage argv stays pinned).
- (3) The capability map gains the 11th "Android evidence" column.
- (4) `script/android_foreign_promotion.sh` runs locally only, because artifact download needs an authenticated `gh` and CI is pull-request only.
- (5) The `@claims` token for the ledger is `vector-set hash`.

## Debt rows

| Item | Owner | Trigger | Receiver |
|---|---|---|---|
| (a) `server.event.push` and `server.state.update` skip `capabilityAvailable`, emit `invalid_payload` outside the vector `denial_reasons`, and an unknown `server.state.update` returns ok (D-14, deferred; behavior unchanged in this phase) | Android bridge maintainers | A phase that claims bridge-command breadth or promotes these commands into shared vectors | The v29 Android/bridge phase |
| (b) Dead `androidx.webkit` line in the generated app template | Android template maintainers | The next template change (needs a `template_version` bump) | The next phase that edits `priv/templates/crosswake/shell/android` |
| (c) Example host `org.json` alignment with the AOSP-derived test artifact | Android example-host maintainers | The next example-host touch | The next phase that edits the Android example host |
| (d) The Phase 196 `tests: 12` Gradle pin in `phase-evidence.mjs` and the `vector-controls.mjs` intended diagnostics are superseded phase history, left unedited because Phase 196 candidate identities hash those tools whole (D-13, C11; see Overrides of CONTEXT) | Phase-evidence maintainers | The next phase that rebuilds Phase 196 evidence tooling | That phase |
| (e) SemVer parsing diverges between Android (digit-only, signs denied) and iOS `SemVer.swift` (`Int(_:)` accepts `+` and `-`) | Bridge contract maintainers (iOS and Android shell core) | The next phase that edits either `SemVer` or adds shared vectors | The v29 Android/bridge phase (same receiver as row a), which adds a shared version-parsing vector so both platforms are held to one rule |

## Appended by later plans

- (Plan 03, D-13) The Kotlin JVM test floor is `script/check_kotlin_test_floor.py --run` (ratchet floor 25, derived XML-to-source equality, `BridgeChannelBoundaryTest` at least 10 testcases, seven load-bearing named tests, dependency-drift checks), with its fixture controls in `script/check_kotlin_test_floor_test.py`. Both run as separate steps in `android-package-unit`; the pinned `android-package-proof` stage argv is unchanged. Measured on the branch 2026-11-05: 37 XML tests, 37 source tests, 20 boundary testcases. Claim ceiling: JVM evidence only.

## D-24 measurement

Measured 2026-11-05 on the branch, before any edit to `native_evidence_drift_test.exs` or the
reworded sources. Instrument: a one-off `mix run` that applies the two new `:device_support_overclaim`
patterns line by line, with and without the scanner's `line_support_negated?` suppression.

Patterns: `\bAndroid\b.*\b(emulator|device|physical)[- ](verified|tested|proven|support)` and
`\b(emulator|device)-verified Android\b`, both case-insensitive.

Before rewording (hits without suppression / with suppression):

| Surface | Without suppression | With suppression | Hit lines (normalized) |
|---|---|---|---|
| `guides/support_matrix.md` | 2 | 0 | the `shell.android.device_verified` rule row; the non-claims bullet "Android remains available ... that posture is not device-verified" (both carry negation words) |
| `guides/capability_map.md` | 0 | 0 | none |
| `guides/parity_ledger.md` | 0 | 0 | none |
| `guides/native_shell.md` | 0 | 0 | none |
| `lib/crosswake/support_matrix/renderer.ex` (already scanned) | 1 | 0 | the non-claims bullet source (negated) |
| `lib/crosswake/support_matrix/support_matrix.ex` (already scanned) | 3 | 3 | the D-19 comment "Android device-verified promotion criteria"; the rule title "Android shell device/emulator-verified proof promotion"; the evidence text "docs-contract parity for Android device-verified runtime-line" |

The three unsuppressed hits are true hits in the source (comment, title and evidence text of the
`shell.android.device_verified` rule). They are reworded in place; no regex is loosened. The two
suppressed hits in the rendered guide and renderer stay: they are negated statements of the boundary.

After rewording and extending the scanner (same instrument, plus the full `NativeEvidenceDriftTest`
over `guides/capability_map.md` and `guides/parity_ledger.md`, which are now scanned under every
existing line rule as well as the two new ones): unsuppressed hits are 0 on all six surfaces.
The three source lines now read "Android promotion criteria for device-level proof",
"Android shell emulator and device proof promotion" and "docs-contract parity for Android
device_verified runtime-line" (the rule id `shell.android.device_verified` is unchanged). The
documentation-contracts set ran 292 of 297 tests green (284 measured before this plan's tests plus
8 ceiling tests). Known blind spot (H5): the scanner's negation suppression skips any line containing
` not `, ` never `, ` without ` and similar words, so the table test in
`android_claim_ceiling_test.exs` is the primary gate and this scanner is a backstop.

## First CI run

Recorded 2026-11-05 from PR 270. Evidence: `198-EVIDENCE/ci-198.txt`.

- **Outcome A (success).** The advisory `android-foreign-host` job concluded `success` on Linux, on run 42138656194 (PR head 01408a04, synthetic merge commit 232f9d20 whose parents are origin/main 8d9ac9ac and the PR head). The evidence artifact reports published version V = 0.2.11, 2 tests, 0 failures, `control_reason` `could_not_find`, result PASS. All 39 checks of Crosswake CI concluded success.
- **D-18 wording confirmed on CI.** On Gradle 8.7 (distribution `gradle-8.7-bin`) on ubuntu-latest the negative control printed both lines the script matches: `Could not find io.github.sztheory:crosswake-shell-core-android-negctl:0.2.11.` and `Could not resolve all files for configuration ':app:debugRuntimeClasspath'.` No wording change was needed.
- **Earlier red run, fixed forward.** The first run on this PR (id 42137231568, head 50e4d09c) failed documentation-contracts and hex-page-proof with `routing.unclassified_path .gitattributes`, a root file added by Plan 04 that the adoption-context scan did not classify. Fixed in 01408a04 (the scan now treats it as scannable text) and the run was cancelled by that push; nothing was rerun to green. The full local suite had also caught two other Plan 04 and Plan 07 omissions (the root allowlist test and the Phase 52 publish-readiness fixture) before any push, fixed in 14942e8f. The earlier note that `phase52_operator_truth` was pre-existing was wrong: Plan 07 added `guides/parity_ledger.md` to the docs extras.
- **Job cost.** 2.0 measured minutes (2 billable) on ubuntu-latest, against the 8-12 minute expectation. Whole run: 159 billable minutes against the roughly 250 baseline, 20.3 minutes wall clock, 2 jobs with a full-suite step against a baseline of about 10. No new duplicated full-suite run. The job caches only the Gradle distribution on purpose, since the proof must resolve published artifacts from the registries.
- **Promotion line.** `android_foreign: clean_runs=2/2 eligible=yes head=01408a04 ci_ran_on=synthetic_merge`. The count is derived by `script/android_foreign_promotion.sh` from CI history (the cancelled first run's job also concluded success). Promotion is not attempted here: D-20 requires a reviewed promotion PR that makes the job required, and that is a separate change.
- **What this proves.** The published artifact version 0.2.11 resolves and builds in a host that is not this repository, on Linux, and a wrong coordinate fails as expected. It proves the published version, not the version on this branch. Claim ceiling unchanged: JVM and Gradle evidence only, nothing on an emulator or a device.
