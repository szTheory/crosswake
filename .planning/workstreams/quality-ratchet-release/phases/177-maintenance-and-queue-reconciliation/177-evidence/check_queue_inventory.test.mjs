import assert from 'node:assert/strict';
import { mkdtemp, chmod, writeFile, rm } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import test from 'node:test';
import { fileURLToPath } from 'node:url';
import { validateQueueInventory } from './check_queue_inventory.mjs';

const here = path.dirname(fileURLToPath(import.meta.url));
const collector = path.join(here, 'collect_queue.mjs');

async function withFakeGh(scenario, run) {
  const dir = await mkdtemp(path.join(os.tmpdir(), 'crosswake-queue-gh-'));
  const ghPath = path.join(dir, 'gh');
  await writeFile(ghPath, `#!/usr/bin/env node
const args = process.argv.slice(2);
if (args[0] !== 'api' || args[1] !== 'graphql' || args.some(a => /mutation\\b|addLabels|removeLabels|closeIssue|mergePullRequest|createComment|updateIssue|assignUser/i.test(a))) {
  process.stderr.write('rejected non-read argv'); process.exit(91);
}
const q = args.find(a => a.startsWith('query='))?.slice(6) || '';
const kind = q.includes('pullRequests') ? 'pullRequests' : 'issues';
const after = q.match(/after: "([^"]+)"/)?.[1] || null;
const scenario = process.env.FAKE_GH_SCENARIO;
let result = { data: { repository: { nameWithOwner: 'owner/repo' } } };
const node = kind === 'issues'
  ? { id: 'I_1', number: 7, state: 'OPEN', updatedAt: '2026-10-12T12:00:00Z', url: 'https://github.com/owner/repo/issues/7', closedByPullRequestsReferences: { totalCount: 0, pageInfo: { hasNextPage: false }, nodes: [] } }
  : { id: 'P_7', number: 7, state: 'OPEN', updatedAt: '2026-10-12T12:00:00Z', url: 'https://github.com/owner/repo/pull/7', headRefName: 'work', headRefOid: 'abc123', baseRefName: 'main', mergeable: 'CONFLICTING', closingIssuesReferences: { totalCount: 0, pageInfo: { hasNextPage: false }, nodes: [] }, statusCheckRollup: { state: 'FAILURE', contexts: { pageInfo: { hasNextPage: false }, nodes: [{ __typename: 'CheckRun', name: 'ci / test', conclusion: 'FAILURE' }] } } };
if (scenario === 'malformed') { process.stdout.write('{'); process.exit(0); }
if (scenario === 'denied') { process.stderr.write('HTTP 403'); process.exit(1); }
if (scenario === 'nonzero') { process.stderr.write('process failed'); process.exit(2); }
if (scenario === 'null-connection') result.data.repository[kind] = null;
else if (scenario === 'missing-page') result.data.repository[kind] = { totalCount: 1, pageInfo: { hasNextPage: true, endCursor: null }, nodes: [node] };
else if (scenario === 'cursor-loop' && after) result.data.repository[kind] = { totalCount: 2, pageInfo: { hasNextPage: true, endCursor: 'same' }, nodes: [{ ...node, id: 'second', number: 8, url: node.url.replace('/7', '/8') }] };
else if (scenario === 'cursor-loop') result.data.repository[kind] = { totalCount: 2, pageInfo: { hasNextPage: true, endCursor: 'same' }, nodes: [node] };
else if (scenario === 'duplicate') result.data.repository[kind] = { totalCount: 1, pageInfo: { hasNextPage: false, endCursor: null }, nodes: [node, node] };
else if (scenario === 'two-pages' && after) result.data.repository[kind] = { totalCount: 2, pageInfo: { hasNextPage: false, endCursor: null }, nodes: [{ ...node, id: 'second', number: 8, url: node.url.replace('/7', '/8') }] };
else if (scenario === 'two-pages') result.data.repository[kind] = { totalCount: 2, pageInfo: { hasNextPage: true, endCursor: kind + '-next' }, nodes: [node] };
else if (scenario === 'second-page') result.data.repository[kind] = { totalCount: 2, pageInfo: { hasNextPage: false, endCursor: null }, nodes: [node] };
else result.data.repository[kind] = { totalCount: 1, pageInfo: { hasNextPage: false, endCursor: null }, nodes: [node] };
process.stdout.write(JSON.stringify(result));
`);
  await chmod(ghPath, 0o755);
  try {
    await run({ dir, ghPath });
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}

function collect(env) {
  return spawnSync(process.execPath, [collector, '--repo', 'owner/repo'], {
    encoding: 'utf8', env: { ...process.env, ...env },
  });
}

test('real gh subprocess contract keeps issue #7 separate from PR #7', async () => {
  await withFakeGh('ok', async ({ dir }) => {
    const result = collect({ PATH: `${dir}:${process.env.PATH}` });
    assert.equal(result.status, 0, `${result.stderr} ${result.stdout}`);
    const inventory = JSON.parse(result.stdout);
    assert.equal(inventory.status, 'complete');
    assert.deepEqual(inventory.counts, { issues: 1, pullRequests: 1 });
    assert.deepEqual(inventory.objects.map(x => `${x.kind}:${x.number}`).sort(), ['issue:7', 'pull_request:7']);
    assert.equal(inventory.objects.find(x => x.kind === 'pull_request').headOid, 'abc123');
    assert.equal(inventory.objects.some(x => 'body' in x || 'title' in x || 'author' in x), false);
  });
});

test('real gh subprocess exhausts both independently paginated connections', async () => {
  await withFakeGh('two-pages', async ({ dir }) => {
    const result = collect({ PATH: `${dir}:${process.env.PATH}`, FAKE_GH_SCENARIO: 'two-pages' });
    assert.equal(result.status, 0, `${result.stderr} ${result.stdout}`);
    const inventory = JSON.parse(result.stdout);
    assert.deepEqual(inventory.counts, { issues: 2, pullRequests: 2 });
    assert.equal(inventory.objects.length, 4);
    assert.equal(inventory.status, 'complete');
  });
});

for (const scenario of ['duplicate', 'null-connection', 'malformed', 'denied', 'nonzero', 'missing-page', 'cursor-loop']) {
  test(`${scenario} subprocess result cannot validate as a complete empty queue`, async () => {
    await withFakeGh(scenario, async ({ dir }) => {
      const result = collect({ PATH: `${dir}:${process.env.PATH}`, FAKE_GH_SCENARIO: scenario });
      assert.notEqual(result.status, 0);
      assert.doesNotThrow(() => JSON.parse(result.stdout));
      const evidence = JSON.parse(result.stdout);
      assert.notEqual(evidence.status, 'complete');
    });
  });
}

test('collector rejects write-like gh argv', async () => {
  await withFakeGh('ok', async ({ dir }) => {
    const result = collect({ PATH: `${dir}:${process.env.PATH}`, FAKE_GH_SCENARIO: 'ok' });
    assert.equal(result.status, 0, `${result.stderr} ${result.stdout}`);
  });
});

function validInventory() {
  const disposition = {
    category: 'retain_pending_diagnosis',
    rationale: 'Current check state needs a named owner diagnosis.',
    accountableRole: 'release maintainer',
    nextAction: 'Release maintainer inspects the current failed check and records its cause.',
    trigger: 'Reopen when the current head or check result changes.',
    evidenceRef: 'https://github.com/owner/repo/pull/7',
    releaseProposal: false,
  };
  return {
    schemaVersion: 1, status: 'complete', repository: 'owner/repo', source: 'gh api graphql read-only subprocess',
    observationStartedAt: '2026-10-12T12:00:00.000Z', observationCompletedAt: '2026-10-12T12:01:00.000Z',
    counts: { issues: 1, pullRequests: 1 },
    refresh: { status: 'matched', refreshedAt: '2026-10-12T12:01:00.000Z', counts: { issues: 1, pullRequests: 1 }, changedObjectCount: 0 },
    objects: [
      { kind: 'issue', id: 'I_1', number: 7, updatedAt: '2026-10-12T12:00:00.000Z', url: 'https://github.com/owner/repo/issues/7', relatedPullRequestNumbers: [], disposition: { ...disposition, evidenceRef: 'https://github.com/owner/repo/issues/7' } },
      { kind: 'pull_request', id: 'P_7', number: 7, updatedAt: '2026-10-12T12:00:00.000Z', url: 'https://github.com/owner/repo/pull/7', headRefName: 'work', headOid: 'abc1234', baseRefName: 'main', mergeable: 'CONFLICTING', checkState: 'FAILURE', failedChecks: ['ci / test'], relatedIssueNumbers: [], disposition: { ...disposition, evidenceRef: 'https://github.com/owner/repo/pull/7' } },
    ],
  };
}

test('checker accepts actionable rows and keeps cross-kind numeric identities separate', () => {
  assert.deepEqual(validateQueueInventory(validInventory()), []);
});

test('checker rejects duplicate objects, missing actions, stale refresh and disallowed content', () => {
  const value = validInventory();
  value.objects.push({ ...value.objects[0] });
  delete value.objects[1].disposition.nextAction;
  value.objects[1].privateBody = 'must not be retained';
  value.refresh.status = 'drifting';
  assert.deepEqual(new Set(validateQueueInventory(value)), new Set(['refresh_not_matched', 'unexpected_object_field', 'disposition_field_missing', 'duplicate_identity', 'count_mismatch', 'nondeterministic_order']));
});

