# Phase 187: Doctor and proof fidelity - Research

**Researched:** 2026-10-16
**Domain:** Elixir library internals (doctor diagnostics, proof-lane evidence validator, one Mix task), plus planning-file deferral records. No new dependencies.
**Confidence:** HIGH (every code claim below was read in the candidate this session; the three behavioural claims were also reproduced by running the candidate code)

All code paths are relative to the candidate `/private/tmp/crosswake-phase180-impl` (HEAD `bd29400722e14bed74c987bf5a9903f486dc6fc2`, `git status` clean at research time). Planning paths are relative to the recovery checkout `<home>/projects/crosswake`.

<user_constraints>
## User Constraints (from 187-CONTEXT.md)

### Locked Decisions
D-01..D-19 are locked in `187-CONTEXT.md`; the planner MUST read that file and copy it into plans. Summary of the load-bearing ones (not a substitute for the file):

- **D-01** real values replace every placeholder in `evidence_input/1`: `crosswake_version` from `Application.spec(:crosswake, :vsn)` as a string; `template_version` from the host generated-shell manifest if present and valid, else `Mix.Tasks.Crosswake.Gen.Shell.template_version/0`, else the sentinel; `commit_ref` = `git-<hex>` from the host project's `git rev-parse HEAD`; `device_class` stays `:unknown`.
- **D-02** validator accepts only the closed sentinel set by exact match (`commit_ref: "git-unknown"`, `crosswake_version: "unknown"`, `template_version: "unknown"`); `git-` plus 40 or 64 zeros is rejected with `PL-EVIDENCE-COMMIT`; no entropy heuristics. Reversibility: costly.
- **D-03** sentinel evidence is still written (advisory), never promotable, never proof; one predicate (e.g. `provenance_known?/1`) in `evidence.ex`; `:physical_iphone` + any sentinel rejected at validation; promotion to the physical destination refuses sentinel evidence.
- **D-04** dirty tracked tree gives `git-unknown` (tracked files only; planner confirms the flag).
- **D-05** `System.find_executable("git")` + `System.cmd/3`, no shell, fixed args, host project as cwd; missing binary / non-zero exit / output not matching `^[0-9a-f]{40}([0-9a-f]{24})?$` gives the sentinel; never parse `.git`; never log stderr, branch, remote, author, paths.
- **D-06** negative fixtures: all-zero rejected; sentinel accepted for advisory but blocked for `:physical_iphone` and promotion; no-`.git` dir gives `git-unknown`; dirty tracked tree gives `git-unknown`; task source no longer contains `"0.1.0"`, `"161"` or the all-zero ref.
- **D-07** every `runtime: :offline_island` + `offline: :local_first` + no `island_contract` route yields `:error`, code `offline_posture_incomplete`, status `:incomplete`, plus `incoherent_routes: [sorted route ids]` in details; evaluated over all manifest routes before the existing contract filter; mix task exits non-zero (intended).
- **D-08** no route with `offline != :unavailable` gives `offline.status` `:not_claimed` (JSON `"not_claimed"`) and advisory `offline_posture_not_claimed` (exit 0); `states`, `telemetry`, `routes` keys stay present (`routes` empty); CHANGELOG/guide line.
- **D-09** do NOT widen to every `offline != :unavailable` route; record the two known gaps.
- **D-10** `unmanaged_routes` passes `details: %{unmanaged_paths: Enum.uniq(paths) |> Enum.sort(), router: inspect(module)}` (`nil` stays `nil`); test asserts the JSON output of `mix crosswake.doctor --format json`.
- **D-11** synthetic paths only (`/public`); guide gains two lines (`--router` accepts any module exporting `__routes__/0`; doctor JSON contains host route patterns, do not paste into public issues).
- **D-12** compile-time `Policy.Route` rule deferred; doctor is the single enforcement point; three reopen triggers.
- **D-13** canonical record = new `187-DEFERRALS.md` (174-FID-01 bullet schema) for CW-REQ-A, CW-REQ-D, the D-12 rule, and the D-09 gaps; SEED-014 gets dated Phase 187 disposition paragraphs (CW-REQ-A, CW-REQ-D sections); `REQUIREMENTS.md` "Future Requirements (deferred)" rows rewritten to the triggers with a "see 187-DEFERRALS.md" pointer.
- **D-14** CW-REQ-A records both readings of "after Phase 175 publishes" and defers under either; real numbers `@schema_version 2`, 19 assertions, 2 to 3 bump if reopened (the seed's "20" is stale); three reopen triggers; reopening is a new requirement.
- **D-15** CW-REQ-D deferred; two reopen triggers; if reopened drop only the `Route:` line, keep `routeID` on `RouteDenialPresentation`.
- **D-16** no new test/CI lane for the deferral records; verify structure only.
- **D-17** only the codename "first adopter" in any record.
- **D-18** 185/186 phase mechanics (uncommitted candidate edits until a final commit plan; full-suite failure set equals the 186 baseline; mutation log; post-commit probe/history manifest/home-path scan; no push; no twin/Simulator).
- **D-19** 186 WR-01 not folded in. 186 WR-03 (harness `--evidence ""` / bare `--evidence`) is the planner's call; if folded in, record as a deviation.

### Claude's Discretion
Function names (`provenance_known?/1`, git helper module/placement); how the host manifest `template_version` is located and validated; plan split and wave order (doctor edits DOCTOR-01/02 and provenance edits DOCTOR-03 touch disjoint files; DOCTOR-04 is planning files only); formatter text for the new `not_claimed` status.

### Deferred Ideas (OUT OF SCOPE)
- Compile-time `Policy.Route` rule for `:local_first` without `island_contract` (D-12).
- `:cached_read_only` without `cache_contract`; non-`:offline_island` `:local_first` claims (D-09 known gaps).
- CW-REQ-A haptics assertion (`PhysicalIphoneContract` 2 to 3) (D-14).
- CW-REQ-D `RouteUnavailableView` debug line and platform defaults (D-15).
- 186 WR-01 (unreadable Info.plist refusal).
- A durable tripwire test pinning the `PhysicalIphoneContract` version to the deferral record (rejected, D-16).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCTOR-01 | `unmanaged_routes` finding carries structured `details` (paths, router) in `--format json` | Finding site `doctor.ex:379-390`; `Policy.Warning` already holds `unmanaged_paths` and `module`; JSON formatter already emits `details` (`json_formatter.ex:216`). See "DOCTOR-01 findings". |
| DOCTOR-02 | `:offline_island` + `:local_first` without `island_contract` is flagged; "not claimed" when nothing claims offline; compile-time rule recorded as deferred | Filter hole at `doctor.ex:467-473`; reproduced by running the candidate. See "DOCTOR-02 findings". |
| DOCTOR-03 | Real provenance in `verify_navigation_shell`; explicit sentinels; validator rejects all-zero commit | Placeholders at `crosswake.proof_lane.verify_navigation_shell.ex:104-107`; validator `evidence.ex` `valid_versions/1`/`git_ref/1`/`promotion_class/2`. See "DOCTOR-03 findings". |
| DOCTOR-04 | CW-REQ-A and CW-REQ-D deferrals recorded with evidence and reopen triggers; CW-REQ-A both readings | Sources verified; see "DOCTOR-04 findings". Planning files only. |
</phase_requirements>

## Summary

This is a four-requirement fidelity phase with small, well-localised product edits in three candidate source files (`lib/crosswake/doctor/doctor.ex`, `lib/crosswake/proof_lane/evidence.ex`, `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex`) plus one optional new helper module, tests, a CHANGELOG line and two guide lines. DOCTOR-04 is planning files only. No new dependency is needed and none is recommended.

Three defects were reproduced against the live candidate (probe run with an isolated `MIX_BUILD_PATH`): an `:offline_island` route with `offline: :local_first` and no `island_contract` yields `offline.status == :supported` and an advisory `offline_posture_ready`; the `unmanaged_routes` finding has an empty `details` map; a manifest with no offline routes also reports `:supported` with `routes == %{}`. A fourth fact matters for D-09: a `:native_screen` route with `:local_first` and no contract is also silently `:supported` today (the gap D-09 records).

Four places where the CONTEXT text needs a precise reading by the planner (none contradicts a decision, each needs a concrete implementation choice): (1) `inspect(nil)` returns `"nil"`, so "a `nil` module stays `nil`" needs an explicit guard; (2) `verify_navigation_shell` resolves its subject files against `File.cwd!()`, so "host project" for git is `File.cwd!()` and the existing positive test runs inside the (dirty) candidate repo, so it can no longer assert a real hash; (3) `Application.spec(:crosswake, :vsn)` is `nil` unless the app is loaded; (4) the SEED-014 claim that `:cached_read_only` without a `cache_contract` "is already invalid" is false in the candidate (D-09 already knows this).

**Primary recommendation:** five plans: 187-01 doctor (DOCTOR-01 + DOCTOR-02, tracer), 187-02 evidence validator (sentinels, all-zero rejection, `provenance_known?/1`, promotion block), 187-03 provenance helper + task wiring (depends on 02), 187-04 deferral records (planning-only, independent), 187-05 gate, mutation controls, single `fix(187)` commit, post-commit probes. Plans 01, 02 and 04 are parallel-safe (disjoint files).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Unmanaged-route details on the finding | Library core (`Crosswake.Doctor`) | Policy compiler (`Policy.Warning`, already carries data) | Doctor drops data the compiler already produced; fix at the check call only. |
| Offline posture coherence + `not_claimed` | Library core (`Crosswake.Doctor`) | `FindingPolicy` (vocabulary home) | Doctor is the single enforcement point (D-12); `Policy.Route` compile rule stays deferred. |
| Evidence provenance validation | Proof-lane (`Crosswake.ProofLane.Evidence`) | — | One validator, one predicate; every consumer calls it. |
| Reading git/crosswake/template provenance | Mix task (`verify_navigation_shell`) via a small helper | `Mix.Tasks.Crosswake.Gen.Shell` (version constant) | I/O at the edge; validator stays pure. |
| Deferral records | Planning docs (recovery checkout) | SEED-014, REQUIREMENTS.md | Records only; no code, no CI lane (D-16). |

No browser/CDN/database tier is involved.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir stdlib (`System.cmd/3`, `System.find_executable/1`, `Application.spec/2`, `Regex`) | project toolchain (Elixir 1.19.5 per 186-VALIDATION.md; `.tool-versions` modified in recovery checkout, not read) | git read, version read, validation | D-05 mandates the stdlib; no new dep. |
| Jason | already a dependency (`Jason.encode!` used in `evidence.ex`) | evidence JSON | Existing. |
| ExUnit | bundled | tests | Existing suite. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `System.cmd("git", ...)` | a Git library, or parsing `.git/HEAD` | Rejected by D-05 ("another copy and paste is better than another dep"; `.git` parsing is fragile with packed refs, worktrees, reftable). |

**Installation:** none. **Package Legitimacy Audit:** not applicable, the phase installs no external packages (no `gsd_run query package-legitimacy` run needed). `git version 2.41.0` is installed locally [VERIFIED: `git --version` this session].

## Architecture Patterns

### System Architecture Diagram

```
mix crosswake.doctor --router R --format json
   -> Crosswake.Doctor.run/1
        -> compile_and_validate_manifest/2 (doctor.ex:375)
             Compiler.compile -> {:ok, %{warnings: [%Warning{unmanaged_paths, module}]}}
             warning -> check(:warning,"unmanaged_routes",...,details)   <- DOCTOR-01 edit
             Manifest.compile -> manifest
        -> phase_4_posture(manifest) (doctor.ex:466)                     <- DOCTOR-02 edit
             all routes -> [incoherent: offline_island+local_first+no island_contract]  (new, BEFORE filter)
             filter cache_contract|island_contract -> existing coherence
             none claim offline -> :not_claimed + advisory
        -> %Report{status: :error iff any finding severity :error}
   -> JSONFormatter.render (json_formatter.ex check_to_map emits details)
   -> Mix.shell().info(output) THEN Mix.raise if status :error (crosswake.doctor.ex:~55-59)

mix crosswake.proof_lane.verify_navigation_shell --destination --run-root --observation
   -> NavigationShellAdvisory.build/subject_digests (paths resolved from File.cwd!())
   -> evidence_input/1   <- DOCTOR-03 edit: helper reads version/template/git in File.cwd!()
   -> Evidence.build  (validate_fields -> valid_versions: sentinel set + all-zero reject)
   -> Evidence.promote (promotion_class: sentinel evidence cannot go to ".../physical_iphone")
   -> Evidence.scan_stage / Evidence.check (decode path re-validates stored bytes)
```

### Recommended Project Structure (edits only)
```
lib/crosswake/doctor/doctor.ex                         # DOCTOR-01, DOCTOR-02
lib/crosswake/doctor/finding_policy.ex                 # optional: offline_not_claimed clause (pattern exists for support_claim/1)
lib/crosswake/proof_lane/evidence.ex                   # sentinels, all-zero rule, provenance_known?/1, promotion block
lib/crosswake/proof_lane/provenance.ex (new, optional)# git/version/template reader, pure-ish, unit-testable with a cwd arg
lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex  # evidence_input/1 uses the helper
test/crosswake/doctor/doctor_test.exs (+ new file)     # doctor tests
test/crosswake/proof_lane/evidence_test.exs            # validator tests
test/crosswake/proof_lane/provenance_test.exs (new)    # git fixtures
test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs
CHANGELOG.md, guides/offline.md, guides/install.md     # doc lines (D-08, D-11)
```

### Pattern 1: doctor `check/6` with structured details (DOCTOR-01)
Existing call, read this session at `doctor.ex:379-390`:
```elixir
{:ok, %{warnings: warnings}} ->
  warning_findings =
    Enum.map(warnings, fn warning ->
      check(
        :warning,
        "unmanaged_routes",
        "policy_compile",
        warning.message,
        "decide whether unmanaged routes are intentionally outside Crosswake ownership"
      )
    end)
```
`check/6` signature `defp check(severity, code, check_name, message, hint, details \\ %{})` (`doctor.ex` near line 2033). Add the sixth argument:
```elixir
%{
  unmanaged_paths: warning.unmanaged_paths |> Enum.uniq() |> Enum.sort(),
  router: warning.module && inspect(warning.module)   # nil stays nil; inspect(nil) would be "nil"
}
```
`Policy.Warning` struct: `defstruct [:message, :module, unmanaged_paths: []]` [VERIFIED: `lib/crosswake/policy/warning.ex:7`]; `Compiler.source_module/1` returns `nil` for a list route source [VERIFIED: `compiler.ex:70-71`]. The JSON formatter passes `details: check.details` straight through (`json_formatter.ex:216`), so no formatter change is needed; the human formatter does not print details, so none is required there.

### Pattern 2: offline posture over ALL routes, then the existing filter (DOCTOR-02)
Existing code, read at `doctor.ex:466-534`: `offline_routes` filters `route.cache_contract != nil or route.island_contract != nil`, then `coherent?` is `Enum.all?` over the filtered set, `status: if(coherent?, do: :supported, else: :incomplete)`, and a single check with code `offline_posture_ready` / `offline_posture_incomplete` and details keys `status, states, telemetry_keys, terminal_outcomes, routes`. Edit:
1. Before the filter compute `incoherent_ids = manifest.routes |> Map.values() |> Enum.filter(&(&1.runtime == :offline_island and &1.offline == :local_first and is_nil(&1.island_contract))) |> Enum.map(& &1.id) |> Enum.sort()`.
2. `coherent?` becomes `incoherent_ids == [] and <existing>`.
3. Incoherent finding details gain `incoherent_routes: incoherent_ids` (keep the existing keys so JSON shape is stable).
4. `claims_offline? = Enum.any?(Map.values(manifest.routes), &(&1.offline != :unavailable))`. When false: `offline.status = :not_claimed`, `routes: %{}` (already empty because the filter set is empty), keep `states` and `telemetry`, and emit advisory `offline_posture_not_claimed` instead of `offline_posture_ready` (severity `:advisory`, so exit 0). Hint must say cached read-only is not local mutation (D-08). Message must say no routes declare offline behavior. Follow the existing `FindingPolicy.support_claim(:not_claimed)` tuple style (`{severity, code, message, hint}`, `finding_policy.ex:44`) if the planner chooses to put the vocabulary in `FindingPolicy`; the CONTEXT permits either.
5. Precedence when both conditions could be true: impossible (an incoherent route has `offline == :local_first`, which counts as a claim), so `:not_claimed` never masks an error.

Status precedence to pin in a test: incoherent -> `:incomplete`; else no claims -> `:not_claimed`; else `:supported`.

Reproduction (probe run this session in the candidate, isolated `MIX_BUILD_PATH`):
```
offline.status: :supported
findings: [{:warning, "unmanaged_routes", []}, {:advisory, "offline_posture_ready", [:status, :states, :routes, :terminal_outcomes, :telemetry_keys]}]
no-offline: {:supported, %{}}
native_screen local_first no contract: :supported
```
(route `/a`: `runtime: :offline_island, offline: :local_first, security: :standard`, no `island_contract`; route list passed as `route_source`.) The same probe shows `unmanaged_routes` `details` is `[]` keys today.

### Pattern 3: validator rule in the existing style (DOCTOR-03)
Read at `evidence.ex`: `valid_versions/1` calls `decimal_version(input[:template_version], "template_version")`, `semver(input[:crosswake_version])` and `git_ref(input[:commit_ref])`; `git_ref/1` matches `~r/^git-(?:[0-9a-f]{40}|[0-9a-f]{64})$/` and returns `error("PL-EVIDENCE-COMMIT", "commit_ref", "use a full opaque Git reference")`; `promotion_class/2` rejects non-physical evidence going to a destination whose basename is `physical_iphone` with `PL-EVIDENCE-PHYSICAL`; `valid_physical_fields/1` handles `:physical_iphone`. Implementation outline (names are Claude's discretion):
```elixir
@unknown_commit "git-unknown"
@unknown_version "unknown"

defp git_ref(@unknown_commit), do: :ok
defp git_ref(value) when is_binary(value) do
  cond do
    String.match?(value, ~r/^git-(?:0{40}|0{64})$/) ->
      error("PL-EVIDENCE-COMMIT", "commit_ref", "use a real Git reference, not an all-zero hash")
    String.match?(value, ~r/^git-(?:[0-9a-f]{40}|[0-9a-f]{64})$/) -> :ok
    true -> error("PL-EVIDENCE-COMMIT", "commit_ref", "use a full opaque Git reference")
  end
end
defp semver(@unknown_version), do: :ok            # exact match, before the byte_size guard clause
defp decimal_version(@unknown_version, "template_version"), do: :ok   # only for template_version, never schema_version

@spec provenance_known?(t() | map()) :: boolean()
def provenance_known?(%{commit_ref: c, crosswake_version: v, template_version: t}),
  do: c != @unknown_commit and v != @unknown_version and t != @unknown_version
```
Important details:
- The all-zero clause must run BEFORE the generic hex clause (the generic regex accepts zeros). 40 and 64 zero variants are both required (D-02).
- `decimal_version(@unknown_version, "schema_version")` must stay rejected (sentinel only valid for `template_version`).
- Exact-match only; `"Unknown"`, `"unknown "`, `"git-UNKNOWN"` stay rejected (add to the fixture set).
- The decode path (`decode_evidence/2` -> `string_map_to_evidence/1` -> `validate_fields/1`) re-runs `valid_versions/1` on stored bytes, so sentinel evidence round-trips (`Jason.encode!(to_map(evidence)) == bytes` holds) and an all-zero file already on disk is rejected at `check/1`/`scan_stage/1`.
- The sensitive-value scanner (`@sensitive_terms`) does not match `unknown` or `git-unknown` (terms checked: answer selected payload account customer credential password secret token transcript media archive endpoint device_id screenshot trace console log raw_output xcresult; plus `http` prefix).
- Add `PL-EVIDENCE-PHYSICAL` (or a new `PL-EVIDENCE-PROVENANCE`; a new id is a vocabulary addition, keep it only if tests pin it) in two places: `valid_physical_fields/1` for `device_class: :physical_iphone` when `not provenance_known?(input)` and in `promote/3` after `promotion_class/2` when `Path.basename(destination) == "physical_iphone"`. Today `promotion_class/2` already blocks non-physical evidence going to that destination, and physical evidence with a sentinel will be blocked at validation, so the promotion check is belt-and-braces; the planner should still write the test (D-06) and the guard so the predicate is the single rule (D-03).

### Anti-Patterns to Avoid
- **Entropy/repeated-digit heuristics** for "fake looking" hashes (D-02 forbids).
- **Parsing `.git` files** (D-05).
- **Shelling out via `System.shell` or `:os.cmd`** (D-05: no shell).
- **Inferring `device_class` from the host OS** (D-01).
- **Putting `Application.spec` result straight into the map** (charlist, or `nil`): convert with `to_string/1` and map `nil` to the sentinel.
- **Making `:not_claimed` an `:error`/`:warning`**: D-08 says advisory, exit 0.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Generator template version | A second constant or parsing the module source | `Mix.Tasks.Crosswake.Gen.Shell.template_version/0` (public, `lib/mix/tasks/crosswake.gen.shell.ex:43-44`, value `@template_version 4` at line 34) | Its own doc says "Never re-parse the module source or duplicate this integer". |
| Path redaction if a path ever reaches output | New redactor | `ShellPackage.display_location/2` (Phase 186) | Already tested. |
| Evidence canonical JSON / digest / promotion | New writer | `Evidence.build/1`, `to_map/1`, `promote/2`, `check/2` | Allowlist + digest-bound; the task already uses them. |
| Doctor finding construction | Raw `%Check{}` | `check/6` | Existing pattern; details are snake_case keys. |

**Key insight:** every piece needed already exists; the phase threads data through that existing code and adds closed-set validation. Any new module should be a thin reader.

## Runtime State Inventory

Not a rename/refactor/migration phase. However D-02 has a storage consequence worth stating: stored proof-lane evidence JSON that adopters recorded elsewhere may contain the old all-zero `commit_ref` placeholder; after this phase those files fail `Evidence.check/1`. None of this repo's stored data does (the only all-zero occurrences in the candidate are the task literal; `grep -rIl 'git-0{40}'` found `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex` only, plus the SEED text in `.planning`). Category answers: stored data none in repo; live service config none; OS-registered state none; secrets/env none; build artifacts none.

## Common Pitfalls

### Pitfall 1: the existing positive task test runs inside a dirty git repo
**What goes wrong:** `crosswake_proof_lane_verify_navigation_shell_test.exs` executes the task with the test process cwd = candidate repo root, because `NavigationShellAdvisory.subject_digests/0` resolves its 12 subject paths with `Path.expand(relative_path, File.cwd!())` [VERIFIED: `navigation_shell_advisory.ex:115`]. Before the commit plan the candidate tree is dirty, so the new git read returns `git-unknown`; after the commit it returns a real hash. A test asserting a real hash is flaky by construction.
**How to avoid:** put the git/version/template logic in a helper taking an explicit `cwd`, unit-test it against temp git repos (`System.tmp_dir!`, `git init`, local `-c user.email -c user.name` config, no global config dependence), and have the task test assert only the invariant: `commit_ref` matches `^git-([0-9a-f]{40}|[0-9a-f]{64}|unknown)$`, `crosswake_version == to_string(Application.spec(:crosswake, :vsn))`, `template_version == Integer.to_string(Mix.Tasks.Crosswake.Gen.Shell.template_version())` (or the manifest value), the retained file passes `Evidence.check/2`, and the source file contains none of `"0.1.0"`, `"161"`, `0000000000000000000000000000000000000000`.
**Warning signs:** a test that passes locally on a clean tree and fails in the full-suite run on the dirty candidate (or the reverse).

### Pitfall 2: temp-dir fixtures nested in another git repo, or inherited git environment
**What goes wrong:** "no `.git`" fixture picks up a parent repo if the temp dir sits inside one; `GIT_DIR`/`GIT_WORK_TREE`/`GIT_INDEX_FILE` in the environment (set by git hooks or some CI) redirects `git rev-parse` away from `cwd`.
**How to avoid:** create fixtures under `System.tmp_dir!()` with a unique name (not inside the candidate); in the helper pass `cd: cwd` and `env: [{"GIT_DIR", nil}, {"GIT_WORK_TREE", nil}, {"GIT_INDEX_FILE", nil}, {"GIT_CEILING_DIRECTORIES", nil}]` is NOT recommended for ceiling (unset only the first three) [ASSUMED: `System.cmd/3` `:env` accepts `{key, nil}` to unset, documented Elixir behaviour; verify in the red test]. Also pass `stderr_to_stdout: false` and discard stderr (D-05: never log it); note `System.cmd` still lets git write stderr to the VM's stderr unless redirected, so the helper must capture or discard it (the simple option: `stderr_to_stdout: true` and then require output to match the hex regex, which also keeps any error text out of evidence and logs because only a regex match is used).
**Warning signs:** CI log shows `fatal: not a git repository`.

### Pitfall 3: `git status --porcelain --untracked-files=no` semantics
Verified this session in a temp repo: clean tracked tree with an untracked file prints nothing; a modified tracked file prints ` M t` [VERIFIED: ran in a `mktemp -d` repo]. So `--untracked-files=no` ignores untracked build output and flags modified tracked files, which is what D-04 wants. Staged-but-uncommitted changes also print (index vs HEAD), which is correct (HEAD does not describe the code). An empty repository (no commits): `git rev-parse HEAD` exits non-zero, so it becomes the sentinel with no extra code. Submodule dirtiness may also print; acceptable (conservative). Run `status` only after `rev-parse` succeeds, and treat a non-zero `status` exit as the sentinel (fail closed).

### Pitfall 4: `Application.spec(:crosswake, :vsn)` returns `nil` if the app is not loaded
**What goes wrong:** the task as written does not start or load the app. In a host project run, `mix` loads code paths but the `:crosswake` application spec is only registered after load. A `nil` becomes the string `""`/crash via `to_string(nil)` = `""` (fails semver and the task raises `navigation_shell.verification_failed`) rather than the sentinel.
**How to avoid:** helper does `_ = Application.load(:crosswake)` (idempotent) then `case Application.spec(:crosswake, :vsn) do nil -> "unknown"; vsn -> to_string(vsn) end`, and the validator remains the final guard. [ASSUMED: behaviour in a real host without `app.config`; ExUnit run has the app loaded. Verify with a `mix run --no-start`-style probe in the red run, or accept via the fallback since the sentinel path is safe either way.]

### Pitfall 5: `inspect(nil)` is the string "nil"
D-10's "a `nil` module stays `nil`" is not what `inspect/1` does. Use `module && inspect(module)` (or an explicit `case`) and add a list-route-source assertion (`details.router == nil`, JSON `null`). Doctor accepts a route list as `route_source` [VERIFIED: probe this session].

### Pitfall 6: churn in tests that use fixtures with no offline routes
The CONTEXT measured 4 tests asserting `offline.status == :supported` (all use fixtures with offline routes: `ManagedRouter` has `offline: :local_first` with `island_contract: :study_session_v1` and a `cached_read_only` route). Remaining risk is tests whose fixture has no offline route at all and that now see `:not_claimed` plus a new advisory finding (for example hint-quality tests in `test/crosswake/proof/phase154_advisory_actionability_test.exs`, which asserts every Phase 154 advisory hint is substantial; the new advisory is not a Phase 154 code, but any test that iterates "all advisory findings" would see it). The planner's Task 1 must run `test/crosswake/doctor`, `test/mix/tasks`, and `test/crosswake/proof` (doctor-related) red/green and list any assertion changed. Do not widen the doctor tests' `@allowed_detail_keys` (that list in `doctor_host_commands_test.exs:8-18` applies to host-command findings only, read this session).

### Pitfall 7: `mix crosswake.doctor` raises after printing
`crosswake.doctor.ex` prints via `Mix.shell().info(output)` then `Mix.raise("Crosswake doctor found blocking issues")` on `:error` [VERIFIED: file read]. A test on the JSON output of an `:error` run must use `capture_io` around `assert_raise Mix.Error` (output is already printed). DOCTOR-01's finding is a `:warning`, so a clean fixture still exits 0; but the unmanaged fixture (`DefaultsRouter`, unmanaged `/public`) also trips support verification findings unless the install-manifest + proof hooks setup of `crosswake_doctor_test.exs` (~line 120-150, `--native-checks`) is reused. Simplest path: `Crosswake.Doctor.run(route_source: DefaultsRouter, ...)` + `Crosswake.Doctor.JSONFormatter.render/1` in `doctor_test.exs`, plus one `Mix.Tasks.Crosswake.Doctor.run([... "--format", "json"])` case mirroring the `crosswake_doctor_test.exs` setup so success criterion 1 ("asserted by a test on the JSON output") is met at the task level.

### Pitfall 8: CHANGELOG / guide text and docs-sync/guide readers
New guide/CHANGELOG lines must pass `mix crosswake.docs.sync --check` and the guide reader tests (`test/crosswake/guides`, hex page, closeout and docs-parity tests were part of the 186 gate list). No generated guide (`capability_map.md`, `support_matrix.md`) should change. Put the `offline.status` line in `CHANGELOG.md` `[Unreleased]` and `guides/offline.md`; put the two `--router`/JSON-privacy lines in `guides/install.md` (line ~229 already discusses `--router`) [VERIFIED: grep this session]. Use only "first adopter" wording or none in public guides (AGENTS.md).

## Code Examples

### Provenance helper contract (suggested shape)
```elixir
# lib/crosswake/proof_lane/provenance.ex   (name is discretion)
@spec read(Path.t()) :: %{crosswake_version: String.t(), template_version: String.t(), commit_ref: String.t()}
def read(cwd) do
  %{
    crosswake_version: crosswake_version(),
    template_version: template_version(cwd),
    commit_ref: commit_ref(cwd)
  }
end

defp commit_ref(cwd) do
  with git when is_binary(git) <- System.find_executable("git"),
       {head, 0} <- System.cmd(git, ["rev-parse", "HEAD"], cd: cwd, stderr_to_stdout: true),
       head = String.trim(head),
       true <- String.match?(head, ~r/^[0-9a-f]{40}([0-9a-f]{24})?$/),
       {"", 0} <- System.cmd(git, ["status", "--porcelain", "--untracked-files=no"], cd: cwd, stderr_to_stdout: true) do
    "git-" <> head
  else
    _ -> "git-unknown"
  end
end
```
(rescue `ErlangError`/`File.Error` from a missing `cwd` with the sentinel; a non-existent `cd:` raises.) For `template_version/1`, read `Path.join([cwd, "native/ios/crosswake_shell/.crosswake/shell.json"])` (the iOS root used by `shell.status` [VERIFIED: `crosswake.shell.status.ex:47-50`, `{"ios", "native/ios/crosswake_shell"}`] and written by `write_shell_manifest/5` with `"template_version" => @template_version` [VERIFIED: `gen.shell.ex:889-905`]); accept only an integer in `1..99_999_999` (the evidence field allows 1 to 8 decimal digits, `decimal_version/2`), convert with `Integer.to_string/1`; any read/decode/shape failure falls through to `Integer.to_string(Mix.Tasks.Crosswake.Gen.Shell.template_version())`. The "else sentinel" branch in D-01 is only reachable if the constant itself is somehow invalid; it is a total function today, keep the sentinel only for exactness. Use the iOS manifest only (navigation-shell evidence is an iOS lane); do not merge Android.

### Task wiring
`evidence_input/1` keeps its map keys exactly (the validator's `exact_keys/1` requires the closed key set) and replaces only the three provenance values with `Provenance.read(File.cwd!())`. `device_class: :unknown` stays.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fake all-zero commit digest | Explicit `git-unknown` sentinel, all-zero rejected | this phase | Evidence JSON now carries a closed sentinel vocabulary (costly to rename, D-02). |
| `offline.status` is `:supported` or `:incomplete` | adds `:not_claimed` | this phase | JSON consumers must tolerate `"not_claimed"`; CHANGELOG line (D-08). |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `System.cmd/3` `:env` accepts `{"GIT_DIR", nil}` to unset a variable | Pitfall 2 | Helper still works without env scrubbing; only affects hook/CI edge cases. Verify in the red test. |
| A2 | `Application.spec(:crosswake, :vsn)` may be `nil` when the app is not loaded in a host task run | Pitfall 4 | If always loaded, the `Application.load` call is harmless; if not and unguarded, the task fails closed with `verification_failed` (still safe). |
| A3 | The precedent that unknown provenance is marked unknown, not faked (SLSA/in-toto), is recalled from memory (the CONTEXT also says so) | Context only | Not load-bearing; decision is owner-locked. |
| A4 | `.tool-versions` Elixir 1.19.5 is the toolchain used by the candidate (taken from 186-VALIDATION.md; the file itself is modified in the recovery checkout and was not read) | Standard Stack | Cosmetic. |

## Open Questions

1. **Does the planner fold in 186 WR-03 (harness `--evidence ""` / bare `--evidence`)?**
   - Known: it is `script/verify_loopback_origin_simulator.sh:25-34, 286-303`, status `open` in `186-REVIEW-DISPOSITION.md`, manual harness only, with a drafted fix (track `EVIDENCE_REQUESTED`, treat an empty value as an error) in `186-REVIEW.md:72-84`; Phase 188 reruns the harness.
   - Unclear: owner preference; it is outside DOCTOR-01..04.
   - Recommendation: fold it in as a small separate task of plan 187-05's predecessor (own red test in `test/crosswake/proof_lane/loopback_origin_harness_test.exs`, own mutation control), recorded as a deviation in the SUMMARY, because 188 uses the harness and cannot change code. If the planner declines, record a one-line pointer in 187-DEFERRALS.md under "not folded in". Either way WR-01 stays untouched.
2. **Should the promotion block use a new rule id?** Recommendation: reuse `PL-EVIDENCE-PHYSICAL` (no new id) so no vocabulary ledger changes; only introduce `PL-EVIDENCE-PROVENANCE` if a test elsewhere already enumerates rule ids (not checked; grep `PL-EVIDENCE-` in tests before choosing).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| git | D-05 provenance read, git fixtures | yes | 2.41.0 | none needed (sentinel path) |
| elixir / mix | all tests | yes | project toolchain (candidate compiled and ran a probe this session) | none |
| Swift / Xcode | not needed (no Swift change, D-15/D-16) | n/a | n/a | n/a |

Missing dependencies: none.

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json`.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5 per 186-VALIDATION.md) |
| Config file | `test/test_helper.exs` |
| Quick run command | `cd /private/tmp/crosswake-phase180-impl && MIX_BUILD_PATH=/private/tmp/crosswake-phase180-run/_build_187_NN_test mix test <files> > /private/tmp/crosswake-phase180-run/<name>-187-NN.out 2>&1; echo $? > ....exit` then `grep -Eq '^[1-9][0-9]* tests, 0 failures'` |
| Full suite command | `env -u MIX_BUILD_PATH mix test --exclude requires_example_host > /private/tmp/crosswake-phase180-run/fix-187.full.out 2>&1`; failure set via `extract-184-07.sh`, compared with `fix-186.failures` |

Baseline failure set (read this session, `/private/tmp/crosswake-phase180-run/fix-186.failures`): exactly `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`. Never pipe a gating command into `tail`/`head`; never share a `MIX_BUILD_PATH` between two mix runs; never accept 0 tests (project rules, AGENTS memory + 186-VALIDATION.md).

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCTOR-01 | `unmanaged_routes` finding has `details.unmanaged_paths == ["/public"]` and `details.router == "Crosswake.TestSupport.RouterFixtures.DefaultsRouter"`; JSON output carries both; list route source gives `router: nil`; paths sorted/unique | unit (`Crosswake.Doctor.run` + `JSONFormatter.render`) and task-level `capture_io` | `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs` | exists (new tests added) |
| DOCTOR-02 | hole route gives one `:error` `offline_posture_incomplete`, `offline.status == :incomplete`, `incoherent_routes: ["hole"]`; mix task raises; coherent `ManagedRouter` stays `:supported`; no offline routes gives `:not_claimed` + advisory `offline_posture_not_claimed`, JSON `"not_claimed"`, `routes == %{}`, exit 0; `:native_screen`+`:local_first` stays unflagged (pins D-09) | unit + task | same files, new describe `offline posture` | exists |
| DOCTOR-03 validator | all-zero 40 and 64 rejected `PL-EVIDENCE-COMMIT`; `git-unknown`/`unknown` accepted for advisory; near-misses (`Unknown`, `git-UNKNOWN`, `unknown ` ) rejected; `schema_version "unknown"` rejected; `:physical_iphone` + sentinel rejected; promote sentinel evidence to a `.../physical_iphone` destination refused; round-trip `check/1` on stored sentinel evidence passes; all-zero bytes on disk fail `check/1` | unit | `mix test test/crosswake/proof_lane/evidence_test.exs` | exists (new tests added; existing `@valid` fixture uses `git-0123456789abcdef0123456789abcdef01234567`, not all-zero) |
| DOCTOR-03 provenance | git repo clean -> `git-<40hex>` equals `git rev-parse HEAD`; no `.git` -> `git-unknown`; dirty tracked file -> `git-unknown`; untracked-only -> real hash; empty repo -> `git-unknown`; no `git` on PATH -> `git-unknown`; manifest with integer `template_version` used; malformed/absent manifest falls back to `Gen.Shell.template_version/0`; `crosswake_version` equals the app spec | unit with temp repos | `mix test test/crosswake/proof_lane/provenance_test.exs` | no, Wave 0 (new file) |
| DOCTOR-03 task | invariant assertions in Pitfall 1; source has none of `"0.1.0"`, `"161"`, the all-zero ref | task | `mix test test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` | exists |
| DOCTOR-04 | `187-DEFERRALS.md` exists, two reading rows for CW-REQ-A, triggers for A, D and the compile-time rule; SEED-014 and REQUIREMENTS.md point at it; phase diff touches neither `physical_iphone_contract.ex` nor any Swift source | structural check (shell, one-time, in phase evidence, no permanent test, D-16) | `grep`/`git diff --name-only` commands recorded in `RUNS/deferrals-187.check` | no, produced by plan |

### Red/green evidence convention (established by 185/186)
Each tracer/task keeps a red run before the fix: `RUNS/red-187-NN[-tK].out` plus `.exit` (non-zero) with the named failing test headers verified by `awk`/`grep` against the exact test names, then a green run `RUNS/green-187-NN.out` with `grep -Eq '^[1-9][0-9]* tests, 0 failures'`. After each plan: `MIX_BUILD_PATH=$RUNS/_build_187_NN_dev mix compile --force --warnings-as-errors` and `mix format --check-formatted` on the changed files. Control tests that must pass on the unchanged code (for example the coherent `ManagedRouter` stays `:supported`) are listed so a red run cannot be red for the wrong reason (186-01 pattern).

### Mutation controls (throwaway copy `/private/tmp/crosswake-187-mutation`, own `MIX_BUILD_PATH`, one edit each, sha256 before differs from after, each named test must appear in a failure header; derive `mutate-187.sh` from `RUNS/mutate-186.sh`, which exists)
0. unmutated, all 187 focused files: pass, N >= 1.
1. `unmanaged_routes` check without `details`: DOCTOR-01 tests fail.
2. `router:` uses `inspect(module)` unguarded: the nil-router test fails.
3. `unmanaged_paths` unsorted or not unique: the sort/uniq test fails.
4. incoherent computation placed after the contract filter (the original hole): the hole test fails.
5. incoherent predicate widened to every `offline != :unavailable` route (violates D-09): the `:native_screen` / cached-read-only pin test fails.
6. `incoherent_routes` removed from details: the details test fails.
7. no-claim branch removed (status `:supported`): the `not_claimed` status and advisory tests fail.
8. `offline_posture_not_claimed` severity raised to `:error`/`:warning`: the exit-0 test fails.
9. all-zero clause removed from `git_ref/1`: both all-zero (40/64) tests fail.
10. all-zero clause moved after the generic hex clause: same tests fail.
11. sentinel match loosened (case-insensitive, prefix, or `schema_version` accepts `unknown`): the near-miss tests fail.
12. `provenance_known?/1` always `true`: the physical-sentinel and promotion-block tests fail.
13. promotion check removed: the promote-to-`physical_iphone` sentinel test fails.
14. git helper ignores non-zero `rev-parse` exit or returns `git-` + raw output: no-`.git`/empty-repo test fails.
15. dirty-tree check removed (or `--untracked-files=no` replaced by `-uall`): the dirty-tracked test (and the untracked-only test, for the second variant) fail.
16. task `evidence_input/1` restored to literals (OLD file): the source-literal and invariant tests fail.
17. manifest `template_version` read ignores the host manifest or accepts a non-integer: manifest tests fail.
18. (only if WR-03 is folded in) harness empty `--evidence` accepted: its harness test fails.
Mechanism map: DOCTOR-01 -> 1-3; DOCTOR-02 -> 4-8; DOCTOR-03 -> 9-17.

### Sampling Rate
- **Per task commit (uncommitted candidate edits):** the focused file(s) for that task with its own `MIX_BUILD_PATH`.
- **Per plan:** all files the plan owns, `mix format --check-formatted`, `mix compile --warnings-as-errors`, plus `test/crosswake/doctor`, `test/mix/tasks`, `test/crosswake/proof_lane` for 187-01..03.
- **Phase gate (plan 05):** full suite failure set `cmp`-equal to `fix-186.failures`; guides/changelog/docs-sync/closeout readers green; ledger `--check` (`script/inventory_collection_assertions.exs --check`) green (new tests must not add `assert/refute Enum.all?/any?(` lines over possibly empty collections: 186-05 enforced "adds no assert or refute Enum.all?/any?( line"; write loop assertions with a pinned non-empty list first); absence checker pin literal 249 untouched (`script/check_absence_is_not_success.exs`; new test files raise the actual count, which must stay >= 249; do not edit the pin, 188 owns it); adoption-scan findings compared with `adoption-scan-186.findings`; diff boundaries (no `.github`, no Android, no Swift, no `physical_iphone_contract.ex`, no generated guides, no mix.exs/mix.lock change); single `fix(187)` commit on `bd294007` with an explicit path allowlist and the attribution trailer the session specifies; post-commit `TwinProducers.probe_source` result `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`, twin history manifest 87 OK, home-path/username scan of the phase directory and RUNS evidence. No push, no twin, no Simulator, no twin-05.

### Wave 0 Gaps
- [ ] `test/crosswake/proof_lane/provenance_test.exs`: temp git repo helpers (init with explicit local identity, commit, dirty, untracked, empty repo, no `.git`, PATH without git via `System.put_env` restore in `on_exit`).
- [ ] If a new `Provenance` module is added, no framework install is needed.
- [ ] `RUNS/mutate-187.sh` derived from `mutate-186.sh`; `RUNS/fix-187.*` artifacts.

## Security Domain

`security_enforcement` is absent from config, treated as enabled.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3/V4 Auth, session, access control | no | n/a |
| V5 Input Validation | yes | closed-set exact-match validator in `evidence.ex`; hex regex on git output; integer range on manifest `template_version` |
| V6 Cryptography | no | existing SHA-256 digests unchanged; nothing hand-rolled |
| V7/V14 Error handling, config | yes | fail closed to sentinel; never echo git stderr, branch, remote, author or paths |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Fabricated provenance accepted as real (all-zero commit) | Spoofing / Repudiation | reject all-zero in the validator (D-02); dirty tree yields sentinel (D-04) |
| Sentinel evidence promoted as device proof | Spoofing | `provenance_known?/1` gate at validation and promotion (D-03) |
| Command injection through git invocation | Tampering | `System.cmd/3` with fixed argv, no shell (D-05) |
| Host route patterns leaking via doctor JSON | Information disclosure | guide line (D-11), synthetic paths in tests; `router` is a module name only |
| Adopter identity in deferral records | Information disclosure | codename "first adopter" only (D-17); never reidentify (AGENTS.md) |

## DOCTOR-04 findings (planning-only content, verified sources)

Sources read this session:
- **CW-REQ-A:** `PhysicalIphoneContract` `@schema_version 2` at `lib/crosswake/proof_lane/physical_iphone_contract.ex:8` [VERIFIED]; 19 assertion ids (`grep -c 'id: "PI-'` returned 19) [VERIFIED]; SEED text says 20 and bump 2 to 3, so the seed's 20 is stale [VERIFIED: `SEED-014`, staleness note]. Phase 174 disposition `defer-with-reason`, trigger "after Phase 175 publishes" [VERIFIED: `174-FID-01-DISPOSITION.md`]. Reading 1 evidence: `milestones/v23.0-MILESTONE-AUDIT.md` states "core 0.2.11 ordinary 38155320492 is six child COMPLETE with direct Hex/iOS/Maven checks; Chimeway 0.1.2 ordinary 38167555514 passed guarded publication, public clean-room doctor and direct Hex". Reading 2 evidence: same audit, "42 of 43 requirements are satisfied. REL-10 remains historically breached. Phase 175 retains 8/9 and OPEN_HISTORICAL_BREACH", front-matter `closeout_disposition: accepted_historical_breach_requires_qualified_archive`, and "This is the original first-publish timing failure, with no remaining release repair identified. Another publish or another repair plan cannot change it." `MILESTONES.md` records "Phase 175 is archived with SC-1 breached, never marked passed" [VERIFIED].
- **CW-REQ-D:** `RouteUnavailableView.swift:29-30` is `if let routeID = denial.routeID {` / `Text("Route: \(routeID)")` [VERIFIED: read lines 25-33]. D-15 triggers stand; no Swift in v26.
- **Compile-time rule:** `Policy.Route.validate_offline_contracts/1` checks only contract implies mode (`cache_contract` requires `:cached_read_only`; `island_contract` requires `runtime :offline_island` and `:local_first`) [VERIFIED: `route.ex:115-135`]. `Policy.Validator` additionally rejects `:live_view` + `:local_first` and `:offline_island` + `:unavailable` [VERIFIED: `validator.ex:67-86`]. Runtimes are `[:live_view, :offline_island, :native_screen]` [VERIFIED: `schema.ex:16`], so a `:native_screen` + `:local_first` + no contract route compiles and is silently `:supported` (probe-confirmed). The SEED-014 CW-REQ-F text says `:cached_read_only` without `cache_contract` "is already invalid"; that is false in the candidate. 187-DEFERRALS.md should state this correction under the D-09 gaps (it supports D-09 and removes a wrong premise from the seed).
- **Schema to reuse:** 174-FID-01 bullets: Disposition, Decided, Reason, Evidence (or Evidence of no source change), Reopen trigger, Date, Recorded also in.
- **REQUIREMENTS rows to rewrite** (read at `REQUIREMENTS.md` ~lines 99-110, "Future Requirements (deferred)"): rows for CW-REQ-A, CW-REQ-D and the compile-time rule currently carry shorter/different triggers ("A deliberately breaking proof-lane release after a known-good pipeline run, or the adopter asking to drop its own haptics gate"; "The next change to the Swift templates, or the adopter adopting the shipped view"; "After a fixture audit, in an explicitly breaking release"). Rewrite to the D-12/D-14/D-15 triggers and add "see 187-DEFERRALS.md". Use the phrase "first adopter", not "adopter" alone where a codename is needed.
- **Structural verification commands** (D-16, one-time, written to `RUNS/deferrals-187.check`, no permanent test): `test -f 187-DEFERRALS.md`; `grep -c` rows for both CW-REQ-A readings (expect 2 reading rows); `grep -q` triggers for A, D and the compile-time rule; `grep -q '187-DEFERRALS.md'` in SEED-014 and REQUIREMENTS.md; `git -C $C diff --name-only 25614cf6..` style check that the candidate diff contains neither `lib/crosswake/proof_lane/physical_iphone_contract.ex` nor any `.swift`; home-path/identity scan of the new file. These edits are plain uncommitted files in the recovery checkout (no staging/commit there).

## Execution conventions the planner must follow (derived from 185/186 plans)

- **Locations:** `C=/private/tmp/crosswake-phase180-impl` (HEAD must equal `bd29400722e14bed74c987bf5a9903f486dc6fc2` as a precondition, push URL `no-push-phase180` [VERIFIED: `git remote -v` shows `origin no-push-phase180 (push)`]), `RUNS=/private/tmp/crosswake-phase180-run`, `R=$HOME/projects/crosswake`, `PD=$R/.planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity`. Product edits in `C`, uncommitted until the final plan; planning files in `R` stay plain uncommitted files (never stage/commit there).
- **Build isolation:** every focused mix command uses its own `MIX_BUILD_PATH` (`$RUNS/_build_187_NN_test`, `_dev`, `_mut`); only the full suite runs with `MIX_BUILD_PATH` unset and nothing else running in `C` meanwhile.
- **No masked exit codes:** redirect gating commands to files and record `.exit`; never pipe into `tail`/`head` (memory: piped checks mask exit codes). Never accept 0 tests.
- **Red first:** capture the red run before each fix; control tests that pass on old code are named so red cannot be red for the wrong reason.
- **Blocked plans:** write `187-0N-BLOCKED.md`, never a `SUMMARY` (memory: blocked SUMMARY naming); precondition checks list "no 187-0N-BLOCKED.md exists".
- **Single commit:** exactly one `fix(187): ...` commit in the final plan with an explicit path allowlist (never `git add -A`/`.`), required paths listed, optional paths listed, trailer line copied verbatim from the session attribution reminder; porcelain empty afterwards; no push.
- **Mutation harness:** throwaway copy `/private/tmp/crosswake-187-mutation`, never mutate inside `C`; pre-mutation sha256 manifest of the changed paths verified after (24 OK in 186); `mutation-187.log` with exactly N `control ` lines.
- **Sensitive data:** no absolute home path or username in any phase artifact or evidence; scan and record the file list scanned (`home-scan-187.log`).
- **Doctor edit order:** Phase 186 already landed its `doctor.ex` edits (`bd294007`); 187 edits sit on top, no conflict, because 186 is committed.
- **gsd handoff note:** the Phase 187 step after research is `$gsd-plan-phase 187 --ws quality-ratchet-release`; Phase 188 freezes and changes no code.

### Suggested plan split
| Plan | Wave | Files (candidate unless noted) | Requirement |
|------|------|-------------------------------|-------------|
| 187-01 (tracer) | 1 | `lib/crosswake/doctor/doctor.ex`, optionally `finding_policy.ex`, `test/crosswake/doctor/doctor_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs`, `CHANGELOG.md`, `guides/offline.md`, `guides/install.md` | DOCTOR-01, DOCTOR-02 |
| 187-02 | 1 | `lib/crosswake/proof_lane/evidence.ex`, `test/crosswake/proof_lane/evidence_test.exs` | DOCTOR-03 (validator) |
| 187-04 | 1 | `PD/187-DEFERRALS.md`, `R/.planning/seeds/SEED-014-...md`, `R/.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` (recovery checkout, plain files) | DOCTOR-04 |
| 187-03 | 2 (after 02) | new `lib/crosswake/proof_lane/provenance.ex`, `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex`, `test/crosswake/proof_lane/provenance_test.exs`, `test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` | DOCTOR-03 (task) |
| 187-05 | 3 | gate, `mutate-187.sh`, optional WR-03 fix if folded in (separate earlier task), single `fix(187)` commit, post-commit probes | all |

Plans 01, 02, 04 do not share files and can run in parallel only if the runtime permits; per project memory Crosswake executors dispatch with forced isolation none, so sequential execution in `C` is the safe assumption (and each uses its own `MIX_BUILD_PATH`).

## Sources

### Primary (HIGH confidence, read in this session)
- Candidate source: `lib/crosswake/doctor/doctor.ex` (375-390, 464-534, ~213-230, ~2033), `lib/crosswake/doctor/finding_policy.ex`, `lib/crosswake/doctor/json_formatter.ex` (185-220), `lib/crosswake/doctor/formatter.ex` (195-235), `lib/mix/tasks/crosswake.doctor.ex` (40-70), `lib/crosswake/proof_lane/evidence.ex` (whole), `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex` (whole), `lib/mix/tasks/crosswake.gen.shell.ex` (34, 43-44, 715-740, 889-905), `lib/mix/tasks/crosswake.shell.status.ex` (47-50, 60-170), `lib/crosswake/policy/route.ex` (90-150), `validator.ex` (55-125), `schema.ex` (16), `warning.ex`, `compiler.ex` (70-76), `navigation_shell_advisory.ex` (1-40, 111-120), `physical_iphone_contract.ex` (8), `RouteUnavailableView.swift` (25-33).
- Candidate tests: `test/crosswake/doctor/doctor_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs`, `test/crosswake/proof_lane/evidence_test.exs` (1-60, 150-170), `test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` (whole), `test/crosswake/policy/warning_test.exs`, `doctor_host_commands_test.exs` (1-20, 150-160).
- Planning: `187-CONTEXT.md`, `SEED-014`, `REQUIREMENTS.md`, `174-FID-01-DISPOSITION.md`, `v23.0-MILESTONE-AUDIT.md` (grepped lines), `MILESTONES.md` (~75-79), `.planning/research/v26/SUMMARY.md` (C1, C8, C14 rows), `186-05-PLAN.md`, `186-VALIDATION.md`, `186-REVIEW.md` (WR-03), `186-05-SUMMARY.md` (grepped).
- Runtime evidence: probe run in the candidate with isolated `MIX_BUILD_PATH` under the session scratchpad (no candidate files modified; `git status` clean afterwards); `git status --porcelain --untracked-files=no` behavior verified in a temp repo; `git --version`.

### Secondary / Tertiary
None used. No web or Context7 lookups were needed: the phase uses only the Elixir stdlib and in-repo code.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, stdlib only, no new package.
- Architecture: HIGH, every edit site read and three defects reproduced.
- Pitfalls: HIGH for 1, 3, 5, 7 (read or run); MEDIUM for 2 and 4 (A1, A2 assumptions flagged).

**Research date:** 2026-10-16
**Valid until:** until the candidate HEAD moves from `bd294007` (re-check line numbers if it does).
