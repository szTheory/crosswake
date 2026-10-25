# v25 DX Research: One Maintainer Path, One Honest Offline Flow

**Scope:** Brief decisions 25–29: maintainer jobs, learner-facing offline states, accessibility, output hierarchy, and appropriate brand use.  
**Baseline:** Public Crosswake source at approved pin `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`; the local recovery checkout is older/dirty, so assertions about shipped behavior are pin-qualified.  
**Confidence:** High for established Phoenix/Mix, Apple, W3C, and Playwright guidance; medium for v25-specific wording until the twin reports actual host outcomes.

## Recommendation

Use one documented maintainer path: declare host configuration, generate/check iOS setup, run the bounded reference study once, and inspect its report. Keep the learner surface to real study actions and accurate status. Do not build demo-control panels or a dashboard. At the checked pin, `mix crosswake.demo` boots the showcase; `mix crosswake.doctor` reports setup/policy/support truth; `mix crosswake.inspect` reports route readiness. Reuse these entrypoints and report conventions. Add only a narrow, distinct scenario command; “demo” must not imply production runtime or physical-device proof.

Phoenix generators are task-named and output host files; local template overrides can need maintenance across upgrades. Igniter offers `--dry-run`, explicit prompts/`--yes`, and optional examples. Keep `mix crosswake.gen.*`, show destinations/owners, provide diff/check before writes, and finish with the next command. The brand informs voice and semantic tokens, not a visual-product program.

## Maintainer jobs to be done

| When / who | Job and inputs | Action | Result they need | Why it matters |
|---|---|---|---|---|
| **Day 0 — Phoenix maintainer, setup** | Host/router, app/test bundle IDs, team/signing mode, production origin, build target. | Declare host config; run generator, diff/check, doctor, and build. | Host-owned scaffold, route-derived manifest/activation, effective settings, output paths, and remaining unproven items. | Avoid manual patching and placeholder-origin binaries. |
| **Day 1 — maintainer, route/origin changed** | Committed config, router, generated project. | Rerun the same generation/check command; inspect diff and build. | Managed outputs update; host edits remain visible; unknown generated files stop with repair steps. | Avoid stale policy and overwritten native edits. |
| **Day 2 — maintainer/operator, failure** | Source revision, scenario, host, tools. | Run finite twin; follow its report’s doctor/inspect action. | Summary counts passed/failed/blocked; report names actual layer, ran observations, failure cause, path, next action—without answers, credentials, account IDs, or config values. | A missing layer remains blocked, not green. |

### Vocabulary and action verbs

Use stable nouns: **Host App**, **route**, **app binary**, **offline island**, **media pack**, **saved review**, **queued review**, **replay**, **server response**, **conflict**, **disabled route**, **twin run**, **observation**, and **report**. Prefer concrete verbs: **declare**, **generate**, **regenerate**, **check**, **build**, **run**, **observe**, **save**, **queue**, **replay**, **accept**, **reject**, **resolve**, and **inspect**. Avoid “sync magically,” “demo success,” “device ready,” and “production tested” unless that exact authority/layer was observed.

## Maintainer path and output hierarchy

Illustrative invocation (final command name should converge with twin architecture):

```sh
MIX_ENV=prod mix crosswake.gen.shell ios --check
mix crosswake.doctor --native-checks
mix crosswake.twin study --report tmp/crosswake-study-twin.json
mix crosswake.inspect --router Elixir.MyAppWeb.Router
```

The setup remains explicit; the twin must not secretly regenerate or alter the host app. `crosswake.twin` and the report path are illustrative names, pending architecture convergence.

Recommended stdout order:

1. **Result:** `Study twin failed: 8 passed, 1 failed, 1 blocked.`
2. **First failure/blocker:** one short, cause-specific sentence and the owner (`iOS simulator`, `reference Phoenix host`, or `backend replay`).
3. **Report:** exact local report path and the privacy-safe summary path.
4. **Next action:** one command or one named host-owned repair.

The structured report should contain source revision, scenarios, observations, outcome, fidelity layer, failures/unavailable checks, and links. Keep raw output local; never include host config or answers in stdout, report, logs, screenshots, or aggregates. Keep failure causes. `failed` means an assertion ran and did not match; `blocked` means required observation could not run; `passed` requires observation. A blocked run is incomplete.

| Surface choice | Pros | Cost / risk | Decision |
|---|---|---|---|
| Documented commands + existing doctor/inspect and source-bound report | Uses familiar Mix tools and existing machine-readable/human reports; low UI maintenance; diffable and CI-usable; can state fidelity and failure cause. | Requires good runbook ordering and concise report. | **Choose.** One bounded twin command plus current diagnostics and one report. |
| Embedded controls in study screen | Learner can perform the actual study actions; twin can use stable accessible controls. | Debug toggles or canned success buttons would contaminate the production route and make a simulated callback look real. | Use only normal study actions (answer, save, replay when online); fault injection stays in test/host adapters. |
| New maintainer dashboard | Persistent status can look convenient. | New auth, UI, data, deployment, accessibility, and privacy surface for a bounded one-run job; competes with route/runtime ownership. | **Defer.** No evidence requires a dashboard. |

## Learner-visible state copy

Keep the user flow separate from maintainer output. The app should show only states backed by durable local or host/backend observations. Keep the answer form available while offline when the offline island owns the route.

| Actual state | Suggested learner copy | Required meaning |
|---|---|---|
| Local save completed; network unavailable | **Saved on this device.** It will be sent when you’re online. | Use only after local persistence succeeds; this is not server acceptance. |
| Outbox has pending records | **Waiting to send · 3 reviews** | Counts are optional; never show payload contents in generic status. Do not call these “synced.” |
| Replay in progress | **Sending saved reviews…** | A transient status, not proof of backend commit. Keep the page usable if possible. |
| Server accepted and local record drained | **Saved to your account.** | Show only after backend acceptance and outbox removal are both observed. |
| Server rejected a review | **The server did not accept this review.** Then state whether it remains saved and give the actual host-owned next action. | Do not disguise rejection as retry success; retention semantics must be explicit. |
| Conflict returned | **This review needs attention. Your offline version is still saved on this device.** `Review` | Use “still saved” only when the host/local store confirms retained work. Do not imply last-write-wins. |
| Route or replay disabled | **Study is temporarily unavailable. Your saved reviews are waiting and won’t be sent while study is disabled.** | Keep queued work; show retained count if available; do not imply entry denial discards it. |
| Required pack missing/corrupt | **Audio isn’t ready for offline use. The study pack must be verified before this lesson can open offline.** | The lesson stays unavailable until size/hash verification and atomic install pass. |

This vocabulary follows the existing offline guide’s separation of `cached read-only`, `saved locally`, `queued for replay`, `replay failed`, and `conflict requires attention`. It reflects the governing privacy and replay rules: Phoenix authorizes replay, scope partitions the outbox, and logout/account switch fences replay. It must not imply that a generated activation fixture contains user/session authorization: generated activation output should contain static route/runtime facts only. It must not invent an account, session, scope, or replay permission. **Open question for synthesis:** the Generation report describes one configured primary origin. A host may need additional explicit allowlisted auth/media origins; deciding whether one primary origin plus a closed host-owned allowlist is required is unresolved. Do not silently broaden origin matching.

## Accessibility and performance: only what the states need

- **Status and assistive tech:** pair text/icon with color; use polite `role="status"` updates without moving focus, semantic controls and visible focus. A blocking conflict has an announced status and named `Review` action. Playwright should select by role/name and assert actual state.
- **Touch and layout:** use 44×44 pt iOS hit regions for key actions. Queued counts/recovery controls reflow at narrow widths and larger text.
- **Theme/contrast:** follow canonical semantic tokens and system light/dark; no per-app theme selector. Light `text.muted` uses Stone 600 (4.53:1 on Foam 50); Stone 500 is limited to disabled/decorative/large text; Wake 500 is not normal light text. State labels accompany color.
- **Focus, motion, performance:** preserve the 2px focus ring and keep it unobscured. No celebratory sync animation; reduce any transition for `prefers-reduced-motion`. Show local-save feedback immediately after persistence, replay only under the current foreground authorization, and avoid polling/network waits before showing saved work.
- **Audio:** play only verified installed media; state missing/corrupt denials in text. No autoplay, background playback, or new audio breadth.

These checks directly support the one offline flow and generated report; they are not a new accessibility audit or brand sprint. The current canonical brand spec (ratified v1.0) supersedes the old prompt book. Carry its calm, precise, task-first wording and semantic tokens forward; do not reopen logo, typography, animation, or showcase work.

## Learner copy versus maintainer detail

Learner copy says what happened to this person’s work and what they can do now: “Saved on this device,” “Waiting to send,” or “Review.” It does not expose route IDs, protocol versions, build hashes, SQL errors, or internal denial taxonomy.

Maintainer detail names the exact owner and layer: route ID and runtime owner, pack verification result, manifest/source revision, replay outcome, test destination, failure stage, and report path. It excludes answer/media payloads, transcripts, credentials, account identifiers, tokens, stable device identifiers, and raw values from private config. Use a run correlation reference only if it is random and one-run scoped; it must not become a stable device/account identifier.

## Gaps and limits

- The pinned `mix crosswake.demo` is a showcase boot wrapper, not an automated offline-study twin. Its documentation must not call it a full iOS demonstration. The twin command/name remains an integration choice for the other research reports.
- Current learning example UI at the inspected pin is illustrative local state and is not the real offline mutation/replay authority. Do not present it as real backend or device evidence.
- No copy should claim “server saved,” “all synced,” or “account scoped” until the observation producer proves those conditions.
- Bundle/origin/settings privacy and generated-file behavior are owned by Generation research; this report raises only the possible explicit auth/media-origin allowlist conflict and static-only activation boundary.
- Do not expand to a dashboard, broad polished demo, additional learner feature, background sync, generic account recovery UI, Android, new native control, or product/brand program.

## Proposed v25 DX acceptance additions

1. One first-run path identifies its inputs, generated paths and owners; `--check`/`--diff` precede managed writes and the guide ends with one exact next command.
2. A single finite twin invocation produces a privacy-safe summary that names passed/failed/blocked scenarios, actual observation layer, source revision, report path, failure cause, and next action. Missing observations cannot pass.
3. The learner flow demonstrates only ordinary study actions and state copy that matches persistence, replay, backend acceptance/rejection/conflict, retained queued work, feature disablement, and verified media availability.
4. The bounded UI uses semantic labels/status announcements, visible keyboard focus, color-independent state text, 44 pt iOS main controls, system light/dark, large-text reflow, and reduced-motion behavior for any transition it adds.
5. No maintainer detail or sensitive payload enters learner copy or public proof; no dashboard, demo-only production toggle, or synthetic success path is introduced.

## Sources

- [Phoenix Mix generators: task names, generated host files, local template overrides](https://phoenix.hexdocs.pm/Mix.Tasks.Phx.Gen.html)
- [Igniter installer task: dry run, prompts, and optional examples](https://igniter.hexdocs.pm/Mix.Tasks.Igniter.Install.html)
- [Playwright locators: role and accessible-name selectors, auto-waiting](https://playwright.dev/docs/api/class-locator)
- [Apple HIG Buttons: 44×44 pt hit region and press feedback](https://developer.apple.com/design/human-interface-guidelines/buttons)
- [Apple HIG Dark Mode: respect system appearance and preserve contrast](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- [Apple HIG Motion: purposeful, optional, brief motion](https://developer.apple.com/design/human-interface-guidelines/motion)
- [Apple accessibility testing: system accessibility settings including Reduce Motion](https://developer.apple.com/documentation/accessibility/testing-system-accessibility-features-in-your-app)
- [W3C WCAG 2.2 overview: status, focus, target-size, contrast criteria](https://www.w3.org/WAI/WCAG22/Understanding/)
- [W3C Understanding WCAG 4.1.3 Status Messages](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html)
- Crosswake: approved-pin [`README`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/README.md), [`crosswake.demo`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/mix/tasks/crosswake.demo.ex), [`crosswake.doctor`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/mix/tasks/crosswake.doctor.ex), [`crosswake.inspect`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/lib/mix/tasks/crosswake.inspect.ex), [`offline guide`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/guides/offline.md).
- Current design authority: `brandbook/BRAND-SPEC.md` and `brandbook/tokens/crosswake.tokens.json` (ratified semantic tokens supersede the historical brand prompt).
