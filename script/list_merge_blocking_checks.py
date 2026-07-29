#!/usr/bin/env python3
"""List the merge-blocking CI check contexts declared across .github/workflows/*.

A job is a merge-blocking required-check candidate when its display name (`name:`, or the
job id if unnamed) contains the substring "merge-blocking" — the repo's two naming idioms,
`merge-blocking-<x>` (prefix) and `<x> (merge-blocking)` (suffix), both match. The printed
name IS the status-check "context" used by branch-protection required_status_checks.

Shared by register_required_checks.sh (what to register) and
check_required_checks_registered.sh (what should be registered). One source of truth so
adding a new merge-blocking lane needs no new registration code (PROOF-03 follow-on).

Names containing an unresolved `${{ ... }}` expression are skipped (can't be a literal context).

Usage:
  list_merge_blocking_checks.py             -> one context per line (sorted, de-duped)
  list_merge_blocking_checks.py --emitters  -> "<context>\t<workflow path>\t<job id>" per EMITTER,
                                               sorted, NOT de-duped

`--emitters` exists because the default output de-duplicates, which makes a name emitted by two
different jobs structurally invisible here — and branch protection matches required contexts by
STRING, so two jobs sharing a name means a red run can be masked by a green one. The gate fails
open. check_required_checks_registered.sh consumes `--emitters` to assert uniqueness.
"""
import glob
import sys

try:
    import yaml
except ImportError:
    # Self-bootstrap PyYAML. GitHub-hosted runners are inconsistent about whether the
    # `python3` on PATH already has PyYAML, so a hermetic proof lane that shells to this
    # script must not depend on ambient availability. Try a few install strategies
    # (plain, --user, and PEP 668 --break-system-packages) before giving up.
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
            continue

    if yaml is None:
        print("[crosswake] FAIL: PyYAML is required (pip install pyyaml)", file=sys.stderr)
        sys.exit(2)


def main() -> int:
    emitters_mode = "--emitters" in sys.argv[1:]
    contexts = []
    emitters = []
    paths = sorted(glob.glob(".github/workflows/*.yml") + glob.glob(".github/workflows/*.yaml"))
    for path in paths:
        try:
            with open(path) as f:
                doc = yaml.safe_load(f)
        except Exception:
            continue
        if not isinstance(doc, dict):
            continue
        jobs = doc.get("jobs") or {}
        if not isinstance(jobs, dict):
            continue
        for jid, job in jobs.items():
            if not isinstance(job, dict):
                continue
            name = job.get("name") or jid
            if not isinstance(name, str):
                continue
            if "${{" in name:
                continue
            if "merge-blocking" in name.lower():
                contexts.append(name)
                emitters.append((name, path, jid))

    if emitters_mode:
        for name, path, jid in sorted(emitters):
            print(f"{name}\t{path}\t{jid}")
        return 0

    for c in sorted(set(contexts)):
        print(c)
    return 0


if __name__ == "__main__":
    sys.exit(main())
