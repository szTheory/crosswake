# v20.0 Native Controls Pack 1 — Research Summary

Synthesis of six expert-lens research passes (ground truth, prior art, API design,
release strategy, UX contract, vision coherence). Source documents live beside this
file. This is the decision record the roadmap is built from.

## The reframing

The Phase 152 handoff proposed five controls plus two read-only surfaces. Ground truth
showed that framing double-counted shipped work and under-counted the real cost.

`guides/capability_map.md` scores **proof posture**, not plumbing existence. Milestone
v3.1 (Phases 15-17) shipped working native dispatch for `haptics`, `share`, `app_info`,
`deep_link`, `permissions.status`, `notification_token`, and `file_picker` on both iOS
and Android — verified in the live `BridgeChannel.swift` / `.kt` switch statements. The
capability map lists some of them as v20 candidates only because their *proof* is
advisory.

The real delta is three tiers:

| Tier | Capabilities | Work required |
|------|--------------|---------------|
| Already shipped, merge-blocking | `haptics`, `app_info`, `permissions.status`, `deep_link` | None. Invocation ergonomics only (see below). |
| Implemented, advisory proof | `share`, `notification_token` | Proof promotion. Zero production code. |
| Zero presence anywhere | alert/confirm, menu/action-button, toast, review-prompt | Full new-capability engineering (Elixir + both natives + vectors + proof). |

So v20 is not "add five controls." It is: **build the typed control-contract seam that
Pack 1 and every future pack rides on, and prove it with the one control that genuinely
needs to be native.**

## The anti-pattern this milestone fixes

The Phase 149 haptics call — nominally the ergonomic baseline — is a hand-rolled
`<script>` IIFE in `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex`
with no reply path. There is today no supported, typed way for a LiveView to invoke a
bounded control and receive an answer. That gap, not the control count, is what makes
native affordances expensive for adopters.

## Control verdicts

| Control | Verdict | Reason |
|---------|---------|--------|
| **Menu / action-button** | **BUILD** — the wedge | Unanimous across lenses as the strongest genuinely-new control. The literal "feels wrong in a webview" moment. Gets VoiceOver/TalkBack semantics, platform-correct placement, and native dismiss gestures for free. Zero platform-policy risk. Clean fallback. It is also the control that *answers*, so it exercises the reply path the seam must provide. |
| **Haptics** | **MIGRATE** onto the seam | Already native and merge-blocking. Becomes the fire-and-forget exemplar and retires the `<script>` IIFE. |
| **Share** | **PROMOTE** proof | Fully implemented on both platforms. Needs a real fallback-copy route-tour assertion to move `proof_class` from `:advisory` to `:merge_blocking`. Carries a required iPad crash guard (`UIActivityViewController` without `sourceView`/`sourceRect` is a guaranteed crash, not a degradation). |
| **`permissions.status`** | **DOCS honesty pass** | Read-only snapshot. Must never imply permission *request* authority. (Handoff Open Decision 4.) |
| **`notification_token`** | **DOCS honesty pass** | Provider-tagged evidence only. Must never imply delivery assurance. (Handoff Open Decision 4.) |
| **Alert / confirm** | **CUT** as a bridge family | A branded, token-wired, focus-trapped, route-tour-provable LiveView modal is *better* than an unbranded OS alert on a route Phoenix already owns. Native buys nothing here except on a native screen, which is not Pack 1. Ships instead as a generated, host-owned fallback component. |
| **Toast** | **CUT** — category error | iOS has no native toast primitive. Every "toast" library is a hand-rolled overlay, so a cross-platform native toast overclaims by construction. Belongs to LiveView-owned UI. |
| **Review prompt** | **DEFER** — highest brand risk | Both Apple and Google forbid CTA-triggered prompts and provide no completion signal. Any API reporting success is a lie. Revisit only with a `requested`-only reply and never a button. |

## Architecture decisions

**Core, not a companion.** These controls have no external SDK, no optional Elixir
dependency to gate, no host-owned schema, and no independent persona — which is exactly
what distinguishes a companion (`sigra`, `chimeway`, `threadline`, `rulestead`, `rindle`)
from a core bridge command. The v3.1 controls already live in `lib/crosswake/bridge/commands/`
in core. A `crosswake_controls` package would cargo-cult the extraction playbook onto
capabilities with nothing to gate.

**The catalog line (the rule that keeps this from becoming a plugin catalog).** A control
is IN only if it passes all six: route-local and declarable; low-frequency request-reply;
zero external SDK or provider dependency; semantically bounded (closed, named command
vocabulary); fails closed to a Phoenix-owned fallback; backend stays authoritative. It
becomes a plugin catalog the moment commands are host-registrable or dynamic, need a
provider SDK or durable schema, lack a non-native fallback, or go high-frequency or
streaming. This rule ships as a merge-blocking structural test, not just prose.

**API shape.** A chainable server-side `Crosswake.Bridge.push/3` mirroring
`Phoenix.LiveView.push_event/3` — imperative Elixir over one shipped JS hook, borrowing
LiveView's own blessed declarative-effect seam rather than importing Hotwire's
HTML-attribute model. The load-bearing move: **no-shell, old-shell, and
undeclared-capability all collapse into one typed `Crosswake.Shell.Denial` reply**, so the
adopter writes one `handle_event` branch, not three.

**Fallbacks are generated, never imported.** Crosswake ships no component tier — that is a
deliberate brand anti-feature. But the confirm modal and action-menu fallbacks must look
right on day one. Resolution: generalize the existing `mix crosswake.gen.offline_ui`
precedent into a `gen.native_controls_ui` verbatim-copy generator. Every fallback is a
file the adopter owns outright the moment it is generated — never an importable
`Crosswake.UI.*` module. "No component tier" stays literally true.

## Release strategy

**Menu requires a native shell-core release.** Native bridge dispatch is a closed,
non-reflective `switch` over a fixed enum compiled into the shipped binaries
(`Crosswake.RuntimeLine.RebuildPolicy` formalizes this: `rebuild: :none` applies only to
capabilities whose native dispatch already shipped). There is no way to add real behavior
for a new command without a native rebuild.

**Therefore SEED-003 is a hard prerequisite and lands first.** The
`crosswake-shell-core-ios` SwiftPM mirror is stuck at `v0.1.2` while core and Android are
at `0.2.0`, because `MIRROR_PUSH_TOKEN` 403'd at the core 0.2.0 publish and has never been
rotated. v18 built the guardrails and the backfill script but never executed the real push.
Until it is fixed, a new shell-core release cannot reach iOS adopters at all. The fix is
small and standard for splitsh monorepos: rotate to a fine-grained PAT with
`Contents: read/write`, then run the already-built `verify_ios_mirror_backfill.sh --apply`.

**SEED-004 defers.** The real defect (doctor router-loadability) was already fixed in v18
Phase 144; the remainder is cosmetic, and the clean-room harness only runs for companion
Hex publishes — a surface v20 does not touch.

**Proof lane.** Extend the existing `native-behavioral-proof-gate.yml` composition, which
already runs merge-blocking Android JVM vectors and advisory iOS Swift vectors against the
committed `bridge_contract_vectors.json`. Add one merge-blocking browser route-tour lane
proving the fallbacks render, fail closed when undeclared, and never silently degrade. No
new simulator/emulator lane — the v15 COLL-01 hang and the Xcode-toolchain wall are
unchanged.

**Rebuild class.** This release is `native-rebuild-required`. It must be labeled as such in
the changelog, the support matrix, and doctor guidance, per the v14.0 rebuild-class
machinery.

## Footgun ledger (guards this milestone must carry)

1. **iPad share crash** — `UIActivityViewController` without `sourceView`/`sourceRect` on
   the popover presentation controller crashes. Not a degradation. Needs an explicit guard.
2. **Review prompt as a button or a "did it show?" API** — forbidden by both stores; no
   completion signal exists.
3. **Toast as a native capability** — no iOS OS primitive exists; overclaims by construction.
4. **Share reply overclaiming delivery** — the OS confirms sheet dismissal at most, never
   that the recipient acted.
5. **Haptics ignoring OS reduce-motion / haptics settings** — an accessibility violation.
6. **A silently-wrong fallback** — worse than a visible denial. Never show the end user a
   broken affordance; never hide a broken affordance from the developer.

## Sources

- `.planning/research/v20/GROUND-TRUTH.md` — file-level delta, rebuild-class analysis
- `.planning/research/v20/PRIOR-ART.md` — Hotwire Native, Capacitor, Expo, Flutter, RN,
  LiveView Native; platform-policy truth table; 9-item footgun ledger
- `.planning/research/v20/API-DESIGN.md` — the adopter-facing API, rejected alternatives
- `.planning/research/v20/RELEASE-STRATEGY.md` — lane composition, SEED verdicts, choreography
- `.planning/research/v20/UX-CONTRACT.md` — per-control JTBD, degradation, a11y, microcopy
- `.planning/research/v20/VISION-COHERENCE.md` — core-vs-companion, the catalog line, anti-scope
