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

// Remaining Swift owners have different reader contracts; keep the original modes intact.
const swiftPackage = 'packages/crosswake-shell-core-ios';
const swiftTests = `${swiftPackage}/Tests/CrosswakeShellCoreTests`;
const sharedResource = `${swiftTests}/Resources/bridge_contract_vectors.json`;
const swiftPlan = suite => [
  { command: 'swift', args: ['package', 'clean'], cwd: swiftPackage },
  { command: 'swift', args: ['test', '--filter', suite], cwd: swiftPackage },
];
const otherSpecs = {
  'swift-reply': [{ suite: 'BridgeReplyLegTests', symbol: 'test_committed_vectors_agree_with_the_shipped_landing_pad_name',
    kind: 'behavioral', resource: sharedResource, collection: 'reply_leg_vectors', loaded: 2, completed: 2,
    controls: ['missing', 'removed', 'empty', 'all-suppressed'] }],
  'swift-metadata': [
    { suite: 'ActivationConformanceTests', symbol: 'test_activation_success_resolves_to_liveView', completed: null },
    { suite: 'OfflineIslandAdmissionTests', symbol: 'test_offline_island_route_resolves_to_offlineIsland_presentation', completed: null },
    { suite: 'Phase180TwinFeasibilityTests', symbol: 'test_G3_invariant_activation_does_not_manufacture_registered_host_command', completed: null },
  ].map(spec => ({ ...spec, readerSymbol: 'setUpWithError', kind: 'metadata-only', resource: sharedResource,
    collection: 'vectors', loaded: 15, controls: ['missing', 'removed', 'empty'] })),
  'swift-topology': [{ suite: 'NavigationCoordinatorTests', symbol: 'testCompiledRootRequiresResolverAuthorization',
    kind: 'behavioral', resource: 'priv/contract_vectors/navigation_topology_vectors.json', collection: 'vectors',
    loaded: 5, selected: 1, completed: 1, selectedID: 'synthetic_authorized_root',
    controls: ['missing', 'removed', 'empty', 'selected-id-loss', 'duplicate-selected-id'] }],
};
function topologySelection(vectors, spec) {
  const selected = vectors.filter(v => v.id === spec.selectedID);
  assert.equal(selected.length, spec.selected, 'selected-count');
  return selected;
}
function otherPopulation(bytes, spec) {
  assert.ok(bytes, 'missing-input');
  const vectors = JSON.parse(bytes)[spec.collection];
  assert.ok(Array.isArray(vectors), 'missing-collection');
  assert.equal(vectors.length, spec.loaded, 'loaded-count');
  if (spec.selectedID) topologySelection(vectors, spec);
  assert.equal(new Set(vectors.map(v => v.id)).size, spec.loaded, 'duplicate-ids');
  if (spec.kind === 'metadata-only') assert.equal(spec.completed, null, 'metadata-execution-not-applicable');
  else assert.equal(spec.completed, spec.suite === 'BridgeReplyLegTests' ? 2 : 1, 'completed-count');
  return vectors;
}
function otherQuick(mode) {
  const started = performance.now();
  test(`quick ${mode}: reader-specific populations and loss controls`, () => {
    for (const spec of otherSpecs[mode]) {
      const bytes = readFileSync(resolve(root, spec.resource));
      const corpus = JSON.parse(bytes);
      otherPopulation(bytes, spec);
      assert.throws(() => otherPopulation(null, spec), /missing-input/);
      for (const vectors of [corpus[spec.collection].slice(1), []]) {
        assert.throws(() => otherPopulation(JSON.stringify({ ...corpus, [spec.collection]: vectors }), spec), /loaded-count/);
      }
      if (spec.kind === 'metadata-only') {
        assert.throws(() => otherPopulation(bytes, { ...spec, completed: 14 }), /metadata-execution-not-applicable/);
      } else {
        assert.throws(() => otherPopulation(bytes, { ...spec, completed: 0 }), /completed-count/);
        const requireCompleted = selected => assert.equal(selected.length, spec.completed, 'completed-count');
        requireCompleted(spec.selectedID ? topologySelection(corpus[spec.collection], spec) : corpus[spec.collection]);
        assert.throws(() => requireCompleted(corpus[spec.collection].filter(() => false)), /completed-count/);
        if (spec.selectedID) {
          assert.throws(() => topologySelection(corpus[spec.collection].map(v => ({ ...v, id: 'synthetic-unselected' })), spec), /selected-count/);
          const duplicate = corpus[spec.collection].map((v, i) => i === 1 ? { ...v, id: spec.selectedID } : v);
          assert.throws(() => topologySelection(duplicate, spec), /selected-count/);
        }
      }
    }
  });
  test(`quick ${mode}: exact owners, rebuilt command plans and failure restoration`, () => {
    const expected = {
      'swift-reply': ['BridgeReplyLegTests'],
      'swift-metadata': ['ActivationConformanceTests', 'OfflineIslandAdmissionTests', 'Phase180TwinFeasibilityTests'],
      'swift-topology': ['NavigationCoordinatorTests'],
    }[mode];
    assert.deepEqual(otherSpecs[mode].map(s => s.suite), expected, 'owner-roster');
    if (mode === 'swift-topology') readerInventory();
    for (const spec of otherSpecs[mode]) {
      assert.equal(spec.resource, spec.suite === 'NavigationCoordinatorTests'
        ? 'priv/contract_vectors/navigation_topology_vectors.json' : sharedResource, 'reader-resource');
      assert.ok(readFileSync(resolve(root, swiftTests, `${spec.suite}.swift`), 'utf8').includes(spec.symbol), 'reader-symbol');
      assert.deepEqual(swiftPlan(spec.suite), [
        { command: 'swift', args: ['package', 'clean'], cwd: 'packages/crosswake-shell-core-ios' },
        { command: 'swift', args: ['test', '--filter', spec.suite], cwd: 'packages/crosswake-shell-core-ios' },
      ]);
    }
    const dir = mkdtempSync(join(tmpdir(), 'crosswake-vector-quick-'));
    const path = join(dir, 'synthetic');
    const bytes = Buffer.from('synthetic-original');
    writeFileSync(path, bytes);
    try {
      assert.throws(() => withBytes(path, bytes, () => {
        writeFileSync(path, 'synthetic-mutated');
        requireSuccess(child({ command: process.execPath, args: ['-e', 'process.exit(7)'], cwd: '.' }, 2000));
      }), /child-failed/);
      assert.equal(hash(readFileSync(path)), hash(bytes));
    } finally { rmSync(dir, { recursive: true, force: true }); }
    assert.ok(performance.now() - started < 20000, 'quick-deadline');
  });
}
function otherConsumer(spec, expected) {
  return swiftPlan(spec.suite).map((step, index) => {
    const result = child(step);
    let tests;
    if (index === 0) requireSuccess(result);
    else {
      if (expected === 'pass') requireSuccess(result);
      else assert.notEqual(result.exit, 0, 'negative-control-passed');
      assert.match(result.output, /Build complete!/, 'fresh-build-incomplete');
      assert.ok(result.output.includes(`Test Case '-[CrosswakeShellCoreTests.${spec.suite} ${spec.symbol}]' started.`), 'reader-not-discovered');
      const summary = result.output.match(/Executed ([1-9]\d*) tests?, with (?:(\d+) tests? skipped and )?(\d+) failures?/);
      assert.ok(summary, 'nonempty-test-discovery');
      tests = { discovered: Number(summary[1]), skipped: Number(summary[2] ?? 0), failures: Number(summary[3]) };
      assert.equal(tests.discovered, { BridgeReplyLegTests: 8, ActivationConformanceTests: 4,
        OfflineIslandAdmissionTests: 15, Phase180TwinFeasibilityTests: 6, NavigationCoordinatorTests: 7 }[spec.suite], 'reader-suite-count');
      assert.doesNotMatch(result.output, /error: (?:emit-module|fatalError|compile command)/, 'unrelated-build-failure');
      if (expected === 'pass') {
        assert.equal(tests.failures, 0);
        assert.equal(tests.skipped, spec.suite === 'Phase180TwinFeasibilityTests' ? 2 : 0, 'unexpected-test-skip');
      }
      else {
        const diagnostic = expected === 'missing' ? 'CW-VECTOR-MISSING' : expected === 'loaded'
          ? `CW-VECTOR-LOADED expected ${spec.loaded}` : expected === 'selected'
          ? 'CW-VECTOR-SELECTED expected 1' : `CW-VECTOR-COMPLETED expected ${spec.completed}`;
        assert.ok(result.output.includes(diagnostic), 'intended-diagnostic-missing');
        const failed = [...result.output.matchAll(/Test Case '-\[CrosswakeShellCoreTests\.(\w+) (\w+)\]' failed/g)];
        assert.ok(failed.length > 0 && failed.every(m => m[1] === spec.suite), 'unrelated-test-failure');
        if (expected === 'completed' || expected === 'selected') assert.ok(failed.every(m => m[2] === spec.symbol), 'unrelated-case-failure');
      }
    }
    return { ...step, exit: result.exit, durationMs: result.durationMs, outputSha256: hash(result.output), ...(tests ? { tests } : {}) };
  });
}
function readerInventory() {
  const androidTests = 'packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core';
  const rows = [
    ['test/crosswake/bridge/bridge_behavioral_vector_test.exs', 'BridgeVectorBehavioralTest', 'behavioral', 'bridge_contract_vectors.json', '196-03'],
    [`${swiftTests}/BridgeConformanceTests.swift`, 'BridgeConformanceTests', 'behavioral', 'bridge_contract_vectors', '196-03'],
    [`${swiftTests}/BridgeReplyLegTests.swift`, 'BridgeReplyLegTests', 'behavioral', 'bridge_contract_vectors', '196-04'],
    [`${swiftTests}/NavigationCoordinatorTests.swift`, 'testCompiledRootRequiresResolverAuthorization', 'behavioral', 'navigation_topology_vectors.json', '196-04'],
    ...['ActivationConformanceTests', 'OfflineIslandAdmissionTests', 'Phase180TwinFeasibilityTests'].map(suite =>
      [`${swiftTests}/${suite}.swift`, 'setUpWithError', 'metadata-only', 'bridge_contract_vectors', '196-04']),
    [`${androidTests}/BridgeConformanceTest.kt`, 'BridgeConformanceTest', 'behavioral', 'bridge_contract_vectors.json', '196-05-pending'],
    [`${androidTests}/BridgeReplyLegTest.kt`, 'replyLegVector', 'behavioral', 'reply_leg_vectors', '196-05-pending'],
    [`${androidTests}/ActivationConformanceTest.kt`, 'ActivationConformanceTest', 'metadata-only', 'bridge_protocol_version', '196-05-pending'],
    ['test/crosswake/contract/contract_drift_test.exs', '@generated_json_paths', 'structural-integrity', 'bridge_contract_vectors.json', 'not-executed-by-this-plan'],
    ['lib/crosswake/doctor/publish_readiness.ex', 'contract_version_parity_check', 'structural-version', 'bridge_contract_vectors.json', 'not-executed-by-this-plan'],
    ['test/crosswake/proof/phase154_recipe_followable_test.exs', '@vector_paths', 'structural-vocabulary', 'bridge_contract_vectors.json', 'not-executed-by-this-plan'],
    ['test/crosswake/proof/phase154_catalog_guard_test.exs', 'CatalogGuard.bridge_sources()', 'structural-source-scan', 'bridge_contract_vectors.json', 'not-executed-by-this-plan'],
    ['lib/crosswake/proof_lane/navigation_shell_advisory.ex', 'transition_vectors', 'advisory-input', 'navigation_transition_vectors.json', 'not-native-execution'],
    ['lib/mix/tasks/crosswake.contract.gen.ex', 'write_if_changed', 'producer-integrity', 'bridge_contract_vectors.json', 'producer-not-behavioral-reader'],
    ['test/crosswake/proof/phase166_repository_quality_test.exs', 'remediation_command', 'reference-only', 'bridge_contract_vectors.json', 'path-inventory-not-json-reader'],
  ];
  assert.equal(rows.length, 17, 'reader-inventory-count');
  assert.equal(new Set(rows.map(row => row[0])).size, 17, 'reader-inventory-duplicates');
  return rows.map(([owner, symbol, kind, inputToken, verification]) => {
    const bytes = readFileSync(resolve(root, owner));
    assert.ok(bytes.toString().includes(symbol) && bytes.toString().includes(inputToken), 'reader-inventory-source-mismatch');
    return { owner, symbol, kind, input: inputToken, verification, corpusVerdictExecutions: kind === 'behavioral' ? 'reader-specific-see-owner-evidence' : 'not-applicable', sourceSha256: hash(bytes) };
  });
}
function otherFull(mode) {
  const started = performance.now();
  const readers = [];
  for (const spec of otherSpecs[mode]) {
    const path = resolve(root, spec.resource);
    const owner = `${swiftTests}/${spec.suite}.swift`;
    const ownerPath = resolve(root, owner);
    const original = readFileSync(path);
    const source = readFileSync(ownerPath);
    const corpus = JSON.parse(original);
    otherPopulation(original, spec);
    const before = otherConsumer(spec, 'pass');
    const controls = [];
    let after;
    try {
      withBytes(path, original, () => withBytes(ownerPath, source, () => {
        for (const control of spec.controls) {
          writeFileSync(path, original);
          writeFileSync(ownerPath, source);
          let expected = 'loaded';
          if (control === 'missing') { unlinkSync(path); expected = 'missing'; }
          else if (control === 'all-suppressed') {
            const mutated = source.toString().replace('for vector in vectors {', 'for vector in vectors.filter({ _ in false }) {');
            assert.notEqual(mutated, source.toString(), 'selection-seam-not-found');
            writeFileSync(ownerPath, mutated);
            expected = 'completed';
          } else {
            let vectors;
            if (control === 'selected-id-loss') {
              vectors = corpus[spec.collection].map(v => v.id === spec.selectedID ? { ...v, id: 'synthetic-unselected' } : v);
              expected = 'selected';
            } else if (control === 'duplicate-selected-id') {
              vectors = corpus[spec.collection].map((v, i) => i === 1 ? { ...v, id: spec.selectedID } : v);
              expected = 'selected';
            } else vectors = control === 'removed' ? corpus[spec.collection].slice(1) : [];
            writeFileSync(path, JSON.stringify({ ...corpus, [spec.collection]: vectors }));
          }
          const resourceHash = existsSync(path) ? hash(readFileSync(path)) : null;
          const ownerHash = hash(readFileSync(ownerPath));
          assert.ok(resourceHash !== hash(original) || ownerHash !== hash(source), 'mutation-did-not-change-bytes');
          const processes = otherConsumer(spec, expected);
          controls.push({ control, expected, resourceSha256: resourceHash, ownerSha256: ownerHash, processes });
          process.stdout.write(`vector-control ${mode} ${spec.suite} ${control}: discriminating failure\n`);
        }
      }));
    } finally {
      assert.equal(hash(readFileSync(path)), hash(original), 'resource-restoration-failed');
      assert.equal(hash(readFileSync(ownerPath)), hash(source), 'owner-restoration-failed');
      after = otherConsumer(spec, 'pass');
    }
    readers.push({ owner, symbol: spec.readerSymbol ?? spec.symbol, testSymbol: spec.symbol, kind: spec.kind, resource: spec.resource,
      loaded: spec.loaded, ...(spec.selected ? { selected: spec.selected } : {}), completed: spec.completed,
      selectionControl: spec.kind === 'metadata-only' ? 'not-applicable-no-filter' : 'applicable',
      resourceSha256: hash(original), ownerSha256: hash(source), before, controls, restoration: { byteExact: true, after } });
  }
  const receiptPath = resolve(root, phase, '196-EVIDENCE/swift-other-vectors.json');
  const receipt = existsSync(receiptPath) ? JSON.parse(readFileSync(receiptPath)) : { schema: 1, modes: {} };
  receipt.modes[mode] = { helperSha256: hash(readFileSync(fileURLToPath(import.meta.url))), readers, durationMs: Math.round(performance.now() - started) };
  if (mode === 'swift-topology') {
    receipt.inventory = readerInventory();
    receipt.inventoryScope = 'Existing bridge request/reply and navigation file references; source-checked roles, no new platform or device claim. Phase198 owns set hashes and parity ledger.';
  }
  writeFileSync(receiptPath, `${JSON.stringify(receipt, null, 2)}\n`);
  process.stdout.write(`vector-controls ${mode}: ${readers.length} owners restored; ${receipt.modes[mode].durationMs}ms\n`);
}

const [command, mode] = process.argv.slice(2);
if (Object.hasOwn(otherSpecs, command === 'quick' ? mode : command)) {
  if (command === 'quick') otherQuick(mode);
  else otherFull(command);
} else if (command === 'quick') quick(mode);
else full(command);
