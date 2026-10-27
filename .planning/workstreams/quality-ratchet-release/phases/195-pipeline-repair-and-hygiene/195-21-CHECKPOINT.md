---
phase: 195-pipeline-repair-and-hygiene
plan: 21
status: awaiting_decision
completed_tasks: [1]
current_task: 2
---

# Plan 195-21 approval checkpoint

Last completed phase: 194. Phase195 remains20/21 plans; REL-03 pending and verification7/8 gaps_found. Task1 completed: independent review and repairs, privacy scan, open fix PR, exact-head CI and candidate gate. Task2 awaits two independent irreversible-operation decisions; Task3 has not run. No 195-21-SUMMARY exists because the plan is incomplete.

- PR: https://github.com/szTheory/crosswake/pull/259
- Fix ref/head: fix/secret-mask-structural at 24baafa3d5a65df6f84366209b372b7c5448cdbe
- Base: 7621c0ce0c38edec76cc54209eccf5acf40feddf
- Crosswake CI run40449366324 passed49/49 jobs on that PR head.
- Synthetic checkout: 86bc26ca1fc60a9bd9204f655cefc2b442100555, independently joined to the real classify-change checkout log. It is not the PR head or an actual main merge.
- Scope: exactly script/verify_repository.mjs and test/js/ci_secret_masking.test.mjs. Conventional fix commits affect the next patch release; release PR236 stays open and no release/publish/tag operation is authorized.
- Tests: masking190/190 and fullNode327/327; independent repaired-head review9/9 families and327/327 fullNode; all8 GAP3 findings fixed, zero open. Helper97/97 selftests and candidate mode passed from docs after fixing its cache-free log read and branch-bound selftest export.
- Repository delete_branch_on_merge=true. Merge and automatic remote deletion of fix/secret-mask-structural require separate allow/hold answers, recorded in gap3-delivery.json's current attempt. Neither answer has been received or consumed.

After answers: reread candidate/live readiness. A hold or changed scope stops. Both current allows are required while automatic deletion is enabled; do not toggle the setting. Run gate mode, then use gh pr merge259 --merge --match-head-commit bound to the recorded full head (no admin/force/delete flag). Read actual state before any retry. Continue Task3 exactly as195-21-PLAN: reconcile docs with current origin/main, commit receipt before clean-tree landed execution, and run the landed helper's actual-main processes. It must derive fresh proof; do not supply counts or relabel historical verification as passed. No docs/release PR merge or unrelated deletion is approved.

No phase command is eligible before the two decisions. The next user action is separate merge allow/hold and deletion allow/hold. This is an irreversible-action approval, not human UAT. Existing GR-06 Phase196 and old Phase197 debt remain unchanged. Preserve preexisting untracked privacy evidence. Every commit/push remains under explicit conditional per-file privacy scans and immediate postcommit rescan.

Approval update 2026-10-27T11:44:51Z: user authorized the displayed PR259 merge only. Same attempt/head/base/run/deletion setting rechecked unchanged. Merge answer allow is recorded and unconsumed; automatic remote deletion of fix/secret-mask-structural still needs its separate allow/hold. Do not ask for merge approval again for this unchanged attempt; do not merge while automatic deletion lacks consent.

## Expired attempt reconciliation

At 2026-10-27T11:47:32.343Z, attempt 03b7adfaed1c9423d2a345168b34a211 was reconciled: displayed 2026-10-27T04:47:20.087Z, user replied merge allow, merge permission unconsumed, deletion still pending. PR259/head/base/CI/deletion setting remained unchanged and PR stayed open. The phase helper rejects that old display under its existing30-minute expiry. Automatic approval review rejected a proposed removal of that expiry as an unauthorized authorization-safeguard weakening; the helper was restored byte-identically to committed code. No rejected command ran and no approval transferred.

A fresh attempt now awaits both separate decisions; the earlier merge allow is historical, expired and unconsumed. The new display must include its unchanged PR/head and automatic deletion scope. No phase command is eligible until its two fresh decisions.

2026-10-27T11:52:09.764506+00:00 — User explicitly allowed both operations on current attempt d00052b42c254fba3255930b75da574f: PR259 merge at24baafa3 and automatic remote deletion of fix/secret-mask-structural. Both permissions recorded, unconsumed pending live gate and actual operation.
