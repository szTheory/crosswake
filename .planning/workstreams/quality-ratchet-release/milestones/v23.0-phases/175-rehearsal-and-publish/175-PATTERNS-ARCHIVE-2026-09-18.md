# Phase 175: Rehearsal and Publish - Pattern Map

**Mapped:** 2026-09-18
**Files analyzed:** 6 groups (2 new docs, 1 modified doc, 1 modified script + new helper, ~10 workflow
files needing SHA-pin edits, 1 new CI-hygiene check + its regression test, plus the `checkpoint:decision`
plan-authoring convention used across all three publish waves)
**Analogs found:** 6 / 6

This is an execution/evidence phase (per RESEARCH.md's Summary): almost nothing here is new
application code. The "files" are docs, one CLI utility, a batch of workflow-file edits, and a small
CI-hygiene check script. Every analog below is drawn from this repo's existing release-tooling and
CI-hygiene conventions — no external pattern needed.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `docs/RELEASE-INCIDENT-RESPONSE.md` (new, REL-10+REL-16) | config/doc (runbook) | request-response (human reads table, picks command) | `docs/COMPANION-PUBLISH-RUNBOOK.md` (structure/voice) + `docs/MILESTONE-BOUNDARY-HYGIENE.md` (table-first runbook shape) | role-match |
| `docs/COMPANION-PUBLISH-RUNBOOK.md` (modify, DOC-04 delete + DOC-06 add) | config/doc | request-response | itself (existing file, edit in place) | exact |
| `scripts/ci_monitor.cjs` `checkActions()` (modify, D-21/D-25/D-27) | utility (CLI subcommand) | batch (scan files → report) | same file's other subcommands, e.g. `validate-evidence`/`render-evidence` for CLI shape; `check_release_workflow_integrity.exs`'s declared-roster pattern for the "derive, don't hardcode" scope fix | exact |
| new `assertFullScope`-style helper in `scripts/ci_monitor.cjs` (D-25) | utility (reusable guard) | transform | `script/check_absence_is_not_success.exs`'s "assert the mutation changed something" checker shape | role-match |
| new version-literal CI check (D-19), e.g. `script/check_release_doc_version_literals.exs` | test/config-validation (CI-hygiene check) | batch (scan docs → pass/fail) | `script/check_release_workflow_integrity.exs` (declared-roster, exit-contract-commented Elixir script scanning release surface) and `script/check_absence_is_not_success.exs` (regex-scan-and-report-findings shape) | exact |
| regression test for the scope-cardinality guard (D-28 item 3) | test | transform | no direct `ci_monitor.cjs` test file exists in-repo (searched, none found) — model on `check_absence_is_not_success.exs`'s own "narrow the glob, assert failure" self-test discipline, or add an inline `test-*` subcommand following `ci_monitor.cjs`'s existing `test-evidence` subcommand convention | role-match |
| ~10 workflow files needing SHA-pin edits (Wave 0, D-21) | config (CI workflow) | event-driven (GitHub Actions trigger) | `.github/workflows/hex-publish.yml` and `.github/actions/setup-elixir-cache/action.yml` — both already fully SHA-pinned with trailing version comments | exact |
| `checkpoint:decision` task blocks inside the phase's own PLAN.md files (D-07 through D-11) — not a repo source file, but the plan-authoring artifact the planner produces | planning template | request-response (human types back a value) | `.planning/workstreams/quality-ratchet-release/milestones/v22.0-phases/168-0-2-1-release-candidate-readiness/168-09-PLAN.md` Task 2 (`gate="blocking-human"`) and `165-11-PLAN.md` Task 1 (`gate="blocking"`) | exact |

## Pattern Assignments

### `docs/RELEASE-INCIDENT-RESPONSE.md` (new doc, REL-10 + REL-16)

**Analog:** `docs/COMPANION-PUBLISH-RUNBOOK.md` (279 lines) for voice/register, `docs/MILESTONE-BOUNDARY-HYGIENE.md` for the "reusable runbook, read-only-first, table/command blocks" shape.

**Opening register pattern** (`docs/COMPANION-PUBLISH-RUNBOOK.md` lines 1-6):
```markdown
# Companion Publish Runbook

This is the operator contract for the Crosswake `0.2.1` release candidate. It keeps the
three linked coordinates together, keeps all five companions independently versioned, and
separates reversible evidence from publication. The status and candidate commands are
read-only: neither command publishes, pushes a ref, merges a pull request, or changes a registry.
```
Copy this register (short declarative "this is the operator contract for X" opening, immediately
followed by a read-only/mutation boundary statement) — but per D-19 the new doc must NOT repeat the
version-literal mistake this exact passage made (`0.2.1` hardcoded as if permanent). State the
"no version-specific claims" invariant instead, at the top, per D-19.

**"STOP" callout pattern for a currently-true-but-version-bound fact** (`docs/COMPANION-PUBLISH-RUNBOOK.md`
lines 29-45) — this is the exact section DOC-04 deletes, and the exact anti-pattern D-19's CI check
exists to prevent recurring: a bolded "STOP —" callout followed by prose naming a bare version. Do
NOT reuse this shape with a literal version in the new document; if a STOP-style callout is needed,
phrase it in terms of state (`approved_version` mismatch) not a version literal.

**Table-first, no-narrative-prose runbook shape** (`docs/MILESTONE-BOUNDARY-HYGIENE.md` lines 1-24):
```markdown
# Milestone-Boundary Hygiene Runbook

A reusable checklist for getting the repo into a clean, coherent state before starting
(or continuing) the next chunk of work — "don't start the next adventure with dirty
underwear on."
...
**This runbook does NOT publish to hex.pm.** Publishing is a separate, deliberate step
...
## 0. Snapshot the state (read-only)

\`\`\`bash
git status -sb                                   # working tree clean? how far ahead of origin?
...
\`\`\`
```
Copy this shape for D-15's structure: a one-line scope-boundary bold statement up top (this doc's
equivalent: the irreversibility summary table), immediately followed by numbered `##` sections each
opening with a fenced command block, no narrative paragraphs between commands. D-16's column set
(`Detect | Decide | Command | Irreversibility`) is new to this repo — no existing table has this exact
shape — so author it directly against D-15/D-16's spec; use `docs/COMPANION-PUBLISH-RUNBOOK.md`'s
"Five states and one correction" section (search that file for `### 1.` style subheadings) as the
nearest existing precedent for enumerating discrete states/rows with one-line cells.

**Retire/backfill semantics to embed (REL-10), sourced directly from RESEARCH.md's Pitfall 4/5 and
D-11's "recovery language must be generated from, or linked to, the REL-16 response table"**:
- Hex: `mix hex.retire PACKAGE VERSION --unretire` reverses retirement; retirement is an advisory flag,
  not a removal (Pitfall 4).
- Maven: immutable once `PUBLISHED`; only `VALIDATED` deployments are droppable — quote
  `release-please.yml` lines ~1156-1157's own comment: `"immutability is scoped to PUBLISHED only;
  VALIDATED deployments are safely droppable"` (Pitfall 5).
- iOS mirror: re-pointing a tag does not un-resolve consumers who already fetched the old commit via
  SwiftPM's resolved-package cache (D-20 — currently documented nowhere in this repo; this is new
  content, not copied from an existing file).

---

### `docs/COMPANION-PUBLISH-RUNBOOK.md` (modify — DOC-04, DOC-06)

**Analog:** itself. This is a direct edit, not a new-file-from-analog case.

**DOC-04 deletion target** (lines 29-45, confirmed still present):
```markdown
## Before releasing any version other than 0.2.1

**STOP — this pipeline currently publishes exactly one version.**

`publish-hex`, `publish-ios-core`, `publish-android-core`, and `exact-public-proof` in
`.github/workflows/release-please.yml` are each gated on
`needs.release-please.outputs.version == '0.2.1'`. For any other version every one of them skips,
so the release **tags and then publishes nothing**. The linked rollup reports `PARTIAL` — correctly,
but only because everything downstream was skipped. Do not read that `PARTIAL` as a transient
failure to retry.

Close `TODO-009` / `SEED-017` before attempting a release of `0.2.2` or later. The fix must
generalize the version **without** generalizing the authority: the per-release exact-identity
binding has to replace the version literal, not disappear with it.

Related: a release completing through exact-ref recovery does not run `exact-public-proof` at all,
because that job `needs:` the ordinary publish jobs. 0.2.1 shipped this way, which is why the
post-publication proof has never executed.
```
Delete this entire `##` section outright per D-17 ("deleted, not softened"). Note the final paragraph
("Related: a release completing through exact-ref recovery...") is a separate, still-true fact about
`exact-public-proof` not running through recovery — verify at delete-time whether that sentence should
be preserved elsewhere in the doc (it is not version-bound) or whether it is now stale too; D-17 only
mandates removing the "STOP" claim itself.

**DOC-06 insertion point:** the file's "Exact seven-step operator sequence" (starting ~line 47) and its
iOS-mirror-specific step (grep `subtree` / `v0.2.1` around line 107: `the recorded 'v0.2.0' baseline and
dry-run the 'v0.2.1' split`) are the two places to add explicit `git subtree split` documentation,
replacing any implicit assumption of `splitsh-lite`. RESEARCH.md confirms zero live references remain
outside one unrelated comment in `script/check_ios_mirror_parity.sh:31` — DOC-06 is purely additive
documentation, not a removal.

**Version-literal-avoidance requirement (D-19) applies to edits here too**: any new prose added by
DOC-06 must not introduce a fresh bare version literal outside a code fence — write the CI check
(below) before or alongside this edit so it catches regressions immediately.

---

### `scripts/ci_monitor.cjs` — `checkActions()` fix (D-21, D-25, D-27)

**Analog:** the file's own existing subcommand shape, plus `check_release_workflow_integrity.exs`'s
"declared roster, never derived from a scan" comment for *why* some things stay hardcoded and others
must not.

**Current hardcoded-default shape to replace** (`scripts/ci_monitor.cjs` lines 269-303):
```javascript
function checkActions(args) {
  const paths = args.length ? args : [
    ".github/workflows/crosswake-ci.yml",
    ".github/actions/setup-android-jvm/action.yml",
    ".github/actions/setup-elixir-cache/action.yml",
  ];
  const lines = paths.flatMap((file) => {
    let source;
    try {
      source = fs.readFileSync(file, "utf8");
    } catch (_error) {
      fail(`could not read required action source: ${file}`);
    }

    return source
      .split("\n")
      .map((line, index) => ({ line, index: index + 1 }))
      .filter(({ line }) => /uses:\s*[^#\s]+/.test(line))
      .map(({ line, index }) => `${file}:${index}:${line}`);
  });
  const mutable = lines.filter((line) => {
    const match = line.match(/uses:\s*([^\s#]+)/);
    if (!match || match[1].startsWith("./") || !match[1].includes("@")) return false;
    const ref = match[1].split("@").pop();
    return !/^[a-f0-9]{40}$/i.test(ref);
  });

  process.stdout.write(lines.join("\n") + (lines.length ? "\n" : ""));
  process.stdout.write(`actions=${lines.length} mutable_refs=${mutable.length}\n`);
  if (mutable.length) {
    process.stderr.write("mutable third-party action refs are forbidden in required CI authority\n");
    process.exitCode = 1;
  }
}
```
Per D-21/D-27, the fix is:
1. Replace the hardcoded 3-path default with a `glob`-derived default: `.github/workflows/*.yml` +
   `.github/actions/**/action.yml` (D-28 item 1 — "derived, never hardcoded"). Node has no built-in
   glob; use `fs.readdirSync`/recursive walk (this file already has no glob dependency — verified no
   `require("glob")` anywhere in the file), consistent with the file's zero-dependency style (only
   `node:child_process`, `node:crypto`, `node:fs`, `node:path` are imported at the top, lines 3-6).
2. Print the scanned-file count in the summary line (D-27): extend
   `process.stdout.write(\`actions=${lines.length} mutable_refs=${mutable.length}\n\`)` to also emit
   `files=${paths.length}`.
3. Extract the mutable-ref cardinality assertion into a small reusable helper (D-25) — e.g.
   `function assertNoMutableRefs(lines, mutable) { ... }` — called by `checkActions()` but written so a
   future check can call it too, mirroring how `script/check_absence_is_not_success.exs` factors its
   two independent checks (`mutation_controls/1`, `stale_citations/1`) as separately callable functions
   composed in `run/1`.

**Command output style to preserve exactly** (do not change the two-line stdout contract —
`gh`/CI-log consumers grep this output):
```
actions=252 mutable_refs=31
```
becomes (after fix):
```
files=27 actions=252 mutable_refs=0
```

---

### New CI check for bare version literals (D-19)

**Analog:** `script/check_release_workflow_integrity.exs` (exit-contract comment, declared-not-derived
scope) and `script/check_absence_is_not_success.exs` (regex-scan-and-report-findings shape, `run/1`
returning an exit code, `IO.puts` formatted findings).

**Exit-contract header convention to copy** (`script/check_release_workflow_integrity.exs` line 1-2):
```elixir
#!/usr/bin/env elixir
# exit contract: 0 clean / 1 defect found / 3 could not verify
```

**Findings-reporting shape to copy** (`script/check_absence_is_not_success.exs` lines 55-71):
```elixir
def run(root) do
  findings = mutation_controls(root) ++ stale_citations(root)

  case findings do
    [] ->
      IO.puts("[crosswake] OK: no mutation control asserts a change it never verified.")
      IO.puts("[crosswake] OK: every open finding's test citation resolves to a real test.")
      0

    _ ->
      Enum.each(findings, fn {id, where, detail, hint} ->
        IO.puts("[crosswake] FAIL: #{id}")
        IO.puts("[crosswake]   where: #{where}")
        IO.puts("[crosswake]   what:  #{detail}")
        IO.puts(indent(hint))
        IO.puts("")
      end)

      IO.puts("[crosswake] FAIL: #{length(findings)} check(s) would pass while asserting nothing.")
      1
  end
end
```
Copy this `run/1` → per-check-function → aggregate-findings → `[crosswake] OK`/`FAIL` shape exactly.
For D-19 the check needs one function, e.g. `bare_version_literals/1`, that:
- Reads `docs/COMPANION-PUBLISH-RUNBOOK.md` and `docs/RELEASE-INCIDENT-RESPONSE.md`.
- Strips fenced code blocks (` ``` ... ``` `) before scanning — the check must skip literals *inside*
  fences (D-19: "outside code fences").
- Regex `/\b0\.\d+\.\d+\b/` against the remaining text; any match is a finding.
- Also assert the "This document makes no version-specific claims" invariant sentence is present at
  the top of both files (D-19's second half) — model this second assertion on
  `check_absence_is_not_success.exs`'s `stale_citations/1` pattern of "grep for an expected marker,
  fail if absent."

**Doc-comment / rationale header convention to copy** (`script/check_absence_is_not_success.exs`
lines 1-19) — a multi-paragraph `#` comment explaining *why* the check exists, citing the specific
past incident (here: DOC-04's own version-literal-as-permanent mistake) before any code:
```elixir
# Guards against one recurring defect class: a check that keeps running, keeps
# reporting success, and has stopped asserting anything.
#
# The v22.0 retrospective found this shape five independent times ...
```

**Regression-test discipline (D-28 item 3, applies equally to the version-literal check per D-19's
"structurally hard rather than a thing to remember" framing):** no dedicated `ci_monitor.cjs` test
file exists in this repo today (confirmed absent). Model the self-test on
`check_absence_is_not_success.exs`'s own module doc, which narrates the *specific* regression each
check was built to catch — write an inline fixture-based assertion (temporarily narrow the glob /
inject a known-bad literal, assert the check fails) rather than adding a parallel ExUnit suite, unless
this phase's Wave 0 task explicitly wants a `test/` file — in which case follow
`test/crosswake/proof/ios_rehearsal_script_test.exs`'s existing script-invocation-test shape (cited in
RESEARCH.md's Wave 0 Gaps section) as the closest existing "test a `script/*` executable via `System.cmd`" analog.

---

### Wave 0: SHA-pin the ~10 workflow files with mutable action refs (D-21, D-24)

**Analog:** `.github/workflows/hex-publish.yml` and `.github/actions/setup-elixir-cache/action.yml` —
both already fully SHA-pinned.

**Pinned-ref convention to copy exactly** (`.github/workflows/hex-publish.yml` lines 247, 261, 267, 322):
```yaml
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
        uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
```
Pattern: `uses: <owner>/<repo>@<40-char-lowercase-sha>` followed by ` # <semver-tag>` trailing comment.
Every pin across all 10 target workflow files must follow this exact `sha # v<version>` comment
convention (already the repo-wide norm — confirmed identical SHAs reused verbatim across
`hex-publish.yml`, `.github/actions/setup-android-jvm/action.yml`, and
`.github/actions/setup-elixir-cache/action.yml` for the same action, e.g. `actions/checkout@9c091bb2...`
and `actions/setup-java@de7274f0...` appear identically in multiple files — reuse the exact SHA already
pinned elsewhere in the repo for the same action+version rather than re-resolving it).

**Dependabot maintenance path already in place** (`.github/dependabot.yml`, full file):
```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```
No changes needed here per D-24 — cite this file as evidence the pin has an update path, do not modify it.

**Verification command to reuse post-fix** (this is literally the tool being fixed, run against itself):
```bash
node scripts/ci_monitor.cjs check-actions
# must report files=<count matching a fresh glob> actions=<N> mutable_refs=0
```

---

### `checkpoint:decision` gates (D-07 through D-11) — plan-authoring convention, not a source file

**Analog:** `.planning/workstreams/quality-ratchet-release/milestones/v22.0-phases/168-0-2-1-release-candidate-readiness/168-09-PLAN.md`
Task 2, and `.../165-efficient-and-maintainable-ci/165-11-PLAN.md` Task 1.

**Full task-block shape to copy** (`168-09-PLAN.md`, the `gate="blocking-human"` variant — closest to
this phase's "operator must type back a value" need):
```xml
<task type="checkpoint:decision" gate="blocking-human">
  <name>Task 2: Authorize closing the duplicate-release proposal PR #158</name>
  <read_first>
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-VERIFICATION.md
  </read_first>
  <action>Re-read PR #158's current head and proposed diff with `gh pr view 158` and `gh pr diff 158`
  immediately before presenting, and re-confirm that protected default now declares `0.2.1`. Present
  the exact PR number, head ref, proposed version tuple, the already-published coordinates it would
  duplicate, and the fact that `refs/tags/hex-v0.2.1` already exists at `b780a198`. Do not close the PR
  in this task and do not merge it under any answer.</action>
  <decision>Close PR #158 unmerged so an already-published `0.2.1` cannot be re-tagged and
  re-published, accepting that the next genuine release is `0.2.2`; or leave it open and stop.</decision>
  <context>... This checkpoint exists because closing an open pull request is an outward-facing act,
  not because the direction is unsettled. ...</context>
  <options>
    <option id="close-158-unmerged">...</option>
    <option id="leave-open">...</option>
  </options>
  <resume-signal>Reply `close 158` to authorize the close, or `leave open` to stop this plan here.</resume-signal>
  <reversibility rating="reversible">A closed GitHub pull request can be reopened, ...</reversibility>
  <done>The maintainer has explicitly authorized or declined the close, with the current PR state and
  the published coordinates in front of them.</done>
</task>
```
Map D-07/D-08/D-09/D-11 onto this exact skeleton for each of the three gates:
- `<action>`: re-fetch that leg's live evidence immediately before presenting (mirrors `gh pr view`/
  `gh pr diff` re-read here) — per D-30/D-33, never present stale evidence.
- `<decision>` / `<resume-signal>`: per D-08, make the typed-back value leg-specific and non-fungible
  (e.g. gate 1's resume-signal demands the Hex candidate-rehearsal run ID; gate 2's demands the iOS
  run ID; gate 3's demands the `exact-public-proof` run ID) — this analog's `close 158` / `leave open`
  pair shows the exact mechanic (a literal string the operator must reproduce), just generalize the
  string to the named field D-08 requires.
- `<reversibility rating="one-way">`: per D-07/D-10, state the leg's own recovery cost in its own terms
  (Hex retire-does-not-remove / Maven VALIDATED-droppable-but-PUBLISHED-permanent / iOS tag
  re-pointable-but-cache-unaffected) — link or quote directly from `docs/RELEASE-INCIDENT-RESPONSE.md`'s
  REL-16 table per D-10, rather than re-deriving the language, exactly as this analog's `<reversibility>`
  is a one-line factual claim about the specific object being mutated.
- Gate weight asymmetry (D-09): compare this analog's terse `168-09` gate (single PR-close decision)
  against `165-11-PLAN.md`'s heavier gate (full removal-set, before/after, unique-producer-proof detail
  in `<action>`) as the model for "gates 1 and 3 stay light, gate 2 carries the full evidence block."

**`<action>`/`<context>` re-verification convention from `165-11-PLAN.md`** (lines ~46-58) — copy this
for gate 2's heavier evidence requirement:
```xml
<action>Re-run the read-only live dual-state audit and validate the proposal source digest immediately
before presenting the decision. Show the exact sorted removal set, retained `Crosswake CI` context,
strict true before/after, unique producer proof, live docs/full/cancellation evidence references, and
exact Plan 12 apply command. Ask the maintainer to choose ... never auto-approve, broaden the removal
set, or substitute a human verification for the already automated assertions per D-10.</action>
```

## Shared Patterns

### No-version-literal invariant (applies to both new/modified docs — D-19)
**Source:** the exact defect at `docs/COMPANION-PUBLISH-RUNBOOK.md` lines 29-45 (deleted by DOC-04).
**Apply to:** `docs/RELEASE-INCIDENT-RESPONSE.md` (new) and `docs/COMPANION-PUBLISH-RUNBOOK.md`
(post-edit). State "This document makes no version-specific claims" at the top of both, enforced by
the new CI check.

### Declared-not-derived scope roster (applies to any new scope-selector logic)
**Source:** `script/check_release_workflow_integrity.exs` `@proof_lanes` comment block:
```elixir
# DECLARED, NEVER DERIVED (SEED-019).
#
# This roster is the scope selector for every per-lane publication-record
# assertion below. It is a literal constant on purpose: a roster computed by
# scanning the workflow files for "jobs that mention the emitter" would shrink
# to exclude the exact lane that stopped emitting a record, and the checks
# would then report green about a set that no longer contains the defect.
```
**Apply to:** the CI-hygiene checks touched in this phase (`checkActions()`'s file-discovery glob is
the one place this phase *intentionally inverts* the rule — the glob must be derived, per D-28 item 1,
precisely because a hardcoded 3-path roster was the defect). Cite this comment when explaining, in
plan prose, why the glob-derivation direction is correct here even though the general repo convention
favors hardcoded rosters elsewhere.

### Absence-scored-as-success reporting shape (applies to the new version-literal check and the
scope-cardinality regression test)
**Source:** `script/check_absence_is_not_success.exs` full `run/1` shape (see excerpt above) — `[]` →
two `OK:` lines + `0`; non-`[]` → per-finding `FAIL:` block + count + `1`.
**Apply to:** every new pass/fail check this phase adds, so failures are visually consistent with the
rest of the repo's CI-hygiene scripts.

### Evidence-not-inspection verification commands (applies to all three publish waves)
**Source:** RESEARCH.md's "Independent registry verification" code block (Hex/iOS/Maven `curl`/`git
ls-remote` commands) — not a repo file, but the concrete commands each publish wave's `<verify>` block
should invoke, per D-30 ("never by re-reading a workflow definition").
**Apply to:** the `<verify>` sections of Wave 2/3/4 publish tasks — use the exact commands from
RESEARCH.md's Code Examples section, not a `gh workflow view`-style inspection.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Regression test proving the scope-cardinality guard fails on a narrowed glob (D-28 item 3) | test | transform | No existing `ci_monitor.cjs` test file in this repo (searched `*ci_monitor*test*` and `*test*ci_monitor*`, zero hits) — nearest precedent is `check_absence_is_not_success.exs`'s narrative self-documentation of the regression it guards against, not a runnable test harness. Planner should decide inline-fixture-in-script vs. new `test/` file; RESEARCH.md's Wave 0 Gaps section explicitly says no new ExUnit suite is required, only real-world evidence, but D-28 item 3 does ask for one deliberate regression exercise. |
| iOS-mirror-cache non-un-resolution fact (D-20) | doc content | — | Genuinely new content; not previously documented anywhere in this repo (confirmed by RESEARCH.md and this pass's own search) — author directly from the SwiftPM resolved-package-cache mechanism, no in-repo precedent to copy phrasing from. |

## Metadata

**Analog search scope:** `docs/`, `scripts/ci_monitor.cjs`, `script/check_*.exs`, `.github/workflows/*.yml`,
`.github/actions/**/action.yml`, `.github/dependabot.yml`, `.planning/workstreams/quality-ratchet-release/milestones/**/*-PLAN.md`
**Files scanned:** `docs/COMPANION-PUBLISH-RUNBOOK.md` (full, 279 lines), `docs/MILESTONE-BOUNDARY-HYGIENE.md`
(partial, read-only-checklist section), `scripts/ci_monitor.cjs` (targeted: header/help block, `checkActions()`,
evidence-schema constants), `script/check_release_workflow_integrity.exs` (header/constants), `script/check_absence_is_not_success.exs`
(full doc-comment + `run/1`), `.github/workflows/hex-publish.yml` + `.github/actions/setup-android-jvm/action.yml`
+ `.github/actions/setup-elixir-cache/action.yml` (grep for pinned `uses:` lines), `.github/dependabot.yml` (full),
two `checkpoint:decision`/`checkpoint:decision gate="blocking-human"` PLAN.md task blocks (168-09, 165-11)
**Pattern extraction date:** 2026-09-18
