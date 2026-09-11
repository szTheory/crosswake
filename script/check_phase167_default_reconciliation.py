#!/usr/bin/env python3
"""Fail-closed Phase 167 ancestry-preserving fix-forward authority."""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import urllib.parse
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
BASE = "74fc15cc546b756c210b6cbbdcb2d7f77e3966bb"
RED = "367f5b5491384594a652d137a03933fa3a89418a"
BRANCH = "agent-phase167-fixforward"
PR145 = {"head_oid": "a6e2622acaaa82e82eb33a21760e75db2e51a281", "merge_oid": BASE, "state": "MERGED"}
FAILED = {110: (34544586854, "85e6aeec41b9a53840f0a2315c16c4390cef1878"), 148: (34553181146, "cc5286da6467c6d582f9a9585272360fcc1e4927")}
FULL_OID = re.compile(r"^[0-9a-f]{40}$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
MODES = {"100644", "100755", "120000", "160000"}
PHASE_EVIDENCE = ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence"
MANIFEST_PATH = f"{PHASE_EVIDENCE}/default-branch-dependency-closure.json"
LEDGER_PATH = f"{PHASE_EVIDENCE}/fix-forward-failure-ledger.json"
RESOLUTION_PATH = f"{PHASE_EVIDENCE}/default-branch-reconciliation-resolution.json"
PR110_PATH = f"{PHASE_EVIDENCE}/pr-110-resolution.json"
RUNTIME_PATHS = [
    ".planning/workstreams/quality-ratchet-release/config.json",
    ".planning/workstreams/quality-ratchet-release/milestone.lock",
    ".planning/workstreams/quality-ratchet-release/state.json",
]
RUNTIME_HASHES = dict(zip(RUNTIME_PATHS, [
    "05b25ad604490dba4c12df84c624d04b1c7bae454ecd78a262dd1b97b68c1a28",
    "fd4c22c0f07449f02acc487c3100eed7a10edb1382d63807dd4003a54bfd2943",
    "6cf0413c5cc52eb4f9c10ba497f82614608a54659e10bd48172bad2d9765dff4",
]))
CHECKPOINT_PATHS = sorted([
    "test/crosswake/proof/phase69_docs_contract_parity_test.exs",
    "test/crosswake/guides/architecture_code_walkthrough_test.exs",
    "test/crosswake/guides/release_boundaries_test.exs",
])
AUTHORIZED = sorted([
    ".github/workflows/crosswake-ci.yml", "mix.exs", "lib/crosswake/doctor/doctor.ex",
    "lib/crosswake/telemetry.ex", "lib/mix/tasks/crosswake.contract.gen.ex",
    "lib/mix/tasks/crosswake.docs.sync.ex",
    "packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex",
    "script/check_dependency_security.sh", "script/check_phase166_ownership_ledger.py",
    "script/list_merge_blocking_checks.py", "script/repository_artifact_policy.json",
    "script/repository_verification_stages.json", "script/run_repository_evidence_environment.sh",
    "script/verify_repository.mjs", "examples/phoenix_host/playwright.config.ts",
    "test/js/repository_verification.test.mjs",
    "test/crosswake/proof/phase166_repository_quality_test.exs",
    "test/crosswake/doctor/doctor_threadline_test.exs",
    "test/crosswake/proof/phase43_rulestead_advisory_test.exs",
    "test/crosswake/telemetry_test.exs", *CHECKPOINT_PATHS,
    "test/mix/tasks/crosswake.docs.sync_test.exs",
])
JOBS = sorted([
    "android-package-unit", "e2e-proof", "guard-01-contract-drift-test",
    "guard-01-e2e-honesty", "hex-page-proof", "ios-package-unit",
    "phase130-core-hermetic-proof", "phase132-core-hermetic-proof",
    "phase34-commerce-proof", "phase41-gating-proof", "phase43-rulestead-proof",
    "phase45-rindle-proof", "proof-dependency-security", "proof-requires-example-host",
    "route-tour-proof",
])
JOB_ROOT = {
    **{job: "root_contract" for job in ["hex-page-proof", "phase130-core-hermetic-proof", "phase132-core-hermetic-proof", "phase34-commerce-proof", "phase41-gating-proof", "phase43-rulestead-proof", "phase45-rindle-proof"]},
    **{job: "repository_environment" for job in ["e2e-proof", "proof-dependency-security", "proof-requires-example-host", "route-tour-proof"]},
    "guard-01-contract-drift-test": "generated_contract_cleanliness",
    "guard-01-e2e-honesty": "phase166_ancestry",
    "android-package-unit": "transitive_platform", "ios-package-unit": "transitive_platform",
}
ANCESTORS = sorted([BASE, "8383aaea2a2b2e10bbe61dd843b51f4129a5d447", "d8e7cf3f7f62a88e92bd5f25e7bfa7c77869442b", "cc14f63662ec6d5db3adf918cb5a59327447353f", "c6b02e388c59e375950329c268c76197f945b5b4", "eba0f21b052c43d957df8ab280ecaa04771782aa", "c06b6109ab3f68a5433a99c3ffb7ff11eafe71ca", RED])
PROOF_ARGV = [
    ["python3", "script/check_phase167_default_reconciliation.py", "--self-test"],
    ["python3", "script/check_phase167_default_reconciliation.py", "--verify-failure-ledger", LEDGER_PATH],
    ["mix", "format", "--check-formatted"],
    ["mix", "test", "test/crosswake/proof/phase69_docs_contract_parity_test.exs", "test/crosswake/guides/architecture_code_walkthrough_test.exs", "test/crosswake/guides/release_boundaries_test.exs"],
    ["node", "--test", "test/js/repository_verification.test.mjs"],
    ["python3", "script/check_phase166_ownership_ledger.py", "--ledger", ".planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md", "--evidence", ".planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json"],
]
FORBIDDEN = ("http://", "https://", "bearer ", "ghp_", "raw_answer", "transcript", "credential", "stable_device", "founder_identity")


class ProofError(Exception): pass
def require(ok: bool, rule: str) -> None:
    if not ok: raise ProofError(rule)
def run(argv: list[str], cwd: Path = ROOT) -> str:
    result = subprocess.run(argv, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    require(result.returncode == 0, "command_failed")
    return result.stdout
def git(*args: str, cwd: Path = ROOT) -> str: return run(["git", *args], cwd)
def gh_json(*args: str) -> Any: return json.loads(run(["gh", *args]))
def canonical(value: Any) -> bytes: return (json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True) + "\n").encode()
def digest(value: Any) -> str: return hashlib.sha256(canonical(value)).hexdigest()
def load(path: Path) -> dict[str, Any]:
    value = json.loads(path.read_text(encoding="utf-8")); require(isinstance(value, dict), "json_object"); return value
def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(json.dumps(value, sort_keys=True, indent=2).encode() + b"\n")
def keys(value: Any, expected: set[str], rule: str) -> None: require(isinstance(value, dict) and set(value) == expected, rule)
def privacy(value: Any) -> None: require(not any(x in canonical(value).decode("ascii").lower() for x in FORBIDDEN), "privacy_sentinel")
def tree(oid: str) -> str:
    require(FULL_OID.fullmatch(oid) is not None, "commit_oid"); value = git("rev-parse", f"{oid}^{{tree}}").strip(); require(FULL_OID.fullmatch(value) is not None, "tree_oid"); return value
def sha(path: Path) -> str: return hashlib.sha256(path.read_bytes()).hexdigest()
def diff_paths(left: str, right: str) -> list[str]:
    raw = subprocess.run(["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "-z", left, right], cwd=ROOT, check=True, stdout=subprocess.PIPE).stdout
    return sorted(x.decode() for x in raw.split(b"\0") if x)
def stage(oid: str, path: str) -> dict[str, str | None]:
    raw = subprocess.run(["git", "ls-tree", "-z", oid, "--", path], cwd=ROOT, check=True, stdout=subprocess.PIPE).stdout
    if not raw: return {"mode": None, "blob": None}
    require(raw.count(b"\0") == 1, "stage_count"); meta, actual = raw[:-1].split(b"\t", 1); mode, kind, blob = meta.decode().split(" ")
    require(actual.decode() == path and mode in MODES and kind in {"blob", "commit"} and FULL_OID.fullmatch(blob) is not None, "stage")
    return {"mode": mode, "blob": blob}
def runtime_clean() -> None:
    untracked = sorted(x for x in git("ls-files", "--others", "--exclude-standard", "-z").split("\0") if x)
    require(untracked == RUNTIME_PATHS, "runtime_paths")
    require(all(sha(ROOT / path) == expected for path, expected in RUNTIME_HASHES.items()), "runtime_hashes")


def failure_ledger() -> dict[str, Any]:
    roots = [
        {"id": "generated_contract_cleanliness", "category": "generated_contract_cleanliness", "disposition": "repair_required", "repair_paths": CHECKPOINT_PATHS, "regression_paths": CHECKPOINT_PATHS, "fixed_argv": [["mix", "format", "--check-formatted"], ["mix", "test", *CHECKPOINT_PATHS]], "reproduction_result": "failed_as_expected"},
        {"id": "phase166_ancestry", "category": "phase166_ancestry", "disposition": "repair_required", "repair_paths": ["script/check_phase166_ownership_ledger.py"], "regression_paths": ["test/js/repository_verification.test.mjs"], "fixed_argv": [["node", "--test", "test/js/repository_verification.test.mjs"]], "reproduction_result": "failed_as_expected"},
        {"id": "repository_environment", "category": "repository_environment", "disposition": "repair_required", "repair_paths": [".github/workflows/crosswake-ci.yml", "script/verify_repository.mjs"], "regression_paths": [".github/workflows/crosswake-ci.yml", "test/js/repository_verification.test.mjs"], "fixed_argv": [["mix", "deps.get"], ["node", "--test", "test/js/repository_verification.test.mjs"], ["script/verify_repository.sh", "--stage", "repository-preflight"]], "reproduction_result": "failed_as_expected"},
        {"id": "root_contract", "category": "root_contract", "disposition": "repair_required", "repair_paths": ["lib/mix/tasks/crosswake.docs.sync.ex", "test/mix/tasks/crosswake.docs.sync_test.exs"], "regression_paths": ["test/mix/tasks/crosswake.docs.sync_test.exs"], "fixed_argv": [["mix", "test", "--exclude", "requires_example_host", "--exclude", "advisory_only"]], "reproduction_result": "failed_as_expected"},
        {"id": "transitive_platform", "category": "transitive_platform", "disposition": "transitive_only", "repair_paths": [], "regression_paths": [], "fixed_argv": [], "reproduction_result": "not_independent"},
    ]
    return {"schema_version": 2, "kind": "fix_forward_failure_ledger", "base_oid": BASE, "reproduction_source_oid": git("rev-parse", "HEAD").strip(), "red_tracer_oid": RED, "failed_runs": [{"pr_number": n, "run_id": FAILED[n][0], "head_oid": FAILED[n][1], "conclusion": "FAILURE", "failed_leaves": [{"job": job, "root_id": JOB_ROOT[job]} for job in JOBS]} for n in [110, 148]], "roots": sorted(roots, key=lambda x: x["id"]), "authorized_repair_paths": AUTHORIZED, "formatter_checkpoint_paths": CHECKPOINT_PATHS, "required_ancestor_oids": ANCESTORS, "rejected_topology": {"first_boundary_path_count": 232, "second_boundary_path_count": 11, "status": "diagnostic_only", "reason": "shallow_history_unavailable"}, "runtime": {"erlang": "27.3.4.15", "elixir": "1.19.5-otp-27", "node": "22.14.0", "otp_semantic": "27"}, "runtime_file_hashes": RUNTIME_HASHES}


def validate_ledger(value: Any) -> None:
    keys(value, {"schema_version", "kind", "base_oid", "reproduction_source_oid", "red_tracer_oid", "failed_runs", "roots", "authorized_repair_paths", "formatter_checkpoint_paths", "required_ancestor_oids", "rejected_topology", "runtime", "runtime_file_hashes"}, "ledger_schema")
    require(value["schema_version"] == 2 and value["kind"] == "fix_forward_failure_ledger" and value["base_oid"] == BASE and value["red_tracer_oid"] == RED, "ledger_authority")
    require(FULL_OID.fullmatch(value["reproduction_source_oid"]) is not None, "source_oid")
    require(value["authorized_repair_paths"] == AUTHORIZED and value["formatter_checkpoint_paths"] == CHECKPOINT_PATHS and value["required_ancestor_oids"] == ANCESTORS, "ledger_scope")
    require(value["runtime"] == {"erlang": "27.3.4.15", "elixir": "1.19.5-otp-27", "node": "22.14.0", "otp_semantic": "27"} and value["runtime_file_hashes"] == RUNTIME_HASHES, "ledger_runtime")
    require(value["rejected_topology"] == {"first_boundary_path_count": 232, "second_boundary_path_count": 11, "status": "diagnostic_only", "reason": "shallow_history_unavailable"}, "topology")
    require(isinstance(value["failed_runs"], list) and len(value["failed_runs"]) == 2, "runs")
    for item, n in zip(value["failed_runs"], [110, 148]):
        keys(item, {"pr_number", "run_id", "head_oid", "conclusion", "failed_leaves"}, "run_schema")
        require((item["pr_number"], item["run_id"], item["head_oid"], item["conclusion"]) == (n, FAILED[n][0], FAILED[n][1], "FAILURE"), "run_identity")
        require(item["failed_leaves"] == [{"job": job, "root_id": JOB_ROOT[job]} for job in JOBS], "leaf_coverage")
    require([x.get("id") for x in value["roots"]] == sorted(set(JOB_ROOT.values())), "root_set")
    repairs: list[str] = []
    for item in value["roots"]:
        keys(item, {"id", "category", "disposition", "repair_paths", "regression_paths", "fixed_argv", "reproduction_result"}, "root_schema")
        require(item["id"] == item["category"] and item["disposition"] in {"repair_required", "resolved_by_full_source", "transitive_only"}, "root_disposition")
        require(item["repair_paths"] == sorted(set(item["repair_paths"])) and item["regression_paths"] == sorted(set(item["regression_paths"])), "root_paths")
        for argv in item["fixed_argv"]: require(isinstance(argv, list) and argv and all(isinstance(p, str) and p and not re.search(r"[;&|`\n\r]", p) for p in argv), "fixed_argv")
        if item["disposition"] == "repair_required": require(item["repair_paths"] and item["regression_paths"] and item["fixed_argv"], "repair_proof"); repairs += item["repair_paths"]
        else: require(item["repair_paths"] == [], "nonrepair_edit")
    require(len(repairs) == len(set(repairs)) and set(repairs) <= set(AUTHORIZED) and set(CHECKPOINT_PATHS) <= set(repairs), "repair_queue")
    privacy(value)


def source_manifest(payload: str) -> dict[str, Any]:
    payload = git("rev-parse", f"{payload}^{{commit}}").strip()
    for oid in ANCESTORS: subprocess.run(["git", "merge-base", "--is-ancestor", oid, payload], cwd=ROOT, check=True)
    records = [{"path": path, "base": stage(BASE, path), "payload": stage(payload, path)} for path in diff_paths(BASE, payload) if path != MANIFEST_PATH]
    return {"schema_version": 2, "kind": "fix_forward_candidate_scope", "base_oid": BASE, "base_tree_oid": tree(BASE), "payload_source_oid": payload, "payload_source_tree_oid": tree(payload), "manifest_path": MANIFEST_PATH, "manifest_mode": "100644", "records": records, "records_digest": digest(records), "required_ancestor_oids": ANCESTORS, "proof_argv": PROOF_ARGV, "runtime_file_hashes": RUNTIME_HASHES, "expected_branch": BRANCH}


def validate_manifest(value: Any) -> None:
    keys(value, {"schema_version", "kind", "base_oid", "base_tree_oid", "payload_source_oid", "payload_source_tree_oid", "manifest_path", "manifest_mode", "records", "records_digest", "required_ancestor_oids", "proof_argv", "runtime_file_hashes", "expected_branch"}, "manifest_schema")
    require(value["schema_version"] == 2 and value["kind"] == "fix_forward_candidate_scope" and value["base_oid"] == BASE and value["base_tree_oid"] == tree(BASE), "manifest_base")
    require(FULL_OID.fullmatch(value["payload_source_oid"]) is not None and value["payload_source_tree_oid"] == tree(value["payload_source_oid"]), "manifest_payload")
    require(value["manifest_path"] == MANIFEST_PATH and value["manifest_mode"] == "100644" and value["required_ancestor_oids"] == ANCESTORS and value["proof_argv"] == PROOF_ARGV and value["runtime_file_hashes"] == RUNTIME_HASHES and value["expected_branch"] == BRANCH, "manifest_contract")
    expected = [p for p in diff_paths(BASE, value["payload_source_oid"]) if p != MANIFEST_PATH]
    require([x.get("path") for x in value["records"]] == expected and value["records_digest"] == digest(value["records"]), "manifest_records")
    for item in value["records"]:
        keys(item, {"path", "base", "payload"}, "record_schema"); require(item["base"] == stage(BASE, item["path"]) and item["payload"] == stage(value["payload_source_oid"], item["path"]), "record_blob")
    for oid in ANCESTORS: subprocess.run(["git", "merge-base", "--is-ancestor", oid, value["payload_source_oid"]], cwd=ROOT, check=True)
    privacy(value)


def verify_candidate(value: dict[str, Any], candidate: str, local_clean: bool) -> None:
    validate_manifest(value); candidate = git("rev-parse", f"{candidate}^{{commit}}").strip()
    require(git("rev-parse", f"{candidate}^").strip() == value["payload_source_oid"] and diff_paths(value["payload_source_oid"], candidate) == [MANIFEST_PATH], "candidate_delta")
    require(git("branch", "--show-current").strip() == BRANCH and not git("diff", "--name-only").strip() and not git("diff", "--cached", "--name-only").strip(), "candidate_state")
    runtime_clean()
    if local_clean:
        proof = Path(tempfile.mkdtemp(prefix=".phase167-candidate-proof.", dir=ROOT / ".planning"))
        try:
            run(["script/run_repository_evidence_environment.sh", "--source-repository", str(ROOT), "--commit", candidate, "--output-dir", str(proof)])
            evidence = load(proof / "clean-checkout-run.json")
            require(evidence.get("supported_code_sha") == candidate and [x.get("result") for x in evidence.get("stages", [])] == ["PASS"] * 9, "clean_checkout")
        finally: shutil.rmtree(proof, ignore_errors=True)


def repository() -> tuple[str, str]:
    info = gh_json("repo", "view", "--json", "nameWithOwner,defaultBranchRef", "--jq", "{repo:.nameWithOwner,branch:.defaultBranchRef.name}")
    endpoint = f"repos/{info['repo']}/branches/{urllib.parse.quote(info['branch'], safe='')}"
    return info["repo"], gh_json("api", endpoint, "--jq", ".commit.sha")
def pr(number: int) -> dict[str, Any]:
    return gh_json("pr", "view", str(number), "--json", "number,state,headRefOid,baseRefOid,mergeCommit,comments", "--jq", "{number,state,head_oid:.headRefOid,base_oid:.baseRefOid,merge_oid:(.mergeCommit.oid//null),comments:[.comments[].body]}")
def check(repo: str, head: str) -> Any:
    return gh_json("api", f"repos/{repo}/commits/{head}/check-runs?filter=latest&per_page=100", "--jq", '[.check_runs[]|select(.name=="Crosswake CI")|{head_oid:.head_sha,status:(.status|ascii_upcase),conclusion:((.conclusion//"")|ascii_upcase)}]|first')
def reachable(repo: str, ancestor: str, descendant: str) -> bool:
    item = gh_json("api", f"repos/{repo}/compare/{ancestor}...{descendant}", "--jq", "{status,behind_by}"); return item.get("status") in {"ahead", "identical"} and item.get("behind_by") == 0
def validate_supersession(item: Any, number: int) -> None:
    keys(item, {"schema_version", "kind", "pr_number", "old_head_oid", "failed_run_id", "state", "merged", "marker_sha256", "replacement_pr_number", "replacement_head_oid", "replacement_merge_oid"}, "supersession_schema")
    require(item["schema_version"] == 2 and item["kind"] == "superseded_fix_forward" and (item["pr_number"], item["old_head_oid"], item["failed_run_id"]) == (number, FAILED[number][1], FAILED[number][0]) and item["state"] == "CLOSED" and item["merged"] is False and SHA256.fullmatch(item["marker_sha256"]) is not None, "supersession")


def validate_resolution(value: Any, live: bool) -> None:
    keys(value, {"schema_version", "kind", "replacement_pr_number", "tested_head_oid", "tested_base_oid", "tested_tree_oid", "merge_commit_oid", "merge_tree_oid", "fresh_default_oid", "crosswake_ci", "required_ancestor_oids", "pr145", "superseded", "phase_branch", "receipt_parent_oid", "local_main_before_oid"}, "resolution_schema")
    require(value["schema_version"] == 2 and value["kind"] == "fix_forward_resolution" and value["tested_base_oid"] == BASE and value["crosswake_ci"] == "SUCCESS" and value["required_ancestor_oids"] == ANCESTORS and value["pr145"] == PR145 and value["phase_branch"] == BRANCH, "resolution_contract")
    for k in ["tested_head_oid", "tested_tree_oid", "merge_commit_oid", "merge_tree_oid", "fresh_default_oid", "receipt_parent_oid", "local_main_before_oid"]: require(FULL_OID.fullmatch(value[k]) is not None, k)
    require(value["tested_tree_oid"] == value["merge_tree_oid"] and value["fresh_default_oid"] == value["merge_commit_oid"] and value["receipt_parent_oid"] == value["tested_head_oid"], "resolution_identity")
    require([x.get("pr_number") for x in value["superseded"]] == [110, 148], "superseded_set")
    for item in value["superseded"]: validate_supersession(item, item["pr_number"]); require(item["replacement_pr_number"] == value["replacement_pr_number"] and item["replacement_head_oid"] == value["tested_head_oid"] and item["replacement_merge_oid"] == value["merge_commit_oid"], "supersession_link")
    require(load(ROOT / PR110_PATH) == value["superseded"][0], "pr110_receipt"); privacy(value)
    if live:
        repo, default = repository(); replacement = pr(value["replacement_pr_number"]); ci = check(repo, value["tested_head_oid"])
        require(replacement["state"] == "MERGED" and replacement["head_oid"] == value["tested_head_oid"] and replacement["base_oid"] == BASE and replacement["merge_oid"] == value["merge_commit_oid"], "replacement_live")
        require(default == value["fresh_default_oid"] and reachable(repo, value["tested_head_oid"], default) and ci == {"head_oid": value["tested_head_oid"], "status": "COMPLETED", "conclusion": "SUCCESS"}, "replacement_authority")
        marker = "<!-- crosswake-phase167-superseded_fix_forward -->"; require(hashlib.sha256(marker.encode()).hexdigest() == value["superseded"][0]["marker_sha256"], "marker_digest")
        for item in value["superseded"]:
            snap = pr(item["pr_number"]); require(snap["state"] == "CLOSED" and snap["merge_oid"] is None and snap["head_oid"] == item["old_head_oid"] and marker in snap["comments"], "superseded_live")


def local_reconciliation(value: Any) -> None:
    validate_resolution(value, False); require(git("branch", "--show-current").strip() == BRANCH and git("rev-parse", "refs/heads/main").strip() == value["fresh_default_oid"], "local_refs")
    receipt_commit = git("log", "-1", "--format=%H", "--", RESOLUTION_PATH).strip()
    require(receipt_commit == git("rev-parse", "HEAD").strip() and git("rev-parse", f"{receipt_commit}^").strip() == value["receipt_parent_oid"], "receipt_commit")
    require(not git("diff", "--name-only").strip() and not git("diff", "--cached", "--name-only").strip(), "local_residue"); runtime_clean()


def self_test() -> int:
    valid = failure_ledger(); validate_ledger(valid); fixtures = []
    for name, mutate in [
        ("short_oid", lambda x: x.update(base_oid=BASE[:12])),
        ("unknown_key", lambda x: x.update(unknown=True)),
        ("missing_leaf", lambda x: x["failed_runs"][0].update(failed_leaves=x["failed_runs"][0]["failed_leaves"][:-1])),
        ("outside_repair", lambda x: x["roots"][0].update(repair_paths=["outside.txt"])),
        ("formatter_scope", lambda x: x.update(formatter_checkpoint_paths=x["formatter_checkpoint_paths"][:-1])),
        ("runtime_hash", lambda x: x["runtime_file_hashes"].update({RUNTIME_PATHS[0]: "a" * 64})),
        ("obsolete_topology", lambda x: x["rejected_topology"].update(status="candidate")),
        ("unsafe_argv", lambda x: x["roots"][0].update(fixed_argv=[["sh", "bad | argv"]])),
    ]:
        item = copy.deepcopy(valid); mutate(item); fixtures.append((name, item))
    for name, item in fixtures:
        try: validate_ledger(item)
        except ProofError: continue
        print(f"phase167-default-reconciliation-self-test: FAIL fixture={name}"); return 1
    print(f"phase167-default-reconciliation-self-test: PASS count={len(fixtures) + 1}"); return 0


def main() -> int:
    p = argparse.ArgumentParser(); p.add_argument("--self-test", action="store_true"); p.add_argument("--capture-failure-ledger", action="store_true"); p.add_argument("--verify-failure-ledger", type=Path); p.add_argument("--capture-source-scope", action="store_true"); p.add_argument("--payload-source", default="HEAD"); p.add_argument("--output", type=Path); p.add_argument("--verify-candidate", type=Path); p.add_argument("--candidate", default="HEAD"); p.add_argument("--local-clean-checkout", action="store_true"); p.add_argument("--verify-resolution", type=Path); p.add_argument("--live", action="store_true"); p.add_argument("--verify-local-reconciliation", type=Path); a = p.parse_args()
    try:
        if a.self_test: return self_test()
        if a.capture_failure_ledger: require(a.output is not None, "output"); value = failure_ledger(); validate_ledger(value); write_json(a.output, value); print("phase167-default-reconciliation: CAPTURED failure-ledger"); return 0
        if a.verify_failure_ledger: validate_ledger(load(a.verify_failure_ledger)); print("phase167-default-reconciliation: PASS failure-ledger roots=5 runs=2"); return 0
        if a.capture_source_scope: require(a.output is not None, "output"); value = source_manifest(a.payload_source); validate_manifest(value); write_json(a.output, value); print("phase167-default-reconciliation: CAPTURED source-scope"); return 0
        if a.verify_candidate: verify_candidate(load(a.verify_candidate), a.candidate, a.local_clean_checkout); print("phase167-default-reconciliation: PASS candidate"); return 0
        if a.verify_resolution: require(a.live, "live"); validate_resolution(load(a.verify_resolution), True); print("phase167-default-reconciliation: PASS resolution"); return 0
        if a.verify_local_reconciliation: local_reconciliation(load(a.verify_local_reconciliation)); print("phase167-default-reconciliation: PASS local-reconciliation"); return 0
        p.error("select one fixed mode")
    except (ProofError, OSError, UnicodeDecodeError, json.JSONDecodeError, KeyError, TypeError, ValueError, subprocess.CalledProcessError): print("phase167-default-reconciliation: FAIL closed_failure"); return 1


if __name__ == "__main__": raise SystemExit(main())
