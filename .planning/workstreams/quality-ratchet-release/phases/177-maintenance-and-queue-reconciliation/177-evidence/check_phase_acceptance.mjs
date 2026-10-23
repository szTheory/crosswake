import { readFile, writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { dirname, resolve, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { mkdtempSync, readFileSync, rmSync, writeFileSync, mkdirSync, chmodSync, lstatSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { checkGuidance } from './check_active_guidance.mjs';
import { collectQueue } from './collect_queue.mjs';
import { validateQueueInventory } from './check_queue_inventory.mjs';
import { validateSemanticSelection } from './source_reconciliation.mjs';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../../../../../../');
const evidenceRoot = resolve(dirname(fileURLToPath(import.meta.url)));
const expectedCurrentCommand = '$gsd-execute-phase 177 --ws quality-ratchet-release';
const expectedNextCommand = '$gsd-discuss-phase 178 --ws quality-ratchet-release';
const expectedOverlayPaths = [
  'README.md',
  'docs/COMPANION-PUBLISH-RUNBOOK.md',
  'docs/RELEASE-INCIDENT-RESPONSE.md',
  'test/crosswake/guides/release_boundaries_test.exs',
  'test/crosswake/release_candidate/companion_receipt_test.exs',
  'test/crosswake/release_candidate/evidence_gate_test.exs',
];
const requiredPatchOwners = ['177-02', '177-03', '177-05'];
const genericEntryNames = ['status', 'candidate', 'receipt', 'gate'];

const isText = (value) => typeof value === 'string' && value.trim().length > 0;
const equalSets = (left, right) => left.length === right.length && new Set(left).size === left.length && left.every((value) => right.includes(value));
const safeKey = (object) => `${object?.kind}:${object?.number}`;
const queueFields = ['kind', 'id', 'number', 'updatedAt', 'url', 'headRefName', 'headOid', 'baseRefName', 'mergeable', 'checkState', 'failedChecks', 'relatedIssueNumbers', 'relatedPullRequestNumbers'];

function normalizeRemoteObject(object) {
  const normalized = {};
  for (const field of queueFields) {
    if (!Object.hasOwn(object ?? {}, field)) continue;
    const value = object[field];
    normalized[field] = Array.isArray(value) ? [...value].sort((a, b) => String(a).localeCompare(String(b))) : value;
  }
  return normalized;
}

function sameRemoteRoster(recorded, live) {
  if (!Array.isArray(recorded) || !Array.isArray(live)) return false;
  const recordedMap = new Map(recorded.map((item) => [safeKey(item), normalizeRemoteObject(item)]));
  const liveMap = new Map(live.map((item) => [safeKey(item), normalizeRemoteObject(item)]));
  if (recordedMap.size !== recorded.length || liveMap.size !== live.length || recordedMap.size !== liveMap.size) return false;
  return [...recordedMap].every(([key, value]) => JSON.stringify(value) === JSON.stringify(liveMap.get(key)));
}

function sourceBindingDigest(binding) {
  const payload = { ...binding };
  delete payload.bindingDigest;
  return createHash('sha256').update(JSON.stringify(payload)).digest('hex');
}

function add(errors, condition, message) {
  if (!condition) errors.push(message);
}

function countRowsBy(rows, predicate) {
  return Array.isArray(rows) ? rows.filter(predicate).length : 0;
}

export function validateAcceptance(input) {
  const errors = [];
  const { inventory, maintenance, binding, semantic, candidate, mirror, queue, active, handoff, sourceProof, historic } = input ?? {};
  add(errors, Array.isArray(input?.summaryStatuses) && input.summaryStatuses.length === 7 && input.summaryStatuses.every(([, status]) => status === 'complete'), 'One or more completed stream summaries are missing or not marked complete.');
  const inventoryRows = inventory?.rows;
  const expectedRowIds = Array.isArray(inventoryRows) ? inventoryRows.map((row) => row?.rowId) : [];
  const maintenanceIds = Array.isArray(maintenance?.rows) ? maintenance.rows.map((row) => row?.rowId) : [];
  const semanticIds = Array.isArray(semantic?.rows) ? semantic.rows.map((row) => row?.rowId) : [];
  const bindingIds = Array.isArray(binding?.rows) ? binding.rows.map((row) => row?.rowId) : [];

  add(errors, expectedRowIds.length > 0 && expectedRowIds.every(isText) && new Set(expectedRowIds).size === expectedRowIds.length, 'Phase 176 inventory row roster is missing or duplicated.');
  add(errors, equalSets(maintenanceIds, expectedRowIds), 'Maintenance review row coverage does not match the actual Phase 176 roster.');
  add(errors, equalSets(semanticIds, expectedRowIds), 'Semantic source selection row coverage does not match the actual Phase 176 roster.');
  add(errors, equalSets(bindingIds, expectedRowIds) && binding?.selectedCount === expectedRowIds.length && equalSets(binding?.selectedRowIds ?? [], expectedRowIds), 'Source binding row coverage is incomplete or duplicated.');
  add(errors, binding?.status === 'complete-qualified' && isText(binding?.baseCommit) && isText(binding?.baseTree) && isText(binding?.bindingDigest), 'Source binding is absent or unqualified.');
  add(errors, binding?.bindingDigest === sourceBindingDigest(binding), 'Source binding digest does not match the canonical public binding payload.');
  const semanticStatusById = new Map((semantic?.rows ?? []).map((row) => [row.rowId, row.sourceOwned ? 'source-retained-privately' : 'preserved-out-of-source-scope']));
  add(errors, Array.isArray(binding?.rows) && binding.rows.every((row) => semanticStatusById.get(row.rowId) === row.status), 'Source binding per-row disposition differs from the semantic selection.');
  add(errors, semantic?.status === 'semantic-selection-complete' && semantic?.baseCommit === binding?.baseCommit && semantic?.baseTree === binding?.baseTree, 'Source binding and semantic selection do not share the exact source identity.');

  const sourceCount = countRowsBy(semantic?.rows, (row) => row?.sourceOwned === true);
  const outsideCount = countRowsBy(semantic?.rows, (row) => row?.sourceOwned === false);
  add(errors, sourceCount + outsideCount === expectedRowIds.length && semantic?.counts?.sourceRows === sourceCount && semantic?.counts?.outOfSourceRows === outsideCount, 'Semantic row partitions are partial or inconsistent.');
  add(errors, Array.isArray(semantic?.rows) && semantic.rows.every((row) => row?.preservation?.headIndexWorktreeSeparate === true && row?.preservation?.privatePartitionRetained === true && row?.preservation?.workingSourceOverlaySelected === false && isText(row?.nextCheck)), 'A captured row lacks separate private preservation or an explicit next check.');
  add(errors, semantic?.rows?.filter((row) => row.sourceOwned).every((row) => row.selectedAction === 'retain-captured-units-privately; preserve exact pinned-source bytes') && semantic?.rows?.filter((row) => !row.sourceOwned).every((row) => row.selectedAction === 'preserve-out-of-source-scope'), 'Source-owned and out-of-scope rows do not retain their explicit selected actions.');
  add(errors, binding?.counts?.applicable === sourceCount && binding?.counts?.retainedPrivately === sourceCount && binding?.counts?.preservedOutOfScope === outsideCount, 'Qualified source row counts do not match the semantic source/out-of-scope split.');
  add(errors, semantic?.counts?.previouslyBlockedConflicts === binding?.counts?.previouslyBlockedConflicts && binding?.counts?.unresolved === 0, 'Source preservation or previously blocked conflict accounting changed.');
  add(errors, Array.isArray(binding?.patches) && equalSets(binding.patches.map((patch) => patch?.owner), requiredPatchOwners) && binding.patches.every((patch) => patch?.status === 'recorded' && patch?.changedFiles > 0), 'A required owner patch is missing, unbound, or empty.');
  add(errors, mirror?.source?.sourceBindingStatus === binding?.status && mirror?.source?.baseCommit === binding?.baseCommit && mirror?.source?.baseTree === binding?.baseTree, 'Mirror review is not bound to the qualified source.');

  const candidateProof = candidate?.supportedGenericEntryProof;
  const genericProofComplete = genericEntryNames.every((name) => isText(candidateProof?.[name]?.positive) && isText(candidateProof?.[name]?.denied));
  add(errors, candidate?.status === 'bounded-current-path-proof-complete' && genericProofComplete && candidateProof && candidate?.supportedGenericEntryProof?.liveWriterCalls === 0, 'Generic actual-entry proof is missing a positive or denied case for one or more supported paths, or records a live writer call.');
  add(errors, candidate?.verification?.mix?.result === 'pass' && candidate?.verification?.mix?.tests > 0 && candidate?.verification?.mix?.failures === 0, 'Candidate/status/receipt/gate test evidence is not passing.');
  add(errors, candidate?.verification?.workflowIntegrity?.result === 'pass' && candidate?.verification?.workflowIntegrity?.checks > 0 && candidate?.verification?.workflowIntegrity?.failures === 0, 'Release workflow integrity evidence is not passing.');
  add(errors, candidate?.plan93?.historicalVerdict === 'unchanged; no new verdict established' && candidate?.plan93?.readerComparison === 'unproven', 'Historical candidate-reader uncertainty was changed or overstated.');

  const modeIds = Array.isArray(semantic?.modes) ? semantic.modes.map((mode) => mode?.mode) : [];
  const mirrorModeIds = Array.isArray(mirror?.modeRecords) ? mirror.modeRecords.map((mode) => mode?.mode) : [];
  const maintenanceModeIds = Array.isArray(maintenance?.retirementCandidates) ? maintenance.retirementCandidates.map((mode) => mode?.mode) : [];
  add(errors, modeIds.length > 0 && equalSets(mirrorModeIds, modeIds) && equalSets(maintenanceModeIds, modeIds), 'Historical mode roster is incomplete or differs across evidence streams.');
  add(errors, maintenance?.gates?.sourceChangeEligibleCandidates === 0 && maintenance?.gates?.phase178Claimed === false && maintenance?.gates?.requirementCompletionClaimed === false, 'Maintenance review overstates retirement or Phase 178 completion.');
  add(errors, mirror?.source?.productionSourceChanges === 0 && mirror?.actualEntry?.exitCode !== undefined && mirror?.actualEntry?.gitStatusUnchanged === true && ['credentialsRead', 'networkRequests', 'evidenceWrites', 'approvalConsumption'].every((key) => mirror?.actualEntry?.sideEffects?.[key] === false), 'Unsupported mirror entry did not fail without changing the source checkout or avoiding side effects.');
  add(errors, mirror?.supportedCurrentPathEvidence?.tests > 0 && mirror?.supportedCurrentPathEvidence?.failures === 0 && mirror?.supportedCurrentPathEvidence?.checks > 0 && mirror?.supportedCurrentPathEvidence?.failed === 0, 'Current generic supported-path proof is incomplete or failing.');
  add(errors, mirror?.modeRecords?.every((mode) => mode?.retirementClaim === false), 'A historical mode has acquired an unsupported retirement claim.');

  const objects = queue?.objects;
  const queueKeys = Array.isArray(objects) ? objects.map(safeKey) : [];
  const liveQueueKeys = Array.isArray(input?.liveQueue?.objects) ? input.liveQueue.objects.map(safeKey) : [];
  const issueCount = countRowsBy(objects, (item) => item?.kind === 'issue');
  const prCount = countRowsBy(objects, (item) => item?.kind === 'pull_request');
  add(errors, queue?.status === 'complete' && queueKeys.length > 0, 'Queue roster is missing or incomplete.');
  add(errors, queueKeys.every((key) => !key.endsWith(':undefined')) && new Set(queueKeys).size === queueKeys.length, 'Queue roster contains a duplicate queue identity.');
  const strictQueueErrors = validateQueueInventory(queue);
  add(errors, strictQueueErrors.length === 0, `Strict queue inventory validation failed (${strictQueueErrors.join(', ')}).`);
  add(errors, queue?.counts?.issues === issueCount && queue?.counts?.pullRequests === prCount && queue?.refresh?.counts?.issues === issueCount && queue?.refresh?.counts?.pullRequests === prCount, 'Queue counts do not match the complete refreshed object roster.');
  add(errors, queue?.refresh?.status === 'matched' && queue?.refresh?.changedObjectCount === 0, 'Final queue refresh does not match the recorded roster.');
  add(errors, isText(queue?.source) && isText(queue?.observationStartedAt) && isText(queue?.observationCompletedAt) && Date.parse(queue.observationCompletedAt) >= Date.parse(queue.observationStartedAt), 'Queue source or observation window is missing or invalid.');
  add(errors, input?.liveQueue?.status === 'complete' && input?.liveQueue?.refresh?.status === 'matched' && equalSets(liveQueueKeys, queueKeys) && sameRemoteRoster(objects, input?.liveQueue?.objects), 'Fresh read-only queue refresh differs from the complete normalized decision-bearing metadata.');

  add(errors, active?.valid === true && active?.currentCommand === expectedCurrentCommand, 'Active guidance check failed or no longer resolves the current Phase 177 command.');
  add(errors, handoff?.nextCommand === expectedNextCommand && handoff?.condition === 'after independent verification passes', 'Handoff command or its independent-verification condition is stale.');
  add(errors, historic?.rel10 === 'BREACHED' && historic?.parkedAdopter === true, 'Historical Phase 175 or parked-adopter gate meaning was softened.');
  add(errors, sourceProof?.head === binding?.baseCommit && equalSets(sourceProof?.statusPaths ?? [], expectedOverlayPaths), 'Source overlay is incomplete or has changes outside the six replay-bound files.');
  add(errors, sourceProof?.genericTests?.tests === candidate?.verification?.mix?.tests && sourceProof?.genericTests?.failures === 0, 'Fresh source generic tests do not match the recorded actual-entry proof.');
  add(errors, sourceProof?.docsTests?.tests > 0 && sourceProof?.docsTests?.failures === 0, 'Fresh public-guide and ancestry tests are incomplete or failing.');
  add(errors, sourceProof?.workflow?.checks === candidate?.verification?.workflowIntegrity?.checks && sourceProof?.workflow?.failures === 0, 'Fresh workflow integrity run does not match the recorded result.');

  return {
    errors,
    metrics: {
      inventoryRows: expectedRowIds.length,
      sourceRows: sourceCount,
      outOfSourceRows: outsideCount,
      preservedConflicts: binding?.counts?.previouslyBlockedConflicts ?? null,
      historicalModes: modeIds.length,
      queueIssues: issueCount,
      queuePullRequests: prCount,
      queueObjects: queueKeys.length,
      liveQueueRefreshedAt: input?.liveQueue?.refresh?.refreshedAt ?? null,
      genericEntryPaths: genericEntryNames.filter((name) => isText(candidateProof?.[name]?.positive) && isText(candidateProof?.[name]?.denied)).length,
      activeCommand: active?.currentCommand ?? null,
      nextCommand: handoff?.nextCommand ?? null,
      sourceOverlayFiles: sourceProof?.statusPaths?.length ?? 0,
    },
  };
}

async function readJson(path) {
  return JSON.parse(await readFile(path, 'utf8'));
}

function run(executable, args, cwd, label) {
  try {
    return execFileSync(executable, args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], maxBuffer: 8 * 1024 * 1024 });
  } catch (error) {
    throw new Error(`${label} failed with exit ${error.status ?? 'unknown'}`);
  }
}

function statusPaths(sourceRoot) {
  const output = run('git', ['status', '--short', '--untracked-files=all'], sourceRoot, 'source status check');
  return output.split(/\r?\n/).filter(Boolean).map((line) => line.slice(3).trim()).sort();
}

function parseStatusPaths(sourceRoot) {
  const output = run('git', ['status', '--porcelain=v1', '--untracked-files=all'], sourceRoot, 'source bundle replay status');
  return output.split(/\r?\n/).filter(Boolean).map((line) => line.slice(3).trim()).sort();
}

function verifyPrivateBundleRoot(root) {
  const stat = lstatSync(root);
  if (!stat.isDirectory() || stat.isSymbolicLink() || (typeof process.getuid === 'function' && stat.uid !== process.getuid()) || (stat.mode & 0o077) !== 0) throw new Error('private source handoff directory is not owner-only');
}

function replayOwnerBundles(sourceRoot, binding, semantic, finalPaths) {
  const handoffRoot = process.env.CROSSWAKE_177_PRIVATE_HANDOFF;
  if (!handoffRoot) throw new Error('private source handoff is unavailable');
  verifyPrivateBundleRoot(handoffRoot);
  const baseCommit = run('git', ['rev-parse', 'HEAD'], sourceRoot, 'source base check').trim();
  const baseTree = run('git', ['rev-parse', 'HEAD^{tree}'], sourceRoot, 'source base tree check').trim();
  if (baseCommit !== binding.baseCommit || baseTree !== binding.baseTree) throw new Error('recovery source base differs from the public binding');

  const partitionsPath = resolve(handoffRoot, 'partitions.json');
  const partitionsStat = lstatSync(partitionsPath);
  if (!partitionsStat.isFile() || partitionsStat.isSymbolicLink() || (typeof process.getuid === 'function' && partitionsStat.uid !== process.getuid()) || (partitionsStat.mode & 0o077) !== 0) throw new Error('private source partitions are not owner-only');
  const partitions = JSON.parse(readFileSync(partitionsPath, 'utf8'));
  validateSemanticSelection({ review: semantic, bundle: partitions, binding, baseCommit, baseTree });

  const metadata = new Map(binding.patches.map((patch) => [patch.owner, patch]));
  const results = [];
  for (const owner of requiredPatchOwners) {
    const path = resolve(handoffRoot, `cumulative-${owner}.bundle.json`);
    const fileStat = lstatSync(path);
    if (!fileStat.isFile() || fileStat.isSymbolicLink() || (typeof process.getuid === 'function' && fileStat.uid !== process.getuid()) || (fileStat.mode & 0o077) !== 0) throw new Error('private cumulative source bundle is not owner-only');
    const record = JSON.parse(readFileSync(path, 'utf8'));
    const patchRecord = metadata.get(owner);
    if (record.owner !== owner || record.baseCommit !== baseCommit || record.baseTree !== baseTree || !patchRecord || patchRecord.status !== 'recorded' || record.patchBytes !== patchRecord.patchBytes || record.untrackedFiles !== patchRecord.untrackedFiles) throw new Error('private source bundle metadata does not match the public binding');
    const patchBytes = Buffer.from(record.patchBase64 ?? '', 'base64');
    const digest = createHash('sha256').update(patchBytes).digest('hex');
    if (!record.patchBase64 || patchBytes.toString('base64') !== record.patchBase64 || patchBytes.length !== record.patchBytes || digest !== record.patchDigest) throw new Error('private source bundle patch integrity check failed');
    if (!Array.isArray(record.untracked) || record.untracked.length !== record.untrackedFiles) throw new Error('private source bundle untracked inventory is incomplete');

    const tempRoot = mkdtempSync(resolve(tmpdir(), 'crosswake-177-acceptance-replay-'));
    try {
      const replay = resolve(tempRoot, 'repo');
      run('git', ['clone', '--quiet', sourceRoot, replay], tempRoot, 'private source patch replay clone');
      run('git', ['checkout', '--quiet', '--detach', baseCommit], replay, 'private source patch replay checkout');
      if (run('git', ['rev-parse', 'HEAD^{tree}'], replay, 'private source replay base check').trim() !== baseTree) throw new Error('private source replay started from a different source tree');
      const patchPath = resolve(tempRoot, 'source.patch');
      writeFileSync(patchPath, patchBytes, { mode: 0o600 });
      if (patchBytes.length) run('git', ['apply', '--binary', patchPath], replay, 'private source patch application');
      for (const untracked of record.untracked) {
        if (typeof untracked.path !== 'string' || untracked.path.startsWith('/') || untracked.path.split('/').includes('..')) throw new Error('private source bundle has an unsafe path');
        const bytes = Buffer.from(untracked.bytes ?? '', 'base64');
        if (bytes.toString('base64') !== untracked.bytes) throw new Error('private source bundle untracked bytes are malformed');
        const target = resolve(replay, untracked.path);
        if (!target.startsWith(`${replay}/`)) throw new Error('private source bundle path escaped its replay root');
        mkdirSync(resolve(target, '..'), { recursive: true });
        writeFileSync(target, bytes, { mode: untracked.mode });
        chmodSync(target, untracked.mode);
      }
      const paths = parseStatusPaths(replay);
      if (paths.length !== patchRecord.changedFiles || !paths.every((rel) => finalPaths.includes(rel))) throw new Error('private source bundle changed-file roster differs from the bound source overlay');
      if (owner === '177-05' && !equalSets(paths, expectedOverlayPaths)) throw new Error('final private source bundle does not reproduce the six-path source overlay');
      for (const rel of paths) {
        const actual = readFileSync(resolve(sourceRoot, rel));
        const replayed = readFileSync(resolve(replay, rel));
        if (!actual.equals(replayed)) throw new Error('private source bundle replay differs from the current source overlay');
        const actualMode = statSync(resolve(sourceRoot, rel)).mode & 0o777;
        const replayMode = statSync(resolve(replay, rel)).mode & 0o777;
        if (actualMode !== replayMode) throw new Error('private source bundle replay mode differs from the current source overlay');
      }
      results.push({ owner, replayed: true, changedFiles: paths.length });
    } finally {
      rmSync(tempRoot, { recursive: true, force: true });
    }
  }
  return results;
}

function captureSourceProof(sourceRoot, binding, semantic) {
  const head = run('git', ['rev-parse', 'HEAD'], sourceRoot, 'source identity check').trim();
  const changedPaths = statusPaths(sourceRoot);
  const patchReplays = replayOwnerBundles(sourceRoot, binding, semantic, changedPaths);
  const genericOutput = run('mix', ['test', 'test/mix/tasks/crosswake_release_candidate_test.exs', 'test/mix/tasks/crosswake_release_status_test.exs', 'test/crosswake/release_candidate/companion_receipt_test.exs', 'test/crosswake/release_candidate/evidence_gate_test.exs'], sourceRoot, 'generic actual-entry tests');
  const genericMatch = genericOutput.match(/(\d+) tests?, (\d+) failures?/);
  const docsOutput = run('mix', ['test', 'test/crosswake/guides/release_boundaries_test.exs', 'test/crosswake/proof/phase175_runbook_ancestry_test.exs'], sourceRoot, 'public guidance and ancestry tests');
  const docsMatch = docsOutput.match(/(\d+) tests?, (\d+) failures?/);
  const workflowOutput = run('elixir', ['script/check_release_workflow_integrity.exs'], sourceRoot, 'workflow integrity check');
  const workflowMatch = workflowOutput.match(/DONE: (\d+) of \1 roster checks emitted; (\d+) failed\./);
  if (!genericMatch || !docsMatch || !workflowMatch) throw new Error('A source verification command completed without a parseable test/check summary.');
  return {
    head,
    statusPaths: changedPaths,
    patchReplays,
    genericTests: { tests: Number(genericMatch[1]), failures: Number(genericMatch[2]) },
    docsTests: { tests: Number(docsMatch[1]), failures: Number(docsMatch[2]) },
    workflow: { checks: Number(workflowMatch[1]), failures: Number(workflowMatch[2]) },
  };
}

function currentCommandFromState(text) {
  const section = text.split('## Exact Next Action')[1]?.split('\n## ')[0] ?? '';
  return section.match(/\$gsd-[^\s`]+\s+\d+\s+--ws\s+[A-Za-z0-9._-]+/)?.[0] ?? null;
}

function readSummaryStatus(text) {
  const frontmatter = text.match(/^---\s*\n([\s\S]*?)\n---/);
  return frontmatter?.[1].match(/^status:\s*([\w-]+)\s*$/m)?.[1] ?? null;
}

async function loadInputs(sourceRoot) {
  const p = (name) => resolve(evidenceRoot, name);
  const phaseRoot = resolve(evidenceRoot, '..');
  const workstreamRoot = resolve(repoRoot, '.planning/workstreams/quality-ratchet-release');
  const inventoryRoot = resolve(workstreamRoot, 'phases/176-local-work-and-artifact-disposition');
  const names = ['177-01-SUMMARY.md', '177-02-SUMMARY.md', '177-03-SUMMARY.md', '177-04-SUMMARY.md', '177-05-SUMMARY.md', '177-06-SUMMARY.md', '177-08-SUMMARY.md'];
  const summaryStatuses = await Promise.all(names.map(async (name) => [name, readSummaryStatus(await readFile(resolve(phaseRoot, name), 'utf8'))]));
  const [inventory, maintenance, binding, semantic, candidate, mirror, queue] = await Promise.all([
    readJson(resolve(inventoryRoot, '176-INVENTORY.json')),
    readJson(p('maintenance-review.json')),
    readJson(p('source-binding.json')),
    readJson(p('semantic-reconciliation.json')),
    readJson(p('candidate-read-review.json')),
    readJson(p('mirror-router-review.json')),
    readJson(p('queue-inventory.json')),
  ]);
  const liveQueue = collectQueue(queue.repository);
  const state = await readFile(resolve(workstreamRoot, 'STATE.md'), 'utf8');
  const sourceProof = captureSourceProof(sourceRoot, binding, semantic);
  const guidance = await checkGuidance(repoRoot);
  const archive = await readFile(resolve(workstreamRoot, 'milestones/v23.0-phases/175-rehearsal-and-publish/175-VERIFICATION.md'), 'utf8');
  const historic = {
    rel10: /REL-10:\s*BREACHED/.test(archive) ? 'BREACHED' : 'changed',
    parkedAdopter: /PARKED[\s\S]*TODO-002 remains open[\s\S]*source-bound signed-device run/.test(await readFile(resolve(repoRoot, '.planning/workstreams/first-b2c-adopter-readiness/STATE.md'), 'utf8')),
  };
  return {
    inventory,
    maintenance,
    binding,
    semantic,
    candidate,
    mirror,
    queue,
    liveQueue,
    active: { valid: guidance.errors.length === 0, currentCommand: currentCommandFromState(state) },
    handoff: { nextCommand: expectedNextCommand, condition: 'after independent verification passes' },
    sourceProof,
    historic,
    summaryStatuses,
  };
}

function buildReport(input, validation, mode) {
  return {
    schemaVersion: 1,
    phase: '177',
    plan: '07',
    status: validation.errors.length ? 'blocked' : 'ready_for_independent_verification',
    mode,
    checkedAt: new Date().toISOString(),
    evidence: {
      streamSummaries: input.summaryStatuses.map(([file, status]) => ({ file, status })),
      source: {
        bindingStatus: input.binding.status,
        baseCommit: input.binding.baseCommit,
        baseTree: input.binding.baseTree,
        bindingDigest: input.binding.bindingDigest,
        selectedRows: input.binding.selectedCount,
        sourceRows: validation.metrics.sourceRows,
        outOfSourceRows: validation.metrics.outOfSourceRows,
        preservedConflicts: validation.metrics.preservedConflicts,
        modeCount: validation.metrics.historicalModes,
        patchOwners: input.binding.patches.map(({ owner, status, changedFiles, untrackedFiles, patchBytes }) => ({ owner, status, changedFiles, untrackedFiles, patchBytes })),
        privateReplayChecks: input.sourceProof.patchReplays,
        overlayPaths: input.sourceProof.statusPaths,
        productionSourceChanges: input.mirror.source.productionSourceChanges,
      },
      genericActualEntryProof: {
        paths: validation.metrics.genericEntryPaths,
        mixTests: input.sourceProof.genericTests,
        workflow: input.sourceProof.workflow,
      },
      publicGuidanceTests: input.sourceProof.docsTests,
      queue: {
        issues: validation.metrics.queueIssues,
        pullRequests: validation.metrics.queuePullRequests,
        totalObjects: validation.metrics.queueObjects,
        finalRefresh: input.queue.refresh,
        perObjectNextActions: true,
        liveRefresh: { status: input.liveQueue.refresh?.status, refreshedAt: input.liveQueue.refresh?.refreshedAt, changedObjectCount: input.liveQueue.refresh?.changedObjectCount },
      },
      activeCommand: input.active.currentCommand,
      historicalRel10: input.historic.rel10,
      adopterGatePreserved: input.historic.parkedAdopter,
      retainedReaderUncertainty: input.candidate.plan93.readerComparison,
    },
    reviewFindings: {
      'CR-01': 'resolved: fresh queue comparison binds complete normalized allowlisted decision metadata; same-updatedAt CI/head/base/relationship changes fail fixtures',
      'CR-02': 'resolved: acceptance calls validateQueueInventory and rejects missing disposition fields, invalid category, and invalid releaseProposal flag',
      'WR-01': 'resolved: canonical public binding digest is recomputed, semantic row dispositions are compared, and private partition plus three owner bundles are validated and replayed against the source overlay',
    },
    checks: { errors: validation.errors, metrics: validation.metrics },
    handoff: {
      status: 'parent_publication_pending',
      afterIndependentVerification: input.handoff.nextCommand,
      condition: input.handoff.condition,
      phase178Owns: 'Bind the exact final source and matching hosted CI; no Phase 177 artifact substitutes for that gate.',
    },
    claims: { phaseComplete: false, requirementsMarkedComplete: false, phase178ProofComplete: false },
  };
}

async function main() {
  const args = process.argv.slice(2);
  const mode = args.includes('--complete') ? 'complete' : args.includes('--tracer') ? 'tracer' : null;
  const artifactArg = args.find((arg) => !arg.startsWith('--'));
  const artifact = resolve(repoRoot, artifactArg ?? relative(repoRoot, resolve(evidenceRoot, 'phase-acceptance.json')));
  const sourceRoot = process.env.CROSSWAKE_RECOVERY_ROOT;
  if (!mode || !sourceRoot) {
    console.error('usage: check_phase_acceptance.mjs (--tracer|--complete) [artifact.json] (CROSSWAKE_RECOVERY_ROOT required)');
    process.exitCode = 2;
    return;
  }
  try {
    const input = await loadInputs(sourceRoot);
    const validation = validateAcceptance(input);
    const report = buildReport(input, validation, mode);
    await writeFile(artifact, `${JSON.stringify(report, null, 2)}\n`);
    const handoff = {
      schemaVersion: 1,
      phase: '177',
      workstream: 'quality-ratchet-release',
      status: validation.errors.length ? 'blocked' : 'awaiting_independent_verification',
      lastCompletedPlan: '177-08',
      activePhaseStatus: validation.errors.length ? 'acceptance_blocked' : 'acceptance_checks_passed_parent_closeout_pending',
      currentRegisteredCommand: input.active.currentCommand,
      exactNextCommandAfterIndependentVerification: input.handoff.nextCommand,
      nextCommandCondition: input.handoff.condition,
      parentOwns: ['independent verification result', 'registered STATE/ROADMAP transition', 'requirement completion decision'],
      phase178Boundary: 'Phase 178 owns exact final source binding and hosted CI on that same commit.',
      phaseComplete: false,
      requirementsMarkedComplete: false,
    };
    await writeFile(resolve(evidenceRoot, 'handoff-payload.json'), `${JSON.stringify(handoff, null, 2)}\n`);
    if (validation.errors.length) {
      process.stderr.write(`BLOCKED: ${validation.errors.length} Phase 177 acceptance checks failed. See phase-acceptance.json.\n`);
      process.exitCode = 1;
    } else {
      process.stdout.write(`${mode === 'tracer' ? 'TRACER' : 'COMPLETE'}: ${validation.metrics.inventoryRows} rows, ${validation.metrics.historicalModes} retained modes, ${validation.metrics.genericEntryPaths} actual-entry paths, ${validation.metrics.queueObjects} refreshed queue objects. Phase 178 remains the next proof owner.\n`);
    }
  } catch (error) {
    console.error(`BLOCKED: acceptance evidence could not be loaded or checked (${error.message}).`);
    process.exitCode = 1;
  }
}

if (import.meta.url === `file://${process.argv[1]}`) main();
