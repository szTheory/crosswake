---
phase: "178"
slug: clean-checkout-and-final-ci
status: verified
threats_open: 0
asvs_level: 1
register_authored_at_plan_time: true
created: "2026-10-13"
---

# Phase 178 — Security

All 15 distinct plan-authored threats have implementation evidence at ASVS level 1. The repeated supply-chain row is consolidated by its stable ID. All five behavioral evidence suites passed 82/82 and the actual final join passed. The eight-path refinement supersedes original six-path references without changing the trust scope.

## Trust Boundaries

Private source bundles enter independent clones; subprocess and GitHub output enter owner-private evidence; only allowlisted source identities, counts and safe causes enter public projections. Remote delivery requires the exact one-use proposal authorization. Mutable hosted identities and policies must still match at the final read barrier.

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-178-01 | Tampering | bundle replay | high | mitigate | prepare_candidate.mjs exact base, eight refined paths, byte digests, containment and real Git negative fixtures | closed |
| T-178-02 | Information disclosure | candidate evidence | high | mitigate | private 0700/0600 storage and allowlisted projection; secret-sentinel fixtures | closed |
| T-178-03 | Information disclosure | runner logs | high | mitigate | local_proof.mjs owner-private captures and public field allowlist | closed |
| T-178-04 | Tampering | dependency setup | high | mitigate | retained tool probes, exact source lockfiles and private manifest-compatible setup; approved Java17 SDK refinement | closed |
| T-178-05 | Repudiation | source identity | high | mitigate | local_proof.mjs validates retained and current HEAD/tree, staged entries, raw index bytes and NUL status; ignored-path classification | closed |
| T-178-06 | Spoofing | runner identity | high | mitigate | ci_evidence.mjs actual checkout logs and pinned action; governed merge and head-only policies distinguished | closed |
| T-178-07 | Repudiation | job/check pagination | high | mitigate | parsePageEnvelope/validateRunGraph complete pages, unique IDs/counts, selected attempt and suite | closed |
| T-178-08 | Information disclosure | job logs | high | mitigate | private subprocess captures and closed public projection; disclosure negative controls | closed |
| T-178-09 | Elevation of privilege | delivery authority | high | mitigate | proposal_delivery.mjs exact one-use allow/card binding; no inherited release authority | closed |
| T-178-10 | Repudiation | uncertain delivery | high | mitigate | atomic consumed claim, read reconciliation and no second write; concurrent and error fixtures | closed |
| T-178-11 | Tampering | proposal diff | high | mitigate | actual eight-file/base/head recheck before authorized push/PR; exact card/body binding | closed |
| T-178-12 | Spoofing | synthetic merge | high | mitigate | fixed canonical Git merge-ref reads and exact immutable final object/local proof; same-tree different-OID denied | closed |
| T-178-13 | Tampering | live drift | high | mitigate | join_proof.mjs canonical GitHub hostname/repositories and start/end run/PR/base/ref/full-policy fingerprint barrier | closed |
| T-178-14 | Repudiation | acceptance | high | mitigate | private raw CI reconstruction plus current local collector; required/advisory outcomes explicitly separated | closed |
| T-178-SC | Tampering | dependency installation | high | mitigate | no package or dependency declaration added; existing source lockfiles used in private setup only | closed |

## Accepted Risks Log

No accepted risks. The earlier missing assertion text remains an execution-history limitation; it is not inferred away or used as a passing proof. No adopter, release or physical-device trust claim is promoted.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|---|---|---|---|---|
| 2026-10-13 | 15 | 15 | 0 | phase execution owner, L1 implementation/fixture inspection |

## Sign-Off

- [x] Every authored threat has a mitigation disposition and implementation evidence.
- [x] Zero accepted-risk substitutions and zero blocking open threats.
- [x] Level 1 short-circuit applies: plan-time register exists and all mitigations were found.
- [x] No implementation changes or Git staging/commits were made for this audit.

Approval: verified 2026-10-13. This checks the bounded phase implementation; it does not grant any new write authority.
