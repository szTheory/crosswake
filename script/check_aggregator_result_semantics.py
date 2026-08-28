#!/usr/bin/env python3
"""Credential-free closed-policy proof for required aggregator results."""

import argparse
import json
import sys
import unittest
from dataclasses import dataclass


@dataclass(frozen=True)
class Evaluation:
    disposition: str
    classification: str


@dataclass(frozen=True)
class OutcomeProblem:
    kind: str
    name: str
    remediation: str


def evaluate_results(results, required_leaves, irrelevant_leaves):
    required = set(required_leaves)
    irrelevant = set(irrelevant_leaves)
    declared = set(results)

    unexpected = sorted(declared - required)
    if unexpected:
        return Evaluation("fail", "unexpected")

    if irrelevant - required:
        return Evaluation("fail", "invalid_irrelevance")

    saw_irrelevant_skip = False

    for leaf in sorted(required):
        if leaf not in results:
            return Evaluation("fail", "missing")

        value = results[leaf]
        if value == "success":
            continue
        if value == "skipped" and leaf in irrelevant:
            saw_irrelevant_skip = True
            continue
        if value == "":
            return Evaluation("fail", "empty")
        if value in {
            "failure",
            "cancelled",
            "skipped",
            "timed_out",
            "action_required",
            "stale",
        }:
            return Evaluation("fail", value)
        return Evaluation("fail", "unknown")

    if saw_irrelevant_skip:
        return Evaluation("neutral", "irrelevant_skipped")
    return Evaluation("pass", "success")


def expected_workflow_outcomes():
    return {
        "success": "success",
        "failure": "failure",
        "cancelled": "failure",
        "skipped_disallowed": "failure",
        "skipped_irrelevant": "success",
        "timed_out": "failure",
        "action_required": "failure",
        "stale": "failure",
        "unknown": "failure",
        "empty": "failure",
        "missing": "failure",
    }


def validate_workflow_outcomes(outcomes):
    expected = expected_workflow_outcomes()
    problems = []

    for name, expected_value in expected.items():
        if name not in outcomes:
            problems.append(
                OutcomeProblem(
                    "missing_outcome",
                    name,
                    "provide every named alls-green step outcome to --assert-outcomes",
                )
            )
            continue

        actual = outcomes[name]
        if not isinstance(actual, str) or not actual.strip():
            problems.append(
                OutcomeProblem(
                    "empty_outcome",
                    name,
                    "capture the step outcome; empty records fail closed",
                )
            )
        elif actual != expected_value:
            problems.append(
                OutcomeProblem(
                    "inverted_outcome",
                    name,
                    "expected step outcome '%s', received '%s'"
                    % (expected_value, actual),
                )
            )

    for name in sorted(set(outcomes) - set(expected)):
        problems.append(
            OutcomeProblem(
                "unexpected_outcome",
                name,
                "remove undeclared outcome records or add a named policy arm",
            )
        )

    return problems


class AggregatorResultSemanticsSelfTest(unittest.TestCase):
    def test_complete_closed_vocabulary_matrix(self):
        matrix = [
            ("success", {"leaf": "success"}, set(), "pass", "success"),
            ("failure", {"leaf": "failure"}, set(), "fail", "failure"),
            ("cancelled", {"leaf": "cancelled"}, set(), "fail", "cancelled"),
            ("skipped_disallowed", {"leaf": "skipped"}, set(), "fail", "skipped"),
            (
                "skipped_irrelevant",
                {"leaf": "skipped"},
                {"leaf"},
                "neutral",
                "irrelevant_skipped",
            ),
            ("timed_out", {"leaf": "timed_out"}, set(), "fail", "timed_out"),
            (
                "action_required",
                {"leaf": "action_required"},
                set(),
                "fail",
                "action_required",
            ),
            ("stale", {"leaf": "stale"}, set(), "fail", "stale"),
            ("unknown", {"leaf": "mystery"}, set(), "fail", "unknown"),
            ("empty", {"leaf": ""}, set(), "fail", "empty"),
            ("missing", {}, set(), "fail", "missing"),
        ]

        names = [case[0] for case in matrix]
        self.assertEqual(len(names), 11)
        self.assertEqual(len(set(names)), 11)

        for name, results, irrelevant, disposition, classification in matrix:
            with self.subTest(result_class=name):
                evaluation = evaluate_results(results, {"leaf"}, irrelevant)
                self.assertEqual(evaluation.disposition, disposition)
                self.assertEqual(evaluation.classification, classification)
                print(
                    "aggregator-policy: case=%s disposition=%s classification=%s"
                    % (name, evaluation.disposition, evaluation.classification)
                )

    def test_canonical_workflow_outcomes_are_accepted(self):
        self.assertEqual(validate_workflow_outcomes(expected_workflow_outcomes()), [])

    def test_missing_outcome_negative_control_is_rejected_exactly(self):
        outcomes = expected_workflow_outcomes()
        outcomes.pop("cancelled")

        self.assertEqual(
            validate_workflow_outcomes(outcomes),
            [
                OutcomeProblem(
                    "missing_outcome",
                    "cancelled",
                    "provide every named alls-green step outcome to --assert-outcomes",
                )
            ],
        )
        print("aggregator-policy: negative-control=missing_outcome detected=cancelled")

    def test_inverted_outcome_negative_control_is_rejected_exactly(self):
        outcomes = expected_workflow_outcomes()
        outcomes["failure"] = "success"

        self.assertEqual(
            validate_workflow_outcomes(outcomes),
            [
                OutcomeProblem(
                    "inverted_outcome",
                    "failure",
                    "expected step outcome 'failure', received 'success'",
                )
            ],
        )
        print("aggregator-policy: negative-control=inverted_outcome detected=failure")

    def test_extra_and_empty_outcomes_are_rejected(self):
        outcomes = expected_workflow_outcomes()
        outcomes["success"] = ""
        outcomes["undeclared"] = "failure"

        self.assertEqual(
            validate_workflow_outcomes(outcomes),
            [
                OutcomeProblem(
                    "empty_outcome",
                    "success",
                    "capture the step outcome; empty records fail closed",
                ),
                OutcomeProblem(
                    "unexpected_outcome",
                    "undeclared",
                    "remove undeclared outcome records or add a named policy arm",
                ),
            ],
        )


def run_self_test():
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(AggregatorResultSemanticsSelfTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


def parse_outcomes(raw):
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as error:
        raise ValueError("outcomes must be one JSON object: %s" % error.msg)
    if not isinstance(value, dict):
        raise ValueError("outcomes must be one JSON object")
    return value


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--self-test", action="store_true")
    mode.add_argument("--assert-outcomes", metavar="JSON")
    args = parser.parse_args(argv)

    if args.self_test:
        return run_self_test()

    try:
        outcomes = parse_outcomes(args.assert_outcomes)
    except ValueError as error:
        print("aggregator-outcomes: FAIL: %s" % error, file=sys.stderr)
        return 1

    problems = validate_workflow_outcomes(outcomes)
    for problem in problems:
        print(
            "aggregator-outcomes: FAIL: %s name=%s remediation=%s"
            % (problem.kind, problem.name, problem.remediation),
            file=sys.stderr,
        )
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
