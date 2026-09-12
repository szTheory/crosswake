#!/usr/bin/env python3
from __future__ import annotations
"""Inventory literal GitHub Actions job producers with fail-closed diagnostics.

The default view lists exact target contexts from ``script/required_check_policy.json``.
``--emitters`` emits those target producer records, while ``--producers`` emits every literal job
producer. Isolated fixtures without a policy retain substring discovery for detector self-tests.
Records are stable TSV:
``<display name>\t<workflow path>\t<job id>``. The full view lets the branch-protection audit
prove registered contexts have a local producer without confusing registration policy with local
workflow truth.

An omitted job ``name`` deliberately resolves to the literal job id, matching GitHub's check-name
fallback. An explicitly empty name or an expression-bearing name has no stable authority and fails.
Malformed workflow structure and duplicate merge-blocking producers also fail with provenance.
"""

import argparse
import glob
import json
import os
import sys
from collections import defaultdict

try:
    import yaml
except ImportError:
    print("[crosswake] FAIL: PyYAML is required; use the declared dependency setup", file=sys.stderr)
    sys.exit(2)


CROSSWAKE_CI = ".github/workflows/crosswake-ci.yml"
REQUIRED_CHECK_POLICY = "script/required_check_policy.json"
MIGRATED_SOURCE_WORKFLOWS = {
    ".github/workflows/brandbook-verify.yml",
    ".github/workflows/collateral-guard.yml",
    ".github/workflows/hex-page-proof.yml",
    ".github/workflows/release-as-staleness-gate.yml",
    ".github/workflows/phase130-proof.yml",
    ".github/workflows/phase132-proof.yml",
    ".github/workflows/phase23-proof.yml",
    ".github/workflows/phase34-proof.yml",
    ".github/workflows/phase41-proof.yml",
    ".github/workflows/phase43-proof.yml",
    ".github/workflows/phase45-proof.yml",
    ".github/workflows/phase48-proof.yml",
    ".github/workflows/phase52-proof.yml",
    ".github/workflows/phase58-proof.yml",
    ".github/workflows/phase69-proof.yml",
    ".github/workflows/phase70-proof.yml",
    ".github/workflows/phase71-proof.yml",
    ".github/workflows/phase73-proof.yml",
    ".github/workflows/phase74-proof.yml",
    ".github/workflows/phase75-closeout-gate.yml",
}
MIGRATED_JOB_IDS = {
    "brand-structural",
    "collateral-binaries-guard",
    "hex-page-proof",
    "release-as-staleness-proof",
    "proof-aggregator-negative-control",
    "guard-01-contract-drift-test",
    "guard-02-generate-and-diff",
    "proof-dependency-security",
    "proof-requires-example-host",
    "phase130-core-hermetic-proof",
    "phase130-companion-engine-absent-proof",
    "phase132-core-hermetic-proof",
    "phase132-companion-engine-absent-proof",
    "phase23-commerce-proof",
    "phase34-commerce-proof",
    "phase41-gating-proof",
    "phase43-rulestead-proof",
    "phase45-rindle-proof",
    "phase48-provider-adapter-proof",
    "phase52-operator-proof",
    "phase58-auth-closeout-proof",
    "phase69-closeout-proof",
    "phase70-subscription-saas-proof",
    "phase71-notification-workflow-proof",
    "phase73-auth-sensitive-admin-workflow-proof",
    "phase74-offline-draft-recovery-proof",
    "phase75-closeout-gate",
}


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

        triggers = doc.get("on", doc.get(True, {}))
        trigger_names = set(triggers) if isinstance(triggers, dict) else set()
        if path == CROSSWAKE_CI:
            if trigger_names != {"pull_request"}:
                errors.append(
                    diagnostic(
                        "migrated-authority-trigger",
                        path,
                        None,
                        f"Crosswake CI triggers are {sorted(trigger_names)!r}",
                        "retain pull_request as the sole recurring product-proof authority.",
                    )
                )
        elif path in MIGRATED_SOURCE_WORKFLOWS:
            forbidden = trigger_names & {"pull_request", "push"}
            if forbidden:
                errors.append(
                    diagnostic(
                        "migrated-source-trigger",
                        path,
                        None,
                        f"retained advisory workflow still has {sorted(forbidden)!r}",
                        "keep only schedule and workflow_dispatch authority.",
                    )
                )
            duplicate_jobs = set(jobs) & MIGRATED_JOB_IDS
            if duplicate_jobs:
                errors.append(
                    diagnostic(
                        "migrated-job-duplicate",
                        path,
                        None,
                        f"moved jobs remain present: {sorted(duplicate_jobs)!r}",
                        "remove the PR-owned jobs from the retained advisory workflow.",
                    )
                )

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
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--emitters", action="store_true")
    modes.add_argument("--producers", action="store_true")
    parser.add_argument("--require-display-name")
    args = parser.parse_args()
    mode = "--producers" if args.producers else "--emitters" if args.emitters else "--contexts"
    records, errors = inventory()

    target_names = None
    if os.path.isfile(REQUIRED_CHECK_POLICY):
        try:
            with open(REQUIRED_CHECK_POLICY, encoding="utf-8") as handle:
                policy = json.load(handle)
            target_names = policy.get("target_contexts")
            target_check = policy.get("target_check")
            if (
                not isinstance(target_names, list)
                or not target_names
                or any(not isinstance(name, str) or not name for name in target_names)
                or target_names != sorted(set(target_names))
            ):
                raise ValueError("target_contexts must be a sorted non-empty unique string array")
            if target_check != {"context": "Crosswake CI", "app_id": 15368}:
                raise ValueError("target_check must bind Crosswake CI to GitHub Actions app 15368")
            if target_names != [target_check["context"]]:
                raise ValueError("target_contexts must exactly project target_check context")
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            errors.append(
                diagnostic(
                    "invalid-required-check-policy",
                    REQUIRED_CHECK_POLICY,
                    None,
                    str(exc),
                    "restore the exact manifest-declared target context policy.",
                )
            )
            target_names = []

    if args.require_display_name:
        matching = [record for record in records if record[0] == args.require_display_name]
        if len(matching) != 1:
            errors.append(
                diagnostic(
                    "producer-count",
                    ".github/workflows",
                    None,
                    f"literal context {args.require_display_name!r} has {len(matching)} producers",
                    "retain exactly one literal producer for the target context.",
                )
            )
        records = matching

    if mode == "--producers" or args.require_display_name:
        selected = records
    elif target_names is not None:
        selected = [record for record in records if record[0] in target_names]
    else:
        selected = [record for record in records if "merge-blocking" in record[0].lower()]

    if mode in {"--emitters", "--producers"} or args.require_display_name:
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
