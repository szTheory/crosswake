# Recommendation: CHANGELOG Shape (v3.3 Category C)

## TL;DR

Use Keep-a-Changelog format with a `## [Unreleased]` anchor, a "planning milestones vs Hex releases" preamble, and a single `[0.1.0]` entry synthesizing the v1.0–v3.2 internal history. Do not create per-milestone CHANGELOG entries — planning labels are not Hex versions and exposing them as version headers will mislead adopters and confuse release-please's insertion logic. This shape is already the canonical szTheory house pattern (proven in oarlock and sigra), fully compatible with release-please's `\n###? v?[0-9[]` detection regex, and directly aligned with Crosswake's "release truth matters" and "narrow honest claims" anchors.

---

## Decisions Recommended

### Keep-a-Changelog + `[Unreleased]` anchor: YES

release-please inserts new entries by finding the first version header matching `\n###? v?[0-9[]` and prepending the new block above it. The `[Unreleased]` section placed _below_ the header block and _above_ the first versioned entry (`## 0.1.0 ...`) keeps that pipeline working. The `[Unreleased]` anchor also communicates to adopters that the lib is actively maintained and changes between releases will be visible before they land.

Evidence from house projects: both oarlock and sigra include `## [Unreleased]` sections. The bootstrap skill's canonical CHANGELOG template explicitly includes it. This is not an experiment — it is the established default.

### Single `[0.1.0]` entry from MILESTONES.md history: YES

The first Hex-published entry should synthesize the full internal history (v1.0 Route Policy Foundation through v3.2 Commerce and Entitlement Seams) into one cohesive surface: what the library does at 0.1.0 and why it can be trusted. This entry should describe _capabilities_ (route policy DSL, manifest, bridge contracts, capability families, commerce corridors, entitlement lifecycle), not re-narrate internal phase-by-phase work items. An adopter arriving at the Hex page needs "what does this library do and is it serious?" — not an internal changelog of 25 planning phases.

Lattice_stripe's `1.7.0` entry is instructive: it bundled four skipped-publish milestone tranches into one public release with a "Highlights" paragraph and milestone-inline subsections marked "_Not published separately to Hex_". That is the right instinct, but for Crosswake's first-ever Hex release the single entry should read as an initial capability statement, not a migration guide.

### Per-milestone CHANGELOG entries (`[v1.0]`, `[v2.0]`, `[v3.0]`, `[v3.1]`, `[v3.2]` as CHANGELOG headers): NO

This is the one clear mistake to avoid. Planning labels are _not_ Hex versions. Publishing them as CHANGELOG version headers would:

1. Mislead adopters into thinking they can install `crosswake ~> 3.2` or that `3.1` is a prior published release.
2. Confuse release-please: the `\n###? v?[0-9[]` regex would match `## v3.2`, `## v3.1`, etc., potentially placing the new `0.1.0` entry _after_ those headers rather than at the top.
3. Violate the "narrow honest claims" principle from crosswake-elixir-oss-dna.md — publishing version-shaped artifacts that cannot be installed is a premature claim.

The correct handling is to reference planning history in a `### Roadmap traceability` subsection _within_ the `[0.1.0]` entry (sigra pattern), or to mention it in the preamble. Not as parallel version headers.

### Machine-enforced CHANGELOG shape test in v3.3 scope: NO — defer to v3.4

v3.3's machine-enforcement budget is already committed to the graduated default of SUMMARY-frontmatter parity tests (WR-01, WR-02). Adding a CHANGELOG shape check in the same milestone creates two shape-gate surfaces that need to be co-designed. The right graduation path is:

1. Ship v3.3 with the CHANGELOG skeleton as a human-auditable artifact.
2. In v3.4 (or alongside the first `feat:` push), evaluate whether a CI check for `[Unreleased]` header presence, conventional-commit consistency, and no `v1.0`/`v2.0`/`v3.x` planning-label headers is worth the maintenance cost.

A lightweight ExUnit docs-contract test checking `## [Unreleased]` presence in CHANGELOG.md (similar to the sigra docs-truth pattern) is a candidate, but not required for first publish.

---

## Survey: How Successful Elixir OSS Libs Write CHANGELOGs

| Lib | Format | `[Unreleased]` anchor | First-entry style | Notes |
|---|---|---|---|---|
| Phoenix | Custom, no KaC headers | No | `## v1.8.0-rc.0` with "Enhancements / Bug fixes" | Oldest entry links to v1.7 branch |
| Ecto | Custom, `## vX.Y.Z (YYYY-MM-DD)` | No | Links to v2.2 branch | Sections: Enhancements / Bug fixes / Backwards incompatible changes |
| Plug | Custom | No | Links to v1.6 branch | Sections: Security / Bug fixes / Enhancements |
| Oban | Custom with narrative intro | No | Single `v2.23.0` shown | Emoji section headers; heavily narrative per release |
| LiveView | Custom | No | `v1.2.0-rc.0` links to v1.1 branch | Sections: Enhancements / Bug fixes |
| ex_doc | Custom, closest to KaC shape | No | `v0.5.0` — "First public release" (1 line) | Reverse-chrono, version + date, Enhancements / Bug fixes |
| telemetry | Keep-a-Changelog (explicit ref) | No (despite KaC claim) | `v0.1.0` — "First release of Telemetry library" (1 line) | Most honest minimal first entry in the survey |
| finch | Partial KaC | Yes (`## Unreleased` empty) | `v0.1.0 (2021-07-15)` — "Initial release" | Has `Unreleased` header; no brackets |
| req | Custom | Yes (`## Unreleased` empty) | `v0.1.0 (2021-07-15)` — "* Initial release" | Closest to house style; narrative major releases, bullet minor ones |
| Ash | Custom | No | `[v3.4.37]` (truncated) | Auto-generated via release-please; `### Features:` / `### Bug Fixes:` |
| Bandit | Custom | No | `0.6.5 (10 Jan 2023)` | Sections: Fixes / Changes / Enhancements |
| **oarlock** (house) | KaC + preamble | **Yes** | `0.1.0` — release-please generated Features + Bug Fixes list | Canonical house pattern; preamble disambiguates planning milestones |
| **sigra** (house) | KaC + preamble + roadmap traceability | **Yes** | `[0.1.0]` — BREAKING changes + Added | Per-release `### Roadmap traceability` subsection linking milestone files |
| **lattice_stripe** (house) | KaC + publishing note | **Yes** | `[1.7.0]` — bundled 1.4–1.7 tranches | Explicit "Milestone included in X.Y.Z. Not published separately." pattern |

**Key finding:** Large ecosystem libs (Phoenix, Ecto, Plug, Oban, LiveView) have evolved custom formats without `[Unreleased]` anchors because they predate release-please and Keep-a-Changelog conventions, and they manage releases manually. The libraries that use release-please automation (req, finch, Ash, and the entire szTheory house) converge on the `[Unreleased]` anchor. The szTheory house format adds the preamble disambiguation and roadmap traceability subsections — these are differentiating signals of correctness that adopters of a first-publish lib specifically need.

**The "first entry minimal" pattern:** telemetry, ex_doc, and finch all started with one line: "First release" or "Initial release." That is the correct instinct — no need to reproduce all internal history in bullet form. The `[0.1.0]` entry should be a readable capability statement (3-5 bullets or a paragraph), not a commit log.

---

## release-please Mechanical Requirements

### What release-please does to CHANGELOG.md

release-please uses this regex to find the insertion point:

```
\n###? v?[0-9[]
```

It matches an H2 or H3 header followed by an optional `v` and then either a digit or a `[`. It inserts the new version entry **above** the first match. This means:

1. Any existing `## [Unreleased]` section placed _above_ the first versioned entry is fine — release-please will match the versioned entry below it, not the `[Unreleased]` line.
2. Planning-milestone headers like `## v3.2` or `## v1.0` would match the regex and become insertion-point candidates. This is why per-milestone headers in the CHANGELOG must be avoided.
3. If CHANGELOG.md has no version headers, release-please prepends a `# Changelog` header and the new entry.

### What release-please produces

For each release, it generates:

```markdown
## [X.Y.Z](https://github.com/owner/repo/compare/vPREV...vX.Y.Z) (YYYY-MM-DD)


### Features

* **scope:** description ([commithash](url))

### Bug Fixes

* **scope:** description ([commithash](url))
```

Section headers used by the `conventional-commits` preset (which is what release-please-elixir uses):

| Conventional commit type | CHANGELOG section |
|---|---|
| `feat:` | `### Features` |
| `fix:` | `### Bug Fixes` |
| `perf:` | `### Performance Improvements` |
| `revert:` | `### Reverts` |
| `docs:` | omitted (not surfaced by default) |
| `chore:` | omitted |
| `style:` | omitted |
| `refactor:` | omitted |
| `test:` | omitted |
| `build:` | omitted |
| `BREAKING CHANGE:` footer | `### BREAKING CHANGES` |

### The `bootstrap-sha` gotcha for Crosswake

Crosswake has 25 phases of non-conventional commits that release-please will try to walk backwards unless anchored. The canonical fix (already documented in SUMMARY.md) is setting `bootstrap-sha` in `release-please-config.json` to the commit just before the first conventional-commit commit, preventing backwards walk. Without this, release-please explodes the initial `0.1.0` CHANGELOG entry with every internal commit it can parse.

The oarlock and sigra CHANGELOG first entries show what the auto-generated content looks like when release-please writes it: a flat list of every `feat:` and `fix:` commit that fell into the release window. For Crosswake, hand-crafting the `[0.1.0]` entry and using `bootstrap-sha` to stop the backwards walk is the correct approach.

---

## Recommended CHANGELOG.md Skeleton for v3.3

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v3.2** in **`.planning/MILESTONES.md`** — those labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`MILESTONES.md`** as canonical for milestone dates and archive paths.

## [Unreleased]

### Added

* Initial public release.

## [0.1.0] — 2026-MM-DD

### Added

* Route policy DSL for declaring per-route runtime ownership: LiveView, offline island, native screen, or adapter. Runtime manifest and compatibility contract generated from route policy declarations.
* Bounded bridge contract for low-frequency native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, `file_picker`) with route-local enforcement and typed command envelopes.
* Offline semantics: cached read-only routes, offline islands with append-only journals, sync endpoints, and server-authoritative reconciliation — each with explicit contract boundaries and doctor diagnostics.
* Commerce corridor declarations with provider-neutral `commerce.corridor.*` denial vocabulary, entitlement lifecycle lane semantics (authority/access/reconciliation/freshness/evidence), and a Phoenix-owned reconciliation inbox example. Provider adapters (StoreKit, Play Billing) are not included; this release operationalizes the seam contract only.
* `mix crosswake.doctor` diagnostics, support matrix, and proof lanes verified against three adopter-shaped exemplar lanes: Phoenix SaaS portal, selective-native flow, and local-first study flow.

### Roadmap traceability

Internal planning milestones v1.0 (Route Policy Foundation), v2.0 (Adopter Stress Profiles), v3.0 (Capability Contract And Packaging), v3.1 (Native Capabilities and Bridge Expansion), and v3.2 (Commerce And Entitlement Seams) are archived in `.planning/MILESTONES.md`. These are not separate Hex releases.

[Unreleased]: https://github.com/szTheory/crosswake/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/szTheory/crosswake/releases/tag/v0.1.0
```

**Notes on the skeleton:**

- Fill in `2026-MM-DD` with the actual publish date.
- Replace `szTheory/crosswake` with the confirmed GitHub repo URL.
- The `### Added` bullets in `[0.1.0]` are capability statements, not commit logs. They describe what an adopter gets, not what the planning phases contained.
- The `[Unreleased]` section at the top initially has "Initial public release." This is the seed content for release-please's first update pass after v3.3 ships. Release-please will replace it with the next release's entries.
- The comparison/tag links at the bottom are the Keep-a-Changelog link-definition convention. They make version headers clickable and are required for sigra/oarlock parity.
- Do NOT include a `### Summary` subsection (bootstrap skill gotcha #6: sigra-specific convention that breaks the release pipeline).

---

## Pros/Cons Table

| Approach | Pros | Cons |
|---|---|---|
| **Recommended: Single `[0.1.0]` + preamble + `[Unreleased]`** | Honest (no phantom versions), machine-compatible with release-please, matches house style, clear to adopters, tells the right story | Loses the narrative of individual milestone work (but `.planning/MILESTONES.md` is the right home for that) |
| Per-milestone entries (`[v1.0]`, `[v2.0]`, etc.) | Shows development depth | Misleads adopters about installable versions; breaks release-please insertion regex; violates narrow-claims principle |
| No `[Unreleased]` anchor | Slightly simpler initial file | Breaks the preamble signal; adoption diverges from house pattern; future release-please behavior less predictable |
| Pure release-please auto-write (no hand-crafted `[0.1.0]`) | Fully automated | Requires every commit since repo creation to be conventional-format; 25 phases of non-conventional commits produce noise or require extensive `bootstrap-sha` tuning |
| Copy a large lib's format (Ecto/Phoenix/Oban) | Looks like an established project | Those projects don't use release-please; their formats don't serve Crosswake's automation needs |

---

## Lessons from "Long-Backstory" First Releases

### 1. telemetry (BEAM ecosystem, 2018)

telemetry was developed internally at Erlang Solutions before going public. Its CHANGELOG first entry: `v0.1.0` — "First release of Telemetry library." That is one line. Zero backstory. The correctness signal came from the code quality and documentation, not the CHANGELOG. **Lesson:** When the backstory is internal, the right CHANGELOG move is a clean statement of initial capability, not a reconstruction of internal history.

### 2. req (Wojtek Mach, 2021)

req had active development before its 0.1.0 Hex publish. Its CHANGELOG has `## Unreleased` at the top and `v0.1.0 (2021-07-15) — * Initial release` as the first versioned entry. Exactly one line. **Lesson:** Even when a lib has months of pre-publish work, the first Hex CHANGELOG entry does not need to reconstruct that work. "Initial release" is honest and sufficient.

### 3. lattice_stripe (szTheory house, 2026)

lattice_stripe shipped milestones v1.4, v1.5, v1.6, and v1.7 without publishing to Hex, then bundled them into a single `1.7.0` Hex publish. The CHANGELOG has a top note: "Sections 1.4.0 through 1.6.0 below are milestone checkpoints shipped together in 1.7.0 — they were not published as separate Hex releases." Each interim milestone got a subsection labeled "_Milestone included in 1.7.0. Not published separately to Hex._" **Lesson:** The house pattern for bundled milestones is to explain the bundling explicitly in the entry, using inline milestone sections marked as non-published rather than fabricating version-separated histories. For Crosswake's first release, inline milestone sub-sections are optional since the MILESTONES.md reference at the bottom of the entry is cleaner than 5 inline sections.

### 4. Sigra (szTheory house, 2026)

Sigra published `0.1.0` as a packaging version before the first real Hex listing (0.2.0). The `[0.1.0]` entry has BREAKING changes and Added entries about what changed versus the pre-Hex packaging state. The preamble ("planning milestones labeled v1.0–v1.4 ... describe shipped tranches of work, not a second installable version axis") was written after the first release and added to `0.2.0` as the pattern solidified. **Lesson:** Write the preamble at 0.1.0, not later. Crosswake has the benefit of doing it right the first time.

---

## DX/UX Considerations

### What adopters actually scan for in a CHANGELOG on first visit

1. **"Is this maintained?"** — The `[Unreleased]` section signals ongoing activity. Even if empty, its presence says "we expect to put things here."
2. **"Can I trust the version?"** — A clean `0.1.0` entry with capability bullets and an honest scope disclaimer ("provider adapters not included") signals correctness discipline.
3. **"What does it actually do?"** — The 5-bullet capability summary in the recommended `[0.1.0]` entry answers this. Adopters skimming a CHANGELOG are pre-evaluating whether to add the dependency.
4. **"Are there breaking changes in my upgrade path?"** — On first install there is no upgrade path, but the `### BREAKING CHANGES` section in future entries handles this.
5. **"How long was this in development?"** — The roadmap traceability footnote and preamble answer this honestly without fabricating a release history.

### How the recommended skeleton serves adopter DX

- Preamble resolves the "what are all those v1.0/v3.2 references in GitHub?" confusion on first visit.
- Capability bullets in `[0.1.0]` front-load what the lib does and what it explicitly does not do (commerce providers deferred).
- The `### Roadmap traceability` subsection satisfies "show me the work" without inflating the version header count.
- The link-definitions at the bottom make `[Unreleased]` and `[0.1.0]` clickable, which is standard for adopters who read CHANGELOGs on GitHub.

---

## Coherence with Project Vision

### "Install truth is product truth"

The CHANGELOG at first install is part of the install truth surface. An adopter who runs `mix hex.info crosswake` or visits the Hex page will see the CHANGELOG. A CHANGELOG with phantom version headers (`v1.0`, `v3.2`) implies releases that don't exist on Hex, which is exactly the kind of misleading claim that the OSS DNA document warns against ("vague claims about what is production-ready," "letting marketing framing outrun architectural truth").

### "Release truth matters"

The preamble explicitly disambiguates planning labels from Hex releases. It is a release-truth statement in the CHANGELOG itself. This is not boilerplate — it is a direct expression of the project's commitment to release honesty.

### "Narrow honest claims"

The `[0.1.0]` capability bullets explicitly scope what shipped: the route policy DSL, bridge families, offline contracts, commerce seam contracts. They explicitly scope what did not ship: provider adapters, companion integrations. This matches the OSS DNA pattern of "optional surfaces are documented as optional" and "non-goals are written down."

### "Machine-enforced parity tests (graduated default from v3.2)"

The machine-enforcement question for CHANGELOG is deferred to v3.4 (see Decision 4 above). However, the preamble + `[Unreleased]` anchor is itself a machine-readable convention — release-please depends on it. The mechanical contract is already present; the question is whether to add an ExUnit test asserting it. That test would be cheap (regex match on `File.read!("CHANGELOG.md")`) and is a clear v3.4 graduation candidate.

### Brand voice ("write like a careful maintainer; prefer operational truth over hype")

The recommended entry opens with capability descriptions, not marketing claims. "Route policy DSL for declaring per-route runtime ownership" is an operational truth statement. "Commerce corridor declarations with provider-neutral denial vocabulary ... provider adapters not included" is an honest scope boundary. This matches the brand-book instruction: "Release notes: Transparent, changelog-first."

---

## Confidence

**HIGH**

Rationale:
- The mechanical release-please behavior is verified from source (`changelog.ts` regex `\n###? v?[0-9[]`), not docs.
- The house pattern (oarlock, sigra) is proven across two published Hex libs with release-please automation.
- The bootstrap skill's CHANGELOG template is the canonical starting point and already includes every element recommended here.
- The three scoping decisions map directly to the house style with zero experimental surface.
- The only judgment call is the wording of the `[0.1.0]` capability bullets, which can be refined during v3.3 execution without changing the structural decisions.

The one area with less than HIGH confidence: the exact `bootstrap-sha` anchor value needed to prevent release-please from walking back through 25 planning phases. That value must be determined at v3.3 execution time by identifying the first conventional-format commit in the repo history, but it does not affect the CHANGELOG shape decisions.
