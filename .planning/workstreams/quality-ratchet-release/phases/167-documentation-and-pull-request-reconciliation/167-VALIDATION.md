---
phase: "167"
slug: "documentation-and-pull-request-reconciliation"
status: draft
nyquist_compliant: true
wave_0_complete: false
created: "2026-09-10"
---

# Phase 167 — Validation Strategy

> Per-phase validation contract for documentation authority, parked-adopter truth, and guarded pull-request reconciliation.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on the repository-pinned Elixir/OTP toolchain, Node built-in tests, repository scripts, Swift Package Manager, and read-only GitHub CLI queries |
| **Config file** | `test/test_helper.exs`; repository-policy fixtures under `test/js`; GitHub state queried immediately before and after each remote action |
| **Quick run command** | `mix test test/mix/tasks/crosswake.docs.sync_test.exs test/crosswake/support_matrix test/crosswake/capability_map` |
| **Full suite command** | `mix crosswake.docs.sync --check && mix crosswake.adoption_context.scan && node --test test/js/repository_verification.test.mjs` plus the existing `documentation-contracts`, package/ExDoc, and pull-request-triggered `Crosswake CI` owner |
| **Estimated runtime** | Focused local checks under 120 seconds after the pinned Erlang/Elixir toolchain is available; hosted GitHub checks are observed, not time-thresholded |

---

## Sampling Rate

- **After every task commit:** Run the smallest affected ExUnit or Node test and `mix crosswake.docs.sync --check` once generated projections exist.
- **After every plan wave:** Run the documentation-contract, package/ExDoc, privacy-scan, repository-policy, and docs-only-routing checks touched by that wave.
- **Before `$gsd-verify-work`:** Run the full recurring documentation proof, confirm the post-412 PR #149 candidate and closeout PR heads each received exact-head `Crosswake CI` success, prove both heads remain ancestors of reachable tree-identical default merges, and validate the seven-PR ordinary inventory plus separate recovery receipts against fresh GitHub state.
- **Max feedback latency:** 120 seconds for focused local checks; no threshold for external GitHub queue time.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 167-01-01 | 167-01 | 1 | DOC-01, DOC-02 | T-167-01, T-167-02 | Typed claims reject all D-20 contradictions before support rendering | ExUnit unit + projection | `mix test test/crosswake/capability_map/capability_map_test.exs test/crosswake/support_matrix/renderer_test.exs` | ✅ existing homes; focused cases pending | ⬜ pending |
| 167-01-02 | 167-01 | 1 | DOC-01 | T-167-01, T-167-03 | Both generated projections consume one validated three-claim owner | ExUnit unit + byte parity | `mix test test/crosswake/capability_map test/crosswake/support_matrix/renderer_test.exs` | ✅ existing homes | ⬜ pending |
| 167-01-03 | 167-01 | 1 | DOC-01, DOC-02 | T-167-02 | Public/durable terminology and parked recovery stay privacy-safe | privacy scan + ExUnit | `mix crosswake.adoption_context.scan && mix test test/crosswake/guides/quick_start_adoption_drift_test.exs test/crosswake/planning/first_adopter_context_test.exs` | ✅ existing homes | ⬜ pending |
| 167-02-01 | 167-02 | 2 | DOC-01 | T-167-04, T-167-05, T-167-06 | Docs sync writes deterministically and check mode is observational | Mix task integration | `mix test test/mix/tasks/crosswake.docs.sync_test.exs` | ❌ created by Plan 02 | ⬜ pending |
| 167-02-02 | 167-02 | 2 | DOC-01 | T-167-04, T-167-05 | Multi-record policy rejects unsafe/colliding records and restores outputs | Node + ExUnit negative fixtures | `mix test test/crosswake/proof/phase166_repository_quality_test.exs --only artifact_policy --only generated_contracts && node --test test/js/repository_verification.test.mjs` | ✅ existing homes; fixtures pending | ⬜ pending |
| 167-03-01 | 167-03 | 3 | DOC-01, DOC-02 | T-167-07, T-167-09 | Existing CI owner runs no-write generated and semantic proof | workflow lint + manifest + ExUnit | `actionlint .github/workflows/crosswake-ci.yml && python3 script/check_ci_leaf_manifest.py --self-test && mix test test/crosswake/proof/phase166_repository_quality_test.exs test/crosswake/proof/phase69_docs_contract_parity_test.exs` | ✅ existing homes | ⬜ pending |
| 167-03-02 | 167-03 | 3 | DOC-01 | T-167-07, T-167-08 | Docs-only routing remains visible, narrow, and fail-closed | ExUnit + workflow lint | `mix test test/crosswake/proof/phase165_ci_integrity_test.exs --only classifier --only manifest --only triggers && actionlint .github/workflows/crosswake-ci.yml` | ✅ existing homes | ⬜ pending |
| 167-04-01 | 167-04 | 4 | DOC-01, DOC-02 | T-167-10, T-167-11 | Reader paths retain owner-linked truth and ExDoc topology | ExUnit semantic + docs sync | `mix test test/crosswake/guides/architecture_code_walkthrough_test.exs test/crosswake/proof/phase69_docs_contract_parity_test.exs && mix crosswake.docs.sync --check` | ✅ existing homes | ⬜ pending |
| 167-04-02 | 167-04 | 4 | DOC-01 | T-167-10 | Operator/install/compatibility recovery agrees with executable owners | ExUnit semantic + docs sync | `mix test test/crosswake/guides/release_boundaries_test.exs && mix crosswake.docs.sync --check` | ✅ existing home | ⬜ pending |
| 167-04-03 | 167-04 | 4 | DOC-01, DOC-02 | T-167-11, T-167-12 | Handoff and runbook preserve privacy and Phase 168 stop | privacy scan + ExUnit | `mix crosswake.adoption_context.scan && mix test test/crosswake/guides/release_boundaries_test.exs test/crosswake/guides/quick_start_adoption_drift_test.exs` | ✅ existing homes | ⬜ pending |
| 167-05-01 | 167-05 | 5 | DOC-03 | T-167-14, T-167-15 | Shared validator rejects stale identity, bad CI, scope drift, and unauthorized supersession | Python synthetic self-test | `python3 script/check_phase167_pr_dispositions.py --self-test-resolution` | ❌ created by Plan 05 | ⬜ pending |
| 167-05-02 | 167-05 | 5 | DOC-03 | T-167-13, T-167-14 | All seven setup-java uses share one official immutable v6 OID | workflow lint + ExUnit | `actionlint .github/workflows/crosswake-ci.yml .github/workflows/phase68-proof.yml .github/workflows/release-please.yml && mix test test/crosswake/proof/phase165_ci_integrity_test.exs` | ✅ existing homes | ⬜ pending |
| 167-05-03 | 167-05 | 5 | DOC-03 | T-167-14, T-167-15 | #121 resolution binds exact tested head/base, same-head CI, scope, replacement, and default reachability | live receipt verification | `python3 script/check_phase167_pr_dispositions.py --verify-resolution .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-121-resolution.json --live` | ❌ receipt created by Plan 05 | ⬜ pending |
| 167-06-3A | 167-06 | 6 | DOC-01, DOC-03 | T-167-16, T-167-17 | Historical failures map to shared owners; shallow queue/schema and pinned full-history proof are split | Existing committed RED/GREEN | `python3 script/check_phase167_default_reconciliation.py --self-test && python3 script/check_phase167_default_reconciliation.py --verify-failure-ledger .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/fix-forward-failure-ledger.json` | ✅ RED `367f5b54`, GREEN `7ba66d80`; do not rerun/recommit | ✅ complete |
| 167-06-3B | 167-06 | 6 | DOC-01, DOC-03 | T-167-17, T-167-18 | Authorized hermetic repairs and the exact three formatter checkpoint paths reached a locally green frozen source | Historical formatter + full candidate proof | `mix format --check-formatted && mix test test/crosswake/proof/phase69_docs_contract_parity_test.exs test/crosswake/guides/architecture_code_walkthrough_test.exs test/crosswake/guides/release_boundaries_test.exs && python3 script/check_phase167_default_reconciliation.py --verify-candidate .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-dependency-closure.json --candidate 412dc4d15bed871b4eefabc05ced4567da25c61c --local-clean-checkout` | ✅ repair `7625d3c1`, initial freeze `7d8c3732`, final failed-hosted freeze `412dc4d1` | ✅ complete locally; hosted diagnostic failed |
| 167-06-3C | 167-06 | 6 | DOC-01, DOC-03 | T-167-19, T-167-20 | Frozen 412/PR #149 attempt remains diagnostic-only after 40 success, six failed leaves, and transitive umbrella; no merge/closure occurred | historical exact-head hosted evidence | `python3 script/check_phase167_default_reconciliation.py --verify-post-412-ledger .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/fix-forward-failure-ledger.json --attempt 412dc4d15bed871b4eefabc05ced4567da25c61c` | ❌ post-412 classification pending | ❌ frozen failed diagnostic; superseded by 3D-3F |
| 167-06-3D | 167-06 | 6 | DOC-01, DOC-03 | T-167-29, T-167-31 | Four primary proofs remain passing while the generated cleanup owner is closed inside the exact five-path universe | Existing Node RED/GREEN + closed ledger verification | `node --test test/js/repository_verification.test.mjs --test-name-pattern="generated.contract|repository cleanliness" && python3 script/check_phase167_default_reconciliation.py --self-test && python3 script/check_phase167_default_reconciliation.py --verify-post-412-ledger .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/fix-forward-failure-ledger.json --owner generated_contract_cleanup` | ✅ RED `24fac450`, GREEN `60d77d61`, ledger `5a132620`; do not rerun/recommit | ✅ complete |
| 167-06-3E | 167-06 | 6 | DOC-01, DOC-03 | T-167-30, T-167-31 | Invalid a35 diagnostic stays consumed; one replacement uses job-level env so later upload conditions see activation, proves diagnostic suppression plus normal artifact behavior, emits only closed category/owner facts, and preserves Phase41 as no-edit nondeterminism before browser GREEN | Workflow-scope RED/GREEN + Node redaction/artifact authority + one replacement live receipt | `actionlint .github/workflows/crosswake-ci.yml && node --test test/js/repository_verification.test.mjs --test-name-pattern="browser stage|browser proof|hosted diagnostic|failure artifact|redaction" && python3 script/check_phase167_default_reconciliation.py --verify-post-412-ledger .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/fix-forward-failure-ledger.json --owner browser --live` | ✅ local RED `1e3469dd`; ❌ a35/run 34635587034 invalid and original 1/1 consumed; replacement diagnostic/GREEN pending | ⬜ pending |
| 167-06-3F | 167-06 | 6 | DOC-01, DOC-03 | T-167-19, T-167-20, T-167-31 | 412 manifest is invalidated; exactly one new manifest-only candidate uses the final allowance, passes all 47 exact-head checks, merges, then and only then supersedes #148/#110 | complete local candidate + live resolution/reconciliation | `python3 script/check_phase167_default_reconciliation.py --verify-candidate .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-dependency-closure.json --candidate HEAD --local-clean-checkout && python3 script/check_phase167_default_reconciliation.py --verify-resolution .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-reconciliation-resolution.json --live && python3 script/check_phase167_default_reconciliation.py --verify-local-reconciliation .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-reconciliation-resolution.json` | ❌ sole recaptured manifest and receipts pending | ⬜ pending |
| 167-07-01 | 167-07 | 7 | DOC-03 | T-167-20, T-167-21 | Phase branch remains checked out while isolated #105 work preserves deterministic single-resume behavior | Swift package tests | `swift test --package-path packages/crosswake-shell-core-ios` | ✅ existing home | ⬜ pending |
| 167-07-02 | 167-07 | 7 | DOC-03 | T-167-20, T-167-22 | #105 is exact-head green/merged; receipt commits first, then fresh protected default merges into the phase branch with exact parent/tree/ancestry/runtime proof before Plan 08 | Swift + live receipt + fixed-argv integration proof | `swift test --package-path packages/crosswake-shell-core-ios && python3 script/check_phase167_pr_dispositions.py --verify-resolution .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-105-resolution.json --live && git fetch --no-tags origin main && sh -c 'receipt=.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-105-resolution.json; if ! receipt_oid="$(git log -1 --format=%H -- "$receipt")"; then exit 1; fi; if ! branch="$(git branch --show-current)"; then exit 1; fi; if ! first_parent="$(git rev-parse HEAD^1)"; then exit 1; fi; if ! second_parent="$(git rev-parse HEAD^2)"; then exit 1; fi; if ! fresh_default="$(git rev-parse FETCH_HEAD)"; then exit 1; fi; if ! untracked="$(git ls-files --others --exclude-standard)"; then exit 1; fi; expected="$(printf "%s\n" .planning/workstreams/quality-ratchet-release/config.json .planning/workstreams/quality-ratchet-release/milestone.lock .planning/workstreams/quality-ratchet-release/state.json)"; test "$branch" = agent-phase167-fixforward && test "$first_parent" = "$receipt_oid" && test "$second_parent" = "$fresh_default" && git merge-base --is-ancestor 367f5b5491384594a652d137a03933fa3a89418a HEAD && git merge-base --is-ancestor "$receipt_oid" HEAD && git diff --quiet FETCH_HEAD HEAD -- packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift && git diff --quiet && git diff --cached --quiet && test "$untracked" = "$expected" && test "$(shasum -a 256 .planning/workstreams/quality-ratchet-release/config.json)" = "05b25ad604490dba4c12df84c624d04b1c7bae454ecd78a262dd1b97b68c1a28  .planning/workstreams/quality-ratchet-release/config.json" && test "$(shasum -a 256 .planning/workstreams/quality-ratchet-release/milestone.lock)" = "fd4c22c0f07449f02acc487c3100eed7a10edb1382d63807dd4003a54bfd2943  .planning/workstreams/quality-ratchet-release/milestone.lock" && test "$(shasum -a 256 .planning/workstreams/quality-ratchet-release/state.json)" = "6cf0413c5cc52eb4f9c10ba497f82614608a54659e10bd48172bad2d9765dff4  .planning/workstreams/quality-ratchet-release/state.json"'` | ❌ receipt and phase-branch integration merge created by Plan 07 | ⬜ pending |
| 167-08-01 | 167-08 | 8 | DOC-03 | T-167-23, T-167-25 | Seven ordinary dispositions, four release deferrals, and separate recovery receipts fail closed | Python synthetic + live artifact | `python3 script/check_phase167_pr_dispositions.py --self-test && python3 script/check_phase167_pr_dispositions.py --verify .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-dispositions.json --live` | ✅ base validator; seven-row/recovery modes pending | ⬜ pending |
| 167-08-02 | 167-08 | 8 | DOC-01, DOC-02, DOC-03 | T-167-24, T-167-26 | Unprotected phase branch stores payload-only scope; runtime derives candidate identity and proves exactly one manifest delta before protected-default merge | Plan 08 fixed closeout-candidate mode + hosted recurring-contract gate | `python3 script/check_phase167_pr_dispositions.py --verify-closeout-candidate .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-scope.json --candidate HEAD --local-clean-checkout && python3 script/check_phase167_pr_dispositions.py --verify .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-dispositions.json && mix crosswake.docs.sync --check && mix crosswake.adoption_context.scan && script/check_phase166_clean_checkout_engineering_quality.sh && python3 script/check_ci_leaf_manifest.py --self-test` | ❌ payload-only scope and derived-candidate mode pending | ⬜ pending |
| 167-08-03 | 167-08 | 8 | DOC-01, DOC-02, DOC-03 | T-167-23, T-167-25, T-167-26, T-167-27 | Resolution and all later commits remain on phase branch; local main ref advances only clean/no-pending; five-name Phase 168 ownership stays non-circular | live receipt + name/owner lifecycle + fixed-argv phase-branch reconciliation | `python3 script/check_phase167_pr_dispositions.py --verify-closeout-resolution .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-resolution.json --live && python3 script/check_phase167_pr_dispositions.py --verify-local-reconciliation .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-resolution.json --scope .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-scope.json && mix crosswake.docs.sync --check && mix crosswake.adoption_context.scan && python3 script/check_phase167_pr_dispositions.py --verify .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-dispositions.json --live` | ❌ derived-candidate receipt and name/owner-only handoff pending | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/crosswake.docs.sync_test.exs` — write mode, successful `--check`, drift failure, no-write proof, and exact remediation output.
- [ ] Focused canonical-claim fixtures — the three required claim layers and all five D-20 impossible combinations.
- [ ] Multi-record repository-policy fixtures — one/multiple argv, duplicate source/output, unordered output, unsafe argv, undeclared output, and restoration behavior.
- [ ] Focused parked-state/current-claim assertion — codename-only durable state and the exact external route/device resume gate.
- [x] Phase-local resolution verifier — introduced in Plan 05; Plan 06 replaces obsolete ordered transitions with root-cause/ancestry proof and Plan 08 extends seven-PR, recovery, and closeout authority.
- [ ] Restore or select the repository-pinned Erlang/Elixir toolchain before any local Mix verification claim.

---

## Manual-Only Verifications

All phase behavior and evidence evaluation is automated. If GitHub credentials or branch permissions are unavailable, a maintainer may supply that external authority, but exact-SHA/check assertions and post-action evidence remain automated. PRs #57, #115, #146, and #147 are explicit non-mutation boundaries; their merges require separate Phase 168 release approval.

---

## Security Threat References

| Ref | Threat | Required Mitigation |
|-----|--------|---------------------|
| T-167-01 | Reference-host evidence is rendered as current first-adopter support | Model evidence subject, source binding, and activation independently; reject contradictory combinations before rendering. |
| T-167-02 | Generated and authored documents become competing truth stores | Change executable owners first, regenerate byte-stable projections, and protect authored prose with semantic assertions only. |
| T-167-03 | A documentation parity check mutates or stages the worktree | Render in memory for `--check`; compare bytes without invoking writers; preserve index and working-tree state. |
| T-167-04 | A second artifact registry or CI context creates split authority | Extend `script/repository_artifact_policy.json` and the existing documentation/package owners only. |
| T-167-05 | Adopter identity, payload, credential, device, or private-route data leaks into docs/evidence | Use closed low-cardinality fields and the existing destination-aware privacy scanner; never echo untrusted values. |
| T-167-06 | PR state changes between observation and mutation | Refresh exact head/base/check state immediately before each action and stop on mismatch. |
| T-167-07 | A stale or release-triggering PR is merged accidentally | Apply only the locked disposition for each exact PR number; keep #57/#115/#146/#147 open and deferred to Phase 168. |
| T-167-16 | Failed jobs drive symptom-by-symptom widening or leak raw logs | Group allowlisted conclusions by shared owner, reproduce locally, and retain closed rule IDs only. |
| T-167-17 | Tree identity or shallow checkout discards Phase 166 evidence history | Preserve ancestry for pinned full-history range/tree proof; separately prove recurring remediation queue/schema validation in a shallow repository because ancestry alone is insufficient there. |
| T-167-18 | CI hermeticity is obtained by weakening proof or dynamically widening repairs | Require the existing `367f5b54` RED, shallow GREEN, a closed repair universe intersected with plan files, exactly three added formatter test paths, and unchanged recurring leaf/failure authority. |
| T-167-19 | Hosted CI proves different bytes from local clean proof | Freeze one commit, require exact remote head, and invalidate on any later source change. |
| T-167-20 | Failed PRs close before replacement authority exists | Verify replacement merge first, then exact-head close #148/#110 unmerged with fixed markers. |
| T-167-24 | Local recovery/planning truth never reaches protected default | Freeze the pre-closeout source and land its exact tree through one closeout PR. |
| T-167-26 | CI is attributed to a default merge SHA the workflow never tests | Bind CI to exact closeout PR head; prove merge/default authority by reachability and identical tree OIDs. |
| T-167-27 | Post-merge handoff claims evidence that cannot yet exist | Phase 167 validates only five exact names plus the Phase 168 owner; Phase 168 later binds final blobs and protected-default landing in its own scope/receipt. |
| T-167-28 | Protected local main receives executor commits, the phase branch omits newly merged default bytes, or reconciliation loses history/runtime state | Require unprotected `agent-phase167-fixforward`, receipt-first no-rewrite integration of fresh protected default with exact parents/source blob/ancestry/runtime proof, optional clean no-pending local-main ref update only afterward, and all later commits on the integrated phase branch without config weakening/reset/clean/stash/switch. |
| T-167-29 | Shared generated cleanup is repaired by guessing or by changing transitive platform owners | Require a job-equivalent RED and choose only the evidence-proven fully provisioned owner or explicit common prerequisite closure inside the exact generated five-path universe. |
| T-167-30 | Hosted browser diagnosis leaks private logs/artifacts, cannot identify an owner, or promotes an empty-version clue into causality | Preserve invalid a35 evidence, then prove job-level env reaches later upload conditions; require diagnostic suppression, normal-path artifact retention, closed mapper/redaction, unchanged proof failure, and one replacement push before evidence-bound repair. |
| T-167-31 | Repeated recovery attempts widen scope, silently retry Phase41, or mutate PR state before proof | Record original diagnostic 1/1 consumed; permit exactly one replacement diagnostic and one final PR #149 update; suppression/category/Phase41 recurrence, exhaustion, a new owner, or any red/missing final check checkpoints with all three recovery PRs open/unmerged. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is under 120 seconds for focused local checks.
- [x] `nyquist_compliant: true` is set in frontmatter after validation.

**Approval:** pending
