# Phase 197 plan check: open issues after iteration 3

Status: planning paused 2026-10-29 after the 3-iteration cap. The plans at `ec5f7513` (14 plans)
are not yet approved for execution. Resume with one guided revision pass covering every item
below, then one more plan-checker run.

Decided by the user and recorded in 197-CONTEXT.md:
- D-04 amendment (`:ios_host` deferred to 0.2.12 / Phase 199), applied in iteration 1.
- D-26 (qualify linked guides in Phase 197). This resolves the blocker and warning 7 below once a
  plan implements it.

## Open issues (iteration 3)

1. BLOCKER (no plan owns it). `guides/support_matrix.md:80` (rendered by
   `lib/crosswake/support_matrix/renderer.ex:137`), `guides/capability_map.md:10` and
   `guides/native_shell.md` ("Declared iOS Host Setup") describe `:ios_host` as shipped, and
   install.md links to them. Fix it per D-26: qualify in the renderer and native_shell.md, then
   regenerate through `mix crosswake.docs.sync`.
2. WARNING 197-02 T3. The amendment is appended next to the superseded clauses in DOCS-02 and
   ROADMAP SC2 ("matrix shows/matches the versions published"). Replace those clauses in place
   and keep the amendment note.
3. WARNING 197-14 T2. `pr-ci-197.txt` records the PR head SHA and is then committed and pushed,
   so the SHA is stale when it lands. Record CI on the final pushed head after the last push, for
   example in a PR comment.
4. WARNING 197-10 T2. (a) The `git grep -l "release.status --live" -- .github/workflows` gate
   passes only on exit 1, so write it as `! git grep -q ...`. (b) `release.status: rc [0-9]+`
   passes on any rc. Add a per-package check that each of the five packages shows a published
   version.
5. WARNING 197-11 T1. In the `with` chain of `explicit_unpublished_candidate?/3`, the
   `published_version` binding becomes unused and produces a compile warning, which fails CI's
   warnings-as-errors. Drop or underscore the binding, and add `mix compile --warnings-as-errors`
   to the verify step.
6. WARNING (all plans touching .ex/.exs). No plan runs
   `mix format --check-formatted <changed files>`, which CI's format-proof stage requires.
7. WARNING (no plan owns it). `guides/compatibility.md:45-52`, `native_shell_upgrade.md:57-87`,
   `support_matrix.md:40-42` and `architecture.md:111` state manifest `1.2.0` as shipped, but
   0.2.11 emits `1.1.0`. Fix it per D-26.
8. WARNING 197-12 T3. The telemetry guide must list `[:crosswake, :offline, :replay]`, the name
   declared at `lib/crosswake/telemetry.ex:127`, and show its emitted `:stop` form beneath it.

Info (optional):
- 197-08 and 197-11 are the plans most likely to overrun. Calibration confidence is low.
- 197-03/04: the must_have claims every tool is checked, but only some removals are tested.
  Narrow the claim or loop the test over all tools; bash removal in particular is untested.
- 197-09: native_shell.md says the entry "must be declared by the selected router", but
  `valid_entry/1` only checks that it is non-empty. Fix the wording.
