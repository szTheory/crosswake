#!/usr/bin/env python3
"""Fail-closed exact-SHA validation for Phase 167 pull-request receipts."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
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
    endpoint = f"repos/{repository}/commits/{head_oid}/check-runs?filter=latest&per_page=100"
    query = (
        '[.check_runs[] | select(.name == "Crosswake CI") | '
        "{name:.name,head_oid:.head_sha,status:(.status | ascii_upcase),"
        "conclusion:((.conclusion // \"\") | ascii_upcase)}] | first"
    )
    return gh_json("api", "-H", "Accept: application/vnd.github+json", endpoint, "--jq", query)


def default_snapshot() -> tuple[str, str, str]:
    repository = gh_json(
        "repo", "view", "--json", "nameWithOwner,defaultBranchRef", "--jq",
        "{repository:.nameWithOwner,branch:.defaultBranchRef.name}",
    )
    branch = repository["branch"]
    endpoint = f"repos/{repository['repository']}/branches/{urllib.parse.quote(branch, safe='')}"
    authority = gh_json("api", "-H", "Accept: application/vnd.github+json", endpoint, "--jq", "{oid:.commit.sha}")
    return repository["repository"], branch, authority["oid"]


def merge_is_reachable(repository: str, merge_oid: str, default_oid: str) -> bool:
    endpoint = f"repos/{repository}/compare/{merge_oid}...{default_oid}"
    result = gh_json(
        "api", "-H", "Accept: application/vnd.github+json", endpoint, "--jq",
        "{status:.status,behind_by:.behind_by}",
    )
    return result.get("status") in {"ahead", "identical"} and result.get("behind_by") == 0


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
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test-resolution", action="store_true")
    parser.add_argument("--verify-resolution", type=Path)
    parser.add_argument("--live", action="store_true")
    args = parser.parse_args()
    if args.self_test_resolution:
        return self_test_resolution()
    if args.verify_resolution is None or not args.live:
        parser.error("use --self-test-resolution or --verify-resolution PATH --live")
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
