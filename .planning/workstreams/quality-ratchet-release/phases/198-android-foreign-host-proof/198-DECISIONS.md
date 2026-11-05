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
