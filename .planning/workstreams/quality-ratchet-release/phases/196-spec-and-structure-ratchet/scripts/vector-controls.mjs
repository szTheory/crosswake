import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, unlinkSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const root = resolve(fileURLToPath(new URL('../../../../../..', import.meta.url)));
const phase = '.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet';
const specs = {
  elixir: {
    resource: 'test/fixtures/bridge_contract_vectors.json',
    owner: 'test/crosswake/bridge/bridge_behavioral_vector_test.exs',
    loaded: 15, completed: 9, excluded: 'native_only',
    plan: [{ command: 'mix', args: ['test', 'test/crosswake/bridge/bridge_behavioral_vector_test.exs'], cwd: '.' }],
  },
};
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
function specFor(mode) { assert.ok(Object.hasOwn(specs, mode), 'unknown-reader'); return specs[mode]; }
function population(bytes, spec) {
  assert.ok(bytes, 'missing-input');
  const corpus = JSON.parse(bytes);
  // RED scaffold: count and eligibility rejection is added after the control fails.
  return corpus.vectors;
}
function child(step, timeout = 300000) {
  const started = performance.now();
  const result = spawnSync(step.command, step.args, {
    cwd: resolve(root, step.cwd), encoding: 'utf8', timeout,
    maxBuffer: 16 * 1024 * 1024, env: { ...process.env, NO_COLOR: '1' },
  });
  const output = `${result.stdout ?? ''}${result.stderr ?? ''}`;
  assert.ok(!result.error && result.signal === null, 'child-process-error');
  return { exit: result.status, output, durationMs: Math.round(performance.now() - started) };
}
function requireSuccess(result) { assert.equal(result.exit, 0, 'child-failed'); }
function withBytes(path, bytes, action) {
  try { return action(); }
  finally {
    writeFileSync(path, bytes);
    assert.equal(hash(readFileSync(path)), hash(bytes), 'restoration-failed');
  }
}
function quick(mode) {
  const started = performance.now();
  const spec = specFor(mode);
  test(`quick ${mode}: independently pinned population rejects lost inputs`, () => {
    const bytes = readFileSync(resolve(root, spec.resource));
    const corpus = JSON.parse(bytes);
    assert.equal(corpus.vectors.length, spec.loaded);
    assert.equal(corpus.vectors.filter(v => v[spec.excluded] !== true).length, spec.completed);
    population(bytes, spec);
    assert.throws(() => specFor('unknown'), /unknown-reader/);
    assert.throws(() => population(null, spec), /missing-input/);
    for (const vectors of [corpus.vectors.slice(1), [], corpus.vectors.map(v => ({ ...v, [spec.excluded]: true }))]) {
      assert.throws(() => population(JSON.stringify({ ...corpus, vectors }), spec), /loaded-count|completed-count/);
    }
  });
  test(`quick ${mode}: exact command plan, real child failure and finally restoration`, () => {
    assert.deepEqual(spec.plan, [{ command: 'mix', args: ['test', 'test/crosswake/bridge/bridge_behavioral_vector_test.exs'], cwd: '.' }]);
    const dir = mkdtempSync(join(tmpdir(), 'crosswake-vector-quick-'));
    const path = join(dir, 'synthetic');
    const bytes = Buffer.from('synthetic-original');
    writeFileSync(path, bytes);
    try {
      assert.throws(() => withBytes(path, bytes, () => {
        writeFileSync(path, 'synthetic-mutated');
        assert.notEqual(hash(readFileSync(path)), hash(bytes));
        requireSuccess(child({ command: process.execPath, args: ['-e', 'process.exit(7)'], cwd: '.' }, 2000));
      }), /child-failed/);
      assert.equal(hash(readFileSync(path)), hash(bytes));
      requireSuccess(child({ command: process.execPath, args: ['-e', 'process.exit(0)'], cwd: '.' }, 2000));
    } finally { rmSync(dir, { recursive: true, force: true }); }
    assert.ok(performance.now() - started < 20000, 'quick-deadline');
  });
}

const [command, mode] = process.argv.slice(2);
if (command === 'quick') quick(mode);
else throw new Error('unknown-command');
