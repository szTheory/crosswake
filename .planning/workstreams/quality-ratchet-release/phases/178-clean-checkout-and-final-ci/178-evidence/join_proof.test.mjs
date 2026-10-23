import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { joinProof, liveRead, verifyCurrentLocalProjection } from './join_proof.mjs';

const contract = JSON.parse(fs.readFileSync(new URL('./ci-contract.json', import.meta.url), 'utf8'));
const oid = (char) => char.repeat(40);
const stageOrder = [
  'repository-preflight', 'root-proof', 'example-host-proof', 'browser-proof',
  'ios-package-proof', 'android-package-proof', 'format-proof', 'warnings-proof',
  'repository-cleanliness',
];

function liveAdapterFixture(options = {}) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-live-test-'));
  fs.chmodSync(directory, 0o700);
  const captureRoot = path.join(directory, 'capture');
  fs.mkdirSync(captureRoot, { mode: 0o700 });
  const scenarioPath = path.join(directory, 'scenario.json');
  const callsPath = path.join(directory, 'calls.json');
  fs.writeFileSync(scenarioPath, JSON.stringify(options), { mode: 0o600 });
  const ghPath = path.join(directory, 'gh-fixture');
  const gitPath = path.join(directory, 'git-fixture');
  fs.writeFileSync(ghPath, `#!/usr/bin/env node
const fs = require('node:fs');
const scenario = JSON.parse(fs.readFileSync(process.env.FIXTURE_SCENARIO, 'utf8'));
const callsFile = process.env.FIXTURE_CALLS;
const calls = fs.existsSync(callsFile) ? JSON.parse(fs.readFileSync(callsFile, 'utf8')) : [];
const args = process.argv.slice(2);
const route = args.at(-1);
calls.push({ args, route });
fs.writeFileSync(callsFile, JSON.stringify(calls), { mode: 0o600 });
const count = calls.filter(row => row.route === route).length;
const candidate = '3e8a4b2601b542323edfd6053f25e56c67873b47';
const base = 'd0dbdf7bf196cea167ced3c50cf620bf3cb2452b';
const merge = scenario.mergeOid || 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
let value;
if (route.endsWith('/actions/runs/38322827152')) value = [{ id: 38322827152, run_attempt: scenario.attemptDrift && count > 1 ? 2 : 1, workflow_id: 353403178, check_suite_id: 103831660113, head_sha: candidate, event: 'pull_request', status: 'completed', conclusion: 'success' }];
else if (route.endsWith('/pulls/238')) value = [{ number: 238, state: 'open', merge_commit_sha: merge, head: { sha: candidate, repo: { full_name: scenario.wrongRepo ? 'elsewhere/fork' : 'szTheory/crosswake' } }, base: { ref: 'main', sha: base, repo: { full_name: 'szTheory/crosswake' } } }];
else if (route.endsWith('/commits/main')) value = [{ sha: base }];
else if (route.endsWith('/branches/main/protection/required_status_checks')) value = [{ url: scenario.policyChanged ? 'https://api.github.com/repos/szTheory/crosswake/branches/main/protection/required_status_checks?changed=1' : 'https://api.github.com/repos/szTheory/crosswake/branches/main/protection/required_status_checks', strict: true, contexts: ['Crosswake CI'], contexts_url: 'https://api.github.com/repos/szTheory/crosswake/branches/main/protection/required_status_checks/contexts', checks: [{ context: 'Crosswake CI', app_id: 15368 }] }];
else if (route.endsWith('/rules/branches/main?per_page=100')) value = [[]];
else { process.stderr.write('unexpected fixture route'); process.exit(2); }
process.stdout.write(JSON.stringify(value));
`);
  fs.chmodSync(ghPath, 0o700);
  fs.writeFileSync(gitPath, `#!/usr/bin/env node
process.stdout.write((process.env.FIXTURE_MERGE || 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa') + '\\trefs/pull/238/merge\\n');
`);
  fs.chmodSync(gitPath, 0o700);
  return {
    directory, captureRoot, ghPath, gitPath, callsPath,
    hosted: {
      repository: 'szTheory/crosswake',
      run: { id: 38322827152, attempt: 1 },
      pullRequest: { number: 238 },
      candidate: { commit: '3e8a4b2601b542323edfd6053f25e56c67873b47' },
      governedMergeOid: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    },
    read(scenario = options) {
      fs.writeFileSync(scenarioPath, JSON.stringify(scenario), { mode: 0o600 });
      return liveRead(this.hosted, {
        captureRoot, ghExecutable: ghPath, gitExecutable: gitPath,
        env: { ...process.env, GH_HOST: 'rerouted.example', FIXTURE_SCENARIO: scenarioPath, FIXTURE_CALLS: callsPath, FIXTURE_MERGE: scenario.mergeOid || 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' },
      });
    },
    calls() { return JSON.parse(fs.readFileSync(callsPath, 'utf8')); },
    dispose() { fs.rmSync(directory, { recursive: true, force: true }); },
  };
}

function proofFixture() {
  const commit = oid('a');
  const candidate = contract.candidate.commit;
  const tree = oid('b');
  const base = contract.candidate.baseCommit;
  const jobNames = [...contract.graph.proofLeaves.map((row) => row.displayName), ...contract.graph.controlNodes.map((row) => row.displayName), contract.graph.umbrella.displayName];
  const requiredJobs = jobNames.map((name, index) => {
    const checkoutPolicy = contract.graph.requiredCheckoutPolicies[name];
    const isSourceLess = contract.graph.sourceLessJobs.includes(name);
    const kind = checkoutPolicy?.kind;
    const oidValue = kind === 'head' ? candidate : commit;
    return {
      name,
      jobId: index + 1,
      checkRunId: index + 101,
      conclusion: 'success',
      checkout: isSourceLess ? null : { jobId: index + 1, checkRunId: index + 101, attempt: 1, kind, oid: oidValue, refKind: kind === 'head' ? 'pull_request_head_sha' : 'pull_request_merge_ref' },
    };
  });
  return {
    contract,
    hosted: {
      schemaVersion: 1,
      status: 'candidate-run-observed',
      repository: 'szTheory/crosswake',
      workflow: { id: contract.workflow.id, path: contract.workflow.path, source: { version: candidate, blobOid: contract.workflow.source.blobOid } },
      candidate: { commit: candidate, tree: contract.candidate.tree, baseCommit: base },
      pullRequest: { number: 238, state: 'open', headCommit: candidate, baseRef: 'main', baseCommit: base },
      run: { id: 38322827152, attempt: 1, event: 'pull_request', url: 'https://github.com/szTheory/crosswake/actions/runs/38322827152', headCommit: candidate, checkSuiteId: 10, jobCount: 49, checkCount: 49 },
      governedMergeOid: commit,
      policy: { observedAt: '2026-10-12T23:59:00Z', strict: true, rulesetEvidence: 'successful-empty', effectiveRuleCount: 0, requiredContexts: [{ context: 'Crosswake CI', appId: 15368, sources: ['branch_protection'] }] },
      classifier: { result: 'full_proof', authorizedSkipCount: 0 },
      requiredJobs,
    },
    local: {
      schemaVersion: 1,
      phase: 178,
      plan: '02',
      kind: 'final',
      status: 'pass',
      command: 'script/verify_repository.sh --all',
      source: { commit, tree },
      stages: stageOrder.map((purpose) => ({ purpose, result: 'PASS' })),
      stageCount: 9,
      executedLogCount: 8,
      ignoredArtifacts: { beforeCount: 0, afterCount: 0, newCount: 0 },
      privateEvidence: 'owner-private-retained',
      privateIntegrity: {
        bindingValid: true,
        invocationValid: true,
        retainedCapturesValid: true,
        headTreeIndexAndNulSnapshotsUnchanged: true,
        requiredGraphGreen: true,
        ciPolicyFingerprints: { branchProtection: 'a'.repeat(64), effectiveRules: 'b'.repeat(64) },
        advisoryJobs: [{ name: 'brand-visual', jobId: 999, checkRunId: 999, attempt: 1, status: 'completed', conclusion: 'success' }],
      },
    },
    live: {
      canonicalRepository: 'szTheory/crosswake',
      pullRequest: { number: 238, state: 'open', repo: 'szTheory/crosswake', headRepo: 'szTheory/crosswake', baseRepo: 'szTheory/crosswake', headCommit: candidate, baseRef: 'main', baseCommit: base, mergeCommitSha: commit },
      mergeRef: { ref: 'refs/pull/238/merge', oid: commit },
      run: { id: 38322827152, attempt: 1, workflowId: 353403178, checkSuiteId: 10, headCommit: candidate, event: 'pull_request', status: 'completed', conclusion: 'success' },
      policy: { current: true, strict: true, rulesetEvidence: 'successful-empty', effectiveRuleCount: 0, requiredContexts: [{ context: 'Crosswake CI', appId: 15368, sources: ['branch_protection'] }], branchProtectionFingerprint: 'a'.repeat(64), effectiveRulesFingerprint: 'b'.repeat(64) },
      canonicalBaseCommit: base,
      barrierStable: true,
    },
  };
}

test('accepts final local --all proof only for the exact observed hosted merge OID', () => {
  const result = joinProof(proofFixture());
  assert.equal(result.status, 'pass');
  assert.equal(result.source.commit, oid('a'));
  assert.equal(result.requirements.MAINT_07, 'passed');
  assert.equal(result.requirements.MAINT_08, 'passed');
  assert.equal(result.candidateState, 'open-unmerged');
});

test('rejects equal-tree proof when the local commit differs from runner checkout', () => {
  const fixture = proofFixture();
  fixture.local.source.commit = oid('9');
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'source_commit_mismatch');
});

test('rejects a prior hosted attempt even when its jobs were green', () => {
  const fixture = proofFixture();
  fixture.live.run.attempt = 2;
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'hosted_attempt_drift');
});

test('rejects preliminary local proof even when all nine stages passed', () => {
  const fixture = proofFixture();
  fixture.local.kind = 'preliminary';
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'local_proof_incomplete');
});

test('rejects incomplete --all stage and log evidence', () => {
  const fixture = proofFixture();
  fixture.local.stages.pop();
  fixture.local.executedLogCount = 7;
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'local_proof_incomplete');
});

test('rejects fabricated or incomplete private capture integrity', () => {
  const fixture = proofFixture();
  fixture.local.privateIntegrity.retainedCapturesValid = false;
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'private_capture_integrity_failed');
});

test('classifies a stale private invocation projection as local raw evidence drift', () => {
  const current = proofFixture().local;
  const stale = structuredClone(current);
  stale.runId = 'earlier-attempt';
  assert.throws(() => verifyCurrentLocalProjection(stale, current, current), /local_raw_evidence_invalid/);
});

test('rejects a missing, duplicate, or unauthorized hosted graph row', () => {
  const fixture = proofFixture();
  fixture.hosted.requiredJobs.pop();
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'hosted_graph_incomplete');
});

test('counts contract-declared advisory rows without treating them as required proof jobs', () => {
  const fixture = proofFixture();
  const result = joinProof(fixture);
  assert.equal(result.status, 'pass');
  assert.equal(result.hosted.jobCount, 49);
  assert.equal(result.hosted.checkCount, 49);
  assert.equal(result.hosted.advisoryJobCount, 1);
  assert.equal(result.hosted.requiredJobCount, 48);
});

test('rejects missing or unclassified advisory evidence', () => {
  const missing = proofFixture();
  missing.local.privateIntegrity.advisoryJobs = [];
  assert.equal(joinProof(missing).cause, 'hosted_graph_incomplete');

  const unexpected = proofFixture();
  unexpected.local.privateIntegrity.advisoryJobs[0].name = 'unclassified-job';
  assert.equal(joinProof(unexpected).cause, 'hosted_graph_incomplete');

  const duplicateIdentity = proofFixture();
  duplicateIdentity.local.privateIntegrity.advisoryJobs[0].jobId = duplicateIdentity.hosted.requiredJobs[0].jobId;
  assert.equal(joinProof(duplicateIdentity).cause, 'hosted_graph_incomplete');
});

test('rejects stale PR, changed base, or missing current policy evidence', () => {
  const fixture = proofFixture();
  fixture.live.pullRequest.headCommit = oid('8');
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'live_pull_request_drift');
});

test('rejects a changed current policy even when the hosted record was green', () => {
  const fixture = proofFixture();
  fixture.live.policy.requiredContexts = [];
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'live_policy_drift');
});

test('rejects a changed canonical merge ref with identical PR head and base', () => {
  const fixture = proofFixture();
  fixture.live.pullRequest.mergeCommitSha = oid('c');
  fixture.live.mergeRef.oid = oid('c');
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'live_pull_request_drift');
});

test('requires the canonical repository, both repository owners, and a stable end-read barrier', () => {
  const wrongRepo = proofFixture();
  wrongRepo.live.pullRequest.headRepo = 'attacker/fork';
  assert.equal(joinProof(wrongRepo).cause, 'live_pull_request_drift');

  const unstable = proofFixture();
  unstable.live.barrierStable = false;
  assert.equal(joinProof(unstable).cause, 'hosted_attempt_drift');
});

test('compares full policy fingerprints so same-count ruleset changes are blocked', () => {
  const fixture = proofFixture();
  fixture.live.policy.effectiveRulesFingerprint = 'c'.repeat(64);
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'live_policy_drift');
});

test('accepts a failed advisory workflow conclusion when the required graph remains green', () => {
  const fixture = proofFixture();
  fixture.live.run.conclusion = 'failure';
  fixture.local.privateIntegrity.advisoryJobs[0].conclusion = 'failure';
  const result = joinProof(fixture);
  assert.equal(result.status, 'pass');
});

test('rejects a failed required workflow conclusion even if the supplied job rows claim success', () => {
  const fixture = proofFixture();
  fixture.live.run.conclusion = 'failure';
  fixture.local.privateIntegrity.advisoryJobs[0].conclusion = 'success';
  fixture.local.privateIntegrity.requiredGraphGreen = false;
  const result = joinProof(fixture);
  assert.equal(result.status, 'blocked');
  assert.equal(result.cause, 'hosted_attempt_drift');
});

test('production live adapter pins the canonical GitHub host and preserves private subprocess evidence', () => {
  const adapter = liveAdapterFixture();
  try {
    const live = adapter.read();
    const calls = adapter.calls();
    const githubCalls = calls.filter((row) => row.args.includes('api'));
    const gitCall = live.captures.find((row) => row.executable === 'git-fixture');
    assert.equal(live.barrierStable, true);
    assert.equal(live.pullRequest.repo, 'szTheory/crosswake');
    assert.equal(live.mergeRef.ref, 'refs/pull/238/merge');
    assert.equal(githubCalls.length, 10);
    assert.ok(githubCalls.every((row) => row.args[0] === '--hostname' && row.args[1] === 'github.com'));
    assert.deepEqual(gitCall.args, ['ls-remote', 'https://github.com/szTheory/crosswake.git', 'refs/pull/238/merge']);
    assert.equal(live.captures.length, 12);
    for (const capture of live.captures) {
      for (const field of ['stdout', 'stderr', 'status']) assert.equal(fs.statSync(capture[field]).mode & 0o777, 0o600);
    }
  } finally {
    adapter.dispose();
  }
});

function joinWithAdapter(live, expectedPolicy) {
  const fixture = proofFixture();
  fixture.live = live;
  fixture.hosted.run.checkSuiteId = live.run.checkSuiteId;
  fixture.local.privateIntegrity.ciPolicyFingerprints = expectedPolicy;
  return joinProof(fixture);
}

test('production adapter merge-ref drift blocks despite unchanged PR head and base', () => {
  const adapter = liveAdapterFixture();
  try {
    const retained = adapter.read();
    const drifted = adapter.read({ mergeOid: 'cccccccccccccccccccccccccccccccccccccccc' });
    assert.equal(drifted.pullRequest.headCommit, retained.pullRequest.headCommit);
    assert.equal(drifted.pullRequest.baseCommit, retained.pullRequest.baseCommit);
    const result = joinWithAdapter(drifted, {
      branchProtection: retained.policy.branchProtectionFingerprint,
      effectiveRules: retained.policy.effectiveRulesFingerprint,
    });
    assert.equal(result.cause, 'live_pull_request_drift');
  } finally {
    adapter.dispose();
  }
});

test('production adapter rejects same-count full-policy drift against retained CI pages', () => {
  const adapter = liveAdapterFixture();
  try {
    const retained = adapter.read();
    const changed = adapter.read({ policyChanged: true });
    assert.equal(changed.policy.effectiveRuleCount, retained.policy.effectiveRuleCount);
    assert.deepEqual(changed.policy.requiredContexts, retained.policy.requiredContexts);
    assert.equal(changed.barrierStable, true);
    const result = joinWithAdapter(changed, {
      branchProtection: retained.policy.branchProtectionFingerprint,
      effectiveRules: retained.policy.effectiveRulesFingerprint,
    });
    assert.equal(result.cause, 'live_policy_drift');
  } finally {
    adapter.dispose();
  }
});

test('production adapter end barrier rejects a hosted attempt that changes during collection', () => {
  const adapter = liveAdapterFixture();
  try {
    const live = adapter.read({ attemptDrift: true });
    assert.equal(live.barrierStable, false);
    const result = joinWithAdapter(live, {
      branchProtection: live.policy.branchProtectionFingerprint,
      effectiveRules: live.policy.effectiveRulesFingerprint,
    });
    assert.equal(result.cause, 'hosted_attempt_drift');
  } finally {
    adapter.dispose();
  }
});

test('production adapter rejects a noncanonical PR head repository', () => {
  const adapter = liveAdapterFixture();
  try {
    const live = adapter.read({ wrongRepo: true });
    assert.equal(live.pullRequest.headRepo, 'elsewhere/fork');
    assert.equal(joinWithAdapter(live, {
      branchProtection: live.policy.branchProtectionFingerprint,
      effectiveRules: live.policy.effectiveRulesFingerprint,
    }).status, 'blocked');
  } finally {
    adapter.dispose();
  }
});

test('never places private paths or raw runner output in the acceptance projection', () => {
  const fixture = proofFixture();
  const result = joinProof(fixture);
  assert.equal(JSON.stringify(result).includes('/private/tmp'), false);
  assert.equal(JSON.stringify(result).includes('rawOutput'), false);
});
