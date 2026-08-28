#!/usr/bin/env python3
"""Inventory literal GitHub Actions job producers with fail-closed diagnostics.

The default view lists merge-blocking registration candidates. ``--emitters`` emits every
candidate record, while ``--producers`` emits every literal job producer. Records are stable TSV:
``<display name>\t<workflow path>\t<job id>``. The full view lets the branch-protection audit
prove registered contexts have a local producer without confusing registration policy with local
workflow truth.

An omitted job ``name`` deliberately resolves to the literal job id, matching GitHub's check-name
fallback. An explicitly empty name or an expression-bearing name has no stable authority and fails.
Malformed workflow structure and duplicate merge-blocking producers also fail with provenance.
"""

import glob
import sys
from collections import defaultdict

try:
    import yaml
except ImportError:
    # Preserve the repository's existing runner bootstrap behavior. No new dependency is added.
    import subprocess

    yaml = None
    for _extra in ([], ["--user"], ["--break-system-packages"]):
        try:
            subprocess.run(
                [sys.executable, "-m", "pip", "install", "--quiet", *_extra, "pyyaml"],
                check=True,
                capture_output=True,
            )
            import yaml  # noqa: F811

            break
        except Exception:
            yaml = None

    if yaml is None:
        print("[crosswake] FAIL: PyYAML is required (pip install pyyaml)", file=sys.stderr)
        sys.exit(2)


def diagnostic(identifier: str, path: str, job: str | None, detail: str, fix: str) -> str:
    source = path if job is None else f"{path} ({job})"
    return (
        f"[crosswake] FAIL: {identifier} - {source}: {detail}\n"
        f"[crosswake]   What to do next: {fix}"
    )


def inventory() -> tuple[list[tuple[str, str, str]], list[str]]:
    records: list[tuple[str, str, str]] = []
    errors: list[str] = []
    paths = sorted(glob.glob(".github/workflows/*.yml") + glob.glob(".github/workflows/*.yaml"))

    if not paths:
        errors.append(
            diagnostic(
                "missing-workflows",
                ".github/workflows",
                None,
                "no workflow YAML files were found",
                "restore the workflow tree before evaluating required-check authority.",
            )
        )
        return records, errors

    for path in paths:
        try:
            with open(path, encoding="utf-8") as stream:
                doc = yaml.safe_load(stream)
        except Exception as exc:
            errors.append(
                diagnostic(
                    "malformed-workflow",
                    path,
                    None,
                    f"YAML parsing failed ({type(exc).__name__})",
                    "repair the YAML so every job can be inventoried.",
                )
            )
            continue

        if not isinstance(doc, dict):
            errors.append(
                diagnostic(
                    "non-map-workflow",
                    path,
                    None,
                    "the workflow document is empty or is not a mapping",
                    "define a workflow mapping with a jobs mapping.",
                )
            )
            continue

        jobs = doc.get("jobs")
        if not isinstance(jobs, dict):
            errors.append(
                diagnostic(
                    "non-map-jobs",
                    path,
                    None,
                    "jobs is missing or is not a mapping",
                    "define jobs as a mapping from literal job ids to job definitions.",
                )
            )
            continue

        if not jobs:
            errors.append(
                diagnostic(
                    "empty-jobs",
                    path,
                    None,
                    "the jobs mapping is empty",
                    "add the workflow's literal job producers or remove the empty workflow.",
                )
            )
            continue

        for job_id, job in sorted(jobs.items(), key=lambda item: str(item[0])):
            job_id_text = str(job_id)
            if not isinstance(job_id, str) or not isinstance(job, dict):
                errors.append(
                    diagnostic(
                        "malformed-job",
                        path,
                        job_id_text,
                        "job id and definition must be a string and mapping",
                        "replace the job with one literal id and a mapping definition.",
                    )
                )
                continue

            if "name" not in job:
                name = job_id
            else:
                name = job.get("name")
                if not isinstance(name, str) or not name.strip():
                    errors.append(
                        diagnostic(
                            "unnamed-authority",
                            path,
                            job_id,
                            "the explicit display name is empty or non-string",
                            "set one non-empty literal name, or omit name to use the literal job id.",
                        )
                    )
                    continue

            if "${{" in name:
                errors.append(
                    diagnostic(
                        "dynamic-authority",
                        path,
                        job_id,
                        f"display name {name!r} is expression-bearing",
                        "replace it with one stable literal name before making it required.",
                    )
                )
                continue

            if "\t" in name or "\n" in name:
                errors.append(
                    diagnostic(
                        "malformed-authority-name",
                        path,
                        job_id,
                        "display name contains a tab or newline and cannot be emitted as TSV",
                        "use a single-line literal display name.",
                    )
                )
                continue

            records.append((name, path, job_id))

    required = defaultdict(list)
    for record in records:
        if "merge-blocking" in record[0].lower():
            required[record[0]].append(record)

    for name, producers in sorted(required.items()):
        if len(producers) > 1:
            sources = ", ".join(f"{path} ({job})" for _, path, job in producers)
            errors.append(
                diagnostic(
                    "duplicate-producer/duplicate-merge-blocking-name",
                    sources,
                    None,
                    f"literal context {name!r} has {len(producers)} producers",
                    "rename the later producer while retaining a stable merge-blocking name.",
                )
            )

    return sorted(records), errors


def main() -> int:
    args = sys.argv[1:]
    allowed = {"--emitters", "--producers"}
    if len(args) > 1 or any(arg not in allowed for arg in args):
        print("usage: list_merge_blocking_checks.py [--emitters|--producers]", file=sys.stderr)
        return 2

    mode = args[0] if args else "--contexts"
    records, errors = inventory()

    if mode == "--producers":
        selected = records
    else:
        selected = [record for record in records if "merge-blocking" in record[0].lower()]

    if mode in {"--emitters", "--producers"}:
        for name, path, job_id in selected:
            print(f"{name}\t{path}\t{job_id}")
    else:
        for name in sorted({record[0] for record in selected}):
            print(name)

    for error in errors:
        print(error, file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
