import { createHash } from 'node:crypto';

const digest = (value) => createHash('sha256').update(JSON.stringify(value)).digest('hex');
const fail = (message) => { throw new Error(message); };
const uniqueMap = (rows, key, label) => {
  if (!Array.isArray(rows)) fail(`${label} is missing`);
  const map = new Map(rows.map((row) => [row?.[key], row]));
  if (map.size !== rows.length || map.has(undefined)) fail(`${label} has duplicate or invalid identities`);
  return map;
};

export function validateSemanticSelection({ review, bundle, binding, baseCommit, baseTree }) {
  if (review?.status !== 'semantic-selection-complete' || review.baseCommit !== baseCommit || review.baseTree !== baseTree || review.captureId !== binding.captureId) fail('semantic selection is bound to a different source');
  if (bundle.captureId !== review.captureId || bundle.baseCommit !== baseCommit || bundle.baseTree !== baseTree) fail('private partitions are bound to a different source');
  const selected = uniqueMap(review.rows, 'rowId', 'semantic row selection');
  const partitions = uniqueMap(bundle.rows, 'rowId', 'private row partitions');
  const bindingRows = uniqueMap(binding.rows, 'rowId', 'public binding rows');
  if (selected.size !== partitions.size || bindingRows.size !== partitions.size) fail('semantic selection or binding lost preserved rows');
  for (const [rowId, part] of partitions) {
    const row = selected.get(rowId); const bound = bindingRows.get(rowId);
    if (!row || !bound || row.path !== part.rel || !row.owner || !row.nextCheck || row.preservation?.headIndexWorktreeSeparate !== true || row.preservation?.privatePartitionRetained !== true || row.preservation?.workingSourceOverlaySelected !== false) fail('semantic row does not match its captured source identity');
    if (!part.partitions || !['head', 'index', 'worktree'].every((name) => part.partitions[name] && Object.hasOwn(part.partitions[name], 'bytes'))) fail('captured byte partition is missing');
    for (const name of ['head', 'index', 'worktree']) {
      const value = part.partitions[name];
      const actual = digest({ kind: value.kind, mode: value.mode, bytes: value.bytes ?? null });
      if (actual !== value.digest) fail('captured byte partition integrity check failed');
    }
    if (row.sourceOwned && (row.selectedAction !== 'retain-captured-units-privately; preserve exact pinned-source bytes' || row.preservation?.workingSourceOverlaySelected !== false)) fail('source row lacks an explicit preservation selection');
    if (!row.sourceOwned && row.selectedAction !== 'preserve-out-of-source-scope') fail('out-of-scope row selection is invalid');
  }
  const modes = uniqueMap(review.modes, 'mode', 'historical router modes');
  if (modes.size !== review.counts?.routerModes || [...modes.values()].some((mode) => mode.pinnedBaseRouterPresent !== false || !mode.requiredConsumerJob || !mode.nextCheck)) fail('historical mode selection is incomplete');
  const sourceRows = [...selected.values()].filter((row) => row.sourceOwned).length;
  const outOfScope = selected.size - sourceRows;
  if (review.counts?.inventoryRows !== selected.size || review.counts?.sourceRows !== sourceRows || review.counts?.outOfSourceRows !== outOfScope) fail('semantic row counts do not match the selected population');
  return { selected, partitions, bindingRows, sourceRows, outOfScope, modeCount: modes.size };
}

export function assertOverlayState({ selectedStatus, actual, overlay, base }) {
  const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  if (selectedStatus === 'safe-overlay') {
    if (!equal(actual, overlay)) fail('derived overlay bytes do not match the binder-computed result');
  } else if (!equal(actual, base)) fail('clone changed outside the exact binder-computed safe overlays');
}
