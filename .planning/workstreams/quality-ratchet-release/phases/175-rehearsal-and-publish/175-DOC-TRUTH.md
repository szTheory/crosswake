# Phase 175 Plan 05: Documentation Truth Record (DOC-04, DOC-06, D-19)

This file records the vacuity-taxonomy row for the new `script/check_release_doc_version_literals.exs`
check (per the milestone's `VERIFICATION-CONVENTIONS.md` VAC-03 convention), plus the DOC-04 and
DOC-06 dispositions decided during execution, with the evidence behind each.

## Vacuity taxonomy row

The six shapes (A-F) are defined at `.planning/research/v23/PITFALLS.md` §"Pitfall 4" and are not
restated here, per that document's link-never-copy discipline.

| Check ID | Shape | Non-vacuity evidence (measured) |
|---|---|---|
| `doc.version_literals.no_bare_literal_outside_fence` + `doc.version_literals.invariant_marker_present` | matches none of A-F, because both are itemized, closed-world scans over a fixed, declared two-file roster (`docs/COMPANION-PUBLISH-RUNBOOK.md`, `docs/RELEASE-INCIDENT-RESPONSE.md`) asserting a positive structural fact about each rostered document's own text — not a predicate over a possibly-empty *runtime-derived* collection (Shape A: the roster is a hardcoded constant, never a scan result, so it cannot silently shrink to zero the way `Enum.all?([], ...)` does), not a `needs:`-skip condition (Shapes B/D/E — this check runs as a plain CI step, not inside the release workflow graph), not `continue-on-error` on a one-way-door step (Shape C — it is wired as a blocking step in the same job as `check_release_workflow_integrity.exs`), and not a shell exit-code idiom (Shape F — it is an Elixir script with its own explicit 0/1/3 exit contract, not a piped shell command). | Demonstrated red on an injected literal (`.../evidence/175-version-literal-check.log`, run 1: exit 1, cites `evidence/scratch/scratch-runbook.md:276` and quotes the injected line `Injected test claim: this scratch copy pins the release to 1.2.3 for the check's own red demonstration.`), demonstrated green on the same scratch copy with the literal removed (run 2: exit 0), and demonstrated green on the real two-file roster (run 3: exit 0). Additionally demonstrated red on invariant-sentence removal (`evidence/scratch/scratch-runbook-no-invariant.md`, ad hoc run: exit 1, `doc.version_literals.invariant_marker_present`) and red on a missing rostered file (`--roster docs/DOES-NOT-EXIST.md`: exit 3, `BLOCKED`), so the roster-missing path does not silently pass either. |

## DOC-04 disposition

**Deleted, not softened.** The `## Before releasing any version other than 0.2.1` section (the
`**STOP —**` callout, the `needs.release-please.outputs.version == '0.2.1'` claim, and the
`TODO-009`/`SEED-017` paragraph) was removed outright from `docs/COMPANION-PUBLISH-RUNBOOK.md`.
Confirmed stale before deleting: `publish-hex`, `publish-ios-core`, and `publish-android-core` in
`.github/workflows/release-please.yml` (lines 228, 560, 606) now gate on
`needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version`,
a dynamic per-release binding — the literal `'0.2.1'` comparison the deleted section described no
longer exists anywhere in the workflow. Witnessed by `grep -c 'TODO-009' docs/COMPANION-PUBLISH-RUNBOOK.md`
→ `0`.

**The section's final "Related:" paragraph was preserved, reworded.** Its claim — that a release
completing through exact-ref recovery does not run `exact-public-proof`, because that job `needs:`
the ordinary publish jobs — is not version-bound and was re-verified against
`.github/workflows/release-please.yml`'s current `exact-public-proof` job (lines 753-763): it still
`needs: [approved-release-guard, release-please, publish-hex, publish-ios-core,
publish-android-core, clean-room-proof-ios, clean-room-proof-android]`, so the claim remains true.
It now lives in `## Candidate-local versus exact-public proof`, with `0.2.1` replaced by "the
previously approved candidate."

Nine outside-fence bare version literals were de-versioned (the opening contract line, the three
linked-coordinate bullets, the companion-floors line, the mirror-rehearsal step's baseline-and-split
line, the two status-surface lines about the mirror baseline and the candidate public ref, and the
rollback paragraph about an already-published version). The one remaining `0.2.1` literal in the
file (`mix crosswake.release.candidate --version 0.2.1 --ref <40sha> ...`) is inside a fenced
command example and was left untouched per the plan's explicit fence exception.

The invariant sentence `This document makes no version-specific claims.` was added immediately
after the opening paragraph, before the first `##` heading.

## DOC-06 disposition

**Purely additive, as prior research predicted.** `git subtree split` is now named by name in the
three places the mirror split was previously described only by effect: the trusted mirror
rehearsal step (`### 5. Run the trusted mirror rehearsal`), `## Ordinary publication and
recovery`, and `### Scope of the iOS mirror recovery mode`. `grep -c 'git subtree split'
docs/COMPANION-PUBLISH-RUNBOOK.md` → `3`.

**Live-code re-verification, not assumed:** `script/release_candidate/ios_mirror.sh` lines 65-68
compute the split as
```
SPLIT_SHA=$(git -C "$RELEASE_REPO" subtree split \
    --prefix=packages/crosswake-shell-core-ios "$SOURCE_REF" 2>/dev/null | tail -1)
```
— the documentation's description ("computes the mirror commit with `git subtree split` over the
iOS package path") matches this invocation.

**Residual `splitsh` reference re-checked:** `grep -rl 'splitsh' .github/ script/ lib/ scripts/`
returns exactly one file, `script/check_ios_mirror_parity.sh`, at the comment "TAG-EXISTENCE ONLY:
no splitsh-SHA-identity comparison" (line 31) — a comment, not a live invocation. Left alone, as
the plan instructed. No live workflow or script invokes the previous splitter.

**The runbook itself does not name the previous splitter at all.** `grep -c 'splitsh'
docs/COMPANION-PUBLISH-RUNBOOK.md` → `0`. This is deliberate: the new "durable mechanism" sentence
states that the previously-used external splitter is not to be reinstalled or referenced going
forward without naming it, consistent with the plan's "operator contract, not a changelog"
framing — no migration note or history section was added.

**Archived `.planning/` history is untouched (D-18).** `git status --porcelain
.planning/workstreams/quality-ratchet-release/milestones/` returned empty both after Task 1 and
after Task 2.
