# Phase 179 — Semantic Migration Repair

The prior security re-audit of `e25f17b` closed twelve of thirteen threat rows. T-179-05 remained open because multiline proof configurations could skip rewriting, settings references could point elsewhere, and shell migration did not validate the complete graph.

## Changes and ownership

All implementation is committed in the independent candidate `/private/tmp/crosswake-phase179-impl`, ending at HEAD `09dcb7169749d21e7b5a62a1ae3b9f546a6df522`, tree `8b6f327a2c35febffc5b143909619cac1202284e`. The recovery checkout has no source or Git-index changes.

- `89d3773`: seven semantic regression tests, observed **7 tests / 7 failures** before the production repair.
- `4456d82`: one balanced OpenStep parse supplies both graph validation and byte spans for bounded migration edits. Shell and proof require the complete recognized configuration/list/target/project graph, selected root and target membership, and a settings reference whose actual file/group destination is the managed xcconfig. Multiline/quoted/commented configurations are migrated rather than silently skipped. Owned unconditional and SDK-conditional identity/signing masks are removed; declared target bundle variables are restored. Unrelated native comments, settings and Unicode bytes are preserved, and migration is idempotent. The older fragment-only test fixture now uses the real complete shell template.
- `09dcb71`: capture the test Xcode stderr boundary without contaminating JSON or printing raw destination lists, remove raw build output from failure messages, and reconcile four new collection assertions. Each new collection assertion has an explicit two-result guard. The owned inventory renderer preserves all prior 231 keys and adds four guarded rows, for **235 total**; the original **52 frozen guard rows** remain unchanged.

## Focused verification on the repaired source

- New graph, managed-output and maintained proof-lane suites: **40 tests, 0 failures**.
- Shell migration and real generated Phoenix host integration: **9 tests, 0 failures**, including actual Xcode Debug/Release app/test identities from the original ordinary declaration and real interrupted-build recovery.
- Assertion inventory and frozen-guard checks: **24 tests, 0 failures**.
- Pinned Node 22.14 actual settings suite: **5 tests, 0 failures**, including manual/automatic 20-cell matrices and a reformatted, masked proof migration checked through actual Xcode against the original declaration. Resource, packaged-path and missing-input controls pass.
- Compilation with warnings as errors, formatting and Git whitespace checks pass.
- Recovery preservation check: HEAD, Git index bytes and all **1,263** protected tracked source files match the execution-start baseline.

## Remaining gates and limits

Independent security/code re-review and the three required broad proof leaves are still pending on this final commit. Earlier broad passes belong to `f92306a` and are not promoted to this candidate. No physical-device, adopter, release or publication claim is made.

Earlier process debt and unretained-output unknowns remain in `179-REVIEW-FIX.md`; this repair does not assign retrospective causes or manufacture missing test-first evidence.
