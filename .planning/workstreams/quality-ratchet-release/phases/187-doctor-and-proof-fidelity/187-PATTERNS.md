# Phase 187: Doctor and proof fidelity - Pattern Map

**Mapped:** 2026-10-16
**Files analyzed:** 17 (modified/new)
**Analogs found:** 16 / 17 (the git/provenance reader has only a partial analog)

All code paths are relative to the candidate `/private/tmp/crosswake-phase180-impl` (HEAD `bd294007`, every analog below verified git-tracked there) unless prefixed `R:` (recovery checkout `<home>/projects/crosswake`) or `RUNS/` (`/private/tmp/crosswake-phase180-run`, untracked phase evidence, not product source). Line numbers are for `bd294007`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/doctor/doctor.ex` (unmanaged_routes, ~379-390) | service (diagnostic check) | transform | same file, `policy_compile_failed` + 186 `host_commands_*` checks passing `details` via `check/6` | exact |
| `lib/crosswake/doctor/doctor.ex` (`phase_4_posture/1`, 466-534) | service (posture check) | transform | same file, existing `offline_posture_ready/incomplete` + `FindingPolicy.support_claim(:not_claimed)` | exact |
| `lib/crosswake/doctor/finding_policy.ex` (optional `offline_not_claimed`) | utility (vocabulary) | transform | same file `support_claim(:not_claimed)` lines 44-48 | exact |
| `lib/crosswake/doctor/formatter.ex` (~210-225, human line for `not_claimed`) | utility (formatter) | transform | same file `offline posture:` line | exact |
| `lib/crosswake/proof_lane/evidence.ex` (sentinels, all-zero, `provenance_known?/1`, promotion block) | model/validator | request-response (validate) | same file `git_ref/1`, `valid_physical_fields/1`, `promotion_class/2` | exact |
| `lib/crosswake/proof_lane/provenance.ex` (NEW, optional) | utility (I/O edge reader) | file-I/O + subprocess | `lib/mix/tasks/crosswake.gen.shell.ex` `template_version/0` (version source) and `shell.status` manifest read; no subprocess analog | partial |
| `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex` (`evidence_input/1`, 101-117) | controller (mix task) | request-response | same file | exact |
| `test/crosswake/doctor/doctor_test.exs` | test | request-response | same file (ManagedRouter report assertions ~120-145) | exact |
| `test/mix/tasks/crosswake_doctor_test.exs` | test | request-response (capture_io JSON) | same file lines 120-160 | exact |
| `test/crosswake/proof_lane/evidence_test.exs` | test | request-response | same file (`@valid` 1-60) | exact |
| `test/crosswake/proof_lane/provenance_test.exs` (NEW) | test | file-I/O (temp git repos) | `test/crosswake/doctor/doctor_host_commands_test.exs` setup (tmp dir + `on_exit`) | role-match |
| `test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` | test | request-response | same file `run_fixture/1` | exact |
| `CHANGELOG.md`, `guides/offline.md`, `guides/install.md` | docs | n/a | 186 CHANGELOG entry for legacy-manifest (guarded by `test/crosswake/guides/host_command_seam_guide_test.exs`) | role-match |
| `187-DEFERRALS.md` (NEW, R:) | planning record | n/a | `174-FID-01-DISPOSITION.md` | exact |
| `R:.planning/seeds/SEED-014-...md`, `R:.../REQUIREMENTS.md` | planning record | n/a | 174-FID-01 "Recorded also in" dated lines | role-match |
| `RUNS/mutate-187.sh` (NEW) | script (evidence harness) | batch | `RUNS/mutate-186.sh` | exact |
| optional WR-03: `script/verify_loopback_origin_simulator.sh` 25-34 + `test/crosswake/proof_lane/loopback_origin_harness_test.exs` | script + test | request-response (arg parse) | same file | exact |

## Pattern Assignments

### `lib/crosswake/doctor/doctor.ex` - DOCTOR-01 unmanaged details (service, transform)

**Analog:** the same call site, lines 375-390, plus `check/6` at 2033.

Current (what to edit):
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
`check/6` (line 2033): `defp check(severity, code, check_name, message, hint, details \\ %{})`. Add the 6th arg:
```elixir
%{
  unmanaged_paths: warning.unmanaged_paths |> Enum.uniq() |> Enum.sort(),
  router: warning.module && inspect(warning.module)   # inspect(nil) is "nil"; guard it (RESEARCH Pitfall 5)
}
```
`Policy.Warning` is `defstruct [:message, :module, unmanaged_paths: []]`. JSON needs no change: `json_formatter.ex` `check_to_map/1` (~208-216) already emits `details: check.details`. Keys are snake_case atoms. Do not add keys to `@allowed_detail_keys` in `doctor_host_commands_test.exs:8-18` (host-command findings only).

### `lib/crosswake/doctor/doctor.ex` - DOCTOR-02 offline posture (service, transform)

**Analog:** `phase_4_posture/1`, lines 466-534. Existing shape to preserve (JSON keys `status, states, telemetry, routes`; finding details `status, states, telemetry_keys, terminal_outcomes, routes`):
```elixir
offline_routes = manifest.routes |> Map.values()
  |> Enum.filter(fn route -> route.cache_contract != nil or route.island_contract != nil end)
  |> Enum.map(fn route -> {route.id, %{runtime: ..., offline: ..., sync_seam: ..., cache_contract: ..., island_contract: ...}} end) |> Map.new()
coherent? = Enum.all?(offline_routes, fn {_id, route} -> case route.offline do
  :cached_read_only -> route.cache_contract and not route.island_contract
  :local_first -> route.island_contract
  :unavailable -> true end end)
offline = %{status: if(coherent?, do: :supported, else: :incomplete), states: ..., telemetry: ..., routes: stringify_offline_routes(offline_routes)}
check(if(coherent?, do: :advisory, else: :error),
      if(coherent?, do: "offline_posture_ready", else: "offline_posture_incomplete"),
      "offline_posture", msg, hint, %{status: Atom.to_string(offline.status), ...})
```
Edit plan (D-07/D-08): compute `incoherent_ids` over `Map.values(manifest.routes)` BEFORE the filter (`runtime == :offline_island and offline == :local_first and is_nil(island_contract)`, `Enum.map(& &1.id) |> Enum.sort()`); `coherent? = incoherent_ids == [] and <existing>`; add `incoherent_routes: incoherent_ids` to the details; `claims_offline? = Enum.any?(routes, &(&1.offline != :unavailable))`; precedence incomplete > not_claimed > supported; no-claims emits advisory `"offline_posture_not_claimed"` and `status: :not_claimed`. Do NOT widen to `offline != :unavailable` (D-09).

**Not-claimed vocabulary analog** (`finding_policy.ex:44-48`, 4-tuple style):
```elixir
def support_claim(:not_claimed) do
  {:advisory, "support_claim_not_claimed",
   "native shell support is not claimed for this host; Phoenix and manifest checks remain active",
   "generate a shell or pass --native-targets ios|android|all when the host begins claiming native support"}
end
```
`@type support_status :: :supported | :verification_required | :not_claimed` is at line 7 (atom already exists; no new vocabulary). Hint must say cached read-only is not local mutation.

**Exit behavior** (`lib/mix/tasks/crosswake.doctor.ex` ~55-59): output printed first, then `Mix.raise` only when `report.status == :error`.
```elixir
Mix.shell().info(output)
if report.status == :error do
  Mix.raise("Crosswake doctor found blocking issues")
end
```

### Doctor tests (test, request-response)

**Analog 1:** `test/crosswake/doctor/doctor_test.exs` ~120-145, direct `Doctor.run` with fixture routers:
```elixir
{:ok, report} = Doctor.run(route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter, install_manifest_path: install_manifest_path, cwd: target)
assert report.offline.status == :supported
```
Use `route_source:` with a plain route list for the hole fixture and `router: nil`; `RouterFixtures.DefaultsRouter` (unmanaged `/public`) for DOCTOR-01. Pair with `Crosswake.Doctor.JSONFormatter.render/1` and `Jason.decode!`.

**Analog 2:** `test/mix/tasks/crosswake_doctor_test.exs:120-160` for the task-level JSON test (reuse its install-manifest + `write_proof_hook!` setup so the unmanaged fixture does not trip support errors):
```elixir
output = capture_io(fn -> File.cd!(target, fn ->
  Mix.Tasks.Crosswake.Doctor.run(["--router", "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
    "--install-manifest", install_manifest_path, "--format", "json", "--native-checks"]) end) end)
decoded = Jason.decode!(output)
assert decoded["offline"]["status"] == "supported"
```
For an `:error` (hole) run wrap in `assert_raise Mix.Error` inside `capture_io` (output is printed before the raise; RESEARCH Pitfall 7). Controls that must stay green on old code: ManagedRouter `:supported`, `:native_screen`+`:local_first` unflagged (pins D-09). Synthetic paths only (`/public`).

### `lib/crosswake/proof_lane/evidence.ex` - validator (model, validate)

**Analog:** the same file; add rules in the `error("PL-EVIDENCE-…", path, hint)` tuple style.

Existing (lines 241-278):
```elixir
defp valid_versions(input) do
  with :ok <- decimal_version(input[:schema_version], "schema_version"),
       :ok <- semver(input[:crosswake_version]),
       :ok <- decimal_version(input[:template_version], "template_version"),
       :ok <- git_ref(input[:commit_ref]) do :ok end
end
defp git_ref(value) when is_binary(value) do
  if String.match?(value, ~r/^git-(?:[0-9a-f]{40}|[0-9a-f]{64})$/), do: :ok,
    else: error("PL-EVIDENCE-COMMIT", "commit_ref", "use a full opaque Git reference")
end
```
Target shape: exact-match clause `defp git_ref("git-unknown"), do: :ok` first; all-zero (`~r/^git-(?:0{40}|0{64})$/`) -> `PL-EVIDENCE-COMMIT` BEFORE the generic hex clause (generic accepts zeros); `semver("unknown")` and `decimal_version("unknown", "template_version")` (never `"schema_version"`) clauses placed before the size-guarded clauses. Add `def provenance_known?/1` (single rule, D-03).

**Physical block** - extend `valid_physical_fields/1` (296-312): in the `:physical_iphone ->` branch add `provenance_known?(input)` into the `with` chain; failure goes to the existing `false ->` arm `error("PL-EVIDENCE-PHYSICAL", "artifact", "use a complete passed physical record")`.

**Promotion block** - `promote/3` (142-158) pipeline `with ... :ok <- promotion_class(evidence, destination), ...`; current class check (lines 654-661):
```elixir
defp promotion_class(%__MODULE__{device_class: :physical_iphone}, _destination), do: :ok
defp promotion_class(_evidence, destination) do
  if Path.basename(destination) == "physical_iphone",
    do: error("PL-EVIDENCE-PHYSICAL", "artifact", "promote only a complete physical record"),
    else: :ok
end
```
Add a guard clause refusing when `Path.basename(destination) == "physical_iphone"` and `not provenance_known?(evidence)`. Reuse `PL-EVIDENCE-PHYSICAL` (grep `PL-EVIDENCE-` in tests before inventing an id).

**Test analog:** `evidence_test.exs` `@valid` map (lines 8-22, commit `git-0123...4567`, not all-zero) and the table-driven loop at ~55-60:
```elixir
for {field, value, rule_id} <- [{:commit_ref, "alice_123", "PL-EVIDENCE-COMMIT"}, {:commit_ref, "git-0123456789abcdef", "PL-EVIDENCE-COMMIT"}, ...] do
```
Extend that loop for all-zero 40/64, near-misses (`"Unknown"`, `"git-UNKNOWN"`, `"unknown "`), `schema_version: "unknown"`. Pin a non-empty list before any `Enum.all?/any?` assertion (collection-ledger rule, `script/inventory_collection_assertions.exs --check`).

### `lib/crosswake/proof_lane/provenance.ex` (NEW, optional; io/subprocess)

**Analog (partial):** `lib/mix/tasks/crosswake.gen.shell.ex:34-44` is the version source to call, never duplicate:
```elixir
@template_version 4
@spec template_version() :: pos_integer()
def template_version, do: @template_version
```
Host manifest location: `native/ios/crosswake_shell/.crosswake/shell.json` (iOS root from `crosswake.shell.status.ex:47-50`; written by `gen.shell.ex` ~889-905 with `"template_version" => @template_version`). Accept only an integer in `1..99_999_999`; any failure falls back to `Integer.to_string(Mix.Tasks.Crosswake.Gen.Shell.template_version())`.

**No in-repo analog for the git subprocess.** Use the shape drafted in RESEARCH "Code Examples" (`System.find_executable("git")`, `System.cmd(git, ["rev-parse","HEAD"], cd: cwd, stderr_to_stdout: true)`, hex regex `^[0-9a-f]{40}([0-9a-f]{24})?$`, then `["status","--porcelain","--untracked-files=no"]` must return `{"", 0}`, else `"git-unknown"`; `rescue` for a missing `cwd`). `crosswake_version`: `Application.load(:crosswake)` then `Application.spec(:crosswake, :vsn)`; `nil` -> `"unknown"`, else `to_string/1`.

### `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex` (controller, request-response)

**Analog:** the file itself, `evidence_input/1` lines 101-117. Keep the exact key set (validator `exact_keys/1`); replace only three values:
```elixir
%{ schema_version: "2",
   crosswake_version: "0.1.0",                                     # -> provenance.crosswake_version
   template_version: "161",                                        # -> provenance.template_version
   commit_ref: "git-0000000000000000000000000000000000000000",    # -> provenance.commit_ref
   route_id: "route-0000000000000000", assertion_ids: NavigationShellAdvisory.assertion_ids(),
   status: :passed, outcome: :passed, captured_at: ..., retention_label: :brief,
   device_class: :unknown,                                         # stays
   approved_hashes: [%{kind: :navigation_shell_advisory, canonical_bytes: advisory_bytes}] }
```
Read provenance with `File.cwd!()` (subject files already resolve from `File.cwd!()`, `navigation_shell_advisory.ex:115`). Errors in this task surface as `Mix.raise("navigation_shell.verification_failed")`-style fail-closed messages; do not add new message text.

**Test analog:** `test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs` (positive test lines 7-30, `run_fixture/1`). It runs in the (dirty) candidate repo, so assert only invariants: `commit_ref =~ ~r/^git-([0-9a-f]{40}|[0-9a-f]{64}|unknown)$/`, `crosswake_version == to_string(Application.spec(:crosswake, :vsn))`, `template_version == Integer.to_string(Gen.Shell.template_version())`, file passes `Evidence.check/2`, and `File.read!` of the task source contains none of `"0.1.0"`, `"161"`, forty zeros. Use `Mix.Task.reenable(@task)` before each run (existing idiom).

### `test/crosswake/proof_lane/provenance_test.exs` (NEW; file-I/O fixtures)

**Analog:** `test/crosswake/doctor/doctor_host_commands_test.exs` setup (lines ~21-27) for temp-dir lifecycle:
```elixir
setup do
  dir = Path.join(System.tmp_dir!(), "doctor-host-commands-#{System.unique_integer([:positive])}")
  File.mkdir_p!(dir)
  on_exit(fn -> File.rm_rf!(dir) end)
  %{dir: dir}
end
```
Use `use ExUnit.Case, async: false` if PATH is mutated. Fixtures: `git init` with `-c user.email=... -c user.name=...` locally (no global config), clean, dirty tracked, untracked-only, empty repo, no `.git` (temp dir outside the candidate), no git on PATH (`System.put_env` + restore in `on_exit`). Scrub `GIT_DIR`/`GIT_WORK_TREE`/`GIT_INDEX_FILE` via `env: [{"GIT_DIR", nil}, ...]` (assumption A1; verify in the red run).

### Deferral records (planning-only)

**`187-DEFERRALS.md` analog:** `R:.planning/workstreams/quality-ratchet-release/milestones/v23.0-phases/174-clean-room-host-realism-adopter-fidelity/174-FID-01-DISPOSITION.md`. Front matter then one `##` section per item with this bullet order:
```markdown
---
phase: ...
requirement: ...
seed: SEED-014
date: 2026-09-18
---
## CW-REQ-A — no haptics assertion in `PhysicalIphoneContract`
- **Disposition:** `defer-with-reason`
- **Decided:** ...
- **Reason:** ...
- **Reopen trigger:** ...
- **Date:** 2026-09-18
- **Evidence of no source change:** `git diff --name-only HEAD -- lib/` is empty ...
- **Recorded also in:** `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md`, CW-REQ-A section, dated disposition line.
```
Sections to write: CW-REQ-A (two reading rows, real numbers: `@schema_version 2`, 19 ids, 2->3; Reading 1 core 0.2.11 + chimeway 0.1.2 per `v23.0-MILESTONE-AUDIT.md`; Reading 2 REL-10 BREACHED, `accepted_historical_breach_requires_qualified_archive`, 8/9 and 42/43), CW-REQ-D, compile-time `Policy.Route` rule (D-12), D-09 gaps including the SEED-014 correction that `:cached_read_only` without `cache_contract` is NOT already invalid, and (if declined) WR-03 under "not folded in". Only the codename "first adopter".

**SEED-014 / REQUIREMENTS.md:** add a dated Phase 187 disposition paragraph in the CW-REQ-A and CW-REQ-D sections of SEED-014, and rewrite the "Future Requirements (deferred)" rows (~lines 99-110 of `R:...REQUIREMENTS.md`) to the D-12/D-14/D-15 triggers with "see 187-DEFERRALS.md". Plain uncommitted files; never stage in the recovery checkout.

**Structural check (D-16, one-time, to `RUNS/deferrals-187.check`):** `test -f`, `grep -c` two reading rows, `grep -q` triggers, `grep -q '187-DEFERRALS.md'` in both pointers, and `git -C $C diff --name-only` containing neither `lib/crosswake/proof_lane/physical_iphone_contract.ex` nor any `.swift`.

### `RUNS/mutate-187.sh` (script, batch)

**Analog:** `RUNS/mutate-186.sh`. Copy these pieces verbatim and change names/paths (`186` -> `187`, `_build_187_05_mut`, `/private/tmp/crosswake-187-mutation`, `LOG=$RUNS/mutation-187.log`):

- Preamble and throwaway copy (lines 1-33): `set -u; umask 022; export MIX_BUILD_PATH=$BM; rsync -a --exclude .git "$C"/ "$M"/; cd "$M"`.
- Helpers (35-64): `touch_file`, `restore_all` (copies back from `$C`), `sha`, `apply` (perl `-0pi`, asserts sha changed), `apply_whole_old` (`git -C "$C" show "$rev:$f"`; for 187 set `OLD=bd29400722e14bed74c987bf5a9903f486dc6fc2`), `totals`, `has_header` (awk on `^ +[0-9]+\) test ` with `index($0, name)`).
- `finish` (95-115): `mix test $tf > "$out" 2>&1; rc=$?`; harness failure unless `rc != 0`, `N >= 1`, `MF >= 1` and every named test has a failure header; log line `control $n: $guard: failed as expected in "<name>" (rc=... N tests, MF failures)`.
- `negative`/`ctl_neg` (117-135, 159-168): `mix test --trace`, named test must run and pass (use for the D-09 widening control and the untracked-only control).
- `ctl N GUARD TESTFILES "name1|name2" FILE PERL_EXPR [FILE EXPR]...` (138-149) and `ctl_whole` (151-157); control 0 is the unmutated focused-file run (171-180).
- Example `ctl` lines to copy the shape of (228-238), e.g.:
```bash
ctl 5 "host_commands_stale_skipped branch returns []" $DOC "$T_ABS" $DOCEX 's~if declaring == \[\] do~if true do~'
```
- Tail (257-260): `cd "$RUNS"; rm -rf "$M"; echo "FAILS=$FAILS"; [ "$FAILS" -eq 0 ]`.
- Drop the Swift-only `finish_swift`/`extract-swift-186.sh` pieces (no Swift in 187). Test-name variables use the exact `test "..."` strings from the new tests (`T_...=`), then reference them in `ctl`. The 18 controls are enumerated in RESEARCH "Mutation controls" (0-18, mechanism map DOCTOR-01 -> 1-3, DOCTOR-02 -> 4-8, DOCTOR-03 -> 9-17). Final log must contain exactly N `control ` lines; pre/post sha256 manifest of changed candidate paths (`candidate-187.pre-mutation.sha256`, as `RUNS/candidate-186.pre-mutation.sha256`).

### Red/green verify idiom (186 plans; apply to every 187 plan)

**Analog:** `186-01-PLAN.md` lines 146 and 156 (`R:.planning/workstreams/quality-ratchet-release/phases/186-.../186-01-PLAN.md`). Red run is captured BEFORE the fix:
```bash
MIX_BUILD_PATH=$RUNS/_build_187_NN_test mix test <files> > $RUNS/red-187-NN-tK.out 2>&1; echo $? > $RUNS/red-187-NN-tK.exit
```
Automated verify (single `<automated>` line, no pipes into `tail`/`head`):
```bash
C=/private/tmp/crosswake-phase180-impl; RUNS=/private/tmp/crosswake-phase180-run; cd $C \
&& test "$(git rev-parse HEAD)" = bd29400722e14bed74c987bf5a9903f486dc6fc2 \
&& test "$(cat $RUNS/red-187-NN-t1.exit)" != 0 \
&& for n in '<exact test name>' ...; do awk -v n="$n" '/^ +[0-9]+\) test / && index($0, n) {f=1} END {exit !f}' $RUNS/red-187-NN-t1.out || exit 1; done \
&& MIX_BUILD_PATH=$RUNS/_build_187_NN_test mix test <files> > $RUNS/t1-187-NN.out 2>&1 \
&& grep -Eq '^[1-9][0-9]* tests, 0 failures' $RUNS/t1-187-NN.out \
&& grep -q '<literal in source>' <lib file>
```
Rules carried verbatim: own `MIX_BUILD_PATH` per mix run (`_build_187_NN_test`/`_dev`); controls that pass on old code are named so a red run cannot be red for the wrong reason; compile gate `MIX_BUILD_PATH=$RUNS/_build_187_NN_dev mix compile --force --warnings-as-errors` and `mix format --check-formatted` recorded to `compile-187-NN.exit` / `format-187-NN.exit`; status allowlist via `git status --porcelain=v1 --untracked-files=all > $RUNS/status-187-NN.txt` and `grep -vE '^( M|\?\?) (path1|path2...)$'` empty; `test -z "$(grep -rlF "$HOME" <evidence files>)"`; blocked plan writes `187-0N-BLOCKED.md`, never SUMMARY. Final plan: full suite `env -u MIX_BUILD_PATH mix test --exclude requires_example_host > $RUNS/fix-187.full.out 2>&1`, failures extracted with `RUNS/extract-184-07.sh` and `cmp`-equal to `RUNS/fix-186.failures` (only `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`); one `fix(187)` commit with an explicit path allowlist (artifacts `fix-186.commit/.message/.msgbody/.paths` are the 186 analogs).

### Optional WR-03 fix (script + test)

**Analog:** `script/verify_loopback_origin_simulator.sh:25-34` (arg loop):
```bash
--evidence)
  EVIDENCE="${2:-}"
  shift 2
  ;;
```
Bare `--evidence` or `--evidence ""` silently disables evidence. Draft fix is in `186-REVIEW.md:72-84` (track `EVIDENCE_REQUESTED`, empty value is an error). Test analog: `test/crosswake/proof_lane/loopback_origin_harness_test.exs` evidence cases (`T_E1`-`T_E3` names in `mutate-186.sh:218-220`, "evidence: ... blocks with LOOP-IOS-EVIDENCE before any build"). If folded in, add mutation control 18 and record as a deviation. WR-01 untouched.

## Shared Patterns

### Fail closed with a closed vocabulary
**Source:** `lib/crosswake/proof_lane/evidence.ex` (exact-key allowlist, `error(rule_id, path, remediation)` at ~717). **Apply to:** evidence validator and provenance reader (any unreadable/invalid value becomes the sentinel or a rejected rule, never a guessed value).

### Never echo sensitive/identifying values
**Source:** `Evidence` sensitive-term scanner (`@sensitive_terms`; `unknown`/`git-unknown` do not match); `Crosswake.Shell.ShellPackage.display_location/2` (Phase 186) is the path redactor if a path ever reaches output. **Apply to:** provenance helper (discard git stderr, branch, remote, author, paths), doctor details (module name only, synthetic `/public` in tests), all phase artifacts (home path -> `<home>`; codename "first adopter" only).

### Doctor finding construction
**Source:** `doctor.ex:2033` `check/6`. **Apply to:** all new/changed findings; details maps use snake_case atom keys; severity `:error` only for the hole, `:advisory` for not_claimed, `:warning` stays for unmanaged_routes.

### No masked exit codes / no zero-test greens
**Source:** `186-VALIDATION.md` and `mutate-186.sh` `totals`/`finish`. **Apply to:** every gating command (redirect to file, record `.exit`, require `^[1-9][0-9]* tests, 0 failures`).

### Collection-assertion ledger and absence pin
**Source:** `script/inventory_collection_assertions.exs --check`, `script/check_absence_is_not_success.exs` (literal 249, untouched). **Apply to:** all new tests; never add `assert/refute Enum.all?/any?(` over a possibly empty collection; pin a non-empty list first.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| git subprocess in `provenance.ex` | utility | subprocess | No existing `System.cmd("git", ...)` read helper in `lib/`; use RESEARCH "Code Examples" draft and D-05 constraints. |

## Metadata

**Analog search scope:** candidate `lib/crosswake/doctor`, `lib/crosswake/proof_lane`, `lib/mix/tasks`, `test/crosswake/doctor`, `test/crosswake/proof_lane`, `test/mix/tasks`, `script/`; `RUNS/`; 174-FID-01 and 186 plans in the recovery checkout.
**Tracked-source gate:** `git ls-files` confirmed in the candidate for every named lib, test and script analog; `RUNS/*` is untracked phase evidence (cited as run-script analogs only, never as source to build on).
**Pattern extraction date:** 2026-10-16
