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
  '--no-filter', '--no-tce', '--no-optimize', '--concurrency', '1', '--timeout', '10000',
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
  assert.equal(p.carriedMs, 340269.58370900154, 'carried-budget');
  const homes = { MIX_HOME: 'mix', MIX_ARCHIVES: 'archives', HEX_HOME: 'hex' };
  for (const [key, leaf] of Object.entries(homes)) {
    assert.equal(p.homes[key], join(p.toolRoot, leaf), 'isolated-home');
  }
  return p;
}

export function remaining(p, now) {
  assert(now >= p.startedMonotonicMs, 'clock-regression');
  const left = p.budgetMs - p.carriedMs - (now - p.startedMonotonicMs);
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
const attemptDir = `${evidence}/muex-attempt2`;
const protocolPath = `${attemptDir}/protocol.json`;
const resultPath = `${attemptDir}/bootstrap-result.json`;
const history = `${evidence}/muex-attempt1-history`;
const monotonic = () => Number(process.hrtime.bigint()) / 1e6;
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const git = (...args) => execFileSync('git', args, { encoding: 'utf8' }).trim();
const json = (path, value) => { mkdirSync(dirname(path), { recursive: true }); writeFileSync(path, JSON.stringify(value, null, 2) + '\n'); };
function allFiles(dir) { return readdirSync(dir, { withFileTypes: true }).flatMap(e => e.isDirectory() ? allFiles(`${dir}/${e.name}`) : [`${dir}/${e.name}`]); }
function protectedFiles() { return [...targets, ...tests.flatMap(allFiles), 'test/test_helper.exs', 'mix.exs', 'mix.lock']; }

async function bootstrap() {
  fresh(protocolPath); fresh(resultPath);
  const prior = JSON.parse(readFileSync(`${history}/muex-protocol.json`));
  const priorResult = JSON.parse(readFileSync(`${history}/result.json`));
  assert.equal(priorResult.status, 'terminal-incomplete');
  assert.equal(priorResult.elapsedMs, 340269.58370900154);
  assert.equal(priorResult.archiveFailure.label, 'archive-json-dependency-unavailable');
  const files = protectedFiles();
  assert.equal(git('status', '--porcelain', '--', ...files), '', 'dirty-input');
  const p = validateProtocol({ ...prior, schema: 'crosswake-muex-protocol/2', attempt: randomUUID(), attemptNumber: 2,
    flags, carriedMs: priorResult.elapsedMs, startedMonotonicMs: monotonic(), startedAt: new Date().toISOString(),
    sourceCommit: git('rev-parse', 'HEAD'), sourceTree: git('rev-parse', 'HEAD^{tree}'),
    sourceDigests: Object.fromEntries(files.map(f => [f, digest(readFileSync(f))])),
    fullBaselineArguments: argumentsFor(targets, '<fresh-attempt2-baseline-path>'), bootstrapArguments: argumentsFor([targets[0]], `${attemptDir}/bootstrap-report.json`),
    historyDigests: Object.fromEntries(allFiles(history).map(f => [f, digest(readFileSync(f))])),
    archiveFirst: 'satisfied-by-attempt1-observed-integration-failure', fallback: 'verified-existing-escript',
    controlSelection: { mutators: ['comparison'], tests, pairsRequired: targets, status: 'exact-weakening-must-freeze-before-controls' },
    toolchain: { node: process.version, mix: execFileSync('mix', ['--version'], { encoding: 'utf8' }).trim() } });
  assert.equal(p.toolchain.mix, prior.toolchain.mix, 'toolchain-changed');
  assert.equal(digest(readFileSync(`${p.toolRoot}/muex.tar`)), p.package.expectedChecksum, 'package-changed');
  for (const [f, hash] of Object.entries(priorResult.sourceChecksums)) assert.equal(digest(readFileSync(`${p.toolRoot}/source/${f}`)), hash, 'tool-source-changed');
  assert.equal(digest(readFileSync(`${p.toolRoot}/source/muex`)), priorResult.escriptSha256, 'executable-changed');
  const config = readFileSync(`${p.toolRoot}/source/lib/muex/config.ex`, 'utf8');
  assert(config.includes('--tce` / `--no-tce') && config.includes('defp resolve_tce'), 'unsupported-no-tce');
  p.verifiedEscriptSha256 = priorResult.escriptSha256;
  p.sourceChecksums = priorResult.sourceChecksums;
  p.resolutionSha256 = digest(readFileSync(`${evidence}/MUEX-ATTEMPT-RESOLUTION.md`));
  json(protocolPath, p);
  const receipt = { schema: 'crosswake-muex-process/2', attempt: p.attempt, status: 'running', commands: [], carriedMs: p.carriedMs, requirement: 'SPEC-04 pending' };
  json(resultPath, receipt);
  const saved = new Map(files.map(f => [f, readFileSync(f)]));
  const bin = dirname(execFileSync('asdf', ['which', 'elixir'], { encoding: 'utf8' }).trim());
  const versions = Object.fromEntries(readFileSync('.tool-versions', 'utf8').trim().split('\n').map(s => s.trim().split(/\s+/)));
  const env = { ...process.env, ...p.homes, ASDF_ELIXIR_VERSION: versions.elixir, ASDF_ERLANG_VERSION: versions.erlang, PATH: `${bin}${delimiter}${process.env.PATH}`, MIX_ENV: 'test' };
  async function run(label, command, args, restoring = false) {
    const left = restoring ? Math.max(60000, p.budgetMs - p.carriedMs - (monotonic() - p.startedMonotonicMs)) : remaining(p, monotonic());
    const r = await child(command, args, { env, timeoutMs: left });
    writeFileSync(`${p.toolRoot}/attempt2-${label}.log`, r.output);
    receipt.commands.push({ label, command, args, exit: r.exit, timedOut: r.timedOut, interrupted: r.interrupted, durationMs: r.durationMs, outputSha256: digest(r.output) });
    json(resultPath, receipt);
    console.log(JSON.stringify({ stage: label, exit: r.exit, durationMs: Math.round(r.durationMs), remainingMs: Math.round(p.budgetMs - p.carriedMs - (monotonic() - p.startedMonotonicMs)) }));
    successful(r); return r;
  }
  try {
    const reportPath = `${attemptDir}/bootstrap-report.json`; fresh(reportPath);
    receipt.reportStartedAtMs = Date.now();
    await run('bootstrap', `${p.toolRoot}/source/muex`, p.bootstrapArguments.slice(1));
    assert(existsSync(reportPath), 'missing-real-report');
    assert(statSync(reportPath).mtimeMs >= receipt.reportStartedAtMs, 'stale-real-report');
    const bytes = readFileSync(reportPath); const report = JSON.parse(bytes);
    receipt.reportSha256 = digest(bytes); receipt.summary = report.summary;
    assert(report.summary.total > 0 && report.mutations.length > 0, 'empty-real-report');
    assert(report.summary.killed + report.summary.survived > 0, 'no-useful-outcome');
    assert(report.mutations.some(m => ['killed', 'survived'].includes(m.status) && m.location.file === targets[0]), 'no-useful-target');
    receipt.status = 'captured';
  } catch (error) { receipt.status = 'terminal-incomplete'; receipt.reason = String(error.message).split('\n')[0]; process.exitCode = 1; }
  finally {
    for (const [f, bytes] of saved) { if (!readFileSync(f).equals(bytes)) writeFileSync(f, bytes); assert.deepEqual(readFileSync(f), bytes); }
    receipt.restored = true;
    try {
      await run('restore-compile', 'mix', ['compile', '--force', '--warnings-as-errors'], true);
      const r = await run('restore-tests', 'mix', ['test', ...tests], true);
      const counts = [...r.output.matchAll(/(\d+) tests?, (\d+) failures/g)].map(m => ({ tests: Number(m[1]), failures: Number(m[2]) }));
      assert(counts.length > 0 && counts.every(c => c.tests > 0 && c.failures === 0), 'clean-tests-empty'); receipt.cleanTests = counts;
    } catch { receipt.status = 'terminal-incomplete'; receipt.reason ??= 'restoration-verification-failed'; process.exitCode = 1; }
    receipt.elapsedMs = monotonic() - p.startedMonotonicMs;
    receipt.aggregateElapsedMs = p.carriedMs + receipt.elapsedMs;
    receipt.remainingMs = Math.max(0, p.budgetMs - receipt.aggregateElapsedMs);
    if (receipt.aggregateElapsedMs > p.budgetMs) { receipt.status = 'terminal-incomplete'; receipt.reason = 'aggregate-budget-exhausted'; process.exitCode = 1; }
    for (const [f, hash] of Object.entries(p.historyDigests)) assert.equal(digest(readFileSync(f)), hash, 'history-changed');
    assert.equal(git('status', '--porcelain', '--', ...files), '', 'restoration-dirty');
    json(resultPath, receipt);
    console.log(JSON.stringify({ status: receipt.status, reason: receipt.reason, summary: receipt.summary, cleanTests: receipt.cleanTests, aggregateElapsedMs: receipt.aggregateElapsedMs, remainingMs: receipt.remainingMs }));
  }
}

const command = process.argv[2];
if (command === 'bootstrap') await bootstrap();
else if (command === 'quick' && process.argv[3] === 'bootstrap') {
  const started = performance.now();
  test('frozen attempt2 flags and carried aggregate budget discriminate', () => {
    const p = { version: '0.12.0', targets, tests, flags, budgetMs: 1800000, carriedMs: 340269.58370900154, noiseLimit: 0.2, startedMonotonicMs: 100, homes: { MIX_HOME: '/tool/mix', MIX_ARCHIVES: '/tool/archives', HEX_HOME: '/tool/hex' }, toolRoot: '/tool' };
    validateProtocol(p);
    for (const bad of [{ ...p, targets: targets.slice(1) }, { ...p, version: '0.11.0' }, { ...p, flags: flags.filter(f => f !== '--no-tce') }, { ...p, tests: tests.slice(1) }, { ...p, budgetMs: 1800001 }, { ...p, carriedMs: 0 }, { ...p, homes: { ...p.homes, HEX_HOME: '/elsewhere' } }]) assert.throws(() => validateProtocol(bad));
    assert.equal(remaining(p, 100), 1459730.4162909985);
    assert.equal(remaining(p, 1459830.4162909985), 0);
    assert.throws(() => remaining(p, 1459831)); assert.throws(() => remaining(p, 99));
    assert.deepEqual(argumentsFor(targets, 'fresh.json'), ['muex', '--files', targets.join(','), '--test-paths', tests.join(','), ...flags, '--output', 'fresh.json']);
  });
  test('actual child failure timeout interruption freshness and finally restore', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'muex-quick-'));
    try {
      const path = join(dir, 'bytes'); fresh(path); writeFileSync(path, 'original'); assert.throws(() => fresh(path));
      successful(await child(process.execPath, ['-e', 'process.exit(0)']));
      const fail = await child(process.execPath, ['-e', 'process.exit(7)']); assert.equal(fail.exit, 7); assert.throws(() => successful(fail));
      const timeout = await child(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { timeoutMs: 80 }); assert(timeout.timedOut); assert.throws(() => successful(timeout));
      const controller = new AbortController(); const pending = child(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { abortSignal: controller.signal }); setTimeout(() => controller.abort(), 40); const interrupted = await pending; assert(interrupted.interrupted); assert.throws(() => successful(interrupted));
      await assert.rejects(restored(path, async () => { writeFileSync(path, 'changed'); throw new Error('injected'); })); assert.equal(readFileSync(path, 'utf8'), 'original');
    } finally { rmSync(dir, { recursive: true, force: true }); }
    assert(performance.now() - started < 20000, 'quick-deadline');
  });
} else { console.log(JSON.stringify({ status: 'refused', reason: command === 'controls' ? 'useful-bootstrap-and-real-adapter-required' : 'unknown-stage' })); process.exitCode = 1; }
