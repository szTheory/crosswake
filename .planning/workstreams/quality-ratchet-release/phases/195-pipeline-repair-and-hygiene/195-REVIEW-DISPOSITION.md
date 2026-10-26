---
phase: 195-pipeline-repair-and-hygiene
review: 195-REVIEW.md
review_status: issues_found
findings_total: 11
open: 11
fixed: 0
wontfix: 0
---

# Phase 195: Code Review Disposition

Two findings are critical and both are in REL-03's secret masking (`maskSecretShapes` in `script/verify_repository.mjs`, merged in PR #251). The orchestrator reproduced both on `main`:

- `AWS_SECRET_ACCESS_KEY="abcdefghijk"` passes through unmasked.
- `password = "my secret pass"` is masked only as `my secret ***`.
- `curl -H "Cookie: sid=..."` passes through unmasked.

The existing tests pass only because their seeds are single unquoted words at the start of a line. Nothing is fixed in this pass. Every finding stays `open` until the user picks a route: a gap-closure plan for CR-01, CR-02, WR-01 to WR-03 and WR-04 to WR-06, or carried follow-ups.

| ID | Severity | File | Disposition | Note |
|----|----------|------|-------------|------|
| CR-01 | critical | script/verify_repository.mjs | open | Quoted values (`KEY="v"`, `key = "v"`) are not masked. Reproduced on main. |
| CR-02 | critical | script/verify_repository.mjs | open | Multi-word quoted values leak in part. `Digest`, a mid-line `Cookie:`, URL userinfo and JWTs are not masked. Reproduced on main. |
| WR-01 | warning | script/verify_repository.mjs | open | The keyword rule over-masks prose (`token expired` becomes `token ***`), which hurts diagnosability. |
| WR-02 | warning | script/verify_repository.mjs | open | The line-anchored cookie regex is quadratic on blank-line runs and runs before truncation. |
| WR-03 | warning | test/js/ci_secret_masking.test.mjs | open | `isMaskLine` has no word boundary and counts commented lines, so the guard can pass vacuously. |
| WR-04 | warning | script/verify_published_cleanroom.sh | open | curl has no timeout, retry or protocol pin, so a stalled registry hangs instead of failing. |
| WR-05 | warning | script/verify_published_cleanroom.sh | open | Some network and parse failures are still reported as `not_published`. |
| WR-06 | warning | script/verify_published_cleanroom.sh | open | The POM version check is a loose substring match and does not check groupId or artifactId. |
| IN-01 | info | .github/workflows/* | open | The `actions/checkout` pin `3d3c42e5` carries mixed `# v6`, `# v6.0.2` and `# v7` comments. |
| IN-02 | info | .github/workflows/phase*-proof.yml | open | Dead `event_name == 'schedule'` conditions and "scheduled/manual" notices remain. |
| IN-03 | info | script/verify_published_cleanroom.sh | open | `need_tools` omits `head` and `tr`. |
