#!/usr/bin/env python3
"""Fail-closed structural proof for the Crosswake CI manifest and umbrella."""

from __future__ import annotations

import argparse
import copy
import json
import re
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
JOB_LIMIT = 256
NEEDS_BYTE_LIMIT = 32 * 1024
FINAL_PROOF_LEAVES = (
    "android-generated-shell-unit",
    "android-package-unit",
    "brand-structural",
    "collateral-binaries-guard",
    "documentation-contracts",
    "e2e-proof",
    "guard-01-contract-drift-test",
    "guard-01-e2e-honesty",
    "guard-02-generate-and-diff",
    "guard-02-prod-route-absence",
    "hex-page-proof",
    "ios-mirror-parity-proof",
    "ios-package-unit",
    "phase10-proof",
    "phase130-companion-engine-absent-proof",
    "phase130-core-hermetic-proof",
    "phase132-companion-engine-absent-proof",
    "phase132-core-hermetic-proof",
    "phase18-elixir-android-proof",
    "phase18-ios-proof",
    "phase23-commerce-proof",
    "phase34-commerce-proof",
    "phase41-gating-proof",
    "phase43-rulestead-proof",
    "phase45-rindle-proof",
    "phase48-provider-adapter-proof",
    "phase5-proof",
    "phase52-operator-proof",
    "phase58-auth-closeout-proof",
    "phase67-android-jvm-proof",
    "phase69-closeout-proof",
    "phase70-subscription-saas-proof",
    "phase71-notification-workflow-proof",
    "phase73-auth-sensitive-admin-workflow-proof",
    "phase74-offline-draft-recovery-proof",
    "phase75-closeout-gate",
    "phase79-android-proof",
    "phase79-ios-proof",
    "phase96-threadline-docs-contract-proof",
    "proof-aggregator-negative-control",
    "proof-dependency-security",
    "proof-requires-example-host",
    "release-as-staleness-proof",
    "route-tour-proof",
)
FINAL_CONTROL_NODES = ("classify-change",)
FINAL_NEEDS = tuple(sorted(FINAL_PROOF_LEAVES + FINAL_CONTROL_NODES))


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
    legacy = record_map(
        manifest["legacy_compatibility_contexts"],
        "job_id",
        {"job_id", "display_context", "needs_target"},
        "legacy_compatibility_contexts",
        problems,
    )
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

    for leaf_id, row in proofs.items():
        job_text = yaml.safe_dump(jobs.get(leaf_id, {}), sort_keys=False)
        normalized_job = re.sub(r"\s+", " ", job_text)
        normalized_command = re.sub(r"\s+", " ", row["remediation_command"])
        if normalized_command not in normalized_job:
            problems.append(Problem("remediation_mismatch", leaf_id, "literal remediation command is absent from job"))
        if row["irrelevance_reason"] is not None:
            condition = str(jobs.get(leaf_id, {}).get("if", ""))
            if "classification == 'full_proof'" not in condition:
                problems.append(Problem("executable_leaf_condition", leaf_id, "leaf is not closed on full_proof"))

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

    legacy_ids = set(legacy)
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

    for leaf_id, row in proofs.items():
        reason = row["irrelevance_reason"]
        if reason is not None and (leaf_id not in umbrella_text or reason not in umbrella_text):
            problems.append(Problem("umbrella_irrelevance_missing", leaf_id, "leaf and manifest reason must be explicit"))

    for job_id, row in legacy.items():
        job = jobs.get(job_id)
        if not isinstance(job, dict):
            problems.append(Problem("missing_compatibility_job", job_id, "manifest context has no workflow job"))
            continue
        actual = literal_name(job_id, job, problems)
        if actual is not None and actual != row["display_context"]:
            problems.append(Problem("compatibility_display_mismatch", job_id, f"workflow={actual!r}"))
        target = row["needs_target"]
        if target not in set(proofs) | {UMBRELLA_ID}:
            problems.append(Problem("compatibility_target_invalid", job_id, f"target={target!r}"))
        if job.get("needs") != [target]:
            problems.append(Problem("compatibility_needs_mismatch", job_id, f"expected={[target]!r}"))
        if str(job.get("if", "")).replace("${{", "").replace("}}", "").strip() != "always()":
            problems.append(Problem("compatibility_not_always", job_id, "if must be always()"))
        text = yaml.safe_dump(job, sort_keys=False)
        for token in ("actions/checkout", "uses: ./", "setup-", "mix deps.get"):
            if token in text:
                problems.append(Problem("compatibility_setup_forbidden", job_id, f"contains {token}"))

    if producer_records is not None:
        producers = [row for row in producer_records if row[0] == UMBRELLA_NAME]
        if len(producers) != 1 or producers[0][2] != UMBRELLA_ID:
            problems.append(Problem("umbrella_producer_count", UMBRELLA_NAME, f"observed={len(producers)}"))
    return problems


def production_producers():
    sys.path.insert(0, str(ROOT / "script"))
    from list_merge_blocking_checks import inventory
    return inventory()


def serialized_needs_bytes(needs_fixture: object) -> int:
    return len(
        json.dumps(needs_fixture, sort_keys=True, separators=(",", ":")).encode("utf-8")
    )


def validate_maximum_shape(workflow: object, needs_fixture: object) -> list[Problem]:
    problems: list[Problem] = []
    if not isinstance(workflow, dict) or not isinstance(workflow.get("jobs"), dict):
        return [Problem("missing_jobs", "jobs", "maximum workflow requires literal jobs")]
    jobs = workflow["jobs"]
    expected_jobs = set(FINAL_NEEDS) | {UMBRELLA_ID}
    for member in sorted(expected_jobs - set(jobs)):
        problems.append(Problem("maximum_missing_job", member, "reviewed final job is absent"))
    for member in sorted(set(jobs) - expected_jobs):
        problems.append(Problem("maximum_extra_job", member, "job is outside reviewed final authority"))
    if len(jobs) >= JOB_LIMIT:
        problems.append(Problem("job_budget", str(len(jobs)), f"must be below {JOB_LIMIT}"))

    for identifier in FINAL_NEEDS:
        job = jobs.get(identifier)
        actual_name = literal_name(identifier, job, problems)
        if actual_name is not None and actual_name != identifier:
            problems.append(Problem("maximum_display_name_mismatch", identifier, f"workflow={actual_name!r}"))
        if isinstance(job, dict) and "strategy" in job:
            problems.append(Problem("dynamic_matrix_forbidden", identifier, "authority jobs must be literal"))

    umbrella = jobs.get(UMBRELLA_ID)
    if not isinstance(umbrella, dict):
        problems.append(Problem("missing_umbrella", UMBRELLA_ID, "maximum umbrella is absent"))
    else:
        needs = umbrella.get("needs")
        if needs != list(FINAL_NEEDS):
            actual = set(needs) if isinstance(needs, list) else set()
            for member in sorted(set(FINAL_NEEDS) - actual):
                problems.append(Problem("maximum_missing_need", member, "reviewed member is absent"))
            for member in sorted(actual - set(FINAL_NEEDS)):
                problems.append(Problem("maximum_extra_need", member, "need is undeclared"))
            if actual == set(FINAL_NEEDS):
                problems.append(Problem("maximum_needs_order", UMBRELLA_ID, "needs must be deterministically sorted"))
        if str(umbrella.get("if", "")).replace("${{", "").replace("}}", "").strip() != "always()":
            problems.append(Problem("umbrella_not_always", UMBRELLA_ID, "if must be always()"))
        env = umbrella.get("steps", [{}])[0].get("env", {}) if isinstance(umbrella.get("steps"), list) else {}
        if env.get("NEEDS_JSON") != "${{ toJSON(needs) }}":
            problems.append(Problem("needs_handoff", "NEEDS_JSON", "must be exact toJSON(needs)"))
        text = yaml.safe_dump(umbrella, sort_keys=False)
        if "json.loads" not in text or "classify-change" not in text:
            problems.append(Problem("inline_evaluator_missing", UMBRELLA_ID, "closed evaluator is absent"))
        for token in ("actions/checkout", "uses: ./", "setup-", " install ", "pip install", "npm install"):
            if token in text:
                problems.append(Problem("maximum_setup_forbidden", token, "umbrella must be checkout-free"))

    if not isinstance(needs_fixture, dict):
        problems.append(Problem("invalid_needs_fixture", "needs", "fixture must be an object"))
    else:
        for member in sorted(set(FINAL_NEEDS) - set(needs_fixture)):
            problems.append(Problem("needs_fixture_missing", member, "worst-case record is absent"))
        for member in sorted(set(needs_fixture) - set(FINAL_NEEDS)):
            problems.append(Problem("needs_fixture_extra", member, "record is outside reviewed authority"))
        if list(needs_fixture) != list(FINAL_NEEDS):
            problems.append(Problem("needs_fixture_order", "needs", "records must be deterministically sorted"))
        for member in FINAL_NEEDS:
            record = needs_fixture.get(member)
            if not isinstance(record, dict) or record.get("result") != "action_required":
                problems.append(Problem("needs_fixture_result", member, "use longest closed result action_required"))
            elif member != "classify-change" and record.get("outputs", {}).get("irrelevance_reason") != "all_changed_paths_allowlisted":
                problems.append(Problem("needs_fixture_irrelevance", member, "use longest closed irrelevance reason"))
        size = serialized_needs_bytes(needs_fixture)
        if size >= NEEDS_BYTE_LIMIT:
            problems.append(Problem("needs_payload_budget", str(size), f"must be below {NEEDS_BYTE_LIMIT}"))
    return problems


def maximum_negative_controls(workflow: dict, needs_fixture: dict) -> list[Problem]:
    observed: list[Problem] = []

    missing_control = copy.deepcopy(workflow)
    missing_control["jobs"].pop("classify-change")
    observed.extend(validate_maximum_shape(missing_control, needs_fixture))

    extra_need = copy.deepcopy(workflow)
    extra_need["jobs"][UMBRELLA_ID]["needs"].append("invented-need")
    observed.extend(validate_maximum_shape(extra_need, needs_fixture))

    setup = copy.deepcopy(workflow)
    setup["jobs"][UMBRELLA_ID]["steps"].insert(0, {"uses": "actions/checkout@v7"})
    observed.extend(validate_maximum_shape(setup, needs_fixture))

    too_many = copy.deepcopy(workflow)
    while len(too_many["jobs"]) < JOB_LIMIT:
        identifier = f"budget-probe-{len(too_many['jobs']):03d}"
        too_many["jobs"][identifier] = {"name": identifier, "runs-on": "ubuntu-latest", "steps": [{"run": "true"}]}
    observed.extend(validate_maximum_shape(too_many, needs_fixture))

    too_large = copy.deepcopy(needs_fixture)
    too_large["__padding__"] = {"result": "action_required", "outputs": {"padding": ""}}
    empty_size = serialized_needs_bytes(too_large)
    too_large["__padding__"]["outputs"]["padding"] = "x" * (NEEDS_BYTE_LIMIT - empty_size)
    if serialized_needs_bytes(too_large) != NEEDS_BYTE_LIMIT:
        raise AssertionError("one-byte budget fixture was not exact")
    observed.extend(validate_maximum_shape(workflow, too_large))
    return observed


def run_maximum_shape(workflow_path: Path, needs_path: Path) -> int:
    try:
        workflow = load_workflow(workflow_path)
        needs_fixture = load_json(needs_path)
    except (OSError, json.JSONDecodeError, yaml.YAMLError) as error:
        print(f"maximum-shape: FAIL: fixture_unavailable detail={error}", file=sys.stderr)
        return 1
    lint = __import__("subprocess").run(
        ["actionlint", str(workflow_path)], capture_output=True, text=True, check=False
    )
    problems = validate_maximum_shape(workflow, needs_fixture)
    if lint.returncode != 0:
        problems.append(Problem("actionlint", str(workflow_path), lint.stdout.strip() or lint.stderr.strip()))
    negatives = maximum_negative_controls(workflow, needs_fixture)
    required_negative_kinds = {
        "maximum_missing_job",
        "maximum_extra_need",
        "maximum_setup_forbidden",
        "job_budget",
        "needs_payload_budget",
    }
    seen = {problem.kind for problem in negatives}
    for kind in sorted(required_negative_kinds - seen):
        problems.append(Problem("missing_negative_control", kind, "mutation did not fail as required"))
    if problems:
        for problem in problems:
            print(problem.render(), file=sys.stderr)
        return 1
    print(
        f"maximum-shape: pass jobs={len(workflow['jobs'])} "
        f"needs_bytes={serialized_needs_bytes(needs_fixture)}"
    )
    return 0


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

    def test_compatibility_missing_duplicate_and_wrong_target_fail(self) -> None:
        first = self.manifest["legacy_compatibility_contexts"][0]
        self.assert_problem(
            lambda m, _w: m["legacy_compatibility_contexts"].append(copy.deepcopy(first)),
            "duplicate_legacy_compatibility_contexts",
            first["job_id"],
        )
        self.assert_problem(
            lambda _m, w: w["jobs"].pop(first["job_id"]),
            "missing_compatibility_job",
            first["job_id"],
        )
        self.assert_problem(
            lambda m, _w: m["legacy_compatibility_contexts"][0].update(needs_target="invented"),
            "compatibility_target_invalid",
            first["job_id"],
        )


def run_self_test() -> int:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ManifestSelfTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print("ci leaf manifest self-test: pass")
        return 0
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--self-test", action="store_true")
    modes.add_argument("--maximum-shape", type=Path)
    parser.add_argument("--needs-fixture", type=Path)
    args = parser.parse_args()
    if args.self_test:
        return run_self_test()
    if args.needs_fixture is None:
        parser.error("--needs-fixture is required with --maximum-shape")
    return run_maximum_shape(args.maximum_shape, args.needs_fixture)


if __name__ == "__main__":
    sys.exit(main())
