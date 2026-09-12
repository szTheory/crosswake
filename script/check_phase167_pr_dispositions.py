#!/usr/bin/env python3
"""Fail-closed exact-SHA validation for Phase 167 pull-request receipts."""

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
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Callable


ROOT = Path(__file__).resolve().parents[1]
FULL_OID = re.compile(r"^[0-9a-f]{40}$")
RECEIPT_FIELDS = {
    "schema_version",
    "original_number",
    "candidate_number",
    "tested_head_oid",
    "tested_base_oid",
    "merge_commit_oid",
    "fresh_default_oid",
    "crosswake_ci",
    "scope_profile",
    "intent_commit_count",
    "disposition",
    "replacement_for",
    "supersession_receipt",
}
SCOPE_PROFILES = {
    "setup_java_v6": {
        ".github/actions/setup-android-jvm/action.yml",
        ".github/workflows/crosswake-ci.yml",
        ".github/workflows/phase68-proof.yml",
        ".github/workflows/release-please.yml",
        "test/crosswake/proof/phase165_ci_integrity_test.exs",
    },
    "packstore_waiter_clarity": {
        "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift"
    },
    "package_reconciliation": {
        ".github/workflows/crosswake-ci.yml",
        ".planning/WINDOWS.md",
        ".planning/workstreams/first-b2c-adopter-readiness/STATE.md",
        ".planning/workstreams/quality-ratchet-release/REQUIREMENTS.md",
        ".planning/workstreams/quality-ratchet-release/ROADMAP.md",
        ".planning/workstreams/quality-ratchet-release/STATE.md",
        ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-01-SUMMARY.md",
        ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-02-SUMMARY.md",
        ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-03-SUMMARY.md",
        ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-04-SUMMARY.md",
        ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-PATTERNS.md",
        "CONTRIBUTING.md",
        "README.md",
        "docs/COMPANION-PUBLISH-RUNBOOK.md",
        "guides/architecture.md",
        "guides/capability_map.md",
        "guides/code-walkthrough.md",
        "guides/companion_compatibility.md",
        "guides/compatibility.md",
        "guides/install.md",
        "guides/physical_iphone_handoff.md",
        "guides/support_matrix.md",
        "guides/troubleshooting.md",
        "lib/crosswake/capability_map.ex",
        "lib/crosswake/capability_map/renderer.ex",
        "lib/crosswake/support_matrix/renderer.ex",
        "lib/mix/tasks/crosswake.docs.sync.ex",
        "packages/crosswake_rindle/README.md",
        "packages/crosswake_rindle/mix.exs",
        "packages/crosswake_rulestead/README.md",
        "packages/crosswake_rulestead/mix.exs",
        "script/ci_docs_allowlist.json",
        "script/ci_leaf_manifest.json",
        "script/check_release_workflow_integrity.exs",
        "script/repository_artifact_policy.json",
        "script/verify_repository.mjs",
        "test/crosswake/capability_map/capability_map_test.exs",
        "test/crosswake/capability_map/renderer_test.exs",
        "test/crosswake/guides/architecture_code_walkthrough_test.exs",
        "test/crosswake/guides/quick_start_adoption_drift_test.exs",
        "test/crosswake/guides/release_boundaries_test.exs",
        "test/crosswake/proof/phase132_compat_matrix_drift_test.exs",
        "test/crosswake/proof/phase142_release_integrity_test.exs",
        "test/crosswake/proof/phase165_ci_integrity_test.exs",
        "test/crosswake/proof/phase165_ci_policy_test.exs",
        "test/crosswake/proof/phase166_repository_quality_test.exs",
        "test/crosswake/proof/phase69_docs_contract_parity_test.exs",
        "test/crosswake/support_matrix/renderer_test.exs",
        "test/js/repository_verification.test.mjs",
        "test/mix/tasks/crosswake.docs.sync_test.exs",
    },
}
SUPERSESSION_MARKERS = {
    121: "<!-- crosswake-phase167-pr-121-superseded -->",
    110: "<!-- crosswake-phase167-pr-110-superseded -->",
}
ORDINARY_NUMBERS = [57, 105, 110, 115, 121, 146, 147]
DEFERRED_NUMBERS = [57, 115, 146, 147]
DEFER_MARKER = "<!-- crosswake-phase167-release-only-deferred-phase168 -->"
INVENTORY_FIELDS = {
    "schema_version",
    "kind",
    "captured_at",
    "default_oid",
    "ordinary_prs",
    "release_only_deferred",
    "recovery_transactions",
}
ORDINARY_FIELDS = {
    "number",
    "head_oid",
    "base_oid",
    "check_summary",
    "disposition",
    "reason",
    "next_gate",
}
CHECK_FIELDS = {"name", "head_oid", "status", "conclusion"}
DEFER_FIELDS = {"number", "comment_node_id", "marker_sha256"}
RECOVERY_FIELDS = {
    "role",
    "number",
    "head_oid",
    "state",
    "merge_oid",
    "replacement_number",
    "receipt_path",
    "receipt_sha256",
}
DISPOSITIONS = {
    57: ("release_only_deferred", "release_candidate_requires_phase_168", "phase_168_exact_candidate_and_maintainer_approval"),
    105: ("merged", "packstore_waiter_clarity_landed", "none"),
    110: ("closed_unmerged_superseded", "complete_truth_landed_by_replacement", "replacement_pr_149_receipt"),
    115: ("release_only_deferred", "release_candidate_requires_phase_168", "phase_168_exact_candidate_and_maintainer_approval"),
    121: ("merged", "setup_java_v6_landed", "none"),
    146: ("release_only_deferred", "release_candidate_requires_phase_168", "phase_168_exact_candidate_and_maintainer_approval"),
    147: ("release_only_deferred", "release_candidate_requires_phase_168", "phase_168_exact_candidate_and_maintainer_approval"),
}
RECOVERY_PATHS = {
    145: ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-reconciliation-resolution.json",
    110: ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/pr-110-resolution.json",
    148: ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-reconciliation-resolution.json",
    149: ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/default-branch-reconciliation-resolution.json",
}
RECOVERY_ROLES = ["historical_merged", "failed_closed_unmerged", "failed_closed_unmerged", "replacement_merged"]
FORBIDDEN_EVIDENCE = (
    "http://",
    "https://",
    "bearer ",
    "ghp_",
    "raw_answer",
    "transcript",
    "credential",
    "stable_device",
    "founder_identity",
)
PLAN07_DEFAULT = "783bd74df1c050f6c0214da4682d198a528ba59c"
CLOSEOUT_SCOPE_PATH = ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-scope.json"
CLOSEOUT_SCOPE_FIELDS = {
    "schema_version",
    "payload_source_oid",
    "payload_source_tree",
    "payload_scope",
    "self_excluded_manifest",
}
CLOSEOUT_RECORD_FIELDS = {"path", "mode", "blob"}
CLOSEOUT_SELF_FIELDS = {"path", "expected_mode", "expected_schema_fields"}
CLOSEOUT_REQUIRED_ANCESTORS = [
    "367f5b5491384594a652d137a03933fa3a89418a",
    "b489905d0f735e88268905607390021256e405b8",
    "e0959e8cb503eae7352c21a5d6693ef99d0d5a9b",
    "1587e1a557884b0b34cad8b748ccbd948c090eed",
    "783bd74df1c050f6c0214da4682d198a528ba59c",
    "b5424dc59ab0305bbc7a16d53d8bf1339d21b02a",
    "bda14a28b6447f1e6f5ad9d825d429b42f7da1db",
    "c961d4a60633e1c1db3ea11c4e4dd5d912073f6b",
    "a7c3d91ebf57380ecb7a2458cc8a148bc30312df",
]
RUNTIME_PATHS = [
    ".planning/workstreams/quality-ratchet-release/config.json",
    ".planning/workstreams/quality-ratchet-release/milestone.lock",
    ".planning/workstreams/quality-ratchet-release/state.json",
]
RUNTIME_HASHES = {
    RUNTIME_PATHS[0]: "05b25ad604490dba4c12df84c624d04b1c7bae454ecd78a262dd1b97b68c1a28",
    RUNTIME_PATHS[1]: "fd4c22c0f07449f02acc487c3100eed7a10edb1382d63807dd4003a54bfd2943",
    RUNTIME_PATHS[2]: "6cf0413c5cc52eb4f9c10ba497f82614608a54659e10bd48172bad2d9765dff4",
}


@dataclass(frozen=True)
class Problem:
    rule: str
    number: int

    def render(self) -> str:
        return f"phase167-pr: FAIL rule={self.rule} pr={self.number}"


Runner = Callable[[list[str]], dict[str, Any]]


def validate_resolution(receipt: dict[str, Any], live: dict[str, Any]) -> list[Problem]:
    number = receipt.get("original_number") if isinstance(receipt.get("original_number"), int) else 0
    problems: list[Problem] = []

    def reject(condition: bool, rule: str) -> None:
        if condition:
            problems.append(Problem(rule, number))

    reject(set(receipt) != RECEIPT_FIELDS, "receipt_schema")
    reject(receipt.get("schema_version") != 1, "receipt_schema_version")
    original = receipt.get("original_number")
    candidate = receipt.get("candidate_number")
    reject(original not in {121, 110, 105}, "original_number")
    reject(not isinstance(candidate, int) or candidate <= 0, "candidate_number")
    for field in ("tested_head_oid", "tested_base_oid", "merge_commit_oid", "fresh_default_oid"):
        reject(not isinstance(receipt.get(field), str) or FULL_OID.fullmatch(receipt[field]) is None, f"{field}_format")
    reject(receipt.get("crosswake_ci") != "SUCCESS", "receipt_crosswake_ci")
    profile = receipt.get("scope_profile")
    reject(profile not in SCOPE_PROFILES, "scope_profile")
    commit_count = receipt.get("intent_commit_count")
    reject(not isinstance(commit_count, int) or isinstance(commit_count, bool) or commit_count < 1, "intent_commit_count")
    disposition = receipt.get("disposition")
    reject(disposition not in {"merged", "superseded"}, "disposition")

    replacement = candidate != original
    reject(replacement and original not in {121, 110}, "replacement_unauthorized")
    reject((receipt.get("replacement_for") == original) != replacement, "replacement_relationship")
    reject(bool(receipt.get("supersession_receipt")) != replacement, "supersession_receipt")
    reject((disposition == "superseded") != replacement, "disposition_relationship")
    reject(original == 105 and (replacement or disposition != "merged"), "packstore_replacement_forbidden")
    reject(profile == "packstore_waiter_clarity" and commit_count != 1, "packstore_intent_commit_count")

    original_live = live.get("original") if isinstance(live.get("original"), dict) else {}
    candidate_live = live.get("candidate") if isinstance(live.get("candidate"), dict) else {}
    check = live.get("check") if isinstance(live.get("check"), dict) else {}
    reject(original_live.get("number") != original, "original_live_number")
    reject(candidate_live.get("number") != candidate, "candidate_live_number")
    reject(candidate_live.get("head_oid") != receipt.get("tested_head_oid"), "tested_head_drift")
    reject(candidate_live.get("base_oid") != receipt.get("tested_base_oid"), "tested_base_drift")
    reject(candidate_live.get("state") != "MERGED", "candidate_not_merged")
    reject(candidate_live.get("merge_commit_oid") != receipt.get("merge_commit_oid"), "merge_commit_drift")
    reject(candidate_live.get("commit_count") != commit_count, "intent_commit_count_drift")
    if profile in SCOPE_PROFILES:
        reject(set(candidate_live.get("files", [])) != SCOPE_PROFILES[profile], "scope_drift")
    reject(check.get("name") != "Crosswake CI", "crosswake_ci_missing")
    reject(check.get("head_oid") != receipt.get("tested_head_oid"), "crosswake_ci_head_drift")
    reject(check.get("status") != "COMPLETED", "crosswake_ci_incomplete")
    reject(check.get("conclusion") != "SUCCESS", "crosswake_ci_unsuccessful")
    reject(live.get("default_oid") != receipt.get("fresh_default_oid"), "default_oid_drift")
    reject(not live.get("merge_reachable"), "merge_unreachable")
    if replacement:
        reject(original_live.get("state") != "CLOSED", "original_not_closed")
        reject(original_live.get("merge_commit_oid") is not None, "original_was_merged")
        reject(not live.get("supersession_marker"), "supersession_marker_missing")
    else:
        reject(original_live.get("state") != "MERGED", "original_not_merged")
        reject(bool(live.get("supersession_marker")), "unexpected_supersession_marker")
    return problems


def run_json(argv: list[str]) -> Any:
    completed = subprocess.run(
        argv,
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    return json.loads(completed.stdout)


def gh_json(*args: str) -> Any:
    return run_json(["gh", *args])


def pr_snapshot(number: int) -> dict[str, Any]:
    query = (
        "{number:.number,state:.state,head_oid:.headRefOid,base_oid:.baseRefOid,"
        "merge_commit_oid:(.mergeCommit.oid // null),files:[.files[].path],"
        "commit_count:(.commits | length)}"
    )
    return gh_json(
        "pr", "view", str(number), "--json",
        "number,state,headRefOid,baseRefOid,mergeCommit,files,commits", "--jq", query,
    )


def check_snapshot(repository: str, head_oid: str) -> dict[str, Any] | None:
    owner, name = repository.split("/", 1)
    query = (
        "query { repository(owner:%s,name:%s) { object(expression:%s) { ... on Commit { "
        "statusCheckRollup { contexts(first:100) { nodes { ... on CheckRun { name status conclusion } } } } } } } }"
        % (json.dumps(owner), json.dumps(name), json.dumps(head_oid))
    )
    value = gh_json(
        "api", "graphql", "-f", f"query={query}", "--jq",
        '.data.repository.object.statusCheckRollup.contexts.nodes | map(select(.name == "Crosswake CI") | {name:.name,status:(.status | ascii_upcase),conclusion:((.conclusion // "") | ascii_upcase)}) | first',
    )
    if isinstance(value, dict):
        value["head_oid"] = head_oid
    return value


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def file_sha256(path: str) -> str:
    return sha256_bytes((ROOT / path).read_bytes())


def git_text(*args: str) -> str:
    completed = subprocess.run(
        ["git", *args], cwd=ROOT, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    return completed.stdout.strip()


def tree_oid(commit: str) -> str:
    value = git_text("rev-parse", f"{commit}^{{tree}}")
    if FULL_OID.fullmatch(value) is None:
        raise ValueError("tree oid")
    return value


def diff_paths(left: str, right: str) -> list[str]:
    raw = subprocess.run(
        ["git", "diff-tree", "--no-commit-id", "--name-only", "-r", "-z", left, right],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    ).stdout
    return sorted(item.decode("utf-8") for item in raw.split(b"\0") if item)


def tree_record(commit: str, path: str) -> dict[str, str]:
    raw = subprocess.run(
        ["git", "ls-tree", "-z", commit, "--", path], cwd=ROOT, check=True, stdout=subprocess.PIPE
    ).stdout
    if raw.count(b"\0") != 1:
        raise ValueError("tree record")
    metadata, actual = raw[:-1].split(b"\t", 1)
    mode, kind, blob = metadata.decode("ascii").split(" ")
    if actual.decode("utf-8") != path or kind != "blob" or mode not in {"100644", "100755", "120000"} or FULL_OID.fullmatch(blob) is None:
        raise ValueError("tree record")
    return {"path": path, "mode": mode, "blob": blob}


def runtime_clean() -> bool:
    untracked = sorted(filter(None, git_text("ls-files", "--others", "--exclude-standard", "-z").split("\0")))
    return (
        untracked == RUNTIME_PATHS
        and all(file_sha256(path) == expected for path, expected in RUNTIME_HASHES.items())
        and not git_text("diff", "--name-only")
        and not git_text("diff", "--cached", "--name-only")
    )


def capture_closeout_scope(payload: str) -> dict[str, Any]:
    payload_oid = git_text("rev-parse", f"{payload}^{{commit}}")
    paths = [path for path in diff_paths(PLAN07_DEFAULT, payload_oid) if path != CLOSEOUT_SCOPE_PATH]
    return {
        "schema_version": 1,
        "payload_source_oid": payload_oid,
        "payload_source_tree": tree_oid(payload_oid),
        "payload_scope": [tree_record(payload_oid, path) for path in paths],
        "self_excluded_manifest": {
            "path": CLOSEOUT_SCOPE_PATH,
            "expected_mode": "100644",
            "expected_schema_fields": sorted(CLOSEOUT_SCOPE_FIELDS),
        },
    }


def validate_closeout_scope(value: dict[str, Any]) -> None:
    if set(value) != CLOSEOUT_SCOPE_FIELDS or value.get("schema_version") != 1:
        raise ValueError("closeout schema")
    payload = value.get("payload_source_oid")
    if not isinstance(payload, str) or FULL_OID.fullmatch(payload) is None:
        raise ValueError("payload oid")
    if value.get("payload_source_tree") != tree_oid(payload):
        raise ValueError("payload tree")
    expected_self = {
        "path": CLOSEOUT_SCOPE_PATH,
        "expected_mode": "100644",
        "expected_schema_fields": sorted(CLOSEOUT_SCOPE_FIELDS),
    }
    if value.get("self_excluded_manifest") != expected_self:
        raise ValueError("self exclusion")
    if git_text("ls-tree", payload, "--", CLOSEOUT_SCOPE_PATH):
        raise ValueError("manifest not excluded")
    expected_paths = [path for path in diff_paths(PLAN07_DEFAULT, payload) if path != CLOSEOUT_SCOPE_PATH]
    scope = value.get("payload_scope")
    if not isinstance(scope, list) or [item.get("path") for item in scope if isinstance(item, dict)] != expected_paths:
        raise ValueError("payload paths")
    for item in scope:
        if not isinstance(item, dict) or set(item) != CLOSEOUT_RECORD_FIELDS or item != tree_record(payload, item["path"]):
            raise ValueError("payload record")
    for oid in CLOSEOUT_REQUIRED_ANCESTORS:
        subprocess.run(["git", "merge-base", "--is-ancestor", oid, payload], cwd=ROOT, check=True)
    serialized = json.dumps(value, sort_keys=True, separators=(",", ":")).lower()
    if any(token in serialized for token in FORBIDDEN_EVIDENCE):
        raise ValueError("privacy")


def verify_closeout_candidate(value: dict[str, Any], candidate: str, local_clean: bool) -> None:
    validate_closeout_scope(value)
    candidate_oid = git_text("rev-parse", f"{candidate}^{{commit}}")
    if git_text("rev-parse", f"{candidate_oid}^") != value["payload_source_oid"]:
        raise ValueError("candidate parent")
    if diff_paths(value["payload_source_oid"], candidate_oid) != [CLOSEOUT_SCOPE_PATH]:
        raise ValueError("candidate delta")
    if tree_record(candidate_oid, CLOSEOUT_SCOPE_PATH)["mode"] != value["self_excluded_manifest"]["expected_mode"]:
        raise ValueError("candidate manifest mode")
    if git_text("branch", "--show-current") != "agent-phase167-fixforward" or not runtime_clean():
        raise ValueError("candidate checkout")
    if local_clean:
        proof_root = Path(tempfile.mkdtemp(prefix=".phase167-closeout-proof.", dir=ROOT / ".planning"))
        try:
            subprocess.run(
                [
                    "script/run_repository_evidence_environment.sh",
                    "--source-repository",
                    str(ROOT),
                    "--commit",
                    candidate_oid,
                    "--output-dir",
                    str(proof_root),
                ],
                cwd=ROOT,
                check=True,
            )
            evidence = json.loads((proof_root / "clean-checkout-run.json").read_text(encoding="utf-8"))
            if evidence.get("supported_code_sha") != candidate_oid or [item.get("result") for item in evidence.get("stages", [])] != ["PASS"] * 9:
                raise ValueError("clean checkout")
        finally:
            shutil.rmtree(proof_root, ignore_errors=True)


def self_test_closeout_schema() -> int:
    valid = {
        "schema_version": 1,
        "payload_source_oid": "a" * 40,
        "payload_source_tree": "b" * 40,
        "payload_scope": [{"path": "README.md", "mode": "100644", "blob": "c" * 40}],
        "self_excluded_manifest": {
            "path": CLOSEOUT_SCOPE_PATH,
            "expected_mode": "100644",
            "expected_schema_fields": sorted(CLOSEOUT_SCOPE_FIELDS),
        },
    }
    fixtures = [
        {**valid, "candidate_oid": "d" * 40},
        {**valid, "payload_source_oid": "short"},
        {**valid, "payload_scope": []},
        {**valid, "self_excluded_manifest": {**valid["self_excluded_manifest"], "expected_mode": "100755"}},
    ]
    for item in fixtures:
        structurally_valid = (
            set(item) == CLOSEOUT_SCOPE_FIELDS
            and item.get("schema_version") == 1
            and FULL_OID.fullmatch(str(item.get("payload_source_oid", ""))) is not None
            and isinstance(item.get("payload_scope"), list)
            and len(item["payload_scope"]) == 1
            and item.get("self_excluded_manifest") == valid["self_excluded_manifest"]
        )
        if structurally_valid:
            return 1
    return 0


def inventory_pr_snapshot(number: int) -> dict[str, Any]:
    query = (
        "{number:.number,state:.state,head_oid:.headRefOid,base_oid:.baseRefOid,"
        "merge_oid:(.mergeCommit.oid // null),"
        "check:([.statusCheckRollup[] | select(.name == \"Crosswake CI\") | "
        "{name:.name,status:(.status | ascii_upcase),conclusion:((.conclusion // \"\") | ascii_upcase)}] | first),"
        f"marker_ids:[.comments[] | select(.body == {json.dumps(DEFER_MARKER)}) | .id]}}"
    )
    value = gh_json(
        "pr", "view", str(number), "--json",
        "number,state,headRefOid,baseRefOid,mergeCommit,statusCheckRollup,comments", "--jq", query,
    )
    if isinstance(value.get("check"), dict):
        value["check"]["head_oid"] = value["head_oid"]
    return value


def open_pr_numbers() -> list[int]:
    values = gh_json("pr", "list", "--state", "open", "--limit", "100", "--json", "number")
    return sorted(int(item["number"]) for item in values)


def load_inventory_live() -> dict[str, Any]:
    repository, _branch, default_oid = default_snapshot()
    snapshots = {number: inventory_pr_snapshot(number) for number in set(ORDINARY_NUMBERS + [145, 148, 149])}
    checks = {number: snapshots[number]["check"] for number in ORDINARY_NUMBERS}
    markers = {number: snapshots[number]["marker_ids"] for number in DEFERRED_NUMBERS}
    return {
        "repository": repository,
        "default_oid": default_oid,
        "snapshots": snapshots,
        "checks": checks,
        "markers": markers,
        "open_numbers": open_pr_numbers(),
    }


def validate_inventory(value: dict[str, Any], live: dict[str, Any] | None = None) -> list[Problem]:
    problems: list[Problem] = []

    def reject(condition: bool, rule: str, number: int = 0) -> None:
        if condition:
            problems.append(Problem(rule, number))

    reject(set(value) != INVENTORY_FIELDS, "inventory_schema")
    reject(value.get("schema_version") != 1 or value.get("kind") != "phase167_pr_dispositions", "inventory_identity")
    reject(not isinstance(value.get("captured_at"), str) or re.fullmatch(r"20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z", value.get("captured_at", "")) is None, "captured_at")
    reject(not isinstance(value.get("default_oid"), str) or FULL_OID.fullmatch(value.get("default_oid", "")) is None, "default_oid_format")
    rows = value.get("ordinary_prs") if isinstance(value.get("ordinary_prs"), list) else []
    reject([row.get("number") for row in rows if isinstance(row, dict)] != ORDINARY_NUMBERS, "ordinary_set")
    for row in rows:
        number = row.get("number") if isinstance(row, dict) and isinstance(row.get("number"), int) else 0
        reject(not isinstance(row, dict) or set(row) != ORDINARY_FIELDS, "ordinary_schema", number)
        if not isinstance(row, dict):
            continue
        reject(FULL_OID.fullmatch(str(row.get("head_oid", ""))) is None, "ordinary_head", number)
        reject(FULL_OID.fullmatch(str(row.get("base_oid", ""))) is None, "ordinary_base", number)
        check_value = row.get("check_summary")
        reject(not isinstance(check_value, dict) or set(check_value) != CHECK_FIELDS, "check_schema", number)
        if isinstance(check_value, dict):
            reject(check_value.get("name") != "Crosswake CI", "check_name", number)
            reject(check_value.get("head_oid") != row.get("head_oid"), "check_head", number)
            reject(check_value.get("status") != "COMPLETED", "check_status", number)
            reject(check_value.get("conclusion") not in {"SUCCESS", "FAILURE"}, "check_conclusion", number)
        reject(tuple(row.get(field) for field in ("disposition", "reason", "next_gate")) != DISPOSITIONS.get(number), "ordinary_disposition", number)

    defers = value.get("release_only_deferred") if isinstance(value.get("release_only_deferred"), list) else []
    reject([item.get("number") for item in defers if isinstance(item, dict)] != DEFERRED_NUMBERS, "defer_set")
    marker_hash = sha256_bytes(DEFER_MARKER.encode("utf-8"))
    for item in defers:
        number = item.get("number") if isinstance(item, dict) and isinstance(item.get("number"), int) else 0
        reject(not isinstance(item, dict) or set(item) != DEFER_FIELDS, "defer_schema", number)
        if isinstance(item, dict):
            reject(not isinstance(item.get("comment_node_id"), str) or re.fullmatch(r"IC_[A-Za-z0-9_-]+", item["comment_node_id"]) is None, "defer_comment_id", number)
            reject(item.get("marker_sha256") != marker_hash, "defer_marker", number)

    recovery = value.get("recovery_transactions") if isinstance(value.get("recovery_transactions"), list) else []
    reject([item.get("number") for item in recovery if isinstance(item, dict)] != [145, 148, 110, 149], "recovery_set")
    reject([item.get("role") for item in recovery if isinstance(item, dict)] != RECOVERY_ROLES, "recovery_roles")
    for item in recovery:
        number = item.get("number") if isinstance(item, dict) and isinstance(item.get("number"), int) else 0
        reject(not isinstance(item, dict) or set(item) != RECOVERY_FIELDS, "recovery_schema", number)
        if not isinstance(item, dict):
            continue
        path = RECOVERY_PATHS.get(number)
        reject(item.get("receipt_path") != path, "recovery_receipt_path", number)
        if path is not None:
            reject(item.get("receipt_sha256") != file_sha256(path), "recovery_receipt_digest", number)
        reject(FULL_OID.fullmatch(str(item.get("head_oid", ""))) is None, "recovery_head", number)
        if number in {110, 148}:
            reject(item.get("state") != "CLOSED" or item.get("merge_oid") is not None or item.get("replacement_number") != 149, "failed_recovery", number)
        elif number == 145:
            reject(item.get("state") != "MERGED" or item.get("merge_oid") != "74fc15cc546b756c210b6cbbdcb2d7f77e3966bb" or item.get("replacement_number") is not None, "historical_recovery", number)
        elif number == 149:
            reject(item.get("state") != "MERGED" or item.get("merge_oid") != "e0959e8cb503eae7352c21a5d6693ef99d0d5a9b" or item.get("replacement_number") is not None, "replacement_recovery", number)

    serialized = json.dumps(value, sort_keys=True, separators=(",", ":")).lower()
    reject(any(token in serialized for token in FORBIDDEN_EVIDENCE), "privacy_sentinel")

    if live is not None:
        reject(value.get("default_oid") != live.get("default_oid"), "default_oid_drift")
        reject(live.get("open_numbers") != DEFERRED_NUMBERS, "unknown_open_pr")
        for row in rows:
            if not isinstance(row, dict) or row.get("number") not in ORDINARY_NUMBERS:
                continue
            number = int(row["number"])
            snapshot = live["snapshots"].get(number, {})
            reject(snapshot.get("head_oid") != row.get("head_oid"), "live_head_drift", number)
            reject(snapshot.get("base_oid") != row.get("base_oid"), "live_base_drift", number)
            expected_state = "OPEN" if number in DEFERRED_NUMBERS else ("CLOSED" if number == 110 else "MERGED")
            reject(snapshot.get("state") != expected_state, "live_state", number)
            if number == 110:
                reject(snapshot.get("merge_oid") is not None, "failed_pr_merged", number)
            check_value = live["checks"].get(number)
            reject(check_value != row.get("check_summary"), "live_check_drift", number)
        for item in defers:
            if not isinstance(item, dict) or item.get("number") not in DEFERRED_NUMBERS:
                continue
            receipts = live["markers"].get(item["number"], [])
            reject(receipts != [item.get("comment_node_id")], "live_defer_marker", item["number"])
        for item in recovery:
            if not isinstance(item, dict) or item.get("number") not in live["snapshots"]:
                continue
            snapshot = live["snapshots"][item["number"]]
            reject(snapshot.get("head_oid") != item.get("head_oid") or snapshot.get("state") != item.get("state") or snapshot.get("merge_oid") != item.get("merge_oid"), "live_recovery_drift", item["number"])
    return problems


def valid_inventory_fixture() -> dict[str, Any]:
    oid = lambda char: char * 40
    rows = []
    for index, number in enumerate(ORDINARY_NUMBERS):
        disposition, reason, gate = DISPOSITIONS[number]
        head = oid(format(index + 1, "x"))
        rows.append({
            "number": number,
            "head_oid": head,
            "base_oid": oid("a"),
            "check_summary": {"name": "Crosswake CI", "head_oid": head, "status": "COMPLETED", "conclusion": "SUCCESS"},
            "disposition": disposition,
            "reason": reason,
            "next_gate": gate,
        })
    defers = [{"number": number, "comment_node_id": f"IC_fixture_{number}", "marker_sha256": sha256_bytes(DEFER_MARKER.encode())} for number in DEFERRED_NUMBERS]
    resolution_path = RECOVERY_PATHS[145]
    pr110_path = RECOVERY_PATHS[110]
    recovery = [
        {"role": "historical_merged", "number": 145, "head_oid": "a6e2622acaaa82e82eb33a21760e75db2e51a281", "state": "MERGED", "merge_oid": "74fc15cc546b756c210b6cbbdcb2d7f77e3966bb", "replacement_number": None, "receipt_path": resolution_path, "receipt_sha256": file_sha256(resolution_path)},
        {"role": "failed_closed_unmerged", "number": 148, "head_oid": "cc5286da6467c6d582f9a9585272360fcc1e4927", "state": "CLOSED", "merge_oid": None, "replacement_number": 149, "receipt_path": resolution_path, "receipt_sha256": file_sha256(resolution_path)},
        {"role": "failed_closed_unmerged", "number": 110, "head_oid": "85e6aeec41b9a53840f0a2315c16c4390cef1878", "state": "CLOSED", "merge_oid": None, "replacement_number": 149, "receipt_path": pr110_path, "receipt_sha256": file_sha256(pr110_path)},
        {"role": "replacement_merged", "number": 149, "head_oid": "b489905d0f735e88268905607390021256e405b8", "state": "MERGED", "merge_oid": "e0959e8cb503eae7352c21a5d6693ef99d0d5a9b", "replacement_number": None, "receipt_path": resolution_path, "receipt_sha256": file_sha256(resolution_path)},
    ]
    return {"schema_version": 1, "kind": "phase167_pr_dispositions", "captured_at": "2026-09-12T00:00:00Z", "default_oid": oid("b"), "ordinary_prs": rows, "release_only_deferred": defers, "recovery_transactions": recovery}


def self_test_inventory() -> int:
    valid = valid_inventory_fixture()
    if validate_inventory(valid):
        print("phase167-pr-dispositions-self-test: FAIL fixture=valid")
        return 1
    fixtures: list[tuple[str, Callable[[dict[str, Any]], None]]] = [
        ("extra_row", lambda value: value["ordinary_prs"].append(copy.deepcopy(value["ordinary_prs"][-1]))),
        ("missing_row", lambda value: value["ordinary_prs"].pop()),
        ("stale_head", lambda value: value["ordinary_prs"][0].update(head_oid="abc")),
        ("recovery_conflated", lambda value: value["recovery_transactions"].pop()),
        ("replacement_missing", lambda value: value["recovery_transactions"].pop()),
        ("failed_merged", lambda value: value["recovery_transactions"][1].update(merge_oid="f" * 40)),
        ("release_mutation", lambda value: value["ordinary_prs"][0].update(disposition="merged")),
        ("missing_marker", lambda value: value["release_only_deferred"].pop()),
        ("unknown_key", lambda value: value.update(title="untrusted")),
        ("privacy", lambda value: value.update(source_url="https://invalid.example")),
    ]
    for name, mutate in fixtures:
        candidate = copy.deepcopy(valid)
        mutate(candidate)
        if not validate_inventory(candidate):
            print(f"phase167-pr-dispositions-self-test: FAIL fixture={name}")
            return 1
    if self_test_closeout_schema() != 0:
        print("phase167-pr-dispositions-self-test: FAIL fixture=closeout_schema")
        return 1
    print(f"phase167-pr-dispositions-self-test: PASS count={len(fixtures) + 5}")
    return 0


def default_snapshot() -> tuple[str, str, str]:
    value = gh_json(
        "api", "graphql", "-f",
        "query=query { repository(owner:\"szTheory\",name:\"crosswake\") { nameWithOwner defaultBranchRef { name target { oid } } } }",
        "--jq", ".data.repository | {repository:.nameWithOwner,branch:.defaultBranchRef.name,oid:.defaultBranchRef.target.oid}",
    )
    return value["repository"], value["branch"], value["oid"]


def merge_is_reachable(repository: str, merge_oid: str, default_oid: str) -> bool:
    subprocess.run(["git", "fetch", "--quiet", "--no-tags", "origin", default_oid], cwd=ROOT, check=True)
    return subprocess.run(["git", "merge-base", "--is-ancestor", merge_oid, default_oid], cwd=ROOT).returncode == 0


def has_supersession_marker(repository: str, original: int) -> bool:
    marker = SUPERSESSION_MARKERS.get(original)
    if marker is None:
        return False
    endpoint = f"repos/{repository}/issues/{original}/comments?per_page=100"
    query = f"[.[].body == {json.dumps(marker)}] | any"
    return bool(gh_json("api", "--paginate", "-H", "Accept: application/vnd.github+json", endpoint, "--jq", query))


def load_live(receipt: dict[str, Any]) -> dict[str, Any]:
    original = int(receipt["original_number"])
    candidate = int(receipt["candidate_number"])
    repository, _branch, default_oid = default_snapshot()
    candidate_snapshot = pr_snapshot(candidate)
    original_snapshot = candidate_snapshot if candidate == original else pr_snapshot(original)
    return {
        "original": original_snapshot,
        "candidate": candidate_snapshot,
        "check": check_snapshot(repository, str(receipt["tested_head_oid"])),
        "default_oid": default_oid,
        "merge_reachable": merge_is_reachable(repository, str(receipt["merge_commit_oid"]), default_oid),
        "supersession_marker": has_supersession_marker(repository, original) if candidate != original else False,
    }


def self_test_resolution() -> int:
    oid_a = "a" * 40
    oid_b = "b" * 40
    oid_c = "c" * 40
    receipt = {
        "schema_version": 1,
        "original_number": 121,
        "candidate_number": 121,
        "tested_head_oid": oid_a,
        "tested_base_oid": oid_b,
        "merge_commit_oid": oid_c,
        "fresh_default_oid": oid_c,
        "crosswake_ci": "SUCCESS",
        "scope_profile": "setup_java_v6",
        "intent_commit_count": 1,
        "disposition": "merged",
        "replacement_for": None,
        "supersession_receipt": False,
    }
    live = {
        "original": {"number": 121, "state": "MERGED", "head_oid": oid_a},
        "candidate": {
            "number": 121,
            "state": "MERGED",
            "head_oid": oid_a,
            "base_oid": oid_b,
            "merge_commit_oid": oid_c,
            "files": sorted(SCOPE_PROFILES["setup_java_v6"]),
            "commit_count": 1,
        },
        "check": {"name": "Crosswake CI", "head_oid": oid_a, "status": "COMPLETED", "conclusion": "SUCCESS"},
        "default_oid": oid_c,
        "merge_reachable": True,
        "supersession_marker": False,
    }
    fixtures = {
        "non_full_oid": ({**receipt, "tested_head_oid": "abc"}, live),
        "head_drift": (receipt, {**live, "candidate": {**live["candidate"], "head_oid": oid_b}}),
        "base_drift": (receipt, {**live, "candidate": {**live["candidate"], "base_oid": oid_a}}),
        "missing_check": (receipt, {**live, "check": None}),
        "pending_check": (receipt, {**live, "check": {**live["check"], "status": "IN_PROGRESS"}}),
        "cancelled_check": (receipt, {**live, "check": {**live["check"], "conclusion": "CANCELLED"}}),
        "unsuccessful_check": (receipt, {**live, "check": {**live["check"], "conclusion": "FAILURE"}}),
        "unmerged_candidate": (receipt, {**live, "candidate": {**live["candidate"], "state": "OPEN"}}),
        "unreachable_merge": (receipt, {**live, "merge_reachable": False}),
        "scope_drift": (receipt, {**live, "candidate": {**live["candidate"], "files": []}}),
        "commit_count_drift": (receipt, {**live, "candidate": {**live["candidate"], "commit_count": 2}}),
        "extra_field": ({**receipt, "title": "untrusted"}, live),
        "default_drift": (receipt, {**live, "default_oid": oid_b}),
        "check_head_drift": (receipt, {**live, "check": {**live["check"], "head_oid": oid_b}}),
    }
    if validate_resolution(receipt, live):
        print("FAIL valid_resolution")
        return 1
    for name, (candidate_receipt, candidate_live) in fixtures.items():
        if not validate_resolution(candidate_receipt, candidate_live):
            print(f"FAIL {name}")
            return 1
    replacement_receipt = {
        **receipt,
        "candidate_number": 201,
        "disposition": "superseded",
        "replacement_for": 121,
        "supersession_receipt": True,
    }
    replacement_live = {
        **live,
        "original": {"number": 121, "state": "CLOSED", "head_oid": oid_b, "merge_commit_oid": None},
        "candidate": {**live["candidate"], "number": 201},
        "supersession_marker": True,
    }
    if validate_resolution(replacement_receipt, replacement_live):
        print("FAIL valid_supersession")
        return 1
    for profile, files in SCOPE_PROFILES.items():
        profile_receipt = {
            **receipt,
            "original_number": 105 if profile == "packstore_waiter_clarity" else 121,
            "candidate_number": 105 if profile == "packstore_waiter_clarity" else 121,
            "scope_profile": profile,
        }
        profile_live = {
            **live,
            "original": {
                **live["original"],
                "number": profile_receipt["original_number"],
            },
            "candidate": {
                **live["candidate"],
                "number": profile_receipt["candidate_number"],
                "files": sorted(files),
            },
        }
        if validate_resolution(profile_receipt, profile_live):
            print(f"FAIL valid_scope_{profile}")
            return 1
    supersession_fixtures = {
        "unauthorized_replacement": ({**replacement_receipt, "original_number": 105, "replacement_for": 105}, replacement_live),
        "unresolved_original": (replacement_receipt, {**replacement_live, "original": {**replacement_live["original"], "state": "OPEN"}}),
        "missing_supersession_marker": (replacement_receipt, {**replacement_live, "supersession_marker": False}),
    }
    for name, (candidate_receipt, candidate_live) in supersession_fixtures.items():
        if not validate_resolution(candidate_receipt, candidate_live):
            print(f"FAIL {name}")
            return 1
    count = len(fixtures) + len(supersession_fixtures) + len(SCOPE_PROFILES) + 2
    print(f"phase167-pr-self-test: PASS count={count}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--self-test-resolution", action="store_true")
    parser.add_argument("--verify-resolution", type=Path)
    parser.add_argument("--verify", type=Path)
    parser.add_argument("--verify-closeout-candidate", type=Path)
    parser.add_argument("--candidate", default="HEAD")
    parser.add_argument("--local-clean-checkout", action="store_true")
    parser.add_argument("--live", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test_inventory()
    if args.self_test_resolution:
        return self_test_resolution()
    if args.verify_closeout_candidate is not None:
        try:
            raw = json.loads(args.verify_closeout_candidate.read_text(encoding="utf-8"))
            if not isinstance(raw, dict):
                raise ValueError("scope must be an object")
            verify_closeout_candidate(raw, args.candidate, args.local_clean_checkout)
        except (OSError, UnicodeDecodeError, json.JSONDecodeError, ValueError, KeyError, TypeError, subprocess.CalledProcessError):
            print("phase167-closeout-candidate: FAIL closed_failure")
            return 1
        print("phase167-closeout-candidate: PASS derived_candidate=runtime")
        return 0
    if args.verify is not None:
        try:
            raw = json.loads(args.verify.read_text(encoding="utf-8"))
            if not isinstance(raw, dict):
                raise ValueError("inventory must be an object")
            problems = validate_inventory(raw, load_inventory_live() if args.live else None)
        except (OSError, UnicodeDecodeError, json.JSONDecodeError, ValueError, KeyError, TypeError, subprocess.CalledProcessError):
            print(Problem("inventory_query_failed", 0).render())
            return 1
        if problems:
            for problem in sorted(set(problems), key=lambda item: (item.rule, item.number)):
                print(problem.render())
            return 1
        print(f"phase167-pr-dispositions: PASS ordinary={len(raw['ordinary_prs'])} recovery={len(raw['recovery_transactions'])}")
        return 0
    if args.verify_resolution is None or not args.live:
        parser.error("select one fixed verification mode")
    try:
        raw = json.loads(args.verify_resolution.read_text(encoding="utf-8"))
        if not isinstance(raw, dict):
            raise ValueError("receipt must be an object")
        problems = validate_resolution(raw, load_live(raw))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError, ValueError, KeyError, TypeError, subprocess.CalledProcessError):
        print(Problem("live_query_failed", 0).render())
        return 1
    if problems:
        for problem in sorted(set(problems), key=lambda item: (item.rule, item.number)):
            print(problem.render())
        return 1
    print(f"phase167-pr: PASS pr={raw['original_number']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
