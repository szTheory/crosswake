# Phase 26: Package Metadata Audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `26-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 26-Package Metadata Audit
**Areas discussed:** Confirm @source_url repo URL, LICENSE copyright holder, Description text, docs/0 extras scope vs Phase 27

---

## Confirm @source_url repo URL

Phase 26 success criterion #1 is human-gated on the real GitHub repo URL. The placeholder `https://github.com/example/crosswake` currently in `mix.exs:37-42` must be replaced with the real URL.

| Option | Description | Selected |
|--------|-------------|----------|
| szTheory/crosswake exists | The GitHub repo at https://github.com/szTheory/crosswake already exists and is the canonical source. Use that URL for @source_url, :links GitHub, and docs/0 source_url. | ✓ |
| Different org/name | The real repo is at a different URL. | |
| Repo not created yet | Maintainer needs to create the repo before this phase can execute. | |

**User's choice:** szTheory/crosswake exists.
**Notes:** Git user is `szTheory` (confirmed from environment); SC #1's human gate is satisfied at discuss time. The `@source_url` module attribute will be set to `"https://github.com/szTheory/crosswake"` and reused by `:links`, top-level `project/0` `source_url`/`homepage_url`, and `docs/0` `source_url`.

---

## LICENSE copyright holder

Apache-2.0 LICENSE needs a `Copyright [year] [name]` line that ships permanently in the published tarball.

| Option | Description | Selected |
|--------|-------------|----------|
| szTheory | `Copyright 2026 szTheory` — matches GitHub handle and hex.pm Owners account. | ✓ |
| Crosswake authors | `Copyright 2026 Crosswake authors` — community-style; future contributors implicitly covered. | |
| Real name | Maintainer's real legal name for clear copyright attribution. | |

**User's choice:** szTheory.
**Notes:** Consistent with the rest of the szTheory OSS attribution surface and the hex.pm Owners account auto-attribution. License year is the current year (2026).

---

## Description text

Hex.pm package header tagline. Visible on every search result and the package page header.

This decision was deferred to a research-then-recommend subagent dispatch (per the user's saved feedback pattern for coupled gray areas). The subagent considered the three initial candidates plus surveyed canonical Elixir libs and brand-book voice, and synthesized a fourth candidate.

| Option | Description | Selected |
|--------|-------------|----------|
| A. Keep current | "Phoenix-first route policy and runtime contract substrate" (57 chars). Compact, technical, but "substrate" is jargon with no ecosystem precedent. | |
| B. REC-METADATA recommendation | "Route policy and runtime contract layer for Phoenix applications targeting mobile deployments." (95 chars). Surfaces mobile but uses corporate phrasing. | |
| C. Hybrid sharp-and-short | "Route policy and runtime contracts for Phoenix mobile apps." (59 chars). Implies the lib serves already-mobile apps rather than Phoenix apps adding mobile. | |
| D. Synthesized (subagent recommendation) | "Route policy and runtime contracts for Phoenix apps that go mobile." (60 chars). Brand-book's own one-liner verbatim ("apps that go mobile"); honors both architectural pillars (route policy + runtime contracts); matches the 50–70 char ecosystem median. | ✓ |

**User's choice:** D — Lock both as recommended.
**Notes:** Subagent confidence HIGH. Full rationale captured in `.planning/research/REC-PHASE-26-COHERENT.md`. The description harmonizes with the existing README opener "for apps that go mobile."

---

## docs/0 extras scope vs Phase 27

REC-METADATA's mix.exs template includes `CHANGELOG.md` in the `docs/0` extras list, but `CHANGELOG.md` does not exist on disk until Phase 27 creates it. Three implementation options.

This decision was also deferred to the research-then-recommend subagent dispatch alongside the description text decision (coupled — both land in the same Phase 26 mix.exs commit and must be mutually consistent).

| Option | Description | Selected |
|--------|-------------|----------|
| Forward-ref | Include CHANGELOG.md in extras at Phase 26. `mix docs` would fail at Phase 26 commit state (file missing) but Phase 26 SC #5 only requires `mix compile`. | |
| Phase-split | Leave CHANGELOG.md out of extras at Phase 26. Phase 27 adds the one-line edit when it creates the file. Preserves szTheory canonical invariant (file-in-extras = file-on-disk in the same commit, confirmed against oarlock/sigra). | ✓ |
| Stub-out | Create a placeholder CHANGELOG.md at Phase 26 just so extras + files are valid. Phase 27 rewrites the stub. Muddies the blame graph. | |

**User's choice:** Phase-split — Lock both as recommended.
**Notes:** Subagent confidence HIGH. Forward-ref rejected for violating atomic-commit discipline (Phase 26 checkout state should be self-consistent). Stub-out rejected for ownership-muddying (Phase 26 owns content it doesn't conceptually own). Phase 26's extras list will be README + LICENSE + 11 guides (13 entries). Phase 27 plan must include the one-line mix.exs edit to add CHANGELOG.md to extras in the same commit that creates the file.

---

## Claude's Discretion

- Exact ordering of keys inside `project/0`, `package/0`, and `docs/0` (default: match REC-METADATA.md template ordering).
- Whether to add `homepage_url: @source_url` alongside `source_url` (REC includes it; default: yes).
- Whether to keep the `defp description` helper vs inline the string (default: keep helper for parity with REC-METADATA template).
- Whether to alphabetize the `:links` map keys (default: yes).
- Exact formatting of the long `extras:` list (default: one entry per line).
- Comments near omitted `:maintainers` (default: NO — comments rot, REC-METADATA.md is the durable rationale).

## Deferred Ideas

- Add `CHANGELOG.md` to `docs/0` extras → Phase 27.
- `mix docs` clean-run verification → Phase 30 (HEX-03).
- `mix hex.build --unpack` tarball content audit → Phase 30 (HEX-02).
- README absolute-URL audit → Phase 30 (HEX-01).
- Switch `"Changelog"` link from GitHub raw to hexdocs-hosted (only possible after first publish) → post-v3.3 polish.
- Sharpen `:description` based on adopter feedback → post-v3.3 release.
