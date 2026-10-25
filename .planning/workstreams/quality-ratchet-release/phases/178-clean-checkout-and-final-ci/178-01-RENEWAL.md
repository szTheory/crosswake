# Phase 178 Plan 01 Renewal: Requalify the eight-path source candidate

The bounded source repair was replayed from the canonical base in an independent full clone. The original six-path Phase177 bundle reconstructed the retained candidate tree, then the three-path repair bundle produced the reviewed eight-path source delta and a new local candidate commit. A fresh detached proof clone matches that commit and tree exactly.

The renewed candidate is `3e8a4b2601b542323edfd6053f25e56c67873b47` with tree `27f4073039b4dd976492127549603a76ce22499b`, parented directly on canonical base `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`. Its exact selected paths are the six mandatory maintenance paths plus `script/collection_assertion_ledger.json` and `script/collection_assertion_remediation.json`; the repair bundle’s three paths overlap the existing guide test and add those two snapshots, leaving eight distinct paths.

The qualifier checks the original six-file replay and repair replay using actual Phase177 bundle fields, including the combined `patchBase64` and `{path, mode, bytes, patch}` untracked-file shape. It verifies patch byte counts and digests, canonical main/base identity, exact source path sets, 230 unchanged ledger keys and bucket counts, 52 frozen remediation keys and expressions, and line-reference-only movement in derived fields. It rejects tampered patch bytes, wrong bases, path drift, frozen-membership changes, bucket changes, symlink escapes, and a proof clone whose clean HEAD is not the bound commit.

The new immutable candidate binding and fresh owner-private pointer were written after qualification succeeded. The public candidate projection contains only candidate commit/tree, eight paths, count, and existing pending requirement status. MAINT-07 remains pending full `--all`; MAINT-08 remains pending hosted CI. No requirement completion is claimed.

## Verification

- `node --check 178-evidence/prepare_candidate.mjs` — passed.
- `node --test 178-evidence/prepare_candidate.test.mjs` — 10 passed, 0 failed.
- `prepare_candidate.mjs --self-test` — passed.
- `prepare_candidate.mjs --check` against the renewed private binding — passed; eight selected paths and clean detached proof identity.
- Recovery checkout protection comparison — source bytes/modes for all 1,296 non-planning files, HEAD, symbolic branch, raw index digest, index-entry digest, and worktree identity matched the saved snapshot.

## Deferred

The complete retained `script/verify_repository.sh --all` run and hosted CI remain Plan02 work. The earlier failed run remains historical evidence only and is not counted as a pass. Existing MAINT-07/08 status remains pending.
