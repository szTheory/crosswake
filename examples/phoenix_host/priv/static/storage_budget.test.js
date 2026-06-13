import test from 'node:test';
import assert from 'node:assert';
import { canSatisfyJournalReserve } from './storage_logic.js';

test('canSatisfyJournalReserve returns false if remaining space is less than reserve', () => {
  const estimateQuota = 1000;
  const estimateUsage = 800;
  const journalReserve = 300;
  // remaining = 200, which is < 300
  assert.strictEqual(canSatisfyJournalReserve(estimateQuota, estimateUsage, journalReserve), false);
});

test('canSatisfyJournalReserve returns true if sufficient space exists', () => {
  const estimateQuota = 1000;
  const estimateUsage = 500;
  const journalReserve = 300;
  // remaining = 500, which is >= 300
  assert.strictEqual(canSatisfyJournalReserve(estimateQuota, estimateUsage, journalReserve), true);
});

test('canSatisfyJournalReserve returns true if exactly equal space exists', () => {
  const estimateQuota = 1000;
  const estimateUsage = 700;
  const journalReserve = 300;
  // remaining = 300, which is >= 300
  assert.strictEqual(canSatisfyJournalReserve(estimateQuota, estimateUsage, journalReserve), true);
});
