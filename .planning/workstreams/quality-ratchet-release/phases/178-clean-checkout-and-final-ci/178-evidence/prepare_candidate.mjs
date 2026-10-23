import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

export const BASE_COMMIT = 'd0dbdf7bf196cea167ced3c50cf620bf3cb2452b';
export const BASE_TREE = '12a0f1bf3c32ecdde0326f4a288b597b11e33b06';
export const INITIAL_PATHS = Object.freeze([
  'README.md',
  'docs/COMPANION-PUBLISH-RUNBOOK.md',
  'docs/RELEASE-INCIDENT-RESPONSE.md',
  'test/crosswake/guides/release_boundaries_test.exs',
  'test/crosswake/release_candidate/companion_receipt_test.exs',
  'test/crosswake/release_candidate/evidence_gate_test.exs',
]);
export const REPAIR_PATHS = Object.freeze([
  'script/collection_assertion_ledger.json',
  'script/collection_assertion_remediation.json',
  'test/crosswake/guides/release_boundaries_test.exs',
]);
export const ALLOWED_PATHS = Object.freeze([...new Set([...INITIAL_PATHS, ...REPAIR_PATHS])].sort());

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../../../../../..');
const SOURCE_BINDING = path.join(ROOT, '.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/source-binding.json');
const SEMANTIC = path.join(ROOT, '.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-evidence/semantic-reconciliation.json');
const PHASE177_PRIVATE_POINTER = '/private/tmp/crosswake-177-owner-env';
const BUNDLE_NAME = 'cumulative-177-05.bundle.json';
const BINDING_NAME = 'candidate-binding.json';
const PUBLIC_NAME = path.join(ROOT, '.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-evidence/candidate-source.json');

export function safeFailure(cause) { return { ok: false, cause: SAFE_CAUSES.has(cause) ? cause : 'verification-failed' }; }
const SAFE_CAUSES = new Set(['wrong-base', 'invalid-bundle', 'path-set-mismatch', 'symlink-escape', 'dirty-proof', 'missing-private-handoff', 'source-identity', 'semantic-reconciliation', 'candidate-binding', 'missing-environment', 'clone-failed', 'apply-failed', 'commit-failed', 'proof-failed', 'public-binding', 'derived-snapshot-drift']);

function fail(cause, message = 'candidate preparation failed') {
  const err = new Error(message); err.safeCause = SAFE_CAUSES.has(cause) ? cause : 'verification-failed'; throw err;
}
function digest(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function readJson(file, cause = 'verification-failed') { try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { fail(cause); } }
function readPrivateJson(file, cause = 'candidate-binding') {
  let st; try { st = fs.lstatSync(file); } catch { fail(cause); }
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o077) !== 0) fail(cause);
  return readJson(file, cause);
}
function decodeBase64(text) {
  if (typeof text !== 'string' || !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(text)) return null;
  const bytes = Buffer.from(text, 'base64'); return bytes.toString('base64') === text ? bytes : null;
}
function validRelPath(rel) {
  return typeof rel === 'string' && rel.length > 0 && !rel.startsWith('/') && !rel.includes('\\') &&
    rel.split('/').every(part => part && part !== '.' && part !== '..') && !rel.includes('\0');
}
function patchPaths(patch) {
  const found = new Set();
  for (const line of patch.toString('utf8').split('\n')) {
    if (!line.startsWith('diff --git ')) continue;
    const m = /^diff --git a\/([^\s]+) b\/([^\s]+)$/.exec(line);
    if (!m || m[1] !== m[2] || !validRelPath(m[1])) return null;
    found.add(m[1]);
  }
  return [...found].sort();
}
export function validateBundle(bundle, expected) {
  if (!bundle || typeof bundle !== 'object' || bundle.baseCommit !== expected.baseCommit || bundle.baseTree !== expected.baseTree) return safeFailure('wrong-base');
  const patch = decodeBase64(bundle.patchBase64);
  if (!patch || !Array.isArray(bundle.untracked) || bundle.patchBytes !== patch.length || bundle.patchDigest !== digest(patch) || bundle.untrackedFiles !== bundle.untracked.length) return safeFailure('invalid-bundle');
  const paths = patchPaths(patch);
  if (!paths) return safeFailure('invalid-bundle');
  const untrackedPaths = [];
  for (const entry of bundle.untracked) {
    if (!entry || !validRelPath(entry.path) || !Number.isInteger(entry.mode) || entry.mode < 0 || entry.mode > 0o777 || !decodeBase64(entry.bytes) || !decodeBase64(entry.patch)) return safeFailure('invalid-bundle');
    untrackedPaths.push(entry.path);
  }
  if (new Set(untrackedPaths).size !== untrackedPaths.length || untrackedPaths.some(p => !paths.includes(p))) return safeFailure('path-set-mismatch');
  const untrackedPatch = Buffer.concat(bundle.untracked.map(entry => decodeBase64(entry.patch)));
  if (untrackedPatch.length && !patch.subarray(patch.length - untrackedPatch.length).equals(untrackedPatch)) return safeFailure('invalid-bundle');
  const all = paths;
  const wanted = [...expected.paths].sort();
  if (new Set(all).size !== all.length || JSON.stringify(all) !== JSON.stringify(wanted)) return safeFailure('path-set-mismatch');
  return { ok: true, patch, paths: all };
}

function git(repo, args, options = {}) {
  const result = spawnSync('git', ['-C', repo, ...args], {
    encoding: null, timeout: 120000, input: options.input,
    env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', ...(options.env || {}) },
  });
  if (result.error || result.signal || result.status !== 0) fail(options.cause || 'verification-failed');
  return { stdout: Buffer.from(result.stdout || []), stderr: Buffer.from(result.stderr || []), status: result.status, signal: result.signal, error: result.error };
}
function out(repo, args) { return git(repo, args).stdout.toString('utf8').trim(); }
function sha(repo, ref) { return out(repo, ['rev-parse', ref]); }
function indexMatchesHead(repo) {
  const diff = spawnSync('git', ['-C', repo, 'diff', '--cached', '--quiet', 'HEAD', '--'], {
    encoding: null, timeout: 30000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' },
  });
  if (diff.error || diff.signal || diff.status !== 0) return false;
  const index = git(repo, ['ls-files', '--stage', '-z']).stdout;
  const tree = git(repo, ['ls-tree', '-r', '-z', '--full-tree', 'HEAD']).stdout;
  const indexRows = index.toString('utf8').split('\0').filter(Boolean).map(row => {
    const match = /^(\d{6}) ([0-9a-f]+) 0\t([\s\S]*)$/.exec(row);
    return match ? `${match[1]} ${match[2]}\t${match[3]}` : null;
  });
  const treeRows = tree.toString('utf8').split('\0').filter(Boolean).map(row => {
    const match = /^(\d{6}) (?:blob|commit) ([0-9a-f]+)\t([\s\S]*)$/.exec(row);
    return match ? `${match[1]} ${match[2]}\t${match[3]}` : null;
  });
  if (indexRows.includes(null) || treeRows.includes(null)) return false;
  return JSON.stringify(indexRows.sort()) === JSON.stringify(treeRows.sort());
}
function statusPaths(repo) {
  const raw = git(repo, ['status', '--porcelain=v1', '-z', '--untracked-files=all']).stdout;
  const fields = raw.toString('utf8').split('\0').filter(Boolean); return fields.map(x => x.slice(3)).sort();
}
function changedPaths(repo, base, commit) {
  return out(repo, ['diff-tree', '--no-commit-id', '--name-only', '-r', base, commit]).split('\n').filter(Boolean).sort();
}
function assertNoSymlinkEscape(repo, rel) {
  if (!validRelPath(rel)) fail('symlink-escape');
  let cursor = repo;
  for (const part of rel.split('/')) {
    cursor = path.join(cursor, part);
    let stat;
    try { stat = fs.lstatSync(cursor); } catch (err) { if (err.code === 'ENOENT') continue; throw err; }
    if (stat.isSymbolicLink()) fail('symlink-escape');
  }
}
export function assertDeliveryPathSafe(repo, rel) { assertNoSymlinkEscape(repo, rel); return true; }
function expectedBlobIds(patch) {
  const result = new Map(); let current = null;
  for (const line of patch.toString('utf8').split('\n')) {
    const header = /^diff --git a\/([^\s]+) b\/([^\s]+)$/.exec(line);
    if (header) { current = header[1]; continue; }
    const index = /^index [0-9a-f]+\.\.([0-9a-f]+)(?: [0-7]{6})?$/.exec(line);
    if (current && index) result.set(current, index[1]);
  }
  return result;
}
function verifyAppliedPatch(repo, patch, paths) {
  const ids = expectedBlobIds(patch);
  for (const rel of paths) {
    if (ids.has(rel)) {
      const actual = out(repo, ['hash-object', '--', rel]);
      if (!ids.get(rel).startsWith(actual.slice(0, ids.get(rel).length))) fail('apply-failed');
    }
  }
}
export function assertCleanProof(repo, commit, tree) {
  if (sha(repo, 'HEAD') !== commit || sha(repo, 'HEAD^{tree}') !== tree || !indexMatchesHead(repo) || out(repo, ['status', '--porcelain=v1', '-z', '--untracked-files=all']) !== '') fail('dirty-proof');
  return true;
}
export function replayBundle(repo, bundle, expected, options = {}) {
  const validated = validateBundle(bundle, expected);
  if (!validated.ok) fail(validated.cause);
  for (const rel of validated.paths) assertNoSymlinkEscape(repo, rel);
  const applied = spawnSync('git', ['-C', repo, 'apply', '--binary', '--'], { input: validated.patch, encoding: null, timeout: 30000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  if (applied.error || applied.signal || applied.status !== 0) fail('apply-failed');
  verifyAppliedPatch(repo, validated.patch, validated.paths);
  for (const entry of bundle.untracked) {
    const target = path.resolve(repo, entry.path);
    if (!pathWithinRoot(target, repo)) fail('symlink-escape');
    assertNoSymlinkEscape(repo, entry.path);
    const actual = fs.readFileSync(target);
    const mode = fs.statSync(target).mode & 0o777;
    if (!actual.equals(decodeBase64(entry.bytes)) || mode !== entry.mode) fail('apply-failed');
  }
  const expectedStatus = options.statusPaths || expected.paths;
  if (JSON.stringify(statusPaths(repo)) !== JSON.stringify([...expectedStatus].sort())) fail('path-set-mismatch');
  return { paths: validated.paths, gitStatus: applied.status };
}

const keySet = value => value && typeof value === 'object' && !Array.isArray(value) ? Object.keys(value).sort() : null;
function normalizeLineRefs(value) {
  return typeof value === 'string' ? value.replace(/(\bline\s+|:)(\d+)(?=\b|\D)/g, '$1#') : value;
}
function sameWithLineRefs(a, b) { return JSON.stringify(normalizeLineRefs(a)) === JSON.stringify(normalizeLineRefs(b)); }
function indexRows(rows, count, requiredFields) {
  if (!Array.isArray(rows) || rows.length !== count) fail('derived-snapshot-drift');
  const map = new Map();
  for (const row of rows) {
    if (!row || typeof row.key !== 'string' || map.has(row.key) || JSON.stringify(keySet(row)) !== JSON.stringify([...requiredFields].sort())) fail('derived-snapshot-drift');
    map.set(row.key, row);
  }
  return map;
}
export function assertDerivedSnapshots(oldRoot, finalRoot) {
  let oldLedger, newLedger, oldRemediation, newRemediation;
  try {
    oldLedger = JSON.parse(fs.readFileSync(path.join(oldRoot, 'script/collection_assertion_ledger.json'), 'utf8'));
    newLedger = JSON.parse(fs.readFileSync(path.join(finalRoot, 'script/collection_assertion_ledger.json'), 'utf8'));
    oldRemediation = JSON.parse(fs.readFileSync(path.join(oldRoot, 'script/collection_assertion_remediation.json'), 'utf8'));
    newRemediation = JSON.parse(fs.readFileSync(path.join(finalRoot, 'script/collection_assertion_remediation.json'), 'utf8'));
  } catch { fail('derived-snapshot-drift'); }
  for (const field of ['scope', 'generator', 'sunset']) if (oldLedger[field] !== newLedger[field]) fail('derived-snapshot-drift');
  if (JSON.stringify(keySet(oldLedger)) !== JSON.stringify(keySet(newLedger))) fail('derived-snapshot-drift');
  const ledgerFields = ['key', 'shape', 'bucket', 'rationale', 'display', 'enclosing', 'expression'];
  const oldRows = indexRows(oldLedger.rows, 230, ledgerFields);
  const newRows = indexRows(newLedger.rows, 230, ledgerFields);
  if (JSON.stringify([...oldRows.keys()].sort()) !== JSON.stringify([...newRows.keys()].sort())) fail('derived-snapshot-drift');
  const buckets = new Map();
  for (const [key, oldRow] of oldRows) {
    const row = newRows.get(key);
    for (const field of ['shape', 'bucket', 'expression']) if (oldRow[field] !== row[field]) fail('derived-snapshot-drift');
    for (const field of ['rationale', 'display', 'enclosing']) if (!sameWithLineRefs(oldRow[field], row[field])) fail('derived-snapshot-drift');
    buckets.set(row.bucket, (buckets.get(row.bucket) || 0) + 1);
  }
  if (JSON.stringify([...buckets].sort()) !== JSON.stringify([['safe-by-construction', 134], ['safe-cardinality-pinned', 32], ['safe-compile-time-literal', 4], ['safe-guarded', 60]].sort())) fail('derived-snapshot-drift');
  if (JSON.stringify(keySet(oldRemediation)) !== JSON.stringify(keySet(newRemediation))) fail('derived-snapshot-drift');
  for (const field of ['frozen_at', 'generator', 'note']) if (oldRemediation[field] !== newRemediation[field]) fail('derived-snapshot-drift');
  const remediationFields = ['key', 'shape', 'display', 'enclosing', 'expression'];
  const oldFrozen = indexRows(oldRemediation.rows, 52, remediationFields);
  const newFrozen = indexRows(newRemediation.rows, 52, remediationFields);
  if (JSON.stringify([...oldFrozen.keys()].sort()) !== JSON.stringify([...newFrozen.keys()].sort())) fail('derived-snapshot-drift');
  for (const [key, oldRow] of oldFrozen) {
    const row = newFrozen.get(key);
    if (oldRow.shape !== row.shape || oldRow.expression !== row.expression) fail('derived-snapshot-drift');
    for (const field of ['display', 'enclosing']) if (!sameWithLineRefs(oldRow[field], row[field])) fail('derived-snapshot-drift');
  }
  return { ledgerRows: oldRows.size, remediationRows: oldFrozen.size, bucketCounts: Object.fromEntries([...buckets].sort()) };
}
export function replayRenewal(repo, originalBundle, repairBundle, oldBinding, canonicalOrigin) {
  if (!oldBinding || oldBinding.sourceBaseCommit !== BASE_COMMIT || oldBinding.sourceBaseTree !== BASE_TREE || oldBinding.selectedPaths?.length !== INITIAL_PATHS.length) fail('candidate-binding');
  const oldPaths = [...INITIAL_PATHS].sort();
  replayBundle(repo, originalBundle, { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, paths: INITIAL_PATHS });
  for (const rel of INITIAL_PATHS) git(repo, ['add', '--', rel]);
  if (out(repo, ['write-tree']) !== oldBinding.candidateTree) fail('candidate-binding');
  const repairExpected = { baseCommit: oldBinding.candidateCommit, baseTree: oldBinding.candidateTree, paths: REPAIR_PATHS };
  const baseline = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-derived-before-'));
  fs.chmodSync(baseline, 0o700);
  try {
    for (const rel of REPAIR_PATHS.filter(p => p.endsWith('.json'))) {
      fs.copyFileSync(path.join(repo, rel), path.join(baseline, path.basename(rel)));
    }
    // Snapshot comparisons use a flat private fixture directory to avoid touching the clone.
    const baselineLedger = path.join(baseline, 'script/collection_assertion_ledger.json');
    const baselineRemediation = path.join(baseline, 'script/collection_assertion_remediation.json');
    fs.mkdirSync(path.dirname(baselineLedger), { recursive: true, mode: 0o700 });
    fs.renameSync(path.join(baseline, 'collection_assertion_ledger.json'), baselineLedger);
    fs.renameSync(path.join(baseline, 'collection_assertion_remediation.json'), baselineRemediation);
    replayBundle(repo, repairBundle, repairExpected, { statusPaths: ALLOWED_PATHS });
    assertDerivedSnapshots(baseline, repo);
  } finally { fs.rmSync(baseline, { recursive: true, force: true }); }
  for (const rel of ALLOWED_PATHS) git(repo, ['add', '--', rel]);
  const candidateTree = out(repo, ['write-tree']);
  if (JSON.stringify(out(repo, ['diff', '--cached', '--name-only', '-z']).split('\0').filter(Boolean).sort()) !== JSON.stringify([...ALLOWED_PATHS].sort())) fail('path-set-mismatch');
  if (canonicalOrigin) fetchCanonicalBase(repo, canonicalOrigin);
  return { oldPaths, candidateTree, selectedPaths: [...ALLOWED_PATHS].sort() };
}
function ensurePrivateDir(dir) {
  fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
  const st = fs.lstatSync(dir);
  if (!st.isDirectory() || (st.mode & 0o077) !== 0) fail('missing-private-handoff');
}
function writeImmutable(file, content) {
  if (fs.existsSync(file)) fail('candidate-binding');
  const tmp = `${file}.tmp-${crypto.randomBytes(6).toString('hex')}`;
  const fd = fs.openSync(tmp, 'wx', 0o600);
  try { fs.writeFileSync(fd, `${JSON.stringify(content, null, 2)}\n`); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  fs.renameSync(tmp, file); fs.chmodSync(file, 0o600);
}
function atomicPublic(content) {
  const tmp = `${PUBLIC_NAME}.tmp-${crypto.randomBytes(5).toString('hex')}`;
  fs.mkdirSync(path.dirname(PUBLIC_NAME), { recursive: true });
  fs.writeFileSync(tmp, `${JSON.stringify(content, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(tmp, PUBLIC_NAME); fs.chmodSync(PUBLIC_NAME, 0o644);
}
function ownerPrivateRoot() {
  let pointer;
  try { const ps = fs.lstatSync(PHASE177_PRIVATE_POINTER); if (!ps.isFile() || ps.isSymbolicLink() || (ps.mode & 0o077) !== 0) fail('missing-private-handoff'); pointer = fs.readFileSync(PHASE177_PRIVATE_POINTER, 'utf8'); } catch { fail('missing-private-handoff'); }
  const match = /^CROSSWAKE_177_PRIVATE_HANDOFF='([^']+)'$/m.exec(pointer);
  if (!match) fail('missing-private-handoff');
  const root = path.resolve(match[1]); const st = fs.lstatSync(root);
  if (!st.isDirectory() || (st.mode & 0o077) !== 0) fail('missing-private-handoff');
  return root;
}
function ownerBundle(ownerRoot) {
  const file = path.join(ownerRoot, BUNDLE_NAME); const st = fs.lstatSync(file);
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o077) !== 0) fail('missing-private-handoff');
  return fs.readFileSync(file);
}
function privatePointerRoot(pointerFile) {
  let contents; let st;
  try { st = fs.lstatSync(pointerFile); contents = fs.readFileSync(pointerFile, 'utf8'); } catch { fail('missing-private-handoff'); }
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o077) !== 0) fail('missing-private-handoff');
  const env = /^CROSSWAKE_178_PRIVATE_HANDOFF='([^']+)'$/m.exec(contents);
  const raw = env ? env[1] : contents.trim();
  if (!path.isAbsolute(raw) || raw.includes('\n')) fail('missing-private-handoff');
  const root = path.resolve(raw); const rootStat = fs.lstatSync(root);
  if (!rootStat.isDirectory() || rootStat.isSymbolicLink() || (rootStat.mode & 0o077) !== 0) fail('missing-private-handoff');
  return root;
}
function privateFile(root, basename) {
  if (!validRelPath(basename) || basename.includes('/')) fail('missing-private-handoff');
  const file = path.join(root, basename); const st = fs.lstatSync(file);
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o077) !== 0) fail('missing-private-handoff');
  return file;
}
function canonicalOriginAndMain() {
  const origin = out(ROOT, ['remote', 'get-url', 'origin']);
  let url; try { url = new URL(origin); } catch { fail('source-identity'); }
  const repoName = url.pathname.split('/').filter(Boolean).at(-1)?.replace(/\.git$/, '');
  if (url.protocol !== 'https:' || url.hostname !== 'github.com' || url.username || url.password || repoName !== 'crosswake') fail('source-identity');
  const r = spawnSync('git', ['ls-remote', '--exit-code', origin, 'refs/heads/main'], { encoding: null, timeout: 30000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  if (r.error || r.signal || r.status !== 0) fail('source-identity');
  const row = Buffer.from(r.stdout || []).toString('utf8').trim().split('\n').find(line => line.endsWith('\trefs/heads/main'));
  const mainCommit = row?.split(/\s+/)[0];
  if (mainCommit !== BASE_COMMIT) fail('source-identity');
  return { origin, mainCommit };
}
function fetchCanonicalBase(repo, origin) {
  const r = spawnSync('git', ['-C', repo, 'fetch', '--no-write-fetch-head', '--no-tags', origin, BASE_COMMIT], { encoding: null, timeout: 60000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  if (r.error || r.signal || r.status !== 0 || sha(repo, `${BASE_COMMIT}^{commit}`) !== BASE_COMMIT || sha(repo, `${BASE_COMMIT}^{tree}`) !== BASE_TREE) fail('source-identity');
}
function verifyBundleProducesTree(bundle, sourceRoot, canonicalOrigin, candidateTree) {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-bundle-check-'));
  fs.chmodSync(temp, 0o700);
  try {
    const replayRoot = path.join(temp, 'replay'); clone(sourceRoot, replayRoot);
    if (sha(replayRoot, 'HEAD') !== BASE_COMMIT || sha(replayRoot, 'HEAD^{tree}') !== BASE_TREE) fail('source-identity');
    fetchCanonicalBase(replayRoot, canonicalOrigin);
    replayBundle(replayRoot, bundle, { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, paths: INITIAL_PATHS });
    for (const rel of INITIAL_PATHS) git(replayRoot, ['add', '--', rel]);
    if (out(replayRoot, ['write-tree']) !== candidateTree) fail('candidate-binding');
  } finally { fs.rmSync(temp, { recursive: true, force: true }); }
}
function validatePublicInputs() {
  const source = readJson(SOURCE_BINDING);
  const semantic = readJson(SEMANTIC);
  if (source.baseCommit !== BASE_COMMIT || source.baseTree !== BASE_TREE || source.selectedCount !== 119 || source.status !== 'complete-qualified') fail('source-identity');
  if (semantic.baseCommit !== BASE_COMMIT || semantic.baseTree !== BASE_TREE || semantic.status !== 'semantic-selection-complete') fail('semantic-reconciliation');
  return { source, semantic };
}
function pathWithinRoot(candidate, root) {
  const rel = path.relative(root, candidate);
  return rel === '' || (!rel.startsWith(`..${path.sep}`) && rel !== '..' && !path.isAbsolute(rel));
}
function clone(source, target, from = 'source') {
  if (fs.existsSync(target)) fail('clone-failed');
  fs.mkdirSync(path.dirname(target), { recursive: true, mode: 0o700 });
  const result = spawnSync('git', ['clone', '--no-local', source, target], { encoding: null, timeout: 120000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  if (result.error || result.signal || result.status !== 0) fail(from === 'proof' ? 'proof-failed' : 'clone-failed');
  fs.chmodSync(target, 0o700);
  return { status: result.status, signal: result.signal, error: result.error };
}
function ensureEmptyOrAbsent(dir) { if (fs.existsSync(dir)) fail('clone-failed'); }

function prepare() {
  const privateRoot = process.env.CROSSWAKE_178_PRIVATE_HANDOFF_ROOT;
  const delivery = process.env.CROSSWAKE_178_DELIVERY_ROOT;
  const proof = process.env.CROSSWAKE_178_PROOF_ROOT;
  if (![privateRoot, delivery, proof].every(v => typeof v === 'string' && path.isAbsolute(v))) fail('missing-environment');
  const roots = [privateRoot, delivery, proof].map(v => path.resolve(v));
  if (new Set(roots).size !== 3 || roots.some(r => pathWithinRoot(r, ROOT) || pathWithinRoot(ROOT, r))) fail('missing-environment');
  ensureEmptyOrAbsent(delivery); ensureEmptyOrAbsent(proof); ensurePrivateDir(privateRoot);
  const ownerRoot = ownerPrivateRoot();
  const { source, semantic } = validatePublicInputs();
  const bundleBytes = ownerBundle(ownerRoot);
  const bundle = JSON.parse(bundleBytes.toString('utf8'));
  if (bundle.schemaVersion !== 1 || bundle.baseCommit !== BASE_COMMIT || bundle.baseTree !== BASE_TREE) fail('wrong-base');
  const validated = validateBundle(bundle, { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, paths: INITIAL_PATHS });
  if (!validated.ok) fail(validated.cause);
  const canonical = canonicalOriginAndMain();
  const sourceRoot = '/private/tmp/crosswake-177-source/crosswake';
  if (path.basename(out(sourceRoot, ['rev-parse', '--show-toplevel'])) !== 'crosswake' || sha(sourceRoot, 'HEAD') !== BASE_COMMIT || sha(sourceRoot, 'HEAD^{tree}') !== BASE_TREE) fail('source-identity');
  // The attested independent source may carry retained working-tree edits. Clone from its exact
  // HEAD only; --no-local ensures those uncommitted bytes are never copied into delivery.
  clone(sourceRoot, delivery);
  if (sha(delivery, 'HEAD') !== BASE_COMMIT || sha(delivery, 'HEAD^{tree}') !== BASE_TREE) fail('source-identity');
  fetchCanonicalBase(delivery, canonical.origin);
  replayBundle(delivery, bundle, { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, paths: INITIAL_PATHS });
  for (const rel of INITIAL_PATHS) git(delivery, ['add', '--', rel]);
  if (out(delivery, ['diff', '--cached', '--name-only', '-z']).split('\0').filter(Boolean).sort().join('\0') !== [...INITIAL_PATHS].sort().join('\0')) fail('path-set-mismatch');
  const commitResult = spawnSync('git', ['-C', delivery, 'commit', '-m', 'chore(178-01): qualify maintenance candidate'], { encoding: null, timeout: 120000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_AUTHOR_NAME: 'Crosswake Maintainer', GIT_AUTHOR_EMAIL: 'maintainer@example.invalid', GIT_COMMITTER_NAME: 'Crosswake Maintainer', GIT_COMMITTER_EMAIL: 'maintainer@example.invalid' } });
  if (commitResult.error || commitResult.signal || commitResult.status !== 0) fail('commit-failed');
  const candidateCommit = sha(delivery, 'HEAD'); const candidateTree = sha(delivery, 'HEAD^{tree}');
  if (out(delivery, ['status', '--porcelain=v1', '-z', '--untracked-files=all']) !== '') fail('commit-failed');
  if (out(delivery, ['rev-parse', `${candidateCommit}^`]) !== BASE_COMMIT || JSON.stringify(changedPaths(delivery, BASE_COMMIT, candidateCommit)) !== JSON.stringify([...INITIAL_PATHS].sort())) fail('commit-failed');
  clone(delivery, proof, 'proof');
  git(proof, ['checkout', '--detach', candidateCommit]);
  try { assertCleanProof(proof, candidateCommit, candidateTree); } catch { fail('proof-failed'); }
  const publicProjection = {
    schemaVersion: 1,
    phase: 178,
    plan: '01',
    status: 'source-qualified',
    sourceBaseCommit: BASE_COMMIT,
    sourceBaseTree: BASE_TREE,
    candidateCommit,
    candidateTree,
    selectedPaths: INITIAL_PATHS,
    selectedCount: INITIAL_PATHS.length,
    proofClone: 'clean-detached-exact-commit',
    canonicalMainMatchesBase: true,
    retainedRows: source.selectedCount,
    historicalReaderComparisons: 'unproven-2',
    requirements: { 'MAINT-07': 'pending-full-run', 'MAINT-08': 'pending-hosted-ci' },
  };
  atomicPublic(publicProjection);
  const binding = {
    schemaVersion: 1,
    phase: 178,
    plan: '01',
    sourceBaseCommit: BASE_COMMIT,
    sourceBaseTree: BASE_TREE,
    candidateCommit,
    candidateTree,
    selectedPaths: INITIAL_PATHS,
    ownerPrivateRoot: ownerRoot,
    privateHandoffRoot: privateRoot,
    deliveryRoot: delivery,
    proofRoot: proof,
    bundleSha256: digest(bundleBytes),
    patchSha256: digest(validated.patch),
    semanticBindingDigest: semantic.bindingDigest || null,
    sourceBindingDigest: source.bindingDigest || null,
    deliveryIndexTree: out(delivery, ['write-tree']),
    proofIndexTree: out(proof, ['write-tree']),
    deliveryStatus: 'clean', proofStatus: 'clean',
  };
  writeImmutable(path.join(privateRoot, BINDING_NAME), binding);
  const ownerEnvPointer = `${privateRoot}\n`;
  const pointerFile = '/private/tmp/crosswake-178-owner-env';
  const pointerTmp = `${pointerFile}.tmp-${crypto.randomBytes(4).toString('hex')}`;
  fs.writeFileSync(pointerTmp, ownerEnvPointer, { mode: 0o600 }); fs.renameSync(pointerTmp, pointerFile); fs.chmodSync(pointerFile, 0o600);
  return { candidateCommit, candidateTree, selectedCount: INITIAL_PATHS.length, proof: 'clean-detached-exact-commit', binding: BINDING_NAME };
}

function renew() {
  const privateRoot = process.env.CROSSWAKE_178_PRIVATE_HANDOFF_ROOT;
  const delivery = process.env.CROSSWAKE_178_DELIVERY_ROOT;
  const proof = process.env.CROSSWAKE_178_PROOF_ROOT;
  if (![privateRoot, delivery, proof].every(v => typeof v === 'string' && path.isAbsolute(v))) fail('missing-environment');
  const roots = [privateRoot, delivery, proof].map(v => path.resolve(v));
  if (new Set(roots).size !== 3 || roots.some(r => pathWithinRoot(r, ROOT) || pathWithinRoot(ROOT, r))) fail('missing-environment');
  ensureEmptyOrAbsent(delivery); ensureEmptyOrAbsent(proof); ensurePrivateDir(privateRoot);
  const oldRoot = privatePointerRoot('/private/tmp/crosswake-178-owner-env');
  const oldBinding = readPrivateJson(privateFile(oldRoot, BINDING_NAME), 'candidate-binding');
  if (oldBinding.sourceBaseCommit !== BASE_COMMIT || oldBinding.sourceBaseTree !== BASE_TREE || oldBinding.candidateCommit !== '5923a679ffbe1b587d97165aab772986b65cbd18' || oldBinding.candidateTree !== 'cf6ad7a134e7f8d7d54c33d3a40d0178ef5bb113') fail('candidate-binding');
  const repairBindingFile = privateFile(oldRoot, 'repair-source-binding.json');
  const repairBinding = readPrivateJson(repairBindingFile, 'candidate-binding');
  const repairRoot = path.resolve(repairBinding.repairRoot || path.dirname(repairBindingFile));
  const repairRootStat = fs.lstatSync(repairRoot);
  if (!repairRootStat.isDirectory() || repairRootStat.isSymbolicLink() || (repairRootStat.mode & 0o077) !== 0) fail('candidate-binding');
  const repairBundleFile = path.resolve(repairBinding.bundlePath || '');
  const bundleDir = path.dirname(repairBundleFile);
  const bundleDirStat = fs.lstatSync(bundleDir);
  if (![repairRoot, oldRoot].some(allowed => pathWithinRoot(repairBundleFile, allowed) && fs.realpathSync(bundleDir) === fs.realpathSync(allowed)) || !bundleDirStat.isDirectory() || bundleDirStat.isSymbolicLink() || (bundleDirStat.mode & 0o077) !== 0) fail('candidate-binding');
  const repairBundleStat = fs.lstatSync(repairBundleFile);
  if (!repairBundleStat.isFile() || repairBundleStat.isSymbolicLink() || (repairBundleStat.mode & 0o077) !== 0) fail('missing-private-handoff');
  const repairBytes = fs.readFileSync(repairBundleFile);
  if (repairBinding.bundleDigest !== digest(repairBytes) || repairBinding.bundleBytes !== repairBytes.length || repairBinding.patchDigest !== undefined && repairBinding.patchDigest !== JSON.parse(repairBytes.toString('utf8')).patchDigest || repairBinding.patchBytes !== undefined && repairBinding.patchBytes !== JSON.parse(repairBytes.toString('utf8')).patchBytes) fail('candidate-binding');
  const repairBundle = readJson(repairBundleFile, 'invalid-bundle');
  if (repairBinding.baseCommit !== oldBinding.candidateCommit || repairBinding.baseTree !== oldBinding.candidateTree || JSON.stringify([...repairBinding.paths].sort()) !== JSON.stringify([...REPAIR_PATHS].sort())) fail('candidate-binding');
  const oldOwnerRoot = ownerPrivateRoot();
  const originalBundleBytes = ownerBundle(oldOwnerRoot);
  const originalBundle = JSON.parse(originalBundleBytes.toString('utf8'));
  const oldValidated = validateBundle(originalBundle, { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, paths: INITIAL_PATHS });
  if (!oldValidated.ok || digest(originalBundleBytes) !== oldBinding.bundleSha256 || digest(oldValidated.patch) !== oldBinding.patchSha256) fail('candidate-binding');
  const canonical = canonicalOriginAndMain();
  const sourceRoot = '/private/tmp/crosswake-177-source/crosswake';
  if (sha(sourceRoot, 'HEAD') !== BASE_COMMIT || sha(sourceRoot, 'HEAD^{tree}') !== BASE_TREE) fail('source-identity');
  clone(sourceRoot, delivery);
  if (sha(delivery, 'HEAD') !== BASE_COMMIT || sha(delivery, 'HEAD^{tree}') !== BASE_TREE) fail('source-identity');
  fetchCanonicalBase(delivery, canonical.origin);
  const replayed = replayRenewal(delivery, originalBundle, repairBundle, oldBinding, canonical.origin);
  const commitResult = spawnSync('git', ['-C', delivery, 'commit', '-m', 'chore(178-01): renew maintenance candidate'], { encoding: null, timeout: 120000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_AUTHOR_NAME: 'Crosswake Maintainer', GIT_AUTHOR_EMAIL: 'maintainer@example.invalid', GIT_COMMITTER_NAME: 'Crosswake Maintainer', GIT_COMMITTER_EMAIL: 'maintainer@example.invalid' } });
  if (commitResult.error || commitResult.signal || commitResult.status !== 0) fail('commit-failed');
  const candidateCommit = sha(delivery, 'HEAD'); const candidateTree = sha(delivery, 'HEAD^{tree}');
  if (candidateTree !== replayed.candidateTree || out(delivery, ['rev-parse', `${candidateCommit}^`]) !== BASE_COMMIT || JSON.stringify(changedPaths(delivery, BASE_COMMIT, candidateCommit)) !== JSON.stringify([...ALLOWED_PATHS].sort()) || out(delivery, ['status', '--porcelain=v1', '-z', '--untracked-files=all']) !== '') fail('commit-failed');
  clone(delivery, proof, 'proof'); git(proof, ['checkout', '--detach', candidateCommit]);
  assertCleanProof(proof, candidateCommit, candidateTree);
  const publicProjection = {
    schemaVersion: 1, phase: 178, plan: '01', status: 'source-qualified',
    sourceBaseCommit: BASE_COMMIT, sourceBaseTree: BASE_TREE, candidateCommit, candidateTree,
    selectedPaths: [...ALLOWED_PATHS].sort(), selectedCount: ALLOWED_PATHS.length,
    proofClone: 'clean-detached-exact-commit', canonicalMainMatchesBase: true,
    retainedRows: 119, historicalReaderComparisons: 'unproven-2',
    requirements: { 'MAINT-07': 'pending-full-run', 'MAINT-08': 'pending-hosted-ci' },
  };
  const binding = {
    schemaVersion: 2, phase: 178, plan: '01', sourceBaseCommit: BASE_COMMIT, sourceBaseTree: BASE_TREE,
    candidateCommit, candidateTree, selectedPaths: [...ALLOWED_PATHS].sort(),
    ownerPrivateRoot: oldOwnerRoot, privateHandoffRoot: privateRoot, deliveryRoot: delivery, proofRoot: proof,
    originalOwnerRoot: oldOwnerRoot, oldPrivateRoot: oldRoot, repairRoot, repairBindingPath: repairBindingFile, repairBundlePath: repairBundleFile,
    originalBundleSha256: digest(originalBundleBytes), originalPatchSha256: digest(oldValidated.patch),
    oldCandidateBindingSha256: digest(fs.readFileSync(privateFile(oldRoot, BINDING_NAME))), repairBindingSha256: digest(fs.readFileSync(repairBindingFile)),
    repairBundleSha256: digest(repairBytes), repairPatchSha256: digest(validateBundle(repairBundle, { baseCommit: oldBinding.candidateCommit, baseTree: oldBinding.candidateTree, paths: REPAIR_PATHS }).patch),
    oldCandidateCommit: oldBinding.candidateCommit, oldCandidateTree: oldBinding.candidateTree,
    deliveryIndexTree: out(delivery, ['write-tree']), proofIndexTree: out(proof, ['write-tree']),
    deliveryStatus: 'clean', proofStatus: 'clean',
  };
  writeImmutable(path.join(privateRoot, 'candidate-binding-renewed.json'), binding);
  atomicPublic(publicProjection);
  const pointerFile = '/private/tmp/crosswake-178-owner-env';
  const pointerTmp = `${pointerFile}.tmp-${crypto.randomBytes(4).toString('hex')}`;
  const fd = fs.openSync(pointerTmp, 'wx', 0o600);
  try { fs.writeFileSync(fd, `${privateRoot}\n`); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  fs.renameSync(pointerTmp, pointerFile); fs.chmodSync(pointerFile, 0o600);
  return { candidateCommit, candidateTree, selectedCount: ALLOWED_PATHS.length, proof: 'clean-detached-exact-commit', binding: 'candidate-binding-renewed.json' };
}

function check() {
  const privateRoot = process.env.CROSSWAKE_178_PRIVATE_HANDOFF_ROOT;
  if (!privateRoot || !path.isAbsolute(privateRoot)) fail('missing-environment');
  const renewed = fs.existsSync(path.join(privateRoot, 'candidate-binding-renewed.json'));
  const bindingPath = path.join(privateRoot, renewed ? 'candidate-binding-renewed.json' : BINDING_NAME);
  const binding = readPrivateJson(bindingPath, 'candidate-binding');
  const privateStat = fs.lstatSync(privateRoot);
  if (!privateStat.isDirectory() || (privateStat.mode & 0o077) !== 0) fail('candidate-binding');
  const ownerRoot = ownerPrivateRoot();
  const bundleBytes = ownerBundle(ownerRoot);
  const bundle = JSON.parse(bundleBytes.toString('utf8'));
  const delivery = binding.deliveryRoot; const proof = binding.proofRoot;
  const canonical = canonicalOriginAndMain();
  fetchCanonicalBase(delivery, canonical.origin);
  if (renewed) {
    const oldPrivateRoot = binding.oldPrivateRoot;
    const oldRootStat = fs.lstatSync(oldPrivateRoot);
    if (!path.isAbsolute(oldPrivateRoot) || oldRootStat.isSymbolicLink() || !oldRootStat.isDirectory() || (oldRootStat.mode & 0o077) !== 0) fail('candidate-binding');
    const oldBinding = readPrivateJson(privateFile(oldPrivateRoot, BINDING_NAME), 'candidate-binding');
    const repairBindingPath = privateFile(oldPrivateRoot, 'repair-source-binding.json');
    const repairBinding = readPrivateJson(repairBindingPath, 'candidate-binding');
    if (digest(fs.readFileSync(repairBindingPath)) !== binding.repairBindingSha256) fail('candidate-binding');
    const repairRoot = path.resolve(repairBinding.repairRoot || path.dirname(repairBindingPath));
    const repairRootStat = fs.lstatSync(repairRoot);
    if (!repairRootStat.isDirectory() || repairRootStat.isSymbolicLink() || (repairRootStat.mode & 0o077) !== 0) fail('candidate-binding');
    const repairBundlePath = path.resolve(repairBinding.bundlePath || '');
    const bundleDir = path.dirname(repairBundlePath); const bundleDirStat = fs.lstatSync(bundleDir);
    if (![repairRoot, oldPrivateRoot].some(allowed => pathWithinRoot(repairBundlePath, allowed) && fs.realpathSync(bundleDir) === fs.realpathSync(allowed)) || !bundleDirStat.isDirectory() || bundleDirStat.isSymbolicLink() || (bundleDirStat.mode & 0o077) !== 0) fail('candidate-binding');
    const repairStat = fs.lstatSync(repairBundlePath);
    if (!repairStat.isFile() || repairStat.isSymbolicLink() || (repairStat.mode & 0o077) !== 0) fail('candidate-binding');
    const repairBytes = fs.readFileSync(repairBundlePath);
    if (digest(repairBytes) !== repairBinding.bundleDigest || repairBytes.length !== repairBinding.bundleBytes) fail('candidate-binding');
    const repairBundle = JSON.parse(repairBytes.toString('utf8'));
    const repairValidated = validateBundle(repairBundle, { baseCommit: oldBinding.candidateCommit, baseTree: oldBinding.candidateTree, paths: REPAIR_PATHS });
    const validated = validateBundle(bundle, { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, paths: INITIAL_PATHS });
    if (!validated.ok || !repairValidated.ok || digest(bundleBytes) !== binding.originalBundleSha256 || digest(validated.patch) !== binding.originalPatchSha256 || digest(repairValidated.patch) !== binding.repairPatchSha256 || binding.oldCandidateCommit !== oldBinding.candidateCommit || binding.oldCandidateTree !== oldBinding.candidateTree || binding.oldPrivateRoot !== oldPrivateRoot || binding.repairBindingPath !== repairBindingPath || binding.repairBundlePath !== repairBundlePath || binding.oldCandidateBindingSha256 !== digest(fs.readFileSync(privateFile(oldPrivateRoot, BINDING_NAME)))) fail('candidate-binding');
    const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-renew-check-')); fs.chmodSync(temp, 0o700);
    try {
      const replayRoot = path.join(temp, 'replay'); clone('/private/tmp/crosswake-177-source/crosswake', replayRoot);
      if (sha(replayRoot, 'HEAD') !== BASE_COMMIT || sha(replayRoot, 'HEAD^{tree}') !== BASE_TREE) fail('source-identity');
      fetchCanonicalBase(replayRoot, canonical.origin);
      const replayed = replayRenewal(replayRoot, bundle, repairBundle, oldBinding, canonical.origin);
      if (replayed.candidateTree !== binding.candidateTree) fail('candidate-binding');
    } finally { fs.rmSync(temp, { recursive: true, force: true }); }
    if (out(delivery, ['rev-parse', `${binding.candidateCommit}^`]) !== BASE_COMMIT || JSON.stringify(changedPaths(delivery, BASE_COMMIT, binding.candidateCommit)) !== JSON.stringify([...ALLOWED_PATHS].sort())) fail('candidate-binding');
  } else {
    const validated = validateBundle(bundle, { baseCommit: BASE_COMMIT, baseTree: BASE_TREE, paths: INITIAL_PATHS });
    if (!validated.ok || digest(bundleBytes) !== binding.bundleSha256 || digest(validated.patch) !== binding.patchSha256) fail('candidate-binding');
    verifyBundleProducesTree(bundle, '/private/tmp/crosswake-177-source/crosswake', canonical.origin, binding.candidateTree);
    if (out(delivery, ['rev-parse', `${binding.candidateCommit}^`]) !== BASE_COMMIT || JSON.stringify(changedPaths(delivery, BASE_COMMIT, binding.candidateCommit)) !== JSON.stringify([...INITIAL_PATHS].sort())) fail('candidate-binding');
  }
  if (sha(delivery, 'HEAD') !== binding.candidateCommit || sha(delivery, 'HEAD^{tree}') !== binding.candidateTree || !indexMatchesHead(delivery) || out(delivery, ['status', '--porcelain=v1', '-z', '--untracked-files=all']) !== '') fail('candidate-binding');
  assertCleanProof(proof, binding.candidateCommit, binding.candidateTree);
  const pub = readJson(PUBLIC_NAME, 'public-binding');
  if (pub.candidateCommit !== binding.candidateCommit || pub.candidateTree !== binding.candidateTree || JSON.stringify(pub.selectedPaths) !== JSON.stringify([...binding.selectedPaths].sort())) fail('public-binding');
  return { candidateCommit: binding.candidateCommit, candidateTree: binding.candidateTree, selectedCount: binding.selectedPaths.length, proof: 'clean-detached-exact-commit' };
}

function initFixtureRepo(repo) {
  fs.mkdirSync(repo, { recursive: true });
  const run = args => {
    const r = spawnSync('git', ['-C', repo, ...args], { encoding: null, timeout: 30000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' } });
    if (r.error || r.signal || r.status !== 0) fail('verification-failed', 'fixture Git command failed');
    return r;
  };
  run(['init', '-q']); run(['config', 'user.name', 'Fixture']); run(['config', 'user.email', 'fixture@example.invalid']);
  fs.writeFileSync(path.join(repo, 'note.txt'), 'before\n'); run(['add', 'note.txt']); run(['commit', '-qm', 'base']);
  return run;
}
export function runTracerFixture() {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-178-tracer-'));
  try {
    const source = path.join(temp, 'source'); const run = initFixtureRepo(source);
    const baseCommit = out(source, ['rev-parse', 'HEAD']); const baseTree = out(source, ['rev-parse', 'HEAD^{tree}']);
    fs.writeFileSync(path.join(source, 'note.txt'), 'after\n');
    const newBytes = Buffer.from([0, 1, 2, 255]); fs.writeFileSync(path.join(source, 'new.bin'), newBytes);
    const trackedPatch = run(['diff', '--binary']).stdout;
    const untrackedDiff = spawnSync('git', ['-C', source, 'diff', '--no-index', '--binary', '--', '/dev/null', 'new.bin'], { encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
    if (untrackedDiff.error || untrackedDiff.signal || untrackedDiff.status !== 1) fail('verification-failed', 'fixture untracked diff failed');
    const untrackedPatch = Buffer.from(untrackedDiff.stdout || []);
    const patch = Buffer.concat([trackedPatch, untrackedPatch]);
    const bundle = {
      baseCommit, baseTree, patchBytes: patch.length, patchDigest: digest(patch), untrackedFiles: 1,
      patchBase64: patch.toString('base64'),
      untracked: [{ path: 'new.bin', mode: 0o644, bytes: newBytes.toString('base64'), patch: untrackedPatch.toString('base64') }],
    };
    const delivery = path.join(temp, 'delivery'); clone(source, delivery);
    const replay = replayBundle(delivery, bundle, { baseCommit, baseTree, paths: ['note.txt', 'new.bin'] });
    for (const p of ['note.txt', 'new.bin']) git(delivery, ['add', '--', p]);
    const committed = spawnSync('git', ['-C', delivery, 'commit', '-m', 'fixture'], { encoding: null, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_AUTHOR_NAME: 'Fixture', GIT_AUTHOR_EMAIL: 'fixture@example.invalid', GIT_COMMITTER_NAME: 'Fixture', GIT_COMMITTER_EMAIL: 'fixture@example.invalid' } });
    if (committed.error || committed.signal || committed.status !== 0) fail('commit-failed');
    const candidateCommit = sha(delivery, 'HEAD'); const tree = sha(delivery, 'HEAD^{tree}'); const proof = path.join(temp, 'proof'); clone(delivery, proof, 'proof');
    git(proof, ['checkout', '--detach', candidateCommit]);
    const proofHead = sha(proof, 'HEAD'); const proofTree = sha(proof, 'HEAD^{tree}');
    assertCleanProof(proof, candidateCommit, tree);
    return { commit: candidateCommit, tree, proofHead, proofTree, proofStatus: 'clean', paths: ['note.txt', 'new.bin'], newFileBytesMatch: fs.readFileSync(path.join(proof, 'new.bin')).equals(newBytes), gitResultShape: { status: replay.gitStatus } };
  } finally { fs.rmSync(temp, { recursive: true, force: true }); }
}
function assertOk(ok) { if (!ok) fail('verification-failed'); }

function main() {
  const mode = process.argv[2];
  try {
    const result = mode === '--prepare' ? prepare() : mode === '--renew' ? renew() : mode === '--check' ? check() : mode === '--self-test' ? runSelfTest() : fail('missing-environment', 'use --self-test, --prepare, --renew or --check');
    process.stdout.write(`${JSON.stringify({ ok: true, ...result })}\n`);
  } catch (err) {
    process.stderr.write(`${JSON.stringify({ ok: false, cause: SAFE_CAUSES.has(err.safeCause) ? err.safeCause : 'verification-failed' })}\n`);
    process.exitCode = 1;
  }
}
function runSelfTest() {
  const testFile = fileURLToPath(new URL('./prepare_candidate.test.mjs', import.meta.url));
  const result = spawnSync(process.execPath, ['--test', testFile], { encoding: null, timeout: 120000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  if (result.error || result.signal || result.status !== 0) fail('verification-failed');
  return { tests: 'passed' };
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
