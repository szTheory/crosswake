import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { validateSemanticSelection, assertOverlayState } from './source_reconciliation.mjs';

const digest = (value) => createHash('sha256').update(JSON.stringify(value)).digest('hex');
function fixture() {
  const baseCommit = 'a'.repeat(40); const baseTree = 'b'.repeat(40); const captureId = 'fixture-capture';
  const part = (rel, text) => {
    const snapshot = { kind: 'file', mode: 0o644, bytes: Buffer.from(text).toString('base64') };
    snapshot.digest = digest({ kind: snapshot.kind, mode: snapshot.mode, bytes: snapshot.bytes });
    return { rowId: rel, rel, partitions: { head: { ...snapshot }, index: { kind: 'absent', mode: null, bytes: null, digest: digest({ kind: 'absent', mode: null, bytes: null }) }, worktree: { ...snapshot } } };
  };
  const rows = [
    { rowId: 'source.ex', path: 'source.ex', owner: 'Phase 177 source owner', sourceOwned: true, selectedAction: 'retain-captured-units-privately; preserve exact pinned-source bytes', nextCheck: 'Use the current supported job.', preservation: { headIndexWorktreeSeparate: true, privatePartitionRetained: true, workingSourceOverlaySelected: false } },
    { rowId: 'private.json', path: 'private.json', owner: 'repository owner', sourceOwned: false, selectedAction: 'preserve-out-of-source-scope', nextCheck: 'Keep out of scope.', preservation: { headIndexWorktreeSeparate: true, privatePartitionRetained: true, workingSourceOverlaySelected: false } },
  ];
  const bundle = { captureId, baseCommit, baseTree, rows: [part('source.ex', 'head'), part('private.json', 'other')] };
  const review = { status: 'semantic-selection-complete', captureId, baseCommit, baseTree, counts: { inventoryRows: 2, sourceRows: 1, outOfSourceRows: 1, routerModes: 1 }, rows, modes: [{ mode: 'old-mode', pinnedBaseRouterPresent: false, requiredConsumerJob: 'fixture job', nextCheck: 'Use a preserved fixture.' }] };
  const binding = { captureId, baseCommit, baseTree, rows: rows.map((row) => ({ rowId: row.rowId, status: 'blocked-conflict' })) };
  return { baseCommit, baseTree, review, bundle, binding };
}

test('semantic selection rejects a different base', () => {
  const f = fixture();
  assert.throws(() => validateSemanticSelection({ ...f, baseCommit: 'c'.repeat(40) }), /different source/);
});

test('semantic selection rejects omitted and duplicate rows', () => {
  const f = fixture();
  assert.throws(() => validateSemanticSelection({ ...f, review: { ...f.review, rows: f.review.rows.slice(0, 1), counts: { ...f.review.counts, inventoryRows: 1, sourceRows: 1, outOfSourceRows: 0 } } }), /lost preserved rows/);
  assert.throws(() => validateSemanticSelection({ ...f, review: { ...f.review, rows: [...f.review.rows, f.review.rows[0]], counts: { ...f.review.counts, inventoryRows: 3, sourceRows: 2, outOfSourceRows: 1 } } }), /duplicate or invalid identities/);
});

test('semantic selection rejects tampered bytes and a lost partition', () => {
  const f = fixture(); const changed = structuredClone(f.bundle);
  changed.rows[0].partitions.head.bytes = Buffer.from('tampered').toString('base64');
  assert.throws(() => validateSemanticSelection({ ...f, bundle: changed }), /integrity check failed/);
  const lost = structuredClone(f.bundle); delete lost.rows[0].partitions.worktree;
  assert.throws(() => validateSemanticSelection({ ...f, bundle: lost }), /partition is missing/);
});

test('unexpected clone changes cannot be reclassified as retained overlays', () => {
  assert.throws(() => assertOverlayState({ selectedStatus: 'blocked-conflict', actual: { kind: 'file', bytes: 'changed' }, overlay: null, base: { kind: 'file', bytes: 'base' } }), /clone changed outside/);
  assert.throws(() => assertOverlayState({ selectedStatus: 'safe-overlay', actual: { kind: 'file', bytes: 'unexpected' }, overlay: { kind: 'file', bytes: 'selected' }, base: { kind: 'file', bytes: 'base' } }), /binder-computed/);
});

test('reconciliation failures never echo private row paths or payloads', () => {
  const sentinel = '/private/phase177/PRIVATE_PATH_SENTINEL answer=PRIVATE_PAYLOAD_SENTINEL';
  assert.throws(() => assertOverlayState({ selectedStatus: 'blocked-conflict', actual: { kind: 'file', bytes: sentinel }, overlay: null, base: { kind: 'file', bytes: 'base' } }), (error) => {
    assert.equal(error.message, 'clone changed outside the exact binder-computed safe overlays');
    assert.doesNotMatch(error.message, /PRIVATE_PATH_SENTINEL|PRIVATE_PAYLOAD_SENTINEL/);
    return true;
  });
});
