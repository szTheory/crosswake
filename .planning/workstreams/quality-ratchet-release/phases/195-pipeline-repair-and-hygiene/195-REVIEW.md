---
phase: 195-pipeline-repair-and-hygiene
reviewed: 2026-10-26T00:00:00Z
depth: standard
files_reviewed: 44
files_reviewed_list:
  - .github/dependabot.yml
  - .github/workflows/maven-publish-fire-drill.yml
  - .github/workflows/phase130-proof.yml
  - .github/workflows/phase132-proof.yml
  - .github/workflows/phase23-proof.yml
  - .github/workflows/phase34-proof.yml
  - .github/workflows/phase43-proof.yml
  - .github/workflows/phase45-proof.yml
  - .github/workflows/phase48-proof.yml
  - .github/workflows/phase52-proof.yml
  - .github/workflows/phase58-proof.yml
  - .github/workflows/phase70-proof.yml
  - .github/workflows/phase71-proof.yml
  - .github/workflows/phase73-proof.yml
  - .github/workflows/phase74-proof.yml
  - .github/workflows/phase96-proof-advisory.yml
  - .github/workflows/see-it-run-collateral.yml
  - .github/workflows/see-it-run-native.yml
  - .github/workflows/weekly-canary.yml
  - brandbook/collateral/see-it-run/README.md
  - docs/SETUP.md
  - script/check_phase165_efficient_ci.sh
  - script/ci_docs_allowlist.json
  - script/verify_published_cleanroom.sh
  - script/verify_repository.mjs
  - scripts/ci_monitor.cjs
  - test/crosswake/guides/see_it_run_collateral_test.exs
  - test/crosswake/manifest/host_command_seam_fixture_test.exs
  - test/crosswake/proof/ci_recurring_lanes_test.exs
  - test/crosswake/proof/phase153_ios_mirror_unblock_test.exs
  - test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs
  - test/crosswake/proof/phase165_ci_integrity_test.exs
  - test/crosswake/proof/phase165_ci_policy_test.exs
  - test/crosswake/proof/phase165_evidence_test.exs
  - test/crosswake/proof/phase175_release_recovery_test.exs
  - test/crosswake/release/published_cleanroom_test.exs
  - test/crosswake/repository_root_allowlist_test.exs
  - test/crosswake/test_support/version_stamp_test.exs
  - test/js/ci_secret_masking.test.mjs
  - test/mix/tasks/crosswake_gen_shell_origin_mode_test.exs
  - test/support/version_stamp.ex
findings:
  critical: 2
  warning: 6
  info: 3
  total: 11
status: issues_found
---

# Phase 195: Code Review Report

**Reviewed:** 2026-10-26
**Depth:** standard
**Files Reviewed:** 44 (focus: the phase diff against f9f6ccc9, on origin/main)
**Status:** issues_found

## Summary

The workflow changes are sound: least-privilege `permissions`, SHA pins, schedule retirement, and the native split all hold up. The cleanroom script fails closed on every path I traced. The weak spot is the secret masker. I ran `maskSecretShapes` against realistic inputs. Two common credential shapes pass through unmasked, and several others are only partly masked. The derived-secret guard in `ci_secret_masking.test.mjs` can also score a wrong mask as a right one. Its seeds only use the shapes the regexes were written for, so the tests pass (11/11) without covering these gaps.

## Critical Issues

### CR-01: Quoted secret-access-key values are not masked at all

**File:** `script/verify_repository.mjs:58-66`
**Issue:** The `secret_access_key` regex allows a quote before the separator (`["']?\s*[:=]`) but not after it. The value pattern `[^\s"']{3,}` cannot start at a `"`. The generic last regex needs the keyword immediately followed by a separator, and `secret_access_key` has `_` after `secret`. I confirmed these outputs are unchanged by masking:
- `AWS_SECRET_ACCESS_KEY="abcdefghijk"`
- `secret_access_key = "abcdefghijk"`

Quoted env dumps and config echoes are the normal form of this credential, and this output goes to hosted CI logs.

**Fix:** Allow an optional quote before the value and mask quoted spans through the closing quote. Apply the same rule to the generic keyword regex:
```js
.replace(/((?:aws_)?secret[_-]access[_-]key["']?\s*[:=]\s*)(?:"[^"\n]*"|'[^'\n]*'|[^\s"']{3,})/gi, "$1***")
.replace(/(authorization|bearer|token|secret|password|api[_-]?key)(["':=\s]+)(?:"[^"\n]*"|'[^'\n]*'|[^\s"']{3,})/gi, "$1$2***")
```
Add quoted-value seeds to the test.

### CR-02: Values containing spaces leak after the first word, and some headers and URLs bypass masking

**File:** `script/verify_repository.mjs:58-66`
**Issue:** Measured on the current code:
- `password = "my secret pass"` becomes `password = "my secret ***"`. The word `my` leaks.
- `{"password":"abc def"}` becomes `{"password":"*** def"}`. The word `def` leaks.
- `Authorization: Digest username="a", response="deadbeefcafe"` becomes `Authorization: *** username="a", response="deadbeefcafe"`. Only the scheme word is masked.
- `curl -H "Cookie: a=b"` is not masked, because the cookie regex is anchored to the start of a line.
- URL userinfo (`https://u:hunter22@host/x`), JWTs (`eyJ...`) and bare AWS access keys are not covered by any shape.

The header comment promises "Cookie: ... to end of line" and "Authorization: <scheme> <v>". The tests only seed one-word values at line start.

**Fix:**
- Mask quoted values through the closing quote (see CR-01).
- For `Authorization`, mask to end of line, as is done for cookies.
- Drop the `^` anchor on the cookie rule, or add `-H "Cookie: ..."` handling.
- Add `://[^/\s:@]+:[^/\s@]+@` and `eyJ[\w-]+\.[\w-]+\.[\w-]+` shapes.
- Add a seed for each of these.

## Warnings

### WR-01: The generic keyword rule over-masks prose and hurts diagnosability

**File:** `script/verify_repository.mjs:65`
**Issue:** `token expired for user` becomes `token *** for user`. ExUnit failures commonly say "token expired/invalid", "password mismatch" or "secret not found". The rule masks the next word whatever it is. This works against the stated goal ("keep key and header names so failures stay diagnosable").

**Fix:** Require an explicit `=` or `:` separator, or a quote, for the generic rule. Keep the whitespace-only form for `Bearer` and `Authorization`.

### WR-02: Quadratic regex behaviour on blank-line runs, applied to the full unbounded output

**File:** `script/verify_repository.mjs:61`
**Issue:** `^(\s*(?:set-)?cookie` with the `m` flag lets `\s*` span newlines. Every line start in a run of N blank lines rescans the rest of the run. I measured about 1.7s for 60,000 blank lines. Masking runs over the whole stdout and stderr before the tail is cut to `ROOT_PROOF_TAIL_BYTES`, so cost scales with total output.

**Fix:** Use `[ \t]*` instead of `\s*` in the anchored prefix. Better, truncate the text to the tail and detail windows first, then mask.

### WR-03: Derived-secret guard `isMaskLine` has no word boundary and counts comments

**File:** `test/js/ci_secret_masking.test.mjs:101`
**Issue:** `::add-mask::\$\{?NAME\}?` matches `::add-mask::$TOKEN_ID` as a mask for `$TOKEN`. It also matches a commented-out line (`# echo "::add-mask::$TOKEN"`). Either defeats the guard (absence scored as success). The guard also only sees single-line `KEY: ${{ secrets.X }}` env bindings and only `run: |` blocks. A single-line `run: ...` or a multi-line assignment is invisible to it.

**Fix:**
```js
const isMaskLine = (line, name) =>
  new RegExp(`^\\s*(?:echo\\s+)?["']?::add-mask::\\$\\{?${name}\\}?(?![A-Za-z0-9_])`).test(line);
```
Add negative fixtures for a prefix-collision name and for a commented mask.

### WR-04: Cleanroom `fetch` has no timeout, retry or protocol pin

**File:** `script/verify_published_cleanroom.sh:93-96`
**Issue:** `curl -sS -L` has no `--max-time` or `--connect-timeout`. A stalled registry hangs the job until the CI timeout. That is not an explicit fail-closed verdict. `-L` also follows redirects to any scheme.

**Fix:** `curl -sS -L --proto '=https,file' --proto-redir '=https' --connect-timeout 15 --max-time 120 --retry 2`. Keep `file` allowed only when `SELFTEST=1`.

### WR-05: Cleanroom failure reasons conflate network or parse errors with `not_published`

**File:** `script/verify_published_cleanroom.sh:159, 245`
**Issue:** An empty `git ls-remote` result is reported as `ios not_published`, even when the cause is a network or auth failure. A hex JSON parse failure is reported as `not_published`. Both still fail closed (exit 1). But later phases parse these reason codes, so a transient outage would be misread as "version not published".

**Fix:** Capture the `git ls-remote` exit status and report `resolve_failed` on non-zero. Distinguish a jq or python3 parse error from a missing `checksum` field.

### WR-06: Maven POM check is weaker than it claims

**File:** `script/verify_published_cleanroom.sh:127`
**Issue:** `grep -Fq "<version>$VERSION</version>"` matches any element, such as a dependency or parent with the same version string. It does not prove the project coordinates. The artifactId and groupId are also not checked.

**Fix:** Parse the POM, or at least match the project-level `<artifactId>` and `<version>` pair. `python3 -I` with ElementTree would work.

## Info

### IN-01: Same checkout SHA carries conflicting version comments

**File:** `.github/workflows/phase48-proof.yml:22` and others
**Issue:** SHA `3d3c42e5...` is labelled `# v6`, `# v6.0.2` and `# v7` in different files. The fire-drill labels it `v7.0.1`. The comments are provenance for reviewers and Dependabot, so they should agree. Affected files include phase48, 52, 58, 70, 71, 73, 74, 96 and crosswake-ci.yml.

**Fix:** Normalise the comments to the real tag, for example `# v7.0.1`.

### IN-02: Dead `schedule` conditions and stale wording after schedule retirement

**File:** `.github/workflows/phase96-proof-advisory.yml:38` and others
**Issue:** `github.event_name == 'schedule' || ...` conditions remain on workflows that have no `schedule` trigger. The phase23 and phase34 notices still say "scheduled/manual". `see-it-run-collateral.yml` is accurate: it keeps its weekly schedule.

**Fix:** Drop the dead `schedule` clauses, and update the phase23 and phase34 notices.

### IN-03: `need_tools` lists omit tools the legs use

**File:** `script/verify_published_cleanroom.sh:104, 137`
**Issue:** `head`, `tr` and `base` are used in the maven and hex legs but are not in their tool checks. They are near-universal, so the risk is low. The `tool_unavailable` contract is stated as complete.

**Fix:** Add `head` and `tr` to the maven list.

---

_Reviewed: 2026-10-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
