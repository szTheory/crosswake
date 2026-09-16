# Phase 169: Diagnostic Legibility - Research

**Researched:** 2026-09-15
**Domain:** Elixir diagnostics refactor (release-status reporting) + GitHub Actions display-name hygiene + shell/Elixir exit-code conventions
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Keep eager evaluation. Do NOT convert the ~62-tuple list literal to streaming.
- **D-02:** Add two additive stdout verbs to `script/check_release_workflow_integrity.exs`: a
  `ROSTER` line emitted BEFORE the check list is constructed, and a `DONE` sentinel emitted after
  all lines print. Both are purely additive; the existing consumer regex
  `^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$` ignores them.
- **D-03:** Restate MSG-02's message microcopy to the state that can actually occur (no partial
  emission exists under eager evaluation). Literal target strings:
  - Crash before roster: `scanner did not start: no roster line emitted (exit 1). stderr: …` → `:unavailable`
  - Crash after roster: `scanner terminated early: 0 of 68 roster checks ran (exit 1). stderr: …` → `:unverifiable`
  - ID absent from roster: `never defined by scanner: release.foo.bar — not in the scanner's 68-check roster; the required-ID list in Crosswake.ReleaseStatus has drifted from script/check_release_workflow_integrity.exs` → `:error`
- **D-04:** Scanner itself asserts emitted ID set == roster exactly; mismatch is a hard
  `FAIL: release.scanner.roster_exact`. Never advisory.
- **D-05:** `parse_workflow_integrity_output/1` must stop ending in `Map.new/1` (discards order).
  Retain order (ordered list, or `:order` index via `Enum.with_index`).
- **D-06:** Add one new always-emitted check, `release.workflow_integrity`, owning the FULL parsed
  scanner set, surfacing any failing check's verbatim `detail` prefixed by its ID, regardless of
  whether the ID belongs to any caller's `required_ids`. Single stable place root-cause sentence appears.
- **D-07:** The five existing `scanner_check/7` call sites report only their OWN failures, with the
  failing check's verbatim `detail` instead of a bare ID. Under a complete run where only a foreign
  check fails, they report OK — accuracy, not weakening.
- **D-08:** The "not evaluated — the scanner stopped before these gates ran (cause: <id>). This is
  not a pass." cascade pointer applies ONLY to the crash case. Scoped checks carry `:unverifiable`,
  never `:ok`, never a status mapping to exit 0.
- **D-09:** Correct `cond` ordering in `scanner_ids_result/2` (currently `:834`) so `failing`
  precedes `missing`, and compose every non-empty bucket: `"2 failing (…); 1 never defined (…)"`.
  Latent-bug hardening, not the live #164 repro.
- **D-10:** `render/1` needs an indented multi-line block for the D-06 owner check's verbatim
  `detail`; every other check stays single-line. `detail` must not be flattened/truncated. Bump
  `@schema_version` `"1.1.0"` → `"1.2.0"` for any additive machine field (e.g. `cause:`);
  additive-only, existing `%{status:, code:, message:}` consumers keep working.
- **D-11:** Exit-code contract: `0` clean · `1` ran and found a defect · `3` could not verify.
  **Not `2`** (already triple-booked in this repo). `3` already means could-not-run in
  `script/check_required_checks_registered.sh` and `script/verify_generated_ios_shell.sh`.
- **D-12:** `:warning` stays exit 0. No fourth code. `2` deliberately left reserved to existing meanings.
- **D-13:** Add `:unverifiable` as first-class in BOTH `aggregate_status/1` and `exit_code/1`, same
  change. Precedence `:error > :unverifiable > :warning > :ok`; mapping `:error → 1`,
  `:unverifiable → 3`, `:warning → 0`, `:ok → 0`. The catch-all `exit_code(_status), do: 0` at
  `release_status.ex:875` must not silently swallow the new atom.
- **D-14:** Use `exit({:shutdown, 3})`, never `System.halt/1`, for the new path (buffered-stdout /
  at_exit-hook risk). `Mix.raise` cannot express 3 (Mix always exits 1) — keep `Mix.raise` only for
  the exit-1 path. For `check_release_workflow_integrity.exs`, replace `System.halt/1` with
  `System.stop(code); Process.sleep(:infinity)` so stdout flushes under CI's pipe.
- **D-15:** Scope: change `mix crosswake.release.status` (FID-02 minimum) and
  `script/check_release_workflow_integrity.exs` (MSG-02's home). RATIFY, do not rewrite, scripts
  that already conform. Leave `crosswake.shell.status` alone. Optional separable sweep:
  `check_release_version_truth.exs` BLOCKED 2→3.
- **D-16:** Canonical exit-code docs live in the `@doc` for `Crosswake.ReleaseStatus.exit_code/1`.
  Shell/`.exs` verifiers carry a one-line header comment
  `# exit contract: 0 clean / 1 defect found / 3 could not verify`. Runbook gets a LINK, not a copy.
  No exit-code legend printed every run.
- **D-17:** Microcopy follows shipped `[crosswake] …` + "What to do next:" house style. Literal
  target strings (see full CONTEXT.md D-17 block) for FAIL(1) and UNVERIFIED(3) cases. Internal
  status atoms never leaked to the surface; human words are `FAIL` / `UNVERIFIED`.
- **D-18:** Phase 169 performs ALL renames and the duplicate fix atomically in one PR, with **no
  branch-protection step**. Confirmed: live branch protection requires exactly one context,
  `Crosswake CI`; `release-please.yml` triggers only on `push: branches: [main]` +
  `workflow_dispatch` (no PR check contexts emitted at all).
- **D-19:** There is **1** duplicate display name, not 3:
  `advisory provider sandbox/device proof (storekit + play billing)`, produced by both
  `phase48-proof.yml` (`advisory-provider-sandbox-proof`) and `phase70-proof.yml`
  (`advisory-provider-sandbox-device-proof`). The three `0.2.1` names collide with nothing.
- **D-20:** Today's duplicate detection is vacuous by construction —
  `list_merge_blocking_checks.py` only dedupes names containing `"merge-blocking"`; producer loop
  in `check_required_checks_registered.sh` iterates only REGISTERED contexts. Widen to a GLOBAL
  duplicate scan over all `(name, path, job_id)` records; add a version-literal regex reject
  (`\d+\.\d+\.\d+`) in any job `name:` or `upload-artifact` `with.name` under `.github/workflows/`.
- **D-21:** The widened scan and the rename fixes MUST land in the same commit (widening first trips
  on the phase48/phase70 collision; `--admin` merge is refused in this repo).
- **D-22:** Naming convention: `release: <subsystem-noun> <role>`, lowercase after prefix, MUST NOT
  contain a version literal. Literal renames (verified against source, see Code Examples):
  - `release-please.yml:30` `Guard exact approved 0.2.1 merge` → `release: approved-candidate merge guard`
  - `release-please.yml:719` `Prove exact public 0.2.1 artifacts` → `release: exact-public artifact proof`
  - `release-please.yml:767` `Linked 0.2.1 release rollup` → `release: linked release rollup`
  - `release-please.yml:761` (artifact) `exact-public-proof-0.2.1` → `exact-public-proof`
  - `release-please.yml:829` (artifact) `linked-release-status-0.2.1` → `linked-release-status`
  - `phase70-proof.yml` job `advisory-provider-sandbox-device-proof` name
    `advisory provider sandbox/device proof (storekit + play billing)` →
    `advisory provider device proof (play billing)`
- **D-23:** Non-vacuity proof for every new assertion: record the widened scan finds exactly 1 real
  collision on pre-fix `main`. Add a fixture workflow pair introducing a colliding display name and
  assert nonzero exit + diagnostic; a second fixture `name: prove 1.2.3 thing` asserting the
  version-literal reject fires.
- **D-24:** Add a guard test reading each verification entry point and asserting its literal exit
  values against the documented D-16 set; measure it actually finds the entry points before making
  it merge-blocking.

### Claude's Discretion

- Exact module/function decomposition inside `lib/crosswake/release_status.ex`, and whether the
  D-06 owner check is a new private builder or an extension of `scanner_check/7`.
- Whether order is retained as an ordered list or an `:order` key on each check map (D-05).
- The precise indentation/wrapping of the multi-line `detail` block in `render/1` (D-10).
- Whether to take the optional `check_release_version_truth.exs` 2→3 sweep (D-15) — only if it
  stays a clearly separable commit.

### Deferred Ideas (OUT OF SCOPE)

- Streaming scanner emission — rejected for this phase per D-01; ROSTER/DONE contract is
  deliberately forward-compatible with it.
- Widening the status vocabulary beyond `:unverifiable` (e.g. `:blocked`, `:partial` as check
  statuses) — separate deliberate change, not this phase.
- Roadmap/REQUIREMENTS wording corrections (SC #2/#3 text) — recorded but not amended this phase.
- `check_release_version_truth.exs` BLOCKED 2→3 sweep — optional, separable.
- Consolidating legacy and matrix clean-room paths — explicitly forbidden in v23.0.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MSG-01 | Maintainer sees the failing check's own message verbatim, not a bare-ID list | D-06/D-07 add an owner check (`release.workflow_integrity`) surfacing verbatim `detail`; verified live at `release_status.ex:823-845` (`scanner_ids_result/2` currently discards `detail`, only builds ID lists) |
| MSG-02 | Terminated-early distinguished from never-defined | D-02/D-03/D-04: ROSTER/DONE stdout protocol + `roster_exact` hard check; verified the scanner is fully eager (`check_release_workflow_integrity.exs:85-177`) so no true partial-emission state exists — D-03's restated microcopy is the correct target |
| MSG-03 | `missing` never shadows `failing` | D-09: reorder the `cond` at `release_status.ex:834` (verified: `missing != [] -> …` currently precedes the `failing != [] -> …` clause) |
| MSG-06 | Rename 3 `0.2.1` display names; duplicate-name uniqueness assertion | D-18–D-23; all six literal renames verified against `release-please.yml`/`phase70-proof.yml` source this session |
| FID-02 | Verification command exits differently for "found a defect" vs "could not run" | D-11–D-17: add `:unverifiable`/exit-3 to `Crosswake.ReleaseStatus.exit_code/1` (verified catch-all at `:875`) and to `mix crosswake.release.status` (verified `Mix.raise`-only call site at `lib/mix/tasks/crosswake.release.status.ex:47-49`) |
</phase_requirements>

## Summary

This phase is a pure-Elixir/pure-shell diagnostics refactor with **no new dependencies, no new
runtime behavior for the release graph, and no irreversible operations**. The CONTEXT.md for this
phase is unusually complete: it already contains a "verified ground truth" section (established by
actually running the scanner during discussion) that corrects the milestone's own upstream research
document, plus 24 numbered decisions with literal target strings and file:line citations. This
research pass independently re-read every cited source file this session and confirms all quoted
strings and line numbers are accurate (see Code Examples). No corrections to CONTEXT.md were found.

The work has three independent slices: (1) `Crosswake.ReleaseStatus` composition/rendering changes
in `lib/crosswake/release_status.ex` (~140 lines touched: `scanner_check/7`, `scanner_ids_result/2`,
a new owner-check builder, `parse_workflow_integrity_output/1`, `aggregate_status/1`, `exit_code/1`,
`render/1`); (2) an additive stdout protocol change to
`script/check_release_workflow_integrity.exs` (ROSTER/DONE lines, `System.halt` → `System.stop` +
sleep, a new `roster_exact` self-check); (3) a GitHub Actions workflow display-name/duplicate-scan
change spanning `release-please.yml`, `phase70-proof.yml`, `script/list_merge_blocking_checks.py`,
and `script/check_required_checks_registered.sh`, landed atomically per D-21.

**Primary recommendation:** Implement the three slices as three separate plan waves (ReleaseStatus
composition, scanner protocol, workflow renames+duplicate-scan), each independently testable against
the existing `phase142_release_integrity_test.exs` / `phase153_ios_mirror_unblock_test.exs`
regression suite (7+ sites asserting `output =~ "[crosswake] OK: #{id}"` must stay green), and gate
the exit-code change behind the explicit `:error > :unverifiable > :warning > :ok` precedence table
so the existing fail-open catch-all at `exit_code/1:875` cannot silently reabsorb the new status.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Scanner check execution & stdout emission | CLI script (`check_release_workflow_integrity.exs`) | — | Standalone `elixir` script invoked via `System.cmd`; owns the wire format |
| Scanner-output parsing & aggregation | Library (`Crosswake.ReleaseStatus`) | — | Consumes the scanner's stdout via regex; owns cross-check composition and the human-facing report |
| Report rendering (`render/1`) | Library (`Crosswake.ReleaseStatus`) | — | Pure function over the built status map; no I/O |
| Exit-code decision | Mix task (`crosswake.release.status`) | Library (`exit_code/1`) | The library computes the status atom; the Mix task is the only process boundary that can actually set an OS exit code (and currently cannot express `3` via `Mix.raise`) |
| Required-check display names & duplicate detection | CI config (`.github/workflows/*.yml`) | Python inventory script (`list_merge_blocking_checks.py`) + shell assertion (`check_required_checks_registered.sh`) | Display strings are pure YAML; the scan/assertion is a separate, already-existing local tool that reads the YAML as data — no GitHub API round-trip needed for the new assertion |
| Branch-protection required-context set | GitHub API / `required_check_policy.json` | — | Explicitly untouched this phase (D-18); the phase's renames don't intersect it because release-please.yml emits no PR check contexts |

## Standard Stack

No new libraries. This phase modifies existing first-party Elixir modules, an existing Elixir
script, an existing Python inventory script, and existing YAML workflow files.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` [VERIFIED: mix.exs] | Host language for `Crosswake.ReleaseStatus` and the scanner script | Already the project's language; `elixir` is invoked directly for the standalone `.exs` script |
| ExUnit | bundled with Elixir | Test framework for all `test/crosswake/proof/*` regression tests this phase must keep green | Already the project's test framework |
| Python 3 (stdlib only) | n/a | `script/list_merge_blocking_checks.py` and `script/normalize_required_checks.py` | Already the project's inventory-script language; no external packages used or needed |

### Supporting
None — no new packages, no new files outside the ones enumerated in `<canonical_refs>`.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Additive `ROSTER`/`DONE` text lines | `--format=json` scanner output (Credo/Sobelow-idiomatic) | **Rejected in CONTEXT.md.** Breaks the existing regex contract and all seven `phase142` test assertions for no diagnostic gain — noted explicitly in Specific Ideas. |
| `exit({:shutdown, 3})` | `System.halt(3)` | **Rejected in CONTEXT.md (D-14).** `System.halt/1` skips `at_exit` hooks and truncates buffered stdout when piped; `physical_iphone.ex:57` halts immediately after writing JSON to a pipe, so the project already treats this as a live risk. |
| Ordered list / `:order` index for parsed checks | `Map.new/1` (current) | Current implementation discards order, which is the reason MSG-02/MSG-03 root-cause naming and never-ran counts are currently impossible; D-05 mandates fixing this. |

**Installation:** None required — no packages to install.

**Version verification:** Not applicable — no new external packages.

## Package Legitimacy Audit

**Not applicable.** This phase installs no external packages in any ecosystem. All modified files
are first-party Elixir, first-party Python (stdlib), and YAML. No `npm install` / `mix deps.get` /
`pip install` step is required or introduced by this phase's decisions (D-01 through D-24 name only
existing files).

## Architecture Patterns

### System Architecture Diagram

```
                 ┌─────────────────────────────────────────┐
                 │ script/check_release_workflow_integrity.exs │
                 │  (standalone `elixir` process)           │
                 │                                           │
                 │  1. read workflow/config/manifest files   │
                 │  2. build ~68-tuple check list EAGERLY    │
                 │  3. [NEW] print ROSTER line (ids, count)  │
                 │  4. print one OK/FAIL line per check      │
                 │  5. [NEW] assert emitted-ID-set==roster   │
                 │     -> FAIL: release.scanner.roster_exact │
                 │  6. [NEW] print DONE sentinel (n of n)    │
                 │  7. [CHANGED] System.stop(code) not halt  │
                 └──────────────────┬────────────────────────┘
                                    │ stdout (System.cmd, stderr_to_stdout: true)
                                    ▼
                 ┌─────────────────────────────────────────┐
                 │ Crosswake.ReleaseStatus.build/1           │
                 │                                           │
                 │  workflow_integrity_evidence/1            │
                 │    -> parse_workflow_integrity_output/1   │
                 │       [CHANGED] retains order, not Map.new│
                 │    -> %{status: :ok|:failed|:unavailable, │
                 │         checks: [...ordered...]}          │
                 │                                           │
                 │  checks(...) builds ~15 report checks:    │
                 │    - 5x scanner_check/7 call sites        │
                 │      [CHANGED] report own-scope failures  │
                 │      with verbatim `detail`, not bare ID  │
                 │    - [NEW] release.workflow_integrity     │
                 │      owner check: FULL parsed set,        │
                 │      verbatim detail of ANY failing ID    │
                 │                                           │
                 │  aggregate_status/1 [CHANGED: +:unverifiable]│
                 │  exit_code/1        [CHANGED: +:unverifiable -> 3]│
                 └──────────────────┬────────────────────────┘
                                    │ status map
                                    ▼
                 ┌─────────────────────────────────────────┐
                 │ render/1 [CHANGED: multi-line detail      │
                 │  block for owner check only]              │
                 └──────────────────┬────────────────────────┘
                                    ▼
                 ┌─────────────────────────────────────────┐
                 │ Mix.Tasks.Crosswake.Release.Status.run/1  │
                 │  [CHANGED] can no longer just Mix.raise   │
                 │  on any nonzero — must distinguish exit 1 │
                 │  (Mix.raise, since Mix always exits 1)    │
                 │  from exit 3 (exit({:shutdown, 3}))       │
                 └─────────────────────────────────────────┘

  Separate, parallel slice (no shared runtime state with the above):

  .github/workflows/release-please.yml (3 job names + 2 artifact names renamed)
  .github/workflows/phase70-proof.yml   (1 job name renamed, disambiguated)
        │
        ▼
  script/list_merge_blocking_checks.py --producers  [WIDENED: global (name,path,job_id) dup scan
                                                       + version-literal regex reject]
        │
        ▼
  script/check_required_checks_registered.sh          [NEW: uniqueness assertion consumes the
                                                        widened scan; fails on any collision]
```

### Recommended Project Structure

No new files/directories. Existing structure:
```
lib/crosswake/release_status.ex          # composition + rendering (D-05..D-10, D-13)
script/check_release_workflow_integrity.exs  # scanner (D-02, D-04, D-14)
lib/mix/tasks/crosswake.release.status.ex    # exit-code call site (D-14, D-16)
.github/workflows/release-please.yml         # display-name renames (D-22)
.github/workflows/phase70-proof.yml          # display-name rename (D-22)
script/list_merge_blocking_checks.py         # widened duplicate scan (D-20)
script/check_required_checks_registered.sh   # uniqueness assertion, exit-code doc header (D-16, D-24)
test/crosswake/proof/phase142_release_integrity_test.exs   # regression floor — must stay green
test/crosswake/proof/phase153_ios_mirror_unblock_test.exs  # regression floor — must stay green
test/mix/tasks/crosswake_release_status_test.exs           # exit-code/render assertions
test/crosswake/proof_lane/ios_verifier_test.exs            # locks the existing 2-vs-3 exit split
```

### Pattern 1: Additive wire-protocol extension (TAP-plan-line precedent)
**What:** Add new line *kinds* to an existing line-oriented stdout protocol without changing or
reordering the lines the current consumer already parses.
**When to use:** Any time a consumer's regex is narrower than the full producer output and the goal
is "prove completeness" without breaking existing parsers — exactly D-02's ROSTER/DONE addition.
**Example (verified against source):**
```elixir
# Source: script/check_release_workflow_integrity.exs:166-178 (current, before this phase)
failures = Enum.filter(checks, &match?({:error, _, _}, &1))

for {status, id, detail} <- checks do
  prefix = if status == :ok, do: "OK", else: "FAIL"
  IO.puts("[crosswake] #{prefix}: #{id} - #{detail}")
end

if failures == [] do
  System.halt(0)
else
  System.halt(1)
end
```
The consumer regex is `^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$`
[VERIFIED: lib/crosswake/release_status.ex:923] — quoted exactly:
`~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/`. A `ROSTER:`/`DONE:` line does not match this
pattern, so it is silently ignored by `parse_workflow_integrity_output/1` today — confirming D-02's
"purely additive" claim.

### Anti-Patterns to Avoid
- **Converting eager evaluation to streaming to "fix" MSG-02:** rejected explicitly by D-01 — a
  crashed scanner mid-stream would print ~40 already-emitted `OK:` lines that a maintainer skimming
  red CI would misread as a clean run. This is the project's own named "right failure, wrong
  explanation" pitfall.
- **Reporting a bare ID instead of the failing check's `detail`:** the entire live defect this phase
  fixes (MSG-01). `scanner_ids_result/2` [VERIFIED: lib/crosswake/release_status.ex:823-844] —
  quoted: `missing = Enum.reject(required_ids, &Map.has_key?(checks, &1))` /
  `failing = checks |> Enum.filter(fn {_id, check} -> match?(%{status: :error}, check) end) |> Enum.map(fn {id, _check} -> id end)` —
  builds only ID *lists*, discarding `detail` entirely before it ever reaches `scanner_check/7`'s
  message string.
- **Using `System.halt/1` in a script whose stdout is piped by CI:** truncates buffered output.
  [VERIFIED: lib/mix/tasks/crosswake.demo.ex:24-25] — quoted: `A non-zero exit from the script (e.g.
  Docker absent / daemon down) is propagated via \`exit({:shutdown, status})\` so callers see the
  real failure code.` — this is the project's own documented idiom D-14 extends.
- **Adding a fourth check status without updating both `aggregate_status/1` and `exit_code/1` in the
  same commit:** `exit_code/1`'s catch-all [VERIFIED: lib/crosswake/release_status.ex:873-875] —
  quoted verbatim: `def exit_code(:error), do: 1` / `def exit_code(%{status: status}), do:
  exit_code(status)` / `def exit_code(_status), do: 0` — silently maps ANY unrecognized status to
  `0` (success). This is precisely the "absence scored as success" hazard the project has a standing
  named lesson about (PR #173, per Claude's own memory of this project).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fixture-based scanner failure/crash reproduction | A mock/stub of `System.cmd` | `path_from_env/2`'s existing env-var overrides [VERIFIED: script/check_release_workflow_integrity.exs:184-189] — quoted: `defp path_from_env(name, default) do case System.get_env(name) do value when is_binary(value) and value != "" -> value; _ -> default end end` | Every scanner input is already env-overridable (`RELEASE_PLEASE_MANIFEST_PATH` and ~10 more per CONTEXT.md); pointing an env var at a drifted fixture file produces a *real* FAIL/crash with no mocking |
| Duplicate-workflow-display-name detection | A new GitHub Actions job or a call to the GitHub API | Widen the existing local `script/list_merge_blocking_checks.py --producers` traversal (already inventories all producers per CONTEXT.md; confirmed the script already contains a `duplicate-producer/duplicate-merge-blocking-name` diagnostic path at line 268) | The traversal, diagnostic-message helper (`diagnostic/5`), and CLI plumbing already exist — this is a widening of the existing `"merge-blocking" in record[0].lower()` filter (line 260), not new infrastructure |
| Exit-code precedent for "could not verify" | A new exit-code convention | Ratify the existing `3 = UNVERIFIED` convention [VERIFIED: script/check_required_checks_registered.sh:51-52] — quoted: `echo "[crosswake] UNVERIFIED (exit 3): cannot read branch protection for ${REPO}@${BRANCH}." >&2` / `exit 3` | This exact convention is already locked by `test/crosswake/proof/phase135_ci_ops_proof_test.exs:526-533` per CONTEXT.md; adopting it elsewhere is consistency, not invention |

**Key insight:** Nearly everything this phase needs (fixture injection points, a duplicate-scan
traversal, an exit-code convention, a `[crosswake] … / What to do next:` microcopy house style,
`maybe_put/3` for additive nil-safe fields) already exists in the repo. The phase's job is almost
entirely *composition and correction*, not new mechanism — consistent with its "pure diagnostics
refactor" framing in the roadmap.

## Common Pitfalls

### Pitfall 1: Fail-open catch-all silently absorbs the new status atom
**What goes wrong:** Adding `:unverifiable` to `aggregate_status/1` without also updating
`exit_code/1`'s catch-all leaves `exit_code(:unverifiable)` falling through to
`def exit_code(_status), do: 0` — a scanner crash would then report SUCCESS.
**Why it happens:** Elixir function-clause catch-alls are easy to leave stale when a new value is
introduced elsewhere in the pipeline; nothing forces the two functions to be updated together.
**How to avoid:** D-13 requires wiring both `aggregate_status/1` and `exit_code/1` in the SAME
change; add an explicit test asserting `exit_code(:unverifiable) == 3` (not just `!= 0`).
**Warning signs:** A test that only asserts `exit_code(status) != 0` rather than the specific value
`3` would pass even with this bug present — assert the exact code.

### Pitfall 2: Renumbering an exit code that's already load-bearing elsewhere
**What goes wrong:** `2` is already used for three different meanings across this repo (defect-found
in `verify_generated_ios_shell.sh`/`physical_iphone.ex`; usage-error in
`check_required_checks_registered.sh`/`verify_companion_cleanroom.sh`; shells-behind in
`crosswake.shell.status.ex`). Reusing `2` for "could not verify" here would create a fourth,
conflicting meaning.
**Why it happens:** Exit codes look like free integers; without an explicit inventory it's easy to
pick one that's already spoken for.
**How to avoid:** D-11 locked `3`, which is already used for could-not-run in two independently
tested places. Verify no other in-scope script currently uses `3` for something else before adding
a new meaning (checked in this research: only the two "could not run" precedents use `3`).
**Warning signs:** Any test in `test/crosswake/proof_lane/ios_verifier_test.exs` (which "locks the
2-vs-3 split" per CONTEXT.md) failing after this phase's changes signals a collision.

### Pitfall 3: `Mix.raise` cannot express exit code 3
**What goes wrong:** `Mix.Tasks.Crosswake.Release.Status.run/1` currently does
`if Crosswake.ReleaseStatus.exit_code(status) != 0 do Mix.raise(...) end`
[VERIFIED: lib/mix/tasks/crosswake.release.status.ex:47-49] — quoted exactly. `Mix.raise/1` always
terminates the OS process with exit code 1, regardless of the message — it cannot surface a 3.
**Why it happens:** `Mix.raise` is the idiomatic way to fail a Mix task, but it hard-codes exit 1;
this is a Mix framework constraint, not a bug in this file.
**How to avoid:** Branch explicitly: `exit_code(status) == 1` → keep `Mix.raise` (already correct
for the defect-found case); `exit_code(status) == 3` → use `exit({:shutdown, 3})` per D-14, printing
the UNVERIFIED microcopy first via `Mix.shell().info/1` (already used for the normal render).
**Warning signs:** A test asserting the Mix task's OS-level exit code (not just that it raised) will
catch a regression here; `mix run` under `System.cmd` and checking the returned exit status is the
mechanism (see Validation Architecture).

### Pitfall 4: Landing the widened duplicate-name scan before the rename fix
**What goes wrong:** `script/list_merge_blocking_checks.py`'s current dedup only matches names
containing `"merge-blocking"` [VERIFIED: script/list_merge_blocking_checks.py:260] — quoted:
`if "merge-blocking" in record[0].lower():`. Widening this to a global scan BEFORE renaming
`phase70-proof.yml`'s job name will immediately trip on the pre-existing
`advisory-provider-sandbox-proof` / `advisory-provider-sandbox-device-proof` collision
[VERIFIED: .github/workflows/phase48-proof.yml:17, .github/workflows/phase70-proof.yml:17] — both
quoted verbatim as `name: advisory provider sandbox/device proof (storekit + play billing)` — and
turn `main` red, with no `--admin` merge escape hatch in this repo.
**Why it happens:** The natural PR-splitting instinct ("land the check, then land the fix") is wrong
here because the check and the pre-existing defect it detects are not independent.
**How to avoid:** D-21 mandates both land in the SAME commit. Sequence within that commit doesn't
matter since it's one atomic change to `main`.
**Warning signs:** CI going red on a PR that only appears to add a test/check, with no apparent
functional change — a signal the widened scan found a real pre-existing collision that wasn't fixed
in the same commit.

## Code Examples

Verified patterns from this session's direct reads of the actual source files (all quoted verbatim,
not paraphrased):

### Current scanner print loop (before this phase)
```elixir
# Source: script/check_release_workflow_integrity.exs:166-178
failures = Enum.filter(checks, &match?({:error, _, _}, &1))

for {status, id, detail} <- checks do
  prefix = if status == :ok, do: "OK", else: "FAIL"
  IO.puts("[crosswake] #{prefix}: #{id} - #{detail}")
end

if failures == [] do
  System.halt(0)
else
  System.halt(1)
end
```
Confirms D-01's "verified ground truth": the check list (lines 85-164, ~62 entries plus two
`++`-appended generators) is built entirely eagerly BEFORE this loop runs — there is no code path
where a later check's evaluation is skipped because an earlier one failed.

### Current `scanner_ids_result/2` — the live MSG-01 defect and the latent MSG-03 ordering bug
```elixir
# Source: lib/crosswake/release_status.ex:820-844
defp scanner_ids_result(%{status: :unavailable, message: message}, _required_ids),
  do: {false, [], message}

defp scanner_ids_result(%{status: :failed, checks: checks}, required_ids) do
  missing = Enum.reject(required_ids, &Map.has_key?(checks, &1))

  failing =
    checks
    |> Enum.filter(fn {_id, check} -> match?(%{status: :error}, check) end)
    |> Enum.map(fn {id, _check} -> id end)
    |> Enum.sort()

  evidence = Enum.uniq(missing ++ failing)

  cond do
    missing != [] ->
      {false, evidence, "missing scanner IDs: #{Enum.join(missing, ", ")}"}

    failing != [] ->
      {false, evidence, "failing scanner IDs: #{Enum.join(failing, ", ")}"}

    true ->
      {false, evidence, "scanner exited nonzero without parseable failing IDs"}
  end
end
```
This is the exact function D-09 targets: `missing != []` is checked before `failing != []`, so a
scanner run with both a genuinely failing check AND (hypothetically) a missing required ID would
report only "missing scanner IDs: …" and never mention the failure — confirming MSG-03's literal
wording. Note `checks` here is a `Map` (post `parse_workflow_integrity_output/1`'s `Map.new/1`), so
`detail` is available in the map values but is discarded — only `id` is extracted into `failing`,
confirming MSG-01's live defect at its exact source line.

### Current exit-code fail-open catch-all
```elixir
# Source: lib/crosswake/release_status.ex:873-875
def exit_code(:error), do: 1
def exit_code(%{status: status}), do: exit_code(status)
def exit_code(_status), do: 0
```

### Current Mix task exit-code call site (cannot express 3)
```elixir
# Source: lib/mix/tasks/crosswake.release.status.ex:44-49
status = Crosswake.ReleaseStatus.build(live?: opts[:live] == true)
output = if opts[:json] == true, do: Jason.encode!(status, pretty: true), else: Crosswake.ReleaseStatus.render(status)
Mix.shell().info(output)

if Crosswake.ReleaseStatus.exit_code(status) != 0 do
  Mix.raise("Crosswake release status found blocking release issues")
end
```

### The documented `exit({:shutdown, status})` idiom this phase extends
```elixir
# Source: lib/mix/tasks/crosswake.demo.ex:24-25 (comment) and :42 (usage)
# A non-zero exit from the script (e.g. Docker absent / daemon down) is propagated
# via `exit({:shutdown, status})` so callers see the real failure code.
...
exit({:shutdown, status})
```

### Existing exit-3 precedent this phase ratifies
```bash
# Source: script/check_required_checks_registered.sh:50-52
elif ! current="$(gh api "$EP" 2>/dev/null)"; then
  echo "[crosswake] UNVERIFIED (exit 3): cannot read branch protection for ${REPO}@${BRANCH}." >&2
  exit 3
fi
```

### Workflow trigger confirming D-18's "renames are free" claim
```yaml
# Source: .github/workflows/release-please.yml:13-17
on:
  push:
    branches:
      - main
  workflow_dispatch:
```
No `pull_request:` trigger exists, confirming this workflow emits zero PR check contexts, so its
job/artifact display-name renames cannot intersect branch protection's single required context
(`Crosswake CI`).

### Confirmed duplicate display name (D-19)
```yaml
# Source: .github/workflows/phase48-proof.yml:16-17
advisory-provider-sandbox-proof:
  name: advisory provider sandbox/device proof (storekit + play billing)
```
```yaml
# Source: .github/workflows/phase70-proof.yml:16-17
advisory-provider-sandbox-device-proof:
  name: advisory provider sandbox/device proof (storekit + play billing)
```
Identical `name:` strings under different job IDs — confirmed the ONE real collision (not three).

### Confirmed `0.2.1`-bearing display strings targeted by D-22
```yaml
# Source: .github/workflows/release-please.yml:30
approved-release-guard:
  name: Guard exact approved 0.2.1 merge
```
```yaml
# Source: .github/workflows/release-please.yml:719
exact-public-proof:
  name: Prove exact public 0.2.1 artifacts
```
```yaml
# Source: .github/workflows/release-please.yml:767
linked-release-rollup:
  name: Linked 0.2.1 release rollup
```
```yaml
# Source: .github/workflows/release-please.yml:761 (artifact upload)
with:
  name: exact-public-proof-0.2.1
```
```yaml
# Source: .github/workflows/release-please.yml:829 (artifact upload)
with:
  name: linked-release-status-0.2.1
```

### Existing regression-test shape to copy for new assertions
```elixir
# Source: test/crosswake/proof/phase142_release_integrity_test.exs:91 (repeats at :125,:136,:147,:158,:209,:298)
assert output =~ "[crosswake] OK: #{check_id}"
```
This exact assertion shape (also at `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs:134,
202`) must remain green after D-02's additive ROSTER/DONE lines and D-07's own-scope-only reporting
change — neither should alter these specific `OK:`/id/message triples for unaffected checks.

### Duplicate-scan widening target
```python
# Source: script/list_merge_blocking_checks.py:260-272 (current substring-only filter)
if "merge-blocking" in record[0].lower():
    ...
        "duplicate-producer/duplicate-merge-blocking-name",
        ...
        "rename the later producer while retaining a stable merge-blocking name.",
```
D-20 widens the condition this `if` guards from a `"merge-blocking"` substring match to an
unconditional check over ALL `(name, path, job_id)` records.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Bare scanner-check IDs surfaced on failure | Verbatim `detail` string surfaced, prefixed by ID, at one stable owner check | This phase (D-06/D-07) | Directly closes the PR #164-class defect: five identical uninformative errors become one informative paragraph plus four honest greens |
| `System.halt/1` for scanner/task exit | `exit({:shutdown, code})` / `System.stop + Process.sleep(:infinity)` | This phase (D-14) | Prevents stdout truncation when piped by CI; matches the project's own existing documented idiom |
| `missing`-before-`failing` cond ordering | `failing`-before-`missing`, explanation for `missing` instead of unexplained absence | This phase (D-09) | Latent-bug hardening; not observable today because `missing` is empirically always empty, but forecloses a future regression |
| 2-value exit contract (0/1) for `mix crosswake.release.status` | 3-value contract (0/1/3) | This phase (D-11..D-17) | Makes "ran and found nothing wrong" distinguishable from "did not actually run" — the milestone's core thesis applied to this one command |

**Deprecated/outdated:** None — no external library versions are in play; this is purely an
internal-convention change within an already-current codebase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact "68 `[crosswake]` lines" / "27 required IDs" / "0 missing" counts from CONTEXT.md's `<verified_ground_truth>` were established by CONTEXT.md's own author actually running the scanner during discussion, not independently re-run in this research session | Verified Ground Truth (carried into this file's User Constraints) | If those exact counts have drifted since the discussion session (e.g. a check was added in the interim), the D-04 `roster_exact` self-check and D-03's "68 of 68" literal strings would need the current live count substituted before use as literal test fixtures — the planner should have the executor re-run the scanner once at implementation time to confirm the count rather than hardcoding "68" from this document |

**All other claims in this research were verified this session by reading the cited source files
directly** (release_status.ex, check_release_workflow_integrity.exs, release-please.yml,
phase48/70-proof.yml, check_required_checks_registered.sh, list_merge_blocking_checks.py,
crosswake.release.status.ex, crosswake.demo.ex, phase142/153 test files, mix.exs) — no further user
confirmation is needed for those.

## Open Questions

1. **Exact current total check count and required-ID count for the D-04 `roster_exact` fixture and
   D-03's "68 of 68" literal strings**
   - What we know: CONTEXT.md's verified-ground-truth section states 68 emitted lines / 27 required
     IDs / 0 missing, established by an actual run during discussion (2026-09-15).
   - What's unclear: Whether that exact count is still current at plan/execution time (the check
     list in `check_release_workflow_integrity.exs` could have grown between discussion and
     execution if another phase's work lands first — none of the other v23.0 phases in flight touch
     this file per the canonical refs, so this is a low-probability drift).
   - Recommendation: The executor should re-run `elixir script/check_release_workflow_integrity.exs`
     once at the start of implementation and substitute the live count into D-03/D-04's literal
     strings rather than trusting "68" as frozen; this is a cheap confirmation, not a redesign.

2. **Whether the D-15 optional `check_release_version_truth.exs` BLOCKED 2→3 sweep should be taken**
   - What we know: CONTEXT.md marks it as Claude's Discretion, "only if it stays a clearly separable
     commit."
   - What's unclear: Whether the planner should schedule it as an optional final wave or omit it
     entirely from this phase's plan.
   - Recommendation: Schedule it as a separate, clearly-labeled optional final task/plan so it can be
     dropped without touching the required D-01..D-24 work if time/risk pressure emerges.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compiling/testing `release_status.ex`, running the scanner script | ✓ | `~> 1.19` [VERIFIED: mix.exs] | — |
| `mix test` | Running the ExUnit regression suite | ✓ (project's standard command) | — | — |
| Python 3 | `list_merge_blocking_checks.py`, `normalize_required_checks.py` | ✓ (already used elsewhere in this repo's scripts) | — | — |
| `gh` CLI | Only in the LIVE branch-protection check path of `check_required_checks_registered.sh` (`--live` flag) | Not required for this phase's `--local-only` producer-inventory path, which is what D-20/D-23's new duplicate-scan assertion uses | — | Use `--local-only` invocation exclusively; this phase does not touch the `--live` branch-protection path (D-18 explicitly leaves branch protection untouched) |

**Missing dependencies with no fallback:** None — this phase's required code paths (`elixir`,
`mix test`, local Python inventory) are already exercised routinely by this repo's own CI.

**Missing dependencies with fallback:** `gh` / live GitHub API access is not needed for this phase's
in-scope work (see table).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir `~> 1.19`) [VERIFIED: mix.exs] |
| Config file | `mix.exs` project config; no separate ExUnit config file needed beyond `test/test_helper.exs` (standard) |
| Quick run command | `mix test test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase153_ios_mirror_unblock_test.exs test/mix/tasks/crosswake_release_status_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MSG-01 | A deliberately-failing scanner check (env-var-pointed fixture, e.g. drifted manifest per `RELEASE_PLEASE_MANIFEST_PATH`) surfaces its own verbatim `detail` in `mix crosswake.release.status` output, not a bare-ID list | unit/integration | `mix test test/crosswake/proof/phase142_release_integrity_test.exs -x` (extend with a new test asserting the exact verbatim string) | ✅ file exists; new assertion needed — Wave 0 |
| MSG-02 | A scanner crash (env-var-pointed missing-file fixture) is reported as "terminated early" distinct from a never-defined required ID | unit/integration | `mix test test/crosswake/proof/phase142_release_integrity_test.exs -x` (new test exercising both cases) | New test cases — Wave 0 |
| MSG-03 | A `cond` reordering test: construct a scanner-result fixture with both `failing` and `missing` non-empty, assert `failing` is named in the message | unit | New ExUnit test targeting `scanner_ids_result/2` directly or via the public `render/1` surface | New test — Wave 0 |
| MSG-06 | Introduce a duplicate display name into a fixture workflow pair; assert `list_merge_blocking_checks.py`/`check_required_checks_registered.sh` exits nonzero with the duplicate-producer diagnostic; separately assert the version-literal (`\d+\.\d+\.\d+`) reject fires on a `name: prove 1.2.3 thing` fixture | integration (subprocess) | New Python/bash-invoking ExUnit test or a direct `python3 script/list_merge_blocking_checks.py --producers` invocation against a fixture dir | New test — Wave 0 (per D-23's non-vacuity proof requirement) |
| FID-02 | `mix crosswake.release.status` exits 1 for a real defect and exits 3 for could-not-run (crash), diffed via subprocess exit code | integration (subprocess) | New test using `System.cmd("mix", ["crosswake.release.status"], ...)` capturing `exit_status`, or a lower-level test directly asserting `Crosswake.ReleaseStatus.exit_code(:unverifiable) == 3` plus a Mix-task-level subprocess test for the OS-level code | Partial — `test/mix/tasks/crosswake_release_status_test.exs` exists (asserts render/exit-code behavior per canonical refs at lines 160, 241-243, 426, 458, 479); extend it, don't replace it — Wave 0 for the new `:unverifiable`/3 cases |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/proof/phase142_release_integrity_test.exs test/crosswake/proof/phase153_ios_mirror_unblock_test.exs test/mix/tasks/crosswake_release_status_test.exs test/crosswake/proof_lane/ios_verifier_test.exs` (the four files CONTEXT.md's canonical refs identify as constraining this change)
- **Per wave merge:** `mix test` (full suite) plus, for the workflow-rename wave,
  `python3 script/list_merge_blocking_checks.py --producers` and
  `bash script/check_required_checks_registered.sh --local-only` run directly (not just via ExUnit)
  to confirm the non-vacuity count (D-23: "exactly 1 real collision on pre-fix main" before the fix,
  "0" after)
- **Phase gate:** Full suite green before `/gsd-verify-work`; additionally, a manual/CI run of
  `elixir script/check_release_workflow_integrity.exs` against a real (non-fixture) workflow to
  confirm the new `roster_exact` self-check passes on the actual, non-drifted repo state

### Wave 0 Gaps
- [ ] New ExUnit test(s) in `test/crosswake/proof/phase142_release_integrity_test.exs` (or a new
  `phase169_*_test.exs` file, planner's discretion) asserting MSG-01's verbatim-detail surfacing —
  reuse the `path_from_env/2` env-var fixture mechanism, no mocking
- [ ] New ExUnit test(s) covering MSG-02's two crash-shape microcopy strings from D-03 (crash before
  vs after roster line)
- [ ] New ExUnit test covering MSG-03's `failing`-before-`missing` composed message
- [ ] New fixture workflow-file pair (colliding display name) plus a version-literal fixture
  (`name: prove 1.2.3 thing`) for D-23's non-vacuity proof of the widened duplicate scan
- [ ] New test(s) for FID-02's exit-3 path — both at the `exit_code/1` unit level and at the Mix-task
  subprocess level (the latter is the one that actually proves the OS-level exit code, since
  `Mix.raise` unit tests alone cannot observe the process exit status)
- [ ] Guard test per D-24: reads each verification entry point and asserts its literal exit values
  against the D-16 documented set

*(No test-framework installation needed — ExUnit and the project's existing test layout already
cover this phase's requirements; the gaps above are new test CASES, not new infrastructure.)*

## Security Domain

This phase performs no authentication, session, access-control, cryptography, or external-input
handling changes. It renames display strings, reorders a `cond`, adds two additive stdout lines, and
changes an exit-code contract. `security_enforcement` is not explicitly disabled in
`.planning/config.json` for this workstream, so this section is included per the reference protocol,
but no ASVS category applies to this phase's file set.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | n/a — no auth code touched |
| V3 Session Management | no | n/a |
| V4 Access Control | no | n/a — branch protection explicitly untouched (D-18) |
| V5 Input Validation | no (marginal) | The scanner already reads YAML/JSON files it trusts as first-party repo content; the version-literal regex reject (D-20) is a static-analysis check, not an input-validation boundary against untrusted input |
| V6 Cryptography | no | n/a |

### Known Threat Patterns for {stack}

No STRIDE-relevant pattern applies. The nearest adjacent concern — a maintainer misreading CI output
and merging/publishing on a false green — is exactly what this phase's MSG-01/02/03/FID-02 changes
are designed to prevent, and is tracked as a diagnostics-legibility defect, not a security
vulnerability.

## Sources

### Primary (HIGH confidence — read directly this session)
- `/Users/jon/projects/crosswake/lib/crosswake/release_status.ex` (lines 1-200, 370-470, 790-945) — module attributes, `build/1`, `render/1`, `scanner_check/7`, `scanner_ids_result/2`, `aggregate_status/1`, `exit_code/1`, `workflow_integrity_evidence/1`, `parse_workflow_integrity_output/1`, `maybe_put/3`
- `/Users/jon/projects/crosswake/script/check_release_workflow_integrity.exs` (lines 1-190) — eager check-list construction, print loop, `System.halt/1`, `path_from_env/2`
- `/Users/jon/projects/crosswake/.github/workflows/release-please.yml` (lines 1-35, 715-835) — triggers, job names, artifact names targeted by D-22
- `/Users/jon/projects/crosswake/.github/workflows/phase48-proof.yml` and `phase70-proof.yml` (job-name lines) — confirmed D-19's single duplicate
- `/Users/jon/projects/crosswake/script/check_required_checks_registered.sh` (lines 1-60) — exit-3 precedent, `--local-only` producer-inventory path
- `/Users/jon/projects/crosswake/script/list_merge_blocking_checks.py` (relevant grep hits) — existing `"merge-blocking"`-substring dedup filter to be widened
- `/Users/jon/projects/crosswake/test/crosswake/proof/phase142_release_integrity_test.exs` (lines 1-60, plus assertion-line grep) — regression floor shape
- `/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.release.status.ex` (full file) — exit-code call site, `Mix.raise` constraint
- `/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.demo.ex` (relevant lines) — documented `exit({:shutdown, status})` idiom
- `/Users/jon/projects/crosswake/mix.exs` — Elixir version constraint
- `/Users/jon/projects/crosswake/.planning/config.json` — `nyquist_validation: true`

### Secondary (MEDIUM confidence)
- `169-CONTEXT.md`'s own `<verified_ground_truth>` section — states it was established by running
  the scanner live during the discuss-phase session (2026-09-15); not independently re-run in this
  research session, but internally consistent with everything independently verified above (see
  Assumptions Log A1)

### Tertiary (LOW confidence)
- None — no WebSearch or external documentation was needed for this phase; it is entirely a
  first-party repo refactor with no new external dependency or unfamiliar API surface

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; existing Elixir/Python/ExUnit toolchain confirmed present
- Architecture: HIGH — every cited file:line was read directly this session and matches CONTEXT.md's claims verbatim
- Pitfalls: HIGH — each pitfall is grounded in a specific, quoted line of currently-live source code

**Research date:** 2026-09-15
**Valid until:** 30 days (stable first-party codebase; re-verify the "68 checks / 27 required IDs" count from Open Question 1 at plan/execution time regardless)
