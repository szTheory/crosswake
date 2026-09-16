# Phase 169: Diagnostic Legibility - Context

**Gathered:** 2026-09-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Make release and verification failures legible: a maintainer reading any failing release check sees
that check's own sentence, and the system never reports "missing" or "clean" when the true state is
"failing" or "could not run."

The phase may change how `Crosswake.ReleaseStatus` composes and renders scanner results, add an
additive stdout protocol (roster + completion sentinel) to
`script/check_release_workflow_integrity.exs`, widen the duplicate-display-name scan in
`script/list_merge_blocking_checks.py`, add a uniqueness assertion to
`script/check_required_checks_registered.sh`, rename version-welded job/artifact display strings in
`.github/workflows/release-please.yml`, and introduce a documented third exit code for
"could not verify."

The phase does NOT change release-graph behavior, does NOT touch any publish-gating `if:` clause,
does NOT remove the `0.2.1` literals or the `cleanroom.ex:236` weld (Phase 171), does NOT add
`release.publish_gate.no_bare_version_literal` (Phase 171), does NOT retire the interim
`release.version_weld.gates_match_declared_version` tripwire (Phase 171), does NOT touch branch
protection, and does NOT publish anything.

</domain>

<verified_ground_truth>
## Verified Ground Truth — supersedes SUMMARY.md divergence #2

**This was established by running the scanner during discussion, not by reading it.** The upstream
research's causal story is wrong at both links, and the planner must not implement against it.

Reproduction: `RELEASE_PLEASE_MANIFEST_PATH=<manifest with "." = "0.2.2"> elixir
script/check_release_workflow_integrity.exs`

| Observation | Result |
|---|---|
| Clean `main` run | 68 `[crosswake]` lines, 68 OK, 0 FAIL, exit 0 |
| PR #164 drift condition | 68 `[crosswake]` lines, 67 OK, **1 FAIL**, exit 1 |
| Required IDs absent from scanner roster | **zero** (`comm -23` over the 27 required IDs vs the 68 emitted) |

**SUMMARY.md divergence #2 claims:** "the scanner exits non-zero at the weld check → later checks
never emit their `[crosswake] OK/FAIL` lines → their required IDs are absent from `checks` →
`missing != []` fires first." **Both links are false.**

1. `script/check_release_workflow_integrity.exs:83-167` builds the ENTIRE check list eagerly, THEN
   prints every line, THEN halts. A failing check does not suppress any later check.
2. `missing` is empty in practice — every required ID in `release_status.ex`'s module attributes is
   present in the scanner's 68-ID roster.

**Therefore the live PR #164 defect is ONE defect, not three:** `scanner_ids_result/2`
(`lib/crosswake/release_status.ex:823-845`) returns only ID *lists* and never the check's `detail`
string, and because `failing` is computed over the FULL parsed set, all five `scanner_check/7` call
sites print the same foreign bare ID. Five identical uninformative errors; the sentence explaining
the release would tag and publish nothing appears nowhere in the output.

Requirement status as verified:

- **MSG-01** — CONFIRMED LIVE. `detail` is discarded; only bare IDs surface.
- **MSG-03** — LATENT, NOT LIVE. The `cond` at `:834` genuinely orders `missing` before `failing`
  and must be corrected, but with `missing` empty it does not fire today. Fix it as a latent-bug
  hardening; do NOT build the phase's acceptance test around it as the live #164 reproduction.
- **MSG-02** — TARGET STATE UNREACHABLE AS WORDED. There is no partial-emission state. The only
  non-emitting path is a raise during setup/list construction, which prints ZERO `[crosswake]`
  lines. The success criterion's phrase "how many checks after the last observed failure never ran"
  describes a state that cannot occur under eager evaluation. See D-03 for the restated microcopy
  that IS satisfiable and does satisfy MSG-02's intent.

</verified_ground_truth>

<decisions>
## Implementation Decisions

### Scanner emission protocol (MSG-02)

- **D-01:** Keep eager evaluation. Do NOT convert the ~62-tuple list literal to streaming. Streaming
  would trade a genuinely strong property — a crashed scanner asserts NOTHING — for a partial-truth
  mode in which ~40 already-printed `OK:` lines are greens from an aborted process. A maintainer
  skimming red CI reads those as a clean run: this project's named "right failure, wrong
  explanation" pitfall, manufactured by the very phase meant to end it. It also costs ~62 mechanical
  edit sites in a phase chartered as fully reversible.

- **D-02:** Add two additive stdout verbs to `script/check_release_workflow_integrity.exs`. A
  `ROSTER` line emitted BEFORE the check list is constructed, and a `DONE` sentinel emitted after
  all lines print:

  ```
  [crosswake] ROSTER: 68 release.concurrency.not_cancelled,release.concurrency.queue_max,…
  [crosswake] OK:   release.concurrency.not_cancelled - …
  [crosswake] FAIL: release.version_weld.gates_match_declared_version - …
  [crosswake] DONE: 68 of 68 roster checks emitted; 1 failed.
  ```

  `DONE` makes "this was a complete run" a POSITIVE ASSERTION rather than an inference from absence
  — the anti-vacuity move, and the whole point of the phase. `ROSTER` supplies the denominator that
  makes "never defined" (ID absent from the roster ⇒ the required-ID list in
  `Crosswake.ReleaseStatus` has drifted from the scanner) decidable from "never ran" (ID in the
  roster, no line emitted). Precedent: TAP's `1..N` plan line. TAP's known footgun — harnesses
  tolerating a plan/emission mismatch silently — is avoided by D-04.

  Both verbs are purely additive: the existing consumer regex
  `^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$` ignores them, and every existing test assertion of
  the form `output =~ "[crosswake] OK: #{id}"` (7 sites in
  `test/crosswake/proof/phase142_release_integrity_test.exs`, plus
  `phase153_ios_mirror_unblock_test.exs`) stays green.

- **D-03:** Restate MSG-02's message microcopy to describe the state that can actually occur. The
  intent of MSG-02 — "terminated early" is reported distinctly from "never defined" — is fully
  satisfied; only the count phrasing changes, because there is no "last observed failure" to count
  from. Literal target strings:

  - Crash before the roster line: `scanner did not start: no roster line emitted (exit 1). stderr: …`
    → `:unavailable`
  - Crash after the roster line: `scanner terminated early: 0 of 68 roster checks ran (exit 1). stderr: …`
    → `:unverifiable` (per D-11)
  - ID absent from roster: `never defined by scanner: release.foo.bar — not in the scanner's 68-check
    roster; the required-ID list in Crosswake.ReleaseStatus has drifted from
    script/check_release_workflow_integrity.exs` → `:error`

  The ROSTER/DONE contract is forward-compatible: if streaming is ever adopted later, the same
  consumer renders `"14 of 68 … never ran (last emitted: …)"` with no parser change.

- **D-04:** The roster ID list is derived from the check bodies and can rot. Neutralize that
  mechanically: the scanner itself asserts that the emitted ID set equals the roster exactly, and a
  mismatch is a hard `FAIL: release.scanner.roster_exact`. Never advisory.

- **D-05:** `parse_workflow_integrity_output/1` (`lib/crosswake/release_status.ex:919-934`) must stop
  ending in `Map.new/1`, which discards emission order. Retain order (ordered list, or an `:order`
  index stored on each check map via `Enum.with_index`). Order is the precondition for naming a root
  cause deterministically and for computing never-ran counts at all.

### Report composition and blast radius (MSG-01, MSG-03)

- **D-06:** Add one new always-emitted check, `release.workflow_integrity`, which owns the FULL
  parsed scanner set and surfaces any failing check's **verbatim `detail`**, prefixed by its ID,
  regardless of whether that ID belongs to any caller's `required_ids`. This is the single place the
  root-cause sentence appears, at a stable owning ID — not "whichever call site happened to be
  first," which moves when call sites are reordered.

- **D-07:** The five existing `scanner_check/7` call sites
  (`lib/crosswake/release_status.ex:382`, `:394`, `:414`, `:423`, `:432`) report only their OWN
  failures, with the failing check's verbatim `detail` instead of a bare ID. **Under a complete run
  in which only a foreign check fails, they report OK.** This is accuracy, not weakening: their
  gates genuinely passed, the aggregate still fails via D-06's owner check, and the report drops
  from five identical uninformative errors to one paragraph carrying the sentence plus four honest
  greens. This narrows SUMMARY.md's locked rule 1 from "every call site surfaces the foreign detail"
  to "the report surfaces it exactly once, verbatim, prefixed by its ID, at a stable owning check."
  Recorded here as a deliberate decision, not drift — and it is only safe BECAUSE the verified
  ground truth shows all checks emit, so a scoped check's green is a real green.

- **D-08:** The "not evaluated — the scanner stopped before these gates ran (cause: <id>). This is
  not a pass." cascade pointer applies ONLY to the crash case, where the scoped checks genuinely
  could not evaluate. In that case they carry `:unverifiable` (D-11), never `:ok`, and never a
  status that maps to exit 0.

- **D-09:** Correct the `cond` ordering in `scanner_ids_result/2` (`:834`) so `failing` precedes
  `missing`, and compose every non-empty bucket rather than letting one shadow another:
  `"2 failing (…); 1 never defined (…)"`. Treat this as latent-bug hardening per the verified ground
  truth, and give `missing` an explanation rather than presenting absence as an unexplained new
  problem.

- **D-10:** `render/1` (`:136-150`) prints one line per check. The owner check from D-06 needs an
  indented multi-line block for the verbatim `detail`; every other check stays single-line. `detail`
  is user-facing prose and must not be flattened or truncated. Bump `@schema_version` (`:9`)
  `1.1.0` → `1.2.0` for any additive machine field (e.g. `cause:`); additive fields only, so
  existing `%{status:, code:, message:}` consumers keep working.

### Exit-code vocabulary (FID-02)

- **D-11:** The contract is `0` clean · `1` ran and found a defect · `3` could not verify.
  **Not `2`.** In this repo `2` is already triple-booked: *ran and found a defect* in
  `script/verify_generated_ios_shell.sh` and `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex:50,57,61`;
  *usage error* in `script/check_required_checks_registered.sh:14` and
  `script/verify_companion_cleanroom.sh:83`; and *shells are behind* in the adopter-facing
  `lib/mix/tasks/crosswake.shell.status.ex:121`. Meanwhile `3` ALREADY means could-not-run in two
  independent, already-tested places: `script/check_required_checks_registered.sh:51-52`
  (`UNVERIFIED (exit 3)`, locked by `test/crosswake/proof/phase135_ci_ops_proof_test.exs:526-533`)
  and `script/verify_generated_ios_shell.sh:44,149,168,186`. Adopting `3` ratifies an existing
  in-repo convention and renumbers nothing.

- **D-12:** `:warning` stays exit 0. No fourth code. `PARTIAL` and `BLOCKED` are candidate-lifecycle
  states, not run outcomes, and map through the three above. `2` is deliberately left reserved to
  its existing meanings.

- **D-13:** Add `:unverifiable` as a first-class value to BOTH `aggregate_status/1` (`:862-868`) and
  `exit_code/1` (`:872-874`), in the same change. Precedence `:error > :unverifiable > :warning >
  :ok`; mapping `:error → 1`, `:unverifiable → 3`, `:warning → 0`, `:ok → 0`. Wiring both is
  precisely what makes the new atom safe — `exit_code(_status), do: 0` at `:875` is a catch-all that
  would otherwise map any unrecognized new status to SUCCESS, shipping a fresh "absence scored as
  success" hole through the door built to close one. Composition: 6 passed + 1 could-not-run → exit
  3; 1 failed + 1 could-not-run → exit 1 (a confirmed defect outranks an unknown), with BOTH
  reported on stdout, nothing masked.

- **D-14:** Use `exit({:shutdown, 3})`, never `System.halt/1`, for the new path. `System.halt/1`
  skips `at_exit` hooks and truncates buffered stdout when piped — a live risk because
  `physical_iphone.ex:57` halts immediately after writing JSON to a pipe. The repo already knows
  this: `lib/mix/tasks/crosswake.demo.ex:25` documents the `exit({:shutdown, status})` idiom.
  `Mix.raise` cannot express 3 (Mix always exits 1), so keep `Mix.raise` for the exit-1 path.
  For `check_release_workflow_integrity.exs`, replace `System.halt/1` with
  `System.stop(code); Process.sleep(:infinity)` so stdout flushes — CI pipes it at
  `.github/workflows/crosswake-ci.yml:157`.

- **D-15:** Scope: change `mix crosswake.release.status` (the FID-02 minimum) and
  `script/check_release_workflow_integrity.exs` (MSG-02's home). RATIFY, do not rewrite, the two
  scripts that already conform. Leave `crosswake.shell.status` alone — adopter-facing and
  documented. Optional, clearly separable consistency sweep: move
  `script/check_release_version_truth.exs`'s BLOCKED from 2→3 plus
  `test/crosswake/proof/phase168_version_truth_test.exs` and
  `docs/COMPANION-PUBLISH-RUNBOOK.md:216`; its only caller
  (`.github/workflows/crosswake-ci.yml:190`) treats any nonzero as failure.

- **D-16:** Documentation is single-sourced: the canonical table lives in the `@doc` for
  `Crosswake.ReleaseStatus.exit_code/1` (reachable via `h`, ExDoc, hexdocs). Shell and `.exs`
  verifiers carry a one-line header comment `# exit contract: 0 clean / 1 defect found / 3 could not
  verify`. The runbook gets a LINK, not a copy. No exit-code legend is printed on every run — the
  meaning is carried inline by the words `FAIL (exit 1)` / `UNVERIFIED (exit 3)` plus "Do not read
  exit 3 as a pass," so a maintainer never consults a table.

- **D-17:** Microcopy follows the shipped `[crosswake] …` + "What to do next:" house style. Literal
  target strings:

  ```
  [crosswake] FAIL (exit 1): release status ran all 7 checks and found 2 blocking issues.
  [crosswake]   - hex-core: manifest version=0.2.1 is behind published 0.3.0
  [crosswake] What to do next: fix the named issues above, then re-run `mix crosswake.release.status`.
  ```
  ```
  [crosswake] UNVERIFIED (exit 3): 1 of 7 checks could not run, so its result is unknown — not clean.
  [crosswake]   - live-registry(hex): the registry did not answer (network unreachable)
  [crosswake] The 6 checks that did run passed.
  [crosswake] What to do next: restore the missing prerequisite and re-run. Do not read exit 3 as a pass.
  ```

  Internal status atoms are never leaked to the surface; the human words are `FAIL` / `UNVERIFIED`.

### Display-name renames and uniqueness (MSG-06)

- **D-18:** Phase 169 performs ALL renames and the duplicate fix, atomically in one PR, with **no
  branch-protection step anywhere in the sequence.** The deferral rationale is empirically false:
  live branch protection on `main` requires exactly ONE context, `Crosswake CI` (app_id 15368,
  strict) — confirmed against the live API and mirrored/hard-asserted in
  `script/required_check_policy.json` and `script/list_merge_blocking_checks.py`. And
  `.github/workflows/release-please.yml:13-17` triggers only on `push: branches: [main]` +
  `workflow_dispatch`, so it emits NO pull-request check contexts at all. The three `0.2.1` names
  are pure Actions run-graph display strings. **SEED-007's rename footgun does not apply — these
  renames are free.** Grep across `*.sh|py|ex|exs|yml|md|json` finds no reference to any of the five
  strings outside `release-please.yml` itself; `needs:` edges reference job IDs, never names.
  Deferring to Phase 171 would buy no safety and cost phase-boundary hygiene plus a
  convention-exists-but-violators-persist window.

- **D-19:** There is **1** duplicate display name in the repo, not 3. The roadmap's "three duplicate
  required-check names" is incorrect. The single real collision is
  `advisory provider sandbox/device proof (storekit + play billing)`, produced by both
  `.github/workflows/phase48-proof.yml` (`advisory-provider-sandbox-proof`) and
  `.github/workflows/phase70-proof.yml` (`advisory-provider-sandbox-device-proof`). Both are
  advisory, schedule/dispatch-only. The three `0.2.1` names collide with nothing.

- **D-20:** Today's duplicate detection is **vacuous by construction** — the exact named defect this
  milestone fights. `script/list_merge_blocking_checks.py` only dedupes names containing the
  substring `"merge-blocking"`, a heuristic that post-v22.0 matches only de-registered legacy names,
  so the one real duplicate slips straight through; and `check_required_checks_registered.sh`'s
  producer loop iterates only over REGISTERED contexts, i.e. exactly one string. Widen
  `list_merge_blocking_checks.py` to a GLOBAL duplicate scan over all inventoried
  `(name, path, job_id)` records, and add a version-literal regex reject (`\d+\.\d+\.\d+` in any job
  `name:` or `upload-artifact` `with.name` under `.github/workflows/`).

- **D-21:** The widened scan and the rename fixes MUST land in the same commit. Widening first would
  trip on the phase48/phase70 collision and turn `main` red — and `--admin` merge is refused in this
  repo, so there is no escape hatch. This mirrors Phase 171's own atomicity rule.

- **D-22:** Naming convention, enforced mechanically: a release job/artifact display name is
  `release: <subsystem-noun> <role>`, lowercase after the prefix, and MUST NOT contain a version
  literal. Literal renames:

  | file:line | before | after |
  |---|---|---|
  | `release-please.yml:30` | `Guard exact approved 0.2.1 merge` | `release: approved-candidate merge guard` |
  | `release-please.yml:719` | `Prove exact public 0.2.1 artifacts` | `release: exact-public artifact proof` |
  | `release-please.yml:767` | `Linked 0.2.1 release rollup` | `release: linked release rollup` |
  | `release-please.yml:761` (artifact) | `exact-public-proof-0.2.1` | `exact-public-proof` |
  | `release-please.yml:829` (artifact) | `linked-release-status-0.2.1` | `linked-release-status` |
  | `phase70-proof.yml` job `advisory-provider-sandbox-device-proof` | `advisory provider sandbox/device proof (storekit + play billing)` | `advisory provider device proof (play billing)` |

  Artifact names drop the version suffix to match the already-neutral `native-release-status` at
  `:835`. The advisory rename disambiguates phase48 = storekit sandbox, phase70 = play billing
  device.

- **D-23:** Non-vacuity proof for every new assertion, per the project's own standing lesson
  ("measure a check's findings before making it merge-blocking" — PR #173). Record that the widened
  scan finds exactly **1** real collision on pre-fix `main`; that number IS the proof the check is
  not vacuous. Add a fixture workflow pair introducing a colliding display name and assert the
  inventory exits nonzero with the duplicate-producer diagnostic, plus a second fixture with
  `name: prove 1.2.3 thing` asserting the version-literal reject fires.

- **D-24:** Add a guard test that reads each verification entry point and asserts its literal exit
  values against the documented set from D-16, so the contract cannot drift from the doc. Measure
  that the test actually finds the entry points before making it merge-blocking.

### Claude's Discretion

- Exact module/function decomposition inside `lib/crosswake/release_status.ex`, and whether the
  owner check from D-06 is a new private builder or an extension of `scanner_check/7`.
- Whether order is retained as an ordered list or an `:order` key on each check map (D-05).
- The precise indentation/wrapping of the multi-line `detail` block in `render/1` (D-10).
- Whether to take the optional `check_release_version_truth.exs` 2→3 sweep (D-15) — take it only if
  it stays a clearly separable commit.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone decision set
- `.planning/research/v23/SUMMARY.md` — adjudicated decision set and build order. **Divergence #2's
  causal chain is superseded by the `<verified_ground_truth>` section above.** Its locked rules 1-3
  remain in force as refined by D-06/D-07. Divergence #4 (no wholesale required-check rename) is
  partially superseded by D-18/D-19: the rename-risk premise and the "3 duplicates" count are both
  empirically false.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — MSG-01, MSG-02, MSG-03, MSG-06,
  FID-02 are this phase's requirements.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` §"Phase 169: Diagnostic Legibility" —
  goal and the four success criteria. Note SC #2's "after the last observed failure" phrasing and
  SC #3's "three duplicate names" are corrected by D-03 and D-19.
- `.planning/research/v23/PITFALLS.md` — the vacuous-assertion taxonomy in six named shapes; every
  new check this phase adds must be checked against it.
- `.planning/research/v23/DX.md` — proposed before/after message shapes; source of the
  `release: <subsystem> <role>` naming prefix.

### Code under change
- `lib/crosswake/release_status.ex` — `scanner_check/7` (`:796`), `scanner_ids_result/2`
  (`:819-862`), `workflow_integrity_evidence/1` (`:894-916`), `parse_workflow_integrity_output/1`
  (`:919-934`), `aggregate_status/1` (`:862`), `exit_code/1` (`:872-875`), `render/1` (`:136-150`),
  `@schema_version` (`:9`), required-ID module attributes (`:20-80`).
- `script/check_release_workflow_integrity.exs` — `run/2` setup (`:29-81`), eager check list
  (`:83-160`), print loop (`:164-167`), `System.halt/1` (`:169-177`), `release_version_weld/2`
  (`:274`), `path_from_env/2` (`:184`).
- `lib/mix/tasks/crosswake.release.status.ex:49-51` — exit-code call site.
- `.github/workflows/release-please.yml` — `:13-17` triggers, `:30`, `:719`, `:761`, `:767`, `:829`.
- `script/list_merge_blocking_checks.py` — duplicate scan and authority diagnostics.
- `script/check_required_checks_registered.sh` — `:14`, `:51-52`; uniqueness assertion lands here.
- `script/required_check_policy.json` — the single `Crosswake CI` target context. Must remain
  untouched; its `source_digest` is the proof no protected string moved.

### Exit-code precedent (ratify, do not rewrite)
- `script/verify_generated_ios_shell.sh` — `:44,149,168,186` (`unavailable`, exit 3);
  `:115,161,193,198,217,223,229,235` (`blocked`, exit 2).
- `test/crosswake/proof/phase135_ci_ops_proof_test.exs:526-533` — locks `exit 3` as "NOT a pass".
- `lib/mix/tasks/crosswake.demo.ex:25` — documents the `exit({:shutdown, status})` idiom.
- `lib/mix/tasks/crosswake.shell.status.ex:19-27,121` — adopter-facing exit table; out of scope.
- `docs/COMPANION-PUBLISH-RUNBOOK.md:216` — `BLOCKED | 2 | Published truth could not be established`.

### Tests that constrain the change
- `test/crosswake/proof/phase142_release_integrity_test.exs` — 7 assertions of the form
  `output =~ "[crosswake] OK: #{id}"`; the D-02 protocol must keep these green.
- `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` — same shape.
- `test/mix/tasks/crosswake_release_status_test.exs:160,241-243,426,458,479` — existing exit-code and
  render assertions; D-11 renumbers none of them.
- `test/crosswake/proof_lane/ios_verifier_test.exs:162,195,213,262` — locks the 2-vs-3 split.

### Voice
- `brandbook/BRAND-SPEC.md` — governs microcopy voice (calm, specific, actionable; no drama) and
  §146 naming system. **Supersedes `prompts/crosswake-brand-book.md`** — do not use the stale copy.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `maybe_put/3` (`release_status.ex:938`) — already handles the nil/empty case, so additive check
  fields (`cause:`) need no new plumbing.
- `path_from_env/2` (`check_release_workflow_integrity.exs:184`) — every scanner input is already
  env-overridable (`RELEASE_PLEASE_MANIFEST_PATH`, `GUARDED_HEX_PUBLISH_PATH`, and 10 more). This is
  the fixture mechanism for BOTH acceptance tests: point the manifest at a drifted copy to get a
  real FAIL, point a required path at a missing file to get a real crash. No mocking needed.
- `script/list_merge_blocking_checks.py --producers` — already inventories all 103 producers; the
  global duplicate scan is a widening of an existing traversal, not a new one.
- The `[crosswake] …` + "What to do next:" output style is already established across the shell
  verifiers — D-17's microcopy extends it rather than inventing a house style.

### Established Patterns
- Two-clause `scanner_ids_result/2` dispatching on `%{status: :failed}` vs the catch-all — the new
  owner check should extend this shape, not replace it.
- `exit_code/1`'s catch-all `def exit_code(_status), do: 0` is a live fail-open hazard for any new
  status atom. D-13 is what makes `:unverifiable` safe; treat the pairing as non-negotiable.
- `:missing` vs `:unavailable` doctrine is already written and documented at `release_status.ex:605`
  and `:1067-1075` — "answered no" vs "did not answer". The new never-ran/never-defined split must
  route consistently with it: never-ran and didn't-start → unverifiable/unavailable;
  never-defined and failing → `:error`.

### Integration Points
- `.github/workflows/crosswake-ci.yml:157` and `:89-91` invoke the scanner and pipe its stdout —
  this is why D-14 requires `System.stop` over `System.halt`.
- `mix crosswake.release.status` is invoked by NO workflow (only by its test file), so the FID-02
  exit-code change has a blast radius of tests + humans + one runbook row.
- No workflow branches on a specific numeric exit code; every `continue-on-error: true` is an
  advisory proof workflow and every `|| true` is cleanup/kill/rev-parse. `if: failure()`
  (`crosswake-ci.yml:1371`) fires on any nonzero, so exit 3 still trips it.

</code_context>

<specifics>
## Specific Ideas

- The maintainer explicitly asked for a single coherent recommendation set rather than sequential
  per-area questions, and for microcopy to be treated as a first-class deliverable. D-03, D-17 and
  D-22 carry literal target strings for that reason — the planner should treat them as acceptance
  fixtures, not illustrations.
- TAP's `1..N` plan line is the named precedent for D-02's ROSTER. pytest's "errors during
  collection" (a separate category from failures) and `mix test`'s `invalid` count on an aborted
  `setup_all` are the named precedents for the never-ran/never-defined split.
- grep's documented footgun is the phase's own thesis in miniature: `if ! grep -q …` scores an
  unreadable file (exit 2) identically to no-match (exit 1) — absence scored as success, verbatim.
  Copy the distinction; do not copy pytest's five codes or curl's ninety.
- Compiler-diagnostic practice (Mix aborting after a dependency's compile error rather than emitting
  N downstream errors; rustc's root error + `note:` chaining; TypeScript's cascading-error
  suppression) is the model for D-06/D-07. Their shared footgun to avoid: suppressing a cascade so
  thoroughly the dependent unit looks clean — which is why D-08 keeps crash-case dependents loudly
  non-passing.
- Rejected: switching the scanner to `--format=json` (Credo/Sobelow-idiomatic) — it breaks the
  regex contract and all seven `phase142` assertions for no diagnostic gain.

</specifics>

<deferred>
## Deferred Ideas

- **Streaming scanner emission** — rejected for this phase per D-01, but the ROSTER/DONE contract is
  deliberately forward-compatible with it. Revisit only if checks ever become expensive enough that
  partial progress has standalone value; the full scan is currently sub-second and pure file reads.
- **Widening the status vocabulary beyond `:unverifiable`** (e.g. `:blocked`, `:partial` as check
  statuses) — a separate, deliberate change needing its own fail-closed audit of every catch-all.
  Not this phase.
- **Roadmap/REQUIREMENTS wording corrections** — the maintainer chose to lock the decisions without
  opening a roadmap edit. The corrections are recorded in `<verified_ground_truth>`, D-03 and D-19
  so the planner implements the true state; whether to amend ROADMAP.md SC #2/#3 and MSG-06's text
  is a separate call.
- **`check_release_version_truth.exs` BLOCKED 2→3 sweep** — optional and clearly separable per D-15.
- **Consolidating the legacy and matrix clean-room paths** — explicitly forbidden in v23.0 by
  SUMMARY.md divergence #1; seeded for the milestone after v23.0.

</deferred>

---

*Phase: 169-diagnostic-legibility*
*Context gathered: 2026-09-15*
