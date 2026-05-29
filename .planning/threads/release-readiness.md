---
slug: release-readiness
title: Hex.pm publication path + release infrastructure (v3.3 candidate)
status: done
created: 2026-05-27
updated: 2026-05-29
resolution: Shipped as v3.3 Release Readiness — crosswake 0.1.0 live on hex.pm (2026-05-29).
---

# Thread: Release readiness — hex.pm publication

## Goal

Make Crosswake installable from hex.pm with honest release metadata, CHANGELOG, and source_url. This baseline was missing from the original strategic arc (`.planning/MILESTONE-ARC.md`) and was flagged 2026-05-27 during the post-v3.2 milestone-next-step assessment.

This thread tracks the open investigation for the recommended **v3.3 = Release Readiness** milestone.

## Context

*Created 2026-05-27 after v3.2 (Commerce And Entitlement Seams) shipped.*

Repo-grounded facts:

- `mix.exs:4` — `version: "0.1.0"` hardcoded.
- `mix.exs:37-42` — `source_url: "https://github.com/example/crosswake"` is a placeholder; real GitHub repo URL not yet set.
- No `CHANGELOG.md` at repo root.
- No `.release-please-manifest.json` / `release-please-config.json`.
- No `.github/workflows/release.yml` or hex publish workflow.
- No `hex.config` token configured in CI.
- `:description` is set in mix.exs but should be reviewed for hex-page rendering.
- `:package` block in mix.exs needs `:licenses`, `:links`, `:maintainers` audit before publish.

Strategic framing (from `prompts/crosswake-elixir-oss-dna.md:103-137`): "install truth is product truth" and "release truth matters" are szTheory house-style anchors. The maintainer already has a `bootstrap-elixir-hex-lib` skill that paves this exact path.

Why this isn't on `MILESTONE-ARC.md`: planning blindspot. ARC focused on strategic-feature arcs (capabilities, commerce, companions) and did not call out release infra. Amendment landing in ARC alongside this thread.

## References

- `/Users/jon/projects/crosswake/mix.exs` — current package metadata, version, deps
- `/Users/jon/projects/crosswake/README.md` — quickstart copy that needs hex-page polish
- `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib/` — paved-path skill for hex bootstrap
- `prompts/crosswake-elixir-oss-dna.md:103-137` — house-style anchor for release discipline
- `.planning/MILESTONE-ARC.md` (Release Readiness Baseline section, added 2026-05-27)
- `.planning/PROJECT.md` § Next Milestone Goals (release-readiness recommendation, added 2026-05-27)

## Next Steps

- Decide release-please vs tag-driven release pipeline. szTheory bootstrap-elixir-hex-lib skill suggests release-please as canonical.
- Decide initial version: `0.1.0` (declares pre-release) vs `1.0.0-rc.0` (signals contract maturity). Repo has shipped 5 milestones, 11.5k LOC, 8k LOC tests — `1.0.0-rc.0` may be more honest.
- Set real `source_url` to actual GitHub repo (replace `github.com/example/crosswake`).
- Draft CHANGELOG.md from MILESTONES.md v1.0 → v3.2 history.
- Add `.github/workflows/release.yml` (hex publish on tag).
- Verify hex package metadata: licenses (Apache-2.0 already set), links (Source, Docs, Changelog), description, maintainers, files allowlist.
- Run `mix hex.build` locally to inspect package contents.
- Plan hexdocs render: `mix docs` produces docs/, push to hexdocs.pm on publish. README must render correctly on hex package page.
- After v3.3 ships, close this thread.
