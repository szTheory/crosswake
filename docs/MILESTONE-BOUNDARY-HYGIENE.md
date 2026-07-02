# Milestone-Boundary Hygiene Runbook

A reusable checklist for getting the repo into a clean, coherent state before starting
(or continuing) the next chunk of work — "don't start the next adventure with dirty
underwear on."

Crosswake accumulates work on **local `main`** (protected on origin, needs PRs), so local
`main` routinely runs many commits ahead of `origin/main` and syncs via a single **boundary
PR** at natural boundaries (milestone close, or a mid-milestone checkpoint). Run this pass
whenever local `main` has drifted well ahead of origin, PRs have piled up, or GSD state has
gone stale.

**This runbook does NOT publish to hex.pm.** Publishing is a separate, deliberate step
(merging a release-please Release PR). This pass only lands accumulated work to origin, gets
CI green, and cleans up. It *prepares* for future hex releases.

---

## 0. Snapshot the state (read-only)

```bash
git status -sb                                   # working tree clean? how far ahead of origin?
git rev-list --count origin/main..main           # N commits to land
git worktree list                                # any orphan agent worktrees?
gh pr list --state open --limit 30               # what PRs need triage?
gh run list --branch main --limit 12             # is main CI green?
```

## 1. Clean local git — worktrees

Execute-phase can leave orphan `.claude/worktrees/agent-*` worktrees from crashed/degraded
sessions. Before removing one, **verify its commits are not unique** (they're usually stale
duplicates whose work already landed on `main` under different SHAs):

```bash
git -C <worktree> log --oneline main..HEAD        # what commits does it carry?
git log --oneline main | grep -i "<subject>"      # already on main under another SHA?
```

If the work is already on `main` (or genuinely abandoned), remove it:

```bash
git worktree remove --force <worktree> && git branch -D <its-branch>
git worktree prune
git worktree list        # expect only the main checkout
```

If a worktree holds **unique unmerged work**, stop and surface it — don't prune.

## 2. GSD state coherence

STATE.md lags behind executed work (executors update per-plan; the header/widgets drift).
Refresh it to reflect reality — an honest in-progress state is fine and is *not* "weird."

```bash
# read-only sanity scan for stale markers
grep -nE "Progress: \[.*\] 100%|plan-phase <old-phase>|context gathered" .planning/STATE.md
```

- Fix `stopped_at` / `last_activity_desc` / `progress` and the ASCII phase-checklist +
  percent widgets so completed/in-progress phases are marked correctly.
- Clear stale accumulated-context notes that a later plan already resolved.
- Remove any malformed rows (executors sometimes leak plan-duration metrics into the
  Deferred Items table).
- **Guard against over-claims:** a requirement whose acceptance is "publishes to Hex" is
  NOT complete until the publish runs. Mark such reqs in-progress with a "publish gate
  pending" note (see SIGRA-03 precedent). ROADMAP is usually already correct — verify, don't
  churn it.

## 3. User-facing changelog (`CHANGELOG.md`)

Update the `[Unreleased]` section in the existing honesty-forward framing (the four prose
sub-sections: *Unpublished support claims*, *Verification-required and advisory surfaces*,
*Deferred non-shipped claims*, *Published Hex truth*).

- Note new in-tree work that is **extracted/built but unpublished** under *Deferred
  non-shipped claims*.
- **Do NOT** cut a `[0.x.y]` version heading and **do NOT** bump *Published Hex truth* — no
  hex publish happened.
- **Do NOT** hand-edit `packages/*/CHANGELOG.md` — those are release-please managed.

## 4. Triage open PRs

| PR type | Action |
|---------|--------|
| **Stale planning-doc / abandoned** PRs | Close with a note (superseded). |
| **release-please Release PRs** (root + per-companion) | **Leave open** — they are standing deferred hex-publish gates. release-please auto-reconciles them after the boundary lands. Only merge when you actually intend to publish. |
| **Dependabot** (green/mergeable) | Merge **after** the boundary PR lands (so they rebase onto fresh main). Resolve any `.github/workflows/*` conflicts the boundary introduced. |

## 5. Boundary PR — land local `main` → `origin/main`

Repo precedent (PR #28, #40): a single **`sync/main-*`** branch, **merge commit (no squash)**,
`.planning/` **included** (it's already tracked on origin).

```bash
git switch -c sync/main-<label>-catchup            # e.g. sync/main-v17.0-phase137-catchup
git push -u origin sync/main-<label>-catchup
gh pr create --base main --title "sync: <label> catch-up" --body "<template below>"
```

**PR body template:** Scope ("local main is a clean superset, N commits ahead, 0 divergence")
· Why · Shape (planning-vs-code split) · Tests (suite N/0) · Deferred / admin follow-ups.

**Merge gate:** only **2 checks actually block merge** — `merge-blocking rulestead proof
(hermetic)` and `brand-structural`. Every other lane runs on the PR but is advisory (red
doesn't block). Wait for the two required checks green; a flake in an advisory lane is a note,
not a blocker.

```bash
gh pr merge <n> --merge                            # merge commit, no squash
git switch main && git pull --ff-only              # fast-forward local main
git branch -d sync/main-<label>-catchup
```

Confirm: `git log origin/main..main` is empty (0 ahead/0 behind).

## 6. Admin follow-ups (deliberate human/admin actions — not automated)

These mutate branch protection / secrets and are intentionally out of the automated pass:

- **Provision `BRANCH_PROTECTION_READ_TOKEN`** (Administration:read + Issues:write) so the
  scheduled `required-checks-audit.yml` can run — without it that scheduled lane self-pages a
  red run on `main` (it does **not** gate PRs).
- **Register merge-blocking lanes green-first** (only after they are green once on `main`):
  ```bash
  DRY_RUN=0 script/register_required_checks.sh      # admin gh (repo owner)
  script/check_required_checks_registered.sh        # verify (exit 0 = all registered)
  ```
  Green-first ordering dodges the "Expected — Waiting for status" merge deadlock. See the full
  runbook: `.planning/milestones/v16.0-phases/135-ci-ops-hardening-release-as-automation-proof-03/135-REQUIRED-CHECKS-REGISTRATION.md`.

## 7. Done

- `git status` clean, `git worktree list` = main only, `git log origin/main..main` empty.
- `gh pr list --state open` shows only intentional deferred release-please PRs.
- `main` push run green; STATE.md / CHANGELOG coherent.

---

### Related precedents
- Required-checks registration runbook: `.planning/milestones/v16.0-phases/135-…/135-REQUIRED-CHECKS-REGISTRATION.md`
- Milestone close (heavier): `/gsd-audit-milestone` → `/gsd-complete-milestone` + `vX-CLOSEOUT.md` gate template.
- Companion extraction recipe: `script/extract_companion.md`.
