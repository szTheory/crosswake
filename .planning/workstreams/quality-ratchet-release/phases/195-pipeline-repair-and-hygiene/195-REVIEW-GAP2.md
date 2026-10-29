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
  info: 4
  total: 12
status: issues_found
---

# Phase 195: Round-2 Gap-Closure Code Review Report (PR #257, merge 7621c0ce, diff 5862a3d..12281b87)

**Reviewed:** 2026-10-26
**Depth:** deep (probes executed against the exported `maskSecretShapes`, `rootProofFailureTail`, `GAP_SHAPES` and `derivedSecretViolations`; scratch under `<session scratchpad>`)
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Round 1 (GR-01 to GR-10) is closed for the shapes it named. All 138 tests in `ci_secret_masking.test.mjs` pass, and every probe I ran for the round-1 shapes masks correctly. Round 2 added a next-line pass (`maskNextLineValues`) and more rules, and these still have holes.

- **One new quadratic rule.** `KEY_LINE` (the regex behind the next-line pass) takes 23.1 s on a 200,000-character line, `token:` followed by spaces and then `x`. The same input takes 1 ms with a one-token fix. This is a sibling of the JWT rule fixed in 283111ee, and the linear-time suite cannot see it because it has no whitespace-run-after-key input.
- **Leaks.** The rule set is shape-based and still misses credential shapes that this repo's own secrets can produce. The signing secret `ORG_GRADLE_PROJECT_signingInMemoryKey` is an ASCII-armored PGP private key, and the PEM rule does not match `PRIVATE KEY BLOCK`. Elixir `inspect` forms, which ExUnit prints on failure, also leak: cookie maps, list and map values, and a tuple wrapped across lines.
- **Derived-secret guard.** `isMaskLine` accepts lines that do not register the secret: a redirect to `/dev/null`, trailing text after the variable, and a mask inside an `if`, a function body or a heredoc.
- **Raised floor.** The 250 ms floor still separates a quadratic from linear code at 200k characters, by 2 to 3 orders of magnitude. It cannot see a bounded-window regression (see IN-03).

All probe values were synthetic and fragment-built (`fakeLeakVal9X` style). No realistic secret appears below.

## Critical Issues

### CR-01: `KEY_LINE` is quadratic on a long whitespace run after a credential key (sibling of the JWT ReDoS)

**File:** `script/verify_repository.mjs:119`
**Issue:** `KEY_LINE` ends `[ \t]*(?:=>|[:=])[ \t]*(?:[|>][+-]?[0-9]?[+-]?)?[ \t]*\r?$`. The block-indicator group is optional, so two adjacent `[ \t]*` quantifiers can split a whitespace run in O(n) ways, and the `$` fails after each split. `maskNextLineValues` runs this regex on every line.

Executed on `maskSecretShapes("token:" + " ".repeat(N) + "x")`:

| N | time |
|---|---|
| 10,000 | 53 ms |
| 20,000 | 203 ms |
| 40,000 | 815 ms |
| 200,000 | 23,099 ms |

The same quadratic shows with tabs, `" \t"` pairs, `=>`, and `Authorization:` and `cookie:` heads. A fixed copy ran 90 head, whitespace and tail combinations at 30k characters in under 80 ms each, and the 200k probe took 1 ms. A line of 200k spaces is plausible in minified or padded test output. The cost is a CI hang on the failure path, where the tail is the only diagnostic.

The linear-time suite (`test/js/ci_secret_masking.test.mjs:580-610`) has no input of the form key, separator, long whitespace run, non-whitespace, so it passes while this exists. `whitespace_lines` uses newlines, which split into short lines.
**Fix:** Move the trailing whitespace inside the optional group so only one `[ \t]*` can follow the separator:
```js
const KEY_LINE = new RegExp(`(?:${CREDENTIAL_WORDS})${KEY_QUOTE}[ \\t]*(?:=>|[:=])[ \\t]*(?:[|>][+-]?[0-9]?[+-]?[ \\t]*)?\\r?$`, "i");
```
Add LINEAR_INPUTS rows `` `${TK}:` + " ".repeat(200000) + "x" `` and the tab and `" \t"` variants. Also add an "exhaustive head by whitespace-run" row for the other `[ \t]*[:=][ \t]*` rules (`AUTHORIZATION_RULE`, `COOKIE_RULE`, `GENERIC_CREDENTIAL_RULE`, `SECRET_ACCESS_KEY_RULE`), which probed linear today.

### CR-02: Secrets this repo actually holds print unmasked: PGP armored private key block, `signingInMemoryKey=`, camel-case `SecretAccessKey`

**File:** `script/verify_repository.mjs:84` (`PEM_KEY`), `:77` (`CREDENTIAL_WORDS`), `:93` (`SECRET_ACCESS_KEY_RULE`)
**Issue:** Confirmed by execution that these shapes pass through unmasked.
- **ASCII-armored PGP block.** `<BEGIN PGP private-key-block marker>`, then a blank line, body lines and the END marker, prints in full. `PEM_KEY` requires `PRIVATE KEY-----`, but the PGP form is `PRIVATE KEY BLOCK-----`. The workflows hold `secrets.ORG_GRADLE_PROJECT_signingInMemoryKey` and `...signingInMemoryKeyPassword` (five uses each), and the in-memory key is exactly this armored form.
- **`signingInMemoryKey=<value>`** is not masked, because the word `key` alone is not in `CREDENTIAL_WORDS`. Likewise `signing_key:`, `auth_key=`, `deploy_key:` and `MIRROR_DEPLOY_KEY=<value>`. `MIRROR_DEPLOY_KEY` is also a repo secret (seven uses).
- **`SecretAccessKey`.** `{"SecretAccessKey":"<value>"}`, `"secretAccessKey": "<value>"` and `--secret-access-key <value>` leak. Rule d requires a `_` or `-` between the words, so the AWS CLI and SDK JSON spelling is missed. `"SecretString"` and `accessKey=` also leak.
**Fix:**
- Allow an optional `BLOCK` in the PEM marker: `PRIVATE[ ]KEY(?:[ ]BLOCK)?-{5}`.
- Allow an optional separator in rule d: `secret[_-]?access[_-]?key`.
- Add `signing[_-]?(?:in[_-]?memory[_-]?)?key`, `deploy[_-]?key`, `auth[_-]?key`, `secretstring` and `access[_-]?key[_-]?(?!id)` to `CREDENTIAL_WORDS`, or mask any `(?:^|[_-])key` assignment whose key name is on the repo's secret list.
- Add a GAP_SHAPES row per repo secret name, so the secrets inventory and the masker cannot drift.

## Warnings

### WR-01: Elixir `inspect` forms that ExUnit prints on failure still leak

**File:** `script/verify_repository.mjs:77`, `:92` (`COOKIE_RULE`), `:96` (`BEARER_RULE`), `:105` (`TUPLE_RULE`), `:57` (`SECRET_VALUE_SOURCE`)
**Issue:** This is a Phoenix project, and ExUnit prints `conn`, headers and cookie maps in assertion diffs. Confirmed leaks:
- `%{"cookie" => ["sid=<v>"]}` and `%{"set-cookie" => ["sid=<v>; path=/"]}`. `COOKIE_RULE` needs `:` and not `=>`, and the generic rule's value cannot start with `[`.
- `req_cookies: %{"_app_key" => "<v>"}` and `resp_cookies: %{"sid" => %{value: "<v>"}}`. The value starts with `%{` and is less than 3 characters before the next quote.
- `password: ["<v>"]` and `tokens: ["<v>", "<v>2"]`.
- `{:token,\n "<v>"}`. ExUnit's pretty-printer wraps long terms, and the tuple rule is same-line only. `{:token_<65+ chars>, "<v>"}` also leaks (bound is 64).
- `token: ~S"<v>"` and `token: <<"<v>">>`.
- Nested values partially mask: `password: %{value: "<v>"}` becomes `password: *** "<v>"}` and still prints the secret, and `{"password": {"v": "<v>"}}` leaks.
- `password: <v> <v>2` (unquoted multi-word value) masks only the first word.
**Fix:** Let the generic rule's value consume a container opener: after a credential key and separator, mask from the value start to the matching same-line closer, or, where that is hard, to end of line. For `cookie(s)` allow `=>` as well as `:` in `COOKIE_RULE`, and keep the `*cookies` suffix keys. Extend `maskNextLineValues` to a key line ending in `,` after an atom or quoted credential key (`{:token,`).

### WR-02: `{"name":"TOKEN","value":"<v>"}` masks the word `value` and prints the secret

**File:** `script/verify_repository.mjs:105-108` (`TUPLE_RULE`)
**Issue:** Confirmed: `{"name":"token","value":"<v>"}` becomes `{"name":"token","***":"<v>"}`. The tuple rule reads `"token"` as a closed-quote credential key and `,` as its separator, then masks `"value"` as the value. The secret is untouched, and the output is wrong in both directions. The same pairing occurs in Playwright storage state, `{ name: 'sid', value: '<v>' }`, and in GitHub and Kubernetes env JSON such as `{"name":"TOKEN","value":"..."}`.
**Fix:** Require the tuple key to be an atom (`:token`) or require the rule to run only when the element after the comma is not itself a key (no `:` or `=` directly after the closing quote). Add a name/value rule: when a `"name"` field has a credential word, mask the following `"value"` field.

### WR-03: PEM body detection leaks when the body is not on clean base64 lines

**File:** `script/verify_repository.mjs:82-87` (`PEM_LB`, `PEM_ITEM`, `PEM_RULE`)
**Issue:** The body starts only after a line break and must be pure `[A-Za-z0-9+/=]` to end of line. These leak:
- Trailing whitespace after the BEGIN marker (`<BEGIN private-key marker>   \n<body>`).
- A log prefix on each body line (`[log] <body>`).
- A single-line form (`<BEGIN private-key marker><body>` or `... <body> -----END ...`). The `***` is inserted before the body, which stays visible.
- A bare `\r` break.
- A double-escaped `\\n` break.
- A `-` or `_` base64url character in a body line, and a body line with a timestamp.
Only the first body line is checked here; a failing line ends the run and every later line prints.
**Fix:** Make the BEGIN match consume `[ \t]*`. Accept an optional per-line prefix learned from the BEGIN line. Mask the rest of the BEGIN line unconditionally, and mask through the END marker or to the next blank line when no END marker is found, instead of stopping at the first non-matching line.

### WR-04: Prose over-masking not pinned in `ACCEPTED_OVERMASK` (diagnosability loss on common Phoenix output)

**File:** `script/verify_repository.mjs:96` (`BEARER_RULE`), `:141` (generic rule), `test/js/ci_secret_masking.test.mjs:557-566`
**Issue:** Each case below was executed, none is in `PROSE_LINES` or `ACCEPTED_OVERMASK`, and the first three are common ExUnit and Phoenix output:
- `bearer token is required` becomes `bearer *** is required`. `Bearer authentication failed` and `the Bearer scheme is not supported` mask the next word, because the bearer rule treats any 3+ character word as the value.
- Changeset errors: `password: should be at least 12 character(s)` becomes `password: *** be at least 12 character(s)`. `* password: can't be blank` becomes `* password: ***'t be blank`. The unquoted value stops at the apostrophe, so the output is torn mid-word.
- `** (ArgumentError) invalid token: expected a binary` becomes `invalid token: *** a binary`.
- `refresh token: rotated`, `use token: foo`, `cookie: 1`, `credential: missing`.
- `token: 123` and `{:token, 123}` both mask a number and swallow closing brackets: `{:ok, %{token: 1}}` becomes `{:ok, %{token: ***`, and `[token: :bad]` becomes `[token: ***` with the `]` lost.
- `eyJhello.world` and `version eyJ1.2` are masked as JWTs.
- A lone marker `<BEGIN private-key marker>` gets `***` appended.
- `ps -u root:wheel` and `-u admin:admin` are masked by the curl-user rule, which is not anchored to curl.
**Fix:** Either pin each as an `ACCEPTED_OVERMASK` row (the established convention) or narrow the rules. For bearer, require a 20+ character token-like value or a following non-word boundary. For bare values, stop before a closing `)`, `]` or `}` that has no opener in the value. Add a changeset-error prose row.

### WR-05: `isMaskLine` accepts lines that do not register the secret

**File:** `test/js/ci_secret_masking.test.mjs:722-727` and `:769-781` (`derivedSecretViolations`)
**Issue:** The guard only checks that a line starts with `echo` and `::add-mask::$NAME`. Confirmed by `derivedSecretViolations` on fixtures that all report **no violation**:
- `echo "::add-mask::$TOKEN" >/dev/null`, `> /tmp/x`, and `| cat >/dev/null`. The runner reads workflow commands from stdout, so the redirect means nothing is registered.
- `echo "::add-mask::$TOKEN"x`, which registers the value plus `x`, not the value.
- `echo ::add-mask::$TOKEN.suffix`, with the same defect.
- The mask inside `if [ ... ]; then ... fi`, a function body that is never called, or a quoted heredoc body. The scan is line-based and ignores control flow.

The reverse (`printf '::add-mask::%s\n' "$TOKEN"`, `echo -e`, a subshell) is rejected, which is fail-closed and safe.
**Fix:** Require the matched line to have nothing after the closing quote or name except optional `;`, `>&2`, `2>&1` or a trailing comment (`(?:\s*(?:;|>&2|2>&1))*\s*(?:#.*)?$`). Reject a mask line whose indentation is deeper than the assignment's, which catches `if` and function bodies. Reject any line between a heredoc opener and its terminator.

### WR-06: The new tests can pass while real regressions exist

**File:** `test/js/ci_secret_masking.test.mjs:515-526`, `:580-642`
**Issue:**
- **Missing regression class.** The linear-time suite has no key-then-whitespace-run row (see CR-01), so it cannot fail for that rule. A quadratic rule that needs an unusual prefix is invisible to it unless the author already thought of the prefix. Most LINEAR_INPUTS rows take 0 to 9 ms and only the repeated-`://a:` row is non-trivial (23 ms), so they exercise the happy path of the regex that matches first.
- **Tail window not asserted.** The spawned-child gap test asserts every seed appears in the raw output, but not in the 150-line window of the unmasked text. It passes today (140 raw lines, all 52 rows' seeds visible), but there is a 10-line margin. Adding roughly five multi-line rows pushes the earliest rows' stdout copies out, and leaves only the stderr copies, which also drop out past 75 rows. The test would then report a clean tail because the value is out of the tail, not because it is masked.
- **Baseline cached once** (`baselineCache`). A slow first sample inflates the 10x bound for every later row.
**Fix:** Add the whitespace-run inputs. Assert that the unmasked 150-line, 24 KB window contains every seed before the leak check (`unmaskedTail.includes(seed)` for each seed). Compute the baseline per row or take the minimum across several samples.

## Info

### IN-01: Other unmasked credential shapes (bare tokens and CLI forms)

**File:** `script/verify_repository.mjs:174-197`
**Issue:** Confirmed leaks, each a plausible CI log line:
- Provider token prefixes: `glpat-`, `sk_live_`, `rk_live_`, `whsec_`, `AIza`, Twilio `SK`, Azure `AccountKey=<v>==;`, Slack webhook path segments.
- CLI: `-p <v>` (docker, sshpass), `-p<v>` (mysql), `--key <v>` (`mix hex.publish --key`), `--user=deploy:<v>`, `-udeploy:<v>` (the curl rule needs a space), `openssl -pass pass:<v>`.
- Bare key names: `pwd=`, `pass=`, `pw:`, `DB_PASS=`, `DB_PWD=`, `_auth=`, `session_id=`, `?code=`.
- URL: `https://<token>@host` (user only), a password or user longer than 256 characters, a password containing a space, `?sig%3D=`, `?AWSAccessKeyId=AKIA...`, URL-encoded `password%3D<v>`.
- Encodings: a full-width colon separator, an ANSI `[0K` between key and separator (only `...m` sequences are stripped).
- `Bearer\n<v>`, `bearer: <v>`.
- `Basic <base64>` without an `Authorization:` prefix.
**Fix:** Add the high-value rows (`glpat-`, `sk_live_`, `-p <v>`, `--key <v>`, `pwd`, `pass`, `curl --user=`) and strip all CSI sequences (`/\u001b\[[0-9;?]*[ -/]*[@-~]/g`). Decide explicitly which of the rest are out of scope and list them in the header comment.

### IN-02: Derived-secret detection scope gaps

**File:** `test/js/ci_secret_masking.test.mjs:716`, `:755-768`
**Issue:** Confirmed by `derivedSecretAssignments` returning 0 for each:
- `local T=$(...)`, `T+=...` and `read -r T <<< "$SECRET"`.
- An inline use with no assignment (`curl -u "x:$(printf %s "$PW" | base64)"`).
- `echo "T=$(...)" >> "$GITHUB_ENV"`, which carries a derived secret into later steps unmasked.
- Bracket syntax `${{ secrets['X'] }}` and `${{ github.token }}`. The repo uses `GH_TOKEN: ${{ github.token }}` at seven places, so a derived `base64` of it would not be seen.
- The `/:\s*\$\{\{/` skip drops any assignment whose right side contains `: ${{`, for example `AUTH="Authorization: ${{ secrets.X }}"`.
The guard is only as strong as its heuristics, and the live-tree floor of 1 (`total >= 1`) does not protect these.
**Fix:** Document the assumptions in a header comment and add the `local`/`+=`/`$GITHUB_ENV` forms. Restrict the YAML-key skip to assignments with no `=` before the `:`.

### IN-03: Raised floor (40 ms to 250 ms) still discriminates quadratics but not bounded-window regressions

**File:** `test/js/ci_secret_masking.test.mjs:615-642`
**Issue:** A quadratic at 200,000 characters takes seconds (7,266 ms for the old JWT rule, 23,099 ms for CR-01), so the 250 ms floor separates it from linear code (0 to 9 ms measured here) by more than an order of magnitude. A regression that is linear but with a window constant of a few hundred, like the bounded userinfo rule (23 ms today, `{0,256}`), only needs a 10x larger window to approach the floor. The relative `10 * baseline` term is irrelevant because the baseline is about 1 ms, so the floor alone sets the bound.
**Fix:** Keep 250 ms, and add per-row comments of the measured time so drift is visible. Track measured times in `t.diagnostic` (already done) and alert at 25 ms.

### IN-04: JWT left boundary lets `-` and `_` prefixes through

**File:** `script/verify_repository.mjs:189`
**Issue:** `(?<![A-Za-z0-9_-])eyJ...` does not mask `a-eyJ<v>.b.c` or `x_eyJ<v>.b.c`. The boundary was added in 283111ee to keep hyphenated runs linear. A JWT prefixed by `-` or `_` (for example `access_token_eyJ...` or `jwt-eyJ...`) therefore prints. `EYJ` in capitals is also not matched.
**Fix:** Allow `-` and `_` before `eyJ` when the preceding run is shorter than the JWT body, for example `(?<![A-Za-z0-9])eyJ` plus a possessive or length-bounded first segment, then re-run the `jwt_hyphen_run` probe.

---

_Reviewed: 2026-10-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
