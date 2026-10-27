import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawn } from 'node:child_process';
import { performance } from 'node:perf_hooks';
import {
  mkdtempSync, existsSync, writeFileSync, readFileSync,
  rmSync, mkdirSync, statSync, readdirSync,
} from 'node:fs';
import { tmpdir, platform, arch, release, cpus } from 'node:os';
import { createHash, randomUUID } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { join, resolve, dirname, delimiter } from 'node:path';

export const targets = [
  'lib/crosswake/offline/safe_observation.ex',
  'lib/crosswake/offline/journal.ex',
  'lib/crosswake/policy/compiler.ex',
  'lib/crosswake/policy/route.ex',
  'lib/crosswake/bridge/contract.ex',
];
export const tests = [
  'test/crosswake/offline',
  'test/crosswake/policy',
  'test/crosswake/bridge',
];
const flags = [
  '--no-filter', '--no-optimize', '--concurrency', '1', '--timeout', '10000',
  '--fail-at', '0', '--format', 'json',
];

export function argumentsFor(files, output) {
  return [
    'muex', '--files', files.join(','), '--test-paths', tests.join(','),
    ...flags, '--output', output,
  ];
}

export function validateProtocol(p) {
  assert.equal(p.version, '0.12.0', 'pin');
  assert.deepEqual(p.targets, targets, 'targets');
  assert.deepEqual(p.tests, tests, 'tests');
  assert.deepEqual(p.flags, flags, 'flags');
  assert.equal(p.budgetMs, 1800000, 'budget');
  assert.equal(p.noiseLimit, 0.2, 'noise');
  const homes = { MIX_HOME: 'mix', MIX_ARCHIVES: 'archives', HEX_HOME: 'hex' };
  for (const [key, leaf] of Object.entries(homes)) {
    assert.equal(p.homes[key], join(p.toolRoot, leaf), 'isolated-home');
  }
  return p;
}

export function remaining(p, now) {
  assert(now >= p.startedMonotonicMs, 'clock-regression');
  const left = p.budgetMs - (now - p.startedMonotonicMs);
  assert(left >= 0, 'budget-exhausted');
  return left;
}

export function fresh(path) {
  assert(!existsSync(path), 'report-reused');
}

export async function child(command, args, options = {}) {
  const started = performance.now();
  return await new Promise((resolveResult) => {
    const proc = spawn(command, args, { cwd: options.cwd, env: options.env ?? process.env, detached: true, stdio: ['ignore', 'pipe', 'pipe'] });
    let output = '', timedOut = false, interrupted = false;
    const interrupt = () => { interrupted = true; try { process.kill(-proc.pid, 'SIGKILL'); } catch {} };
    process.once('SIGINT', interrupt); process.once('SIGTERM', interrupt); options.abortSignal?.addEventListener('abort', interrupt, { once: true });
    const detach = () => { process.removeListener('SIGINT', interrupt); process.removeListener('SIGTERM', interrupt); options.abortSignal?.removeEventListener('abort', interrupt); };
    const timer = setTimeout(() => { timedOut = true; try { process.kill(-proc.pid, 'SIGKILL'); } catch {} }, options.timeoutMs ?? 1000);
    proc.stdout.on('data', d => { output += d; }); proc.stderr.on('data', d => { output += d; });
    proc.on('error', () => { clearTimeout(timer); detach(); resolveResult({ exit: null, timedOut, interrupted, output: '', durationMs: performance.now() - started, spawnError: true }); });
    proc.on('close', (exit, signal) => { clearTimeout(timer); detach(); resolveResult({ exit, signal, timedOut, interrupted, output, durationMs: performance.now() - started }); });
  });
}
export function successful(r) {
  assert(!r.interrupted, 'child-interrupted');
  assert.equal(r.timedOut, false, 'child-timeout');
  assert.equal(r.exit, 0, 'child-failure');
}

export async function restored(path, operation) {
  const bytes = readFileSync(path);
  try {
    return await operation();
  } finally {
    writeFileSync(path, bytes);
    assert.deepEqual(readFileSync(path), bytes);
  }
}

const phase = '.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet';
const evidence = `${phase}/196-EVIDENCE`;
const protocolPath = `${evidence}/muex-protocol.json`;
const resultPath = `${evidence}/muex-bootstrap/result.json`;
const monotonic = () => Number(process.hrtime.bigint()) / 1e6;
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const git = (...args) => execFileSync('git', args, { encoding: 'utf8' }).trim();
const json = (path, value) => {
  mkdirSync(resolve(path, '..'), { recursive: true });
  writeFileSync(path, JSON.stringify(value, null, 2) + '\n');
};

function allFiles(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap(e =>
    e.isDirectory() ? allFiles(`${dir}/${e.name}`) : [`${dir}/${e.name}`],
  );
}

function protectedFiles() {
  return [
    ...targets, ...tests.flatMap(allFiles),
    'test/test_helper.exs', 'mix.exs', 'mix.lock',
  ];
}

async function bootstrap(fallback = false, resumeBuild = false, resumeLaunch = false) {
  if (!fallback) { fresh(protocolPath); fresh(resultPath); }
  const files = protectedFiles();
  assert.equal(git('status', '--porcelain', '--', ...files), '', 'dirty-input');
  const toolRoot = fallback ? JSON.parse(readFileSync(protocolPath, 'utf8')).toolRoot : `/private/tmp/cw196-muex-${randomUUID()}`;
  const p = fallback ? validateProtocol(JSON.parse(readFileSync(protocolPath, 'utf8'))) : validateProtocol({ schema: 'crosswake-muex-protocol/1', attempt: randomUUID(), version: '0.12.0', targets, tests, flags, budgetMs: 1800000, noiseLimit: 0.2, startedAt: new Date().toISOString(), startedMonotonicMs: monotonic(), toolRoot,
    homes: { MIX_HOME: `${toolRoot}/mix`, MIX_ARCHIVES: `${toolRoot}/archives`, HEX_HOME: `${toolRoot}/hex` }, sourceCommit: git('rev-parse', 'HEAD'), sourceTree: git('rev-parse', 'HEAD^{tree}'), cleanTrackedInputs: true,
    sourceDigests: Object.fromEntries(files.map(f => [f, digest(readFileSync(f))])), machine: { platform: platform(), arch: arch(), release: release(), logicalCpus: cpus().length },
    toolchain: { node: process.version, mix: execFileSync('mix', ['--version'], { encoding: 'utf8' }).trim() }, fullBaselineArguments: argumentsFor(targets, '<fresh-baseline-path>'), bootstrapArguments: argumentsFor([targets[0]], '<fresh-bootstrap-path>'), archiveFirst: true,
    package: { registry: 'https://hex.pm/api/packages/muex/releases/0.12.0', source: 'https://github.com/Oeditus/muex/tree/v0.12.0', expectedChecksum: 'a4b395b87d23b8d34f4508d0c13494b734f1fff8156eca2360fd279a0799d52e' } });
  if (!fallback) json(protocolPath, p); mkdirSync(toolRoot, { recursive: true });
  const saved = new Map(files.map(f => [f, readFileSync(f)]));
  const receipt = fallback ? JSON.parse(readFileSync(resultPath, 'utf8')) : { schema: 'crosswake-muex-process/1', attempt: p.attempt, status: 'running', requirement: 'SPEC-04 pending', commands: [], restored: false };
  if (fallback) {
    assert.equal(receipt.status, 'terminal-incomplete', 'fallback-without-failed-archive'); assert(resumeBuild || resumeLaunch || !receipt.fallbackUsed, 'fallback-reused');
    const observed = receipt.commands.find(r => r.label === 'archive-bootstrap');
    const raw = readFileSync(`${toolRoot}/archive-bootstrap.log`, 'utf8');
    assert(observed?.exit === 1 && !observed.timedOut && digest(raw) === observed.outputSha256 && raw.includes('Jason.encode!/2 is undefined') && raw.includes('Muex.Reporter.Json.generate/2'), 'fallback-ineligible');
    assert(receipt.restored && receipt.cleanTests, 'fallback-before-restoration');
    if (resumeBuild) {
      assert(!receipt.buildEnvironmentReconciled, 'build-resume-reused');
      const failed = receipt.commands.find(c => c.label === 'fallback-deps');
      const output = readFileSync(`${toolRoot}/fallback-deps.log`, 'utf8');
      assert(failed?.exit === 126 && digest(output) === failed.outputSha256 && output.startsWith('No version is set for command mix'), 'build-resume-ineligible');
      for (const path of ['deps', '_build', 'mix.lock', 'muex']) assert(!existsSync(`${toolRoot}/source/${path}`), 'uncertain-install-state');
      assert(!receipt.commands.some(c => c.label === 'escript-bootstrap'), 'mutation-retry-forbidden');
      receipt.buildEnvironmentReconciled = { commandNeverStarted: true, packageInstallNeverStarted: true, toolchain: 'repository .tool-versions', observedExit: 126 };
    }
    if (resumeLaunch) {
      assert(!receipt.launchEnvironmentReconciled, 'launch-resume-reused');
      const failed = receipt.commands.find(c => c.label === 'escript-bootstrap'); const output = readFileSync(`${toolRoot}/escript-bootstrap.log`, 'utf8');
      assert(failed?.exit === 1 && digest(output) === failed.outputSha256 && output.startsWith('Error: Mix is not available: no `elixir` executable was found on PATH'), 'launch-resume-ineligible');
      assert.equal(digest(readFileSync(`${toolRoot}/source/muex`)), receipt.escriptSha256, 'escript-changed');
      assert(!existsSync(`${evidence}/muex-bootstrap/report.json`), 'uncertain-report-state');
      receipt.launchEnvironmentReconciled = { mutationNeverStarted: true, observedExit: 1, reason: 'upstream MixBootstrap requires real Elixir bin parent; asdf shim has no sibling lib', version: p.toolchain.mix };
    }
    receipt.fallbackUsed = true; receipt.archiveFailure = { label: 'archive-json-dependency-unavailable', exit: observed.exit, restored: true, cleanTests: true };
    receipt.status = 'fallback-running'; delete receipt.reason; json(resultPath, receipt);
  }
  const toolVersions = Object.fromEntries(readFileSync('.tool-versions', 'utf8').trim().split('\n').map(s => s.trim().split(/\s+/)));
  const actualElixirBin = dirname(execFileSync('asdf', ['which', 'elixir'], { encoding: 'utf8' }).trim());
  const env = { ...process.env, ...p.homes, ASDF_ELIXIR_VERSION: toolVersions.elixir, ASDF_ERLANG_VERSION: toolVersions.erlang, PATH: `${actualElixirBin}${delimiter}${process.env.PATH}`, MIX_ENV: 'test' };
  async function run(label, command, args, extra = {}) {
    const left = remaining(p, monotonic()); assert(left > 0, 'budget-exhausted');
    const r = await child(command, args, { env, timeoutMs: left, ...extra });
    writeFileSync(`${toolRoot}/${label}.log`, r.output);
    receipt.commands.push({ label, command, args, exit: r.exit, timedOut: r.timedOut, interrupted: r.interrupted, durationMs: r.durationMs, outputSha256: digest(r.output) });
    json(resultPath, receipt); console.log(JSON.stringify({ stage: label, exit: r.exit, timedOut: r.timedOut, durationMs: Math.round(r.durationMs), remainingMs: Math.max(0, p.budgetMs - (monotonic() - p.startedMonotonicMs)) }));
    successful(r); return r;
  }
  try {
    if (!fallback) {
    const registry = await run('registry', 'curl', ['--fail', '--silent', '--show-error', '--max-time', '20', p.package.registry]);
    const metadata = JSON.parse(registry.output); assert.equal(metadata.version, p.version); assert.equal(metadata.checksum, p.package.expectedChecksum);
    await run('package-download', 'curl', ['--fail', '--silent', '--show-error', '--max-time', '30', '-o', `${toolRoot}/muex.tar`, 'https://repo.hex.pm/tarballs/muex-0.12.0.tar']);
    assert.equal(digest(readFileSync(`${toolRoot}/muex.tar`)), p.package.expectedChecksum, 'package-checksum'); receipt.packageChecksumVerified = true;
    for (const [label, sourcePath] of Object.entries({ config: 'lib/muex/config.ex', reporter: 'lib/muex/reporter/json.ex', runner: 'lib/muex/test_runner/port.ex', task: 'lib/mix/tasks/muex.ex', project: 'mix.exs' })) {
      const r = await run(`source-${label}`, 'curl', ['--fail', '--silent', '--show-error', '--max-time', '20', `https://raw.githubusercontent.com/Oeditus/muex/v0.12.0/${sourcePath}`]);
      receipt.sourceChecksums ??= {}; receipt.sourceChecksums[sourcePath] = digest(r.output);
    }
    await run('install-hex', 'mix', ['local.hex', '--force']);
    await run('install-archive', 'mix', ['archive.install', 'hex', 'muex', '0.12.0', '--force']);
    const archives = await run('archive-list', 'mix', ['archive']); assert(archives.output.includes('muex-0.12.0'), 'archive-pin-not-installed');
    } else if (!resumeLaunch) {
      assert.equal(digest(readFileSync(`${toolRoot}/muex.tar`)), p.package.expectedChecksum, 'fallback-package-checksum');
      const sourceRoot = `${toolRoot}/source`;
      if (!resumeBuild) {
        mkdirSync(sourceRoot);
        await run('fallback-package-extract', 'tar', ['xf', `${toolRoot}/muex.tar`, '-C', sourceRoot]);
        await run('fallback-source-extract', 'tar', ['xzf', `${sourceRoot}/contents.tar.gz`, '-C', sourceRoot]);
      }
      for (const [sourcePath, sha] of Object.entries(receipt.sourceChecksums)) assert.equal(digest(readFileSync(`${sourceRoot}/${sourcePath}`)), sha, 'fallback-source-mismatch');
      await run(resumeBuild ? 'fallback-deps-resolved-toolchain' : 'fallback-deps', 'mix', ['deps.get', '--only', 'prod'], { cwd: sourceRoot, env: { ...env, MIX_ENV: 'prod' } });
      await run('fallback-build', 'mix', ['escript.build'], { cwd: sourceRoot, env: { ...env, MIX_ENV: 'prod' } });
      receipt.escriptSha256 = digest(readFileSync(`${sourceRoot}/muex`));
    }
    const reportPath = `${evidence}/muex-bootstrap/report.json`; fresh(reportPath);
    const startedAtMs = Date.now(); receipt.reportStartedAtMs = startedAtMs;
    const r = fallback ? await run(resumeLaunch ? 'escript-toolchain-launch' : 'escript-bootstrap', `${toolRoot}/source/muex`, argumentsFor([targets[0]], reportPath).slice(1)) : await run('archive-bootstrap', 'mix', argumentsFor([targets[0]], reportPath));
    assert(existsSync(reportPath), 'missing-real-report'); assert(statSync(reportPath).mtimeMs >= startedAtMs, 'stale-real-report');
    const report = JSON.parse(readFileSync(reportPath, 'utf8'));
    assert(report.summary.total > 0 && report.mutations.length > 0, 'empty-real-report');
    assert(report.summary.killed + report.summary.survived > 0, 'no-useful-outcome');
    assert(report.mutations.some(m => ['killed', 'survived'].includes(m.status) && m.location.file === targets[0]), 'no-useful-target');
    receipt.status = 'captured'; receipt.reportSha256 = digest(readFileSync(reportPath)); receipt.summary = report.summary;
  } catch (error) {
    receipt.status = 'terminal-incomplete'; receipt.reason = String(error.message).split('\n')[0]; process.exitCode = 1;
  } finally {
    for (const [f, bytes] of saved) { if (!readFileSync(f).equals(bytes)) writeFileSync(f, bytes); assert.deepEqual(readFileSync(f), bytes); }
    receipt.restored = true;
    try { await run('restore-compile', 'mix', ['compile', '--force', '--warnings-as-errors']); const clean = await run('restore-tests', 'mix', ['test', ...tests]); assert(/\b[1-9]\d* tests?, 0 failures/.test(clean.output), 'clean-tests-empty'); receipt.cleanTests = true; }
    catch { receipt.status = 'terminal-incomplete'; receipt.reason ??= 'restoration-verification-failed'; process.exitCode = 1; }
    receipt.elapsedMs = monotonic() - p.startedMonotonicMs; receipt.remainingMs = Math.max(0, p.budgetMs - receipt.elapsedMs); json(resultPath, receipt);
    console.log(JSON.stringify({ status: receipt.status, reason: receipt.reason, restored: receipt.restored, cleanTests: receipt.cleanTests, summary: receipt.summary, remainingMs: Math.round(receipt.remainingMs) }));
  }
}

if (process.argv[2] === 'bootstrap') await bootstrap();
if (process.argv[2] === 'fallback') await bootstrap(true);
if (process.argv[2] === 'resume-build') await bootstrap(true, true);
if (process.argv[2] === 'resume-launch') await bootstrap(true, false, true);

if (process.argv[2] === 'reconcile') {
  const p = validateProtocol(JSON.parse(readFileSync(protocolPath, 'utf8')));
  const receipt = JSON.parse(readFileSync(resultPath, 'utf8'));
  assert.equal(receipt.status, 'terminal-incomplete', 'not-terminal');
  const reportPath = `${evidence}/muex-bootstrap/report.json`;
  const bytes = readFileSync(reportPath);
  const report = JSON.parse(bytes);
  const outcomes = ['killed', 'survived', 'invalid', 'timeout', 'equivalent', 'no_coverage'];
  for (const status of outcomes) assert.equal(report.summary[status], report.mutations.filter(m => m.status === status).length, 'reconcile-count');
  assert.equal(report.summary.total, report.mutations.length, 'reconcile-total');
  assert.equal(report.summary.total, outcomes.reduce((n, key) => n + report.summary[key], 0), 'reconcile-sum');
  assert.equal(report.summary.killed + report.summary.survived, 0, 'reconcile-useful-change');
  for (const [path, sha] of Object.entries(p.sourceDigests)) assert.equal(digest(readFileSync(path)), sha, 'restoration-mismatch');
  assert.equal(git('status', '--porcelain', '--', ...Object.keys(p.sourceDigests)), '', 'restoration-dirty');
  const positive = readFileSync(`${p.toolRoot}/restore-tests.log`, 'utf8');
  const summaries = [...positive.matchAll(/(\d+) tests?, (\d+) failures/g)].map(m => ({ tests: Number(m[1]), failures: Number(m[2]) }));
  assert(summaries.length > 0 && summaries.every(s => s.tests > 0 && s.failures === 0), 'positive-tests-unproven');
  receipt.reportSha256 = digest(bytes); receipt.summary = report.summary;
  receipt.reconciliation = {
    reportSchemaOwner: 'Muex.Reporter.Json@0.12.0', unchangedGenuineReport: true, countsConserved: true,
    invalidCompileErrors: report.mutations.filter(m => m.status === 'invalid' && m.error.startsWith('{:compile_error,')).length,
    recordsJudgedByTests: report.mutations.filter(m => m.test_files.length > 0).length,
    comparisonMutantsLabeledEquivalent: report.mutations.filter(m => m.status === 'equivalent' && m.mutator === 'Muex.Mutator.Comparison').length,
    sourceChecksums: Object.fromEntries(['tce.ex', 'worker_pool.ex', 'compiler.ex'].map(path => [path, digest(readFileSync(`${p.toolRoot}/source/lib/muex/${path}`))])),
    rootCause: 'Upstream TCE fingerprints the first compiled module; SafeObservation has nested Error emitted before its outer module. The genuine report labels changed outer comparisons equivalent. Compilation-invalid mutants account for the remainder.',
    rootCauseEvidence: 'Pinned source compile_renamed [{module,binary}|_] plus read-only benign Code.compile_string module order [Outer.Inner,Outer] and five real Comparison records; no new mutation invocation.',
    knownKillSurvivePairsCompleted: 0, requiredPairs: 5, fixtureCreated: false,
    task1: 'failed-useful-outcome-gate', task2: 'blocked-by-task1', dependent19614: 'blocked',
    sourceAndTestsDigestRestored: true, projectMixFilesUnchanged: true, cleanPositiveTests: summaries,
    nextEligibleExecutionCommand: null,
    supportedUnexecutedOption: '--no-tce (Muex.Config.resolve_tce/1); --no-optimize does not disable TCE',
    reopenCondition: 'Explicitly approved new frozen attempt using official --no-tce, or an approved scoped roadmap move; never reuse this terminal attempt or silently change its flags/appetite.'
  };
  json(resultPath, receipt);
  console.log(JSON.stringify({ status: receipt.status, summary: receipt.summary, judgedRecords: receipt.reconciliation.recordsJudgedByTests, positiveTests: summaries, controls: 'blocked', restored: true }));
}

const command = process.argv[2];
if (command === 'controls' || (command === 'quick' && process.argv[3] === 'controls')) {
  console.log(JSON.stringify({ status: 'blocked', reason: 'useful-bootstrap-precondition-unmet', requirement: 'SPEC-04 pending', pairsCompleted: 0, pairsRequired: 5 }));
  process.exitCode = 1;
} else if (!['bootstrap', 'fallback', 'resume-build', 'resume-launch', 'reconcile'].includes(command) && !(command === 'quick' && process.argv[3] === 'bootstrap')) {
  console.log(JSON.stringify({ status: 'refused', reason: 'unknown-stage' }));
  process.exitCode = 2;
}

if (process.argv[2] === 'quick' && process.argv[3] === 'bootstrap') {
  const started = performance.now();
  test('frozen protocol refuses changed targets flags pin homes and exhausted budget', () => {
    const p = { version: '0.12.0', targets, tests, flags, budgetMs: 1800000, noiseLimit: 0.2, startedMonotonicMs: 100, homes: { MIX_HOME: '/tool/mix', MIX_ARCHIVES: '/tool/archives', HEX_HOME: '/tool/hex' }, toolRoot: '/tool' };
    validateProtocol(p);
    for (const bad of [{ ...p, targets: targets.slice(1) }, { ...p, version: '0.11.0' }, { ...p, flags: flags.slice(1) }, { ...p, tests: tests.slice(1) }, { ...p, budgetMs: 1800001 }, { ...p, homes: { ...p.homes, HEX_HOME: '/elsewhere' } }]) assert.throws(() => validateProtocol(bad));
    assert.equal(remaining(p, 1800100), 0); assert.throws(() => remaining(p, 1800101)); assert.throws(() => remaining(p, 99));
    assert.deepEqual(argumentsFor(targets, 'fresh.json'), ['muex', '--files', targets.join(','), '--test-paths', tests.join(','), ...flags, '--output', 'fresh.json']);
  });
  test('actual tiny child failures timeout fresh path and finally restoration discriminate', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'muex-quick-'));
    try {
      const path = join(dir, 'bytes'); fresh(path); writeFileSync(path, 'original'); assert.throws(() => fresh(path));
      successful(await child(process.execPath, ['-e', 'process.exit(0)']));
      assert.throws(() => successful({ timedOut: false, exit: 7 }));
      const failed = await child(process.execPath, ['-e', 'process.exit(7)']); assert.equal(failed.exit, 7); assert.throws(() => successful(failed));
      const timeout = await child(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { timeoutMs: 80 }); assert.equal(timeout.timedOut, true); assert.throws(() => successful(timeout));
      const controller = new AbortController(); const interrupted = child(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { abortSignal: controller.signal }); setTimeout(() => controller.abort(), 40); const interruptedResult = await interrupted; assert(interruptedResult.interrupted); assert.throws(() => successful(interruptedResult));
      await assert.rejects(restored(path, async () => { writeFileSync(path, 'changed'); throw new Error('injected'); })); assert.equal(readFileSync(path, 'utf8'), 'original');
    } finally { rmSync(dir, { recursive: true, force: true }); }
    assert(performance.now() - started < 20000, 'quick-deadline');
  });
}
