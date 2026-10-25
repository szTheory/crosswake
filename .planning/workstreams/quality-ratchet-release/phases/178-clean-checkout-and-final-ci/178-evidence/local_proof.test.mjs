import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import { execFileSync, spawnSync } from 'node:child_process';
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { test } from 'node:test';
import { candidateBinding as loadCandidateBinding, collect as collectProof, defaultProofOutput, finalSourceBinding as loadFinalSourceBinding, supplementalGitEnv, writeBlockedProjection } from './local_proof.mjs';

const HERE = path.dirname(new URL(import.meta.url).pathname);
const COLLECTOR = path.join(HERE, 'local_proof.mjs');
const POINTER = '/private/tmp/crosswake-178-owner-env';

function candidateSource() {
  return loadCandidateBinding().proofRoot;
}

function candidateIdentity() {
  const { candidateCommit, candidateTree } = loadCandidateBinding();
  return { candidateCommit, candidateTree };
}

function git(root, args) {
  return execFileSync('git', args, { cwd: root, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' }, encoding: 'buffer' });
}

function identity(root) {
  const indexPath = git(root, ['rev-parse', '--path-format=absolute', '--git-path', 'index']).toString('utf8').trim();
  const indexBytes = readFileSync(indexPath);
  return {
    head: git(root, ['rev-parse', 'HEAD']).toString('utf8').trim(),
    tree: git(root, ['rev-parse', 'HEAD^{tree}']).toString('utf8').trim(),
    indexSha256: createHash(indexBytes),
    indexEntriesSha256: createHash(git(root, ['ls-files', '--stage', '-z'])),
    indexBytes,
    status: git(root, ['status', '--porcelain=v1', '-z', '--untracked-files=all'])
  };
}

function createHash(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function fixtureRepo(parent) {
  const root = path.join(parent, 'repo');
  mkdirSync(root);
  execFileSync('git', ['init', '--quiet'], { cwd: root });
  execFileSync('git', ['config', 'user.email', 'local-proof@example.invalid'], { cwd: root });
  execFileSync('git', ['config', 'user.name', 'Local Proof Fixture'], { cwd: root });
  writeFileSync(path.join(root, '.gitignore'), 'ignored-build/\ntmp/\n');
  writeFileSync(path.join(root, 'tracked.txt'), 'fixture\n');
  execFileSync('git', ['add', '.gitignore', 'tracked.txt'], { cwd: root });
  execFileSync('git', ['commit', '--quiet', '-m', 'fixture'], { cwd: root });
  return root;
}

function setup() {
  const parent = mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-local-proof-test-'));
  chmodSync(parent, 0o700);
  const root = fixtureRepo(parent);
  const captureRoot = path.join(parent, 'capture');
  mkdirSync(captureRoot, { mode: 0o700 });
  const runRoot = path.join(captureRoot, 'crosswake-repository-verify.fixture');
  mkdirSync(runRoot, { mode: 0o700 });
  const sourceRoot = candidateSource();
  const sourceModule = pathToFileURL(path.join(sourceRoot, 'script/verify_repository.mjs')).href;
  const before = identity(root);
  const beforePath = path.join(captureRoot, 'supplemental-before.json');
  const afterPath = path.join(captureRoot, 'supplemental-after.json');
  const stdoutPath = path.join(captureRoot, 'invocation.stdout.log');
  const stderrPath = path.join(captureRoot, 'invocation.stderr.log');
  const recordPath = path.join(captureRoot, 'invocation.json');
  return { parent, root, captureRoot, runRoot, sourceRoot, sourceModule, before, beforePath, afterPath, stdoutPath, stderrPath, recordPath };
}

function harness(f, { mutate = null } = {}) {
  const sourceScript = `
    import fs from 'node:fs';
    import { pathToFileURL } from 'node:url';
    import { execFileSync } from 'node:child_process';
    const source = await import(${JSON.stringify(f.sourceModule)});
    const manifest = source.loadStageManifest();
    const workflowSource = fs.readFileSync(${JSON.stringify(path.join(f.sourceRoot, '.github/workflows/crosswake-ci.yml'))}, 'utf8');
    const versions = ${JSON.stringify({
      bash: 'GNU bash, version 5.2.0', git: 'git version 2.50.0', node: 'v22.14.0', elixir: 'Elixir 1.19.5', erl: '27', npm: '10.9.2', swift: 'Swift version 6.3.3', xcodebuild: 'Xcode 26.6', java: 'openjdk version "17.0.0"', 'gradle-wrapper': 'Gradle 8.7'
    })};
    const stages = [];
    const result = source.runVerification({
      selection: 'all', manifest, workflowSource, repoRoot: ${JSON.stringify(f.root)},
      runRoot: ${JSON.stringify(f.runRoot)}, captureRoot: ${JSON.stringify(f.captureRoot)},
      enforceArtifactPolicy: false,
      probe: tool => ({ stdout: versions[tool.tool] ?? '' }),
      spawn: (command, args, options) => {
        stages.push({ command, args, cwd: options.cwd });
        const stdout = 'child stdout from real facade seam\\n';
        const stderr = 'child stderr from real facade seam\\n';
        return { status: 0, stdout, stderr };
      }
    });
    const output = ${JSON.stringify(f.stdoutPath)};
    fs.writeFileSync(output, result.output + '\\n', { mode: 0o600 });
    fs.writeFileSync(${JSON.stringify(f.stderrPath)}, '', { mode: 0o600 });
    const statusPath = ${JSON.stringify(f.captureRoot)} + '/facade-status.txt';
    fs.writeFileSync(statusPath, String(result.status), { mode: 0o600 });
    fs.writeFileSync(${JSON.stringify(f.captureRoot)} + '/harness-stages.json', JSON.stringify(stages), { mode: 0o600 });
    console.log(result.output);
    process.exitCode = result.status;
  `;
  const run = spawnSync(process.execPath, ['--input-type=module', '-e', sourceScript], { encoding: 'utf8' });
  f.processOutput = `${run.stdout ?? ''}${run.stderr ?? ''}`;
  f.processStatus = run.status;
  if (mutate) mutate(f);
  const after = identity(f.root);
  writeFileSync(path.join(f.runRoot, 'supplemental-before.z'), f.before.status, { mode: 0o600 });
  writeFileSync(path.join(f.runRoot, 'supplemental-after.z'), after.status, { mode: 0o600 });
  const beforeRawIndexPath = path.join(f.captureRoot, 'supplemental-before.index');
  const afterRawIndexPath = path.join(f.captureRoot, 'supplemental-after.index');
  writeFileSync(beforeRawIndexPath, f.before.indexBytes, { mode: 0o600 });
  writeFileSync(afterRawIndexPath, after.indexBytes, { mode: 0o600 });
  const { indexBytes: _beforeIndexBytes, ...beforeSnapshot } = f.before;
  const { indexBytes: _afterIndexBytes, ...afterSnapshot } = after;
  const summary = { ...beforeSnapshot, statusPath: path.join(f.runRoot, 'supplemental-before.z'), ignoredPath: path.join(f.runRoot, 'ignored-before.z'), rawIndexPath: beforeRawIndexPath };
  const final = { ...afterSnapshot, statusPath: path.join(f.runRoot, 'supplemental-after.z'), ignoredPath: path.join(f.runRoot, 'ignored-after.z'), rawIndexPath: afterRawIndexPath };
  writeFileSync(f.beforePath, JSON.stringify(summary), { mode: 0o600 });
  writeFileSync(f.afterPath, JSON.stringify(final), { mode: 0o600 });
  const ignored = git(f.root, ['ls-files', '--others', '--ignored', '--exclude-standard', '-z']);
  writeFileSync(path.join(f.runRoot, 'ignored-before.z'), Buffer.alloc(0), { mode: 0o600 });
  writeFileSync(path.join(f.runRoot, 'ignored-after.z'), ignored, { mode: 0o600 });
  const record = {
    schemaVersion: 1,
    testFixture: true,
    source: { commit: f.before.head, tree: f.before.tree, indexSha256: f.before.indexSha256, indexEntriesSha256: f.before.indexEntriesSha256, ...candidateIdentity() },
    sourceAfter: { commit: after.head, tree: after.tree, indexSha256: after.indexSha256, indexEntriesSha256: after.indexEntriesSha256 },
    run: { id: 'fixture-run-178', status: f.processStatus, stdoutPath: f.stdoutPath, stderrPath: f.stderrPath, facadeStatusPath: path.join(f.captureRoot, 'facade-status.txt'), runRoot: f.runRoot, captureRoot: f.captureRoot, sourceRoot: f.sourceRoot, repoRoot: f.root },
    supplemental: { beforePath: f.beforePath, afterPath: f.afterPath, ignoredBefore: path.join(f.runRoot, 'ignored-before.z'), ignoredAfter: path.join(f.runRoot, 'ignored-after.z') },
    secretSentinels: []
  };
  writeFileSync(f.recordPath, JSON.stringify(record), { mode: 0o600 });
  chmodSync(f.recordPath, 0o600);
}

function collect(f, kind = 'preliminary', options = { allowFixture: true }) {
  try {
    const proof = collectProof(f.recordPath, path.join(f.parent, 'public-proof.json'), kind, options.finalBindingPath, options);
    return { status: 0, stdout: `PASS ${proof.kind}`, stderr: '' };
  } catch (error) {
    return { status: 1, stdout: '', stderr: `FAIL ${error.safeCause ?? error.name}` };
  }
}

test('real exported facade output, child logs, snapshots and source identity satisfy the complete proof', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  harness(f);
  assert.equal(f.processStatus, 0, f.processOutput);
  assert.equal((f.processOutput.match(/^PASS /gm) ?? []).length, 9);
  assert.equal(readdirSync(path.join(f.runRoot, 'logs')).length, 8);
  const result = collect(f);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  const proof = JSON.parse(readFileSync(path.join(f.parent, 'public-proof.json'), 'utf8'));
  assert.equal(proof.status, 'pass');
  assert.equal(proof.source.commit, f.before.head);
  assert.equal(proof.source.tree, f.before.tree);
  assert.equal(proof.stageCount, 9);
  assert.equal(proof.executedLogCount, 8);
  assert(!JSON.stringify(proof).includes(f.parent));
  assert.equal(defaultProofOutput('preliminary'), path.join(HERE, 'preliminary-local-proof.json'));
  assert.equal(defaultProofOutput('final'), path.join(HERE, 'final-local-proof.json'));
  assert.equal(supplementalGitEnv({ GIT_OPTIONAL_LOCKS: '1' }).GIT_OPTIONAL_LOCKS, '0');
});

test('production collection rejects arbitrary source commit/tree even when candidate identity is supplied', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  harness(f);
  const record = JSON.parse(readFileSync(f.recordPath, 'utf8'));
  record.run.sourceRoot = candidateSource();
  record.source.commit = 'a'.repeat(40);
  record.source.tree = 'b'.repeat(40);
  writeFileSync(f.recordPath, JSON.stringify(record), { mode: 0o600 });
  const result = collect(f, 'preliminary', { allowFixture: false });
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /candidate-mismatch/);
});

test('nonzero facade status is reported before source snapshot drift and preserves a classified safe stage cause', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  harness(f);
  const record = JSON.parse(readFileSync(f.recordPath, 'utf8'));
  record.run.status = 1;
  record.sourceAfter.indexSha256 = '0'.repeat(64);
  writeFileSync(f.recordPath, JSON.stringify(record), { mode: 0o600 });
  writeFileSync(f.stdoutPath, 'PASS repository-preflight\nFAIL android-package-proof; corrective-command=private\n', { mode: 0o600 });
  writeFileSync(path.join(f.runRoot, 'logs', 'android-package-proof.log'), 'status=17\nCould not create provider for value source AndroidLocationsBuildService.AndroidDirectoryCreator.\nprivate output sentinel\n', { mode: 0o600 });
  assert.match(collect(f).stderr, /invocation-nonzero/);
  ({ candidateCommit: record.source.commit, candidateTree: record.source.tree } = candidateIdentity());
  writeFileSync(f.recordPath, JSON.stringify(record), { mode: 0o600 });
  const output = path.join(f.parent, 'blocked-proof.json');
  assert.equal(writeBlockedProjection(f.recordPath, output, 'preliminary', undefined, new Error('runner failed')), true);
  const proof = JSON.parse(readFileSync(output, 'utf8'));
  assert.equal(proof.sourceIntegrity, 'changed');
  assert.equal(proof.cause, 'raw-index-drift');
  assert.deepEqual(proof.observedStages, [
    { purpose: 'repository-preflight', result: 'PASS' },
    { purpose: 'android-package-proof', result: 'FAIL' }
  ]);
  assert.deepEqual(proof.blockedStages, [
    { purpose: 'android-package-proof', result: 'FAIL', cause: 'android-sdk-preferences-conflict' }
  ]);
  assert(!JSON.stringify(proof).includes('private output sentinel'));
  assert(!JSON.stringify(proof).includes('corrective-command'));
});

test('raw index snapshot drift has a distinct safe cause rather than a candidate mismatch', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  harness(f);
  const record = JSON.parse(readFileSync(f.recordPath, 'utf8'));
  record.sourceAfter.indexSha256 = '0'.repeat(64);
  writeFileSync(f.recordPath, JSON.stringify(record), { mode: 0o600 });
  assert.match(collect(f).stderr, /raw-index-drift/);
});

test('raw index bytes are hashed, private, and compared before and after collection', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  harness(f);
  const before = JSON.parse(readFileSync(f.beforePath, 'utf8'));
  const after = JSON.parse(readFileSync(f.afterPath, 'utf8'));
  assert.equal(statSync(before.rawIndexPath).mode & 0o777, 0o600);
  assert.equal(statSync(after.rawIndexPath).mode & 0o777, 0o600);
  assert.equal(createHash(readFileSync(before.rawIndexPath)), before.indexSha256);
  assert.equal(createHash(readFileSync(after.rawIndexPath)), after.indexSha256);
  assert.equal(collect(f).status, 0);

  const bytes = readFileSync(after.rawIndexPath);
  bytes[0] ^= 1;
  writeFileSync(after.rawIndexPath, bytes, { mode: 0o600 });
  assert.match(collect(f).stderr, /raw-index-drift/);
});

test('real artifact policy permits newly created owned regular files under ignored_local_tooling tmp', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  const fixture = path.join('tmp', 'Crosswake.Proof.Phase161_1NavigationGateIntegrityTest', 'test-fixture-marker', 'bin-8123', 'mix');
  harness(f, { mutate: () => {
    const file = path.join(f.root, fixture);
    mkdirSync(path.dirname(file), { recursive: true });
    writeFileSync(file, '#!/bin/sh\nexit 0\n', { mode: 0o700 });
  } });
  const policy = JSON.parse(readFileSync(path.join(f.sourceRoot, 'script/repository_artifact_policy.json'), 'utf8'));
  assert(policy.ignored_transient.find(record => record.category === 'ignored_local_tooling').matchers.some(matcher => matcher.kind === 'tree' && matcher.value === 'tmp'));
  const result = collect(f);
  assert.equal(result.status, 0, result.stderr || result.stdout);
  const proof = JSON.parse(readFileSync(path.join(f.parent, 'public-proof.json'), 'utf8'));
  assert.equal(proof.ignoredArtifacts.newCount, 1);
});

test('self-test text cannot satisfy the full-run evidence contract', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  writeFileSync(f.stdoutPath, 'PASS repository-preflight self-test\n', { mode: 0o600 });
  f.processStatus = 0;
  const after = identity(f.root);
  const empty = path.join(f.runRoot, 'empty.z'); writeFileSync(empty, Buffer.alloc(0), { mode: 0o600 });
  writeFileSync(f.beforePath, JSON.stringify({ head: f.before.head, tree: f.before.tree, ...f.before, statusPath: empty, ignoredPath: empty }), { mode: 0o600 });
  writeFileSync(f.afterPath, JSON.stringify({ head: after.head, tree: after.tree, ...after, statusPath: empty, ignoredPath: empty }), { mode: 0o600 });
  const rec = { schemaVersion: 1, testFixture: true, source: { commit: f.before.head, tree: f.before.tree, ...f.before, ...candidateIdentity() }, sourceAfter: { commit: after.head, tree: after.tree, ...after }, run: { id: 'fixture-run-self-test', status: 0, stdoutPath: f.stdoutPath, stderrPath: f.stderrPath, facadeStatusPath: path.join(f.captureRoot, 'facade-status.txt'), runRoot: f.runRoot, captureRoot: f.captureRoot, sourceRoot: f.sourceRoot, repoRoot: f.root }, supplemental: { beforePath: f.beforePath, afterPath: f.afterPath }, secretSentinels: [] };
  writeFileSync(rec.run.facadeStatusPath, '0', { mode: 0o600 }); writeFileSync(f.recordPath, JSON.stringify(rec), { mode: 0o600 });
  const result = collect(f);
  assert.notEqual(result.status, 0);
});

test('collector rejects duplicate, missing, out-of-order, failed and blocked facade results', t => {
  for (const bad of [
    'PASS repository-preflight\nPASS root-proof\nPASS example-host-proof\nPASS browser-proof\nPASS ios-package-proof\nPASS android-package-proof\nPASS format-proof\nPASS warnings-proof\nPASS repository-cleanliness\nPASS repository-cleanliness\n',
    'PASS repository-preflight\nPASS root-proof\nPASS browser-proof\nPASS example-host-proof\nPASS ios-package-proof\nPASS android-package-proof\nPASS format-proof\nPASS warnings-proof\nPASS repository-cleanliness\n',
    'PASS repository-preflight\nPASS root-proof\nPASS example-host-proof\nPASS browser-proof\nPASS ios-package-proof\nPASS android-package-proof\nPASS format-proof\nPASS warnings-proof\nBLOCKED repository-cleanliness; corrective-command=git diff --check\n',
    'PASS repository-preflight\nPASS root-proof\nFAIL example-host-proof; corrective-command=run\n'
  ]) {
    const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
    harness(f);
    writeFileSync(f.stdoutPath, bad, { mode: 0o600 });
    const result = collect(f);
    assert.notEqual(result.status, 0);
  }
});

test('blocked projection keeps safe stage causes and excludes raw child output', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  harness(f);
  const raw = 'FAIL root-proof; corrective-command=MIX_ENV=test mix verify\nBLOCKED example-host-proof; corrective-command=host setup\n';
  writeFileSync(f.stdoutPath, raw, { mode: 0o600 });
  writeFileSync(path.join(f.runRoot, 'logs', 'root-proof.log'), 'status=17\nprivate child output sentinel\n', { mode: 0o600 });
  const record = JSON.parse(readFileSync(f.recordPath, 'utf8'));
  record.run.status = 1;
  ({ candidateCommit: record.source.commit, candidateTree: record.source.tree } = candidateIdentity());
  writeFileSync(f.recordPath, JSON.stringify(record), { mode: 0o600 });
  assert.equal(readFileSync(record.run.stdoutPath, 'utf8'), raw);
  assert.equal(statSync(record.run.stdoutPath).mode & 0o777, 0o600);
  const output = path.join(f.parent, 'blocked-proof.json');
  assert.equal(writeBlockedProjection(f.recordPath, output, 'preliminary', undefined, new Error('runner failed')), true);
  const proof = JSON.parse(readFileSync(output, 'utf8'));
  assert.equal(proof.status, 'blocked');
  assert.deepEqual(proof.observedStages, [
    { purpose: 'root-proof', result: 'FAIL' },
    { purpose: 'example-host-proof', result: 'BLOCKED' }
  ]);
  assert.deepEqual(proof.blockedStages, [
    { purpose: 'root-proof', result: 'FAIL', cause: 'child-exit-nonzero' },
    { purpose: 'example-host-proof', result: 'BLOCKED', cause: 'blocked-by-prerequisite' }
  ], JSON.stringify(proof));
  assert(!JSON.stringify(proof).includes('private child output sentinel'));
  assert(!JSON.stringify(proof).includes('corrective-command'));
});

test('collector rejects nonzero child status, missing or unsafe logs, source drift and dirty status', t => {
  const cases = [
    f => writeFileSync(path.join(f.captureRoot, 'facade-status.txt'), '1', { mode: 0o600 }),
    f => rmSync(path.join(f.runRoot, 'logs', 'root-proof.log')),
    f => chmodSync(path.join(f.runRoot, 'logs', 'root-proof.log'), 0o644),
    f => writeFileSync(path.join(f.root, 'tracked.txt'), 'drift\n'),
    f => execFileSync('git', ['update-index', '--assume-unchanged', 'tracked.txt'], { cwd: f.root }),
    f => writeFileSync(path.join(f.root, 'new.txt'), 'dirty\n'),
    f => { mkdirSync(path.join(f.root, 'ignored-build')); writeFileSync(path.join(f.root, 'ignored-build', 'unexpected.bin'), 'unexpected'); },
    f => { const target = path.join(f.parent, 'outside'); writeFileSync(target, 'outside'); mkdirSync(path.join(f.root, 'tmp')); execFileSync('ln', ['-s', target, path.join(f.root, 'tmp', 'escape')]); }
  ];
  for (const mutate of cases) {
    const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
    harness(f);
    mutate(f);
    const result = collect(f);
    assert.notEqual(result.status, 0);
  }
});

test('every collector Git subprocess receives GIT_OPTIONAL_LOCKS=0', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  harness(f);
  const bin = path.join(f.parent, 'git-spy'); mkdirSync(bin, { mode: 0o700 });
  const trace = path.join(f.parent, 'git-env.log');
  const gitPath = execFileSync('which', ['git'], { encoding: 'utf8' }).trim();
  const wrapper = path.join(bin, 'git');
  writeFileSync(wrapper, `#!/bin/sh\nprintf '%s\\n' "$GIT_OPTIONAL_LOCKS" >> '${trace}'\nexec '${gitPath}' "$@"\n`, { mode: 0o700 }); chmodSync(wrapper, 0o700);
  const previousPath = process.env.PATH;
  const previousLocks = process.env.GIT_OPTIONAL_LOCKS;
  try {
    process.env.PATH = `${bin}:${previousPath}`;
    process.env.GIT_OPTIONAL_LOCKS = '1';
    assert.equal(collect(f).status, 0);
  } finally {
    process.env.PATH = previousPath;
    if (previousLocks === undefined) delete process.env.GIT_OPTIONAL_LOCKS;
    else process.env.GIT_OPTIONAL_LOCKS = previousLocks;
  }
  const values = readFileSync(trace, 'utf8').trim().split('\n');
  assert(values.length > 0);
  assert(values.every(value => value === '0'));
});

test('collector blocks raw sentinel leakage and emits separate preliminary/final records', t => {
  const f = setup(); t.after(() => rmSync(f.parent, { recursive: true, force: true }));
  harness(f);
  const secret = 'fixture-sensitive-media-transcript-token';
  writeFileSync(f.stdoutPath, readFileSync(f.stdoutPath, 'utf8') + `${secret}\n`, { mode: 0o600 });
  const rec = JSON.parse(readFileSync(f.recordPath, 'utf8')); rec.secretSentinels = [secret]; writeFileSync(f.recordPath, JSON.stringify(rec), { mode: 0o600 });
  assert.notEqual(collect(f).status, 0);
  writeFileSync(f.stdoutPath, readFileSync(f.stdoutPath, 'utf8').replace(`${secret}\n`, ''), { mode: 0o600 });
  const finalRoot = path.join(f.parent, 'fresh-final-root');
  execFileSync('git', ['clone', '--quiet', '--no-local', candidateSource(), finalRoot]);
  execFileSync('git', ['checkout', '--quiet', '--detach', candidateIdentity().candidateCommit], { cwd: finalRoot, env: supplementalGitEnv() });
  const finalIdentity = identity(finalRoot);
  const finalRawIndexPath = path.join(f.captureRoot, 'final-supplemental.index');
  writeFileSync(finalRawIndexPath, finalIdentity.indexBytes, { mode: 0o600 });
  const finalStatusPath = path.join(f.runRoot, 'final-status.z');
  const finalIgnoredPath = path.join(f.runRoot, 'final-ignored.z');
  const finalStatus = git(finalRoot, ['status', '--porcelain=v1', '-z', '--untracked-files=all']);
  const finalIgnored = git(finalRoot, ['ls-files', '--others', '--ignored', '--exclude-standard', '-z']);
  writeFileSync(finalStatusPath, finalStatus, { mode: 0o600 });
  writeFileSync(finalIgnoredPath, finalIgnored, { mode: 0o600 });
  for (const snapshotPath of [f.beforePath, f.afterPath]) {
    const snapshot = JSON.parse(readFileSync(snapshotPath, 'utf8'));
    Object.assign(snapshot, {
      head: finalIdentity.head, tree: finalIdentity.tree,
      indexSha256: finalIdentity.indexSha256, indexEntriesSha256: finalIdentity.indexEntriesSha256,
      statusPath: finalStatusPath, ignoredPath: finalIgnoredPath, rawIndexPath: finalRawIndexPath
    });
    writeFileSync(snapshotPath, JSON.stringify(snapshot), { mode: 0o600 });
  }
  const finalRecord = JSON.parse(readFileSync(f.recordPath, 'utf8'));
  finalRecord.source.commit = finalIdentity.head;
  finalRecord.source.tree = finalIdentity.tree;
  finalRecord.source.indexSha256 = finalIdentity.indexSha256;
  finalRecord.source.indexEntriesSha256 = finalIdentity.indexEntriesSha256;
  finalRecord.sourceAfter.commit = finalIdentity.head;
  finalRecord.sourceAfter.tree = finalIdentity.tree;
  finalRecord.sourceAfter.indexSha256 = finalIdentity.indexSha256;
  finalRecord.sourceAfter.indexEntriesSha256 = finalIdentity.indexEntriesSha256;
  finalRecord.run.sourceRoot = finalRoot;
  finalRecord.run.repoRoot = finalRoot;
  writeFileSync(f.recordPath, JSON.stringify(finalRecord), { mode: 0o600 });
  const finalBindingPath = path.join(f.captureRoot, 'final-source-binding.json');
  writeFileSync(finalBindingPath, JSON.stringify({ schemaVersion: 1, phase: 178, plan: '05', ...candidateIdentity(), finalCommit: finalIdentity.head, finalTree: finalIdentity.tree, proofRoot: finalRoot }), { mode: 0o600 });
  assert.equal(loadFinalSourceBinding(finalBindingPath).finalCommit, finalIdentity.head);
  const finalResult = collect(f, 'final', { allowFixture: true, finalBindingPath });
  assert.equal(finalResult.status, 0, finalResult.stderr);
  const proof = JSON.parse(readFileSync(path.join(f.parent, 'public-proof.json'), 'utf8'));
  assert.equal(proof.kind, 'final');
  assert(!JSON.stringify(proof).includes(secret));
});

test('renewed candidate binding is joined to its public projection and rejects unsafe pointers before Git launches', t => {
  const binding = loadCandidateBinding();
  const projection = JSON.parse(readFileSync(path.join(HERE, 'candidate-source.json'), 'utf8'));
  assert.equal(binding.candidateCommit, projection.candidateCommit);
  assert.equal(binding.candidateTree, projection.candidateTree);
  assert.notEqual(binding.candidateCommit, binding.oldCandidateCommit);

  const parent = mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-binding-negative-'));
  chmodSync(parent, 0o700);
  t.after(() => rmSync(parent, { recursive: true, force: true }));
  let launches = 0;
  const gitReader = () => { launches += 1; throw new Error('must not launch'); };
  assert.throws(() => loadCandidateBinding({ pointerPath: path.join(parent, 'missing.pointer'), gitReader }));
  const pointer = path.join(parent, 'recovery.pointer');
  writeFileSync(pointer, `${process.cwd()}\n`, { mode: 0o600 });
  chmodSync(pointer, 0o600);
  assert.throws(() => loadCandidateBinding({ pointerPath: pointer, gitReader }));
  assert.equal(launches, 0);
});
