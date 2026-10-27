---
context: phase
workstream: quality-ratchet-release
phase: 195-pipeline-repair-and-hygiene
task: 0
total_tasks: 0
status: gaps_found
last_updated: 2026-10-27T01:27:38.005Z
---

# BLOCKING CONSTRAINTS — Read Before Anything Else

> Each constraint below was discovered through failure in this session.

- [ ] CONSTRAINT: privacy gate must gate — a commit or push runs only inside `if bash <privacy-193.sh> <files>; then …; fi`. Never chain the scan with `;` before `git commit`/`git push`.

**Do not proceed until all boxes are checked.**

## Critical Anti-Patterns

| Pattern | Description | Severity | Prevention Mechanism |
|---------|-------------|----------|---------------------|
| Ungated privacy scan | On 2026-10-27 `privacy-193.sh …; … && git commit` committed 195-REVIEW-GAP2.md with 2 hits (rc=1 ignored). Caught before push and amended. | blocking | Commit/push only in the `then` branch of `if bash privacy-193.sh …`; rescan after every new commit before push. |
| zsh path splitting | `bash privacy-193.sh $FILES` in zsh passed all paths as one argument → `privacy: unreadable`. | advisory | Build a zsh array `F=(${(f)"$(…)"})` and pass `"${F[@]}"`, or pass paths literally. |
| Shape-by-shape masking | Two REL-03 rounds closed exactly the named shapes; each deep review then found new ones (round 2: CR-01 quadratic `KEY_LINE`, CR-02 PGP block / key-name assignments / camel-case `SecretAccessKey`). | advisory | Round-3 plan should be keyword-driven (credential words in the identifier), inventory-seeded (one row per repo secret name) and fuzzed for linear time over every rule. |
| code-review skill overwrites | `gsd-code-review 195` writes `195-REVIEW.md`, which would overwrite the round-1 review the disposition cites. | advisory | Dispatch gsd-code-reviewer directly with an explicit new output file (e.g. `195-REVIEW-GAP3.md`). |
| Agent merge refused | The auto-mode classifier refuses `gh pr merge` from the agent even after a bound `allow`. | advisory | After the user's `allow`, hand them `! gh pr merge <N> --merge --match-head-commit <sha>`; reconcile afterward. |

<current_state>
Phase 195 (workstream quality-ratchet-release) — all 18 plans have SUMMARYs; re-verification after PR #257 is `gaps_found`, 7/8 must-haves. Only REL-03 ("CI never echoes secrets") fails; REL-01, REL-02, REL-04, REL-05, REL-06, HYG-01, HYG-02 verified unchanged. REL-03 is reopened (unchecked, Pending) in REQUIREMENTS.md.

Branch `docs/195-closeout` pushed at a8c9dd84 (remote matches; tracked tree clean). Main contains PR #257 merge 7621c0ce. Untracked (intentional, not committed): `195-EVIDENCE/privacy-push-195.txt`, `195-EVIDENCE/privacy-push2-195.txt`.
</current_state>

<completed_work>
- 195-16: escaped-JSON, tuple, quoted-Bearer, next-line, CLI-flag, double-equals masking; stricter `isMaskLine` (GR-01, GR-02, GR-10).
- 195-17: provider tokens, PEM, userinfo/AKIA/JWT widening, query credentials, literal-value exemption, timing inputs (GR-03–05, GR-07–09); GR-06 census 0 for all seven forms.
- Orchestrator: JWT rule left boundary `(?<![A-Za-z0-9_-])` (a4327ad0 red, 283111ee fix) — quadratic `eyJ-` run ~7 s → 1 ms.
- 195-18: PR #257 opened, CI fixed forward (linear-time floor 40 → 250 ms, 12281b87), one no-change re-run of red example-host job by user decision, merged by the user under a bound `allow` (7621c0ce); on-main proof; GR-01–GR-10 dispositions; GR-06 deferred to Phase 196 (ROADMAP carried line).
- Round-2 deep review 195-REVIEW-GAP2.md (1a8b7b74): 2 critical, 6 warning, 4 info. Re-verification 195-VERIFICATION.md (a8c9dd84).
</completed_work>

<remaining_work>
- Round-3 REL-03 gap closure: CR-01 (move trailing `[ \t]*` inside the optional block-indicator group of `KEY_LINE`; add whitespace-run linear-time rows), CR-02 (PEM marker optional `BLOCK`; optional separators in the secret-access-key rule; signing/deploy/auth key names and `secretstring` as credential words; one seed per repository secret name). Triage WR-01–WR-03 into the plan; disposition WR-04–WR-06 and IN-01–IN-04.
- Then ship via PR (gated merge), re-verify, and complete the phase.
- Advisory hooks not yet run for 195: `/gsd-secure-phase 195`, `/gsd-validate-phase 195` (no SECURITY.md / VALIDATION.md).
</remaining_work>

<decisions_made>
- User: re-run the red example-host job once without a change (attempt 2 green); recorded as a no-change retry, cause unknown.
- User: PR #257 merge `allow` bound to head 12281b8; GR-06 route `accept` (deferred to Phase 196).
- Linear-time floor raised to 250 ms (deviates from plan 17's `Math.max(40, …)`); it still separates quadratic from linear by orders of magnitude but cannot see rules no input exercises.
- Only REL-03 reverted from Complete (not all eight phase IDs), since the other seven verified.
</decisions_made>

<blockers>
- None blocking planning. Known tooling noise: `roadmap update-plan-progress 195` returns `missing_phase_details`; STATE.md has no `Progress:` line; gsd-tools needs `--ws=<name>` as one token.
</blockers>

## Required Reading (in order)
1. `AGENTS.md` — approval gates, privacy rules, how changes land
2. `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-VERIFICATION.md` — current `gaps:` block
3. `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-REVIEW-GAP2.md` — round-2 findings CR-01/CR-02, WR-01–06, IN-01–04
4. `195-16/17/18-SUMMARY.md` and `195-REVIEW-DISPOSITION.md` in the same phase dir
5. `script/verify_repository.mjs` and `test/js/ci_secret_masking.test.mjs` on main

## Infrastructure State
- No background processes. No open worktrees. Local `fix/secret-mask-key-forms` deleted (merged); remote branch auto-deleted.
- Privacy scan: `bash "$PWD"/.planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/privacy-193.sh <absolute paths>` (bash only). Write private-key markers as `<BEGIN private-key marker>` placeholders and scratch paths as `<session scratchpad>`.
- Executors here run with `record-dispatch-isolation --isolation none` immediately before each dispatch.

<context>
The masker is an enumerated denylist; the recommendation already given to the user is to make round 3 structural (keyword-driven key names, inventory-seeded rows, fuzzed linear-time over all rules) rather than another batch of named shapes.
</context>

<next_action>
Start with: `/gsd-plan-phase 195 --gaps --ws quality-ratchet-release`
</next_action>
