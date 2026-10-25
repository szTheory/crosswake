---
phase: 178-clean-checkout-and-final-ci
plan: "05"
type: execute
wave: 4
depends_on: ["178-04"]
files_modified:
  - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/hosted-ci-proof.json
  - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-local-proof.json
  - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.mjs
  - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-acceptance.json
autonomous: true
requirements: [MAINT-07, MAINT-08]
estimate: {tokens: 30000, raw_tokens: 30000, tasks: 3, confidence: low}
must_haves:
  truths:
    - "D-16–D-20: hosted CI is complete and green for the observed synthetic merge checkout commit on one bound run/attempt, with every required leaf/control/umbrella and current policy context/app accounted for; head-only proof is separate."
    - "D-17/D-23: the exact unmerged runner-tested commit object is preserved/fetched into a new independent full clone, and a new complete --all run on that immutable OID passes with private logs and unchanged source identity."
    - "D-24/D-25: MAINT-07/08 close only after exact local/hosted commit agreement; reports name command, source, stages/checks, cause, source change and next action plainly without implying merge or release."
  artifacts:
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/hosted-ci-proof.json
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-local-proof.json
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.test.mjs
    - .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-acceptance.json
  key_links:
    - "Observed job checkout OID/run attempt -> immutable Git object in fresh clone -> --all retained evidence -> strict same-OID join with current CI graph/policy."
  prohibitions:
    - statement: "MUST NOT label an unmerged reviewed candidate as merged main, a shipped package or first-adopter device support."
      status: unresolved
---

<objective>
Observe the actual governed CI run, repeat the full local verifier on the exact runner-tested commit, and close both requirements only on a strict source join. Purpose: give maintainers reproducible final proof rather than a nearby green run. Output: allowlisted hosted/local evidence and a machine-checked acceptance record.
</objective>

<execution_context>
@<home>/.codex/gsd-core/workflows/execute-plan.md
@<home>/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-CONTEXT.md
@.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-02-SUMMARY.md
@.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-03-SUMMARY.md
@.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-04-SUMMARY.md
</context>

## Artifacts this phase produces

| Producer | Symbol, flag or file and private handoff | Consumer |
|---|---|---|
| 178-05 T1 | `hosted-ci-proof.json`; owner-private bound run/attempt job logs and refreshed policy pointers | 178-05 T2/T3 |
| 178-05 T2 | `final-local-proof.json` selected with `CROSSWAKE_178_PROOF_KIND=final`; separate owner-private exact-commit run root | 178-05 T3 |
| 178-05 T3 | `join_proof.mjs` `--self-test`/`--check`, `join_proof.test.mjs`, `final-acceptance.json` | Phase verifier and workstream requirement/state handoff |

Plan05 reads the immutable candidate, preliminary local, CI policy and delivery bindings through the owner-private root, checks each against its allowlisted public identity and resolves them to the actual hosted run. Raw roots and logs never enter these public artifacts.

<tasks>
<task type="auto">
  <name>Task 1: Observe complete hosted CI and bind every relevant checkout to one run attempt</name>
  <reversibility rating="reversible">Read-only CI observation and phase evidence can be refreshed when a run changes.</reversibility>
  <files>.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/hosted-ci-proof.json</files>
  <read_first>.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/delivery-observation.json; .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci-contract.json; .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.mjs; owner-private ci-policy-binding.json and delivery-binding.json under CROSSWAKE_178_PRIVATE_HANDOFF_ROOT; /private/tmp/crosswake-177-source/crosswake/.github/workflows/crosswake-ci.yml</read_first>
  <action>Per D-15–D-20/D-23, collect the actual PR run with ci_evidence.mjs --collect, not a historical green. Use the exact observed run ID/attempt and complete paginated attempt jobs/checks. Bind canonical repository, workflow path and pinned version, event, PR/head/base, suite/check IDs, URL, observation time and actual per-job checkout OIDs from retained allowlisted checkout log evidence. Evaluate classify-change, every selected-source proof leaf and merge-blocking-crosswake-ci against classifier-authorized skips and refreshed required context/app policy from BOTH base-branch protection and effective active rules for that base, including applicable repository and inherited organization rulesets. Require complete successful reads and explicit successful-empty effective-rule evidence where no rules apply; missing/inaccessible policy blocks. Label release-candidate-full-proof head checkout separately. Re-read PR/base/head/run/attempt/both policy sources before accepting; a new attempt, changed merge ref or missing Git object invalidates this observation. Raw job logs remain private. On a CI failure, repair only demonstrated bounded defects, renew source candidate and replay Plan02–05 on the new identity; preserve the failed run cause and never re-use it as green. The fallback MAINT-08 boundary assumption closes only when zero/one/multiple-page and absent/latest-attempt negative fixtures remain nonpassing; its precision assumption closes only when all job/check IDs and counts are unique/complete and exact 40-hex checkout OIDs are bound.</action>
  <verify><automated>node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/ci_evidence.mjs --collect</automated><fails_when>Nonzero exit, missing page/job/check, absent observed checkout, wrong attempt, stale PR/source, inaccessible policy, failed/neutral/cancelled/unauthorized-skipped leaf, or control/umbrella not successful.</fails_when></verify>
  <acceptance_criteria>hosted-ci-proof.json identifies one unmerged reviewed merge commit, its run/attempt and complete authorized graph under both policy sources; missing authority or provenance blocks. MAINT-08 boundary and precision fallback assumptions have explicit passing negative controls or remain flagged with a safe cause.</acceptance_criteria>
  <done>Hosted proof is tied to the commit actually checked out by the governed jobs.</done>
</task>

<task type="auto">
  <name>Task 2: Verify the exact runner-tested merge object from a fresh clean clone</name>
  <reversibility rating="reversible">A fresh proof clone and retained private evidence can be discarded without altering remote history.</reversibility>
  <files>.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-local-proof.json</files>
  <read_first>.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/hosted-ci-proof.json; .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/local_proof.mjs; owner-private candidate-binding.json and local-proof-binding.json under CROSSWAKE_178_PRIVATE_HANDOFF_ROOT; /private/tmp/crosswake-177-source/crosswake/script/verify_repository.sh; /private/tmp/crosswake-177-source/crosswake/script/repository_verification_stages.json</read_first>
  <action>Per D-08–D-14/D-17/D-23, preserve/fetch the exact observed synthetic merge OID as an immutable Git object into a new independent full clone. Fetch by OID if supported or fetch the PR merge ref and require its resulting object to equal the observed OID before detaching; do not trust a moving ref or equal tree alone. Assert canonical repo, expected six-file source delta, clean tracked/index/nonignored status and independent HEAD/tree/index identity. Reprobe every selected-manifest tool and resolve only exact lock-bound dependencies in this fresh clone, using Plan02 setup discipline. Run a new single `script/verify_repository.sh --all` with distinct explicit private capture/run roots; retain the nine result lines, eight executed-stage logs, raw stdout/stderr and NUL before/final snapshots privately. Preflight has a summary result rather than its own stage log in the attested facade. Set GIT_OPTIONAL_LOCKS=0 on every supplemental before/after Git status, index hash and ignored-path inspection subprocess, independently of the facade's internal snapshots. Collect final-local-proof.json using local_proof.mjs --collect with CROSSWAKE_178_PROOF_KIND=final and the owner-private invocation record. Require HEAD/tree/index/status unchanged and ignored outputs policy-compliant. The MAINT-07 unclassified fallback assumption is accepted only if this final exact runner-tested OID has a complete nine-result --all PASS and unchanged independent snapshots; otherwise retain it flagged with a safe cause. If the object is unavailable, drifted, or cannot pass, keep MAINT-07/08 pending. Do not merge the PR or use preliminary local proof as a substitute.</action>
  <verify><automated>script/verify_repository.sh --all</automated><fails_when>Nonzero exit, missing required tool/dependency, blocked or missing stage, generated drift or source mutation; invoke in the fresh exact observed-commit clone with its private run-root/capture-root environment.</fails_when><automated>node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/local_proof.mjs --collect</automated><fails_when>Nonzero exit, missing retained output, wrong OID/tree/index, dirty NUL status, unexpected ignored residue, or fewer than nine ordered PASS stages; use CROSSWAKE_178_PROOF_KIND=final.</fails_when></verify>
  <acceptance_criteria>final-local-proof.json names exactly the observed governed merge OID, with one complete nine-stage --all PASS, eight executed-stage logs, preflight summary and separately retained nonmutating private status/index snapshots. MAINT-07 unclassified is resolved by this exact-commit acceptance or remains flagged pending.</acceptance_criteria>
  <done>The unmerged reviewed source has reproducible full local verification at the actual runner-tested commit.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Join exact local/hosted proof and produce a plain maintainer handoff</name>
  <reversibility rating="reversible">The phase-local join and pending/complete evidence projection can be recomputed from retained inputs.</reversibility>
  <files>.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.mjs, .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.test.mjs, .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-acceptance.json</files>
  <read_first>.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/final-local-proof.json; .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/hosted-ci-proof.json; .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/candidate-source.json; .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_phase_acceptance.mjs; .planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/check_phase_acceptance.test.mjs; owner-private candidate-binding.json, local-proof-binding.json, ci-policy-binding.json and delivery-binding.json under CROSSWAKE_178_PRIVATE_HANDOFF_ROOT; .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md; .planning/workstreams/quality-ratchet-release/STATE.md</read_first>
  <behavior>Join test accepts only actual retained local and hosted records on the same exact 40-hex commit, complete --all stage order, unchanged before/after HEAD/tree/index/NUL status, bound PR/run/attempt, current policy and complete graph. Tree-equal but SHA-different, previous attempt, drifted PR, preliminary-only local proof, fabricated facade JSON, missing stage or raw private field fails. Successful output states unmerged reviewed candidate; blocked output names safe cause/next action without a green flag.</behavior>
  <action>Per D-17/D-21/D-24/D-25, implement a stdlib join with --self-test and --check modes, then use --check on the actual retained records. Follow the assigned Phase177 check_phase_acceptance.mjs and check_phase_acceptance.test.mjs analogs for exact-identity joins, closed allowlisted errors, and synthetic single-dimension tampering regressions; use their patterns without copying stale Phase177 acceptance criteria. Recheck live PR/run/source/policy just before acceptance; compare final local commit exactly to observed governed merge-checkout OID, not merely tree or PR head. Close MAINT-07 only for the clean full local record and MAINT-08 only for green governed CI on that same OID. Emit final-acceptance.json with allowlisted command, source, stage/check counts, safe cause, source-change fact and next action. If either gate fails, keep both pending as appropriate and retain exact eligible GSD handoff. Preserve Phase175 8/9 and REL-10 breach, Phase176's 119 rows/private archive and unresolved historical readers, and the adopter's sanitized-input/signed-device gates. Do not automatically merge, tag, publish, archive v24 or retire private recovery. Let the phase verifier and workstream orchestrator update requirement/state/roadmap status after checking this evidence; no human UAT replaces automated assertions.</action>
  <verify><automated>node --test .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.test.mjs</automated><fails_when>Nonzero exit or any wrong-commit, stale-attempt, missing-output or private-data negative case is accepted.</fails_when><automated>node .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/join_proof.mjs --check</automated><fails_when>Nonzero exit, local/hosted commit mismatch, incomplete proof or changed live binding.</fails_when></verify>
  <acceptance_criteria>final-acceptance.json can mark both requirements passed only when exact source and both gates agree, and the three fallback assumptions have their owning acceptance checks satisfied; otherwise it records pending status, flagged assumption and one concrete next action.</acceptance_criteria>
  <done>Maintainer sees an honest final source/proof result; phase verifier has enough evidence to accept or reject MAINT-07/08 independently.</done>
</task>
</tasks>

<threat_model>
## Trust Boundaries
| Boundary | Description |
|---|---|
| Hosted CI observation to local clone | A moving PR ref may point at another commit. |
| Local/hosted evidence to completion status | Partial or wrong-source proof can falsely complete requirements. |

## STRIDE Threat Register
| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|---|---|---|---|---|---|
| T-178-12 | Spoofing | synthetic merge source | high | mitigate | Fetch immutable observed OID, verify object after fetch and require exact same-OID local --all. |
| T-178-13 | Tampering | live PR/run drift | high | mitigate | Re-read PR/run/attempt/policy before final join; any changed identity invalidates proof. |
| T-178-14 | Repudiation | final acceptance | high | mitigate | Join complete private-backed stage/check evidence and reject absent, old, or fabricated outputs. |
| T-178-SC | Tampering | npm/pip/cargo installs | high | mitigate | Reuse exact lock-bound dependency setup from Plan02; add no new package. |
</threat_model>

<verification>Collect hosted run/attempt, rerun the full existing verifier on the exact observed OID, and pass negative-tested strict join.</verification>
<success_criteria>Both requirements have exact same-commit proof or remain pending with a named cause; no release or merge is implied.</success_criteria>
<output>Create 178-05-SUMMARY.md with plain command/source/result/cause/next action and linked safe evidence.</output>
