# Phase 178 Index Diagnosis

The renewed full verification recorded a changed raw Git index digest while the staged-entry digest, HEAD, tree, and clean status remained stable. Raw index bytes from that invocation were not retained, so the exact historical writer cannot be identified from that run.

A focused disposable-repository reproduction confirmed that `git write-tree` can change a clean index when its optional TREE extension is absent. The candidate `--check` path called `write-tree` while validating both the delivery and proof clones, so it was not byte-read-only even with `GIT_OPTIONAL_LOCKS=0`.

The check path now verifies the cached diff against HEAD and compares normalized `git ls-files --stage -z` entries with `git ls-tree -r -z HEAD`, without writing the index. Assembly paths retain `write-tree` where they intentionally construct candidate trees. Regression coverage confirms that a clean proof check preserves every raw index byte when the TREE extension is absent.

Validation: `node --test .planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/prepare_candidate.test.mjs` passed all 11 tests. The original failed run remains preserved. No shared proof clone, recovery Git state, or remote state was changed.

## Follow-up: Cleanliness-stage index refresh

The later all-pass run retained private raw index copies. Their v2 entry count, modes, object IDs, sizes, flags, TREE extension, and total byte length matched. Only ctime/mtime cache fields changed for ten generated-contract outputs: the two activation fixtures and vector files, the contract snippet, and the two generated guides. The checksum changed as a consequence of those stat-field updates.

The source shows why those paths can have stale index timestamps: `generatedContractFailure()` runs the declared generators and restores saved output bytes unconditionally in `finally`, which changes filesystem timestamps even when output bytes are identical. The repository-cleanliness stage begins by running `git diff --check`. In a disposable Git fixture with a stat-only mtime difference, that exact command changed raw index bytes despite `GIT_OPTIONAL_LOCKS=0`; `git status`, `git ls-files`, and `git diff --cached --quiet HEAD --` did not. This identifies the actual raw-index writer for the retained all-pass run.

A focused control passed: running `git diff --check` with `GIT_INDEX_FILE` set to an isolated index copy refreshed only that copy and preserved every byte of the real fixture index. A narrower documented setting was then tested and is preferred: per-process `diff.autoRefreshIndex=false` prevents the automatic `update-index --refresh` while preserving check behavior. With an mtime-only mismatch, the exact `git diff --check` exited 0 and preserved every raw index byte; trailing whitespace still produced exit 2; the existing status check detected both staged and unstaged content changes. A disposable `runVerification()` adapter probe also confirmed that settings supplied in the repository-cleanliness stage environment reach the exact `git diff --check` child process.

The runner owner will append `diff.autoRefreshIndex=false` to the private facade child environment while preserving any existing `GIT_CONFIG_COUNT` entries. This retains the generated-contract verification and whitespace check, avoids an alternate index, and protects the bound proof index. No real proof clone or recovery Git state was modified, and no full runner was repeated.
