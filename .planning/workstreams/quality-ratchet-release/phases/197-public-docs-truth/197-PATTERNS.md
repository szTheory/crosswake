# Phase 197: Public docs truth - Pattern Map

**Mapped:** 2026-10-29
**Files analyzed:** 27 (11 doc/config edits, 6 existing test/script edits, 10 new files)
**Analogs found:** 24 / 27 (3 partial or none: ex_doc warning parser, GitHub-slug anchor check, marker extractor)
**Workstream:** quality-ratchet-release (pass `--ws quality-ratchet-release` to every gsd-tools call)
**Tracked-source gate:** every path below was checked with `git ls-files --error-unmatch`; all analogs are tracked. `script/docs-report`, `script/docs_report.exs` and `script/docs_leak_allowlist.json` do not exist yet.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `script/verify_published_cleanroom.sh` (mod: `docs` leg, WR-04/05/06, IN-03) | script (proof) | request-response + batch (fetch, run steps) | itself (`leg_hex`, `fetch`, `need_tools`) + `script/verify_companion_cleanroom.sh` (phx_new) | exact |
| `test/crosswake/release/published_cleanroom_test.exs` (mod) | test | request-response (System.cmd) | itself | exact |
| `README.md` ("Integrating Crosswake", L115-139) | doc | transform | `README.md` L232 `<!-- x-release-please-version -->` (HTML-comment precedent) | role-match |
| `guides/install.md` | doc | transform | `guides/install.md` Step 1b (L105-187) already holds bridge hook, esbuild, `attach/1` | exact (content exists) |
| `guides/native_shell.md` (source text only, L63-72) | doc | transform | itself, `:ios_host` block to reuse | exact |
| new `test/crosswake/guides/cleanroom_doc_markers_test.exs` | test | transform (parse fences) | `test/crosswake/guides/architecture_code_walkthrough_test.exs` (`section_between`) + `script/check_release_doc_version_literals.exs` (`strip_fences`) | role-match |
| `guides/companion_compatibility.md` | doc | transform | itself (table L18-28) | exact |
| `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` (mod) | test | transform | itself + `script/check_release_doc_version_literals.exs` (`\b\d+\.\d+\.\d+\b`) | exact |
| `CHANGELOG.md` | doc | transform | `test/crosswake/hex_page_test.exs` L205-224 (what it pins) | exact |
| new CHANGELOG `[Unreleased]` wording test | test | transform | `test/crosswake/hex_page_test.exs` `section!/2` + `phase171_no_bare_version_literal_test.exs` mutation control | role-match |
| `guides/telemetry.md` | doc | transform | itself (span sections L50-196) + `lib/crosswake/telemetry.ex` L126-132 | role-match |
| `guides/see_it_run.md` (L192-194) | doc | transform | `.planning/BEARINGS.md` L35 wording | exact |
| `guides/android_uat.md` | doc | transform | itself | exact |
| `release-please-config.json` (remove L53-56 entry) | config | n/a | `test/crosswake/planning/release_please_config_test.exs` (does not pin this entry) | exact |
| `test/crosswake/proof/phase68_android_uat_test.exs` (mod) | test | transform | itself + `phase132` helper style | exact |
| `test/crosswake/guides/native_evidence_drift_test.exs` (mod L94-117, L546-547) | test | transform | itself | exact |
| new `script/docs-report` | script (launcher) | request-response | `script/bearings-report` (6 lines) | exact |
| new `script/docs_report.exs` | script (report) | batch + file-I/O + subprocess | `script/bearings_report.exs` (report/UNVERIFIED shape) + `script/check_compile_structure.exs` (`mix` subprocess, `--root`) | role-match |
| new `script/docs_leak_allowlist.json` | config | n/a | `script/ci_docs_allowlist.json` (JSON `schema_version` shape only; separate file per D-18) | partial |
| new `test/crosswake/docs_report_test.exs` | test | batch (fixture dirs) | `test/crosswake/bearings_report_test.exs` (library mode) + `test/crosswake/proof/rescue_boundary_ratchet_test.exs` (`@tag :tmp_dir`, `fixture/put/run`) | role-match |
| new `197-DOCS-REPORT.md`, `197-EVIDENCE/*-197.txt` | evidence | n/a | `195-EVIDENCE/cleanroom-0.2.11-195.txt`, `cleanroom-negative-195.txt` | exact |
| ex_doc `warning:` counting (inside `docs_report.exs`) | utility | transform | `.github/workflows/crosswake-ci.yml` L423-427 (`mix docs` + `test -f doc/index.html`) | partial |
| GitHub-slug anchor check (inside `docs_report.exs`) | utility | transform | none | none |
| `<!-- cleanroom:* -->` marker extractor (bash/awk in the leg) | utility | transform | `strip_fences/1` in `script/check_release_doc_version_literals.exs` L168-183 (fence state machine) | partial |

## Pattern Assignments

### `script/verify_published_cleanroom.sh` (script, request-response + batch)

**Analog:** the file itself. Do not locate anything beside the script: `published_cleanroom_test.exs` L211-217 refutes `BASH_SOURCE`, `dirname $0`, `rev-parse --show-toplevel` and `cp ...tool-versions` in the source, so the docs leg must obtain docs only by `fetch`.

**Header contract to extend** (L1-36, L40, L60-72). Update "Three legs" to four, `DEFAULT_LEGS="hex,maven,ios,docs"`, and add the new selector to the doc block. `CLEANROOM_DOCS_REF` is a selector (like `CLEANROOM_ELIXIR_VERSION`, L23-26), so it is NOT in the refusal gate. If an offline `file://` docs base is needed for hermetic tests, it is a verdict-affecting override and goes in the gate exactly like `CLEANROOM_MAVEN_BASE`:
```bash
SELFTEST="${CLEANROOM_SELFTEST:-}"
LEGS="${CLEANROOM_LEGS:-$DEFAULT_LEGS}"
MAVEN_BASE="${CLEANROOM_MAVEN_BASE:-$MAVEN_DEFAULT_BASE}"
HEX_API="${CLEANROOM_HEX_API:-$HEX_DEFAULT_API}"

if [ "$SELFTEST" != "1" ]; then
  if [ "$LEGS" != "$DEFAULT_LEGS" ] || [ -n "${CLEANROOM_MAVEN_BASE:-}" ] || [ -n "${CLEANROOM_HEX_API:-}" ]; then
    echo "cleanroom: override refused (set CLEANROOM_SELFTEST=1 to use selftest overrides)"
    exit 2
  fi
```
Add the new base override to that `-n` chain, and add `docs` to the leg allowlist case at L253-256 (`hex | maven | ios | docs`), else `unknown leg` exits 2.

**Fail and tool pattern to copy and fix (IN-03)** (L84-99). `need_tools` is where `head`, `tr` (maven leg L135 lists `maven curl cut grep mktemp` but L154 uses `tr`, `head`), `tail` (L215, L225), `tar` (docs tarball mode) and `mkdir`/`rm` must be declared. The first positional is the leg name, not a tool:
```bash
fail() { # leg reason
  echo "cleanroom: FAIL $1 $2"
  FAILED=1
}
need_tools() { # leg tool...
  local leg="$1" t
  shift
  for t in "$@"; do
    if ! command -v "$t" >/dev/null 2>&1; then
      fail "$leg" tool_unavailable
      return 1
    fi
  done
  return 0
}
```

**fetch (WR-04)** (L109-126). The one curl call is L112. Add `--max-time`, `--retry`, `--proto '=https' --proto-redir '=https'` but keep `file://` working for hermetic tests: `--proto '=https'` rejects `file://`, so apply the protocol pin only in the non-`file://` branch (the `case "$url"` already special-cases `file://` at L114-119). Return contract is 0 ok / 3 not published / 4 other; keep it, because every leg switches on it:
```bash
fetch() {
  local url="$1" dest="$2" code rc
  code=$(curl -sS -L -o "$dest" -w '%{http_code}' "$url" 2>/dev/null)
  rc=$?
  case "$url" in
    file://*)
      [ "$rc" -eq 0 ] && [ -f "$dest" ] && return 0
      return 3
      ;;
  esac
  [ "$rc" -eq 0 ] || return 4
  case "$code" in
    200) return 0 ;;
    404) return 3 ;;
    *) return 4 ;;
  esac
}
```

**WR-05 sites (report resolve/parse failure separately from `not_published`):**
- L192 hex: `if [ -z "$registry" ]; then fail hex not_published; return; fi` is a parse failure of a 200 response reported as `not_published`. Use a distinct reason (for example `parse_failed`).
- L238 ios: `git ls-remote ... 2>/dev/null` then empty result is `not_published`, which conflates a network error with an absent tag. Test the exit status first.
- L116-118: `file://` returns 3 for any failure.
- Already correct, copy it: L184-185 (`rc -eq 3` is `not_published`, other `rc` is `resolve_failed`).

**WR-06 site (POM identity)** (L162-166). Today a loose `grep -Fq "<version>$VERSION</version>"` plus `<packaging>aar`. Extend to groupId `io.github.sztheory`, artifactId `$art`, version, packaging. The existing hermetic POM fixture in the test is a bare `<project><version>0.0.1</version><packaging>aar</packaging></project>` (test L47-48) and must gain groupId/artifactId, and the "pom whose version differs" test (L133-146) needs the same.

**Leg skeleton to derive the `docs` leg from** (`leg_hex`, L170-231): `need_tools` first, `mk_work`, toolchain selector, per-step log, `fail <leg> <reason>` on each failure, one PASS line at the end. Copy the toolchain selector verbatim so the docs host resolves asdf shims:
```bash
  if [ -n "${CLEANROOM_ELIXIR_VERSION:-}" ] && [ -n "${CLEANROOM_ERLANG_VERSION:-}" ]; then
    printf 'erlang %s\nelixir %s\n' "$CLEANROOM_ERLANG_VERSION" "$CLEANROOM_ELIXIR_VERSION" >"$host/.tool-versions"
    echo "cleanroom: toolchain elixir $CLEANROOM_ELIXIR_VERSION erlang $CLEANROOM_ERLANG_VERSION"
  else
    echo "cleanroom: toolchain path"
  fi
```
The hex leg pins the dependency as `{:crosswake, "== %s"}` (L208). install.md's own snippet is `{:crosswake, "~> 0.2"}` (L48), which would resolve to the newest 0.2.x rather than the version under test. The `apply` substitution table must therefore map that requirement to `== <version>` (record it in the PASS line so the run is for the version under test).

**Host generation analog** (`script/verify_companion_cleanroom.sh` L287-291, L558-560):
```bash
env MIX_HOME="$MATRIX_GENERATOR_MIX_HOME" HEX_HOME="$MATRIX_GENERATOR_HEX_HOME" \
  "${RUNTIME[@]}" mix archive.install hex phx_new 1.8.13 --force >/dev/null || matrix_fail
...
mix phx.new "$MATRIX_HOST_ROOT" --app clean_room_host --module CleanRoomHost \
  --no-ecto --no-assets --no-dashboard --no-mailer --no-gettext --no-install \
  --no-version-check
```
The docs leg differs in two ways: it must NOT pass `--no-assets` (esbuild config and `assets/js/app.js` are needed, D-02), and it must isolate `MIX_HOME`/`HEX_HOME` in `$WORK` so `archive.install` never touches the caller's archives (the leg_hex path uses `mix new` and has no archive step). A read-only probe here found `phx_new-1.8.13` in `~/.mix/archives` that did not load under the repo's `1.19.5-otp-27`, so do not rely on a pre-installed archive.

**Output contract** (L33-36, L167, L230, L248, L263-272). Add, verbatim shape from D-02:
`cleanroom: leg docs PASS <version> executed=<n> not_applicable=<m> ...`, `cleanroom: FAIL docs step <id> exit <code>`, `cleanroom: FAIL docs <fetch|parse|tool_unavailable> ...`. Retained evidence format to match: `195-EVIDENCE/cleanroom-0.2.11-195.txt` (toolchain line, one `leg ... PASS` per leg, `result PASS legs hex,maven,ios version 0.2.11`, `rc 0`). The final `result` line now reads `legs hex,maven,ios,docs`.

**Docs fetch** (D-03): raw commit URL fetch with `fetch` for `README.md` and `guides/install.md` at `CLEANROOM_DOCS_REF` (40-hex validated like `VERSION` at L52-58, printed in output). Tarball mode (default): a Hex tarball is `tar` containing `contents.tar.gz`, so `tar` and `gzip` go in `need_tools`. Note the alternative the planner may prefer: after `mix deps.get` the same files already sit in `deps/crosswake/`, but the docs must be read before `deps.get` runs (the doc's first step), so a separate tarball fetch is needed.

---

### `test/crosswake/release/published_cleanroom_test.exs` (test, request-response)

**Analog:** itself. Reuse, do not re-invent:
```elixir
@selftest_env [
  {"CLEANROOM_SELFTEST", nil}, {"CLEANROOM_LEGS", nil}, {"CLEANROOM_MAVEN_BASE", nil},
  {"CLEANROOM_HEX_API", nil}, {"CLEANROOM_ELIXIR_VERSION", nil}, {"CLEANROOM_ERLANG_VERSION", nil}
]   # L20-27: add every new override/selector here so the host env cannot leak in

defp run(script, args, env, opts \\ []) do
  System.cmd("bash", [script | args],
    env: @selftest_env ++ env, stderr_to_stdout: true, cd: Keyword.get(opts, :cd, File.cwd!()))
end   # L58-64
```
Patterns to copy for new cases: build a `file://` fixture in `setup` `root` (L29-56), assert the exact failing line (`assert out =~ "cleanroom: FAIL ..."`) AND `refute out =~ "cleanroom: result PASS"` / `refute ... "result SELFTEST"` (L119-121, L171); the missing-tool test (L148-169) builds a PATH of symlinks, which is the model for D-07a's `mix` stub on PATH (write an executable `mix` stub that `exit 1` for the unknown task, put `bin` first on PATH). That test's symlink list (L154) does not include `tail` or `tar`; when `need_tools` grows, extend that list or the test passes for the wrong reason. The contract line carries no tool name, so also consider asserting the leg named.

D-07a requires a negative control that proves `FAIL docs step doctor` and exit 1; D-07b is a real-network run, outside `mix test`.

---

### `README.md` "Integrating Crosswake" and `guides/install.md` (doc, transform)

**Marker precedent:** README L232 already carries an invisible HTML comment, `Crosswake version `0.2.11` <!-- x-release-please-version -->`; `<!-- cleanroom:... -->` follows the same house style. Keep the two namespaces distinct in the marker regex.

**Existing install.md fences and proposed kind** (verify at plan time; line numbers current):

| Lines | Content | Proposed marker |
|---|---|---|
| 45-51 | `{:crosswake, "~> 0.2"}` deps | `apply file=mix.exs` (substitute to `== <version>`) |
| 55-57 | `mix deps.get` | `run` |
| 63-65 | `mix crosswake.install` | `run` |
| 91-100 | LiveDashboard exclusion (`:my_app`) | `show` |
| 119-129 | endpoint `Plug.Static` (installer patches it) | `show` |
| 131-135 | JS layout import and `hooks: {CrosswakeBridge}` | `apply file=assets/js/app.js` (see risk) |
| 140-143 | esbuild `~w(... --external:/crosswake/* --format=esm)` | `apply file=config/config.exs` (see risk) |
| 149-153 | heex hook element | `apply` or `show` |
| 167-176 | `mount/3` with `Crosswake.Bridge.attach()` | `apply file=lib/clean_room_host_web/...` (`MyAppWeb` to `CleanRoomHostWeb`) |
| 193-196 | `mix crosswake.gen.shell ios` / `android` | `show` or `run` (out of this leg per D-02) |
| 225-227 | `mix crosswake.doctor` | `run` |
| 248-250 | `bash script/verify_phase5_example_hosts.sh` | `clone` + italic label (D-06) |
| 258-260 | `mix crosswake.doctor --native-checks` | `show` or `run`; its hooks L264-265 name repo `script/verify_generated_*_shell.sh` |

Also in scope for "no repo-only command" (SC1) though they are not fences: install.md numbered list L17-22 (step 5 is `bash script/verify_phase5_example_hosts.sh`) and README L132-136 plus L202. D-05's test only inspects fences; decide explicitly how list items are labeled.

**README Integrating today** (L115-139) has none of: bridge hook, esbuild flags, `Crosswake.Bridge.attach()`, `:ios_host`. Text to reuse: install.md L119-176 (hook, flags, attach) and `guides/native_shell.md` L64-72:
```elixir
config :crosswake, :ios_host,
  router: MyAppWeb.Router,
  origin: "https://study.crosswake.test",
  entry_route_id: "study-session",
  app_bundle_id: "org.crosswake.host",
  proof_app_bundle_id: "org.crosswake.host.proof",
  device_signing: [mode: :automatic, team_id: "ABCDE12345"]
```
Its `router: MyAppWeb.Router` token and the origin/bundle values are the substitution-table candidates (`MyAppWeb` to `CleanRoomHostWeb`); the origin must be an absolute HTTPS origin without an example host (native_shell.md L77-80), so check that `study.crosswake.test` is accepted at compile or generation time before the leg treats it as runnable.

**Risk to verify before writing the `apply` rule:** install.md's esbuild example uses `--outdir=../priv/static/assets` while the Phoenix 1.8 template (believed, not confirmed here) emits `--outdir=../priv/static/assets/js` plus `--external:/fonts/*`. The prose says "Add both arguments to the existing `args` list" (L137-138), so implement `apply` for this block as "ensure these tokens are present in the existing args", not "replace the line", and confirm against a real `phx.new` 1.8.13 host.

**Tests that constrain these two files (must stay green):**
- `test/crosswake/guides/architecture_code_walkthrough_test.exs` L70-95: README Integrating section must keep `**Current answer:** your Phoenix router owns route declarations and each generated shell is host-owned` and `` `mix crosswake.doctor` ``; section bounds are the headings `### Integrating Crosswake` and `### Contributing or maintaining`.
- `test/crosswake/proof/adopter_profile_contract_test.exs` L47-48: `install =~ "Phoenix SaaS Portal"` and `install =~ "script/verify_phase5_example_hosts.sh"` (keep the token, as a `clone` block).
- `test/crosswake/guides/native_evidence_drift_test.exs` L215-330 + L408 + L533: scans README and install.md; any `0.1.0` literal is a `:stale_public_version_truth` failure (regex L303-310), `verified Android` and `physical-device support` lines fail, and required labels/terms (`## Native Evidence Labels`, `generated public-coordinate proof`, `local-dev proof`) must remain.
- `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` L77 reads `readme_dependency_requirement(install, "crosswake")` = the FIRST `{:crosswake, "..."}` in install.md and compares it to the core floor `~> 0.2`. Keep that literal as the first match.
- `test/crosswake/guides/release_boundaries_test.exs` scans README and install.md (L7-17, `scan_public_docs`) for stale-version "current/latest" phrasing.

---

### new `test/crosswake/guides/cleanroom_doc_markers_test.exs` (test, transform)

**Analog 1, section slicing** (`architecture_code_walkthrough_test.exs` L261, used at L70 and L93):
```elixir
integrating =
  section_between(readme, "### Integrating Crosswake", "### Contributing or maintaining")
```
**Analog 2, fence state machine** (`script/check_release_doc_version_literals.exs` L168-183): toggle on a trimmed line starting with three backticks; copy that logic rather than a regex over the whole file.
```elixir
fence? = line |> String.trim_leading() |> String.starts_with?("```")
cond do
  fence? -> {"", not inside?}
  inside? -> {"", inside?}
  true -> {line, inside?}
end
```
For the marker test, instead of blanking fenced lines, collect them with their preceding non-blank line and fail when that line is not one of the four marker kinds.

**Non-vacuity and negative control (mandatory, see Shared Patterns / absence guard):** assert the fence count is at least a floor (so deleting all fences cannot pass), and the D-05 stripped-marker control must prove the mutation changed the text (copy the `mutated == block` raise from `phase171_no_bare_version_literal_test.exs` L110-136 into a shared helper in the new file).

Required-token list (D-05): bridge hook, `--external:/crosswake/*`, `--format=esm`, `Crosswake.Bridge.attach()`, `:ios_host`, evaluated over the union of `run` and `apply` blocks.

---

### `guides/companion_compatibility.md` and `test/crosswake/proof/phase132_compat_matrix_drift_test.exs`

**Doc edits** (D-10). Table is L22-28; header comment L18-21 includes a stale `<!-- Current Version: ... -->` block to delete or rewrite; prose L30-38 ("unpublished", rindle, rulestead) is to be deleted; replace the `Current Version` column by `Latest on Hex` links. Keep column 0 `Hex Package` (the test finds the header by `~r/^\|.*Hex Package.*\|/`, test L540) and the `Requires \`crosswake\`` header (test L506-518).

Additional stale literals in the same guide that D-11's table-only scan will not catch (decide, do not silently leave): L80 ``version `0.1.3` `` for `crosswake_sigra`; L96-99 engine versions "`rulestead` is at `1.0.0`" and "`rindle` is at `0.3.0`".

**Test edits:**
- Remove `@published_versions` (L33-36) and its four consumers: L85-86 (`package_row_cell(guide, package, "Current Version") == ...`), L99, L106, L112 (`Map.keys(@published_versions)`). Replace the package list with `extracted_companion_mix_files() |> Enum.map(&package_name/1)` (helper at L360-363, `package_name/1` at L459).
- Replace the SC#6 format-guard test (L280-312) and delete `current_version_column_index/1` (L522-532) and the `Current Version` text in the L249 message and the L471 comment.
- New assertion shape: scan only the table rows with the three-component regex used by `check_release_doc_version_literals.exs` L97 (`~r/\b\d+\.\d+\.\d+\b/`). Two-component requirements (`~> 0.2`, `"~> 0.1"` in the Engine cell) must stay legal.
- Non-vacuity floor on rows compared: mirror the existing `assert length(companion_mix_files) == 5` (L165) and the `doc_package_rows(doc)` loop (L215, L297). Negative control per D-11: inject `0.1.0` into one row, assert the mutated doc differs from the original, assert the check goes red.

---

### `CHANGELOG.md` and its new wording test

**Edit sites** (current text): L10 paragraph "Planning milestones vs Hex releases" (calls MILESTONE-ARC canonical), L20 "No new support claims have been cut after `0.2.1` yet", L22 "The current published Hex family includes ...", L36 "The current published Hex release is `0.2.1`".

**Existing code that pins CHANGELOG wording. A blind delete breaks these:**
- `test/crosswake/hex_page_test.exs` L205-224 requires, in `## [Unreleased]`: the four headings `### Unpublished support claims`, `### Verification-required and advisory surfaces`, `### Deferred non-shipped claims`, `### Published Hex truth`; the literal `not shipped`; and, anywhere in the file, `published Hex release` and `planning milestones`. Mirrored in `lib/crosswake/doctor/publish_readiness.ex` L1049-1075 (`unreleased_split?` and `published_hex_truth?`, also requires `## [0.1.0]`) and `lib/crosswake/planning/closeout_verifier.ex` L44-47, L244. So rewrite, do not delete: keep the `### Published Hex truth` heading with a version-free pointer to GitHub Releases and hex.pm, and keep the words "published Hex releases" and "planning milestones" in the top paragraph (which is outside `[Unreleased]`, so it does not trip the new D-13 wording test).
- `test/crosswake/guides/release_boundaries_test.exs` scans `CHANGELOG.md` (L7-9) with `stale_package_versions` = every `## [x.y.z]` heading except the current one (L583-593). Its regexes (L595-630) are unanchored, so `0.2.1` matches inside `0.2.11`. A new pointer sentence that contains a version range must avoid `latest`, `current`, `current baseline|package|release`, `Crosswake version` and `package version` near any `0.2.x` (L595-606, L621-629). The decision text asks for a "version-free" sentence while SC2 says "points to GitHub Releases for 0.2.2-0.2.11": prefer no literal versions, or run `mix test test/crosswake/guides/release_boundaries_test.exs` on the exact wording.
- Also keep at least one `## [x.y.z]` heading (`published_version/0` flunks without one, L411-418).

**New test (D-13):** `section!/2` from `hex_page_test.exs` L228-235 extracts `[Unreleased]`:
```elixir
defp section!(content, heading) do
  pattern = ~r/^#{Regex.escape(heading)}\r?\n(.*?)(?=^## \[|\z)/ms
  case Regex.run(pattern, content, capture: :all_but_first) do
    [section] -> section
    nil -> flunk("missing section #{heading}")
  end
end
```
Assert `refute unreleased =~ ~r/current published|published Hex (family|release)/` plus a negative control that injects each phrase into a copy and requires red (and asserts the copy changed). Simplest home: add a `describe` in `hex_page_test.exs` beside the L205 test, or a new file in `test/crosswake/guides/`.

---

### `guides/telemetry.md` (doc) and its guard

`Crosswake.Telemetry.events/0` already declares the entry (`lib/crosswake/telemetry.ex` L126-132):
```elixir
%{ event: [:crosswake, :offline, :replay], tier: :active,
   description: "Emitted for a closed scoped-replay observation.",
   measurements: [:attempt_count, :event_count, :duration_ms],
   metadata: [:route_id, :runtime, :lifecycle, :outcome, :denial] }
```
**Do not copy the span template blindly.** Every existing guide section (L50-196) lists `:start/:stop/:exception`. Offline replay is emitted by `emit_safe_observation/1` as a single `:telemetry.execute([:crosswake, :offline, :replay, :stop], ...)` (telemetry.ex L361-372), so the "Event names" list for it has only the `:stop` event. Also reconcile the closing sentence "`Crosswake.Offline.Telemetry` is a metadata-contract module only; it has no event catalog" (guide L200): that stays true of the module but should point at where the replay event is declared.

Section skeleton to copy: any guide event section (for example "### Bridge: push", guide L114-129): heading, one-line description, a `Suffix | Measurements | Metadata` table, an "Event names:" bullet list in the double-backtick form `` `[:crosswake, ..., :stop]` ``.

Guard: `test/crosswake/proof/phase133_telemetry_contract_test.exs` L577-620 only checks section headings exist. No test ties the guide to `events()`, which is how `offline.replay` was missed. A cheap guard (in that file's `ProofAssertions.stable_id_message` style): for each `tier: :active` event in `Crosswake.Telemetry.events()` whose prefix is a core `[:crosswake, ...]`, assert the guide mentions the prefix, with a negative control that removes one mention.

---

### `guides/see_it_run.md` (doc)

Edit the paragraph at L192-194 ("What the receipt proves: ... What it does not prove: ..."). Wording source of truth: `.planning/BEARINGS.md` L35, "twin-05 attests a53fbef, not main; no CI lane (v30)." Add one sentence stating the twin receipt attests candidate `a53fbef`, not `main`. Guides tests that read this file: `see_it_run_test.exs`, `see_it_run_banner_test.exs`, `see_it_run_collateral_test.exs`, `readme_see_it_run_test.exs` (re-run all four after the edit).

---

### `guides/android_uat.md`, `release-please-config.json`, `phase68_android_uat_test.exs`, `native_evidence_drift_test.exs`

**Doc** (D-21, D-22): delete L3 (`**Last verified against:** ... <!-- x-release-please-version -->`); remove four phantom bullets (L51 `account_management`, L52 `diagnostic_export`, L55 `companion_snapshot`, L56 `location_capture`). The 15 remaining families were confirmed against `Crosswake.SupportMatrix.canonical().capability_families` during this mapping: `app_info, deep_link, document_scan, entitlement_snapshot, file_picker, haptics, media_capture, notification_token, paywall_entry, permissions.status, purchase_intent, reconciliation_evidence, restore_intent, scanner, share`.

**Config:** delete the object at `release-please-config.json` L53-56 (`{"type":"generic","path":"guides/android_uat.md"}`). `test/crosswake/planning/release_please_config_test.exs` L10-38 does not mention `android_uat`, so the removal is safe, but keep the JSON valid (the entry sits between the `README.md` generic entry and `examples/android_shell_host/app/build.gradle`).

**Existing weak test to replace** (`phase68_android_uat_test.exs`, whole file, 20 lines): a `for` over families with `String.contains?(content, family)` anywhere in the file, so a phantom or a missing family cannot be detected and an empty list passes. Replace by a two-way set-equality test:
```elixir
capability_families =
  SupportMatrix.canonical().capability_families |> Enum.map(& &1.family) |> Enum.uniq()
```
(keep this derivation, L9-12) against the set of backticked bullets under the families heading only (`~r/^- `([a-z_.]+)`$/m` over the slice after the retitled "Capability families (registry mirror)" heading and before `## Boundary`). Add `assert listed != []`, and a control that adds one phantom and removes one real family and requires both to be reported.

**native_evidence_drift_test.exs edits (D-23):**
- L546-547 required terms: `["guides/android_uat.md"] -> [current_version(), "Android 15 (API 35)", "What This Proves", "Boundary"]` must drop `current_version()` and `"Android 15 (API 35)"` (the stamp is gone).
- L94-107 "synthetic regressions fail on stale Android UAT version wording and overclaims": the first half does `String.replace(current_android_uat, "Crosswake v#{current_version()}", "Crosswake v0.1.0")`. With the stamp removed that replace is a no-op, which is exactly the defect `script/check_absence_is_not_success.exs` guards (the `@mutation_hint` text). Replace the stale-version half with a control that re-adds a `Last verified against` stamp and asserts it is flagged (new rule), or delete it with a recorded reason; keep the `device_support_overclaim` half (L109-117) unchanged.
- L731-734 `stale_version_category("guides/android_uat.md")` and the `0.1.0` line rule can stay.

**D-24 grep evidence** (`frozen` over README, `guides/support_matrix.md`, `guides/native_shell.md` returned 0 hits when checked for this map) is evidence-only. Re-run it in the phase evidence; `194-EVIDENCE/sc4-grep-194.sh` is the Phase 194 version (`.planning/.../194-bearings-reset-and-adr-amendments/scripts/sc4-grep-194.sh`).

---

### new `script/docs-report` + `script/docs_report.exs` (script, batch + subprocess)

**Launcher analog, copy exactly** (`script/bearings-report`, 6 lines, mode 755):
```bash
#!/usr/bin/env bash
# Bearings report launcher: runs script/bearings_report.exs from the repo root.
# exit contract: 0 OK / 1 ATTENTION / 2 UNVERIFIED (not a required check)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
exec elixir "$ROOT_DIR/script/bearings_report.exs" "$@"
```
Change the comment to the D-15 contract: exit 0 = ran, exit 2 = UNVERIFIED, never 1.

**Report script shape** (`script/bearings_report.exs`):
- Header states the absence rule (L3-5): a read that failed or returned nothing is UNVERIFIED, never OK; not a required check and referenced by no workflow.
- CLI: `OptionParser.parse(argv, strict: [...])` with a `--root` that `File.cd`s (L19-20, L52-53). Reuse `--root` so ExUnit fixture dirs (D-20) work.
- Single external-read seam returning fixed reason atoms, never stderr text (L55-64); library-mode gate so tests can load the module without running (L667-668: `unless Process.get(:crosswake_bearings_report_library), do: System.halt(...)`).
- Result lines carry fixed strings; `render/1` converts an empty result to UNVERIFIED (L509-525):
```elixir
lines = if lines == [], do: [unverified("report", "no checks produced output")], else: lines
```
- Dependency-injected `deps` map (`run`, `read`, `list`) at L31-36 is what makes the checks testable without network; copy it for `mix docs`.

**Subprocess + `--root` + typed refusal analog:** `script/check_compile_structure.exs` L1-60 (`OptionParser strict: [root: :string, mode: :string]`, `require!` throwing `{:compile_structure, reason}`, a rescue that prints only a fixed `refused=operational_failure`). Use the same "fixed reason, never exception data" discipline for `docs.*` UNVERIFIED lines.

**Required output** (D-15), exactly: `docs.warnings total=<n> extras=<n>`, `docs.links broken=<n> checked=<n> files=<n>`, `docs.leaks hits=<n> allowlisted=<n> stale_allowlist=<n> files=<n>`, `docs-report: REPORT-ONLY (not a required check)`. Scan scope: the `extras:` list in `mix.exs` L124-156 (31 entries, includes `LICENSE` which has no `.md`, and `CHANGELOG.md`). Parse it from `mix.exs` rather than hard-coding, and treat a floor below the extras count as UNVERIFIED (D-20).

**`mix docs`:** the only existing invocation is `.github/workflows/crosswake-ci.yml` L423-427 (`MIX_ENV: dev`, `mix docs`, `test -f doc/index.html`); `ex_doc` is `only: :dev` (`mix.exs` L58, locked 0.40.3). Follow it: run in dev, count lines starting `warning:`, treat a missing `doc/index.html` or non-zero exit as UNVERIFIED (D-16). Do not add `--warnings-as-errors` and do not add this script to any workflow.

**Allowlist file:** new `script/docs_leak_allowlist.json`, keyed by file plus normalized text with a reason, starting empty. Only the `schema_version` + list-of-records style of `script/ci_docs_allowlist.json` is worth borrowing; that file is a CI path classifier consumed by `script/classify_ci_change.py` and `phase165_*` tests and must not be reused or edited.

**Leak patterns** (D-18, case-sensitive): `Phase [0-9]+`, `TODO-[0-9]+`, `D-[0-9]{2}`, `SEED-[0-9]+`, milestone labels `v1x/v2x(.N)` excluding real semver. For the semver exclusion the scanner can reuse the idea in `check_release_doc_version_literals.exs` L97 (`\b\d+\.\d+\.\d+\b`) to blank real versions first.

---

### new `test/crosswake/docs_report_test.exs` (test, batch fixture dirs)

**Library-mode setup, copy** (`bearings_report_test.exs` L17-30):
```elixir
setup_all do
  Process.put(:crosswake_bearings_report_library, true)
  unless Code.ensure_loaded?(Crosswake.BearingsReport) do
    Code.require_file(Path.join(@repo_root, "script/bearings_report.exs"))
  end
  :ok
end
```
(rename the process key and module.) **Launcher test, copy** (L208-211): `System.cmd(@launcher, ["--help"], stderr_to_stdout: true)` asserts exit 0 and the usage line.

**Fixture dirs, copy** (`rescue_boundary_ratchet_test.exs` L269-307): `@tag :tmp_dir` with `%{tmp_dir: root}`, `put(root, file, bytes)` helper, `run(root, args)` shelling `System.cmd("elixir", [@script, "--root", root] ...)` and parsing the report lines. Assert exact counts for a known warning, broken link and leak fixture; allowlist an entry and assert `hits=0 allowlisted=1`; mutate the entry and assert hits return (and the mutation changed the entry); empty input, a scan floor below the extras count, or an unreadable file must exit 2 with `UNVERIFIED`; no path may exit 1.

**Bearings convention to follow:** every check has a positive case and a negative control that asserts the specific line text, so a report that failed for another reason cannot pass (moduledoc, L2-7; unmapped keys return an error so a forgotten case turns UNVERIFIED, L52-55).

---

### Evidence artifacts: `197-DOCS-REPORT.md`, `197-EVIDENCE/*-197.txt`

Naming and content analog: `195-EVIDENCE/cleanroom-0.2.11-195.txt` (real PASS run, retained verbatim) and `cleanroom-negative-195.txt` (blocks of `control: <name>`, command output, `control: rc <n>`). D-19 ordering is mandatory: record the baseline `script/docs-report` counts on current `main` BEFORE any doc edit in this phase, then re-record after, both in `197-DOCS-REPORT.md` with the main SHA and the ex_doc version (0.40.3 locked). D-12: one `mix crosswake.release.status --live` capture (the command is documented in README L151; implementation `lib/crosswake/release_status.ex` L1362 probes `hex.pm/api/packages/<pkg>/releases/<version>`).

---

## Shared Patterns

### Absence is not success (applies to EVERY new or changed test)
**Source:** `script/check_absence_is_not_success.exs` (delta-only guard; baseline `script/fixtures/absence_collection_baseline.exs`) and the working example in `test/crosswake/proof/phase171_no_bare_version_literal_test.exs` L100-137.
**Apply to:** the marker test, phase132 change, phase68 rewrite, native_evidence_drift change, CHANGELOG test, docs_report_test, and any `for`-over-glob.
A mutation-based control must assert that the mutation changed something, and a `for`/glob must have a cardinality or non-empty floor:
```elixir
mutated = String.replace(block, expected, "needs.release-please.outputs.version == '#{version}'")
if mutated == block do
  raise "mutate_job_to_bare_literal/3 produced an IDENTICAL block ... the control would assert nothing"
end
```
`script/fixtures/absence_collection_baseline.exs` lists existing offenders (including `bearings_report_test.exs` "no workflow references the report"); new tests must be clean, not added there.

### Exit-code and UNVERIFIED discipline
**Source:** `script/bearings_report.exs` L12 (0/1/2, UNVERIFIED wins), `script/check_release_doc_version_literals.exs` L2 and L62-85 (0 clean / 1 defect / 3 could not verify, missing roster file is "could not verify" not "clean", roster declared and never derived), `script/verify_published_cleanroom.sh` L17-19.
**Apply to:** `docs_report.exs` (never exit 1), the `docs` leg (missing tool is `tool_unavailable`, never a skip).

### Measure before merge-blocking (D-25)
Merge-blocking in this phase: marker test, CHANGELOG wording test, phase132 change, Android set-equality test (each lands with 0 findings by construction). Report-only for one cycle: the three docs-report counters. `docs-report` must not be referenced by any `.github/workflows/*` file (bearings convention: `bearings_report_test.exs` has a "no workflow references the report" test; mirror it).

### Never pin a false literal
`phase132` pinned `crosswake_rindle` as `"unpublished"` while hex.pm has 0.1.0. Anything asserting versions must read the source of truth (`mix.exs`, `.release-please-manifest.json`) or assert absence of literals, never copy a number. `.release-please-manifest.json` is bot-owned: no test may require a guide to equal it (D-10 rationale).

### Section slicing, tmp dirs, process isolation
`section_between/3` (`architecture_code_walkthrough_test.exs` L261), `section!/2` (`hex_page_test.exs` L228), `@tag :tmp_dir` (`rescue_boundary_ratchet_test.exs`), `System.unique_integer` tmp roots with `on_exit(fn -> File.rm_rf!(root) end)` (`published_cleanroom_test.exs` L29-35). Scripts under `System.cmd` are `async: false` where they share env (`published_cleanroom_test.exs` L16).

### Privacy
**Source:** `AGENTS.md` Sensitive Data Rules. Public docs and allowlist reasons say "first adopter" only. Leak-scan allowlist reasons and evidence files must not name or hint at the real adopter. Run the privacy scan before each push; the invocation is recorded in memory (`privacy-193.sh` with absolute paths as separate zsh args).

### Test ownership
`script/check_exunit_ownership.exs` requires every `test/**/*_test.exs` to belong to a merge-blocking class; new files in `test/crosswake/**` untagged are owned by the default hermetic lane. Do not tag the new tests `:requires_example_host` or `:advisory_only`, and keep them network-free (the real-registry run is phase evidence, not `mix test`).

## No Analog Found

| File / function | Role | Data Flow | Reason |
|---|---|---|---|
| ex_doc `warning:` line counter with `extras=` split | utility | transform | Only a smoke `mix docs` + `test -f` exists in CI; nothing parses warnings. Use the D-16 rule (location line names an extras file); verify the real output format on ex_doc 0.40.3 before writing the parser. |
| GitHub-slug heading to anchor resolution | utility | transform | No slug code in `script/`, `lib/` or tests (greps for slug/anchor found only data fields like `docs_anchor`). Plain regex per D-17; record ExDoc-vs-GitHub slug differences in `197-DOCS-REPORT.md`. |
| Marker-aware step runner (`run`/`apply`/`clone`/`show`, substitution table) | utility | batch | No doc-driven executor exists. Only the fence state machine (`strip_fences/1`) is reusable. Keep it dependency-free bash/awk inside the `docs` leg per D-01. |
| Pinned-`phx_new` host with assets enabled | script | batch | `verify_companion_cleanroom.sh` always passes `--no-assets`; the docs leg must not. Closest is L287-291 and L558-560 above. |

## Metadata

**Analog search scope:** `script/`, `test/crosswake/{release,guides,proof,planning}/`, `test/crosswake/*.exs`, `lib/crosswake/{telemetry,release_status,doctor/publish_readiness,planning/closeout_verifier,support_matrix}`, `.github/workflows/crosswake-ci.yml`, root docs and `guides/`, `release-please-config.json`, `.release-please-manifest.json`, phase 194/195 evidence directories.
**Files scanned:** about 60 read or grep-inspected (large reads: `verify_published_cleanroom.sh`, `bearings_report.exs` lines 1-260 and 509-668, `phase132` test, `native_evidence_drift_test.exs` selected ranges).
**Pattern extraction date:** 2026-10-29
