---
phase: 195-pipeline-repair-and-hygiene
reviewed: 2026-10-26T00:00:00Z
depth: deep
files_reviewed: 2
files_reviewed_list:
  - script/verify_repository.mjs
  - test/js/ci_secret_masking.test.mjs
findings:
  critical: 2
  warning: 6
  info: 2
  total: 10
status: issues_found
---

# Phase 195: Gap-Closure Code Review Report (PR #256, 5862a3d)

**Reviewed:** 2026-10-26
**Depth:** deep (probes executed against the exported `maskSecretShapes`, and the test file's exported `derivedSecretViolations`; scratch under `/private/tmp/claude-501/gr/`)
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The fix closes the specific shapes it names: quoted, multi-word, escaped-quote and unterminated values, `=>`, `secret_key_base`, mid-line Cookie, Digest Authorization, URL userinfo, JWT and AKIA. Those probes mask correctly. ReDoS is not a concern: 25 adversarial 200 KB inputs, including long backslash runs, repeated keywords and unclosed quotes, each finished in 3 ms or less. The unrolled quote loop is safe because its trailing `("?)` always succeeds, so there is no backtracking.

Remaining gaps are mainly in how the key is written. A key preceded by a backslash-escaped quote, an Elixir tuple or atom-pair, or a separator that is not `=`/`:`/`=>` bypasses the generic rule. The `::add-mask::` guard also accepts a single-quoted mask, which registers the literal text `$TOKEN` and not the value.

All probe seeds were synthetic and built from fragments. Findings describe shapes, not values.

## Critical Issues

### GR-01: Credential keys written in escaped-JSON, tuple, and quoted-bearer forms leak (CR-01 not fully closed)

**File:** `script/verify_repository.mjs:93-94` (rules `GENERIC_CREDENTIAL_RULE`, bearer, authorization)
**Issue:** Confirmed by execution that the value passes through unmasked for each of these shapes:
- JSON embedded in a JSON/inspect string: `{\"password\":\"V\"}`. The key is followed by a backslash then a quote, and `["']?` allows only a bare quote. Inspect and log output from ExUnit, Phoenix and Playwright routinely contains this form.
- Elixir tuple and keyword pair with a comma or no separator: `{:token, "V"}` and `{"authorization", "Basic V"}`. The separator class is `= : =>` only, and the authorization rule needs `:`/`=`.
- Quoted bearer: `Bearer "V"`. The bearer value class excludes quotes, so a quoted value never matches.
- A secret on the line after its key: `password:\n  V` and YAML `password: |\n  V`. All rules are same-line only.
- Space-separated CLI forms: `--password V` and `curl -u user:V host`.
- `token == "V"` (double `=`): the first `=` matches, then the value begins with `=` and is under 3 bare characters, so the match fails. The `code: assert token == "expected-value"` prose row asserts this is left unmasked, which codifies the gap.

The stated purpose is that secret values never reach public CI output. An allowlist of separator shapes will keep missing key forms.
**Fix:** Tolerate backslashes and quotes around the key: `(?:\\*["'])?[ \t]*(?:=>|,|[:=]{1,2})`, with the value regex also accepting `\"`-wrapped spans. Add a `Bearer\s+["']?` form and a `-u user:` form. For line-spanning values, add a second pass that masks the next non-blank line when a credential key ends a line with `:`, `=` or `|`. Add the shapes above to `GAP_SHAPES` and drop the `token == "expected-value"` prose row, or make it explicit that it is a known limit.

### GR-02: `isMaskLine` accepts a single-quoted `::add-mask::$VAR`, which masks nothing

**File:** `test/js/ci_secret_masking.test.mjs:347-348`
**Issue:** The `["']?` prefix treats `echo '::add-mask::$TOKEN'` as a valid mask. Single quotes prevent expansion, so the runner registers the literal string `$TOKEN` and the derived secret stays unmasked. Executed: `derivedSecretViolations` returned `[]` for this input. This is a guard bypass that reports success while asserting nothing. The same defect lets `derivationScript` pick up the line, and the "live fire-drill" test only exercises the real double-quoted workflow, so it would not catch the drift.
**Fix:** Allow only double-quoted or unquoted forms, and require a matching close:
```js
new RegExp(`^\\s*(?:echo\\s+)?(?:"::add-mask::\\$(?:${name}(?![A-Za-z0-9_])|\\{${name}\\})"|::add-mask::\\$(?:${name}(?![A-Za-z0-9_])|\\{${name}\\}))`)
```
Add a fixture test where the single-quoted mask is expected to be a violation.

## Warnings

### GR-03: Common provider token prefixes with hyphens or other prefixes are not masked

**File:** `script/verify_repository.mjs:88`
**Issue:** The prefix rule requires `[A-Za-z0-9_]{8,}` straight after the prefix. Probes show `sk-proj-V` and `sk-ant-api03-V` pass through (the hyphen stops the run), as do `xoxb-...` and `npm_<36 chars>`. The comment advertises `sk-` coverage. Short `ghp_abc123` (under 8 characters) is also left alone. A prefixed token with no key name is exactly the shape the generic rule cannot catch.
**Fix:** Use `(sk-|xox[abprs]-|npm_)[A-Za-z0-9_-]{8,}` and lower `gh*_` to `{6,}`.

### GR-04: PEM and private-key bodies on separate lines leak

**File:** `script/verify_repository.mjs:93`
**Issue:** a PEM private-key BEGIN marker line followed by body lines is not masked; the body lines and END marker pass through (confirmed). Only keyed one-line forms (`private_key: "..."`) are covered.
**Fix:** Add a multiline rule: a multiline regex from the PEM private-key BEGIN marker (five dashes, BEGIN, optional key type, PRIVATE KEY, five dashes) lazily through the matching END marker or end of text to the BEGIN marker followed by `***`. Bound the lazy span so it stays linear, and add it to the linear-time inputs.

### GR-05: Userinfo, AWS key ID and JWT rules have shape holes

**File:** `script/verify_repository.mjs:89-91`
**Issue:** Executed results:
- `https://:V@host` (empty user) leaks, since the user class needs 1+ characters.
- `https://user:V/z@host` leaks because the password class stops at `/`.
- The AKIA/ASIA rule needs `\b` on both sides, so `key_AKIA...` and `AKIA...X` are not masked.
- A two-segment `eyJ..` token leaks.
- `Bearer realm="V"` (WWW-Authenticate) is partly masked and leaves the quoted value (`Bearer ***"V"`).
**Fix:** Use `*` for the user part, allow `/` inside the password up to `@`, drop the leading `\b` on the AKIA rule (use `(?<![A-Z0-9])`), and accept two-segment JWTs.

### GR-06: Derived-secret scan is a narrow line grammar that misses ordinary bash

**File:** `test/js/ci_secret_masking.test.mjs:343, 372-398`
**Issue:** Executed: the scan yields zero assignments, and so no violation, for `local X=`, `declare X=`, `X+=`, `read -r X <<<`, `printf -v X`, `echo "X=$SECRET" >> $GITHUB_ENV`, `... >> $GITHUB_OUTPUT`, and single-line `run: X=$(...); use`. `A=1 TOKEN=$SECRET` is recorded under the wrong name (`A`), so `TOKEN` is untracked. A use on the assignment line itself (`TOKEN=...; echo "$TOKEN"`) is never inspected because the scan starts at `index + 1`, so a later mask passes. All were confirmed. The live-tree test floor (`total >= 1`) shows only that something is found, not that the grammar is complete. The comment says one assignment per line is the convention, but nothing enforces it.
**Fix:** Start the usage scan at the assignment line and check the part after the assignment. Recognise `export|local|declare|readonly`. Treat any `secrets.`-derived value written to `GITHUB_ENV`/`GITHUB_OUTPUT` as a violation. Add a "convention violation" failure for lines with several assignments.

### GR-07: Prose that the comment claims is untouched is masked

**File:** `script/verify_repository.mjs:75-76, 94`
**Issue:** `token: nil`, `password: nil`, `token: true` and `max_token: 1000` become `***` (any bare word of 3+ characters after a separator). `Authorization: required for route` and `stale cookie: expired at line` have the rest of the line masked. The authorization and cookie rules also fire mid-prose, with no word boundary before `authorization`. This hides diagnosable ExUnit and Ecto output (`nil`, `true`, numeric limits) and weakens the "prose without a separator is untouched" claim. `PROSE_LINES` only covers `token: ok` (2 characters) and `token_count: 300` (suffix), so none of these is tested.
**Fix:** Exempt `nil|true|false|null|undefined` and pure-numeric values, or accept the loss and add rows to `PROSE_LINES` that document it. For the authorization and cookie rules, require a header-like context (line start, quote, `-H`, or `< `).

### GR-08: Test suite is partly vacuous or brittle in places

**File:** `test/js/ci_secret_masking.test.mjs:249-288, 290-306`
**Issue:** (a) `LINEAR_INPUTS` has no backslash-run, doubled-quote or repeated `\"` input, which are the inputs that would expose the ambiguous `\\[^\n]?` alternation if the trailing `("?)` ever became required. The guard that currently makes it safe is untested. (b) The wall-clock budget (1500 ms) is a proxy; the observed cost is under 5 ms, so a 100x regression still passes. (c) The window-cut test hard-codes `24 * 1024` and 150 instead of importing `ROOT_PROOF_TAIL_BYTES`/`ROOT_PROOF_TAIL_LINES`, so it can silently stop testing the cut if the constants change (the `cutInside` setup assertion mitigates this). (d) No row asserts ANSI-wrapped secrets or CRLF.
**Fix:** Add backslash and mixed-quote inputs, tighten the budget to about 200 ms, export the constants, and add an ANSI and CRLF row.

## Info

### GR-09: Key-ID and query-string credential shapes are unmasked

**File:** `script/verify_repository.mjs:93`
**Issue:** `?key=V`, `?sig=V`, `cookie=V`, `cookies: V`, `secrets=V`, `privatekey=V` and `passwords=V` pass through. Most are plausible URL query or env forms; none is covered by a test or an explicit "not covered" note.
**Fix:** Add `sig|key` query shapes and `private[_-]?key`, or document them as out of scope in the rule comment.

### GR-10: `maskValue` assigns replacement structure by argument position

**File:** `script/verify_repository.mjs:62-66`
**Issue:** `maskValue` depends on the fixed capture-group order from `SECRET_VALUE_SOURCE` (six groups, positional parameters). Adding a group to the source silently shifts every parameter. `GENERIC_CREDENTIAL_RULE` has one prefix group, which is relied on.
**Fix:** Use named groups (`(?<dq>...)`) and read them from the replacer's groups argument.

---

_Reviewed: 2026-10-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
