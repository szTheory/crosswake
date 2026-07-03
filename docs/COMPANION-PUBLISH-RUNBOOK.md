# Companion Publish Runbook

**The safety rail for the irreversible, batched companion-family publish.**

This runbook is the human-facing operating procedure for taking the three
extracted companion packages — `crosswake_sigra`, `crosswake_chimeway`,
`crosswake_threadline` — live on hex.pm, one at a time, in a fixed order. Hex is
**irreversible** after a ~60-minute grace window, so the discipline here matters
more than the machinery: the pipeline is already built and verified; the human
just has to drive it in the right order and stop the moment anything looks wrong.

> **Readiness, not execution.** Authoring and verifying this runbook is the
> complete Phase-140 `FAMILY-04` deliverable. The publish itself (merging Release
> PRs, `mix hex.publish` via CI, `register_required_checks.sh DRY_RUN=0`) is a
> **separate human trigger** carried by the `autonomous: false` execution plan
> (140-05), fired outside this phase after origin-sync + 137/138/139
> execution-verification land. Nothing is published by authoring this document.

---

## Pipeline primitives (verified present)

Every CI primitive the publish depends on already exists in-repo and was
confirmed on disk while authoring this runbook (Phase 140 plan 04, Task 1). **No
new CI wiring is required for the publish** (decision D-02). The list below is the
authoritative "what's already wired" reference — locations are current as of this
writing; if a job moves, re-grep the anchor name rather than trusting the line
number.

### The load-bearing invariant

Companions depend on **core only, never on each other.** This is why publish order
among the companions is arbitrary-after-core and why sequencing lives in this
runbook (human discipline) rather than in CI `needs:` edges. There is **no**
`crosswake_chimeway → crosswake_sigra` dependency to encode.

### Per-companion primitives

For each of `sigra`, `chimeway`, `threadline` the following are confirmed present:

**1. `release-please-config.json` component block** — each companion is registered
as an independent release-please component with `separate-pull-requests: true`
(so each gets its OWN Release PR, merged in its OWN workflow run) plus the one-shot
`release-as: "0.1.0"` bootstrap pin and its `_TODO_release_as` reminder note:

| Companion | `release-please-config.json` block | `separate-pull-requests` | `release-as` + `_TODO_release_as` |
|---|---|---|---|
| sigra | `packages/crosswake_sigra` (~L93) | `true` (L96) | `"0.1.0"` (L98) + `_TODO_release_as` (L97) |
| chimeway | `packages/crosswake_chimeway` (~L113) | `true` (L116) | `"0.1.0"` (L118) + `_TODO_release_as` (L117) |
| threadline | `packages/crosswake_threadline` (~L133) | `true` (L136) | `"0.1.0"` (L138) + `_TODO_release_as` (L137) |

**2. Manifest baseline** in `.release-please-manifest.json` — each companion is
pinned at `0.1.0` so the first Release PR cuts `0.1.0`:

- `"packages/crosswake_sigra": "0.1.0"` (L7)
- `"packages/crosswake_chimeway": "0.1.0"` (L8)
- `"packages/crosswake_threadline": "0.1.0"` (L9)

**3. `publish-hex-<name>` job** in `.github/workflows/release-please.yml`, gated on
the PER-COMPONENT `<name>_release_created == 'true'` output (never the aggregate
`releases_created`, which would republish on every core-only release):

| Job | Location | Gate |
|---|---|---|
| `publish-hex-sigra` | ~L350 | `if: needs.release-please.outputs.sigra_release_created == 'true'` (L357) |
| `publish-hex-chimeway` | ~L441 | `if: needs.release-please.outputs.chimeway_release_created == 'true'` (L448) |
| `publish-hex-threadline` | ~L532 | `if: needs.release-please.outputs.threadline_release_created == 'true'` (L539) |

The per-component `*_release_created` outputs are declared on the `release-please`
job (`sigra` L59, `chimeway` L65, `threadline` L74).

**4. Within-run `clean-room-proof-<name>` job** — the post-publish resolvability +
`mix crosswake.doctor` proof, structurally ordered AFTER its publish job via
`needs: [release-please, publish-hex-<name>]`. This `needs:` edge is the ONLY
ordering primitive in CI, and it holds **within a single workflow run**:

| Job | Location | `needs:` |
|---|---|---|
| `clean-room-proof-sigra` | ~L1090 | `[release-please, publish-hex-sigra]` (L1095) |
| `clean-room-proof-chimeway` | ~L1124 | `[release-please, publish-hex-chimeway]` (L1129) |
| `clean-room-proof-threadline` | ~L1162 | `[release-please, publish-hex-threadline]` (L1167) |

**5. `release-failure-alert` coverage** — the `release-failure-alert` job (~L1258)
fires `if: ${{ failure() }}` (L1275) and lists ALL companion publish + clean-room
jobs in its `needs:` (L1264–L1274): `publish-hex-{rulestead,rindle,sigra,chimeway,threadline}`
and `clean-room-proof-{rulestead,rindle,sigra,chimeway,threadline}`. On any
failure it auto-opens a tracking issue (`issues: write`), so the happy path needs
zero human eyeballing and a genuine failure pages a human.

### Why no cross-companion `needs:` edge exists — and must NOT be added (D-02)

GitHub Actions `needs:` **cannot span workflow runs.** Because every companion has
`separate-pull-requests: true`, each companion's Release PR merges in its OWN
workflow run. A hypothetical `publish-hex-chimeway: needs: publish-hex-sigra` edge
would reference a job that does not exist in chimeway's run — GitHub would either
silently skip it (no ordering enforced) or, with an explicit `if: success()`,
deadlock waiting on a job that never runs. So:

- The within-run `clean-room-proof-<name>: needs: publish-hex-<name>` edge is the
  ONLY safe CI ordering primitive — it orders *publish → proof* inside one run.
- Cross-companion sequencing (sigra → chimeway → threadline) is **the human's job
  via this runbook.** It is intentionally NOT encoded in CI.

> **If you are tempted to add a `needs:` edge between companion publish jobs:
> don't.** It cannot work (cross-run) and will silently skip or deadlock. The
> sequencing lives here, in operator discipline.

### Readiness status

All primitives above are **present and verified.** No BLOCKER. The pipeline is
ready for the human-triggered batched publish once the preconditions below are met.

---

## Preconditions (do NOT start until all are true)

Per decision D-01 (USER-LOCKED), the batched publish is deferred behind a small
set of preconditions. **Deferred ≠ indefinite** — the family should go live once
these clear; there is no reason to hold it back further.

1. **Origin-sync has landed.** Local `main` has been pushed to `origin/main` and CI
   is green on origin. Crosswake accumulates work on protected local `main` and
   syncs via a single boundary PR — run the
   [Milestone-Boundary Hygiene Runbook](./MILESTONE-BOUNDARY-HYGIENE.md) FIRST.
   That runbook explicitly does **not** publish to hex; it only lands accumulated
   work and gets CI green. This publish runbook is what fires afterward.
2. **Phases 137 / 138 / 139 are execution-verified.** The sigra, chimeway, and
   threadline extractions have each been executed and verified green in-tree.
3. **You have hex.pm publish rights** for the `crosswake_*` packages and a shell
   with `gh` authenticated at repo-admin scope (needed only for the ship-gate
   registration step, not for the publish itself).

If any precondition is false, STOP — the publish is not yet ready.

---

## Per-companion publish loop (D-03)

Run this loop for **exactly ONE companion at a time**, in the fixed order:

> **sigra → chimeway → threadline**

Threadline (the pure observer) is published LAST as belt-and-suspenders: by the
time it goes live, sigra and chimeway are already proven on hex, so if the
observer's telemetry-by-name wiring were ever going to surface a surprise, it does
so against a known-good baseline.

**Never batch. Never merge two Release PRs at once.** Complete all five steps for
one companion before touching the next.

For companion `<name>` (in order `sigra`, then `chimeway`, then `threadline`):

1. **Merge exactly ONE Release PR** — the release-please PR for `crosswake_<name>`
   (title contains `crosswake_<name>`). One at a time. Do not merge the next
   companion's Release PR yet.
2. **Wait for green on `main`.** After the merge, the
   `publish-hex-<name>` job runs (`mix hex.publish`), then — gated within the same
   run by `needs: [release-please, publish-hex-<name>]` — the
   `clean-room-proof-<name>` job builds a throwaway host, resolves the freshly
   published package from hex, and runs `mix crosswake.doctor`. **Both must be
   GREEN** before proceeding.
3. **Confirm the docs actually published.** Open
   `https://hexdocs.pm/crosswake_<name>/0.1.0` and confirm it resolves (hexdocs
   lags hex.pm by a short interval; give it a minute). If it never resolves, treat
   it as a failure — investigate before continuing.
4. **Merge the auto-opened `release-as-cleanup` PR.** The `release-as-cleanup` job
   (`release-please.yml` ~L1202, PROOF-03b) auto-opens a one-line PR stripping the
   now-stale one-shot `release-as: "0.1.0"` pin (and its `_TODO_release_as` note)
   for the released component — left in place, every subsequent run would
   re-target `0.1.0` forever (Pitfall 6). The `merge-blocking-release-as-staleness`
   gate (`.github/workflows/release-as-staleness-gate.yml`) stays **RED** until
   this PR merges, so it cannot be silently skipped. Merge it once its CI is green.
5. **ONLY THEN proceed to the next companion.** Return to step 1 for the next name
   in the order.

### Hex is irreversible — the ~60-minute revert window

Once `mix hex.publish` completes, the package version is **permanent.** There is a
~60-minute grace window in which a mistaken publish can be corrected with
`mix hex.retire crosswake_<name> 0.1.0 --message "..."` (retire, not delete — the
version stays but is marked unusable). After that window, `0.1.0` is frozen forever
and the only path forward is a NEW version.

- **Do NOT retry a failed publish by re-pushing.** First check whether the version
  already made it to hex.pm. If it did, re-pushing will fail (version exists) and
  you must go through `mix hex.retire` + a new version — never assume a failed job
  means "nothing published."
- **If `release-failure-alert` fires** (it auto-opens a tracking issue on any
  publish/clean-room failure — see `release-please.yml` ~L1258, `if: failure()`),
  **STOP.** Investigate the failed job named in the issue BEFORE touching the next
  companion. Do not advance the order while a failure is open.

---

## Ship-gate ordering — `register_required_checks.sh` (D-04)

Registering merge-blocking lanes as required status checks is a **separate,
admin-only** action from the publish. It runs **green-first, AFTER new lanes have
gone green on `main` at least once — never before.**

Order:

1. **Land Phase 140** (and any change that introduces a NEW `merge-blocking-*`
   lane) onto `main`.
2. **Let each new `merge-blocking-*` lane run GREEN on `main` at least once.** The
   script's paginated green-first preflight (`register_required_checks.sh` L73–L88)
   SKIPS any lane with no green run on branch HEAD — registering a never-green
   check freezes every open PR at "Expected — Waiting for status."
3. **Preview:** `DRY_RUN=1 script/register_required_checks.sh` (default; prints the
   desired `required_status_checks`, writes nothing).
4. **Apply:** `DRY_RUN=0 script/register_required_checks.sh` (PATCHes the granular
   `required_status_checks` endpoint — appends, `unique_by(.context)`, idempotent;
   leaves `enforce_admins` and review requirements untouched).
5. **Confirm:** let the daily `required-checks-audit.yml` verify the registration.

### Hard rule — never register the publish/proof jobs

The companion `publish-hex-*` and `clean-room-proof-*` jobs are **POST-MERGE** jobs:
they run only after a Release PR merges and are SKIPPED on normal PRs (their
`if: <name>_release_created == 'true'` gate is false on non-release PRs). Requiring
a check that is skipped on normal PRs creates a **permanent PR deadlock** — every
open PR waits forever for a status that will never report.

> **MUST NOT** register `publish-hex-*` or `clean-room-proof-*` as required checks.
> They are post-merge publish jobs, not PR gates. The green-first preflight will
> also refuse to register them (they never run green on a normal PR HEAD), but do
> not rely on that — never pass them as allowlist args.

---

## Why this is deferred, and what counts as "done" for Phase 140

Per D-01 (USER-LOCKED), **authoring and verifying this runbook IS the complete
Phase-140 `FAMILY-04` deliverable** (the "readiness" half). The actual EXECUTION —
merging Release PRs, the hex publishes, and `register_required_checks.sh DRY_RUN=0`
registration — is carried by the **`autonomous: false` execution plan (140-05)**,
fired **separately by the human** outside this phase once the preconditions above
are met.

So for Phase 140: **readiness delivered, execution deferred by design.** Downstream
`execute-phase` and the plan checker should treat this readiness runbook as the
satisfied deliverable; they must NOT expect a hex publish or a required-check
registration to have happened inside Phase 140.
