---
phase: 195-pipeline-repair-and-hygiene
review: 195-REVIEW.md
review_status: issues_found
findings_total: 11
open: 0
fixed: 5
deferred: 4
wontfix: 2
---

# Phase 195: Code Review Disposition

Resolved. The two critical findings (CR-01, CR-02) and WR-01 to WR-03 were in REL-03's secret masking (`maskSecretShapes` in `script/verify_repository.mjs`) and are fixed in PR #256 (merge 5862a3d), with every new test red first (195-14). On the merged code the verifier's four reproduction cases hold: the quoted access key, the mid-line cookie and the multi-word password are masked, and the prose `token expired` is unchanged. The user accepted the recommended route for the rest: WR-04, WR-05, WR-06 and IN-03 are deferred to Phase 197 and IN-01 and IN-02 are wontfix.

| ID | Severity | File | Disposition | Note |
|----|----------|------|-------------|------|
| CR-01 | critical | script/verify_repository.mjs | fixed | Quoted values (`KEY="v"`, `key = "v"`) are not masked. Reproduced on main. Fixed in PR #256 (merge 5862a3d); seeds red first (195-14). |
| CR-02 | critical | script/verify_repository.mjs | fixed | Multi-word quoted values leak in part. `Digest`, a mid-line `Cookie:`, URL userinfo and JWTs are not masked. Reproduced on main. Fixed in PR #256 (merge 5862a3d); seeds red first (195-14). |
| WR-01 | warning | script/verify_repository.mjs | fixed | The keyword rule over-masks prose (`token expired` becomes `token ***`), which hurts diagnosability. Fixed in PR #256 (merge 5862a3d); seeds red first (195-14). |
| WR-02 | warning | script/verify_repository.mjs | fixed | The line-anchored cookie regex is quadratic on blank-line runs and runs before truncation. Fixed in PR #256 (merge 5862a3d); seeds red first (195-14). |
| WR-03 | warning | test/js/ci_secret_masking.test.mjs | fixed | `isMaskLine` has no word boundary and counts commented lines, so the guard can pass vacuously. Fixed in PR #256 (merge 5862a3d); seeds red first (195-14). |
| WR-04 | warning | script/verify_published_cleanroom.sh | deferred | curl has no timeout, retry or protocol pin, so a stalled registry hangs instead of failing. Deferred to Phase 197: its first success criterion reopens script/verify_published_cleanroom.sh to run the install docs; fail-closed already holds on every traced path (195-VERIFICATION.md truth 6). |
| WR-05 | warning | script/verify_published_cleanroom.sh | deferred | Some network and parse failures are still reported as `not_published`. Deferred to Phase 197: its first success criterion reopens script/verify_published_cleanroom.sh to run the install docs; fail-closed already holds on every traced path (195-VERIFICATION.md truth 6). |
| WR-06 | warning | script/verify_published_cleanroom.sh | deferred | The POM version check is a loose substring match and does not check groupId or artifactId. Deferred to Phase 197: its first success criterion reopens script/verify_published_cleanroom.sh to run the install docs; fail-closed already holds on every traced path (195-VERIFICATION.md truth 6). |
| IN-01 | info | .github/workflows/* | wontfix | The `actions/checkout` pin `3d3c42e5` carries mixed `# v6`, `# v6.0.2` and `# v7` comments. Comment-only provenance; the next grouped Dependabot actions bump rewrites the pin comments. |
| IN-02 | info | .github/workflows/phase*-proof.yml | wontfix | Dead `event_name == 'schedule'` conditions and "scheduled/manual" notices remain. No runtime effect; the dead schedule clauses are unreachable and are cleaned when each workflow is next edited. |
| IN-03 | info | script/verify_published_cleanroom.sh | deferred | `need_tools` omits `head` and `tr`. Deferred to Phase 197: its first success criterion reopens script/verify_published_cleanroom.sh to run the install docs; fail-closed already holds on every traced path (195-VERIFICATION.md truth 6). |
