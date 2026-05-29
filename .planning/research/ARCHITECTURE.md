# Architecture Research

**Domain:** Hex.pm publication infrastructure — v3.3 Release Readiness
**Researched:** 2026-05-27
**Confidence:** HIGH (all findings grounded in existing repo artifacts, skill SKILL.md, and PROJECT.md)

---

## System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          COMPONENT CLASSIFICATION                         │
├────────────────────────┬─────────────────────────┬───────────────────────┤
│       UNCHANGED        │        MODIFIED          │          NEW          │
│                        │                          │                       │
│  lib/                  │  mix.exs                 │  CHANGELOG.md         │
│  test/                 │    @source_url (real)    │  release-please-      │
│  examples/             │    package/0 block       │    config.json        │
│  guides/               │    docs/0 added          │  .release-please-     │
│  priv/                 │  README.md               │    manifest.json      │
│  script/               │    hex-page render       │  .github/workflows/   │
│  .github/workflows/    │    source_url links      │    release-please.yml │
│    phase5-proof.yml    │  guides/install.md       │  .github/workflows/   │
│    phase10-proof.yml   │    real install snippet  │    hex-publish.yml    │
│    phase18-proof.yml   │  .gitignore additions    │  HEX_API_KEY secret   │
│    phase23-proof.yml   │  Possibly: doctor        │                       │
│  .planning/            │    install-truth check   │                       │
└────────────────────────┴─────────────────────────┴───────────────────────┘
```

---

## Component Responsibilities

| Component | Responsibility | Status |
|-----------|----------------|--------|
| `mix.exs` `:package` block | Declares Hex package name, licenses, links (Source/Docs/Changelog), files allowlist | Modified — `:maintainers`, `:links` Changelog entry, `name:`, `docs:` all missing |
| `mix.exs` `@source_url` | Canonical repo URL used in docs source links and hex page | Modified — currently `github.com/example/crosswake` placeholder |
| `mix.exs` `docs/0` | Configures ExDoc: `main:`, `source_ref:`, `formatters:`, `extras:` (guides + CHANGELOG) | New function — entirely absent today |
| `CHANGELOG.md` | Keep-a-Changelog format; synthesis from MILESTONES.md history; release-please appends entries on each release | New file — does not exist |
| `release-please-config.json` | Declares `release-type: elixir`, bump strategy, `changelog-path`, one-time `release-as:` pin | New file |
| `.release-please-manifest.json` | Baselines current version at `0.0.0` so release-please knows first release is the next bump | New file — MUST be `0.0.0`, not the current mix.exs version |
| `.github/workflows/release-please.yml` | Listens for merged commits, opens Release PR with CHANGELOG diff and version bump, on merge creates tag, triggers `publish-hex` | New workflow |
| `.github/workflows/hex-publish.yml` | Manual recovery workflow; dispatches hex publish for a specific tag if release-please auto-publish stalls | New workflow |
| `HEX_API_KEY` GitHub secret | Authorizes `mix hex.publish` in CI | New secret — human step, not automated |
| `README.md` | Hex page renders from README; must have correct `source_url`-relative links and render cleanly on hex.pm | Modified — relative links need audit for hex.pm package page |
| `guides/install.md` | Canonical install guide; should reference `{:crosswake, "~> X.Y"}` with the real published version | Modified |
| `doctor` diagnostics | Surfaces install-truth check — "is a published version available?" | Possibly modified — see Doctor/Install Truth section |

---

## Integration Points with Existing CI Lanes

### Existing Workflows (All Unchanged)

| Workflow | Trigger | Lane Type | Gate Status |
|----------|---------|-----------|-------------|
| `phase5-proof.yml` | PR, push main | Hermetic | Merge-blocking |
| `phase10-proof.yml` | PR, push main | Hermetic | Merge-blocking |
| `phase18-proof.yml` | PR, push main | Hermetic | Merge-blocking |
| `phase23-proof.yml` merge-blocking-commerce-proof job | PR, push main, dispatch | Hermetic | Merge-blocking |
| `phase23-proof.yml` advisory-commerce-proof job | Schedule (Mon 06:00 UTC), dispatch | Advisory | Never gates merge (`continue-on-error: true`) |

### New Workflows and Their Relationship to Existing Lanes

**`release-please.yml`** operates on a different event axis than the proof lanes:

- Triggers on: `push` to `main` (after PR merge), `workflow_dispatch`
- The `release-please` job runs on every push to main — it opens or updates a Release PR
- The `publish-hex` job runs ONLY when release-please creates a GitHub release (i.e., after the Release PR is merged) — it is `needs: release-please` gated
- This workflow does NOT interact with branch protection for any proof lane. The existing merge-blocking hermetic jobs (phase5/10/18/23) must still pass before any PR (including the Release PR opened by release-please) can merge. **The Release PR itself goes through the same merge gate as any other PR** — this is by design.

**`hex-publish.yml`** (manual recovery):

- Trigger: `workflow_dispatch` only with `tag` and `release_version` inputs
- No interaction with proof lanes — it runs `mix test` internally to verify before publishing
- No `sync-release-summary` step (gotcha #6 — that is sigra-specific and would block publish)

**Advisory lane for publish path** (if needed):

Per the hermetic-vs-advisory graduation default (PROJECT.md Key Decisions, 2026-05-27), any environment-sensitive publish proof — e.g., a live hex.pm API availability check, or a smoke-test that `mix deps.get crosswake` resolves — should follow the advisory pattern: schedule/dispatch only, `continue-on-error: true`, never in the merge gate. This is analogous to how `advisory-commerce-proof` handles storefront/device checks.

---

## Build Order (Dependency Sequence)

This is the correct sequencing for roadmap phase ordering. Each step depends on the previous.

**Step 1: Package Metadata Audit**
- Check hex.pm/api/packages/crosswake for name availability (gotcha #1)
- Replace `@source_url` placeholder with real GitHub URL (`szTheory/crosswake`)
- Add `name: "crosswake"` to `package/0` — explicit OTP atom match (gotcha #2 prevention)
- Expand `links:` to include Source, Docs, Changelog entries
- Finalize files allowlist: `lib/`, `priv/`, `guides/`, `mix.exs`, `README.md`, `LICENSE`, `CHANGELOG.md`
- Review `:description` string for hex page rendering
- mix.exs must be clean before CHANGELOG or release-please can reference it

**Step 2: Versioning Decision**
- 0.1.0 (pre-release signal) vs 1.0.0-rc.0 (contract-mature signal) — decision drives the `release-as:` pin
- Document rationale in CHANGELOG.md Unreleased section
- This decision is a prerequisite for both CHANGELOG draft and release-please config

**Step 3: CHANGELOG.md Draft**
- Synthesize from MILESTONES.md v1.0 through v3.2 history
- Use Keep-a-Changelog format with `[Unreleased]` heading
- Include planning-milestones-vs-hex-releases bridge note (all prior milestone work folds into the first 0.1.0 entry)
- Do NOT include `### Summary` subsection — that is sigra-specific and breaks the release pipeline (gotcha #6)
- This file must exist before `release-please-config.json` can reference `changelog-path`

**Step 4: release-please Config**
- `release-please-config.json`: `release-type: elixir`, bump strategy, `changelog-path: CHANGELOG.md`
- `.release-please-manifest.json`: baseline at `0.0.0` — NOT the current mix.exs version (gotcha #4)
- Include one-time `release-as:` pin matching Step 2 version decision (gotcha #5)
- CHANGELOG.md must exist first (Step 3 dependency)

**Step 5: Release Workflow**
- `.github/workflows/release-please.yml` — use oarlock template, not sigra (gotcha #6)
- `.github/workflows/hex-publish.yml` — manual recovery
- Wire `publish-hex needs: release-please` only — no `sync-release-summary` job
- GitHub Actions permissions: `default_workflow_permissions=write`, `can_approve_pull_request_reviews=true` (gotcha #3 — must be set immediately after push)

**Step 6: `mix hex.build` Dry Run and Content Audit**
- Run `mix hex.build` locally — verify tarball is named `crosswake-X.Y.Z.tar` (not the OTP atom form)
- Verify files allowlist is complete and correct
- Clean up tarball after verification

**Step 7: ExDoc / Hexdocs Polish**
- Add `defp docs/0` to mix.exs: `main: "readme"`, `source_ref: "v#{@version}"`, `formatters: ["html"]`
- `extras:` list must include `README.md` + `CHANGELOG.md` + guides
- Run `mix docs` locally to verify hexdocs rendering
- README.md render audit — relative links in README render as ExDoc extras links on hexdocs.pm; on the raw hex.pm package page they should use absolute GitHub URLs

**Step 8: HEX_API_KEY Secret (Human Step)**
- Visit hex.pm/dashboard/keys → Generate key named `crosswake-ci` with write permissions
- `gh secret set HEX_API_KEY --repo szTheory/crosswake`
- Cannot be automated — hex.pm key generation is a human browser action
- Verify with `gh secret list --repo szTheory/crosswake`

**Step 9: Release-Please Bootstrap and First Publish**
- Push all above commits to main
- Wait for release-please to open Release PR
- Verify PR proposes the correct version matching the `release-as:` pin (gotcha #5 check)
- Confirm HEX_API_KEY secret is set before merging
- Merge Release PR — triggers `publish-hex` job — verify hex.pm has the release

**Step 10: Post-Publish Cleanup and Proof**
- Remove `release-as:` pin from `release-please-config.json` (gotcha #5 follow-up — if forgotten, future releases will all be pinned)
- Smoke-test: `mix new scratch`, add `{:crosswake, "~> X.Y"}`, `mix deps.get`, `mix compile`
- Verify hexdocs.pm/crosswake/X.Y.Z/ resolves
- Update `guides/install.md` with real `{:crosswake, "~> X.Y"}` snippet
- Doctor install-truth check (if in scope — comes last because hex version must be live first)

---

## Architectural Patterns

### Pattern 1: release-please as the Single Version Authority

**What:** release-please reads conventional commits on `main`, maintains `.release-please-manifest.json` as the version ledger, opens a Release PR with a CHANGELOG diff, and on merge creates the GitHub release and tag that triggers `publish-hex`. No human manually edits `mix.exs` version or CHANGELOG after bootstrap.

**When to use:** After the initial bootstrap. First release requires the one-time `release-as:` pin; subsequent releases are fully automated.

**Trade-offs:** Requires conventional commit discipline (`feat:`, `fix:`, `chore:`, `BREAKING CHANGE:`). The Release PR is a normal PR that goes through all existing merge gates — this is a feature. Misuse of the pin (leaving `release-as:` in config permanently) blocks all future version bumps.

**Key config:**
```json
{
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

Manifest baseline (CRITICAL — gotcha #4):
```json
{ ".": "0.0.0" }
```

### Pattern 2: Hermetic-vs-Advisory Split Applied to Publish Path

**What:** Any environment-sensitive publish-path proof follows the same two-job split established in `phase23-proof.yml`. A dry-run `mix hex.build` is hermetic and can be merge-blocking. A live hex.pm API probe or consumer-side `mix deps.get` smoke test is advisory: schedule/dispatch only, `continue-on-error: true`, never in the merge gate.

**When to use:** If the roadmap includes a CI step that checks "is this version live on hex.pm?" — that check is advisory. Matches how provider simulators are not in the commerce merge gate.

**Trade-offs:** Keeps PRs fast and honest. Advisory lane results are visible in CI dashboard without blocking merges. Promotion to merge-blocking requires the 4-condition promotion path documented in `phase23-proof.yml`.

### Pattern 3: CHANGELOG.md as One-Time Synthesis, Then release-please Owned

**What:** CHANGELOG.md is seeded once from MILESTONES.md history (v1.0 through v3.2), then owned by release-please going forward. The no-divergence rule: MILESTONES.md tracks planning milestone labels (v1.0, v2.0, v3.1, v3.2) which are NOT hex version numbers. CHANGELOG.md tracks hex release versions (0.1.0, 0.2.0, etc.). These are parallel axes.

**When to use:** From the very first CHANGELOG.md commit. The planning-milestones-vs-hex-releases bridge note (from skill template) documents this split explicitly inside CHANGELOG.md itself.

**Prevents:** The divergence trap where a maintainer tries to map hex versions to planning milestone labels. v3.2 as a hex release would imply v1.x and v2.x were also published hex releases — they were not. The first hex release is 0.1.0 (or whichever version is decided) regardless of planning milestone history.

---

## CHANGELOG Synthesis: No-Divergence Rule

The MILESTONES.md history spans planning milestones v1.0 through v3.2. CHANGELOG.md must NOT attempt to map these to hex version numbers (which would imply prior hex releases existed). The correct synthesis pattern:

```markdown
## [Unreleased]

### Added

* Initial public release — incorporates all work from planning milestones
  v1.0 (Route Policy Foundation) through v3.2 (Commerce And Entitlement Seams).
  See .planning/MILESTONES.md for the full milestone history.
```

Release-please then appends a `## [0.1.0] - YYYY-MM-DD` section when the first Release PR merges. All prior work is credited in the Unreleased → 0.1.0 entry. This is honest: there was one published release event, and it contains everything built before it.

The planning-milestones-vs-hex-releases bridge note near the top of CHANGELOG.md documents this explicitly for future readers and prevents future maintainers from treating planning milestone labels as hex version axes.

---

## Doctor / Install Truth Surface

**Current state:** `mix crosswake.doctor` surfaces commerce support truth, capability prerequisites, support matrix, and CI promotion paths. It does NOT currently surface anything about hex publication status or install-path truth.

**v3.3 scope decision:** Whether to add a doctor check for "is the published version available on hex.pm?" is an explicit scope call for the roadmap. It aligns with the "install truth is product truth" house-style anchor (PROJECT.md, Context from OSS DNA). The `bootstrap-elixir-hex-lib` skill does not extend doctor, but the anchor makes it a natural v3.3 surface.

**If in scope — recommended architecture:**

A new check in the existing doctor pipeline that probes the hex.pm API only when an explicit flag is passed:

```
mix crosswake.doctor --router YourAppWeb.Router --check-publish
```

Doctor output section:

```
install truth:
  hex.pm package: crosswake
  current version: 0.1.0
  source_url: https://github.com/szTheory/crosswake
  hex.pm status: (run with --check-publish to probe live)
```

The check is advisory-flagged internally — it makes a network call and reports the result without making the entire local doctor run network-dependent. This is analogous to how the advisory CI lane documents provider-adapter truth without blocking merges.

**Phase ordering implication:** Doctor install-truth extension (if in scope) comes AFTER hex publish is verified live at Step 10. You cannot probe a version that has not been published. This is a Step 10+ addition, not a prerequisite for publication.

---

## mix.exs Modifications: Current vs Required

**Current state (abridged):**
```elixir
@version "0.1.0"

def project do
  [app: :crosswake, version: @version, ..., description: description(), package: package()]
end

defp package do
  [
    licenses: ["Apache-2.0"],
    links: %{"GitHub" => "https://github.com/example/crosswake"}
  ]
end
```

**Required additions for v3.3:**
- Add `@source_url "https://github.com/szTheory/crosswake"` module attribute (real URL)
- Add to `project/0`: `name: "crosswake"`, `source_url: @source_url`, `homepage_url: @source_url`, `docs: docs()`
- Expand `package/0`: add `name: "crosswake"` (gotcha #2), expand `links:` to include Docs and Changelog entries, add `files:` allowlist
- Add new `defp docs/0`: `main: "readme"`, `source_ref: "v#{@version}"`, `source_url: @source_url`, `formatters: ["html"]`, `extras:` list

**Files allowlist:** `~w(lib priv guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)`
- `priv/` is included — `priv/templates/` exists
- `guides/` is included — 11 guide files should render as ExDoc extras
- Do NOT include `test/`, `examples/`, `script/`, `.planning/`, or `prompts/` — these are not for consumers

---

## README Hex-Page Render Considerations

**Current README links (all relative):** e.g., `[guides/user_flows.md](guides/user_flows.md)`. These render correctly as ExDoc extras links on hexdocs.pm IF guides are included in `extras:`. On the raw hex.pm package page (not hexdocs), relative links may 404 because the hex.pm package page renders README as-is without resolving relative paths.

**Recommendation:** README links to guides should use absolute GitHub URLs for the hex.pm package page, OR the README should note that full documentation is available at hexdocs.pm. Required audit: `mix hex.build` + `mix docs` dry run to verify rendering before first publish.

**The existing `script/verify_phase5_example_hosts.sh` is NOT relevant to hex page render verification** — that verifies example hosts, not package page rendering.

---

## New vs Modified vs Unchanged Components (Summary Table)

### New Components

| Component | Path | Purpose |
|-----------|------|---------|
| CHANGELOG.md | `/CHANGELOG.md` | Keep-a-Changelog; seeded from MILESTONES.md; owned by release-please after bootstrap |
| release-please config | `/release-please-config.json` | Declares elixir release-type, bump strategy, one-time release-as pin |
| release-please manifest | `/.release-please-manifest.json` | Baselines at 0.0.0 (gotcha #4 prevention) |
| Release workflow | `/.github/workflows/release-please.yml` | Opens Release PR → on merge creates tag → triggers hex publish |
| Recovery workflow | `/.github/workflows/hex-publish.yml` | Manual dispatch fallback for stalled publish |
| HEX_API_KEY secret | GitHub repo settings | Authorizes mix hex.publish in CI — human step |

### Modified Components

| Component | What Changes |
|-----------|-------------|
| `mix.exs` | `@source_url` real URL; `name:`, `homepage_url:`, `source_url:`, `docs:` in project/0; expanded `package/0` with `name:`, full `links:`, `files:` allowlist; new `defp docs/0` |
| `README.md` | Relative link audit for hex-page render; hex badge and install snippet; version reference |
| `guides/install.md` | Real `{:crosswake, "~> X.Y"}` mix.exs snippet once version decided |
| `.gitignore` | Append `crosswake-*.tar` and `crosswake-*.tar` patterns — prevent hex build artifacts from being committed |

### Unchanged Components

| Component | Why Unchanged |
|-----------|--------------|
| `lib/` | No behavioral changes in v3.3 |
| `test/` | No new tests unless doctor install-truth check added |
| `examples/phoenix_host/` | Proof artifact — not part of hex tarball |
| `script/` | Internal verification scripts |
| `.github/workflows/phase5-proof.yml` | Existing hermetic merge gate |
| `.github/workflows/phase10-proof.yml` | Existing hermetic merge gate |
| `.github/workflows/phase18-proof.yml` | Existing hermetic merge gate |
| `.github/workflows/phase23-proof.yml` | Two-job hermetic+advisory commerce gate |
| `.planning/` | Internal planning artifacts — not in hex tarball |
| `priv/templates/` | Included in hex tarball via files allowlist — no content changes needed |

---

## Gotcha Map for Roadmap Phases

| Gotcha | Risk | Prevention Phase |
|--------|------|-----------------|
| #1 — Hex package name collision | `crosswake` may be taken on hex.pm | Step 1 — check hex.pm/api/packages/crosswake before any mix.exs edit |
| #2 — Tarball named by OTP atom | `mix hex.build` produces `:crosswake`-named tarball if `name:` is absent from `package/0` | Step 1 (add `name: "crosswake"`) + Step 6 (dry run verifies tarball name) |
| #3 — GitHub Actions can't create PRs | release-please fails to open Release PRs | Step 5 — set `default_workflow_permissions=write` immediately after first push |
| #4 — Manifest off-by-one | `.release-please-manifest.json` set to `0.1.0` means release-please thinks 0.1.0 is already released and bumps to 0.1.1 | Step 4 — baseline manifest at `0.0.0` |
| #5 — First release jumps to 1.0.0 | Accumulated `feat:` commits cause release-please to propose 1.0.0 on first run | Step 4 (add `release-as:` pin) + Step 9 (verify PR proposes correct version) + Step 10 (remove pin after publish) |
| #6 — sync_release_summary.sh (sigra-specific) | Copying release-please.yml from sigra brings in a job that greps CHANGELOG for `### Summary` subsections and exits 1 if absent | Step 5 — use oarlock template, not sigra; no `sync-release-summary` job |

---

## Data Flow: Release Pipeline

```
Developer pushes feat:/fix: commit to main (after PR merges through existing gates)
         |
         v
release-please.yml (push to main trigger)
         |
         v
release-please job: reads CHANGELOG.md + .release-please-manifest.json
  → opens / updates Release PR with version bump + CHANGELOG entry
         |
         v
Release PR goes through existing merge gates (all hermetic, unchanged):
  phase5-proof (hermetic) must pass
  phase10-proof (hermetic) must pass
  phase18-proof (hermetic) must pass
  phase23-proof merge-blocking-commerce-proof (hermetic) must pass
         |
         v
Maintainer merges Release PR
         |
         v
release-please creates GitHub Release + tag vX.Y.Z
         |
         v
publish-hex job (needs: release-please):
  mix deps.get
  mix test
  mix hex.publish --yes  (uses HEX_API_KEY secret)
  verify: curl https://hex.pm/api/packages/crosswake/releases/X.Y.Z
         |
         v
Advisory probe (optional, schedule/dispatch, continue-on-error: true):
  consumer smoke-test: mix new scratch, add dep, mix deps.get, mix compile
  hexdocs.pm/crosswake/X.Y.Z/ resolves
```

---

## Sources

- `/Users/jon/projects/crosswake/mix.exs` — current package metadata baseline
- `/Users/jon/projects/crosswake/.planning/PROJECT.md` — Key Decisions table, v3.3 target features
- `/Users/jon/projects/crosswake/.planning/threads/release-readiness.md` — open investigation, repo-grounded facts
- `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md` — canonical paved-path skill with gotcha catalog
- `/Users/jon/projects/crosswake/.github/workflows/phase23-proof.yml` — hermetic-vs-advisory CI split reference implementation
- `/Users/jon/projects/crosswake/README.md` — current README structure and relative link baseline

---

*Architecture research for: Crosswake v3.3 Release Readiness — hex.pm publication infrastructure*
*Researched: 2026-05-27*
