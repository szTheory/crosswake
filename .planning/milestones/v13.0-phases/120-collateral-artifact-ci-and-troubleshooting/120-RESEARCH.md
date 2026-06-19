# Phase 120: Collateral, Artifact CI, And Troubleshooting - Research

**Researched:** 2026-06-19  
**Domain:** Phoenix example-host Playwright proof, evidence artifact contracts, advisory native capture, troubleshooting docs  
**Confidence:** HIGH for repo-local findings; MEDIUM for external CI/tooling behavior because the GSD research seam was unavailable.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- Add a dedicated required browser route-tour proof instead of folding broad route-owner collateral into `examples/phoenix_host/e2e/offline_sync.spec.ts`. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Use semantic Playwright assertions as the correctness gate; screenshots, videos, HTML reports, and traces are evidence/collateral only. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Cover `/library`, `/bridge-proof`, `/offline`, and a native-screen or route-unavailable path such as `/native/claims/:id/capture`. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Make browser route-tour proof merge-blocking with `merge-blocking-*` naming; do not make native simulator/emulator collateral merge-blocking. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Use one run-level `evidence-manifest.json` with route-level entries. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Manifest route entries must include Crosswake version, commit SHA, route id, runtime owner, platform/runtime, command, proof class, support label, coordinate mode when native-relevant, source job, captured-at timestamp, artifacts, retention label, and known limitations. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Required browser artifacts must fail packaging when missing; advisory native artifacts may be absent only with explicit unavailable status and reason. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Keep rich Playwright outputs as CI artifacts with bounded retention and commit only a small curated screenshot set plus manifest when docs need durable collateral. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Treat iOS simulator and Android emulator screenshots/recordings as advisory evidence only. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]
- Add route-owner-first troubleshooting, likely `guides/troubleshooting.md`, with required examples for `undeclared_capability`, `unavailable_capability`, `compatibility_mismatch`, `pack_incompatible`, `external_entry_denied`, `gate_denied`, `step_up_required`, route-unavailable states, native evidence label confusion, rejected offline replay, and conflict/replay outcomes. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]

### the agent's Discretion

Downstream agents may choose exact file names, helper function names, manifest module names, workflow job names, and screenshot paths as long as the locked decisions are preserved; recommended defaults are `route_tour.spec.ts`, a run-level `evidence-manifest.json`, `guides/troubleshooting.md`, and an ExUnit evidence/troubleshooting docs-contract test. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]

### Deferred Ideas (OUT OF SCOPE)

- Managed mobile test services, self-hosted native runners, recurring native screenshot/video automation beyond best-effort advisory evidence, physical-device support, camera support, media-upload support, provider authority, app-store readiness, required simulator/emulator branch protection, DASH-01, NTV-01, and machine-generated diagnostic reference docs are deferred. [VERIFIED: `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`]

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as a Phoenix-first route-policy and runtime-contract system, not a universal UI framework. [VERIFIED: `AGENTS.md`]
- Keep runtime ownership explicit per route and avoid generic WebView wrapper or LiveView-driven native-rendering designs. [VERIFIED: `AGENTS.md`]
- Keep bridge contracts semantic, typed, versioned, and low-frequency. [VERIFIED: `AGENTS.md`]
- Keep offline claims honest by distinguishing cached read-only behavior from true local-first mutation with journals, outboxes, and reconciliation. [VERIFIED: `AGENTS.md`]
- Treat diagnostics, support matrices, proof lanes, and rough-edge documentation as product surface. [VERIFIED: `AGENTS.md`]
- Respect v1 scope boundaries before adding integrations or wider native breadth. [VERIFIED: `AGENTS.md`]

## Phase Boundary and Scope Guard

Phase 120 should package proof and recovery surfaces for existing route-owner behavior; it should not add new runtime capabilities, new native support claims, new offline semantics, or new provider authority. [VERIFIED: `.planning/REQUIREMENTS.md`; VERIFIED: `AGENTS.md`]

The four plans should stay aligned to the roadmap split: browser route-tour proof, evidence manifest/artifact contract, advisory native capture, then troubleshooting/rough-edge docs. [VERIFIED: `.planning/ROADMAP.md`]

Primary recommendation: implement the required browser route-tour as a sibling Playwright spec and CI artifact producer, then validate its manifest and docs with ExUnit source-derived scanners. [VERIFIED: `examples/phoenix_host/playwright.config.ts`; VERIFIED: `test/crosswake/guides/quick_start_adoption_drift_test.exs`; VERIFIED: `test/crosswake/guides/native_evidence_drift_test.exs`]

## Current Repo Findings

The existing Playwright harness already starts `MIX_ENV=test` Phoenix on port `4002`, uses one worker, blocks service workers, retries in CI, and records trace on first retry. [VERIFIED: `examples/phoenix_host/playwright.config.ts`] Playwright officially documents `trace: 'on-first-retry'` as the CI trace pattern and notes that it produces trace output on first retry. [CITED: https://playwright.dev/docs/trace-viewer]

`offline_sync.spec.ts` already proves the high-value offline path through UI clicks, IndexedDB observation, explicit reconnect event, `/study/sync`, Ecto polling through `/_e2e/sync-state/:client_mutation_id`, accepted outbox deletion, and duplicate idempotency. [VERIFIED: `examples/phoenix_host/e2e/offline_sync.spec.ts`] Reuse or extract helpers from this spec; do not make the route tour reimplement fragile IndexedDB plumbing from scratch. [VERIFIED: `examples/phoenix_host/e2e/offline_sync.spec.ts`]

The current route set has stable candidate routes: `/library` has route id `library` and is LiveView-owned, `/bridge-proof` has route id `bridge-proof` and declares `share`, `/offline` has route id `offline-study` and `runtime: :offline_island`, and `/native/claims/:id/capture` has route id `selective-native-claim-capture` with `runtime: :native_screen`. [VERIFIED: `examples/phoenix_host/lib/crosswake_example/router.ex`]

`BridgeProofLive` emits a semantic bridge payload only after the Share button event; assertions should inspect command `share.invoke`, capability `share`, route id `bridge-proof`, active route id, protocol, version, origin, and correlation id rather than requiring a native share sheet. [VERIFIED: `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex`]

`offline_study.js` owns the IndexedDB outbox, `flushOutbox`, `/study/sync` POST, accepted-record deletion, rejected-record warning, and online-event flush behavior. [VERIFIED: `examples/phoenix_host/priv/static/offline_study.js`] This is the route-tour proof boundary for offline: app-owned browser code mutates local state, Phoenix/Ecto reconciles, and the bridge does not own mutation authority. [VERIFIED: `guides/adoption.md`; VERIFIED: `examples/phoenix_host/priv/static/offline_study.js`]

The existing E2E CI workflow already uses an Option-C aggregator named `merge-blocking-offline-sync-e2e` with sibling guard jobs and an `e2e-proof` job. [VERIFIED: `.github/workflows/offline-sync-e2e-gate.yml`] Extending this workflow is lower-drift than creating unrelated proof topology, but the route-tour job should have its own artifact names and manifest paths. [VERIFIED: `.github/workflows/offline-sync-e2e-gate.yml`; CITED: https://github.com/actions/upload-artifact]

`script/check-e2e-honesty.mjs` is AST-based and prevents fabricated offline proof shapes such as injected globals, fetch inside `page.evaluate`, and minted UUIDs in the spec. [VERIFIED: `script/check-e2e-honesty.mjs`] If route-tour reuses offline assertions, either keep `offline_sync.spec.ts` under this guard or extend the guard intentionally to cover the new helper/spec path. [VERIFIED: `script/check-e2e-honesty.mjs`]

Support-truth vocabulary is already canonical in `guides/support_matrix.md`, including `merge-blocking proof`, `advisory evidence`, `checked-in public-coordinate proof`, `local-dev proof`, `generated public-coordinate proof`, `JVM hermetic proof`, `emulator evidence`, `device evidence`, `verification-required`, and `rebuild-required`. [VERIFIED: `guides/support_matrix.md`] Artifact captions and manifest enums should use these labels literally. [VERIFIED: `guides/support_matrix.md`]

Native scripts already provide useful advisory hooks: `script/verify_generated_ios_shell.sh` can build, install, and launch an iOS simulator when Xcode/simulator tools exist, and `script/verify_generated_android_shell.sh` can run JVM-only or connected emulator checks depending on `CROSSWAKE_ANDROID_CONNECTED_TESTS`. [VERIFIED: `script/verify_generated_ios_shell.sh`; VERIFIED: `script/verify_generated_android_shell.sh`] Local probe found Node `v22.14.0`, npm `11.1.0`, Mix `1.19.5`, Xcode `26.5`, no listed available iOS runtimes, and no usable Java runtime/Android CLI tools from the current shell. [VERIFIED: local environment probe]

Docs-contract tests already follow the right pattern: derive facts from source files, scan public docs/sources, include synthetic regression cases, and emit actionable failure categories. [VERIFIED: `test/crosswake/guides/quick_start_adoption_drift_test.exs`; VERIFIED: `test/crosswake/guides/native_evidence_drift_test.exs`]

Doctor/test sources already expose the troubleshooting vocabulary: bridge denial reasons include `compatibility_mismatch`, `external_entry_denied`, `gate_denied`, `pack_incompatible`, `step_up_required`, `undeclared_capability`, and `unavailable_capability`; offline states include terminal outcomes such as `accepted` and `conflict`. [VERIFIED: `test/crosswake/doctor/doctor_test.exs`]

The GSD helper seam failed during research with `Cannot find module '../../../package.json'`, so provider caching and `classify-confidence` could not run. [VERIFIED: local command output] This does not affect repo-local research confidence, but it should be fixed before relying on GSD research cache in later phases. [VERIFIED: local command output]

## Recommended Plan Split

### 120-01 Browser Route-Tour Proof

Add `examples/phoenix_host/e2e/route_tour.spec.ts` with one clear route-owner journey and semantic assertions for the four required owner classes. [VERIFIED: `.planning/ROADMAP.md`; VERIFIED: `examples/phoenix_host/lib/crosswake_example/router.ex`] Use Playwright web-first locators and assertions for visible route state because Playwright documents auto-waiting web assertions such as locator text/visibility assertions. [CITED: https://playwright.dev/docs/test-assertions]

Recommended assertions:

| Route | Route id | Required semantic checks | Screenshot role |
|---|---:|---|---|
| `/library` | `library` | Page renders lesson library; route is reachable as Phoenix/LiveView-owned collateral. [VERIFIED: `router.ex`] | Required browser collateral. |
| `/bridge-proof` | `bridge-proof` | Share button creates bridge payload with `share.invoke`, `share`, `bridge-proof`, protocol/version/origin/correlation fields. [VERIFIED: `bridge_proof_live.ex`] | Required browser collateral; not native share-sheet proof. |
| `/offline` | `offline-study` | Reuse/extract queue/reconnect/Ecto assertions from `offline_sync.spec.ts`. [VERIFIED: `offline_sync.spec.ts`] | Required browser collateral after queued/replayed state. |
| `/native/claims/:id/capture` or deterministic route-unavailable fixture | `selective-native-claim-capture` | Prove route policy marks native-screen ownership or fail-closed unavailable posture without simulator/device dependency. [VERIFIED: `router.ex`; VERIFIED: `guides/native_shell.md`] | Required browser collateral only if the route is deterministic. |

Screenshots should be captured with `page.screenshot({ path })` into a stable artifact directory after semantic assertions pass. [CITED: https://playwright.dev/docs/screenshots] Do not use `toHaveScreenshot()` as the correctness gate in this phase because Phase 120 requires screenshots as collateral rather than pixel-diff proof. [VERIFIED: `120-CONTEXT.md`; CITED: https://playwright.dev/docs/test-snapshots]

### 120-02 Evidence Manifest, Packaging, and CI Contract

Add a narrow manifest writer/validator, preferably a small Node helper for emitting from Playwright plus ExUnit tests for schema and docs/caption contracts. [VERIFIED: `examples/phoenix_host/package.json`; VERIFIED: `test/crosswake/guides/native_evidence_drift_test.exs`]

Recommended run-level shape:

```json
{
  "schema_version": "1.0.0",
  "crosswake_version": "0.1.2",
  "commit_sha": "$GITHUB_SHA",
  "source_job": "route-tour-proof",
  "captured_at": "ISO-8601",
  "retention_label": "ci-artifact-14-days",
  "routes": [
    {
      "route_id": "bridge-proof",
      "runtime_owner": "live_view",
      "platform_runtime": "browser-chromium",
      "command": "npx playwright test e2e/route_tour.spec.ts",
      "proof_class": "merge-blocking proof",
      "support_label": "advisory evidence",
      "coordinate_mode": null,
      "status": "captured",
      "artifacts": ["screenshots/bridge-proof.png"],
      "known_limitations": ["Screenshot does not prove native share sheet execution."]
    }
  ]
}
```

Required keys and allowed labels should be validated in ExUnit so normal `mix test` catches drift before CI artifact upload. [VERIFIED: `test/crosswake/guides/quick_start_adoption_drift_test.exs`; VERIFIED: `guides/support_matrix.md`] Use `actions/upload-artifact` with `if-no-files-found: error` for required browser bundles because the action supports failing when paths are missing. [CITED: https://github.com/actions/upload-artifact] Use explicit `retention-days` because GitHub supports per-artifact retention settings subject to repo/org limits. [CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data]

Job summaries should append concise Markdown to `$GITHUB_STEP_SUMMARY`, because GitHub Actions supports per-step Markdown summaries grouped on the workflow run page. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands]

### 120-03 Advisory Native Capture

Use checked-in public-coordinate host paths as the default caption/manifest coordinate mode because Phase 119 promoted checked-in iOS and Android hosts to published-coordinate defaults. [VERIFIED: `.planning/phases/119-native-evidence-classification/119-CONTEXT.md`; VERIFIED: `test/crosswake/guides/native_evidence_drift_test.exs`]

Prefer a non-blocking/manual-dispatch or advisory job that attempts:

- iOS: `CROSSWAKE_IOS_PROJECT_ROOT=examples/ios_shell_host bash script/verify_generated_ios_shell.sh`, then simulator screenshot/recording only if `xcodebuild`, `xcrun`, and a concrete simulator runtime are available. [VERIFIED: `script/verify_generated_ios_shell.sh`]
- Android: `CROSSWAKE_ANDROID_PROJECT_ROOT=examples/android_shell_host CROSSWAKE_ANDROID_CONNECTED_TESTS=1 bash script/verify_generated_android_shell.sh`, then emulator screenshot/recording only if Java, SDK tools, emulator, and AVD boot succeed. [VERIFIED: `script/verify_generated_android_shell.sh`]

Every native attempt should append a manifest entry with status `captured`, `skipped`, or `unavailable`, and skipped/unavailable entries must include the concrete reason. [VERIFIED: `120-CONTEXT.md`] Local research found Android capture unavailable in this shell because Java runtime resolution failed and Android CLI tools were not present. [VERIFIED: local environment probe]

### 120-04 Troubleshooting and Rough Edges

Add `guides/troubleshooting.md` as route-owner-first documentation with a symptom index and compact repeated entry structure. [VERIFIED: `120-CONTEXT.md`] The guide should link to `guides/route_policy.md`, `guides/bridge.md`, `guides/offline.md`, `guides/native_shell.md`, `guides/adoption.md`, and `guides/support_matrix.md` instead of duplicating full reference material. [VERIFIED: `117-CONTEXT.md`; VERIFIED: `118-CONTEXT.md`]

Add `test/crosswake/guides/troubleshooting_test.exs` or `test/crosswake/guides/evidence_manifest_test.exs` to verify canonical findings/denials have owner, remediation command, proof label, known limitation, and support-matrix/doctor link. [VERIFIED: `test/crosswake/guides/quick_start_adoption_drift_test.exs`; VERIFIED: `test/crosswake/doctor/doctor_test.exs`]

## Validation Architecture

Nyquist validation is enabled because `.planning/config.json` does not set `workflow.nyquist_validation` to `false`. [VERIFIED: `.planning/config.json`]

| Requirement | Behavior | Recommended automated validation |
|---|---|---|
| COLL-01 | Browser route-tour proves LiveView, bridge, offline island, and native-screen/unavailable path with semantic assertions. | `cd examples/phoenix_host && npm ci && npx playwright install chromium && npx playwright test e2e/route_tour.spec.ts` [VERIFIED: `playwright.config.ts`] |
| COLL-02 | Evidence manifest has required keys, allowed proof/support labels, required artifacts, retention label, and known limitations. | `mix test test/crosswake/guides/evidence_manifest_test.exs` plus CI artifact upload with `if-no-files-found: error` [CITED: https://github.com/actions/upload-artifact] |
| NATIVE-COLL-01 | Native simulator/emulator attempts are advisory and honestly labeled as captured/skipped/unavailable. | `mix test test/crosswake/guides/native_evidence_drift_test.exs` plus advisory native job manifest validation [VERIFIED: `native_evidence_drift_test.exs`] |
| TROUBLE-01 | Troubleshooting docs cover doctor findings, denials, route-unavailable states, offline outcomes, and native evidence caveats. | `mix test test/crosswake/guides/troubleshooting_test.exs test/crosswake/doctor/doctor_test.exs` [VERIFIED: `doctor_test.exs`] |

Keep these fast local checks:

```bash
mix test test/crosswake/guides/native_evidence_drift_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/doctor/doctor_test.exs
cd examples/phoenix_host && npm ci && npx playwright test e2e/offline_sync.spec.ts e2e/route_tour.spec.ts
node script/check-e2e-honesty.mjs
```

CI recommendation: extend `.github/workflows/offline-sync-e2e-gate.yml` with a route-tour proof job and artifact upload, then add that job to the existing merge-blocking aggregator or create a sibling `merge-blocking-route-tour-evidence` aggregator. [VERIFIED: `.github/workflows/offline-sync-e2e-gate.yml`]

## Risks and Mitigations

| Risk | Why it matters | Mitigation |
|---|---|---|
| Screenshot-as-proof regression | Visual collateral can pass while behavior is wrong. [VERIFIED: `120-CONTEXT.md`] | Gate on semantic Playwright assertions first; capture screenshots only after assertions pass. [CITED: https://playwright.dev/docs/test-assertions] |
| Duplicated offline plumbing | Reimplementing IndexedDB/Ecto assertions can drift from the already-honest v12 proof. [VERIFIED: `offline_sync.spec.ts`] | Extract a helper or call a route-tour wrapper around the existing proof pattern. [VERIFIED: `offline_sync.spec.ts`] |
| Native overclaim | Simulator/emulator screenshots can be misread as physical-device or provider authority. [VERIFIED: `119-CONTEXT.md`; VERIFIED: `guides/support_matrix.md`] | Manifest dimensions must keep proof class, coordinate mode, execution environment, support label, and known limitations separate. [VERIFIED: `119-CONTEXT.md`] |
| Missing artifacts silently tolerated | Upload defaults can warn instead of fail on missing required files. [CITED: https://github.com/actions/upload-artifact] | Use `if-no-files-found: error` for required browser evidence and manifest validation before upload. [CITED: https://github.com/actions/upload-artifact] |
| Artifact sprawl | Reports, traces, videos, and native logs can bloat the repo if committed. [VERIFIED: `.planning/REQUIREMENTS.md`] | Keep rich outputs in CI artifacts with retention labels; commit only curated screenshots/manifests when needed. [VERIFIED: `120-CONTEXT.md`; CITED: https://docs.github.com/en/actions/tutorials/store-and-share-data] |
| CI branch-protection drift | Existing required status checks are sensitive to job-name changes. [VERIFIED: `.github/workflows/offline-sync-e2e-gate.yml`] | Preserve the existing aggregator or add a carefully named sibling `merge-blocking-*` check with documented registration. [VERIFIED: `.github/workflows/offline-sync-e2e-gate.yml`] |
| Troubleshooting freezes prose too tightly | A brittle docs scanner can block useful guide edits. [VERIFIED: `quick_start_adoption_drift_test.exs`] | Scan required concepts/labels/commands and synthetic regressions, not exact paragraphs. [VERIFIED: `quick_start_adoption_drift_test.exs`] |

## File/Command Inventory

| Area | Files to read/change | Commands |
|---|---|---|
| Browser route tour | `examples/phoenix_host/e2e/route_tour.spec.ts`, `examples/phoenix_host/e2e/offline_sync.spec.ts`, `examples/phoenix_host/playwright.config.ts` [VERIFIED: codebase] | `cd examples/phoenix_host && npx playwright test e2e/route_tour.spec.ts` |
| Route fixtures | `examples/phoenix_host/lib/crosswake_example/router.ex`, `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex`, `examples/phoenix_host/priv/static/offline_study.js` [VERIFIED: codebase] | `cd examples/phoenix_host && mix test test/crosswake_example/router_test.exs` |
| CI artifacts | `.github/workflows/offline-sync-e2e-gate.yml`, new manifest writer/check script if needed [VERIFIED: codebase] | Existing CI pattern: `npm ci`, `npx playwright install --with-deps`, `npx playwright test` |
| Honesty guard | `script/check-e2e-honesty.mjs` [VERIFIED: codebase] | `npm ci --prefix examples/phoenix_host && node script/check-e2e-honesty.mjs` |
| Manifest/docs validation | new `test/crosswake/guides/evidence_manifest_test.exs`, new `test/crosswake/guides/troubleshooting_test.exs`, existing `test/crosswake/guides/native_evidence_drift_test.exs` [VERIFIED: codebase] | `mix test test/crosswake/guides/native_evidence_drift_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs` |
| Native advisory capture | `script/verify_generated_ios_shell.sh`, `script/verify_generated_android_shell.sh`, checked-in host READMEs [VERIFIED: codebase] | iOS: `CROSSWAKE_IOS_PROJECT_ROOT=examples/ios_shell_host bash script/verify_generated_ios_shell.sh`; Android: `CROSSWAKE_ANDROID_PROJECT_ROOT=examples/android_shell_host CROSSWAKE_ANDROID_CONNECTED_TESTS=1 bash script/verify_generated_android_shell.sh` |
| Troubleshooting docs | new `guides/troubleshooting.md`, README/ExDoc guide map if needed, `guides/support_matrix.md`, `guides/route_policy.md`, `guides/adoption.md`, `guides/native_shell.md`, `guides/bridge.md`, `guides/offline.md` [VERIFIED: codebase] | `mix test test/crosswake/doctor/doctor_test.exs test/crosswake/guides/troubleshooting_test.exs` |

Environment availability:

| Dependency | Required by | Available | Version/result | Fallback |
|---|---|---:|---|---|
| Node | Playwright and evidence helper scripts | yes | `v22.14.0` [VERIFIED: local probe] | none needed |
| npm | Playwright dependencies | yes | `11.1.0` [VERIFIED: local probe] | none needed |
| Mix/Erlang | ExUnit/docs validation | yes | Mix `1.19.5`, OTP 28 [VERIFIED: local probe] | none needed |
| Xcode/xcodebuild | iOS advisory capture | partial | Xcode `26.5`; no available runtime listed by `xcrun simctl list runtimes available` [VERIFIED: local probe] | record advisory unavailable if no simulator runtime |
| Java/Android SDK/emulator | Android advisory capture | no | Java runtime unavailable; `adb`/`emulator` not found in probe [VERIFIED: local probe] | use script provisioning where supported, otherwise manifest `unavailable` |

## Open Questions or Assumptions

1. Should the browser route-tour artifact upload live inside `offline-sync-e2e-gate.yml` or a sibling workflow?  
   What we know: the existing workflow already has the required topology and Playwright setup. [VERIFIED: `.github/workflows/offline-sync-e2e-gate.yml`] Recommendation: extend the existing workflow unless job duration or branch-protection naming argues for a sibling aggregator. [VERIFIED: `.github/workflows/offline-sync-e2e-gate.yml`]

2. Should curated screenshots be committed in Phase 120 or left as CI artifacts only?  
   What we know: Phase 120 allows a small optimized committed screenshot set plus manifest when docs need durable collateral, while rich outputs stay in CI. [VERIFIED: `120-CONTEXT.md`] Recommendation: commit only if README/guide evidence path needs stable public images; otherwise link CI artifacts/job summary and keep repo size bounded. [VERIFIED: `.planning/REQUIREMENTS.md`]

3. Is `/native/claims/:id/capture` directly renderable without auth/session setup in Playwright?  
   What we know: the route is inside a LiveView session with `require_authenticated_member`, so brittle auth setup is a risk. [VERIFIED: `examples/phoenix_host/lib/crosswake_example/router.ex`] Recommendation: prefer a deterministic manifest/route-policy assertion or smallest E2E fixture for route-unavailable/native-owner posture rather than weakening the proof. [VERIFIED: `120-CONTEXT.md`]

4. Can native advisory capture run in CI now?  
   What we know: current local shell has Xcode but no listed simulator runtime and no usable Android Java/CLI tools. [VERIFIED: local probe] Recommendation: plan native capture as best-effort advisory with explicit unavailable manifest entries, not a required gate. [VERIFIED: `120-CONTEXT.md`]

## Sources

- `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`
- `.planning/phases/117-route-policy-and-support-truth-guide-foundation/117-CONTEXT.md`
- `.planning/phases/118-runnable-quick-start-and-real-adoption-proof/118-CONTEXT.md`
- `.planning/phases/119-native-evidence-classification/119-CONTEXT.md`
- `.planning/phases/120-collateral-artifact-ci-and-troubleshooting/120-CONTEXT.md`
- `AGENTS.md`
- `examples/phoenix_host/playwright.config.ts`
- `examples/phoenix_host/e2e/offline_sync.spec.ts`
- `examples/phoenix_host/e2e/offline_storage.spec.ts`
- `examples/phoenix_host/lib/crosswake_example/router.ex`
- `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex`
- `examples/phoenix_host/priv/static/offline_study.js`
- `.github/workflows/offline-sync-e2e-gate.yml`
- `script/check-e2e-honesty.mjs`
- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`
- `guides/support_matrix.md`
- `test/crosswake/guides/native_evidence_drift_test.exs`
- `test/crosswake/guides/quick_start_adoption_drift_test.exs`
- `test/crosswake/doctor/doctor_test.exs`
- Playwright assertions, screenshots, trace, and visual comparison docs: `https://playwright.dev/docs/test-assertions`, `https://playwright.dev/docs/screenshots`, `https://playwright.dev/docs/trace-viewer`, `https://playwright.dev/docs/test-snapshots`
- GitHub Actions artifact and summary docs: `https://github.com/actions/upload-artifact`, `https://docs.github.com/en/actions/tutorials/store-and-share-data`, `https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands`

## Metadata

**Confidence breakdown:**

- Browser route-tour architecture: HIGH, based on current Playwright config, route definitions, and existing E2E proof. [VERIFIED: codebase]
- Evidence manifest/artifact contract: HIGH for required fields from Phase 120 context; MEDIUM for exact GitHub artifact behavior because it depends on current action version and repository retention settings. [VERIFIED: `120-CONTEXT.md`; CITED: https://github.com/actions/upload-artifact]
- Native advisory capture: MEDIUM, because scripts exist but local and CI runner tooling availability varies. [VERIFIED: scripts; VERIFIED: local probe]
- Troubleshooting docs/test shape: HIGH, based on existing doctor tests, support matrix vocabulary, and docs-contract scanner patterns. [VERIFIED: codebase]

**Research seam status:** `gsd-tools.cjs query init.phase-op 120` failed with a missing `../../../package.json` module, so research-plan caching and classify-confidence could not be used. [VERIFIED: local command output]

**Valid until:** 2026-07-19 for repo-local architecture; recheck GitHub Actions and Playwright docs before changing artifact/action versions. [CITED: https://github.com/actions/upload-artifact; CITED: https://playwright.dev/docs/trace-viewer]
