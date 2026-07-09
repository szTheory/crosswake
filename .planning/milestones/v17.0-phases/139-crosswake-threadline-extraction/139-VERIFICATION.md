---
phase: 139-crosswake-threadline-extraction
verified: 2026-07-02T22:00:00Z
status: passed
score: 5/5
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "hex.publish --dry-run passes and clean-room lane confirms tarball includes priv/ and excludes test/ (ROADMAP SC#4 / THREAD-03)"
    reason: "The dry-run is wired into the publish-hex-threadline CI job (runs dry-run before the real publish); the clean-room-proof-threadline job is wired and threadline-correct. The irreversible publish and the explicit dry-run pre-flight are deliberately deferred to the batched family publish per the milestone plan (threadline is the FINAL companion, publishes LAST after sigra + chimeway are live). The CI infrastructure to enforce the gate is in place and verified in the codebase. This deferred gate is NOT a missed requirement — it is a human-gated, order-dependent milestone action."
    accepted_by: "jon (scope note in verification request)"
    accepted_at: "2026-07-02T22:00:00Z"
re_verification: null
deferred:
  - truth: "hex.publish --dry-run pre-flight run manually confirmed with priv/ in tarball and test/ excluded"
    addressed_in: "Phase 139 Wave 4 / batched family publish"
    evidence: "Plan 04 Task 1 (auto) will run the dry-run; Task 2 (human) will execute the irreversible publish AFTER sigra + chimeway are live. ROADMAP states Plans: 3/4 executed, Wave 4 is blocked on human gate DEFERRED to family batch."
---

# Phase 139: crosswake_threadline Extraction Verification Report

**Phase Goal:** Threadline audit machinery lives in a standalone `packages/crosswake_threadline/` Hex package, observing companions exclusively via `:telemetry.attach_many` by event-name with zero compile-time deps on sibling companions.
**Verified:** 2026-07-02T22:00:00Z
**Status:** passed
**Re-verification:** No — initial verification
**Scope Note:** Plans 139-01, 139-02, 139-03 are COMPLETE and green. Plan 139-04 is the human-gated irreversible Hex-publish gate (autonomous: false), deliberately DEFERRED to the batched family publish. Verification covers the EXTRACTION goal (Waves 1-3). The publish gate (Wave 4) is intentionally deferred, not missed.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | All Crosswake.Threadline.*, Crosswake.Audit.Ledger, Crosswake.Plug.Threadline, Crosswake.Live.Threadline + both mix tasks resolve from packages/crosswake_threadline/ with namespace preserved (non-breaking host wiring) | VERIFIED | 7 source files + 2 EEX templates confirmed at packages/crosswake_threadline/lib/ and priv/. Module defmodules preserve `Crosswake.Threadline.*` / `Crosswake.Plug.Threadline` / `Crosswake.Live.Threadline` / `Crosswake.Audit.Ledger` namespaces. All 6 source paths confirmed deleted from core lib/. |
| 2 | packages/crosswake_threadline has {:crosswake, ...} as its ONLY Crosswake dep — no crosswake_sigra and no crosswake_chimeway in any env (THREAD-02, SC#2) | VERIFIED | grep of packages/crosswake_threadline/lib/ and mix.exs returned CLEAN — zero sibling hits. mix.exs deps/0 lists only {:crosswake, ...}, {:plug, optional: true}, {:phoenix_live_view, optional: true}, {:nimble_options, ~> 1.1}, {:telemetry, ~> 1.0}, {:ex_doc, dev only}. |
| 3 | Core has zero Crosswake.Threadline.*/Crosswake.Audit.Ledger/Crosswake.Plug.Threadline/Crosswake.Live.Threadline compile-time references in lib/ — atomic two-site decouple complete | VERIFIED | grep of core lib/ for module aliases/calls returned only: (a) string literals in doctor.ex (inside String.contains? — not a compile dep); (b) comments in support_matrix.ex and telemetry.ex explaining the removed dep. No alias, import, or direct function call. SITE 1: @audit_ledger_support_truth_static with frozen literal event_names/metadata_keys/forbidden_metadata_keys confirmed at support_matrix.ex:289. ThreadlineTelemetry alias removed. SITE 2: Crosswake.Threadline.Telemetry.forbidden_metadata_keys() call removed from attach_default_logger/1; only comment reference remains at line 247. |
| 4 | Core @baseline_forbidden_keys received ONLY the curated universal-floor delta (:actor_ref) — NOT threadline's OAuth/passkey-ceremony minutiae; companion-domain keys stay threadline-local (D-5) | VERIFIED | @baseline_forbidden_keys at telemetry.ex contains exactly 11 atoms: the original 10 (access_token, refresh_token, id_token, authorization_code, token, session_ref, subject_ref, actor_id, ip, email) plus :actor_ref as the curated delta. OAuth/passkey keys (pkce_verifier, raw_return_to, provider_payload, return_to, nonce, device_id, user_agent, org_id, credential_id, passkey_credential_id) are confirmed ABSENT from core and still present in packages/crosswake_threadline/lib/crosswake/threadline/telemetry.ex @forbidden_metadata_keys. |
| 5 | CI publish pipeline wired: crosswake_threadline registered as independent release-please component (not linked-versions), with publish-hex-threadline + clean-room-proof-threadline jobs, zero-sibling-dep invariant enforced at CI level (THREAD-03) | PASSED (override) | release-please-config.json: packages/crosswake_threadline block with component: "crosswake_threadline", release-type: "elixir", release-as: "0.1.0", separate-pull-requests: true, NOT in linked-versions — confirmed by python3 validation. .release-please-manifest.json: "packages/crosswake_threadline": "0.1.0". release-please.yml: threadline_release_created/tag_name/version outputs, publish-hex-threadline (gates on threadline_release_created, CROSSWAKE_RELEASE=1, dry-run step before real publish), clean-room-proof-threadline (no-engine mode, no siblings), release-as-cleanup + release-failure-alert extended. YAML valid. Override applied: dry-run not yet run manually (deferred to family batch publish). |

**Score:** 5/5 truths verified (1 with accepted override for the deferred human publish gate)

---

### Deferred Items

Items not yet met but explicitly addressed in later milestone phases or the deferred Wave 4.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | hex.publish --dry-run pre-flight run and confirmed (priv/ in tarball, test/ excluded) | Phase 139 Wave 4 / Plan 04 Task 1 (auto) | ROADMAP shows "Plans: 3/4 plans executed" with Wave 4 explicitly marked as "human publish gate, DEFERRED to family batch". Plan 04 Task 1 is the auto pre-publish gate task. The CI job publish-hex-threadline wires the dry-run → real publish sequence with CROSSWAKE_RELEASE=1. |
| 2 | crosswake_threadline 0.1.0 live on Hex (AFTER sigra + chimeway) | Phase 139 Plan 04 Task 2 (human-gated) / family batch | REQUIREMENTS.md marks THREAD-03 "Complete" (pipeline wired); the irreversible publish is the human Wave 4 go/no-go, deferred to after sigra + chimeway are live per D-9 sequential family order. |

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `packages/crosswake_threadline/mix.exs` | @version 0.1.0, files: incl priv, optional Phoenix deps, NO sibling deps | VERIFIED | @version "0.1.0", files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md), {:plug, optional: true}, {:phoenix_live_view, optional: true} confirmed |
| `packages/crosswake_threadline/lib/crosswake/threadline/{id,telemetry}.ex` | Moved with namespace preserved | VERIFIED | Both files present, defmodule Crosswake.Threadline.{Id,Telemetry} confirmed |
| `packages/crosswake_threadline/lib/crosswake/plug/threadline.ex` | Wrapped in Code.ensure_loaded?(Plug.Conn) | VERIFIED | Line 1: `if Code.ensure_loaded?(Plug.Conn) do` confirmed |
| `packages/crosswake_threadline/lib/crosswake/live/threadline.ex` | Wrapped in Code.ensure_loaded?(Phoenix.LiveView) | VERIFIED | Line 1: `if Code.ensure_loaded?(Phoenix.LiveView) do` confirmed |
| `packages/crosswake_threadline/lib/crosswake/audit/ledger.ex` | Plain defstruct + actor_ref/2 HMAC; HMAC ArgumentError names both paths | VERIFIED | defmodule Crosswake.Audit.Ledger confirmed; ArgumentError message names :secret opt AND :audit_hmac_secret app-env key |
| `packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex` | app_dir(:crosswake_threadline, ...) fixed; skipping verb; Next-steps DX | VERIFIED | app_dir(:crosswake_threadline) on lines 23-24; "skipping" verb confirmed; mix crosswake.threadline CTA in Next steps block |
| `packages/crosswake_threadline/lib/mix/tasks/crosswake.threadline.ex` | NO_COLOR/ASCII fallback + empty-result guard + posture microcopy | VERIFIED | ascii_mode?/0 detects NO_COLOR; "No events found" guard; "Posture: Durable — querying audit ledger" confirmed |
| `packages/crosswake_threadline/priv/templates/crosswake/audit/ledger.ex.eex` | try/rescue handler + on_conflict + advisory moduledoc | VERIFIED | rescue keyword confirmed; on_conflict: :nothing confirmed; advisory hash-chain @moduledoc confirmed |
| `packages/crosswake_threadline/priv/templates/crosswake/audit/migration.exs.eex` | Moved verbatim | VERIFIED | File confirmed at priv/templates/crosswake/audit/migration.exs.eex |
| `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs` | async: true; 4 canary tests; refutes sibling deps | VERIFIED | async: true confirmed; 4 tests: event_names/0 == 3, Plug.init/1 header, actor_ref/2 64-hex, refute :crosswake_sigra + :crosswake_chimeway in deps |
| `lib/crosswake/support_matrix/support_matrix.ex` | @audit_ledger_support_truth_static frozen literals; ThreadlineTelemetry alias removed | VERIFIED | @audit_ledger_support_truth_static at line 289 with frozen event_names/metadata_keys/forbidden_metadata_keys; no ThreadlineTelemetry alias |
| `lib/crosswake/telemetry.ex` | No Threadline.Telemetry call; @baseline_forbidden_keys 11 atoms (curated floor only) | VERIFIED | No compile-time call (comment-only reference); @baseline_forbidden_keys: 11 atoms, :actor_ref as the only delta |
| `test/crosswake/telemetry_test.exs` | Anti-drift test: core_baseline ⊆ union(companion keys); NOT inverse | VERIFIED | Anti-drift test at line 258 with StubThreadlineDomainCompanion (20 keys) + StubChimewayDomainCompanion; inverse explicitly NOT asserted (comment at line 262) |
| `test/crosswake/proof/phase133_telemetry_contract_test.exs` | Rewritten to use :telemetry.execute directly (no circular dep) | VERIFIED | Lines 142-160 emit threadline events via :telemetry.execute directly; comment explains the circular-dep removal rationale |
| `script/verify_companion_cleanroom.sh` | Threadline canary branch + suppress-guard for companion-behaviour assertions | VERIFIED | `if [ "$PACKAGE" = "crosswake_threadline" ]` canary branch at line 267; suppress-guard `if [ "$PACKAGE" != "crosswake_threadline" ]` at line 378; bash -n parses clean |
| `release-please-config.json` | crosswake_threadline component, NOT in linked-versions, release-as: 0.1.0 | VERIFIED | Confirmed by python3 validation; separate-pull-requests: true; independent of linked-versions |
| `.release-please-manifest.json` | "packages/crosswake_threadline": "0.1.0" | VERIFIED | Confirmed by python3 validation |
| `.github/workflows/release-please.yml` | threadline outputs + publish-hex-threadline + clean-room-proof-threadline jobs | VERIFIED | All 3 job references confirmed; threadline_release_created output; strip_release_as.py crosswake_threadline in cleanup; YAML valid |
| `examples/phoenix_host/mix.exs` | crosswake_threadline path dep | VERIFIED | {:crosswake_threadline, path: "../../packages/crosswake_threadline"} at line 54 |
| `guides/companion_compatibility.md` | threadline row, companion_id N/A | VERIFIED | Row confirmed at line 26; companion_id "N/A (not a :companions registrant — wired via Crosswake.Plug.Threadline plug + on_mount: Crosswake.Live.Threadline)" |
| `mix.exs` (core) | companions.test alias lines for crosswake_threadline; NO path dep (circular dep removed) | VERIFIED | Lines 75-76 show companions.test alias; no {:crosswake_threadline, path:...} dep in deps/0 (removed in 139-02 to fix MixProject double-load) |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| core lib/crosswake/telemetry.ex | packages/crosswake_threadline | NOT wired (by design) | VERIFIED | Core deliberately has NO compile dep on threadline after Phase 139 decouple. Threadline observes core events by event-name via :telemetry.attach_many. The absence of wiring IS the correct state. |
| packages/crosswake_threadline | core | {:crosswake, path: "../.."} OR {:crosswake, "~> 0.1"} via CROSSWAKE_RELEASE | VERIFIED | mix.exs crosswake_dep/0 function: path dep in dev, Hex dep when CROSSWAKE_RELEASE=1 |
| packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex | priv/templates/crosswake/audit/*.eex | Application.app_dir(:crosswake_threadline, "priv/templates/crosswake/audit/...") | VERIFIED | Both schema_template and migration_template lines use :crosswake_threadline atom; File.exists? cwd fallback preserved |
| priv/templates/crosswake/audit/ledger.ex.eex handler | :telemetry system | try/rescue wrapping Repo insert; handler returns :ok on failure (never reraises) | VERIFIED | rescue block confirmed; no reraise keyword in template |
| script/verify_companion_cleanroom.sh | packages/crosswake_threadline | threadline canary branch + suppress-guard instead of companion-behaviour assertions | VERIFIED | canary tests Telemetry/Plug/Ledger modules; suppresses enabled?/companion_id/validate_dependency calls |

---

### Data-Flow Trace (Level 4)

Not applicable — this phase produces a library package (no UI components, no server-rendered data flows). The key data flow is compile-time module availability, verified via artifact presence + namespace checks.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| packages/crosswake_threadline/mix.exs: no sibling deps | `grep -rn "crosswake_sigra\|crosswake_chimeway" packages/crosswake_threadline/lib/ packages/crosswake_threadline/mix.exs` | Empty output | PASS |
| app_dir atom fixed | `grep -q 'app_dir(:crosswake_threadline' packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex` | Found (lines 23-24) | PASS |
| priv in files: | `grep -qE 'files:.*\bpriv\b' packages/crosswake_threadline/mix.exs` | files: ~w(lib priv ...) confirmed | PASS |
| Code.ensure_loaded? guards present | grep of plug/threadline.ex and live/threadline.ex | if Code.ensure_loaded?(Plug.Conn) + if Code.ensure_loaded?(Phoenix.LiveView) on line 1 of each | PASS |
| @audit_ledger_support_truth_static frozen | `grep -q "@audit_ledger_support_truth_static" lib/crosswake/support_matrix/support_matrix.ex` | Found at line 289 with frozen literal sub-map | PASS |
| Zero Threadline compile refs in core lib/ | `grep -rn "Crosswake\.Threadline\|Crosswake\.Audit\.Ledger\|Crosswake\.Plug\.Threadline\|Crosswake\.Live\.Threadline" lib/` filtering for compile refs | Only string literals (doctor.ex) and comments — zero module aliases or calls | PASS |
| @baseline_forbidden_keys is 11 atoms, curated floor only | Manual inspection of telemetry.ex | 10 original + :actor_ref only; no OAuth/passkey keys | PASS |
| Anti-drift test NOT asserts inverse | `grep -n "inverse\|NOT asserted\|NOT assert" test/crosswake/telemetry_test.exs` | Lines 123, 262 confirm inverse NOT asserted | PASS |
| Cleanroom proof: async: true; 4 tests | `grep -c "test \"" phase139_threadline_cleanroom_test.exs` | 4 tests; async: true confirmed | PASS |
| ledger.ex.eex: rescue present, no reraise | grep checks | rescue confirmed; no reraise keyword | PASS |
| NO_COLOR, empty-result, posture microcopy | grep of crosswake.threadline.ex | ascii_mode?/0 + "No events found" + "Posture: Durable — querying audit ledger" all present | PASS |
| gen.audit: skipping + CTA | grep of crosswake.gen.audit.ex | "skipping" verb + "mix crosswake.threadline" CTA confirmed | PASS |
| HMAC ArgumentError names both paths | grep of ledger.ex | :audit_hmac_secret app-env key named; :secret opt named | PASS |
| release-please-config.json valid + threadline independent | python3 json.load + component assertion | Component: crosswake_threadline, Release-as: 0.1.0, NOT in linked-versions | PASS |
| release-please.yml valid YAML + 3 jobs wired | python3 yaml.safe_load + grep | Valid YAML; publish-hex-threadline, clean-room-proof-threadline, threadline_release_created, strip_release_as.py crosswake_threadline all confirmed | PASS |
| verify_companion_cleanroom.sh syntax + threadline canary | bash -n + grep | Syntax OK; crosswake_threadline canary branch + suppress-guard present | PASS |
| Commit existence | git log --oneline | All 13 claimed commits (a62b4ba1 through 2b96db67) confirmed in git log | PASS |

---

### Probe Execution

Not applicable — this phase has no probe scripts in the conventional `scripts/*/tests/probe-*.sh` location. Behavioral verification performed via Step 7b spot-checks above.

---

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|---------------|-------------|--------|----------|
| THREAD-01 | 139-01-PLAN, 139-02-PLAN | threadline source + tests move to standalone packages/crosswake_threadline/ Hex project; gen.audit app_dir repointed; host Plug/Live wiring stable | SATISFIED | Package exists with 7 source files + 2 EEX templates + 11 test files; gen.audit app_dir uses :crosswake_threadline; namespace preserved; all core threadline source deleted |
| THREAD-02 | 139-01-PLAN, 139-02-PLAN | zero compile deps on sibling companions; forbidden-metadata-key list owned locally; audit handler crash-isolated (try/rescue); ledger append-only PII-free | SATISFIED | Zero sibling deps confirmed; 20-key forbidden list in threadline/telemetry.ex; try/rescue in ledger.ex.eex template; on_conflict: :nothing idempotent replay |
| THREAD-03 | 139-03-PLAN | independent release-please component; gated by hex.publish --dry-run + clean-room; publishes after sigra + chimeway | SATISFIED (with deferred publish) | release-please-config.json independent component; publish-hex-threadline CI job with --dry-run → real publish gate; clean-room-proof-threadline job with zero-sibling mode; actual publish deliberately deferred to family batch per milestone plan |

No orphaned requirements found — all 3 THREAD requirements are claimed by plans in this phase. FAMILY-01..04 are Phase 140 (next phase), not orphaned here.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| release-please-config.json | 137 | `_TODO_release_as` JSON comment key | Info | This is the established convention across all companion packages (rulestead, rindle, sigra, chimeway all have identical entries). It is a machine-readable reminder for the auto-cleanup job (strip_release_as.py), not an unresolved stub. The cleanup is wired into the CI pipeline. Not a blocker. |

No TBD, FIXME, or XXX markers found in any modified source files. No stub implementations, no placeholder handlers, no hardcoded empty data flowing to rendering.

---

### Special Findings: Atomic Core Decouple (Requested Focus)

**SITE 1 (support_matrix.ex):** `@audit_ledger_support_truth_static` confirmed as frozen literal struct at line 289. The alias `Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry` is absent from the file. Values frozen: `event_names` = 3 request-span events ([:crosswake, :threadline, :request, :start/:stop/:exception]), `metadata_keys` = 4-key PROP-02 allowlist, `forbidden_metadata_keys` = the 20-key threadline denylist inlined as literals. Accessor `def audit_ledger_support_truth, do: [@audit_ledger_support_truth_static]` present. Pattern mirrors @notification_support_truth_static (L263) and @auth_contract_truth_static (L133).

**SITE 2 (telemetry.ex):** The static compile-time `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` call is removed from `attach_default_logger/1`. The "Threadline stays in-tree for Phase 136" comment is removed. `@baseline_forbidden_keys` is 11 atoms: the original 10 plus `:actor_ref` as the sole curated universal-floor delta. OAuth/passkey-ceremony minutiae (pkce_verifier, raw_return_to, provider_payload, return_to, nonce, device_id, user_agent, org_id, credential_id, passkey_credential_id) confirmed ABSENT from core and confirmed PRESENT in threadline's own @forbidden_metadata_keys — no PII regression.

**Circular dep fix (Wave-1 MixProject double-load):** The `{:crosswake_threadline, path: "packages/crosswake_threadline", only: :test}` dep was added by Plan 01 Task 1 but then removed in Plan 02 Task 1 (commit afee444a) after the circular dep `crosswake_threadline -> crosswake -> MixProject double-load` error. `phase133_telemetry_contract_test.exs` (TELEM-04) was rewritten to emit threadline events via `:telemetry.execute` directly, eliminating the circular dep. Core `mix.exs` now has only the `companions.test` alias lines (lines 75-76) for crosswake_threadline — no path dep. This is the correct resolution.

---

### Human Verification Required

None. All observable truths are programmatically verifiable at the codebase level. The deferred items (dry-run confirmation, irreversible publish) are milestone-scoped human-gate actions, not verification gaps.

---

### Gaps Summary

No gaps. All 5 observable truths are VERIFIED or PASSED (override). The phase extraction goal is fully achieved in-tree. The one override (THREAD-03 publish gate) is the deliberate, milestone-planned deferred human action, not a missed implementation.

**Publish gate status (THREAD-03 / Plan 04):** The CI pipeline is wired and correct. The `publish-hex-threadline` job includes the dry-run gate before the real publish. The `clean-room-proof-threadline` job exercises zero-sibling mode. The human Release-PR merge is the go/no-go, explicitly held for the batched family publish after sigra + chimeway are live. This is the design, not a deficiency.

---

_Verified: 2026-07-02T22:00:00Z_
_Verifier: Claude (gsd-verifier)_
