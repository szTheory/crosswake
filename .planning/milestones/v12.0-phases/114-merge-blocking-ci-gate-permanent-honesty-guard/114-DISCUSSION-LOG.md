# Phase 114: Merge-Blocking CI Gate + Permanent Honesty Guard - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 114-merge-blocking-ci-gate-permanent-honesty-guard
**Areas discussed:** Advisory-lane mechanism, Required-check topology, GUARD-02 prod-absence proof, Workflow file rename

> The user directed that each gray area be researched via parallel subagents
> (pros/cons/tradeoffs, idiomatic Elixir/Phoenix/CI, ecosystem lessons, DX, coherent
> one-shot recommendations). Eight `gsd-advisor-researcher` runs total (4 requirement-level
> + 4 sub-decision) backed the decisions. The user delegated the final calls to the
> research-backed recommendations ("one-shot a perfect set so I don't have to think").
> Findings are consolidated in `114-RESEARCH-SYNTHESIS.md`.

---

## Advisory-lane mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Honor intent, keep D-06 | `::notice` + omit from protection `checks[]`; honest-red on failure; no `continue-on-error`. Amend GATE-01 wording. | ✓ |
| Follow GATE-01 literally | Add `continue-on-error: true` per the requirement text, accepting green-on-failure + D-06 contradiction. | |

**User's choice:** Research-backed recommendation (Option 1).
**Notes:** `continue-on-error: true` resolves a failed job as `success` (counts as pass for required checks + downstream `needs:`), can never be promoted to a real gate, and contradicts the repo's own D-06 (`phase96-proof-advisory.yml`) and the project's honest-proof ethos. Oban/Phoenix/Ecto avoid it for advisory signal. Decision triggers a REQUIREMENTS.md/ROADMAP.md wording amendment + a PITFALLS.md correction. → CONTEXT D-02/D-03.

---

## Required-check topology

| Option | Description | Selected |
|--------|-------------|----------|
| One job, ordered steps | Single job with guards as fail-fast steps; one required check but sequential test+prod compiles, coarse signal. | |
| Three sibling required checks | Separate checks; parallel but three branch-protection strings (rename-deadlock ×3). | |
| Aggregator (Option C) | Three sibling jobs + one aggregator (`re-actors/alls-green`) as the only required check. | ✓ |

**User's choice:** Research-backed recommendation — upgraded to Option C (aggregator), which the topology research surfaced as strictly better than the originally-recommended "one job, ordered steps."
**Notes:** Aggregator name `merge-blocking-offline-sync-e2e` satisfies GATE-01's singular wording; sibling jobs isolate `MIX_ENV=test` vs `MIX_ENV=prod` on separate runners (env-scoped cache keys prevent `_build` cross-contamination); one immutable string in branch protection forever; `alls-green` correctly fails on skipped/failed voting jobs. → CONTEXT D-01.

---

## GUARD-02 prod-absence proof

| Option | Description | Selected |
|--------|-------------|----------|
| Executable + in-suite test | `MIX_ENV=prod mix phx.routes` grep-absent CI job + `router_test.exs` positive assertion + controller scoping test; keep `Mix.env()` gating. | ✓ |
| In-suite test + comment only | Positive route test + documented workflow comment; skip the prod compile step. | |

**User's choice:** Research-backed recommendation (Option 1).
**Notes:** A `:test` run can never observe prod-absence (the suite runs as `:test`); only a separate `MIX_ENV=prod` compile + `mix phx.routes` can — hermetic since route-printing compiles but doesn't boot. Use `! grep -q` not `grep -v`; `rm -rf _build/prod` first. Keep compile-time `Mix.env()` (switching to `compile_env` would add per-env config files for one boolean; this app has a single `config.exs`). No runtime guard — compile-out is strictly stronger and a redundant guard falsely implies the route ships to prod. → CONTEXT D-07/D-08/D-09.

---

## Workflow file rename

| Option | Description | Selected |
|--------|-------------|----------|
| Rename to honest name | `phase90-proof.yml` → `offline-sync-e2e-gate.yml`; stable display `name:` + archaeology comment. | ✓ |
| Keep current filename | Leave `phase90-proof.yml`; only rename the job internally. | |

**User's choice:** Research-backed recommendation (Option 1).
**Notes:** Required-check string is job-name-keyed, not path-keyed → rename is safe. Couple it with the job rename + re-registration already in scope (free). Update ~13 `.planning/*.md` references. Required-*workflows* rulesets ARE path-keyed (noted as a future-migration footgun, not in use). → CONTEXT D-10.

---

## Claude's Discretion

- AST implementation details of `check-e2e-honesty.mjs`; CI step names / `$GITHUB_STEP_SUMMARY` copy; whether the controller test uses an existing case template or a minimal sandboxed-Repo call; Elixir/OTP/Playwright action versions (mirror current workflow); cache-key spelling.

## Deferred Ideas

- Migrating to repository rulesets / required-workflows / merge queue (future; would make the file rename a path-keyed breaking reference — revisit then).
- Retiring old `phase90-proof.yml` run history from the Actions sidebar (cosmetic).
- Generalizing `register-e2e-gate.sh` into a reusable multi-check registration helper for the other `phaseNN` gates.
