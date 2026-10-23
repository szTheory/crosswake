# Phase 176: Local Work and Artifact Disposition - Pattern Map

**Mapped:** 2026-10-11  
**Files analyzed:** 6 anticipated deliverables (names are proposals where context leaves filenames open)  
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `176-evidence.mjs` | utility | transform / file-I/O | `script/verify_repository.mjs` | role-match |
| `176-evidence.test.mjs` | test | batch / file-I/O | `test/js/repository_verification.test.mjs` | strong |
| Phase-local inventory and disposition record (filename TBD) | document | transform | `176-CONTEXT.md` disposition contract; repository verifier output conventions | role-match |
| Phase-local generated-contract ownership map (may be a section of inventory) | document | transform | `script/repository_artifact_policy.json` | strong |
| Private recovery manifest (outside git; filename/location TBD) | manifest / utility data | file-I/O | v23 `original-artifacts.json`; verifier snapshot routines | partial |
| Isolated restore fixture/material (temporary only) | test fixture | file-I/O | `test/js/repository_verification.test.mjs` temporary Git repositories | strong |

No runtime API, CI workflow, or production source change is in scope. The inventory, disposition, and owner map can be sections in one dated phase artifact; the private manifest must keep sensitive metadata and storage pointers out of that artifact.

## Pattern Assignments

### `176-evidence.mjs` (utility, transform / file-I/O)

**Analog:** `script/verify_repository.mjs`

Use its direct `spawnSync` invocation with fixed argv, `GIT_OPTIONAL_LOCKS=0`, `encoding: null`, bounded `maxBuffer`, and closed failure messages. Its snapshot helper preserves raw status bytes to a private file (`script/verify_repository.mjs:244-249`):

```js
const result = spawnSync("git", ["status", "--porcelain=v1", "-z", "--untracked-files=all"], {
  cwd: root,
  env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" },
  encoding: null,
  maxBuffer: 16 * 1024 * 1024
});
if (result.error || result.status !== 0 || !Buffer.isBuffer(result.stdout)) {
  throw new Error("Git status snapshot failed");
}
writeFileSync(destination, result.stdout, { mode: 0o600 });
```

For path containment and owner-only scratch permissions, see `script/verify_repository.mjs:236-242`. For policy matcher semantics, see `script/verify_repository.mjs:265-270`; the inventory should report policy facts separately from disposition decisions.

**Important limitation:** Do not copy the current status parser at `script/verify_repository.mjs:251-262` for this phase. It converts the byte stream to UTF-8 before parsing and only skips the second rename/copy field. Phase176 requires arbitrary filename bytes to survive parsing; keep paths as Buffers through record validation, decoding only for safe escaped display. Also expand beyond the verifier's ordinary untracked-path snapshot: the phase contract needs index/worktree separation, deletions, type/mode changes, unmerged stages, gitlinks, and both rename names.

For generated outputs, the existing verifier snapshots bytes, runs declared argv, compares outputs, rejects undeclared paths, and restores original bytes in `script/verify_repository.mjs:291-333`. This is a useful scratch-only drift-check pattern, not a recovery archive: it does not prove restoration of symlink identity, file kinds, executable mode, or staged/unstaged state. Run generators only against isolated scratch, after preserving the pre-generation state.

### `176-evidence.test.mjs` (test, batch / file-I/O)

**Analog:** `test/js/repository_verification.test.mjs`

Follow its Node built-in test runner and temporary repository lifecycle (`test/js/repository_verification.test.mjs:1-29`), then assert against real Git/filesystem state and clean the fixture in `finally`. The existing unusual-name test shows how to preserve a raw NUL status snapshot and assert no payload leaks (`test/js/repository_verification.test.mjs:568-590`):

```js
for (const name of [" leading-space", "-leading-dash", "line\nbreak", "utf8-λ"]) {
  writeFileSync(path.join(repository, name), fixture.secret_sentinel);
}
const before = readFileSync(path.join(runRoot, "git-before.z"));
assert(before.includes(0));
assert.deepEqual(final, before);
assert(!result.output.includes(fixture.secret_sentinel));
```

The test's generated-contract fixture at `test/js/repository_verification.test.mjs:793-891` is the closest pattern for actual generator invocation, drift detection, byte restoration, and index preservation. Adapt it to assert read-back and materialized restore into fresh scratch. Extend fixtures to non-UTF-8 bytes where supported, rename pairs, stage-then-edit, deleted/binary files, symlink/type changes, mode changes, unmerged stages, baseline drift, and real subprocess error/signal/nonzero results. Existing UTF-8 odd-name coverage does not prove correct handling of invalid UTF-8 path bytes.

### Phase-local inventory / disposition record (document, transform)

**Analog:** Phase context contract in `176-CONTEXT.md` and closed/redacted outcomes in `script/verify_repository.mjs`.

Use one row per required path and exactly one of the five defined dispositions. Include comparison identity/basis, recovery result or limitation, and next owner/action. Keep partial merge details subordinate to a path row; retain uncertainty. Render only safe repository-relative paths or opaque IDs. Do not copy raw diffs, digest/size details, symlink targets, unsafe names, or private absolute pointers into committed evidence. Phase176 reports disposition intent; it does not claim cleanup happened.

### Generated-contract ownership map (document, transform)

**Analog:** `script/repository_artifact_policy.json:104-134`

The existing policy already binds canonical task owner, regeneration argv, output paths, and remediation command:

```json
{
  "canonical_source": "lib/mix/tasks/crosswake.contract.gen.ex",
  "regeneration_argv": [
    ["mix", "crosswake.contract.gen"],
    ["mix", "crosswake.contract.gen", "--dev"]
  ],
  "output_paths": ["..."],
  "remediation_command": "mix crosswake.contract.gen && mix crosswake.contract.gen --dev"
}
```

Reuse that registry; do not create a second one. Keep the ownership distinction clear: policy canonical source is the Mix task, while `lib/mix/tasks/crosswake.docs.sync.ex:81-97` names underlying documentation render sources and targets. Preserve changed projections and run any writing task only in scratch.

### Private recovery manifest / restore (manifest, file-I/O)

**Analogs:** `.planning/workstreams/quality-ratchet-release/milestones/v23.0-closeout/original-artifacts.json:1-8` and `script/verify_repository.mjs:236-249`.

The v23 manifest demonstrates a structured mapping from category and source to preserved original, but its historical content and digests are not a schema to copy into public evidence. Keep exact payload and sensitive metadata private. Apply owner-only directory/file modes and destination containment checks from the verifier pattern. Manifest entries should capture enough kind/mode/link and index/worktree metadata to reconstruct the baseline; verify by restoring and comparing materialized results. Do not follow symlinks or treat a patch/archive listing as recovery proof. If no authorized durable root is available, keep source intact and record recovery as blocked.

## Shared Patterns

- **Git evidence:** fixed argument arrays, raw Buffer/NUL parsing, bounded subprocess output, and explicit checks of `error`, `signal`, and `status`; never echo raw subprocess output on failure.
- **Privacy:** private payload and absolute recovery locations stay outside git; committed records use safe relative paths or opaque IDs and closed failure categories.
- **Artifact authority:** `script/repository_artifact_policy.json` owns transient, tracked, generated, forbidden, and fixture classes. Ignore matching alone does not establish disposability.
- **Recovery:** preserve first, restore into isolated fresh scratch, and compare bytes plus object kind, mode, link identity, and index/worktree partitions. Retain source if capture or restoration is incomplete.
- **Ownership boundary:** Phase176 inventories and recovers. Phase177 owns actual retirement/maintenance; Phase178 owns exact clean-source full verification and CI.

## No Analog Found

None for the listed responsibilities. The repository has no analog that fully handles invalid-UTF-8 pathname parsing plus exact private recovery of all Git/filesystem state; combine the bounded verifier and fixture patterns above, respecting their stated limitations.

## Metadata

**Analog search scope:** `script/`, `test/js/`, repository artifact policy, and v23 closeout manifest.  
**Tracked-source check:** every named code/manifest analog was verified with `git ls-files`; no ignored runtime mirror paths are cited.  
**Pattern extraction date:** 2026-10-11
