#!/usr/bin/env python3
"""Closed, exact-tree reconciliation proof for Phase 167 Plan 06 recovery."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import urllib.parse
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
BASE = "74fc15cc546b756c210b6cbbdcb2d7f77e3966bb"
BOUNDARY = "c63a40b25901bfce159e40bc37c0738dc6a1249c"
SOURCE = "fe205ba012d593f4b34cd945e0bb535069210baa"
PR145_HEAD = "a6e2622acaaa82e82eb33a21760e75db2e51a281"
PR145_MERGE = BASE
FULL_OID = re.compile(r"^[0-9a-f]{40}$")
MODES = {"100644", "100755", "120000", "160000"}
RUNTIME_PATHS = [
    ".planning/workstreams/quality-ratchet-release/config.json",
    ".planning/workstreams/quality-ratchet-release/milestone.lock",
    ".planning/workstreams/quality-ratchet-release/state.json",
]
OVERLAPS = [
    "docs/COMPANION-PUBLISH-RUNBOOK.md",
    "guides/companion_compatibility.md",
    "guides/install.md",
    "script/check_phase167_pr_dispositions.py",
    "test/crosswake/proof/phase142_release_integrity_test.exs",
]
TASK_PATHS = [
    "docs/COMPANION-PUBLISH-RUNBOOK.md",
    "guides/companion_compatibility.md",
    "guides/install.md",
    "packages/crosswake_rindle/README.md",
    "packages/crosswake_rindle/mix.exs",
    "packages/crosswake_rulestead/README.md",
    "packages/crosswake_rulestead/mix.exs",
    "script/check_phase167_pr_dispositions.py",
    "script/check_release_workflow_integrity.exs",
    "test/crosswake/proof/phase132_compat_matrix_drift_test.exs",
    "test/crosswake/proof/phase142_release_integrity_test.exs",
]
MANIFEST_FIELDS = {
    "schema_version", "base_oid", "boundary_oid", "source_local_oid",
    "base_tree_oid", "boundary_tree_oid", "source_tree_oid", "pr145",
    "runtime_paths", "transitions", "union", "overlaps",
}
TRANSITION_FIELDS = {"from_oid", "to_oid", "count", "records", "digest"}
RECORD_FIELDS = {"path", "from", "to"}
STAGE_FIELDS = {"mode", "blob"}
UNION_FIELDS = {"count", "paths", "digest"}
OVERLAP_FIELDS = {"path", "base", "boundary", "source"}
PR145_FIELDS = {"head_oid", "merge_oid", "status"}
RECEIPT_FIELDS = {
    "schema_version", "kind", "pr_number", "tested_head_oid", "tested_base_oid",
    "merge_commit_oid", "fresh_default_oid", "crosswake_ci", "intent_commit_count",
    "path_count", "expected_tree_oid", "pr145_head_oid", "pr145_merge_oid",
}
FORBIDDEN = ("http://", "https://", "bearer ", "ghp_", "raw_answer", "transcript", "stable_device", "founder_identity")


class ProofError(Exception):
    pass


def run(argv: list[str]) -> str:
    return subprocess.run(argv, cwd=ROOT, check=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True).stdout


def run_json(argv: list[str]) -> Any:
    return json.loads(run(argv))


def git(*args: str) -> str:
    return run(["git", *args])


def gh_json(*args: str) -> Any:
    return run_json(["gh", *args])


def repository_name() -> str:
    value = run(["gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner"]).strip()
    require(bool(value) and "/" in value, "repository_name")
    return value


def require(condition: bool, rule: str) -> None:
    if not condition:
        raise ProofError(rule)


def canonical(value: Any) -> bytes:
    return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True) + "\n").encode()


def digest(value: Any) -> str:
    return hashlib.sha256(canonical(value)).hexdigest()


def tree(commit: str) -> str:
    value = git("rev-parse", f"{commit}^{{tree}}").strip()
    require(FULL_OID.fullmatch(value) is not None, "tree_oid")
    return value


def paths(left: str, right: str) -> list[str]:
    raw = subprocess.run(
        ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "-z", left, right],
        cwd=ROOT, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    ).stdout
    decoded = raw.decode("utf-8")
    result = [] if not decoded else decoded.rstrip("\0").split("\0")
    require(result == sorted(result), "git_paths_unsorted")
    require(len(result) == len(set(result)), "git_paths_duplicate")
    return result


def stage(commit: str, path: str) -> dict[str, str | None]:
    raw = subprocess.run(["git", "ls-tree", "-z", commit, "--", path], cwd=ROOT,
                         check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout
    if not raw:
        return {"mode": None, "blob": None}
    require(raw.count(b"\0") == 1, "ls_tree_cardinality")
    meta, actual = raw[:-1].split(b"\t", 1)
    mode, kind, blob = meta.decode("ascii").split(" ")
    require(actual.decode("utf-8") == path, "ls_tree_path")
    require(mode in MODES and kind in {"blob", "commit"}, "stage_mode")
    require(FULL_OID.fullmatch(blob) is not None, "stage_blob")
    return {"mode": mode, "blob": blob}


def records(left: str, right: str) -> list[dict[str, Any]]:
    return [{"path": path, "from": stage(left, path), "to": stage(right, path)} for path in paths(left, right)]


def build_manifest() -> dict[str, Any]:
    a = records(BASE, BOUNDARY)
    b = records(BOUNDARY, SOURCE)
    union_paths = sorted({r["path"] for r in a} | {r["path"] for r in b})
    overlap_paths = sorted({r["path"] for r in a} & {r["path"] for r in b})
    overlaps = [
        {"path": path, "base": stage(BASE, path), "boundary": stage(BOUNDARY, path), "source": stage(SOURCE, path)}
        for path in overlap_paths
    ]
    return {
        "schema_version": 1,
        "base_oid": BASE,
        "boundary_oid": BOUNDARY,
        "source_local_oid": SOURCE,
        "base_tree_oid": tree(BASE),
        "boundary_tree_oid": tree(BOUNDARY),
        "source_tree_oid": tree(SOURCE),
        "pr145": {"head_oid": PR145_HEAD, "merge_oid": PR145_MERGE, "status": "merged"},
        "runtime_paths": RUNTIME_PATHS,
        "transitions": {
            "prerequisite": {"from_oid": BASE, "to_oid": BOUNDARY, "count": len(a), "records": a, "digest": digest(a)},
            "package": {"from_oid": BOUNDARY, "to_oid": SOURCE, "count": len(b), "records": b, "digest": digest(b)},
        },
        "union": {"count": len(union_paths), "paths": union_paths, "digest": digest(union_paths)},
        "overlaps": overlaps,
    }


def validate_stage(value: Any, rule: str) -> None:
    require(isinstance(value, dict) and set(value) == STAGE_FIELDS, f"{rule}_schema")
    mode, blob = value.get("mode"), value.get("blob")
    require((mode is None and blob is None) or (mode in MODES and isinstance(blob, str) and FULL_OID.fullmatch(blob)), rule)


def validate_manifest(value: Any) -> None:
    require(isinstance(value, dict) and set(value) == MANIFEST_FIELDS, "manifest_schema")
    require(value["schema_version"] == 1, "schema_version")
    for key, expected in (("base_oid", BASE), ("boundary_oid", BOUNDARY), ("source_local_oid", SOURCE)):
        require(value.get(key) == expected and FULL_OID.fullmatch(value[key]), key)
    require(value["base_tree_oid"] == tree(BASE), "base_tree")
    require(value["boundary_tree_oid"] == tree(BOUNDARY), "boundary_tree")
    require(value["source_tree_oid"] == tree(SOURCE), "source_tree")
    require(isinstance(value["pr145"], dict) and set(value["pr145"]) == PR145_FIELDS, "pr145_schema")
    require(value["pr145"] == {"head_oid": PR145_HEAD, "merge_oid": PR145_MERGE, "status": "merged"}, "pr145_facts")
    require(value["runtime_paths"] == RUNTIME_PATHS, "runtime_paths")
    require(isinstance(value["transitions"], dict) and set(value["transitions"]) == {"prerequisite", "package"}, "transitions_schema")
    expected_specs = {
        "prerequisite": (BASE, BOUNDARY, 232),
        "package": (BOUNDARY, SOURCE, 11),
    }
    observed_paths: dict[str, list[str]] = {}
    for name, (left, right, count) in expected_specs.items():
        item = value["transitions"][name]
        require(isinstance(item, dict) and set(item) == TRANSITION_FIELDS, f"{name}_schema")
        require(item["from_oid"] == left and item["to_oid"] == right and item["count"] == count, f"{name}_boundary")
        require(isinstance(item["records"], list) and len(item["records"]) == count, f"{name}_count")
        record_paths = []
        for record in item["records"]:
            require(isinstance(record, dict) and set(record) == RECORD_FIELDS, f"{name}_record_schema")
            require(isinstance(record["path"], str) and record["path"], f"{name}_path")
            validate_stage(record["from"], f"{name}_from")
            validate_stage(record["to"], f"{name}_to")
            record_paths.append(record["path"])
        require(record_paths == sorted(record_paths) and len(record_paths) == len(set(record_paths)), f"{name}_path_order")
        require(record_paths == paths(left, right), f"{name}_path_equality")
        require(item["records"] == records(left, right), f"{name}_stage_equality")
        require(item["digest"] == digest(item["records"]), f"{name}_digest")
        observed_paths[name] = record_paths
    require(observed_paths["package"] == TASK_PATHS, "package_paths")
    expected_union = sorted(set(observed_paths["prerequisite"]) | set(observed_paths["package"]))
    require(isinstance(value["union"], dict) and set(value["union"]) == UNION_FIELDS, "union_schema")
    require(value["union"]["count"] == 238 and value["union"]["paths"] == expected_union, "union_paths")
    require(value["union"]["digest"] == digest(expected_union), "union_digest")
    require(isinstance(value["overlaps"], list), "overlap_schema")
    require([item.get("path") for item in value["overlaps"] if isinstance(item, dict)] == OVERLAPS, "overlap_paths")
    for item in value["overlaps"]:
        require(isinstance(item, dict) and set(item) == OVERLAP_FIELDS, "overlap_record_schema")
        for key, commit in (("base", BASE), ("boundary", BOUNDARY), ("source", SOURCE)):
            validate_stage(item[key], f"overlap_{key}")
            require(item[key] == stage(commit, item["path"]), f"overlap_{key}_equality")
    serialized = canonical(value).decode("ascii").lower()
    require(not any(marker in serialized for marker in FORBIDDEN), "privacy_sentinel")


def repository_snapshot() -> tuple[str, str, str]:
    info = gh_json("repo", "view", "--json", "nameWithOwner,defaultBranchRef", "--jq",
                   "{repository:.nameWithOwner,branch:.defaultBranchRef.name}")
    endpoint = f"repos/{info['repository']}/branches/{urllib.parse.quote(info['branch'], safe='')}"
    authority = gh_json("api", "-H", "Accept: application/vnd.github+json", endpoint, "--jq", "{oid:.commit.sha}")
    return info["repository"], info["branch"], authority["oid"]


def pr_snapshot(number: int) -> dict[str, Any]:
    snapshot = gh_json("pr", "view", str(number), "--json",
                       "number,state,headRefOid,baseRefOid,mergeCommit,commits",
                       "--jq", "{number:.number,state:.state,head_oid:.headRefOid,base_oid:.baseRefOid,merge_oid:(.mergeCommit.oid // null),commit_count:(.commits|length)}")
    endpoint = f"repos/{repository_name()}/pulls/{number}/files?per_page=100"
    output = run(["gh", "api", "--paginate", "-H", "Accept: application/vnd.github+json", endpoint,
                  "--jq", ".[].filename"])
    snapshot["paths"] = sorted(line for line in output.splitlines() if line)
    return snapshot


def verify_pr(manifest: dict[str, Any], number: int, kind: str) -> dict[str, Any]:
    validate_manifest(manifest)
    snap = pr_snapshot(number)
    require(snap["number"] == number and snap["state"] in {"OPEN", "MERGED"}, "pr_state")
    require(FULL_OID.fullmatch(snap["head_oid"]) is not None and FULL_OID.fullmatch(snap["base_oid"]) is not None, "pr_oid")
    transition = manifest["transitions"][kind]
    expected_paths = [r["path"] for r in transition["records"]]
    require(snap["paths"] == expected_paths, "pr_scope")
    require(snap["commit_count"] == 1, "pr_commit_count")
    require(git("rev-parse", f"{snap['head_oid']}^{{tree}}").strip() == manifest[f"{'boundary' if kind == 'prerequisite' else 'source'}_tree_oid"], "pr_head_tree")
    require(git("rev-parse", f"{snap['base_oid']}^{{tree}}").strip() == manifest[f"{'base' if kind == 'prerequisite' else 'boundary'}_tree_oid"], "pr_base_tree")
    require(git("rev-parse", f"{snap['head_oid']}^").strip() == snap["base_oid"], "pr_parent")
    if kind == "prerequisite":
        require(snap["base_oid"] == BASE, "prerequisite_base")
    return snap


def check_snapshot(repository: str, head: str) -> dict[str, Any] | None:
    endpoint = f"repos/{repository}/commits/{head}/check-runs?filter=latest&per_page=100"
    return gh_json("api", "-H", "Accept: application/vnd.github+json", endpoint, "--jq",
                   '[.check_runs[]|select(.name=="Crosswake CI")|{name:.name,head_oid:.head_sha,status:(.status|ascii_upcase),conclusion:((.conclusion//"")|ascii_upcase)}]|first')


def reachable(repository: str, merge_oid: str, default_oid: str) -> bool:
    value = gh_json("api", "-H", "Accept: application/vnd.github+json",
                    f"repos/{repository}/compare/{merge_oid}...{default_oid}", "--jq", "{status:.status,behind_by:.behind_by}")
    return value.get("status") in {"ahead", "identical"} and value.get("behind_by") == 0


def validate_receipt(receipt: Any, live: bool) -> None:
    require(isinstance(receipt, dict) and set(receipt) == RECEIPT_FIELDS, "receipt_schema")
    require(receipt["schema_version"] == 1 and receipt["kind"] in {"prerequisite", "package"}, "receipt_kind")
    for key in ("tested_head_oid", "tested_base_oid", "merge_commit_oid", "fresh_default_oid", "expected_tree_oid", "pr145_head_oid", "pr145_merge_oid"):
        require(isinstance(receipt[key], str) and FULL_OID.fullmatch(receipt[key]), f"{key}_format")
    require(receipt["pr145_head_oid"] == PR145_HEAD and receipt["pr145_merge_oid"] == PR145_MERGE, "receipt_pr145")
    require(receipt["crosswake_ci"] == "SUCCESS" and receipt["intent_commit_count"] == 1, "receipt_ci_or_commits")
    require(receipt["path_count"] == (232 if receipt["kind"] == "prerequisite" else 11), "receipt_path_count")
    require(receipt["expected_tree_oid"] == tree(BOUNDARY if receipt["kind"] == "prerequisite" else SOURCE), "receipt_tree")
    require(canonical(receipt).decode("ascii").lower().find("https://") == -1, "receipt_privacy")
    if not live:
        return
    repository, _branch, default_oid = repository_snapshot()
    snap = pr_snapshot(receipt["pr_number"])
    require(snap["state"] == "MERGED", "receipt_pr_not_merged")
    require(snap["head_oid"] == receipt["tested_head_oid"] and snap["base_oid"] == receipt["tested_base_oid"], "receipt_head_base")
    require(snap["merge_oid"] == receipt["merge_commit_oid"] and snap["commit_count"] == 1, "receipt_merge")
    check = check_snapshot(repository, receipt["tested_head_oid"])
    require(isinstance(check, dict) and check.get("name") == "Crosswake CI" and check.get("head_oid") == receipt["tested_head_oid"] and check.get("status") == "COMPLETED" and check.get("conclusion") == "SUCCESS", "receipt_ci")
    require(default_oid == receipt["fresh_default_oid"] and reachable(repository, receipt["merge_commit_oid"], default_oid), "receipt_default")
    require(tree(receipt["merge_commit_oid"]) == receipt["expected_tree_oid"], "receipt_merge_tree")


def self_test() -> int:
    valid = build_manifest()
    validate_manifest(valid)
    fixtures: list[tuple[str, Any]] = []
    fixtures.append(("abbreviated_oid", {**valid, "base_oid": BASE[:12]}))
    fixtures.append(("wrong_boundary", {**valid, "boundary_oid": SOURCE}))
    fixtures.append(("unknown_key", {**valid, "remote_title": "x"}))
    fixtures.append(("runtime_path", {**valid, "runtime_paths": RUNTIME_PATHS + ["x"]}))
    fixtures.append(("pr145", {**valid, "pr145": {**valid["pr145"], "head_oid": SOURCE}}))
    for name in ("prerequisite", "package"):
        transition = valid["transitions"][name]
        fixtures.append((f"{name}_missing", {**valid, "transitions": {**valid["transitions"], name: {**transition, "records": transition["records"][:-1]}}}))
        fixtures.append((f"{name}_duplicate", {**valid, "transitions": {**valid["transitions"], name: {**transition, "records": transition["records"] + transition["records"][-1:]}}}))
        fixtures.append((f"{name}_unsorted", {**valid, "transitions": {**valid["transitions"], name: {**transition, "records": list(reversed(transition["records"]))}}}))
        bad_record = {**transition["records"][0], "to": {"mode": "100600", "blob": transition["records"][0]["to"]["blob"]}}
        fixtures.append((f"{name}_mode", {**valid, "transitions": {**valid["transitions"], name: {**transition, "records": [bad_record] + transition["records"][1:]}}}))
        drift_record = {**transition["records"][0], "to": {**transition["records"][0]["to"], "blob": "a" * 40}}
        fixtures.append((f"{name}_blob", {**valid, "transitions": {**valid["transitions"], name: {**transition, "records": [drift_record] + transition["records"][1:]}}}))
    fixtures.append(("union_omission", {**valid, "union": {**valid["union"], "paths": valid["union"]["paths"][:-1]}}))
    fixtures.append(("overlap", {**valid, "overlaps": valid["overlaps"][:-1]}))
    fixtures.append(("privacy", {**valid, "runtime_paths": [*RUNTIME_PATHS[:-1], "https://invalid.example"]}))
    for name, fixture in fixtures:
        try:
            validate_manifest(fixture)
        except ProofError:
            continue
        print(f"phase167-default-reconciliation-self-test: FAIL fixture={name}")
        return 1
    print(f"phase167-default-reconciliation-self-test: PASS count={len(fixtures) + 1}")
    return 0


def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(value, dict), "json_object")
    return value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--capture", action="store_true")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--verify", type=Path)
    parser.add_argument("--verify-pr", type=Path)
    parser.add_argument("--pr", type=int)
    parser.add_argument("--expected-kind", choices=("prerequisite", "package"))
    parser.add_argument("--verify-resolution", type=Path)
    parser.add_argument("--live", action="store_true")
    args = parser.parse_args()
    try:
        if args.self_test:
            return self_test()
        if args.capture:
            require(args.output is not None, "capture_output")
            value = build_manifest()
            validate_manifest(value)
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_bytes(json.dumps(value, indent=2, sort_keys=True).encode() + b"\n")
            print("phase167-default-reconciliation: CAPTURED")
            return 0
        if args.verify is not None:
            validate_manifest(load(args.verify))
            print("phase167-default-reconciliation: PASS manifest")
            return 0
        if args.verify_pr is not None:
            require(args.pr is not None and args.expected_kind is not None, "verify_pr_args")
            verify_pr(load(args.verify_pr), args.pr, args.expected_kind)
            print(f"phase167-default-reconciliation: PASS pr={args.pr} kind={args.expected_kind}")
            return 0
        if args.verify_resolution is not None:
            require(args.live, "resolution_requires_live")
            validate_receipt(load(args.verify_resolution), True)
            print("phase167-default-reconciliation: PASS resolution")
            return 0
        parser.error("select one mode")
    except (ProofError, OSError, UnicodeDecodeError, json.JSONDecodeError, KeyError, TypeError, subprocess.CalledProcessError) as error:
        rule = str(error) if isinstance(error, ProofError) else "closed_failure"
        print(f"phase167-default-reconciliation: FAIL rule={rule}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
