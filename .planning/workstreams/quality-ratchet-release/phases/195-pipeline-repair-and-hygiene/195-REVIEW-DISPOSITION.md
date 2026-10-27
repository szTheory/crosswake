---
phase: 195-pipeline-repair-and-hygiene
review: 195-REVIEW.md
review_status: issues_found
review_gap: 195-REVIEW-GAP.md
findings_total: 41
open: 0
fixed: 34
deferred: 5
wontfix: 2
---

# Phase 195: Code Review Disposition

Resolved. The two critical findings (CR-01, CR-02) and WR-01 to WR-03 were in REL-03's secret masking (`maskSecretShapes` in `script/verify_repository.mjs`) and are fixed in PR #256 (merge 5862a3d), with every new test red first (195-14). On the merged code the verifier's four reproduction cases hold: the quoted access key, the mid-line cookie and the multi-word password are masked, and the prose `token expired` is unchanged. The user accepted the recommended route for the rest: WR-04, WR-05, WR-06 and IN-03 are deferred to Phase 197 and IN-01 and IN-02 are wontfix. The gap review of PR #256 (195-REVIEW-GAP.md) raised ten more findings, GR-01 to GR-10. GR-01 to GR-05 and GR-07 to GR-10 are fixed in PR #257 (merge 7621c0c) and verified on the merged code; GR-06 is deferred to Phase 196 by the user's accepted route.

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
| GR-01 | critical | script/verify_repository.mjs | fixed | Credential keys in escaped-JSON, tuple, quoted-Bearer, next-line, YAML block, CLI-flag, `curl -u` and double-equals forms leaked. Reproduced on main; all nine forms now masked on the merged code (195-EVIDENCE/mask-gr-main-195.txt). Fixed in PR #257 (merge 7621c0c); seeds red first (195-16/195-17). |
| GR-02 | critical | test/js/ci_secret_masking.test.mjs | fixed | `isMaskLine` accepted a single-quoted `::add-mask::$VAR`, which masks nothing; the guard now rejects single-quoted and unterminated masks. Fixed in PR #257 (merge 7621c0c); seeds red first (195-16/195-17). |
| GR-03 | warning | script/verify_repository.mjs | fixed | Provider tokens with hyphens (`sk-`, `xox`, `npm_`) and short `gh*_` tokens were not masked. Fixed in PR #257 (merge 7621c0c); seeds red first (195-16/195-17). |
| GR-04 | warning | script/verify_repository.mjs | fixed | PEM private-key bodies on separate lines leaked. Fixed in PR #257 (merge 7621c0c); seeds red first (195-16/195-17). |
| GR-05 | warning | script/verify_repository.mjs | fixed | Empty-user and slash-containing userinfo, access key IDs after an underscore or with trailing characters, two-segment JWTs and `Bearer realm` had shape holes. The JWT rule gained a left boundary after hyphens (a JWT directly after a hyphen is no longer masked by that rule). Fixed in PR #257 (merge 7621c0c); seeds red first (195-16/195-17). |
| GR-06 | warning | test/js/ci_secret_masking.test.mjs | deferred | Deferred to Phase 196: its goal is checks that cannot pass by asserting nothing; the live-tree census found 0 secret-referencing lines in each of the seven unparsed forms (195-EVIDENCE/mask-gr-warn-control-195.txt). |
| GR-07 | warning | script/verify_repository.mjs | fixed | nil/true/false/null/undefined values and a left boundary on authorization fixed; numeric values and header-shaped Authorization:/cookie: prose stay masked by design (safe direction), pinned as ACCEPTED_OVERMASK rows. Fixed in PR #257 (merge 7621c0c); seeds red first (195-17). |
| GR-08 | warning | test/js/ci_secret_masking.test.mjs | fixed | Linear-time and guard tests were partly vacuous or brittle; backslash and mixed-quote inputs added. The linear-time floor is 250 ms (raised from 40 ms after shared-runner noise; the old JWT rule still fails it). Fixed in PR #257 (merge 7621c0c); seeds red first (195-16/195-17). |
| GR-09 | info | script/verify_repository.mjs | fixed | Query signature and key parameters and plural or `privatekey` keys were unmasked. Fixed in PR #257 (merge 7621c0c); seeds red first (195-16/195-17). |
| GR-10 | info | script/verify_repository.mjs | fixed | `maskValue` assigned replacement structure by argument position; made explicit. Fixed in PR #257 (merge 7621c0c); seeds red first (195-16/195-17). |

## Round-qualified GAP2 and GAP3 dispositions after PR259

All following findings are fixed on actual main `b8398c38e7d92c8bb99dcbc87fdb2370a47e6e97`; candidate CI49/49, independent repaired-head review and landed live-process proof cover their exact families. Earlier rows remain historical. GR-06 retains its accepted Phase196 receiver; original cleanroom debt remains Phase197; no new deferral was accepted.

| ID | Severity | File | Disposition | Note |
|----|----------|------|-------------|------|
| GAP2-CR-01 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 padding credential whitespace matrix`, `round3 separator head adversaries`, `round3 timing quadratic copied control` |
| GAP2-CR-02 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 structural repository signing assignment`, `round3 inventory all workflow secret names`, `round3 private key armor complete layouts`, `round3 review keyed armor priority` |
| GAP2-WR-01 | warning | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 container inspect values`, `round3 tuple wrapped values`, `round3 review escaped json containers`, `round3 review identifier and cli parity` |
| GAP2-WR-02 | warning | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 name-value record isolation`, `round3 review name value record boundaries`, `round3 review name value unrelated records` |
| GAP2-WR-03 | warning | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 private key armor complete layouts`, `round3 private key armor malformed boundaries`, `round3 armor bounded adversaries`, `round3 review keyed armor priority` |
| GAP2-WR-04 | warning | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 residual exact diagnostic pins`, `accepted over-mask pinned: changeset_blank`, `prose round-trips unchanged: short numeric container`, `round3 review sigil diagnostic boundaries` |
| GAP2-WR-05 | warning | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 guard exact stdout registration`, `round3 guard rejected execution contexts`, `round3 review persistent stdout context` |
| GAP2-WR-06 | warning | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 raw window and inventory controls`, `round3 rule family adversaries`, `round3 separator head adversaries`, `round3 review curl missing separators bounded` |
| GAP2-IN-01 | info | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 residual named credential forms`, `round3 residual exact diagnostic pins`, `round3 residual rule adversaries`, `round3 review identifier and cli parity` |
| GAP2-IN-02 | info | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 references bracket and github token`, `round3 review persistent stdout context` |
| GAP2-IN-03 | info | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `linear time baseline`, `round3 padding credential whitespace matrix`, `round3 residual rule adversaries`, `round3 review curl missing separators bounded` |
| GAP2-IN-04 | info | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 residual named credential forms`, `linear time: jwt_hyphen_run`, `linear time: jwt_segments` |
| GAP3-CR-01 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 review curl missing separators bounded` |
| GAP3-CR-02 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 review keyed armor priority` |
| GAP3-CR-03 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 review name value record boundaries`, `round3 review name value unrelated records` |
| GAP3-CR-04 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 review escaped json containers` |
| GAP3-CR-05 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 review identifier and cli parity` |
| GAP3-CR-06 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 review quoted value continuations` |
| GAP3-CR-07 | critical | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 review persistent stdout context` |
| GAP3-WR-01 | warning | script/verify_repository.mjs; test/js/ci_secret_masking.test.mjs | fixed | PR259 merge b8398c38; actual-main proof; `round3 review sigil diagnostic boundaries` |
