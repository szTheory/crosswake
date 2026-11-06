#!/usr/bin/env python3
"""Fixture selftest for check_kotlin_test_floor.py: one fixture per reason in the closed set.

Needs no Gradle, Java or network. Every negative case also asserts the positive base fixture
still evaluates clean, so a harness that fails everything cannot pass.
"""

import importlib.util
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CHECKER_PATH = Path(__file__).with_name("check_kotlin_test_floor.py")
_spec = importlib.util.spec_from_file_location("check_kotlin_test_floor", CHECKER_PATH)
checker = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(checker)

CLEAN_BUILD = (
    "dependencies {\n"
    '    implementation("androidx.core:core-ktx:1.12.0")\n'
    "    // Imported by BridgeChannel.kt (WebViewCompat.addWebMessageListener).\n"
    '    implementation("androidx.webkit:webkit:1.10.0")\n'
    "}\n"
)

OTHER_CLASS = "dev.crosswake.shell.core.OtherTest"


def base_cases():
    """25 passing cases: 10 boundary, every load-bearing name, the rest filler."""
    cases = list(checker.LOAD_BEARING_TESTS)
    boundary_have = sum(1 for classname, _ in cases if classname == checker.BOUNDARY_CLASS)
    for index in range(checker.BOUNDARY_MIN - boundary_have):
        cases.append((checker.BOUNDARY_CLASS, "boundary filler %d" % index))
    index = 0
    while len(cases) < checker.FLOOR:
        cases.append((OTHER_CLASS, "filler %d" % index))
        index += 1
    return [(classname, name, "passed") for classname, name in cases]


def write_suite_xml(results_dir, filename, classname, cases):
    tests = len(cases)
    failures = sum(1 for _, _, state in cases if state == "failed")
    skipped = sum(1 for _, _, state in cases if state == "skipped")
    lines = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<testsuite name="%s" tests="%d" skipped="%d" failures="%d" errors="0">'
        % (classname, tests, skipped, failures),
    ]
    for _, name, state in cases:
        if state == "passed":
            lines.append('  <testcase name="%s" classname="%s" time="0.0"/>' % (name, classname))
        elif state == "failed":
            lines.append(
                '  <testcase name="%s" classname="%s" time="0.0"><failure message="x"/></testcase>'
                % (name, classname)
            )
        else:
            lines.append(
                '  <testcase name="%s" classname="%s" time="0.0"><skipped/></testcase>'
                % (name, classname)
            )
    lines.append("</testsuite>")
    Path(results_dir, filename).write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_results(results_dir, cases, suffix=""):
    """Group cases by classname, one TEST-<classname><suffix>.xml per suite."""
    grouped = {}
    for classname, name, state in cases:
        grouped.setdefault(classname, []).append((classname, name, state))
    for classname, suite_cases in grouped.items():
        write_suite_xml(results_dir, "TEST-%s%s.xml" % (classname, suffix), classname, suite_cases)


def write_source(src_dir, test_count, ignored=1):
    """A fake source tree with test_count counted @Test lines plus ignored @Ignore'd tests."""
    body = ["package fixture", "class FixtureTest {"]
    for index in range(test_count):
        body += ["    @Test", "    fun t%d() {}" % index]
    for index in range(ignored):
        body += ["    @Ignore", "    @Test", "    fun ignored%d() {}" % index]
    body.append("}")
    Path(src_dir, "FixtureTest.kt").write_text("\n".join(body) + "\n", encoding="utf-8")


class Fixture:
    def __init__(self, root, cases=None, source_count=None, build=CLEAN_BUILD):
        self.root = Path(root)
        self.results = self.root / "results"
        self.src = self.root / "src"
        self.build_file = self.root / "build.gradle.kts"
        for path in (self.results, self.src):
            path.mkdir(parents=True, exist_ok=True)
        cases = base_cases() if cases is None else cases
        write_results(self.results, cases)
        write_source(self.src, len(cases) if source_count is None else source_count)
        self.build_file.write_text(build, encoding="utf-8")

    def reasons(self):
        totals = checker.junit_totals(self.results)
        return checker.evaluate(
            totals,
            checker.source_test_count(self.src),
            self.build_file.read_text(encoding="utf-8"),
        )


class FloorCheckerTest(unittest.TestCase):
    def positive_control(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(Fixture(tmp).reasons(), [], "positive control must be clean")

    def assertReason(self, reason, fixture_factory):
        self.positive_control()
        with tempfile.TemporaryDirectory() as tmp:
            reasons = fixture_factory(tmp).reasons()
        self.assertIn(reason, reasons)
        return reasons

    # 1
    def test_positive_control_is_clean(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = Fixture(tmp)
            self.assertEqual(fixture.reasons(), [])
            totals = checker.junit_totals(fixture.results)
            self.assertEqual(totals["tests"], 25)
            self.assertEqual(checker.source_test_count(fixture.src), 25)

    # 2
    def test_below_floor(self):
        cases = base_cases()
        # drop one non-load-bearing case: 24 tests, source tree kept in step
        index = next(i for i, c in enumerate(cases) if c[0] == OTHER_CLASS)
        short = cases[:index] + cases[index + 1:]
        self.assertEqual(len(short), 24)
        reasons = self.assertReason("below_floor", lambda tmp: Fixture(tmp, cases=short))
        self.assertEqual(reasons, ["below_floor"])

    # 3
    def test_failures(self):
        cases = base_cases()
        index = next(i for i, c in enumerate(cases) if c[0] == OTHER_CLASS)
        cases[index] = (cases[index][0], cases[index][1], "failed")
        reasons = self.assertReason("failures", lambda tmp: Fixture(tmp, cases=cases))
        self.assertEqual(reasons, ["failures"])

    # 4
    def test_skipped(self):
        cases = base_cases()
        index = next(i for i, c in enumerate(cases) if c[0] == OTHER_CLASS)
        cases[index] = (cases[index][0], cases[index][1], "skipped")
        reasons = self.assertReason("skipped", lambda tmp: Fixture(tmp, cases=cases))
        self.assertEqual(reasons, ["skipped"])

    # 5
    def test_boundary_below_min(self):
        cases = [c for c in base_cases() if c[0] != checker.BOUNDARY_CLASS]
        # keep 25 tests overall so only the boundary and named-test reasons fire
        index = 0
        while len(cases) < 25:
            cases.append((OTHER_CLASS, "extra %d" % index, "passed"))
            index += 1
        reasons = self.assertReason("boundary_below_min", lambda tmp: Fixture(tmp, cases=cases))
        self.assertNotIn("below_floor", reasons)

    # 6
    def test_no_results(self):
        def zero_xml(tmp):
            fixture = Fixture(tmp)
            for path in fixture.results.glob("TEST-*.xml"):
                path.unlink()
            return fixture

        reasons = self.assertReason("no_results", zero_xml)
        self.assertEqual(reasons[0], "no_results")

    # 7
    def test_duplicate_suite(self):
        def doubled(tmp):
            fixture = Fixture(tmp)
            write_results(fixture.results, base_cases(), suffix="-release")
            return fixture

        reasons = self.assertReason("duplicate_suite", doubled)
        self.assertIn("count_mismatch", reasons)  # 50 XML tests against 25 source tests

    # 8
    def test_count_mismatch(self):
        reasons = self.assertReason(
            "count_mismatch", lambda tmp: Fixture(tmp, source_count=26)
        )
        self.assertEqual(reasons, ["count_mismatch"])

    # 9
    def test_named_test_missing(self):
        cases = base_cases()
        classname, name = checker.LOAD_BEARING_TESTS[0]
        cases = [
            (c, n + " renamed", s) if (c, n) == (classname, name) else (c, n, s)
            for c, n, s in cases
        ]
        reasons = self.assertReason("named_test_missing", lambda tmp: Fixture(tmp, cases=cases))
        self.assertEqual(reasons, ["named_test_missing"])

    # 10
    def test_serialization_dependency_present(self):
        build = CLEAN_BUILD.replace(
            "}\n",
            '    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.0")\n}\n',
        )
        reasons = self.assertReason(
            "serialization_dependency_present", lambda tmp: Fixture(tmp, build=build)
        )
        self.assertEqual(reasons, ["serialization_dependency_present"])

    # 11
    def test_webkit_comment_untruthful(self):
        build = CLEAN_BUILD.replace("addWebMessageListener", "something else")
        reasons = self.assertReason(
            "webkit_comment_untruthful", lambda tmp: Fixture(tmp, build=build)
        )
        self.assertEqual(reasons, ["webkit_comment_untruthful"])

    def cli(self, *extra, root):
        return subprocess.run(
            [sys.executable, str(CHECKER_PATH)] + list(extra),
            capture_output=True,
            text=True,
            check=False,
            cwd=root,
        )

    # 12
    def test_cli_zero_xml_fails_with_no_results(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = Fixture(tmp)
            ok = self.cli(
                "--results-dir", str(fixture.results), "--src-dir", str(fixture.src),
                "--build-file", str(fixture.build_file), root=tmp,
            )
            self.assertEqual(ok.returncode, 0, ok.stdout + ok.stderr)
            self.assertIn("verdict=PASS", ok.stdout)
            for path in fixture.results.glob("TEST-*.xml"):
                path.unlink()
            bad = self.cli(
                "--results-dir", str(fixture.results), "--src-dir", str(fixture.src),
                "--build-file", str(fixture.build_file), root=tmp,
            )
            self.assertEqual(bad.returncode, 1, bad.stdout + bad.stderr)
            self.assertIn("verdict=FAIL reason=no_results", bad.stdout)

    # 13
    def test_cli_run_with_failing_gradle_reports_gradle_failed(self):
        with tempfile.TemporaryDirectory() as tmp:
            fixture = Fixture(tmp)
            pkg = Path(tmp) / "pkg"
            pkg.mkdir()
            gradlew = pkg / "gradlew"
            gradlew.write_text("#!/bin/sh\nexit 1\n", encoding="utf-8")
            gradlew.chmod(gradlew.stat().st_mode | stat.S_IXUSR)
            result = self.cli(
                "--run", "--package-dir", str(pkg),
                "--results-dir", str(fixture.results), "--src-dir", str(fixture.src),
                "--build-file", str(fixture.build_file), root=tmp,
            )
            self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
            self.assertIn("reason=gradle_failed", result.stdout)
            # the same fixture without --run is clean, so only the Gradle exit made it fail
            clean = self.cli(
                "--results-dir", str(fixture.results), "--src-dir", str(fixture.src),
                "--build-file", str(fixture.build_file), root=tmp,
            )
            self.assertEqual(clean.returncode, 0, clean.stdout + clean.stderr)


if __name__ == "__main__":
    unittest.main()
