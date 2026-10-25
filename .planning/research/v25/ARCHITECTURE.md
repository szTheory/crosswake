# v25 selected architecture and decision coverage

Status: researched proposal. [SUMMARY.md](SUMMARY.md) owns the selected recommendations and supersedes conflicting alternatives in specialist reports.

| Brief decisions | Selected recommendation | Evidence and rationale |
|---|---|---|
| 1–2: config authority/CLI | Ordinary host build-time config, normal MIX_ENV, closed options passed to pure generator; legacy compatibility without silent production overrides | GENERATION and CONFIG-LOADING-RESOLUTION; no second config DSL |
| 3: provisioning/privacy | Host-owned identity/team inputs; credentials remain in host/Xcode secure setup; safe presence/wiring results only | GENERATION/PROOF; no real adopter values in Crosswake |
| 4: build modes | Unsigned simulator checks; device-capable effective settings separately inspected | Apple xcconfig/build settings; no device-install claim |
| 5: regeneration | Missing-only native scaffold, recognized managed resources, preflight/staging, explicit interruption recovery and nonwriting check | GENERATION-CHALLENGE; no arbitrary PBX editor |
| 6–7: router/origin | Existing canonical compiler/builder and declared entry route; placeholder origin denied; auth/media dependencies do not broaden route/bridge authority | GENERATION and TWIN-CHALLENGE |
| 8: compatibility | Preserve existing dev/local path, explicit opt-in production config and native-project migration, truthful docs/upgrade impact | GEN/DX; no dependency upgrades |
| 9: twin topology | Existing contract + browser/backend layers plus one generated-iOS composition | TWIN-ARCHITECTURE; do not duplicate full matrices |
| 10–11: WebView identity/layers | Visible generated app and matching controller/bridge observations; Safari remains browser evidence | TWIN challenge and pinned runtime source |
| 12: installed media | Actual island action invokes registered host command and native player for verified installed bytes | MEDIA-OWNERSHIP-RESOLUTION supersedes HTML-file exposure requirement |
| 13: persistence | True app termination/relaunch; same persistent WebKit store; no lifecycle reset | TWIN/PROOF |
| 14–15: replay/denials | Ordinary app request, actual scoped Ecto effect, duplicate idempotency, real backend recovery/fences/flags | TWIN; fixture authority explicitly synthetic |
| 16: finite model | Canonical T01–T10 scenario groups, preconditions kept separate, no case proliferation | PROOF-CHALLENGE resolves roster mismatch |
| 17: independent provenance | Expected sources fixed before launch; installed app, loaded assets, backend/dependency observations matched separately | PROOF-CHALLENGE; declared SHA alone insufficient |
| 18–19: receipt/results | Derived twin-only closed receipt; complete expected observation set; fail/blocked/pass aggregate | PROOF; physical schema unchanged |
| 20: privacy/diagnosis | Closed shared results, restricted local failed logs, no payload or stable identity fields | PROOF/DX; no missing failure cause guesses |
| 21–22: isolation/DB | Invocation owns DB/port/process/run root; Sandbox for in-process tests, committed DB for HTTP | PROOF/Ecto; no default-db cleanup |
| 23: CI/time/retries | Bound subprocesses; retain first failure; stable contract tests reuse existing leaves; no standing one-off simulator workflow | PROOF |
| 24: stop versus blocked | Complete only when required virtual observations pass; external/generic-product blocker ends work incomplete | SUMMARY and scope proposal |
| 25: maintainer JTBD | Declare → diff/generate/check → bounded run → concrete repair/result | DX; one ordinary path |
| 26: learner state | Local save/queued/accepted/recovery/disabled copy reflects actual owners | DX; no technical internals in learner flow |
| 27: inclusive UI | Existing semantic tokens, status/focus/labels/touch/theme/reflow/reduced motion for necessary flow states | Current brandbook and official accessibility guidance |
| 28–29: output/brand | Result/cause/report/next action; calm current-brand vocabulary; no dashboard/polish | DX/PROMPT-COVERAGE |
| 30: cohesion/delivery | Two phases; initial feasibility gates; explicit preserved history and parked lane | SUMMARY; no repeated completed work |

Data flow: host build config + compiled route declarations → managed manifest/static activation/build settings → generated candidate + host-owned native composition → visible study WebView → local island outbox / registered host audio delegate → actual Phoenix admission + Ecto effect → independent safe observations → derived twin receipt.

The receipt is a terminal record, never an input granting authority. Runtime/session/replay and physical promotion remain with their existing owners.
