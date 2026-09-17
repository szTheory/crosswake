# Phase 171: Version/Authority Split - Pattern Map

**Mapped:** 2026-09-17
**Files analyzed:** 17 (2-3 new ExUnit proof tests count as one row-group; 8 `lib/` modules + 6 scripts
+ 4 workflows from the WELD-01 inventory are edits, not new files, and are folded into their per-file
sections below rather than re-listed as 18 separate top-level rows)
**Analogs found:** 17 / 17 (every file has at least a role-match analog; zero "no analog" rows)

All analog excerpts below were re-read directly this session (not trusted from RESEARCH.md alone) and
line numbers were re-verified against the current tree. Every path listed as an analog passed
`git ls-files` (tracked, non-mirror). No gitignored mirror paths were used anywhere in this document.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/crosswake/proof/phase171_no_bare_version_literal_test.exs` (new) | test (proof/scanner-subprocess) | request-response (subprocess exec + stdout parse) | `test/crosswake/proof/phase168_release_version_weld_test.exs` | exact |
| `test/crosswake/proof/phase171_approved_version_output_test.exs` (new) | test (proof/workflow-structural) | request-response (subprocess exec + stdout parse) | `test/crosswake/proof/phase168_release_version_weld_test.exs` | exact |
| `test/crosswake/proof/phase171_identity_gate_unchanged_test.exs` (new, may fold into the file above) | test (proof/fixture-mutation) | request-response | `test/crosswake/proof/phase168_release_version_weld_test.exs` | exact |
| `script/check_release_workflow_integrity.exs` — new check `release.publish_gate.no_bare_version_literal` + roster edit + tripwire deletion + self-referential assertion updates (lines ~92, 361-397, 1106, 1130, 1244, 1345-1347) | utility (static-analysis CI script) | batch/transform (reads YAML+manifest, emits structured OK/FAIL lines) | same file, `release_version_weld/2` (lines 361-397) being replaced, and `roster_exact/1` (line 418) for the roster-coverage idiom | exact (self-analog: new check copies sibling checks' own shape) |
| `.github/workflows/release-please.yml` — `approved-release-guard` job `outputs:`+guard-step edit (WELD-02), four `if:` gates (WELD-03, lines 223/525/571/728) | route/config (GitHub Actions job) | event-driven (workflow_run/merge trigger → gated job graph) | same file, `approved-release-guard`'s existing `approved_head`/`approved_tree` output+emit idiom (lines 36-44, 60, 142-150) | exact (self-analog) |
| `lib/crosswake/release_candidate/workflow.ex` — `@coordinates` → `coordinates(version)` function (WELD-04) | model/service (pure validation+derivation module) | transform | same file — no separate analog exists; see "No Analog Found" note below | role-match (self-analog only) |
| `lib/crosswake/release_candidate/cleanroom.ex:236` — delete version conjunct (WELD-05) | model (validation module) | transform | same file — the three preceding structural conjuncts in the same `unless` (lines 233-235) are the analog for "what this function's job actually is" | exact (self-analog) |
| `lib/crosswake/release_candidate/identity.ex:71,128` — version-suffix + pattern-match clause fix | model (validation module) | transform | `lib/crosswake/release_candidate/cleanroom.ex`'s `version!/1` normalizer (same family of "format check, not literal-equality check" fix) | role-match |
| `lib/crosswake/release_candidate/coordinate.ex` — 5 `unless X == @candidate` sites | model (validation module) — **caller status UNVERIFIED, see below** | transform | `lib/crosswake/release_candidate/identity.ex` (same package, same shape of literal-equality-to-regex fix) | role-match, contingent on caller-status resolution |
| `lib/crosswake/release_candidate/mirror.ex:245,311` (live gates); `:325,332` (display, self-correcting) | model (validation/mode-dispatch module) | transform | `lib/crosswake/release_candidate/workflow.ex`'s `@coordinates` fix (same "module attribute holding a version literal, consumed at multiple call sites" shape) | role-match |
| `lib/crosswake/release_status.ex` — `@candidate_version` derivation (WELD's registry-probe construction) | service (read-only registry-probe builder) | request-response (constructs external-registry check inputs) | `lib/crosswake/release_candidate/workflow.ex` (nearest sibling module in the same `release_candidate`/`release_status` family reading a version to derive an external-facing string) | role-match |
| `lib/mix/tasks/crosswake.release.candidate.ex:50` — `opts[:version] == "0.2.1"` → regex format check | route (Mix.Task CLI entrypoint) | request-response (CLI arg parse → domain call) | same file's own `@sha_pattern`/`Regex.match?(@sha_pattern, opts[:ref])` check three lines below (line 51) | exact (self-analog: same function, adjacent conjunct already does exactly this shape of check) |
| `lib/crosswake/release_candidate.ex:100` — `validate_command_identity!("0.2.1", ...)` pattern-match clause | service (CLI-entrypoint validator) | request-response | `lib/mix/tasks/crosswake.release.candidate.ex`'s `@sha_pattern` regex-guard idiom (same fix shape, one layer down the call chain) | role-match |
| `script/guarded_hex_publish.sh:140`; `script/release_candidate/android_publication.sh:18,46,60`; `script/release_candidate/ios_mirror.sh:52` | utility (shell publish/recovery script) | file-I/O / CRUD (invokes package-manager publish) | `script/release_candidate/ios_mirror.sh:46` (the `$VERSION`-driven baseline-mode conjunct three lines above the literal one, in the SAME file, is the analog for "how this file already interpolates `$VERSION` correctly elsewhere") | exact (self-analog within `ios_mirror.sh`); role-match for the other two scripts |
| `script/verify_ios_mirror_backfill.sh:6,49` (docstring only — no fix required per research) | utility (shell verification script) | N/A (comment text) | N/A — no code change | N/A (docstring-only, no pattern needed) |
| `.github/workflows/hex-publish.yml:45,192,308` | config (GitHub Actions workflow_dispatch job) | event-driven | `.github/workflows/release-please.yml`'s `approved-release-guard` → `approved_version` output (WELD-02) is the single-producer value this file's comparisons should consume once threaded through, OR at minimum the same literal→derived-value fix shape | role-match |
| `.github/workflows/ios-mirror-backfill.yml:107,147,336,431` (live gates); `:288-293` (UNVERIFIED — fixture vs. live, see Open Question) | config (GitHub Actions workflow_dispatch job) | event-driven | `.github/workflows/release-please.yml`'s four publish-gate `if:` clauses (WELD-03) — nearest sibling "compare against approved_version, not a literal" fix | role-match |
| `.planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-WELD-INVENTORY.md` (new, WELD-01 deliverable — exact filename/location is the planner's call; research calls it "the committed weld-inventory table") | documentation (in-repo tabular ledger) | batch (static table, hand/tool-populated, git-committed) | `.planning/workstreams/quality-ratchet-release/milestones/v22.0-phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md` | exact |

## Pattern Assignments

### `test/crosswake/proof/phase171_no_bare_version_literal_test.exs` (test, request-response)

**Analog:** `test/crosswake/proof/phase168_release_version_weld_test.exs` (full file read this
session; excerpts below are byte-for-byte from the current tracked file).

**Module/attributes/moduledoc pattern** (lines 1-36):
```elixir
defmodule Crosswake.Proof.Phase168ReleaseVersionWeldTest do
  @moduledoc """
  Merge-blocking tripwire for TODO-009 / SEED-017.
  ...
  """

  use ExUnit.Case, async: true

  @scanner "script/check_release_workflow_integrity.exs"
  @workflow ".github/workflows/release-please.yml"
  @manifest ".release-please-manifest.json"
  @check_id "release.version_weld.gates_match_declared_version"

  @gated_jobs ~w(publish-hex publish-ios-core publish-android-core exact-public-proof)
```
For phase 171's new file, rename `@check_id` to
`"release.publish_gate.no_bare_version_literal"` and reuse `@gated_jobs` (rename to
`@version_gated_jobs` to mirror the scanner's own attribute name at
`script/check_release_workflow_integrity.exs:18`).

**Fixture idiom — `tmp_dir!/1`, `manifest_at!/2`, `workflow_copy!/2`** (lines 38-70):
```elixir
defp tmp_dir!(name) do
  dir =
    Path.join(
      System.tmp_dir!(),
      "cw-p168-weld-#{name}-#{System.unique_integer([:positive])}"
    )

  File.mkdir_p!(dir)
  ExUnit.Callbacks.on_exit(fn -> File.rm_rf(dir) end)
  dir
end

defp manifest_at!(dir, version) do
  path = Path.join(dir, "manifest.json")

  body =
    @manifest
    |> File.read!()
    |> JSON.decode!()
    |> Map.put(".", version)
    |> Map.put("packages/crosswake-shell-core-ios", version)
    |> Map.put("packages/crosswake-shell-core-android", version)
    |> JSON.encode!()

  File.write!(path, body)
  path
end

defp workflow_copy!(dir, contents) do
  path = Path.join(dir, "release-please.yml")
  File.write!(path, contents)
  path
end
```
Copy these three verbatim for phase171 — the phase171 file needs the SAME manifest-mutation and
workflow-mutation fixture builders, since MSG-05's pre-repair fixture is a mutated copy of
`release-please.yml`, not the manifest.

**Subprocess-exec pattern — `run/2` with env override** (lines 72-77):
```elixir
defp run(workflow_path, manifest_path) do
  System.cmd("elixir", [@scanner, workflow_path],
    stderr_to_stdout: true,
    env: [{"RELEASE_PLEASE_MANIFEST_PATH", manifest_path}]
  )
end
```
Copy verbatim.

**Stdout line-parsing pattern — `line_for/2`** (lines 79-94, comment included verbatim because it
documents a real hazard that will recur for phase171's own check):
```elixir
# 169-01 added an additive `[crosswake] ROSTER: <count> <comma-joined ids>` line
# that lists every declared check ID, including this test's @check_id — a bare
# String.contains?/2 substring match now finds THAT line first (it prints
# before any OK/FAIL line), not the actual result line for the check. Match the
# real `[crosswake] (OK|FAIL): <id> - ` line shape instead, which is the same
# consumer contract release_status.ex's parser depends on and 169-01/169-02
# guarantee stays byte-identical.
defp line_for(output, id) do
  output
  |> String.split("\n")
  |> Enum.find(&String.contains?(&1, "] OK: #{id} -"))
  |> case do
    nil -> output |> String.split("\n") |> Enum.find(&String.contains?(&1, "] FAIL: #{id} -"))
    line -> line
  end
end
```
Copy verbatim — this is not optional stylistic sugar, it is the correct parsing contract post-169.

**Non-vacuity mutation-control pattern — `mutate_job_version/3` + its own self-check** (lines
200-231): the phase171 test needs the INVERSE direction (prove the NEW check fails on the OLD
literal), so `mutate_job_version/3` should be adapted to write `== '0.2.1'` back into a copy of the
ALREADY-FIXED `release-please.yml` (reconstructing the pre-repair shape), per RESEARCH.md's
"Non-Vacuity Proof Pattern" section. The self-checking "did the mutation actually change anything"
raise-if-identical guard in this function is the load-bearing part to copy — do not drop it:
```elixir
defp mutate_job_version(workflow, job, version) do
  block = job_block(workflow, job)

  unless Regex.match?(~r/outputs\.version\s*==\s*'\d+\.\d+\.\d+'/, block) do
    raise "..."
  end

  mutated =
    Regex.replace(
      ~r/(outputs\.version\s*==\s*')\d+\.\d+\.\d+(')/,
      block,
      "\\g{1}#{version}\\g{2}"
    )

  if mutated == block do
    raise "..."
  end

  String.replace(workflow, block, mutated, global: false)
end
```

**Test structure** (`describe`/`test` blocks, lines 96-187): mirror the three-tier structure —
(1) "the check is silent on the real, fixed repository", (2) "the check fires when a pre-repair
fixture reintroduces the literal", (3) "every one of the four gated jobs is independently covered by
the mutation control, and the roster's job list matches what the workflow actually gates on".

---

### `test/crosswake/proof/phase171_approved_version_output_test.exs` (test, request-response)

**Analog:** same file, `test/crosswake/proof/phase168_release_version_weld_test.exs` — reuse
`tmp_dir!/1` and a new fixture builder analogous to `manifest_at!/2` that also emits a fake
`GITHUB_OUTPUT` file, since this test asserts the `approved-release-guard` job's shell block computes
`approved_version` from the manifest (see RESEARCH.md's WELD-02 section for the exact
`manifest_version=$(jq -er '."."' .release-please-manifest.json)` shell to assert against). This is a
structural/text assertion over the job's YAML block (via `job_block`/`job_if`-style regex extraction,
same idiom as the scanner script itself), not a live GitHub Actions run.

**WELD-08 regression pattern (identity gate stays exact):** mutate ONLY the manifest version in a
copy while holding the guard's head/tree/base assertions fixed, and assert the guard step's shell
block still contains every one of its existing identity predicates
(`approved_head="$second_parent"`, the `merge_tree=$(git rev-parse ...)` line, the receipt/CI-run
cross-check jq calls at lines 114-140) — i.e., a `refute`/`assert` pair reading the job block text
before and after, not a live execution.

---

### `script/check_release_workflow_integrity.exs` (utility, batch/transform)

**Analog:** same file. Three areas to copy from within it.

**1. The `check/3` idiom** (lines 408-409):
```elixir
defp check(id, true, detail), do: {:ok, id, detail}
defp check(id, false, detail), do: {:error, id, detail}
```
Every check function in this file returns `check(id, boolean, detail)` as its last expression. The
new check must do the same.

**2. The check-to-be-replaced, `release_version_weld/2`, full body** (lines 343-397) — this is both
the DELETION target (WELD-07) and the shape template for the new check (same helpers: `job_block/2`,
`Regex.scan/3` over `outputs.version == '...'`, a `cond`-built `detail` string):
```elixir
defp release_version_weld(jobs, release_manifest) do
  declared = Map.get(release_manifest, ".")

  welded =
    @version_gated_jobs
    |> Enum.flat_map(fn job ->
      jobs
      |> job_block(job)
      |> then(
        &Regex.scan(~r/outputs\.version\s*==\s*'(\d+\.\d+\.\d+)'/, &1, capture: :all_but_first)
      )
      |> List.flatten()
      |> Enum.map(&{job, &1})
    end)

  {matching, drifted} = Enum.split_with(welded, fn {_job, version} -> version == declared end)
  ...
  check("release.version_weld.gates_match_declared_version", welded != [] and drifted == [], detail)
end
```
The new `no_bare_version_literal/1` check should use the SAME `Enum.flat_map` over
`@version_gated_jobs` + `job_if/2` (not `job_block/2` — the new check only needs the `if:` string,
research's own draft in RESEARCH.md's "The New Check" section correctly uses `job_if`) +
`Regex.scan(~r/outputs\.version\s*==\s*'\d+\.\d+\.\d+'/, ...)` pattern, but assert `offenders == []`
instead of matching-against-declared.

**3. The `roster_exact/1` roster-coverage idiom** (lines 411-428, quoted for reference — DO NOT
duplicate this function, it is already generic over `@roster_ids`; only `@roster_ids` itself needs
editing: remove `release.version_weld.gates_match_declared_version` at line 92, add
`release.publish_gate.no_bare_version_literal` in its place, same list, same `~w(...)` sigil block
(lines 34-100)).

**4. Self-referential assertions that MUST be updated in the same commit (confirmed by direct read,
not just RESEARCH.md's claim):**
- `linked_release_children/3` (lines 1093-1132), specifically line 1106:
  ```elixir
  includes?(job_if(jobs, job), "needs.release-please.outputs.version == '0.2.1'") and
  ```
  and the failure-detail string at line 1130 naming `"...Hex/iOS/Android 0.2.1 children..."`. Both
  must change to match WELD-03's post-fix `if:` text
  (`needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version`).
- `phase168_ios_recovery_exact_identity/1` (lines 1223-1268), line 1244:
  `~s([ "$RELEASE_VERSION" = "0.2.1" ])` inside the `compared?` list — confirmed this is
  `hex-publish.yml`'s own recovery-path literal comparison, part of `pinned_constants`/`compared?`
  checks for the Phase 168 exact-identity recovery lane, which this research flags as needing
  lockstep update if `hex-publish.yml`'s own recovery gate is touched.
- `phase168_partial_recovery_routes/3` (lines 1288-1352), lines 1344-1347: asserts the exact
  Android POM path string
  `"io/github/sztheory/crosswake-shell-core-android/0.2.1/crosswake-shell-core-android-0.2.1.pom"`
  is present and a differently-shaped coordinate is absent. Needs the planner's explicit decision
  (generalize to a `$VERSION`-interpolated pattern vs. leave pinned to this specific historical Phase
  168 recovery event) — do not silently generalize without recording that decision, since this
  function's own name/comment ties it to "Phase 168 partial recovery," which reads as intentionally
  historical/fixture-like, unlike the `linked_release_children` weld at line 1106 which is NOT
  event-scoped.

---

### `.github/workflows/release-please.yml` (config, event-driven)

**Analog:** same file — `approved-release-guard` job (self-analog).

**Outputs-declaration pattern** (lines 36-44, current tree, re-verified):
```yaml
    outputs:
      linked_release: ${{ steps.guard.outputs.linked_release }}
      approved_head: ${{ steps.guard.outputs.approved_head }}
      approved_tree: ${{ steps.guard.outputs.approved_tree }}
      merge_oid: ${{ steps.guard.outputs.merge_oid }}
      merge_parents: ${{ steps.guard.outputs.merge_parents }}
      merge_tree: ${{ steps.guard.outputs.merge_tree }}
      candidate_receipt: ${{ steps.guard.outputs.candidate_receipt }}
      candidate_run_id: ${{ steps.guard.outputs.candidate_run_id }}
      candidate_receipt_run_id: ${{ steps.guard.outputs.candidate_receipt_run_id }}
```
Add `approved_version: ${{ steps.guard.outputs.approved_version }}` as one more line, same style
(no quoting, same 6-space indent under `outputs:`).

**`emit_output` shell helper + call-site idiom** (lines 60-61, 142-150):
```bash
emit_output() { printf '%s\n' "$1" >> "$GITHUB_OUTPUT"; }
emit_output "linked_release=false"
...
emit_output "linked_release=true"
emit_output "approved_head=$approved_head"
emit_output "approved_tree=$approved_tree"
emit_output "merge_oid=$merge_oid"
emit_output "merge_parents=$first_parent,$second_parent"
emit_output "merge_tree=$merge_tree"
emit_output "candidate_receipt=$candidate_receipt"
emit_output "candidate_run_id=$candidate_run_id"
emit_output "candidate_receipt_run_id=$candidate_receipt_run_id"
```
Add `emit_output "approved_version=$manifest_version"` in the same block, same style — one shell
variable, one `emit_output` line, matching every sibling output.

**The `linked_candidate` pre-check to generalize** (lines 73-79, current tree, re-verified verbatim):
```bash
linked_candidate=false
if grep -q '@version "0.2.1"' mix.exs &&
  grep -q 'version = "0.2.1"' packages/crosswake-shell-core-android/build.gradle.kts &&
  jq -e '."." == "0.2.1" and ."packages/crosswake-shell-core-ios" == "0.2.1" and ."packages/crosswake-shell-core-android" == "0.2.1"' .release-please-manifest.json >/dev/null; then
  linked_candidate=true
fi
[ "$linked_candidate" = "true" ] || exit 0
```
RESEARCH.md's proposed rewrite (already vetted against this exact block) replaces the three
hardcoded `"0.2.1"` occurrences with a `manifest_version` variable read once via
`jq -er '."."' .release-please-manifest.json`, then compares mix.exs/gradle/manifest against EACH
OTHER via that variable — copy that rewrite directly.

**The four publish-gate `if:` clauses (WELD-03), re-verified at current line numbers (223, 525, 571,
728 — unchanged from RESEARCH.md):**
```yaml
# line 223 — publish-hex
if: ${{ needs.approved-release-guard.outputs.linked_release == 'true' && needs.release-please.outputs.version == '0.2.1' && contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}
# line 525 — publish-ios-core
if: ${{ needs.approved-release-guard.outputs.linked_release == 'true' && needs.release-please.outputs.version == '0.2.1' && contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios') }}
# line 571 — publish-android-core
if: ${{ needs.approved-release-guard.outputs.linked_release == 'true' && needs.release-please.outputs.version == '0.2.1' && contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-android') }}
# line 728 — exact-public-proof
if: ${{ needs.approved-release-guard.outputs.linked_release == 'true' && needs.release-please.outputs.version == '0.2.1' }}
```
Rewrite the middle conjunct only, in all four, to:
```yaml
needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version
```

---

### `lib/crosswake/release_candidate/workflow.ex` (model, transform) — WELD-04

**Analog:** self (no other module in the codebase derives a coordinate map from an input version —
confirmed by reading the full 178-line file this session; `@dependencies` is pure topology and stays
frozen, only `@coordinates` needs to become a function).

**Current shape** (lines 1-19, re-verified verbatim):
```elixir
@children ~w(hex ios_mirror android ios_public_proof android_public_proof exact_public)a
@public_children ~w(hex ios_mirror android)a
@statuses ~w(success failed skipped)
@coordinates %{
  hex: "hex:crosswake@0.2.1",
  ios_mirror: "swift:crosswake-shell-core-ios@0.2.1",
  android: "maven:io.crosswake:crosswake-shell-core@0.2.1"
}
@dependencies %{ ... }  # unchanged — pure topology, no version content
```

**Consumer call site** (`rollup!/1`, lines 22-38, quoted in full since the fix touches its input
validation and its coordinate-lookup line):
```elixir
@spec rollup!(map()) :: map()
def rollup!(input) do
  unless exact_map?(input, ~w(approved_ref candidate_receipt children)a), do: invalid!()
  approved_ref = exact_hex!(input.approved_ref, 40)
  candidate_receipt = exact_hex!(input.candidate_receipt, 64)
  children = children!(input.children)
  ...
  successful_coordinates =
    @public_children
    |> Enum.filter(&(children[&1] == "success"))
    |> Enum.map(&Map.fetch!(@coordinates, &1))
    |> Enum.sort()
  ...
```
Fix shape: add `:version` to the required-keys list
(`~w(approved_ref candidate_receipt children version)a`), and replace
`Map.fetch!(@coordinates, &1)` with `Map.fetch!(coordinates(version), &1)` where
`coordinates(version)` is a new private function:
```elixir
defp coordinates(version) do
  %{
    hex: "hex:crosswake@#{version}",
    ios_mirror: "swift:crosswake-shell-core-ios@#{version}",
    android: "maven:io.crosswake:crosswake-shell-core@#{version}"
  }
end
```

**IMPORTANT — corrects an open question in RESEARCH.md (A3):** the full file was read this session
(not just lines 1-60). `evaluate_cli!/0` (lines 89-123) is the CLI wrapper RESEARCH.md flagged as
unread; it is now confirmed NOT to independently compute or duplicate `@coordinates` — it only reads
`APPROVED_HEAD`/`APPROVED_TREE`/`APPROVED_REF`/`CANDIDATE_RECEIPT`/`*_STATE` env vars and calls
`rollup!/1`. It currently has **no version input at all**. WELD-04's fix must add one more
`System.fetch_env!("APPROVED_VERSION")` call inside `evaluate_cli!/0` and thread it into the
`rollup!/1` call's input map as `version: ...` — this is a real, concrete gap RESEARCH.md flagged as
unverified and this session resolves: the wrapper needs a new env var, not just an arity change on
`rollup!/1` itself. `validate!/1` (lines 69-87) rebuilds via `rollup!/1` too and will need the same
`:version` field threaded from `result` if `result` gains a `version` key (check whether the
`linked-release-status.json` schema — `schema_version`/`approved_ref`/etc., lines 49-64 — should also
gain a `version` key; RESEARCH.md does not resolve this, flag for planner).

---

### `lib/crosswake/release_candidate/cleanroom.ex:236` (model, transform) — WELD-05

**Analog:** self — the function's own three preceding conjuncts are the pattern for "what this
function's job actually is."

**Current shape, re-verified verbatim** (lines 218-239):
```elixir
defp validate_approved_artifacts!(artifacts) when is_list(artifacts) do
  normalized =
    Enum.map(artifacts, fn artifact ->
      unless exact_map?(artifact, @approved_artifact_keys), do: invalid!()

      %{
        package: package!(artifact.package),
        version: version!(artifact.version),
        metadata_digest: sha!(artifact.metadata_digest),
        payload_digest: sha!(artifact.payload_digest)
      }
    end)

  by_package = Map.new(normalized, &{&1.package, &1})

  unless length(normalized) == length(Artifact.packages()) and
           map_size(by_package) == length(normalized) and
           Map.keys(by_package) |> Enum.sort() == Enum.sort(Artifact.packages()) and
           Map.fetch!(by_package, "crosswake").version == "0.2.1",
         do: invalid!()

  Map.new(Artifact.packages(), &{&1, Map.fetch!(by_package, &1)})
end
```

**Fix — delete the fourth conjunct only** (do not replace with a parameter; RESEARCH.md's rationale,
confirmed against the surrounding structural checks, is correct — the three remaining conjuncts
already fully establish package-set completeness):
```elixir
unless length(normalized) == length(Artifact.packages()) and
         map_size(by_package) == length(normalized) and
         Map.keys(by_package) |> Enum.sort() == Enum.sort(Artifact.packages()),
       do: invalid!()
```

---

### `lib/mix/tasks/crosswake.release.candidate.ex:50` (route/CLI, request-response) — feeds WELD-06

**Analog:** self — the file's own `@sha_pattern` regex-guard three lines below is the exact fix shape
to copy.

**Current full `parse!/1`, re-verified verbatim** (lines 15-16, 40-62):
```elixir
@sha_pattern ~r/\A[0-9a-f]{40}\z/
@required_options ~w(version ref output_dir)a
...
defp parse!(args) when is_list(args) do
  {opts, argv, invalid} =
    OptionParser.parse(args, strict: [version: :string, ref: :string, output_dir: :string])

  keys = Keyword.keys(opts)

  valid? =
    invalid == [] and argv == [] and Enum.sort(keys) == Enum.sort(@required_options) and
      Enum.uniq(keys) == keys and exact_option_counts?(args) and opts[:version] == "0.2.1" and
      is_binary(opts[:ref]) and Regex.match?(@sha_pattern, opts[:ref]) and
      is_binary(opts[:output_dir]) and opts[:output_dir] != "" and
      not String.contains?(opts[:output_dir], <<0>>)
  ...
```
Fix: add `@version_pattern ~r/\A\d+\.\d+\.\d+\z/` alongside `@sha_pattern`, and replace
`opts[:version] == "0.2.1"` with `is_binary(opts[:version]) and Regex.match?(@version_pattern, opts[:version])` —
identical idiom to the existing `opts[:ref]` conjunct two clauses later, in the same `and`-chain.

**`@moduledoc`/`@shortdoc` text (docstring-only, lines 4,7,9)** must also generalize away from the
literal example `--version 0.2.1` per DOC-05/copy-discipline, since
`check_release_workflow_integrity.exs:483` asserts this exact example text is present in the
candidate-receipt terminal output (`includes?(full, "mix crosswake.release.candidate --version 0.2.1 --ref <40sha>")`)
— that scanner assertion must be relaxed to a pattern in lockstep, per the scanner section above.

---

### `lib/crosswake/release_candidate.ex:100` (service, request-response) — feeds WELD-06

**Analog:** `lib/mix/tasks/crosswake.release.candidate.ex`'s `@sha_pattern` idiom (same fix shape,
one call-chain layer down — this function is called directly with the value the Mix task already
validated, so both must move to format-checks together).

Fix shape (from RESEARCH.md, not independently re-read this session past the cited line — planner
should re-grep line 100 before writing the diff since the file was not fully re-read this pass):
```elixir
defp validate_command_identity!(version, ref, output_dir)
     when is_binary(version) and is_binary(ref) and is_binary(output_dir) do
  unless Regex.match?(~r/\A\d+\.\d+\.\d+\z/, version) and ..., do: raise(...)
  ...
end
```

---

### Scripts (`guarded_hex_publish.sh`, `android_publication.sh`, `ios_mirror.sh`) — utility, file-I/O

**Analog:** `script/release_candidate/ios_mirror.sh` is its own best analog — the SAME file already
contains a correctly-generalized sibling comparison three lines above the one that needs fixing.

Confirmed pattern from RESEARCH.md (not independently re-read this session; the two lines were read
directly by the research pass): line 46 (`[ "$VERSION" = "0.2.0" ] || usage`, baseline mode, leave
untouched — fixture) sits twelve lines from line 52 (`[ "$VERSION" = "0.2.1" ] || usage`, candidate
mode, must generalize to accept any `$VERSION` matching the CLI-supplied semver, live gate). Do not
conflate the two modes.

For `android_publication.sh:18` (URL built from a literal instead of the already-accepted `$VERSION`
CLI arg) and `:60` (`grep -q 'version = "0.2.1"' ...`), the fix is straightforward
`$VERSION`-interpolation — RESEARCH.md's inline diff (`grep -q "version = \"$VERSION\""`) is the
pattern to copy; no separate analog file needed, this script already accepts `$VERSION` elsewhere in
its own arg-parsing (confirmed by RESEARCH.md's own read, cited at `android_publication.sh:46`).

For `guarded_hex_publish.sh:140` (`[ "$PACKAGE" != "crosswake" ] || [ "$VERSION" != "0.2.1" ]`), the
analog is the same generalization idiom — compare `$VERSION` against an externally-supplied expected
value (passed in as an arg/env var) rather than a literal.

---

### `.planning/.../171-WELD-INVENTORY.md` (documentation, batch) — WELD-01

**Analog:** `.planning/workstreams/quality-ratchet-release/milestones/v22.0-phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md`
(full structure read this session).

**Structure to copy** (verbatim excerpt, lines 1-16):
```markdown
# Phase 166 Ownership Ledger

- Base commit: `<sha>`
- Tree commit: `<sha>`
- Candidate rule: <one-line rule statement>
- Unresolved flags: <named list>

<one paragraph of scope/exclusion prose>

## Candidates

| candidate | evidence | owner | disposition |
| --- | --- | --- | --- |
| <path> | <evidence citation> | <owner> | <disposition> |
```
For phase 171's WELD-01 table, the direct structural analog is: `candidate` → `File:Line`, `evidence`
→ `Literal context (verbatim)`, `owner` → N/A (drop or repurpose as a second evidence column), and
`disposition` → the four-way `live gate` / `fixture` / `docstring` / `display string` classification
already used in RESEARCH.md's own Weld Inventory tables — copy those tables' row shape directly
(RESEARCH.md's tables are themselves already in the exact target shape; this artifact should
transcribe them, occurrence-level not file-level per the phase requirement, into a file matching
`166-ownership-ledger.md`'s markdown-table convention rather than inventing a new table schema).
**Note the disposition vocabulary differs** (166 uses `retained`/`changed`/`removed-with-proof`/
`unproven-retained`; 171 uses `live gate`/`fixture`/`docstring`/`display string`) — do not merge the
two vocabularies, they answer different questions (166: is this file still needed; 171: does this
occurrence gate behavior).

## Shared Patterns

### The scanner's `check(id, bool, detail)` contract
**Source:** `script/check_release_workflow_integrity.exs:408-409`
**Apply to:** the new `release.publish_gate.no_bare_version_literal` check function; every other
check in the file already follows it.
```elixir
defp check(id, true, detail), do: {:ok, id, detail}
defp check(id, false, detail), do: {:error, id, detail}
```

### The scanner's YAML-block extraction helpers
**Source:** `script/check_release_workflow_integrity.exs:278-339` (`job_blocks/1`, `job_block/2`,
`job_if/2`, `job_needs/2`, `job_key/2`, `normalize_expression/1`)
**Apply to:** the new check (needs `job_if/2` specifically, already used by dozens of existing
checks in this file — do not write a new YAML-parsing helper).

### The proof-test fixture idiom (`tmp_dir!` + `on_exit` + subprocess `run/2`)
**Source:** `test/crosswake/proof/phase168_release_version_weld_test.exs` (also independently present
in `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`'s `tmp_json_path/1` +
`System.cmd/3` calls — confirms this is a stable, repeated house convention across at least two
recent phases, not a one-off).
**Apply to:** all three new `test/crosswake/proof/phase171_*.exs` files.

### Single-producer value derivation (no second computation path)
**Source:** `.github/workflows/release-please.yml`'s `approved-release-guard` job — `approved_head`/
`approved_tree` are computed ONCE inside the guard step and consumed everywhere else purely by
reference (`needs.approved-release-guard.outputs.approved_head`), never re-derived.
**Apply to:** `approved_version` (WELD-02) must follow the identical shape — computed once in the
guard, consumed by comparison everywhere else (the four `if:` gates, and any `lib/` module that needs
the approved version should receive it as an explicit input/env var, not re-grep `mix.exs` itself).

## No Analog Found

None. Every file in the WELD-01 inventory has at least a role-match or self-analog (the phase is
almost entirely a "generalize an existing literal-equality check to a format/derived-value check"
shape, and the codebase has multiple prior instances of exactly that shape — `ios_mirror.sh`'s own
$VERSION handling, `identity.ex`'s existing regex clauses, `crosswake.release.candidate.ex`'s
`@sha_pattern` conjunct — so nothing here required inventing a pattern from RESEARCH.md's Code
Examples alone).

**Two items need the planner's own decision, not a pattern assignment, per RESEARCH.md's Open
Questions (re-confirmed, not re-resolved, this session):**
1. `lib/crosswake/release_candidate/coordinate.ex` — caller status unverified; a broader
   `grep -rn "Coordinate" lib/ script/ .github/` was NOT re-run this session (out of scope for a
   read-only pattern-mapping pass beyond what RESEARCH.md already did); the planner must resolve
   before assigning this file to a plan wave.
2. `.github/workflows/ios-mirror-backfill.yml:288-293` — fixture vs. live gate; full surrounding job
   definition was not re-read this session.

## Metadata

**Analog search scope:** `test/crosswake/proof/`, `script/`, `.github/workflows/`, `lib/crosswake/`,
`lib/mix/tasks/`, `.planning/workstreams/quality-ratchet-release/milestones/`
**Files scanned:** `phase168_release_version_weld_test.exs`, `phase169_check_name_uniqueness_test.exs`
(existence-confirmed, not content-read — phase171's proof tests do not need its pattern),
`phase170_vacuous_assertion_ledger_test.exs` (read in full for house-style confirmation),
`check_release_workflow_integrity.exs` (targeted reads: lines 1-100, 270-410, 1090-1360),
`release-please.yml` (targeted grep + line-range confirmation), `workflow.ex` (full file, 178 lines),
`cleanroom.ex` (lines 1-40, 218-239), `crosswake.release.candidate.ex` (full file, 69 lines),
`166-ownership-ledger.md` (lines 1-60)
**Pattern extraction date:** 2026-09-17
