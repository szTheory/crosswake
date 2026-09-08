#!/usr/bin/env python3
"""Pure, fail-closed policy for selecting obsolete Crosswake CI PR runs."""

import argparse
import itertools
import json
import re
import sys
import unittest
from dataclasses import asdict, dataclass
from pathlib import Path


MAX_RUN_ID = (1 << 63) - 1
MAX_PR_NUMBER = (1 << 31) - 1
REPOSITORY_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
CANCELLABLE_STATUSES = {"queued", "in_progress"}
KNOWN_STATUSES = CANCELLABLE_STATUSES | {"completed"}


@dataclass(frozen=True)
class Selection:
    schema_version: int
    disposition: str
    reason: str
    run_ids: tuple[int, ...]


def closed(disposition, reason, run_ids=()):
    return Selection(1, disposition, reason, tuple(run_ids))


def positive_integer(value, maximum):
    return type(value) is int and 0 < value <= maximum


def single_pr_number(run):
    pulls = run.get("pull_requests")
    if not isinstance(pulls, list) or len(pulls) != 1:
        return None
    pull = pulls[0]
    if not isinstance(pull, dict) or set(pull) != {"number"}:
        return None
    number = pull["number"]
    return number if positive_integer(number, MAX_PR_NUMBER) else None


def run_identity(run, *, candidate):
    if not isinstance(run, dict):
        return None
    required = {
        "id",
        "repository",
        "workflow_id",
        "workflow_name",
        "event",
        "pull_requests",
    }
    allowed = required | {"head_repository", "head_branch"}
    if candidate:
        required = required | {"status"}
        allowed = allowed | {"status"}
    if not required <= set(run) or not set(run) <= allowed:
        return None
    if not positive_integer(run["id"], MAX_RUN_ID):
        return None
    if not positive_integer(run["workflow_id"], MAX_RUN_ID):
        return None
    repository = run["repository"]
    if not isinstance(repository, str) or not REPOSITORY_RE.fullmatch(repository):
        return None
    workflow_name = run["workflow_name"]
    if not isinstance(workflow_name, str) or not (0 < len(workflow_name) <= 100):
        return None
    if run["event"] != "pull_request":
        return None
    pr_number = single_pr_number(run)
    if pr_number is None:
        return None
    if candidate and run["status"] not in KNOWN_STATUSES:
        return None
    return (
        run["id"],
        repository,
        run["workflow_id"],
        workflow_name,
        pr_number,
        run.get("status"),
    )


def select_obsolete_runs(
    current,
    candidates,
    *,
    expected_repository=None,
    expected_workflow_name=None,
):
    current_identity = run_identity(current, candidate=False)
    if current_identity is None:
        return closed("invalid", "invalid_current")
    current_id, repository, workflow_id, workflow_name, pr_number, _ = current_identity
    if expected_repository is not None and repository != expected_repository:
        return closed("invalid", "unexpected_repository")
    if expected_workflow_name is not None and workflow_name != expected_workflow_name:
        return closed("invalid", "unexpected_workflow")

    if not isinstance(candidates, dict) or set(candidates) != {
        "pagination_complete",
        "runs",
    }:
        return closed("invalid", "invalid_candidates")
    if candidates["pagination_complete"] is not True:
        return closed("invalid", "incomplete_pagination")
    if not isinstance(candidates["runs"], list):
        return closed("invalid", "invalid_candidates")

    selected = set()
    for candidate in candidates["runs"]:
        identity = run_identity(candidate, candidate=True)
        if identity is None:
            return closed("invalid", "invalid_candidate")
        (
            candidate_id,
            candidate_repository,
            candidate_workflow_id,
            candidate_name,
            candidate_pr,
            status,
        ) = identity
        if (
            candidate_repository == repository
            and candidate_workflow_id == workflow_id
            and candidate_name == workflow_name
            and candidate_pr == pr_number
            and candidate_id < current_id
            and status in CANCELLABLE_STATUSES
        ):
            selected.add(candidate_id)

    if not selected:
        return closed("no_op", "no_strict_lower")
    return closed("cancel_lower", "strict_lower", sorted(selected))


def load_json(value):
    path = Path(value)
    text = path.read_text(encoding="utf-8") if path.is_file() else value
    return json.loads(text)


def fixture_path():
    return Path(__file__).resolve().parents[1] / "test/fixtures/ci/cancellation/cases.json"


class CancellationSelectorSelfTest(unittest.TestCase):
    def test_fixture_corpus(self):
        fixture = json.loads(fixture_path().read_text(encoding="utf-8"))
        self.assertEqual(fixture["schema_version"], 1)
        for case in fixture["cases"]:
            if case["name"] == "two_controller_inversion":
                older = select_obsolete_runs(case["older_current"], case["candidates"])
                newer = select_obsolete_runs(case["newer_current"], case["candidates"])
                self.assertEqual(list(older.run_ids), case["expected"]["older_controller_ids"])
                self.assertEqual(list(newer.run_ids), case["expected"]["newer_controller_ids"])
                self.assertNotIn(case["expected"]["authoritative_run_id"], older.run_ids)
                self.assertNotIn(case["expected"]["authoritative_run_id"], newer.run_ids)
                continue

            actual = select_obsolete_runs(case["current"], case["candidates"])
            expected = case["expected"]
            self.assertEqual(actual.disposition, expected["disposition"], case["name"])
            self.assertEqual(actual.reason, expected["reason"], case["name"])
            self.assertEqual(list(actual.run_ids), expected["run_ids"], case["name"])

    def test_expected_authority_is_exact(self):
        fixture = json.loads(fixture_path().read_text(encoding="utf-8"))
        case = next(item for item in fixture["cases"] if item["name"] == "lower_adjacent_is_selected")
        self.assertEqual(
            select_obsolete_runs(
                case["current"],
                case["candidates"],
                expected_repository="other/repository",
                expected_workflow_name="Crosswake CI",
            ),
            closed("invalid", "unexpected_repository"),
        )

    def test_pending_peer_is_valid_but_not_cancellable(self):
        fixture = json.loads(fixture_path().read_text(encoding="utf-8"))
        case = next(item for item in fixture["cases"] if item["name"] == "lower_adjacent_is_selected")
        candidates = json.loads(json.dumps(case["candidates"]))
        pending = json.loads(json.dumps(candidates["runs"][0]))
        pending["id"] = case["current"]["id"] + 1
        pending["status"] = "pending"
        candidates["runs"].append(pending)

        selection = select_obsolete_runs(case["current"], candidates)
        self.assertEqual(selection.disposition, "cancel_lower")
        self.assertEqual(list(selection.run_ids), case["expected"]["run_ids"])
        self.assertNotIn(pending["id"], selection.run_ids)

    def test_selection_is_permutation_invariant_and_never_selects_maximum(self):
        fixture = json.loads(fixture_path().read_text(encoding="utf-8"))
        case = next(
            item for item in fixture["cases"] if item["name"] == "permutations_sort_once"
        )
        authoritative_maximum = max(
            case["current"]["id"],
            *(run["id"] for run in case["candidates"]["runs"]),
        )
        for permutation in itertools.permutations(case["candidates"]["runs"]):
            candidates = {"pagination_complete": True, "runs": list(permutation)}
            selection = select_obsolete_runs(case["current"], candidates)
            self.assertEqual(list(selection.run_ids), case["expected"]["run_ids"])
            self.assertNotIn(authoritative_maximum, selection.run_ids)


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--current-run")
    parser.add_argument("--candidates")
    parser.add_argument("--repository")
    parser.add_argument("--workflow-name")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv or sys.argv[1:])
    if args.self_test:
        suite = unittest.defaultTestLoader.loadTestsFromTestCase(CancellationSelectorSelfTest)
        result = unittest.TextTestRunner(verbosity=0).run(suite)
        if result.wasSuccessful():
            print("cancellation selector self-test: pass")
            return 0
        return 1
    if not args.current_run or not args.candidates:
        print(json.dumps(asdict(closed("invalid", "missing_input")), sort_keys=True))
        return 0
    try:
        selection = select_obsolete_runs(
            load_json(args.current_run),
            load_json(args.candidates),
            expected_repository=args.repository,
            expected_workflow_name=args.workflow_name,
        )
    except (OSError, UnicodeError, json.JSONDecodeError):
        selection = closed("invalid", "malformed_json")
    payload = asdict(selection)
    payload["run_ids"] = list(selection.run_ids)
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
