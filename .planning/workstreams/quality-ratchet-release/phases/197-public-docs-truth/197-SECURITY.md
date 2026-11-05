---
phase: "197"
slug: public-docs-truth
status: verified
threats_open: 0
asvs_level: 1
created: "2026-11-05"
---

# Phase 197 — Security

> Threat register from the 15 PLAN threat models. Mitigations were verified by reading code, tests and recorded evidence in the working tree, which equals merged PR 268. The auditor did not re-run the suites or the clean-room script.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| repo files → docs report | Doc text is parsed as untrusted input; the report prints counts and reason atoms | public doc lines (`--detail` only) |
| network → clean-room script | `fetch` of Hex tarballs, POMs and raw sources | public package and doc content |
| script → docs-leg host | README/install steps executed in a throwaway work dir with `env -i` | synthetic values only |
| evidence/PR comments → public | SHAs, counts, check names | no adopter data |

---

## Threat Register

All 41 STRIDE threats are closed. Evidence paths are relative to the repo; `EVID/` is `.planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/`.

| Threat ID | Category | Component | Severity | Disposition | Mitigation (verified) | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-197-01 | Repudiation | DocsReport counters | high | mitigate | unread input exits 2 UNVERIFIED, never a zero; fixtures in `test/crosswake/docs_report_test.exs` | closed |
| T-197-40 | Repudiation | mix test gates | high | mitigate | `script/mix_test_gate.sh` unpiped, stale out file removed, rc/summary/floor checks; `mix_test_gate_test.exs` | closed |
| T-197-02 | Info disclosure | report output | low | mitigate | fixed reason atoms only | closed |
| T-197-36 | Tampering | leak allowlist | medium | mitigate | schema validation, six invalid fixtures | closed |
| T-197-03 | Elevation | CI workflows | medium | mitigate | test asserts no workflow references the report; no `.github/` diff | closed |
| T-197-04 | Repudiation | baseline evidence | high | mitigate | `EVID/ordering-197.txt` merge-base rc 0 | closed |
| T-197-05 | Info disclosure | evidence files | medium | mitigate | `EVID/privacy-197.txt` clean after run 1 fix | closed |
| T-197-34 | Repudiation | REQUIREMENTS/ROADMAP/STATE | medium | mitigate | amendments recorded; Phase 199 `deferred=none` criterion | closed |
| T-197-06 | DoS | fetch | medium | mitigate | `--max-time`/`--retry` bound | closed |
| T-197-07 | Spoofing | fetch redirects | high | mitigate | `--proto =https --proto-redir =https`; file:// only under SELFTEST | closed |
| T-197-08 | Tampering | POM check | medium | mitigate | block-stripping `pom_field`, mismatch fixtures | closed |
| T-197-09 | Repudiation | failure reasons | medium | mitigate | distinct `not_published`/`resolve_failed`/`parse_failed` | closed |
| T-197-10 | Info disclosure | docs_env | high | mitigate | `env -i` allowlist; HEX_API_KEY sentinel test | closed |
| T-197-11 | Tampering | docs_fetch_sources | high | mitigate | 40-hex ref check; overrides refused without SELFTEST | closed |
| T-197-12 | Tampering | proof provenance | medium | mitigate | source commit printed; real run shows `source=commit:` | closed |
| T-197-13 | DoS | step execution | medium | mitigate | process-group watchdog, interrupt handling | closed |
| T-197-16 | Tampering | tarball extraction | medium | mitigate | selective extract, symlink/non-regular rejection | closed |
| T-197-33 | Spoofing | tarball source | medium | mitigate | https-pinned default repo; override refused | closed |
| T-197-14 | Tampering | step `file=` | high | mitigate | `docs_path_ok` rejects empty/absolute/`..` paths, checked twice | closed |
| T-197-15 | Repudiation | skipped steps | high | mitigate | executed floor 18; `:ios_host` exemption keyed to 0.2.12 and printed as `deferred` | closed |
| T-197-17 | Repudiation | README/install.md | medium | mitigate | real run `executed=18 not_applicable=2 deferred=ios_host`; marker tests | closed |
| T-197-18 | Info disclosure | doc text/evidence | medium | mitigate | synthetic values; privacy scan rc 0 on 98 inputs | closed |
| T-197-19 | Tampering | `:ios_host` examples | low | mitigate | `ios_host_doc_values_test.exs` validates via `IOSHostConfig.normalize` | closed |
| T-197-35 | Repudiation | docs-leg unread steps | high | mitigate | `EVID/cleanroom-docs-reader-audit-197.txt` vs 0.2.11 tarball | closed |
| T-197-20 | Repudiation | companion matrix | medium | mitigate | phase132 drift test with injected control | closed |
| T-197-21 | Repudiation | CHANGELOG Unreleased | medium | mitigate | wording guard test with controls | closed |
| T-197-22 | Tampering | release automation | medium | mitigate | no new `## [x.y.z]` section added | closed |
| T-197-30 | Repudiation | publish.parity rule | high | mitigate | candidate rule in `publish_readiness.ex`; real-repo and broken-copy tests | closed |
| T-197-23 | Repudiation | android_uat.md | high | mitigate | no stamp or device claim; drift and phantom-set tests | closed |
| T-197-24 | Tampering | release-please config | medium | mitigate | only the android_uat extra-file removed; JSON decode tests | closed |
| T-197-25 | Info disclosure | telemetry guide | low | mitigate | metadata matches `telemetry.ex events/0`; no payload or ids | closed |
| T-197-31 | Repudiation | suite/ordering evidence | medium | mitigate | gate-graded `EVID/suite-197.txt`, PASS 3134/0 | closed |
| T-197-32 | Repudiation | D-07b control | medium | mitigate | negative control with exact FAIL lines | closed |
| T-197-26 | Info disclosure | pushes/PR/evidence | high | mitigate | privacy scan rc 0; `.planning/config.json` not in diff | closed |
| T-197-27 | Elevation | merge to main | high | mitigate | merge was a separate one-use gate | closed |
| T-197-28 | Repudiation | CI evidence | medium | mitigate | CI record names head and synthetic merge ref | closed |
| T-197-37 | Info disclosure | PR comment | medium | mitigate | SHAs, check names and run ids only | closed |
| T-197-29 | Repudiation | real clean-room run | medium | mitigate | no selftest overrides; ends `result PASS` | closed |
| T-197-38 | Repudiation | guides claiming unreleased features | high | mitigate | `unreleased_claim_qualifier_test.exs`, 8 pairs with controls | closed |
| T-197-39 | Tampering | generated guides | medium | mitigate | qualifier lives in renderers; `docs.sync --check` in CI (not re-run by the auditor) | closed |
| T-197-SC-04, T-197-SC-14 | Tampering | `mix archive.install hex phx_new` | medium | mitigate | pinned 1.8.13, isolated MIX_HOME | closed |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| T-197-SC-01..03, 05..13, 15 | dependency installs (low) | No dependency added by this phase; `mix.exs` has no diff. The `mix.lock` change came from merging main with PR 269, a separate advisory fix. | plan-time disposition `accept` | 2026-11-05 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-05 | 56 | 56 | 0 | gsd-security-auditor |

Proof limit: ASVS L1 presence checks; suites and the clean-room script were not re-run by the auditor. The unregistered-flags check found nothing.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-05
