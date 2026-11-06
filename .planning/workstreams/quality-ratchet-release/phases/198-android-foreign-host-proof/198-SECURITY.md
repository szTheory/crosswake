---
phase: "198"
slug: android-foreign-host-proof
status: verified
threats_open: 0
asvs_level: 1
created: "2026-11-05"
---

# Phase 198 — Security

> Threat register from the 12 PLAN threat models (44 numbered threats plus 12 per-plan supply-chain rows). Mitigations were verified by reading code, tests, workflow config and recorded evidence in the working tree, which equals main after PRs 270 and 271. The auditor did not run the suites, the scripts or CI, so "a test proves X" means the test exists and asserts X.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| bridge envelope → Kotlin core | untrusted JSON from the page is parsed and origin-gated | request fields, origin string |
| vector corpus copies → Swift/Kotlin tests | three byte-identical copies verified by sha256 before use | public contract vectors |
| network → foreign-host script | Hex tarball and Maven artifact fetched over https only, built under `env -i` in a clean HOME | public package bytes |
| CI event data → workflow `run:` | PR head SHA passed through `env:` and validated as 40 hex | SHA only |
| evidence/PR text → public | SHAs, counts, reason atoms | no adopter data, no tokens |

---

## Threat Register

All 56 threats are closed (44 numbered, 12 supply-chain). Paths are relative to the repo. `KT` = `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core`, `KTEST` = same package under `src/test`.

| Threat ID | Category | Component | Severity | Disposition | Mitigation (verified) | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-198-01 | Tampering | BridgeRequestEnvelope | high | mitigate | all nine fields through `requireString` (`KT/BridgeChannel.kt:375-398`); 18 rejections asserted in `BridgeChannelBoundaryTest` | closed |
| T-198-02 | Elevation | SemVer.parse | medium | mitigate | digits-only component check; `SemVerBoundaryTest` (5 tests) | closed |
| T-198-03 | Spoofing | listenerAllows | high | mitigate | exact main-frame and origin equality (`BridgeChannel.kt:100-101`); trailing-slash near miss tested | closed |
| T-198-04 | Repudiation | JVM test JSON library | medium | mitigate | pinned AOSP-derived `android-json`, choice recorded in 198-DECISIONS.md | closed |
| T-198-05 | Spoofing | origin gate | high | mitigate | deny on origin mismatch (`BridgeChannel.kt:117`); 7 near-miss origins asserted | closed |
| T-198-06 | Elevation | route pack authority | high | mitigate | request-claimed, empty, partial and unversioned packs all denied, with a positive control | closed |
| T-198-07 | Info disclosure | deny reply | high | mitigate | sentinel secret absent from denial; echo positive control | closed |
| T-198-08 | Tampering | side effects before denial | medium | mitigate | haptics counter 0 on deny, 1 on allow | closed |
| T-198-09 | Elevation | server.event.push / state.update | medium | accept | characterized by test; debt row (a) in 198-DECISIONS.md with owner, trigger, receiver | closed (accepted) |
| T-198-10 | Repudiation | `check_kotlin_test_floor.py` | high | mitigate | forced clean test run; fails on zero XML, duplicate suite, count mismatch, below floor, skips, failures; runs in merge-blocking `android-package-unit` | closed |
| T-198-11 | Tampering | build.gradle.kts drift | medium | mitigate | `serialization_dependency_present` and `webkit_comment_untruthful` checks | closed |
| T-198-12 | DoS | android-package-unit duration | low | accept | cost recorded in `198-EVIDENCE/ci-198.txt` | closed (accepted) |
| T-198-13 | Tampering | Kotlin corpus copy | high | mitigate | sha256 verified before use; flipped-byte test | closed |
| T-198-14 | Repudiation | stale hash constant | medium | mitigate | constant derived from the bytes the generator writes | closed |
| T-198-15 | Tampering | line-ending conversion | medium | mitigate | narrow `eol=lf` pins in `.gitattributes` | closed |
| T-198-16 | Tampering | Swift corpus copy | high | mitigate | CryptoKit sha256 at all five loader sites; flipped-byte unit test | closed |
| T-198-17 | Repudiation | Swift/Kotlin divergence | high | mitigate | one `vector_hex` binding feeds both constants; parity ledger test with divergence control | closed |
| T-198-18 | Repudiation | Android claim overstatement | high | mitigate | `:jvm_hermetic` ceiling; `validate_android_evidence!` raises for emulator/device | closed |
| T-198-19 | Tampering | hand-pasted boundary copies | medium | mitigate | single `@android_boundary` used by the renderers; hand copy pinned by test | closed |
| T-198-20 | Repudiation | overclaim scanner | low | mitigate | scanner pattern recorded and checked | closed |
| T-198-21 | Repudiation | ledger Android cell | high | mitigate | `android_level/1` demotes to `:not_claimed` unless registry compare is clean and a Kotlin consumer executes | closed |
| T-198-22 | Tampering | stale ledger | medium | mitigate | `mix crosswake.docs.sync --check` in documentation-contracts; tamper control | closed |
| T-198-23 | Repudiation | consumer drift | medium | mitigate | consumer registry compared with scan; two controls | closed |
| T-198-24 | Info disclosure | guide text | medium | mitigate | forbidden-vocabulary test with non-vacuous samples | closed |
| T-198-25 | Repudiation | Android columns in guides | high | mitigate | header-driven ceiling test with negative controls, run in documentation-contracts | closed |
| T-198-26 | Repudiation | Android prose outside tables | medium | mitigate | drift test scans `native_shell.md` and `android_uat.md` | closed |
| T-198-27 | Repudiation | unreleased ledger read as shipped | medium | mitigate | qualifier in renderer and `unreleased_claim_qualifier_test` entry | closed |
| T-198-28 | Spoofing | dependency source | high | mitigate | no mavenLocal/project include, clean HOME, `--refresh-dependencies`, AAR sha256 equals published digest | closed |
| T-198-29 | Repudiation | vacuous PASS | high | mitigate | host-owned probe proves code source is the downloaded runtime jar; tests ≥ 1, zero skips | closed |
| T-198-30 | Tampering | wrong-coordinate control | medium | mitigate | 404, dry-run and diff-count preconditions; `control_inconclusive` class; both Gradle messages matched | closed |
| T-198-31 | Info disclosure | credentials reaching build/evidence | high | mitigate | `env -i` allowlist, evidence schema carries no paths, emails or tokens | closed |
| T-198-32 | Tampering | transport downgrade | medium | mitigate | `--proto '=https'`; overrides refused outside self-test | closed |
| T-198-33 | Repudiation | promotion readiness | high | mitigate | count derived from run history; every read failure exits 2 UNVERIFIED | closed |
| T-198-34 | Tampering | stale evidence from older script | medium | mitigate | script-blob mismatch breaks the clean count | closed |
| T-198-35 | Info disclosure | gh error text in output | medium | mitigate | stderr discarded; fixed reason strings only | closed |
| T-198-36 | Elevation | silent promotion | medium | mitigate | script is read-only; umbrella `needs` excludes the job; leaf-manifest check holds `ADVISORY_JOBS` | closed |
| T-198-37 | Tampering | `run:` injection from event data | high | mitigate | head SHA passed via `env:` and validated against 40 hex | closed |
| T-198-38 | Elevation | advisory job gaining required authority | high | mitigate | four manifest checks plus phase165 integrity test | closed |
| T-198-39 | Info disclosure | secrets in the networked job | high | mitigate | no `secrets.*` reference; `contents: read` only | closed |
| T-198-40 | DoS | CI minutes | low | accept | measured 2.0 billable min for the job | closed (accepted) |
| T-198-41 | Info disclosure | pushed files and PR body | high | mitigate | `198-EVIDENCE/privacy-198.txt`: 4 scans, rc 0, earlier hits fixed before any push | closed |
| T-198-42 | Elevation | merge/publish without approval | high | mitigate | plan performed no merge, tag, publish or branch deletion; no publish step in the new jobs | closed |
| T-198-43 | Repudiation | claiming a clean run that did not happen | medium | mitigate | red first run recorded as not retried; promotion count derived by script | closed |
| T-198-44 | Info disclosure | evidence JSON committed | low | mitigate | fixed evidence schema, no free text | closed |
| T-198-SC (01, 09, 11) | Supply chain | dependency pin, first-party fetch, pinned actions | high/medium | mitigate | test-only pinned coordinate; Hex package `crosswake` plus sha-verified AAR; same SHA-pinned actions as the rest of the workflow | closed |
| T-198-SC (02–08, 10, 12) | Supply chain | no dependency added | low | accept | each plan declares none | closed (accepted) |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| T-198-09 | server.event.push / server.state.update ungated in the Android bridge | unchanged behavior, characterized by test; debt row (a) in 198-DECISIONS.md names owner, trigger and receiver (v29 Android/bridge phase) | plan-time disposition | 2026-11-05 |
| T-198-12 | android-package-unit adds about 20 s | recorded by the cost report | plan-time disposition | 2026-11-05 |
| T-198-40 | CI minutes for android-foreign-host | 2.0 billable min measured; total 159 vs about 250 baseline | plan-time disposition | 2026-11-05 |
| T-198-SC (02–08, 10, 12) | no dependency added | nothing to verify | plan-time disposition | 2026-11-05 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-05 | 56 | 56 | 0 | gsd-security-auditor (`/gsd-secure-phase 198`) |

Proof limit: ASVS L1 presence checks; the auditor did not run suites, scripts or CI. The unregistered-flags check found nothing in the SUMMARY Threat Flags sections.

Informational, not threats of this phase and not blocking:

- `.github/workflows/crosswake-ci.yml` job `release-candidate-full-proof` interpolates `${{ github.event.pull_request.base.sha }}` directly in a `run:` body. It predates Phase 198 and the value is a GitHub-supplied 40-hex SHA, but it is the pattern T-198-37 forbids for the new job. Moving it to `env:` is cheap hardening for a later phase.
- `script/android_foreign_promotion.sh` runs `unzip` on CI artifacts, locally and with an authenticated `gh`. Info-ZIP strips `..` components by default; fork-PR artifacts would be a possible future input.
- The T-198-19 single-literal count is a recorded one-time measurement in 198-06-SUMMARY, not a standing test.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-05
