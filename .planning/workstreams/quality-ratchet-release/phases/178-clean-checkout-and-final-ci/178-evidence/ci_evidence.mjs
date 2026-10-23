#!/usr/bin/env node
import fs from 'node:fs';
import { createHash, randomUUID } from 'node:crypto';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PHASE_DIR = path.dirname(HERE);
const EVIDENCE_DIR = HERE;
const REPO = 'szTheory/crosswake';
const WORKFLOW_PATH = '.github/workflows/crosswake-ci.yml';
const PRIVATE_OWNER_POINTER = '/private/tmp/crosswake-178-owner-env';
const PRIVATE_BINDING_NAMES = ['candidate-binding-renewed.json', 'candidate-binding.json'];
const UMBRELLA_ID = 'merge-blocking-crosswake-ci';

export function safeCause(message) {
  if (typeof message === 'string' && /^[a-z][a-z0-9]*(?:_[a-z0-9]+)*(?:,[a-z][a-z0-9]*(?:_[a-z0-9]+)*)*$/.test(message)) return message;
  return 'adapter_unexpected_failure';
}

export function parsePageEnvelope(raw, member) {
  let pages;
  try {
    pages = typeof raw === 'string' ? JSON.parse(raw) : raw;
  } catch {
    return { ok: false, cause: 'malformed_page_json' };
  }
  if (!Array.isArray(pages) || pages.length === 0) return { ok: false, cause: 'missing_page' };
  const records = [];
  let totalCount = null;
  const ids = new Set();
  for (const page of pages) {
    if (!page || typeof page !== 'object' || !Number.isInteger(page.total_count) || !Array.isArray(page[member])) {
      return { ok: false, cause: 'malformed_page_shape' };
    }
    if (totalCount === null) totalCount = page.total_count;
    if (page.total_count !== totalCount) return { ok: false, cause: 'inconsistent_page_total' };
    for (const record of page[member]) {
      if (!record || typeof record !== 'object' || !Number.isSafeInteger(record.id)) {
        return { ok: false, cause: 'missing_record_id' };
      }
      if (ids.has(record.id)) return { ok: false, cause: 'duplicate_record_id' };
      ids.add(record.id);
      records.push(record);
    }
  }
  if (records.length !== totalCount) return { ok: false, cause: 'incomplete_page_count' };
  return { ok: true, pageCount: pages.length, totalCount, records };
}

function singleResponse(raw) {
  let value;
  try { value = typeof raw === 'string' ? JSON.parse(raw) : raw; }
  catch { return { ok: false, cause: 'malformed_response_json' }; }
  if (!Array.isArray(value) || value.length !== 1 || !value[0] || typeof value[0] !== 'object') {
    return { ok: false, cause: 'incomplete_single_response' };
  }
  return { ok: true, value: value[0] };
}

function policyResponse(raw, name) {
  if (raw && typeof raw === 'object' && !Array.isArray(raw) && Number.isInteger(raw.status)) {
    return { ok: false, cause: `${name}_http_${raw.status}` };
  }
  return singleResponse(raw);
}

function addRequired(target, context, appId, source, errors) {
  if (typeof context !== 'string' || context.trim() === '') {
    errors.push('malformed_required_context');
    return;
  }
  if (appId !== null && appId !== undefined && !Number.isSafeInteger(appId)) {
    errors.push('malformed_required_app_id');
    return;
  }
  const previous = target.get(context);
  if (previous && previous.appId !== null && appId !== null && previous.appId !== appId) {
    errors.push('conflicting_required_app_id');
    return;
  }
  if (!previous) target.set(context, { context, appId: appId ?? null, sources: [source] });
  else {
    previous.appId = previous.appId ?? appId ?? null;
    if (!previous.sources.includes(source)) previous.sources.push(source);
  }
}

export function normalizePolicy(branchProtectionRaw, rulesRaw) {
  const protection = policyResponse(branchProtectionRaw, 'branch_protection');
  if (!protection.ok) return { ok: false, blockers: [protection.cause] };
  if (rulesRaw && typeof rulesRaw === 'object' && !Array.isArray(rulesRaw) && Number.isInteger(rulesRaw.status)) {
    return { ok: false, blockers: [`effective_rules_http_${rulesRaw.status}`] };
  }
  let rulesPages;
  try { rulesPages = typeof rulesRaw === 'string' ? JSON.parse(rulesRaw) : rulesRaw; }
  catch { return { ok: false, blockers: ['effective_rules_malformed_json'] }; }
  if (!Array.isArray(rulesPages) || rulesPages.length === 0 || rulesPages.some((page) => !Array.isArray(page))) {
    return { ok: false, blockers: ['effective_rules_incomplete_page'] };
  }
  const branch = protection.value;
  if (typeof branch.strict !== 'boolean') return { ok: false, blockers: ['branch_protection_missing_strict'] };
  const required = new Map();
  const errors = [];
  if (Array.isArray(branch.contexts)) {
    for (const context of branch.contexts) addRequired(required, context, null, 'branch_protection', errors);
  }
  if (branch.checks !== undefined) {
    if (!Array.isArray(branch.checks)) errors.push('branch_protection_malformed_checks');
    else for (const check of branch.checks) {
      if (!check || typeof check !== 'object') errors.push('branch_protection_malformed_check');
      else {
        if (check.app_id !== undefined && check.app_id !== null && (!Number.isSafeInteger(check.app_id) || check.app_id < 0)) errors.push('branch_protection_malformed_app_id');
        addRequired(required, check.context, check.app_id ?? null, 'branch_protection', errors);
      }
    }
  }
  if (required.size === 0) errors.push('branch_protection_missing_required_checks');

  const rules = rulesPages.flat();
  for (const rule of rules) {
    if (!rule || typeof rule !== 'object' || typeof rule.type !== 'string') {
      errors.push('effective_rules_malformed_rule');
      continue;
    }
    if (rule.type !== 'required_status_checks') continue;
    const checks = rule.parameters?.required_status_checks;
    if (!Array.isArray(checks) || checks.length === 0) {
      errors.push('ruleset_missing_required_status_checks');
      continue;
    }
    for (const check of checks) {
      if (!check || typeof check !== 'object') {
        errors.push('ruleset_malformed_required_status_check');
        continue;
      }
      const integrationId = check.integration_id ?? null;
      if (integrationId !== null && (!Number.isSafeInteger(integrationId) || integrationId < 0)) errors.push('ruleset_malformed_integration_id');
      addRequired(required, check.context, integrationId, 'effective_rules', errors);
    }
  }
  if (errors.length) return { ok: false, blockers: [...new Set(errors)] };
  return {
    ok: true,
    strict: branch.strict,
    rulesetEvidence: rules.length === 0 ? 'successful-empty' : 'active-rules-observed',
    effectiveRuleCount: rules.length,
    required: [...required.values()].map(({ context, appId, sources }) => ({ context, appId, sources })).sort((a, b) => a.context.localeCompare(b.context)),
  };
}

export function extractCheckoutOid(logText, pinnedActionSha) {
  if (typeof logText !== 'string' || !/^[0-9a-f]{40}$/i.test(pinnedActionSha ?? '')) return { ok: false, cause: 'missing_checkout_log' };
  const pinPattern = new RegExp(`actions\\/checkout@${pinnedActionSha}|actions\\/checkout[^\\n]*SHA: ${pinnedActionSha}`, 'i');
  if (!pinPattern.test(logText)) return { ok: false, cause: 'checkout_action_pin_unobserved' };
  const lines = logText.replace(/^\uFEFF/, '').split(/\r?\n/);
  const oids = new Set();
  const refs = new Set();
  for (let index = 0; index < lines.length; index += 1) {
    const command = lines[index].match(/\bgit checkout\b([^\n]*)/i)?.[1];
    if (command) {
      const finalArgument = command.trim().match(/(?:"([^"]+)"|'([^']+)'|(\S+))$/);
      const ref = finalArgument?.[1] ?? finalArgument?.[2] ?? finalArgument?.[3];
      if (ref) refs.add(ref);
      if (/^[0-9a-f]{40}$/i.test(ref ?? '')) oids.add(ref.toLowerCase());
    }
    if (/\bgit log -1 --format=%H\b/i.test(lines[index])) {
      const next = lines[index + 1]?.match(/(?:^|\s)([0-9a-f]{40})(?:\s|$)/i);
      if (next) oids.add(next[1].toLowerCase());
    }
  }
  if (oids.size === 0) return { ok: false, cause: 'checkout_oid_unobserved' };
  if (oids.size !== 1) return { ok: false, cause: 'checkout_oid_ambiguous' };
  if (refs.size !== 1) return { ok: false, cause: 'checkout_ref_ambiguous' };
  return { ok: true, oid: [...oids][0], ref: [...refs][0] };
}

function flattenPages(pages, member, label, blockers) {
  if (!Array.isArray(pages) || pages.length === 0) {
    blockers.push(`${label}_missing_page`);
    return [];
  }
  const result = [];
  const ids = new Set();
  let total = null;
  for (const page of pages) {
    if (!page || !Number.isInteger(page.total_count) || !Array.isArray(page[member])) {
      blockers.push(`${label}_malformed_page`);
      return [];
    }
    if (total === null) total = page.total_count;
    else if (total !== page.total_count) blockers.push(`${label}_inconsistent_total`);
    for (const row of page[member]) {
      if (!Number.isSafeInteger(row?.id)) blockers.push(`${label}_missing_id`);
      else if (ids.has(row.id)) blockers.push(`${label}_duplicate_id`);
      else ids.add(row.id);
      result.push(row);
    }
  }
  if (result.length !== total) blockers.push(`${label}_incomplete_count`);
  return result;
}

export function exactCommitMatch(expectedCommit, observedCommit) {
  return /^[0-9a-f]{40}$/i.test(expectedCommit ?? '') && /^[0-9a-f]{40}$/i.test(observedCommit ?? '') && expectedCommit.toLowerCase() === observedCommit.toLowerCase();
}

export function validateFreshSnapshot({ runId, attempt, workflowId, checkSuiteId, pullNumber, candidateCommit, baseCommit, finalRun, finalPull, finalMain }) {
  if (!finalRun || finalRun.id !== runId || finalRun.run_attempt !== attempt || finalRun.workflow_id !== workflowId || finalRun.check_suite_id !== checkSuiteId || finalRun.event !== 'pull_request' || finalRun.status !== 'completed' || !exactCommitMatch(finalRun.head_sha, candidateCommit)) return { ok: false, cause: 'final_run_attempt_or_head_drift' };
  if (!validRunUrl(finalRun.html_url, runId)) return { ok: false, cause: 'final_run_url_unavailable' };
  if (!Array.isArray(finalRun.pull_requests) || finalRun.pull_requests.length !== 1 || finalRun.pull_requests[0].number !== pullNumber || !exactCommitMatch(finalRun.pull_requests[0].head?.sha, candidateCommit) || finalRun.pull_requests[0].base?.ref !== 'main' || !exactCommitMatch(finalRun.pull_requests[0].base?.sha, baseCommit)) return { ok: false, cause: 'final_run_pull_request_drift' };
  if (!finalPull || finalPull.number !== pullNumber || finalPull.state !== 'open' || !exactCommitMatch(finalPull.head?.sha, candidateCommit) || finalPull.base?.ref !== 'main' || !exactCommitMatch(finalPull.base?.sha, baseCommit)) return { ok: false, cause: 'final_pr_candidate_or_base_drift' };
  if (!exactCommitMatch(finalMain?.sha, baseCommit)) return { ok: false, cause: 'canonical_base_moved_before_acceptance' };
  return { ok: true };
}

export function validRunUrl(value, runId) {
  if (!Number.isSafeInteger(runId) || typeof value !== 'string') return false;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && url.hostname === 'github.com' && url.pathname === `/szTheory/crosswake/actions/runs/${runId}` && !url.username && !url.password;
  } catch { return false; }
}

export function validateRunGraph(input) {
  const blockers = [];
  const { run, expectedAttempt, expectedWorkflowId, expectedBaseRef, expectedCheckoutAction, policy, manifest, checkoutLogs = {}, authorizedSkips = [] } = input;
  if (!run || !Number.isSafeInteger(run.id) || !Number.isInteger(run.run_attempt)) blockers.push('run_metadata_missing');
  if (run?.run_attempt !== expectedAttempt) blockers.push('latest_attempt_mismatch');
  if (run?.workflow_id !== expectedWorkflowId) blockers.push('workflow_identity_mismatch');
  if (run?.event !== 'pull_request') blockers.push('unexpected_event');
  const pr = Array.isArray(run?.pull_requests) && run.pull_requests.length === 1 ? run.pull_requests[0] : null;
  if (!pr || !/^[0-9a-f]{40}$/i.test(pr.head?.sha ?? '') || !/^[0-9a-f]{40}$/i.test(pr.base?.sha ?? '') || pr.base?.ref !== expectedBaseRef) blockers.push('pull_request_identity_missing_or_drifted');
  if (!policy?.ok || !Array.isArray(policy.required)) blockers.push('required_policy_unavailable');

  const leafRows = Array.isArray(manifest?.proof_leaves) ? manifest.proof_leaves : [];
  const controls = Array.isArray(manifest?.required_control_nodes) ? manifest.required_control_nodes : [];
  if (leafRows.length === 0) blockers.push('selected_manifest_has_no_proof_leaves');
  const requiredRows = [...leafRows.map((row) => ({ ...row, kind: 'leaf' })), ...controls.map((row) => ({ ...row, kind: 'control' })), { node_id: UMBRELLA_ID, display_name: 'Crosswake CI', required_result: 'success', kind: 'umbrella' }];
  const jobs = flattenPages(input.jobsPages, 'jobs', 'jobs', blockers);
  const checks = flattenPages(input.checkPages, 'check_runs', 'checks', blockers);
  const requiredJobByName = new Map();
  for (const row of requiredRows) {
    const matches = jobs.filter((job) => job.name === row.display_name);
    if (matches.length !== 1) blockers.push('required_job_cardinality_mismatch');
    else requiredJobByName.set(row.display_name, matches[0]);
  }
  const allUrls = checks.map((check) => check.url).filter((url) => typeof url === 'string');
  if (new Set(allUrls).size !== allUrls.length) blockers.push('duplicate_check_url');
  const usedCheckUrls = new Set();
  const checkForJob = (job) => {
    if (typeof job?.check_run_url !== 'string') return null;
    const match = checks.filter((check) => check.url === job.check_run_url);
    if (match.length !== 1 || usedCheckUrls.has(job.check_run_url)) return null;
    usedCheckUrls.add(job.check_run_url);
    return match[0];
  };
  const requiredCheckByName = new Map();
  for (const row of requiredRows) {
    const job = requiredJobByName.get(row.display_name);
    if (!job) continue;
    if (job.run_id !== run?.id || job.run_attempt !== expectedAttempt) blockers.push('required_job_run_attempt_mismatch');
    const check = checkForJob(job);
    if (!check) blockers.push('required_job_check_url_unmatched');
    else {
      if (check.name !== row.display_name) blockers.push('required_job_check_name_mismatch');
      if (check.check_suite?.id !== run?.check_suite_id) blockers.push('required_check_suite_mismatch');
      requiredCheckByName.set(row.display_name, check);
      const checkUrlId = job.check_run_url.match(/\/check-runs\/(\d+)$/)?.[1];
      if (check.id !== Number(checkUrlId)) blockers.push('required_job_check_url_id_mismatch');
    }
    const expectedOutcome = row.kind === 'leaf' ? ['success', 'skipped'] : ['success'];
    if (job.status !== 'completed' || !expectedOutcome.includes(job.conclusion)) blockers.push('required_job_not_successful_terminal');
    if (check && (check.status !== 'completed' || !expectedOutcome.includes(check.conclusion))) blockers.push('required_check_not_successful_terminal');
    if (check && job.conclusion !== check.conclusion) blockers.push('required_job_check_conclusion_mismatch');
  }
  const allowedSkipNames = new Set(authorizedSkips);
  const expectedLeafRun = input.expectedLeafRun ?? {};
  for (const leaf of leafRows) {
    const job = requiredJobByName.get(leaf.display_name);
    const check = requiredCheckByName.get(leaf.display_name);
    if (typeof expectedLeafRun[leaf.leaf_id] !== 'boolean') blockers.push('classifier_workflow_skip_contract_missing');
    if (job?.conclusion === 'skipped' || check?.conclusion === 'skipped') {
      if (!allowedSkipNames.has(leaf.leaf_id) || expectedLeafRun[leaf.leaf_id] !== false) blockers.push('unauthorized_skip');
    } else if (expectedLeafRun[leaf.leaf_id] === false) blockers.push('classifier_workflow_expected_leaf_skip');
  }

  const requiredApps = new Map((policy?.required ?? []).map((row) => [row.context, row.appId]));
  for (const [context, appId] of requiredApps) {
    const matches = checks.filter((check) => check.name === context);
    if (matches.length !== 1) blockers.push('required_context_cardinality_mismatch');
    else {
      if (appId !== null && matches[0].app?.id !== appId) blockers.push('required_context_app_mismatch');
      if (matches[0].check_suite?.id !== run?.check_suite_id) blockers.push('required_context_suite_mismatch');
      if (matches[0].status !== 'completed' || matches[0].conclusion !== 'success') blockers.push('required_context_not_successful');
    }
  }

  const checkouts = {};
  for (const row of [...leafRows.map((row) => ({ ...row, kind: 'leaf' })), ...controls.map((row) => ({ ...row, kind: 'control' }))]) {
    const job = requiredJobByName.get(row.display_name);
    if (!job || (row.kind === 'leaf' && job.conclusion === 'skipped')) continue;
    const kind = input.checkoutKinds?.[row.display_name];
    if (!['merge', 'head'].includes(kind)) {
      blockers.push('required_checkout_policy_missing');
      continue;
    }
    const expectedAction = input.expectedCheckoutActions?.[row.display_name] ?? expectedCheckoutAction;
    if (!expectedAction) {
      blockers.push('required_checkout_action_pin_missing');
      continue;
    }
    const parsed = extractCheckoutOid(checkoutLogs[job.id], expectedAction);
    if (!parsed.ok) blockers.push(parsed.cause);
    else {
      if (kind === 'head' && (parsed.oid !== pr?.head?.sha?.toLowerCase() || parsed.ref !== pr?.head?.sha?.toLowerCase())) blockers.push('head_checkout_oid_mismatch');
      if (kind === 'merge') {
        if (parsed.oid === pr?.head?.sha?.toLowerCase()) blockers.push('merge_checkout_is_pr_head');
        if (parsed.ref !== `refs/remotes/pull/${pr?.number}/merge`) blockers.push('checkout_ref_unrecognized');
      }
      checkouts[row.display_name] = { jobId: job.id, checkRunId: requiredCheckByName.get(row.display_name)?.id ?? null, attempt: expectedAttempt, kind, oid: parsed.oid, refKind: kind === 'head' ? 'pull_request_head_sha' : 'pull_request_merge_ref' };
    }
  }
  if (!input.sourceLessJobs?.includes('Crosswake CI')) blockers.push('umbrella_source_less_policy_missing');
  const mergeOids = new Set(Object.values(checkouts).filter((row) => row.kind === 'merge').map((row) => row.oid));
  if (mergeOids.size > 1) blockers.push('merge_checkout_source_inconsistent');
  if (mergeOids.size !== 1) blockers.push('governed_merge_oid_missing_or_ambiguous');
  const uniqueBlockers = [...new Set(blockers)];
  return { ok: uniqueBlockers.length === 0, blockers: uniqueBlockers, checkouts, governedMergeOid: mergeOids.size === 1 ? [...mergeOids][0] : null, jobCount: jobs.length, checkCount: checks.length };
}

function privateOwnerRoot() {
  const pointerStat = fs.statSync(PRIVATE_OWNER_POINTER);
  if ((pointerStat.mode & 0o777) !== 0o600 || pointerStat.uid !== process.getuid()) throw new Error('private_owner_pointer_permissions_invalid');
  const root = fs.readFileSync(PRIVATE_OWNER_POINTER, 'utf8').trim();
  if (!root || !path.isAbsolute(root)) throw new Error('private_owner_root_missing');
  const rootStat = fs.statSync(root);
  if ((rootStat.mode & 0o777) !== 0o700 || rootStat.uid !== process.getuid()) throw new Error('private_owner_root_permissions_invalid');
  return root;
}

function loadCandidateBinding(ownerRoot) {
  const present = PRIVATE_BINDING_NAMES.filter((name) => fs.existsSync(path.join(ownerRoot, name)));
  if (present.length !== 1) throw new Error('candidate_binding_selection_ambiguous_or_missing');
  const bindingPath = path.join(ownerRoot, present[0]);
  const bindingStat = fs.statSync(bindingPath);
  if ((bindingStat.mode & 0o777) !== 0o600 || bindingStat.uid !== process.getuid()) throw new Error('candidate_binding_permissions_invalid');
  const binding = JSON.parse(fs.readFileSync(bindingPath, 'utf8'));
  if (binding.phase !== 178 || binding.plan !== '01') throw new Error('candidate_binding_wrong_plan');
  return { name: present[0], binding };
}

function sha256(value) {
  return createHash('sha256').update(value).digest('hex');
}

export function runPrivate(label, command, args, options = {}) {
  const ownerRoot = options.ownerRoot ?? privateOwnerRoot();
  const captureRoot = options.captureRoot ?? path.join(ownerRoot, 'ci-adapter-fixture', 'production-processes');
  fs.mkdirSync(captureRoot, { recursive: true, mode: 0o700 });
  fs.chmodSync(captureRoot, 0o700);
  const result = spawnSync(command, args, { encoding: 'utf8', cwd: options.cwd, env: { ...process.env, ...options.env, GIT_OPTIONAL_LOCKS: '0' }, maxBuffer: 16 * 1024 * 1024, timeout: options.timeoutMs ?? 30_000, killSignal: 'SIGTERM' });
  const stem = path.join(captureRoot, label.replace(/[^A-Za-z0-9._-]/g, '_'));
  const stdout = result.stdout ?? '';
  const stderr = result.stderr ?? '';
  const processStatus = result.status ?? 1;
  for (const [suffix, value] of [['stdout', stdout], ['stderr', stderr], ['status', String(processStatus)]]) fs.writeFileSync(`${stem}.${suffix}`, value, { mode: 0o600 });
  for (const suffix of ['stdout', 'stderr', 'status']) fs.chmodSync(`${stem}.${suffix}`, 0o600);
  const capture = { stdout: `${stem}.stdout`, stderr: `${stem}.stderr`, status: `${stem}.status`, stdoutBytes: Buffer.byteLength(stdout), stderrBytes: Buffer.byteLength(stderr), stdoutSha256: sha256(stdout), stderrSha256: sha256(stderr), statusSha256: sha256(String(processStatus)) };
  if (result.error) return { ok: false, cause: result.error.code === 'ETIMEDOUT' ? 'subprocess_timeout' : 'subprocess_unavailable', status: processStatus, stdout, stderr, capture };
  return { ok: processStatus === 0, status: processStatus, stdout, stderr, capture };
}

export function invocationCaptureRoot(ownerRoot, purpose) {
  const root = path.join(ownerRoot, 'ci-adapter-fixture', `${purpose}-${Date.now()}-${randomUUID()}`);
  fs.mkdirSync(root, { recursive: true, mode: 0o700 });
  fs.chmodSync(root, 0o700);
  return root;
}

export function verifyCapture(capture, expectedStatus, expectedStdout, expectedStderr) {
  if (!capture) throw new Error('capture_pointer_missing');
  for (const field of ['stdout', 'stderr', 'status']) {
    const stat = fs.statSync(capture[field]);
    if ((stat.mode & 0o777) !== 0o600 || stat.size > 16 * 1024 * 1024) throw new Error('capture_permissions_or_size_invalid');
  }
  const stdout = fs.readFileSync(capture.stdout, 'utf8');
  const stderr = fs.readFileSync(capture.stderr, 'utf8');
  const status = fs.readFileSync(capture.status, 'utf8');
  if (status !== String(expectedStatus) || stdout !== expectedStdout || stderr !== expectedStderr || sha256(stdout) !== capture.stdoutSha256 || sha256(stderr) !== capture.stderrSha256 || sha256(status) !== capture.statusSha256) throw new Error('capture_integrity_mismatch');
  return { status: Number(status), stdoutBytes: Buffer.byteLength(stdout), stderrBytes: Buffer.byteLength(stderr), stdoutSha256: sha256(stdout), stderrSha256: sha256(stderr), statusSha256: sha256(status) };
}

function atomicPrivateJson(filePath, value) {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  fs.chmodSync(dir, 0o700);
  const temp = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  fs.writeFileSync(temp, `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600, flag: 'wx' });
  fs.chmodSync(temp, 0o600);
  fs.renameSync(temp, filePath);
  fs.chmodSync(filePath, 0o600);
}

export function retainPrivateFile(filePath, ownerRoot, stem) {
  if (!fs.existsSync(filePath)) return null;
  const bytes = fs.readFileSync(filePath);
  const retained = path.join(ownerRoot, `${stem}-${sha256(bytes)}.json`);
  if (!fs.existsSync(retained)) {
    fs.writeFileSync(retained, bytes, { mode: 0o600, flag: 'wx' });
    fs.chmodSync(retained, 0o600);
  } else if (!fs.readFileSync(retained).equals(bytes)) throw new Error('private_binding_archive_collision');
  return retained;
}

function atomicPublicJson(filePath, value) {
  const temp = `${filePath}.${process.pid}.tmp`;
  fs.writeFileSync(temp, `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600, flag: 'w' });
  fs.renameSync(temp, filePath);
}

function verifyCaptureRecord(capture) {
  if (!capture || typeof capture.stdout !== 'string' || typeof capture.stderr !== 'string' || typeof capture.status !== 'string') throw new Error('capture_pointer_malformed');
  const contents = {};
  for (const field of ['stdout', 'stderr', 'status']) {
    const stat = fs.statSync(capture[field]);
    if ((stat.mode & 0o777) !== 0o600 || stat.size > 16 * 1024 * 1024) throw new Error('capture_permissions_or_size_invalid');
    contents[field] = fs.readFileSync(capture[field], 'utf8');
  }
  if (contents.status !== '0') throw new Error('capture_process_not_successful');
  if (Buffer.byteLength(contents.stdout) !== capture.stdoutBytes || Buffer.byteLength(contents.stderr) !== capture.stderrBytes || sha256(contents.stdout) !== capture.stdoutSha256 || sha256(contents.stderr) !== capture.stderrSha256 || sha256(contents.status) !== capture.statusSha256) throw new Error('capture_integrity_mismatch');
  return { status: 0, stdoutBytes: capture.stdoutBytes, stderrBytes: capture.stderrBytes, stdoutSha256: capture.stdoutSha256, stderrSha256: capture.stderrSha256, statusSha256: capture.statusSha256 };
}

function verifyCaptureTree(value) {
  if (!value || typeof value !== 'object') return;
  if (typeof value.stdout === 'string' && typeof value.stderr === 'string' && typeof value.status === 'string') {
    verifyCaptureRecord(value);
    return;
  }
  for (const child of Object.values(value)) verifyCaptureTree(child);
}

export function persistCollectionArtifacts({ ownerRoot, evidenceRoot, runId, attempt, proof, privateBinding }) {
  if (!Number.isSafeInteger(runId) || !Number.isSafeInteger(attempt) || attempt < 1 || proof?.status !== 'candidate-run-observed' || proof?.run?.id !== runId || proof?.run?.attempt !== attempt || !validRunUrl(proof?.run?.url, runId) || proof?.workflow?.source?.version !== proof?.candidate?.commit || !/^[0-9a-f]{40}$/i.test(proof?.workflow?.source?.blobOid ?? '') || !/^[0-9a-f]{40}$/i.test(proof?.governedMergeOid ?? '') || privateBinding?.runId !== runId || privateBinding?.attempt !== attempt || privateBinding?.accepted !== true || proof?.candidate?.commit !== privateBinding?.candidateCommit || proof?.candidate?.tree !== privateBinding?.candidateTree) throw new Error('collection_artifact_identity_mismatch');
  verifyCaptureTree(privateBinding.rawCapturePointers);
  const publicText = `${JSON.stringify(proof, null, 2)}\n`;
  if (/\/private\/|\/Users\/|ghp_[A-Za-z0-9]|Authorization:/i.test(publicText)) throw new Error('public_proof_private_data_detected');
  atomicPrivateJson(path.join(ownerRoot, `ci-run-binding-${runId}-${attempt}.json`), privateBinding);
  atomicPublicJson(path.join(evidenceRoot, 'hosted-ci-proof.json'), proof);
  return { publicArtifact: 'hosted-ci-proof.json', privateBinding: `ci-run-binding-${runId}-${attempt}.json` };
}

function requiredCommand(command, args, options = {}) {
  const result = runPrivate(options.label ?? path.basename(command), command, args, options);
  if (!result.ok) throw new Error(options.failureCause ?? 'required_source_check_failed');
  return result.stdout;
}

function validatePrivateRoot(root) {
  if (!path.isAbsolute(root)) throw new Error('private_owner_root_missing');
  const stat = fs.statSync(root);
  if ((stat.mode & 0o777) !== 0o700 || stat.uid !== process.getuid()) throw new Error('private_owner_root_permissions_invalid');
  return root;
}

function candidateContext({ ownerRoot = privateOwnerRoot(), captureRoot } = {}) {
  validatePrivateRoot(ownerRoot);
  const selected = loadCandidateBinding(ownerRoot);
  const { binding } = selected;
  const source = JSON.parse(fs.readFileSync(path.join(EVIDENCE_DIR, 'candidate-source.json'), 'utf8'));
  const deliveryRoot = binding.deliveryRoot;
  if (!path.isAbsolute(deliveryRoot) || !fs.existsSync(path.join(deliveryRoot, '.git'))) throw new Error('candidate_delivery_root_unavailable');
  const commit = requiredCommand('git', ['-C', deliveryRoot, 'rev-parse', 'HEAD'], { label: 'candidate-head', cwd: PHASE_DIR, captureRoot }).trim();
  const tree = requiredCommand('git', ['-C', deliveryRoot, 'rev-parse', 'HEAD^{tree}'], { label: 'candidate-tree', cwd: PHASE_DIR, captureRoot }).trim();
  if (!exactCommitMatch(binding.candidateCommit, commit) || !exactCommitMatch(source.candidateCommit, commit) || tree !== binding.candidateTree || tree !== source.candidateTree) throw new Error('candidate_identity_mismatch');
  if (!Array.isArray(binding.selectedPaths) || binding.selectedPaths.length !== 8 || binding.selectedPaths.length !== source.selectedCount) throw new Error('candidate_path_count_mismatch');
  const privatePaths = [...binding.selectedPaths].sort();
  const publicPaths = [...(source.selectedPaths ?? [])].sort();
  if (JSON.stringify(privatePaths) !== JSON.stringify(publicPaths)) throw new Error('candidate_path_set_mismatch');
  if (!exactCommitMatch(binding.sourceBaseCommit, source.sourceBaseCommit) || binding.sourceBaseTree !== source.sourceBaseTree) throw new Error('candidate_base_binding_mismatch');
  const status = requiredCommand('git', ['-C', deliveryRoot, 'status', '--porcelain=v1', '-z', '--untracked-files=all'], { label: 'candidate-status', captureRoot });
  if (status.length !== 0) throw new Error('candidate_delivery_not_clean');
  return { ownerRoot, bindingFile: selected.name, binding, source, deliveryRoot, commit, tree };
}

function parseWorkflowWithPython(deliveryRoot, captureRoot) {
  const snippet = [
    'import json, pathlib, sys, yaml',
    'p = pathlib.Path(sys.argv[1])',
    'd = yaml.safe_load(p.read_text(encoding="utf-8"))',
    'jobs = d.get("jobs")',
    'assert isinstance(jobs, dict)',
    'checkout = {}',
    'checkout_pins = {}',
    'for job_id, job in jobs.items():',
    '    refs = []',
    '    job_pins = []',
    '    for step in job.get("steps", []):',
    '        if isinstance(step, dict) and str(step.get("uses", "")).startswith("actions/checkout@"):',
    '            refs.append(step.get("with", {}).get("ref") if isinstance(step.get("with", {}), dict) else None)',
    '            match = __import__("re").fullmatch(r"actions/checkout@([0-9a-f]{40})", str(step.get("uses", "")))',
    '            if match: job_pins.append(match.group(1))',
    '    checkout[job_id] = refs',
    '    checkout_pins[job_id] = sorted(set(job_pins))',
    'pins = sorted(set(__import__("re").findall(r"actions/checkout@([0-9a-f]{40})", p.read_text(encoding="utf-8"))))',
    'print(json.dumps({"name": d.get("name"), "jobs": list(jobs), "jobNames": {k: (v.get("name") or k) for k,v in jobs.items()}, "needs": {k: v.get("needs", []) for k,v in jobs.items()}, "jobConditions": {k: v.get("if") for k,v in jobs.items()}, "checkoutRefs": checkout, "checkoutPinsByJob": checkout_pins, "checkoutPins": pins}))',
  ].join('\n');
  const output = requiredCommand('python3', ['-c', snippet, path.join(deliveryRoot, WORKFLOW_PATH)], { label: 'workflow-shape', captureRoot });
  return JSON.parse(output);
}

function isFixedGetRoute(route) {
  const prefix = `repos/${REPO}/`;
  if (typeof route !== 'string' || !route.startsWith(prefix)) return false;
  const tail = route.slice(prefix.length);
  return [
    /^branches\/main\/protection\/required_status_checks$/,
    /^rules\/branches\/main\?per_page=100$/,
    /^actions\/workflows\/crosswake-ci\.yml$/,
    /^commits\/main$/,
    /^actions\/runs\/\d+$/,
    /^pulls\/\d+$/,
    /^actions\/runs\/\d+\/attempts\/\d+\/jobs\?per_page=100$/,
    /^check-suites\/\d+\/check-runs\?per_page=100$/,
    /^actions\/jobs\/\d+\/logs$/,
  ].some((pattern) => pattern.test(tail));
}

export function runGh(label, route, paginate = false, options = {}) {
  if (!isFixedGetRoute(route)) return { ok: false, cause: 'github_route_not_allowlisted' };
  const safeLabel = label.replace(/[^A-Za-z0-9]/g, '_');
  const args = ['api'];
  if (paginate) args.push('--paginate', '--slurp');
  if (route.endsWith('/logs')) args.push('--allow-escape-sequences');
  args.push(route);
  const result = runPrivate(label, options.command ?? 'gh', args, options);
  if (!result.ok) {
    const statusCode = result.stderr.match(/\b(401|403|404|422|429)\b/)?.[1];
    return { ok: false, cause: result.cause === 'subprocess_timeout' ? `${safeLabel}_timeout` : statusCode ? `${safeLabel}_github_http_${statusCode}` : `${safeLabel}_read_failed`, capture: result.capture };
  }
  const integrity = verifyCapture(result.capture, 0, result.stdout, result.stderr);
  try { return { ok: true, value: JSON.parse(result.stdout), capture: result.capture, integrity }; }
  catch { return { ok: true, value: result.stdout, capture: result.capture, integrity }; }
}

function safePolicyProjection(policy) {
  return {
    strict: policy.strict,
    rulesetEvidence: policy.rulesetEvidence,
    effectiveRuleCount: policy.effectiveRuleCount,
    required: policy.required.map(({ context, appId, sources }) => ({ context, appId, sources })),
  };
}

export function parseClassifierOutput(outputText, manifest) {
  if (typeof outputText !== 'string') return { ok: false, cause: 'classifier_output_missing' };
  const values = new Map();
  for (const line of outputText.replace(/\u001b\[[0-9;]*m/g, '').split(/\r?\n/)) {
    const index = line.indexOf('=');
    if (index < 1) continue;
    const key = line.slice(0, index).trim();
    if (['classification', 'irrelevant_leaves', 'scheduled_families', 'release_candidate_scope'].includes(key)) values.set(key, line.slice(index + 1).trim().replace(/['"`]+$/, ''));
  }
  for (const key of ['classification', 'irrelevant_leaves', 'scheduled_families']) if (!values.has(key)) return { ok: false, cause: 'classifier_output_incomplete' };
  let irrelevant;
  let scheduled;
  try {
    irrelevant = JSON.parse(values.get('irrelevant_leaves'));
    scheduled = JSON.parse(values.get('scheduled_families'));
  }
  catch { return { ok: false, cause: 'classifier_irrelevant_leaves_malformed' }; }
  if (!Array.isArray(irrelevant) || irrelevant.some((id) => typeof id !== 'string') || new Set(irrelevant).size !== irrelevant.length || !Array.isArray(scheduled) || scheduled.some((id) => typeof id !== 'string') || new Set(scheduled).size !== scheduled.length) return { ok: false, cause: 'classifier_irrelevant_leaves_malformed' };
  const leaves = new Map((manifest?.proof_leaves ?? []).map((row) => [row.leaf_id, row]));
  if (irrelevant.some((id) => !leaves.get(id)?.irrelevance_reason)) return { ok: false, cause: 'classifier_skip_not_authorized_by_manifest' };
  const classification = values.get('classification');
  if (classification !== 'full_proof' && irrelevant.length === 0) return { ok: false, cause: 'classifier_skip_conditions_incomplete' };
  if (classification === 'full_proof' && irrelevant.length !== 0) return { ok: false, cause: 'classifier_full_proof_has_irrelevant_leaves' };
  return { ok: true, classification, authorizedSkipIds: irrelevant, scheduledFamilies: scheduled, releaseCandidateScope: values.get('release_candidate_scope') ?? null };
}

export function evaluateWorkflowCondition(expression, classifier, controlSucceeded = true) {
  if (expression === null || expression === undefined || expression === '') return { ok: true, shouldRun: true };
  const clean = String(expression).trim().replace(/^\$\{\{\s*/, '').replace(/\s*\}\}$/, '');
  const parts = clean.split(/\s+\|\|\s+/);
  let sawSupported = false;
  let unknown = false;
  for (const part of parts) {
    let match;
    if ((match = part.match(/^needs\.classify-change\.result\s*==\s*['"]success['"]$/))) {
      sawSupported = true;
      if (controlSucceeded) return { ok: true, shouldRun: true };
    } else if ((match = part.match(/^needs\.classify-change\.outputs\.(classification|release_candidate_scope)\s*==\s*['"]([^'"]+)['"]$/))) {
      sawSupported = true;
      const value = match[1] === 'classification' ? classifier.classification : classifier.releaseCandidateScope;
      if (value === null || value === undefined) { unknown = true; continue; }
      if (value === match[2]) return { ok: true, shouldRun: true };
    } else if ((match = part.match(/^contains\(fromJSON\(needs\.classify-change\.outputs\.scheduled_families\),\s*['"]([^'"]+)['"]\)$/))) {
      sawSupported = true;
      if (classifier.scheduledFamilies.includes(match[1])) return { ok: true, shouldRun: true };
    } else if (part === 'always()') {
      sawSupported = true;
      return { ok: true, shouldRun: true };
    } else return { ok: false, cause: 'workflow_condition_unrecognized' };
  }
  if (!sawSupported) return { ok: false, cause: 'workflow_condition_unrecognized' };
  return { ok: true, shouldRun: unknown ? null : false };
}

export function deriveSkipContract(manifest, workflowConditions, classifier) {
  const authorized = [];
  const shouldRun = {};
  const pendingLeafIds = [];
  for (const leaf of manifest?.proof_leaves ?? []) {
    const expression = workflowConditions?.[leaf.display_name];
    const evaluated = evaluateWorkflowCondition(expression, classifier);
    if (!evaluated.ok) return { ok: false, cause: evaluated.cause };
    shouldRun[leaf.leaf_id] = evaluated.shouldRun;
    const classifierMarksIrrelevant = classifier.authorizedSkipIds.includes(leaf.leaf_id);
    if (evaluated.shouldRun === null) {
      if (classifierMarksIrrelevant) return { ok: false, cause: 'classifier_skip_condition_unobserved' };
      pendingLeafIds.push(leaf.leaf_id);
      continue;
    }
    if (!evaluated.shouldRun) {
      if (!leaf.irrelevance_reason || !classifierMarksIrrelevant) return { ok: false, cause: 'classifier_skip_not_authorized_by_workflow_and_manifest' };
      authorized.push(leaf.leaf_id);
    } else if (classifierMarksIrrelevant) return { ok: false, cause: 'classifier_skip_workflow_condition_conflict' };
  }
  for (const id of classifier.authorizedSkipIds) if (!shouldRun.hasOwnProperty(id)) return { ok: false, cause: 'classifier_skip_leaf_unknown' };
  return { ok: true, authorizedSkipIds: authorized, shouldRun, pendingLeafIds };
}

function baseContract(candidate, workflow, policy, classifier) {
  const manifest = JSON.parse(fs.readFileSync(path.join(candidate.deliveryRoot, 'script/ci_leaf_manifest.json'), 'utf8'));
  const requiredNodes = manifest.required_control_nodes.map((row) => ({ id: row.node_id, displayName: row.display_name, requiredResult: row.required_result }));
  const umbrellaId = Object.keys(workflow.needs).find((id) => id === UMBRELLA_ID);
  if (!umbrellaId || workflow.jobNames[umbrellaId] !== 'Crosswake CI') throw new Error('merge_blocking_umbrella_missing');
  if (manifest.proof_leaves.length !== 46 || requiredNodes.length !== 1 || requiredNodes[0].id !== 'classify-change') throw new Error('selected_graph_cardinality_mismatch');
  const expectedNeeds = new Set([...manifest.proof_leaves.map((row) => row.leaf_id), ...requiredNodes.map((row) => row.id)]);
  const umbrellaNeeds = new Set(workflow.needs[umbrellaId] ?? []);
  if (expectedNeeds.size !== umbrellaNeeds.size || [...expectedNeeds].some((id) => !umbrellaNeeds.has(id))) throw new Error('selected_umbrella_needs_mismatch');
  const checkoutPolicyFor = (displayName) => {
    const jobId = Object.keys(workflow.jobNames).find((id) => workflow.jobNames[id] === displayName);
    if (!jobId) throw new Error('required_workflow_job_missing');
    const refs = workflow.checkoutRefs[jobId] ?? [];
    if (refs.length > 1) throw new Error('required_checkout_step_ambiguous');
    if (refs.length === 0) return { kind: 'none', jobId };
    const pins = workflow.checkoutPinsByJob[jobId] ?? [];
    if (pins.length !== 1) throw new Error('required_checkout_action_pin_ambiguous');
    const headRef = refs[0] === '${{ github.event.pull_request.head.sha }}';
    return { kind: headRef ? 'head' : 'merge', explicitRef: headRef ? 'pull_request_head_sha' : null, actionPin: pins[0], jobId };
  };
  const requiredCheckoutPolicies = Object.fromEntries([
    ...manifest.proof_leaves.map((row) => row.display_name),
    ...manifest.required_control_nodes.map((row) => row.display_name),
  ].map((name) => [name, checkoutPolicyFor(name)]));
  const umbrellaPolicy = checkoutPolicyFor('Crosswake CI');
  if (umbrellaPolicy.kind !== 'none') throw new Error('umbrella_expected_source_less');
  return {
    schemaVersion: 1,
    status: 'policy-observed-source-contract-ready-for-run',
    repository: REPO,
    workflow: { path: WORKFLOW_PATH, id: null, name: workflow.name, pinnedCheckoutActions: workflow.checkoutPins },
    candidate: { baseCommit: candidate.binding.sourceBaseCommit, commit: candidate.commit, tree: candidate.tree, selectedPathCount: candidate.binding.selectedPaths.length },
    graph: {
      proofLeafCount: manifest.proof_leaves.length,
      proofLeaves: manifest.proof_leaves.map((row) => ({ id: row.leaf_id, displayName: row.display_name })),
      controlNodes: requiredNodes,
      umbrella: { id: umbrellaId, displayName: workflow.jobNames[umbrellaId], needs: workflow.needs[umbrellaId] },
      advisoryJobs: Object.keys(workflow.jobNames).filter((id) => !manifest.proof_leaves.some((row) => row.display_name === workflow.jobNames[id]) && !requiredNodes.some((row) => row.displayName === workflow.jobNames[id]) && id !== umbrellaId),
      checkoutPolicies: Object.fromEntries(manifest.proof_leaves.map((row) => {
        return [row.display_name, requiredCheckoutPolicies[row.display_name]];
      })),
      requiredCheckoutPolicies,
      sourceLessJobs: ['Crosswake CI'],
    },
    classification: classifier,
    policy: { targetBase: 'main', observedAt: null, branchProtection: null, effectiveRules: null, combinedRequiredChecks: [] },
    hostedWorkflowCredentialAccess: { state: 'unproven-until-hosted-run', localPolicyReadIsNotProof: true },
    nextGate: 'hosted candidate run and exact per-job checkout evidence remain unobserved',
  };
}

function livePolicy(captureRoot, command, env) {
  const branch = runGh('branch-protection', `repos/${REPO}/branches/main/protection/required_status_checks`, true, { captureRoot, command, env });
  if (!branch.ok) throw new Error(branch.cause);
  const rules = runGh('effective-rules', `repos/${REPO}/rules/branches/main?per_page=100`, true, { captureRoot, command, env });
  if (!rules.ok) throw new Error(rules.cause);
  const policy = normalizePolicy(branch.value, rules.value);
  if (!policy.ok) throw new Error(policy.blockers.join(','));
  return { policy, branch, rules };
}

function contractMode() {
  const ownerRoot = privateOwnerRoot();
  const captureRoot = invocationCaptureRoot(ownerRoot, 'contract');
  const candidate = candidateContext({ ownerRoot, captureRoot });
  const readGh = (label, route, paginate = false) => runGh(label, route, paginate, { captureRoot });
  const workflow = parseWorkflowWithPython(candidate.deliveryRoot, captureRoot);
  const manifestCheck = runPrivate('manifest-self-test', 'python3', ['script/check_ci_leaf_manifest.py', '--self-test'], { cwd: candidate.deliveryRoot, ownerRoot: candidate.ownerRoot, captureRoot });
  if (!manifestCheck.ok) throw new Error('selected_manifest_self_test_failed');
  const classifierPath = path.join(candidate.deliveryRoot, 'script/classify_ci_change.py');
  const classifierOut = path.join(captureRoot, 'classifier-output.txt');
  fs.writeFileSync(classifierOut, '', { mode: 0o600 });
  fs.chmodSync(classifierOut, 0o600);
  const classify = runPrivate('selected-classifier', 'python3', [classifierPath, '--repo', candidate.deliveryRoot, '--base', candidate.binding.sourceBaseCommit, '--merge', candidate.commit, '--github-output', classifierOut], { cwd: candidate.deliveryRoot, ownerRoot: candidate.ownerRoot, captureRoot });
  if (!classify.ok) throw new Error('selected_source_classifier_failed');
  const classifierText = fs.readFileSync(classifierOut, 'utf8');
  const classifier = {};
  for (const line of classifierText.split(/\r?\n/)) {
    const index = line.indexOf('=');
    if (index < 0) continue;
    const key = line.slice(0, index);
    if (['schema_version', 'classification', 'reason', 'scheduled_families', 'irrelevant_leaves', 'release_candidate_scope', 'release_candidate_reason'].includes(key)) classifier[key] = line.slice(index + 1);
  }
  const manifest = JSON.parse(fs.readFileSync(path.join(candidate.deliveryRoot, 'script/ci_leaf_manifest.json'), 'utf8'));
  const classifierState = parseClassifierOutput(classifierText, manifest);
  if (!classifierState.ok) throw new Error(classifierState.cause);
  if (classifier.classification !== 'full_proof') throw new Error('candidate_classifier_not_full_proof');
  if (manifestCheck.stdout && !/manifest self-test: pass/i.test(manifestCheck.stdout)) throw new Error('selected_manifest_self_test_not_confirmed');
  if (workflow.checkoutPins.length === 0 || workflow.name !== 'Crosswake CI' || workflow.jobs.length < 48 || workflow.jobNames[UMBRELLA_ID] !== 'Crosswake CI') throw new Error('selected_workflow_graph_incomplete');

  const currentMain = readGh('current-main', `repos/${REPO}/commits/main`, true);
  if (!currentMain.ok) throw new Error(currentMain.cause);
  const mainResult = singleResponse(currentMain.value);
  if (!mainResult.ok || !exactCommitMatch(mainResult.value.sha, candidate.binding.sourceBaseCommit)) throw new Error('canonical_base_moved_since_candidate');

  const remoteWorkflow = readGh('workflow-identity', `repos/${REPO}/actions/workflows/crosswake-ci.yml`, true);
  if (!remoteWorkflow.ok) throw new Error(remoteWorkflow.cause);
  const workflowResult = singleResponse(remoteWorkflow.value);
  if (!workflowResult.ok || workflowResult.value.path !== WORKFLOW_PATH || workflowResult.value.state !== 'active') throw new Error('canonical_workflow_identity_unavailable');

  const workflowBlob = runPrivate('candidate-workflow-blob', 'git', ['-C', candidate.deliveryRoot, 'rev-parse', `${candidate.commit}:${WORKFLOW_PATH}`], { ownerRoot: candidate.ownerRoot, captureRoot });
  if (!workflowBlob.ok || !/^[0-9a-f]{40}$/i.test(workflowBlob.stdout.trim())) throw new Error('candidate_workflow_blob_unavailable');
  const { policy, branch, rules } = livePolicy(captureRoot);
  const contract = baseContract(candidate, workflow, policy, classifier);
  const skipConditions = Object.fromEntries(manifest.proof_leaves.map((row) => [row.leaf_id, workflow.jobConditions[contract.graph.requiredCheckoutPolicies[row.display_name].jobId] ?? null]));
  const skipContract = deriveSkipContract(manifest, skipConditions, classifierState);
  if (!skipContract.ok) throw new Error(skipContract.cause);
  contract.graph.skipPolicy = { authorizedSkipIds: skipContract.authorizedSkipIds, pendingLeafIds: skipContract.pendingLeafIds, conditionBound: true };
  contract.workflow.id = workflowResult.value.id;
  contract.workflow.source = { version: candidate.commit, blobOid: workflowBlob.stdout.trim() };
  contract.selectedSourceChecks = { manifestSelfTest: 'pass', classifier: 'pass', exactCandidateBaseStillCurrent: true };
  contract.policy.observedAt = new Date().toISOString();
  contract.policy.branchProtection = {
    state: 'read-success',
    strict: policy.strict,
    requiredContexts: (policy.required.filter((row) => row.sources.includes('branch_protection'))).map(({ context, appId }) => ({ context, appId })),
    rawResponseCaptured: true,
  };
  contract.policy.effectiveRules = {
    state: policy.rulesetEvidence,
    ruleCount: policy.effectiveRuleCount,
    requiredContexts: policy.required.filter((row) => row.sources.includes('effective_rules')).map(({ context, appId }) => ({ context, appId })),
    rawResponseCaptured: true,
  };
  contract.policy.combinedRequiredChecks = policy.required.map(({ context, appId, sources }) => ({ context, appId, sources }));
  contract.nextGate = 'observe one current PR run, complete attempt jobs/check pages, and actual per-job checkout OIDs';

  const privateBinding = {
    schemaVersion: 1,
    phase: 178,
    plan: '03',
    candidateBindingFile: candidate.bindingFile,
    candidateCommit: candidate.commit,
    candidateTree: candidate.tree,
    sourceBaseCommit: candidate.binding.sourceBaseCommit,
    sourceBaseTree: candidate.binding.sourceBaseTree,
    selectedPaths: candidate.binding.selectedPaths,
    workflow: { repository: REPO, path: WORKFLOW_PATH, id: workflowResult.value.id, checkoutActionPins: workflow.checkoutPins },
    workflowSource: { version: candidate.commit, blobOid: workflowBlob.stdout.trim() },
    classifierState: { classification: classifierState.classification, authorizedSkipIds: classifierState.authorizedSkipIds, scheduledFamilies: classifierState.scheduledFamilies, releaseCandidateScope: classifierState.releaseCandidateScope },
    skipConditions,
    policy: { targetBase: 'main', observedAt: contract.policy.observedAt, normalized: safePolicyProjection(policy) },
    rawResponsePointers: {
      branchProtection: branch.capture,
      effectiveRules: rules.capture,
      workflowIdentity: remoteWorkflow.capture,
      currentMain: currentMain.capture,
      workflowBlob: workflowBlob.capture,
    },
    rawResponseIntegrity: {
      branchProtection: branch.integrity,
      effectiveRules: rules.integrity,
      workflowIdentity: remoteWorkflow.integrity,
      currentMain: currentMain.integrity,
      workflowBlob: verifyCapture(workflowBlob.capture, 0, workflowBlob.stdout, workflowBlob.stderr),
      verifiedAgainstNormalizedValues: true,
    },
    historicalFixture: { runId: 38152560619, attempt: 1, purpose: 'adapter-shape-only', candidateAcceptance: false },
  };
  const policyBindingPath = path.join(candidate.ownerRoot, 'ci-policy-binding.json');
  retainPrivateFile(policyBindingPath, candidate.ownerRoot, 'ci-policy-binding-history');
  atomicPublicJson(path.join(EVIDENCE_DIR, 'ci-contract.json'), contract);
  atomicPrivateJson(policyBindingPath, privateBinding);
  return contract;
}

export function collectMode(runId, attempt, options = {}) {
  if (!Number.isSafeInteger(runId) || !Number.isSafeInteger(attempt) || attempt < 1) throw new Error('run_id_and_attempt_required');
  const ownerRoot = validatePrivateRoot(options.ownerRoot ?? privateOwnerRoot());
  const captureRoot = invocationCaptureRoot(ownerRoot, `collect-${runId}-${attempt}`);
  const evidenceRoot = options.evidenceRoot ?? EVIDENCE_DIR;
  const command = options.ghCommand;
  const env = options.env;
  const candidate = candidateContext({ ownerRoot, captureRoot });
  const readGh = (label, route, paginate = false) => runGh(label, route, paginate, { captureRoot, command, env });
  const policyBindingPath = path.join(candidate.ownerRoot, 'ci-policy-binding.json');
  const prior = JSON.parse(fs.readFileSync(policyBindingPath, 'utf8'));
  if (prior.candidateCommit !== candidate.commit || prior.candidateTree !== candidate.tree) throw new Error('policy_binding_candidate_mismatch');
  const runResponse = readGh('collect-run', `repos/${REPO}/actions/runs/${runId}`, true);
  if (!runResponse.ok) throw new Error(runResponse.cause);
  const runResult = singleResponse(runResponse.value);
  if (!runResult.ok) throw new Error('run_response_incomplete');
  const run = runResult.value;
  if (run.run_attempt !== attempt || run.workflow_id !== prior.workflow.id || !run.check_suite_id) throw new Error('run_attempt_or_workflow_mismatch');
  if (run.event !== 'pull_request' || !Array.isArray(run.pull_requests) || run.pull_requests.length !== 1) throw new Error('run_pull_request_identity_unavailable');
  const runPull = run.pull_requests[0];
  if (!Number.isSafeInteger(runPull.number) || !exactCommitMatch(run.head_sha, candidate.commit) || !exactCommitMatch(runPull.head?.sha, candidate.commit)) throw new Error('run_candidate_head_mismatch');
  if (runPull.base?.ref !== 'main' || !exactCommitMatch(runPull.base?.sha, candidate.binding.sourceBaseCommit)) throw new Error('run_candidate_base_mismatch');
  const currentPrResponse = readGh('collect-current-pr-initial', `repos/${REPO}/pulls/${runPull.number}`, true);
  if (!currentPrResponse.ok) throw new Error(currentPrResponse.cause);
  const currentPrResult = singleResponse(currentPrResponse.value);
  if (!currentPrResult.ok) throw new Error('current_pr_response_incomplete');
  const currentPr = currentPrResult.value;
  if (currentPr.state !== 'open' || !exactCommitMatch(currentPr.head?.sha, candidate.commit) || currentPr.base?.ref !== 'main' || !exactCommitMatch(currentPr.base?.sha, candidate.binding.sourceBaseCommit)) throw new Error('current_pr_candidate_or_base_drift');
  const currentMainResponse = readGh('collect-current-main-initial', `repos/${REPO}/commits/main`, true);
  if (!currentMainResponse.ok) throw new Error(currentMainResponse.cause);
  const currentMainResult = singleResponse(currentMainResponse.value);
  if (!currentMainResult.ok || !exactCommitMatch(currentMainResult.value.sha, candidate.binding.sourceBaseCommit)) throw new Error('canonical_base_moved_since_candidate');
  const jobsResponse = readGh('collect-jobs', `repos/${REPO}/actions/runs/${runId}/attempts/${attempt}/jobs?per_page=100`, true);
  if (!jobsResponse.ok) throw new Error(jobsResponse.cause);
  const suiteResponse = readGh('collect-check-runs', `repos/${REPO}/check-suites/${run.check_suite_id}/check-runs?per_page=100`, true);
  if (!suiteResponse.ok) throw new Error(suiteResponse.cause);
  const jobsParsed = parsePageEnvelope(jobsResponse.value, 'jobs');
  const checksParsed = parsePageEnvelope(suiteResponse.value, 'check_runs');
  if (!jobsParsed.ok) throw new Error(jobsParsed.cause);
  if (!checksParsed.ok) throw new Error(checksParsed.cause);
  if (jobsParsed.records.some((job) => job.run_id !== runId || job.run_attempt !== attempt)) throw new Error('job_page_wrong_attempt');
  const checkoutLogs = {};
  const logCaptures = {};
  const logIntegrity = {};
  const contract = JSON.parse(fs.readFileSync(path.join(EVIDENCE_DIR, 'ci-contract.json'), 'utf8'));
  if (contract.candidate.commit !== candidate.commit || contract.candidate.tree !== candidate.tree || contract.workflow?.source?.version !== candidate.commit || !/^[0-9a-f]{40}$/i.test(contract.workflow?.source?.blobOid ?? '') || prior.workflowSource?.version !== candidate.commit || prior.workflowSource?.blobOid !== contract.workflow.source.blobOid) throw new Error('public_contract_candidate_mismatch');
  const manifest = JSON.parse(fs.readFileSync(path.join(candidate.deliveryRoot, 'script/ci_leaf_manifest.json'), 'utf8'));
  const requiredCheckoutRows = [...manifest.proof_leaves, ...manifest.required_control_nodes];
  const requiredNames = new Set(requiredCheckoutRows.map((row) => row.display_name));
  for (const job of jobsParsed.records.filter((row) => requiredNames.has(row.name))) {
    if (job.status === 'completed' && job.conclusion === 'skipped') continue;
    if (job.status !== 'completed' || job.conclusion !== 'success') continue;
    const logs = readGh(`collect-job-${job.id}-logs`, `repos/${REPO}/actions/jobs/${job.id}/logs`, false);
    if (!logs.ok) throw new Error(`job_${job.id}_${logs.cause}`);
    if (typeof logs.value !== 'string') throw new Error(`job_${job.id}_logs_malformed`);
    checkoutLogs[job.id] = logs.value;
    logCaptures[job.id] = logs.capture;
    logIntegrity[job.id] = logs.integrity;
  }
  const classifierRow = manifest.required_control_nodes.find((row) => row.node_id === 'classify-change');
  const classifierJob = jobsParsed.records.find((job) => job.name === classifierRow?.display_name);
  if (!classifierJob || !checkoutLogs[classifierJob.id]) throw new Error('classifier_control_log_missing');
  if (!prior.classifierState || prior.classifierState.classification !== contract.classification?.classification || !Array.isArray(prior.classifierState.authorizedSkipIds) || !Array.isArray(prior.classifierState.scheduledFamilies)) throw new Error('classifier_source_contract_missing');
  const classifierResult = { ok: true, ...prior.classifierState };
  const releaseCandidateJob = jobsParsed.records.find((job) => job.name === 'release-candidate-full-proof');
  if (!releaseCandidateJob || releaseCandidateJob.status !== 'completed' || releaseCandidateJob.conclusion !== 'success') throw new Error('release_candidate_scope_or_fullproof_unobserved');
  // The selected workflow runs this job only when its exact source-declared scope condition is full_matrix.
  classifierResult.releaseCandidateScope = 'full_matrix';
  const checkoutKinds = Object.fromEntries(Object.entries(contract.graph.requiredCheckoutPolicies ?? {}).map(([name, value]) => [name, value.kind]));
  const skipContract = deriveSkipContract(manifest, prior.skipConditions, classifierResult);
  if (!skipContract.ok) throw new Error(skipContract.cause);

  // Refresh mutable PR/run/base/policy state after page and log collection and just before acceptance.
  const finalRunResponse = readGh('collect-run-final', `repos/${REPO}/actions/runs/${runId}`, true);
  if (!finalRunResponse.ok) throw new Error(finalRunResponse.cause);
  const finalRunResult = singleResponse(finalRunResponse.value);
  if (!finalRunResult.ok) throw new Error('final_run_response_incomplete');
  const finalRun = finalRunResult.value;
  const finalPrResponse = readGh('collect-current-pr-final', `repos/${REPO}/pulls/${runPull.number}`, true);
  if (!finalPrResponse.ok) throw new Error(finalPrResponse.cause);
  const finalPrResult = singleResponse(finalPrResponse.value);
  if (!finalPrResult.ok) throw new Error('final_pr_response_incomplete');
  const finalPr = finalPrResult.value;
  const finalMainResponse = readGh('collect-current-main-final', `repos/${REPO}/commits/main`, true);
  if (!finalMainResponse.ok) throw new Error(finalMainResponse.cause);
  const finalMainResult = singleResponse(finalMainResponse.value);
  if (!finalMainResult.ok) throw new Error('final_main_response_incomplete');
  const fresh = validateFreshSnapshot({ runId, attempt, workflowId: prior.workflow.id, checkSuiteId: run.check_suite_id, pullNumber: runPull.number, candidateCommit: candidate.commit, baseCommit: candidate.binding.sourceBaseCommit, finalRun, finalPull: finalPr, finalMain: finalMainResult.value });
  if (!fresh.ok) throw new Error(fresh.cause);
  const { policy, branch, rules } = livePolicy(captureRoot, command, env);
  const result = validateRunGraph({
    run: finalRun,
    expectedAttempt: attempt,
    expectedWorkflowId: prior.workflow.id,
    expectedBaseRef: 'main',
    expectedCheckoutActions: Object.fromEntries(Object.entries(contract.graph.requiredCheckoutPolicies ?? {}).map(([name, value]) => [name, value.actionPin])),
    checkoutKinds,
    policy,
    manifest,
    jobsPages: jobsResponse.value,
    checkPages: suiteResponse.value,
    checkoutLogs,
    authorizedSkips: skipContract.authorizedSkipIds,
    expectedLeafRun: skipContract.shouldRun,
    sourceLessJobs: contract.graph.sourceLessJobs,
  });
  if (!result.ok) throw new Error(result.blockers.join(','));
  const observedAt = new Date().toISOString();
  const proof = {
    schemaVersion: 1,
    status: 'candidate-run-observed',
    observedAt,
    repository: REPO,
    workflow: { id: prior.workflow.id, path: WORKFLOW_PATH, source: prior.workflowSource },
    candidate: { commit: candidate.commit, tree: candidate.tree, baseCommit: candidate.binding.sourceBaseCommit },
    pullRequest: { number: runPull.number, state: finalPr.state, headCommit: finalPr.head.sha, baseRef: finalPr.base.ref, baseCommit: finalPr.base.sha },
    run: { id: runId, attempt, event: finalRun.event, url: finalRun.html_url, headCommit: finalRun.head_sha, checkSuiteId: finalRun.check_suite_id, jobCount: result.jobCount, checkCount: result.checkCount },
    governedMergeOid: result.governedMergeOid,
    policy: { observedAt, strict: policy.strict, rulesetEvidence: policy.rulesetEvidence, effectiveRuleCount: policy.effectiveRuleCount, requiredContexts: policy.required.map(({ context, appId, sources }) => ({ context, appId, sources })) },
    classifier: { result: classifierResult.classification, authorizedSkipCount: classifierResult.authorizedSkipIds.length },
    requiredJobs: [...manifest.proof_leaves.map((row) => row.display_name), ...manifest.required_control_nodes.map((row) => row.display_name), 'Crosswake CI'].map((name) => {
      const job = jobsParsed.records.find((row) => row.name === name);
      const check = job ? checksParsed.records.find((row) => row.url === job.check_run_url) : null;
      const checkout = result.checkouts[name] ?? null;
      return { name, jobId: job?.id ?? null, checkRunId: check?.id ?? null, conclusion: job?.conclusion ?? null, checkout };
    }),
  };
  const privateRunBinding = {
    schemaVersion: 1,
    phase: 178,
    plan: '03',
    candidateBindingFile: candidate.bindingFile,
    candidateCommit: candidate.commit,
    candidateTree: candidate.tree,
    workflowSource: prior.workflowSource,
    runId,
    attempt,
    checkSuiteId: finalRun.check_suite_id,
    observedAt,
    rawCapturePointers: {
      initialRun: runResponse.capture,
      initialPullRequest: currentPrResponse.capture,
      initialBase: currentMainResponse.capture,
      jobs: jobsResponse.capture,
      checks: suiteResponse.capture,
      finalRun: finalRunResponse.capture,
      finalPullRequest: finalPrResponse.capture,
      finalBase: finalMainResponse.capture,
      finalBranchProtection: branch.capture,
      finalEffectiveRules: rules.capture,
      jobLogs: logCaptures,
    },
    rawCaptureIntegrity: {
      initialRun: runResponse.integrity,
      initialPullRequest: currentPrResponse.integrity,
      initialBase: currentMainResponse.integrity,
      jobs: jobsResponse.integrity,
      checks: suiteResponse.integrity,
      finalRun: finalRunResponse.integrity,
      finalPullRequest: finalPrResponse.integrity,
      finalBase: finalMainResponse.integrity,
      finalBranchProtection: branch.integrity,
      finalEffectiveRules: rules.integrity,
      jobLogs: logIntegrity,
    },
    accepted: true,
  };
  persistCollectionArtifacts({ ownerRoot: candidate.ownerRoot, evidenceRoot, runId, attempt, proof, privateBinding: privateRunBinding });
  return { status: proof.status, runId, attempt, candidateCommit: candidate.commit, candidateTree: candidate.tree, result };
}

function selfTest() {
  const branch = [{ strict: true, contexts: ['Crosswake CI'], checks: [{ context: 'Crosswake CI', app_id: 15368 }] }];
  const emptyRules = [[]];
  if (!normalizePolicy(branch, emptyRules).ok) return false;
  if (parsePageEnvelope(JSON.stringify([{ total_count: 1, jobs: [{ id: 1 }] }]), 'jobs').ok !== true) return false;
  if (extractCheckoutOid(`actions/checkout@${'c'.repeat(40)}\n2026-10-12T00:00:01Z ##[command]git checkout --progress --force -B branch refs/remotes/pull/8/merge\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${'d'.repeat(40)} subject`, 'c'.repeat(40)).ok !== true) return false;
  return true;
}

export function main(argv, dependencies = {}) {
  const mode = argv[0];
  const stdout = dependencies.stdout ?? process.stdout;
  const stderr = dependencies.stderr ?? process.stderr;
  try {
    if (mode === '--self-test') {
      if (!selfTest()) throw new Error('self_test_failed');
      stdout.write('ci evidence self-test: pass\n');
      return 0;
    }
    if (mode === '--contract') {
      const contract = contractMode();
      stdout.write(`ci contract: ${contract.status}; leaves=${contract.graph.proofLeafCount}; policy=${contract.policy.combinedRequiredChecks.length}; rulesets=${contract.policy.effectiveRules.state}\n`);
      return 0;
    }
    if (mode === '--collect') {
      const getArg = (flag) => argv[argv.indexOf(flag) + 1];
      const result = collectMode(Number(getArg('--run-id')), Number(getArg('--attempt')), dependencies.collectOptions);
      stdout.write(`ci run: ${result.status}; run=${result.runId}; attempt=${result.attempt}; jobs=${result.result.jobCount}; checks=${result.result.checkCount}\n`);
      return 0;
    }
    stderr.write('usage: ci_evidence.mjs --self-test | --contract | --collect --run-id ID --attempt N\n');
    return 2;
  } catch (error) {
    const cause = safeCause(error?.message);
    stderr.write(`ci evidence: blocked cause=${cause}\n`);
    return 1;
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) process.exit(main(process.argv.slice(2)));

