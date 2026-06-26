---
phase: 131
slug: publish-pipeline-clean-room-lane-rulestead
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-06-26
---

# Phase 131 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| companion source → published tarball | `crosswake_dep/0` decides whether the published artifact records a real Hex requirement; a wrong branch ships a runtime-broken package | dep metadata (`hex_metadata.config`) |
| repo config → release-please cut decision | config/manifest entries decide WHEN and at WHAT version the companion is cut | version / release-as metadata (public) |
| CI job → Hex.pm publish | `HEX_API_KEY` authorizes an IRREVERSIBLE publish; dry-run gate + per-component if-gate guard it | publish credential (secret) |
| release-please output → publish trigger | gating on the wrong output publishes the companion on a core-only release | per-component `release_created` flag |
| script `$VERSION` arg → curl URL | an unvalidated version string flows into a Hex API URL | version string (untrusted input) |
| publish job → clean-room job | the `needs:` graph guarantees resolvability is proven only AFTER the dry-run-gated publish | job-ordering dependency |
| one-shot release-as → future cuts | a stale `release-as` silently pins all future companion cuts to 0.1.0 | version-pinning config |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-131-01 | Tampering | published tarball dep metadata (D-12) | high | mitigate | `script/verify_companion_package.sh` Step 2 greps `hex_metadata.config` for `crosswake`; built under `CROSSWAKE_RELEASE=1` so the resolver emits the honest Hex dep (verified present: Step 2 dep-presence gate, lines 60–80) | closed |
| T-131-02 | Elevation/Spoofing | release-as left in config (Pitfall 6) | low | accept | Config-only, no secret surface; removal owned by Plan 03 runbook (`131-RELEASE-AS-REMOVAL.md`) | closed |
| T-131-03 | Information disclosure | release-please.yml output aliases | low | accept | Aliases expose only version/tag/created-flag — already-public release metadata; no secret echoed | closed |
| T-131-04 | Elevation of privilege | publish-hex-rulestead if-gate (D-07) | high | mitigate | Job gates strictly on `needs.release-please.outputs.rulestead_release_created == 'true'`, never the aggregate `releases_created` (verified: `release-please.yml:146`, D-07 comment 142–144) | closed |
| T-131-05 | Tampering / runtime break | tarball missing crosswake dep (D-12) | high | mitigate | Job-level `CROSSWAKE_RELEASE: "1"` (`release-please.yml:154`) forces the resolver to emit the Hex dep; `hex.publish --dry-run` (205) precedes the real publish (211); Plan 01 Step-2 grep is the belt | closed |
| T-131-06 | Information disclosure | HEX_API_KEY in publish job | medium | mitigate | Reuses the existing repo secret; referenced only via `${{ secrets.HEX_API_KEY }}` in `env:` of dry-run + publish steps (verified: `release-please.yml:204,210`); no echo, no logging | closed |
| T-131-07 | Injection | `$VERSION` → curl URL in cleanroom script | low | mitigate | `$VERSION` validated against a semver regex before constructing the Hex API URL (`verify_companion_cleanroom.sh:53`); `set -euo pipefail` (33) | closed |
| T-131-08 | Tampering / ordering bypass | clean-room-proof-rulestead needs graph (PROOF-02) | high | mitigate | `needs: [release-please, publish-hex-rulestead]` (`release-please.yml:632`) makes the clean-room job structurally unable to run before the dry-run-gated publish; merge-blocking `phase130-proof.yml` lanes remain the PR-time pre-publish gate | closed |
| T-131-09 | Denial of service (release pipeline) | stale release-as 0.1.0 (Pitfall 6) | low | mitigate | Removal runbook with explicit trigger + verification (`131-RELEASE-AS-REMOVAL.md`); cross-referenced in `script/extract_companion.md` §12f so rindle inherits the removal step | closed |
| T-131-SC | Tampering | npm/pip/cargo installs | low | accept | No new package-manager installs; `mix deps.get` / clean-room resolves only already-published `crosswake`/`crosswake_rulestead`/`rulestead`; CI adds only first-party Hex tooling (`mix local.hex`/`mix local.rebar`) | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (high) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-131-1 | T-131-02 | `release-as` left in config is intentional pre-cut state — it must persist through the first Release PR cut; config-only, no secret surface. Removal documented in `131-RELEASE-AS-REMOVAL.md`. | szTheory | 2026-06-26 |
| AR-131-2 | T-131-03 | release-please output aliases expose only version/tag/created-flag — already-public release metadata; no secret echoed. | szTheory | 2026-06-26 |
| AR-131-3 | T-131-SC | No new package-manager installs introduced; resolution is limited to already-locked/already-published first-party packages plus first-party Hex tooling. | szTheory | 2026-06-26 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-26 | 10 | 10 | 0 | gsd-secure-phase (L1 grep-depth, short-circuit: register authored at plan time, asvs_level 1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-26
