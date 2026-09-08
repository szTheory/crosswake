#!/usr/bin/env python3
"""Fail-closed NUL-safe classifier for the Phase 165 PR proof graph."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path, PurePosixPath


SCHEMA_VERSION = 1
ZERO_SHA = "0" * 40
SHA = re.compile(r"^[0-9a-f]{40}$")
KNOWN_SINGLE = {"A", "M", "D", "T", "U", "X", "B"}
KNOWN_DOUBLE = {"R", "C"}


def closed_result(classification: str, reason: str) -> dict[str, object]:
    docs = classification == "documentation_only"
    return {
        "schema_version": SCHEMA_VERSION,
        "classification": classification,
        "reason": reason,
        "scheduled_families": ["documentation_contracts"] if docs else ["full_proof"],
        "irrelevant_leaves": (
            ["android", "apple", "browser", "packaging", "root_suite"] if docs else []
        ),
    }


def full_proof(reason: str) -> dict[str, object]:
    return closed_result("full_proof", reason)


def load_allowlist(path: Path) -> dict[str, object]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        raise ValueError("allowlist_unavailable") from None
    if set(value) != {"schema_version", "exact", "trees", "excluded"}:
        raise ValueError("allowlist_invalid")
    if value["schema_version"] != 1:
        raise ValueError("allowlist_invalid")
    for key in ("exact", "trees", "excluded"):
        if not isinstance(value[key], list) or not all(
            isinstance(item, str) and item for item in value[key]
        ):
            raise ValueError("allowlist_invalid")
        if value[key] != sorted(set(value[key])):
            raise ValueError("allowlist_invalid")
    return value


def safe_relative_path(raw: bytes) -> str | None:
    try:
        path = raw.decode("utf-8", "strict")
    except UnicodeDecodeError:
        return None
    candidate = PurePosixPath(path)
    if not path or path == "." or candidate.is_absolute():
        return None
    if any(part in {"", ".", ".."} for part in candidate.parts):
        return None
    return path


def parse_name_status(raw: bytes) -> list[tuple[str, tuple[str, ...]]] | None:
    if not raw or not raw.endswith(b"\0"):
        return None
    fields = raw[:-1].split(b"\0")
    records: list[tuple[str, tuple[str, ...]]] = []
    index = 0
    while index < len(fields):
        try:
            status = fields[index].decode("ascii", "strict")
        except UnicodeDecodeError:
            return None
        index += 1
        kind = status[:1]
        if kind in KNOWN_DOUBLE:
            if not re.fullmatch(r"[RC]\d{1,3}", status) or index + 1 >= len(fields):
                return None
            raw_paths = fields[index : index + 2]
            index += 2
        elif kind in KNOWN_SINGLE:
            if status != kind or index >= len(fields):
                return None
            raw_paths = fields[index : index + 1]
            index += 1
        else:
            return None
        paths = tuple(safe_relative_path(item) or "" for item in raw_paths)
        if not all(paths):
            return None
        records.append((status, paths))
    return records or None


def is_documentation_path(path: str, allowlist: dict[str, object]) -> bool:
    if path in allowlist["excluded"]:
        return False
    if path in allowlist["exact"]:
        return True
    parts = PurePosixPath(path).parts
    return len(parts) > 1 and parts[0] in allowlist["trees"] and path.endswith(".md")


def classify_records(
    records: list[tuple[str, tuple[str, ...]]] | None, allowlist: dict[str, object]
) -> dict[str, object]:
    if not records:
        return full_proof("diff_empty_or_malformed")
    paths = sorted(path for _status, record_paths in records for path in record_paths)
    if all(is_documentation_path(path, allowlist) for path in paths):
        return closed_result("documentation_only", "all_changed_paths_allowlisted")
    return full_proof("unallowlisted_or_mixed_path")


def git_ok(repo: Path, args: list[str]) -> bool:
    return subprocess.run(
        ["git", "-C", os.fspath(repo), *args],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    ).returncode == 0


def classify(repo: Path, base: str, merge: str, allowlist_path: Path) -> dict[str, object]:
    try:
        allowlist = load_allowlist(allowlist_path)
    except ValueError as error:
        return full_proof(str(error))
    if not SHA.fullmatch(base or "") or not SHA.fullmatch(merge or ""):
        return full_proof("sha_invalid")
    if base == ZERO_SHA or merge == ZERO_SHA:
        return full_proof("sha_zero")
    if not git_ok(repo, ["cat-file", "-e", f"{base}^{{commit}}"]):
        return full_proof("base_unresolvable")
    if not git_ok(repo, ["cat-file", "-e", f"{merge}^{{commit}}"]):
        return full_proof("merge_unresolvable")
    diff = subprocess.run(
        ["git", "-C", os.fspath(repo), "diff", "--name-status", "-z", "-M", "-C", base, merge],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if diff.returncode != 0:
        return full_proof("diff_unavailable")
    return classify_records(parse_name_status(diff.stdout), allowlist)


def emit(result: dict[str, object], github_output: str | None) -> None:
    serialized = json.dumps(result, sort_keys=True, separators=(",", ":"))
    if github_output:
        with open(github_output, "a", encoding="utf-8") as stream:
            stream.write(f"schema_version={result['schema_version']}\n")
            stream.write(f"classification={result['classification']}\n")
            stream.write(f"reason={result['reason']}\n")
            stream.write(
                "scheduled_families="
                + json.dumps(result["scheduled_families"], separators=(",", ":"))
                + "\n"
            )
            stream.write(
                "irrelevant_leaves="
                + json.dumps(result["irrelevant_leaves"], separators=(",", ":"))
                + "\n"
            )
    print(serialized)


class ClassifierSelfTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.allowlist = load_allowlist(Path(__file__).with_name("ci_docs_allowlist.json"))

    def assert_classification(self, raw: bytes, expected: str) -> None:
        result = classify_records(parse_name_status(raw), self.allowlist)
        self.assertEqual(result["classification"], expected)

    def test_closed_status_arity_and_path_boundaries(self) -> None:
        for raw in (
            b"A\0README.md\0",
            b"M\0guides/a.md\0",
            b"D\0brandbook/retired.md\0",
            b"R100\0guides/old.md\0guides/new.md\0",
            b"C075\0docs/source.md\0docs/copy.md\0",
            b"A\0guides/newline\nname.md\0",
            b"A\0guides/[literal]*.md\0",
        ):
            self.assert_classification(raw, "documentation_only")

        for raw in (
            b"A\0README.md\0M\0lib/crosswake.ex\0",
            b"A\0docs/PORT-REGISTRY.md\0",
            b"Z\0README.md\0",
            b"R100\0guides/old.md\0",
            b"A\0README.md",
            b"",
            b"M\0/absolute.md\0",
            b"M\0guides/../secret.md\0",
        ):
            self.assert_classification(raw, "full_proof")

    def test_record_order_does_not_change_output(self) -> None:
        first = b"A\0README.md\0M\0guides/a.md\0"
        second = b"M\0guides/a.md\0A\0README.md\0"
        self.assertEqual(
            classify_records(parse_name_status(first), self.allowlist),
            classify_records(parse_name_status(second), self.allowlist),
        )

    def test_zero_and_unresolvable_shas_fail_closed(self) -> None:
        repo = Path.cwd()
        self.assertEqual(
            classify(repo, ZERO_SHA, "a" * 40, Path(__file__).with_name("ci_docs_allowlist.json"))[
                "classification"
            ],
            "full_proof",
        )
        self.assertEqual(
            classify(repo, "a" * 40, "b" * 40, Path(__file__).with_name("ci_docs_allowlist.json"))[
                "classification"
            ],
            "full_proof",
        )

    def test_shallow_checkout_requires_object_acquisition(self) -> None:
        with tempfile.TemporaryDirectory(prefix="crosswake-ci-classifier-") as root_text:
            root = Path(root_text)
            source = root / "source"
            remote = root / "remote.git"
            shallow = root / "shallow"
            subprocess.run(["git", "init", "-q", "-b", "main", os.fspath(source)], check=True)
            subprocess.run(["git", "-C", os.fspath(source), "config", "user.name", "CI Fixture"], check=True)
            subprocess.run(["git", "-C", os.fspath(source), "config", "user.email", "fixture@example.invalid"], check=True)
            (source / "README.md").write_text("base\n", encoding="utf-8")
            subprocess.run(["git", "-C", os.fspath(source), "add", "README.md"], check=True)
            subprocess.run(["git", "-C", os.fspath(source), "commit", "-qm", "base"], check=True)
            base = subprocess.check_output(["git", "-C", os.fspath(source), "rev-parse", "HEAD"], text=True).strip()
            subprocess.run(["git", "-C", os.fspath(source), "checkout", "-qb", "feature"], check=True)
            (source / "README.md").write_text("base\ndocs\n", encoding="utf-8")
            subprocess.run(["git", "-C", os.fspath(source), "commit", "-qam", "docs"], check=True)
            subprocess.run(["git", "-C", os.fspath(source), "checkout", "-q", "main"], check=True)
            subprocess.run(["git", "-C", os.fspath(source), "merge", "--no-ff", "-qm", "synthetic merge", "feature"], check=True)
            merge = subprocess.check_output(["git", "-C", os.fspath(source), "rev-parse", "HEAD"], text=True).strip()
            subprocess.run(["git", "init", "--bare", "-q", os.fspath(remote)], check=True)
            subprocess.run(["git", "-C", os.fspath(source), "remote", "add", "origin", os.fspath(remote)], check=True)
            subprocess.run(["git", "-C", os.fspath(source), "push", "-q", "origin", "main", "feature"], check=True)
            subprocess.run(["git", "clone", "-q", "--depth", "1", "--branch", "main", f"file://{remote}", os.fspath(shallow)], check=True)
            allowlist_path = Path(__file__).with_name("ci_docs_allowlist.json")
            self.assertEqual(classify(shallow, base, merge, allowlist_path)["classification"], "full_proof")
            subprocess.run(["git", "-C", os.fspath(shallow), "fetch", "-q", "--unshallow", "origin"], check=True)
            self.assertEqual(classify(shallow, base, merge, allowlist_path)["classification"], "documentation_only")


def run_self_test() -> int:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(ClassifierSelfTest)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    if result.wasSuccessful():
        print("classifier self-test: pass")
        return 0
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--repo", default=".")
    parser.add_argument("--base")
    parser.add_argument("--merge")
    parser.add_argument("--allowlist", default=os.fspath(Path(__file__).with_name("ci_docs_allowlist.json")))
    parser.add_argument("--github-output")
    args = parser.parse_args()
    if args.self_test:
        return run_self_test()
    if args.base is None or args.merge is None:
        parser.error("--base and --merge are required")
    emit(classify(Path(args.repo), args.base.lower(), args.merge.lower(), Path(args.allowlist)), args.github_output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
