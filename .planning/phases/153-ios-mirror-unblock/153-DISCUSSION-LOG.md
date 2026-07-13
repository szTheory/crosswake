# Phase 153: iOS Mirror Unblock - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-12
**Phase:** 153-ios-mirror-unblock
**Areas discussed:** Token & human handoff, Backfill push shape, "Hard, named failure" surface, Release-job correctness

**Method:** User requested research-backed, one-shot coherent recommendations rather than sequential Q&A. Four `gsd-advisor-researcher` agents ran in parallel (one per gray area), each grounded in `prompts/crosswake-elixir-oss-dna.md` and briefed with verified live state. Findings were reconciled by the orchestrator — including one direct contradiction between agents (see below) — then presented as a single recommendation set with two confirmation questions.

---

## Root cause (emerged during research; not a pre-identified gray area)

Agents A and D **contradicted each other** on why the 2026-07-03 push 403'd.

| Position | Claim | Verdict |
|----------|-------|---------|
| Agent D (F3) | The `x-access-token:${MIRROR_TOKEN}@` URL userinfo authenticates the push; `permissions: contents: read` is correct and the token was genuinely used. | ✗ Wrong |
| Agent A | `actions/checkout`'s default `persist-credentials: true` writes an `http.https://github.com/.extraheader` Authorization header into `.git/config` that matches *every* `https://github.com/*` remote and **overrides** URL userinfo — so the push ran as `github-actions[bot]`. | ✓ Correct |

**Resolved in favor of Agent A by forensic elimination**, not by preference:
1. The job's own `if [ -z "${MIRROR_TOKEN:-}" ]` guard did not fire → the secret **was** set and non-empty (corroborated: `gh secret list` shows it created 2026-06-17).
2. The 403 nonetheless named **`github-actions[bot]`**, not `szTheory` — a PAT that was actually used would produce a denial naming its owner.
3. ⇒ The token in the URL was never used. Independently verified: `grep -rn persist-credentials .github/workflows/` returns **no matches**.

**Impact:** this invalidates the prevailing theory in SEED-003, in `.planning/research/v20/RELEASE-STRATEGY.md` §3, and in the MIRROR requirement framing — all of which say "rotate the PAT." Doing only that would 403 again. Captured as **D-01** and flagged as superseding those documents.

---

## Token & human handoff

| Option | Description | Selected |
|--------|-------------|----------|
| SSH deploy key | New `MIRROR_DEPLOY_KEY` + `persist-credentials: false`. Never expires; immune to the extraheader bug by construction; blast radius = one regenerable mirror repo; 4-command handoff, no browser. | ✓ |
| Keep PAT, fix `persist-credentials` only | Minimal diff. But scope never exercised, and a fine-grained PAT expires (366-day max) **silently, mid-release** — recurring intervention forever. | |
| GitHub App installation token | No key expiry, clean bot identity, org-ready. But needs app registration + install + 2 secrets, and is still HTTPS so it *also* needs the `persist-credentials` fix. | |

**User's choice:** SSH deploy key (recommended option).
**Notes:** Decisive factor was the intersection of two properties no other option has together — structural immunity to the actual root cause (different transport), and zero rotation. The PAT's annual re-mint was judged a recurring-intervention tax against the project's stated zero-intervention goal, and a guaranteed future repeat of this same incident. GitHub App explicitly noted as the correct *later* upgrade if a bot identity is ever needed beyond this one push.

**Also surfaced (deferred):** `RELEASE_PLEASE_TOKEN` falls back to `|| github.token` — a silent-degradation path against the no-silent-fallback rule. GPG signing-key expiry is unmonitored and is the true Android analogue of this risk.

---

## Backfill push shape

| Option | Description | Selected |
|--------|-------------|----------|
| CI dispatch, tag + main (`apply=true update_main=true`) | Unblocks SwiftPM; `merge-base --is-ancestor` *proves* the mirror-main lineage the release job silently assumes; fixes the stale README shopfront; main is `--force-with-lease` (reversible). | ✓ |
| CI dispatch, tag only | Smallest irreversible surface, but leaves the lineage assumption unproven and the mirror's landing page at 0.1.2. | |
| Local `script/... --apply` | Fast, but proves only that *the laptop's* credential works — leaves the CI push path (the thing that actually failed) still unexercised. | |
| Do nothing | Rejected — 0.2.0 is live on Hex + Maven with no resolvable SwiftPM tag. | |

**User's choice:** Folded into the accepted recommendation set.
**Notes:** Venue was decisive: the failure being repaired is literally *"CI did not push the tag,"* so a laptop push would fix the symptom while leaving the CI credential unexercised until the next real release. Live probe confirmed the mirror is clean — `main`, `HEAD`, and `v0.1.2` are all one SHA (`6417ae65`), zero mirror-only commits — so `--update-main` adds a free lineage proof at no extra blast radius. The tag is a one-way door (forward-only remedy via `v0.2.1`); `main` is reversible.

**Residual footgun recorded:** the script's `--update-main` path pushes the tag *before* checking ancestry, so a lineage failure lands in the tag-only state (not corruption, but the irreversible half precedes the gated half).

---

## "Hard, named failure" surface

| Option | Description | Selected |
|--------|-------------|----------|
| Core guards + merge-blocking parity gate | All release-job fixes, plus `merge-blocking-ios-mirror-parity` (one `ls-remote`, keyed on released `ios-core-v*` tags). Red lands on the merge button. | ✓ |
| Core guards only | Satisfies MIRROR-02 literally; leaves drift from force-push/tag-deletion/half-finished-backfill undetected until the next release. | |
| Core + parity gate + weekly cron reconcile | Adds a scheduled deep reconciler. Rejected: GitHub auto-disables scheduled workflows after 60 days of inactivity, so a cron **fails open** — a *new* silent-failure surface, i.e. the exact bug being fixed. | |

**User's choice:** Core guards + parity gate (recommended option).
**Notes:** The framing insight that drove this — and that reframed the whole requirement — is that **`publish-ios-core` already hard-fails with `exit 1`**, so the 2026-07-03 run *was* red and still went unnoticed for ~3 months. "Make it louder" is therefore a non-fix. The variable is not redness but **where red lands**: a post-merge Actions run has neither persistence nor an inbox. Hence red was relocated onto two surfaces the maintainer cannot route around — the merge button (parity gate) and the issues list + email (`release-failure-alert`, which already exists and merely omits the native jobs from its `needs:`).

**Deadlock trap recorded:** the parity gate must key on released tags, never on `.release-please-manifest.json` — the manifest bumps *before* the tag exists, so keying on it would make the release PR block itself permanently.

**Also decided:** `mix crosswake.release.status --live` currently exits 0 on a stale mirror. Judged a support-truth lie in the project's own voice; promoted to `:error`, with `:missing` (definite negative) split from `:unavailable` (unknown) so the message never misreports which failure occurred.

---

## Release-job correctness

| Finding | Severity | In scope? |
|---------|----------|-----------|
| Split runs from `github.sha`, not the release tag — diverges on release-please's retroactive `autorelease: pending` path, publishing **wrong content under a correct-looking tag** | High | ✓ Yes (D-11) |
| Mirror not gated on Hex — least-recoverable registry races the most-recoverable one | Medium | ✓ Yes (D-12) |
| Mirror push is **not atomic** — `main` and tag are two commands, so a tag failure leaves main advanced with no tag | High | ✓ Yes (D-13) |
| `native-release-rollup` computes `native_core=partial` and then **exits 0** | High | ✓ Yes (D-17) |
| `release-failure-alert.needs` omits all native jobs — the surface that broke is the only one with no alerting | Med-High | ✓ Yes (D-15) |
| `permissions: contents: read` | **Not a bug** | ✗ No change — recorded so it isn't "fixed" |
| `actions/upload-artifact@v4` unpinned | Low | ✗ Deferred (checker asserts the literal string) |

**User's choice:** All in-scope fixes accepted as part of the recommendation set.
**Notes:** Agent D's initially-stated mechanism for the checkout bug ("main advances between merge and job start") was **wrong** — `actions/checkout` pins to `github.sha`, so there is no race on the happy path. The agent self-corrected: the real divergence path is release-please's retroactive release behavior, which this repo **has already been on**. Corroborating evidence that tag-pinning is the right discipline: `verify_ios_mirror_backfill.sh` *already* rejects `main`/`HEAD` and demands an exact `refs/tags/ios-core-vX` ref — the backfill script encodes the discipline the release job violates.

**Constraint discovered in the integrity checker:** `native_proof_decoupled` **deliberately** requires the iOS lane not to depend on Android, so the Hex gate must be `needs: [release-please, publish-hex]` **only**. Without reading the checker this would have been "fixed" wrongly.

---

## Claude's Discretion

- File/function decomposition of `script/check_ios_mirror_parity.sh`; whether `--deep` (splitsh SHA-identity) lands in v1.
- SSH wiring via pinned `webfactory/ssh-agent` vs inline `GIT_SSH_COMMAND` — planner picks per the repo's action-pinning discipline.
- Plan count and split (transport+backfill vs durable guards are the natural boundary).

## Deferred Ideas

- Credential-expiry preflight lane (weekly cron) for remaining PATs — worth a seed.
- `RELEASE_PLEASE_TOKEN`'s `|| github.token` silent fallback — worth a seed.
- Unmonitored GPG signing-key expiry (the true Android analogue of this incident) — worth a seed.
- SHA-pin `actions/upload-artifact@v4` (requires a lockstep checker edit).
- Weekly cron reconciliation lane (k8s publishing-bot pattern) — rejected as fail-open.
- Standalone `ios-mirror-fire-drill` job — unnecessary; the `apply=false` dispatch serves this once it gains the dry-run probe.
- Mark the mirror repo `[READ ONLY]` with Issues disabled (Symfony/Laravel convention). **Never archive** — that would brick the release job's push.
