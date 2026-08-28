---
phase: 153
slug: ios-mirror-unblock
status: verified
# threats_open counts OPEN threats at or above workflow.security_block_on (high).
threats_open: 0
asvs_level: 1
created: 2026-07-30
---

# Phase 153 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub Actions runner → `szTheory/crosswake-shell-core-ios` | Release and backfill jobs push a derived SwiftPM tree into a separate public repository. | SSH deploy-key authentication; immutable tag refs; mutable `main` ref |
| `actions/checkout` workspace → later git remotes | Checkout-created git configuration can affect remotes added later in the same job. | Git credential configuration and remote URLs |
| GitHub secret store → job process | The mirror deploy key is made available only to the jobs that perform authenticated pushes. | `MIRROR_DEPLOY_KEY` private key |
| Release Please output → published mirror content | A public, immutable version tag must be derived from the exact released source ref. | Release tag name and subtree split SHA |
| Operator workstation → GitHub API | One-time deploy-key provisioning and secret registration cross a human/administrative boundary. | Deploy-key public/private halves and repository settings |
| Public mirror → parity/release-truth probes | Unauthenticated remote responses drive merge and release-health results. | Git refs, probe success/failure, registry presence |
| Branch protection → merge button | A discovered CI context is advisory until repository branch protection requires it. | Required-status-check configuration |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and L1 evidence | Status |
|-----------|----------|-----------|----------|-------------|----------------------------|--------|
| T-153-01 | Spoofing / Elevation of Privilege | Checkout credentials hijack a later mirror remote. | high | mitigate | Both mirror workflows use `persist-credentials: false`, SSH transport, and SHA-pinned `webfactory/ssh-agent`; `release.ios.ssh_transport` and `release.ios_backfill.ssh_transport` enforce the shape. | closed |
| T-153-02 | Information Disclosure | `MIRROR_DEPLOY_KEY` private material leaks during provisioning or CI use. | high | mitigate | CI loads the key only through `webfactory/ssh-agent`; no workflow step prints it. The completed provisioning record says `gh secret set` consumed stdin and temporary key files were removed. | closed |
| T-153-03 | Tampering | An already-published SwiftPM tag is moved. | high | mitigate | Tag refspecs remain unforced while any lease is scoped only to `refs/heads/main`; hermetic tests prove an existing tag cannot move. Live evidence preserves `v0.1.2` at `6417ae65…` while `v0.2.0` resolves separately. | closed |
| T-153-04 | Tampering | A stale lease overwrites mirror `main`, or a partial multi-ref push advances only one ref. | high | mitigate | The release lane uses one `git push --atomic` with an explicit freshly-read lease; the backfill lane uses an explicit lease. Tests cover stale-lease rejection and atomic no-partial-apply behavior. | closed |
| T-153-SC | Tampering | Third-party SSH-agent action is replaced or compromised through a floating reference. | medium | mitigate | `webfactory/ssh-agent` is pinned to commit `e83874834305fe9a4a2997156cb26c5de65a8555` in both workflows; no package-manager install was added. | closed |
| T-153-05 | Tampering | `v0.2.0` is published at the wrong subtree split object. | high | mitigate | Verify-only run `30316715897` recorded split SHA `658d6025…`; run `30316962777` pushed the tag; direct remote verification shows `refs/tags/v0.2.0` at that same SHA. | closed |
| T-153-06 | Elevation of Privilege | Mirror credential has missing write access or unnecessarily broad authority. | medium | accept/mitigate | The write-enabled deploy key is scoped to the single regenerable mirror repository, and the dry-run push proves required write access before mutation. The remaining single-repository push authority is accepted below. | closed |
| T-153-07 | Tampering | A newer tree is published under an older, correct-looking version tag. | high | mitigate | `publish-ios-core` checks out `needs.release-please.outputs.tag_name` with `fetch-depth: 0`; `release.ios.checkout_ref_pinned` and its mutation test enforce both clauses. | closed |
| T-153-08 | Repudiation | A native release fails without a durable alert while the release appears successful. | high | mitigate | `release-failure-alert` depends on the native jobs and rollup, while `native-release-rollup` fails on partial native state after writing its artifact. Structural scanner checks and decoy tests cover both controls. | closed |
| T-153-09 | Tampering / Denial of Service | Registry absence and probe unavailability are conflated, producing false release truth. | high | mitigate | Bash and Elixir probes retry three times, distinguish definite absence from unreachability, and fail closed. `release.live_registry_presence` and `release.live_registry_unverifiable` remain separate error codes; targeted tests cover the split. | closed |
| T-153-10 | Tampering | Remote-controlled `git ls-remote` output reaches shell evaluation. | low | mitigate | The parity script parses fixed ref text without `eval` and never interpolates remote output into a command. | closed |
| T-153-11 | Repudiation / Denial of Service | Parity keys off the release manifest and deadlocks a release PR. | high | mitigate | The gate enumerates released `refs/tags/ios-core-v*` refs, not `.release-please-manifest.json`; phase tests enforce the source invariant. | closed |
| T-153-12 | Repudiation | The parity lane exists but remains advisory because branch protection does not require it. | medium | mitigate | The lane is discoverable and green, but Plan 04 records required-check registration as an operator carry. Run `DRY_RUN=0 script/register_required_checks.sh`, then verify the branch-protection context list. | open — below high threshold (non-blocking) |
| T-153-13 | Information Disclosure | A read-only parity check receives an unnecessary credential. | low | mitigate | The public-mirror probe is explicitly unauthenticated via `git -c core.askPass= ls-remote`; the parity workflow provides no mirror secret. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*

*Severity: critical > high > medium > low — only open threats at or above `workflow.security_block_on: high` count toward `threats_open`.*

*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party).*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-153-01 | T-153-06 | A release credential must retain push authority to publish the mirror. A write deploy key confines that authority to one public, derived, regenerable repository and exposes no broader GitHub API or organization scope. | Phase 153 D-05 decision | 2026-07-28 |

---

## Security Audit 2026-07-30

| Metric | Count |
|--------|-------|
| Threats found | 14 |
| Closed | 13 |
| Open | 1 non-blocking / 0 blocking |

ASVS L1 grep-depth verification found no open threat at or above the configured `high`
blocking threshold. Because the register was authored during planning and
`threats_open: 0`, the secure-phase L1 short-circuit applied; no deeper boundary or
end-to-end auditor pass was required.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-30 | 14 | 13 | 1 non-blocking / 0 blocking | Codex secure-phase orchestrator |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed at the configured `high` blocking threshold
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-30
