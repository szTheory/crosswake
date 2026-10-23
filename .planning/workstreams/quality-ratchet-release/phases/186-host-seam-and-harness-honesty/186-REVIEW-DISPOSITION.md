---
phase: 186-host-seam-and-harness-honesty
review: 186-REVIEW.md
critical: 0
warning: 3
info: 4
recorded: 2026-10-16
---

# Phase 186 review disposition

The standard-depth review of `fix(186)` `bd29400722e14bed74c987bf5a9903f486dc6fc2` (over `25614cf6`) found no critical issue. It confirmed that the legacy-route denial grants nothing, that the doctor stale check no longer falls through silently, that `display_location/2` never returns a raw absolute path, that the harness cleanup and hash checks are explicit, and that the physical-iPhone refusal covers all three modes. The reviewer read code and tests; it ran nothing. No finding blocks completion by itself. The open rows below carry forward as advisory debt.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| WR-01 | warning | open (orchestrator checked) | Confirmed by reading `IOSHostOriginMode.observe/2`: an unreadable Info.plist returns `:unreadable`, which is not a signal, and an unreadable or malformed `route_activation.json` returns `:none`; with no local declaration the result is `:none` and the preflight passes. The code follows D-17 exactly ("any result other than `:none` refuses"), so this is a gap in the decision, not a defect of execution. The preflight comment overstates it. Fix candidate: treat `:unreadable` plist as a refusal in the preflight only (a physical run needs a generated shell), with a test. Owner decision; the next change that touches the preflight. |
| WR-02 | warning | open | The `rescue` in `origin_refusal_for/2` reports any crash as local loopback, hiding the real cause; the path has no test. Fails closed. Fix candidate: a distinct cause line for an observation crash, plus a test. |
| WR-03 | warning | fixed by 187-05 (lands in the fix(187) commit; an empty --evidence value and a bare --evidence now both block with LOOP-IOS-EVIDENCE, one JSON object, exit 2) | `--evidence ""` skips the evidence precheck so a run can pass with no evidence file; a bare `--evidence` dies at `shift 2` before the trap (exit 1, no JSON, outside the documented 0/2/3). Manual harness only (not a CI lane). Fix before the Phase 188 Simulator run uses the harness. |
| IN-01 | info | open (Phase 188) | The build-addition allow-list is research assumption A2; it fails closed and Phase 188's real Simulator run confirms or corrects it. |
| IN-02 | info | open (advisory) | The "evidence directory not writable" branch has no test. |
| IN-03 | info | open (advisory) | `..` collapse before link resolution only changes which placeholder is shown; the `remote ` clause passes prefixed strings through. No raw path leak found. |
| IN-04 | info | open (advisory) | `IOSHostGeneration.render/2` calls `File.cwd!/0` on the pure projection path. |
