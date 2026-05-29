# Project Research: Pitfalls For v3.3 Release Readiness (hex.pm Publication)

**Milestone:** v3.3 Release Readiness
**Domain:** First-time hex.pm publication of a mature Elixir library
**Researched:** 2026-05-27
**Confidence:** HIGH — primarily sourced from hex.pm official docs, release-please official docs, bootstrap-elixir-hex-lib skill (oarlock first-publish post-mortem), and Elixir library guidelines.

---

## Critical Pitfalls

### Pitfall 1: Files Allowlist Omission Ships `.planning/`, `prompts/`, or Internal Docs

**What goes wrong:**
Hex's default `:files` list is `["lib", "priv", ".formatter.exs", "mix.exs", "README*", "readme*", "LICENSE*", "license*", "CHANGELOG*", "changelog*", "src", "c_src", "Makefile*"]`. Crosswake's current `package/0` block has NO `:files` key at all (confirmed in `mix.exs:37-42`). The default does not match glob patterns like `.planning/` or `prompts/` — but `priv/` is included by default and any directory named `src` would be included. More critically, if anyone ever adds a `guides/` directory alongside the library (it's already referenced in the bootstrap skill's template), it would be silently included.

The deeper risk: `.planning/` contains strategy docs, MILESTONES.md, threads, and internal roadmap material that are not appropriate for public hex packages. `prompts/` contains OSS DNA prompts. Neither of these matches the hex default glob, so they are currently safe — but the moment `:files` is explicitly set, the author must enumerate exactly what to include. A naive `~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)` that copies the skill template without auditing `guides/` vs internal dirs ships unwanted content permanently into a public, immutable tarball.

**Why it happens:**
Developers copying a template files list without auditing whether Crosswake's directory structure matches the template source.

**How to avoid:**
Run `mix hex.build --unpack` before any publish and inspect every file in the unpacked directory. Explicitly set `:files` in `package/0` to the exact allowlist. Do NOT include `guides/` unless a `guides/` directory for adopter documentation has been created intentionally. Include `src` only if it exists. The safe explicit allowlist for Crosswake's current layout: `~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)`.

**Warning signs:**
- `package/0` has no `:files` key (currently the case in `mix.exs`)
- Any new top-level directory gets added without updating the allowlist
- `mix hex.build --unpack` output contains `.planning/`, `prompts/`, `test/`, or any doc-planning artifact

**Phase to address:**
Package metadata audit phase. Audit and set `:files` explicitly before any publish attempt. Verify with `mix hex.build --unpack`.

---

### Pitfall 2: release-please Manifest Off-By-One Version

**What goes wrong:**
Two distinct failure modes from the oarlock post-mortem (bootstrap-elixir-hex-lib SKILL.md gotchas #4 and #5):

- If `.release-please-manifest.json` baseline is `"0.1.0"`, release-please treats `0.1.0` as already released and proposes `0.1.1` or `0.2.0` as the next release. The first publish goes to the wrong version.
- If `.release-please-manifest.json` baseline is `"0.0.0"` without a `release-as` pin AND there are accumulated `feat:` commits in history, release-please's first-stable-release heuristic proposes `1.0.0`, not `0.1.0`. An unlocked first publish to `1.0.0` when the intent was `0.1.0` cannot be undone.

For Crosswake, which is deciding between `0.1.0` and `1.0.0-rc.0` as the initial published version, this manifests as: whichever version is chosen must be pinned explicitly via `release-as` in `release-please-config.json`, and the manifest baseline must be one version prior.

**Why it happens:**
Misunderstanding the manifest's role: it records what has been released, not what should be released next. Setting it to the intended first version means release-please believes that version has already shipped.

**How to avoid:**
- Set manifest baseline to the version BEFORE the intended first release (e.g., `"0.0.0"` if targeting `0.1.0`, or `"0.0.1"` if targeting `1.0.0-rc.0` — though pre-release versions in manifests require additional care; use `release-as` pin instead).
- Add `"release-as": "<intended-first-version>"` to the package entry in `release-please-config.json` for the FIRST release only.
- Remove the `release-as` pin after the first successful publish (leaving it causes every future PR to be pinned to that version, causing publish-already-exists failures).

**Warning signs:**
- Release PR title proposes a version different from the intended first version
- First CI run after push proposes `0.2.0`, `1.0.0`, or any version other than the one in `release-as`

**Phase to address:**
Release-please config phase. Pin and verify before the first push to GitHub.

---

### Pitfall 3: release-please v4 `releases_created` Output Footgun

**What goes wrong:**
In `release-please-action` v4, the plural `releases_created` output is always `true`, regardless of whether an actual release was created. Any workflow job that uses `if: steps.release.outputs.releases_created` as the gate for hex publish will trigger unconditionally — including on regular PR merges where no release PR was merged. This causes spurious publish attempts (and fails with "version already published" or publishes a pre-release tarball that shouldn't be public).

**Why it happens:**
v3 used `releases_created` safely; v4 changed behavior without renaming. Copying v3 workflow templates into a v4 setup reproduces the bug silently.

**How to avoid:**
Use the singular `release_created` output: `if: ${{ steps.release.outputs.release_created }}`. For a single-package repo (the Crosswake case), this is the correct gate. The bootstrap skill's oarlock template already uses the correct output — do not substitute `releases_created`.

**Warning signs:**
- Publish job runs on every push to main, not just after release PR merges
- CI log shows "version already published" errors on non-release commits
- Workflow YAML contains `releases_created` (plural) as a job condition

**Phase to address:**
Release workflow authoring phase. Audit output variable names in release.yml before push.

---

### Pitfall 4: GitHub Actions Cannot Create PRs (Default Repo Permission)

**What goes wrong:**
GitHub's default repository setting blocks Actions from creating pull requests. release-please depends on opening a Release PR to track upcoming version bumps and changelogs. If the setting is not flipped, the release-please workflow runs, produces no PR, logs a permissions error, and silently does nothing — or fails with a cryptic API 403.

This bit the oarlock bootstrap (SKILL.md gotcha #3) and is easy to forget because the CI run completes (the release-please job doesn't fail hard by default) but no Release PR appears.

**Why it happens:**
GitHub ships the restrictive default to reduce abuse surface. New repos inherit it. The fix is one API call but it's easy to overlook.

**How to avoid:**
Immediately after creating or confirming the public GitHub repo, run:
```
gh api -X PUT /repos/szTheory/crosswake/actions/permissions/workflow \
  -f default_workflow_permissions=write \
  -F can_approve_pull_request_reviews=true
```
Or set via repo Settings > Actions > General > Workflow permissions.

**Warning signs:**
- release-please workflow run shows green but no Release PR appears
- Workflow logs contain "403" or "Resource not accessible by integration" from the GitHub API call

**Phase to address:**
GitHub repo setup phase. Do this before the first release-please workflow run.

---

### Pitfall 5: Version Choice Irreversibly Signals Wrong Maturity Posture

**What goes wrong:**
Publishing `0.1.0` when Crosswake has 11.5k LOC, 8k LOC tests, five shipped internal milestones, and a stable contract surface sends "experimental, unstable" signals to evaluators. Publishing `1.0.0` without an RC period signals "stable public API" when the hex page has never been live and no external adopter has validated the install path.

The irreversibility aspect: hex.pm allows reverts within one hour of initial publish and within 24 hours of the first publish of a brand-new package. After those windows, the version exists permanently (you can retire it, but it remains in the package history and its existence sets ecosystem expectations). Choosing wrong and retiring is noisier than choosing right.

**Why it happens:**
Treating the published version as purely an internal tracking number, not as a public signal that adopters and dependency resolution tools interpret.

**How to avoid:**
Make the explicit decision before the package metadata phase and document it in CHANGELOG.md:
- `0.1.0`: honest pre-release signal, permits breaking changes under semver, but understates the contract maturity. release-please's `bump-minor-pre-major: false` setting means breaking changes inside `0.x` bump patch, not minor — which is the right posture if adopting `0.x`.
- `1.0.0-rc.0`: signals "contract-mature, beta install path" without claiming production stability. Adopters who pin `~> 1.0` get updates within the 1.x series. Pre-release versions are excluded from `~> x.y` requirement matching by default in Hex (`:allow_pre` defaults to false), so `1.0.0-rc.0` won't satisfy a `~> 1.0` requirement in a downstream unless that downstream opts in.

The evidence favors `0.1.0` if the primary concern is staying on a well-understood release-please automation path. Use `1.0.0-rc.0` only if the explicit goal is signaling contract maturity to early adopters who need to opt into pre-release.

**Warning signs:**
- Version in mix.exs and CHANGELOG.md are inconsistent
- release-please `release-as` pin not updated to match the chosen version
- No CHANGELOG entry explaining the rationale for the chosen version

**Phase to address:**
Version decision phase (before package metadata or CHANGELOG work begins). Document rationale.

---

### Pitfall 6: CHANGELOG Synthesized from MILESTONES.md Drifts from hex.pm Rendering Context

**What goes wrong:**
MILESTONES.md uses Crosswake-internal milestone labels (`v1.0 Route Policy Foundation`, `v3.2 Commerce And Entitlement Seams`) that have no meaning on the hex package page. Naively copying milestone headings into CHANGELOG.md creates a CHANGELOG that looks like internal planning artifacts, not a public adopter-facing release history.

The secondary risk: release-please writes to CHANGELOG.md on each release. If the CHANGELOG is pre-populated with handcrafted entries using non-standard heading formats (e.g., `## v3.2 Commerce And Entitlement Seams` instead of `## [0.1.0] - 2026-05-27`), release-please may insert its auto-generated block in the wrong position or fail to find the `## [Unreleased]` anchor it requires.

**Why it happens:**
MILESTONES.md is an excellent internal source of truth but was not written for hex.pm/adopter consumption. Direct copy-paste elides the translation step.

**How to avoid:**
- CHANGELOG.md must use Keep-a-Changelog format with `## [Unreleased]` at the top.
- The initial `## [Unreleased]` section under the Bootstrap Disclaimer (see SKILL.md template) should contain a single `* Initial public release.` entry — not a history dump of v1.0 through v3.2.
- v1.0 through v3.2 history belongs in a `## Historical Planning Milestones` appendix section with a header note explaining these are internal planning phases, or omitted entirely from CHANGELOG.md in favor of a link to MILESTONES.md.
- Test `mix docs` locally before publish; verify hexdocs renders the CHANGELOG extras correctly.

**Warning signs:**
- CHANGELOG.md has `## v3.2 Commerce And Entitlement Seams` or similar non-semver headings at the top
- No `## [Unreleased]` anchor exists (release-please will fail to find insert point)
- `## Planning milestones vs Hex releases` disclaimer (from SKILL.md template) is absent — adopters see no explanation for the milestone vocabulary

**Phase to address:**
CHANGELOG authoring phase. Draft CHANGELOG.md before wiring release-please; validate the heading structure with the release-please elixir release-type parser.

---

### Pitfall 7: `source_url` Placeholder in `mix.exs` Published to hex.pm

**What goes wrong:**
`mix.exs:40` currently reads `"GitHub" => "https://github.com/example/crosswake"`. Publishing with this value means every hex package page link, every hexdocs "view source" link, and every CHANGELOG diff link points to a nonexistent repo. Worse, this is a public signal on hex.pm that the package was published carelessly.

**Why it happens:**
The placeholder was set during private milestone work and was not replaced because the repo was not yet public.

**How to avoid:**
Set `@source_url` to the actual GitHub repo URL in mix.exs. Also add `@source_url` as a module attribute and reference it in both `project/0` and `package/0` (the skill template pattern). Confirm the GitHub repo exists and is public before first publish. Add `source_url: @source_url` to the `docs/0` function's `source_ref: "v#{@version}"` block.

**Warning signs:**
- `mix.exs` still contains `example/crosswake` or any placeholder string
- `mix hex.build --unpack` + grep for "example" finds it in the unpacked tarball metadata

**Phase to address:**
Package metadata audit phase. First action before anything else.

---

## Moderate Pitfalls

### Pitfall 8: `mix.exs` Missing `docs/0` Function — ex_doc Not a Dev Dependency

**What goes wrong:**
Crosswake's current `mix.exs` has no `docs/0` function and no `{:ex_doc, ...}` dependency. Publishing without `ex_doc` means hexdocs.pm will either show no documentation or render auto-generated module stubs without the README, guides, or extras. The hex package page displays the package description but no polished docs landing page.

Additionally, if `ex_doc` is added but listed without `only: [:dev]`, it becomes a transitive compile dependency for every adopter of the library, which is unnecessary and inconsiderate.

**How to avoid:**
Add `{:ex_doc, "~> 0.34", only: :dev, runtime: false}` to deps. Add a `docs/0` private function:
```elixir
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    source_url: @source_url,
    extras: ["README.md", "CHANGELOG.md"]
  ]
end
```
Add `docs: docs()` to `project/0`. Run `mix docs` locally and verify the HTML output before publish.

**Warning signs:**
- `mix.exs` has no `docs:` key in `project/0`
- `mix deps` shows no `ex_doc` entry
- `mix docs` fails or produces no `doc/` directory

**Phase to address:**
Package metadata audit phase, alongside `:files` and `:package` audits.

---

### Pitfall 9: Dependency Version Constraints Too Tight (Blocking Adopter Upgrades)

**What goes wrong:**
Crosswake currently depends on `{:phoenix, "~> 1.8"}` and `{:phoenix_live_view, "~> 1.1"}`. The `~> 1.8` form is correct (allows 1.8.x and 1.9.x, 1.10.x, etc. but not 2.0). However, if any dependency were specified as `"~> 1.8.0"` (with patch), it would block adopters from using Phoenix 1.9.x when it ships. The library guidelines are explicit: `"~> x.y.z"` prevents minor upgrades for the adopter.

The secondary risk: `{:jason, "~> 1.4"}` and `{:nimble_options, "~> 1.1"}` look correct. Verify no dep uses a three-part patch constraint.

**How to avoid:**
Audit every dep in `deps/0`. Ensure all production dependencies use `"~> major.minor"` form, not `"~> major.minor.patch"`. For pre-1.0 deps, `"~> 0.x.y"` is acceptable.

**Warning signs:**
- Any `{:dep, "~> x.y.z"}` where `z` is a patch version in a 1.x+ library

**Phase to address:**
Package metadata audit phase.

---

### Pitfall 10: `HEX_API_KEY` Exposed in Workflow Logs

**What goes wrong:**
If `HEX_API_KEY` is echoed, printed to a step summary, or logged in any workflow step — even accidentally via a debug flag — it becomes visible in GitHub Actions logs. Anyone with read access to the repo can view historical workflow logs. A leaked key allows any holder to publish to hex.pm as the package owner.

The supply-chain angle: if a CI workflow uses a third-party action pinned by version tag (not SHA), a compromised action version can exfiltrate the secret. The tj-actions/changed-files incident (March 2025) did exactly this across 23,000 repos.

**How to avoid:**
- Store `HEX_API_KEY` as a repository secret, never as an environment file or workflow variable that might be echoed.
- Reference only as `${{ secrets.HEX_API_KEY }}` in the publish step's `env:` block.
- Pin all third-party actions in workflows to full commit SHA, not to `@v4` tags: `uses: actions/checkout@<full-sha>`.
- Do not add `-v` or `--verbose` to `mix hex.publish` steps — verbose mode can print environment details.

**Warning signs:**
- Any workflow step that `echo`s environment variables
- Third-party actions referenced as `@v3`, `@v4` instead of `@<40-char-sha>`
- `HEX_API_KEY` set anywhere other than GitHub Secrets UI

**Phase to address:**
Release workflow authoring phase. Security audit of all workflow YAML before push.

---

### Pitfall 11: release-please Accumulates Non-Conventional Commits from Private History

**What goes wrong:**
Crosswake has 25+ phases of commit history with commit messages that were written for internal milestone tracking, not for conventional commits format. When release-please runs for the first time on a repo with accumulated history, it may scan all commits since the beginning of time (if no `bootstrap-sha` is set) and produce a CHANGELOG that contains hundreds of non-conformant entries, or produce an unexpected major bump from any commit that happens to parse as `feat!:` or contain `BREAKING CHANGE:` in its body.

**Why it happens:**
release-please's manifest-releaser uses the GitHub API to walk commits back to the most recent tag or the `bootstrap-sha`. Without a bootstrap anchor, every commit is in scope.

**How to avoid:**
Set `"bootstrap-sha"` in `release-please-config.json` to the SHA of the most recent commit before the release workflow is first wired. This tells release-please to treat everything before that SHA as pre-existing history, not as changelog material:
```json
{
  "bootstrap-sha": "<sha-of-last-commit-before-release-wire>",
  "packages": { "...": {} }
}
```
The bootstrap-sha is only used once; after the first Release PR merges, it becomes irrelevant and can be removed.

**Warning signs:**
- First release-please PR contains a CHANGELOG with dozens of entries referencing internal planning phases
- Version bump is unexpected (e.g., proposes 2.0.0 from an old "BREAKING: ..." commit in the archive)

**Phase to address:**
Release-please config phase. Set bootstrap-sha before the first push with release-please workflow.

---

### Pitfall 12: README Renders Differently on hex.pm Package Page vs hexdocs.pm

**What goes wrong:**
hex.pm's package page renders the README directly from the tarball without ExDoc processing. hexdocs.pm renders the README through ExDoc's HTML pipeline. The differences that bite:
- Relative image paths (`./assets/diagram.png`) render correctly in GitHub and hexdocs but break on the hex.pm package page, which has no asset serving.
- Elixir code blocks with `<!--hexdoc skip-->` comments and other ExDoc-specific directives are visible as raw HTML comments on the hex.pm page.
- Admonitions and callout syntax (`> #### Note\n> `) render correctly in ExDoc but appear as plain blockquotes on hex.pm.

**How to avoid:**
- Use absolute GitHub raw URLs for any images in README.md: `https://raw.githubusercontent.com/szTheory/crosswake/main/assets/...`
- Preview the hex package page rendering by running `mix hex.build --unpack` and opening the README in a plain Markdown renderer (not GitHub-flavored).
- For Crosswake specifically: check if README.md contains any relative asset links.

**Warning signs:**
- README.md contains `![...](./)` or `![...](assets/)` relative image paths
- README uses `> [!NOTE]` GitHub-flavored admonition syntax (not standard Markdown)

**Phase to address:**
README and hexdocs polish phase. Verify rendering before first publish.

---

### Pitfall 13: `release-as` Pin Left In After First Publish

**What goes wrong:**
The `release-as` pin in `release-please-config.json` is a one-time bootstrap override that forces the first release to a specific version. If it is not removed after the first successful publish, every subsequent release-please PR will attempt to re-propose the same version. The publish step will fail with "version already published on hex.pm" or release-please will create an infinite loop of Release PRs all targeting `0.1.0`.

**Why it happens:**
The cleanup step is documented in the skill but easy to skip after the excitement of a first publish.

**How to avoid:**
Treat `release-as` removal as a mandatory post-publish step. Add it to the release phase acceptance criteria: "CHANGELOG.md updated AND release-as pin removed AND release-please config committed."

```bash
sed -i '' '/"release-as":/d' release-please-config.json
git commit -am "chore: remove release-as pin (0.1.0 shipped)"
git push origin main
```

**Warning signs:**
- `release-please-config.json` still contains `"release-as"` after first publish
- Second release-please run proposes the same version as the first

**Phase to address:**
Post-publish cleanup phase (explicit phase or acceptance criteria step in the release phase).

---

### Pitfall 14: `ex_doc` Missing from `:files` Allowlist for `guides/` Extras

**What goes wrong:**
If `docs/0` lists `extras: ["README.md", "CHANGELOG.md", "guides/architecture.md"]` but `package/0` `:files` does not include `"guides"`, the hex tarball won't contain the guides files. hexdocs.pm will build docs from the tarball and silently omit the extras — producing a docs site with no guides content and no error. This is a particularly nasty silent failure because `mix docs` (which runs from the source tree) works fine; only the hexdocs.pm build (from tarball) fails.

**How to avoid:**
Ensure `:files` allowlist matches every directory referenced in `docs/0` extras. If guides are added later, update both in the same commit.

**Warning signs:**
- `extras:` in `docs/0` references a directory not present in `:files`
- hexdocs.pm shows fewer pages than `mix docs` generates locally

**Phase to address:**
Package metadata audit phase. Cross-check `:files` vs `docs/0` extras before publish.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip `mix hex.build --unpack` audit | Faster publish | Ships .planning/ or internal docs permanently | Never |
| Copy files list from template without auditing | Template reuse | Wrong files included or missing | Never |
| Leave `release-as` pin after first publish | Simpler first PR | Infinite Release PR loop | Never — must remove |
| Skip `bootstrap-sha` in release-please config | Simpler config | Massive CHANGELOG from private history | Never |
| Pin actions by tag (`@v4`) instead of SHA | Easier to read | Supply chain vulnerability (tj-actions pattern) | Only for internal-only repos with no secrets |
| Use `releases_created` output gate | Copy from v3 docs | Spurious hex publish on every push | Never in v4 |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| release-please + existing repo | Manifest baseline at `0.1.0` | Baseline at `0.0.0` with `release-as: "0.1.0"` pin |
| release-please + existing repo | No `bootstrap-sha` | Set `bootstrap-sha` to HEAD SHA before first push |
| release-please v4 | `releases_created` condition | `release_created` (singular) condition |
| hex publish + GitHub Actions | API key in env echo | `${{ secrets.HEX_API_KEY }}` in env block only |
| hexdocs + README | Relative image paths | Absolute raw.githubusercontent.com URLs |
| hex tarball + guides | Guides in extras but not `:files` | Cross-check `:files` vs extras list every time |
| hex.pm + description | Missing `description()` function | Required field — will error at publish time |
| release-please + GitHub | Default workflow permissions | Flip `default_workflow_permissions=write` immediately after repo creation |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Third-party actions pinned by tag not SHA | Compromised action exfiltrates `HEX_API_KEY` (tj-actions 2025 pattern) | Pin all `uses:` to full 40-char commit SHA |
| `HEX_API_KEY` in repo-level secret without environment protection | Any workflow on any branch can access the key | Consider environment secrets with approval gate for the publish environment |
| `mix hex.publish` with `--verbose` flag | Key value in logs | Never add verbose flag; use `mix hex.build --dry-run` for validation |
| Publishing from a branch other than main | Unreviewed code shipped | Release workflow must gate on `refs/tags/v*` or require Release PR merge to main |

---

## "Looks Done But Isn't" Checklist

- [ ] **`:package` block:** Has `:licenses`, `:links`, `:maintainers`, AND `:files` — missing any one causes hex-page rendering gaps or ships wrong content.
- [ ] **`source_url`:** No longer contains `example/crosswake` placeholder — verify with `grep -r "example" mix.exs`.
- [ ] **CHANGELOG.md:** Has `## [Unreleased]` anchor at top — release-please inserts above this; without it the insert position is undefined.
- [ ] **release-please manifest:** Baseline is `"0.0.0"` not `"0.1.0"` — one-off-by-one version causes first publish to wrong version.
- [ ] **`release-as` pin:** Present in config before first publish AND removed after.
- [ ] **GitHub permissions:** `default_workflow_permissions=write` set — otherwise release-please silently fails to create PR.
- [ ] **Tarball audit:** `mix hex.build --unpack` run and output inspected for unwanted files.
- [ ] **hexdocs smoke test:** `mix docs` runs locally without errors before publish.
- [ ] **ex_doc dev-only:** `{:ex_doc, ..., only: :dev, runtime: false}` — not a production dep.
- [ ] **`releases_created` vs `release_created`:** Workflow YAML uses singular `release_created` output gate.
- [ ] **`release-as` pin removed:** After first publish, `release-please-config.json` has no `release-as` key.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Wrong files shipped in tarball | HIGH | Retire the version within 1-hour window (`mix hex.publish --revert VERSION`); fix `:files`, republish. After 1 hour: contact hex.pm admin or retire with `mix hex.retire VERSION security` + republish corrected version. |
| Wrong version published | MEDIUM | Within 24h of brand-new package: revert entire package. After 24h: retire wrong version, publish correct version separately. Note: retired version remains in history. |
| `release-as` pin not removed | LOW | Remove pin, commit, push. release-please will self-correct on next run. |
| `source_url` placeholder published | MEDIUM | Within 1 hour: revert and republish. After: publish corrected metadata in next version bump. |
| CHANGELOG missing `[Unreleased]` anchor | LOW | Add `## [Unreleased]` section, push to main — release-please fixes on next run before any publish occurs. |
| release-please creates wrong-version PR | LOW | Close the PR, fix manifest/config, push — release-please will open a new correct PR. No publish has occurred yet. |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Files allowlist ships internal docs | Package metadata audit phase | `mix hex.build --unpack` + manual inspection of unpacked dir |
| Manifest off-by-one / release-as missing | release-please config phase | Verify Release PR title matches intended first version |
| `releases_created` v4 output | Release workflow authoring phase | Code review of `if:` condition in publish job |
| GitHub Actions can't create PRs | GitHub repo setup phase | Confirm Release PR appears after first push |
| Version choice (0.1.0 vs 1.0.0-rc.0) | Version decision phase (before metadata) | CHANGELOG entry documents rationale |
| CHANGELOG milestones vs hex format | CHANGELOG authoring phase | Validate `## [Unreleased]` anchor exists; test with `mix docs` |
| source_url placeholder | Package metadata audit phase | `grep "example" mix.exs` returns nothing |
| ex_doc missing / not dev-only | Package metadata audit phase | `mix docs` succeeds; `mix deps` shows `ex_doc` with `only: :dev` |
| Dep version constraints too tight | Package metadata audit phase | Audit each dep in `deps/0` for `~> x.y.z` three-part form |
| HEX_API_KEY leak / supply chain | Release workflow authoring phase | SHA-pinned actions; secret in `env:` block only |
| Conventional commit history accumulation | release-please config phase | `bootstrap-sha` set; first Release PR CHANGELOG is minimal |
| README rendering differences | README/hexdocs polish phase | `mix hex.build --unpack`; view README in non-GitHub renderer |
| `release-as` left in after publish | Post-publish cleanup phase | `grep "release-as" release-please-config.json` returns nothing |
| guides in extras but not in `:files` | Package metadata audit phase | Cross-check `docs/0` extras vs `:files` list |

---

## Sources

- hex.pm publish documentation: https://hex.pm/docs/publish
- mix hex.publish task docs: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html
- hex.pm FAQ (unpublish/retire windows): https://hex.pm/docs/faq
- Elixir library guidelines (dependency constraints, mix.lock): https://hexdocs.pm/elixir/library-guidelines.html
- release-please manifest releaser docs: https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md
- Elixir School release-please guide (existing repo bootstrap): https://elixirschool.com/blog/managing-releases-with-release-please
- release-please v4 `releases_created` footgun: https://danwakeem.medium.com/beware-the-release-please-v4-github-action-ee71ff9de151
- GitHub Actions SHA pinning: https://www.stepsecurity.io/blog/pinning-github-actions-for-enhanced-security-a-complete-guide
- bootstrap-elixir-hex-lib SKILL.md (oarlock first-publish post-mortem, 6 gotchas): `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md`
- Crosswake mix.exs current state: `/Users/jon/projects/crosswake/mix.exs`
- Crosswake release-readiness thread: `/Users/jon/projects/crosswake/.planning/threads/release-readiness.md`

---
*Pitfalls research for: v3.3 Release Readiness — first-time hex.pm publication of a mature Elixir library*
*Researched: 2026-05-27*
