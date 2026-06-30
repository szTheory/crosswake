# Phase 135: CI-Ops Hardening — Release-As Automation (PROOF-03) - Context

**Gathered:** 2026-06-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Formalize and CI-prove the **already-landed** PROOF-03 work: the two post-publish
companion-release follow-ups (one-shot `release-as` removal + clean-room-proof confirmation)
are enforced with **no recurring human step**, parametric across every `crosswake_*` companion.
The only intentional human gate that remains is merging the Release PR (the irreversible
`hex.publish` go/no-go).

**Critical framing:** this is a **formalization/proof-capture phase, not a greenfield build.**
The implementation landed on local main 2026-06-26 (commit history under v16.0 WIP). All five
artifacts already exist on disk (verified during discussion):
- `script/check_release_as_staleness.sh` + `.github/workflows/release-as-staleness-gate.yml` (SC1)
- `script/strip_release_as.py` + `release-as-cleanup` job in `.github/workflows/release-please.yml` (SC2)
- `release-failure-alert` wiring in `release-please.yml` (SC3)
- Step 12f in `script/extract_companion.md` points at the automation (SC4)
- `script/register_required_checks.sh` + `script/check_required_checks_registered.sh` + the
  in-phase runbook `135-REQUIRED-CHECKS-REGISTRATION.md` (SC5)

The phase's job is to **audit each artifact against its success criterion, prove it, and fix
only where a SC actually fails** — not to rebuild proven work.

**In scope:** proof artifacts (a hermetic ExUnit proof test + structural YAML assertions),
minimal fixes where an audit finds a SC gap, the verification record. Origin sync and admin
registration are out-of-phase tracked human gates (see Deferred).

**Out of scope:** new CI capabilities, live-fire of GitHub-side effects, the actual
admin/branch-protection registration, the v16.0→origin sync itself.
</domain>

<decisions>
## Implementation Decisions

### Plan Posture (toward already-landed code)
- **D-01: Audit-then-prove.** For each of SC1–SC5, the executor reads the landed artifact,
  writes a proof assertion against its success criterion, and applies a **minimal fix only
  where the assertion fails**. Passing artifacts are recorded as proven with **no code change**.
  Treats landed code as ground-truth-but-verify (the posture that closed Phases 132/133). Reject
  both "proof-capture only" (blind to SC↔behavior drift) and "re-derive from SC" (wasteful).

### Proof Bar (what counts as "proven")
- **D-02: Hermetic core + structural wiring.** Prove the deterministic core hermetically; assert
  the un-hermetic GitHub-side effects structurally (the phase133 doc-presence-assert pattern).
  Per-SC bar:
  - **SC1 (staleness guard):** ExUnit **RED→GREEN** proof — script returns RED (non-zero) against
    a fixture whose `release-as` pin equals an already-released `{component}-v{X}` tag, and GREEN
    (zero) once the pin is removed. Marquee deliverable; must be demonstrated, not asserted.
  - **SC2 (auto-cleanup PR):** unit-prove `script/strip_release_as.py` **idempotency** on a config
    fixture (strips `release-as` + `_TODO_release_as`, minimal diff, re-run is a no-op) **+**
    structurally assert the `release-as-cleanup` job is wired in `release-please.yml`.
  - **SC3 (failure-alert):** structurally assert the `release-failure-alert` job exists with
    `if: failure()` on the publish + clean-room-proof jobs, and is **dormant on the green path**.
  - **SC4 (recipe inheritance):** assert `script/extract_companion.md` Step 12f references the
    automation (not a manual runbook) so sigra/chimeway/threadline inherit 0-human release ops.
  - **SC5 (registration tooling):** prove `register_required_checks.sh` is **idempotent + green-first**
    via dry-run, and `check_required_checks_registered.sh` is a **fail-closed detector** that flags
    a declared `merge-blocking-*` lane missing from branch protection.
  - **Live-fire deferred** (real release firing the cleanup PR + alert; admin registration) — see Deferred.
  Reject "live-fire required" — it would stall the phase on the origin sync and a real companion release.

### Registration Human-Gate Boundary
- **D-03: Tooling-proven in-phase, actual registration deferred.** SC5 **closes on tooling
  correctness**, not on the admin action. In-phase = prove the registrar + detector. Out-of-phase
  (tracked human gate) = `DRY_RUN=0 script/register_required_checks.sh` by an admin **after** v16.0
  lands on origin and each lane has gone green on origin once (per `135-REQUIRED-CHECKS-REGISTRATION.md`).
  This preserves "the only intentional human gate is merging the Release PR" — registration is the
  one legitimate admin action, with the recurring toil and the silent "declared-but-advisory" gap
  removed. Reject "registration in-phase" (couples the phase to the milestone-boundary sync + admin auth).

### Claude's Discretion
- **Proof-test home:** an ExUnit `test/crosswake/proof/phase135_*_test.exs` joining the hermetic
  suite (mirrors `test/crosswake/proof/phase133_telemetry_contract_test.exs`), rather than a
  standalone CI proof workflow (`phase13{0,2}-proof.yml` pattern). Rationale: keeps the proof in the
  hermetic 1109-suite, gives it a single merge-blocking lane, and the assertions are shell/Python
  shell-outs + YAML structural checks that ExUnit handles cleanly. Researcher/planner may confirm.
- **Git-tag fixture mechanism for SC1:** the staleness check depends on `{component}-v{X}` git tags,
  so the RED→GREEN proof needs either a synthetic temp-git-repo fixture or a stubbed tag lookup —
  researcher to determine the cleanest hermetic approach (no network, no real tags).
- The detector (`check_required_checks_registered.sh`) MAY be wired to run periodically (maintainer
  or scheduled job with an admin PAT) so the gap cannot silently reopen — optional, planner's call.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirement & Roadmap
- `.planning/REQUIREMENTS.md` §PROOF-03 (line ~41) — the full requirement text (a/b/c + registration de-toil)
- `.planning/ROADMAP.md` — Phase 135 entry: Goal + 5 numbered Success Criteria (the proof targets)

### Landed Implementation (the artifacts to audit & prove)
- `script/check_release_as_staleness.sh` — SC1 fail-closed staleness guard (parametric over all packages)
- `.github/workflows/release-as-staleness-gate.yml` — SC1 `merge-blocking-release-as-staleness` lane (IS the check)
- `script/strip_release_as.py` — SC2 cleanup script (strips `release-as` + `_TODO_release_as`)
- `.github/workflows/release-please.yml` — SC2 `release-as-cleanup` job + SC3 `release-failure-alert` job
- `script/extract_companion.md` §12f (line ~360) + checklist (line ~411,416) — SC4 recipe inheritance
- `script/register_required_checks.sh` — SC5 parametric idempotent green-first registrar
- `script/check_required_checks_registered.sh` — SC5 fail-closed gap detector
- `.planning/phases/135-ci-ops-hardening-release-as-automation-proof-03/135-REQUIRED-CHECKS-REGISTRATION.md` — the out-of-phase registration runbook (the human gate)

### Proof Patterns (precedent)
- `test/crosswake/proof/phase133_telemetry_contract_test.exs` — ExUnit proof + structural-presence-assert pattern (closest analog)
- `.github/workflows/phase130-proof.yml`, `.github/workflows/phase132-proof.yml` — CI-proof-workflow alternative pattern
- `.github/workflows/contract-drift-gate.yml` — the validate→exit-1 topology the staleness gate is modeled on
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **phase133 proof test** (`test/crosswake/proof/phase133_telemetry_contract_test.exs`): the
  structural-assertion + presence-check pattern to clone for SC2–SC5's structural assertions.
- **All five PROOF-03 scripts/workflows**: already on disk and functioning — the proof targets,
  not things to write from scratch.
- **`135-REQUIRED-CHECKS-REGISTRATION.md`**: complete runbook + the 20-lane trusted-set table;
  the planner references it rather than re-deriving the registration story.

### Established Patterns
- **Merge-blocking lane = the workflow itself** (e.g. `release-as-staleness-gate.yml` job name IS
  the required check), modeled on `contract-drift-gate.yml` (validate → exit 1, no auto-commit).
- **Hermetic-suite discipline:** flaky native/emulator lanes are deliberately kept advisory; only
  hermetic/deterministic lanes are named `merge-blocking-*`. The proof test must stay hermetic.
- **Local-main-ahead-of-origin:** origin is still v15.0 (`d7c5276`); v16.0 lanes don't exist on
  origin yet — this is why registration is deferred to the sync boundary (green-first preflight).

### Integration Points
- New proof test slots into the existing ExUnit hermetic suite (currently ~1109/0 locally).
- Two deferred core-hermetic failures (`milestone_transition_reset`, `phase52_operator_truth`)
  are noted as fixed in Phase 135 per the runbook — the audit should confirm they're green.
</code_context>

<specifics>
## Specific Ideas

- SC1's RED→GREEN must be **demonstrated** (run the script both ways), not merely asserted — it is
  the marquee deliverable and the whole point of "the fix cannot be forgotten."
- Keep `strip_release_as.py`'s cleanup PR **minimal-diff and idempotent** — the proof should pin
  both properties (a second run is a no-op).
- The phase **formalizes/tracks** work that already shipped to local main; the verification record
  should be explicit that code largely pre-exists and the deliverable is the proof + any audit fixes.
</specifics>

<deferred>
## Deferred Ideas

- **v16.0 → origin sync** — the ~100-commit catch-up PR (per the #28/#30 pattern). Prerequisite to
  registration but a milestone-boundary action, not a Phase 135 task.
- **Actual required-check registration** — `DRY_RUN=0 script/register_required_checks.sh` by an
  admin after origin sync + lanes green once. The legitimate human gate; tracked in the runbook.
- **Live-fire of GitHub-side effects** — exercising the real `release-as-cleanup` PR and
  `release-failure-alert` issue against a true companion release. Validated structurally in-phase;
  live confirmation happens organically at the next companion (sigra/chimeway/threadline) release.
- **Periodic detector run** — scheduling `check_required_checks_registered.sh` with an admin PAT so
  the declared-but-advisory gap cannot silently reopen. Optional hardening; planner's discretion.

### Reviewed Todos (not folded)
None — `todo.match-phase 135` returned 0 matches.
</deferred>

---

*Phase: 135-ci-ops-hardening-release-as-automation-proof-03*
*Context gathered: 2026-06-28*
