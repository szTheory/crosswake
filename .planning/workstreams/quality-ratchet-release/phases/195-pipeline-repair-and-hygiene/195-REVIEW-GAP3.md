---
phase: 195-pipeline-repair-and-hygiene
reviewed: 2026-10-27T04:20:56Z
depth: deep
files_reviewed: 2
files_reviewed_list:
  - script/verify_repository.mjs
  - test/js/ci_secret_masking.test.mjs
reviewed_head: 24baafa3d5a65df6f84366209b372b7c5448cdbe
initial_reviewed_head: 8c519bfff50ef46eb62c58ae140eb68f9b6130b7
base_head: 7621c0ce0c38edec76cc54209eccf5acf40feddf
source_blobs:
  script/verify_repository.mjs: b9a8bba556037d7e78138649e517975e0c823565
  test/js/ci_secret_masking.test.mjs: 947eb25d3b563228efb562235dad6fb37d830780
initial_source_blobs:
  script/verify_repository.mjs: a7a665dc79e3bbca2fd727fa6f726a75f212a7e8
  test/js/ci_secret_masking.test.mjs: e5fe0e3a264c687f8ff38ac5e78848643d358e3e
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
historical_findings:
  critical: 7
  warning: 1
  total: 8
status: clean
---

# Phase 195: GAP3 Independent Code Review

## Narrative Findings (AI reviewer)

The final repaired two-file head has no unresolved findings from this review. All eight original findings are fixed, supported by defensive source inspection and the exact existing regression families listed below. The initial review of `8c519bfff50ef46eb62c58ae140eb68f9b6130b7` found seven blockers and one warning; their historical descriptions and failed archive-run evidence are preserved. This review establishes neither merge permission nor a post-merge REL-03 pass.

Source and tests were exported with `git archive` without switching the shared checkout. Synthetic seeds were fragment-built. Probe processes used two-second deadlines and 64 KiB output limits; outputs retained only labels, booleans and measurements. No credential, network request or publishing operation was used. Relevant governing documents, plans 19–21, summaries, all earlier reviews, disposition and verification were read. Neither source file is ignored. No configured reviewer skills were returned; project skill directories were absent.

## Historical Critical Issues — initial candidate

### GAP3-CR-01: Curl user scanning is quadratic on nonmatching flag runs

**Severity:** BLOCKER  
**File:** `script/verify_repository.mjs:449`  
**Issue:** The unanchored `-u`/ `--user=` alternatives restart a greedy `[^\\s:]+` scan at each flag occurrence when the maximal run contains no colon. This is another failure-path hang; the whole captured output is masked before its bounded tail is selected.

Independent subprocess measurements for `curl ` followed by repeated `-u`:

| Input units | Candidate ms |
|---:|---:|
| 4,005 | 6.898 |
| 8,005 | 28.453 |
| 16,005 | 98.629 |
| 32,005 | 355.413 |
| 200,005 | two-second deadline exceeded |

A second 210,005-unit input using repeated `--user=` also exceeded the deadline. Existing `command_curl` uses repeated successful colon forms; `curl_user_repeat` does not select this command-scoped branch. Their success does not cover this nonmatch.

**Reproducer labels:** `curl_unseparated_user`, `curl_unseparated_long`.  
**Fix:** Scan maximal command argument runs once, maintaining monotonic progress, or enforce a proven argument boundary before the flag while preserving compact curl credentials. Add both no-colon forms and independent per-row bounds; preserve successful, quoted and ordinary-diagnostic cases.  
**Final regression identity:** `round3 review curl missing separators bounded`.

### GAP3-CR-02: Earlier passes erase armored-key BEGIN markers and leak the body

**Severity:** BLOCKER  
**File:** `script/verify_repository.mjs:529` (ordering through line 535)  
**Issue:** `maskNextLineValues`, then structured assignment masking, run before `maskPrivateKeyBlocks`. A credential key immediately preceding an armored multiline private key causes an earlier pass to replace the BEGIN marker. The later armor scanner cannot find it; body lines then reach `rootProofFailureTail` unchanged. Confirmed for same-line `private_key: <BEGIN>\n<body>\n<END>`, next-line `private_key:\n<BEGIN>\n<body>\n<END>`, and a quoted JSON-key variant. Standalone armor tests miss the interaction.

**Reproducer labels:** `armor_key_same`, `armor_key_next`, `armor_json_key`.  
**Fix:** Consume armor before any pass can destroy its marker, then preserve the established public marker/output pins and safe diagnostics after a matching END. Add keyed and wrapped complete, missing-END and mismatched-END cases through the real tail API.  
**Final regression identity:** `round3 review keyed armor priority`.

### GAP3-CR-03: Name/value records leak after ordinary field reordering or nesting

**Severity:** BLOCKER  
**File:** `script/verify_repository.mjs:282`  
**Issue:** `flatObject` excludes nested braces; `nameValuePrefix` requires `name` immediately followed by `value`; only its first match is processed. All these actual credential records leak through the public tail:

- `{"value": V, "name": "TOKEN"}`
- `{"name": "TOKEN", "type": "secret", "value": V}`
- `{"name": "TOKEN", "value": {"raw": V}}`
- A record with multiple credential name/value pairs.

JSON property order is not a credential boundary. The three current name/value regression rows all use the same adjacent scalar layout.

**Reproducer labels:** `record_value_first`, `record_extra_field`, `record_nested_value`, `record_multiple`.  
**Fix:** Walk record boundaries and fields structurally, identify credential names regardless of property order, mask their complete associated values and process all relevant fields without crossing into unrelated records. Add an unrelated neighboring record as an exact preservation control.  
**Final regression identity:** `round3 review name value record boundaries`.

### GAP3-CR-04: Escaped JSON containers bypass complete-value masking

**Severity:** BLOCKER  
**File:** `script/verify_repository.mjs:125` and `:264`  
**Issue:** The complete structured assignment prefix accepts plain quoted identifiers but rejects the backslash-escaped quoted identifiers already supported by the older generic scalar rule. For an escaped JSON password field whose value is a list containing V, the generic fallback consumes only a fragment before the escaped value; V remains in the public tail. Passing `escaped_json_multiword` proves scalar coverage, not container coverage.

**Reproducer label:** `escaped_container`.  
**Fix:** Recognize escaped key delimiters in the structural prefix and preserve their escape/quote depth while consuming the entire balanced value. Cover nested escaped maps/lists and malformed termination as well as the existing exact scalar pins.  
**Final regression identity:** `round3 review escaped json containers`.

### GAP3-CR-05: Identifier and value support diverges between assignments, next-line values and CLI flags

**Severity:** BLOCKER  
**File:** `script/verify_repository.mjs:112`, `:377`, `:485`  
**Issue:** Several entry points retain separate older grammars instead of using the structural identifier classifier and complete value reader:

- `"signingInMemoryKey":\n  V` leaks; `STRUCTURAL_KEY_LINE` cannot consume the closing quote after the identifier.
- A quoted next-line token key using the newly supported full-width separator leaks.
- `tool --signingInMemoryKey V` leaks despite the exact identifier being credential-bearing as an assignment.
- `tool --password [V]` with V quoted inside the list leaks because the CLI value regex consumes the list opener, not the complete list.
- An otherwise matching flag with more than 64 prefix characters leaks.

Each case reached the public tail with its synthetic seed intact.

**Reproducer labels:** `camel_next_quoted`, `fullwidth_quoted_next`, `camel_cli`, `cli_container`, `cli_longprefix`.  
**Fix:** Share identifier classification and complete-value reading across supported next-line and CLI contexts, including quoted identifiers and supported separators. Remove the unproved CLI identifier cap using monotonic scanning; retain the explicit `--password-file` nonmatch and existing output pins.  
**Final regression identity:** `round3 review identifier and cli parity`.

### GAP3-CR-06: Triple-quoted credential values are mistaken for empty strings

**Severity:** BLOCKER  
**File:** `script/verify_repository.mjs:130`  
**Issue:** `readQuotedValueEnd` treats the second quote of a triple-quote opener as the end of an empty scalar. A valid Elixir keyword value consisting of `token:`, a triple-double-quote opener, newline, V, newline and a matching triple-quote closer leaves V visible in the public tail. A same-line triple-quoted representation also leaks. The ordinary doubled-quote timing input checks runtime, not secret absence.

**Reproducer labels:** `heredoc_triple`, `triplequoted`.  
**Fix:** Detect multiline quote delimiters before ordinary scalar delimiters, consume through their matching closer and fail closed for incomplete forms. Retain known closers and safe diagnostics beyond a complete value; add raw-window seed checks for both single- and double-quote heredoc variants.  
**Final regression identity:** `round3 review quoted value continuations`.

### GAP3-CR-07: The guard accepts an add-mask echo whose stdout was redirected earlier

**Severity:** BLOCKER  
**File:** `test/js/ci_secret_masking.test.mjs:1136`  
**Issue:** The prior-context scan checks control nesting but ignores persistent descriptor changes. This local synthetic body returned zero violations while the runner emulator exposed the derived value:

1. Preserve stdout with `exec 3>&1`.
2. Redirect stdout with `exec >/dev/null`.
3. Derive TOKEN from the synthetic secret-bound env value using the existing supported assignment form.
4. Use the exact supported `echo "::add-mask::$TOKEN"`.
5. Restore stdout with `exec >&3`, then echo TOKEN.

The registration never reaches the runner. A bounded local Bash execution and `runnerMaskedLog` independently confirmed the leak; only the boolean result was output. This is a false proof for the newly claimed unconditional stdout registration, separate from GR-06's accepted declaration/append/read/output grammar deferral.

**Reproducer label:** `guard_prior_stdout_redirect`.  
**Fix:** Fail closed across prior persistent descriptor changes and other unsupported output-routing context, rather than certifying an exact echo in isolation. Add a real local execution/emulator negative control and ensure `derivationScript` does not extract a supposedly valid mask from this context.  
**Final regression identity:** `round3 review persistent stdout context`.

## Historical Warnings — initial candidate

### GAP3-WR-01: Complete slash, pipe and angle sigils consume following diagnostics

**Severity:** WARNING  
**File:** `script/verify_repository.mjs:169` and `:178`  
**Issue:** `readContainerStart` advertises slash, pipe and angle sigil delimiters, but `closerFor` has no angle mapping and the loop recognizes terminal quote delimiters or bracket/bitstring closers only. Complete `~s/V/` and `~s|V|` credentials therefore fall through to the missing-closer EOF return. Independently verified that the following `Finished in` diagnostic disappears. This is a real valid-container parsing error, not the accepted missing/mismatched armor EOF policy. The current container test places diagnostics before each row and aggregates the survival assertion, so it cannot detect this loss.

**Reproducer labels:** `sigil_unpaired`, `sigil_slash`, `sigil_pipe`.  
**Fix:** Return the actual closer and delimiter kind from the container opener reader; handle escaped single-character sigil terminators before generic nesting and preserve suffix modifiers. Assert safe following diagnostics per complete row, with exact slash, pipe, angle and malformed-value cases.  
**Final regression identity:** `round3 review sigil diagnostic boundaries`.

## All-round final disposition matrix

This is the single machine-checkable disposition table: exactly 35 unique finding IDs, one status cell each. Every fixed row cites exact test identities executed successfully in the actual-checkout full suite on the final reviewed head. Dynamic gap-shape/prose identities are generated by the committed test source. Only GAP1-GR-06 retains the existing accepted Phase 196 receiver. The initial finding descriptions above are historical evidence, not open findings on the repaired head.

| Finding | Status | Exact successful test identities | Disposition and receiver |
|---|---|---|---|
| ORIG-CR-01 | fixed | `gap shape aws_key_double_quoted is masked`; `gap shape aws_key_single_quoted is masked` | Named quoted access-key values remain protected. |
| ORIG-CR-02 | fixed | `gap shape password_multiword_quoted is masked`; `gap shape digest_authorization is masked`; `gap shape cookie_midline_curl is masked`; `gap shape url_userinfo is masked` | Earlier quoted/header/URL cases and the later structural repairs pass. |
| ORIG-WR-01 | fixed | `prose round-trips unchanged: token expired for user`; `prose round-trips unchanged: password mismatch for account`; `prose round-trips unchanged: secret not found in vault` | Earlier no-separator prose remains readable. |
| ORIG-WR-02 | fixed | `linear time: blank_lines`; `linear time: whitespace_lines` | Earlier blank-line quadratic is covered; new curl quadratic is separately repaired below. |
| ORIG-WR-03 | fixed | `derivedSecretViolations rejects a prefix-collision mask`; `derivedSecretViolations ignores a commented-out mask` | Earlier prefix/comment cases pass. |
| GAP1-GR-01 | fixed | `gap shape escaped_json_multiword is masked`; `gap shape elixir_tuple_atom is masked`; `gap shape next_line_value is masked`; `gap shape cli_flag_space is masked` | Earlier scalar spellings and new structural combinations pass. |
| GAP1-GR-02 | fixed | `derivedSecretViolations rejects a single-quoted add-mask`; `derivationScript skips a single-quoted add-mask line` | Literal-single-quote registration is rejected. |
| GAP1-GR-03 | fixed | `gap shape sk_project_key is masked`; `gap shape sk_versioned_key is masked`; `gap shape slack_bot_token is masked`; `gap shape npm_token is masked` | Named provider prefixes pass. |
| GAP1-GR-04 | fixed | `gap shape pem_multiline is masked`; `gap shape pem_no_end is masked`; `gap shape pem_encrypted_headers is masked`; `round3 review keyed armor priority` | Standalone and keyed armor cases pass. |
| GAP1-GR-05 | fixed | `gap shape url_empty_user is masked`; `gap shape url_slash_password is masked`; `gap shape aws_key_id_prefixed is masked`; `gap shape jwt_two_segment is masked` | Earlier URL, key-ID and JWT boundaries pass. |
| GAP1-GR-06 | accepted | `live workflow tree: non-empty floor and zero violations`; `round3 references bracket and github token` | Existing broader Bash grammar deferral only; receiver phase196. No new deferral accepted. |
| GAP1-GR-07 | fixed | `prose round-trips unchanged: token: nil`; `prose round-trips unchanged: password: false`; `prose round-trips unchanged: preauthorization: pending review` | Literal/prose boundaries and explicit overmask pins pass. |
| GAP1-GR-08 | fixed | `linear time: backslash_run`; `linear time: doubled_quotes`; `ANSI-wrapped and CRLF secrets never reach the tail`; `a value cut by the tail byte window never appears` | Named adversaries, shared limits and raw-window controls pass. |
| GAP1-GR-09 | fixed | `gap shape query_key is masked`; `gap shape query_sig is masked`; `gap shape privatekey_assign is masked`; `gap shape passwords_assign is masked` | Named query/key forms pass. |
| GAP1-GR-10 | fixed | `gap shape escaped_quote_value is masked`; `gap shape escaped_json_multiword is masked` | Named groups remain in source; exact output regressions pass. |
| GAP2-CR-01 | fixed | `round3 padding credential whitespace matrix`; `round3 separator head adversaries`; `round3 timing quadratic copied control` | Named KEY_LINE defect and copied quadratic rejection pass. |
| GAP2-CR-02 | fixed | `round3 structural repository signing assignment`; `round3 inventory all workflow secret names`; `round3 private key armor complete layouts`; `round3 review keyed armor priority` | Signing identifiers, actual workflow inventory and armor combinations pass. |
| GAP2-WR-01 | fixed | `round3 container inspect values`; `round3 tuple wrapped values`; `round3 review escaped json containers`; `round3 review identifier and cli parity` | Named inspect forms and reviewed structural combinations pass. |
| GAP2-WR-02 | fixed | `round3 name-value record isolation`; `round3 review name value record boundaries`; `round3 review name value unrelated records` | Adjacent, reordered, nested and unrelated records pass. |
| GAP2-WR-03 | fixed | `round3 private key armor complete layouts`; `round3 private key armor malformed boundaries`; `round3 armor bounded adversaries`; `round3 review keyed armor priority` | Standalone, malformed and keyed armor cases pass. Existing EOF pins remain explicit. |
| GAP2-WR-04 | fixed | `round3 residual exact diagnostic pins`; `accepted over-mask pinned: changeset_blank`; `prose round-trips unchanged: short numeric container`; `round3 review sigil diagnostic boundaries` | Reviewed prose pins and complete-sigil diagnostic boundaries pass. |
| GAP2-WR-05 | fixed | `round3 guard exact stdout registration`; `round3 guard rejected execution contexts`; `round3 review persistent stdout context` | Named exact-line, control-context and persistent stdout cases are rejected or accepted as specified. |
| GAP2-WR-06 | fixed | `round3 raw window and inventory controls`; `round3 rule family adversaries`; `round3 separator head adversaries`; `round3 review curl missing separators bounded` | Named window/baseline controls and new represented interaction adversaries pass. |
| GAP2-IN-01 | fixed | `round3 residual named credential forms`; `round3 residual exact diagnostic pins`; `round3 residual rule adversaries`; `round3 review identifier and cli parity` | Named 45-form inventory plus reviewed CLI combinations pass. |
| GAP2-IN-02 | fixed | `round3 references bracket and github token`; `round3 review persistent stdout context` | Named reference spellings and stdout repair pass; broader accepted grammar remains solely GAP1-GR-06. |
| GAP2-IN-03 | fixed | `linear time baseline`; `round3 padding credential whitespace matrix`; `round3 residual rule adversaries`; `round3 review curl missing separators bounded` | Per-row timing and finite bounds execute; no universal runtime claim is made. |
| GAP2-IN-04 | fixed | `round3 residual named credential forms`; `linear time: jwt_hyphen_run`; `linear time: jwt_segments` | Named JWT prefix/case and pathological inputs pass. |
| GAP3-CR-01 | fixed | `round3 review curl missing separators bounded` | Monotonic curl token scanning skips nonmatching maximal runs; both original no-colon cases and eleven bounded rows pass. |
| GAP3-CR-02 | fixed | `round3 review keyed armor priority` | Armor runs first, before passes can consume its BEGIN marker; keyed/wrapped cases pass. |
| GAP3-CR-03 | fixed | `round3 review name value record boundaries`; `round3 review name value unrelated records` | Record-local lexical ownership and nonoverlapping replacement ranges handle ordering/nesting while preserving unrelated records. |
| GAP3-CR-04 | fixed | `round3 review escaped json containers` | Shared escaped-key grammar and quote/container reading cover the reviewed containers and malformed termination. |
| GAP3-CR-05 | fixed | `round3 review identifier and cli parity` | Shared identifier/continuation grammar and complete CLI values cover the reviewed parity cases, including unindented typed continuation. |
| GAP3-CR-06 | fixed | `round3 review quoted value continuations` | Triple delimiters use escape-aware monotonic reading before ordinary scalar quotes; reviewed heredocs and concatenation cases pass. |
| GAP3-CR-07 | fixed | `round3 review persistent stdout context` | Prior persistent exec contexts in the supported regression inventory invalidate registration/extraction. |
| GAP3-WR-01 | fixed | `round3 review sigil diagnostic boundaries` | Recognized complete sigil closers terminate consumption; each complete row preserves following diagnostics. |

The original review's cleanroom WR-04/05/06 and IN-03 remain the previously accepted Phase 197 debt. They are outside this two-file masker review and were not reaccepted, broadened, repaired or independently reverified here. Original IN-01/02 retain their earlier wontfix disposition. Historical batch approvals authorize no new gate.

## Initial archive verification evidence and limits

- The independent exported masking-file invocation executed **181 tests: 180 pass, one fail, zero skipped**, in **18,420 ms**, and emitted **202 numeric timing rows**. The failing identity was `round3 inventory all workflow secret names`: the source archive has no git index for `git ls-files`. This is insufficient inventory proof, not a product-regression claim.
- The independent exported full Node invocation exited nonzero in **16,848 ms**: **289 executed tests, 274 pass, 15 fail, zero skipped**. The inventory and other git/checkout-dependent fixtures failed in the archive. These results do not independently reproduce the executor's earlier **181/181** and **318/318** evidence and must not be promoted into an actual-checkout pass. Final full-suite proof remains required on the real fix checkout and later actual merged main.
- The historical 202-row timing artifact and 45-row pre-fix/identity control matrix were read as prior evidence. This run independently re-emitted the 202 timing rows and ran the candidate's existing copied-quadratic and raw-window tests; it did not rerun all 45 historical pre-fix/identity subprocess controls. Finite success does not override the new failures.
- New leak probes assert seed visibility in input and in the actual `rootProofFailureTail` output; each input is within the unmasked public window. Ordinary password masking serves as a protected-case comparison in the candidate suite. New runtime probes use isolated children with a two-second deadline. Eleven additional scanner adversaries were run: two curl inputs timed out; sampled userinfo, record-name, identifier-padding, armor-nonmatch, tuple, bearer, provider, escaped-quote and sigil inputs completed in 4–32 ms. The smaller curl series independently exhibits approximately quadratic growth.
- The actual registration-guard functions were extracted from the exact candidate test blob and evaluated locally; only synthetic `exec`, `printf`, `base64` and `echo` ran. The local runner emulator confirmed a derived leak with zero guard violations.
- Scratch probe sources are ephemeral reproducibility aids, not durable proof authority. No raw synthetic seed or process error is included in this report. The shared source, branch, index and existing artifacts were not changed by the reviewer. Scratch git metadata briefly prepared for git-aware tests was removed before any suite ran against it; no result relies on it.

## Final repaired-head re-review

**Reviewed head:** `24baafa3d5a65df6f84366209b372b7c5448cdbe`  
**Production blob:** `b9a8bba556037d7e78138649e517975e0c823565`  
**Test blob:** `947eb25d3b563228efb562235dad6fb37d830780`  
**Open critical/high findings:** 0  
**Open warnings from this review:** 0

The independent final pass inspected the repaired production/test changes and ran only existing repository regression tests on the actual checked-out fix branch. After the narrowed review instruction, no additional attack inputs or probe scripts were constructed or executed. Final claims are therefore bounded to source inspection and these existing cases.

- `node --test --test-name-pattern "^round3 review " test/js/ci_secret_masking.test.mjs` passed **9/9**, with zero failures and zero skipped, in **2,074 ms**. All nine exact identities named in the final table executed. The eleven existing interaction timing rows emitted positive measurements; maximum candidate time was **34.023 ms**, below the independently calculated per-row bound and two-second child deadline.
- `node --test test/js/*.mjs` passed **327/327**, with zero failures and zero skipped, in **25,745 ms**, on the actual checkout. This includes the real workflow inventory, all earlier-case families, window controls, exact diagnostic pins and the nine review families. Unlike the initial archive run, this is real checkout execution evidence.
- HEAD and both source blob identities were read before the final runs and independently read again afterward. They remained the values above. The tracked index and worktree were clean afterward; the reviewer edited only this report.
- The focused final source follow-up to GAP3-CR-06 replaces delimiter `indexOf` with a monotonic escape-aware scan. The existing quoted-continuation family now also includes the escaped triple-delimiter row and passed on this final head. The added red/green commits remain part of the source history; their execution counts reported by the repair worker are attributed evidence, not substituted for this independent final run.
- Source inspection confirms armor-first ordering; monotonic curl token progress; record-local field ownership; shared escaped-key, complete-value and CLI classification; triple-delimiter handling; explicit rejection of the existing persistent exec-context inventory; and termination on recognized sigil closers. Those changes address the original eight findings without a new deferral.
- The repair worker additionally reported copied pre-fix and identity-control failures. This final reviewer did not independently rerun those separate scratch controls under the narrowed instruction. The existing copied-quadratic/raw-window controls did execute in the full suite. Fresh actual-main proof and its mandated controls remain the delivery verifier's separate responsibility.

**Verdict:** all eight original GAP3 findings are fixed on the exact final reviewed head, with no unresolved finding from this review. This finite review does not prove arbitrary Bash programs or unlabelled arbitrary secrets safe. Existing GR-06/Phase 196 and original cleanroom/Phase 197 receivers remain unchanged. No new deferral, merge, publish or branch-deletion permission is recorded here.

Last completed phase remains 194. Phase 195 and REL-03 remain pending delivery and fresh actual-merged-main verification; the next authorized local work is the parent plan-21 candidate/readiness flow. The workstream command is `$gsd-execute-phase 195 --gaps-only --ws quality-ratchet-release`; no completed review or test step needs repeating unless the code head changes.

---
_Reviewer: gsd-code-reviewer; final independent defensive source review and existing-test execution on the exact head above._

