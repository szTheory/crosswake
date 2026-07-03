---
phase: 141-core-first-publish-family-release
milestone: v17.0
created: 2026-07-03
source: "/gsd-progress route → user chose 'plan a core-first publish fix phase'; decisions locked via AskUserQuestion (no full discuss cycle needed — blocker is well-characterized)"
requirements: [FAMILY-05, FAMILY-04]
---

# Phase 141 — Core-First Publish & Family Release — CONTEXT

## Why this phase exists (the blocker)

On 2026-07-03 a user-authorized, canary-first **sigra publish** (Phase 140 Wave 2 / plan 140-05) was attempted: sigra Release PR #42 was merged, triggering `publish-hex-sigra`. It **failed at the `mix compile` step, before `hex.publish` ever ran** — so **nothing was published** (no irreversible action; no `hex.retire` needed). Error:

```
== Compilation error in file lib/crosswake/companions/sigra/evaluator.ex ==
** (KeyError) key :code not found
    (crosswake 0.1.2) expanding struct: Crosswake.Compatibility.Finding.__struct__/1
    (crosswake 0.1.2) .../sigra/evaluator.ex:258: ...Evaluator.deny/4
```

**Root cause (systemic):** the companion family depends on **unpublished v17.0 core**. sigra `evaluator.ex:258` and chimeway `resolver.ex:102` build `%Finding{code: ...}`; the `:code`/`:details` fields + `:auth` clause were added to core `Crosswake.Compatibility.Finding` in commit `cc87362d` (**phase 137-01**) — unpublished. Core is still **0.1.2** on Hex. The companion publish seam (`crosswake_dep()`, D-11/D-13) resolves `{:crosswake, "~> 0.1"}` at publish → Hex serves **0.1.2** (pre-`:code`) → compile fails. All three v17.0 companions share the `~> 0.1` floor → all blocked identically. Dress-rehearsals passed only because they use the local **path dep** (`../..`), never the published-Hex resolution — so this could ONLY surface on a real publish, which the canary caught.

The FAMILY-04 publish plan (140-05) + `docs/COMPANION-PUBLISH-RUNBOOK.md` **omitted the core-first prerequisite.**

## Locked decisions (2026-07-03)

- **D-141-A — Core version: `0.2.0`.** Minor bump: the core changes since 0.1.2 are additive (`Finding.{code,details}`, `:auth` clause, `:companions` registry) — backward-compatible for existing 0.1.2 consumers. `0.2.0` becomes the honest "Requires crosswake >= 0.2.0" floor.
- **D-141-B — Publish DAG is core-first, then companions.** Publish core `0.2.0` and confirm it resolves on Hex BEFORE any companion publish. Then sigra → chimeway → threadline sequentially (each `publish-hex-*` + `clean-room-proof-*` green + hexdocs resolving before the next).
- **D-141-C — Bump companion dep floors `~> 0.1` → `~> 0.2`** in the `crosswake_dep()` publish seam of `crosswake_sigra`, `crosswake_chimeway`, `crosswake_threadline` (mix.exs). Update the compat-matrix "Requires crosswake >= X" column to `>= 0.2.0`. This is a code change → release-please will open fresh companion Release PRs (patch bump or re-cut of 0.1.0).
- **D-141-D — Scope excludes rulestead/rindle.** The v16.0 companions use only 0.1.2-era `Finding` fields (rulestead: `axis/route_id/message/subject`, NO `:code`; rindle: no `Finding` use), so they are NOT blocked by core-first and can publish against 0.1.2 independently, later, as a separate decision. Their Release PRs (#39/#38) stay open/untouched. (Consistent with REQUIREMENTS "Out of Scope": no re-versioning of rulestead/rindle.)
- **D-141-E — Every `hex.publish` is a human go/no-go gate (`autonomous: false`).** Core publish AND each companion publish are irreversible; the human is the publish authority. No publish step runs inside autonomous phase execution. (Same discipline as 140-05; the classifier already enforced this once.)

## Key mechanics / anchors for the planner

- **Core publish vehicle:** the root `release-please` Release PR **#25** ("chore: release main", open since 2026-06-17). It must recompute over phases 136–140 to land core `0.2.0`. Verify what version release-please computes (root `release-please-config.json` has `release-type: elixir`, NO `release-as` pin on `.`). May need a Conventional-Commit `feat:` or a `release-as` nudge to force `0.2.0` if release-please computes a patch.
- **release-please manifest/tag state:** `.release-please-manifest.json` has core `.` = `0.1.2`; companion entries already `0.1.0`. The failed sigra attempt's tag/release were deleted, but release-please may re-open a sigra Release PR. Companion `release-as: "0.1.0"` pins (+ `_TODO_release_as` notes) are still in `release-please-config.json` — the D-141-C floor bump + re-publish must reconcile these (drop the pin after first successful publish via the auto-opened release-as-cleanup PR).
- **Publish pipeline (verified present, Phase 140-04):** per-companion `publish-hex-<name>` (gated on `<name>_release_created`, uses `secrets.HEX_API_KEY`, `mix hex.publish --dry-run` then `--yes`), within-run `clean-room-proof-<name>`, and `release-failure-alert` (`if: failure()`). `HEX_API_KEY` secret confirmed present. Operating procedure: `docs/COMPANION-PUBLISH-RUNBOOK.md` (author: 140-04) — extend it with the core-first step.
- **Ship-gate:** `register_required_checks.sh` green-first (DRY_RUN=1 → 0), repo-admin gh (owner token has `repo` scope). `publish-hex-*`/`clean-room-proof-*` MUST NOT be registered required (permanent deadlock).
- **Branch protection reality:** main requires the **full 22 merge-blocking lanes** (v16.0 ship-gate; `strict:true`, `enforce_admins:true`) — every Release PR must go green on all 22, and if origin/main advances mid-CI the PR must be brought up to date. (See [[feedback-milestone-boundary-hygiene]] gotcha.)

## Verification the phase must satisfy
- `mix hex.info crosswake` shows `0.2.0`; hexdocs.pm/crosswake/0.2.0 resolves.
- Each companion clean-room-proof resolves it against core `0.2.0` (not 0.1.2) and is green; hexdocs.pm/crosswake_<name>/0.1.0 resolves.
- Compat matrix shows "Requires crosswake >= 0.2.0"; drift test green.
- No `publish-hex-*`/`clean-room-proof-*` registered as required checks.

## Related
[[project-crosswake-core-first-publish]] · [[feedback-milestone-boundary-hygiene]] · [[project-crosswake-release-pipeline]] · `docs/COMPANION-PUBLISH-RUNBOOK.md`
