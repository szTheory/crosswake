#!/usr/bin/env python3
"""Validate the evidence-bounded Phase 166 ownership ledger."""

from __future__ import annotations

import argparse
import json
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
REMEDIATION_COLUMNS = (
    "source path",
    "owner",
    "finding class",
    "focused regression",
    "focused command",
    "result",
)
FINDING_CLASSES = {
    "dead-branch",
    "accidental-duplicate",
    "misleading-fallback",
    "responsibility-extraction",
}
REMEDIATION_RESULTS = {"pending", "pass"}
EVIDENCE_ONLY_PATHS = {
    ".planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.json",
    ".planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/evidence/clean-checkout-run.md",
    ".planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-ownership-ledger.md",
    ".planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-VALIDATION.md",
}


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
    while True:
        expanded = expansion_sources | {
            row["target"]
            for row in edges
            if row["source candidate"] in expansion_sources and valid_value(row["target"])
        }
        if expanded == expansion_sources:
            break
        expansion_sources = expanded
    for row in edges:
        key = (row["source candidate"], row["target"])
        if row["source candidate"] not in expansion_sources:
            problems.append(Problem("invalid_edge_source", row["source candidate"], "source is not reachable from a Git candidate"))
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


def validate_evidence_binding(text: str, evidence_path: Path) -> list[Problem]:
    problems: list[Problem] = []
    tree = metadata(text, "Tree commit")
    try:
        evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        return [Problem("invalid_evidence", str(evidence_path), type(error).__name__)]

    evidence_sha = evidence.get("supported_code_sha")
    if evidence_sha != tree:
        problems.append(
            Problem("evidence_sha_mismatch", str(evidence_path), f"expected={tree} actual={evidence_sha}")
        )

    section = re.search(r"^## Evidence-only delta\n\n(.*?)(?=^## |\Z)", text, re.MULTILINE | re.DOTALL)
    observed_paths = set(re.findall(r"`([^`]+)`", section.group(1))) if section else set()
    for path in sorted(EVIDENCE_ONLY_PATHS - observed_paths):
        problems.append(Problem("missing_evidence_only_path", path, "path is absent from evidence-only delta"))
    for path in sorted(observed_paths - EVIDENCE_ONLY_PATHS):
        problems.append(Problem("extra_evidence_only_path", path, "path is outside the closed evidence-only delta"))

    stages = evidence.get("stages")
    if not isinstance(stages, list) or len(stages) != 9 or any(
        not isinstance(stage, dict) or stage.get("result") != "PASS" for stage in stages
    ):
        problems.append(Problem("incomplete_clean_gate", str(evidence_path), "all nine stages must pass"))
    repository_state = evidence.get("repository_state")
    if not isinstance(repository_state, dict) or any(
        repository_state.get(key) is not True
        for key in ("baseline_empty", "final_empty", "snapshots_equal", "index_unchanged")
    ):
        problems.append(Problem("unclean_repository_state", str(evidence_path), "repository state is not closed"))
    if evidence.get("cleanup") != {"status": "PASS"}:
        problems.append(Problem("incomplete_cleanup", str(evidence_path), "owned cleanup did not pass"))
    return problems


def remediation_queue(text: str, root: Path) -> tuple[list[dict[str, str]], list[Problem]]:
    problems = validate_text(text, root)
    if problems:
        return [], problems

    candidates_rows = table(text, "Candidates", ["candidate", "evidence", "owner", "disposition"])
    edge_rows = table(
        text,
        "Direct expansions",
        ["source candidate", "target", "edge kind", "evidence", "owner", "disposition"],
    )
    queue_rows = table(text, "Remediation queue", list(REMEDIATION_COLUMNS))
    if candidates_rows is None or edge_rows is None or queue_rows is None:
        return [], [Problem("invalid_remediation_schema", "remediation queue", "exact remediation columns are required")]

    expected_paths = {
        row["candidate"] for row in candidates_rows if row["disposition"] in {"changed", "removed-with-proof"}
    }
    expected_paths.update(
        row["target"] for row in edge_rows if row["disposition"] in {"changed", "removed-with-proof"}
    )
    observed_paths = [row["source path"] for row in queue_rows]

    for path in sorted(expected_paths - set(observed_paths)):
        problems.append(Problem("missing_remediation", path, "changed path has no remediation row"))
    for path in sorted(set(observed_paths) - expected_paths):
        problems.append(Problem("extra_remediation", path, "row is not backed by a changed disposition"))
    for path in sorted({path for path in observed_paths if observed_paths.count(path) > 1}):
        problems.append(Problem("duplicate_remediation", path, "source path occurs more than once"))
    if observed_paths != sorted(observed_paths):
        problems.append(Problem("unordered_remediations", "remediation queue", "rows must be sorted by source path"))

    for row in queue_rows:
        source = row["source path"]
        regression = row["focused regression"]
        for field in REMEDIATION_COLUMNS:
            if not valid_value(row[field]):
                problems.append(Problem("incomplete_remediation", source, f"{field} is required"))
        if row["finding class"] not in FINDING_CLASSES:
            problems.append(Problem("unknown_finding_class", source, row["finding class"]))
        if row["result"] not in REMEDIATION_RESULTS:
            problems.append(Problem("unknown_remediation_result", source, row["result"]))
        for kind, path in (("source", source), ("regression", regression)):
            if path.startswith("/") or ".." in Path(path).parts or path.startswith(".planning/"):
                problems.append(Problem(f"invalid_{kind}_path", source, path))
                continue
            try:
                git("ls-files", "--error-unmatch", "--", path, cwd=root)
            except subprocess.CalledProcessError:
                problems.append(Problem(f"untracked_{kind}_path", source, path))

    return queue_rows, problems


def render_remediation_queue(rows: list[dict[str, str]]) -> str:
    lines = [f"phase166-remediations: PASS count={len(rows)}"]
    lines.extend(
        "phase166-remediation: " + json.dumps(row, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
        for row in rows
    )
    return "\n".join(lines)


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
        (root / "z.txt").write_text("z\n")
        git("add", "a.txt", "b.txt", "z.txt", cwd=root); git("commit", "-qm", "tree", cwd=root)
        tree = git("rev-parse", "HEAD", cwd=root).decode().strip()
        rows = [
            "| a.txt | focused test | owner-a | retained |",
            "| b.txt | workflow search | owner-b | removed-with-proof |",
            "| z.txt | dependency trace | owner-z | retained |",
        ]
        edges = [
            ["m-expanded", "a-expanded", "caller", "literal call", "deep-owner", "retained"],
            ["z.txt", "m-expanded", "caller", "literal call", "middle-owner", "retained"],
        ]
        proof = ["b.txt", "entrypoint search", "config search", "dependency trace", "dispatch review", "focused test", "complete gate"]
        valid = render_ledger(base, tree, rows, edges, [proof])
        remediation_header = "\n".join([
            "## Remediation queue",
            "",
            "| " + " | ".join(REMEDIATION_COLUMNS) + " |",
            "| " + " | ".join("---" for _ in REMEDIATION_COLUMNS) + " |",
        ])
        remediation_row = "| b.txt | owner-b | dead-branch | a.txt | test -f a.txt | pass |"
        valid = valid + remediation_header + "\n" + remediation_row + "\n"
        mutations = {
            "missing_candidate": valid.replace(rows[1] + "\n", ""),
            "extra_candidate": valid.replace(rows[1], rows[1] + "\n| extra.txt | evidence | owner | retained |"),
            "open_edge": valid.replace("| m-expanded | a-expanded | retained |\n", ""),
            "unknown_disposition": valid.replace("| a.txt | focused test | owner-a | retained |", "| a.txt | focused test | owner-a | mystery |"),
        }
        for index, field in enumerate(REMOVAL_FIELDS, 1):
            broken = proof.copy(); broken[index] = "-"
            mutations[f"missing_{field.replace('/', '_').replace('-', '_')}"] = render_ledger(base, tree, rows, edges, [broken])
        if validate_text(valid, root):
            print("FAIL valid_fixture")
            return 1
        print("PASS reverse_lexical_multihop")
        for name, mutation in mutations.items():
            if not validate_text(mutation, root):
                print(f"FAIL {name}")
                return 1
            print(f"PASS {name}")
        queue, queue_problems = remediation_queue(valid, root)
        if queue_problems or render_remediation_queue(queue) != (
            'phase166-remediations: PASS count=1\n'
            'phase166-remediation: {"finding class":"dead-branch","focused command":"test -f a.txt",'
            '"focused regression":"a.txt","owner":"owner-b","result":"pass","source path":"b.txt"}'
        ):
            print("FAIL deterministic_remediation_queue")
            return 1
        print("PASS deterministic_remediation_queue")

        empty = render_ledger(base, base, [], [], []) + remediation_header + "\n"
        empty_queue, empty_problems = remediation_queue(empty, root)
        if empty_problems or render_remediation_queue(empty_queue) != "phase166-remediations: PASS count=0":
            print("FAIL empty_remediation_queue")
            return 1
        print("PASS empty_remediation_queue")

        evidence_only = "\n".join(
            ["", "## Evidence-only delta", ""]
            + [f"- `{path}`" for path in sorted(EVIDENCE_ONLY_PATHS)]
            + [""]
        )
        evidence = {
            "supported_code_sha": tree,
            "stages": [{"stage_id": f"stage-{index}", "result": "PASS"} for index in range(9)],
            "repository_state": {
                "baseline_empty": True,
                "final_empty": True,
                "snapshots_equal": True,
                "index_unchanged": True,
            },
            "cleanup": {"status": "PASS"},
        }
        evidence_path = root / "evidence.json"
        evidence_path.write_text(json.dumps(evidence), encoding="utf-8")
        if validate_evidence_binding(valid + evidence_only, evidence_path):
            print("FAIL evidence_binding")
            return 1
        print("PASS evidence_binding")

        evidence["supported_code_sha"] = base
        evidence_path.write_text(json.dumps(evidence), encoding="utf-8")
        if not any(
            problem.kind == "evidence_sha_mismatch"
            for problem in validate_evidence_binding(valid + evidence_only, evidence_path)
        ):
            print("FAIL evidence_sha_mismatch")
            return 1
        print("PASS evidence_sha_mismatch")

        evidence["supported_code_sha"] = tree
        evidence_path.write_text(json.dumps(evidence), encoding="utf-8")
        if not any(
            problem.kind == "missing_evidence_only_path"
            for problem in validate_evidence_binding(valid, evidence_path)
        ):
            print("FAIL missing_evidence_only_path")
            return 1
        print("PASS missing_evidence_only_path")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--verify-remediations", type=Path)
    parser.add_argument("--evidence", type=Path)
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if args.verify_remediations:
        queue, problems = remediation_queue(
            args.verify_remediations.read_text(encoding="utf-8"), args.root.resolve()
        )
        if problems:
            for problem in sorted(problems, key=lambda item: (item.kind, item.member, item.detail)):
                print(problem.render())
            return 1
        print(render_remediation_queue(queue))
        return 0
    ledger_text = args.ledger.read_text(encoding="utf-8")
    problems = validate_text(ledger_text, args.root.resolve())
    if args.evidence:
        problems.extend(validate_evidence_binding(ledger_text, args.evidence))
    if problems:
        for problem in sorted(problems, key=lambda item: (item.kind, item.member, item.detail)):
            print(problem.render())
        return 1
    print("phase166-ownership: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
