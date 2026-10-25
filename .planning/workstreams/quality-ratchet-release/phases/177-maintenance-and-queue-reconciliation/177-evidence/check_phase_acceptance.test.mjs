import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { validateAcceptance } from './check_phase_acceptance.mjs';

function bindDigest(binding) {
  const payload = { ...binding };
  delete payload.bindingDigest;
  return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
}

function fixture() {
  const ids = ['row-a', 'row-b'];
  const rows = ids.map((rowId, index) => ({ rowId, sourceOwned: index === 0, nextAction: 'retain and verify' }));
  const modes = [{ mode: 'inspect', requiredConsumerJob: '177-02', nextCheck: 'compare reader' }];
  const value = {
    summaryStatuses: Array.from({ length: 7 }, (_, index) => [`177-${String(index < 6 ? index + 1 : 8).padStart(2, '0')}-SUMMARY.md`, 'complete']),
    inventory: { rows: ids.map((rowId) => ({ rowId })) },
    maintenance: { rows, retirementCandidates: modes.map((mode) => ({ ...mode, disposition: 'retain' })), gates: { sourceChangeEligibleCandidates: 0, phase178Claimed: false, requirementCompletionClaimed: false } },
    binding: {
      status: 'complete-qualified', baseCommit: 'base', baseTree: 'tree', selectedCount: 2,
      selectedRowIds: ids,
      counts: { applicable: 1, retainedPrivately: 1, unresolved: 0, preservedOutOfScope: 1, previouslyBlockedConflicts: 0 },
      rows: ids.map((rowId, index) => ({ rowId, status: index === 0 ? 'source-retained-privately' : 'preserved-out-of-source-scope' })),
      patches: [
        { owner: '177-02', status: 'recorded', changedFiles: 1, replayStatus: 'passed' },
        { owner: '177-03', status: 'recorded', changedFiles: 1, replayStatus: 'passed' },
        { owner: '177-05', status: 'recorded', changedFiles: 1, replayStatus: 'passed' },
      ],
    },
    semantic: {
      status: 'semantic-selection-complete', baseCommit: 'base', baseTree: 'tree',
      counts: { inventoryRows: 2, sourceRows: 1, outOfSourceRows: 1, routerModes: 1, previouslyBlockedConflicts: 0 },
      rows: rows.map((row, index) => ({ ...row, sourceOwned: index === 0, selectedAction: index === 0 ? 'retain-captured-units-privately; preserve exact pinned-source bytes' : 'preserve-out-of-source-scope', nextCheck: 'verify owner', preservation: { headIndexWorktreeSeparate: true, privatePartitionRetained: true, workingSourceOverlaySelected: false } })), modes,
    },
    candidate: {
      status: 'bounded-current-path-proof-complete',
      supportedGenericEntryProof: { ...Object.fromEntries(['status', 'candidate', 'receipt', 'gate'].map((name) => [name, { positive: 'actual positive entry', denied: 'actual denied entry' }])), liveWriterCalls: 0 },
      verification: { mix: { result: 'pass', tests: 43, failures: 0 }, workflowIntegrity: { result: 'pass', checks: 98, failures: 0 } },
      plan93: { historicalVerdict: 'unchanged; no new verdict established', readerComparison: 'unproven' },
    },
    mirror: {
      status: 'complete-bounded-review',
      source: { baseCommit: 'base', baseTree: 'tree', sourceBindingStatus: 'complete-qualified', selectedRows: 2, privateSourceRows: 1, preservedOutOfScopeRows: 1, previousConflictsPreserved: 0, currentSourceStatusEntries: [], productionSourceChanges: 0 },
      actualEntry: { exitCode: 1, gitStatusUnchanged: true, result: 'unsupported entry', sideEffects: { credentialsRead: false, networkRequests: false, evidenceWrites: false, approvalConsumption: false } },
      supportedCurrentPathEvidence: { tests: 43, failures: 0, checks: 98, failed: 0 },
      modeRecords: modes.map((mode) => ({ mode: mode.mode, selectedAction: 'retain', retirementClaim: false })),
    },
    queue: {
      schemaVersion: 1, status: 'complete', repository: 'szTheory/crosswake', source: 'gh api graphql read-only subprocess', observationStartedAt: '2026-10-12T15:00:00Z', observationCompletedAt: '2026-10-12T15:00:02Z',
      counts: { issues: 1, pullRequests: 0 }, objects: [{ kind: 'issue', id: 'issue-id-24', number: 24, updatedAt: '2026-10-12T14:00:00Z', url: 'https://github.com/szTheory/crosswake/issues/24', relatedPullRequestNumbers: [], disposition: { nextAction: 'inspect one exact claim', category: 'retain_pending_diagnosis', rationale: 'Keep visible pending diagnosis.', accountableRole: 'maintainer', trigger: 'When local evidence changes.', evidenceRef: 'https://github.com/szTheory/crosswake/issues/24', releaseProposal: false } }],
      refresh: { status: 'matched', refreshedAt: '2026-10-12T15:00:02Z', counts: { issues: 1, pullRequests: 0 }, changedObjectCount: 0 },
    },
    liveQueue: {
      status: 'complete', objects: [{ kind: 'issue', id: 'issue-id-24', number: 24, updatedAt: '2026-10-12T14:00:00Z', url: 'https://github.com/szTheory/crosswake/issues/24', relatedPullRequestNumbers: [] }],
      refresh: { status: 'matched', counts: { issues: 1, pullRequests: 0 }, changedObjectCount: 0, refreshedAt: '2026-10-12T15:00:02Z' },
    },
    active: { valid: true, currentCommand: '$gsd-execute-phase 177 --ws quality-ratchet-release' },
    handoff: { nextCommand: '$gsd-discuss-phase 178 --ws quality-ratchet-release', condition: 'after independent verification passes' },
    sourceProof: { head: 'base', statusPaths: ['README.md', 'docs/COMPANION-PUBLISH-RUNBOOK.md', 'docs/RELEASE-INCIDENT-RESPONSE.md', 'test/crosswake/guides/release_boundaries_test.exs', 'test/crosswake/release_candidate/companion_receipt_test.exs', 'test/crosswake/release_candidate/evidence_gate_test.exs'], genericTests: { tests: 43, failures: 0 }, docsTests: { tests: 21, failures: 0 }, workflow: { checks: 98, failures: 0 } },
    historic: { rel10: 'BREACHED', parkedAdopter: true },
  };
  value.binding.bindingDigest = bindDigest(value.binding);
  return value;
}

test('accepts complete joined evidence while keeping Phase 178 proof future work', () => {
  const result = validateAcceptance(fixture());
  assert.deepEqual(result.errors, []);
  assert.equal(result.metrics.inventoryRows, 2);
  assert.equal(result.metrics.genericEntryPaths, 4);
});

test('rejects a missing maintenance row', () => {
  const value = fixture();
  value.maintenance.rows.pop();
  assert.match(validateAcceptance(value).errors.join('\n'), /row coverage/i);
});

test('rejects duplicate queue identities even when counts match', () => {
  const value = fixture();
  value.queue.objects.push({ ...value.queue.objects[0] });
  assert.match(validateAcceptance(value).errors.join('\n'), /duplicate queue/i);
});

test('rejects a roster that changed during the fresh read-only refresh', () => {
  const value = fixture();
  value.liveQueue.objects[0].number = 25;
  assert.match(validateAcceptance(value).errors.join('\n'), /fresh read-only queue refresh/i);
});

test('rejects changed decision-bearing metadata even when updatedAt is unchanged', () => {
  for (const [field, changed] of [
    ['checkState', 'FAILURE'], ['headOid', 'abcdef0123456789'], ['baseRefName', 'release/other'],
    ['relatedIssueNumbers', [25]], ['failedChecks', ['required-check']],
  ]) {
    const value = fixture();
    const item = { kind: 'pull_request', id: 'pr-id-24', number: 24, updatedAt: '2026-10-12T14:00:00Z', url: 'https://github.com/szTheory/crosswake/pull/24', headRefName: 'branch', headOid: 'abcdef0123456780', baseRefName: 'main', mergeable: 'MERGEABLE', checkState: 'SUCCESS', failedChecks: [], relatedIssueNumbers: [24] };
    const live = { ...item, [field]: changed };
    value.queue.objects.push({ ...item, disposition: { category: 'retain_pending_diagnosis', rationale: 'Keep visible pending diagnosis.', accountableRole: 'maintainer', nextAction: 'Inspect the exact claim.', trigger: 'When evidence changes.', evidenceRef: 'https://github.com/szTheory/crosswake/pull/24', releaseProposal: false } });
    value.queue.counts = { issues: 1, pullRequests: 1 };
    value.queue.refresh.counts = { issues: 1, pullRequests: 1 };
    value.liveQueue.objects.push(live);
    value.liveQueue.refresh.counts = { issues: 1, pullRequests: 1 };
    assert.match(validateAcceptance(value).errors.join('\n'), /fresh read-only queue refresh/i, field);
  }
});

test('accepts reordered equivalent decision-bearing collections after normalization', () => {
  const value = fixture();
  const item = { kind: 'pull_request', id: 'pr-id-24', number: 24, updatedAt: '2026-10-12T14:00:00Z', url: 'https://github.com/szTheory/crosswake/pull/24', headRefName: 'branch', headOid: 'abcdef0123456780', baseRefName: 'main', mergeable: 'MERGEABLE', checkState: 'SUCCESS', failedChecks: [], relatedIssueNumbers: [24, 25] };
  value.queue.objects.push({ ...item, disposition: { category: 'retain_pending_diagnosis', rationale: 'Keep visible pending diagnosis.', accountableRole: 'maintainer', nextAction: 'Inspect the exact claim.', trigger: 'When evidence changes.', evidenceRef: 'https://github.com/szTheory/crosswake/pull/24', releaseProposal: false } });
  value.queue.counts = { issues: 1, pullRequests: 1 };
  value.queue.refresh.counts = { issues: 1, pullRequests: 1 };
  value.liveQueue.objects.push({ ...item, failedChecks: [], relatedIssueNumbers: [25, 24] });
  value.liveQueue.refresh.counts = { issues: 1, pullRequests: 1 };
  assert.deepEqual(validateAcceptance(value).errors, []);
});

test('strict queue dispositions require every field, valid enums, and bounded release flags', () => {
  for (const field of ['category', 'rationale', 'accountableRole', 'nextAction', 'trigger', 'evidenceRef', 'releaseProposal']) {
    const value = fixture();
    delete value.queue.objects[0].disposition[field];
    assert.match(validateAcceptance(value).errors.join('\n'), /strict queue inventory validation/i, field);
  }
  const wrongEnum = fixture();
  wrongEnum.queue.objects[0].disposition.category = 'maybe';
  assert.match(validateAcceptance(wrongEnum).errors.join('\n'), /strict queue inventory validation/i);
  const wrongFlag = fixture();
  wrongFlag.queue.objects[0].disposition.releaseProposal = 'false';
  assert.match(validateAcceptance(wrongFlag).errors.join('\n'), /strict queue inventory validation/i);
});

test('preserves issue and pull request identity when both use the same number', () => {
  const value = fixture();
  const pr = { kind: 'pull_request', id: 'pr-id-24', number: 24, updatedAt: '2026-10-12T14:00:00Z', url: 'https://github.com/szTheory/crosswake/pull/24', headRefName: 'branch', headOid: 'abcdef0123456780', baseRefName: 'main', mergeable: 'MERGEABLE', checkState: 'SUCCESS', failedChecks: [], relatedIssueNumbers: [], disposition: { category: 'retain_pending_diagnosis', rationale: 'Keep visible pending diagnosis.', accountableRole: 'maintainer', nextAction: 'Inspect the exact claim.', trigger: 'When evidence changes.', evidenceRef: 'https://github.com/szTheory/crosswake/pull/24', releaseProposal: false } };
  value.queue.objects.push(pr);
  value.queue.counts = { issues: 1, pullRequests: 1 };
  value.queue.refresh.counts = { issues: 1, pullRequests: 1 };
  value.liveQueue.objects.push({ ...pr, disposition: undefined });
  value.liveQueue.refresh.counts = { issues: 1, pullRequests: 1 };
  assert.deepEqual(validateAcceptance(value).errors, []);
});

test('rejects forged source digests and per-row disposition tampering', () => {
  const wrongDigest = fixture();
  wrongDigest.binding.bindingDigest = 'nonempty-but-forged';
  assert.match(validateAcceptance(wrongDigest).errors.join('\n'), /digest does not match/i);
  const wrongRow = fixture();
  wrongRow.binding.rows[0].status = 'preserved-out-of-source-scope';
  wrongRow.binding.bindingDigest = bindDigest(wrongRow.binding);
  assert.match(validateAcceptance(wrongRow).errors.join('\n'), /per-row disposition/i);
});

test('rejects a stale next command', () => {
  const value = fixture();
  value.handoff.nextCommand = '$gsd-plan-phase 177 --ws quality-ratchet-release';
  assert.match(validateAcceptance(value).errors.join('\n'), /handoff command/i);
});

test('rejects an unbound source patch', () => {
  const value = fixture();
  value.binding.baseCommit = 'another-base';
  assert.match(validateAcceptance(value).errors.join('\n'), /source binding/i);
});

test('rejects a softened historical Phase 175 breach', () => {
  const value = fixture();
  value.historic.rel10 = 'PASSED';
  assert.match(validateAcceptance(value).errors.join('\n'), /historical Phase 175/i);
});

test('rejects zero generic actual-entry cases', () => {
  const value = fixture();
  value.candidate.supportedGenericEntryProof = {};
  assert.match(validateAcceptance(value).errors.join('\n'), /actual-entry proof/i);
});

test('rejects incomplete source delivery and stale active instructions', () => {
  const partial = fixture();
  partial.sourceProof.statusPaths = ['README.md'];
  assert.match(validateAcceptance(partial).errors.join('\n'), /source overlay/i);
  const stale = fixture();
  stale.active.valid = false;
  assert.match(validateAcceptance(stale).errors.join('\n'), /active guidance/i);
});
