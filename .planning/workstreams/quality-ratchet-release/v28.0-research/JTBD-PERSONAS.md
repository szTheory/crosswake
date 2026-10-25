# Crosswake v28.0 Research: Jobs-To-Be-Done, Personas, and "Will This Be Useful?" Sanity Check

**Dimension:** JTBD, user personas, competitive positioning, onboarding sanity check
**Researched:** 2026-10-24
**Supersedes:** `.planning/research/JTBD-AND-USER-FLOWS.md` (dated 2026-05-23; see "What changed" below)
**Overall confidence:** MEDIUM-HIGH. Repo findings are HIGH (read directly). Competitor facts are HIGH where tagged to a primary page I fetched, MEDIUM/LOW where inferred or from old forum threads.
**Coordinator decisions applied (2026-10-24, after first draft):** (1) **Android is UNFROZEN as soon as possible**, so the ADR's "iOS-only" and "Android frozen" posture is superseded for roadmapping; Android-needing personas are now first-class (Section 3, P7, and Section 4a). (2) **Synthetic adopter profiles may reopen ADR stop-list items when evidence shows a real gap**; the "do not do" list in Section 9 is therefore a *default with a named reopening path* (Section 9a), not a permanent ban. Both ADR and AGENTS.md need an update PR to match (Section 10, decision 0).
**Method limits (read this first):**
- This is a static walk of the onboarding path (README, guides, installer and doctor source, example host README). I did NOT run `mix crosswake.install`, `doctor`, `gen.shell` or the example host, because the brief is read-only. Every "friction" item below is therefore a documented-path finding, not a timed run. Item C1/C2 in the readiness table are explicitly "unmeasured", and building the measurement is itself a top recommendation.
- No real adopter is named or inferred. "P1" below is a shape (solo or tiny-team B2C Phoenix app with an offline study-like flow), taken from the public adopter-profile guide and the codename ADR only.

---

## 1. Headline answer

**Will it be a useful framework?** Yes, for a narrow and real niche, and not yet demonstrably for anyone outside it.

- The niche: a **Phoenix B2C (or prosumer) app that needs an iPhone App Store presence AND has one flow that must keep working offline with honest, privacy-safe replay**. For that job, no alternative gives you per-route runtime ownership, typed fail-closed denials, and a diagnosable offline contract in one Phoenix-native package.
- Outside the niche (a Phoenix app that just needs "an iPhone app with push and maybe haptics"), **Hotwire Native or a plain WebView shell will get a team to a store listing faster than Crosswake can**, and Crosswake's own docs say so implicitly (default most routes to `:live_view`). Crosswake wins there only on governance (denials, diagnostics), which teams undervalue until they are burned.
- The biggest risk to usefulness is **not missing features**. It is (a) an unmeasured newcomer path with at least two documented steps that cannot work as written outside the repo, (b) vocabulary and proof-label surface that is far larger than the job it serves, and (c) a roadmap history that drifted toward generalization (commerce, notification corridors, native-screen families) which the governing ADR now forbids.

**Single opinionated recommendation:** Stay an infrastructure project for the First B2C Adopter (ADR GET-6). Spend the next milestone not on features but on **making the newcomer path measurable and honest** (clean-room harness from Hex coordinates, doc ramp cleanup, doctor-to-troubleshooting coverage), and pin every roadmap item to a persona-job ID. Nothing here requires new native or Android surface.

---

## 2. What changed since the previous JTBD memo (do not just repeat it)

The 2026-05-23 memo is stale in three ways that matter for roadmapping.

1. **Its recommended ordering is now on the stop list.** It ranks (1) commerce/paywall corridor, (2) notification re-entry corridor, (3) diagnostics, (4) auth corridor, (5) more native-screen families. `AGENTS.md` and the ADR now say: do not build native menu/action breadth, capture/device packs, commerce productionization, dashboard, generic sync, or background sync unless the ADR reversal condition is met (two independent active adopters needing overlapping generalized behavior, or a funded business-line mandate). Items 1, 2 and 5 of that ordering are therefore **retired as not executed**. Items 3 and 4 survive only in narrowed form (diagnostics yes; auth only as "backend auth authority for scoped replay").
2. **Its "three canonical jobs" are really one job plus two supporting shapes.** Since the ADR, the one funded job is: *one real Phoenix app, one physical iPhone, one offline mutation island, with scoped replay and backend auth authority*. The SaaS Portal and Selective Native profiles are legitimate teaching shapes but have no active adopter pulling on them.
3. **It has no persona dimension and no adoption-readiness measure.** It lists jobs by ownership story, not by who is hiring Crosswake, what they switch from, or what makes them quit. This document adds that.

Also stale: the memo sits in `.planning/research/` (root) rather than a workstream, and its "Update Protocol" has no owner or trigger. Recommendation R3 below fixes both.

---

## 3. Personas

Seven personas (P7 added). Priority is set by the ADR: **P1 is the only persona Crosswake is allowed to optimize for now.** P2 to P6 are used as *tests of whether the roadmap is accidentally P1-only in a harmful way* (for example a hard-coded assumption that blocks a team with real SSO), and to decide what documentation must say honestly. They are not mandates to build.

### P1. Solo / tiny-team Phoenix founder with an offline-capable B2C product (PRIMARY, ADR-bound)

- **JTBD:** "When my web product is working and users ask for an iPhone app that works on a plane or in a bad-signal room, help me ship one **without a second codebase or a native rewrite**, and without losing or leaking a user's offline work."
- **Trigger:** App Store presence becomes a public-release requirement; one flow (study, practice, logging) needs local mutation; a pure PWA is rejected for iOS reasons (install friction, storage eviction, no real push/permissions story on their audience).
- **Current alternatives:** PWA with service worker; Hotwire Native or Capacitor around the LiveView site (works for online routes, no honest offline mutation); hand-rolled WKWebView + custom JS bridge; React Native/Expo rewrite of the offline screen only.
- **Switching cost into Crosswake:** low code cost (declarative route metadata, additive installer), **high setup cost** (iOS signing, an HTTPS origin, Xcode, bridge-hook wiring, `:ios_host` declaration). They are solo, so every undocumented step costs a day.
- **Adopt if:** time-to-first-route-on-iPhone is hours not days; doctor names the exact fix for each failure; offline replay is demonstrably scoped per account and survives logout/switch; they can eject or leave without rewriting the Phoenix side (routes stay normal LiveViews with extra metadata).
- **Abandon if:** a generated shell needs hand-patching on every upgrade; the first push raises an error whose cause is in a guide they have not read; support-truth vocabulary reads like a compliance regime; an App Store review rejection ("repackaged website", guideline 4.2) arrives and Crosswake offers no guidance.
- **Evidence in repo:** ADR GET-6, adopter brief, `guides/adopter_profiles.md` (Local-First Study Flow), `guides/physical_iphone_handoff.md` (physical proof still blocked on an external gate).

### P2. Small B2C/SaaS startup team (2 to 6 engineers, 0 to 1 iOS-curious) (SECONDARY test persona)

- **JTBD:** "When the board or customers want a mobile app, give us a credible one in a quarter by reusing what we have, with predictable maintenance cost."
- **Trigger:** Sales/customer ask; competitor has an app; push notifications and deep links requested.
- **Current alternatives:** Hotwire Native (if they like Turbo-style navigation), Capacitor (if they have a JS frontend), Expo/React Native (if they hire a mobile dev), outsourced native build.
- **Switching cost:** moderate. They need a second person to own the Xcode project; `host-owned` shells mean that person owns a generated native project forever.
- **Adopt if:** the shell upgrade story is clear (the "do I need to rebuild?" four-class table is actually good here); push/deep-link works from a guide in a day.
- **Abandon if:** the native shell upgrade burden exceeds a web deploy cadence; they need push, deep links, auth return, and commerce all at once and those are labeled "advisory", "deferred", or "provider-only".
- **Honest fit:** weaker than P1 today. The notification and commerce stories are contract vocabulary without adopter proof. Do not market to P2 yet.

### P3. Agency / consultancy shipping Phoenix apps for clients (WEAK FIT today)

- **JTBD:** "When a client asks for 'the app', give me a repeatable, low-risk path I can bill fixed-price and hand over."
- **Trigger:** third repeated client request.
- **Current alternatives:** Capacitor/Ionic or Expo (hiring pool is large), Hotwire Native for Rails shops, PWA.
- **Switching cost:** high: they need a known, learnable stack across clients. Elixir-only mobile tooling shrinks the pool of people who can maintain it after handoff.
- **Adopt if:** one generator produces a project a non-Elixir iOS dev can open and understand; docs read as a recipe.
- **Abandon if:** any client project needs bespoke native breadth; shell needs a Crosswake maintainer to debug.
- **Roadmap implication:** ignore as a driver. Use only as a smell test: "could a stranger run this from the README?" which is exactly the clean-room criterion.

### P4. Enterprise / SSO / MDM team (B2B SaaS on Phoenix) (OUT OF SCOPE, document honestly)

- **JTBD:** "When our B2B customers demand a managed iOS app with SSO and MDM policy, make it pass their security review without forking our web app."
- **Current alternatives:** native build, Intune/MDM-wrapped Capacitor, Hotwire Native.
- **Blockers in Crosswake today (all documented as deferred):** SSO/OAuth/OIDC/MFA/passkeys provider guidance, refresh-token helpers, impersonation, native auth UI. The repo has auth-posture and step-up *contracts* (`auth_min_level`, `requires_recent_auth`, `auth_return`) but explicitly no provider adoption proof.
- **Roadmap implication:** the route-policy auth fields are a liability if they imply support. Keep them labeled "contract only, no provider proof" and do not extend. This persona is the strongest reason to tier the DSL (Section 6, R8).

### P5. Skeptical mobile engineer (VETO HOLDER, not a buyer) (CRITICAL for credibility)

- **JTBD (what they hire for):** "Tell me up front where this will fall over, so I do not inherit a WebView app I cannot debug."
- **Beliefs:** web wrappers get rejected by Apple (guideline 4.2), feel non-native, leak state across the bridge, and become unmaintainable.
- **What earns grudging respect:** typed versioned bridge contract with fail-closed denial, no continuous bridge traffic (continuous authority belongs in an offline island or native screen), host-owned Swift they can read and edit, explicit rebuild classes, a `route unavailable` surface instead of silent degrade, and public honesty about what is advisory (simulator) versus proven (device).
- **What loses them:** generated Swift that fights Xcode; any claim of "write once"; unproven offline claims; proof taxonomy used as a substitute for a running app on a phone.
- **Roadmap implication:** the physical-iPhone proof is the single most persuasive artifact for this persona. A recorded, reproducible, privacy-safe device run beats every additional label.

### P6. Security / privacy officer (GATEKEEPER)

- **JTBD:** "When engineering proposes offline mutation on user devices, let me verify that sensitive payloads are scoped, authorized on replay, and never leak into telemetry."
- **Wants:** opaque scope refs, scope-partitioned outboxes, replay authorization, fail-closed logout/account-switch, no raw payloads/tokens/device IDs in logs or diagnostics, evidence they can read.
- **Evidence in repo:** AGENTS.md sensitive-data rules, doctor/inspection redaction work (v26), privacy scan before every push.
- **Roadmap implication:** this is Crosswake's most defensible differentiator (honest, privacy-scoped offline) and it is **the least visible in the README**. Surface it.

### P7. Cross-platform B2C team (Android is a hard requirement) (NEW after Android unfreeze)

- **JTBD:** "When our users are split across iPhone and Android, give me one Phoenix-owned product with the same route-ownership contract on both, without maintaining two divergent shells."
- **Trigger:** consumer B2C where Android share is large or a customer/regional market is Android-first; a store launch that cannot be iOS-only.
- **Current alternatives:** Hotwire Native (both platforms, mature: Android 1.3.1), Capacitor, Expo/React Native, Flutter, PWA (Android PWA support is the strongest).
- **Switching cost:** high if the Android shell is less proven than iOS; two shells double native review and release burden.
- **Adopt if:** Android has the same one-command proof, the same denial vocabulary, a real-device path, and shared contract vectors (these already exist for the bridge contract on JVM).
- **Abandon if:** Android lags iOS by features or evidence; the docs split into "iOS here, Android later" caveats; the generator drifts from the iOS contract.
- **Impact of missing Android today:** P7 is excluded entirely and P2/P3 are partly excluded (agencies nearly always need both). Android also removes the strongest PWA-vs-native counterargument on that platform, so Android needs an honest "why not a PWA" story. **This persona is the main reason to unfreeze Android, and it makes parity of the *contract* (not UI breadth) the target.**
- **Risks to manage:** doubling the proof surface before the iOS path is measured; Android WebView and offline storage eviction semantics differ from WKWebView, so the "honest offline" claims must be re-proven on Android, not inherited. Sequence: iOS clean-room harness (R4) first, then reuse its structure for Android.

### Maintainer / contributor lens (not a persona to build for)

OSS contributors face: ~156 library modules, a huge `.planning/` history, 6,600 lines of guides, root-level scratch scripts, and a proof/CI regime tuned for one maintainer. Contribution is realistic only for docs and narrowly scoped fixes. Do not optimize for external contribution before there is a second adopter.

---

## 4. Competitive positioning (primary sources where fetched)

| Competitor | Verified facts | Overlap with Crosswake | Where it beats Crosswake | Where Crosswake beats it |
|---|---|---|---|---|
| **Hotwire Native** (Rails/Turbo) | Web-first: native shell around a web view, native navigation, "Bridge Components" (web Stimulus controller + Swift/Kotlin counterpart), "Path Configuration" (JSON rules: URL regex patterns to properties like `presentation`, `context`, `view_controller`, `modal_style`). iOS 1.3.0 (Jul 2026), Android 1.3.1 (Jul 2026). [HIGH, native.hotwired.dev] | Closest philosophical analog. Path configuration is "route policy lite". | Maturity, adoption, 37signals backing, both platforms, native nav feel, huge Rails mindshare, far less to learn. | Path config maps URL patterns to *navigation presentation* only. It has no per-route runtime owner declaration (`live_view` vs `offline_island` vs `native_screen`), no offline mutation contract, no typed versioned denial vocabulary, no doctor that cross-checks router and manifest. Turbo-centric JS side (Stimulus) is awkward for LiveView apps [MEDIUM, my inference]. |
| **LiveView Native** | GitHub repo `liveview-native/live_view_native` **archived by owner 2026-02-10, read-only**; README referenced `0.4.0-rc.1`, no stable release shown. No announcement found. [HIGH on archive, LOW on reasons] | It was the "Phoenix to native" answer; Crosswake explicitly refuses the "LiveView drives native rendering" idea. | n/a (dead). | Its archival removes the only first-party Elixir "native from Phoenix" option. Crosswake's thesis ("not LiveView-driven native rendering") is vindicated, but the **market signal is also cautionary: a well-funded Elixir mobile effort stopped**. |
| **Mob** (hex `mob`) | Elixir framework running BEAM on device; LiveView mode wraps a local on-device Phoenix endpoint in WKWebView/WebView; native `~MOB` screens render through Compose/SwiftUI. Version 0.9.x on hexdocs, README says early-stage / not production [MEDIUM] | Different bet: on-device server. | Real offline (server is local), hot code push over distribution. | Server-authoritative Phoenix app unchanged; no on-device BEAM, review-risk and size cost; Crosswake keeps the server as authority. Mob is a *threat* only if "offline" is the buying criterion and BEAM-on-device matures. |
| **elixir-desktop** | MIT, README marks desktop and iOS/Android "complete" via example repo, JSON/TCP bridge; roadmap shows installers, signing, auto-update unfinished; maintenance recency not verifiable from the page [MEDIUM] | On-device BEAM + LiveView-in-webview. | Fully local app. | Same as Mob: Crosswake targets apps whose truth is on a server. |
| **Capacitor / Ionic** | `server.url` is documented as "**not intended for use in production**"; default model is bundled `webDir` assets [HIGH, capacitorjs.com/docs/config] | Generic web-in-shell + plugins. | Plugin ecosystem, store familiarity, large hiring pool. | A LiveView app *requires* a server; Capacitor's blessed model is bundled static assets, so a LiveView-on-Capacitor shell sits in the documented-discouraged lane. Crosswake's manifest-first activation is the opposite design: server origin is the declared norm. |
| **Expo / React Native** | Expo "DOM components" run web React in a WebView; SPA only (no SSR); remote websites require a manual `react-native-webview`; async JSON bridge [HIGH, docs.expo.dev] | Incremental web-in-native. | Real native UI breadth, OTA updates, enormous ecosystem. | Needs a JS rewrite of the product; does not reuse server-rendered LiveView. Crosswake is the "don't rewrite" choice. |
| **Tauri 2 mobile** | Supports iOS/Android, system webview, Rust core, Swift/Kotlin plugin bindings; maturity not stated on the page [MEDIUM] | Webview shell with plugin bridge. | Small binaries, Rust ecosystem. | Rust+JS stack mismatch for a Phoenix team. |
| **Flutter** | (Not re-fetched; general knowledge, MEDIUM) add-to-app, platform channels | Embedded runtime, bridge. | Pixel-consistent native UI. | Rewrite; no Phoenix integration. |
| **PWA** | iOS support has improved but install friction and storage eviction remain real concerns for B2C [MEDIUM, general; not re-verified for Oct 2026] | The "just don't build an app" alternative. | Zero store friction, zero native code. | No App Store presence, weaker offline durability guarantees on iOS, no native permissions choreography. |
| **Apple App Store 4.2** | "Your app should include features, content, and UI that elevate it beyond a repackaged website." [HIGH, Apple review guidelines] | Applies to *every* WebView-shell approach. | n/a | Crosswake's native-owned shell, route-owner manifest, and offline island are *evidence for review*, but **no guide tells an adopter how to present this to App Review**. Gap. |
| Elixir Forum threads (2021 to 2023) | Recurring asks for "turbo-ios for LiveView", skepticism about wrappers, claims LiveView cannot do offline [LOW, dated] | Validates demand for exactly Crosswake's shape. | | |

### Where Crosswake is genuinely differentiated (keep investing)

1. **Per-route runtime ownership as a checked contract** (router metadata to manifest to shell activation to doctor). No competitor expresses `live_view / cached read-only / offline_island / native_screen` as an owner declaration with compile-time and doctor enforcement.
2. **Honest offline claims**: cached read-only is explicitly not local mutation; one study island is explicitly not generic sync. This is rare and valuable and matches what P5/P6 want.
3. **Fail-closed typed denials** (`route unavailable`, `shell_unreachable`, `pack_incompatible`, `conflict requires attention`). Competitors degrade silently or throw bridge errors.
4. **Phoenix-first, server-authoritative**: the product stays a Phoenix app. Ejecting is cheap, which lowers adoption risk for P1.
5. **Doctor/proof as product surface** where a team needs to answer "what exactly breaks on a real device?". Differentiated in *idea*; the execution has a vocabulary-bloat problem (Section 5).
6. **Privacy-scoped offline replay** (opaque scopes, partitioned outboxes, redacted diagnostics). Strongest differentiator for P6; under-surfaced.

### Where Crosswake is weaker (admit it)

- Maturity, adoption, community: one adopter (parked), one maintainer.
- iOS-only in practice today (Android currently at its generator/JVM posture, being unfrozen). A team needing both platforms cannot choose Crosswake until Android reaches a proven device path; see Section 4a.
- No native-feel navigation story beyond a bounded first-adopter slice, versus Hotwire Native's polished navigation.
- Install path is longer than Hotwire Native's documented getting started (unmeasured; see Section 5).
- App Store review guidance absent.
- No proof anyone but the author can complete the path.

### What Crosswake must never try to become

React Native for Phoenix; a universal UI framework; LiveView-driven native rendering (LiveView Native's archival is a warning, not an opening); a generic plugin/capability bus; a generic sync engine or background-sync promise; an on-device BEAM (Mob/elixir-desktop territory); a commerce/auth provider SDK; an Android-parity effort; a hosted dashboard; a brand/showcase business. These are already in AGENTS.md; this research confirms none of them has a competitor gap worth the cost.

### Steelman: "nobody needs this" and "just use Hotwire Native or Capacitor"

Strongest forms, then verdicts.

1. *"Hotwire Native already does server-rendered-web-in-native with bridge components and path config, with a 37signals-sized community, and nothing in LiveView prevents using it."* **Partly true.** For online-only routes with a few native affordances it likely is the faster path, and Crosswake should say so in a comparison page. It is not the answer for honest offline mutation with scoped replay; Hotwire Native has no offline contract. **Verdict: Crosswake's justification collapses to the offline island plus governance. If P1's offline island is dropped, so is the reason to adopt.**
2. *"A PWA covers B2C offline."* **Partly true** on Android and desktop; weaker and riskier on iOS for durability and App Store presence. If the adopter's customers are fine with an installed PWA, Crosswake has no deliverable (ADR already admits this for Alpha).
3. *"The market is a few hundred Phoenix teams, and LiveView Native's archival shows it does not pay."* **True as a risk.** This is why the ADR treats Crosswake as infrastructure, not a business line. Do not contradict it.
4. *"Governance (denials, doctor, labels) is what teams skip."* **Plausible.** Governance only sells after an incident. Therefore the first-run experience must deliver a visible win (an iPhone route running) before it teaches governance.
5. *"The proof/label regime is overhead that outweighs the product."* **Currently the most credible critique** (78 label mentions across guides and README; phase numbers in 14 public guides). Fixing this is cheaper than any feature.

**Net:** Crosswake is *useful if scoped to P1* and *at risk of being overbuilt relative to a single adopter*. The roadmap should therefore **bias toward making the P1 path measurably short and measurably honest**, not toward breadth.

---

## 5. Onboarding sanity check (newcomer walk: README to guides to generators to doctor to example host)

### Walk and friction (concrete, with evidence)

| # | Step | Finding | Severity |
|---|------|---------|----------|
| 1 | GitHub landing / repo root | Tracked scratch files at repo root: `fix_bridge_tests.swift`, `fix_generator_test.py`, `fix_pbxproj.py`, `fix_public.py`, `fix_public2.py`, `fix_published.py`, `gen_manifest.exs`, `patch_activation_coordinator_tests.py`, `test_subclass.swift`, `update_main_activity.sh`, `update_pbxproj_for_spm.py`, `update_swift_access.py`, plus a `crosswake-checkpoint-*.bundle` git bundle (13 files; confirmed via `git ls-files`). Also `SETUP.md` at root is a **maintainer credential-provisioning runbook** (Sonatype, GPG), named like a getting-started file. First impression: unfinished and confusing. | High (cheap) |
| 2 | README "Integrating Crosswake" | Tells the newcomer to run `bash script/verify_phase5_example_hosts.sh`. That script lives in the Crosswake repo; the Hex package ships only `lib priv mix.exs README.md LICENSE CHANGELOG.md guides` (`mix.exs` package files). A host developer cannot run it. `guides/install.md` Step 4 repeats it. **As written, the documented install path has a step that cannot work from a normal host.** | High |
| 3 | README integrating block vs install.md | README block is `install, doctor, gen.shell ios, gen.shell android, doctor --native-checks`. It omits: declaring a policy route, wiring the bridge hook (layout import, `LiveSocket` hooks, `<div id="crosswake-bridge">`), esbuild `--external:/crosswake/* --format=esm`, `Crosswake.Bridge.attach/1`, and the `:crosswake, :ios_host` config that production iOS generation requires. The "Current answer" blocks read complete but are not. | High |
| 4 | install.md length and phase leakage | 325 lines; Step 1, Step 1b, Step 2... plus a ~150-word single paragraph of internal phase numbers ("Phase 55 handoff ticket...", "Phase 56...", "Phase 57...", "Phase 58...") at line 289. Internal planning history is leaking into public guides: Phase N references appear in 14 guides. | Medium |
| 5 | Attach footgun | `Crosswake.Bridge.push/3` raises `NotMountedError` until `attach/1` is called. Docs frame this as "every adopter hits it exactly once". That is a known first-run failure by design. The route id is known to the router for the matched route, so "never guesses a route id" does not obviously require a manual `assign` of both manifest and route id on every route. | Medium (design spike) |
| 6 | First route on a real iPhone | Requires: `:ios_host` config (router, absolute **HTTPS** origin with no example host, entry route, two distinct bundle IDs, signing team), `MIX_ENV`-aware generation, Xcode build, signing. Loopback origin is Simulator-only and "reported as not production-ready"; a physical iPhone cannot use loopback. I did not find a documented "expose your dev server to a physical phone" recipe in the files I read (not exhaustively verified). Time-to-first-iPhone-route is therefore plausibly measured in days. | High |
| 7 | Doctor | Good: auto-discovers router via install manifest, stays green with native `not_claimed`, honest about best-effort hook grep. Friction: `troubleshooting.md` still tells people to pass `--router Elixir.YourAppWeb.Router` for nearly every finding, contradicting README's "doctor discovers the router". Troubleshooting indexes 11 finding codes; doctor has many more checks (I did not enumerate; unverified bijection). Doctor JSON contains route patterns (privacy note exists; good). | Medium |
| 8 | Concept load | Newcomer must absorb: 6-rung runtime ladder, 3 adopter profiles, 6 owner decisions with 4 "truths" each, 11 support-truth labels, 4 "rebuild" change classes, `family` vs wire `command` capability vocabularies plus a permanently-accepted legacy dotted form, host-owned vs library-owned, packs vs transfers vs sync seams, 5 companion packages (`rulestead`, `rindle`, `sigra`, `chimeway`, `threadline`) with no guidance on whether a first adopter needs any. | High (vocab) |
| 9 | Docs volume | 30 guides, 6,604 lines. README links ~14 from "Choose your path". No single "your first route on iPhone in one page" page. `see_it_run` is the best newcomer artifact (one command + Docker, showcase hub) but it demos the *checked-in* host, not "your" host. | Medium |
| 10 | Naming inconsistency between doc sets | Adopter profiles: *Phoenix SaaS Portal / Selective Native Flow / Local-First Study Flow*. Showcase hub lanes: *SaaS/Admin, Field Service, Learning/Training*. Same ideas, two vocabularies. | Low-Medium |
| 11 | Example host README | Final sections contain tautologies ("Supported behavior is strictly bound to the typed boundaries."; "Deferred behavior is omitted entirely until it can be proven.") that read like template filler. This is the repo's own recurring "absence scored as success" pattern applied to docs. | Low-Medium |
| 12 | Mix task namespace | 24 task modules ship in the Hex package. About half are maintainer/release/proof tooling (`closeout.verify` (un-namespaced), `release.candidate/gate/receipt/status`, `bump_template_version`, `docs.sync`, `adoption_context.scan`, `contract.gen`, `proof_lane.*`), visible to every adopter in `mix help`. | Medium |
| 13 | Claims honesty | Strength: README states "Blocked: sanitized route policy and signed-device proof are required before this host can be promoted." That honesty is a differentiator; keep it. But it means **no public evidence yet that the iPhone path works end to end for any real host** (reference simulator rehearsal only). | Informational |

### Is the API surface right-sized?

| Surface | Verdict | Reason |
|---|---|---|
| Core route metadata (`runtime`, `offline`, `entry`, `security`, `capabilities`) | **Right-sized** | Small, teachable, maps to the one job. |
| Ownership-specific fields (`cache_contract`, `island_contract`, `packs`, `sync`, `transfers`, `gated_by`, `on_unavailable`) | **Right-sized for P1/P5; hide by tier** | Needed for the offline island and native screen; validated at compile time (good). |
| `auth_*`, `commerce`, `notification_open`, `auth_return` route fields | **Oversized for current proof** | No provider/adopter proof; implies support to P4. Freeze and mark "contract only". |
| Bridge (typed, versioned, low-frequency) | **Right-sized** | Matches P5's demands; the attach step is the only wart. |
| Mix tasks | **Mixed** | ~11 adopter-facing (`install`, `doctor`, `gen.shell`, `gen.bridge_hook`, `gen.offline_ui`, `gen.native_controls_ui`, `gen.sync`, `gen.proof_lane`, `inspect`, `demo`, `shell.status`) alongside maintainer tooling. |
| Companion packages (5) | **Oversized for the first-adopter story** | Not needed for one study island; confuses the picture. De-emphasize in README. |
| Proof/support-truth label taxonomy (11 labels) | **Oversized** | Contradicts AGENTS.md's own "prefer one-command host proof over new label taxonomy". |
| Guides | **Oversized** | 6.6k lines; ramp needs a one-page front door. |

---

## 4a. How missing Android affects adoption

- Excludes P7 outright; weakens P2 and P3 (a B2C startup or agency answering "iOS only" loses most deals); does not affect P1 if its public v1 is iPhone-first.
- Competitors both ship Android (Hotwire Native Android 1.3.1; Capacitor, Expo, Tauri, Flutter). Crosswake is the only candidate in the table that is iOS-only in practice, so an evaluator comparing in a spreadsheet drops it on a single row.
- The Android shell exists with generator, Maven and JVM tests, but no device proof or documented first-route path in what I read. "Unfrozen" should mean: adopt the same readiness criteria (C1 to C8) for Android, not port features.
- New criterion C9 below tracks it.

## 6. "Useful framework" criteria and today's grade

Nine measurable criteria (C9 added after the Android decision). "Measured?" says whether a number exists today. Most are not, and that is the primary finding.

| # | Criterion | Target | Today | Grade | Measured? |
|---|-----------|--------|-------|-------|-----------|
| C1 | **Time-to-first-route-on-Simulator** from `mix phx.new` host using published Hex coordinates | <= 30 min, scripted, <= 8 commands | Documented path has a non-runnable step and omitted wiring (friction 2, 3). No clean-room run exists (SEED-004 follow-up). | **D** | No |
| C2 | **Time-to-first-route-on-physical-iPhone** (signed, HTTPS origin) | <= 1 working day, documented end to end | Reference simulator rehearsal retained; physical proof blocked on external gate; no tunnel/staging origin recipe found. | **Incomplete (unproven)** | No |
| C3 | **Zero hand patches** (generated shell and Phoenix wiring work without editing generated or library files) | 0 hand edits besides declared host-owned config | iOS host generation from `:ios_host` declaration is patch-free (v25, credit). Phoenix side requires 3 hand-wired fragments plus esbuild flags plus `attach` per route. | **C+** | Partly (v25 twin) |
| C4 | **Doctor explains every failure**: every doctor finding code has an owner, one first command, and a troubleshooting anchor | 100% bijection, enforced by test | 11 indexed codes; bijection unverified; inconsistent `--router` advice. | **B-** | No |
| C5 | **Clean-room reproducibility from published packages** (path-dep rehearsals cannot catch published-core resolution; documented lesson) | CI job from Hex/SwiftPM coordinates passes install, doctor, `gen.shell ios --check`, simulator build | Example hosts are checked-in public-coordinate proof, not a fresh `phx.new` host. | **D** | No |
| C6 | **Docs ramp**: README to first success in <= 3 clicks; zero internal "Phase N" or unexplained labels on the ramp | zero-leak lint passes | Phase refs in 14 guides; 78 label mentions; no one-page first route guide. | **C-** | No |
| C7 | **Offline honesty and privacy evidence**: scoped replay, fail-closed logout/switch, no payloads in telemetry, proven on a physical device | automated device assertions, privacy scan clean | Contracts and redaction strong (B+); physical-device evidence pending external gate. | **B+ contract / incomplete device** | Partly |
| C9 | **Android parity of the contract**: same one-command proof, denial vocabulary, shared contract vectors, and a device path as iOS | Android passes C1, C3, C4 and a device smoke run | Generator, Maven and JVM vectors exist; no device proof or first-route guide; positioned as frozen. | **D** | No |
| C8 | **Upgrade clarity**: doctor names the change class and rebuild obligation | every compat finding names class and action | Four change classes documented; v14 work addressed protocol drift. | **B+** | Partly |

**Overall readiness grade: C.** Strong contracts and honest claims, weak newcomer path, no measurement. This is fixable with mostly docs and one harness, no new product surface.

---

## 7. Keeping persona alignment over time

Opinionated and cheap, in order:

1. **One persona/JTBD file as a citation target** at `.planning/PERSONAS.md` (distilled from Section 3 of this doc; about 1 page). Persona IDs P1 to P6 and job IDs J1 to J5 (J1 first iPhone route; J2 offline island that survives logout/switch; J3 know why it failed; J4 upgrade without surprise; J5 prove it to a skeptic). Each milestone REQUIREMENTS entry carries `Persona/Job: P1/J2` or `Maintainer-infra`. Plan-checker should fail a requirement with neither. This is a documentation convention, not a feature, and fits the existing traceability tables.
2. **A regenerated readiness scorecard** (the Section 6 table), produced by a script (clean-room harness output plus lint counts), committed per milestone. Every roadmap item must name which criterion it moves. This turns "useful framework" into a number that cannot be scored as success by absence (the repo's known failure mode): a criterion with no measurement is graded Incomplete, never green.
3. **Persona-shaped route-inventory fixtures, not persona-shaped apps.** For P2 (SaaS portal with strict auth), P4 (SSO/step-up posture), and P1 (offline island), keep three small fixture routers run through `doctor` and manifest-generation tests. This detects "the roadmap quietly broke a persona" at near-zero cost. **Do not build separate persona host apps** (the ADR forbids kitchen-sink hosts; the example host README already says "do not turn the example host into a kitchen-sink demo").
4. **Digital twin bound to P1 only.** The existing iOS twin (T01 to T10, privacy-safe receipt) is the P1/P5/P6 evidence artifact. Keep it the only twin. Do not make twins per persona.
5. **A persona delta line at milestone close**: one paragraph answering "which persona's job got measurably cheaper, per which criterion?" If the answer is "none", the milestone must be justified as maintainer-infra or protecting a contract, explicitly.
6. **Re-entry gate**: when the adopter lane resumes, P1 stops being a proxy and becomes a real user; re-run this document against that experience before touching P2/P3.

---

## 8. Ranked recommendations

Horizon: immediate (next milestone start), near (this milestone or next), mid, long. Effort: S (hours), M (a phase), L (multi-phase).

| Rank | Recommendation | Horizon | Effort | Persona/Criterion |
|---|---|---|---|---|
| R1 | **Fix the install path lies**: remove or replace `bash script/verify_phase5_example_hosts.sh` from README "Integrating" and install.md Steps 4 and 5 with a command that exists in a normal host; add the omitted wiring (bridge hook, esbuild args, attach, `:ios_host`) to the README block or a single linked "first route" page. | immediate | S | P1; C1, C6 |
| R2 | **Repo-root hygiene PR**: delete or move the 12 scratch scripts and the checkpoint bundle; move `SETUP.md` to a maintainers doc directory; confirm none is referenced by CI before removal. | immediate | S | P5; C6 |
| R3 | **Create `.planning/PERSONAS.md` plus requirement citation rule** and retire the stale root JTBD memo's ordering explicitly as "not executed". | immediate | S | all; alignment |
| R4 | **Clean-room harness** (SEED-004): scripted `mix phx.new` host, from published Hex and SwiftPM coordinates, install, declare one route, doctor, `gen.shell ios --check`, simulator build; emits timings and pass/fail. Runs on demand first; promote to CI only when stable (AGENTS.md rule). | near | M-L | P1/P5; C1, C3, C5 |
| R5 | **Doc ramp rewrite**: one-page "Your first route on iPhone Simulator", README restructured so the first screenful answers "what, for whom, when not", move label taxonomy behind the Proof section, strip "Phase N" references from public guides, add a docs lint (zero phase leaks on the ramp, nonempty-scope assertion to avoid vacuous green). | near | M | P1/P2/P5; C6 |
| R6 | **Doctor to troubleshooting bijection test**: enumerate finding codes from the doctor source, assert each has an owner, first command, and anchor; fix `--router` inconsistency. Measure findings before making it merge-blocking (repo lesson). | near | M | P1/P5; C4 |
| R7 | **Design spike: auto-attach from router metadata** (derive manifest and route id on `on_mount` for routes that declare bridge capabilities), or a doctor static check for `push` without `attach`. Spike only; must not weaken fail-closed `NotMountedError`. | near | S-M | P1; C3 |
| R8 | **Tier the policy DSL in docs** (Tier 1 core; Tier 2 owner-specific; Tier 3 "contract only, no provider/adopter proof": `auth_*`, `commerce`, `notification_open`). No new fields. | near | S | P4/P5; surface size |
| R9 | **Mix task hygiene**: rename `closeout.verify` into the `crosswake.` namespace, mark maintainer tasks `@shortdoc` "maintainers:" or hide from `mix help` via `@moduledoc false` where appropriate, keep adopter tasks first. Check compat: renaming is breaking for any current caller; keep an alias for one release. | mid | S-M | P2/P5 |
| R10 | **"Crosswake vs Hotwire Native, Capacitor, PWA, Mob" honest decision page**, including "when not to use Crosswake" and how to explain the shell to App Review (guideline 4.2). | mid | S | P1/P2/P5 |
| R11 | **Persona-shaped fixture routers** (P1 island, P2 strict-auth SaaS, P4 step-up posture) under doctor and manifest tests. | mid | M | P2/P4; alignment |
| R13 | **Unfreeze Android through the same gates**: after R4, build the Android clean-room lane and a device smoke path, write the Android first-route guide, and extend the doctor/troubleshooting bijection to Android findings. Contract parity, not feature parity. | near to mid | L | P7/P2/P3; C9 |
| R12 | **External newcomer trial** (agent-run clean-room is the default gate; one friendly non-author Phoenix developer only if you want social proof). Do only after the adopter lane is active again. | long | M | all |

---

## 9. Explicit "do NOT do" list

1. By default do not add native menu/action breadth, capture/device packs, new companions, commerce productionization, notification corridors, a dashboard, brand/showcase polish, generic or background sync, or generic native storage. These stay deferred **until a synthetic adopter profile produces evidence of a real gap (Section 9a)**. The stale memo's items 1, 2 and 5 are retired as ordered, but not banned: they reopen only through 9a.
2. ~~Do not add Android features...~~ **Reversed by user decision:** Android is unfrozen. Do NOT instead: promise Android parity before an Android device path is proven; copy iOS-specific proof labels onto Android; or let Android work start before the iOS clean-room harness (R4) exists, since Android would inherit the same unmeasured onboarding.
3. Do not build per-persona host apps or per-persona twins.
4. Do not add provider SDKs or SSO/OIDC/MFA templates to chase P4.
5. Do not extend the policy DSL (no new route fields) before the newcomer path is measured.
6. Do not create new label taxonomy; consolidate instead.
7. Do not market to agencies/enterprise or publish a "Crosswake vs X" page that claims superiority on dimensions (maturity, plugins, navigation feel) where Crosswake is weaker.
8. Do not build an on-device BEAM or "write once" mobile story; do not respond to LiveView Native's archival by reviving native rendering.
9. Do not make the new lint or clean-room checks merge-blocking before measuring their findings on current `main` (repo lesson: "absence scored as success").
10. Do not name, infer, or link the real first adopter in any persona, scorecard, or fixture.

---

## 9a. Reopening stop-list items via synthetic adopter profiles

User decision: synthetic adopter profiles may reopen stop-list items when evidence shows a real gap. To keep this from becoming the old unbounded generalization, use this gate:

1. A **synthetic adopter profile** is a written persona-job scenario (P1 to P7) plus a route inventory fixture and a scripted journey run through the clean-room harness (R4), never a full app.
2. A stop-list item reopens only when the profile's scripted journey **fails a readiness criterion for a reason that item would remove**, with the failing artifact (doctor output, receipt) cited. "A competitor has it" or "a persona would like it" is not evidence.
3. Reopening is recorded as an ADR amendment (item, profile, failing criterion, evidence, exit condition) and the item is scoped to the smallest slice that clears that criterion.
4. Candidates most likely to pass the gate, ranked by my read: (a) **Android device path** (already approved), (b) **notification-driven re-entry** (P2; push and deep links are table stakes for B2C), (c) **auth return / session authority proof for one provider-neutral flow** (P4, and P1 account-switch), (d) native navigation breadth beyond the first-adopter slice (P5). Commerce, capture packs, dashboard and generic sync have no persona evidence today and should stay closed.
5. Synthetic profiles must carry no real customer details (codename rules still apply).

## 10. Decisions only the user can make

0. **ADR and AGENTS.md update.** Two accepted decisions are now contradicted by the user's latest direction: "v21 is an iOS-only adoption milestone / Android frozen" and the stop-list-without-reopening rule. Confirm the ADR amendment wording (Android order relative to iOS physical proof; the 9a gate) and land it through a PR so docs and guides stay consistent ("update together when a decision changes").

1. **Public posture while the adopter lane is parked.** The user said they are not yet ready to use it on their own projects, and the public README and Hex package are live. Choose: (a) keep the public surface minimal-but-honest (recommended; do R1, R2, R5 only), or (b) invest in public newcomer experience beyond that (conflicts with the ADR's infrastructure framing unless the reversal condition is met).
2. **Approve R2 (deleting tracked files and moving SETUP.md).** It lands as a PR with CI green and needs the usual `allow` gate for merge; the bundle file might be the only copy of something, so confirm before removal. `SETUP.md` also contains a maintainer contact string in a key-generation command; decide whether that stays public.
3. **Mix task renames (R9) are user-visible breaking changes** for anyone already depending on `mix closeout.verify` or `release.*`; decide whether the alias grace period is worth the clutter.
4. **Whether `auth_*`, `commerce`, `notification_open` route fields stay in the public DSL** as "contract only" (recommended) or get deprecated, which is a compatibility decision.
5. **Whether the clean-room harness (R4) is allowed to be a recurring CI lane** or stays phase evidence. AGENTS.md says only promote recurring-contract checks; this one protects "published-package resolution" (a recurring defect class), so I recommend CI, but only after two clean runs.
6. **Whether to attempt any outside human trial** at all before the adopter lane resumes. Default: no.

---

## 11. Gaps and what is unverified

- Onboarding was walked statically; no timings. Confirm friction items 2, 3, 6 by running R4's harness first.
- I did not enumerate doctor finding codes against `troubleshooting.md` (C4 grade is an estimate).
- I did not verify whether a physical-iPhone dev-origin (tunnel/staging) recipe exists beyond the files read.
- Competitor currency: LiveView Native archival is confirmed on its repo page but the reason and any successor are unknown; elixir-desktop and Mob maintenance recency are not verified; PWA iOS capability status for Oct 2026 was not re-verified; Flutter and Tauri maturity not deeply checked.
- Whether Hotwire Native works cleanly with LiveView navigation is my inference, not a tested fact; if the user cares, a one-hour spike would settle it and would sharpen the R10 page.

## Sources

- Hotwire Native overview (iOS 1.3.0, Android 1.3.1, bridge components, web-first guidance): https://native.hotwired.dev/ and https://native.hotwired.dev/overview/bridge-components (HIGH)
- Hotwire Native path configuration reference: https://native.hotwired.dev/reference/path-configuration (HIGH)
- LiveView Native repository (archived 2026-02-10, read-only): https://github.com/liveview-native/live_view_native (HIGH on archive status; no announcement found)
- Mob LiveView mode docs: https://mob.hexdocs.pm/liveview.html and hex package listings (MEDIUM; pre-1.0, README states early-stage)
- elixir-desktop: https://github.com/elixir-desktop/desktop (MEDIUM; recency unverified)
- Capacitor configuration (`server.url` not intended for production): https://capacitorjs.com/docs/config (HIGH)
- Expo DOM components: https://docs.expo.dev/guides/dom-components/ (HIGH)
- Tauri 2: https://v2.tauri.app/start/ (MEDIUM)
- Apple App Review Guidelines (4.2, 2.5.2): https://developer.apple.com/app-store/review/guidelines/ (HIGH)
- Elixir Forum threads on LiveView mobile (2021 to 2023, LOW): https://elixirforum.com/t/what-is-the-best-easiest-way-to-convert-a-phoenix-liveview-app-into-an-ios-and-android-app/37159 , https://elixirforum.com/t/brainstorming-on-a-mobile-companion-library-for-liveview/49112
- Repo evidence: `README.md`, `AGENTS.md`, `mix.exs` (package files), `guides/install.md`, `guides/route_policy.md`, `guides/adopter_profiles.md`, `guides/native_shell.md`, `guides/troubleshooting.md`, `guides/user_flows.md`, `examples/phoenix_host/README.md`, `.planning/ADR-FIRST-B2C-ADOPTER.md`, `.planning/PROJECT.md`, `.planning/research/JTBD-AND-USER-FLOWS.md`, `git ls-files` for root files, `lib/mix/tasks/`.
