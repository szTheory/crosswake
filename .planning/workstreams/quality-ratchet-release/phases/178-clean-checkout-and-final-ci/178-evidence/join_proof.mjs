#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { collect as collectLocalProof } from './local_proof.mjs';
import {
  deriveSkipContract,
  exactCommitMatch,
  normalizePolicy,
  parsePageEnvelope,
  validateFreshSnapshot,
  validateRunGraph,
} from './ci_evidence.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PHASE_DIR = path.dirname(HERE);
const POINTER = '/private/tmp/crosswake-178-owner-env';
const STAGE_ORDER = Object.freeze([
  'repository-preflight', 'root-proof', 'example-host-proof', 'browser-proof',
  'ios-package-proof', 'android-package-proof', 'format-proof', 'warnings-proof',
  'repository-cleanliness',
]);
const HEX40 = /^[0-9a-f]{40}$/i;
const HEX64 = /^[0-9a-f]{64}$/i;
const SAFE_CAUSES = new Set([
  'hosted_proof_missing', 'hosted_proof_invalid', 'hosted_graph_incomplete',
  'source_commit_mismatch', 'local_proof_missing', 'local_proof_incomplete',
  'private_capture_integrity_failed', 'hosted_attempt_drift', 'hosted_run_not_green',
  'live_pull_request_drift', 'live_run_drift', 'live_policy_drift',
  'canonical_base_moved', 'candidate_identity_drift', 'object_unavailable',
  'private_binding_missing', 'raw_ci_evidence_invalid', 'local_raw_evidence_invalid',
  'github_read_failed', 'policy_unavailable', 'unexpected_failure',
]);

function safeCause(value) { return SAFE_CAUSES.has(value) ? value : 'unexpected_failure'; }
function sha(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function eqJson(a, b) { return JSON.stringify(a) === JSON.stringify(b); }
function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === 'object') return Object.fromEntries(Object.keys(value).sort().map((key) => [key, canonical(value[key])]));
  return value;
}
function fingerprint(value) { return sha(Buffer.from(JSON.stringify(canonical(value)))); }
function sameSet(a, b) { return Array.isArray(a) && Array.isArray(b) && a.length === b.length && new Set(a).size === a.length && a.every((value) => b.includes(value)); }

function blocked(cause) {
  const code = safeCause(cause);
  return {
    schemaVersion: 1,
    status: 'blocked',
    cause: code,
    requirements: { MAINT_07: 'pending', MAINT_08: 'pending' },
    candidateState: 'open-unmerged',
    nextAction: 'Keep both requirements pending; resolve the named evidence cause, then rerun Plan 05 against the current hosted attempt.',
  };
}

function requiredNames(contract) {
  const rows = [
    ...(contract?.graph?.proofLeaves ?? []),
    ...(contract?.graph?.controlNodes ?? []),
    contract?.graph?.umbrella,
  ];
  return rows.map((row) => row?.displayName).filter((value) => typeof value === 'string');
}

export function joinProof(input) {
  const { hosted, local, live, contract, privateIntegrity = local?.privateIntegrity } = input ?? {};
  if (!hosted || hosted.schemaVersion !== 1 || hosted.status !== 'candidate-run-observed' || hosted.repository !== 'szTheory/crosswake' || !contract) return blocked('hosted_proof_missing');
  const source = hosted.candidate;
  if (!HEX40.test(source?.commit ?? '') || !HEX40.test(source?.tree ?? '') || !HEX40.test(hosted.governedMergeOid ?? '') ||
      hosted.workflow?.id !== contract.workflow?.id || hosted.workflow?.path !== contract.workflow?.path ||
      hosted.workflow?.source?.version !== source.commit || hosted.workflow?.source?.blobOid !== contract.workflow?.source?.blobOid ||
      source.commit !== contract.candidate?.commit || source.tree !== contract.candidate?.tree ||
      source.baseCommit !== contract.candidate?.baseCommit) return blocked('hosted_proof_invalid');
  if (!Number.isSafeInteger(hosted.run?.id) || !Number.isInteger(hosted.run?.attempt) || hosted.run.attempt < 1 ||
      hosted.run.event !== 'pull_request' || hosted.run.headCommit !== source.commit ||
      hosted.run.url !== `https://github.com/szTheory/crosswake/actions/runs/${hosted.run.id}` ||
      hosted.pullRequest?.number !== 238 || hosted.pullRequest?.state !== 'open' ||
      hosted.pullRequest?.headCommit !== source.commit || hosted.pullRequest?.baseRef !== 'main' ||
      hosted.pullRequest?.baseCommit !== source.baseCommit || hosted.classifier?.result !== 'full_proof' ||
      hosted.classifier?.authorizedSkipCount !== (contract.graph?.skipPolicy?.authorizedSkipIds?.length ?? -1)) return blocked('hosted_proof_invalid');

  const names = requiredNames(contract);
  const jobs = hosted.requiredJobs;
  const advisoryNames = contract.graph?.advisoryJobs;
  const advisoryJobs = privateIntegrity?.advisoryJobs;
  if (names.length !== 48 || new Set(names).size !== names.length || !Array.isArray(jobs) || jobs.length !== names.length ||
      !sameSet(jobs.map((row) => row?.name), names) || !Array.isArray(advisoryNames) || new Set(advisoryNames).size !== advisoryNames.length ||
      !Array.isArray(advisoryJobs) || advisoryJobs.length !== advisoryNames.length ||
      !sameSet(advisoryJobs.map((row) => row?.name), advisoryNames) ||
      hosted.run.jobCount !== jobs.length + advisoryJobs.length || hosted.run.checkCount !== jobs.length + advisoryJobs.length ||
      new Set(jobs.map((row) => row?.jobId)).size !== jobs.length || new Set(jobs.map((row) => row?.checkRunId)).size !== jobs.length) return blocked('hosted_graph_incomplete');
  const terminalAdvisoryConclusions = new Set(['success', 'failure', 'cancelled', 'skipped']);
  const requiredJobIds = new Set(jobs.map((row) => row.jobId));
  const requiredCheckIds = new Set(jobs.map((row) => row.checkRunId));
  const advisoryJobIds = new Set();
  const advisoryCheckIds = new Set();
  for (const row of advisoryJobs) {
    if (!Number.isSafeInteger(row.jobId) || !Number.isSafeInteger(row.checkRunId) || row.attempt !== hosted.run.attempt ||
        row.status !== 'completed' || !terminalAdvisoryConclusions.has(row.conclusion) || requiredJobIds.has(row.jobId) ||
        requiredCheckIds.has(row.checkRunId) || advisoryJobIds.has(row.jobId) || advisoryCheckIds.has(row.checkRunId)) return blocked('hosted_graph_incomplete');
    advisoryJobIds.add(row.jobId);
    advisoryCheckIds.add(row.checkRunId);
  }
  const sourceLess = new Set(contract.graph.sourceLessJobs ?? []);
  for (const row of jobs) {
    const policy = contract.graph.requiredCheckoutPolicies?.[row.name];
    if (!Number.isSafeInteger(row.jobId) || !Number.isSafeInteger(row.checkRunId) || row.conclusion !== 'success') return blocked('hosted_graph_incomplete');
    if (sourceLess.has(row.name)) {
      if (row.checkout !== null) return blocked('hosted_graph_incomplete');
      continue;
    }
    if (!policy || !row.checkout || row.checkout.jobId !== row.jobId || row.checkout.checkRunId !== row.checkRunId ||
        row.checkout.attempt !== hosted.run.attempt || row.checkout.kind !== policy.kind || !HEX40.test(row.checkout.oid ?? '')) return blocked('hosted_graph_incomplete');
    const expected = policy.kind === 'head' ? source.commit : hosted.governedMergeOid;
    const expectedRef = policy.kind === 'head' ? 'pull_request_head_sha' : 'pull_request_merge_ref';
    if (!exactCommitMatch(row.checkout.oid, expected) || row.checkout.refKind !== expectedRef) return blocked('hosted_graph_incomplete');
  }

  if (!local || local.schemaVersion !== 1 || local.phase !== 178 || local.kind !== 'final' || local.status !== 'pass' ||
      local.command !== 'script/verify_repository.sh --all' || local.privateEvidence !== 'owner-private-retained' ||
      !HEX40.test(local.source?.commit ?? '') || !HEX40.test(local.source?.tree ?? '') ||
      !Array.isArray(local.stages) || local.stages.length !== STAGE_ORDER.length || local.stageCount !== STAGE_ORDER.length ||
      local.executedLogCount !== 8 || !eqJson(local.stages.map((stage) => [stage.purpose, stage.result]), STAGE_ORDER.map((purpose) => [purpose, 'PASS']))) return blocked('local_proof_incomplete');
  if (!privateIntegrity?.bindingValid || !privateIntegrity?.invocationValid || !privateIntegrity?.retainedCapturesValid || !privateIntegrity?.headTreeIndexAndNulSnapshotsUnchanged) return blocked('private_capture_integrity_failed');
  if (!exactCommitMatch(local.source.commit, hosted.governedMergeOid)) return blocked('source_commit_mismatch');
  const advisoryFailure = advisoryJobs.some((row) => row.conclusion === 'failure');
  const completedRun = live?.run?.status === 'completed' && (live.run.conclusion === 'success' ||
    (live.run.conclusion === 'failure' && advisoryFailure && privateIntegrity?.requiredGraphGreen === true));
  if (!live || live.canonicalRepository !== 'szTheory/crosswake' || live.barrierStable !== true ||
      live.run?.id !== hosted.run.id || live.run?.attempt !== hosted.run.attempt || live.run?.workflowId !== hosted.workflow.id ||
      live.run?.checkSuiteId !== hosted.run.checkSuiteId || live.run?.event !== 'pull_request' ||
      !exactCommitMatch(live.run?.headCommit, source.commit) || !completedRun) return blocked('hosted_attempt_drift');
  if (live.pullRequest?.number !== hosted.pullRequest.number || live.pullRequest?.state !== 'open' ||
      live.pullRequest?.repo !== 'szTheory/crosswake' || live.pullRequest?.headRepo !== 'szTheory/crosswake' || live.pullRequest?.baseRepo !== 'szTheory/crosswake' ||
      !exactCommitMatch(live.pullRequest?.headCommit, source.commit) || live.pullRequest?.baseRef !== 'main' ||
      !exactCommitMatch(live.pullRequest?.baseCommit, source.baseCommit) ||
      !exactCommitMatch(live.pullRequest?.mergeCommitSha, hosted.governedMergeOid) ||
      live.mergeRef?.ref !== 'refs/pull/238/merge' || !exactCommitMatch(live.mergeRef?.oid, hosted.governedMergeOid)) return blocked('live_pull_request_drift');
  if (!exactCommitMatch(live.canonicalBaseCommit, source.baseCommit)) return blocked('canonical_base_moved');
  if (!live.policy?.current || !live.policy.strict || !['successful-empty', 'active-rules-observed'].includes(live.policy.rulesetEvidence) ||
      !Array.isArray(live.policy.requiredContexts) || live.policy.requiredContexts.length === 0 ||
      !eqJson(live.policy.requiredContexts, hosted.policy?.requiredContexts) ||
      live.policy.effectiveRuleCount !== hosted.policy?.effectiveRuleCount || live.policy.rulesetEvidence !== hosted.policy?.rulesetEvidence ||
      !HEX64.test(live.policy.branchProtectionFingerprint ?? '') || !HEX64.test(live.policy.effectiveRulesFingerprint ?? '') ||
      live.policy.branchProtectionFingerprint !== privateIntegrity?.ciPolicyFingerprints?.branchProtection ||
      live.policy.effectiveRulesFingerprint !== privateIntegrity?.ciPolicyFingerprints?.effectiveRules) return blocked('live_policy_drift');

  return {
    schemaVersion: 1,
    status: 'pass',
    source: { commit: local.source.commit, tree: local.source.tree },
    candidateState: 'open-unmerged',
    hosted: { runId: hosted.run.id, attempt: hosted.run.attempt, jobCount: hosted.run.jobCount, checkCount: hosted.run.checkCount, requiredJobCount: jobs.length, advisoryJobCount: advisoryJobs.length, governedCheckoutCount: jobs.filter((row) => row.checkout?.kind === 'merge').length, headProofCount: jobs.filter((row) => row.checkout?.kind === 'head').length },
    local: { command: local.command, stageCount: local.stageCount, executedLogCount: local.executedLogCount },
    policy: { requiredContextCount: live.policy.requiredContexts.length, effectiveRuleCount: live.policy.effectiveRuleCount, rulesetEvidence: live.policy.rulesetEvidence },
    requirements: { MAINT_07: 'passed', MAINT_08: 'passed' },
    cause: 'none',
    nextAction: 'Submit this evidence to the phase verifier; the candidate remains open and unmerged.',
  };
}

function privateOwnerRoot() {
  const st = fs.lstatSync(POINTER);
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o777) !== 0o600) throw new Error('private_binding_missing');
  const root = fs.realpathSync(fs.readFileSync(POINTER, 'utf8').trim());
  const tempRoot = fs.realpathSync(os.tmpdir());
  const withinTemp = [path.resolve('/private/tmp'), tempRoot].some((base) => root === base || root.startsWith(`${base}${path.sep}`));
  if (!withinTemp || root === fs.realpathSync(path.resolve(HERE, '../../../../../..'))) throw new Error('private_binding_missing');
  const rootStat = fs.lstatSync(root);
  if (!rootStat.isDirectory() || rootStat.isSymbolicLink() || (rootStat.mode & 0o777) !== 0o700 || rootStat.uid !== process.getuid()) throw new Error('private_binding_missing');
  return root;
}

function readPrivateJson(file, root) {
  const real = fs.realpathSync(file);
  if (!real.startsWith(`${root}${path.sep}`)) throw new Error('private_binding_missing');
  const st = fs.lstatSync(file);
  if (!st.isFile() || st.isSymbolicLink() || st.uid !== process.getuid() || (st.mode & 0o077) !== 0) throw new Error('private_binding_missing');
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function verifyCaptureTree(value, root, captures = []) {
  if (!value || typeof value !== 'object') return captures;
  if (typeof value.stdout === 'string' && typeof value.stderr === 'string' && typeof value.status === 'string' && typeof value.stdoutSha256 === 'string') {
    for (const field of ['stdout', 'stderr', 'status']) {
      const file = value[field];
      const real = fs.realpathSync(file);
      if (!real.startsWith(`${root}${path.sep}`)) throw new Error('raw_ci_evidence_invalid');
      const st = fs.lstatSync(file);
      if (!st.isFile() || st.isSymbolicLink() || st.uid !== process.getuid() || (st.mode & 0o077) !== 0 || st.size > 16 * 1024 * 1024) throw new Error('raw_ci_evidence_invalid');
    }
    const stdout = fs.readFileSync(value.stdout);
    const stderr = fs.readFileSync(value.stderr);
    const status = fs.readFileSync(value.status);
    if (sha(stdout) !== value.stdoutSha256 || sha(stderr) !== value.stderrSha256 || sha(status) !== value.statusSha256 ||
        stdout.length !== value.stdoutBytes || stderr.length !== value.stderrBytes || status.toString('utf8') !== '0') throw new Error('raw_ci_evidence_invalid');
    captures.push({ record: value, stdout: stdout.toString('utf8'), stderr: stderr.toString('utf8') });
    return captures;
  }
  for (const child of Object.values(value)) verifyCaptureTree(child, root, captures);
  return captures;
}

function captureIntegrityProjection(value) {
  if (!value || typeof value !== 'object') return value;
  if (typeof value.stdout === 'string' && typeof value.stderr === 'string' && typeof value.status === 'string') {
    return {
      status: 0,
      stdoutBytes: value.stdoutBytes,
      stderrBytes: value.stderrBytes,
      stdoutSha256: value.stdoutSha256,
      stderrSha256: value.stderrSha256,
      statusSha256: value.statusSha256,
    };
  }
  return Object.fromEntries(Object.entries(value).map(([key, child]) => [key, captureIntegrityProjection(child)]));
}

function readCaptureText(record, root) {
  const matches = verifyCaptureTree(record, root);
  if (matches.length !== 1) throw new Error('raw_ci_evidence_invalid');
  return matches[0].stdout;
}

function decodeSingle(text) {
  const value = JSON.parse(text);
  if (!Array.isArray(value) || value.length !== 1 || !value[0] || typeof value[0] !== 'object') throw new Error('raw_ci_evidence_invalid');
  return value[0];
}

function validateCiPrivate(hosted, contract, ownerRoot) {
  const runBindingPath = path.join(ownerRoot, `ci-run-binding-${hosted.run.id}-${hosted.run.attempt}.json`);
  const runBinding = readPrivateJson(runBindingPath, ownerRoot);
  const policyBinding = readPrivateJson(path.join(ownerRoot, 'ci-policy-binding.json'), ownerRoot);
  const candidateNames = ['candidate-binding-renewed.json', 'candidate-binding.json'].filter((name) => fs.existsSync(path.join(ownerRoot, name)));
  if (candidateNames.length !== 1) throw new Error('candidate_identity_drift');
  const candidateBinding = readPrivateJson(path.join(ownerRoot, candidateNames[0]), ownerRoot);
  if (runBinding.plan !== '03' || runBinding.accepted !== true || runBinding.runId !== hosted.run.id || runBinding.attempt !== hosted.run.attempt ||
      runBinding.candidateCommit !== hosted.candidate.commit || runBinding.candidateTree !== hosted.candidate.tree ||
      policyBinding.candidateCommit !== hosted.candidate.commit || policyBinding.candidateTree !== hosted.candidate.tree ||
      policyBinding.candidateBindingFile !== candidateNames[0] || candidateBinding.candidateCommit !== hosted.candidate.commit || candidateBinding.candidateTree !== hosted.candidate.tree ||
      candidateBinding.sourceBaseCommit !== hosted.candidate.baseCommit) throw new Error('candidate_identity_drift');
  const runRecords = verifyCaptureTree(runBinding.rawCapturePointers, ownerRoot);
  if (runRecords.length < 9 || !eqJson(captureIntegrityProjection(runBinding.rawCapturePointers), runBinding.rawCaptureIntegrity)) throw new Error('raw_ci_evidence_invalid');
  const policyRecords = verifyCaptureTree(policyBinding.rawResponsePointers, ownerRoot);
  if (policyRecords.length !== 5 || policyBinding.rawResponseIntegrity?.verifiedAgainstNormalizedValues !== true ||
      !eqJson(captureIntegrityProjection(policyBinding.rawResponsePointers), Object.fromEntries(Object.entries(policyBinding.rawResponseIntegrity).filter(([key]) => key !== 'verifiedAgainstNormalizedValues')))) throw new Error('raw_ci_evidence_invalid');
  const routeText = (capture) => {
    const text = readCaptureText(capture, ownerRoot);
    return text;
  };
  const finalRun = decodeSingle(routeText(runBinding.rawCapturePointers.finalRun));
  const finalPull = decodeSingle(routeText(runBinding.rawCapturePointers.finalPullRequest));
  const finalMain = decodeSingle(routeText(runBinding.rawCapturePointers.finalBase));
  const initialPull = decodeSingle(routeText(runBinding.rawCapturePointers.initialPullRequest));
  const jobsPages = JSON.parse(routeText(runBinding.rawCapturePointers.jobs));
  const checkPages = JSON.parse(routeText(runBinding.rawCapturePointers.checks));
  const branchPages = JSON.parse(routeText(runBinding.rawCapturePointers.finalBranchProtection));
  const rulesPages = JSON.parse(routeText(runBinding.rawCapturePointers.finalEffectiveRules));
  const policy = normalizePolicy(branchPages, rulesPages);
  if (!policy.ok) throw new Error('raw_ci_evidence_invalid');
  const recordedPolicy = { strict: policy.strict, rulesetEvidence: policy.rulesetEvidence, effectiveRuleCount: policy.effectiveRuleCount, requiredContexts: policy.required };
  if (!eqJson(recordedPolicy, { strict: hosted.policy?.strict, rulesetEvidence: hosted.policy?.rulesetEvidence, effectiveRuleCount: hosted.policy?.effectiveRuleCount, requiredContexts: hosted.policy?.requiredContexts })) throw new Error('raw_ci_evidence_invalid');
  const deliveryRoot = fs.realpathSync(candidateBinding.deliveryRoot);
  const manifest = JSON.parse(fs.readFileSync(path.join(deliveryRoot, 'script/ci_leaf_manifest.json'), 'utf8'));
  const requiredRows = [...manifest.proof_leaves, ...manifest.required_control_nodes];
  const logs = {};
  for (const [jobId, capture] of Object.entries(runBinding.rawCapturePointers.jobLogs ?? {})) logs[jobId] = routeText(capture);
  const classifier = { ok: true, ...policyBinding.classifierState, releaseCandidateScope: 'full_matrix' };
  const skip = deriveSkipContract(manifest, policyBinding.skipConditions, classifier);
  if (!skip.ok) throw new Error('raw_ci_evidence_invalid');
  const graph = validateRunGraph({
    run: finalRun,
    expectedAttempt: hosted.run.attempt,
    expectedWorkflowId: hosted.workflow.id,
    expectedBaseRef: 'main',
    expectedCheckoutActions: Object.fromEntries(Object.entries(contract.graph.requiredCheckoutPolicies).map(([name, row]) => [name, row.actionPin])),
    checkoutKinds: Object.fromEntries(Object.entries(contract.graph.requiredCheckoutPolicies).map(([name, row]) => [name, row.kind])),
    policy,
    manifest,
    jobsPages,
    checkPages,
    checkoutLogs: logs,
    authorizedSkips: skip.authorizedSkipIds,
    expectedLeafRun: skip.shouldRun,
    sourceLessJobs: contract.graph.sourceLessJobs,
  });
  if (!graph.ok || graph.jobCount !== hosted.run.jobCount || graph.checkCount !== hosted.run.checkCount || graph.governedMergeOid !== hosted.governedMergeOid) throw new Error('raw_ci_evidence_invalid');
  const fresh = validateFreshSnapshot({ runId: hosted.run.id, attempt: hosted.run.attempt, workflowId: hosted.workflow.id, checkSuiteId: hosted.run.checkSuiteId, pullNumber: hosted.pullRequest.number, candidateCommit: hosted.candidate.commit, baseCommit: hosted.candidate.baseCommit, finalRun, finalPull, finalMain });
  if (!fresh.ok || initialPull.number !== hosted.pullRequest.number) throw new Error('raw_ci_evidence_invalid');
  const actualJobs = [...manifest.proof_leaves.map((row) => row.display_name), ...manifest.required_control_nodes.map((row) => row.display_name), 'Crosswake CI'].map((name) => {
    const parsedJobs = parsePageEnvelope(jobsPages, 'jobs');
    const parsedChecks = parsePageEnvelope(checkPages, 'check_runs');
    if (!parsedJobs.ok || !parsedChecks.ok) throw new Error('raw_ci_evidence_invalid');
    const job = parsedJobs.records.find((row) => row.name === name);
    const check = job ? parsedChecks.records.find((row) => row.url === job.check_run_url) : null;
    const checkout = graph.checkouts[name] ?? null;
    return { name, jobId: job?.id ?? null, checkRunId: check?.id ?? null, conclusion: job?.conclusion ?? null, checkout };
  });
  if (!eqJson(actualJobs, hosted.requiredJobs) || policyBinding.workflowSource?.version !== hosted.workflow.source.version || policyBinding.workflowSource?.blobOid !== hosted.workflow.source.blobOid) throw new Error('raw_ci_evidence_invalid');
  const jobsParsed = parsePageEnvelope(jobsPages, 'jobs');
  const checksParsed = parsePageEnvelope(checkPages, 'check_runs');
  if (!jobsParsed.ok || !checksParsed.ok || jobsParsed.records.length !== hosted.run.jobCount || checksParsed.records.length !== hosted.run.checkCount) throw new Error('raw_ci_evidence_invalid');
  const requiredNames = new Set(actualJobs.map((row) => row.name));
  const advisoryNames = contract.graph.advisoryJobs;
  if (!Array.isArray(advisoryNames) || new Set(advisoryNames).size !== advisoryNames.length) throw new Error('raw_ci_evidence_invalid');
  const advisoryRows = [];
  for (const name of advisoryNames) {
    const matches = jobsParsed.records.filter((row) => row.name === name);
    if (matches.length !== 1) throw new Error('raw_ci_evidence_invalid');
    const job = matches[0];
    const linkedChecks = checksParsed.records.filter((row) => row.url === job.check_run_url);
    if (linkedChecks.length !== 1) throw new Error('raw_ci_evidence_invalid');
    const check = linkedChecks[0];
    const terminal = new Set(['success', 'failure', 'cancelled', 'skipped']);
    if (job.run_id !== hosted.run.id || job.run_attempt !== hosted.run.attempt || job.status !== 'completed' || !terminal.has(job.conclusion) ||
        check.id !== Number(job.check_run_url.match(/\/check-runs\/(\d+)$/)?.[1]) || check.name !== name ||
        check.check_suite?.id !== hosted.run.checkSuiteId || check.status !== 'completed' || check.conclusion !== job.conclusion) throw new Error('raw_ci_evidence_invalid');
    advisoryRows.push({ name, jobId: job.id, checkRunId: check.id, attempt: job.run_attempt, status: job.status, conclusion: job.conclusion });
  }
  const accounted = new Set([...requiredNames, ...advisoryNames]);
  if (accounted.size !== requiredNames.size + advisoryNames.length || jobsParsed.records.some((row) => !accounted.has(row.name))) throw new Error('raw_ci_evidence_invalid');
  return {
    accepted: true,
    advisoryJobs: advisoryRows,
    policyFingerprints: { branchProtection: fingerprint(branchPages), effectiveRules: fingerprint(rulesPages) },
    privateIntegrity: { retainedCapturesValid: true, allJobsReconstructed: true, requiredGraphGreen: true },
  };
}

export function verifyCurrentLocalProjection(rechecked, onDisk, local) {
  if (!eqJson(rechecked, onDisk) || !eqJson(rechecked, local)) throw new Error('local_raw_evidence_invalid');
  return true;
}

function privateLocalIntegrity(local, ownerRoot) {
  const finalBindingPath = path.join(ownerRoot, 'final-source-binding.json');
  const finalBinding = readPrivateJson(finalBindingPath, ownerRoot);
  if (finalBinding.schemaVersion !== 1 || finalBinding.phase !== 178 || finalBinding.plan !== '05' ||
      !HEX40.test(finalBinding.finalCommit ?? '') || !HEX40.test(finalBinding.finalTree ?? '') ||
      finalBinding.finalCommit !== local.source?.commit || finalBinding.finalTree !== local.source?.tree ||
      typeof finalBinding.proofRoot !== 'string' || typeof finalBinding.invocationRecord !== 'string') throw new Error('private_binding_missing');
  const runRoot = fs.realpathSync(finalBinding.proofRoot);
  const canonicalTempRoots = [path.resolve('/private/tmp'), fs.realpathSync(os.tmpdir())];
  if (!canonicalTempRoots.some((base) => runRoot === base || runRoot.startsWith(`${base}${path.sep}`))) throw new Error('private_binding_missing');
  const tempOutput = path.join(ownerRoot, `.join-recheck-${crypto.randomUUID()}.json`);
  let rechecked;
  try {
    rechecked = collectLocalProof(finalBinding.invocationRecord, tempOutput, 'final', finalBindingPath);
  } catch {
    fs.rmSync(tempOutput, { force: true });
    throw new Error('local_raw_evidence_invalid');
  }
  const onDisk = JSON.parse(fs.readFileSync(path.join(HERE, 'final-local-proof.json'), 'utf8'));
  fs.rmSync(tempOutput, { force: true });
  verifyCurrentLocalProjection(rechecked, onDisk, local);
  return { bindingValid: true, invocationValid: true, retainedCapturesValid: true, headTreeIndexAndNulSnapshotsUnchanged: true };
}

function ensurePrivateDirectory(directory) {
  fs.mkdirSync(directory, { recursive: true, mode: 0o700 });
  fs.chmodSync(directory, 0o700);
  const st = fs.lstatSync(directory);
  if (!st.isDirectory() || st.isSymbolicLink() || st.uid !== process.getuid() || (st.mode & 0o077) !== 0) throw new Error('private_binding_missing');
  return fs.realpathSync(directory);
}

function captureTool(executable, args, { captureRoot, label, env = process.env }) {
  const result = spawnSync(executable, args, {
    encoding: 'utf8', timeout: 30000, maxBuffer: 32 * 1024 * 1024,
    env: { ...env, GIT_OPTIONAL_LOCKS: '0' },
  });
  if (!captureRoot) throw new Error('private_binding_missing');
  const root = ensurePrivateDirectory(captureRoot);
  const stem = `${String(captureTool.sequence++).padStart(2, '0')}-${label}`;
  const paths = Object.fromEntries(['stdout', 'stderr', 'status'].map((name) => [name, path.join(root, `${stem}.${name}`)]));
  const stdout = Buffer.from(result.stdout ?? '');
  const stderr = Buffer.from(result.stderr ?? result.error?.message ?? '');
  const status = Buffer.from(`${result.status ?? `signal:${result.signal ?? 'unknown'}`}`);
  for (const [name, bytes] of [['stdout', stdout], ['stderr', stderr], ['status', status]]) {
    fs.writeFileSync(paths[name], bytes, { mode: 0o600, flag: 'wx' });
    fs.chmodSync(paths[name], 0o600);
  }
  const capture = {
    label, executable: path.basename(executable), args, ...paths,
    stdoutBytes: stdout.length, stderrBytes: stderr.length, statusBytes: status.length,
    stdoutSha256: sha(stdout), stderrSha256: sha(stderr), statusSha256: sha(status),
  };
  captureTool.records.push(capture);
  if (result.error || result.status !== 0) throw new Error(label.startsWith('git-') ? 'live_pull_request_drift' : 'github_read_failed');
  return stdout.toString('utf8');
}
captureTool.sequence = 0;
captureTool.records = [];

function ghRead(route, { captureRoot, executable = 'gh', env = process.env } = {}) {
  const args = ['--hostname', 'github.com', 'api', '--paginate', '--slurp', route];
  const text = captureTool(executable, args, { captureRoot, label: 'gh-read', env });
  try { return JSON.parse(text); } catch { throw new Error('github_read_failed'); }
}

function gitMergeRef({ captureRoot, executable = 'git', env = process.env }) {
  const args = ['ls-remote', 'https://github.com/szTheory/crosswake.git', 'refs/pull/238/merge'];
  const text = captureTool(executable, args, { captureRoot, label: 'git-merge-ref', env });
  const lines = text.trim().split(/\r?\n/).filter(Boolean);
  if (lines.length !== 1) throw new Error('live_pull_request_drift');
  const match = lines[0].match(/^([0-9a-f]{40})\trefs\/pull\/238\/merge$/i);
  if (!match) throw new Error('live_pull_request_drift');
  return { ref: 'refs/pull/238/merge', oid: match[1].toLowerCase() };
}

function runProjection(run) {
  return { id: run.id, attempt: run.run_attempt, workflowId: run.workflow_id, checkSuiteId: run.check_suite_id, headCommit: run.head_sha, event: run.event, status: run.status, conclusion: run.conclusion };
}
function pullProjection(pull) {
  return {
    number: pull.number, state: pull.state, repo: pull.base?.repo?.full_name,
    headRepo: pull.head?.repo?.full_name, baseRepo: pull.base?.repo?.full_name,
    headCommit: pull.head?.sha, baseRef: pull.base?.ref, baseCommit: pull.base?.sha,
    mergeCommitSha: pull.merge_commit_sha,
  };
}
function decodeRun(pages) { return decodeSingle(JSON.stringify(pages)); }

export function liveRead(hosted, { captureRoot, ghExecutable = 'gh', gitExecutable = 'git', env = process.env } = {}) {
  if (hosted?.repository !== 'szTheory/crosswake' || hosted?.pullRequest?.number !== 238) throw new Error('hosted_proof_invalid');
  captureTool.records = [];
  const repo = 'repos/szTheory/crosswake';
  const read = (route) => ghRead(route, { captureRoot, executable: ghExecutable, env });
  const readRun = () => decodeRun(read(`${repo}/actions/runs/${hosted.run.id}`));
  const readPull = () => decodeRun(read(`${repo}/pulls/238`));
  const readBase = () => decodeRun(read(`${repo}/commits/main`));
  const readMerge = () => gitMergeRef({ captureRoot, executable: gitExecutable, env });
  const start = {
    run: readRun(), pull: readPull(), base: readBase(), merge: readMerge(),
  };
  const branchPages = read(`${repo}/branches/main/protection/required_status_checks`);
  const rulesPages = read(`${repo}/rules/branches/main?per_page=100`);
  const policy = normalizePolicy(branchPages, rulesPages);
  if (!policy.ok) throw new Error('policy_unavailable');
  const policyFingerprints = { branchProtection: fingerprint(branchPages), effectiveRules: fingerprint(rulesPages) };
  const end = {
    run: readRun(), pull: readPull(), base: readBase(), merge: readMerge(),
    branchProtectionFingerprint: fingerprint(read(`${repo}/branches/main/protection/required_status_checks`)),
    effectiveRulesFingerprint: fingerprint(read(`${repo}/rules/branches/main?per_page=100`)),
  };
  const startProjection = {
    run: runProjection(start.run), pullRequest: pullProjection(start.pull), baseCommit: start.base.sha,
    mergeRef: start.merge, policyFingerprints,
  };
  const endProjection = {
    run: runProjection(end.run), pullRequest: pullProjection(end.pull), baseCommit: end.base.sha,
    mergeRef: end.merge, policyFingerprints: { branchProtection: end.branchProtectionFingerprint, effectiveRules: end.effectiveRulesFingerprint },
  };
  const canonicalRepository = 'szTheory/crosswake';
  const stable = eqJson(startProjection, endProjection) && end.run.run_attempt === hosted.run.attempt &&
    end.run.head_sha === hosted.candidate.commit && end.pull.number === 238 &&
    end.pull.base?.repo?.full_name === canonicalRepository && end.pull.head?.repo?.full_name === canonicalRepository &&
    end.pull.merge_commit_sha === end.merge.oid;
  verifyLiveCaptures(captureRoot, captureTool.records);
  return {
    canonicalRepository,
    pullRequest: pullProjection(end.pull),
    mergeRef: end.merge,
    run: runProjection(end.run),
    policy: {
      current: true, strict: policy.strict, rulesetEvidence: policy.rulesetEvidence,
      effectiveRuleCount: policy.effectiveRuleCount, requiredContexts: policy.required,
      branchProtectionFingerprint: policyFingerprints.branchProtection,
      effectiveRulesFingerprint: policyFingerprints.effectiveRules,
    },
    canonicalBaseCommit: end.base.sha,
    barrierStable: stable,
    barrierStart: startProjection,
    barrierEnd: endProjection,
    captureRoot: fs.realpathSync(captureRoot),
    captures: captureTool.records,
    captureIntegrity: true,
  };
}

function verifyLiveCaptures(captureRoot, captures) {
  const root = fs.realpathSync(captureRoot);
  if (!Array.isArray(captures) || captures.length !== 12) throw new Error('private_capture_integrity_failed');
  for (const capture of captures) {
    for (const [field, sizeField, hashField] of [['stdout', 'stdoutBytes', 'stdoutSha256'], ['stderr', 'stderrBytes', 'stderrSha256'], ['status', 'statusBytes', 'statusSha256']]) {
      const file = capture[field];
      const real = fs.realpathSync(file);
      if (!real.startsWith(`${root}${path.sep}`)) throw new Error('private_capture_integrity_failed');
      const st = fs.lstatSync(file);
      if (!st.isFile() || st.isSymbolicLink() || st.uid !== process.getuid() || (st.mode & 0o077) !== 0) throw new Error('private_capture_integrity_failed');
      const bytes = fs.readFileSync(file);
      if (bytes.length !== capture[sizeField] || sha(bytes) !== capture[hashField]) throw new Error('private_capture_integrity_failed');
    }
    if (fs.readFileSync(capture.status, 'utf8') !== '0') throw new Error('private_capture_integrity_failed');
  }
}

function readJsonPublic(file) { return JSON.parse(fs.readFileSync(path.join(HERE, file), 'utf8')); }
function writeAcceptance(result) {
  const target = path.join(HERE, 'final-acceptance.json');
  const tmp = `${target}.${process.pid}.tmp`;
  fs.writeFileSync(tmp, `${JSON.stringify(result, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(tmp, target);
  fs.chmodSync(target, 0o644);
}

export function checkMode() {
  let last = blocked('unexpected_failure');
  try {
    const ownerRoot = privateOwnerRoot();
    const hosted = readJsonPublic('hosted-ci-proof.json');
    const local = readJsonPublic('final-local-proof.json');
    const contract = readJsonPublic('ci-contract.json');
    const candidate = readJsonPublic('candidate-source.json');
    if (candidate.candidateCommit !== hosted.candidate?.commit || candidate.candidateTree !== hosted.candidate?.tree || candidate.selectedCount !== 8) throw new Error('candidate_identity_drift');
    const ci = validateCiPrivate(hosted, contract, ownerRoot);
    const integrity = privateLocalIntegrity(local, ownerRoot);
    const liveCaptureRoot = path.join(ownerRoot, `join-live-${hosted.run.id}-${hosted.run.attempt}-${crypto.randomUUID()}`);
    ensurePrivateDirectory(liveCaptureRoot);
    const live = liveRead(hosted, { captureRoot: liveCaptureRoot });
    last = joinProof({ hosted, local, live, contract, privateIntegrity: { ...integrity, ...ci.privateIntegrity, ciPolicyFingerprints: ci.policyFingerprints, advisoryJobs: ci.advisoryJobs } });
    if (last.status !== 'pass') throw new Error(last.cause);
    const liveBinding = {
      schemaVersion: 1,
      phase: 178,
      plan: '05',
      observedAt: new Date().toISOString(),
      runId: hosted.run.id,
      attempt: hosted.run.attempt,
      candidateCommit: hosted.candidate.commit,
      governedMergeOid: hosted.governedMergeOid,
      mergeRef: live.mergeRef,
      pullRequestRepos: { base: live.pullRequest.baseRepo, head: live.pullRequest.headRepo },
      pullRequestState: live.pullRequest.state,
      canonicalBaseCommit: live.canonicalBaseCommit,
      policy: live.policy,
      barrierStart: live.barrierStart,
      barrierEnd: live.barrierEnd,
      liveCaptureRoot: live.captureRoot,
      liveCaptures: live.captures,
      liveCaptureIntegrity: live.captureIntegrity,
      ciPrivateIntegrity: { ...ci.privateIntegrity, policyFingerprints: ci.policyFingerprints, advisoryJobs: ci.advisoryJobs },
      accepted: true,
    };
    const bindingPath = path.join(ownerRoot, `final-join-live-binding-${hosted.run.id}-${hosted.run.attempt}-${crypto.randomUUID()}.json`);
    fs.writeFileSync(bindingPath, `${JSON.stringify(liveBinding, null, 2)}\n`, { mode: 0o600 });
    fs.chmodSync(bindingPath, 0o600);
    writeAcceptance(last);
    return { ok: true, result: last };
  } catch (error) {
    last = blocked(error?.message);
    writeAcceptance(last);
    return { ok: false, result: last };
  }
}

export function main(argv = process.argv.slice(2)) {
  if (argv.length === 1 && argv[0] === '--self-test') {
    if (STAGE_ORDER.length !== 9 || STAGE_ORDER[0] !== 'repository-preflight' || STAGE_ORDER.at(-1) !== 'repository-cleanliness') throw new Error('self_test_failed');
    process.stdout.write('join proof self-test: pass\n');
    return 0;
  }
  if (argv.length === 1 && argv[0] === '--check') {
    const result = checkMode();
    if (!result.ok) {
      process.stderr.write(`join proof: blocked cause=${result.result.cause}\n`);
      return 1;
    }
    process.stdout.write(`join proof: pass; hosted=${result.result.hosted.jobCount}/${result.result.hosted.checkCount}; local=${result.result.local.stageCount}/9; requirements=MAINT-07,MAINT-08\n`);
    return 0;
  }
  process.stderr.write('usage: join_proof.mjs --self-test | --check\n');
  return 2;
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { process.exitCode = main(); }
  catch (error) { process.stderr.write(`join proof: blocked cause=${safeCause(error?.message)}\n`); process.exitCode = 1; }
}
