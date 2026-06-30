#!/usr/bin/env python3
"""Assert the structural wiring of a re-actors/alls-green merge-blocking aggregator job.

A `merge-blocking-*` aggregator only actually blocks a PR when THREE structural facts hold
for the aggregator job in its workflow YAML:

  1. `if: always()` — so the job runs even when a needed leaf is skipped/failed. Without it a
     skipped dependency would skip the aggregator, and the required check would never report
     (footgun 1: skipped silently counts as success).
  2. `needs:` contains EVERY expected leaf job — a leaf dropped out of `needs:` no longer feeds
     the rollup, so its failure cannot block the merge.
  3. some step `uses: re-actors/alls-green@...` AND that step's `with.jobs` references
     `toJSON(needs)` — the mechanism that turns a red/skipped leaf into a red aggregator.

A `String.contains?` substring check cannot prove list *membership* or that `if: always()` is on
*this* job (vs. some unrelated job), so true YAML structure is required. This script is the
structural counterpart to the literal-presence checks in the phase134 native-gate proof test, and
is reusable across all three aggregators (native-behavioral-proof, contract-drift, offline-sync-e2e).

Usage:
  assert_aggregator_wiring.py <workflow.yml> <aggregator-job-name> <leaf1> [leaf2 ...]

Exit codes:
  0  wiring verified (all three facts hold)
  1  wiring violation — prints a precise MISSING: line per failed fact
  2  could not evaluate (PyYAML missing, file unreadable, or aggregator job not found).
     exit 2 is distinct from a wiring violation and guards non-vacuity: renaming the aggregator
     makes the asserting test fail rather than pass silently.
"""
import sys

try:
    import yaml
except ImportError:
    print("[crosswake] FAIL (exit 2): PyYAML is required (pip install pyyaml)", file=sys.stderr)
    sys.exit(2)

# PyYAML parses `if: always()` to the scalar string "always()" and
# `if: ${{ always() }}` to "${{ always() }}". Both are valid run-always forms.
_ALWAYS_FORMS = {"always()", "${{ always() }}"}


def _find_job(jobs, target):
    """Return the job dict whose display name (`name:`, else job id) == target, or None."""
    for jid, job in jobs.items():
        if not isinstance(job, dict):
            continue
        name = job.get("name") or jid
        if name == target:
            return job
    return None


def main(argv) -> int:
    if len(argv) < 3:
        print("[crosswake] FAIL (exit 2): usage: assert_aggregator_wiring.py "
              "<workflow.yml> <aggregator-job-name> <leaf1> [leaf2 ...]", file=sys.stderr)
        return 2

    path, aggregator = argv[0], argv[1]
    expected_leaves = argv[2:]

    try:
        with open(path) as f:
            doc = yaml.safe_load(f)
    except Exception as exc:  # unreadable / unparseable
        print(f"[crosswake] FAIL (exit 2): cannot read/parse {path}: {exc}", file=sys.stderr)
        return 2

    jobs = (doc or {}).get("jobs") if isinstance(doc, dict) else None
    if not isinstance(jobs, dict):
        print(f"[crosswake] FAIL (exit 2): no jobs: mapping in {path}", file=sys.stderr)
        return 2

    job = _find_job(jobs, aggregator)
    if job is None:
        print(f"[crosswake] FAIL (exit 2): aggregator job '{aggregator}' not found in {path}",
              file=sys.stderr)
        return 2

    violations = []

    # Fact 1: if: always()
    if_expr = job.get("if")
    if_expr_str = if_expr.strip() if isinstance(if_expr, str) else if_expr
    if if_expr_str not in _ALWAYS_FORMS:
        violations.append(
            f"MISSING: '{aggregator}' must declare `if: always()` "
            f"(found if={if_expr!r}); a skipped dependency would otherwise count as success.")

    # Fact 2: needs: contains every expected leaf (bare-string normalized to list)
    needs = job.get("needs")
    if isinstance(needs, str):
        needs = [needs]
    needs = needs or []
    missing_leaves = [leaf for leaf in expected_leaves if leaf not in needs]
    if missing_leaves:
        violations.append(
            f"MISSING: '{aggregator}' needs: is missing {missing_leaves} "
            f"(needs={needs}); those leaves cannot block the merge.")

    # Fact 3: an alls-green step whose with.jobs references toJSON(needs)
    steps = job.get("steps") or []
    alls_green_ok = False
    for step in steps:
        if not isinstance(step, dict):
            continue
        uses = step.get("uses")
        if isinstance(uses, str) and uses.startswith("re-actors/alls-green@"):
            with_jobs = (step.get("with") or {}).get("jobs")
            if isinstance(with_jobs, str) and "toJSON(needs)" in with_jobs:
                alls_green_ok = True
                break
    if not alls_green_ok:
        violations.append(
            f"MISSING: '{aggregator}' has no step using re-actors/alls-green@... "
            f"with `jobs: ${{{{ toJSON(needs) }}}}` — the rollup mechanism is absent.")

    if violations:
        for v in violations:
            print(f"[crosswake] {v}", file=sys.stderr)
        return 1

    print(f"OK: '{aggregator}' wiring verified in {path} "
          f"(if:always() + needs⊇{expected_leaves} + alls-green/toJSON(needs))")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
