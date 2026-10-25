---
phase: 187-doctor-and-proof-fidelity
reviewed: 2026-10-16T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - CHANGELOG.md
  - guides/install.md
  - guides/offline.md
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/provenance.ex
  - lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex
  - script/collection_assertion_ledger.json
  - script/verify_loopback_origin_simulator.sh
  - test/crosswake/doctor/doctor_fidelity_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/loopback_origin_harness_test.exs
  - test/crosswake/proof_lane/provenance_test.exs
  - test/mix/tasks/crosswake_doctor_test.exs
  - test/mix/tasks/crosswake_proof_lane_verify_navigation_shell_test.exs
  - test/support/router_fixtures.ex
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 187: Code Review Report

**Reviewed:** 2026-10-16
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

Reviewed commit a53fbef (parent bd29400) in the candidate checkout, by diff and file reads. Nothing was executed.

## Summary

The core fail-closed machinery holds up:
- The sentinel path in `evidence.ex` is exact-match only.
- The all-zero commit check runs in `git_ref/1`, which `decode_evidence` re-runs through `validate_fields`. `check/1` and `scan_stage/1` therefore refuse stored all-zero evidence.
- `provenance_known?/1` gates both `valid_physical_fields` and `promotion_class`.
- The doctor precedence is `incomplete > not_claimed > supported`, and the incoherent-island scan runs before the contract filter.
- The shell `--evidence` parsing is correct.

Four warnings remain where a value is silently presented as "known" or a check does not reach the case it names. No privacy leak of home paths or usernames was found. The router module name and route paths do reach doctor JSON; that is documented in `guides/install.md`.

## Warnings

### WR-01: Malformed or absent host shell manifest silently becomes a "known" template version

**File:** `lib/crosswake/proof_lane/provenance.ex:41-58`
**Issue:** `template_version/1` falls back to the generator constant for every failure of the host manifest read. That includes a missing file, invalid JSON, a wrong type, and an out-of-range value. The result is a concrete decimal string such as `"161"`, and `provenance_known?/1` treats it as known. The value is the generator's current version, not the host's. A host with a corrupt or stale `shell.json`, or with no generated shell at all, therefore produces provenance that claims a specific template version it never had. `"unknown"` is only reachable when the generator itself returns garbage. That is a silent degradation: the sentinel exists for exactly this case.
**Fix:** Distinguish "no manifest" from "manifest unreadable or invalid". Return `"unknown"` for the invalid case. Keep the generator fallback only if the plan explicitly allows it for an absent file, and then say so in the changelog and the tests.
```elixir
case File.read(path) do
  {:error, :enoent} -> generator_template_version()
  {:ok, bytes} ->
    case Jason.decode(bytes) do
      {:ok, %{"template_version" => n}} when is_integer(n) and n in 1..99_999_999 -> Integer.to_string(n)
      _ -> "unknown"
    end
  _ -> "unknown"
end
```
The test "absent, malformed or out-of-range manifest falls back to the generator" (`provenance_test.exs`) currently asserts the silent behavior and must change with it.

### WR-02: `commit_ref/1` can report an enclosing repository's HEAD, and its git env scrub is incomplete

**File:** `lib/crosswake/proof_lane/provenance.ex:86`
**Issue:**
- Only `GIT_DIR`, `GIT_WORK_TREE` and `GIT_INDEX_FILE` are unset. `GIT_COMMON_DIR`, `GIT_OBJECT_DIRECTORY`, `GIT_ALTERNATE_OBJECT_DIRECTORIES`, `GIT_NAMESPACE`, `GIT_CEILING_DIRECTORIES`, `GIT_CONFIG_*` and `GIT_DISCOVERY_ACROSS_FILESYSTEM` are inherited. Hook or CI environments set some of these.
- `git rev-parse HEAD` with `cd: cwd` walks upward. If the host directory has no `.git` of its own, for example an exported tree or a vendored host inside a monorepo, the commit and clean-tree status of the parent repository are recorded as the host's commit. The repo comment says "a HEAD that does not describe the verified code looks real but is wrong". The no-`.git` test (`provenance_test.exs`) passes only because the system tmp dir happens not to sit inside a repository.
**Fix:** After `rev-parse HEAD`, require `git rev-parse --show-toplevel` to equal the canonicalized `cwd`; otherwise return `git-unknown`. Scrub the full `GIT_*` set, or run with `env -i`-style minimal env plus `GIT_CONFIG_NOSYSTEM=1`. Add a test with a host dir nested in a repo and no `.git` of its own.

### WR-03: Offline coherence still silently passes a `cached_read_only` route with no `cache_contract`

**File:** `lib/crosswake/doctor/doctor.ex:487-512`
**Issue:** The incoherent scan is added only for `offline_island` plus `local_first` plus no `island_contract`. `offline_routes` still filters out any route with neither contract, so a `cached_read_only` route with `cache_contract == nil` never reaches the `coherent?` case clause. That clause (`route.cache_contract and ...`) is unreachable for that shape. `claims_offline?` is true for it (`offline != :unavailable`), so the status becomes `:supported` and `offline_posture_ready` is emitted. The new comment says the filter "drops exactly the routes this check exists to catch", but only one of the two incoherent shapes is fixed. This is the same absence-scored-as-success pattern. It is possible only if the compiler lets such a route through; I did not confirm whether it rejects it earlier. If it does reject it, the dead clause and the claim in the comment are misleading.
**Fix:** Generalize `incoherent_ids` to every route with `offline != :unavailable` whose contract set does not match its declared mode. Alternatively, add a test showing the compiler rejects the other shape and document that reliance.

### WR-04: `Evidence.provenance_known?/1` is a public gate that validates nothing beyond the two sentinels

**File:** `lib/crosswake/proof_lane/evidence.ex:75-82`
**Issue:** It returns true for any binary that is not the sentinel. That includes `"git-000...0"`, `"x"` and `""`. It is correct only because every current call site runs it after `validate_fields`. `promotion_class/2` takes `evidence.device_class` and `evidence.commit_ref` from the struct. A struct built directly (the test does `%{evidence | commit_ref: ...}`) skips validation. A future caller using the helper as a standalone "is this real provenance" check gets a false positive.
**Fix:** Make `known?/2` apply the same format predicate as the validators (the commit hex pattern and not all-zero, semver, decimal). Alternatively, mark the function `@doc false` and document the precondition.

## Info

### IN-01: Test code that is vacuous or obfuscated

**File:** `test/crosswake/proof_lane/provenance_test.exs:100-104`
**Issue:** `then(&(&1 <> String.slice(other, 0, 0)))` appends an empty string and is a no-op. It also shadows `other` confusingly. Several `assert length(list) == N` lines exist only to dodge the collection-assertion scanner (`for` over a literal list). They add noise, not coverage.
**Fix:** Delete the no-op pipe. Keep the cardinality asserts only where the scanner requires them.

### IN-02: Ledger entries re-keyed by hand-edited line numbers

**File:** `script/collection_assertion_ledger.json:179,222-225`
**Issue:** Display line numbers and the "line 385" rationale text were hand-shifted after the test files grew. They go stale on the next edit above those lines. The stable `key` fields are unchanged, so the gate still matches.
**Fix:** Regenerate the ledger with the remediation script rather than editing it.

### IN-03: Doctor JSON now exposes the host router module name and all unmanaged paths

**File:** `lib/crosswake/doctor/doctor.ex:388-392`
**Issue:** This is documented for paths. The router module name (`Host.Router`) is a likely adopter-identifying string, and it now lands in doctor JSON and the human formatter. The rule says doctor output must not carry adopter identifiers. The install-guide warning covers pasting into issues but not the retained proof artifacts.
**Fix:** Confirm doctor JSON is never retained in proof artifacts. Otherwise emit only a short hash of the module name, or omit `router` when it is not needed.

---

_Reviewed: 2026-10-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
