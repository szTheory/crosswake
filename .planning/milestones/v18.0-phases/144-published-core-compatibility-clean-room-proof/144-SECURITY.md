---
phase: 144
slug: published-core-compatibility-clean-room-proof
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity
threats_open: 0
asvs_level: 1
created: 2026-07-08
---

# Phase 144 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> State B closeout: no prior SECURITY.md existed; register was built from plan-time `<threat_model>` blocks in 144-01/02/03-PLAN.md.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Release Please output -> clean-room script | Package and version outputs select the published companion artifact under proof. | Package name, version, tag metadata |
| Hex.pm registry -> clean-room dependency authority | Published Hex release metadata determines the real `crosswake` compatibility floor. | Public registry JSON, dependency requirements |
| Hex resolver -> proof result | `mix.lock` selected versions decide whether the clean-room proof installed the exact intended artifacts. | Resolved package versions |
| Clean-room script -> doctor proof | Script setup must not mask whether `mix crosswake.doctor --router` can load a fresh router itself. | Temporary host code, router module name |
| CLI argument -> doctor task | `--router` names host code loaded by diagnostics. | Host module atom/string |
| Workflow source -> scanner | Release DAG semantics are inferred from repository text before GitHub executes it. | Workflow YAML text |
| Scanner output -> CI/operator | Stable OK/FAIL IDs decide whether release-integrity proof passes or blocks. | Check IDs, operator diagnostics |
| CI logs -> operator | Logs must explain package/version/floor state without exposing credentials. | Public package metadata, failure copy |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-144-01 | Tampering | `script/verify_companion_cleanroom.sh` package/version inputs | mitigate | `package_config/0` allowlists exactly five `crosswake_*` packages and rejects unknown packages; `validate_inputs/0` requires a version and validates semver before URL construction or Mix file interpolation (`script/verify_companion_cleanroom.sh:92-135`). | closed |
| T-144-02 | Tampering | Hex release metadata | mitigate | The script fetches exact `https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}`, fails closed on 404/non-200, parses JSON structurally, checks version equality, rejects retired/unusable releases, and requires `requirements.crosswake.requirement` (`script/verify_companion_cleanroom.sh:161-228`). Scanner ID `release.cleanroom.hex_metadata_floor` guards this behavior. | closed |
| T-144-03 | Spoofing | Hex dependency resolver output | mitigate | `assert_lockfile_postconditions/0` reads `mix.lock`, asserts the companion selected exactly `${VERSION}`, asserts `crosswake` is present, and verifies the selected core version matches the derived Hex requirement (`script/verify_companion_cleanroom.sh:235-302`). Scanner ID `release.cleanroom.lockfile_postcondition` guards the postcondition. | closed |
| T-144-04 | Information Disclosure | clean-room logs | mitigate | Operator output is branded `[crosswake]` status copy with package/version/floor/selected-core/profile/state and next action; no registry credentials are referenced or echoed by the clean-room script (`script/verify_companion_cleanroom.sh:74-86,315-319,722-738`). | closed |
| T-144-05 | Denial of Service | missing live packages | mitigate | Missing or unpublished packages fail closed with package/version-specific copy instead of silently skipping proof (`script/verify_companion_cleanroom.sh:130-135,161-174,224-228`). | closed |
| T-144-06 | Spoofing | `--router` argument | mitigate | `Mix.Tasks.Crosswake.Doctor` requires `app.config`, compiles and reloads loadpaths when the router is not already loaded, then requires Phoenix router shape via `__routes__/0` before diagnostics (`lib/mix/tasks/crosswake.doctor.ex:9,87-128`). Fresh-router, missing-module, and non-router tests cover the behavior (`test/mix/tasks/crosswake_doctor_router_test.exs:30-101`). | closed |
| T-144-07 | Denial of Service | Doctor task requirements | mitigate | Doctor uses `@requirements ["app.config"]` and explicitly avoids `app.start`, so router diagnostics do not boot endpoint, database, or supervision state (`lib/mix/tasks/crosswake.doctor.ex:9`; scanner ID `release.doctor.app_config_requirement`). | closed |
| T-144-08 | Tampering | Clean-room script proof order | mitigate | The clean-room script runs `mix crosswake.doctor --router CleanRoomHost.Router` directly after compile setup and does not preload the router with `Code.ensure_loaded?/1`; scanner IDs `release.doctor.fresh_router_loaded` and `release.workflow.doctor_proof_unmasked` fail on router-preload masking (`script/verify_companion_cleanroom.sh:722-733`; `script/check_release_workflow_integrity.exs:449-492`). | closed |
| T-144-09 | Repudiation | Router failure diagnostics | mitigate | Missing routers and loaded non-router modules emit distinct Mix errors: unavailable after `app.config`/compile vs. loaded but missing `__routes__/0` (`lib/mix/tasks/crosswake.doctor.ex:87-95`; `test/mix/tasks/crosswake_doctor_router_test.exs:73-101`). | closed |
| T-144-10 | Information Disclosure | Doctor output | accept | No new secret-bearing output is introduced; accepted risk documented below. Doctor copy names module availability/router-shape state only, and tests assert the expected bounded diagnostics. | closed |
| T-144-11 | Elevation of Privilege | aggregate Release Please gate | mitigate | Behavioral release jobs are checked against aggregate `releases_created` authority; scanner ID `release.workflow.aggregate_gate.behavioral_jobs_absent` fails any behavioral job gated on `needs.release-please.outputs.releases_created` (`script/check_release_workflow_integrity.exs:656-675`; negative fixture in `test/crosswake/proof/phase142_release_integrity_test.exs:136-145`). | closed |
| T-144-12 | Tampering | proof job order | mitigate | Every companion clean-room proof job must need its matching `publish-hex-*` job and gate on its component release output; `release.workflow.proof_after_publish` and per-component proof checks enforce this (`.github/workflows/release-please.yml:791-970`; `script/check_release_workflow_integrity.exs:787-846`). | closed |
| T-144-13 | Denial of Service | release workflow concurrency | mitigate | Release publish/proof concurrency preserves pending runs with `cancel-in-progress: false` and `queue: max`; scanner IDs `release.workflow.concurrency_queue_max` and `release.workflow.no_cancel_in_progress_true` guard the workflow, including comment-only decoys (`.github/workflows/release-please.yml:26-27`; `script/check_release_workflow_integrity.exs:596-608`; tests at `test/crosswake/proof/phase142_release_integrity_test.exs:290-310`). | closed |
| T-144-14 | Tampering | clean-room dependency floors | mitigate | Clean-room floor authority comes from exact Hex metadata, exact companion pins use `PACKAGE_REQUIREMENT="== ${VERSION}"`, and lockfile postconditions verify selected versions; scanner IDs `release.cleanroom.hex_metadata_floor`, `release.cleanroom.exact_companion_pin`, and `release.cleanroom.lockfile_postcondition` guard regressions (`script/check_release_workflow_integrity.exs:298-351`). | closed |
| T-144-15 | Tampering | package matrix | mitigate | The scanner requires all five clean-room proof jobs and all five script package profiles, including Chimeway/Sigra absence and Threadline observer non-registration (`script/check_release_workflow_integrity.exs:375-417`). Package floors remain mixed and explicit: rulestead/rindle `~> 0.1`, sigra/chimeway/threadline `~> 0.2` (`packages/crosswake_*/mix.exs`). | closed |
| T-144-16 | Information Disclosure | mirror-token preflight | mitigate | `publish-ios-core` stores the secret only in `MIRROR_TOKEN`, fails fast when absent, validates usability with `git ls-remote mirror HEAD`, and only prints action copy/token-name guidance, not token values (`.github/workflows/release-please.yml:388-430`). Scanner ID `release.workflow.mirror_token_preflight` preserves this structure (`script/check_release_workflow_integrity.exs:734-752`). | closed |
| T-144-17 | Spoofing | doctor proof masking | mitigate | The clean-room script's proof boundary is the doctor command itself, and consolidated scanner ID `release.workflow.doctor_proof_unmasked` requires doctor-owned `app.config` readiness plus absence of script-side router preload (`script/verify_companion_cleanroom.sh:722-733`; `script/check_release_workflow_integrity.exs:468-492`; negative fixture in `test/crosswake/proof/phase142_release_integrity_test.exs:270-284`). | closed |
| T-144-SC | Tampering | package-manager installs | accept | No npm/pip/cargo install tasks were introduced. Implementation uses existing Bash, curl, Mix, Hex, Python stdlib, Elixir stdlib, and ExUnit surfaces; accepted risk documented below. | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-144-01 | T-144-10 | Doctor output names only module availability and router-shape readiness. No secrets, credentials, tokens, or user data are introduced by the diagnostics added in Phase 144. | gsd-secure-phase | 2026-07-08 |
| AR-144-02 | T-144-SC | Phase 144 did not add npm, pip, cargo, or new third-party package-manager install tasks. Existing Mix/Hex and stdlib tooling remain within the already-accepted project build surface. | gsd-secure-phase | 2026-07-08 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-08 | 18 | 18 | 0 | gsd-secure-phase (short-circuit: plan-time register verified locally, asvs_level 1) |

**Method:** State B - `144-SECURITY.md` created from plan-time threat models in all three PLAN files. `register_authored_at_plan_time: true`; all 18 unique threats were verified closed against implementation evidence, accepted-risk documentation, or scanner/test proof. The phase SUMMARY files do not contain `## Threat Flags` sections, so no additional summary threat flags were incorporated.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-08
