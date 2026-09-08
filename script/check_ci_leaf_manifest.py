#!/usr/bin/env python3
"""Fail-closed structural proof for the Crosswake CI manifest and umbrella."""

from __future__ import annotations

import argparse
import copy
import json
import sys
import unittest
from dataclasses import dataclass
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "script/ci_leaf_manifest.json"
DEFAULT_WORKFLOW = ROOT / ".github/workflows/crosswake-ci.yml"
UMBRELLA_ID = "merge-blocking-crosswake-ci"
UMBRELLA_NAME = "Crosswake CI"


@dataclass(frozen=True)
class Problem:
    kind: str
    member: str
    detail: str

    def render(self) -> str:
        return f"ci-leaf-manifest: FAIL: {self.kind} member={self.member} detail={self.detail}"


def load_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def load_workflow(path: Path) -> object:
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def literal_name(job_id: str, job: object, problems: list[Problem]) -> str | None:
    if not isinstance(job, dict):
        problems.append(Problem("invalid_job", job_id, "job declaration must be a mapping"))
        return None
    name = job.get("name", job_id)
    if not isinstance(name, str) or not name or "${{" in name:
        problems.append(Problem("invalid_display_name", job_id, "name must be one literal string"))
        return None
    return name


def record_map(rows, id_key, exact_keys, kind, problems):
    if not isinstance(rows, list) or not rows:
        problems.append(Problem(f"empty_{kind}", kind, "authority array must be non-empty"))
        return {}
    result = {}
    for index, row in enumerate(rows):
        member = f"{kind}[{index}]"
        if not isinstance(row, dict) or set(row) != exact_keys:
            problems.append(Problem(f"invalid_{kind}_record", member, "record keys do not match schema"))
            continue
        identifier = row.get(id_key)
        if not isinstance(identifier, str) or not identifier:
            problems.append(Problem(f"invalid_{kind}_id", member, "identifier must be non-empty"))
            continue
        if identifier in result:
            problems.append(Problem(f"duplicate_{kind}", identifier, "identifier occurs more than once"))
        result[identifier] = row
    if list(result) != sorted(result):
        problems.append(Problem(f"unordered_{kind}", kind, "records must be ordered by identifier"))
    return result


def validate(manifest: object, workflow: object, producer_records=None) -> list[Problem]:
    problems: list[Problem] = []
    expected_top = {"schema_version", "proof_leaves", "required_control_nodes", "legacy_compatibility_contexts"}
    if not isinstance(manifest, dict) or set(manifest) != expected_top or manifest.get("schema_version") != 2:
        return [Problem("invalid_manifest", "manifest", "top-level schema must be version 2 and closed")]

    proofs = record_map(manifest["proof_leaves"], "leaf_id", {"leaf_id", "display_name", "family", "remediation_command", "irrelevance_reason"}, "proof_leaves", problems)
    controls = record_map(manifest["required_control_nodes"], "node_id", {"node_id", "display_name", "required_result"}, "required_control_nodes", problems)
    legacy = manifest["legacy_compatibility_contexts"]
    if not isinstance(legacy, list):
        problems.append(Problem("invalid_legacy_compatibility_contexts", "legacy", "must be an array"))
        legacy = []
    if "classify-change" not in controls:
        problems.append(Problem("missing_classifier_control", "classify-change", "required control is absent"))
    for member in sorted(set(proofs) & set(controls)):
        problems.append(Problem("authority_overlap", member, "member is both proof and control"))

    for leaf_id, row in proofs.items():
        for field in ("display_name", "family", "remediation_command"):
            if not isinstance(row[field], str) or not row[field] or "${{" in row[field]:
                problems.append(Problem(f"invalid_{field}", leaf_id, "field must be a non-empty literal"))
        reason = row["irrelevance_reason"]
        if reason is not None and (not isinstance(reason, str) or not reason):
            problems.append(Problem("invalid_irrelevance_reason", leaf_id, "must be null or non-empty"))
    for node_id, row in controls.items():
        if row["required_result"] != "success":
            problems.append(Problem("invalid_control_result", node_id, "control nodes require success"))

    if not isinstance(workflow, dict) or not isinstance(workflow.get("jobs"), dict):
        problems.append(Problem("missing_jobs", "jobs", "workflow jobs mapping is required"))
        return problems
    jobs = workflow["jobs"]
    umbrella = jobs.get(UMBRELLA_ID)
    if not isinstance(umbrella, dict):
        problems.append(Problem("missing_umbrella", UMBRELLA_ID, "literal umbrella job is required"))
        return problems

    expected = set(proofs) | set(controls)
    needs = umbrella.get("needs")
    if not isinstance(needs, list) or not needs or not all(isinstance(item, str) for item in needs):
        problems.append(Problem("invalid_static_needs", UMBRELLA_ID, "needs must be a non-empty literal list"))
        needs = []
    if len(needs) != len(set(needs)):
        problems.append(Problem("duplicate_static_need", UMBRELLA_ID, "needs contains duplicates"))
    for member in sorted(expected - set(needs)):
        problems.append(Problem("missing_static_need", member, "manifest member is absent from umbrella needs"))
    for member in sorted(set(needs) - expected):
        problems.append(Problem("extra_static_need", member, "umbrella need is absent from manifest authority"))

    legacy_ids = {row.get("job_id") for row in legacy if isinstance(row, dict) and isinstance(row.get("job_id"), str)}
    governed_jobs = set(jobs) - {UMBRELLA_ID} - legacy_ids
    for member in sorted(expected - governed_jobs):
        problems.append(Problem("missing_job", member, "manifest member has no workflow job"))
    for member in sorted(governed_jobs - expected):
        problems.append(Problem("extra_job", member, "workflow job is outside manifest authority"))

    for identifier, row in {**proofs, **controls}.items():
        actual = literal_name(identifier, jobs.get(identifier), problems)
        if actual is not None and actual != row["display_name"]:
            problems.append(Problem("display_name_mismatch", identifier, f"workflow={actual!r}"))
    umbrella_name = literal_name(UMBRELLA_ID, umbrella, problems)
    if umbrella_name != UMBRELLA_NAME:
        problems.append(Problem("umbrella_name_mismatch", UMBRELLA_ID, f"workflow={umbrella_name!r}"))
    if str(umbrella.get("if", "")).replace("${{", "").replace("}}", "").strip() != "always()":
        problems.append(Problem("umbrella_not_always", UMBRELLA_ID, "if must be always()"))
    umbrella_text = yaml.safe_dump(umbrella, sort_keys=False)
    for token in ("actions/checkout", "uses: ./", "pip install", "setup-", "npm install", "mix deps.get"):
        if token in umbrella_text:
            problems.append(Problem("umbrella_setup_forbidden", token, "umbrella must remain checkout-free"))

    if producer_records is not None:
        producers = [row for row in producer_records if row[0] == UMBRELLA_NAME]
        if len(producers) != 1 or producers[0][2] != UMBRELLA_ID:
            problems.append(Problem("umbrella_producer_count", UMBRELLA_NAME, f"observed={len(producers)}"))
    return problems


def production_producers():
    sys.path.insert(0, str(ROOT / "script"))
    from list_merge_blocking_checks import inventory
    return inventory()


class ManifestSelfTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = load_json(DEFAULT_MANIFEST)
        cls.workflow = load_workflow(DEFAULT_WORKFLOW)

    def assert_problem(self, mutate, expected_kind: str, member: str) -> None:
        manifest = copy.deepcopy(self.manifest)
        workflow = copy.deepcopy(self.workflow)
        mutate(manifest, workflow)
        problems = validate(manifest, workflow, [(UMBRELLA_NAME, str(DEFAULT_WORKFLOW), UMBRELLA_ID)])
        self.assertTrue(any(p.kind == expected_kind and p.member == member for p in problems), problems)

    def test_production_contract(self) -> None:
        records, inventory_errors = production_producers()
        self.assertEqual(inventory_errors, [])
        self.assertEqual(validate(self.manifest, self.workflow, records), [])

    def test_missing_extra_and_empty_authority(self) -> None:
        self.assert_problem(lambda m, _w: m["proof_leaves"].clear(), "empty_proof_leaves", "proof_leaves")
        self.assert_problem(lambda m, _w: m["required_control_nodes"].clear(), "empty_required_control_nodes", "required_control_nodes")
        self.assert_problem(lambda _m, w: w["jobs"][UMBRELLA_ID].update(needs=[]), "invalid_static_needs", UMBRELLA_ID)
        self.assert_problem(lambda m, _w: m["required_control_nodes"].clear(), "missing_classifier_control", "classify-change")
        self.assert_problem(lambda _m, w: w["jobs"].pop(UMBRELLA_ID), "missing_umbrella", UMBRELLA_ID)
        self.assert_problem(lambda _m, w: w["jobs"][UMBRELLA_ID]["needs"].append("invented"), "extra_static_need", "invented")

    def test_each_side_reports_the_exact_divergent_member(self) -> None:
        self.assert_problem(
            lambda _m, w: w["jobs"][UMBRELLA_ID]["needs"].remove("documentation-contracts"),
            "missing_static_need",
            "documentation-contracts",
        )
        self.assert_problem(
            lambda _m, w: w["jobs"].pop("documentation-contracts"),
            "missing_job",
            "documentation-contracts",
        )
        self.assert_problem(
            lambda _m, w: w["jobs"].update({"invented": {"name": "invented"}}),
            "extra_job",
            "invented",
        )

    def test_declaration_order_is_set_semantics(self) -> None:
        manifest = copy.deepcopy(self.manifest)
        workflow = copy.deepcopy(self.workflow)
        manifest["proof_leaves"].reverse()
        workflow["jobs"][UMBRELLA_ID]["needs"].reverse()
        meaningful = [p for p in validate(manifest, workflow) if not p.kind.startswith("unordered_")]
        self.assertEqual(meaningful, [])


def run_self_test() -> int:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ManifestSelfTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print("ci leaf manifest self-test: pass")
        return 0
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return run_self_test()
    parser.error("--self-test is required")


if __name__ == "__main__":
    sys.exit(main())
