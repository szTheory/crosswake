#!/usr/bin/env python3
"""Validate the evidence-bounded Phase 166 ownership ledger."""

from __future__ import annotations

import argparse
import re
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_LEDGER = ROOT / ".planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md"
DISPOSITIONS = {"retained", "changed", "removed-with-proof", "unproven-retained"}
EDGE_KINDS = {"caller", "import", "include", "generator", "mutator", "test", "shared-authority"}
REMOVAL_FIELDS = (
    "supported-entrypoint",
    "workflow/config",
    "dependency",
    "dynamic-dispatch",
    "focused-regression",
    "complete-clean-gate",
)


@dataclass(frozen=True)
class Problem:
    kind: str
    member: str
    detail: str

    def render(self) -> str:
        return f"phase166-ownership: FAIL: {self.kind} member={self.member} detail={self.detail}"


def git(*args: str, cwd: Path) -> bytes:
    return subprocess.run(
        ["git", *args], cwd=cwd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ).stdout


def candidates(root: Path, base: str, tree: str) -> list[str]:
    raw = git("diff", "--name-only", "-z", base, tree, cwd=root)
    paths = [item.decode("utf-8", "surrogateescape") for item in raw.split(b"\0") if item]
    return sorted(path for path in paths if not path.startswith(".planning/"))


def metadata(text: str, label: str) -> str | None:
    match = re.search(rf"^- {re.escape(label)}: `([^`]+)`$", text, re.MULTILINE)
    return match.group(1) if match else None


def table(text: str, heading: str, columns: list[str]) -> list[dict[str, str]] | None:
    match = re.search(rf"^## {re.escape(heading)}\n\n((?:\|.*\n)+)", text, re.MULTILINE)
    if not match:
        return None
    lines = match.group(1).strip().splitlines()
    parsed = [[cell.strip() for cell in line.strip().strip("|").split("|")] for line in lines]
    if len(parsed) < 2 or parsed[0] != columns or len(parsed[1]) != len(columns):
        return None
    return [dict(zip(columns, row)) for row in parsed[2:] if len(row) == len(columns)]


def valid_value(value: str) -> bool:
    return bool(value and value != "-" and "\n" not in value and "\r" not in value)


def has_cycle(edges: list[dict[str, str]]) -> bool:
    graph: dict[str, set[str]] = {}
    for edge in edges:
        graph.setdefault(edge["source candidate"], set()).add(edge["target"])
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(node: str) -> bool:
        if node in visiting:
            return True
        if node in visited:
            return False
        visiting.add(node)
        if any(visit(child) for child in graph.get(node, ())):
            return True
        visiting.remove(node)
        visited.add(node)
        return False

    return any(visit(node) for node in graph)


def validate_text(text: str, root: Path) -> list[Problem]:
    problems: list[Problem] = []
    base = metadata(text, "Base commit")
    tree = metadata(text, "Tree commit")
    if not base or not tree:
        return [Problem("missing_metadata", "ledger", "base and tree commits are required")]
    try:
        expected = candidates(root, base, tree)
    except subprocess.CalledProcessError:
        return [Problem("invalid_git_range", "ledger", "base and tree must resolve in this repository")]

    candidate_columns = ["candidate", "evidence", "owner", "disposition"]
    rows = table(text, "Candidates", candidate_columns)
    if rows is None:
        return [Problem("invalid_candidate_table", "candidates", "exact candidate columns are required")]
    observed = [row["candidate"] for row in rows]
    for path in sorted(set(expected) - set(observed)):
        problems.append(Problem("missing_candidate", path, "Git candidate has no ledger row"))
    for path in sorted(set(observed) - set(expected)):
        problems.append(Problem("extra_candidate", path, "ledger row is outside the Git candidate set"))
    for path in sorted({path for path in observed if observed.count(path) > 1}):
        problems.append(Problem("duplicate_candidate", path, "candidate occurs more than once"))
    if observed != sorted(observed):
        problems.append(Problem("unordered_candidates", "candidates", "candidate rows must be sorted"))
    for row in rows:
        if not valid_value(row["evidence"]) or not valid_value(row["owner"]):
            problems.append(Problem("incomplete_candidate", row["candidate"], "evidence and owner are required"))
        if row["disposition"] not in DISPOSITIONS:
            problems.append(Problem("unknown_disposition", row["candidate"], row["disposition"]))

    edge_columns = ["source candidate", "target", "edge kind", "evidence", "owner", "disposition"]
    edges = table(text, "Direct expansions", edge_columns)
    closure_columns = ["source candidate", "target", "terminal result"]
    closures = table(text, "Closed edges", closure_columns)
    removal_columns = ["candidate", *REMOVAL_FIELDS]
    removals = table(text, "Removal evidence", removal_columns)
    if edges is None or closures is None or removals is None:
        problems.append(Problem("invalid_expansion_schema", "ledger", "expansion, closure, and removal tables are required"))
        return problems

    edge_keys = [(row["source candidate"], row["target"]) for row in edges]
    closure_map = {(row["source candidate"], row["target"]): row["terminal result"] for row in closures}
    expansion_sources = set(expected)
    for row in edges:
        key = (row["source candidate"], row["target"])
        if row["source candidate"] not in expansion_sources:
            problems.append(Problem("invalid_edge_source", row["source candidate"], "source is neither a Git candidate nor an earlier direct expansion"))
        if row["edge kind"] not in EDGE_KINDS:
            problems.append(Problem("invalid_edge_kind", " -> ".join(key), row["edge kind"]))
        if not all(valid_value(row[field]) for field in ("target", "evidence", "owner")):
            problems.append(Problem("incomplete_edge", " -> ".join(key), "target, evidence, and owner are required"))
        if row["disposition"] not in DISPOSITIONS:
            problems.append(Problem("unknown_disposition", " -> ".join(key), row["disposition"]))
        if key not in closure_map:
            problems.append(Problem("open_edge", " -> ".join(key), "terminal closure is absent"))
        elif closure_map[key] != row["disposition"]:
            problems.append(Problem("closure_mismatch", " -> ".join(key), closure_map[key]))
        expansion_sources.add(row["target"])
    for key in sorted(set(closure_map) - set(edge_keys)):
        problems.append(Problem("extra_closure", " -> ".join(key), "closure has no expansion row"))
    if len(edge_keys) != len(set(edge_keys)) or len(closure_map) != len(closures):
        problems.append(Problem("duplicate_edge", "direct expansions", "edges and closures must be unique"))
    if edge_keys != sorted(edge_keys):
        problems.append(Problem("unordered_edges", "direct expansions", "expansions must be sorted"))
    if has_cycle(edges):
        problems.append(Problem("cyclic_expansion", "direct expansions", "ownership expansion must terminate"))

    removal_map = {row["candidate"]: row for row in removals}
    removed = {row["candidate"] for row in rows if row["disposition"] == "removed-with-proof"}
    removed.update(row["target"] for row in edges if row["disposition"] == "removed-with-proof")
    for path in sorted(removed - set(removal_map)):
        problems.append(Problem("missing_removal_evidence", path, "D-09 evidence row is absent"))
    for path in sorted(set(removal_map) - removed):
        problems.append(Problem("extra_removal_evidence", path, "path is not removed-with-proof"))
    for path, row in removal_map.items():
        for field in REMOVAL_FIELDS:
            if not valid_value(row[field]):
                problems.append(Problem(f"missing_{field.replace('/', '_').replace('-', '_')}", path, "D-09 evidence is required"))
    return problems


def render_ledger(base: str, tree: str, rows: list[str], edge_rows: list[list[str]], removal_rows: list[list[str]] | None = None) -> str:
    candidate_lines = ["| candidate | evidence | owner | disposition |", "| --- | --- | --- | --- |", *rows]
    edge_lines = ["| source candidate | target | edge kind | evidence | owner | disposition |", "| --- | --- | --- | --- | --- | --- |", *("| " + " | ".join(row) + " |" for row in edge_rows)]
    closure_lines = ["| source candidate | target | terminal result |", "| --- | --- | --- |", *(f"| {row[0]} | {row[1]} | {row[5]} |" for row in edge_rows)]
    removal_lines = ["| candidate | " + " | ".join(REMOVAL_FIELDS) + " |", "| --- | " + " | ".join("---" for _ in REMOVAL_FIELDS) + " |", *("| " + " | ".join(row) + " |" for row in (removal_rows or []))]
    return "\n".join([
        "# Phase 166 Ownership Ledger", "", f"- Base commit: `{base}`", f"- Tree commit: `{tree}`", "- Unresolved flag: `FA-ENG-02`", "",
        "## Candidates", "", *candidate_lines, "", "## Direct expansions", "", *edge_lines, "", "## Closed edges", "", *closure_lines, "", "## Removal evidence", "", *removal_lines, "",
    ])


def self_test() -> int:
    with tempfile.TemporaryDirectory(prefix="phase166-ownership.") as tmp:
        root = Path(tmp)
        git("init", "-q", cwd=root)
        git("config", "user.email", "phase166@example.invalid", cwd=root)
        git("config", "user.name", "Phase 166", cwd=root)
        (root / "a.txt").write_text("a\n")
        git("add", "a.txt", cwd=root); git("commit", "-qm", "base", cwd=root)
        base = git("rev-parse", "HEAD", cwd=root).decode().strip()
        (root / "a.txt").write_text("changed\n"); (root / "b.txt").write_text("b\n")
        git("add", "a.txt", "b.txt", cwd=root); git("commit", "-qm", "tree", cwd=root)
        tree = git("rev-parse", "HEAD", cwd=root).decode().strip()
        rows = [
            "| a.txt | focused test | owner-a | retained |",
            "| b.txt | workflow search | owner-b | removed-with-proof |",
        ]
        edges = [["a.txt", "direct.txt", "caller", "literal call", "direct-owner", "retained"]]
        proof = ["b.txt", "entrypoint search", "config search", "dependency trace", "dispatch review", "focused test", "complete gate"]
        valid = render_ledger(base, tree, rows, edges, [proof])
        mutations = {
            "missing_candidate": valid.replace(rows[1] + "\n", ""),
            "extra_candidate": valid.replace(rows[1], rows[1] + "\n| extra.txt | evidence | owner | retained |"),
            "open_edge": valid.replace("| a.txt | direct.txt | retained |\n", ""),
            "unknown_disposition": valid.replace("| a.txt | focused test | owner-a | retained |", "| a.txt | focused test | owner-a | mystery |"),
        }
        for index, field in enumerate(REMOVAL_FIELDS, 1):
            broken = proof.copy(); broken[index] = "-"
            mutations[f"missing_{field.replace('/', '_').replace('-', '_')}"] = render_ledger(base, tree, rows, edges, [broken])
        if validate_text(valid, root):
            print("FAIL valid_fixture")
            return 1
        for name, mutation in mutations.items():
            if not validate_text(mutation, root):
                print(f"FAIL {name}")
                return 1
            print(f"PASS {name}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    problems = validate_text(args.ledger.read_text(encoding="utf-8"), args.root.resolve())
    if problems:
        for problem in sorted(problems, key=lambda item: (item.kind, item.member, item.detail)):
            print(problem.render())
        return 1
    print("phase166-ownership: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
