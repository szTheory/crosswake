# v25 research synthesis: iOS setup and a bounded reference twin

**Status:** researched recommendation; milestone requirements/roadmap remain proposed. No implementation, merge, publication or adopter promotion occurred.
**Research date:** 2026-10-13.
**Production source inspected:** `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, read through pinned public GitHub source. The protected recovery checkout is a different source and was not treated as production truth.

## Recommendation

Keep the two-phase milestone: **179, iOS Host Setup Without Hand Patches**, followed by **180, Bounded Digital Twin Demonstration**. Repair the supported generation path, then join existing components through one real, visible reference flow. Reuse the Phoenix host, offline-island browser corpus, native pack provider, registered host-command seam and iOS adapters. Do not build a second host or a mobile testing platform.

The highest-value missing proof is the composition: **generated candidate → visible WebView study action → actual local persistence/host media adapter → normal Phoenix replay → durable Ecto effect**. Separate green browser and native tests do not establish that chain. Existing Simulator Safari rehearsal remains useful browser evidence; it is not generated-shell evidence.

This is an investment in removing hand patches and demonstrating one adoptable path. The release/cleanup debt retained at v24 does not become this milestone's work queue.

## Selected generation design

Use one host-owned declaration in ordinary Phoenix/Mix **build-time config**. The Mix task reads a normalized closed configuration and passes it into the generator; core generation functions do not consult global application state. `MIX_ENV` selects the ordinary host config. Do not add a second config-file DSL or lasting CLI source of truth.

The generator requires compilation of the host router, **not `app.config` or `app.start`**. `app.config` evaluates `runtime.exs` and can demand production database/secret-key values before any native files are generated. A minimal real Mix experiment confirmed this: the runtime-config task failed on a deliberately absent runtime variable; the compile-only task read build-time configuration, exited zero and did not start the app. See [experiment](build-config-experiment.json) and [resolution](CONFIG-LOADING-RESOLUTION.md). This validates the Mix lifecycle only, not a full Phoenix/Xcode generation.

The declaration owns router, primary origin, entry route, bundle/test identity and device signing settings. Private host values can be injected by host-controlled build environment/local configuration; do not commit adopter identity into Crosswake fixtures or emit it through diffs, diagnostics or receipts. Simulator generation/checks require no Apple credentials. Missing device configuration remains a clearly named device-setup limitation.

Preserve existing local/dev invocation and documented compatibility. Production generation becomes explicit and fail-closed. `--check` observes without writing; `--diff` reports paths/fields and ownership conflicts without exposing private values. Routine flags must not silently override declared production inputs. Exact public key spelling belongs in the Phase 179 interface contract; the selected authority/precedence does not.

Refresh only recognized Crosswake-managed manifest, activation and build-setting projections. The host owns its config, Swift, entitlements and Xcode project edits. Initial generation wires the project to the managed settings; existing projects need a documented opt-in migration, not arbitrary project rewriting. Validate inputs, ownership and every intended destination before writes. Stage outputs, use per-file atomic replacement, and detect/recover an interrupted multi-output update; a partially updated generation must never report success or pass the build check. Do not promise a filesystem-wide atomic transaction from several independent renames.

Use `.xcconfig` for identity/signing settings, with explicit unsigned simulator and device-capable modes. Inspect effective app/test target settings for both SDK classes and relevant configurations. Higher-precedence hardcoded project settings can mask xcconfig values; the project hook and tests must catch that. Exclude xcconfig from bundled resources. Keep origin in canonical manifest JSON, not an unescaped xcconfig URL (`//` is a comment delimiter). Settings inspection establishes wiring, not physical installation or signing-asset availability. [Apple configuration files](https://developer.apple.com/documentation/xcode/adding-a-build-configuration-file-to-your-project/) support this separation.

Build the manifest through the existing route compiler/builder from the selected host router. Derive static activation from a declared valid entry route and the same primary origin. Reject placeholder or malformed production origins before effects. Generated activation contains no session, account, scope, credential or replay grant.

**Keep three origin policies separate:** primary route/bridge navigation authority; host-owned authentication continuation; host-owned media acquisition. Auth/CDN origins do not become route bridge allowlists by implication. The reference twin uses its configured primary host. No SSO/CDN expansion is selected; an actual distinct origin need is an explicit host dependency, not permission to relax same-origin checks.

## Selected twin architecture and media owner

Keep fast ExUnit/Plug/Ecto/Swift contracts and the existing real Phoenix/Playwright corpus. Add one generated-candidate iOS simulator composition for the missing joins. Avoid replaying every test across three runtimes merely to produce symmetrical counts.

The simulator must launch the generated app and observe its **visible** study WebView, matching bridge controller and correlated reply. A hidden WebView, Safari launch, unrelated native test, or test-only direct callback cannot satisfy this observation. The app's normal island writes the outbox and triggers replay; the backend independently observes the real transaction and duplicate effect.

For audio, prefer the existing **host-owned native playback boundary**, initiated by the visible offline-island user action. The existing registered `HostBridgeCommandDelegate` supports route-declared `host.*` commands; the reference host needs narrow wiring for its study audio action. The host verifies the installed pack/asset and plays through its own AVFoundation adapter. Require the normal user action, correlated command/reply, active-route authorization, installed byte identity and observed player progress under target-scoped network denial. A separate AVAudioPlayer test does not prove this chain.

This corrects the earlier specialist recommendation that WebKit itself must decode native installed files. The user workflow can belong to the island while the native host owns playback. Do not add a generic file URL/scheme service, storage API or public core audio capability. If the existing declared host-command path cannot support the composition safely, report the missing seam and stop before broadening core. See [media resolution](MEDIA-OWNERSHIP-RESOLUTION.md) and the pinned [delegate](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift).

## Finite scenario roster

These are ten **scenario groups**, not the separate physical contract's assertion count. Each group declares its required observation owners; all required observations must run and pass. Cold boot, primary origin, installed build/asset identity and same visible WebView/bridge are setup preconditions, not extra scenarios. Do not substitute another ten-row list.

| ID | Scenario | Required observation |
|---|---|---|
| T01 | Install one reference pack online | Exact size/hash verification, atomic installation and installed-byte readback |
| T02 | Enter authorized study and go offline | Actual visible generated-app route, declared synthetic test authority, verified target-scoped network failure |
| T03 | Save selected and free-form answers offline | Normal UI interaction and durable local outbox observation; no payload retained |
| T04 | Play installed audio; deny missing/corrupt media | Visible island action reaches the host player with verified bytes; dependent entry/playback fails closed for faults |
| T05 | Terminate/relaunch without reset | Same installed app and persistent WebKit store retain local work across actual process termination |
| T06 | Reconnect and replay exactly once | Normal app HTTP path, independently observed Ecto effect, duplicate delivery adds no effect, empty outbox |
| T07 | Recover rejection/conflict | Server-backed outcomes retain work and show appropriate recovery, not client-canned success |
| T08 | Logout/account switch | Old-scope replay is fenced before a different scope can act; no cross-scope backend effect |
| T09 | Disable entry/replay | Both denials are exercised and queued work remains retained |
| T10 | Inspect safe source-bound results | Complete observation roster; wrong source, missing/fabricated observations and sensitive fields are rejected |

Existing browser/backend tests satisfy only the observations they actually make. The scenario plan must name which generated-iOS observations establish the previously missing seams. A browser count cannot silently substitute for required iOS persistence or audio observations. Exactly once means one durable domain effect under duplicate delivery, not exactly-once network delivery.

## Isolation, evidence and developer experience

The runner owns a fresh database, exclusive loopback port, exact Phoenix child process, app/test context and private run root. Existing whole-table review cleanup is acceptable only inside that proven run-owned database. Never reuse a default database/server or delete pre-existing rows. Keep Ecto Sandbox for in-process tests; genuine cross-process HTTP uses the owned committed test database. [Ecto Sandbox](https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html) describes the process-ownership boundary.

Network faults are verified at the tested transport, scoped to the invocation. Do not take the laptop offline, infer WebView/native denial from a Playwright toggle, or dispatch an offline event and call it network failure. Fault setup must itself be observed. Preserve the uninterrupted lifecycle; no reset, reinstall or storage-store replacement between offline writes and relaunch/replay.

Use a **small twin-only receipt**, derived from independent observations. It grants no route, replay, support or promotion authority. Preserve the physical schema and its collectors unchanged. Compare expected candidate/dependency, generated input, installed app, loaded JS/media and backend identities with observed identities; copying one declared SHA into every row is insufficient. The receipt contains a closed roster, safe source/runtime data, actual outcomes and residual gates. No private host values, answer/media payloads, credentials, account/scope IDs or stable device IDs. Expected private inputs and execution identities may be compared in memory or held in normal host-owned configuration; they are not copied into proof logs. Public summaries do not expose hashes of low-entropy private identity fields.

Results distinguish executed failures from unmet prerequisites. Any executed failure makes the aggregate failed; otherwise an unavailable required observation makes it blocked; only a complete passing roster makes it passed. A blocked run remains incomplete. Preserve concrete failure causes through closed safe observations and restricted diagnostics that pass the privacy policy before retention; private storage does not exempt payloads from that policy. Disable DOM/network traces, screenshots/video and arbitrary raw result attachments for the sensitive study journey unless a closed safe projection is established. Keep only sanitized cause/result attachments from Xcode, and prevent request-parameter/SQL/console logging of answers, credentials and identity. This narrows specialist suggestions to retain raw traces privately. No retry-to-green or overwritten first failure; if unsafe raw output cannot be retained, say so and do not invent its cause.

One narrow verification command belongs under the existing proof-lane namespace; proposed spelling is `mix crosswake.proof_lane.verify_twin ios`, **not a shipped command**. It consumes the prepared candidate/configuration and owns only its temporary runtime resources. It does not secretly regenerate the maintainer's app. Output leads with result, concrete first failure/blocker, local report path and one next action. Reuse doctor/inspect for diagnostics; no dashboard or demo-only controls in the learner route.

Learner copy describes actual durable state: saved locally, waiting to send, accepted by server, needs review, temporarily disabled. Keep route IDs/build hashes/SQL details out of that flow. Use current semantic tokens, status announcements, accessible names/focus, adequate touch targets, system themes and reduced motion only where needed to operate the bounded flow. [Current brand specification](../../../brandbook/BRAND-SPEC.md) supersedes the historical brand prompt; no polish program is selected.

Promote stable generation/ownership, receipt validation and anti-overclaim regressions into existing relevant CI leaves. Keep the full simulator demonstration local/milestone-scoped unless recurring value and stable actionable feedback are demonstrated. No new reconciliation workflow or device matrix.

## What to prove first and when to stop

1. **Generation feasibility:** actual host compile/config path without runtime/server credentials; effective Xcode app/test settings; preservation/conflict and interrupted-update behavior. The minimal Mix loading question is resolved by experiment; full host/Xcode behavior is not yet executed.
2. **Composition feasibility:** actual generated visible WebView, registered host audio action, verified installed-byte playback and target-scoped network denial. Use one disposable host-owned composition before expanding cases. No generic core protocol/storage repair is authorized.
3. **Bounded demonstration:** execute the ten groups using reused coverage plus missing joins. Repair only reproducible defects in this declared generation/reference composition.

Stop when all required virtual observations pass and remaining uncertainty belongs solely to recorded physical/adopter gates. Also stop for a genuine blocker or a demonstrated need for broader product work, recording incomplete requirements; that is not milestone completion. Reopen only for a concrete new failure or new authorized adopter evidence. No automatic extra phase, seed sweep, cleanup campaign or successor milestone.

## Research convergence and retained uncertainties

Four lenses produced four reports, followed by three focused challenges and two targeted resolutions. The synthesis resolves config precedence/loading, origin separation, media ownership, source joins, receipt ownership, cleanup isolation and the conflicting scenario roster. [Prompt coverage](PROMPT-COVERAGE.md) accounts for all thirteen prompt files and current-brand precedence. The [decision map](ARCHITECTURE.md) connects all thirty enumerated decisions to the selected path.

Remaining questions require actual candidate execution, not more broad research: Xcode settings and migration wiring; interrupted managed-output recovery; generated app/host command and installed-media composition; target-scoped network denial; independent build/asset/backend identity capture. No implementation/runtime success is claimed here. The real adopter remains parked pending its validated route handoff and fresh signed-device proof.

Next workflow position remains `$gsd-new-milestone --ws quality-ratchet-release`, completing scope/roadmap confirmation. Phase 178 is the last completed phase; Phase 179 is proposed and not active.
