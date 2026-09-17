# Phase 172: Per-Package Proof Scope - Pattern Map

**Mapped:** 2026-09-17
**Files analyzed:** 4 candidate edit targets (1 shell script, 1 manifest-producing module, 1
manifest-consuming module, 1 test file) + 1 workflow caller read for context
**Analogs found:** 4 / 4 (all self-analog — this phase edits the actual constraint sites directly;
there is no sibling per-package-graded-claim module to copy from elsewhere in the tree)

All paths below verified tracked via `git ls-files` from this worktree. No mirror paths used.

## Key Finding: the single-shared-ref constraint is NOT inside `cleanroom.ex`

The `<required_reading>` block names `cleanroom.ex` as "the module that owns
`validate_approved_artifacts!/1`," and phase 171 did remove a version-literal weld at what was
line 236 in that function. That is real and still true. But the actual `unique | length == 1`
collapse the ROADMAP's Success Criterion 1 refers to is **not** Elixir code inside `cleanroom.ex`
at all — it is a `jq` filter in a shell script:

**The exact constraint expression:**
`script/verify_companion_cleanroom.sh:207`
```bash
candidate_ref=$(jq -er 'map(.candidate_ref) | unique | if length == 1 then .[0] else error("candidate ref") end' "$MATRIX_APPROVED_MANIFEST") || matrix_fail
```
This reads the approved-candidate manifest (an array of six per-package objects), maps to
`.candidate_ref`, and **errors out** unless every one of the six objects carries the identical
ref. `$candidate_ref` (the single collapsed value) is then reused for the entire six-package
re-fetch loop at line 209 and passed as ONE positional arg into
`Crosswake.ReleaseCandidate.Artifact.inspect_cli!/1` at lines 268-269 — every re-fetched package
gets stamped with that one shared ref regardless of what ref it actually validated at.

**A second, upstream instance of the same collapse (producer side, not just consumer side):**
`lib/crosswake/release_candidate/artifact.ex:18,26-27,46,67,86,101,127` — `Artifact.inspect_family!/1`
takes a single **top-level** `candidate_ref` input key (not a per-artifact field: `@input_keys ~w(candidate_ref output_root artifacts)a`, line 18), resolves it once (`candidate_ref = sha!(input.candidate_ref, @ref_pattern)`, line 46), and then broadcasts that one value onto every one of the six `inspect_artifact!/3` calls (line 57, consumed at line 127). This is the structural origin of "one ref for all six packages" — the shell script's `jq unique|length==1` check is really just *verifying* an invariant that this module's input shape *forces* to be true by construction (there is only one ref to give it). Loosening the manifest schema to six independent refs requires touching **both** this producer (give `inspect_family!/1` a per-package ref map or a list of `{package, ref}` pairs) and the consumer jq filter — fixing the jq filter alone is not sufficient, and the planner should not treat `verify_companion_cleanroom.sh:207` as the only weld.

**What `cleanroom.ex` itself actually validates today has no `candidate_ref` field at all:**
`@artifact_keys` (line 24, candidate-local) and `@approved_artifact_keys` (line 25, exact-public)
are both ref-blind: `~w(package version source unpacked_root metadata_digest payload_digest)a` and
`~w(package version metadata_digest payload_digest)a` respectively. `Cleanroom.evaluate_public!/1`
proves byte-exact digest equality (`public_artifact_reason/3`, lines 278-304) using only
`metadata_digest`/`payload_digest` — it never looks at which ref a package's digests were computed
against. Adding "each package proven against its own ref" as a *result field* the planner can
grade on (`byte_exact` vs `reachable_and_compatible` vs `unproven`) most naturally means: (1)
`@approved_artifact_keys` gains `candidate_ref` as a sixth key, (2) `validate_approved_artifacts!/1`
stops silently ignoring it and instead resolves/compares it per-package, and (3)
`public_artifact_reason/3` gains a ref-drift branch that reports a named weaker claim instead of
folding into the existing `"digest_mismatch"` string. See Pattern Assignments below.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `script/verify_companion_cleanroom.sh:207` (jq collapse) | utility (shell verification script) | file-I/O / transform (manifest read → resolved scalar) | same file — the six-package loop it feeds, lines 209-245 | exact (self-analog) |
| `lib/crosswake/release_candidate/artifact.ex` — `@input_keys`/`inspect_family!/1` (lines 18, 26-27, 42-63) | service/model (fail-closed candidate-payload authority) | transform (one input map → 6 normalized observations) | same file — `inspect_artifact!/3` (line 101) already receives package-specific args (`artifact.package`, `artifact.version`) alongside the shared `candidate_ref`; the per-package threading idiom already exists for every OTHER field | exact (self-analog) |
| `lib/crosswake/release_candidate/cleanroom.ex` — `@approved_artifact_keys`, `validate_approved_artifacts!/1` (lines 25, 218-241) | model (validation module) | CRUD/transform (normalize + completeness-check a 6-entry list) | same file — `validate_candidate_artifacts!/3` (lines 183-214), the structurally-identical sibling normalizer one function up, which already does "map + `by_package` completeness check" for a different key set | exact (self-analog within same module family) |
| `lib/crosswake/release_candidate/cleanroom.ex` — `public_artifact_reason/3` graded-claim branch (lines 278-304) | model (pure classifier, `cond`-based) | transform | same function — its own existing `cond` clauses (`"registry_missing"`, `"invalid_status"`, `"source_not_registry"`, `"path_lock_present"`, `"source_root_invalid"`, `"digest_mismatch"`, `nil`) are the vocabulary and ordering convention to extend, not replace | exact (self-analog) |
| `test/crosswake/release_candidate/cleanroom_test.exs` — two-different-refs fixture | test (fixture-mutation, ExUnit) | request-response | same file — `public_fixture/0` (lines 351-381) + `update_approved_artifact/3` (lines 421-427) | exact (self-analog) |

## Pattern Assignments

### `script/verify_companion_cleanroom.sh` (utility, file-I/O/transform)

**Analog:** same file, the loop it feeds.

**Constraint to remove/loosen** (line 207, verbatim):
```bash
candidate_ref=$(jq -er 'map(.candidate_ref) | unique | if length == 1 then .[0] else error("candidate ref") end' "$MATRIX_APPROVED_MANIFEST") || matrix_fail
```

**Consumer loop it currently feeds a single scalar into** (lines 209-269, structure to preserve —
only the ref source changes from "one shared scalar" to "per-package lookup"):
```bash
for package in crosswake crosswake_rulestead crosswake_rindle crosswake_sigra crosswake_chimeway crosswake_threadline; do
  version=$(jq -er --arg package "$package" '.[] | select(.package == $package) | .version' "$MATRIX_APPROVED_MANIFEST") || matrix_fail
  ...
done
...
"${RUNTIME[@]}" mix run --no-start -e 'Crosswake.ReleaseCandidate.Artifact.inspect_cli!(System.argv())' -- \
  "$candidate_ref" "$public_root" "$normalized_manifest" "${artifact_args[@]}" >/dev/null
```
**Fix shape:** the `version=$(jq ... select(.package == $package) | .version)` line (line 210) is
already the exact per-package lookup idiom to copy for `candidate_ref` — replace the one
`unique | length == 1` scalar with a per-package `jq -er --arg package "$package" '.[] | select(.package == $package) | .candidate_ref'` lookup inside the loop, collect it alongside `version` into
`artifact_args`, and stop passing a single `"$candidate_ref"` positional into the CLI call —
`Artifact.inspect_cli!/1`'s arg contract (see below) must change in lockstep since it currently
takes exactly one ref as its first positional arg.

---

### `lib/crosswake/release_candidate/artifact.ex` (service/model, transform)

**Analog:** self — the module's own per-package field-threading idiom (`package`, `version`
already flow through `inspect_artifact!/3` distinctly per artifact; only `candidate_ref` is
special-cased as a shared, hoisted-out value).

**Current shape** (lines 9-27, 42-63, verbatim):
```elixir
@input_keys ~w(candidate_ref output_root artifacts)a
...
@type observation :: %{
        candidate_ref: String.t(),
        package: String.t(),
        ...
      }

@spec inspect_family!(map()) :: [observation()]
def inspect_family!(input) do
  unless exact_map?(input, @input_keys), do: invalid!()

  candidate_ref = sha!(input.candidate_ref, @ref_pattern)
  output_root = regular_directory!(input.output_root)
  artifacts = input.artifacts

  unless is_list(artifacts) and length(artifacts) == length(@packages), do: invalid!()

  package_names = Enum.map(artifacts, &artifact_package!/1)

  unless package_names == @packages, do: invalid!()

  artifacts
  |> Enum.map(&inspect_artifact!(&1, candidate_ref, output_root))
  |> Enum.sort_by(&Enum.find_index(@packages, fn package -> package == &1.package end))
rescue
  ...
end
```
**Fix shape:** move `candidate_ref` off `@input_keys`/the top-level input map and onto each element
of `input.artifacts` instead — `@artifact_keys` (line 17,
`~w(package version tarball unpacked_root outer_checksum source)a`) is the list to extend with
`candidate_ref`, mirroring exactly how `package`/`version` are already per-artifact fields
consumed inside `inspect_artifact!/3` (lines 101-142) rather than hoisted arguments. The `sha!/2`
per-value validator (line 365-369) is already generic — call it once per artifact
(`sha!(artifact.candidate_ref, @ref_pattern)`) instead of once for the whole family (current line
46). The `inspect_cli!/1` CLI wrapper (lines 67-97) will need its arg-chunking size to grow from 6
fields to 7 (`Enum.chunk_every(6)` at line 72 → 7) to carry `candidate_ref` per-artifact through
the CLI boundary, matching `verify_companion_cleanroom.sh`'s `artifact_args` fix above.

---

### `lib/crosswake/release_candidate/cleanroom.ex` — `validate_approved_artifacts!/1` (model, CRUD/transform)

**Analog:** same file, `validate_candidate_artifacts!/3` (lines 183-214) — the structurally
identical sibling one function above, which is the correct template because it already
demonstrates "normalize each entry with per-entry fields + a `by_package` completeness gate built
from `Artifact.packages()`," the exact shape `validate_approved_artifacts!/1` needs once
`candidate_ref` becomes a real per-package field instead of being absent.

**Current shape to extend** (lines 218-241, verbatim — this is the function phase 171 already
edited once, at what was line 236, to remove the version-literal weld; phase 172 edits it again,
non-conflicting: adding a field, not touching the completeness `unless`):
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
           Map.keys(by_package) |> Enum.sort() == Enum.sort(Artifact.packages()),
         do: invalid!()

  Map.new(Artifact.packages(), &{&1, Map.fetch!(by_package, &1)})
end
```
**Fix shape:** add `candidate_ref` to `@approved_artifact_keys` (line 25) and to the per-artifact
map built above, validated with the SAME `sha!/1` 64-hex-char validator already used for the two
digest fields (note: `Artifact.@ref_pattern` is 40-hex-char SHA, distinct from `Cleanroom.@sha_pattern`'s 64-hex-char digest pattern at line 38 — `candidate_ref` needs its OWN pattern constant in this module, do not reuse `sha!/1` as-is; add a `ref!/1` mirroring `Artifact.sha!/2`'s two-arg
pattern-parameterized shape at `artifact.ex:365-369`). **Do not touch the completeness `unless` at
lines 233-236** — six-distinct-packages-present is an orthogonal invariant to six-possibly-distinct-refs and phase 171 already proved this exact `unless` is minimal; do not re-collapse refs back into it.

---

### `lib/crosswake/release_candidate/cleanroom.ex` — `public_artifact_reason/3` (model, transform) — the graded-claim home

**Analog:** self — its own `cond` vocabulary (lines 278-304) is both the existing result-type
convention AND the correct analog for "a check that reports a weaker claim honestly instead of
failing or falsely passing."

**Current shape, verbatim (lines 278-304):**
```elixir
defp public_artifact_reason(artifact, expected, source_root) do
  cond do
    artifact.status == "MISSING" and artifact.source == "unavailable" and
      is_nil(artifact.unpacked_root) and is_nil(artifact.metadata_digest) and
      is_nil(artifact.payload_digest) and artifact.path_lock_count == 0 ->
      "registry_missing"

    artifact.status != "PASS" ->
      "invalid_status"

    artifact.source != "hex_registry" ->
      "source_not_registry"

    artifact.path_lock_count != 0 ->
      "path_lock_present"

    not public_root?(artifact.unpacked_root, source_root) ->
      "source_root_invalid"

    artifact.metadata_digest != expected.metadata_digest or
        artifact.payload_digest != expected.payload_digest ->
      "digest_mismatch"

    true ->
      nil
  end
end
```
**Why this is the right (and only) non-vacuous analog, not just an existing thing:** every branch
here names a *specific, falsifiable* condition before it returns a string — it never returns a
success-shaped value except in the `true -> nil` fallthrough that only fires once every other
concrete predicate has failed to match. That is exactly the discipline SC#4 demands for
`reachable_and_compatible`/`unproven`: a NEW branch must name the concrete condition (drifted past
every approved `candidate_ref` — i.e. `artifact.metadata_digest == expected.metadata_digest and
artifact.payload_digest == expected.payload_digest` STILL holds, i.e. byte digests happen to
match, but `artifact.candidate_ref not in expected.acceptable_refs` or similar), not a fallback
"else, weaker."

**Fix shape:** insert a new `cond` clause **before** the final `true -> nil` branch (ordering
matters — `cond` short-circuits, and today's `nil` fallthrough is what currently means
"byte_exact," so the new branch must intercept before it, not after):
```elixir
artifact.metadata_digest == expected.metadata_digest and
    artifact.payload_digest == expected.payload_digest and
    artifact.candidate_ref not in expected.acceptable_refs ->
  "reachable_and_compatible"
```
The function's return value today is a bare string consumed by
`Enum.filter(children, &(&1.reason not in [nil, "registry_missing"]))` (line 96) and
`Map.take(&1, [:package, :reason])` (line 130) in `evaluate_public!/1` — **do not invent a new
tagged-tuple/struct convention**; this module's existing convention is a flat reason string with
`nil` meaning "fully proven," and the new claim types must slot into that same flat-string
vocabulary (`"reachable_and_compatible"`, `"unproven"`) rather than introducing a parallel
representation. **The digest-equality comparison itself (`!=`) must not change** — SC#3 requires
byte-exact strength to be unchanged for every package it can still be established for; the new
branch only fires when digests already match (which IS byte-exact) but ref provenance cannot be
confirmed — do not weaken the `!=` comparison to accommodate ref drift.

**Caller-side collapse to also fix (SC#4's "never silently averaged into one green result"):**
`evaluate_public!/1` (lines 100-117) currently computes ONE top-level `state` (`"COMPLETE"` /
`"BLOCKED"` / `"PARTIAL"`) for the whole six-package family by filtering `children` into
`blocked`/`missing`/`succeeded` buckets (lines 96-98). A package newly classified
`"reachable_and_compatible"` must NOT be silently bucketed into `succeeded` (which currently means
`is_nil(&1.reason)`, i.e. `succeeded = Enum.filter(children, &is_nil(&1.reason))` at line 98) —
the planner must decide whether such a package moves to `blocked` (safe default, since
`Enum.filter(children, &(&1.reason not in [nil, "registry_missing"]))` at line 96 already treats
any non-nil, non-`"registry_missing"` reason as blocking) or gets a THIRD bucket. The result
already exposes per-package reasons via `failed_packages` (line 129-130,
`Map.take(&1, [:package, :reason])`) — extending that same per-package reason-surfacing (not the
single top-level `state`) is how SC#4's "never silently averaged" requirement is satisfied without
inventing new result shape.

---

### `test/crosswake/release_candidate/cleanroom_test.exs` (test, fixture-mutation)

**Analog:** same file, `public_fixture/0` (lines 351-381) + `update_approved_artifact/3` (lines
421-427).

**Fixture-construction idiom to copy verbatim** (lines 351-381):
```elixir
defp public_fixture do
  candidate = candidate_fixture()
  public_root = Path.join(Path.dirname(candidate.source_root), "public-payloads")
  File.mkdir!(public_root)

  approved_artifacts =
    Enum.map(candidate.artifacts, fn artifact ->
      Map.take(artifact, [:package, :version, :metadata_digest, :payload_digest])
    end)

  public_artifacts =
    Enum.map(candidate.artifacts, fn artifact ->
      root = Path.join(public_root, artifact.package)
      File.mkdir!(root)

      artifact
      |> Map.put(:source, "hex_registry")
      |> Map.put(:unpacked_root, root)
      |> Map.put(:status, "PASS")
      |> Map.put(:path_lock_count, 0)
    end)

  %{
    source_mode: "exact-public",
    ...
    approved_artifacts: approved_artifacts,
    public_artifacts: public_artifacts,
    ...
  }
end
```
Once `candidate_ref` is added to `Artifact`'s per-artifact shape (see above) and flows into
`candidate_fixture/0`'s artifacts (this test file's `candidate_fixture/0` at line 286 builds
artifacts synthetically — the planner should give each of the six a **distinct** ref, e.g.
`String.duplicate("a", 40)` for one and `String.duplicate("b", 40)` for another, following
`test/crosswake/release_candidate/artifact_test.exs:6`'s `@candidate_ref String.duplicate("a", 40)`
convention), the `Map.take(artifact, [:package, :version, :metadata_digest, :payload_digest])`
line above is the ONE line to extend with `:candidate_ref` to carry it into `approved_artifacts`.

**Targeted per-package mutation idiom to copy verbatim** (lines 421-427):
```elixir
defp update_approved_artifact(input, package, callback) do
  update_in(input.approved_artifacts, fn artifacts ->
    Enum.map(artifacts, fn artifact ->
      if artifact.package == package, do: callback.(artifact), else: artifact
    end)
  end)
end
```
This is exactly the mechanism SC#2's "a fixture where two packages carry different refs and both
validate independently" needs — a two-different-refs fixture is
`update_approved_artifact(public_fixture_input, "crosswake_sigra", &Map.put(&1, :candidate_ref, String.duplicate("b", 40)))`
against a `public_fixture/0` where every other package already carries `"a" * 40`. No new fixture
helper is needed; only the mutation payload changes.

**Drift-fixture idiom for SC#4** (forces one package past every candidate ref while keeping
digests matching, to hit the new `"reachable_and_compatible"` branch without touching digest
equality): combine `update_approved_artifact/3` (change only `:candidate_ref`, leave
`:metadata_digest`/`:payload_digest` untouched) with the existing `update_public_artifact/3`
helper (referenced at line ~437, same file, same shape as `update_approved_artifact/3` one
function above it) left UNCHANGED for that package — this isolates the test to "ref drifted, bytes
did not," which is precisely the condition the new `cond` branch keys on.

## Shared Patterns

### `Artifact.packages()` is the single canonical six-package enumeration source
**Source:** `lib/crosswake/release_candidate/artifact.ex:9-16,39-40`
```elixir
@packages ~w(
  crosswake
  crosswake_rulestead
  crosswake_rindle
  crosswake_sigra
  crosswake_chimeway
  crosswake_threadline
)
...
@spec packages() :: [String.t()]
def packages, do: @packages
```
**Apply to:** every completeness check across both modules already calls `Artifact.packages()`
(`cleanroom.ex` lines 96, 208, 213, 233-238, 268-273) rather than re-declaring the list — the
literal six-package list is NOT independently hardcoded anywhere else in `lib/`. The ONE bare
literal enumeration outside this module is `script/verify_companion_cleanroom.sh:209`'s `for
package in crosswake crosswake_rulestead ...` shell loop — that is a second, shell-side source of
truth for "six" that the planner should note does not derive from `Artifact.packages()` (cannot,
across the Elixir/shell boundary) and is not itself part of this phase's scope to fix, only to be
aware it exists alongside the Elixir-side canonical list.

### The `check(id, boolean, detail)` / flat-reason-string convention (not a tagged-tuple house style)
**Source:** `lib/crosswake/release_candidate/cleanroom.ex:278-304` (`public_artifact_reason/3`)
**Apply to:** the new `reachable_and_compatible`/`unproven` result values. Confirmed by full-tree
grep that this codebase has **no existing tagged-tuple or struct convention for graded claims** —
`{:ok, ...}`/`{:error, ...}` pairs exist elsewhere (e.g. `script/check_release_workflow_integrity.exs`'s `check/3`, see phase 171's PATTERNS.md "Shared Patterns" section) but that is a
different module family (CI static-analysis checks) with a different consumer contract (stdout
`OK:`/`FAIL:` lines). `cleanroom.ex`'s own convention — a bare string reason, `nil` meaning fully
proven — is the one this phase must extend, not the scanner's tagged-tuple convention.

### Non-vacuity discipline for the new claim (governing-rule compliance)
**Source:** this milestone's own rule (a check that asserts nothing while reporting green is the
defect) plus `public_artifact_reason/3`'s existing branch-ordering discipline.
**Apply to:** the new `cond` branch and its test. The branch must be reachable ONLY when digests
independently match (never as a catch-all for "digest matched, don't know why"), and the test
fixture must independently construct a case where `candidate_ref` is provably wrong (drifted past
`expected.acceptable_refs`, a concrete, inspectable list) while `metadata_digest`/`payload_digest`
are held byte-identical — proving the new branch fires for the RIGHT reason, not merely that it
fires.

## No Analog Found

None. Every edit site in this phase is itself the analog (the phase edits the actual constraint
expressions directly; there is no sibling "per-package graded claim" module elsewhere in the tree
to copy wholesale from — the closest available analog for the classifier shape is
`public_artifact_reason/3` itself, already assigned above).

## Metadata

**Analog search scope:** `script/verify_companion_cleanroom.sh` (targeted grep + lines 180-280
read), `lib/crosswake/release_candidate/artifact.ex` (full file, 385 lines), `lib/crosswake/release_candidate/cleanroom.ex` (full file, 443 lines, re-read this session per required_reading), `test/crosswake/release_candidate/cleanroom_test.exs` (lines 1-100, 280-435 read), `.github/workflows/release-please.yml` (lines 700-769, exact-public-proof job), `.planning/workstreams/quality-ratchet-release/phases/171-version-authority-split/171-PATTERNS.md` (full file, reused verbatim where the file set overlaps)
**Files scanned:** the five files above; grep sweep across `lib/`, `test/`, `script/`,
`.github/workflows/` for `candidate_ref`, `approved_artifacts`, `byte_exact`,
`reachable_and_compatible`, `unproven`, `reachable\b` confirmed no existing occurrences of the
three new result-type terms anywhere in the tracked tree
**Pattern extraction date:** 2026-09-17
