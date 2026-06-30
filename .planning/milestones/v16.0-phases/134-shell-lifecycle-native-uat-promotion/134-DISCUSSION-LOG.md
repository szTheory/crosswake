# Phase 134 Discussion Log

**Date:** 2026-06-28
**Mode:** discuss (research-then-recommend)

## How this discussion ran

The maintainer selected all four gray areas AND requested deep subagent research per area
(ecosystem idioms, pros/cons/tradeoffs, footguns, DX, brand/vision alignment) with a single
coherent one-shot recommendation set "so I don't have to think." Three parallel research agents
were dispatched; their findings were synthesized, cross-checked for coherence, and locked.

## Gray areas presented

1. **Version granularity & stamp** (keystone) — LIFE-02a
2. **`shell.status` comparison model** — LIFE-02b
3. **`gen.shell --diff` semantics** — LIFE-02b
4. **Android UAT promotion scope** — LIFE-01a/01b

(LIFE-02c upgrade-changelog folded into the versioning research; `gen.shell.ex:254` placeholder
replacement is a concrete deliverable.)

## Research dispatched

- **Agent A — Versioning/drift/changelog**: surveyed phx.gen, Igniter, Rails app:update, kubebuilder
  PROJECT file, gradle-wrapper, sqlc/protoc, JHipster, Next codemods. Recommended whole-set integer
  epoch + manifest + comment stamp + content-hash drift test + RebuildPolicy-linked changelog.
- **Agent B — CLI status+diff UX**: surveyed copier (the key precedent), Igniter dry-run, hex.outdated,
  npm/rustup (crying-wolf footgun), terraform/kubectl/helm diff, mix format/dotnet format exit codes.
  Recommended `.crosswake-shell.json` answers-file model, exit-2-when-behind, in-memory non-destructive
  diff re-rendered from saved params, unified diff + RebuildPolicy annotation.
- **Agent C — Android UAT promotion**: analyzed the actual aggregator workflow + verify scripts +
  Phase 135 registration tooling. Recommended a new hermetic `android-generated-shell-unit` job fanned
  into the existing aggregator (registration auto-deferred, coherent with Phase 135), honest iOS labels.

## Decisions locked (D-01 – D-21)

See `134-CONTEXT.md` `<decisions>`. Three cross-area reconciliations + one correctness catch are
recorded in `<cross_area_reconciliations>`:
1. Integer epoch (NOT library SemVer) — avoids the crying-wolf "behind" alarm.
2. One merged `.crosswake/shell.json` manifest (provenance + copier-style params) + in-file comment cross-check.
3. Exit-2-when-behind / 1-on-error (terraform/copier/kubectl precedent).
4. `RebuildPolicy.diff/2` diffs manifests not files → `--diff` annotation uses a file→class lookup, advisory only.

## Maintainer sign-off

Presented the full D-01–D-21 set; maintainer chose **"Lock it — write CONTEXT.md"** with no adjustments.

## Deferred ideas captured

3-way interactive merge/auto-patcher; iOS merge-blocking; Android device/emulator verification;
DRY_RUN=0 admin registration; `--require-shell` strict mode; adopter-side major-staleness CI guidance.
(See `134-CONTEXT.md` `<deferred>`.)
