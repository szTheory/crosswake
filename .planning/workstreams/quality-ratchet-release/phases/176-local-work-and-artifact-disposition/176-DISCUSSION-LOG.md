# Phase 176: Local Work and Artifact Disposition - Discussion Log

> **Audit trail only.** Planning and execution use 176-CONTEXT.md. This log records alternatives and research, not completed cleanup or recovery evidence.

**Date:** 2026-10-11
**Workstream:** quality-ratchet-release
**Areas:** Recovery location; useful source changes; cleanup timing.

## User direction and process

The initial question offered all three areas. The user answered “all” and requested parallel research, applicable prompt material, reputable primary sources, Elixir/Phoenix conventions, examples, pros/cons/tradeoffs, relevant stakeholder lenses, an adversarial pass, a coherent recommendation set, and automatic adoption of those recommendations. The user also prefers smaller, flatter dependency trees.

Three advisor researchers worked in parallel, read-only, one per area. Each then reviewed a narrow refinement of the combined recommendation. The orchestrator adopted the set under this explicit delegation. No individual table row below is represented as a separate user vote. No further vision or preference question remained necessary.

The discussions used current workstream scope, Phase166/167 artifact/provenance decisions, the project OSS/DX prompts, and the newer brandbook. Rich application UI and Plug/Ecto runtime design were not applicable to this repository-maintenance phase; maintainer jobs, terminal accessibility, clear ownership, and recovery experience were applicable.

## Recovery location

| Option | Benefits | Costs and footguns | Outcome |
|---|---|---|---|
| Repository-only archive | Durable rationale and reviewable provenance | Raw diffs/content can disclose sensitive material and bloat git | Use only for sanitized inventory and decisions |
| Private archive only | Preserves exact bytes outside source control | Rationale, retention, and handoff can disappear with local storage | Use for payload, with a private manifest and explicit retention |
| Hybrid | Reviewable dispositions plus exact private recovery | Must reconcile safe row IDs with the private payload manifest | Adopt |

**Recommendation:** A dated phase record in git plus owner-controlled persistent recovery storage outside working source. Temporary storage is restore scratch. Private raw data is not a proof/log artifact. Preserve symlinks as links, executable mode, deleted/type-changed paths, and staged/unstaged distinctions; restore and compare rather than trusting a copy exit code. Do not claim backup coverage that was not checked.

Git distinguishes index and worktree comparisons; binary/full-index patches can support reconstruction but omit untracked payload unless separately captured. A bundle preserves selected refs and reachable objects; an archive operates on a named tree. Neither alone preserves dirty work. These documented limits support using exact snapshots plus recovery rehearsal. [Git diff](https://git-scm.com/docs/git-diff), [Git bundle](https://git-scm.com/docs/git-bundle), [Git archive](https://git-scm.com/docs/git-archive).

**Adversarial refinement:** Keep absolute recovery pointers, unsafe filenames, sensitive hashes/sizes, and symlink targets private. Never follow links to unrelated data or archive credentials wholesale. Keep unresolved source intact if safe durable preservation is unavailable. Retain preserved-only material until a later scoped archive-retirement decision.

## Useful source changes

| Option | Benefits | Costs and footguns | Outcome |
|---|---|---|---|
| Whole-path comparison alone | Simple complete coverage | One file may contain both merged and unique changes | Use as the mandatory index |
| Patch/hunk matching alone | Efficient triage | Similarity is not behavioral or authority equivalence | Use only as supporting evidence |
| Path-complete inventory plus semantic ownership units | Captures partial merges and linked behavior | Needs bounded source/test/owner inspection | Adopt |

**Recommendation:** Exactly one of the five roadmap dispositions per path, with subordinate records for behavior/hunk decisions. A partly merged file remains retain while unique work is unresolved. Name exact comparison commits and distinguish byte identity from semantic equivalence. Preserve different local text even if its behavior appears merged.

Git's documented comparison endpoints and patch-series/common-ancestor tools support provenance; deciding semantic equivalence is a project review judgment. [Git diff](https://git-scm.com/docs/git-diff), [Git range-diff](https://git-scm.com/docs/git-range-diff), [Git merge-base](https://git-scm.com/docs/git-merge-base).

Elixir has dynamic task/alias entry points and module dependency tooling; Phoenix routing uses macros. Therefore the Phase177 retirement gate must supplement module analysis with supported Mix aliases/tasks, workflow, script, and generated-path inspection. None of these tools alone proves a code path dead. [Mix aliases](https://mix.hexdocs.pm/Mix.html), [Mix.Task](https://mix.hexdocs.pm/Mix.Task.html), [Mix xref](https://mix.hexdocs.pm/Mix.Tasks.Xref.html), [Phoenix.Router](https://phoenix.hexdocs.pm/Phoenix.Router.html).

**Adversarial refinement:** Untracked numbered tag-apply variants and similar tests are candidates, not proven obsolete code. Every source/test/workflow row stays accountable even when grouped by invariant. Do not create a sixth mixed disposition. Do not redo Phase177's full retirement or Phase178's complete verification during inventory.

## Cleanup timing

| Option | Benefits | Costs and footguns | Outcome |
|---|---|---|---|
| Apply individually proven removals in Phase176 | Immediate resolution of some residue | Needs explicit operation authority, verified recovery, fresh baseline, and containment | Optional only for exact permitted invocation-owned scratch |
| Inventory and preserve; hand source work to Phase177 | Satisfies recovery goal with low loss risk and clear phase ownership | Requires dispositions with concrete next actions | Adopt as the required Phase176 outcome |
| Delay inventory/recovery to Phase178 | Defers effort | Couples dirty recovery to final clean-source proof and leaves unique work exposed | Reject |

**Recommendation:** Phase176 produces complete inventory, five-disposition coverage, verified durable recovery, and generated-contract ownership. Deletion is not required by its success criteria. Keep the recovery checkout intact apart from scoped planning/evidence writes; make source maintenance a Phase177 handoff and clean exact-source verification a Phase178 gate.

Git porcelain output is stable for scripts; its NUL format has specific rename-path rules, and ordinary status omits ignored files. The plan must account for these actual output shapes. Policy membership and invocation ownership decide residue, not ignore status. [Git status](https://git-scm.com/docs/git-status), [Git check-ignore](https://git-scm.com/docs/git-check-ignore), [Git ls-files](https://git-scm.com/docs/git-ls-files).

**Adversarial refinement:** `.tmp/` and `.planning/tmp/` are not the existing root `tmp/` rule. Recheck baseline and containment before any permitted grouped action. Report unreadable/unclassified paths instead of skipping them. Keep historical failure verdicts and consumed release attempts unchanged. An approved maintenance scope does not transfer release authority or justify blanket cleanup.

## Ecosystem lessons and coherent architecture

Hex exposes the configured package file set and supports building an unpacked package. Use package inspection where package ownership is relevant; it does not define repository recovery coverage. [mix hex.build](https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html).

Cargo documents packaging followed by extraction/build verification and checking that build scripts did not alter source. It also documents flattening symlinks. The useful lesson is to verify the materialized result; copying Cargo's archive semantics would fail exact symlink recovery here. This is an inference applied to Phase176 recovery and Phase178 final-source proof, not an adoption of Cargo tooling. [Cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html).

The project prompts favor named supported commands, install/proof truth, explicit host/library ownership, and low dependency surface. Reuse the repository artifact policy and Git/stdlib; no new runtime abstraction, cleanup framework, public API, or permanent CI lane is warranted.

| Lens | Consequence for the adopted set |
|---|---|
| Maintainer and future contributor | Complete path coverage, recoverable bytes, one disposition and concrete next action |
| Architecture and Elixir/Phoenix | Source owns behavior; generated outputs project it; dynamic callers remain a retirement gate |
| Security and privacy | Raw content remains private; sensitive filenames/links/metadata are not committed; paths cannot escape scope |
| DevOps/SRE and reproducibility | Exact source identities, fresh baseline, restore rehearsal, later final-source CI |
| DX and accessibility | Plain text, escaped paths, no color-only status, grouped checks, one useful correction |
| Product and scope | Preserve the first-adopter boundaries; no release rerun, new dependency, dashboard, Android breadth, or historical verdict rewrite |

## Agent discretion

Evidence filenames/layout, safe row IDs, bounded inspection order, and private storage root within available authorized scope. These are implementation details the user delegated, not new preference gates. Missing concrete filesystem authority or an unsafe storage condition must stop the affected execution operation, not invalidate this completed discussion.

## Deferred work and next action

Phase177 owns actual source maintenance/retirement, instruction repair, and the open GitHub queue. Phase178 owns complete clean-checkout verification and hosted CI for the final exact source. Archive retirement remains a later scoped decision.

Last fully passed phase: 174. Phase175 is archived at 8/9 with REL-10 breached. Phase176 discussion is captured; research/planning and execution have not been claimed complete, and MAINT-01/02/04 remain pending.

**Exact next command:** `$gsd-plan-phase 176 --ws quality-ratchet-release`.
