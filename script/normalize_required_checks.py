#!/usr/bin/env python3
"""Validate and normalize GitHub's app-bound required-check response."""

from __future__ import annotations

import argparse
import json
import sys
import unittest
from pathlib import Path


FIXTURES = (
    Path(__file__).resolve().parents[1]
    / "test/fixtures/ci/required-checks/cases.json"
)


def normalize(value: object) -> dict[str, object]:
    if not isinstance(value, dict) or value.get("strict") is not True:
        raise ValueError("strict app-bound required-check response required")

    checks = value.get("checks")
    contexts = value.get("contexts")
    if not isinstance(checks, list) or not checks or not isinstance(contexts, list):
        raise ValueError("checks and mirrored contexts arrays required")

    normalized_checks: list[dict[str, object]] = []
    for check in checks:
        if not isinstance(check, dict) or set(check) != {"context", "app_id"}:
            raise ValueError("exact context and app_id check record required")
        context = check["context"]
        app_id = check["app_id"]
        if not isinstance(context, str) or not context or type(app_id) is not int or app_id <= 0:
            raise ValueError("valid app-bound check record required")
        normalized_checks.append({"context": context, "app_id": app_id})

    check_names = [check["context"] for check in normalized_checks]
    if len(check_names) != len(set(check_names)):
        raise ValueError("duplicate or ambiguous check authority")
    if any(not isinstance(context, str) or not context for context in contexts):
        raise ValueError("valid mirrored context names required")
    if len(contexts) != len(set(contexts)):
        raise ValueError("duplicate or ambiguous mirrored contexts")
    if set(contexts) != set(check_names):
        raise ValueError("mirrored contexts differ from app-bound checks")

    return {
        "strict": True,
        "checks": sorted(normalized_checks, key=lambda check: str(check["context"])),
        "contexts": sorted(contexts),
    }


class NormalizeRequiredChecksTest(unittest.TestCase):
    def test_realistic_fixture_corpus(self) -> None:
        fixture = json.loads(FIXTURES.read_text(encoding="utf-8"))
        self.assertEqual(fixture["schema_version"], 1)
        names = [case["name"] for case in fixture["cases"]]
        self.assertEqual(names, list(dict.fromkeys(names)))
        for case in fixture["cases"]:
            if case["valid_shape"]:
                normalized = normalize(case["protection"])
                self.assertTrue(normalized["strict"], case["name"])
            else:
                with self.assertRaises(ValueError, msg=case["name"]):
                    normalize(case["protection"])


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args(argv)
    if args.self_test:
        result = unittest.TextTestRunner(verbosity=0).run(
            unittest.defaultTestLoader.loadTestsFromTestCase(NormalizeRequiredChecksTest)
        )
        if result.wasSuccessful():
            print("required-check normalization self-test: pass")
            return 0
        return 1
    if not args.input:
        parser.error("--input is required")
    try:
        if args.input == "-":
            value = json.load(sys.stdin)
        else:
            value = json.loads(Path(args.input).read_text(encoding="utf-8"))
        result = normalize(value)
    except (OSError, UnicodeError, json.JSONDecodeError, ValueError):
        print("invalid required-check response", file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
