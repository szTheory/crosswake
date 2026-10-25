# Phase 175: Source Diagnosis and Conditional Preflight - Pattern Map

**Mapped:** 2026-09-30; reconciled against final D-62–D-65 decisions  
**Files classified:** 9 candidate file groups, including conditional evidence and output files  
**Analogs found:** 9 / 9

This map covers D-54 through D-65. Plans 175-49 through 175-54 are terminal history. If a new split passes, D-59 requires the same new plan to continue through a fresh complete preflight, new digest, one durably reserved authenticated porcelain dry-run, post-observations, and independent audit. Mapping code does not authorize running it. No tag write, merge, Gate 2, recovery, or publication follows from a proven evidence artifact.

## File Classification

| Candidate new/modified file | Role | Data flow | Closest tracked analog | Match |
|---|---|---|---|---|
| `script/release_candidate/ios_mirror.sh` (only if the reviewed source seam needs it) | shell adapter | local process / Git observation | same file, lines 1-70 | exact source boundary, but surrounding script has out-of-scope release branches |
| `lib/crosswake/release_candidate/ios_tag_source_evidence.ex` | pure evidence service | bounded observation → classification → receipt validation | same file, lines 4-42, 69-97, 194-257 | exact |
| `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs` | ExUnit test | fixture observation → asserted classification | same file, lines 25-164, 181-230 | exact |
| Private source process runner and adjacent test, **only if needed** (planner chooses location) | process utility and ExUnit test | argv/working directory → bounded status; injected fake → assertion | `lib/crosswake/release_candidate/evidence_live.ex:987-998`; `test/mix/tasks/crosswake_release_status_test.exs:49-92` | role/data-flow match, no exact source-only runner exists |
| Fresh preflight/post-observation collector and adjacent tests, **if code is needed** | private evidence adapter | remote/PR/policy/credential reads → closed fact map | `lib/crosswake/release_candidate/evidence_live.ex:200-311,701-875`; `lib/crosswake/release_candidate/ios_tag_source_evidence.ex:269-298,336-355` | role/data-flow match; existing live collector serves REL-17, so scope reuse carefully |
| One-shot dry-run/parser/reservation seam and adjacent tests, **if code is needed** | private process/parser utility | bounded stdout/stderr → exact tuple; durable receipt → invocation | `script/release_candidate/ios_mirror.sh:103-136`; `lib/crosswake/release_candidate/ios_tag_source_evidence.ex:300-334,459-489` | partial: current mirror script uses different ref set and permissive grep |
| New phase-local blocked/proven evidence artifact | evidence file | sanitized facts → canonical bytes/digest → readback/audit | `lib/crosswake/release_candidate/companion_receipt.ex:59-65,185-209`; `lib/crosswake/release_candidate/ios_tag_source_evidence.ex:99-123,527-536` | role/data-flow match; no reusable fsync reservation helper found |
| `lib/mix/tasks/crosswake.release.status.ex` and, if required, `lib/crosswake/release_status.ex` | read-only Mix task and projection service | validated status → fixed text/JSON → exit | same files, lines 29-70 and 113-166 | exact output discipline; receipt-specific projection is new |
| `test/mix/tasks/crosswake_release_status_test.exs` | ExUnit output contract test | task output → text/JSON assertions | same file, lines 135-217 | exact |

The candidate list is an implementation map, not a mandate to modify every file. A phase-local private runner may be smaller than touching the broad mirror script. No Phoenix, Plug, Ecto, UI, new release authority, or CI file belongs to this follow-up.

## Pattern Assignments

### Source process edge: `script/release_candidate/ios_mirror.sh` or a private runner

**Git split command to preserve:** `script/release_candidate/ios_mirror.sh:65-70`:

```bash
SPLIT_SHA="${CROSSWAKE_IOS_MIRROR_SPLIT_SHA:-}"
if [ -z "$SPLIT_SHA" ]; then
  SPLIT_SHA=$(git -C "$RELEASE_REPO" subtree split \
    --prefix=packages/crosswake-shell-core-ios "$SOURCE_REF" 2>/dev/null | tail -1)
fi
printf '%s' "$SPLIT_SHA" | grep -Eq '^[0-9a-f]{40}$' || SPLIT_SHA=""
```

Preserve the `subtree split`, exact prefix, and selected source arguments. This pipeline currently hides split's own exit attribution; do not copy the `tail -1` pipeline as a diagnostic implementation. The script's other modes and push branches are distinct from the follow-up's conditional one-target dry-run.

**Private argv process idiom:** `lib/crosswake/release_candidate/evidence_live.ex:987-998`:

```elixir
defp bounded_cmd(program, args, options, timeout_ms) do
  task = Task.async(fn -> System.cmd(program, args, options) end)

  case Task.yield(task, timeout_ms) do
    {:ok, result} -> result
    nil ->
      Task.shutdown(task, :brutal_kill)
      {"", 124}
  end
end
```

Use direct argv and `cd:` for the same isolated clone. The source runner must distinguish process creation failure from a started process returning nonzero. This analog merges timeout into status 124 and some callers use `stderr_to_stdout: true`; those choices do **not** satisfy D-64 for private Git output. The accepted D-64 amendment permits strict transient parsing of only a successful subtree split's documented single OID; a failed or extra-output result stays unknown/blocked. Human diagnostics and stderr remain opaque. Do not place streams, arguments, path, environment, or remotes in a receipt or operator text. Four pre-reservation checks need independent TRUE/FALSE/UNKNOWN outcomes.

**Precondition probe shape:** Keep all readiness checks read-only and output-free. In the isolated full clone, inspect `.git/shallow` metadata; unexpected topology or inaccessible metadata is UNKNOWN. For the selected commit, require exit 0 from both `git cat-file -e <selected>^{commit}` and `git cat-file -e refs/tags/ios-core-v0.2.6^{commit}`, then exit 0 from `git merge-base --is-ancestor <selected> refs/tags/ios-core-v0.2.6` in both directions. With full history and both commits proven, status 1 proves tag/commit mismatch; other failures are UNKNOWN. For the package prefix, use `git cat-file tree <selected>:packages/crosswake-shell-core-ios/` with trailing slash and classify only process/exit facts. Establish subtree availability through filesystem metadata at the explicit absolute `GIT_EXEC_PATH`: require regular executable `git-subtree` plus readable `git-sh-setup`, and pass the same value to every Git child. If the variable is unset/unresolvable, classify UNKNOWN. Never call `git subtree --help` (Git 2.41 rewrites `git cmd --help` to Git's help path before helper dispatch) or parse `git --exec-path` output. Reduce each check to TRUE/FALSE/UNKNOWN without parsing precondition stdout, paths, or human text. Never persist probe output or filesystem paths. [CITED: https://git-scm.com/docs/git-cat-file; https://git-scm.com/docs/git-merge-base; https://git-scm.com/docs/git; https://raw.githubusercontent.com/git/git/v2.41.0/tree-walk.c; https://raw.githubusercontent.com/git/git/v2.41.0/git.c]

### Source classifier and receipt: `lib/crosswake/release_candidate/ios_tag_source_evidence.ex`

**Closed schema and vocabulary:** lines 4-42 define the version, tri-states, results, next actions, and exact source fields. New readiness fields require a new private receipt schema while old Plan 175-54 validation remains intact.

**Core pattern:** lines 69-97:

```elixir
def classify!(observations) when is_map(observations) do
  unless exact_atom_keys?(observations, @source_atom_keys), do: invalid!()
  unless valid_source_observations?(observations), do: invalid!()

  result = source_result(observations)

  classified =
    observations
    |> Map.put(:result, result)
    |> then(fn value ->
      if result == "PASS", do: value, else: Map.put(value, :split_oid, nil)
    end)

  classified
rescue
  _error -> invalid!()
end

def validate_receipt!(receipt) when is_map(receipt) do
  if valid_receipt?(receipt), do: :ok, else: invalid!()
rescue
  _error -> invalid!()
end
```

`source_result/1` at lines 194-215 already distinguishes `NONZERO_EXIT`, unknown observation, missing OID, and PASS. `valid_source_receipt?/1` at lines 236-257 recomputes classification from the serialized fields. `exact_atom_keys?/2`, `exact_string_keys?/2`, bounded exit/version/OID validators, and the generic error at lines 562-607 prevent unsafe extra fields and error echo. Apply the same closed validation to subtree availability and prefix tree tri-states. Only the documented one-OID success shape may be parsed from successful subtree stdout; do not infer a failure cause from Git prose.

### Source evidence tests: `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs`

**Table of bounded cases:** lines 25-105 use `{source, expected}` tuples, call `classify!/1`, assert OID is retained only on PASS, then validate the corresponding receipt. **Privacy and consistency cases:** lines 116-164 reject extra `raw_stderr`, `raw_output`, `remote_url`, malformed Git version, and process facts that disagree. **Fixture pattern:** `source/1` and `observed_source/1` at lines 181-205 start UNKNOWN and merge explicit overrides. Extend these patterns for each new precondition and the pre-reservation block. Keep fake runner cases local and avoid actual split in unit cases.

### Conditional fresh preflight and post-observations

**Exact fact map:** `lib/crosswake/release_candidate/ios_tag_source_evidence.ex:269-298` validates the existing preflight fields and requires a complete source/mirror ref roster with digests, source tag, mirror main/prior tag, absent target, PR #219 head/base/readiness, policy digest, exact targets, helper identity, and push permission before `complete` can be `TRUE`:

```elixir
defp complete_preflight?(preflight) do
  preflight["source_refs_count"] != nil and digest?(preflight["source_map_sha256"]) and
    preflight["mirror_refs_count"] != nil and digest?(preflight["mirror_map_sha256"]) and
    valid_oid?(preflight["source_tag_commit"]) and valid_oid?(preflight["mirror_main"]) and
    valid_oid?(preflight["mirror_prior_tag"]) and preflight["target_absent"] == "TRUE" and
    preflight["pr_number"] == 219 and valid_oid?(preflight["pr_head"]) and
    valid_oid?(preflight["pr_base"]) and preflight["pr_ready"] == "TRUE" and
    preflight["policy_complete"] == "TRUE" and digest?(preflight["policy_sha256"]) and
    preflight["source_target"] == "EXPECTED_CROSSWAKE_SOURCE" and
    preflight["mirror_read_target"] == "EXPECTED_IOS_MIRROR_PUBLIC" and
    preflight["mirror_push_target"] == "EXPECTED_IOS_MIRROR_WRITE" and
    preflight["helper_identity"] == "EXPECTED_GH_CLI" and
    preflight["push_permission"] == "TRUE"
end
```

**Read adapters:** `lib/crosswake/release_candidate/evidence_live.ex:200-222,246-259,732-759` shows bounded GitHub JSON reads, effective policy checks and paginated ruleset collection. These are existing REL-17 adapters, so copy their fail-closed read/pagination pattern into a private phase-local evidence collector only where the selected facts match; avoid extending public release authorization. `script/release_candidate/ios_mirror.sh:73-79` shows remote ref reads, but its `awk | head -1` discards duplicate-ref evidence. For D-59, require complete, cardinality-checked remote maps and treat read failure as UNKNOWN, never target absence.

**Post comparison:** `IosTagSourceEvidence` lines 336-355 reuse the exact preflight field set plus `unchanged`, and lines 470-475 require equality of every fact:

```elixir
defp pending_observations?(preflight, post) when is_map(post) do
  complete_preflight?(preflight) and post["unchanged"] == "TRUE" and
    Map.delete(post, "unchanged") == preflight
end
```

Re-observe from the new attempt after the one dry-run. A source PASS alone does not qualify any preflight fact or permit reservation.

### Durable reservation, one dry-run, and stdout grammar

**Reservation and readback validator:** `IosTagSourceEvidence` lines 300-324 require `reserved`, `invocations_reserved` in `[0,1]`, a reservation timestamp, parser schema, bounded counters and the two allowed stderr classes. Lines 527-536 require `reservation_readback_ok` to agree with any reserved invocation and cap the serialized receipt. The implementation must persist, fsync, reopen, and verify the sanitized receipt **before** calling Git; these validators check the receipt shape, not physical durability. `lib/crosswake/release_candidate.ex:150-159` has same-directory temporary write/rename, but no fsync or directory fsync. Use it only as a naming/cleanup analog, not as proof of the required durable reservation.

**Push location, with a crucial distinction:** `script/release_candidate/ios_mirror.sh:103-136` builds argv arrays for `git push --dry-run --porcelain`, captures stdout to a temporary file, and reads remote refs after the call. Its ordinary candidate branch pushes both main and tag with `--atomic`, and lines 120-128 accept any matching grep line. Do **not** copy that ref set or permissive result check. The new conditional attempt allows one authenticated `--dry-run --porcelain --force-with-lease=refs/tags/v0.2.6:` targeting only the expected split object and tag. Keep stdout/stderr separate and private.

**Closed receipt verdict:** `IosTagSourceEvidence` lines 328-334 bind the accepted tuple to the source split OID and exact target; lines 459-468 require exit 0, one status row, zero unexpected/malformed lines, no overflow/truncation, and an allowed stderr classification:

```elixir
defp accepted_dry_run?(dry_run, receipt) do
  dry_run["invocations_reserved"] == 1 and dry_run["reserved"] and
    dry_run["exit_status"] == 0 and valid_git_version?(dry_run["git_version"]) and
    dry_run["stdout_byte_count"] > 0 and not dry_run["stdout_overflow"] and
    not dry_run["stdout_truncated"] and dry_run["banner_count"] in [0, 1] and
    dry_run["status_count"] == 1 and dry_run["unexpected_count"] == 0 and
    dry_run["malformed_count"] == 0 and
    dry_run["stderr_class"] in ["EMPTY", "NONEMPTY_UNINTERPRETED"] and
    valid_accepted?(dry_run["accepted"], receipt["source"]["split_oid"])
end
```

No tracked source parser currently implements D-54's complete byte-stream grammar. The accepted D-64 amendment permits this **transient machine-output parse**, alongside the successful subtree OID parse; it does not permit parsing human diagnostics. The planner should add a small pure parser over bounded synthetic bytes: optional one exact `To ...` banner; exactly one tab-separated `*`, `<split>:refs/tags/v0.2.6`, `[new tag]` row; no extra line, malformed tab, nonterminal blank, invalid encoding, truncation, or overflow. Nonzero exit blocks regardless of parsed row. Stderr is reduced only to `EMPTY` or `NONEMPTY_UNINTERPRETED`; it never drives a verdict or cause label. `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:339-380` supplies current dry-run fixture fields but tests the receipt shape, not the full parser.

**Git version metadata:** D-56 still requires a normalized Git version as diagnostic metadata. `IosTagSourceEvidence` lines 8 and 573-577 accept only `git version` followed by a bounded numeric dotted version. If the runner collects `git --version`, parse only that tiny exact grammar transiently, then store only the normalized version; a missing/unexpected result is not authority and must not be turned into human-diagnostic parsing. The accepted D-64 amendment leaves this D-56 field intact.

### Sanitized receipt, digest, and independent audit

**Canonical bytes analog:** `lib/crosswake/release_candidate/companion_receipt.ex:59-65,185-209` sorts map keys recursively and returns canonical bytes plus SHA-256. Compute the new attempt's digest over its own sanitized receipt projection, excluding its self-digest field; never copy Plan 175-49..54 digests. `lib/crosswake/release_candidate/evidence_input.ex:381-400` validates bounded regular-file reads and turns errors into a generic invalid result. Keep raw Git/API output and credentials out of durable evidence.

**State validator:** `IosTagSourceEvidence` lines 394-489 already define blocked preflight, dry-run failure, changed post facts, AUDIT_PENDING, failed audit and PREFLIGHT_PROVEN cases. A pending artifact requires complete preflight, accepted dry-run and unchanged post facts. A proven artifact requires PASS audit bound to `pending_digest`, fresh audit observation and `REVIEW_SEPARATE_TAG_DECISION`, while lines 357-360 still require zero writes and `NOT_ATTEMPTED`:

```elixir
receipt["stage"] == "PREFLIGHT_PROVEN" and receipt["boundary"] == "AUDIT" and
  complete_preflight?(preflight) and accepted_dry_run?(receipt["dry_run"], receipt) and
  pending_observations?(preflight, post) and digest?(meta["pending_digest"]) and
  audit["status"] == "PASS" and audit["reason"] == "PREFLIGHT_PROVEN" and
  audit["input_digest"] == meta["pending_digest"] and timestamp?(audit["observed_at"]) and
  audit["next_action"] == "REVIEW_SEPARATE_TAG_DECISION" and
  audit["observations"] == preflight
```

This is the body of `proven_state?/1` at lines 483-489. The independent audit should re-read and recompute the new canonical digest, verify exact tuple/cardinality and reservation timing, and reobserve mutable facts without repeating the dry-run. `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:287-310,359-430` has complete preflight, accepted dry-run, pending-audit, and proven-receipt fixtures for focused negative cases.

### Maintainer text/JSON: `lib/mix/tasks/crosswake.release.status.ex` and `lib/crosswake/release_status.ex`

**Task pattern:** `lib/mix/tasks/crosswake.release.status.ex:29-70` parses strict `--json`, builds one status, renders either `Jason.encode!(status, pretty: true)` or `Crosswake.ReleaseStatus.render(status)`, calls `Mix.shell().info(output)` before the exit branch, then returns 0 or raises/exits for blocking and unverifiable states. Reuse this ordering if source status is projected there.

**Projection pattern:** `lib/crosswake/release_status.ex:113-166` builds stable text lines from the status struct. `render_check_line/1` at lines 247-256 emits a status, code, message, and one next action. For the Plan 175-54 shape, project only the validated receipt fields: `BLOCKED_PREFLIGHT`, `SOURCE`, `FULL_CLONE_SPLIT_FAILED`, `NONZERO_EXIT`, exit 1, explicit unknown cause, and `REVIEW_SOURCE_SETUP`. Text and JSON must derive from one bounded projection. Keep the existing release authorization gate separate; source diagnostics are read-only.

**Output test pattern:** `test/mix/tasks/crosswake_release_status_test.exs:135-217` uses `capture_io/1`, checks human phrases, parses JSON, asserts exact top-level keys and required fields, and rejects stale copy. Extend only if the plan genuinely exposes receipt projection through this task; update the stated schema contract deliberately rather than silently adding JSON keys.

## Shared Patterns

### Boundary before classification

Observe Git in the isolated clone, reduce every check to TRUE/FALSE/UNKNOWN, and pass only those bounded values to `IosTagSourceEvidence.classify!/1`. Existing source classifier lines 125-137 validate tri-states; lines 194-215 make source classification deterministic. Use `.git/shallow` metadata and output-free, bounded exit-status probes for preconditions. Do not parse precondition stdout or human output. A failed or unavailable readiness probe blocks before the durable reservation. A passing probe is an observed precondition, not a guarantee of split success.

### Conditional order after source PASS

Collect a new complete preflight and digest, then persist and read back the one-invocation reservation. Only then may the single authenticated dry-run execute. Classify the complete stdout under D-54 and stderr under D-55, reobserve all mutable facts, and run an independent audit against the new digest. `IosTagSourceEvidence.valid_post_source_state?/1` at lines 394-450 encodes the closed state transitions; do not advance on missing, changed, or ambiguous facts. Existing `write.attempts == 0` and `decision == nil` remain invariant for this evidence plan.

### Closed receipt and private output

`IosTagSourceEvidence.validate_receipt!/1` at lines 90-123 and `valid_source_receipt?/1` at lines 236-257 reject unknown fields and recompute the result. Existing tests at lines 116-164 exercise unsafe-field rejection. Keep the previous receipt schema/version recognized for terminal Plan 175-54 evidence; version the follow-up schema instead of mutating history.

### Operator language

Use `ReleaseStatus.render/1` and the Mix task's same-status text/JSON choice as the output model. One fixed, calm action follows a failed source operation. Do not display raw command output, source paths, executable arguments, environment, remotes, or output hashes.

## No Exact Analog Found

| Candidate | Role | Data flow | Gap |
|---|---|---|---|
| Private source runner | process utility | four Git probes → tri-states → one reserved split result | Current `evidence_live.ex` has a bounded `System.cmd/3` helper, but no source-specific pre-reservation runner with process-start attribution, strict single-OID success parsing, and D-64 privacy rules. |
| Receipt-specific maintainer projection | pure output service | validated source receipt → fixed text/JSON | Existing release status projects broader release truth; it does not currently consume the Plan 175-54 source receipt. |
| Complete porcelain parser | pure parser | bounded stdout bytes → exact one-ref tuple/counts | The current mirror shell script checks for a matching line with grep; the receipt validator checks already-reduced counters and tuple. Neither classifies every stdout line under D-54. |
| Durable reservation writer | local file I/O utility | sanitized receipt → fsynced file and directory → reopened readback | `Crosswake.ReleaseCandidate.atomic_write!/2` uses temporary write and rename, but lacks the fsync/readback sequence required before the one-shot operation. |

## Metadata

**Search scope:** `lib/crosswake/release_candidate`, `lib/crosswake/release_candidate.ex`, `lib/crosswake/release_status.ex`, `lib/mix/tasks`, `script/release_candidate`, and adjacent tests.  
**Tracked-source gate:** Every named analog above returned a nonempty `git ls-files -- <path>` result.  
**Files directly inspected:** 10 tracked source/test files.  
**Tests and release commands:** None run during pattern mapping.

## Addendum — Exact-head evidence collection (2026-10-02)

This addendum maps the current D-77–D-83 read-only plan only. It does not revise the historical
D-54–D-65 assignments above. Keep the plan to the selected PR/head, same-head workflow bytes,
complete run/attempt and required-check evidence, effective declarations, and a sanitized artifact.
Rerun, source, push, merge, tag, Gate 2, recovery, registry, and publication paths have no file
assignment here.

### File Classification

| Current file group | Role / data flow | Closest tracked analog | Match |
|---|---|---|---|
| `lib/crosswake/release_candidate/ios_tag_source_runner.ex` (narrow private collector, if code is needed) | process adapter; GitHub request/response → bounded facts | same file: `decode_gh_json/2` (1489–1514), `normalize_plan60_check_pages/4` (1565–1607), `plan60_collect_run_facts/3` (3095–3192), `plan66_read_workflow_once!/4` (3764–3808) | exact boundary and data flow |
| `lib/crosswake/release_candidate/ios_tag_source_evidence.ex` (new versioned attempt schema/classification) | pure evidence service; facts → closed classification and digest | same file: Plan66 builder/validator (1092–1184) | exact |
| `test/crosswake/release_candidate/ios_tag_source_runner_test.exs` | ExUnit; injected fake `gh` responses → collection assertions | same file: transport/pagination and Plan66 one-shot lifecycle tests (22–45, 726–882) | exact |
| `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs` | ExUnit; candidate facts → schema/privacy assertions | same file: Plan66 closed schema and unsafe-field cases (556–662) | exact |
| New plan-local evidence JSON and lifecycle journal | evidence artifact / append-only event log | runner's Plan66 exclusive artifact writer and lifecycle helpers (1610–1672, 3844–3864) | role/data-flow match; use new paths and attempt ID |

### Pattern Assignments

**Transport and collection:** Keep argument arrays and the injected `System.cmd/3` seam from
`IosTagSourceRunner.decode_gh_json/2` (1490–1514); its `api` branch deliberately preserves
`gh api` pagination arguments without appending jq. Reuse the bounded page validation and exact
identity checks in `normalize_plan60_check_pages/4` (1566–1607), and the selected run/attempt
binding in `plan62_collect_run_facts/3` (3095–3192). For same-head workflow retrieval,
`plan60_remote_workflow/1` (5113–5127) decodes GitHub's base64 content; for the durable one-read
pattern, `plan66_read_workflow_once!/4` (3764–3808) writes and verifies intent before invoking an
injected request adapter. Adapt these patterns for the selected PR/head and exhaust every page;
do not reuse the old selected-candidate literals or add Actions write operations.

**Closed facts and artifact:** Follow `IosTagSourceEvidence.build_plan66_aggregate!/7` and
`validate_plan66_aggregate!/2` (1092–1184): exact keys, bounded counts, allow-listed reason codes,
opaque attempt identity, canonical digest, and invalid-on-any-extra-field behavior. Make a new
schema and artifact path; Plan66 evidence is terminal history. Keep provider bodies, credentials,
argv, environment, paths, and raw streams out of the saved receipt. The runner's Plan66 write path
(3844–3864) uses exclusive creation, restrictive permissions, sync, readback, decode, and
revalidation; its lifecycle helpers (1610–1672) enforce ordered transitions and append+sync.

**Regression coverage and output:** Extend the existing injected-response tests for head/run/
attempt mismatch, incomplete or repeated pagination, duplicate identities, totals/declaration
disagreement, pending checks, invalid workflow content, and only the D-76 aggregate exception.
Use the evidence tests' extra-field rejection cases to prove raw response data cannot leak into the
artifact. If a user-invocable task is needed, keep it an explicit plan-scoped Mix entry point and
copy the text/JSON projection discipline from `lib/mix/tasks/crosswake.release.status.ex` (29–75);
do not add network behavior to `mix crosswake.release.status` itself.

### Shared Patterns and Gaps

- Preserve `TRUE` / `FALSE` / `UNKNOWN` distinctions, complete-page and exact-identity checks, and
  fail-closed classification. A missing or inaccessible observation stays unknown.
- Keep GitHub access behind an injected Elixir/Mix process boundary. This command serves a
  maintainer's release-evidence decision; Phoenix/Plug request handling, Ecto persistence, a
  dashboard, generic GitHub client, and a recurring CI lane add no needed user capability.
- No tracked artifact analog retains Plan66's exact workflow bytes: that plan stored only the
  aggregate verdict/counts and did not retain the bytes. The new schema must explicitly bind the
  exact fetched workflow to the PR head while honoring D-81's ban on raw provider bodies in
  durable receipts; do not claim Plan66 already proves byte retention.

**Tracked-source check:** All named source and test analogs above are tracked (`git ls-files` was
nonempty for each). No tests, live reads, or release commands were run.

## Addendum — Plan 175-69 bounded source outcomes (2026-10-02)

This mapping applies to D-84–D-86 and the Plan69 research addendum. Preserve the historical
Plan68 v1 artifact, digest, validator, lifecycle, and earlier pattern sections. The new plan may
make one separately reviewed read-only collection only after local fake cases pass; pattern mapping
does not authorize that collection.

### File Classification

| New/modified file | Role | Data flow | Closest tracked analog | Match |
|---|---|---|---|---|
| `lib/crosswake/release_candidate/ios_tag_source_runner.ex` | private process adapter | eight sequential GitHub responses → bounded source facts; durable lifecycle/artifact file I/O | same file, `decode_gh_json/2` (1499–1525), Plan68 collection (6690–6782, 6787–6985), lifecycle/artifact (7238–7422) | exact role and flow; accumulator is new |
| `lib/crosswake/release_candidate/ios_tag_source_evidence.ex` | pure evidence model/classifier | normalized facts → closed v2 validation, digest, text/JSON projection | same file, Plan68 v1 builder/validator/projection (1221–1355) and schema constants (136–170) | exact role and flow; new version |
| `test/crosswake/release_candidate/ios_tag_source_runner_test.exs` | ExUnit integration-style fake | injected request responses → per-stage outcomes, request trace, durable artifact | same file, Plan68 fake, no-second-attempt, partial GraphQL, workflow privacy (2003–2160) | exact |
| `test/crosswake/release_candidate/ios_tag_source_evidence_test.exs` | ExUnit pure contract | fixtures → closed schema, classification, privacy, v1 compatibility | same file, Plan68 proof and negative cases (664–785) | exact |
| Temporary explicit `lib/mix/tasks/crosswake.release.plan69.ex`, only for the reviewed attempt | maintainer Mix task | CLI arguments → one explicit collection → text/JSON and exit | `lib/mix/tasks/crosswake.release.status.ex:29–75`; Plan68 projection at `ios_tag_source_evidence.ex:1295–1355` | role/data-flow match; remove after use |
| New Plan69 phase-local JSON and lifecycle files | evidence artifact and append-only journal | closed facts → canonical digest → exclusive durable write/readback | Plan68 lifecycle/artifact helpers in runner (7238–7422) | exact flow with new names and version |

No Plug/Phoenix route, Ecto table, UI component, broad provider wrapper, or permanent CI lane is
implied by these decisions.

### Pattern Assignments

**Runner transport and source accumulator.** `IosTagSourceRunner.decode_gh_json/2`
(`lib/crosswake/release_candidate/ios_tag_source_runner.ex:1499–1525`) accepts an injected
`System.cmd/3` function and returns `{:ok, decoded}` or one of three fixed error atoms; it drops
provider output on error. `plan68_collect_counted_pages/6` (6996–7025) checks total and page
cardinality before returning complete pages; `normalize_plan68_run_pages/3` (7423–7452),
`normalize_plan68_job_pages/3` (7480–7509), and GraphQL page collection (7545–7705) check
identity, uniqueness, cursor, and run/attempt binding. Keep those parsers inside each source stage.
The current `plan68_collect_facts/2` (6787–6799) maps a later error to one fallback map, and
`plan68_collect_from_pr/3` (6881–6985) uses one `with` chain. For Plan69, use an explicit fixed
stage accumulator so completed facts survive a later source failure. Only commit a source's facts
to that accumulator after its full parser succeeds. Stop requests at the first unavailable stage.

**Pure v2 evidence boundary.** `IosTagSourceEvidence.build_plan68_exact_head!/2` and
`validate_plan68_exact_head!/2` (`lib/crosswake/release_candidate/ios_tag_source_evidence.ex:1221–1285`)
show the concrete contract: `exact_string_keys?`, bounded attempt ID, derived status, fixed release
hold/readiness, canonical SHA-256, digest recomputation, size cap, and generic invalid result.
Copy that shape into separate v2 functions/constants. Use the fixed ordered eight sources from
D-84: initial PR, run roster, attempt jobs, required checks, REST declarations, GraphQL
declarations, workflow, final PR. Each has `COMPLETE`, `UNAVAILABLE`, or `NOT_ATTEMPTED` and a
closed reason. A count exists only after complete normalization; otherwise project `UNKNOWN`.
Reject a completed later source after an unavailable prerequisite, unsafe extra keys, partial
records from a failed source, changed identity, and any promotion to release readiness. Leave the
v1 schema/constants (`ios_tag_source_evidence.ex:136–170`) and v1 validator untouched.

**Artifact and lifecycle.** `collect_plan68_exact_head!/2` (`ios_tag_source_runner.ex:6690–6782`)
checks both paths absent, creates an opaque attempt, appends and reads back reservation and intent
before the request, then seals and validates one artifact. `read_plan68_lifecycle!/1`
(7258–7323) checks exact event keys/order and matching attempt; `write_plan68_artifact_exclusive!/2`
(7391–7410) uses exclusive creation, restrictive permissions, file sync, directory sync, byte
readback, decode, and schema validation. Use new Plan69 paths/schema/event operation and bind
the terminal event to the v2 digest. Never persist response bodies, workflow bytes, argv, endpoints,
credentials, paths, stdout/stderr, or exception text. The old pair remains terminal history.

**Maintainer output and tests.** `plan68_projection/1` and `render_plan68_text/1`
(`ios_tag_source_evidence.ex:1295–1355`) derive human and JSON output from one validated artifact
and display unavailable counts as `UNKNOWN`. Copy that approach for eight short ordered source
rows, overall UNKNOWN/BLOCKED/ACTIVE disposition, and one safe next action. The temporary task
can follow `Crosswake.Release.Status.run/1` (`lib/mix/tasks/crosswake.release.status.ex:29–75`):
strict options, render before exit, and no hidden remote read in the standing status task.
`ios_tag_source_runner_test.exs:2003–2160` provides the injected fake, lifecycle ordering,
second-attempt rejection, GraphQL partial-error and oversized-workflow privacy cases. Extend
with an error at each of the eight boundaries and assert prior complete counts survive, later
sources are not attempted, and request trace stops. `ios_tag_source_evidence_test.exs:664–785`
provides exact-key rejection, stale/pending/mismatch, unknown-count, and v1 compatibility cases;
add v2 cross-field and canary cases while retaining the v1 digest behavior.

### Shared Patterns and Gap

- Keep GitHub access at the injected private Mix/process edge; stage parsers return tagged results.
- Keep completeness separate from eligibility: a fully observed failing check is `COMPLETE` as a
  source and still keeps the overall release gate blocked.
- A source error produces one allowlisted category and no partial source count. Earlier complete
  source facts survive. Text and JSON read the same validated v2 projection.
- There is no exact accumulator analog in tracked source. The existing `with` is appropriate inside
  one source parser; use `case` or `Enum.reduce_while/3` across the eight sources.

**Tracked-source gate:** Every named on-disk analog above was confirmed by nonempty `git ls-files`
output. No code edits, tests, network calls, staging, or commits were made during this mapping.
