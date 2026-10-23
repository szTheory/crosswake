import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import {
  ALLOWED_PATHS, prepareProposal, deliverProposal, validateSources, publicProposalSafe,
} from './proposal_delivery.mjs';
import { normalizePolicy } from './ci_evidence.mjs';

const REPO = 'szTheory/crosswake';
const hex = n => crypto.createHash('sha1').update(n).digest('hex');
function command(bin, args, cwd) {
  const r = spawnSync(bin, args, { cwd, encoding: 'utf8' });
  assert.equal(r.status, 0, `${bin} ${args.join(' ')} failed: ${r.stderr}`);
  return r.stdout.trim();
}
function putJson(file, value, mode = 0o644) {
  fs.mkdirSync(path.dirname(file), { recursive: true, mode: 0o700 });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, { mode });
  fs.chmodSync(file, mode);
}
function fixture(t, tweak = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-delivery-'));
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  const repo = path.join(root, 'delivery'); fs.mkdirSync(repo);
  command('git', ['init', '-q', repo], root);
  command('git', ['-C', repo, 'config', 'user.name', 'Fixture'], root);
  command('git', ['-C', repo, 'config', 'user.email', 'fixture@example.invalid'], root);
  fs.writeFileSync(path.join(repo, 'README.md'), 'fixture\n');
  command('git', ['-C', repo, 'add', '.'], root); command('git', ['-C', repo, 'commit', '-qm', 'base'], root);
  const base = command('git', ['-C', repo, 'rev-parse', 'HEAD'], root);
  const baseTree = command('git', ['-C', repo, 'rev-parse', 'HEAD^{tree}'], root);
  const baseBranch = command('git', ['-C', repo, 'branch', '--show-current'], root);
  command('git', ['-C', repo, 'checkout', '-qb', 'maintenance/phase178-fixture'], root);
  const paths = ALLOWED_PATHS;
  for (const rel of paths) {
    const file = path.join(repo, rel); fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, `change ${rel}\n`);
  }
  command('git', ['-C', repo, 'add', '--', ...paths], root); command('git', ['-C', repo, 'commit', '-qm', 'candidate'], root);
  const head = command('git', ['-C', repo, 'rev-parse', 'HEAD'], root);
  const tree = command('git', ['-C', repo, 'rev-parse', 'HEAD^{tree}'], root);
  const expectedBase = tweak.wrongBase ? hex('wrong-base') : base;
  const selected = [...paths];
  const proofRoot = path.join(root, 'proof');
  command('git', ['clone', '-q', '--no-hardlinks', repo, proofRoot], root);
  const owner = path.join(root, 'private'); fs.mkdirSync(owner, { mode: 0o700 }); fs.chmodSync(owner, 0o700);
  const candidate = { schemaVersion: 2, phase: 178, plan: '01', candidateCommit: head, candidateTree: tree, sourceBaseCommit: expectedBase, sourceBaseTree: baseTree, selectedPaths: selected, deliveryRoot: repo, proofRoot };
  const proofCapture = path.join(owner, 'proof-capture'); fs.mkdirSync(proofCapture, { mode: 0o700 });
  const runRoot = path.join(proofCapture, 'run'); fs.mkdirSync(runRoot, { mode: 0o700 }); fs.mkdirSync(path.join(runRoot, 'logs'), { mode: 0o700 });
  const stages = ['repository-preflight', 'root-proof', 'example-host-proof', 'browser-proof', 'ios-package-proof', 'android-package-proof', 'format-proof', 'warnings-proof', 'repository-cleanliness'];
  const stageText = stages.map(s => `PASS ${s}`).join('\n') + '\n';
  const stdoutPath = path.join(proofCapture, 'run.stdout'); const stderrPath = path.join(proofCapture, 'run.stderr'); const statusPath = path.join(proofCapture, 'run.status');
  fs.writeFileSync(stdoutPath, stageText, { mode: 0o600 }); fs.writeFileSync(stderrPath, '', { mode: 0o600 }); fs.writeFileSync(statusPath, '0', { mode: 0o600 });
  for (const stage of stages.slice(1)) fs.writeFileSync(path.join(runRoot, 'logs', `${stage}.log`), 'status=0\n', { mode: 0o600 });
  fs.writeFileSync(path.join(runRoot, 'git-before.z'), '', { mode: 0o600 }); fs.writeFileSync(path.join(runRoot, 'git-final.z'), '', { mode: 0o600 });
  const indexPath = command('git', ['-C', proofRoot, 'rev-parse', '--path-format=absolute', '--git-path', 'index'], root);
  const indexBytes = fs.readFileSync(indexPath); const indexHash = crypto.createHash('sha256').update(indexBytes).digest('hex');
  const entryHash = crypto.createHash('sha256').update(spawnSync('git', ['-C', proofRoot, 'ls-files', '--stage', '-z'], { encoding: null }).stdout).digest('hex');
  const supplemental = {};
  for (const slot of ['before', 'after']) {
    const rawIndexPath = path.join(owner, `proof-index-${slot}.bin`); fs.writeFileSync(rawIndexPath, indexBytes, { mode: 0o600 });
    const statusFile = path.join(owner, `proof-status-${slot}.z`); fs.writeFileSync(statusFile, '', { mode: 0o600 });
    const ignoredPath = path.join(owner, `proof-ignored-${slot}.z`); fs.writeFileSync(ignoredPath, '', { mode: 0o600 });
    const metaPath = path.join(owner, `proof-${slot}.json`);
    putJson(metaPath, { head, tree, indexSha256: indexHash, indexEntriesSha256: entryHash, rawIndexPath, statusPath: statusFile, ignoredPath }, 0o600);
    supplemental[slot] = { metaPath, rawIndexPath, statusFile, ignoredPath };
  }
  const invocationRecord = path.join(proofCapture, 'invocation.json');
  putJson(invocationRecord, { schemaVersion: 1, run: { status: 0, id: 'fixture-run', sourceRoot: proofRoot, repoRoot: proofRoot, runRoot, captureRoot: proofCapture, stdoutPath, stderrPath, facadeStatusPath: statusPath }, source: { commit: head, tree, candidateCommit: head, candidateTree: tree, indexSha256: indexHash, indexEntriesSha256: entryHash }, sourceAfter: { commit: head, tree, indexSha256: indexHash, indexEntriesSha256: entryHash }, supplemental: { beforePath: supplemental.before.metaPath, afterPath: supplemental.after.metaPath } }, 0o600);
  const proof = { schemaVersion: 1, phase: 178, plan: '02', kind: 'preliminary', candidateCommit: head, candidateTree: tweak.staleProof ? hex('stale') : tree, selectedPaths: selected, stageCount: 9, executedLogCount: 8, proofRoot, runRoot, captureRoot: proofCapture, invocationId: 'fixture-run', invocationRecord, sourceBefore: { commit: head, tree, indexSha256: indexHash, indexEntriesSha256: entryHash, rawIndexPath: supplemental.before.rawIndexPath }, sourceAfter: { commit: head, tree, indexSha256: indexHash, indexEntriesSha256: entryHash, rawIndexPath: supplemental.after.rawIndexPath } };
  const branchProtection = { strict: true, contexts: ['Crosswake CI', 'Secondary CI'], checks: [{ context: 'Crosswake CI', app_id: 15368 }] };
  const effectiveRules = [[{ id: 1, type: 'deletion' }]];
  const normalized = normalizePolicy([branchProtection], effectiveRules);
  const workflowBlob = 'a'.repeat(40);
  const ci = { schemaVersion: 1, phase: 178, plan: '03', candidateCommit: head, candidateTree: tree, selectedPaths: selected, workflow: { repository: REPO, path: '.github/workflows/crosswake-ci.yml', id: 353403178, checkoutActionPins: ['abc', 'def'] }, policy: { targetBase: 'main', normalized } };
  const rawValues = { branchProtection: [branchProtection], effectiveRules, workflowIdentity: [{ id: 353403178, path: '.github/workflows/crosswake-ci.yml', state: 'active' }], currentMain: [{ sha: expectedBase }], workflowBlob: `${workflowBlob}\n` };
  const rawResponsePointers = {}; const rawResponseIntegrity = {};
  for (const [name, value] of Object.entries(rawValues)) {
    const stdout = Buffer.from(name === 'workflowBlob' ? value : JSON.stringify(value)); const stderr = Buffer.alloc(0); const status = Buffer.from('0');
    const files = {};
    for (const [suffix, bytes] of Object.entries({ stdout, stderr, status })) { const file = path.join(owner, `ci-${name}-${suffix}.bin`); fs.writeFileSync(file, bytes, { mode: 0o600 }); files[suffix] = file; }
    const hash = b => crypto.createHash('sha256').update(b).digest('hex');
    rawResponsePointers[name] = { ...files, stdoutBytes: stdout.length, stderrBytes: 0, stdoutSha256: hash(stdout), stderrSha256: hash(stderr), statusSha256: hash(status) };
    rawResponseIntegrity[name] = { status: 0, stdoutBytes: stdout.length, stderrBytes: 0, stdoutSha256: hash(stdout), stderrSha256: hash(stderr), statusSha256: hash(status) };
  }
  ci.rawResponsePointers = rawResponsePointers; ci.rawResponseIntegrity = { ...rawResponseIntegrity, verifiedAgainstNormalizedValues: true };
  putJson(path.join(owner, 'candidate-binding-renewed.json'), candidate, 0o600);
  putJson(path.join(owner, 'local-proof-binding.json'), proof, 0o600);
  putJson(path.join(owner, 'ci-policy-binding.json'), ci, 0o600);
  const sourceFile = path.join(root, 'candidate-source.json');
  const proofFile = path.join(root, 'preliminary-local-proof.json');
  const contractFile = path.join(root, 'ci-contract.json');
  putJson(sourceFile, { schemaVersion: 1, phase: 178, plan: '01', status: 'source-qualified', sourceBaseCommit: expectedBase, sourceBaseTree: baseTree, candidateCommit: head, candidateTree: tree, selectedPaths: selected, selectedCount: 8, canonicalMainMatchesBase: true });
  putJson(proofFile, { schemaVersion: 1, phase: 178, plan: '02', kind: 'preliminary', status: 'pass', source: { commit: head, tree }, stageCount: 9, executedLogCount: 8, stages: stages.map(purpose => ({ purpose, result: 'PASS' })), ignoredArtifacts: { beforeCount: 0, afterCount: 0, newCount: 0 } });
  putJson(contractFile, { schemaVersion: 1, status: 'policy-observed-source-contract-ready-for-run', repository: REPO, candidate: { baseCommit: expectedBase, commit: head, tree, selectedPathCount: 8 }, workflow: { path: ci.workflow.path, id: ci.workflow.id, source: { version: head, blobOid: workflowBlob } }, policy: { branchProtection: { strict: true }, effectiveRules: { state: normalized.rulesetEvidence, ruleCount: normalized.effectiveRuleCount } } });
  if (tweak.extraPath) {
    fs.writeFileSync(path.join(repo, 'unexpected.txt'), 'extra'); command('git', ['-C', repo, 'add', 'unexpected.txt'], root); command('git', ['-C', repo, 'commit', '-qm', 'extra'], root);
  }
  const gh = path.join(root, 'gh');
  const bareRemote = path.join(root, 'remote.git'); command('git', ['init', '--bare', '-q', bareRemote], root);
  const policy = branchProtection;
  const ghScript = `#!/usr/bin/env node
const fs=require("node:fs");const a=process.argv.slice(2);const route=a[a.length-1];const branch="maintenance/phase178-${head.slice(0,12)}";
if(a[0]==="pr"&&a[1]==="create"){if(process.env.FIXTURE_CREATE_RESULT==="error"){process.stderr.write("remote response lost\\n");process.exit(1)}if(a.includes("--body")||!a.includes("--body-file")){process.stderr.write("body-file contract missing\\n");process.exit(2)}const bodyFile=a[a.indexOf("--body-file")+1];const st=fs.statSync(bodyFile);if((st.mode&511)!==384){process.stderr.write("body-file permissions invalid\\n");process.exit(2)}const arg=(n)=>a[a.indexOf(n)+1];const pr={id:42,number:42,state:"open",title:arg("--title"),body:process.env.FIXTURE_PR_MISMATCH==="true"?"changed body":fs.readFileSync(bodyFile,"utf8"),html_url:"https://github.com/${REPO}/pull/42",head:{ref:branch,sha:"${head}",repo:{full_name:"${REPO}"}},base:{ref:"main",sha:"${base}",repo:{full_name:"${REPO}"}}};fs.writeFileSync(process.env.FIXTURE_PR_STATE,JSON.stringify(process.env.FIXTURE_DUPLICATE_PR==="true"?[pr,{...pr,id:43,number:43}]:[pr]));process.stdout.write("https://github.com/${REPO}/pull/42\\n");process.exit(0)}
if(a[0]!=="api"){process.stderr.write("unsupported command\\n");process.exit(2)}
if(route==="repos/${REPO}")process.stdout.write(JSON.stringify({full_name:"${REPO}",default_branch:"main"}));
else if(route==="repos/${REPO}/branches/main")process.stdout.write(JSON.stringify({name:"main",commit:{sha:"${base}"}}));
else if(route==="repos/${REPO}/branches/main/protection/required_status_checks"){const p=${JSON.stringify(policy)};if(process.env.FIXTURE_POLICY_ALT==="true")p.contexts[1]="Other CI";process.stdout.write(JSON.stringify([p]))}
else if(route==="repos/${REPO}/rules/branches/main?per_page=100")process.stdout.write(JSON.stringify([[{id:1,type:process.env.FIXTURE_POLICY_ALT==="true"?"creation":"deletion"}]]));
else if(route.startsWith("repos/${REPO}/pulls?")){const data=fs.existsSync(process.env.FIXTURE_PR_STATE)?JSON.parse(fs.readFileSync(process.env.FIXTURE_PR_STATE,"utf8")):[];process.stdout.write(JSON.stringify([data]))}
else if(route.startsWith("repos/${REPO}/branches/"+branch)&&((process.env.FIXTURE_BRANCH_COLLISION==="true")||(process.env.FIXTURE_BRANCH_EXISTS==="true")||fs.existsSync(process.env.FIXTURE_PUSHED))){process.stdout.write(JSON.stringify({name:branch,commit:{sha:process.env.FIXTURE_BRANCH_SHA||"${head}"}}))}
else if(route.startsWith("repos/${REPO}/branches/"+branch)){process.stderr.write("HTTP 404: Not Found\\n");process.exit(1)}
else {process.stderr.write("HTTP 403: Resource not accessible by integration\\n");process.exit(1)}`;
  fs.writeFileSync(gh, ghScript, { mode: 0o700 }); fs.chmodSync(gh, 0o700);
  const gitWrapper = path.join(root, 'git-wrapper.cjs');
  fs.writeFileSync(gitWrapper, `#!/usr/bin/env node\nconst fs=require("node:fs");const {spawnSync}=require("node:child_process");const a=process.argv.slice(2);if(a.includes("push")&&process.env.FIXTURE_PUSH_RESULT==="error"){process.stderr.write("push response lost\\n");process.exit(1)}const r=spawnSync("git",a,{stdio:"inherit",env:process.env});if(a.includes("push")&&r.status===0&&process.env.FIXTURE_PUSHED)fs.writeFileSync(process.env.FIXTURE_PUSHED,"yes");process.exit(r.status??1);`, { mode: 0o700 }); fs.chmodSync(gitWrapper, 0o700);
  return { root, repo, owner, sourceFile, proofFile, contractFile, gh, gitWrapper, bareRemote, head, tree, base, baseTree, baseBranch, paths, proofRoot, proofCapture, runRoot, supplemental, branchCollision: tweak.branchCollision === true };
}

function deliveryFixtureOptions(f, extraEnv = {}) {
  const proposalFile = path.join(f.root, 'maintenance-proposal.json');
  const observationFile = path.join(f.root, 'delivery-observation.json');
  const env = { ...process.env, FIXTURE_PR_STATE: path.join(f.root, 'pr-state.json'), FIXTURE_EXPECTED_HEAD: f.head, FIXTURE_PUSHED: path.join(f.root, 'pushed'), FIXTURE_BRANCH_COLLISION: f.branchCollision ? 'true' : 'false', ...extraEnv };
  return { ...f, privateRoot: f.owner, sourceFile: f.sourceFile, proofFile: f.proofFile, contractFile: f.contractFile, outputFile: proposalFile, proposalFile, observationFile, gitBin: f.gitWrapper, ghBin: f.gh, env, fixtureMode: true, remoteUrl: f.bareRemote };
}

test('source join accepts exact renewed eight-path candidate and preliminary evidence', t => {
  const f = fixture(t);
  const result = validateSources({ ...f, privateRoot: f.owner, gitBin: 'git' });
  assert.equal(result.candidate.candidateCommit, f.head);
  assert.deepEqual(result.paths, [...ALLOWED_PATHS]);
});

test('production preparation uses real git and gh subprocess output and writes a privacy-safe proposal', async t => {
  const f = fixture(t);
  const result = await prepareProposal({ ...f, privateRoot: f.owner, sourceFile: f.sourceFile, proofFile: f.proofFile, contractFile: f.contractFile, outputFile: path.join(f.root, 'maintenance-proposal.json'), gitBin: f.gitWrapper, ghBin: f.gh, baseCommit: f.base, canonicalUrl: 'https://github.com/szTheory/crosswake.git' });
  assert.equal(result.proposal.status, 'ready-for-scoped-authorization');
  assert.equal(result.proposal.target.head, f.head);
  assert.equal(result.proposal.diff.pathCount, 8);
  assert.equal(result.proposal.validation.stagesPassed, 9);
  assert.equal(publicProposalSafe(result.proposal), true);
  assert.deepEqual(result.proposal.action.pushArgv, ['git', 'push', 'https://github.com/szTheory/crosswake.git', `${f.head}:refs/heads/${result.proposal.target.branch}`]);
  assert.equal(result.proposal.action.pullRequest.argv[result.proposal.action.pullRequest.argv.indexOf('--repo') + 1], 'github.com/szTheory/crosswake');
  assert.equal(result.proposal.action.pullRequest.repo, 'github.com/szTheory/crosswake');
  assert.ok(result.proposal.action.pullRequest.body.includes('230 ledger keys, 52 frozen rows'));
  const saved = JSON.parse(fs.readFileSync(path.join(f.root, 'maintenance-proposal.json')));
  assert.deepEqual(saved, result.proposal);
  assert.equal(fs.statSync(path.join(f.root, 'maintenance-proposal.json')).mode & 0o777, 0o644);
});

test('re-preparation archives the prior undisplayed card and binding by unique attempt id', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f); const first = await prepareProposal(options); const oldId = first.proposal.proposalId;
  const second = await prepareProposal(options);
  assert.notEqual(second.proposal.proposalId, oldId);
  assert.ok(fs.existsSync(`${options.outputFile}.superseded-undisplayed-${oldId}.json`));
  assert.ok(fs.existsSync(path.join(f.owner, `delivery-binding.json.superseded-undisplayed-${oldId}.json`)));
  assert.equal(JSON.parse(fs.readFileSync(options.observationFile)).remoteWrites, 0);
});

for (const [label, tweak, expected] of [
  ['wrong base', { wrongBase: true }, 'wrong-base'],
  ['extra path', { extraPath: true }, 'path-set-mismatch'],
  ['stale proof', { staleProof: true }, 'proof-mismatch'],
]) test(`blocks ${label}`, t => {
  const f = fixture(t, tweak);
  assert.throws(() => validateSources({ ...f, privateRoot: f.owner, gitBin: 'git' }), e => e.safeCause === expected);
});

test('blocks a preexisting remote branch before writing a proposal', async t => {
  const f = fixture(t, { branchCollision: true });
  await assert.rejects(prepareProposal({ ...f, privateRoot: f.owner, sourceFile: f.sourceFile, proofFile: f.proofFile, contractFile: f.contractFile, outputFile: path.join(f.root, 'proposal.json'), gitBin: f.gitWrapper, ghBin: f.gh, env: { ...process.env, FIXTURE_BRANCH_COLLISION: 'true' } }), e => e.safeCause === 'branch-collision');
  assert.equal(fs.existsSync(path.join(f.root, 'proposal.json')), false);
});

test('blocks inaccessible policy reads with an actionable safe cause', async t => {
  const f = fixture(t);
  const denied = path.join(f.root, 'denied-gh');
  fs.writeFileSync(denied, '#!/bin/sh\necho "HTTP 403: Resource not accessible by integration" >&2\nexit 1\n', { mode: 0o700 });
  fs.chmodSync(denied, 0o700);
  await assert.rejects(prepareProposal({ ...f, privateRoot: f.owner, sourceFile: f.sourceFile, proofFile: f.proofFile, contractFile: f.contractFile, outputFile: path.join(f.root, 'proposal.json'), gitBin: f.gitWrapper, ghBin: denied, baseCommit: f.base, canonicalUrl: 'https://github.com/szTheory/crosswake.git' }), e => e.safeCause === 'policy-read-inaccessible');
});

test('no decision leaves the one-use binding untouched; hold is bound to this displayed attempt', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f); await prepareProposal(options);
  const binding = path.join(f.owner, 'delivery-binding.json'); const before = fs.readFileSync(binding);
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: false }), e => e.safeCause === 'missing-authority');
  assert.deepEqual(fs.readFileSync(binding), before);
  const held = await deliverProposal({ ...options, decision: 'hold' });
  assert.equal(held.status, 'held'); assert.equal(held.remoteWrites, 0);
  assert.equal(JSON.parse(fs.readFileSync(binding)).state, 'held');
});

test('authorized fixture flow consumes the exact binding before one push and PR, then reads back the exact PR', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f); await prepareProposal(options); const pushInfo = [];
  let result; try { result = await deliverProposal({ ...options, onPushResult: x => pushInfo.push(x), decision: 'allow', authorized: true }); } catch (e) { assert.fail(`${e.safeCause}; fixture push=${JSON.stringify(pushInfo)}`); }
  assert.equal(result.status, 'delivered-awaiting-hosted-ci');
  assert.equal(result.pullRequest.number, 42); assert.equal(result.remoteWrites.push, 'confirmed'); assert.equal(result.remoteWrites.pullRequestCreate, 'confirmed-by-readback');
  assert.equal(JSON.parse(fs.readFileSync(path.join(f.owner, 'delivery-binding.json'))).state, 'delivered');
  const displayed = JSON.parse(fs.readFileSync(options.proposalFile));
  for (const [kind, expectedArgv] of [['push', displayed.action.pushArgv], ['pull-request', undefined]]) {
    const operationFile = path.join(f.owner, `delivery-operation-${displayed.proposalId}-${kind}.json`);
    assert.equal(fs.statSync(operationFile).mode & 0o777, 0o600);
    const operation = JSON.parse(fs.readFileSync(operationFile));
    assert.equal(operation.state, 'consumed-and-reconciled');
    if (kind === 'push') assert.deepEqual(operation.argv, expectedArgv);
    else {
      assert.deepEqual(operation.argv.slice(0, -2), displayed.action.pullRequest.argv);
      assert.equal(operation.argv.at(-2), '--body-file');
      assert.equal(operation.bodyFile, operation.argv.at(-1));
      assert.equal(operation.bodyBytes, Buffer.byteLength(displayed.action.pullRequest.body));
      assert.equal(operation.bodySha256, crypto.createHash('sha256').update(displayed.action.pullRequest.body).digest('hex'));
      assert.equal(fs.readFileSync(operation.bodyFile, 'utf8'), displayed.action.pullRequest.body);
      assert.equal(fs.statSync(operation.bodyFile).mode & 0o777, 0o600);
    }
  }
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: true }), e => e.safeCause === 'binding-consumed');
});

test('uncertain PR delivery is read-reconciled once and never retried', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f, { FIXTURE_CREATE_RESULT: 'error' }); await prepareProposal(options);
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: true }), e => e.safeCause === 'uncertain-delivery');
  const binding = JSON.parse(fs.readFileSync(path.join(f.owner, 'delivery-binding.json')));
  assert.equal(binding.consumed, true); assert.equal(binding.state, 'pull-request-attempted');
  const observation = JSON.parse(fs.readFileSync(options.observationFile));
  assert.equal(observation.status, 'pull-request-outcome-uncertain'); assert.equal(observation.remoteWrites, 'possible');
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: true }), e => e.safeCause === 'binding-consumed');
});

test('duplicate exact PR observations block after one consumed operation', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f, { FIXTURE_DUPLICATE_PR: 'true' }); await prepareProposal(options);
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: true }), e => e.safeCause === 'branch-collision');
  assert.equal(JSON.parse(fs.readFileSync(path.join(f.owner, 'delivery-binding.json'))).consumed, true);
});

test('rejects nested private keys, user paths, and token sentinels', () => {
  assert.equal(publicProposalSafe({ card: { nested: { capturePath: '/tmp/private' } } }), false);
  assert.equal(publicProposalSafe({ card: { details: 'diagnostic <home>/Library/secret' } }), false);
  assert.equal(publicProposalSafe({ card: { details: 'ghp_1234567890abcdefghijklmnop' } }), false);
});

test('proof raw index or retained log tampering fails closed', t => {
  for (const field of ['raw-index', 'stage-log']) {
    const f = fixture(t);
    const file = field === 'raw-index' ? f.supplemental.after.rawIndexPath : path.join(f.runRoot, 'logs', 'root-proof.log');
    if (field === 'stage-log') fs.writeFileSync(file, 'status=1\n', { mode: 0o600 }); else fs.appendFileSync(file, 'tamper'); fs.chmodSync(file, 0o600);
    assert.throws(() => validateSources({ ...f, privateRoot: f.owner }), e => ['proof-mismatch', 'private-permissions'].includes(e.safeCause));
  }
});

test('tampered CI raw capture fails its private integrity join', t => {
  const f = fixture(t);
  const ci = JSON.parse(fs.readFileSync(path.join(f.owner, 'ci-policy-binding.json')));
  fs.appendFileSync(ci.rawResponsePointers.effectiveRules.stdout, 'tamper');
  assert.throws(() => validateSources({ ...f, privateRoot: f.owner }), e => e.safeCause === 'policy-mismatch');
});

test('changed branch context and effective rule with the same count block before consuming authority', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f); await prepareProposal(options); options.env.FIXTURE_POLICY_ALT = 'true';
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: true }), e => e.safeCause === 'policy-mismatch');
  assert.equal(JSON.parse(fs.readFileSync(path.join(f.owner, 'delivery-binding.json'))).consumed, false);
});

test('push exit zero with a mismatched remote SHA records a possible write and does not create a PR', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f, { FIXTURE_BRANCH_SHA: hex('wrong-remote-sha') }); await prepareProposal(options);
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: true }), e => e.safeCause === 'verification-failed');
  const observation = JSON.parse(fs.readFileSync(options.observationFile));
  assert.equal(observation.status, 'push-not-confirmed'); assert.equal(observation.remoteWrites, 'possible');
  assert.equal(fs.existsSync(path.join(f.root, 'pr-state.json')), false);
});

test('push error is reconciled once and persists possible-write state', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f, { FIXTURE_PUSH_RESULT: 'error' }); await prepareProposal(options);
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: true }), e => e.safeCause === 'uncertain-delivery');
  const observation = JSON.parse(fs.readFileSync(options.observationFile));
  assert.equal(observation.status, 'push-not-confirmed'); assert.equal(observation.remoteWrites, 'possible');
});

test('a mismatched PR body is retained as an attempted uncertain observation', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f, { FIXTURE_PR_MISMATCH: 'true' }); await prepareProposal(options);
  await assert.rejects(deliverProposal({ ...options, decision: 'allow', authorized: true }), e => e.safeCause === 'verification-failed');
  const observation = JSON.parse(fs.readFileSync(options.observationFile));
  assert.equal(observation.status, 'pull-request-mismatch'); assert.equal(observation.remoteWrites, 'possible');
});

test('concurrent delivery calls can claim a displayed attempt only once', async t => {
  const f = fixture(t); const options = deliveryFixtureOptions(f); await prepareProposal(options);
  const results = await Promise.allSettled([
    deliverProposal({ ...options, decision: 'allow', authorized: true }),
    deliverProposal({ ...options, decision: 'allow', authorized: true }),
  ]);
  assert.equal(results.filter(x => x.status === 'fulfilled').length, 1);
  assert.equal(results.filter(x => x.status === 'rejected').length, 1);
  assert.equal(results.find(x => x.status === 'rejected').reason.safeCause, 'binding-consumed');
});

test('refuses a write without a one-use binding and never includes private pointers in output', t => {
  const f = fixture(t);
  assert.equal(publicProposalSafe({ status: 'ready', ownerRoot: f.owner, privateCapture: '/private/log', patchBase64: 'secret' }), false);
});
