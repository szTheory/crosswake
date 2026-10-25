# Phase 170: Vacuous Assertion Remediation - Pattern Map

**Mapped:** 2026-09-16
**Files analyzed:** 9 new/net-new file groups (1 script, 1 snapshot, 2 new proof tests, 7 existing
test files receiving empty-input regressions, ~42 test files receiving one-line guard insertions,
1 VERIFICATION.md template convention + 1 retroactive addendum)
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `script/inventory_collection_assertions.exs` | utility (tree scanner/CLI) | batch (file walk → stdout report) | `script/check_absence_is_not_success.exs` | exact |
| committed snapshot (`script/inventory_collection_assertions.snapshot.exs` or `.json`, Claude's discretion) | config/fixture (roster data) | transform (regenerate → diff) | `@roster_ids` module attribute in `script/check_release_workflow_integrity.exs` | role-match |
| ledger-completeness ExUnit test | test | request-response (regenerate, assert equal) | `phase169_diagnostic_legibility_test.exs` describe block "Task 3: release.scanner.roster_exact" (lines 553-583) | exact |
| itemized closed-world structural test | test | batch (enumerate fixed list, assert per-entry) | `test/crosswake/proof/phase169_check_name_uniqueness_test.exs` (pure-predicate-extraction pattern, lines 220-260) | exact |
| empty-input regression tests (7 existing files) | test | request-response | each file's own existing nearby test (see per-file sections) | exact (same file, same idiom) |
| one-line `refute Enum.empty?` guard insertions (~42 files) | test | request-response | `test/crosswake/doctor/doctor_test.exs:725-735`, `test/crosswake/support_matrix/support_matrix_test.exs:183-192`, `test/crosswake/release_candidate/mirror_test.exs:142-144` | exact |
| `vacuity_taxonomy` VERIFICATION.md section + Phase 169 addendum | config (planning artifact) | transform (template convention) | `.planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-VERIFICATION.md` frontmatter (`covered_files`/`deferred`/`overrides_applied`) | exact |

## Pattern Assignments

### `script/inventory_collection_assertions.exs` (utility, batch)

**Analog:** `script/check_absence_is_not_success.exs` (git-tracked, confirmed via `git ls-files`)

**Module/CLI shape** (lines 1-30, header comment + `defmodule Crosswake.AbsenceIsNotSuccess do` /
`@moduledoc false`): a standalone `#!/usr/bin/env elixir` script, one `defmodule` wrapping the whole
scanner, a top-of-file narrative comment explaining WHY the check exists (what defect class, what
real incident), then two `@..._hint` module attributes holding multi-paragraph heredocs that are
printed alongside any failure — this is the DX convention to reuse for the inventory script's own
explanatory hints (e.g. why `safe-cardinality-pinned` exists, why keys are content-hashed not
line-numbered).

**Tree-walk pattern** (lines 79-88, `mutation_controls/1`):
```elixir
defp mutation_controls(root) do
  root
  |> Path.join("test/**/*.exs")
  |> Path.wildcard()
  |> Enum.sort()
  |> Enum.flat_map(&mutation_findings(&1, root))
end
```
`Path.wildcard/1` + `Enum.sort/1` (deterministic ordering — load-bearing for D-05's content-hash
approach: sorted, stable iteration keeps diffs legible) + `Enum.flat_map/2` per file is the exact
shape to reuse for walking `test/**/*.exs` and emitting one row per matched `assert
Enum.all?/refute Enum.any?` call site.

**Source-parsing approach** (lines 90-96, `mutation_findings/1` calls `strip_heredocs/1` then
`function_blocks/1`): this repo's scanners do NOT use `Code.string_to_quoted` / real AST — they use
regex-over-source-text with explicit heredoc-stripping to avoid matching fixture strings. Two
concrete helpers to imitate:
- `strip_heredocs/1` (lines 105-118): replaces heredoc bodies with blank lines, preserving line
  numbers, so the scanner does not report matches from `"""..."""`-quoted fixture code.
- `function_blocks/1` (lines 121-146): splits source into `{kind, name, body}` chunks bounded by
  `def`/`defp`/`test`/`describe`/`property` regexes — the same crude-but-sufficient boundary
  detection the inventory script needs to find the `describe`/`test` name enclosing each assertion
  (needed for D-05's `{enclosing describe/test name, normalized assertion expression}` hash key).

**Detection regex idiom** (lines 178-182, `builds_mutation?/1` / `asserts_change?/1`): simple
`Regex.match?(~r/.../, body)` predicates, composed with `Enum.filter`/`Enum.reject` pipelines —
reuse this shape for `assert Enum\.all\?`, `assert Enum\.any\?`, `refute Enum\.any\?`,
`refute Enum\.all\?` detection plus the guard-window scan (6-line lookback for
`refute Enum\.empty\?` / `assert \[_ \| _\]`) and the `safe-cardinality-pinned` detector (a
preceding `assert Enum.map(...) == [...]` literal).

**Output / exit-code style** (lines 55-72, `run/2`):
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
Reuse this `[crosswake] OK:` / `[crosswake] FAIL: <id>` / `where:` / `what:` shape verbatim for the
inventory script's own run output (it is a scanner, so it should also speak this house dialect even
though — per D-13 — it is never wired into `check_absence_is_not_success.exs` or a required-check
registry). Note `run/2` takes `root` as an argument (not hardcoded `File.cwd!()`), which is what lets
`phase169_diagnostic_legibility_test.exs`-style tests point the scanner at a `@tag :tmp_dir` fixture
— mirror this for the inventory script so the ledger-completeness test and the structural test can
run it against a synthetic fixture tree, not only the live repo.

**Relative-path helper** — grep `relative(path, root)` in the same file for the exact
`Path.relative_to/2`-based helper used to print portable `file:line` display strings (needed for
D-05's human-readable but non-key `file:line` field).

---

### Committed snapshot file (config/fixture, Claude's discretion on serialization)

**Analog:** `@roster_ids` in `script/check_release_workflow_integrity.exs` (git-tracked) — NOT a
literal precedent for file *format* (that's a module attribute, not a standalone file), but the
precedent for what a "declared roster" looks like in this codebase and how it is compared:

```elixir
# script/check_release_workflow_integrity.exs lines 418-446
defp roster_exact(checks) do
  emitted_ids =
    checks
    |> Enum.map(fn {_status, id, _detail} -> id end)
    |> MapSet.new()
    |> MapSet.put("release.scanner.roster_exact")

  declared_ids = MapSet.new(@roster_ids)

  extra_emitted = emitted_ids |> MapSet.difference(declared_ids) |> Enum.sort()
  missing_emitted = declared_ids |> MapSet.difference(emitted_ids) |> Enum.sort()

  detail =
    if extra_emitted == [] and missing_emitted == [] do
      "emitted #{MapSet.size(emitted_ids)} check IDs match the declared @roster_ids exactly"
    else
      [
        if(extra_emitted != [], do: "emitted but not declared in @roster_ids: #{Enum.join(extra_emitted, ", ")}"),
        if(missing_emitted != [], do: "declared in @roster_ids but never emitted: #{Enum.join(missing_emitted, ", ")}")
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("; ")
    end

  check("release.scanner.roster_exact", extra_emitted == [] and missing_emitted == [], detail)
end
```
This is the exact `MapSet.difference` "extra vs. missing, both directions, both named in the
failure message" shape D-06's ledger-completeness assertion must mirror one level down (call sites
instead of check IDs): "N site(s) not yet classified" (missing from snapshot) and "N orphan row(s)"
(in snapshot, not in tree) — the message template already sketched in CONTEXT.md's
`code_context`/Reusable Assets section, e.g.
`[crosswake] FAIL: the committed classification snapshot has 1 site not yet classified and 0 orphan rows.`

Since no standalone committed-snapshot *file* (as opposed to an in-source `@roster_ids` attribute)
exists anywhere in this repo today, Claude's discretion on serialization is unconstrained by
precedent beyond: (a) it must diff legibly (a sorted, one-row-per-line or one-object-per-line
format, not a single minified blob — this repo's `script/required_check_policy.json` — see
`test/crosswake/proof/phase169_check_name_uniqueness_test.exs` lines ~250-260 — is the nearest
"committed JSON config the tests read back with `Jason.decode!`" precedent if JSON is chosen), and
(b) it must be readable without re-deriving classifications (a plain `Jason.decode!(File.read!(...))`
or `Code.eval_file/1` round-trip, matching how `script/required_check_policy.json` is consumed in
that same test file).

---

### Ledger-completeness ExUnit test (test, request-response)

**Analog:** `test/crosswake/proof/phase169_diagnostic_legibility_test.exs`, describe block
"Task 3: release.scanner.roster_exact — self-checking roster, proven non-vacuous" (lines 553-583)

```elixir
describe "Task 3: release.scanner.roster_exact — self-checking roster, proven non-vacuous" do
  test "a clean run emits [crosswake] OK: release.scanner.roster_exact" do
    {output, exit_code} = run_scanner()

    assert exit_code == 0, output
    assert output =~ ~r/^\[crosswake\] OK: release\.scanner\.roster_exact - /m
  end

  test "removing one ID token from @roster_ids turns the scanner red at release.scanner.roster_exact (non-vacuity proof)" do
    source = File.read!(@scanner)
    mutated = mutate_roster_remove_id(source, "release.concurrency.not_cancelled")

    path = Path.join(System.tmp_dir!(), "crosswake-phase169-roster-mutation-#{System.unique_integer([:positive])}.exs")
    File.write!(path, mutated)
    on_exit(fn -> File.rm(path) end)

    {output, exit_code} = System.cmd("elixir", [path], stderr_to_stdout: true)

    assert exit_code != 0,
           "expected a drifted @roster_ids to make the scanner exit non-zero:\n#{output}"

    assert output =~ "[crosswake] FAIL: release.scanner.roster_exact"
  end
end
```
This is the file to mirror wholesale for the phase-170 ledger test: (1) a "clean run against the
committed snapshot passes" test, and (2) a mutation/non-vacuity test that deliberately desyncs the
snapshot from the live tree (e.g. temp-copy the inventory script + a synthetic extra test file, or
strip one row from a temp copy of the snapshot) and asserts the ledger test would itself fail —
satisfying D-14's requirement to prove the new tests are not themselves vacuous. Note the technique
used for the mutation: write a *mutated copy* of the source/data to a `System.tmp_dir!()` path and
`System.cmd("elixir", [path])` it as a real OS subprocess, rather than trying to mutate the running
scanner in-process — this sidesteps macro/compile-time binding entirely and is proven idiom here.

**Home location:** `test/crosswake/proof/` is confirmed as the corpus location by the whole
`phaseNN_*_test.exs` naming family; name the new file
`test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` (or split ledger-completeness and
the structural test into two files — Claude's discretion per CONTEXT.md).

---

### Itemized closed-world structural test (test, batch)

**Analog:** `test/crosswake/proof/phase169_check_name_uniqueness_test.exs`, the
"pure predicate extracted from the real check, then proven capable of failing against a synthetic
fixture" pattern (lines 220-260, `on_trigger_clean?/1` + the two paired tests):

```elixir
# Extracted as pure predicates (rather than inline asserts against the live file) so a
# synthetic violating fixture can prove each guard is capable of going red (D-23 non-vacuity)
# instead of resting on "it currently passes against a currently-clean file."
defp on_trigger_clean?(triggers) do
  is_map(triggers) and Enum.sort(Map.keys(triggers)) == ["push", "workflow_dispatch"]
end
...
test "Task 3: release-please.yml's on: mapping has exactly push and workflow_dispatch keys" do
  triggers = workflow_json!(".github/workflows/release-please.yml", "doc.get('on', doc.get(True, {}))")
  assert on_trigger_clean?(triggers)
  refute Map.has_key?(triggers, "pull_request")
end

test "Task 3: on:-trigger guard fires on a synthetic trigger set with pull_request added" do
  # Non-vacuity proof: the real file cannot be safely mutated by this test (it is live CI
  # config asserted elsewhere), so this proves the PREDICATE the real-file test relies on is
  # capable of going false, not just currently true.
  refute on_trigger_clean?(%{"push" => %{}, "workflow_dispatch" => nil, "pull_request" => %{}})
end
```
Mirror this per `needs-fix` entry: read the real file at its `file:line` (or re-derive by re-running
the inventory script's own source-reading helper), assert the `refute Enum.empty?(...)` guard line
is present, AND assert (by string/AST comparison) that its argument expression textually matches
the collection expression the flagged assertion consumes — CONTEXT.md D-12.1's "argument expression
matches the assertion's argument expression" requirement. Since this repo's own scanners do source-
regex rather than real AST (see `script/check_absence_is_not_success.exs`'s `function_blocks/1`
above), the simplest match to the existing idiom is: extract both lines via regex capture group
(the expression between `refute Enum.empty?(` / `assert Enum.all?(` and its closing paren/comma),
normalize whitespace, and compare as strings — this is D-05's own normalization requirement reused
here rather than invented fresh. If a real parse is preferred, `Code.string_to_quoted!/1` on each
extracted line is available (stdlib, no new dependency) but no existing script in this repo uses it
— note this as the one place the inventory work would introduce a new technique, if chosen.

**Population source:** the test's fixed `needs-fix` list must come from the committed snapshot
file's own residual rows (Bucket `needs-fix` per D-07), read back exactly as the ledger-completeness
test reads it — do not hand-type a second copy of the list inside this test module, or the two tests
can silently disagree about what the fixed population is (the same anti-duplication argument as
D-18's "link, never copy").

---

### Empty-input regression tests (7 existing files)

**Analog for each: the file's own existing adjacent test**, since these are insertions/additions
into files whose current input-construction idiom the planner must match, not a foreign pattern.

- **`test/crosswake/doctor/doctor_test.exs`** — flagged site at line ~731
  (`assert Enum.all?(report.findings |> Enum.filter(&String.starts_with?(&1.code, "commerce.corridor."))...)`,
  inside test starting line 745, `Doctor.run(route_source: CommerceCorridorRouter, ...)`). Sibling
  test at line 541, `"commerce_summary returns the not_applicable freshness baseline when no
  commerce routes exist"`, already exists as a real "no commerce routes" case — confirm this file
  already has a router fixture with zero commerce routes (grep for a plain, non-commerce
  `route_source` module in the same file, e.g. `PurchaseCorridorRouter`/similar without commerce
  declarations) and reuse it directly rather than fabricating a new router module. `Doctor.run/1`
  takes `route_source:`, `install_manifest_path:`, `cwd:` keyword options (see lines 705-711) — the
  empty-input case is "call `Doctor.run/1` with a route source that declares zero
  `commerce.corridor.*`-prefixed routes" and assert `refute Enum.empty?(...)` now fails loudly
  instead of the filtered list silently being `[]` and `Enum.all?([], _)` vacuously passing.

- **`test/crosswake/support_matrix/support_matrix_test.exs`** — flagged site at line ~187
  (`assert Enum.all?(Enum.filter(matrix.release_boundaries, &(&1.target in ["ios_shell",
  "android_shell"])), &String.contains?(&1.versioning, "lockstep"))`, inside test starting
  line ~172). `SupportMatrix.canonical()` (line ~164, ~176) returns a fixed, hardcoded matrix — there
  is no natural "empty" input to construct without stubbing `SupportMatrix.canonical/0` itself
  (module-level data, closer to `safe-compile-time-literal` in spirit but reachable via filter, so
  it stays in the runtime-derived risk tier per D-12.2's explicit site list). The regression test
  should filter on a target string that matches zero release-boundary entries
  (`&(&1.target in ["nonexistent_target"])`) to force the empty case without needing a second
  `SupportMatrix` implementation.

- **`test/crosswake/guides/evidence_manifest_test.exs`** — flagged sites at lines 110-118
  (`assert Enum.all?(manifest_values(manifest, "proof_class"), &(&1 in @allowed_proof_classes))`
  etc., inside test starting line 106, `"allowed labels are literal capability-map and
  proof-posture vocabulary"`). `manifest = read_manifest!(@example_manifest)` (a real committed
  fixture file) is the current input-construction idiom — see `@example_manifest` module attribute
  near the top of the file and `read_manifest!/1`'s definition (`File.read!` + `Jason.decode!` or
  similar). Forcing an empty case means calling `manifest_values/2` with a manifest object built
  in-test (a literal map with an empty `"routes"`/relevant key) rather than reading the fixture file,
  since the real fixture is guaranteed non-empty by its own "synthetic regressions reject missing
  D-08 root and route fields" sibling test at line 125.

- **`test/crosswake/guides/release_boundaries_test.exs`** — flagged site at line ~101
  (`assert Enum.all?(companions, &(&1.relationship == "independent"))`, inside test
  `"read-only release status projects the exact candidate boundary"` starting line ~80).
  `Crosswake.ReleaseStatus.build()` (line 81) is a real call against the live release-status
  computation, not an injectable fixture — forcing `companions` to `[]` likely requires either a
  test-only `build/1` variant accepting overrides (check whether `Crosswake.ReleaseStatus.build/1`
  already accepts keyword overrides elsewhere in this test file before assuming one must be added;
  this phase does NOT change `lib/` per the phase boundary, so if no override hook exists, this site
  may only be reachable via the structural test, not a genuine empty-input regression — flag this to
  the planner as a possible scope note).

- **`test/mix/tasks/crosswake_release_status_test.exs`**, **`test/crosswake/release_candidate/
  coordinate_test.exs`**, **`test/crosswake/release_candidate/mirror_test.exs`** — the release-graph
  `refute Enum.any?` sites (see Shared Patterns → Release-graph `refute Enum.any?` below for verbatim
  excerpts). Each already constructs its subject via a real `Coordinate`/`Mirror`/`ReleaseStatus`
  computation against fixture manifests already present in the same test file (e.g.
  `coordinate_test.exs`'s `@candidate`/`@companions` module attributes feeding
  `Coordinate.something(...)`) — mirror that fixture-construction idiom, driving toward a genuinely
  empty companion/argument list rather than fabricating a bypass.

---

### One-line `refute Enum.empty?` guard insertions (~42 files, needs-fix subset)

**Representative call sites** (verbatim, to show the exact insertion shape — insert
`refute Enum.empty?(<same collection expression>)` immediately before each, per D-09):

`test/crosswake/doctor/doctor_test.exs:725-735`:
```elixir
    assert Enum.all?(
             report.findings
             |> Enum.filter(&String.starts_with?(&1.code, "commerce.corridor.")),
             fn finding -> Map.has_key?(finding.details, :proof_class) end
           )
```
→ insert `refute Enum.empty?(report.findings |> Enum.filter(&String.starts_with?(&1.code, "commerce.corridor.")))` on the line above.

`test/crosswake/support_matrix/support_matrix_test.exs:187-192`:
```elixir
    assert Enum.all?(
             Enum.filter(
               matrix.release_boundaries,
               &(&1.target in ["ios_shell", "android_shell"])
             ),
             &String.contains?(&1.versioning, "lockstep")
           )
```
→ insert `refute Enum.empty?(Enum.filter(matrix.release_boundaries, &(&1.target in ["ios_shell", "android_shell"])))` above.

`test/crosswake/release_candidate/mirror_test.exs:142`:
```elixir
    refute Enum.any?(result.push_arguments, &String.contains?(&1, "force"))
```
→ (this is the `refute Enum.any?` shape, D-01's 47 unflagged-but-identical population) insert
`refute Enum.empty?(result.push_arguments)` above.

**Safe-by-classification sites that get NO insertion** (D-11) — confirm before touching:
`test/crosswake/guides/native_evidence_drift_test.exs:29`
(`assert Enum.all?(@scanned_paths, &File.exists?/1)` — module-attribute list literal, `safe-by-construction`/`safe-compile-time-literal`, leave untouched).

---

### `vacuity_taxonomy` VERIFICATION.md section + Phase 169 addendum

**Analog:** `.planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/
169-VERIFICATION.md` (git-tracked), whose frontmatter already establishes the contract D-15 extends:

```yaml
---
phase: 169-diagnostic-legibility
verified: 2026-09-16T16:10:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - ...
covered_digest: "v1:sha256:..."
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "REQUIREMENTS.md header names the active v23.0 milestone"
    addressed_in: "unscheduled (project-state bookkeeping, not a phase)"
    evidence: "..."
---
```
The `deferred:` list-of-objects shape (`truth:` / `addressed_in:` / `evidence:`) is the closest
existing precedent for a structured, per-item frontmatter field — model the new `vacuity_taxonomy:`
frontmatter field the same way: a list of objects, one per new check the phase landed, each carrying
`check_id:`, `shape:` (one of A-F or an explicit "matches none, because ___" per D-15), and
`non_vacuity_evidence:` (a measured fact, per D-15's "never a bare yes/no tick" and D-14's
precedent). No standalone `VERIFICATION-TEMPLATE.md` file exists in this repository (the verifier is
plugin/skill-driven, not a checked-in template); this instance file IS the closest analog and the
one the planner should read in full when writing the convention change.

**Body-section precedent for a null-statement pattern** (D-16's "ROSTER/DONE" requirement — a phase
that landed no new checks must say so explicitly): mirror `169-VERIFICATION.md`'s "Human
Verification Required" section, which states `None.` plus one sentence of justification rather than
omitting the section — the same explicit-null convention D-16 asks for in the new
`vacuity_taxonomy` section.

**Retroactive Phase 169 addendum home:** `deferred-items.md` in the same phase directory
(`.planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/deferred-items.md`,
git-tracked) is the existing precedent for a small, scoped, after-the-fact record living beside an
already-closed phase's artifacts without editing the closed VERIFICATION.md itself — its shape
(`# Deferred Items` heading, one bullet per item, `status:`/narrative fields) is the nearest existing
convention for "a scoped addendum file that does not touch the closed artifact," satisfying D-19.
Per CONTEXT.md's Claude's Discretion, whether the Phase 169 `vacuity_taxonomy` addendum is its own
new file in that same directory or a section appended to a Phase 170 artifact is left open — but if
a new file is chosen, name and format it after `deferred-items.md`, not as a free-form note.

## Shared Patterns

### `[crosswake] OK:` / `[crosswake] FAIL: <id>` / `where:` / `what:` output style
**Source:** `script/check_absence_is_not_success.exs` lines 55-72
**Apply to:** `script/inventory_collection_assertions.exs`'s own run output, and the ledger-
completeness test's failure messages (per the CONTEXT.md-specified example message format).

### Regenerate-and-assert-exact-equality (roster_exact)
**Source:** `script/check_release_workflow_integrity.exs` lines 418-446 (`roster_exact/1`) and its
proof in `test/crosswake/proof/phase169_diagnostic_legibility_test.exs` lines 553-583.
**Apply to:** the ledger-completeness test (D-04/D-06) — same `MapSet.difference` both-directions
comparison, one level down (call sites instead of check IDs).

### Pure-predicate-extraction + paired synthetic-fixture non-vacuity proof
**Source:** `test/crosswake/proof/phase169_check_name_uniqueness_test.exs` lines 220-260
(`on_trigger_clean?/1` plus its two paired tests).
**Apply to:** the itemized structural test (D-12.1) and any predicate the inventory script's
classifier reuses for guard-window detection.

### Source-regex-over-heredoc-stripped-text (not real AST)
**Source:** `script/check_absence_is_not_success.exs` lines 105-146 (`strip_heredocs/1`,
`function_blocks/1`).
**Apply to:** `script/inventory_collection_assertions.exs`'s detection core — this is the
established idiom in this repo for scanning `.exs` source text; deviating to real `Code.
string_to_quoted` parsing would be a novel technique with no precedent (acceptable if Claude judges
it materially safer for D-12.1's expression-matching, but call it out as new).

### Explicit "there was nothing" over omission
**Source:** `169-VERIFICATION.md`'s "Human Verification Required" section body (`None.` + one
justifying sentence) and D-16's ROSTER/DONE argument.
**Apply to:** the new `vacuity_taxonomy` VERIFICATION.md section, whenever a covered phase landed no
new checks.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| committed snapshot file's exact serialization format | config/fixture | transform | No standalone committed-snapshot file (as opposed to an in-source `@roster_ids` attribute) exists anywhere in this repo today; nearest partial analog is `script/required_check_policy.json` for "a committed JSON config the test suite reads back with `Jason.decode!`," but its schema (a small fixed policy object) does not resemble a per-site row ledger. Genuinely Claude's discretion per CONTEXT.md. |

## Metadata

**Analog search scope:** `script/*.exs`, `test/crosswake/proof/*.exs`,
`test/crosswake/{doctor,support_matrix,guides,manifest,release_candidate}/*.exs`,
`test/mix/tasks/crosswake_release_status_test.exs`,
`.planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/`
**Files scanned:** ~15 read/grepped in full or by section; ~220 call sites enumerated by grep count
per CONTEXT.md's `<verified_ground_truth>` (not individually re-read here — the inventory script is
the mechanism that will enumerate them exactly).
**Pattern extraction date:** 2026-09-16
**Tracked-source gate:** all analog paths cited above confirmed via `git ls-files` before citing.
