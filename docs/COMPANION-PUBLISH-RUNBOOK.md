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
