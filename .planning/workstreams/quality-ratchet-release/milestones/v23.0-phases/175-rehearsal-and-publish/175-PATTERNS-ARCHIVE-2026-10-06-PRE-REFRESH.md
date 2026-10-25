# Phase 175: Rehearsal and Publish - Pattern Map

**Mapped:** 2026-10-04
**Scope:** D-103 local follow-up to validate/track the candidate receipt artifact helper and rerun only blocked local verification.
**Files analyzed:** 9
**Analogs found:** 9 / 9

This map supports planning only. Source inspection, a readable helper, scanner string checks, and test declarations are not execution proof. Do not promote REL-17 workflow or final-guard claims until the named local scanner/tests execute successfully. Keep unsupported matrix cells `UNKNOWN`; do not expand into publisher workflow or final guard edits without a named failing assertion. No provider/remote access, CI, or release authority is in scope.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `script/release_candidate/assert_candidate_receipt_artifact.sh` (existing untracked candidate; track unchanged only if contract-matched) | utility / shell guard | file-I/O | `script/guarded_hex_publish.sh` (shell guard conventions); exact behavior contract in `test/crosswake/proof/phase175_release_recovery_test.exs` | role-match |
| `script/check_release_workflow_integrity.exs` (read/execute; no source edit planned) | utility / structural scanner | file-I/O, transform | `test/crosswake/release_candidate/workflow_test.exs` | role-match |
| `test/crosswake/proof/phase175_release_recovery_test.exs` (run existing cases) | test | file-I/O | self; exact roster and rejection suite | exact |
| `test/crosswake/release_candidate/workflow_test.exs` (scanner-dependent test in requested suite) | test | transform | self; Maven receipt consumer ordering | exact |
| `test/crosswake/proof/phase175_rel17_publish_paths_test.exs` | test | request-response / transform | `test/crosswake/proof/phase175_rel17_wiring_test.exs` | role-match |
| `test/crosswake/proof/phase175_rel17_recovery_paths_test.exs` | test | request-response / transform | `test/crosswake/proof/phase175_rel17_publish_paths_test.exs` | role-match |
| `test/crosswake/proof/phase175_rel17_wiring_test.exs` | test | transform | self; named scanner checks and mutation fixtures | exact |
| `test/crosswake/proof/phase175_rel17_condition_paths_test.exs` | test | request-response, file-I/O | self; sanitization and matrix assertions | exact |
| `test/crosswake/release_candidate/evidence_live_test.exs` | test | request-response | self; injected fetch function and fixture-backed live evidence | exact |
| `.planning/WINDOWS.md` entry 36 | planning ledger | transform | existing open-entry row format | role-match |
| `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-78-REL17-PATH-MATRIX.md` | evidence artifact | transform | same matrix and its `@tag :matrix` test in `test/crosswake/proof/phase175_rel17_condition_paths_test.exs` | exact |

## Pattern Assignments

### `script/release_candidate/assert_candidate_receipt_artifact.sh` (utility, file-I/O)

**Candidate:** Existing untracked file; `git ls-files` does not recognize it. Treat as a proposed tracked source file only after review. If it matches the stated contract, track the exact bytes without behavior changes. Do not infer runtime validity from presence or scanner readability.

**Helper pattern** (`script/release_candidate/assert_candidate_receipt_artifact.sh`, lines 1-21):

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: assert_candidate_receipt_artifact.sh RECEIPT_DIR" >&2
  exit 2
fi

python3 - "$1" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
expected = {"artifacts.json", "candidate-receipt.json", "candidate-receipt.md"}
entries = list(root.iterdir())
actual = {entry.name for entry in entries}
valid = actual == expected and all(entry.is_file() and not entry.is_symlink() for entry in entries)
if not valid:
    print("candidate receipt artifact has an unexpected file roster", file=sys.stderr)
    raise SystemExit(1)
PY
```

This enforces one directory argument, exact shallow top-level names, regular files, and no symlinks. It does not validate file contents, digest, provenance, or release authority; the workflow performs separate checks for those.

**Caller order pattern** (`.github/workflows/release-please.yml`, lines 952-971): download the uniquely selected artifact, invoke the helper, then calculate/compare digest and validate receipt fields. The later setup/credential and publication sequence follows. This is source structure only; this task must not edit the workflow.

```bash
gh run download "$RECEIPT_RUN_ID" --repo "$GITHUB_REPOSITORY" \
  --name "$artifact_name" --dir "$receipt_dir"
bash script/release_candidate/assert_candidate_receipt_artifact.sh "$receipt_dir"
receipt="$receipt_dir/candidate-receipt.json"
receipt_digest=$(sha256sum "$receipt" | awk '{print $1}')
[ "$receipt_digest" = "$APPROVED_RECEIPT" ]
```

### `test/crosswake/proof/phase175_release_recovery_test.exs` (test, file-I/O)

**Analog:** self; it is the direct executable behavior contract for the helper.

**Imports/setup and accepted/rejected behavior** (lines 1-61):

```elixir
@helper "script/release_candidate/assert_candidate_receipt_artifact.sh"
@expected ~w(artifacts.json candidate-receipt.json candidate-receipt.md)

test "accepts the exact canonical receipt artifact roster" do
  dir = temp_dir!()
  on_exit(fn -> File.rm_rf!(dir) end)
  write_roster!(dir, @expected)
  assert run_helper(dir) == 0
end

test "rejects an extra top-level receipt member" do
  # Build expected set plus unexpected.txt, then assert nonzero helper exit.
end

test "rejects nested receipt files" do
  # Add nested/extra.json and assert nonzero helper exit.
end

test "rejects a symlinked receipt member" do
  # Replace a roster member by a symlink and assert nonzero helper exit.
end
```

The same module also rejects a missing member. The helper is run with `System.cmd("bash", [@helper, dir], stderr_to_stdout: true)` and only its status is asserted. These are existing regression cases, not evidence they passed in this workspace.

### `script/check_release_workflow_integrity.exs` (utility, file-I/O / transform)

**Analog:** `test/crosswake/release_candidate/workflow_test.exs` for structural workflow checks and ordering assertions.

**Scanner dependency and receipt-order predicate** (`script/check_release_workflow_integrity.exs`, lines 1999-2043):

```elixir
defp android_ordinary_receipt_chain(jobs) do
  block = job_block(jobs, "publish-android-core")
  guard = job_block(jobs, "approved-release-guard")
  receipt_roster_guard =
    File.read!("script/release_candidate/assert_candidate_receipt_artifact.sh")

  download = index_of(block, "Download and validate the approved candidate receipt")
  credentials = index_of(block, "ORG_GRADLE_PROJECT_mavenCentralUsername")
  publish = index_of(block, "android_publication.sh")

  check(
    "release.android.ordinary_receipt_chain",
    download != nil and credentials != nil and publish != nil and
      download < credentials and download < publish and
      includes?(block, "bash script/release_candidate/assert_candidate_receipt_artifact.sh \"$receipt_dir\"") and
      includes?(receipt_roster_guard, "artifacts.json") and
      includes?(receipt_roster_guard, "candidate-receipt.json") and
      includes?(receipt_roster_guard, "candidate-receipt.md"),
    "publish-android-core must download and validate the exact guard-selected receipt before Maven credentials"
  )
end
```

The scanner reads source text and emits named checks. A successful scanner run can establish its structural predicates; it does not execute publisher final guards or prove release publication behavior.

### Scanner-dependent REL-17 test roster (test, transform / request-response)

The Plan78 suite uses ExUnit tests with fixture mutations and scanner output assertions. Keep those distinct from external action execution:

- `test/crosswake/proof/phase175_rel17_publish_paths_test.exs`: removes ordinary job gates and moves the Release Please gate to require named scanner failures; see lines 74-97.
- `test/crosswake/proof/phase175_rel17_recovery_paths_test.exs`: checks each recovery entry gate mutation; see lines 78-113.
- `test/crosswake/proof/phase175_rel17_wiring_test.exs`: requires all declared REL-17 IDs to emit `OK`, and mutations to iOS/Maven boundaries to emit named failures; see lines 11-38 and 118-140.
- `test/crosswake/proof/phase175_rel17_condition_paths_test.exs`: uses fixture-backed fake providers and checks state, row roster, evidence references, sanitization, and holds. `@tag :matrix` test begins at line 349. A matrix assertion proves only the checked local representation and linked test references.
- `test/crosswake/release_candidate/evidence_live_test.exs`: supplies a function-valued fake fetch seam and asserts captured evidence; lines 14-35 show repeated invocation and fixture isolation. This does not perform provider access in the focused follow-up.
- `test/crosswake/release_candidate/workflow_test.exs`: its Maven receipt consumer case checks helper placement before Java setup and Maven credentials at lines 95-115.

Do not alter these sources for the follow-up unless a separately authorized, named failure makes a change necessary. First rerun the exact existing tests and scanner specified by the approved execution plan; no commands were run for this pattern map.

### `.planning/WINDOWS.md` entry 36 (ledger, transform)

**Analog:** adjacent open ledger rows in the same table. Entry 36 is at line 53 in the current checkout and presently records the prior scanner blocker. Update only after the helper regression, scanner, and requested scanner-dependent suite have actually run; retain UNKNOWN for any claim not covered by passing assertions. Do not infer entry closure from source inspection.

### `175-78-REL17-PATH-MATRIX.md` (evidence artifact, transform)

**Analog:** same matrix plus `@tag :matrix` in `test/crosswake/proof/phase175_rel17_condition_paths_test.exs` (lines 349-385 onward).

The matrix records per-publisher condition states, assertion references, and required dispositions. Preserve its schema and hold lines. Update only workflow presence/order cells supported by successful named scanner checks and matching scanner mutation tests. Keep `final_guard_execution` UNKNOWN: the scanner and fixture tests inspect source/structural paths and the P1 fake sink is not execution of each real publication script. Matrix prose currently distinguishes a fake sink after the live shell gate from end-to-end Hex/iOS/Maven final-guard execution; preserve that distinction.

## Shared Patterns

### Exact receipt artifact boundary

**Sources:** `script/release_candidate/assert_candidate_receipt_artifact.sh:9-20`, `test/crosswake/proof/phase175_release_recovery_test.exs:4-50`, and `.github/workflows/release-please.yml:952-971`.

The helper owns shallow roster/name/type/symlink validation. The caller owns selected artifact identity, digest, receipt content and identity bindings, and placement before credentials/publication. Keep ownership separate and do not overstate the helper contract.

### Structural check versus runtime proof

**Sources:** `script/check_release_workflow_integrity.exs:1999-2043`, `test/crosswake/proof/phase175_rel17_wiring_test.exs:11-38`, and `175-78-REL17-PATH-MATRIX.md:66-80`.

The scanner and mutation tests establish source-level workflow presence/order only after their successful execution. They do not establish that remote workflows ran, credentials were used, or final publisher scripts executed. The matrix should retain UNKNOWN for unsupported runtime claims.

### Sanitized evidence and fail-closed status

**Source:** `test/crosswake/proof/phase175_rel17_condition_paths_test.exs:349-385` and matrix required dispositions at `175-78-REL17-PATH-MATRIX.md:96-116`.

Maintain exact publisher/condition rosters, allowed states, references, and hold lines. Evidence updates must be tied to a named passing assertion. Preserve REL-13/REL-17 OPEN, candidate readiness BLOCKED, merge policy UNKNOWN, release hold ACTIVE, held plans, and Phase 175 INCOMPLETE unless a separately authorized proof chain changes them.

## No Analog Found

None for the scoped follow-up. The helper’s exact implementation is intentionally paired with its dedicated regression tests; the structural scanner and matrix tests provide adjacent analogs for the documentation/verification files.

## Metadata

**Analog search scope:** receipt helper, release workflow scanner, Maven workflow caller, exact-roster tests, REL-17 scanner/matrix tests, Windows ledger, and Plan78 path matrix.
**Tracked-source gate:** verified with `git ls-files` for all named existing analogs; the candidate receipt helper is present but untracked, so it is labeled a candidate rather than a tracked analog.
**Execution:** read-only source review only; no tests, scanner, formatter, provider/remote access, or release commands were run.
