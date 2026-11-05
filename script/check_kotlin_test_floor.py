#!/usr/bin/env python3
"""Recurring floor gate for the Kotlin core JVM unit tests (Phase 198, AND-02).

Reads fresh JUnit XML written by `testDebugUnitTest` (never Gradle console totals), derives the
expected count from the test source tree, and fails closed on stale, absent, double-counted,
skipped or failing results. Stdlib only; no network.

Output line:
  kotlin-floor: tests=<n> source_tests=<m> boundary=<k> floor=25 verdict=PASS|FAIL [reason=<r>]
Exit: 0 PASS, 1 FAIL, 2 usage error or Gradle could not run.
"""

import argparse
import glob
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PACKAGE_DIR = REPO_ROOT / "packages" / "crosswake-shell-core-android"

# Ratchet floor: raise it when tests are added, never lower it. The current count is derived
# (XML count must equal the non-@Ignore @Test count in src/test), never pinned to a literal.
FLOOR = 25

BOUNDARY_CLASS = "dev.crosswake.shell.core.BridgeChannelBoundaryTest"
BOUNDARY_MIN = 10

LOAD_BEARING_TESTS = (
    (
        "dev.crosswake.shell.core.BridgeConformanceTest",
        "all bridge contract vectors pass status and denial-reason assertions",
    ),
    (BOUNDARY_CLASS, "envelope rejects non string required fields on the JVM"),
    (BOUNDARY_CLASS, "origin near misses are denied with origin_denied"),
    (BOUNDARY_CLASS, "request claimed packs never satisfy route pack authority"),
    (BOUNDARY_CLASS, "deny reply has an empty payload and never echoes a request secret"),
    (BOUNDARY_CLASS, "denial happens before side effects with a positive control"),
    (BOUNDARY_CLASS, "listener gate allows only the main frame from the exact allowed origin"),
    (
        "dev.crosswake.shell.core.SemVerBoundaryTest",
        "negative plus signed and overflowing components fail closed",
    ),
)

REASONS = (
    "no_results",
    "below_floor",
    "failures",
    "skipped",
    "duplicate_suite",
    "count_mismatch",
    "boundary_below_min",
    "named_test_missing",
    "serialization_dependency_present",
    "webkit_comment_untruthful",
    "gradle_failed",
)

SERIALIZATION_MARKERS = (
    "kotlinx-serialization-json",
    "org.jetbrains.kotlin.plugin.serialization",
    "kotlin(\"plugin.serialization\")",
)

DEFAULT_RESULTS_DIR = PACKAGE_DIR / "build" / "test-results" / "testDebugUnitTest"
DEFAULT_SRC_DIR = PACKAGE_DIR / "src" / "test"
DEFAULT_BUILD_FILE = PACKAGE_DIR / "build.gradle.kts"


def junit_totals(results_dir):
    """Sum every TEST-*.xml in results_dir. Pure read; returns a plain dict."""
    files = sorted(glob.glob(os.path.join(str(results_dir), "TEST-*.xml")))
    totals = {
        "files": len(files),
        "tests": 0,
        "failed": 0,
        "skipped": 0,
        "suites": {},
        "duplicates": [],
        "cases": [],
    }
    for path in files:
        root = ET.parse(path).getroot()
        suites = [root] if root.tag == "testsuite" else list(root.iter("testsuite"))
        for suite in suites:
            name = suite.get("name", "")
            totals["tests"] += int(suite.get("tests", "0"))
            totals["failed"] += int(suite.get("failures", "0")) + int(suite.get("errors", "0"))
            totals["skipped"] += int(suite.get("skipped", "0"))
            if name in totals["suites"]:
                totals["duplicates"].append(name)
            totals["suites"][name] = totals["suites"].get(name, 0) + int(suite.get("tests", "0"))
            for case in suite.iter("testcase"):
                bad = any(
                    case.find(tag) is not None for tag in ("failure", "error", "skipped")
                )
                totals["cases"].append((case.get("classname", ""), case.get("name", ""), not bad))
    return totals


def source_test_count(src_dir):
    """Count `@Test` annotations in *.kt under src_dir, minus @Ignore-adjacent ones."""
    count = 0
    for path in sorted(Path(src_dir).rglob("*.kt")):
        lines = path.read_text(encoding="utf-8").splitlines()
        for index, line in enumerate(lines):
            if not re.match(r"^\s*@Test\b", line):
                continue
            neighbours = [line]
            if index > 0:
                neighbours.append(lines[index - 1])
            if index + 1 < len(lines):
                neighbours.append(lines[index + 1])
            if any("@Ignore" in text for text in neighbours):
                continue
            count += 1
    return count


def build_file_violations(text):
    """Dependency-drift reasons from the core build file text."""
    reasons = []
    if any(marker in text for marker in SERIALIZATION_MARKERS):
        reasons.append("serialization_dependency_present")
    lines = text.splitlines()
    truthful = False
    for index, line in enumerate(lines):
        if "androidx.webkit:webkit" in line:
            truthful = index > 0 and "addWebMessageListener" in lines[index - 1]
            break
    if not truthful:
        reasons.append("webkit_comment_untruthful")
    return reasons


def evaluate(totals, source_count, build_text):
    """Return failure reasons in a fixed order; empty list means PASS."""
    reasons = []
    if totals["files"] == 0:
        reasons.append("no_results")
    if totals["duplicates"]:
        reasons.append("duplicate_suite")
    if totals["failed"] > 0:
        reasons.append("failures")
    if totals["skipped"] > 0:
        reasons.append("skipped")
    if totals["tests"] < FLOOR:
        reasons.append("below_floor")
    if totals["tests"] != source_count:
        reasons.append("count_mismatch")
    boundary = sum(1 for classname, _, _ in totals["cases"] if classname == BOUNDARY_CLASS)
    if boundary < BOUNDARY_MIN:
        reasons.append("boundary_below_min")
    passed = {(classname, name) for classname, name, ok in totals["cases"] if ok}
    if any(pair not in passed for pair in LOAD_BEARING_TESTS):
        reasons.append("named_test_missing")
    reasons.extend(build_file_violations(build_text))
    return reasons


def boundary_count(totals):
    return sum(1 for classname, _, _ in totals["cases"] if classname == BOUNDARY_CLASS)


def run_gradle(package_dir):
    env = dict(os.environ)
    env["CROSSWAKE_ANDROID_CONNECTED_TESTS"] = "0"
    return subprocess.run(
        ["./gradlew", "--no-daemon", "cleanTestDebugUnitTest", "testDebugUnitTest"],
        cwd=str(package_dir),
        env=env,
        check=False,
    ).returncode


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--run", action="store_true", help="force a fresh testDebugUnitTest run")
    parser.add_argument("--package-dir", default=str(PACKAGE_DIR))
    parser.add_argument("--results-dir", default=str(DEFAULT_RESULTS_DIR))
    parser.add_argument("--src-dir", default=str(DEFAULT_SRC_DIR))
    parser.add_argument("--build-file", default=str(DEFAULT_BUILD_FILE))
    args = parser.parse_args(argv)

    gradle_failed = False
    if args.run:
        gradlew = Path(args.package_dir) / "gradlew"
        if not gradlew.is_file() or not os.access(str(gradlew), os.X_OK):
            print("kotlin-floor: cannot run %s" % gradlew, file=sys.stderr)
            return 2
        gradle_failed = run_gradle(args.package_dir) != 0

    try:
        totals = junit_totals(args.results_dir)
        source_count = source_test_count(args.src_dir)
        build_text = Path(args.build_file).read_text(encoding="utf-8")
    except (OSError, ET.ParseError, ValueError) as error:
        print("kotlin-floor: cannot read inputs: %s" % error, file=sys.stderr)
        return 2

    reasons = evaluate(totals, source_count, build_text)
    if gradle_failed:
        reasons.insert(0, "gradle_failed")

    verdict = "PASS" if not reasons else "FAIL"
    line = "kotlin-floor: tests=%d source_tests=%d boundary=%d floor=%d verdict=%s" % (
        totals["tests"],
        source_count,
        boundary_count(totals),
        FLOOR,
        verdict,
    )
    if reasons:
        line += " reason=%s" % reasons[0]
    print(line)
    for reason in reasons:
        print("kotlin-floor: reason %s" % reason)
    return 0 if not reasons else 1


if __name__ == "__main__":
    sys.exit(main())
