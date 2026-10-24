# v27.0 debt disposition

Source: the `tech_debt` list in the [v27.0 audit](../v27.0-MILESTONE-AUDIT.md). None of these items blocks a requirement.

## Resolved by this closeout

- Stale STATE.md (status, stopped_at, Exact Next Action, Session block, Operator Next Steps) — rewritten.
- Stale `.continue-here.md` (`phase_193_pr2_awaiting_merge`) — rewritten.
- ROADMAP conditional Phase 193 line, "in progress" headers, missing 193 completion date, and 191/192 "verification pending" progress rows — fixed in the archive copy; the workstream ROADMAP is collapsed.
- REQUIREMENTS FIX-01..07 checkboxes `[ ]` while traceability said Complete — ticked in the archive copy.
- v26 debt (188 WR-01, 188 WR-08, unpinned `g()`, 185 WR-02, 187 WR-02, guard pin 249 vs 253, 186 WR-01 owner decision) — closed by FIX-01..07 and landed on `main`.

## Carried

| Item | Origin | Trigger to act |
|---|---|---|
| Keep or remove the `crosswake-integration-191` clone: its remote-tracking tips exist in no backup. Back them up, then remove the clone. | 193 ledger (`ref_tip_unprotected`) | Next local cleanup |
| Handoffs say 8 unbacked tips; the ledger has 5 `R-POST-REF` rows plus "remote 2" on R-POST-LOC-01. Reconcile the count when backing up the clone. | 193 audit | Same as above |
| Ledger header `removed: 300` counts 55 rows that were already absent (245 actually removed). The totals are consistent; the label overstates. The ledger is evidence and stays unchanged. | 193 audit | None; recorded here |
| 193-VERIFICATION.md was written by the executor, not by an independent verifier. The audit re-checked its claims. | 193 audit | None; recorded here |
| FIX-01..03 successor scripts run only from the Phase 190 folder; no recurring gate on `main`. Promoting them is new scope. | 190 D-01/D-02 | Next change to privacy scan or gate tooling |
| 190 follow-ups: `run-once-05-190.sh` /tmp vs /private/tmp path text check; unformatted `native_shell_upgrade_test.exs` at base; five Phase170 full-suite-only failures. | 190-VERIFICATION | Next full-suite or formatter change |
| Phase 190-origin privacy residue in candidate history (1 home path, 1 username), accepted and deferred to a hygiene seed. | phase-gate-191 | Before any history rewrite or public mirror |
| 192 review: 0 critical / 8 warnings / 6 info, open; the kept items, credential masking in CI failure output first, are in SEED-025. | 192-REVIEW-DISPOSITION | SEED-025 triggers |
| 189 review: five findings deferred with reasons. | 189-REVIEW-DISPOSITION | As recorded there |
| See It Run Collateral on the 192 merge commit was `in_progress` at verification (advisory). | 192 audit | None; advisory |
| Nyquist validation skipped at audit (VALIDATION.md exists for 189–193). | audit | `$gsd-validate-phase` if wanted |
| Release PR #236 open and on hold; merging or publishing it is a separate decision. | 189 dispositions | User decision |

Parked, unchanged: physical signed-iPhone run; the first adopter's sanitized route handoff (`--ws first-b2c-adopter-readiness`).
