#!/usr/bin/env node
import { spawnSync } from 'node:child_process';

const API_TIMEOUT_MS = 30_000;
const MAX_BUFFER = 8 * 1024 * 1024;
const PAGE_SIZE = 100;
const SAFE_FAILURES = new Set(['gh_unavailable', 'read_failed', 'invalid_json', 'invalid_shape', 'incomplete_page', 'cursor_loop', 'duplicate_identity', 'count_mismatch', 'repository_mismatch', 'roster_drift']);

function safeFailure(code) {
  return SAFE_FAILURES.has(code) ? code : 'read_failed';
}

function parseRepo(value) {
  const match = /^([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+)$/.exec(value || '');
  if (!match) throw new Error('repo must be an owner/name identifier');
  return { owner: match[1], name: match[2], fullName: `${match[1]}/${match[2]}` };
}

function quoteGraphql(value) {
  return JSON.stringify(value);
}

function pageQuery(kind, repo, cursor) {
  const connection = kind === 'issue'
    ? `issues(states: OPEN, first: ${PAGE_SIZE}, after: ${cursor === null ? 'null' : quoteGraphql(cursor)}) {
        totalCount pageInfo { hasNextPage endCursor }
        nodes { id number state updatedAt url closedByPullRequestsReferences(first: 20) { totalCount pageInfo { hasNextPage } nodes { number } } }
      }`
    : `pullRequests(states: OPEN, first: ${PAGE_SIZE}, after: ${cursor === null ? 'null' : quoteGraphql(cursor)}) {
        totalCount pageInfo { hasNextPage endCursor }
        nodes { id number state updatedAt url headRefName headRefOid baseRefName mergeable closingIssuesReferences(first: 20) { totalCount pageInfo { hasNextPage } nodes { number } } statusCheckRollup { state contexts(first: 100) { pageInfo { hasNextPage } nodes { __typename ... on CheckRun { name conclusion } ... on StatusContext { context state } } } } }
      }`;
  return `query { repository(owner: ${quoteGraphql(repo.owner)}, name: ${quoteGraphql(repo.name)}) { nameWithOwner ${connection} } }`;
}

function runGh(query) {
  const result = spawnSync('gh', ['api', 'graphql', '-f', `query=${query}`], {
    encoding: 'utf8', timeout: API_TIMEOUT_MS, maxBuffer: MAX_BUFFER,
  });
  if (result.error || result.status !== 0) throw new Error('read_failed');
  let parsed;
  try { parsed = JSON.parse(result.stdout); } catch { throw new Error('invalid_json'); }
  if (!parsed || parsed.errors?.length || !parsed.data?.repository) throw new Error('invalid_shape');
  return parsed.data.repository;
}

function safeNode(kind, node) {
  if (!node || typeof node.id !== 'string' || !Number.isSafeInteger(node.number) || node.number < 1 || node.state !== 'OPEN' || typeof node.updatedAt !== 'string' || typeof node.url !== 'string') throw new Error('invalid_shape');
  const out = {
    kind,
    id: node.id,
    number: node.number,
    updatedAt: node.updatedAt,
    url: node.url,
  };
  if (kind === 'issue') {
    out.relatedPullRequestNumbers = relationNumbers(node.closedByPullRequestsReferences);
  }
  if (kind === 'pull_request') {
    if (typeof node.headRefName !== 'string' || typeof node.headRefOid !== 'string' || typeof node.baseRefName !== 'string') throw new Error('invalid_shape');
    out.headRefName = node.headRefName;
    out.headOid = node.headRefOid;
    out.baseRefName = node.baseRefName;
    out.mergeable = node.mergeable;
    out.checkState = node.statusCheckRollup?.state ?? 'UNKNOWN';
    const checkConnection = node.statusCheckRollup?.contexts;
    const contexts = checkConnection?.nodes;
    if (Array.isArray(contexts)) {
      out.failedChecks = contexts.flatMap((context) => {
        if (context.__typename === 'CheckRun' && context.conclusion && context.conclusion !== 'SUCCESS' && context.conclusion !== 'NEUTRAL' && context.conclusion !== 'SKIPPED') return typeof context.name === 'string' ? [context.name] : [];
        if (context.__typename === 'StatusContext' && context.state && context.state !== 'SUCCESS' && context.state !== 'EXPECTED') return typeof context.context === 'string' ? [context.context] : [];
        return [];
      }).sort((a, b) => a.localeCompare(b));
      if (checkConnection.pageInfo?.hasNextPage === true) throw new Error('incomplete_page');
      if (node.statusCheckRollup?.state === 'FAILURE' && typeof checkConnection.pageInfo?.hasNextPage !== 'boolean') throw new Error('invalid_shape');
    } else if (node.statusCheckRollup?.state === 'FAILURE') {
      throw new Error('incomplete_page');
    } else {
      out.failedChecks = [];
    }
    out.relatedIssueNumbers = relationNumbers(node.closingIssuesReferences);
  }
  return out;
}

function relationNumbers(connection) {
  if (!connection || !Number.isSafeInteger(connection.totalCount) || connection.totalCount < 0 || !Array.isArray(connection.nodes) || !connection.pageInfo || typeof connection.pageInfo.hasNextPage !== 'boolean') throw new Error('invalid_shape');
  if (connection.pageInfo.hasNextPage || connection.nodes.length !== connection.totalCount) throw new Error('incomplete_page');
  const numbers = connection.nodes.map((item) => item?.number);
  if (numbers.some((number) => !Number.isSafeInteger(number) || number < 1) || new Set(numbers).size !== numbers.length) throw new Error('invalid_shape');
  return numbers.sort((a, b) => a - b);
}

function objectKey(object) { return `${object.kind}:${object.number}`; }

function compareObjects(a, b) {
  return a.kind.localeCompare(b.kind) || a.number - b.number || a.id.localeCompare(b.id);
}

function stableRoster(objects) {
  return objects.map((object) => JSON.stringify(object)).sort();
}

function readSnapshot(repo) {
  const all = [];
  const counts = {};
  for (const [kind, field] of [['issue', 'issues'], ['pull_request', 'pullRequests']]) {
    let cursor = null;
    let reportedCount;
    const seenCursors = new Set();
    const seenKeys = new Set();
    let exhausted = false;
    while (!exhausted) {
      const result = runGh(pageQuery(kind, repo, cursor));
      if (result.nameWithOwner?.toLowerCase() !== repo.fullName.toLowerCase()) throw new Error('repository_mismatch');
      const connection = result[field];
      if (!connection || !Number.isSafeInteger(connection.totalCount) || connection.totalCount < 0 || !Array.isArray(connection.nodes) || !connection.pageInfo || typeof connection.pageInfo.hasNextPage !== 'boolean') throw new Error('invalid_shape');
      if (reportedCount === undefined) reportedCount = connection.totalCount;
      else if (reportedCount !== connection.totalCount) throw new Error('count_mismatch');
      for (const raw of connection.nodes) {
        const object = safeNode(kind, raw);
        const key = objectKey(object);
        if (seenKeys.has(key)) throw new Error('duplicate_identity');
        seenKeys.add(key);
        all.push(object);
      }
      exhausted = !connection.pageInfo.hasNextPage;
      if (!exhausted) {
        const next = connection.pageInfo.endCursor;
        if (typeof next !== 'string' || next.length === 0 || seenCursors.has(next) || next === cursor) throw new Error('cursor_loop');
        seenCursors.add(next);
        cursor = next;
      }
      if (!exhausted && all.length > 100_000) throw new Error('incomplete_page');
    }
    if (all.filter((object) => object.kind === kind).length !== reportedCount) throw new Error('count_mismatch');
    counts[field] = reportedCount;
  }
  all.sort(compareObjects);
  return { counts, objects: all };
}

function blocked(repo, startedAt, failure) {
  return {
    schemaVersion: 1,
    status: 'blocked',
    blocker: safeFailure(failure),
    repository: repo.fullName,
    source: 'gh api graphql read-only subprocess',
    observationStartedAt: startedAt,
    observationCompletedAt: new Date().toISOString(),
    counts: { issues: null, pullRequests: null },
    objects: [],
    refresh: { status: 'not_completed' },
  };
}

export function collectQueue(repoValue, now = () => new Date().toISOString()) {
  const repo = parseRepo(repoValue);
  const startedAt = now();
  let initial;
  let refreshed;
  try {
    initial = readSnapshot(repo);
    refreshed = readSnapshot(repo);
  } catch (error) {
    const output = blocked(repo, startedAt, error.message);
    output.observationCompletedAt = now();
    return output;
  }
  const matches = JSON.stringify(stableRoster(initial.objects)) === JSON.stringify(stableRoster(refreshed.objects));
  const output = {
    schemaVersion: 1,
    status: matches ? 'complete' : 'drifting',
    repository: repo.fullName,
    source: 'gh api graphql read-only subprocess',
    observationStartedAt: startedAt,
    observationCompletedAt: now(),
    counts: { issues: refreshed.counts.issues, pullRequests: refreshed.counts.pullRequests },
    objects: refreshed.objects,
    refresh: {
      status: matches ? 'matched' : 'drifting',
      refreshedAt: now(),
      counts: { issues: refreshed.counts.issues, pullRequests: refreshed.counts.pullRequests },
      changedObjectCount: matches ? 0 : Math.abs(initial.objects.length - refreshed.objects.length) + refreshed.objects.filter((object, index) => JSON.stringify(object) !== JSON.stringify(initial.objects[index])).length,
    },
  };
  if (!matches) output.blocker = 'roster_drift';
  return output;
}

function main() {
  const args = process.argv.slice(2);
  const repoIndex = args.indexOf('--repo');
  if (args.length !== 2 || repoIndex !== 0 || !args[1]) {
    process.stdout.write(`${JSON.stringify({ status: 'blocked', blocker: 'invalid_shape', counts: { issues: null, pullRequests: null }, objects: [] })}\n`);
    process.exitCode = 2;
    return;
  }
  let output;
  try { output = collectQueue(args[1]); } catch { output = { status: 'blocked', blocker: 'invalid_shape', counts: { issues: null, pullRequests: null }, objects: [] }; }
  process.stdout.write(`${JSON.stringify(output)}\n`);
  if (output.status !== 'complete') process.exitCode = 2;
}

if (import.meta.url === `file://${process.argv[1]}`) main();
