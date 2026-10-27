import assert from 'node:assert/strict';
import { test } from 'node:test';
import { spawn } from 'node:child_process';
import { performance } from 'node:perf_hooks';
import { mkdtempSync, existsSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

export const targets = ['lib/crosswake/offline/safe_observation.ex', 'lib/crosswake/offline/journal.ex', 'lib/crosswake/policy/compiler.ex', 'lib/crosswake/policy/route.ex', 'lib/crosswake/bridge/contract.ex'];
export const tests = ['test/crosswake/offline', 'test/crosswake/policy', 'test/crosswake/bridge'];
const flags = ['--no-filter', '--no-optimize', '--concurrency', '1', '--timeout', '10000', '--fail-at', '0', '--format', 'json'];
export function argumentsFor(files, output) { return ['muex', '--files', files.join(','), '--test-paths', tests.join(','), ...flags, '--output', output]; }
export function validateProtocol(p) { return p; }
export function remaining(p, now) { return p.budgetMs - (now - p.startedMonotonicMs); }
export function fresh(path) { assert(!existsSync(path), 'report-reused'); }
export async function child(command, args, options = {}) {
  const started = performance.now();
  return await new Promise((resolveResult) => {
    const proc = spawn(command, args, { cwd: options.cwd, env: options.env ?? process.env, detached: true, stdio: ['ignore', 'pipe', 'pipe'] });
    let output = '', timedOut = false;
    const timer = setTimeout(() => { timedOut = true; try { process.kill(-proc.pid, 'SIGKILL'); } catch {} }, options.timeoutMs ?? 1000);
    proc.stdout.on('data', d => { output += d; }); proc.stderr.on('data', d => { output += d; });
    proc.on('error', () => { clearTimeout(timer); resolveResult({ exit: null, timedOut, output: '', durationMs: performance.now() - started, spawnError: true }); });
    proc.on('close', (exit, signal) => { clearTimeout(timer); resolveResult({ exit, signal, timedOut, output, durationMs: performance.now() - started }); });
  });
}
export function successful(r) { assert.equal(r.timedOut, false, 'child-timeout'); assert.equal(r.exit, 0, 'child-failure'); }
export async function restored(path, operation) { const bytes = readFileSync(path); try { return await operation(); } finally { writeFileSync(path, bytes); assert.deepEqual(readFileSync(path), bytes); } }

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
      await assert.rejects(restored(path, async () => { writeFileSync(path, 'changed'); throw new Error('injected'); })); assert.equal(readFileSync(path, 'utf8'), 'original');
    } finally { rmSync(dir, { recursive: true, force: true }); }
    assert(performance.now() - started < 20000, 'quick-deadline');
  });
}
