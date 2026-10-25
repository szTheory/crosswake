#!/usr/bin/env node
import { readFile } from 'node:fs/promises';

const TOP_KEYS = new Set(['schemaVersion', 'status', 'blocker', 'repository', 'source', 'observationStartedAt', 'observationCompletedAt', 'counts', 'objects', 'refresh']);
const OBJECT_KEYS = new Set(['kind', 'id', 'number', 'updatedAt', 'url', 'headRefName', 'headOid', 'baseRefName', 'mergeable', 'checkState', 'failedChecks', 'relatedIssueNumbers', 'relatedPullRequestNumbers', 'disposition']);
const DISPOSITION_KEYS = new Set(['category', 'rationale', 'accountableRole', 'nextAction', 'trigger', 'evidenceRef', 'releaseProposal']);
const LINK_RE = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;

const isText = (value) => typeof value === 'string' && value.trim().length > 0;
const parseDate = (value) => isText(value) && Number.isFinite(Date.parse(value));
const key = (object) => `${object.kind}:${object.number}`;
const compare = (a, b) => a.kind.localeCompare(b.kind) || a.number - b.number || a.id.localeCompare(b.id);

export function validateQueueInventory(value, { requireDispositions = true } = {}) {
  const errors = [];
  const add = (code) => { if (!errors.includes(code)) errors.push(code); };
  if (!value || typeof value !== 'object' || Array.isArray(value)) return ['invalid_document'];
  if (Object.keys(value).some((name) => !TOP_KEYS.has(name))) add('unexpected_top_level_field');
  if (value.schemaVersion !== 1 || value.status !== 'complete') add('not_complete');
  if (!LINK_RE.test(value.repository || '') || value.source !== 'gh api graphql read-only subprocess') add('invalid_source_identity');
  if (!parseDate(value.observationStartedAt) || !parseDate(value.observationCompletedAt) || Date.parse(value.observationCompletedAt) < Date.parse(value.observationStartedAt)) add('invalid_observation_window');
  if (!value.counts || !Number.isSafeInteger(value.counts.issues) || !Number.isSafeInteger(value.counts.pullRequests) || value.counts.issues < 0 || value.counts.pullRequests < 0) add('invalid_counts');
  if (!value.refresh || value.refresh.status !== 'matched' || !parseDate(value.refresh.refreshedAt) || value.refresh.changedObjectCount !== 0 || !value.refresh.counts || value.refresh.counts.issues !== value.counts?.issues || value.refresh.counts.pullRequests !== value.counts?.pullRequests) add('refresh_not_matched');
  if (!Array.isArray(value.objects)) {
    add('objects_missing');
    return errors;
  }
  const seen = new Set();
  const byKind = { issue: 0, pull_request: 0 };
  for (const object of value.objects) {
    if (!object || typeof object !== 'object' || Array.isArray(object)) { add('invalid_object'); continue; }
    if (Object.keys(object).some((name) => !OBJECT_KEYS.has(name))) add('unexpected_object_field');
    if (!['issue', 'pull_request'].includes(object.kind) || !Number.isSafeInteger(object.number) || object.number < 1 || !isText(object.id)) { add('invalid_identity'); continue; }
    const identity = key(object);
    if (seen.has(identity)) add('duplicate_identity');
    seen.add(identity);
    byKind[object.kind] += 1;
    const suffix = object.kind === 'issue' ? `/issues/${object.number}` : `/pull/${object.number}`;
    if (object.url !== `https://github.com/${value.repository}${suffix}` || !parseDate(object.updatedAt)) add('invalid_object_metadata');
    if (object.kind === 'pull_request') {
      if (!isText(object.headRefName) || !/^[a-f0-9]{7,64}$/i.test(object.headOid || '') || !isText(object.baseRefName) || !isText(object.mergeable) || !isText(object.checkState) || !Array.isArray(object.failedChecks) || object.failedChecks.some((check) => !isText(check))) add('invalid_pull_request_metadata');
      if (!Array.isArray(object.relatedIssueNumbers) || object.relatedIssueNumbers.some((number) => !Number.isSafeInteger(number) || number < 1)) add('invalid_relationships');
    } else if (!Array.isArray(object.relatedPullRequestNumbers) || object.relatedPullRequestNumbers.some((number) => !Number.isSafeInteger(number) || number < 1)) add('invalid_relationships');
    if (requireDispositions) {
      const disposition = object.disposition;
      if (!disposition || typeof disposition !== 'object' || Array.isArray(disposition)) add('disposition_missing');
      else {
        if (Object.keys(disposition).some((name) => !DISPOSITION_KEYS.has(name))) add('unexpected_disposition_field');
        if ([...DISPOSITION_KEYS].some((name) => !(name in disposition))) add('disposition_field_missing');
        if (!['retain_pending_diagnosis', 'held_for_release', 'blocked_external_gate', 'verified_resolved_or_superseded'].includes(disposition.category)) add('invalid_disposition_category');
        for (const field of ['rationale', 'accountableRole', 'nextAction', 'trigger', 'evidenceRef']) if (!isText(disposition[field])) add('disposition_field_missing');
        if (typeof disposition.releaseProposal !== 'boolean') add('invalid_release_proposal_flag');
        if (disposition.category === 'held_for_release' && disposition.releaseProposal !== true) add('release_hold_not_explicit');
        if (disposition.releaseProposal === true && (disposition.category !== 'held_for_release' || !/separate release selection|fresh exact-candidate/i.test(`${disposition.rationale} ${disposition.nextAction} ${disposition.trigger}`))) add('release_authority_not_bounded');
      }
    }
  }
  if (byKind.issue !== value.counts?.issues || byKind.pull_request !== value.counts?.pullRequests || seen.size !== value.objects.length) add('count_mismatch');
  if (value.objects.some((object, index) => index > 0 && compare(value.objects[index - 1], object) > 0)) add('nondeterministic_order');
  return errors;
}

async function main() {
  const file = process.argv[2];
  if (!file || process.argv.length !== 3) {
    process.stderr.write('usage: check_queue_inventory.mjs <inventory.json>\n');
    process.exitCode = 2;
    return;
  }
  let inventory;
  try { inventory = JSON.parse(await readFile(file, 'utf8')); } catch {
    process.stdout.write('{"valid":false,"errors":["invalid_json"]}\n');
    process.exitCode = 1;
    return;
  }
  const errors = validateQueueInventory(inventory);
  process.stdout.write(`${JSON.stringify({ valid: errors.length === 0, errors })}\n`);
  if (errors.length) process.exitCode = 1;
}

if (import.meta.url === `file://${process.argv[1]}`) main();
