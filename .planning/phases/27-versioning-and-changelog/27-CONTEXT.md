# Phase 27: Versioning Decision And CHANGELOG Synthesis - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Lock the first published hex version at `0.1.0` and produce a `CHANGELOG.md` whose shape release-please can parse and whose content honestly describes what 0.1.0 delivers. Concretely: verify `mix.exs` `@version` module attribute is `0.1.0`, synthesize `CHANGELOG.md` with Keep-a-Changelog format, an `[Unreleased]` anchor, a preamble disambiguating planning milestones from Hex releases, a single `[0.1.0]` entry with 4-5 capability bullets, a non-claims disclaimer, and a roadmap traceability footer, and finally, add `"CHANGELOG.md"` to the `docs/0` extras list in `mix.exs`.

Out of scope for this phase (belongs in later v3.3 phases): release-please config files (Phase 28), release workflows and supply-chain hardening (Phase 29), README absolute-URL audit and publish verification (Phase 30).
</domain>

<decisions>
## Implementation Decisions

### Pre-locked by REC-CHANGELOG.md (HIGH confidence, no re-litigation)

- **D-01:** **Keep-a-Changelog + `[Unreleased]` anchor.** `CHANGELOG.md` uses the KaC format and includes an `## [Unreleased]` anchor below the preamble and above the first versioned entry. This is required for release-please insertion logic.
- **D-02:** **Single `[0.1.0]` entry.** Do not create per-milestone headers (`v1.0`, `v3.2`). Synthesize the internal history into a single capability statement for `0.1.0`.
- **D-03:** **Preamble disambiguation.** Add a preamble explaining the difference between internal planning milestones (`v1.0` - `v3.2` in `MILESTONES.md`) and the public Hex semver releases (starting at `0.1.0`).
- **D-04:** **Roadmap traceability.** Add a `### Roadmap traceability` subsection within the `[0.1.0]` entry, linking to `.planning/MILESTONES.md` and `.planning/PROJECT.md`.
- **D-05:** **Explicit capability bullets.** The `[0.1.0]` entry must have 4-5 bullets describing actual runtime capabilities: route policy DSL, manifest + capability ladder, bounded bridge with v3.1 families, offline contracts, commerce + entitlement seams with reconciliation example.
- **D-06:** **Explicit non-claims.** Include a non-claim statement: "no provider adapters yet, no first-party companions yet".

### Pre-locked by Phase 26 (D-12)

- **D-07:** **Add `"CHANGELOG.md"` to `docs/0` extras.** Phase 26 deferred adding `CHANGELOG.md` to the `mix.exs` `docs/0` extras list. Phase 27 must add this line in the same commit that creates the file.

### First Publish Version

- **D-08:** `@version "0.1.0"`. `mix.exs` is already pinned to `"0.1.0"`. Leave it as is and confirm it compiles.

### Claude's Discretion

- **Date formatting:** Use the current date for the `[0.1.0]` release date if applicable, or leave a placeholder if preferred by the template.
- **Capability phrasing:** Adopt the bullet phrasing from the `REC-CHANGELOG.md` skeleton verbatim.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope And Phase Contract

- `.planning/ROADMAP.md` §"Phase 27: Versioning Decision And CHANGELOG Synthesis" — goal, depends-on, requirements list, and 4 success criteria.
- `.planning/REQUIREMENTS.md` §"B. Versioning And CHANGELOG Truth" — VER-01, LOG-01 through LOG-04.

### Research Inputs Used For Recommendations

- `.planning/research/REC-CHANGELOG.md` — HIGH confidence recommendation backing D-01 through D-06. Contains the complete recommended `CHANGELOG.md` skeleton.

### Established Patterns

- **Phase 26 D-12 (Phase-split)** — dictates that `"CHANGELOG.md"` gets added to `mix.exs` in this phase to keep the repository state atomic.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`@version "0.1.0"`** in `mix.exs:4` — already correct.
- **`defp docs do` extras list** in `mix.exs` — where `"CHANGELOG.md",` must be inserted.
- **`REC-CHANGELOG.md` Skeleton** — provides the exact Markdown template to be adapted.

### Integration Points

- **release-please insertion point:** The `## [Unreleased]` section is critical. If altered or omitted, Phase 28/29's release automation will fail to insert future release notes properly.
- **`docs/0` consumption:** Inserting `"CHANGELOG.md"` into the extras list ensures it is rendered on HexDocs, visible alongside the Guides and README.

</code_context>

<specifics>
## Specific Ideas

- **`CHANGELOG.md` Creation:** Copy the skeleton from `REC-CHANGELOG.md` verbatim, filling in `szTheory/crosswake` for GitHub URLs, today's date for the release date, and preserving all markdown structure strictly.
- **`mix.exs` Edit:** Add `"CHANGELOG.md",` directly to the `extras` list inside `mix.exs`, preserving existing indentation and trailing commas format.
- Verify `mix compile` succeeds and that `CHANGELOG.md` exists. Wait, running `mix docs` is deferred to Phase 30, so `mix compile` is sufficient here.

</specifics>

<deferred>
## Deferred Ideas

- **Machine-enforced CHANGELOG shape test** — deferred to v3.4 per `REC-CHANGELOG.md`.

</deferred>
