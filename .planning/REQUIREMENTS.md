# Requirements: v20.0 Native Controls Pack 1

**Milestone goal:** Ship the typed control-contract seam that every native-controls pack
rides on, and prove it with the one control that genuinely needs to be native — replacing
the ad-hoc `<script>` escape hatch adopters use today with a bounded, fail-closed,
route-declared affordance.

Research synthesis: `.planning/research/v20/SUMMARY.md`.

## v1 Requirements

### MIRROR — iOS mirror unblock (prerequisite)

Native bridge dispatch is a closed `switch` over a fixed enum compiled into the shipped
shell-core binaries, so any new control requires a new native release. The
`crosswake-shell-core-ios` SwiftPM mirror is stuck at `v0.1.2` while core and Android are
at `0.2.0` — until that is fixed, a new shell-core release cannot reach iOS adopters at
all. This category must land before MENU.

- [ ] **MIRROR-01**: The `crosswake-shell-core-ios` SwiftPM mirror carries a `v0.2.0` tag matching the live Hex and Maven `0.2.0` core, so iOS adopters can resolve the current shell core.
- [ ] **MIRROR-02**: A native shell-core release publishes to Hex, Maven, and the iOS mirror in one run, and a mirror-push failure surfaces as a hard, named CI failure instead of a silent 403.

### GATE / RUNNER / CACHE — CI gate integrity and runner cost (inserted)

Pulled forward from SEED-007 as Phase 153.1 — a deliberately narrow slice. `GATE-*` is a
correctness fix, not an optimization: branch protection matches required contexts by **string**, so
duplicate check names let a red run be masked by a green one, and 20 test files excluded by every CI
lane run only on laptops. `RUNNER-*`/`CACHE-*` are pulled forward for sequencing — Phase 154 is the
milestone's largest phase and would otherwise pay the per-PR tax across all of it. `CONSOL-*`,
`FLAKE-*`, `DX-*`, and the merge-queue decision stay planted in SEED-007.

- [ ] **GATE-01**: No two workflow jobs emit the same `merge-blocking` check name, so branch protection cannot conflate a red run with a green one wearing the same name.
- [ ] **GATE-02**: `check_required_checks_registered.sh` fails when two jobs share a check name — asserting uniqueness, not merely presence — and has a negative control proving the assertion is not vacuous.
- [ ] **GATE-03**: The `:requires_example_host` test files run on a named CI lane, and a bare local `mix test` excludes the same tag set CI does, so local and CI agree on what passing means.
- [ ] **RUNNER-01**: Every job on `macos-*` is justified per job by a demonstrated Apple-toolchain invocation, traced through each `run:` into the scripts it calls; a structural test rejects an unjustified macOS job.
- [ ] **RUNNER-02**: Every workflow declares `timeout-minutes`, so a hung job cannot hold a scarce macOS runner for the six-hour default while other jobs queue behind it.
- [ ] **CACHE-01**: Elixir lanes restore `deps/` and `_build` from caches keyed `os|arch|otp|elixir|MIX_ENV|hash(mix.lock)`, with `restore-keys` differing by exactly the lock hash, so a toolchain bump can never restore incompatible BEAM files.
- [ ] **CACHE-02**: A structural test rejects any cache key missing a dimension, and no retired `actions/cache@v3` usage remains.

### CTRL — the control-contract seam (load-bearing)

The reusable machinery. Once this exists, controls 4..N are cheap, repeatable work.

- [x] **CTRL-01**: A LiveView can invoke a bounded control via `Crosswake.Bridge.push/3` and receive a typed reply correlated to the invocation.
- [x] **CTRL-02**: No-shell, too-old-shell, and undeclared-capability all resolve to one typed `Crosswake.Shell.Denial` reply, so an adopter writes one `handle_event` branch rather than three.
- [x] **CTRL-03**: A route invoking a capability it never declared in route policy fails loudly and names the missing declaration, rather than silently doing nothing.
- [x] **CTRL-04**: The bridge command vocabulary stays closed and named — host-registrable or dynamic command registration is structurally impossible.
- [x] **CTRL-05**: Every control declares its rebuild class, and a native-rebuild-required release is labeled as such in the changelog, the support matrix, and doctor guidance.

### MENU — the first genuinely-new native control

The reply-path exemplar. Unanimous across research lenses as the strongest new control:
the literal "feels wrong in a webview" moment, zero platform-policy risk, clean fallback.

- [ ] **MENU-01**: A route declares menu/action-button affordances in route policy, with allowed actions and fallback behavior explicit.
- [ ] **MENU-02**: The iOS and Android shell cores render a native menu and return the chosen action as a typed reply.
- [ ] **MENU-03**: Native menu actions carry VoiceOver and TalkBack semantics and native dismiss gestures.

### FALL — host-owned fallbacks (no component tier)

Crosswake ships no component library — that is a deliberate anti-feature. But fallbacks
must look right on day one, so they are generated and owned by the host, never imported.

- [ ] **FALL-01**: `mix crosswake.gen.native_controls_ui` scaffolds host-owned, brand-tokenized fallback components (confirm modal, action menu) as verbatim-copy files the adopter owns outright.
- [ ] **FALL-02**: Generated fallbacks render correctly in light and dark, trap focus, and meet the existing contrast gates; no importable `Crosswake.UI.*` module exists.

### HRDN — harden what already shipped

- [ ] **HRDN-01**: The AdminPilot haptics call runs through `Bridge.push/3`; the hand-rolled `<script>` IIFE with no reply path is gone.
- [ ] **HRDN-02**: Haptics respects the operating system's reduce-motion and haptics accessibility settings.
- [ ] **HRDN-03**: The iOS share sheet cannot crash on iPad — a missing popover anchor is guarded rather than left to the OS.

### EVID — read-only surfaces stay honest

- [ ] **EVID-01**: `permissions.status` documentation and support truth never imply permission *request* authority; it is a read-only snapshot.
- [ ] **EVID-02**: `notification_token` documentation and support truth never imply delivery assurance; it is provider-tagged evidence only.

### PROOF — the lanes

- [ ] **PROOF-01**: A merge-blocking browser route-tour lane proves fallbacks render, fail closed when undeclared, and never silently degrade.
- [ ] **PROOF-02**: `share` and `notification_token` move from advisory to merge-blocking proof posture.
- [ ] **PROOF-03**: Menu behavior is proven from the committed `bridge_contract_vectors.json` on both natives without a simulator or emulator.
- [x] **PROOF-04**: The catalog line ships as a merge-blocking structural test — a proposed control failing any of its six criteria fails CI.

## Future Requirements (deferred)

- **Review prompt** — deferred until it can ship as a `requested`-only reply with no button and no success signal. Both Apple and Google forbid CTA-triggered prompts and provide no completion callback.
- **Capture & Device Controls pack** — camera, scanner, document scan, media upload, permission-request UX, evidence availability.
- **Commerce/Paywall productionization** — storefront adapters, entitlement refresh, purchase-evidence ingestion.
- **Offline Sync / Native Storage productization** (SYNCP-01, NTV-01) — native storage budgets, durable journals, outboxes, retry, conflict handling.
- **Native Controls Pack 2 — Themable Web Control Equivalents** (THEME-*, WCTRL-*, reuse FALL-*) — a brand-themable, host-owned, generator-emitted WEB equivalent for every delegated native control; extends the token system by elevation/z/motion/border-width/padding and generalizes v20's FALL host-owned fallback family. Planted as SEED-005; the web-side follow-on to this milestone.
- **Native Navigation Shell** (NAVG-*, SHELL-*, SYNC-*, LIFE-*, A11Y-*) — a real native tab bar + nav stack (à la Hotwire Native) hosting Crosswake routes, nav graph declared once in the manifest and rendered per-platform; native shell fidelity toward consumer-grade "feels-native." Planted as SEED-006; its own milestone (distinct axis from the controls packs) carrying an explicit positioning north-star shift.
- **Release-PR changelog deadlock** (RELTRUTH-01) — the root release PR (#57, `0.2.0`→`0.2.1`) can never go green. `test/crosswake/guides/release_boundaries_test.exs:128` derives "current version" from `mix.exs` via `Application.spec(:crosswake, :vsn)`, so inside a release PR the bumped version makes the *previous* version look stale and flags `CHANGELOG.md:20-22,36` as `[stale_latest_hex]` — even though those lines are **true** (`0.2.0` genuinely is the published release; `0.2.1` is not out). The root package sets `skip-changelog: true`, so release-please never updates `CHANGELOG.md` to resolve it. Root cause: the gate conflates "version in `mix.exs`" with "latest published Hex release", which are deliberately different during a release PR. The principled fix follows the precedent already set by `script/check_release_as_staleness.sh` — *the git tag, not the local manifest, is the authoritative already-released signal* — but proof workflows currently check out without `fetch-tags`, so it also needs a CI checkout change. Deferred as its own scoped work, not a drive-by: it changes the semantics of a merge-blocking release-honesty gate (the same class that caught the rulestead/rindle overclaim), and #57 additionally needs version-bump fixture regeneration (`release-status` mirror ref, `phase52_publish_readiness.json`, `native_evidence_drift`, `doctor_threadline`, `phase43`) that only makes sense alongside a real decision to publish `0.2.1`.
- **CI/CD Performance & Gate Integrity** (OBS-*, GATE-*, RUNNER-*, CACHE-*, CONSOL-*, FLAKE-*, DX-*) — CI spends ~25,500 runner-seconds (~7 h) per push to run an ~88-second test suite, and the spend is mostly macOS **queue** time (one merge-blocking proof measured 2,230 s queued / 180 s executed) for jobs that mostly need no Apple toolchain. Measuring it surfaced three correctness holes: three required check *names* are each emitted by two workflows (branch protection matches by string, so a red run can be masked by a green one), 20 `:requires_example_host` test files run only on laptops (no CI lane executes them — how the red gate fixed in #89 went unnoticed), and leaked `Application.put_env` global state made those tests pass in a full suite while failing in isolation. Planted as SEED-007; infrastructure rather than product, so it can run in parallel with any product milestone, and `GATE-*` is severable and pullable forward on its own. **Partially pulled forward 2026-07-28 as Phase 153.1** — `GATE-*`, `RUNNER-*`, and `CACHE-*` are now v20 requirements (see the inserted category above), because `GATE-*` is correctness rather than optimization and because Phase 154 would otherwise pay the per-PR tax across the milestone's largest phase. What remains deferred here is `CONSOL-*` (39 workflow files → ~4, change detection, required-context topology), `FLAKE-*`, `DX-*`, full `OBS-*` instrumentation, and the merge-queue (`on: merge_group:`) decision — the judgment-heavy pieces that need their own milestone. Explicit non-goals: do not shard the Elixir suite (per-shard setup exceeds the execution saved), and never workflow-level `paths:`-filter a required context (a skipped required check hangs the PR forever).
- **`crosswake_dashboard`** (DASH-01) — operator route/support/telemetry/audit/release inspection surface.
- **SEED-004** — companion clean-room proof harness cosmetics. The real defect was fixed in v18 Phase 144; the harness only runs for companion Hex publishes, a surface v20 does not touch.

## Out of Scope

- **A native `toast` capability** — iOS ships no toast primitive, so a cross-platform native toast overclaims by construction. Toasts are LiveView-owned UI.
- **A native `alert`/`confirm` bridge family** — a branded, focus-trapped, route-tour-provable LiveView modal is better than an unbranded OS alert on a route Phoenix already owns. It ships as a generated fallback (FALL-01), not a bridge command.
- **An importable `Crosswake.UI.*` component tier** — fallbacks are generated, host-owned, verbatim-copy files, following the `gen.offline_ui` precedent.
- **A `crosswake_controls` companion package** — controls have no external SDK or optional dependency to gate, which is what defines a companion in this family. They stay in core alongside the v3.1 command families.
- **Host-registrable, dynamic, or high-frequency bridge commands** — the vocabulary stays closed and named, enforced by PROOF-04.
- **Expanding the haptics pattern vocabulary** — `haptics.impact` shipped in v3.1 and is sufficient.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| GATE-01 | Phase 153.1 | Pending |
| GATE-02 | Phase 153.1 | Pending |
| GATE-03 | Phase 153.1 | Pending |
| RUNNER-01 | Phase 153.1 | Pending |
| RUNNER-02 | Phase 153.1 | Pending |
| CACHE-01 | Phase 153.1 | Pending |
| CACHE-02 | Phase 153.1 | Pending |
| MIRROR-01 | Phase 153 | In Progress (153-01 done; live tag push is 153-02, human-gated) |
| MIRROR-02 | Phase 153 | In Progress (153-01/153-03 done: transport, atomic push, and escalation land; merge-blocking parity gate + release-truth CLI split are 153-04) |
| CTRL-01 | Phase 154 | Complete |
| CTRL-02 | Phase 154 | Complete |
| CTRL-03 | Phase 154 | Complete |
| CTRL-04 | Phase 154 | Complete |
| CTRL-05 | Phase 154 | Complete |
| PROOF-04 | Phase 154 | Complete |
| HRDN-01 | Phase 154 | Pending |
| FALL-01 | Phase 155 | Pending |
| FALL-02 | Phase 155 | Pending |
| PROOF-01 | Phase 155 | Pending |
| MENU-01 | Phase 156 | Pending |
| MENU-02 | Phase 156 | Pending |
| MENU-03 | Phase 156 | Pending |
| PROOF-03 | Phase 156 | Pending |
| HRDN-02 | Phase 157 | Pending |
| HRDN-03 | Phase 157 | Pending |
| EVID-01 | Phase 157 | Pending |
| EVID-02 | Phase 157 | Pending |
| PROOF-02 | Phase 157 | Pending |

**Coverage:** 28/28 v1 requirements mapped (21 original + 7 inserted with Phase 153.1). No orphans.
