#!/usr/bin/env python3
"""Fail-closed exact-SHA validation for Phase 167 pull-request receipts."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
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
    "package_reconciliation": set(),
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
    """RED seam: the GREEN commit supplies closed receipt/live validation."""
    return []


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
    }
    if validate_resolution(receipt, live):
        print("FAIL valid_resolution")
        return 1
    for name, (candidate_receipt, candidate_live) in fixtures.items():
        if not validate_resolution(candidate_receipt, candidate_live):
            print(f"FAIL {name}")
            return 1
    print(f"phase167-pr-self-test: PASS count={len(fixtures) + 1}")
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
    print(Problem("live_validation_not_implemented", 0).render())
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
