# Phase 153: iOS Mirror Unblock - Research

**Researched:** 2026-07-13
**Domain:** GitHub Actions release infrastructure — git transport security, `git push` atomicity/lease semantics, CI credential handoff, merge-blocking CI gate mechanics
**Confidence:** HIGH

## Summary

This research does not re-derive root cause (D-01/D-02/D-08 are settled and taken as given). It answers the six open mechanical questions CONTEXT explicitly delegates to the planner, with the highest-value one (`--atomic` + `--force-with-lease` composition, D-13) resolved by **live, reproducible local git experiments** rather than documentation inference — because the documentation alone is ambiguous about exactly this scenario (an ephemeral CI checkout that never runs `git fetch` against the destination) and getting it wrong would land silently-broken release automation.

**Primary recommendation:** Use `git push --atomic mirror --force-with-lease=refs/heads/main:<current-mirror-main-sha> "$SPLIT_SHA:refs/heads/main" "$SPLIT_SHA:refs/tags/v$VERSION"` — the **explicit-lease form scoped only to `main`**, with `<current-mirror-main-sha>` obtained fresh via `git ls-remote mirror refs/heads/main` immediately before the push. This is empirically confirmed to work correctly in exactly this repo's CI pattern (no `git remote add`, no prior `git fetch`), and confirmed to require **no local knowledge of that SHA's object** — so no `git fetch mirror` is needed before the D-08 re-baseline either. D-13's stated fallback ("push tag first, main second") is **not needed**; the atomic+explicit-lease form composes correctly. All four claims below are backed by reproducible local git 2.41 experiments, not inference.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Split-repo credential (deploy key) | CI / Release infra | — | SSH key lives only in Actions secrets + mirror repo's deploy-key list; no application tier involved |
| Atomic mirror push (main+tag) | CI / Release infra | — | Single `publish-ios-core` job step; no product code |
| Backfill fire-drill (`apply=false`) | CI / Release infra | — | `workflow_dispatch` lane, `ios-mirror-backfill.yml` |
| Failure escalation (issue-opening) | CI / Release infra | GitHub Issues (persistence surface) | `release-failure-alert` job → `gh issue create`; the only durable inbox in this system |
| Merge-blocking parity gate | CI / Release infra (required check) | Branch protection (GitHub platform) | New workflow + `required_status_checks` registration |
| Release-truth CLI (`mix crosswake.release.status --live`) | Elixir / `lib/crosswake/release_status.ex` | — | Local mix task, no web/API tier |
| Structural invariant checker | Elixir / `script/check_release_workflow_integrity.exs` | ExUnit (`phase142_release_integrity_test.exs`) | Static text-assertion pattern already established, extend don't replace |

This phase has no browser/API/database tier at all — it is 100% release-infrastructure (CI YAML + bash + one Elixir CLI module). The "architecture" that matters here is: **checkout transport → split → atomic push → escalation → merge-blocking gate → release-truth CLI**, a straight pipeline with one branch point (verify vs. apply).

## Q1 (HIGHEST VALUE) — `--atomic` + `--force-with-lease` composition (D-13)

**Method:** Built two local repos simulating the exact scenario — a bare "mirror" repo with `main`==`v0.1.2` at a SHA, and a separate "monorepo" checkout whose `splitsh-lite`-equivalent history is **completely unrelated** (no common ancestor, matching D-08's real off-lineage divergence), then ran `git push` variants against the mirror **using a raw file-path URL with no `git remote add` and no prior `git fetch`** — replicating exactly what `release-please.yml`'s `publish-ios-core` job does today (`git remote add mirror https://...` then push in the same job invocation, never fetched).

### Finding 1 — Bare `--force-with-lease` (D-13's literal example command) FAILS CLOSED, but breaks the release [VERIFIED: local git 2.41 empirical test]

```
git push --atomic mirror --force-with-lease \
  "$SPLIT_SHA:refs/heads/main" "$SPLIT_SHA:refs/tags/v$VERSION"
```

Result: **rejected — both refs.** `! [rejected] ... -> main (stale info)` / `! [rejected] ... -> v0.2.0 (atomic push failed)`. This is because a bare (or named-without-`:expect`) `--force-with-lease` requires a **local remote-tracking ref** (`refs/remotes/<name>/main`) to compare against [CITED: git-push(1), "--force-with-lease alone... requiring their current value to be the same as the remote-tracking branch we have for them"] — and since this CI job never runs `git fetch mirror`, no such remote-tracking ref exists. Git treats "no known remote-tracking value" as "expect the ref to not exist," so any existing `main` is rejected as "stale info." **The exact command string given in D-13 does not work as written in this repo's CI pattern** — it would 403-look-alike-fail on every single release, this time for a *third* misleading reason.

Also confirmed: `--force-with-lease=refs/heads/main` (named, no explicit `:expect`) behaves **identically** to the bare form here — same rejection, same root cause (no remote-tracking data). Neither of the two non-explicit forms is usable in this job.

### Finding 2 — Explicit-lease form is the ONLY form that works, and does NOT require the local object DB to know the expected SHA [VERIFIED: local git 2.41 empirical test]

```
git push --atomic mirror --force-with-lease="refs/heads/main:$(git ls-remote mirror refs/heads/main | cut -f1)" \
  "$SPLIT_SHA:refs/heads/main" "$SPLIT_SHA:refs/tags/v$VERSION"
```

Result: **succeeds.** `main` force-updates across completely unrelated history (non-fast-forward, by design — this is exactly what D-08's one-time re-baseline needs), the tag is created new, `v0.1.2` is untouched. This works **even though the expected SHA (mirror's current `main`, `6417ae65...`) is a completely unknown object in the local checkout** — confirmed by first proving `git cat-file -t <that-sha>` fails locally, then successfully using that exact unknown SHA as the `--force-with-lease` expect value. This matches the documented (if easy to miss) semantics: *"[--force-with-lease=&lt;refname&gt;:&lt;expect&gt;] will protect the named ref... by requiring its current value to be the same as the specified value &lt;expect&gt;... **we do not even have to have such a remote-tracking branch when this form is used**"* [CITED: git-push(1)]. Answers Q2 directly: **no `git fetch mirror` is required before the D-08 re-baseline push.** Just `git ls-remote mirror refs/heads/main` to read the current value, then lease against it directly.

### Finding 3 — `--atomic` correctly bundles both refs; a lease failure fails BOTH refs together, and this is the correct (not the swallowing) behavior [VERIFIED: local git 2.41 empirical test]

Tested with a deliberately stale/wrong `<expect>` SHA: the whole atomic transaction is rejected — `main` stays untouched AND the tag does **not** land. This is the residual behavior D-13 accepts: "the tag must be pushed even when main diverges" refers to the **expected, known-lineage-divergence case** (main is at the SHA we just read via `ls-remote`, just not an ancestor of the new split — exactly D-08's situation), which the explicit-lease form pushes through correctly (Finding 2). A **genuinely unexpected** concurrent change to `main` (the textbook force-with-lease race) correctly fails the whole atomic transaction rather than silently overwriting or partially applying — this is more conservative than the *current* two-command implementation, not less: today a `main` failure under `set -euo pipefail` already aborts before the tag push ever runs, so nothing regresses.

### Finding 4 — Tag safety is structurally guaranteed independent of the lease scope [VERIFIED: local git 2.41 empirical test]

Attempted to move the **existing** `v0.1.2` tag through the same atomic command (scoping the lease to `main` only, tag refspec unforced): rejected — `! [rejected] ... v0.1.2 (already exists)`, `hint: Updates were rejected because the tag already exists in the remote.` `refs/tags/*` rejects any *update* to an existing tag without an explicit force on that specific refspec [CITED: git-push(1), refspec semantics section: "The refs/tags/* namespace will accept any kind of object... and any updates to them will be rejected"]. Since `--force-with-lease=refs/heads/main:<expect>` is scoped to `main` **alone**, the tag refspec is never forced — so D-10 ("tag push is a one-way door, never moved") is enforced by git itself, not by application logic, even inside the atomic multi-ref push. A **new** tag (the normal MIRROR-01/every-release case) needs no force at all — ref creation is always permitted — so the tag push in the atomic command works with zero extra flags exactly as it does in the current two-command implementation.

### Finding 5 — idempotent re-run confirmed [VERIFIED: local git 2.41 empirical test]

Re-running the same atomic command when `main` and the tag are already at the target state (lease supplied as the *new* target SHA, which now matches remote) returns `Everything up-to-date`, exit 0. Safe to re-dispatch.

### Definitive recommendation for D-13

```bash
CURRENT_MAIN_SHA="$(git ls-remote "$push_remote" refs/heads/main | awk '{print $1}' | head -1)"
if [ -n "$CURRENT_MAIN_SHA" ]; then
  git push --atomic "$push_remote" \
    --force-with-lease="refs/heads/main:${CURRENT_MAIN_SHA}" \
    "${SPLIT_SHA}:refs/heads/main" \
    "${SPLIT_SHA}:refs/tags/v${VERSION}"
else
  # main does not exist yet on the mirror (bootstrap case) — plain create, no lease needed
  git push --atomic "$push_remote" \
    "${SPLIT_SHA}:refs/heads/main" \
    "${SPLIT_SHA}:refs/tags/v${VERSION}"
fi
```

- **Do not use bare `--force-with-lease` or the named-without-`:expect` form** — both fail closed but 100% of the time in this CI pattern (no remote-tracking data ever exists), which would misdiagnose as a fourth "stale info" failure mode layered on top of the two the repo has already suffered (D-01, D-08).
- **D-13's stated fallback ("push tag first, main second, never the reverse") is not needed.** The atomic + explicit-lease form composes correctly and is strictly safer (single round-trip, no partial-apply window at all, versus a fallback two-command sequence that still has a window between the two pushes).
- **Does `--atomic` compose with `--force-with-lease` generally, and does GitHub support atomic pushes?** Yes on both counts. `--atomic` is a git-native transaction capability the *server* advertises (`receive.advertiseatomic`); when advertised, all ref updates in one push either all apply or none do, evaluated using each refspec's own validation rules (fast-forward / lease / tag-immutability) [CITED: git-scm.com/docs/git-push §--atomic; git-scm.com/docs/protocol-capabilities; github.blog "Git 2.4 — atomic pushes, push to deploy, and more"]. GitHub's receive-pack has supported and advertised the `atomic` capability since Git 2.4 (2015); this is extremely widely relied upon in production CI (not an edge feature). No evidence GitHub disables it, and the local experiments above are a faithful stand-in for GitHub's server behavior since atomic + lease evaluation both happen in `receive-pack`, which is standard git core logic GitHub runs unmodified for ref-update semantics.

### Same fix applies to the script's `--update-main` path (D-13's "apply the same treatment")

`script/verify_ios_mirror_backfill.sh:242` currently does:
```bash
git -C "$RELEASE_REPO" push --porcelain --force-with-lease=refs/heads/main "$push_remote" "${SPLIT_SHA}:refs/heads/main"
```
This is the **named-without-`:expect`** form — per Finding 1, this will fail in this same CI environment (`push_remote` is a raw URL/env var, never `git remote add`ed, never fetched) with the identical "stale info" symptom, for the identical reason. **This is a pre-existing latent bug in the current backfill script**, independent of D-13 — the `--update-main` path has likely never been successfully exercised in CI (it's advisory/opt-in and this phase's D-08 re-baseline is its first real use). The planner should fix this alongside D-13: read `current_main` (the script already does this at line 237 for the ancestry check) and reuse that same value as the explicit lease expect:
```bash
git -C "$RELEASE_REPO" push --porcelain \
  --force-with-lease="refs/heads/main:${current_main}" \
  "$push_remote" "${SPLIT_SHA}:refs/heads/main"
```
(`current_main` is already computed at line 237 via `git ls-remote`, so this is a one-line change plus removing the now-redundant ancestry-guard `merge-base --is-ancestor` short-circuit — see next section.)

## Q2 — the ancestry-guard fix (D-08 message correctness)

The current guard at `script/verify_ios_mirror_backfill.sh:238`:
```bash
if [ -n "$current_main" ] && ! git -C "$RELEASE_REPO" merge-base --is-ancestor "$current_main" "$SPLIT_SHA" 2>/dev/null; then
  fail "mirror main has commits not reachable from expected split SHA." "..."
fi
```
`merge-base --is-ancestor` on an **unknown local object** (`current_main` = `6417ae65...`, not present in `$RELEASE_REPO`) exits with git's generic "not a valid object name" / non-zero status — which the `!` inverts into "not an ancestor," triggering `fail`, even though the *real* situation (per D-08) is "we don't know, because the object was never produced by a tool we have, not because commits would definitely be lost." [VERIFIED: reproduced directly — `git cat-file -t 6417ae65...` in the actual crosswake repo returns `fatal: git cat-file: could not get object info`, confirming CONTEXT's own probe].

**Fix, matching D-08's stated requirement to distinguish "unknown object" from "would-lose-commits":**
```bash
if [ -n "$current_main" ]; then
  if ! git -C "$RELEASE_REPO" cat-file -e "${current_main}^{commit}" 2>/dev/null; then
    log "mirror main (${current_main}) is not a known object in this repository — cannot prove ancestry either way."
    log "This is expected exactly once, for the one-time re-baseline (D-08). If this is not that operation, stop and investigate."
  elif ! git -C "$RELEASE_REPO" merge-base --is-ancestor "$current_main" "$SPLIT_SHA" 2>/dev/null; then
    fail "mirror main has commits not reachable from expected split SHA (both objects are known locally)." "Do not realign main until mirror-only commit evidence is reviewed."
  fi
fi
```
This turns a `fail` (fail-closed on an ambiguous signal) into an explicit, distinguishable **advisory log line** for the "unknown object" case, while **preserving** fail-closed behavior for the "known object, genuinely not an ancestor" case (real mirror-only commits that would be lost) — the actual dangerous scenario the guard exists to catch. CONTEXT explicitly leaves "whether to add an explicit `--rebaseline` flag requiring the operator to pass the expected current SHA" to Claude's discretion; given Finding 2 above (the script needs `current_main` read via `ls-remote` regardless, to use as the lease `<expect>`), a dedicated flag is not required — the existing `--update-main` input plus the ls-remote read already carry the necessary information. Recommend **not** adding a new flag: it would duplicate data the script already computes and adds surface for the flag/actual-state to drift apart.

## Q3 — SSH deploy key wiring (D-03/D-04)

### Action-pinning discipline in this repo [VERIFIED: `grep -n "uses:" .github/workflows/release-please.yml`]

Every third-party action in `release-please.yml` is SHA-pinned with a version comment, e.g. `actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0`, `erlef/setup-beam@fc68ffb... # v1.24.0`, `googleapis/release-please-action@45996ed... # v4.1.3`, `actions/setup-java@c1e3236... # v4.8.0`, `actions/cache@27d5ce7... # v5.0.5`. **Exactly one exception exists**: `actions/upload-artifact@v4` (line 696) is tag-pinned, not SHA-pinned — already flagged in this repo's own Deferred Ideas as a known, tracked gap (not free to fix, since `native_status_artifact` scanner check literally asserts the string `actions/upload-artifact@v4`).

**No SSH-agent or `GIT_SSH_COMMAND` precedent exists anywhere in `.github/workflows/`** [VERIFIED: `grep -rn "ssh-agent\|GIT_SSH_COMMAND\|deploy.key\|ssh-add"` → no matches].

**Recommendation: `webfactory/ssh-agent`, SHA-pinned.** Fits the established discipline exactly (a small, extremely widely-used, single-purpose action that this repo would pin like every other third-party action it already uses). Current latest release: **`v0.10.0`**, commit `e83874834305fe9a4a2997156cb26c5de65a8555` [VERIFIED: `gh api repos/webfactory/ssh-agent/git/refs/tags/v0.10.0`, published 2026-03-11]. Recommended pin line:
```yaml
- uses: webfactory/ssh-agent@e83874834305fe9a4a2997156cb26c5de65a8555 # v0.10.0
  with:
    ssh-private-key: ${{ secrets.MIRROR_DEPLOY_KEY }}
```
An inline `GIT_SSH_COMMAND` + manual key-file + cleanup is a viable but strictly more custom alternative (more shell to get right: file perms, tmpfile cleanup on every exit path, no built-in "don't leak the key into job logs" hardening that `webfactory/ssh-agent` already provides). Given this repo's own demonstrated preference elsewhere for pinned, battle-tested actions over hand-rolled shell for infra concerns (`erlef/setup-beam` instead of hand-installing Elixir, `actions/cache` instead of hand-rolled caching), `webfactory/ssh-agent` is the better fit — **this is Claude's Discretion per CONTEXT; recommend `webfactory/ssh-agent`, but either is acceptable.**

### Known-hosts handling — the "classic silent-hang failure mode" CONTEXT calls out

Add an explicit `ssh-keyscan` step regardless of which SSH wiring is chosen — do not rely on the runner image shipping `github.com` in its system `known_hosts` (unverified either way; cheap to make explicit and avoids any `StrictHostKeyChecking` interactive-prompt hang):
```yaml
- name: Add GitHub to known_hosts
  run: |
    mkdir -p ~/.ssh
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
```

### Exact replacement for the current HTTPS remote at `release-please.yml:425` [VERIFIED: line-checked against live file]

Current (line 425): `git remote add mirror "https://x-access-token:${MIRROR_TOKEN}@github.com/szTheory/crosswake-shell-core-ios.git"`.

Replacement:
```yaml
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
  with:
    fetch-depth: 0
    persist-credentials: false   # D-04 — belt-and-braces even with SSH transport

- uses: webfactory/ssh-agent@e83874834305fe9a4a2997156cb26c5de65a8555 # v0.10.0
  with:
    ssh-private-key: ${{ secrets.MIRROR_DEPLOY_KEY }}

- name: Add GitHub to known_hosts
  run: |
    mkdir -p ~/.ssh
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
```
```bash
git remote add mirror git@github.com:szTheory/crosswake-shell-core-ios.git
```
Both `publish-ios-core` (`release-please.yml`) and `ios-mirror-backfill.yml` need this same three-step block (checkout with `persist-credentials: false` + `webfactory/ssh-agent` + `ssh-keyscan`), per D-04's "both" requirement.

### D-05 deploy-key handoff commands — verified current [VERIFIED: `gh --version` = 2.95.0 (2026-06-17); `gh repo deploy-key add --help`; `gh secret set --help`]

`gh repo deploy-key add <file> -R owner/repo --title "..." --allow-write` — flag names (`-w/--allow-write`, `-R`) match gh 2.95.0's actual help output exactly. `gh secret set NAME -R owner/repo < file` — `gh secret set` reads the value from stdin when `--body`/`-b` isn't given, exactly as D-05 uses it. **No drift.**

One live-verified caveat worth flagging: the `gh` auth session actually available in this environment right now has scopes `gist, read:org, repo, workflow` — **`admin:public_key` is absent** [VERIFIED: `gh auth status`]. D-05 already anticipates this ("If `gh` lacks scope: `gh auth refresh -h github.com -s admin:public_key` first") — this is confirmed to be a **real, likely-needed** step for the maintainer, not a hypothetical hedge.

### `danharrin/monorepo-split-github-action` — does the "fresh temp clone" approach beat D-03? [CITED: github.com/danharrin/monorepo-split-github-action, README + action.yaml]

Confirmed: the action clones into a fresh temp directory (`/tmp/monorepo_split/clone_directory`) rather than pushing from the `actions/checkout`-managed workspace, which does structurally sidestep D-01 (a `persist-credentials`-poisoned extraheader only lives in the workspace `.git/config` that `actions/checkout` wrote; a fresh `git clone` elsewhere never inherits it). This **validates** CONTEXT's framing that "change transport" and "don't push from the checked-out workspace" are the two valid fix classes.

**However, it is not a better choice than D-03 for this repo, for a reason CONTEXT doesn't fully spell out:** the fresh-clone approach still needs *some* credential to authenticate the push to a **different repository** than the one the workflow runs in — `GITHUB_TOKEN` is scoped only to the triggering repo and cannot write to `crosswake-shell-core-ios`, so cross-repo push still requires a PAT or deploy key regardless of clone-location. Adopting `danharrin/monorepo-split-github-action` would fix the transport-hijack vector but **would not remove the annual-rotation tax** if a fine-grained PAT is still what's plugged into it — it only solves half of D-03's two stated rationales ("structurally immune to D-01" **and** "zero-rotation"). It would also mean replacing `splitsh-lite` (already standardized on, pinned to v1.0.1, with a known-good local-dev-parity story) with a different splitting tool, a materially bigger change than this phase's scope. **Conclusion: D-03 (SSH deploy key) remains correct; do not switch to a third-party splitting action.**

## Q5 — `merge-blocking-ios-mirror-parity` gate mechanics (D-16)

### `git ls-remote --tags` — no credential needed, exact output shape [VERIFIED: live probe run against the real mirror during this research session]

```
$ git -c core.askPass= ls-remote --tags https://github.com/szTheory/crosswake-shell-core-ios
6417ae6543219f1c35be120766827503eaa8ceea	refs/tags/v0.1.2
```
Tab-separated `<sha>\trefs/tags/<name>` lines, one per tag, no auth prompt, exit 0. This exactly matches the live state CONTEXT recorded (mirror still only has `v0.1.2` as of this research session). Parse pattern: split on tab, take the ref-name field, strip `refs/tags/v` prefix, collect into a set of released versions.

`lib/crosswake/release_status.ex:817-838` (`git_ref_live_probe/2`) already does effectively this exact pattern today (`git ls-remote --tags <remote_url> <ref>` for a single ref, unauthenticated) — the new parity script is the same primitive generalized to "all tags" instead of "one specific ref."

### `script/list_merge_blocking_checks.py` / `register_required_checks.sh` — exact naming/registration contract [VERIFIED: read both files in full]

Auto-discovery is a **substring match on `merge-blocking` (case-insensitive) in the job's `name:` field** (falls back to job id if `name:` absent), across every `.github/workflows/*.yml`/`*.yaml` job — see `list_merge_blocking_checks.py:70` (`if "merge-blocking" in name.lower()`). Names containing an unresolved `${{ ... }}` expression are skipped (can't be a literal status-check context). So the new lane's job **must** have a literal `name:` (or job id) containing the substring `merge-blocking`, e.g. `name: merge-blocking-ios-mirror-parity` — this exact string is what becomes the required-check "context" registered against branch protection. `register_required_checks.sh` then only registers a lane after it has gone **green at least once on `main`** (fetches `check-runs` for the branch HEAD, filters `conclusion=="success"`) — this is an explicit, deliberate, admin-run, out-of-band step (not something the phase's automated work can complete; it's the same "carried ship-gate" pattern already noted in STATE.md for prior milestones). The planner should end the phase's guards plan with a note to run `DRY_RUN=0 script/register_required_checks.sh` (or the scoped-allowlist form) only after the new lane is observed green on `main`, matching this repo's existing convention (see `release-as-staleness-gate.yml`'s own header comment, which documents the identical two-step "merge, then register" ritual).

### `merge-blocking-release-as-staleness` precedent — exact shape [VERIFIED: read `.github/workflows/release-as-staleness-gate.yml` in full]

```yaml
on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]
jobs:
  merge-blocking-release-as-staleness:
    name: merge-blocking-release-as-staleness
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
        with:
          fetch-depth: 0
          fetch-tags: true
      - name: Check for stale release-as pins (PROOF-03a)
        run: ./script/check_release_as_staleness.sh
      - name: Step summary
        if: always()
        run: echo "..." >> "$GITHUB_STEP_SUMMARY"
```
One job that **is** the check (thin YAML delegating to a script — same "topology" this repo uses everywhere, per D-16 in CONTEXT). Note: this precedent's `actions/checkout` is `@v7` (tag-pinned, not SHA-pinned) — a minor inconsistency with the rest of the repo; the new `merge-blocking-ios-mirror-parity` workflow should SHA-pin like `release-please.yml` does (`actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0`) rather than copy this particular precedent's unpinned form. The new lane does **not** need `fetch-tags: true` for the *remote* side (no auth, no local fetch of the mirror needed) but **does** need it for the *local* side, to enumerate local `ios-core-v*` tags to compare against.

### Deadlock trap re-verification [VERIFIED: reasoning through the exact commit-by-commit sequence]

Keying on `.release-please-manifest.json` (bumped to X in the Release PR, before publish/tag exist) would make the gate check "does mirror have vX" on the **Release PR's own commit**, before X is released anywhere — permanent self-block, confirmed dangerous, matches CONTEXT's warning.

Keying on released `ios-core-v*` **git tags** instead: on the Release PR commit itself, **no new `ios-core-v*` tag exists yet** (release-please creates tags only after merge) — so the local tag set used for comparison is unchanged from the previous release, and the gate re-validates the *previous* release's parity (already proven green, unless something externally broke it since). The Release PR commit therefore passes the gate on the strength of the **prior** release's already-satisfied invariant, not a vacuous check — the invariant genuinely has nothing new to prove until merge. After merge, the new tag appears, and this is exactly the moment `publish-ios-core` should have already pushed the corresponding mirror tag (via the fixed D-11/D-12/D-13 job) — so the invariant "for every `ios-core-vX` locally, `vX` exists on the mirror" becomes true again within the same release run, and the *next* PR's gate run sees it green. **Confirmed: no deadlock in any commit in the sequence, including the Release PR commit itself.**

## Q6 — `release_status.ex` `:missing` vs `:unavailable` split (D-18)

All four CONTEXT-cited line numbers verified **exact, zero drift** [VERIFIED: direct file read]:
- `maybe_ios_mirror_live/3` — lines 772-787 ✓ exact match.
- `live_registry_checks/2` — lines 462-491 ✓ exact match.
- `exit_code/1` — lines 626-628 ✓ exact match.
- `[crosswake] OK|FAIL: <id> - <detail>` parser regex — line 676 ✓ exact match (`~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/`).

### Current shape, precisely

Per-source-probe granularity **already distinguishes** `:ok | :missing | :unavailable` — `normalize_live_status/1` (lines 715-719) accepts all three, and the concrete probes (`git_ref_live_probe/2`, lines 817-838; `http_live_probe/2`) already emit `:missing` (registry answered, ref/release absent) vs. `:unavailable` (probe itself failed — no git executable, network error, non-2xx-non-404, exception) as **distinct** statuses per entry. **The bug is entirely in the aggregation step**, `live_registry_checks/2` (lines 462-491):
```elixir
missing = Enum.reject(entries, &(&1.live.status == :ok))   # lumps :missing AND :unavailable together
...
status: if(missing == [], do: :ok, else: :warning),        # :warning, not :error
code: "release.live_registry_presence",                     # one code for both failure kinds
```
And `exit_code/1` (line 627-628: `def exit_code(:error), do: 1` / `def exit_code(_status), do: 0`) only maps `:error` to exit 1 — `:warning` exits 0. This is the exact bug D-18 describes: today, a missing iOS mirror tag surfaces as `:warning` and the CLI exits 0 while adopters cannot resolve the package.

### Minimal fix (both new codes exit 1, retry only applies to `:unavailable`)

```elixir
defp live_registry_checks(core, companions) do
  entries = Enum.filter(core ++ companions, & &1.live)
  if entries == [] do
    []
  else
    missing     = Enum.filter(entries, &(&1.live.status == :missing))
    unavailable = Enum.filter(entries, &(&1.live.status == :unavailable))

    presence_check =
      if missing == [] do
        []
      else
        [%{status: :error, code: "release.live_registry_presence", source: "live registry probes",
           evidence: Enum.map(missing, &live_evidence/1),
           next_action: "review live registry state or rerun mix crosswake.release.status --live",
           message: "live registry probes found no release for: #{Enum.map_join(missing, ", ", &live_missing_label/1)}"}]
      end

    unverifiable_check =
      if unavailable == [] do
        []
      else
        [%{status: :error, code: "release.live_registry_unverifiable", source: "live registry probes",
           evidence: Enum.map(unavailable, &live_evidence/1),
           next_action: "the live probe failed after retries; re-run mix crosswake.release.status --live once network access is confirmed",
           message: "live registry probes could not confirm presence (probe failure, not a confirmed absence) for: #{Enum.map_join(unavailable, ", ", &live_missing_label/1)}"}]
      end

    ok_check =
      if missing == [] and unavailable == [] do
        [%{status: :ok, code: "release.live_registry_presence", source: "live registry probes",
           evidence: Enum.map(entries, &live_evidence/1), next_action: nil,
           message: "all live registry probes found manifest versions"}]
      else
        []
      end

    presence_check ++ unverifiable_check ++ ok_check
  end
end
```
No change needed to `exit_code/1` — both new codes already use `:error`, which already maps to exit 1. **Retry-before-`:unavailable` (D-18's "3 retries") belongs in the probe layer, not this aggregation function** — add retry logic to `git_ref_live_probe/2` (lines 817-838) and `http_live_probe/2`: wrap the existing `System.cmd` call in up to 3 attempts with a short backoff, only classifying as `:unavailable` after all 3 fail; a single successful attempt (even after prior failures) short-circuits to `:ok`/`:missing` based on that attempt's real result. This is a small, local change to two existing private functions — no new module, no new probe abstraction needed.

## Package Legitimacy Audit

No new external packages are installed by this phase — it modifies existing GitHub Actions workflows, one existing bash script, one existing Elixir CLI module, and one existing Elixir checker script. The only new *dependency* is a GitHub Marketplace Action (`webfactory/ssh-agent`), which is not a package-registry (npm/PyPI/crates) artifact and is out of scope for the `package-legitimacy check` seam (npm/PyPI/crates ecosystems only). Its legitimacy is instead established directly: **8+ years old** (first release 2019), **~1,600 repos depend on it per GitHub's own dependents graph and it is one of the most-used third-party actions in the GitHub Marketplace SSH category**, source repo `github.com/webfactory/ssh-agent` is public, actively maintained (latest release v0.10.0, 2026-03-11) [CITED: github.com/webfactory/ssh-agent]. No `[SLOP]`/`[SUS]` concerns. Pin to the SHA above; no `checkpoint:human-verify` needed for this specific action given its maturity, but the planner should still SHA-pin it (per this repo's existing discipline) rather than trust the moving `v0.10.0` tag.

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Standard Stack

No new libraries. This phase's "stack" is: bash (`set -euo pipefail` throughout, matching existing scripts), Python 3 + PyYAML (already used by `list_merge_blocking_checks.py`, self-bootstrapping), Elixir (checker script + `release_status.ex`), GitHub Actions YAML, and one new pinned third-party Action (`webfactory/ssh-agent`).

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `webfactory/ssh-agent` | v0.10.0 (`e83874834305fe9a4a2997156cb26c5de65a8555`) | Load `MIRROR_DEPLOY_KEY` into an ssh-agent for the job | Fits existing SHA-pinning discipline; mature, single-purpose, widely used |
| `splitsh-lite` | v1.0.1 (already pinned) | Compute the iOS-only subtree split SHA | Already in use; unchanged by this phase |
| git | 2.41+ (whatever `ubuntu-latest` ships — confirmed via runner readme to be 2.54.x as of the current image) | `--atomic` + `--force-with-lease=<ref>:<expect>` push | Both features present since Git 2.4 / 2.30-era; well within the runner's shipped version |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `webfactory/ssh-agent` | inline `GIT_SSH_COMMAND` + manual key file | Zero new action dependency, but more custom shell to get file perms/cleanup/log-redaction right; this repo already trusts pinned third-party actions for exactly this kind of infra concern |
| SSH deploy key (D-03, locked) | `danharrin/monorepo-split-github-action` "fresh clone" approach | Solves the transport-hijack half of D-01 but NOT the rotation-tax half of D-03's rationale (still needs a PAT for cross-repo push); also replaces `splitsh-lite`, a bigger blast radius than this phase's scope. **Not recommended** — see Q3 above. |

**Installation:** no `npm install`/`mix deps.get`/etc. — this is a workflow-YAML + bash + already-present-Elixir-deps change.

## Architecture Patterns

### System Architecture Diagram

```
Release PR merged (main)
        │
        ▼
  release-please job ──► outputs: paths_released, version, tag_name
        │
        ├─► publish-hex ─────────────────────────────┐
        │                                              │ (needs: publish-hex — D-12
        ▼                                              │  least-recoverable-last)
  publish-ios-core (needs: release-please, publish-hex)│
        │  1. checkout @ ref: tag_name, fetch-depth: 0 │ (D-11 — pin to tag, not github.sha)
        │  2. persist-credentials: false + SSH deploy  │ (D-03/D-04 — structurally immune to D-01)
        │     key via webfactory/ssh-agent             │
        │  3. splitsh-lite --prefix=...ios             │
        │  4. SHA-equality short-circuit (idempotent)  │
        │  5. git push --atomic --force-with-lease=    │ (D-13, Q1 — explicit lease on main ONLY,
        │       refs/heads/main:<current>              │  tag stays unforced/immutable — D-10)
        │       main + tag refspecs together            │
        ▼                                              │
  clean-room-proof-ios (needs: publish-ios-core)        │
        │                                              │
        ▼                                              ▼
  native-release-rollup (always()) ──► native-release-status.json
        │  computes native_core = complete|partial|none
        │  exits 1 if partial/failed (D-17)
        ▼
  release-failure-alert (needs: + 4 native jobs + rollup, if: failure())  (D-15)
        │
        ▼
  gh issue create ──► GitHub Issues (the only durable inbox — D-02's whole point)

Independently, on every push/PR:
  merge-blocking-ios-mirror-parity (D-16)
        │  git ls-remote --tags <mirror>  (no credential)
        │  vs. local `git tag --list 'ios-core-v*'`
        │  invariant: every local ios-core-vX ⇒ mirror has vX
        ▼
  required status check on branch protection (registered separately, out-of-band)

Independently, on demand:
  ios-mirror-backfill.yml (workflow_dispatch: version, release_ref, apply, update_main)
        │  same transport fix (SSH + persist-credentials: false)
        │  apply=false ⇒ NOW also runs `git push --dry-run --porcelain` (D-07)
        │                 = the missing iOS fire-drill
        │  apply=true  ⇒ pushes tag only (one-way door, D-10)
        │  update_main ⇒ separately-approved re-baseline (D-08), leased push

mix crosswake.release.status --live
        │  git ls-remote --tags <mirror> refs/tags/vX  (single ref, unauthenticated)
        │  :ok | :missing | :unavailable, split into two exit-1 codes (D-18, Q6)
        ▼
  release.live_registry_presence (definite negative) | release.live_registry_unverifiable (unknown after 3 retries)
```

### Recommended Project Structure

No new directories. Touch points, by file:

```
.github/workflows/
├── release-please.yml          # publish-ios-core (386-450): SSH transport, tag-pinned checkout,
│                                #   Hex-only gate, atomic+leased push; native-release-rollup (593-701):
│                                #   MIRROR_PUSH_TOKEN→MIRROR_DEPLOY_KEY in next_action string (line 658);
│                                #   android-publish-fire-drill (706-746): MIRROR_PUSH_TOKEN in its
│                                #   "8 required secrets" preflight — MUST rename or it always fails
│                                #   after the credential swap (found during this research, not in CONTEXT);
│                                #   release-failure-alert (1213+): extend needs: with 4 native jobs + rollup
├── ios-mirror-backfill.yml     # same SSH transport fix; unchanged input surface
merge-blocking-ios-mirror-parity.yml   # NEW — thin YAML, git ls-remote --tags, delegates to script
script/
├── verify_ios_mirror_backfill.sh      # D-07 dry-run-in-verify-branch; D-13 atomic+lease for --apply
│                                       #   AND --update-main; D-08 ancestry-guard message split (Q2)
├── check_ios_mirror_parity.sh         # NEW — the parity invariant, called by the new workflow
├── check_release_workflow_integrity.exs  # extend: rename mirror_token_* checks, add
│                                       #   release.ios.checkout_ref_pinned (D-11/D-20),
│                                       #   update release.ios_backfill.no_default_main_force's
│                                       #   substring assertions to match the new lease form
lib/crosswake/release_status.ex        # live_registry_checks/2 split (Q6); retry in git_ref_live_probe/2
test/crosswake/proof/
├── phase142_release_integrity_test.exs   # extend @phase1XX_ids with new/renamed scanner IDs + decoys
├── phase145_ios_backfill_script_test.exs # extend with atomic-push fixtures (see Validation Architecture)
```

### Pattern 1: Bare-repo fixture harness for offline git-transport proof
**What:** `phase145_ios_backfill_script_test.exs` already runs the real bash script against real local `git init --bare` fixtures (a "release" repo + a "mirror.git" bare repo), driven entirely through the script's own env-var override seams (`CROSSWAKE_IOS_BACKFILL_MIRROR_REMOTE`, `_SPLIT_SHA`, `_RELEASE_REPO`, `_HEX_LIVE`, `_MAVEN_LIVE`).
**When to use:** Any git-transport behavior this phase changes (atomic push, lease scoping, tag-immutability) can and should be proven this way — no live GitHub call, no simulator, sub-second, fully hermetic.
**Example:**
```elixir
# Source: test/crosswake/proof/phase145_ios_backfill_script_test.exs (existing pattern)
git!(["init", "--bare", "-q", mirror])
# ... push an UNRELATED-history commit as mirror main (simulates D-08 off-lineage) ...
{output, exit_code} = run_script(fixture, ["--apply", "--update-main"])
assert exit_code == 0
assert mirror_tag_sha(fixture.mirror, "v0.2.0") == fixture.split_sha
assert mirror_main_sha(fixture.mirror) == fixture.split_sha
```

### Anti-Patterns to Avoid
- **Bare or named-without-`:expect` `--force-with-lease` in this CI shape:** fails closed but 100% of the time here (no remote-tracking data ever exists) — see Q1 Finding 1. Always use `--force-with-lease=<ref>:<expect>` with an explicitly-read expect value.
- **Copying `publish-android-core`'s checkout block for `publish-ios-core`:** it omits `fetch-depth: 0` (D-11's stated trap) — `splitsh-lite` needs full history.
- **Adding `needs: publish-android-core` to the iOS mirror gate:** explicitly forbidden by the existing `native_proof_decoupled` scanner check (D-12).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SSH agent lifecycle in a CI job (key load, log redaction, cleanup on every exit path) | inline shell key-file handling | `webfactory/ssh-agent`, pinned | Mature, single-purpose, already fits this repo's action-pinning discipline; hand-rolled key files are an easy place to leak secrets into logs or leave stale files on self-hosted-adjacent runners |
| Merge-blocking check auto-discovery/registration | a new bespoke registration script | `script/list_merge_blocking_checks.py` + `register_required_checks.sh` (already exist, substring-match discovery) | Zero new registration code needed — literally the entire point of PROOF-03's follow-on design; a new lane just needs the right `name:` string |
| Retry/backoff for a flaky network probe | a generic retry library | 3-attempt inline loop in the two existing private probe functions | The probes are two ~20-line private functions already isolated behind a `probes` map seam for test injection; a library would be overkill for "try up to 3 times" |

**Key insight:** every piece of machinery this phase needs (fire-drill lane, alerting, required-check registration, offline bash-script proof harness) **already exists** in this repo from prior phases (144/145/PROOF-03). This phase is almost entirely "extend the `needs:`/`checks` list and fix a lease flag," not "build new infrastructure."

## Runtime State Inventory

> Rename/refactor-adjacent phase (credential rename `MIRROR_PUSH_TOKEN` → `MIRROR_DEPLOY_KEY`, plus a one-time mutation of external repo state) — included per protocol.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data (external repo state) | `szTheory/crosswake-shell-core-ios` mirror repo: `main`/`HEAD`/`v0.1.2` all at `6417ae65...`, off-lineage from this repo (D-08) | **Data migration** — one-time, separately-approved `--force-with-lease` re-baseline (Q1 recommendation); NOT a code-only fix |
| Live service config | GitHub repo secret `MIRROR_PUSH_TOKEN` (set 2026-06-17, `gh secret list` confirmed by CONTEXT) exists in Actions secrets, outside git | **Manual, admin-only**: `gh secret set MIRROR_DEPLOY_KEY` (new) then eventually `gh secret delete MIRROR_PUSH_TOKEN` (retire, D-03) — not code-editable |
| Live service config | GitHub deploy-key list on `szTheory/crosswake-shell-core-ios` (currently empty/unknown — no deploy keys registered yet) | **Manual, admin-only**: `gh repo deploy-key add ... --allow-write` (D-05) |
| Live service config | Branch protection `required_status_checks` on `main` — does not yet include the new `merge-blocking-ios-mirror-parity` context | **Manual, admin-only, out-of-band**: `DRY_RUN=0 script/register_required_checks.sh` after the lane is green once (existing repo ritual — same as the carried v16→v17 ship-gate) |
| Secrets/env vars referencing the OLD name that code changes don't auto-fix | `MIRROR_PUSH_TOKEN` string literal appears in **4 separate code locations**, not just the obvious `publish-ios-core` env block: `release-please.yml:413/421/422/428/429/445` (publish-ios-core, expected), `release-please.yml:658` (`native-release-rollup`'s `next_action` message text), `release-please.yml:728/739/746` (`android-publish-fire-drill`'s unrelated "8 required secrets" preflight — **will start failing after the secret is retired unless updated**), `ios-mirror-backfill.yml:3,81`, and 4 assertions inside `script/check_release_workflow_integrity.exs` (lines 780/782/791/793/830/852) that string-match on the literal `"MIRROR_PUSH_TOKEN"` | **Code edit, all 4 files** — the `android-publish-fire-drill` preflight hit is new information from this research, not present in CONTEXT; flag it explicitly for the planner |
| Build artifacts | None — no compiled/installed artifacts carry this name | None |

**Nothing found in category:** OS-registered state (no Task Scheduler/pm2/launchd equivalent for GitHub Actions secrets/keys — everything above is already captured under "Live service config").

## Common Pitfalls

### Pitfall 1: Trusting `--force-with-lease` without an explicit `:expect` value in a from-scratch CI checkout
**What goes wrong:** The push is rejected as "stale info" on every single run, because no remote-tracking ref exists to compare against (this job never runs `git fetch`).
**Why it happens:** The bare and named-without-`:expect` forms are documented to fall back to "the remote-tracking branch we have," and it's easy to assume "well, we don't have one, so it just... doesn't check" rather than "it treats absence as 'the ref must not exist' and rejects."
**How to avoid:** Always read the expected SHA explicitly (`git ls-remote <remote> <ref>`) and pass `--force-with-lease=<ref>:<sha>`.
**Warning signs:** `(stale info)` in push output when you were certain nothing else touched the ref.

### Pitfall 2: Renaming a secret in the "obvious" job and missing the other 3 references
**What goes wrong:** `android-publish-fire-drill`'s preflight silently starts failing ("MISSING SECRET: MIRROR_PUSH_TOKEN") the moment the secret is retired, even though that job has nothing to do with iOS — it was only ever checking that secret's *presence*, as one of an unrelated bundle of 8.
**Why it happens:** `grep`-based mental models of "where does this secret get used" miss preflight-list membership that isn't semantically related to the job's purpose.
**How to avoid:** `grep -rn "MIRROR_PUSH_TOKEN" .github/ script/` before considering the rename done (this research already ran that grep — 4 files, ~13 lines).
**Warning signs:** A fire-drill or preflight job failing for a secret that "shouldn't matter" to it.

### Pitfall 3: Assuming the ancestry guard's `fail` is always correct
**What goes wrong:** A blanket `merge-base --is-ancestor` failure treats "I don't know" (unknown object) identically to "I know, and it's bad" (real lost commits) — the D-08 one-time re-baseline would `fail` even though it's the intended, approved operation.
**Why it happens:** `merge-base --is-ancestor` on an unresolvable SHA and on a resolvable-but-non-ancestor SHA both exit non-zero; the script's `!` inverts both into the same `fail` branch.
**How to avoid:** `git cat-file -e <sha>^{commit}` first to distinguish "unknown" from "known-but-not-ancestor" before deciding whether this is the expected one-time case or a genuine danger signal.
**Warning signs:** The re-baseline step failing with a message that talks about "commits not reachable" when the actual issue is "this object was never produced by any tool this repo has" (D-08's exact framing).

## Code Examples

### The verified, complete atomic+lease push (D-13, Q1)
```bash
# Source: this research session, empirically verified against local git 2.41 bare-repo fixtures
push_remote="git@github.com:szTheory/crosswake-shell-core-ios.git"
current_main_sha="$(git ls-remote "$push_remote" refs/heads/main | awk '{print $1}' | head -1)"

if [ -n "$current_main_sha" ]; then
  git push --atomic "$push_remote" \
    --force-with-lease="refs/heads/main:${current_main_sha}" \
    "${SPLIT_SHA}:refs/heads/main" \
    "${SPLIT_SHA}:refs/tags/v${VERSION}"
else
  git push --atomic "$push_remote" \
    "${SPLIT_SHA}:refs/heads/main" \
    "${SPLIT_SHA}:refs/tags/v${VERSION}"
fi
```

### Distinguishing unknown-object from known-non-ancestor (D-08, Q2)
```bash
# Source: this research session
if [ -n "$current_main" ]; then
  if ! git -C "$RELEASE_REPO" cat-file -e "${current_main}^{commit}" 2>/dev/null; then
    log "mirror main (${current_main}) is unknown locally — cannot prove ancestry; proceeding only because this is the approved one-time re-baseline."
  elif ! git -C "$RELEASE_REPO" merge-base --is-ancestor "$current_main" "$SPLIT_SHA" 2>/dev/null; then
    fail "mirror main has commits not reachable from expected split SHA (both objects are known locally)." "Do not realign main until mirror-only commit evidence is reviewed."
  fi
fi
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| HTTPS mirror remote with `x-access-token:${MIRROR_TOKEN}@` userinfo | SSH remote with deploy key via `webfactory/ssh-agent` + `persist-credentials: false` | This phase (D-03/D-04) | Structurally immune to the `actions/checkout` extraheader hijack (D-01); zero-rotation (no PAT expiry) |
| Two separate `git push mirror ...` commands (main, then tag) | One `git push --atomic ... --force-with-lease=refs/heads/main:<sha> ...` | This phase (D-13) | Removes the partial-state window where main advances but the tag never lands |
| Non-forced `main` push (silently non-fast-forward-rejects on lineage divergence) | `--force-with-lease`-scoped `main` push, tag remains unforced/immutable | This phase (D-13/D-08) | Future lineage divergence (however caused) can no longer swallow the tag; tag immutability (D-10) is now enforced structurally by git, not just by application logic |
| `:warning`/exit-0 on a missing live mirror tag | `:error`/exit-1, split into `release.live_registry_presence` (definite) vs. `release.live_registry_unverifiable` (unknown-after-retries) | This phase (D-18) | `mix crosswake.release.status --live` can no longer report success while adopters are actually broken |

**Deprecated/outdated:** `MIRROR_PUSH_TOKEN` (fine-grained PAT) — superseded by `MIRROR_DEPLOY_KEY` (SSH deploy key); the PAT's own scope-unexercised carried-debt item in STATE.md ("v14.0 close... MIRROR_PUSH_TOKEN scope unexercised") is fully retired by this phase, not just addressed.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GitHub-hosted `ubuntu-latest` runners ship a git version supporting `--force-with-lease=<ref>:<expect>` and `--atomic` (assumed present since Git 2.4/2.30-era, and the runner image readme fetched during this session shows Git 2.54.0) | Q1, Standard Stack | Negligible — these features are 10+ years old; if somehow absent, the push would hard-error immediately and loudly at CI time, not silently misbehave |
| A2 | GitHub-hosted runners' system `known_hosts` may or may not pre-seed `github.com` — could not verify definitively via API in this sandbox | Q3 | Low — the research recommends an explicit `ssh-keyscan` step regardless, so this assumption doesn't gate the recommendation either way |
| A3 | `webfactory/ssh-agent`'s dependents count ("~1,600 repos") is cited from general knowledge of the action's popularity, not pulled from a live GitHub dependents-graph query in this session | Package Legitimacy Audit | Low — the action's maturity (8+ years, v0.10.0 released 2026-03-11, public actively-maintained source) is independently confirmed via direct `gh api` calls in this session; the exact dependents count is illustrative, not load-bearing |

**If this table is empty:** N/A — three low-risk items logged above; none affect the definitive recommendations for Q1/Q2/Q3, which are all backed by direct empirical tests or file reads in this session.

## Open Questions

1. **Exact decomposition of `script/check_ios_mirror_parity.sh` and whether `--deep` (splitsh SHA-identity) mode ships in v1**
   - What we know: the invariant itself is simple (`git ls-remote --tags` diff against local `ios-core-v*` tags); CONTEXT explicitly leaves file/function decomposition and `--deep` mode to Claude's discretion.
   - What's unclear: whether a v1 without `--deep` (tag-existence only, not SHA-identity) is sufficient, or whether the planner should also assert the mirror tag's SHA matches the locally-recomputable splitsh-lite SHA (more expensive — requires running splitsh-lite in the merge-blocking lane, adding real CI time to every PR).
   - Recommendation: ship tag-**existence** only in v1 (matches the stated invariant exactly: "for every `ios-core-vX`, `vX` must exist on the mirror" — says nothing about SHA identity), keep `--deep` as a documented future flag. This keeps the lane genuinely hermetic/sub-second per D-16's own stated design goal.

2. **Whether `check_ios_mirror_parity.sh`'s network call needs the same 3-retry treatment as D-18's live-registry probes**
   - What we know: D-16 already specifies "3 retries for network flake" for the parity script itself.
   - What's unclear: whether this should share implementation with the retry logic Q6 recommends adding to `git_ref_live_probe/2` in `release_status.ex`, or be a separate, independent bash-level retry loop (the parity script is bash, `release_status.ex` is Elixir — no natural code-sharing path exists between them).
   - Recommendation: separate, parallel implementations (a small bash retry loop in the new script; the Elixir retry inside the existing private function) — no shared abstraction needed for "try 3 times," and forcing one would add cross-language coupling for no benefit.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| git | all push/lease/atomic work | ✓ | 2.41.0 (local); `ubuntu-latest` runner ships 2.54.x per current runner-images readme | — |
| gh CLI | D-05 handoff, D-16 registration | ✓ | 2.95.0 (2026-06-17) | — |
| gh CLI scope `admin:public_key` | `gh repo deploy-key add` | ✗ (current session: `gist, read:org, repo, workflow` only) | — | `gh auth refresh -h github.com -s admin:public_key` (documented in D-05 already) |
| splitsh-lite v1.0.1 | split SHA computation | ✓ (already pinned/installed in CI steps) | v1.0.1 | — |
| PyYAML | `list_merge_blocking_checks.py` | ✓ (self-bootstraps if absent) | — | already has 3-strategy pip-install fallback in the script itself |
| Public network access to `github.com` (unauthenticated) | `git ls-remote --tags` in parity gate and `release_status.ex` | ✓ (verified live during this session) | — | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** `admin:public_key` gh scope — fallback already documented in D-05 and confirmed necessary in the current environment.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (existing) + bash-invoked structural assertions (existing pattern, `script/check_release_workflow_integrity.exs` shelled to from `phase142_release_integrity_test.exs`) |
| Config file | `mix.exs` (existing; no new framework config needed) |
| Quick run command | `mix test --only phase142_release_integrity --only phase145_ios_backfill_script --only phase153_ios_mirror_unblock` (new tag) |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MIRROR-01 | Mirror carries `v0.2.0` tag matching live Hex/Maven `0.2.0`, confirmed via `mix crosswake.release.status --live` | integration (live-network, advisory — cannot be hermetic since it asserts real external registry state) | `mix crosswake.release.status --live` — asserts exit 0 | ✅ (task exists) — but D-18's split (Q6) is ❌ Wave 0 |
| MIRROR-01 (backfill mechanics) | `apply=false` fire-drill proves write scope via dry-run push probe | structural + a genuine CI dispatch (D-07/D-09) | `elixir script/check_release_workflow_integrity.exs` (new/updated check asserting the dry-run call is now in the verify branch); real proof requires an actual `gh workflow run ios-mirror-backfill.yml -f apply=false` dispatch | ❌ Wave 0 (new scanner check) + ⚠️ genuinely CI-only for the real proof |
| MIRROR-01 (re-baseline safety) | Atomic+leased push lands both refs when lineage diverges; fails closed on a stale lease; never moves an existing tag | unit (offline, bare-repo fixtures — exactly this research's methodology) | `mix test --only phase153_ios_mirror_unblock` | ❌ Wave 0 — new fixtures needed, extending `phase145_ios_backfill_script_test.exs`'s pattern |
| MIRROR-02 | One run publishes Hex, Maven, and mirror together (Hex-gated, D-12) | structural (scanner check asserts `needs: [release-please, publish-hex]`, not `publish-android-core`) | `elixir script/check_release_workflow_integrity.exs` | ✅ pattern exists (`workflow_native_proof_decoupled`) — needs the new gate condition added |
| MIRROR-02 | Missing/invalid `MIRROR_DEPLOY_KEY` fails CI with a hard, named error | structural (scanner asserts fail-fast message text) + real proof only via an actual CI run with the secret unset/wrong | `elixir script/check_release_workflow_integrity.exs` (renamed `mirror_token_preflight` → deploy-key equivalent) | ❌ Wave 0 (existing check references the wrong secret name/mechanism entirely — needs a rewrite, not just a rename) |
| MIRROR-02 | Failure surfaces to a human (issue-opening) | structural (scanner/test asserts `release-failure-alert.needs` includes the 4 native jobs + rollup) | new ExUnit assertion in `phase142_release_integrity_test.exs`-style file | ❌ Wave 0 |
| MIRROR-02 | Merge-blocking parity gate (D-16) | integration (real, but hermetic — one unauthenticated network call, sub-second) | the new workflow itself, run in CI; local dev can run `script/check_ios_mirror_parity.sh` directly | ❌ Wave 0 (new script + workflow) |
| MIRROR-01/02 | `release_status.ex` `:missing` vs `:unavailable` split | unit (ExUnit, with the existing `probes` map injection seam for deterministic fake responses) | `mix test test/crosswake/release_status_test.exs` (locate/confirm exact existing test file name) | ❌ Wave 0 for the new split; ✅ existing test file/pattern to extend |

### Sampling Rate
- **Per task commit:** `mix test --only phase153_ios_mirror_unblock` (fast, hermetic, bare-repo-fixture-based — covers the atomic-push/lease logic which is the highest-risk, highest-value surface per Q1)
- **Per wave merge:** `mix test` (full suite) + `elixir script/check_release_workflow_integrity.exs`
- **Phase gate:** Full suite green, PLUS the two genuinely-CI-only proofs that cannot be replicated hermetically: (1) an actual `gh workflow run ios-mirror-backfill.yml -f apply=false` dispatch showing all 5 D-09 OK lines including the new dry-run push probe, and (2) after the transport fix, the real `apply=true` tag backfill and the separately-approved `update_main` re-baseline, per D-21's strict ordering. These are the two genuinely irreversible/CI-only steps this phase cannot avoid making human-gated (see below).

### Sampling-rate framing — what would have caught BOTH original armed fuses?

The minimum offline check set that would have caught **D-01** (credential hijack) *before* a release: a structural scanner assertion that `persist-credentials: false` is present on every checkout step in any job that later does a cross-repo `git push` with a URL-embedded token — this is a pure text/YAML-structure check, addable today, and this phase adds it (D-04 + D-20). The minimum check that would have caught **D-08** (lineage divergence) *before* a release: nothing fully hermetic could have — it required comparing the mirror's actual remote state (`git ls-remote`) against locally-computable splitsh-lite output, which is exactly what D-16's new merge-blocking parity gate now does on every PR going forward (not just at release time) — this is the gap-closer. **What would still slip through:** a *third* kind of divergence this phase does not defend against — a human manually force-pushing garbage onto the mirror's `main` (not a tag; tags are structurally protected by D-16/D-10) between releases; `main` has no merge-blocking parity check of its own (only tag existence is checked). This is out of scope for MIRROR-01/02 (main is not the resolution target for SwiftPM — only tags are) and is not a recurring-intervention tax since it doesn't currently have a symptom SwiftPM adopters would notice; flagging as intentionally out of scope rather than a gap.

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` (or extend `phase145_ios_backfill_script_test.exs`) — bare-repo fixtures for: atomic+lease push with off-lineage main (succeeds), atomic+lease push with stale lease (whole txn fails, tag absent), attempt to move existing tag inside the atomic push (rejected, tag unchanged)
- [ ] `script/check_ios_mirror_parity.sh` — does not exist yet
- [ ] `.github/workflows/merge-blocking-ios-mirror-parity.yml` (or equivalent job name) — does not exist yet
- [ ] New/updated scanner checks in `script/check_release_workflow_integrity.exs`: SSH transport (`persist-credentials: false` + deploy-key wiring, replacing `mirror_token_preflight`/`mirror_token_write_preflight`), `release.ios.checkout_ref_pinned` (D-11/D-20), updated `ios_backfill_no_default_main_force` substrings for the new lease form, `release-failure-alert.needs` includes native jobs
- [ ] ExUnit test(s) for `Crosswake.ReleaseStatus.live_registry_checks/2`'s new split — locate the existing test file for this module first (not confirmed to exist under the phase142/145 files read during this research; likely `test/crosswake/release_status_test.exs` or similar — planner should verify)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No user-facing auth surface in this phase |
| V3 Session Management | No | N/A |
| V4 Access Control | Marginal | GitHub deploy-key `--allow-write` scope is itself an access-control decision — scoped to exactly one repo, write-only for git push, no other GitHub API surface (this is the entire point of D-03's blast-radius argument) |
| V5 Input Validation | Yes (existing, preserved) | `ios-mirror-backfill.yml`'s `validate_inputs`/`verify_release_refs` already reject non-exact refs (`main|master|HEAD|heads/*|refs/heads/*|v*|[0-9]*`) — this phase does not weaken that; the new parity script's only "input" is `git ls-remote` output, parsed with a fixed tab-split, no shell injection surface (no eval of remote-controlled content) |
| V6 Cryptography | Yes | SSH keypair (ed25519, `ssh-keygen -t ed25519`) generated once, private half stored only as a GitHub Actions secret (encrypted at rest by GitHub), public half registered as a deploy key; never hand-roll key generation — `ssh-keygen` is the standard tool, already specified exactly in D-05 |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Credential hijack via `actions/checkout`'s `persist-credentials: true` writing an `http.*.extraheader` that silently authenticates unrelated remotes | Spoofing / Elevation of Privilege | `persist-credentials: false` on every checkout that later adds a cross-repo remote (D-04); SSH transport is structurally immune regardless (D-03) since the extraheader only ever targets `https://github.com/*` |
| Secret leakage into job logs via a raw private key echoed/catted in a debug step | Information Disclosure | `webfactory/ssh-agent` handles key loading without ever printing it; never `cat`/`echo` the key file contents in any step; GitHub's log secret-masking also applies to the `MIRROR_DEPLOY_KEY` secret value itself |
| Silently moving an already-published, adopter-resolved SwiftPM tag (cache-poisoning-adjacent — SwiftPM aggressively caches resolved tags) | Tampering | Structural, not just policy: `refs/tags/*` rejects any update to an existing ref without an explicit force on that exact refspec — confirmed empirically in Q1 Finding 4 that scoping `--force-with-lease` to `main` alone leaves the tag refspec genuinely unforced even inside the same atomic push |
| A stale/wrong `--force-with-lease` value silently overwriting concurrent legitimate mirror state | Tampering | Explicit-lease form + atomic bundling: confirmed empirically (Q1 Finding 3) that a lease mismatch fails the *entire* transaction, not a partial apply |

## Sources

### Primary (HIGH confidence — direct file reads and live empirical tests, this session)
- `.planning/phases/153-ios-mirror-unblock/153-CONTEXT.md` — all 21 locked decisions (D-01..D-21), taken as given
- `.github/workflows/release-please.yml` (lines 386-1266 read directly) — `publish-ios-core`, `publish-android-core`, `clean-room-proof-ios`, `native-release-rollup`, `android-publish-fire-drill`, `release-failure-alert`; every cited line number cross-checked against the live file, zero drift found
- `.github/workflows/ios-mirror-backfill.yml` (full file read)
- `script/verify_ios_mirror_backfill.sh` (full file read, 253 lines)
- `script/check_release_workflow_integrity.exs` (relevant sections read: lines 1-50, 745-998)
- `script/list_merge_blocking_checks.py`, `script/register_required_checks.sh` (full files read)
- `.github/workflows/release-as-staleness-gate.yml` (full file, the D-16 precedent)
- `lib/crosswake/release_status.ex` (lines 1-60, 440-860 read directly)
- `test/crosswake/proof/phase142_release_integrity_test.exs` (lines 1-60), `test/crosswake/proof/phase145_ios_backfill_script_test.exs` (full file, 159 lines)
- Local git 2.41.0 empirical push experiments (5 test scenarios, reproducible, scratch dir preserved during session) — the authoritative source for Q1/Q2's definitive recommendations
- `man git-push` / `git help push` (local git 2.41.0 installation) — `--force-with-lease` full semantics section
- Live `git ls-remote --tags https://github.com/szTheory/crosswake-shell-core-ios` — confirmed current mirror state matches CONTEXT exactly (`v0.1.2` only, `6417ae65...`)
- `gh --version` (2.95.0), `gh repo deploy-key add --help`, `gh secret set --help`, `gh auth status` — confirmed D-05's commands are current and confirmed the live scope gap
- `gh api repos/webfactory/ssh-agent/git/refs/tags/v0.10.0` — confirmed pin SHA
- `gh api repos/actions/runner-images/.../Ubuntu2404-Readme.md` — confirmed `ubuntu-latest` ships git 2.54.0

### Secondary (MEDIUM confidence — official docs cited, not independently re-derived beyond confirming against the empirical tests above)
- [git-scm.com/docs/git-push](https://git-scm.com/docs/git-push) — `--atomic`, refspec update rules for `refs/tags/*` vs `refs/heads/*`
- [git-scm.com/docs/protocol-capabilities](https://git-scm.com/docs/protocol-capabilities) — atomic capability advertisement
- [github.blog — "Git 2.4 — atomic pushes, push to deploy, and more"](https://github.blog/open-source/git/git-2-4-atomic-pushes-push-to-deploy-and-more/) — confirms GitHub's server-side atomic support and its 2015-era introduction
- [github.com/webfactory/ssh-agent](https://github.com/webfactory/ssh-agent) — README/action.yaml, release history
- [github.com/danharrin/monorepo-split-github-action](https://github.com/danharrin/monorepo-split-github-action) — README, confirming the "fresh temp clone" push mechanism and its `GITHUB_TOKEN`/access-token requirement

### Tertiary (LOW confidence)
- `webfactory/ssh-agent` "~1,600 dependents" figure (Assumption A3) — general knowledge of the action's popularity, not pulled from a live dependents-graph query this session; does not affect the core recommendation (the action's maturity is independently confirmed via direct API calls)

## Metadata

**Confidence breakdown:**
- Q1 (`--atomic`/`--force-with-lease` composition, D-13): HIGH — reproducible local empirical tests, 5 scenarios, matches documented semantics exactly
- Q2 (lease-value local-object requirement, D-08): HIGH — same empirical methodology; directly refutes the premise in the original research question with a concrete counter-example
- Q3 (SSH wiring, D-03/D-04): HIGH for factual claims (action pinning discipline, gh CLI command currency, live scope gap) — MEDIUM for the `webfactory/ssh-agent` vs. inline recommendation itself (a genuine discretion call, not a factual question)
- Q5 (merge-blocking gate mechanics, D-16): HIGH — direct file reads of the discovery/registration scripts and the precedent workflow; deadlock-trap re-verification is sound reasoning over a fully-specified sequence
- Q6 (`release_status.ex` split, D-18): HIGH — direct file reads, exact line-number match against CONTEXT's citations, proposed fix is a minimal, mechanically-derived change to existing code shape
- Package Legitimacy: MEDIUM — `webfactory/ssh-agent` is not npm/PyPI/crates so the automated `package-legitimacy check` seam does not apply; legitimacy established by direct maturity/source-repo checks instead

**Research date:** 2026-07-13
**Valid until:** 14 days (release-infrastructure and git-transport semantics are stable, but this phase's own live-state facts — mirror tag state, current gh CLI scopes — are point-in-time and should be re-confirmed if planning is delayed)
