# Phase 178: Clean Checkout and Final CI - Pattern Map

**Mapped:** 2026-10-12  
**Files analyzed:** 4 evidence joins plus existing verifier/CI contracts  
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| Phase178 local source/run/CI evidence join (phase-local `.mjs`/JSON) | utility | transform | Phase177 `check_phase_acceptance.mjs` | role-match |
| Phase178 evidence test | test | transform | Phase177 `check_phase_acceptance.test.mjs` | role-match |
| Complete local-run evidence | evidence | request-response | tracked `script/verify_repository.mjs` and its tests | exact contract |
| Hosted-CI graph/source evidence | evidence | transform | tracked CI manifest/classifier/validator/workflow | exact contract |

The first two are implied phase-local evidence artifacts, not product source changes. Phase177 evidence scripts live under planning and are not tracked source; use their behavior as implementation precedent only. Production analog paths below resolve inside the attested clone `/private/tmp/crosswake-177-source/crosswake`, and were confirmed with that clone's `git ls-files`.

## Pattern Assignments

### Phase-local acceptance/evidence join (utility, transform)

**Analog:** Phase177 `177-evidence/check_phase_acceptance.mjs` (local evidence precedent; not a source edit target).

It imports narrow validators, builds a single `errors` array, checks joins by stable identities and exact source binding, and returns metrics/errors rather than silently coercing missing inputs. The real public entry is `validateAcceptance(input)` at lines 65 onward; imports and expected six-path list are lines 1-29.

```js
export function validateAcceptance(input) {
  const errors = [];
  const { inventory, maintenance, binding, semantic, candidate, mirror, queue, active, handoff, sourceProof, historic } = input ?? {};
  add(errors, Array.isArray(input?.summaryStatuses) && input.summaryStatuses.length === 7 &&
    input.summaryStatuses.every(([, status]) => status === 'complete'),
    'One or more completed stream summaries are missing or not marked complete.');
  // Join each evidence roster by row identity; require binding and semantic source IDs to agree.
```

**Carry forward:** join on exact commit/tree/run attempt plus per-job observed checkout identity; derive pass only after all required fields, expected jobs and local verifier stages are accounted for. Emit a compact allowlisted result and safe blocker codes. Do not serialize raw command output, status paths, credentials, or private logs.

### Tests for evidence joins (test, transform)

**Analog:** Phase177 `177-evidence/check_phase_acceptance.test.mjs` (local precedent; not tracked source).

Its `fixture()` builds full joined evidence, with tests for a valid result and single-dimension tampering. Lines 67-92 show acceptance, missing-row rejection, duplicate identities despite matching counts, and refresh drift. `source_reconciliation.test.mjs` lines 24-48 additionally checks wrong base, omitted/duplicate rows, tampered bytes and private-data-safe errors.

```js
test('rejects duplicate queue identities even when counts match', () => {
  const value = fixture();
  value.queue.objects.push({ ...value.queue.objects[0] });
  value.queue.counts.issues = 2;
  assert.match(validateAcceptance(value).errors.join('\\n'), /duplicate queue identity/i);
});
```

For Phase178, vary commit vs tree identity, missing per-job checkout proof, stale attempt, omitted CI leaf, unauthorized skip, incomplete pagination, and blocked/nonzero verifier result. Keep fixtures synthetic and assert public output excludes private paths/log text.

### Complete repository verifier (utility, request-response)

**Analog:** tracked `script/verify_repository.mjs`, `runVerification(options = {})` lines 440-498; regression suite `test/js/repository_verification.test.mjs`.

The function validates manifest/workflow parity and artifact policy, snapshots the repo, rejects a dirty `--all` baseline before proof work, then runs declared stages with dependency blocking and retained logs. Stage IDs are closed at lines 14-15. Key test at `test/js/repository_verification.test.mjs:605-622` proves dirty full-run rejection before any stage starts; lines 624-646 exercise NUL-delimited status snapshots and preservation of the index.

```js
if (selection === "all" && before.length > 0) {
  const record = { result: "FAIL", purpose: "repository-cleanliness",
    remediation_command: "git status --short" };
  try { gitSnapshot(root, path.join(runRoot, "git-final.z")); } catch { /* fail closed */ }
  if (!suppliedRunRoot) rmSync(runRoot, { recursive: true, force: true });
  return { status: 1, output: renderSummary([record]), records: [record] };
}
```

Invoke the existing `script/verify_repository.sh --all` only from the fresh exact-commit checkout. The result is the single complete-run authority; stage-by-stage runs are diagnostics. Retain raw logs privately and publish only approved summaries.

### Hosted CI graph and source identity (evidence, transform)

**Analogs:** tracked `script/ci_leaf_manifest.json`, `script/classify_ci_change.py`, `script/check_ci_leaf_manifest.py`, `.github/workflows/crosswake-ci.yml`.

The manifest/validator define the closed proof roster and umbrella; validator self-tests at `check_ci_leaf_manifest.py:579-649` mutate missing/extra jobs, control nodes, irrelevance reasons and stage parity. The classifier returns full proof for malformed/empty diff and unallowlisted or mixed paths (`classify_ci_change.py:175-188`); never infer documentation-only for the six-file candidate. Workflow lines 174-189 show `release-candidate-full-proof` checks out PR head SHA, while ordinary pull-request jobs use event checkout semantics. Preserve that per-job distinction.

**Join fields:** canonical repo, workflow path/version, event/PR, head/base, runner-observed commit/tree per job, run ID and attempt, check identity, observation time, complete paginated jobs/checks, current required policy. Require `classify-change`, `merge-blocking-crosswake-ci`, every manifest leaf, and only classifier/manifest-authorized skips. Run identity cannot be replaced by a branch, badge, run-level head SHA, or tree equality.

## Shared Patterns

- **Fail closed:** Use exact immutable identities and closed rosters; missing, stale, drifting, failed, neutral, cancelled, unapproved-skip, or incomplete evidence yields blocked/non-passing.
- **Privacy:** Phase177 acceptance helpers use bounded error strings and identifiers. Keep raw subprocess logs/status snapshots in the owner-only capture root; no raw filenames or command output in the public phase report.
- **Clean proof:** Compare HEAD, tree and index independently from NUL-delimited status, and inspect ignored outputs under the existing artifact policy. Do not call a modified preparation clone a clean proof checkout.

## No Analog Found

None for the overall Phase178 evidence chain: existing helpers cover source qualification, clean full verification, and CI graph structure. The new cross-source join remains phase-local glue; keep it small and evidence-only.

## Metadata

**Analog search scope:** Phase177 `177-evidence`; attested clone `script/`, `test/js/`, `.github/workflows/`.  
**Pattern extraction:** 2026-10-12.  
**Tracked-source gate:** verifier/CI analogs verified tracked in attested clone; Phase177 evidence scripts are explicitly local planning evidence, not tracked source.

