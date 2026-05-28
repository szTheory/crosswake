# Phase 26: Package Metadata Audit - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `mix.exs` honestly point to the real GitHub repository and declare a complete `:package` block so the hex.pm page renders correctly for the first publish. Concretely: replace the placeholder `source_url`, add a `@source_url` module attribute, declare an explicit `:files` allowlist, set the three-link `:links` map, add a `LICENSE` file, wire a `docs/0` function plus the `ex_doc` dev dependency, and confirm `mix deps.get && mix compile` succeeds clean.

Out of scope for this phase (belongs in later v3.3 phases): CHANGELOG.md synthesis (Phase 27), `@version` already pinned at `0.1.0` (touched if needed but not re-decided), release-please config files (Phase 28), release workflows and supply-chain hardening (Phase 29), README absolute-URL audit and `mix hex.build --unpack` / `mix docs` / `mix hex.publish --dry-run` (Phase 30), GitHub permissions flip and the publish itself (Phase 31), and post-publish cleanup (Phase 32).

</domain>

<decisions>
## Implementation Decisions

### Pre-locked by REC-METADATA.md (HIGH confidence, no re-litigation)

- **D-01:** OMIT `:maintainers` from the `:package` block. Field is deprecated in the hex spec; hex.pm returns `maintainers: null` for every lib that sets it; ownership is surfaced via the hex.pm account "Owners" section (linked to the publishing account). Matches oarlock canonical szTheory template.
- **D-02:** INCLUDE `docs/0` function and `{:ex_doc, "~> 0.38", only: :dev, runtime: false}` on first publish. A hex page without hexdocs is a hard trust failure for a serious library; 13/13 sampled canonical libs ship docs on first release.
- **D-03:** Add explicit `name: "crosswake"` to the `:package` block (tarball-naming safety per `bootstrap-elixir-hex-lib` skill gotcha #2 — even though the OTP atom matches, this prevents future drift if the atom is ever renamed).
- **D-04:** Three-link `:links` map: `"Changelog"` → `#{@source_url}/blob/main/CHANGELOG.md`, `"Documentation"` → `https://hexdocs.pm/crosswake`, `"GitHub"` → `@source_url`. Order alphabetical so hex.pm sidebar renders deterministically.
- **D-05:** `:licenses ["Apache-2.0"]`. Apache-2.0 is the locked license for Crosswake; LICENSE file content must match this SPDX identifier exactly.
- **D-06:** Explicit `:files` allowlist (no defaults): `~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)`. Includes `priv/` (generator templates) and `guides/` (adopter docs). Excludes `.planning/`, `prompts/`, `test/`, `.github/`, `examples/`, `native/`. CHANGELOG.md is forward-referenced in `:files` per Phase 26 success criterion #2 — the file itself lands in Phase 27, but the allowlist line is added here so `:files` reaches its final shape in one commit.
- **D-07:** `docs/0` shape: `main: "readme"`, `source_ref: "v#{@version}"`, `source_url: @source_url`, `formatters: ["html"]`, plus the extras list (see D-13).
- **D-08:** Top-level `project/0` additions: `name: "crosswake"`, `source_url: @source_url`, `homepage_url: @source_url`, `package: package()`, `docs: docs()`.

### Repo URL (human-gated, SC #1)

- **D-09:** `@source_url "https://github.com/szTheory/crosswake"` — module attribute introduced and reused by `:links`, `:package`, and `docs/0`. The GitHub repo at this URL is confirmed to exist; SC #1's human-gate is satisfied at discuss time.

### LICENSE file content

- **D-10:** LICENSE file content is the canonical Apache-2.0 boilerplate with the copyright line set to `Copyright 2026 szTheory`. No deviation from the SPDX-published Apache-2.0 text (no custom appendix, no boilerplate stripping). Year is `2026` (current). Copyright holder string is the GitHub handle `szTheory`, matching the hex.pm Owners attribution and the rest of the szTheory OSS attribution surface.

### `:description` text (brand voice, hex page first impression)

- **D-11:** `:description` = `"Route policy and runtime contracts for Phoenix apps that go mobile."` (60 chars).
  - Synthesized choice (Candidate D in REC-PHASE-26-COHERENT.md). Rejects "substrate" jargon (Candidate A, no ecosystem precedent), rejects "targeting mobile deployments" corporate phrasing (Candidate B, +36 chars), rejects "Phoenix mobile apps" framing (Candidate C, implies the lib serves already-mobile apps rather than Phoenix apps adding mobile).
  - "Apps that go mobile" is the brand-book's own one-liner, verbatim.
  - Naming "runtime contracts" alongside "route policy" honors the two architectural pillars.
  - Matches the 50–70 char ecosystem median (Phoenix/Ecto/Plug/etc. canonical libs), noun-first, "for X" scoping, no hype words.

### `docs/0` extras scope (Phase 26 vs Phase 27 boundary)

- **D-12:** Choose **phase-split** for the `extras:` list. Phase 26 ships `docs/0` extras WITHOUT `CHANGELOG.md`. Phase 27 adds the `CHANGELOG.md` line to extras in the same commit that creates the file.
  - Forward-ref is rejected: listing a file in extras that doesn't exist on disk violates atomic-commit discipline — anyone checking out the Phase 26 commit and running `mix docs` would get a loud failure.
  - Stub-out is rejected: forces Phase 26 to own content (a placeholder CHANGELOG.md) that Phase 27 immediately rewrites, muddying the blame graph.
  - Phase-split preserves the szTheory canonical invariant (oarlock, sigra): file in extras = file on disk in the same commit. Phase 27's mix.exs diff is a single added line.

- **D-13:** Phase 26 `extras:` list (explicit, 13 entries — no globs):
  ```
  "README.md",
  "LICENSE",
  "guides/install.md",
  "guides/support_matrix.md",
  "guides/adopter_profiles.md",
  "guides/user_flows.md",
  "guides/capabilities.md",
  "guides/bridge.md",
  "guides/offline.md",
  "guides/commerce.md",
  "guides/compatibility.md",
  "guides/native_shell.md",
  "guides/packs.md"
  ```
  README.md is required by `main: "readme"`. LICENSE included as an extra (renders Apache-2.0 text on hexdocs as a navigable page). All 11 `guides/*.md` enumerated explicitly so adding/removing a guide is a deliberate diff.

- **D-14:** Use `groups_for_extras: [Guides: ~r/guides\//]` to group the 11 guide pages under a single "Guides" section in the hexdocs sidebar. README and LICENSE stay ungrouped (top-level).

### Verification posture for Phase 26

- **D-15:** Phase 26 success criterion #5 only requires `mix deps.get && mix compile` to succeed clean. `mix docs` and `mix hex.build --unpack` are intentionally deferred to Phase 30 (HEX-03 / HEX-02). Plan and execution should NOT add `mix docs` verification to Phase 26 — that creates a cross-phase coupling on CHANGELOG.md.

### Claude's Discretion

- Exact ordering of keys inside `project/0`, `package/0`, and `docs/0` (preserve readability; match REC-METADATA.md template ordering as the default).
- Whether to add `homepage_url: @source_url` alongside `source_url` (REC-METADATA.md includes it; harmless; default to yes).
- Whether to keep the existing single-line `defp description` helper or inline the description string (preference: keep the helper for parity with REC-METADATA.md template).
- Whether to alphabetize the `:links` map keys (default: yes, alphabetical).
- Exact formatting/wrapping of the long `extras:` list (default: one entry per line, no trailing commas inside Erlang/Elixir tuple literal).
- Whether to add a brief code comment near `:maintainers` placeholder to document why it's omitted (default: NO — comments rot; REC-METADATA.md is the durable rationale).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope And Phase Contract

- `.planning/ROADMAP.md` §"Phase 26: Package Metadata Audit" — goal, depends-on, requirements list, and 5 success criteria.
- `.planning/REQUIREMENTS.md` §"A. Package Metadata Truth" — META-01 through META-06 (the six requirements mapped to Phase 26 in the traceability table).
- `.planning/PROJECT.md` §"Current Milestone: v3.3 Release Readiness" — milestone goal and "install truth is product truth" framing.
- `.planning/MILESTONE-ARC.md` §"Release Readiness Baseline" — strategic-arc context for v3.3 (added 2026-05-27 as a blindspot amendment).
- `.planning/threads/release-readiness.md` — open thread with repo-grounded facts on current `mix.exs` state.

### Research Inputs Used For Recommendations

- `.planning/research/REC-METADATA.md` — HIGH confidence recommendation backing D-01 through D-08 and D-13. Contains the complete recommended `mix.exs` template (lines 166–263) which is the working blueprint for Phase 26 implementation.
- `.planning/research/REC-PHASE-26-COHERENT.md` — coherent recommendation backing D-11 (description text) and D-12 (extras scope).
- `.planning/research/REC-CHANGELOG.md` — informs the Phase 26/27 boundary (CHANGELOG synthesis is Phase 27, not Phase 26).
- `.planning/research/REC-VERSIONING.md` — confirms `@version "0.1.0"` is the correct first-publish version.
- `.planning/research/REC-PIPELINE.md` — informs why `source_ref: "v#{@version}"` matches release-please's tag format (downstream Phase 28-29).
- `.planning/research/PITFALLS.md` Pitfalls 1, 7, 8, 14 — files allowlist, source_url placeholder, missing docs/0, guides-in-extras-but-not-files silent footgun. Pitfall 14 is the inverse-failure case Phase-split (D-12) is designed to avoid.
- `.planning/research/SUMMARY.md` — v3.3 research overview confirming infra-only scope and sequencing constraint.

### Paved-Path Skill (Template Source)

- `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md` — canonical szTheory hex-lib bootstrap. Specifically: gotcha #2 (name field, backs D-03), Commit 2 mix.exs template (matches D-01 through D-08, D-13). Phase 26 is essentially executing this skill's Commit 2 step against an existing repo.

### Brand And House-Style Anchors (Voice For D-11)

- `prompts/crosswake-brand-book.md` §"first release checklist" + voice rules — "Keep the first release visually quiet, technical, and trustworthy" — backs the description choice (D-11) and the omission of marketing-y phrasing.
- `prompts/crosswake-elixir-oss-dna.md` §1 "install truth is product truth" and §4 "release truth matters" — the strategic frame for why every Phase 26 decision matters; backs the no-deferrals stance on metadata items.
- `README.md` — current public introduction; the `:description` should harmonize with its tone (which D-11 does: "apps that go mobile" matches the README opener "for apps that go mobile").

### Current Repo State (What Phase 26 Edits)

- `mix.exs:1-43` — current minimal `:package` block with placeholder GitHub URL (`github.com/example/crosswake`). Phase 26's primary edit target.
- `guides/*.md` — 11 existing guide files referenced in `docs/0` extras (D-13).
- (Phase 26 creates) `LICENSE` at repo root — does not currently exist.

### Reference Implementations (For "How Do Other szTheory Libs Do It")

- `/Users/jon/projects/oarlock/mix.exs` — canonical szTheory hex-lib mix.exs template. Match its `:package` and `docs/0` structure verbatim where applicable.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`@version "0.1.0"`** in `mix.exs:4` — already correct (locked in REC-VERSIONING for the v3.3 milestone; Phase 27 will verify the pin but Phase 26 does not change it).
- **`defp description`** helper in `mix.exs:33-35` — keep the helper pattern; update only the string content to D-11.
- **`defp package`** helper in `mix.exs:37-42` — extend, do not replace. Add `name`, `:files`, replace `:links` map, keep `:licenses`.
- **`guides/` directory** with 11 markdown files — all already exist; D-13's extras list maps 1:1 to existing files. Confirmed via `ls guides/`.
- **`priv/templates/`** directory — generator templates that must ship in the tarball (correctly included via the `priv` entry in D-06's `:files` allowlist).

### Established Patterns

- **Module-attribute-then-reuse pattern** — REC-METADATA.md and the bootstrap skill both use `@version` and `@source_url` module attributes referenced from multiple places. Phase 26 introduces `@source_url`; `@version` already follows this pattern.
- **Explicit `:files` allowlist** — Crosswake's repo layout (with `.planning/`, `prompts/`, `examples/`, `native/`, `test/`) makes the implicit-default `:files` unsafe. Explicit allowlist is the only way to guarantee internal directories never leak.

### Integration Points

- **`@source_url` attribute** flows to: `project/0` (`source_url`, `homepage_url`), `:package` `:links` (`"GitHub"` value), `docs/0` (`source_url`). One source of truth.
- **`@version` attribute** flows to: `project/0` (`version:`), `docs/0` (`source_ref: "v#{@version}"`). One source of truth.
- **`docs/0`** is consumed by: `mix docs` (Phase 30 HEX-03), the published hexdocs site, release-please's tag format (Phase 28 — `source_ref` must match the release-please tag prefix `v` which is the default).
- **`:files` allowlist** is consumed by: `mix hex.build` (Phase 30 HEX-02 verifies via `--unpack`), the published tarball, and indirectly by `:files`-vs-`docs/0`-extras consistency (every file referenced in extras must be in `:files` — Pitfall 14).

</code_context>

<specifics>
## Specific Ideas

- Use REC-METADATA.md's mix.exs template at lines 166–263 as the working blueprint. Apply D-11 (replace REC's description with the locked text) and D-13 (remove `"CHANGELOG.md"` from the extras list — Phase 27 adds it).
- Phase 26 commit should leave the repo in a state where `mix deps.get && mix compile` succeeds with zero warnings AND a future checkout of just-this-commit + `mix compile` is reproducible. (No reliance on a Phase 27 file existing.)
- LICENSE file: use the canonical Apache-2.0 boilerplate from `https://www.apache.org/licenses/LICENSE-2.0.txt` (or the SPDX-published copy). Replace only the `[yyyy]` and `[name of copyright owner]` placeholders with `2026` and `szTheory`. Do not strip the appendix or modify any clause.

</specifics>

<deferred>
## Deferred Ideas

- **Add `CHANGELOG.md` to `docs/0` extras** — defer to Phase 27 (the phase that creates CHANGELOG.md). Phase 27 plan must include the one-line `mix.exs` edit alongside CHANGELOG creation.
- **`mix docs` clean-run verification** — defer to Phase 30 (HEX-03 explicitly verifies this). Phase 26 must NOT add `mix docs` to its verification gates.
- **`mix hex.build --unpack` tarball content audit** — defer to Phase 30 (HEX-02).
- **README absolute-URL audit** — defer to Phase 30 (HEX-01).
- **Switching `"Changelog"` link from GitHub raw to `https://hexdocs.pm/crosswake/changelog.html`** — Phoenix/LiveView use the hexdocs-hosted form which is a slightly cleaner UX. This is only possible after first publish (hexdocs URL must exist). Possible post-v3.3 polish; not blocking.
- **Sharpening `:description` after adopter feedback** — D-11 is a first-publish choice. After v3.3 ships and adopter signals come in, description can be re-tuned on any subsequent release.

</deferred>

---

*Phase: 26-Package Metadata Audit*
*Context gathered: 2026-05-27*
