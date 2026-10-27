import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, existsSync, unlinkSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
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
  'swift-request': {
    resource: 'packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json',
    owner: 'packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift',
    loaded: 15, completed: 14, excluded: 'elixir_only',
    plan: [{ command: 'swift', args: ['package', 'clean'], cwd: 'packages/crosswake-shell-core-ios' },
           { command: 'swift', args: ['test', '--filter', 'BridgeConformanceTests'], cwd: 'packages/crosswake-shell-core-ios' }],
  },
};
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
function specFor(mode) { assert.ok(Object.hasOwn(specs, mode), 'unknown-reader'); return specs[mode]; }
function population(bytes, spec) {
  assert.ok(bytes, 'missing-input');
  const corpus = JSON.parse(bytes);
  assert.ok(Array.isArray(corpus.vectors), 'missing-vectors');
  assert.equal(corpus.vectors.length, spec.loaded, 'loaded-count');
  assert.equal(new Set(corpus.vectors.map(v => v.id)).size, spec.loaded, 'duplicate-ids');
  assert.equal(corpus.vectors.filter(v => v[spec.excluded] !== true).length, spec.completed, 'completed-count');
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
    assert.equal(spec.resource, mode === 'elixir' ? 'test/fixtures/bridge_contract_vectors.json'
      : 'packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json');
    assert.equal(spec.owner, mode === 'elixir' ? 'test/crosswake/bridge/bridge_behavioral_vector_test.exs'
      : 'packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift');
    const expectedPlan = mode === 'elixir'
      ? [{ command: 'mix', args: ['test', 'test/crosswake/bridge/bridge_behavioral_vector_test.exs'], cwd: '.' }]
      : [{ command: 'swift', args: ['package', 'clean'], cwd: 'packages/crosswake-shell-core-ios' },
         { command: 'swift', args: ['test', '--filter', 'BridgeConformanceTests'], cwd: 'packages/crosswake-shell-core-ios' }];
    assert.deepEqual(spec.plan, expectedPlan);
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

function runConsumer(spec, expected) {
  const records = [];
  for (const [index, step] of spec.plan.entries()) {
    const result = child(step);
    const isTest = index === spec.plan.length - 1;
    if (!isTest || expected === 'pass') requireSuccess(result);
    else assert.notEqual(result.exit, 0, 'negative-control-passed');
    let tests;
    if (isTest) {
      if (spec.excluded === 'elixir_only') {
        assert.match(result.output, /Build complete!/, 'fresh-build-incomplete');
        assert.match(result.output, /Test Case '-\[CrosswakeShellCoreTests\.BridgeConformanceTests test_bridge_vectors_data_driven\]' started\./, 'request-test-not-discovered');
        // XCTest reports setup failures as both skipped and failed. Preserve that distinction;
        // the missing-resource control cannot receive credit for completed vector evaluations.
        const summary = result.output.match(/Executed ([1-9]\d*) tests?, with (?:(\d+) tests? skipped and )?(\d+) failures?/);
        assert.ok(summary, 'nonempty-test-discovery');
        tests = { discovered: Number(summary[1]), skipped: Number(summary[2] ?? 0), failures: Number(summary[3]) };
        assert.equal(tests.discovered, 3, 'reader-suite-count');
        if (expected !== 'missing') assert.equal(tests.skipped, 0, 'unexpected-test-skip');
        assert.doesNotMatch(result.output, /error: (?:emit-module|fatalError|compile command)/, 'unrelated-build-failure');
        if (expected === 'missing') assert.match(result.output, /CW-VECTOR-MISSING bridge_contract_vectors\.json/, 'missing-diagnostic');
        if (expected === 'loaded') assert.match(result.output, /CW-VECTOR-LOADED expected 15/, 'loaded-diagnostic');
        if (expected === 'completed') assert.match(result.output, /CW-VECTOR-COMPLETED expected 14/, 'completed-diagnostic');
        const failedCases = [...result.output.matchAll(/Test Case '-\[CrosswakeShellCoreTests\.BridgeConformanceTests (\w+)\]' failed/g)].map(m => m[1]);
        if (expected === 'pass') assert.equal(tests.failures, 0, 'unexpected-test-failure');
        else if (expected !== 'missing') assert.deepEqual(failedCases, ['test_bridge_vectors_data_driven'], 'unrelated-test-failure');
      } else if (expected === 'missing') {
        assert.match(result.output, /could not read file .*bridge_contract_vectors\.json.*no such file or directory/s, 'missing-diagnostic');
      } else {
        assert.match(result.output, /1 test, [01] failures?/, 'nonempty-test-discovery');
        tests = { discovered: 1, skipped: 0, failures: expected === 'pass' ? 0 : 1 };
        if (expected === 'loaded') assert.match(result.output, /CW-VECTOR-LOADED expected 15/, 'loaded-diagnostic');
        if (expected === 'completed') assert.match(result.output, /CW-VECTOR-COMPLETED expected 9/, 'completed-diagnostic');
      }
    }
    records.push({ ...step, exit: result.exit, durationMs: result.durationMs, outputSha256: hash(result.output), ...(tests ? { tests } : {}) });
  }
  return records;
}
function full(mode) {
  const started = performance.now();
  const spec = specFor(mode);
  const path = resolve(root, spec.resource);
  const original = readFileSync(path);
  const corpus = JSON.parse(original);
  population(original, spec);
  const records = [];
  const before = runConsumer(spec, 'pass');
  let after;
  try {
    withBytes(path, original, () => {
      for (const control of ['missing', 'removed', 'empty', 'all-excluded']) {
        writeFileSync(path, original);
        if (control === 'missing') unlinkSync(path);
        else {
          const vectors = control === 'removed' ? corpus.vectors.slice(1)
            : control === 'empty' ? [] : corpus.vectors.map(v => ({ ...v, [spec.excluded]: true }));
          writeFileSync(path, JSON.stringify({ ...corpus, vectors }));
        }
        const mutatedHash = existsSync(path) ? hash(readFileSync(path)) : null;
        assert.notEqual(mutatedHash, hash(original), 'mutation-did-not-change-bytes');
        const expected = control === 'missing' ? 'missing' : control === 'all-excluded' ? 'completed' : 'loaded';
        const processes = runConsumer(spec, expected);
        records.push({ control, expected, mutatedSha256: mutatedHash, processes });
        process.stdout.write(`vector-control ${mode} ${control}: discriminating failure\n`);
      }
    });
  } finally {
    // Even a rejected control must leave both canonical bytes and copied build resources clean.
    assert.equal(hash(readFileSync(path)), hash(original), 'final-restoration-failed');
    after = runConsumer(spec, 'pass');
  }
  assert.equal(hash(readFileSync(path)), hash(original), 'final-restoration-failed');
  const receipt = {
    schema: 1, reader: mode, loaded: spec.loaded, completed: spec.completed,
    resource: spec.resource, resourceSha256: hash(original), owner: spec.owner,
    ownerSha256: hash(readFileSync(resolve(root, spec.owner))),
    helperSha256: hash(readFileSync(fileURLToPath(import.meta.url))),
    before, controls: records, restoration: { byteExact: true, after },
    durationMs: Math.round(performance.now() - started),
  };
  writeFileSync(resolve(root, phase, '196-EVIDENCE', mode === 'elixir' ? 'elixir-vectors.json' : 'swift-request-vectors.json'), `${JSON.stringify(receipt, null, 2)}\n`);
  process.stdout.write(`vector-controls ${mode}: 4 controls; loaded ${spec.loaded}; completed ${spec.completed}; restored; ${receipt.durationMs}ms\n`);
}

const [command, mode] = process.argv.slice(2);
if (command === 'quick') quick(mode);
else full(command);
