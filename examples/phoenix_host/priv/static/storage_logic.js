/**
 * Evaluates whether the remaining storage quota satisfies the requested sync journal reserve.
 *
 * @param {number} estimateQuota - The total storage quota available to the origin (in bytes).
 * @param {number} estimateUsage - The amount of storage already used by the origin (in bytes).
 * @param {number} journalReserve - The amount of space strictly reserved for the sync journal (in bytes).
 * @returns {boolean} True if the reserve can be satisfied, false otherwise.
 */
export function canSatisfyJournalReserve(estimateQuota, estimateUsage, journalReserve) {
  if (typeof estimateQuota !== 'number' || typeof estimateUsage !== 'number' || typeof journalReserve !== 'number') {
    return false;
  }
  
  const remaining = estimateQuota - estimateUsage;
  return remaining >= journalReserve;
}
