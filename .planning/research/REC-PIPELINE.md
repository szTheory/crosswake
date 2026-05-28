# Recommendation: Release Pipeline (v3.3 Category D)

_Research date: 2026-05-27. Based on survey of 9 Elixir OSS libs, oarlock canonical templates, sigra live pipeline, release-please v4/v5 docs, CVE-2025-30066 postmortem, hex.pm publish docs, and Crosswake project identity files._

---

## TL;DR

Put all four items IN scope for v3.3. release-please with the oarlock-canonical workflow (not sigra's postgres variant) is the right automation backbone for a hermetic Elixir-only library. The manual recovery workflow is not dead weight — it is the escape hatch the "recovery-conscious publishing" principle requires, and the oarlock paved path already has it. SHA-pin all actions in every new workflow file: CVE-2025-30066 (tj-actions, March 2025) showed that tag-referenced actions can be backdoored silently, and Crosswake's project identity demands "release truth matters" all the way down to the CI supply chain.

---

## Decisions Recommended

### 1. release-please config + manifest: IN

**Rationale:** Crosswake has a non-conventional commit history (planning commits, phase commits, chore/docs/feat/fix prefix mix with GSD tooling). Without release-please config + manifest in place now, the first publish will require a manual `mix hex.publish` that bypasses all automation — and then release automation never gets bootstrapped because the "first release" already happened outside the system. The manifest `0.0.0` baseline + one-time `release-as: "0.1.0"` pin is exactly the gotcha-catalog prescribes for this situation (gotcha #4 + #5 from the bootstrap-elixir-hex-lib skill). Ship these two files in v3.3 or you'll fight them again every future release.

Config note: use `bump-minor-pre-major: false` (oarlock/lattice_stripe pattern) not `true` (sigra pattern). Crosswake at `0.x` should treat breaking changes as `0.x+1`, not `0.(x+1)`. The project is explicitly not calling itself stable yet; minor bumps from breaking changes inside 0.x are fine and avoid the "first `feat:` jumps to 0.2.0" surprise that confused oarlock users.

### 2. release-please.yml workflow (Release-PR job, oarlock template): IN

**Rationale:** The oarlock template is already the paved path. It has the six oarlock gotchas pre-fixed, runs on ubuntu-latest (Crosswake is a pure Elixir library with no Postgres deps — unlike sigra's postgres-service variant), produces the correct `release_created` output (v4 naming, not v5's `releases_created` plural for non-root), and has SHA-pinned all three core actions. The only substitution needed is the Hex verify step URL (`oarlock` → `crosswake`). The workflow correctly separates the release-please job (PR+tag creation) from the publish-hex job (runs only on `release_created == 'true'`), which is the right hermetic split: release orchestration is advisory-style (non-blocking, advisory) until the merge happens, then publish is deterministic from the tagged commit.

### 3. hex-publish.yml manual-recovery workflow: IN

**Rationale:** Justified in full in the "Manual-recovery workflow value-add analysis" section below. The oarlock template already exists at `~/projects/oarlock/.github/workflows/hex-publish.yml`. For Crosswake, copy it verbatim minus the Hex verify URL substitution. This is not gold-plating — it is the recovery escape hatch that makes the "release truth matters" claim honest. A publish pipeline with no manual recovery path is a publish pipeline that will require a git history rewrite the first time automation misfires.

### 4. SHA-pin all GitHub Actions: IN

**Rationale:** CVE-2025-30066 is a concrete, catalogued, CISA-tracked incident from March 2025. Every new workflow file in v3.3 should use `@<full-commit-SHA> # v<tag>` syntax for all third-party actions. The maintenance cost is bounded by a single `dependabot.yml` entry. The oarlock templates already do this correctly. Crosswake's existing phase-proof workflows (phase5, phase10, phase18, phase23) do NOT SHA-pin — those are pre-existing and not in v3.3 scope to retroactively fix, but every new file shipped in v3.3 should set the standard. Document this as the v3.3+ default, same as hermetic-vs-advisory became a graduated default at v3.2.

---

## Survey: How Successful Elixir OSS Libs Ship to Hex

Research method: checked `.github/workflows/` contents via GitHub API and raw file fetch for 9 libraries. "Publish workflow" = any workflow that calls `mix hex.publish`. "SHA-pinned" = all external actions use `@<SHA>` syntax.

| Lib | Release tool | Publish trigger | Dedicated publish workflow | SHA-pinned | Manual recovery workflow |
|---|---|---|---|---|---|
| **Phoenix** | None found | Manual (no workflow) | No | No | No |
| **Ecto** | None found | Manual (no workflow) | No | No | No |
| **Oban** | None found | Manual (no workflow) | No | No | No |
| **LiveView (phoenix_live_view)** | Tag-push (`v*`) | `github_release.yml` creates GH release only; no hex publish step | No | No (uses `@v4`) | No |
| **Bandit** | Tag-push | `hex_publish.yml`, triggers on semver tag match (`[0-9]+.[0-9]+.[0-9]+`) | Yes (tag-driven) | No (uses `@v6`, `@v1`) | No |
| **Ash** | Tag-push (`refs/tags/v`) | `ash-ci.yml` has `hex_publish` + `github_release` jobs gated on tag ref | Yes (tag-driven, inline) | **Yes** — SHA-pins all three: `actions/checkout@de0fac2e...`, `softprops/action-gh-release@b4309332...`, etc. | No |
| **Livebook** | Tag-push + nightly | `release.yml` — no hex publish (app binary, not a library) | N/A | No (uses `@v6`, `@v1`, `@v3`) | No |
| **Broadway** | None found | Manual (no workflow) | No | No | No |
| **req** | None found | Manual (no workflow) | No | No | No |
| **oarlock** (paved path) | release-please | Automated on Release PR merge | Yes (release-please + hex-publish) | **Yes** — all three SHA-pinned | **Yes** (hex-publish.yml) |
| **sigra** (house style) | release-please | Automated on Release PR merge | Yes (release-please + hex-publish) | **Yes** — all three SHA-pinned | Yes (hex-publish.yml) |

**Survey findings:**

1. The dominant pattern in major Elixir OSS (Phoenix, Ecto, LiveView, Broadway, Oban, req) is **manual or no publish automation**. This is not a model to follow — it reflects either pre-automation era projects or projects relying on maintainer-held CLI publish cadence. The lack of publish automation is a trust gap that maintainers of these projects accept because they have established release discipline and individual accountability. A new library shipping its first version in 2026 should not inherit this pattern.

2. The **tag-driven publish** pattern (Bandit, Ash) is viable but requires a separate "bump the version and tag" manual step per release. For a solo maintainer with a structured codebase, it works. But it doesn't generate a CHANGELOG or Release PR automatically — the maintainer must maintain CHANGELOG by hand.

3. **release-please** adoption in the Elixir OSS ecosystem is low in the top-tier projects surveyed, but this reflects project age and maintainer preference more than a judgment against the tooling. The szTheory house style explicitly uses it (oarlock, sigra), has a paved-path skill for it, and has already solved all six known footguns. Crosswake should not re-discover the tag-driven failure modes when the release-please path is already broken in.

4. **SHA-pinning**: only Ash (among surveyed public Elixir libs) consistently SHA-pins. oarlock and sigra do. Bandit, Livebook, Livewire, Broadway do not. The low adoption rate does not reduce the risk — it reflects low awareness. Post-CVE-2025-30066, SHA-pinning is the clear best practice and the CISA-tracked remediation.

5. **Manual recovery workflow**: only the szTheory paved-path libraries (oarlock, sigra) have it. This is a gap in the broader ecosystem, not a reason to omit it from Crosswake.

---

## release-please Deep-Dive (Footguns + Prevention)

These are the concrete failure cases documented from oarlock bootstrap (2026-04-29) and the release-please docs.

### Footgun 1: Manifest off-by-one

**What happens:** If `.release-please-manifest.json` is set to `"0.1.0"` (the intended first release), release-please reads this as "0.1.0 is already shipped" and proposes `0.1.1` or `0.2.0` as the next version, depending on commit types accumulated. The first release never gets a Release PR.

**Prevention:** Always baseline the manifest at the version BEFORE the intended first release. For a `0.1.0` target: `{ ".": "0.0.0" }`. This is the prescribed value in the bootstrap skill and the oarlock template.

**Detection:** The Release PR title will say `chore(main): release 0.1.1` instead of `release 0.1.0`. Stop immediately if this happens.

### Footgun 2: First release jumps to 1.0.0

**What happens:** With manifest at `0.0.0` and accumulated `feat:` commits, release-please's "first stable" heuristic can propose `1.0.0` instead of `0.1.0`. This is because the default behavior treats a `feat:` on a `0.0.0` baseline as a minor bump from zero, which under some configs telescopes to `1.0.0`.

**Prevention:** Add `"release-as": "0.1.0"` to the package config in `release-please-config.json` for the first release only. This is an explicit pin that overrides version calculation. Remove it immediately after first publish (a `chore:` commit) or every subsequent Release PR will also pin to `0.1.0` and fail on conflict.

**Detection:** Release PR title says `chore(main): release 1.0.0`. Immediate stop.

### Footgun 3: GitHub Actions cannot create PRs (silent failure)

**What happens:** With default repository settings (`default_workflow_permissions=read`), the release-please action runs but silently fails to open the Release PR. No error is thrown — the action succeeds with no PR created. This is the most deceptive footgun because the workflow run shows green.

**Prevention:** Run immediately after `gh repo create`:
```bash
gh api -X PUT /repos/szTheory/crosswake/actions/permissions/workflow \
  -f default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=true
```

Also enable "Allow GitHub Actions to create and approve pull requests" in Settings > Actions > General (web UI).

**Detection:** Run release-please workflow manually via `workflow_dispatch`, check PR list. If no PR appears within 2 minutes, this footgun is likely the cause.

### Footgun 4: v4 vs v5 output naming

**What happens:** In release-please-action v5 (released 2026-04-22), the root-component output changed. For non-monorepos (single root `.` package), v4 outputs `release_created` and v5 outputs both `releases_created` (general) and `release_created` (root-only alias). The `publish-hex` job's `if:` condition uses `release_created` — this continues to work in v5 for single-package repos, but any migration from v4 to v5 for a monorepo would break `if:` conditions using path-prefixed outputs.

**Prevention for Crosswake:** Use v4 (pinned to SHA `de0fac2e4500dabe0009e67214ff5f5447ce83dd` which is what oarlock has in production). When upgrading to v5 later, update the `if:` condition and re-read output docs before merging.

**Current status:** oarlock and sigra both use `googleapis/release-please-action@v4`. The v4 SHA `de0fac2e...` in the oarlock template is the correct pin.

**Note:** The release-please-action referenced in oarlock is actually `actions/checkout@de0fac2e...` — that SHA is for `actions/checkout v6.0.2`. The release-please-action itself is referenced as `@v4` (tag, not SHA) in the current oarlock template. This is an improvement opportunity: pin `googleapis/release-please-action` to a full SHA as well.

### Footgun 5: bootstrap-sha anchor for non-conventional histories

**What happens:** Crosswake has 25 phases of commits that predate any conventional commit discipline. release-please will try to parse all of them for changelog generation. This is mostly harmless (non-conventional commits are silently skipped) but can produce a noisy first CHANGELOG entry if some commit messages accidentally match `feat:` or `fix:` prefixes.

**Prevention:** Set `bootstrap-sha` in the config to the HEAD commit SHA at time of v3.3 setup. This tells release-please "only parse commits after this point for changelog purposes." Combined with the one-time `release-as: "0.1.0"` pin, the first Release PR will have a clean CHANGELOG entry ("Initial public release" or whatever is in the existing `## [Unreleased]` section of the hand-crafted CHANGELOG).

**Prevention alternative:** Since Crosswake's v3.3 will also ship a hand-crafted `CHANGELOG.md` (Category A work), set `skip-changelog: false` in config and let release-please manage CHANGELOG from the `release-as` pin forward. The hand-crafted content covers pre-automation history; release-please takes over from `0.1.0` onward.

### Footgun 6: sigra's sync_release_summary.sh is sigra-specific

**What happens:** sigra's release pipeline has a `sync-release-summary` job that patches GitHub release body from a `### Summary` CHANGELOG section. The oarlock template already has this job stripped. If someone copies sigra's workflow instead of oarlock's, the `needs: sync-release-summary` dependency will fail because the job doesn't exist in the stripped template, blocking publish.

**Prevention:** Use oarlock's template, not sigra's. The bootstrap skill explicitly calls this out. The `release-please.yml` in oarlock has `needs: release-please` only on `publish-hex`, no sync job anywhere.

### Footgun 7: Breaking-change detection in 0.x

**What happens:** With `bump-minor-pre-major: true` (sigra setting), a `BREAKING CHANGE:` footer bumps minor instead of major in 0.x. This is reasonable if you want `0.2.0` from a breaking change in `0.1.0`. With `bump-minor-pre-major: false` (recommended for Crosswake), a breaking change bumps patch (since there is no major to bump in 0.x). This is unusual — it means breaking changes are indistinguishable from patches in the version signal.

**Recommendation:** Use `bump-minor-pre-major: false` but document in CHANGELOG that pre-1.0 breaking changes may appear in any minor or patch release (honest pre-release framing). Flip to `true` only if the maintainer wants `0.2.0`-style semaphore for breaking changes pre-1.0.

### Footgun 8: Monorepo confusion

**What happens:** Crosswake is a single-package repo. But if a future release adds companion packages under a `packages/` subdirectory, the manifest would need multiple entries. Using the manifest releaser from day one (rather than the non-manifest mode) means this upgrade is one config edit, not a workflow rewrite.

**Prevention:** Already prevented by using manifest mode as prescribed.

---

## Manual-Recovery Workflow Value-Add Analysis

The `hex-publish.yml` `workflow_dispatch` workflow is not dead weight. Here is the evidence:

### When a maintainer uses it

**Case 1 — publish-hex CI job fails after tag is created.** The Release PR merges, release-please creates the GitHub Release + `v0.1.0` tag, but `publish-hex` fails (flaky test, network timeout during `mix deps.get`, Hex.pm API timeout). The tag is live on GitHub, the version bump is committed to main, but nothing is on hex.pm. The normal automation cannot re-run `publish-hex` without re-triggering a new release-please PR cycle. The manual recovery workflow accepts `tag=v0.1.0 release_version=0.1.0` and runs the exact same test + dry-run + publish sequence from that tagged commit. Clean recovery, no git surgery needed.

**Case 2 — HEX_API_KEY secret is rotated.** If the key is expired or rotated mid-publish, the automated flow cannot retry without a new workflow run. Manual dispatch with the new key value already in secrets allows immediate retry.

**Case 3 — Operator wants to publish from a specific SHA (not the tag tip).** Rare, but possible during security response when a patch tag is needed for a SHA slightly ahead of the release tag.

**Case 4 — Initial bootstrap publish before automation is wired.** During v3.3 setup, if the maintainer wants to verify publish works before the full release-please cycle is confirmed (dry run only, `--dry-run` flag), the manual recovery workflow provides that path without a full Release PR cycle.

### How hex.pm revert windows interact

- hex.pm allows republication within **60 minutes** of initial publish for a version.
- hex.pm allows unpublish/revert with `mix hex.publish --revert VERSION` within **24 hours for initial package release**.
- After both windows close, the version is immutable. A wrong publish requires a new version number.

With these constraints, having a manual recovery workflow is critical: if automated publish produces the wrong tarball contents (e.g., `.gitignore` doesn't exclude build artifacts and they land in the package), the maintainer has 60 minutes to republish from the manual workflow with the fix applied. Without it, the window closes and the version is permanently wrong.

### What oarlock has

oarlock ships `hex-publish.yml` with `workflow_dispatch` inputs `tag` and `release_version`, runs the full test bar plus dry-run before publishing, and is explicitly documented as "Manual recovery: publish an already-tagged revision to Hex when automation did not run or needs a one-off retry." This is the exact recovery-conscious pattern that Crosswake's project DNA requires.

**Verdict: IN. It is 60 lines of YAML that provides essential recovery coverage. Omitting it is false economy.**

---

## Supply-Chain Hardening: SHA-Pinning

### The tj-actions/changed-files incident (CVE-2025-30066)

On **2025-03-14 and 2025-03-15**, a threat actor compromised the `tj-actions/changed-files` GitHub repository. The attacker modified tags `v1` through `v45.0.7` to point to a single malicious commit (`0e58ed8`) that contained backdoored code designed to print CI secrets to GitHub Actions logs.

**Attack vector:** Network-based, no authentication required. The attacker gained write access to the `tj-actions/changed-files` repository (likely via a compromised maintainer token or OAuth app), then retroactively moved all existing version tags (v1 through v45.0.7) to point to the malicious commit. Any repository that had previously used `tj-actions/changed-files@v45` or any earlier tag was now executing the malicious code on their next CI run.

**Blast radius:** `tj-actions/changed-files` had broad adoption across the GitHub Actions ecosystem. Any repository using the action on `pull_request` or `push` events was at risk of having its secrets (API keys, tokens, deploy keys, etc.) printed to logs. Logs on public repos are public; logs on private repos are accessible to the attacker if they triggered a run. CISA added CVE-2025-30066 to the Known Exploited Vulnerabilities catalog with a mandatory remediation deadline of April 8, 2025 — indicating real-world exploitation was confirmed.

**How SHA-pinning prevents it:** If a workflow references `tj-actions/changed-files@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (a full commit SHA), the attacker's tag manipulation is irrelevant. Git fetches the exact commit specified by SHA, not whatever commit the tag currently points to. Moving the tag does not affect SHA-pinned consumers. The malicious commit `0e58ed8` has a different SHA than any legitimate prior commit — any SHA-pinned workflow would have continued to run the pinned (safe) code rather than the backdoored code.

**Why Crosswake is exposed today:** The existing phase proof workflows (`phase5-proof.yml`, `phase18-proof.yml`, `phase23-proof.yml`) all use `actions/checkout@v4` and `erlef/setup-beam@v1` — tag references, not SHA references. These are not in scope for v3.3 to fix retroactively (that would be a separate hardening phase), but every new workflow file created in v3.3 must set the SHA-pinned standard.

### SHA-pinning in oarlock templates (already correct)

The oarlock workflow templates already SHA-pin all actions:
- `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2`
- `erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0`
- `actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830 # v4.3.0`

Copy these SHA values verbatim into Crosswake's v3.3 workflows. The SHAs are already validated in the oarlock + sigra live pipelines.

### Note: release-please-action SHA

The oarlock `release-please.yml` references `googleapis/release-please-action@v4` as a tag, not a SHA. This is a gap in the paved path. In v3.3, pin this action to a SHA as well. As of the research date, `googleapis/release-please-action` v4 latest SHA can be resolved from:
```bash
gh api repos/googleapis/release-please-action/git/refs/tags/v4 --jq '.object.sha'
```
If the result is a tag object (not a commit), dereference it:
```bash
gh api repos/googleapis/release-please-action/git/tags/<tag_sha> --jq '.object.sha'
```
Add the resulting SHA as `googleapis/release-please-action@<SHA> # v4` in the workflow.

### Maintenance cost with dependabot

SHA-pinned actions are updated automatically by dependabot when a new version is released. Configure `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

With this config, dependabot opens a PR to update each SHA when the underlying action releases a new version. The PR updates both the SHA and the `# vX.Y.Z` comment. Merge the PR after reviewing the action's changelog. The maintenance cost is one PR review per action per version, per week — negligible for a library with 4-5 actions in use.

---

## GitHub Repo Precondition Checklist

These must be done in order. Steps 1-3 are required before the first workflow run.

### Step 1: Create the GitHub repo

```bash
gh repo create szTheory/crosswake \
  --public \
  --description "Route policy for Phoenix apps that go mobile." \
  --source=. \
  --remote=origin \
  --push
```

### Step 2: Grant Actions write + PR-creation permissions (CRITICAL — do this immediately)

This prevents the silent-failure footgun (Footgun 3 above):

```bash
gh api -X PUT /repos/szTheory/crosswake/actions/permissions/workflow \
  -f default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=true
```

Also confirm via web UI: Settings > Actions > General > "Workflow permissions" = "Read and write permissions" + "Allow GitHub Actions to create and approve pull requests" is checked.

### Step 3: Add HEX_API_KEY secret

The only human-only step. See HEX_API_KEY guidance section below for key generation instructions.

```bash
gh secret set HEX_API_KEY --repo szTheory/crosswake
# Paste key when prompted (input is hidden)
gh secret list --repo szTheory/crosswake
# Confirm: HEX_API_KEY  Updated <today>
```

### Step 4: (Optional) Add RELEASE_PLEASE_TOKEN fine-grained PAT

Not required for a fresh repo with no branch protection rules. Required if you later add branch protection that blocks `GITHUB_TOKEN` from pushing to `main`. A fine-grained PAT with `Contents: write` and `Pull requests: write` scopes bypasses this restriction because PAT-triggered workflows re-trigger required CI checks, while `GITHUB_TOKEN`-triggered workflows do not.

If needed:
- Settings > Developer settings > Personal access tokens > Fine-grained tokens
- Scope: `szTheory/crosswake` only, `Contents: write`, `Pull requests: write`, `Issues: write`
- Save as `RELEASE_PLEASE_TOKEN` in repo secrets

### Step 5: Branch protection (recommended but not blocking)

Protect `main` after the first successful release:
```bash
gh api -X PUT /repos/szTheory/crosswake/branches/main/protection \
  --input - <<'EOF'
{
  "required_status_checks": {
    "strict": false,
    "contexts": ["mix test", "merge-blocking commerce support proof (hermetic)"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}
EOF
```

### Step 6: Verify release-please opens correct Release PR

After first push of commits to main, trigger manually:
```bash
gh workflow run release-please.yml --repo szTheory/crosswake
```
Within 2 minutes, verify:
```bash
gh pr list --repo szTheory/crosswake
# Should show: chore(main): release 0.1.0
```
If no PR appears or wrong version, stop and debug (see Footguns 3, 1, 2 above in that order).

---

## HEX_API_KEY Guidance

### What scopes to use

Use `package:crosswake` — **not** `api:write`. This is the minimum-privilege option:

- `api:write` grants write access to all packages the user owns, now and in the future. If the key leaks, an attacker can publish malicious versions of every other szTheory hex package.
- `package:crosswake` limits the key to the single `crosswake` package. Blast radius on leak: one package only.

Generate the scoped key:
```bash
mix hex.user key generate --key-name crosswake-ci --permission package:crosswake
```

The key is shown exactly once. Copy it immediately.

### Where to store it

GitHub Actions secret: `HEX_API_KEY` in repository secrets (not organization secrets). Repository-scoped secrets cannot be read by workflows in other repositories, even other repos owned by the same user.

### Expiration

hex.pm does not expose key expiration in the UI as of this writing. The key does not auto-expire. Rotate manually on a cadence (quarterly is reasonable) or immediately after a suspected credential exposure.

### How to rotate

1. Generate a new key: `mix hex.user key generate --key-name crosswake-ci-new --permission package:crosswake`
2. Update GitHub secret: `gh secret set HEX_API_KEY --repo szTheory/crosswake` (paste new key)
3. Revoke old key: `mix hex.user key revoke crosswake-ci` (or via hex.pm dashboard)
4. Trigger a manual dry-run to confirm the new key works: `gh workflow run hex-publish.yml --ref v0.1.0 --field tag=v0.1.0 --field release_version=0.1.0` — check the "Dry run Hex publish" step succeeds, then cancel before the "Publish to Hex" step runs.

### Blast radius if leaked

With `package:crosswake` scope: attacker can publish any version of `crosswake` to hex.pm, including malicious versions, for the lifetime of the key. Cannot touch other packages.

With `api:write` scope: attacker can publish to any package the user owns. Do not use `api:write`.

Hex.pm packages can be reverted within 60 minutes of publish (or 24 hours for initial release). A leaked key that immediately publishes a malicious version gives users 60 minutes from publish time before the malicious version is immutable on hex.pm. Rotate and revoke immediately on any suspected exposure.

---

## Integration with Crosswake's Hermetic-vs-Advisory Pattern

The v3.2 graduation decision (from `PROJECT.md` Key Decisions) established: "Adopt hermetic-vs-advisory CI split as the default pattern for environment-sensitive proof surfaces." How does the release pipeline fit?

### release-please workflow: advisory-style trigger, hermetic execution

- The release-please job (PR creation) is advisory in the sense that it doesn't gate merges. It runs on every push to `main` and opens or updates a Release PR. Failing to open a Release PR does not block any merge.
- The publish-hex job is hermetic: it runs only on `release_created == 'true'`, checks out a tagged commit (deterministic source), runs tests from that commit (hermetic), performs a dry-run before publish, then publishes. No environment-sensitive dependencies (no provider SDKs, no device, no simulator). It is fully deterministic.

**Classification: release-please job = advisory (non-blocking). publish-hex job = hermetic (deterministic once triggered, but only runs on release creation).**

### Should publish itself be merge-blocking?

No. Publish runs after the tag is created, not as a merge gate. This is correct. Making publish merge-blocking would mean no PR could merge until a new hex version is published — which is nonsensical. The correct model is: CI gates merges (hermetic); release-please manages versioning (advisory); publish runs post-release (triggered, deterministic).

### Manual recovery workflow: advisory dispatch

The `hex-publish.yml` workflow runs on `workflow_dispatch` only — never automatically. It is explicitly advisory (requires a human to trigger it) and is by definition not merge-blocking. This is correct.

### Compatibility with the existing CI split posture

Crosswake's existing merge-blocking lanes (phase5, phase10, phase18, phase23) are unaffected by adding release workflows. The new `release-please.yml` should be explicitly excluded from required branch checks (it is not a test lane; it's a versioning orchestrator). The `hex-publish.yml` should never be a branch check. No changes to branch protection rules are needed for the existing hermetic lanes.

---

## Coherence with Project Vision

### "Install truth is product truth"

The hex.pm package page is the install truth surface for Crosswake. Without a proper publish pipeline, Crosswake cannot exist on that surface. Adding release-please + the publish workflow directly enables this axiom: every `feat:` or `fix:` commit on `main` flows to a Release PR, which flows to a hex.pm publish, which flows to an updated install-truth surface. The package metadata (description, source_url, CHANGELOG link) must all be correct at first publish or the install truth surface is dishonest from day one.

### "Release truth matters"

release-please enforces conventional commits on `main` as the mechanism for determining the next version. This means every merged PR on `main` must be a deliberate conventional commit — the commit message IS the release truth signal. Non-conventional commits (planning commits, chore-without-type commits) are silently skipped. This is fine: only `feat:`, `fix:`, and `BREAKING CHANGE` commits drive version bumps. The release-please workflow makes this system explicit and auditable.

### "Recovery-conscious publishing"

The manual recovery workflow (`hex-publish.yml`) is the direct expression of this principle in infrastructure form. It exists because automated publish can fail between the tag step and the hex.pm step, and recovery must not require a git rewrite. The 60-minute republication window on hex.pm is tight enough that an automated failure with no manual escape hatch could mean a permanently wrong version.

### "Hermetic-vs-advisory CI split"

The publish pipeline respects this split: the release-please PR-creation job is advisory (doesn't gate merges), the publish job is triggered and deterministic (hermetic once started), and the manual recovery workflow is purely dispatch-triggered. Nothing in the release pipeline introduces an environment-sensitive dependency that would create a new hermetic/advisory boundary question.

### Brand voice: "calm, explicit, technical"

The workflow comments in the oarlock template model this voice. They explain what each step does, what can fail, and what the fallback is. Copy this comment style into the Crosswake workflows — not just the YAML skeleton but the explanatory header comments.

---

## Recommended Workflow File Skeletons

These are derived from oarlock canonical templates. Key differences from oarlock: no Postgres service block (Crosswake is a pure Elixir library with no DB deps), hex verify URL uses `crosswake`, same SHA pins.

### .github/workflows/release-please.yml

```yaml
# Release Please opens/updates a Release PR from conventional commits on main.
# When that PR is merged, Release Please creates the GitHub Release + v* tag,
# then publish-hex runs the same test bar as CI and publishes to Hex with
# HEX_API_KEY.
#
# Requires repository secret: HEX_API_KEY (Actions secrets).
# RELEASE_PLEASE_TOKEN: optional fine-grained PAT. Using it for Release Please
# makes release-branch pushes and PRs run required CI (GITHUB_TOKEN does not
# chain-trigger other workflows). Also use if branch rules block the default token.
#
# Release pipeline pattern:
#   release-please job (advisory — non-blocking) -> publish-hex job (hermetic, triggered)
# The release-please job never gates merges. publish-hex runs only on release_created==true.

name: Release Please

on:
  push:
    branches:
      - main
  workflow_dispatch:

permissions:
  contents: write
  issues: write
  pull-requests: write

concurrency:
  group: release-please-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  release-please:
    name: Release Please
    runs-on: ubuntu-latest
    outputs:
      release_created: ${{ steps.release.outputs.release_created }}
      tag_name: ${{ steps.release.outputs.tag_name }}
      version: ${{ steps.release.outputs.version }}
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          fetch-depth: 0

      - name: Run Release Please
        id: release
        uses: googleapis/release-please-action@<RESOLVE-SHA-BEFORE-COMMIT> # v4
        with:
          # Optional: set secret RELEASE_PLEASE_TOKEN (fine-grained PAT) if the
          # default token cannot open Release PRs; otherwise github.token suffices.
          token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json

  publish-hex:
    name: Publish to Hex.pm
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}

      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
        with:
          version-file: .tool-versions
          version-type: strict

      - name: Cache library deps
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830 # v4.3.0
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-library-${{ hashFiles('mix.lock') }}

      - name: Install Hex + Rebar
        run: |
          mix local.hex --force
          mix local.rebar --force

      - name: Fetch library deps
        run: mix deps.get

      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors

      - name: Verify release version in mix.exs
        run: grep -n "@version \"${{ needs.release-please.outputs.version }}\"" mix.exs

      - name: Run library tests
        env:
          MIX_ENV: test
        run: mix test

      - name: Dry run Hex publish
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
        run: mix hex.publish --dry-run --yes

      - name: Publish to Hex
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
        run: mix hex.publish --yes

      - name: Verify version on Hex.pm
        env:
          VERSION: ${{ needs.release-please.outputs.version }}
        run: |
          set -euo pipefail
          for i in $(seq 1 36); do
            if curl -fsS "https://hex.pm/api/packages/crosswake/releases/${VERSION}" | grep -q "\"version\""; then
              echo "Hex.pm lists crosswake ${VERSION}"
              exit 0
            fi
            echo "waiting for Hex index... (${i}/36)"
            sleep 10
          done
          echo "Timed out waiting for https://hex.pm/api/packages/crosswake/releases/${VERSION}"
          exit 1
```

**Note on googleapis/release-please-action SHA:** Before committing, resolve the current v4 SHA:
```bash
gh api repos/googleapis/release-please-action/git/ref/tags/v4 --jq '.object.sha'
# If it returns a tag object SHA, dereference:
# gh api repos/googleapis/release-please-action/git/tags/<TAG_SHA> --jq '.object.sha'
```
Replace `<RESOLVE-SHA-BEFORE-COMMIT>` with the resolved commit SHA and append `# v4`.

---

### .github/workflows/hex-publish.yml

```yaml
# Manual recovery: publish an already-tagged (or pinned SHA) revision to Hex when
# automation did not run or needs a one-off retry. Default path is Release Please
# (.github/workflows/release-please.yml) on merge of the Release PR.
#
# Use this workflow when:
#   1. publish-hex failed after the tag was created (flaky test, network timeout).
#   2. HEX_API_KEY was rotated and you need to retry publish.
#   3. You want to verify publish works with a dry-run before the first Release PR.
#
# Requires repository secret: HEX_API_KEY (Actions secrets).
# Recovery window: hex.pm allows republication within 60 minutes of initial publish.
# After 60 minutes, a version is immutable on hex.pm; a new version number is required.

name: Hex publish (manual recovery)

on:
  workflow_dispatch:
    inputs:
      tag:
        description: 'Git tag or commit SHA to publish from (e.g. v0.1.0).'
        required: true
        type: string
      release_version:
        description: 'Expected @version string in mix.exs at that ref (e.g. 0.1.0).'
        required: true
        type: string

permissions:
  contents: write

jobs:
  publish:
    name: Publish to Hex.pm
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          ref: ${{ inputs.tag }}

      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
        with:
          version-file: .tool-versions
          version-type: strict

      - name: Cache library deps
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830 # v4.3.0
        with:
          path: |
            deps
            _build
          key: ${{ runner.os }}-library-${{ hashFiles('mix.lock') }}

      - name: Install Hex + Rebar
        run: |
          mix local.hex --force
          mix local.rebar --force

      - name: Verify release version in mix.exs
        run: grep -n "@version \"${{ inputs.release_version }}\"" mix.exs

      - name: Fetch library deps
        run: mix deps.get

      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors

      - name: Run library tests
        env:
          MIX_ENV: test
        run: mix test

      - name: Dry run Hex publish
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
        run: mix hex.publish --dry-run --yes

      - name: Publish to Hex
        env:
          HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
        run: mix hex.publish --yes
```

---

### release-please-config.json

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bump-minor-pre-major": false,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "include-v-in-tag": true,
      "release-as": "0.1.0"
    }
  }
}
```

**Important:** `release-as: "0.1.0"` is a one-time pin. Remove it immediately after `0.1.0` ships (in a `chore: remove release-as pin` commit). If left in, every Release PR will propose `0.1.0` indefinitely.

`bump-minor-pre-major: false` means breaking changes pre-1.0 bump patch, not minor. This is intentional: Crosswake at `0.x` should not signal stability through minor version discipline. If the maintainer later wants `0.2.0`-style breaking change signals, flip to `true` before that change.

---

### .release-please-manifest.json

```json
{
  ".": "0.0.0"
}
```

Baseline at `0.0.0`. This is one version before the intended `0.1.0` first release. Never set this to `0.1.0` before the first release runs.

---

### .github/dependabot.yml

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

Add this file in v3.3 alongside the new workflow files. dependabot will open weekly PRs to update SHA pins when new action versions release.

---

## Confidence

| Decision | Confidence | Reasoning |
|---|---|---|
| release-please config + manifest: IN | **HIGH** | Paved path is proven (oarlock, sigra), all six footguns documented and preventable, manifest off-by-one is the #1 first-time failure and the prevention is a single `0.0.0` value |
| release-please.yml workflow: IN | **HIGH** | oarlock template is live and battle-tested, no Postgres service needed (Crosswake is pure Elixir), oarlock SHA pins are already validated, the only substitution is the Hex verify URL |
| hex-publish.yml manual-recovery: IN | **HIGH** | Recovery-conscious publishing is a stated project principle; the 60-minute hex.pm revert window is tight enough that having no manual recovery path is genuinely risky; oarlock template already exists verbatim |
| SHA-pin all GitHub Actions: IN | **HIGH** | CVE-2025-30066 is a CISA-tracked, real-world-exploited incident from March 2025; SHA pinning is the single actionable prevention; oarlock SHAs are already validated and copy-pasteable; dependabot handles ongoing maintenance at zero marginal cost; the only argument against is "the existing phase workflows don't do it" which is not a reason to perpetuate the gap in new files |

No MEDIUM or LOW confidence items. All four decisions are independently defensible and mutually reinforcing as a coherent release system.

---

_Last updated: 2026-05-27._
