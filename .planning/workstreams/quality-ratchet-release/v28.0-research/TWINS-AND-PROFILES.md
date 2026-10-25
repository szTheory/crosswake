# v28 Research: Digital Twins, Scenario Hosts and Adopter Profiles

**Dimension:** twins, demo/scenario hosts, synthetic adopter profiles
**Researched:** 2026-10-24 (read-only; no simulator, device, suite or git write was run)
**Updated 2026-10-24 after three user decisions (see section 11): Android is UNFROZEN, profile-exposed gaps become ADR-reversal candidates, releases are repaired and run on cadence. Where sections 1-10 say Android is frozen or an item is excluded, section 11 supersedes them.**
**Basis:** repo files read at `main` = `af1f4f67` (v27.0 archived). Ecosystem comparisons come from my own knowledge of Hotwire Native, Capacitor, Expo and Rails/Phoenix generators, not from fresh fetches, so treat them as MEDIUM confidence.
**Overall confidence:** HIGH on repo inventory and gaps, MEDIUM on ecosystem analogies and on the effort sizes.

## 0. Bottom line

1. Crosswake has one real twin (the Simulator twin, T01-T10) and one real scenario host (`examples/phoenix_host`). The "profiles" are three guide sections over that one host. That is a strong base for the offline-study story and thin everywhere else.
2. **The twin's only passing receipt (twin-05) does not describe `main`.** It attests candidate `a53fbef` (tree `f7c4d7dc`). `main` differs from it by 13 files under `lib/`, `examples/`, `packages/` and `priv/`, including `twin_runtime.ex`, `twin_producers.ex`, `verify_twin.ex`, `provenance.ex` and `config.exs`. The twin has no CI lane (D-25 of Phase 180 kept it local). Nobody has run it on the code that is now public. This is the single most important "rot" finding.
3. The biggest blind spot is the seam the twin cannot see: the host's webview and the host's own origin. SEED-015 (SSO cold boot) and SEED-016 (webview conformance) are both unbuilt, and the SSO guide section the seed asked for does not exist in `guides/`. Those two gaps are the exact failure the first real adopter hit while every Crosswake gate was green.
4. Everything in the twin and the example host is the author's own host. Crosswake has never been exercised against a **foreign, brownfield Phoenix app** except by companion clean-room lanes (which have never been green, TODO-011). That is the profile most likely to expose defects before a real adopter does, and it needs no adopter facts.
5. A bounded "scenario catalog" with six profiles, expressed as rows over the existing host plus two small additions (an SSO-gateway loopback fixture and a known-bad host fixture), covers the full claim surface without new products. This stays inside GET-6 only if the catalog is framed as proof structure, not new host apps. See decision U1.

## 1. Inventory: every twin, host, scenario and proof lane

### 1.1 Hosts and apps

| Asset | Path | What it is | Runs how | State |
|---|---|---|---|---|
| Shared Phoenix example host | `examples/phoenix_host` | One host, three locked lanes (SaaS Portal, Selective Native, Local-First Study) plus showcase hub, commerce mock, Chimeway, flashcards, media lane | Docker (`bin/see-it-run.sh`), `mix`, Playwright | Live. CI: `e2e-proof`, `route-tour-proof`, `phase5/10-proof` |
| Reference iOS shell host | `examples/ios_shell_host` | Checked-in generated shell, published-coordinate mode | `script/verify_generated_ios_shell.sh`, `bin/crosswake-ios-rehearsal` (Simulator, advisory) | Live. Only 4 unit and 2 UI test files |
| Physical-iPhone proof host | `examples/phoenix_host/native/ios/CrosswakeProofLane`, `physical_iphone/`, `lib/.../physical_iphone_*` | Separate native adapter that verifies installed bytes and plays `AVAudioPlayer`; 19-assertion contract at `@schema_version 2` | `bin/crosswake-physical-iphone`, signed device | One source-bound run on 2026-08-27 (iOS 26.6). Not re-runnable without a device |
| Twin iOS app | `examples/phoenix_host/native/ios/crosswake_shell` | Third iOS project: `StudyWebViewController`, `StudyAudioCommandDelegate`, `StudyPackInstaller`, `TwinHostDriver`, `TwinJourney` test plan | `mix crosswake.proof_lane.verify_twin ios` (local only) | Passed once as twin-05 against a53fbef. Bundle id `org.crosswake.twin` is hardcoded |
| Android shell host | `examples/android_shell_host` (+ `packages/crosswake-shell-core-android`, Maven `io.github.sztheory:crosswake-shell-core-android`) | Checked-in host resolving the published Maven coordinate; generator and JVM hermetic proof; `phase68-proof` emulator advisory (dispatch only, no cron) | CI `android-*` leaves; emulator lane manual | Previously frozen; UNFROZEN by user decision (section 11). No twin, no host-command seam, no device contract, no host-setup generation parity with iOS |
| Companion packages | `packages/crosswake_{sigra,chimeway,rindle,rulestead,threadline}`, shell cores | Published companions | Clean-room lanes, per-package CI | Clean-room lane "never green" (TODO-011 / SEED-004). Rindle unpublished (TODO-010) |

Note the duplication: there are **three iOS projects** around the example host (reference shell, proof-lane host, twin shell). They share ideas but not code, which is a drift risk.

### 1.2 Twin and proof lanes

| Lane | What it proves | How it runs | Freshness | Rot or break |
|---|---|---|---|---|
| Simulator twin T01-T10 (`verify_twin`, 7 identity joins, receipt, 5 stated fidelity limits) | Generated app shows one study island; installed media verified and played by host adapter; offline writes survive process kill; replay exactly once against real Ecto; reject/conflict recovery; logout/account-switch fence; entry/replay disablement; safe receipt | Local only, macOS, Xcode, free loopback port, one run root per attempt, one-shot receipt | twin-05 passed 2026-10-16 on a53fbef. `main` has moved (13 product files). Stale | Hardcoded bundle id (DEBT-IDENT); example-host G2/G6 test failures and a pre-existing Swift G4 failure carried; WR-02 (registry timeout reads as gone); `commit_ref` nested-host scrub; probe read can hang on a FIFO; five-file open warnings list |
| Twin preflight (`twin_preflight`) | Read-only "would a run be allowed" | Local | Current | None noted |
| Playwright browser lane (`e2e-proof`, `route-tour-proof`, `offline_sync` 29 tests, `offline_recovery`, `offline_storage`, `offline_accessibility`, `native_controls_fallback`, `evidence_panel`) | Browser-owned offline island, replay, route ownership, a11y, native-control fallbacks | CI merge-blocking | Current | Browser only; says nothing about WKWebView, iOS storage or the app process |
| ExUnit lane tests (`phase7/8/9_*_lane_test`, `phase70`, `phase74` offline draft recovery, `phase39-41` gating, `phase55/56` handoff and step-up, `phase59/60` Chimeway, `phase23/34` commerce, `phase160_scoped_replay_privacy`) | Contract-level scenario checks per profile | CI | Current, but the file names are phase numbers (`phase74_...`), which hides what profile each protects | Named by history, not by capability |
| Advisory scheduled workflows (`phase23/34/43/45/48/52/58/70/96/130/132-proof`, weekly Monday cron) | Companion and commerce advisory lanes | GitHub schedule | Weekly | 11 phase-numbered workflows; many duplicate CI leaves. A maintenance tax, and the phase naming hides ownership |
| iOS Simulator rehearsal (`bin/crosswake-ios-rehearsal`) | Opens the study route in Simulator; optional iOS test suite | Manual, advisory | Unknown | SEED-010: poor presentation, scroll-heavy smoke |
| `see-it-run` collateral (`see-it-run-collateral.yml`, `capture-collateral.sh`) | Screenshots for docs | Cron plus path push | Weekly | Collateral, not proof. Correctly labelled |
| Generated-shell verifiers (`verify_generated_ios_shell.sh`, `verify_generated_android_shell.sh`) | Generation plus build | CI | Current | Build proof only. 20 Xcode settings cells observed; simulator is unsigned |
| Clean-room lanes (`verify_companion_cleanroom.sh`, `clean-room-proof-rehearsal`, `exact-public-proof`) | Published artifact resolves in a fresh host | Dispatch/release | Never green for companions | TODO-011, TODO-010, TODO-012 |
| Physical contract and preflight | Fail-closed device handoff | Local, device | One run | `TODO-003`: generated test targets ship `CODE_SIGNING_ALLOWED=NO`, so the device lane was unreachable as generated at the time of the adopter report. Phase 179 added signing settings (verified in 179-VERIFICATION truth 1 and 3), but the TODO files still read `open`. Reconcile status. |
| Route inventory and navigation topology validators (`Crosswake.Adoption.*`) | Sanitized route rows validate; empty or `unknown_blocking` inventory blocks promotion | ExUnit | Current | Correct by design; no real rows exist |

### 1.3 What is broken or rotting (ranked)

1. **Twin-05 is not bound to `main`** (above). Also a53fbef exists only as a commit reachable in this repo; the recorded run root lives under `/private/tmp` and is not durable.
2. **Debt already admitted as "can pass while checking nothing"** (v26 disposition): privacy scan exits 0 on empty scope; gate labels that never fail in selftests; `commit_ref` for nested hosts; FIFO hang. These sit on the proof path the twin relies on.
3. **Hardcoded identity in the twin** (`org.crosswake.twin`, `WKAppBoundDomains` pinned to `example.com`, route id `study-session` vs `offline-study` mismatch). The twin attests a stand-in, not the generated identity.
4. **Naming rot:** 11 phase-numbered workflows and about 60 phase-numbered tests cannot be mapped to a capability by a new reader. This is the main DX defect of the proof surface.
5. **Three iOS projects**, no shared source. Any shell change must be mirrored by hand.
6. **Status drift in TODOs/seeds:** TODO-003/006/007/008 read `open` while Phase 179 shipped generation changes; SEED-014's A is stale (19 ids, not 20) and now has a recorded deferral. Planning truth and code truth disagree.
7. **Open open-findings in the example host:** the 5 `routing.unclassified_path` doctor findings under the example host's iOS shell directory were carried through twin-05 as known noise. A doctor that reports findings on its own reference host trains people to ignore it.

## 2. Synthetic adopter profiles (six)

Design rule: each profile is a *row set over the one shared host* plus at most one small fixture. No new host app, no new product, no new Phoenix app. This keeps the "one shared Phoenix host" invariant that `verify_adopter_profile_contract.sh` already enforces and keeps the work from becoming a business-line program (see U1).

Existing guide profiles: Phoenix SaaS Portal, Selective Native Flow, Local-First Study Flow. I keep those names and add three.

### P1. Offline Study (the forcing-function profile; existing)

- **Product shape:** offline study app, one island, foreground media bundle, cached neighbors, billing and settings server-owned.
- **Must contain:** `:offline_island` study route with `local_first` and an `island_contract`; cached read-only path/dashboard/history; one host-supplied foreground pack provider; scoped outbox; replay endpoint with reauth; `gated_by` flag; logout and account-switch fences.
- **Covers:** offline mutation island, replay/auth, installed media, account switch/logout, entry and replay disablement, denials (corrupt pack, missing pack), native navigation shell contract (advisory).
- **Reuses:** LearnLoop, `LocalFirst.*` modules, `offline_route_proof.ts`, twin T01-T10, physical proof host, `RouteInventory`.
- **New:** nothing for coverage. Only a re-run on main (R1) and a single catalog row naming it.

### P2. SSO-Fronted B2B Portal

- **Product shape:** authenticated Phoenix portal behind an identity gateway, step-up for sensitive actions, one low-frequency native affordance (haptics), session handoff.
- **Must contain:** SaaS portal routes (AdminPilot), step-up ceremony, handoff tickets, `crosswake_sigra` session authority, **plus a loopback "SSO gateway" fixture** that answers the first navigation with a cross-origin 302 (the SEED-015 shape) and a same-origin variant.
- **Covers:** SSO cold boot (the native layer is absent, not broken), auth-return boundary, recent-auth, bridge haptics/app_info, `route unavailable` denial, deep-link activation.
- **Reuses:** `saas_portal/*`, phase55/56/58/73 tests, `saas_session_controller`, Sigra companion, twin loopback origin harness (`script/verify_loopback_origin_simulator.sh` and `loopback_origin_simulator/`, listed as unreferenced in v25 debt).
- **New (S-M):** a gateway fixture inside the loopback harness plus a doctor/guide assertion. The Simulator can reproduce the cold-boot cross-origin cancel because it is WebKit behavior, not hardware behavior. (It cannot reproduce a real Cloudflare Access/Okta cookie flow.)

### P3. Selective Native Flow (field capture; existing, mostly future gap)

- **Product shape:** mostly Phoenix-owned app with one `:native_screen` route plus required packs and a transfer seam.
- **Covers:** `:native_screen` ownership, `pack_incompatible` denial, route-local capability and sensitivity, transfer.prepare seam, non-capture routes stay usable.
- **Reuses:** `selective_native/*`, `field_service/*`, phase8 lane test, `native_controls_fallback.spec.ts`.
- **Honest limit:** capture, scanner and document scan are "Future gap" in the capability map. This profile proves **ownership and denial**, not capture. Keep it at that; do not build capture here (stop list).

### P4. Subscription / Commerce Corridor (regression-only)

- **Product shape:** backend-owned entitlements with mocked storefront, reconciliation inbox, no production StoreKit.
- **Covers:** backend projection authority, reconciliation evidence, "provider evidence is not entitlement".
- **Reuses:** `commerce/*`, phase23/34/70 proofs, `SubscriptionLive`.
- **Posture:** keep green, add nothing. ADR forbids commerce productionization. Only change that is justified: rename its tests and workflows by capability (R6).

### P5. Brownfield Foreign Host (the missing profile)

- **Product shape:** an existing Phoenix 1.8 app, not the example host, with its own router, existing browser tests, an existing Xcode project with customized settings, and a stale install manifest from an older Crosswake.
- **Must contain:** a minimal generated Phoenix app fixture (`mix phx.new` output, pinned) outside `examples/phoenix_host`; run `mix crosswake.install`, `crosswake.doctor`, `crosswake.gen.shell ios --check/--diff` into it; an upgrade scenario from a prior template version; a stale-manifest scenario (TODO-004); a bundle-id/team-id scenario (TODO-007); no launch-screen/letterbox check (TODO-008).
- **Covers:** host-reusable proof (explicitly "missing" in the capability map), generator ownership and drift, doctor on a foreign router, upgrade ergonomics, origin-mode refusal, signing settings across the 20 Xcode cells.
- **Reuses:** `mix crosswake_install_test`, `crosswake_gen_shell_host_test`, `native_shell_upgrade.md`, `verify_ios_host_settings.mjs`, clean-room harness (SEED-004 fixes).
- **New (M-L):** the fixture plus a CI leaf that does not need a Simulator (generation, settings observation, doctor, `--check` are all file-level). The build step can stay on the existing macOS leaf.
- **Why it matters:** this is the closest thing to a real adopter that exists without real facts. Both adopter reports (SEED-013/014/015/016) were brownfield defects the example host could not show.

### P6. Hostile Host (known-bad fixtures, negative twin)

- **Product shape:** deliberately broken hosts that Crosswake's gates must reject. Not an app; a set of mutations.
- **Must contain (each as a named fixture plus an expected finding or denial):**
  1. a webview presented to the user that is not the instance the bridge is attached to (SEED-016 option 1);
  2. cross-origin SSO redirect at cold boot (shared with P2);
  3. device-lane fixture addressed through a source-relative path (`#filePath`), simulator-only (CW-REQ-M4);
  4. evidence printed by the app under test that never reaches `xcodebuild` on a device, yielding a false pass with null hardware facts (CW-REQ-M5);
  5. unsigned test targets presented as device-ready (TODO-003);
  6. `WKAppBoundDomains` not matching the declared origin;
  7. replay that trusts a payload scope instead of server authority;
  8. a receipt with an all-zero or placeholder commit (already guarded in v26, keep as control).
- **Covers:** "can the gate fail?", the repo's recurring defect (absence scored as success, PR #173).
- **Reuses:** v26 negative-control habits (`assert-twin` self-test 15/15, 24 guard-reverting mutations), `check_absence_is_not_success.exs`.
- **New (M):** a mutation catalog and a test per mutation. This is the cheapest, highest-value profile for trust, because each row converts an adopter-reported defect into a regression gate.

### Profiles considered and rejected

- *Notification/Chimeway as its own profile:* fold into P2/P4 as an add-on row. It is advisory and provider-evidence only.
- *A separate Android profile:* rejected as a profile; Android is a platform axis across P1-P6 (section 11).
- *Second offline island or generic sync profile:* contradicts "one study island is not generic sync".
- *Beautiful showcase apps:* stop list; SEED-010 stays narrow.

## 3. Capability by profile coverage matrix

Legend: **M** merge-blocking CI proof; **B** browser/ExUnit only; **T** Simulator twin (advisory, synthetic authority); **P** retained physical run (dated, non-transferable); **A** advisory only; **D** documented, no executable proof; **-** none; **N/A** not claimed. "Proposed" marks coverage a profile in section 2 would add.

| Capability / claim | P1 Study | P2 SSO B2B | P3 Native | P4 Commerce | P5 Brownfield | P6 Hostile |
|---|---|---|---|---|---|---|
| Route ownership `:live_view` | M | M | M | M | B | - |
| Route ownership `:native_screen` | - | - | M (denial only) | - | - | - |
| Route ownership `:offline_island` | M, T, P | - | - | - | - | - |
| Cached read-only is not mutation | M | - | B | - | - | - |
| Offline mutation island (journal, outbox) | B, T, P | - | - | - | - | - |
| Scoped replay and authority reauth | B, T, P | - | - | - | - | proposed |
| Logout / account-switch fence | B, T | D (sigra) | - | - | - | proposed |
| Entry and replay disablement (`gated_by`) | M, T | M | - | - | - | - |
| Host commands (seam v1.2, e.g. audio play) | T | - | - | - | - | - |
| Installed media / pack lifecycle | T, P | - | A (`pack_incompatible`) | - | - | - |
| Corrupt/missing media denial | T | - | A | - | - | - |
| Bridge haptics/app_info/permissions | M | M | - | - | - | - |
| Bridge share | A | - | - | - | - | - |
| Deep link / activation | M | M | M | - | - | - |
| **SSO cold boot (native layer lost)** | - | **D / none** | - | - | - | proposed |
| **Host webview conformance (visible instance = bridged instance)** | T (twin asserts it for its own host only) | - | - | - | - | **none** |
| Step-up / handoff / auth-return | - | M (server side) | - | - | - | - |
| Native navigation shell (bounded) | A (fixture) | - | - | - | - | - |
| Generator on a foreign host | - | - | - | - | **none** (example host only) | - |
| Upgrade/stale-manifest self-heal (TODO-004) | - | - | - | - | **none** | - |
| Signing / device-lane reachability | P (reference only) | - | - | - | **D** | proposed |
| Device-evidence honesty (false pass, null hardware facts) | contract only | - | - | - | - | proposed |
| Doctor findings on foreign router | - | - | - | - | **none** | - |
| Privacy of diagnostics/receipts | M, T | - | - | - | - | - |
| Native denial vocabulary closed on the wire (SEED-008) | partial | partial | partial | - | - | - |
| Commerce mock projection | - | - | - | M | - | - |
| Notification token snapshot | - | A | - | - | - | - |
| Capture, scanner, document scan, media upload | N/A | N/A | N/A (Future gap) | N/A | N/A | N/A |
| Generic sync / background sync / multiple islands | N/A (not claimed) | | | | | |
| Android anything beyond JVM hermetic | N/A (frozen) | | | | | |
| Physical iPhone for a real adopter's host | blocked (external gate) | | | | | |

### 3.1 Documented but unproven

1. **Doctor "host webview" claims.** Crosswake says it ships no `WKWebView` and requires the host to supply one (D-35), yet nothing tests the host's choice. Doctor exited 0 while the native layer was absent in the field.
2. **"SSO-fronted origins lose the native layer"** is documented only in a seed. No guide section, no doctor check.
3. **Host-reusable proof** is a capability-map row labelled "missing / not-yet-proven" and is the first-priority item in AGENTS.md, but the only host ever used is the author's.
4. **Native navigation shell** is "advisory, fixture" with topology `unknown_blocking`.
5. **Device-lane reachability.** Docs promise a device proof lane; TODO-003 says it was unreachable as generated. Phase 179 changed generation, but no automated check proves a freshly generated shell's test targets install on hardware (and none can on a Simulator, see section 4).
6. **Closed denial vocabulary** (SEED-008): one typed denial at the adopter boundary, not one vocabulary on the wire.
7. **Account switch / logout for the SaaS profile** is described in Sigra docs but not twin- or browser-tested end to end.
8. **Twin claims about `main`.** The twin's guide text is current but its only receipt is not.

## 4. Twin fidelity: what a twin can and cannot prove

### 4.1 Boundary table

| Question | Simulator twin (T) | Browser (B) | Retained physical (P) | Only a real adopter or device proves |
|---|---|---|---|---|
| Island logic, outbox, replay exactly once, Ecto effects | Yes (synthetic authority) | Yes, for browser | N/A | Real data shapes and volume |
| WKWebView + IndexedDB survives process kill | Yes (same data store) | No | Yes on one device | OS-level storage eviction under pressure, low disk |
| Real WebKit navigation policy (cold-boot cross-origin cancel) | **Yes, can reproduce** | No | Yes | Real IdP cookie and cross-site tracking behavior |
| Audio byte identity and playback start | Partly (decoder and progress; no speaker) | No | Yes (physical speaker) | Route, silent switch, Bluetooth, interruptions, background audio |
| Signing, provisioning, entitlements, install on hardware | **Never** (Simulator is unsigned, shares host filesystem, stdout lands in the xcodebuild log) | No | Yes | Team ID, certs, App Store processing |
| Backgrounding, memory pressure kills, cellular vs Wi-Fi, captive portals | **No** (simulated transport faults only via the loopback boundary) | No | Partial | Real networks |
| App Store review, privacy manifest acceptance | No | No | No | Review |
| Real auth provider flows (SSO, passkeys, MFA) | Synthetic only | Synthetic only | Whatever was run | Provider, tenant, MDM |
| Performance, battery, thermal | No | No | No | Device |
| That Crosswake itself is tamper-proof | No (trusted local runner, edits made and reverted mid-run undetected) | No | No | n/a |

The pattern named in SEED-013 holds: **every defect found on the real device was simulator-green**. Therefore the twin must never be the claim; it is a way to remove every defect that *can* be caught early so the physical run only spends effort on defects that cannot.

### 4.2 Adversarial pass: is a twin fooling us?

- **Absence read as success.** The repo's most repeated defect. Mitigated well in v26 (non-empty floors, negative controls). Remaining: privacy scan on empty scope, never-failing gate labels. Each is a place a green twin can assert nothing.
- **Twin attests a stand-in.** Hardcoded bundle id and app-bound domains mean the twin proves the twin app, not the generator's output. DEBT-IDENT is accepted debt, and it is the exact seam a brownfield host exercises first.
- **Synthetic authority is the oracle.** `synthetic_test_authority` grants sessions, so T08/T09 prove Crosswake *consults* the owner, not that a real backend owner is correct. Honest, and stated in the receipt.
- **Trusted local runner.** The receipt is derived by the same machine that ran the journey; it is evidence for the maintainer, not certification.
- **One-time receipt.** A passing run on a frozen candidate becomes false the moment code changes. Today there is no mechanism that makes an old receipt visibly stale; the guide still says "the shipped command", and a reader cannot tell twin-05 predates `main`.
- **Twin passes because the twin app is shaped to pass.** Participant hosts written by the framework authors rarely hit the host mistakes real adopters make (SEED-016). The Hostile Host profile (P6) is the antidote.
- **Cached-vs-local confusion.** Browser Playwright offline toggles prove island logic, not transport. The twin's loopback fault boundary correctly refuses `navigator.onLine` and Playwright toggles as substitutes (D-08).

### 4.3 Keeping the boundary visible

1. Put `fidelity` and `claim_ceiling` into every catalog row (section 6) and every receipt: one of `contract`, `browser`, `simulator_twin`, `physical_reference`, `adopter_physical`. A row can only claim up to its ceiling. The receipt already carries 5 limits; add `bound_to_head` and `bound_to_tree`.
2. **Bind receipts to a commit.** Debt 188 WR-03 already records "receipt carries no head/tree". Fix it, then make the guide print the receipt's head next to "current".
3. Add a doctor/CI "twin freshness" advisory: compares the latest retained twin receipt's tree with `HEAD` for the files the twin depends on (`lib/crosswake/proof_lane/twin_*`, `examples/phoenix_host/native/ios/crosswake_shell/**`, shell core, templates). Advisory, never merge-blocking, because the twin needs macOS and a Simulator.
4. Keep the support-matrix wording ("device evidence is not backend/session authority", "simulator evidence is not physical-device proof"). Extend the same legend to scenario catalog rows rather than inventing new labels (AGENTS.md prefers one-command proof over label taxonomy).
5. Never let a twin result promote anything: promotion stays with the physical driver and a validated TODO-002 bundle.

### 4.4 Keeping twins from rotting (cadence and cost)

| Tier | What | Cadence | Cost | Gate |
|---|---|---|---|---|
| 0 | File-level and ExUnit scenario checks (receipt shape, catalog consistency, mutation tests, generation `--check`, settings cells, doctor on fixtures) | Every PR | Cheap | Merge-blocking |
| 1 | Playwright browser lane | Every PR (exists) | Moderate | Merge-blocking |
| 2 | Simulator twin run on `main` | **On demand before any release or any twin-touching change, plus a scheduled monthly run on a macOS runner if the user accepts the cost.** Never per PR. | High (Xcode build, one owned Simulator, ~one journey) | Advisory; failure opens a tracked issue, does not block merges |
| 3 | Physical iPhone | Only when an adopter handoff validates | Human setup | The only promotion gate |

Rationale: the twin as built is a one-shot, consume-a-run-root command. That is excellent evidence design and a poor CI shape. Do not convert it into a permanent per-PR lane (the Phase 180 decision D-25 was right). Instead make the *freshness of the receipt* visible and the *twin-touching files* a short, enumerated list so a change to them requires a re-run before the next release.

## 5. What can be done NOW to de-risk the parked adopter lane (no external facts needed)

| # | Action | Closes | Needs adopter facts? |
|---|---|---|---|
| a | Run twin on current `main` (new run root; a new decision per the twin-06 rule) | Staleness of the only receipt | No |
| b | SEED-015 guide section ("If your origin is behind SSO"): cold-boot cross-origin rule, native layer absent not broken, fix is architectural on the host side. Optionally one doctor check that warns when the declared origin is known-gateway-shaped | A day of adopter misdiagnosis | No |
| c | SEED-016 option 1: host-run webview conformance contract (script evaluation reaches page, handlers survive navigation, reply landing pad reachable after cold boot, **visible webview is the bridged instance**). Ship as a test the adopter runs against their host; own nothing | The unfalsifiable green gate | No |
| d | SEED-013 residuals: guide note that device fixtures must be bundled resources (not `#filePath`); reconcile TODO-003/006/007/008 against Phase 179; doctor finding for stale install manifest (TODO-004); changelog "Upgrade Impact" discipline | Device-lane reachability documentation | No |
| e | SEED-014 residuals only where adopter-demonstrated: CW-REQ-A (haptics assertion) stays deferred until a reopen trigger fires (v26 decision) | Avoid a breaking contract change | No |
| f | SEED-011 alpha reference-host slice: **mostly already built.** The twin covers install online, offline study, kill/relaunch, ordered local mutation, replay once, bundle verification, session validation, account-switch denial, disablement. What SEED-011 still wants and the twin does not provide: a *signed/versioned* card manifest bundle with real image and audio bytes in a form an adopter can swap, host-owned refresh/revoke of the bundle, and callbacks for the physical-proof driver. Recommendation: **close SEED-011 as largely satisfied by v25/v26, re-scope the remainder to "bundle refresh/revoke through host-authorized foreground operation" and the physical callbacks, and promote only if a physical run is requested.** | Seed backlog accuracy | No |
| g | Pre-bake the handoff: have `RouteInventory`/`NavigationTopology` ship a worked, clearly synthetic example inventory (generic IDs) and a one-command "validate my sanitized rows" so the day real rows arrive, the chain is already exercised end to end | Time-to-resume when the gate opens | No (synthetic rows only; never infer the real adopter) |
| h | Pre-write the resume runbook for 163.1-08 Task 2: exactly which commands, which files, which physical-driver flags, in which order | Cold-start cost | No |

Do not infer anything about the adopter's routes to do (g); use only the generic study shape already in the route-policy map.

## 6. Recommended scenario catalog structure

### 6.1 Shape

One directory of small declarative records, one per scenario, validated by one ExUnit test and rendered into one guide page. Not a new runner.

```
test/scenarios/            (or priv/scenarios/ if the user wants it shipped)
  catalog.exs              # list of scenario ids, generated index
  S-<profile>-<nn>-<slug>.exs
```

Each scenario record (closed keys, unknown keys rejected, same philosophy as `RouteInventory`):

| Field | Meaning |
|---|---|
| `id` | `S-P1-04-replay-exactly-once` (profile, ordinal, slug) |
| `profile` | P1..P6 |
| `capabilities` | list of capability ids from `Crosswake.CapabilityMap` (so the matrix is generated, not hand-kept) |
| `claim_ceiling` | `contract`, `browser`, `simulator_twin`, `physical_reference`, `adopter_physical` |
| `proofs` | list of `{layer, command_or_test_ref, ci_tier}` where layer is `exunit`, `playwright`, `twin_group`, `physical_assertion`, `generator` |
| `negative_control` | the mutation or known-bad fixture that must make the proof fail (mandatory for any row with ceiling above `contract`) |
| `known_limits` | closed list from the fidelity vocabulary |
| `status` | `proven`, `partial`, `documented_only`, `blocked_external`, `not_claimed` |
| `owner_seed_or_todo` | link to SEED/TODO that tracks the gap |

### 6.2 Rules that make it extensible

1. **A new milestone adds rows, not harnesses.** A new capability must land with at least one scenario row and one negative control; the test fails otherwise (reuses the "absence is not success" guard idea).
2. **Matrix is generated** from `CapabilityMap` rows by profile (section 3 becomes a derived artifact in `guides/` via the existing `mix crosswake.docs.sync` path), so docs and proof cannot drift.
3. **Rename proofs by capability, keep history in frontmatter.** Aliases for `phaseNN_*` tests and workflows (R6), do not delete them.
4. **Ceiling enforced.** A `simulator_twin` row cannot appear under a "supported" label; only `physical_reference` or `adopter_physical` rows can feed the support matrix's device-evidence column.
5. **Twin groups T01-T10 keep their IDs** and map into scenario rows (`S-P1-*`). New twin groups are a new decision (twin receipt roster is closed by design).
6. **Profile guide stays the narrative**: extend `guides/adopter_profiles.md` and its contract script with P2, P5, P6 names only when their rows exist.

### 6.3 What the ecosystems do (MEDIUM confidence, from memory)

- **Hotwire Native** ships demo apps per platform plus a documented bridge component set; its cold-boot behavior is the SEED-015 case. Lesson: reference apps are shared, but adopters bring their own navigation shell; conformance of *your* host is your job unless the framework publishes a checklist. That supports SEED-016 option 1.
- **Capacitor** and **Expo** maintain an examples gallery and run app-level smoke tests per plugin against real project templates; Expo additionally CI-tests the *template* output (a fresh generated project builds). That is the P5 analogue.
- **Phoenix and Rails generators** are proven by "generate into a fresh app and run the tests" in CI, plus an upgrade diff guide. Crosswake's companion clean-room lane is that model; it has never been green.
- **Conformance suites** (HTTP/2, WebDriver, Kubernetes conformance) work because the test is run by the *implementor against their own implementation* and produces a signed-off result. P6 plus the webview conformance contract is the same idea at small scale.
- LiveView Native proves the opposite posture (framework-owned rendering); Crosswake explicitly is not that, so do not copy its showcase-gallery breadth.

## 7. Ranked recommendations

Horizon: immediate = next milestone start; near = within the next 2 milestones; mid = 3-5 milestones; long = only when a reopen trigger fires.

| # | Recommendation | Horizon | Effort | Depends on | Notes |
|---|---|---|---|---|---|
| R1 | Re-run the twin on current `main` (new run root), fix receipt to bind head and tree (188 WR-03), make the receipt's head visible in `see_it_run.md`. | Immediate | S-M | User decision to run (twin-06 rule) and macOS time | Also resolves "twin attests a stand-in" only if R2 lands first; otherwise note DEBT-IDENT |
| R2 | Close the three accepted twin identity debts: bundle id from generated identity, `WKAppBoundDomains` from declared origin, route id `study-session` vs `offline-study`. | Immediate | S-M | None | Makes the twin attest generator output, which P5 then reuses |
| R3 | SEED-015 guide section plus one doctor advisory. | Immediate | S | None | Cheapest adopter-time saver. Do not propose patching Hotwire |
| R4 | SEED-016 option 1: host-run webview conformance contract; **do not** pursue option 2 (first-party WKWebView host). | Immediate to near | M | R3 helps (shares the cold-boot fixture) | "Visible webview is the bridged instance" assertion first |
| R5 | P6 Hostile Host mutation catalog (8 rows above), each with a named negative test. | Near | M | R4 for rows 1-2 | Converts adopter-reported defects into gates; highest trust per hour |
| R6 | Scenario catalog skeleton (section 6) plus rename-by-capability aliases for `phaseNN_*` tests/workflows; generate the coverage matrix from `CapabilityMap`. | Near | M | None | Pure structure; do before adding more rows |
| R7 | P5 Brownfield Foreign Host fixture and a Simulator-free CI leaf (generate, doctor, `--check`, settings cells, stale manifest, upgrade). Also reconcile TODO-003/004/006/007/008 against Phase 179. | Near | M-L | R2 | The best proxy for the real adopter's first day; needs no adopter facts |
| R8 | P2 SSO-gateway loopback fixture inside the existing loopback harness (wire up or remove the unreferenced `verify_loopback_origin_simulator.sh`). | Near | M | R3, R4 | Simulator reproduces WebKit policy; document it cannot reproduce IdP cookies |
| R9 | Twin freshness advisory and a monthly scheduled macOS run (user cost decision). | Mid | M | R1 | Advisory, never merge-blocking |
| R10 | Pre-bake adopter handoff: synthetic example inventory, "validate my rows" command, resume runbook for 163.1-08 Task 2. | Near | S-M | None | Reduces cold-start when the gate opens |
| R11 | Close SEED-011 as mostly satisfied; re-scope remainder (bundle refresh/revoke, physical callbacks). | Immediate (planning only) | S | None | Keeps seed truth honest |
| R12 | Sweep the carried "can pass while checking nothing" debt before the next twin-touching change (privacy scan empty-scope exit 2, negative control per gate label, `g()` pinning, bounded git-local read). | Near | S-M | None | Prerequisite for trusting R1, R9 |
| R13 | Unify the three iOS projects around shared source for the study host (twin shell, proof-lane host, reference shell) or at least add a drift check. | Mid | L | R2 | Only if iOS work continues; otherwise add the drift check only (S) |
| R14 | Haptics assertion CW-REQ-A, RouteUnavailableView route id CW-REQ-D, compile-time `:local_first` rule, native denial vocabulary closure (SEED-008). | Long | M each | Reopen triggers in `187-DEFERRALS.md` | Keep deferred |

Suggested v28 shape (for the roadmapper): **now** R1+R2+R11+R12 (twin is trustworthy on main) with R3 as the first docs win; **next** R4+R5+R6+R7(+R10); **later** R8, R9, R13; **parked** R14 and everything adopter-physical.

## 8. Explicit "do NOT do" list

- (Superseded by section 11: Android is unfrozen.) Do not add Android breadth beyond the parity path in section 11 (no Android-only features, no Android-first profiles).
- Do not build new host apps or products per profile. Profiles are rows over `examples/phoenix_host` plus two small fixtures.
- Do not make the twin a per-PR CI lane, and do not make its freshness check merge-blocking.
- Do not let any twin, simulator, fixture or synthetic-inventory result promote the first adopter or any support claim.
- Do not build capture, scanner, document scan, native menu/action breadth, commerce productionization, generic sync, background sync or generic native storage to make a profile "complete".
- Do not own `WKWebView` lifecycle (SEED-016 option 2) and do not propose forking or patching Hotwire (SEED-015).
- Do not reuse a consumed run root or retry a failed twin to green; repairs are new runs.
- Do not invent adopter facts (routes, sizes, flags) to fill TODO-002; synthetic rows must be visibly generic.
- Do not add a new label taxonomy; extend the existing support-truth legend with `claim_ceiling`.
- Do not delete phase-numbered tests or workflows; alias them.
- Do not bump the physical-iPhone contract schema without a reopen trigger.

## 9. Decisions only the user can make

| ID | Decision | Recommendation |
|---|---|---|
| U1 | **ADR GET-6 tension.** The ADR lists "multiple adopter profiles" under the rejected business-line alternative, and AGENTS.md says Crosswake is infrastructure for one adopter. The user now says digital twins and profiles are the proving ground because they are not ready to use Crosswake themselves. Amend the ADR with a dated note that, while the adopter is parked, profile *scenario rows* over one host are permitted as proof structure, with the reversal conditions unchanged? | Yes, record the amendment; keep new hosts forbidden. |
| U2 | **Android unfreeze.** DECIDED by the user: unfrozen. See section 11 for the path and ADR text. | Done; amend ADR. |
| U3 | **Cost of macOS CI for the twin** (monthly scheduled advisory run vs on-demand only). | On-demand before releases plus monthly advisory if cost is acceptable. |
| U4 | **Approval to run twin-06 on `main`** (new run root, uses Simulator and Xcode on the user's machine). | Approve; it is the cheapest honest freshness fix. |
| U5 | **Ship SEED-016 conformance publicly** (as a documented adopter-run suite) vs keep internal. | Ship it, owning nothing. |
| U6 | **Brownfield fixture location** (inside repo `test/fixtures` vs separate repo). Separate repo repeats the "candidate under /tmp" risk. | In repo. |
| U7 | **Whether to promote SEED-011's remainder** or wait for the adopter's physical run request. | Wait; close the rest. |

## 10. Confidence and gaps

| Area | Confidence | Notes |
|---|---|---|
| Inventory | HIGH | Read from the tree and planning records. Not all workflow files and tests were opened; a few detail claims (for example "about 60 phase-numbered tests", 11 phase workflows) are counted from listings |
| Twin staleness | HIGH | `git diff --stat a53fbef HEAD` showed 13 product files changed under lib/examples/packages/priv, including twin runtime and producers |
| Coverage matrix | MEDIUM | Built from guides, capability map and test names, not from reading every test body. Verify any cell before it drives scope |
| Ecosystem analogies | MEDIUM | From memory, not fetched |
| Effort sizes | MEDIUM | Estimates; R7 and R13 are the most uncertain |

Gaps for phase-level research later: exact CI shape for the P5 leaf; whether the loopback harness can host the SSO gateway fixture without new dependencies; whether `CapabilityMap` can generate the matrix without schema change; the true status of TODO-003/006/007/008 after Phase 179.

## 11. Addendum: user decisions (Android, ADR reversal, releases)

### 11.1 Android is unfrozen: inventory, gaps, matrix

Known state (from repo): Android has a generator, a published Maven shell core, a checked-in host in published-coordinate mode, JVM hermetic CI leaves (`android-generated-shell-unit`, `android-package-unit`, `phase18-elixir-android-proof`, `phase67`, `phase79`), an advisory emulator workflow (`phase68-proof`, dispatch only), and `guides/android_uat.md`. Missing relative to iOS (read from the tree; verify before planning):

| Gap | iOS has | Android has |
|---|---|---|
| Host setup from a Mix declaration (`:crosswake, :ios_host`, compile-only generation, `--diff/--check`, 20 settings cells) | Yes (Phase 179) | No analogue found |
| Host-command seam (manifest 1.2.0 `host_commands`, `host_command_seam_version`) | Yes (Phase 181) | Explicitly not read by Android |
| Simulator/emulator twin (T01-T10 groups, receipt, identity joins) | Yes, one pass | None |
| Offline island on the real WebView (process kill, relaunch, replay) | Twin T05/T06 | Browser lane only |
| Installed media / foreground pack adapter | Twin T01/T04, physical run | Simulated lifecycle only |
| Navigation shell contract (advisory) | Advisory | None |
| Device contract and preflight (19 assertions) | Yes, one run | None |
| Signing/install reachability | Phase 179 settings | Debug-key build only, unverified on hardware |

Android-specific blind spots a twin can reveal that the iOS twin cannot: WebView provider version differences, `WebViewAssetLoader`/cleartext policy for loopback (`10.0.2.2` not `127.0.0.1`), process death and `onSaveInstanceState`, back-button semantics, Doze and app standby, Maven coordinate resolution in a foreign Gradle project (the Android twin of P5), minSdk 26 vs target behaviors, and the intent-based equivalent of SEED-015 (custom tabs for cross-origin redirects).

**Near-term Android path (ranked, all iOS-first-learnings reused):**

| # | Step | Horizon | Effort | Notes |
|---|---|---|---|---|
| A1 | ADR amendment (text below) and un-freeze edits to AGENTS.md, support matrix and capability map ("Android is frozen" wording appears in all three, plus `native_shell` guidance) | Immediate | S | Planning only. Update ADR, REQUIREMENTS, ROADMAP, STATE, support truth together per AGENTS.md |
| A2 | Android column in the scenario catalog (`platform` field per scenario: `ios`, `android`, `both`) and an honest parity inventory generated from it | Immediate/near | S-M | Before any code, so the gap list is a measured artifact, not a guess |
| A3 | Android P5 (brownfield): generate the shell into a foreign Gradle project, resolve the published Maven coordinate, run JVM tests | Near | M | Cheapest Android proof; Linux CI, no emulator |
| A4 | Android P6 hostile-host rows: WebView instance mismatch, cross-origin cold navigation to custom tab, cleartext/loopback misconfig, debug-signed build presented as release | Near | M | Reuses the conformance contract design (R4) |
| A5 | Move `phase68` emulator lane from dispatch-only to scheduled advisory (weekly, like other advisory lanes) and add the P1 offline-study journey as an emulator instrumented test on the loopback origin | Near-mid | M-L | KVM on ubuntu already documented in the workflow. Cheaper than macOS, so Android gets freshness more easily than iOS |
| A6 | Android twin: same T01-T10 roster and receipt schema, owner-tagged observations, `fidelity_limits` stating "emulator not physical device"; reuse the receipt contract rather than forking it | Mid | L | Requires decisions on host-command seam parity (below). Do not start before A2 shows the gap |
| A7 | Host-command seam and host-setup generation parity for Android | Mid | L | Manifest 1.2.0 fields are additive; Android must read them. A real contract change, so version and gate it |
| A8 | Android physical device run | Long | L | Only when an adopter commits Android scope; same fail-closed contract, new run |

Sequencing rule: do not implement Android behavior that iOS has not already proven, and do not let Android parity block the first adopter's iPhone gate. Run Android catalog and P5/P6 rows first because they are cheap and expose blind spots; defer the Android twin until the parity inventory exists.

**ADR amendment must say (draft):**
1. Date, and that it amends the "v21 is an iOS-only adoption milestone" decision, which froze Android during v21 only (v21 is parked; the freeze has outlived its milestone).
2. Android is unfrozen for **proof and parity of existing contracts** (generator, shell core, host-setup, host-command seam, twin, catalog rows). It is not unfrozen for new native features, new templates for their own sake, native-control breadth, or Android-first product surface.
3. Android never gates the first adopter's iPhone physical proof; Android claims keep their own `claim_ceiling` and labels (`JVM hermetic proof`, `emulator evidence`, `device evidence`).
4. Manifest and contract changes remain additive and versioned; any shared contract change names its Android disposition (read, ignore-inert, or breaking) in the changelog "Upgrade Impact".
5. Reversal condition for the unfreeze: if Android parity work delays an iOS gate or the first adopter's physical run by more than one milestone, re-freeze Android and record it.
6. Keep the rest of the stop list.

### 11.2 Matrix additions (Android column)

Add a platform axis to section 3. Current Android cells (best read; verify):

| Capability | Android today | After A3-A7 |
|---|---|---|
| Route ownership `:live_view` / activation | JVM hermetic (M) | plus emulator (A) |
| `:native_screen`, `:offline_island` on real WebView | None (browser lane only) | emulator journey (A5/A6) |
| Offline mutation, replay, account-switch fence | Browser only | emulator twin (A6) |
| Installed media / pack | Simulated lifecycle | needs a host-supplied adapter; decision, not yet scoped |
| Host commands | Not read | A7 |
| Foreign-host generation and Maven resolution | Checked-in host only | A3 |
| Hostile-host rows | None | A4 |
| Device evidence | None | A8 |

### 11.3 Profile-exposed gaps as ADR-reversal candidates

The stop list names generic sync, background sync and generic native storage as excluded unless the ADR's reversal condition is met (two independent active adopters needing overlapping behavior, or a funded business-line mandate). The user has said profiles may reopen the ADR. Process I recommend, so gaps are neither silently excluded nor silently built:

1. Each scenario row may carry a `gap_candidate` block: capability, the scenario that exposes it, the observed failure or limit, the evidence reference, and the cheapest honest mitigation that stays inside current scope.
2. A candidate is only written when a **measured** result (a failing negative control, a documented twin limit, or an adopter report) shows the gap. Argument alone is not evidence.
3. Candidates are collected in one register (extend the seed mechanism) and reviewed at milestone boundaries. Promotion to an ADR reversal proposal requires: two profiles (or a profile plus a real adopter signal) exposing the same gap, an estimate, and a bounded slice with a stop condition. This tracks the existing reversal rule without weakening it; synthetic profiles count as evidence of a gap, not as "independent active adopters".
4. Likely first candidates, from this research (all need evidence before promotion):

| Candidate | Evidence today | Posture |
|---|---|---|
| Foreground bundle refresh/revoke (SEED-011 remainder) | Twin covers install and verify only | Small, host-authorized foreground op; not generic sync |
| Android offline island parity on real WebView | No proof either way | Comes from A5/A6; likely first real data |
| Background replay | Replay only runs in foreground by design; the twin cannot exercise backgrounding | Record as an honest limit; candidate only if a profile (study reminder, flaky network) shows data loss |
| Generic native storage for media | Capability map: "Future gap", provider-adapter only | Candidate only if Android adapter needs a second, different storage shape |
| Generic sync helpers | Single-flow replay only | Do not propose; no evidence beyond the study flow |
| Haptics assertion and denial-vocabulary closure | Existing deferral triggers | Stay in `187-DEFERRALS.md` |

### 11.4 Release pipeline: repair then cadence

Evidence from the repo: the release machinery is large and was repeatedly hardened (Phase 164-175, 171-175 recovery/ancestry work, `REL-10 BREACHED` accepted as a historical qualified breach), the companion clean-room lane has never been green (TODO-011), Rindle is unpublished (TODO-010), exact-public-proof assumes a linked six-package release (TODO-012), the release graph is welded to 0.2.1 (TODO-009 / SEED-017), the iOS mirror has two armed fuses (memory note), and Release Please currently runs green on every merge with all publish jobs skipped.

Recommendation:
1. **Immediate (S-M): repair, in this order.** TODO-012 (exact-public-proof must accept a partial/linked set), TODO-009 / SEED-017 (generalize the release graph from the welded version), TODO-010 (decide Rindle: publish or remove from the proof set), TODO-011 / SEED-004 (make the clean-room lane green by fixing the harness, not by loosening it; P5 shares this fixture). These are prerequisites for a cadence, because a cadence that needs a hand-patched pipeline each time will not hold.
2. **Near: dress rehearsal then first cadence release.** Run the candidate-rehearsal and fire-drill paths (no credentials, no record) to prove the repaired graph, then cut the next release. Core publishes first, then companions (core-first DAG lesson).
3. **Cadence:** release when `main` has releasable commits and the catalog says no row regressed, targeting a fixed rhythm (suggest every milestone boundary, with patch releases as defects demand). Each Hex, Maven and iOS publish and each tag/push stays behind the one-use plain-language `allow`/`hold`, per AGENTS.md; automation prepares the proof and the displayed scope, never the approval.
4. **Twin and catalog tie-in:** before a release PR merges, require (advisory-to-human, not automatic) the receipt freshness check for twin-touching files and the catalog ceiling check. Android coordinates (Maven) join the release when A3 proves foreign-host resolution; until then keep Maven on its current path, because a Maven publish is irreversible.
5. Do not publish from a dress rehearsal result alone; path-dependency rehearsals never catch published-core resolution (recorded lesson).

### 11.5 Updated ranked list

Insert into section 7: A1 and A2 at **Immediate**; release repair (11.4 step 1) at **Immediate**; A3, A4 at **Near** alongside R5-R7; first cadence release at **Near**; A5 at **Near-mid**; A6, A7 at **Mid**; A8 at **Long**. R13 (unify iOS projects) now also considers an Android analogue and stays Mid. Suggested v28 shape becomes: **now** R1, R2, R11, R12, A1, A2, release repair, R3; **next** R4, R5, R6, R7, A3, A4, R10, first release; **later** R8, R9, A5-A7, R13; **parked** R14, A8, anything adopter-physical.

### 11.6 Remaining user decisions

| ID | Decision | Recommendation |
|---|---|---|
| U8 | Approve the ADR amendment wording in 11.1 (and the re-freeze trigger) | Approve |
| U9 | Does Android get an equivalent of the physical-iPhone contract soon, or stay at emulator ceiling until an adopter commits Android? | Emulator ceiling for now (A8 long) |
| U10 | Release cadence rhythm (per milestone vs monthly) and who confirms the displayed scope before each `allow` | Per milestone plus defect patches |
| U11 | Rindle: publish or drop from proof set | Decide before the first cadence release |
