# Phase 135 Runbook — Register merge-blocking lanes as required checks

**Status:** ready for execution at the v16.0 → origin sync boundary
**Why:** the fail-closed detector (`script/check_required_checks_registered.sh`) found that only **2 of
20** declared `merge-blocking` lanes are actually registered required checks on `main`. The other
**18 are advisory in practice** — they run, can go red, and a PR still merges. This runbook closes
that gap. Registration changes branch protection → **admin/maintainer-only** (the legitimate human
gate); the tooling removes the recurring toil, not the privilege.

## Timing (important)

Registration must happen **after** v16.0 lands on `origin/main` and each lane has gone **green on
origin `main` at least once**, because:
- `origin/main` is still at v15.0 (`d7c5276`); the v16.0 lanes (e.g. `merge-blocking-release-as-staleness`)
  don't exist on origin yet.
- `register_required_checks.sh` reads `origin` check-runs and only registers lanes already green there
  (green-first preflight — avoids the "Expected — Waiting for status" deadlock that freezes open PRs).

So: **sync v16.0 → origin first, let CI go green once, then run this.**

## The trusted set = all 20 (all hermetic)

Every declared `merge-blocking` lane is hermetic/deterministic by the project's deliberate split —
flaky native/emulator lanes (iOS `ios-package-unit`, macOS Xcode) are kept **advisory** and are not
named `merge-blocking`. `merge-blocking-native-behavioral-proof` is the **ubuntu JVM** aggregator
(`./gradlew test`, no emulator). There is therefore **no flaky lane to exclude** — the whole set is
a legitimate hard-gate set.

| Lane | Already required? |
| ---- | ----------------- |
| merge-blocking rulestead proof (hermetic) | ✅ yes |
| merge-blocking rindle proof (hermetic) | register |
| merge-blocking-contract-drift | register |
| merge-blocking-offline-sync-e2e | register |
| merge-blocking-closeout-proof | register |
| merge-blocking-native-behavioral-proof (ubuntu JVM, hermetic) | register |
| merge-blocking-release-as-staleness (Phase 135) | register |
| core hermetic proof (merge-blocking) | register — **the two deferred failures (`milestone_transition_reset`, `phase52_operator_truth`) are now fixed in Phase 135; broad hermetic suite is 1109/0 locally** |
| companion engine-absent proof (merge-blocking) | register once green on origin (the PR failure was a transient deps-fetch flake; `mix companions.test` is 55/0 locally) |
| merge-blocking auth closeout proof (hermetic) | register |
| merge-blocking auth-sensitive admin workflow proof (hermetic) | register |
| merge-blocking commerce support proof (hermetic) | register |
| merge-blocking subscription SaaS proof (hermetic) | register |
| merge-blocking notification workflow proof (hermetic) | register |
| merge-blocking provider adapter proof (hermetic) | register |
| merge-blocking operator proof (hermetic) | register |
| merge-blocking gating doctor and support matrix proof (hermetic) | register |
| merge-blocking Threadline docs-contract proof (hermetic) | register |
| merge-blocking offline draft recovery proof (hermetic) | register |
| merge-blocking phase 75 closeout gate | register |

> `brand-structural` is also currently required and is preserved (the script appends, never removes).

## Commands (run from an admin-authenticated shell, repo root)

```bash
# 1. Preview (DRY-RUN by default) — registers ALL green-on-origin merge-blocking lanes.
#    The preflight auto-SKIPs any not-yet-green (e.g. core-hermetic while its deferred
#    failures are unfixed, release-as-staleness until it has run on origin once).
script/register_required_checks.sh

# 2. Apply.
DRY_RUN=0 script/register_required_checks.sh

# 3. Verify the gap is closed (exit 0 = all declared lanes registered).
script/check_required_checks_registered.sh
```

### Optional phased rollout

If you prefer to enforce the core-discipline gates first and add the domain proofs later, pass an
allowlist (intersected, still green-first):

```bash
DRY_RUN=0 script/register_required_checks.sh \
  "merge-blocking-contract-drift" \
  "merge-blocking-release-as-staleness" \
  "merge-blocking-closeout-proof" \
  "merge-blocking-offline-sync-e2e" \
  "merge-blocking rindle proof (hermetic)" \
  "merge-blocking rulestead proof (hermetic)" \
  "merge-blocking-native-behavioral-proof"
```

Then later re-run the no-arg form to sweep in the remaining hermetic domain proofs.

## After registration

- Re-run `script/check_required_checks_registered.sh` → should report **OK** (0 gaps). Any lane it
  still flags is one that hasn't gone green on origin yet — register it after it passes once.
- The detector can run periodically (a maintainer, or a scheduled job with an admin PAT) so this gap
  cannot silently reopen when future `merge-blocking-*` lanes are added.
