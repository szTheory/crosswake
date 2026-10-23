import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import {
  exactCommitMatch,
  main,
  invocationCaptureRoot,
  retainPrivateFile,
  deriveSkipContract,
  evaluateWorkflowCondition,
  extractCheckoutOid,
  normalizePolicy,
  parseClassifierOutput,
  parsePageEnvelope,
  persistCollectionArtifacts,
  runPrivate,
  runGh,
  safeCause,
  validateRunGraph,
  validateFreshSnapshot,
  validRunUrl,
  verifyCapture,
} from './ci_evidence.mjs';

const sha = (digit) => digit.repeat(40);

function paginated(member, rows, total = rows.length) {
  return JSON.stringify([{ total_count: total, [member]: rows }]);
}

function manifest() {
  return {
    proof_leaves: [
      { leaf_id: 'alpha', display_name: 'alpha', irrelevance_reason: null },
      { leaf_id: 'beta', display_name: 'beta', irrelevance_reason: 'all_changed_paths_allowlisted' },
      { leaf_id: 'release-candidate-full-proof', display_name: 'release-candidate-full-proof', irrelevance_reason: 'release_inputs_unchanged' },
    ],
    required_control_nodes: [{ node_id: 'classify-change', display_name: 'classify-change', required_result: 'success' }],
  };
}

function validGraph() {
  const run = {
    id: 71,
    run_attempt: 2,
    event: 'pull_request',
    head_sha: sha('a'),
    check_suite_id: 901,
    workflow_id: 77,
    pull_requests: [{ number: 8, head: { sha: sha('a') }, base: { sha: sha('b'), ref: 'main' } }],
  };
  const names = ['classify-change', 'alpha', 'beta', 'release-candidate-full-proof', 'Crosswake CI', 'advisory-bot'];
  const jobs = names.map((name, index) => ({
    id: 100 + index,
    run_id: 71,
    run_attempt: 2,
    name,
    status: 'completed',
    conclusion: name === 'beta' ? 'skipped' : name === 'advisory-bot' ? 'failure' : 'success',
    check_run_url: `https://api.github.test/repos/szTheory/crosswake/check-runs/${500 + index}`,
  }));
  const checks = jobs.map((job, index) => ({
    id: 500 + index,
    name: job.name,
    url: job.check_run_url,
    check_suite: { id: 901 },
    status: 'completed',
    conclusion: job.conclusion,
    app: { id: 15368, slug: 'github-actions' },
  }));
  const checkoutLogs = Object.fromEntries(jobs.map((job) => [job.id, '']))
  checkoutLogs[100] = `##[group]Run actions/checkout@${sha('c')}\n2026-10-12T00:00:01Z ##[command]git checkout --progress --force -B branch refs/remotes/pull/8/merge\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${sha('d')} classifier merge`;
  checkoutLogs[101] = `##[group]Run actions/checkout@${sha('c')}\n2026-10-12T00:00:01Z ##[command]git checkout --progress --force -B branch refs/remotes/pull/8/merge\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${sha('d')} synthetic merge`;
  checkoutLogs[102] = '';
  checkoutLogs[103] = `##[group]Run actions/checkout@${sha('c')}\n2026-10-12T00:00:01Z ##[command]git checkout --progress --force -B branch ${sha('a')}\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${sha('a')} PR head`;
  return {
    run,
    jobsPages: [{ total_count: jobs.length, jobs }],
    checkPages: [{ total_count: checks.length, check_runs: checks }],
    policy: { ok: true, required: [{ context: 'Crosswake CI', appId: 15368 }] },
    expectedWorkflowId: 77,
    expectedAttempt: 2,
    expectedBaseRef: 'main',
    expectedCheckoutAction: sha('c'),
    checkoutKinds: {
      'classify-change': 'merge',
      alpha: 'merge',
      beta: 'skipped',
      'release-candidate-full-proof': 'head',
    },
    checkoutLogs,
    authorizedSkips: ['beta'],
    expectedLeafRun: { alpha: true, beta: false, 'release-candidate-full-proof': true },
    sourceLessJobs: ['Crosswake CI'],
    manifest: manifest(),
  };
}

test('gh --paginate --slurp array-of-pages shape validates complete counts and unique IDs', () => {
  const parsed = parsePageEnvelope(paginated('jobs', [{ id: 1 }, { id: 2 }]), 'jobs');
  assert.equal(parsed.ok, true);
  assert.equal(parsed.totalCount, 2);
  assert.deepEqual(parsed.records.map((row) => row.id), [1, 2]);

  for (const raw of [
    paginated('jobs', [{ id: 1 }], 2),
    paginated('jobs', [{ id: 1 }, { id: 1 }], 2),
    JSON.stringify([{ total_count: 2, jobs: [{ id: 1 }] }, { total_count: 2, jobs: [{ id: 1 }] }]),
    JSON.stringify([{ jobs: [{ id: 1 }] }]),
    'not-json',
  ]) {
    assert.equal(parsePageEnvelope(raw, 'jobs').ok, false);
  }
});

test('successful empty rules are distinct from inaccessible, malformed, or missing rules', () => {
  const branch = [{ strict: true, contexts: ['Crosswake CI'], checks: [{ context: 'Crosswake CI', app_id: 15368 }] }];
  const policy = normalizePolicy(
    branch,
    [[]],
  );
  assert.equal(policy.ok, true);
  assert.equal(policy.rulesetEvidence, 'successful-empty');
  assert.deepEqual(policy.required.map(({ context, appId }) => ({ context, appId })), [{ context: 'Crosswake CI', appId: 15368 }]);
  assert.equal(normalizePolicy(branch, [[], []]).ok, true);

  for (const rules of [
    [],
    { status: 403 },
    [{ type: 'required_status_checks' }],
    [[{ type: 'required_status_checks', parameters: {} }]],
    [[{ type: 'required_status_checks', parameters: { required_status_checks: [{}] } }]],
  ]) assert.equal(normalizePolicy([{ strict: true, contexts: ['Crosswake CI'] }], rules).ok, false);
  for (const status of [403, 404]) {
    assert.equal(normalizePolicy({ status }, [[]]).ok, false);
    assert.equal(normalizePolicy(branch, { status }).ok, false);
  }

  const duplicate = normalizePolicy(
    [{ strict: true, contexts: ['Crosswake CI'], checks: [{ context: 'Crosswake CI', app_id: 1 }] }],
    [[{ type: 'required_status_checks', parameters: { required_status_checks: [{ context: 'Crosswake CI', integration_id: 2 }] } }]],
  );
  assert.equal(duplicate.ok, false);
});

test('checkout parser requires one exact observed OID and the pinned checkout action', () => {
  assert.equal(extractCheckoutOid(`Run actions/checkout@${sha('c')}\n2026-10-12T00:00:01Z ##[command]git checkout --progress --force -B branch refs/remotes/pull/8/merge\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${sha('d')} subject`, sha('c')).oid, sha('d'));
  for (const log of [
    `Run actions/checkout@${sha('c')}\ncheckout complete`,
    `Run actions/checkout@${sha('e')}\n2026-10-12T00:00:01Z ##[command]git checkout ${sha('d')}\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${sha('d')} subject`,
    `Run actions/checkout@${sha('c')}\n2026-10-12T00:00:01Z ##[command]git checkout refs/remotes/pull/8/merge\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${sha('d')} one\n2026-10-12T00:00:04Z ##[command]git checkout ${sha('e')}`,
    `Run actions/checkout@${sha('c')}\n2026-10-12T00:00:02Z ##[command]git checkout refs/remotes/pull/8/head`,
  ]) assert.equal(extractCheckoutOid(log, sha('c')).ok, false);
});

test('exact source equality requires the full commit SHA even when trees could match', () => {
  assert.equal(exactCommitMatch(sha('a'), sha('a')), true);
  assert.equal(exactCommitMatch(sha('a'), sha('b')), false);
  assert.equal(exactCommitMatch('7273e6c', sha('a')), false);
});

test('final reread rejects PR, base, or attempt drift before proof persistence', () => {
  const current = {
    runId: 71,
    attempt: 2,
    workflowId: 77,
    checkSuiteId: 901,
    pullNumber: 8,
    candidateCommit: sha('a'),
    baseCommit: sha('b'),
    finalRun: { id: 71, run_attempt: 2, workflow_id: 77, check_suite_id: 901, event: 'pull_request', status: 'completed', html_url: 'https://github.com/szTheory/crosswake/actions/runs/71', head_sha: sha('a'), pull_requests: [{ number: 8, head: { sha: sha('a') }, base: { ref: 'main', sha: sha('b') } }] },
    finalPull: { number: 8, state: 'open', head: { sha: sha('a') }, base: { ref: 'main', sha: sha('b') } },
    finalMain: { sha: sha('b') },
  };
  assert.deepEqual(validateFreshSnapshot(current), { ok: true });
  assert.equal(validRunUrl(current.finalRun.html_url, 71), true);
  assert.equal(validRunUrl('https://github.com/someone-else/crosswake/actions/runs/71', 71), false);
  assert.equal(validateFreshSnapshot({ ...current, finalRun: { ...current.finalRun, status: 'in_progress' } }).cause, 'final_run_attempt_or_head_drift');
  assert.equal(validateFreshSnapshot({ ...current, finalRun: { ...current.finalRun, html_url: 'https://example.test/runs/71' } }).cause, 'final_run_url_unavailable');
  assert.equal(validateFreshSnapshot({ ...current, finalRun: { ...current.finalRun, run_attempt: 3 } }).cause, 'final_run_attempt_or_head_drift');
  assert.equal(validateFreshSnapshot({ ...current, finalPull: { ...current.finalPull, head: { sha: sha('c') } } }).cause, 'final_pr_candidate_or_base_drift');
  assert.equal(validateFreshSnapshot({ ...current, finalMain: { sha: sha('c') } }).cause, 'canonical_base_moved_before_acceptance');
});

test('unexpected errors collapse to a safe cause instead of echoing private paths', () => {
  assert.equal(safeCause('candidate_identity_mismatch'), 'candidate_identity_mismatch');
  assert.equal(safeCause('ENOENT: no such file, open /private/tmp/secret-root/raw.log'), 'adapter_unexpected_failure');
});

test('run graph distinguishes merge checkout from head-only checkout and accepts authorized skips only', () => {
  const graph = validGraph();
  const result = validateRunGraph(graph);
  assert.equal(result.ok, true, JSON.stringify(result.blockers));
  assert.equal(result.jobCount, 6);
  assert.equal(result.checkouts.alpha.kind, 'merge');
  assert.equal(result.checkouts.alpha.oid, sha('d'));
  assert.equal(result.checkouts['release-candidate-full-proof'].kind, 'head');
  assert.equal(result.checkouts['release-candidate-full-proof'].oid, sha('a'));
  assert.equal(result.governedMergeOid, sha('d'));

  const wrongAttempt = validGraph();
  wrongAttempt.expectedAttempt = 3;
  assert.equal(validateRunGraph(wrongAttempt).ok, false);

  const missingCheckout = validGraph();
  missingCheckout.checkoutLogs[101] = '';
  assert.equal(validateRunGraph(missingCheckout).ok, false);

  const unapprovedSkip = validGraph();
  unapprovedSkip.authorizedSkips = [];
  assert.equal(validateRunGraph(unapprovedSkip).ok, false);

  for (const conclusion of ['neutral', 'cancelled', 'failure', 'action_required']) {
    const changed = validGraph();
    changed.jobsPages[0].jobs[1].conclusion = conclusion;
    changed.checkPages[0].check_runs[1].conclusion = conclusion;
    assert.equal(validateRunGraph(changed).ok, false);
  }
  const pending = validGraph();
  pending.jobsPages[0].jobs[1].status = 'in_progress';
  pending.jobsPages[0].jobs[1].conclusion = null;
  pending.checkPages[0].check_runs[1].status = 'in_progress';
  pending.checkPages[0].check_runs[1].conclusion = null;
  assert.equal(validateRunGraph(pending).ok, false);

  const wrongApp = validGraph();
  wrongApp.checkPages[0].check_runs[4].app.id = 42;
  assert.equal(validateRunGraph(wrongApp).ok, false);

  const brokenJobCheckUrl = validGraph();
  brokenJobCheckUrl.jobsPages[0].jobs[1].check_run_url = 'https://api.github.test/repos/szTheory/crosswake/check-runs/999';
  assert.equal(validateRunGraph(brokenJobCheckUrl).ok, false);

  const wrongSuite = validGraph();
  wrongSuite.checkPages[0].check_runs[0].check_suite.id = 902;
  assert.equal(validateRunGraph(wrongSuite).ok, false);

  const failingAdvisory = validGraph();
  assert.equal(validateRunGraph(failingAdvisory).ok, true);

  const treeEqualButDifferentSha = validGraph();
  treeEqualButDifferentSha.run.pull_requests[0].head.sha = sha('d');
  treeEqualButDifferentSha.checkoutLogs[103] = `Run actions/checkout@${sha('c')}\n2026-10-12T00:00:01Z ##[command]git checkout --progress --force -B branch ${sha('d')}\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${sha('d')} same tree`;
  assert.equal(validateRunGraph(treeEqualButDifferentSha).ok, false);
});

test('classifier output authorizes skips only when the exact workflow condition and manifest agree', () => {
  const full = parseClassifierOutput("classification=full_proof\nscheduled_families=[\"full_proof\"]\nirrelevant_leaves=[]\nrelease_candidate_scope=full_matrix\n", manifest());
  assert.equal(full.ok, true);
  full.releaseCandidateScope = 'full_matrix';
  const conditions = {
    alpha: "needs.classify-change.outputs.classification == 'full_proof'",
    beta: "needs.classify-change.outputs.classification == 'full_proof'",
    'release-candidate-full-proof': "needs.classify-change.outputs.release_candidate_scope == 'full_matrix'",
  };
  const fullSkipContract = deriveSkipContract(manifest(), conditions, full);
  assert.equal(fullSkipContract.ok, true);
  assert.deepEqual(fullSkipContract.authorizedSkipIds, []);
  assert.deepEqual(fullSkipContract.shouldRun, { alpha: true, beta: true, 'release-candidate-full-proof': true });

  const partial = {
    classification: 'partial',
    authorizedSkipIds: ['beta'],
    scheduledFamilies: ['full_proof'],
    releaseCandidateScope: 'full_matrix',
  };
  const conditional = { ...conditions, alpha: "needs.classify-change.result == 'success'", beta: "contains(fromJSON(needs.classify-change.outputs.scheduled_families), 'public_docs')" };
  const allowed = deriveSkipContract(manifest(), conditional, partial);
  assert.equal(allowed.ok, true);
  assert.deepEqual(allowed.authorizedSkipIds, ['beta']);
  assert.equal(allowed.shouldRun.beta, false);
  assert.equal(deriveSkipContract(manifest(), conditions, partial).ok, false);
  assert.equal(deriveSkipContract(manifest(), { ...conditional, beta: 'always()' }, partial).ok, false);
  assert.equal(evaluateWorkflowCondition('needs.unrecognized.result == \'success\'', full).ok, false);
});

test('production adapter capture is real gh subprocess stdout, stderr, and status kept privately', () => {
  const ownerPointer = '/private/tmp/crosswake-178-owner-env';
  if (!fs.existsSync(ownerPointer)) return;
  const root = fs.readFileSync(ownerPointer, 'utf8').trim();
  const fixture = path.join(root, 'ci-adapter-fixture');
  const status = fs.readFileSync(path.join(fixture, 'historical-jobs.status'), 'utf8');
  const stdout = fs.readFileSync(path.join(fixture, 'historical-jobs.stdout'), 'utf8');
  const stderr = fs.readFileSync(path.join(fixture, 'historical-jobs.stderr'), 'utf8');
  assert.equal(status, '0');
  assert.equal(stderr, '');
  assert.equal(parsePageEnvelope(stdout, 'jobs').ok, true);

  const logsStatus = fs.readFileSync(path.join(fixture, 'historical-job-logs-raw.status'), 'utf8');
  const logsOut = fs.readFileSync(path.join(fixture, 'historical-job-logs-raw.stdout'), 'utf8');
  const logsErr = fs.readFileSync(path.join(fixture, 'historical-job-logs-raw.stderr'), 'utf8');
  assert.equal(logsStatus, '0');
  assert.equal(logsErr, '');
  assert.equal(extractCheckoutOid(logsOut, '9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0').ok, true);
  const failedLogStatus = fs.readFileSync(path.join(fixture, 'historical-job-logs.status'), 'utf8');
  const failedLogOut = fs.readFileSync(path.join(fixture, 'historical-job-logs.stdout'), 'utf8');
  const failedLogErr = fs.readFileSync(path.join(fixture, 'historical-job-logs.stderr'), 'utf8');
  assert.equal(failedLogStatus, '1');
  assert.equal(failedLogOut, '');
  assert.match(failedLogErr, /terminal escape sequences/);
  for (const [name, kind] of [['historical-classify-change-logs.stdout', 'merge'], ['historical-documentation-contracts-logs.stdout', 'merge'], ['historical-job-logs-raw.stdout', 'head']]) {
    const actualLogs = fs.readFileSync(path.join(fixture, name), 'utf8');
    const observed = extractCheckoutOid(actualLogs, '9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0');
    assert.equal(observed.ok, true);
    assert.equal(/refs\/remotes\/pull/.test(actualLogs), kind === 'merge');
  }

  const branch = JSON.parse(fs.readFileSync(path.join(fixture, 'branch-protection.stdout'), 'utf8'));
  const rules = JSON.parse(fs.readFileSync(path.join(fixture, 'effective-rules.stdout'), 'utf8'));
  const policy = normalizePolicy(branch, rules);
  assert.equal(policy.ok, true);
  assert.deepEqual(policy.required.map(({ context, appId }) => ({ context, appId })), [{ context: 'Crosswake CI', appId: 15368 }]);
  const run = JSON.parse(fs.readFileSync(path.join(fixture, 'historical-run.stdout'), 'utf8'));
  assert.equal(Array.isArray(run), true);
  assert.equal(run.length, 1);
  assert.equal(run[0].run_attempt, 1);
  const checks = JSON.parse(fs.readFileSync(path.join(fixture, 'historical-check-runs.stdout'), 'utf8'));
  assert.equal(parsePageEnvelope(checks, 'check_runs').totalCount, 49);
  const mergeLog = fs.readFileSync(path.join(fixture, 'historical-classify-change-logs.stdout'), 'utf8');
  assert.equal(mergeLog.includes('Set output \'classification\''), true);
  const mergeCheckout = extractCheckoutOid(mergeLog, '9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0');
  assert.equal(mergeCheckout.ok, true);
  assert.equal(mergeCheckout.ref, 'refs/remotes/pull/232/merge');
  assert.notEqual(mergeCheckout.ref, `refs/remotes/pull/${run[0].pull_requests[0].number}/merge`);
  assert.notEqual(mergeCheckout.oid, run[0].head_sha);
  assert.notEqual(mergeCheckout.oid, checks[0].check_runs[0].head_sha);
  const headLog = fs.readFileSync(path.join(fixture, 'historical-job-logs-raw.stdout'), 'utf8');
  const headCheckout = extractCheckoutOid(headLog, '9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0');
  assert.equal(headCheckout.ok, true);
  assert.equal(headCheckout.ref, run[0].head_sha);

  const binding = JSON.parse(fs.readFileSync(path.join(root, 'ci-policy-binding.json'), 'utf8'));
  const publicContract = JSON.parse(fs.readFileSync(new URL('./ci-contract.json', import.meta.url), 'utf8'));
  assert.equal(binding.candidateCommit, publicContract.candidate.commit);
  assert.equal(binding.candidateTree, publicContract.candidate.tree);
  for (const [name, capture] of Object.entries(binding.rawResponsePointers)) {
    assert.ok(capture.stdout.endsWith('.stdout'));
    const stdout = fs.readFileSync(capture.stdout, 'utf8');
    const stderr = fs.readFileSync(capture.stderr, 'utf8');
    assert.deepEqual(verifyCapture(capture, 0, stdout, stderr), binding.rawResponseIntegrity[name]);
  }
  const capturedBranch = JSON.parse(fs.readFileSync(binding.rawResponsePointers.branchProtection.stdout, 'utf8'));
  const capturedRules = JSON.parse(fs.readFileSync(binding.rawResponsePointers.effectiveRules.stdout, 'utf8'));
  assert.deepEqual(normalizePolicy(capturedBranch, capturedRules).required, binding.policy.normalized.required);
});

test('production subprocess pointers detect retained-byte tampering and bound command duration', () => {
  const ownerRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-ci-capture-'));
  fs.chmodSync(ownerRoot, 0o700);
  const captureRoot = path.join(ownerRoot, 'captures');
  try {
    const good = runPrivate('fixture-success', process.execPath, ['-e', 'process.stdout.write("normalized-output");process.stderr.write("safe-warning");'], { ownerRoot, captureRoot });
    assert.equal(good.ok, true);
    assert.deepEqual(verifyCapture(good.capture, 0, 'normalized-output', 'safe-warning'), {
      status: 0,
      stdoutBytes: Buffer.byteLength('normalized-output'),
      stderrBytes: Buffer.byteLength('safe-warning'),
      stdoutSha256: good.capture.stdoutSha256,
      stderrSha256: good.capture.stderrSha256,
      statusSha256: good.capture.statusSha256,
    });

    const tamperedPath = path.join(captureRoot, 'tampered.stdout');
    fs.writeFileSync(tamperedPath, 'changed-output', { mode: 0o600 });
    assert.throws(() => verifyCapture({ ...good.capture, stdout: tamperedPath }, 0, 'changed-output', 'safe-warning'), /capture_integrity_mismatch/);

    const timed = runPrivate('fixture-timeout', process.execPath, ['-e', 'setTimeout(()=>{},250);'], { ownerRoot, captureRoot, timeoutMs: 25 });
    assert.equal(timed.ok, false);
    assert.equal(timed.cause, 'subprocess_timeout');
  } finally {
    fs.rmSync(ownerRoot, { recursive: true, force: true });
  }
});

test('invocation captures and replaced private bindings retain earlier bytes', () => {
  const ownerRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-ci-retained-'));
  fs.chmodSync(ownerRoot, 0o700);
  try {
    const firstRoot = invocationCaptureRoot(ownerRoot, 'contract');
    const first = runPrivate('branch-protection', process.execPath, ['-e', 'process.stdout.write("first")'], { ownerRoot, captureRoot: firstRoot });
    const secondRoot = invocationCaptureRoot(ownerRoot, 'contract');
    const second = runPrivate('branch-protection', process.execPath, ['-e', 'process.stdout.write("second")'], { ownerRoot, captureRoot: secondRoot });
    assert.notEqual(first.capture.stdout, second.capture.stdout);
    assert.equal(fs.readFileSync(first.capture.stdout, 'utf8'), 'first');
    assert.equal(fs.readFileSync(second.capture.stdout, 'utf8'), 'second');

    const bindingPath = path.join(ownerRoot, 'ci-policy-binding.json');
    fs.writeFileSync(bindingPath, '{"capture":"first"}\n', { mode: 0o600 });
    const original = fs.readFileSync(bindingPath);
    const retained = retainPrivateFile(bindingPath, ownerRoot, 'ci-policy-binding-history');
    fs.writeFileSync(bindingPath, '{"capture":"second"}\n', { mode: 0o600 });
    assert.deepEqual(fs.readFileSync(retained), original);
    assert.equal((fs.statSync(retained).mode & 0o777), 0o600);
  } finally {
    fs.rmSync(ownerRoot, { recursive: true, force: true });
  }
});

test('production GitHub adapter uses fixed GET routes and retains real subprocess return envelopes', () => {
  const ownerRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-gh-adapter-'));
  fs.chmodSync(ownerRoot, 0o700);
  const captureRoot = path.join(ownerRoot, 'captures');
  const argsPath = path.join(ownerRoot, 'args.json');
  const fakeGh = path.join(ownerRoot, 'gh');
  const route = 'repos/szTheory/crosswake/branches/main/protection/required_status_checks';
  try {
    fs.writeFileSync(fakeGh, `#!/usr/bin/env node\nconst fs=require('node:fs');fs.writeFileSync(process.env.GH_ARGS_PATH,JSON.stringify(process.argv.slice(2)));process.stdout.write(JSON.stringify([{strict:true,contexts:['Crosswake CI'],checks:[{context:'Crosswake CI',app_id:15368}]}]));\n`, { mode: 0o700 });
    fs.chmodSync(fakeGh, 0o700);
    const success = runGh('adapter-success', route, true, { command: fakeGh, ownerRoot, captureRoot, env: { GH_ARGS_PATH: argsPath } });
    assert.equal(success.ok, true);
    assert.deepEqual(JSON.parse(fs.readFileSync(argsPath, 'utf8')), ['api', '--paginate', '--slurp', route]);
    assert.equal(normalizePolicy(success.value, [[]]).ok, true);
    assert.equal(verifyCapture(success.capture, 0, fs.readFileSync(success.capture.stdout, 'utf8'), '' ).status, 0);

    fs.writeFileSync(fakeGh, `#!/usr/bin/env node\nprocess.stderr.write('HTTP 403 Forbidden');process.exit(1);\n`, { mode: 0o700 });
    fs.chmodSync(fakeGh, 0o700);
    const denied = runGh('adapter-denied', 'repos/szTheory/crosswake/rules/branches/main?per_page=100', true, { command: fakeGh, ownerRoot, captureRoot });
    assert.equal(denied.ok, false);
    assert.equal(denied.cause, 'adapter_denied_github_http_403');
    assert.equal(fs.readFileSync(denied.capture.status, 'utf8'), '1');
    assert.equal(fs.readFileSync(denied.capture.stderr, 'utf8'), 'HTTP 403 Forbidden');

    assert.equal(runGh('adapter-untrusted-route', 'repos/szTheory/crosswake/actions/runs/1/artifacts', false, { command: fakeGh, ownerRoot, captureRoot }).ok, false);
    assert.equal(fs.existsSync(path.join(captureRoot, 'adapter-untrusted-route.stdout')), false);
  } finally {
    fs.rmSync(ownerRoot, { recursive: true, force: true });
  }
});

test('hosted proof artifacts persist only after private capture verification and identity checks', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-ci-proof-'));
  fs.chmodSync(root, 0o700);
  const ownerRoot = path.join(root, 'private');
  const evidenceRoot = path.join(root, 'public');
  fs.mkdirSync(ownerRoot, { mode: 0o700 });
  fs.mkdirSync(evidenceRoot, { mode: 0o700 });
  try {
    const captured = runPrivate('accepted-read', process.execPath, ['-e', 'process.stdout.write("[]");'], { ownerRoot, captureRoot: path.join(ownerRoot, 'captures') });
    const proof = {
      schemaVersion: 1,
      status: 'candidate-run-observed',
      candidate: { commit: sha('a'), tree: sha('b') },
      workflow: { source: { version: sha('a'), blobOid: sha('c') } },
      governedMergeOid: sha('d'),
      run: { id: 71, attempt: 2, url: 'https://github.com/szTheory/crosswake/actions/runs/71' },
    };
    const binding = { runId: 71, attempt: 2, candidateCommit: sha('a'), candidateTree: sha('b'), accepted: true, rawCapturePointers: { jobs: captured.capture } };
    assert.throws(() => persistCollectionArtifacts({ ownerRoot, evidenceRoot, runId: 71, attempt: 2, proof: { ...proof, run: { ...proof.run, url: 'https://example.test/runs/71' } }, privateBinding: binding }), /collection_artifact_identity_mismatch/);
    assert.throws(() => persistCollectionArtifacts({ ownerRoot, evidenceRoot, runId: 71, attempt: 2, proof: { ...proof, workflow: { source: { version: sha('a'), blobOid: 'short' } } }, privateBinding: binding }), /collection_artifact_identity_mismatch/);
    assert.throws(() => persistCollectionArtifacts({ ownerRoot, evidenceRoot, runId: 71, attempt: 2, proof: { ...proof, governedMergeOid: null }, privateBinding: binding }), /collection_artifact_identity_mismatch/);
    persistCollectionArtifacts({ ownerRoot, evidenceRoot, runId: 71, attempt: 2, proof, privateBinding: binding });
    const publicPath = path.join(evidenceRoot, 'hosted-ci-proof.json');
    const firstPublic = fs.readFileSync(publicPath, 'utf8');
    assert.equal(JSON.parse(firstPublic).run.id, 71);
    assert.equal(/\/private\/|\/Users\/|ghp_|Authorization:/i.test(firstPublic), false);
    assert.equal((fs.statSync(path.join(ownerRoot, 'ci-run-binding-71-2.json')).mode & 0o777), 0o600);

    const tampered = path.join(ownerRoot, 'tampered.stdout');
    fs.writeFileSync(tampered, 'changed', { mode: 0o600 });
    const badProof = { ...proof, run: { id: 72, attempt: 1, url: 'https://github.com/szTheory/crosswake/actions/runs/72' } };
    const badBinding = { ...binding, runId: 72, attempt: 1, rawCapturePointers: { jobs: { ...captured.capture, stdout: tampered } } };
    assert.throws(() => persistCollectionArtifacts({ ownerRoot, evidenceRoot, runId: 72, attempt: 1, proof: badProof, privateBinding: badBinding }), /capture_integrity_mismatch/);
    assert.equal(fs.existsSync(path.join(ownerRoot, 'ci-run-binding-72-1.json')), false);
    assert.equal(fs.readFileSync(publicPath, 'utf8'), firstPublic);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

test('production --collect reaches artifact persistence through real subprocess envelopes and blocks one final drift', () => {
  const ownerSource = fs.readFileSync('/private/tmp/crosswake-178-owner-env', 'utf8').trim();
  const bindingNames = ['candidate-binding-renewed.json', 'candidate-binding.json'].filter((name) => fs.existsSync(path.join(ownerSource, name)));
  assert.deepEqual(bindingNames, ['candidate-binding-renewed.json']);
  const sourceBinding = JSON.parse(fs.readFileSync(path.join(ownerSource, bindingNames[0]), 'utf8'));
  const sourcePolicy = JSON.parse(fs.readFileSync(path.join(ownerSource, 'ci-policy-binding.json'), 'utf8'));
  const contractPath = path.join(path.dirname(new URL(import.meta.url).pathname), 'ci-contract.json');
  const contract = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
  const manifest = JSON.parse(fs.readFileSync(path.join(sourceBinding.deliveryRoot, 'script/ci_leaf_manifest.json'), 'utf8'));
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-ci-collect-flow-'));
  fs.chmodSync(root, 0o700);
  const ownerRoot = path.join(root, 'owner');
  const evidenceRoot = path.join(root, 'evidence');
  fs.mkdirSync(ownerRoot, { mode: 0o700 });
  fs.mkdirSync(evidenceRoot, { mode: 0o700 });
  fs.copyFileSync(path.join(ownerSource, bindingNames[0]), path.join(ownerRoot, bindingNames[0]));
  fs.chmodSync(path.join(ownerRoot, bindingNames[0]), 0o600);
  fs.copyFileSync(path.join(ownerSource, 'ci-policy-binding.json'), path.join(ownerRoot, 'ci-policy-binding.json'));
  fs.chmodSync(path.join(ownerRoot, 'ci-policy-binding.json'), 0o600);

  const runId = 82178301;
  const attempt = 1;
  const pullNumber = 947;
  const checkSuiteId = 719003;
  const workflowId = sourcePolicy.workflow.id;
  const routeRuns = `repos/szTheory/crosswake/actions/runs/${runId}`;
  const run = {
    id: runId, run_attempt: attempt, workflow_id: workflowId, check_suite_id: checkSuiteId,
    event: 'pull_request', status: 'completed', conclusion: 'success',
    html_url: `https://github.com/szTheory/crosswake/actions/runs/${runId}`,
    head_sha: sourceBinding.candidateCommit,
    pull_requests: [{ number: pullNumber, head: { sha: sourceBinding.candidateCommit }, base: { ref: 'main', sha: sourceBinding.sourceBaseCommit } }],
  };
  const pull = { number: pullNumber, state: 'open', head: { sha: sourceBinding.candidateCommit }, base: { ref: 'main', sha: sourceBinding.sourceBaseCommit } };
  const policyRequired = sourcePolicy.policy.normalized.required;
  const branch = {
    strict: sourcePolicy.policy.normalized.strict,
    contexts: policyRequired.filter((row) => row.sources.includes('branch_protection')).map((row) => row.context),
    checks: policyRequired.filter((row) => row.sources.includes('branch_protection')).map((row) => ({ context: row.context, app_id: row.appId })),
  };
  const rows = [...manifest.proof_leaves, ...manifest.required_control_nodes];
  const requiredNames = [...new Set([...rows.map((row) => row.display_name), 'Crosswake CI', ...contract.graph.advisoryJobs])];
  const logs = {};
  const jobs = requiredNames.map((name, index) => {
    const id = 24000 + index;
    const checkId = 54000 + index;
    const checkout = contract.graph.requiredCheckoutPolicies[name];
    if (checkout?.kind === 'merge' || checkout?.kind === 'head') {
      const oid = checkout.kind === 'head' ? sourceBinding.candidateCommit : sha('e');
      const ref = checkout.kind === 'head' ? sourceBinding.candidateCommit : `refs/remotes/pull/${pullNumber}/merge`;
      logs[`repos/szTheory/crosswake/actions/jobs/${id}/logs`] = `##[group]Run actions/checkout@${checkout.actionPin}\n2026-10-12T00:00:01Z ##[command]git checkout --progress --force -B branch ${ref}\n2026-10-12T00:00:02Z ##[command]git log -1 --format=%H\n2026-10-12T00:00:03Z ${oid} fixture checkout\n`;
    }
    return {
      id, run_id: runId, run_attempt: attempt, name, status: 'completed',
      conclusion: contract.graph.advisoryJobs.includes(name) ? 'failure' : 'success',
      check_run_url: `https://api.github.com/repos/szTheory/crosswake/check-runs/${checkId}`,
    };
  });
  const checkRuns = jobs.map((job, index) => ({
    id: 54000 + index, name: job.name, url: job.check_run_url,
    check_suite: { id: checkSuiteId }, status: 'completed', conclusion: job.conclusion,
    app: { id: 15368, slug: 'github-actions' },
  }));
  const routePayloads = {
    [routeRuns]: [JSON.stringify([run]), JSON.stringify([run])],
    [`repos/szTheory/crosswake/pulls/${pullNumber}`]: [JSON.stringify([pull])],
    'repos/szTheory/crosswake/commits/main': [JSON.stringify([{ sha: sourceBinding.sourceBaseCommit }])],
    [`repos/szTheory/crosswake/actions/runs/${runId}/attempts/${attempt}/jobs?per_page=100`]: [JSON.stringify([{ total_count: jobs.length, jobs }])],
    [`repos/szTheory/crosswake/check-suites/${checkSuiteId}/check-runs?per_page=100`]: [JSON.stringify([{ total_count: checkRuns.length, check_runs: checkRuns }])],
    'repos/szTheory/crosswake/branches/main/protection/required_status_checks': [JSON.stringify([branch])],
    'repos/szTheory/crosswake/rules/branches/main?per_page=100': [JSON.stringify([[]])],
    ...Object.fromEntries(Object.entries(logs).map(([route, response]) => [route, [response]])),
  };
  const dataPath = path.join(root, 'responses.json');
  const countPath = path.join(root, 'counts.json');
  const fakeGh = path.join(root, 'gh-fixture.mjs');
  fs.writeFileSync(dataPath, JSON.stringify({ routePayloads }), { mode: 0o600 });
  fs.writeFileSync(countPath, '{}', { mode: 0o600 });
  fs.writeFileSync(fakeGh, `#!/usr/bin/env node\nimport fs from 'node:fs';\nconst data=JSON.parse(fs.readFileSync(process.env.CI_FIXTURE_DATA,'utf8'));\nconst countsPath=process.env.CI_FIXTURE_COUNTS;\nconst counts=JSON.parse(fs.readFileSync(countsPath,'utf8'));\nconst args=process.argv.slice(2);\nconst route=args.at(-1);\nconst responses=data.routePayloads[route];\nif(!responses){process.stderr.write('HTTP 404 Not Found');process.exit(1);}\nconst index=counts[route]??0;counts[route]=index+1;fs.writeFileSync(countsPath,JSON.stringify(counts));\nprocess.stdout.write(responses[Math.min(index,responses.length-1)]);\n`, { mode: 0o700 });
  fs.chmodSync(fakeGh, 0o700);
  const invoke = () => {
    let stdout = '';
    let stderr = '';
    const code = main(['--collect', '--run-id', String(runId), '--attempt', String(attempt)], {
      collectOptions: { ownerRoot, evidenceRoot, ghCommand: fakeGh, env: { CI_FIXTURE_DATA: dataPath, CI_FIXTURE_COUNTS: countPath } },
      stdout: { write: (value) => { stdout += value; } },
      stderr: { write: (value) => { stderr += value; } },
    });
    return { code, stdout, stderr };
  };
  try {
    const success = invoke();
    assert.equal(success.code, 0, success.stderr);
    assert.match(success.stdout, /candidate-run-observed/);
    const publicPath = path.join(evidenceRoot, 'hosted-ci-proof.json');
    const publicProof = JSON.parse(fs.readFileSync(publicPath, 'utf8'));
    assert.equal(publicProof.run.url, run.html_url);
    assert.equal(publicProof.workflow.source.version, sourceBinding.candidateCommit);
    assert.match(publicProof.workflow.source.blobOid, /^[0-9a-f]{40}$/);
    assert.equal(publicProof.governedMergeOid, sha('e'));
    assert.equal(publicProof.requiredJobs.find((row) => row.name === 'Crosswake CI').checkout, null);
    const privateRunBindingPath = path.join(ownerRoot, `ci-run-binding-${runId}-${attempt}.json`);
    assert.equal((fs.statSync(privateRunBindingPath).mode & 0o777), 0o600);
    const privateRunBinding = JSON.parse(fs.readFileSync(privateRunBindingPath, 'utf8'));
    assert.equal(privateRunBinding.workflowSource.blobOid, publicProof.workflow.source.blobOid);
    assert.equal(privateRunBinding.rawCapturePointers.finalRun.stdout.includes(root), true);

    const priorPublic = fs.readFileSync(publicPath, 'utf8');
    const drifted = { ...run, run_attempt: attempt + 1 };
    const fixture = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
    fixture.routePayloads[routeRuns][1] = JSON.stringify([drifted]);
    fs.writeFileSync(dataPath, JSON.stringify(fixture), { mode: 0o600 });
    fs.writeFileSync(countPath, '{}', { mode: 0o600 });
    const blocked = invoke();
    assert.equal(blocked.code, 1);
    assert.match(blocked.stderr, /final_run_attempt_or_head_drift/);
    assert.equal(fs.readFileSync(publicPath, 'utf8'), priorPublic);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
});

