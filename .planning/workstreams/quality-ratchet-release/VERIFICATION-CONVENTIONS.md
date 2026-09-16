# Milestone v23.0 Verification Convention: `vacuity_taxonomy`

**Scope:** This convention applies to the phase-close `VERIFICATION.md` of Phases 169, 171, 172,
173, 174 and 175 of milestone v23.0 (Release Pipeline Repair & Proof-Lane Truth). Phase 170's own
record is produced by plan 170-05, not by this document.

## Why this exists

ROADMAP.md's Phase 170 success criterion #4 asks for a review checklist item applied at the close
of each remaining phase: every new check landed by any phase in this milestone must be checked
against the six-shape vacuity taxonomy before it is trusted, or eventually made merge-blocking.
Checklist mechanisms that produce real scrutiny — Gawande's DO-CONFIRM pause point with a
designated caller, Google's Production Readiness Review, Kubernetes' KEP graduation criteria —
write the answer into the artifact that already gates a state transition. The mechanisms that
decay into ritual ticking — un-required PR templates, Definition-of-Done checkboxes nobody
enforces — do not. `VERIFICATION.md`'s frontmatter already gates phase closure. This convention
puts the record there, not in a new, optional surface.

## The frontmatter field

Each covered phase's `VERIFICATION.md` frontmatter carries a `vacuity_taxonomy:` key: a list of
objects, modeled directly on the existing `deferred:` list-of-objects shape in
`169-VERIFICATION.md`. Each object carries exactly these keys:

- `check_id:` — the check's own ID, exactly as it appears in its emitter source.
- `shape:` — one of the letters `A`, `B`, `C`, `D`, `E`, or `F` (see "Single-sourcing" below), or
  the explicit escape form `matches none of A-F, because <reason>`. A check may never be recorded
  without at least one shape letter or the explicit escape form — there is no third option, and no
  blank is ever valid.
- `non_vacuity_evidence:` — a measured fact: the count the check actually found on a real run
  (before and after a fix, where applicable), or the specific mutation it was demonstrated turning
  red against. Never an assertion that the check "looks correct" — a number or a named mutation,
  always.

Where a single check genuinely maps to more than one shape, `shape:` records one primary letter
and an `also_shapes:` key lists every additional letter. A check is never recorded against a shape
list with zero letters and no escape form.

## The body section

Each covered phase's `VERIFICATION.md` carries a `## Vacuity Taxonomy` body section: one row per
`vacuity_taxonomy` entry, listed in check-ID lexical order. Lexical ordering is required so the
section diffs stably across phases and two different authors, given the same set of checks,
produce the same file.

## The null statement — omission is never silent

A phase that landed no new checks at all must still carry the section, stating the sentence
**"This phase landed no new checks."** plus one sentence of justification — exactly as
`169-VERIFICATION.md`'s "Human Verification Required" section states `None.` and then says why,
rather than omitting the section entirely.

Omitting the `## Vacuity Taxonomy` section is defined here as **non-compliant**, in every case,
with no exception. Completeness is a positive assertion, never an inference from absence: an
auditor grepping every phase's `VERIFICATION.md` for the section header must get a decidable
answer — "here is what was checked" or "here is the explicit statement that nothing needed
checking" — and must never be left inferring "the section is missing" as evidence of either.
"There was nothing to check" and "we forgot" must never look the same on disk.

## Never a bare tick

A yes/no checkbox — "vacuity taxonomy applied: ☑" with no supporting detail — is rejected outright
and is not an allowed variant of this field. A boolean asserted without inspecting what is inside
it is Shape A restated one layer up, at the process level: exactly the defect class this milestone
exists to remove. Shipping that shape inside the mechanism meant to catch it would defeat the
convention's own purpose.

## Who applies it

The **phase-close verifier** applies this convention, at phase close — not the executor at plan
time, and not a PR reviewer.

- Not the executor at plan time: a check's shape can still change during execution, and the
  convention needs the check as it actually shipped, not as it was planned.
- Not a PR reviewer: nothing durably records a PR-time judgment across all six remaining phases,
  one of which (169) is already merged and has no open PR to comment on. A PR comment is also not
  read by the next phase's planner the way `VERIFICATION.md`'s frontmatter is.

Because `VERIFICATION.md`'s frontmatter contract already gates phase closure, the field cannot be
skipped silently — a phase cannot close without the verifier populating or explicitly nulling it.

## Single-sourcing — link, never copy

The six shapes themselves — their definitions, detection recipes, and fix recipes — live at
[`.planning/research/v23/PITFALLS.md`](../../research/v23/PITFALLS.md) §"Pitfall 4". This
document links to that file and does not restate any shape's definition, detection recipe, or fix
recipe. Referring to a shape by its letter (`A`, `B`, ... `F`) is fine; defining what that letter
means here is not. A second copy of the taxonomy that can silently diverge from the first is
exactly the failure Phase 169's own documentation rule (link, never copy) exists to prevent —
applying the same discipline to this convention's own subject matter would be a contradiction.

## Lifetime

The `vacuity_taxonomy` field outlives milestone v23.0. When `absence.collection_assertion_non_empty`
(VACG-01, tracked under Future Requirements) eventually lands as a merge-blocking guard, it
mechanically supersedes **Shape A only** (see `PITFALLS.md` §"Pitfall 4" for what that letter
means). Shapes B through F have no proposed automated guard at all as of this writing. When
VACG-01 lands, narrow this field to the five remaining shapes — do not retire the field itself.

## Boundary

This is a `.planning/` convention only. No change to `lib/`, `script/`, or `.github/workflows/` is
made for VAC-03 — the convention is a review-checklist mechanism, not a code change, per Phase
170's success criterion #4 wording.

A PR template or `CONTRIBUTING.md` checklist item was considered as the primary surface for this
convention and rejected. Reasons:

1. This repository has no PR template convention today — adding one solely to carry this checklist
   item would be a larger, unrelated change bundled into VAC-03's scope.
2. It cannot reach the already-merged Phase 169: there is no open PR left to attach a checklist
   item to, so a PR-template mechanism would silently exempt the one phase this convention most
   needs to cover retroactively.
3. An un-required checkbox carries no evidentiary weight — nothing forces it to be ticked honestly,
   and nothing downstream reads it. `VERIFICATION.md`'s frontmatter, by contrast, already gates a
   real state transition (phase closure).

A PR template or `CONTRIBUTING.md` item remains acceptable later as a **supplementary** reminder,
once this repository adopts a PR template convention at all — but it is not the primary surface
for VAC-03.

## Covered phases

| Phase | Record location |
|---|---|
| 169 | `phases/169-diagnostic-legibility/169-VACUITY-TAXONOMY.md` (retroactive addendum — see below) |
| 171 | `phases/171-*/171-VERIFICATION.md` frontmatter + `## Vacuity Taxonomy` section |
| 172 | `phases/172-*/172-VERIFICATION.md` frontmatter + `## Vacuity Taxonomy` section |
| 173 | `phases/173-*/173-VERIFICATION.md` frontmatter + `## Vacuity Taxonomy` section |
| 174 | `phases/174-*/174-VERIFICATION.md` frontmatter + `## Vacuity Taxonomy` section |
| 175 | `phases/175-*/175-VERIFICATION.md` frontmatter + `## Vacuity Taxonomy` section |

Phase 169 closed before this convention existed. It is covered retroactively by
[`169-VACUITY-TAXONOMY.md`](phases/169-diagnostic-legibility/169-VACUITY-TAXONOMY.md), a scoped
addendum living beside its artifacts. `169-VERIFICATION.md` itself — a sealed, digest-covered
artifact — is not edited to add this coverage; editing it after the fact would invalidate the
`covered_digest` it already carries and would blur the line between what was verified at close
time and what was added afterward.
