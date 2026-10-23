#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import { validateSemanticSelection, assertOverlayState } from './source_reconciliation.mjs';

const GSD_TOOLS = '<home>/.codex/gsd-core/bin/gsd-tools.cjs';
const CANONICAL_REMOTE = 'https://github.com/szTheory/crosswake.git';
const CAPTURE_ID = '20261012024114124-721bf696c185e4de';
const VALID_OWNERS = new Set(['177-02', '177-03', '177-05']);
const SOURCE_OWNER = /Phase 177 (?:source|test|script|verification|workflow|documentation|docs) owner/i;

function fail(message, code = 1, publicCause = null) { const e = new Error(message); e.exitCode = code; e.publicCause = publicCause; throw e; }
function sha(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function json(file) { return JSON.parse(fs.readFileSync(file, 'utf8')); }
function modeOf(st) { return st.mode & 0o777; }
function safeClass(value) { return typeof value === 'string' && /^[A-Z][A-Z0-9_]{0,31}$/.test(value) ? value : 'UNKNOWN'; }
function safeStage(args) {
  const stage = args.find((value) => typeof value === 'string' && /^[a-z][a-z0-9-]{0,31}$/.test(value));
  return stage ?? 'command';
}
function run(file, args, cwd, options = {}) {
  const result = spawnSync(file, args, { cwd, encoding: null, timeout: options.timeout ?? 30000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', ...options.env } });
  const program = path.basename(file).replace(/[^a-zA-Z0-9._-]/g, '_');
  if (result.error) fail(`${program} subprocess failed`, 1, { program, stage: safeStage(args), cause: 'spawn-error', errorClass: safeClass(result.error.code) });
  if (result.signal) fail(`${program} subprocess terminated`, 1, { program, stage: safeStage(args), cause: 'signal', signal: safeClass(result.signal) });
  if (result.status !== 0 && !options.allowFailure) fail(`${program} subprocess failed`, 1, { program, stage: safeStage(args), cause: 'nonzero-exit', exitCode: Number.isInteger(result.status) ? result.status : null });
  return result;
}
function git(cwd, args, options) { return run('git', args, cwd, options); }
function out(result) { return Buffer.from(result.stdout ?? '').toString('utf8').trim(); }
function realDir(dir, label, { privateMode = false, writable = false } = {}) {
  const st = fs.lstatSync(dir);
  if (!st.isDirectory() || st.isSymbolicLink() || (typeof process.getuid === 'function' && st.uid !== process.getuid())) fail(`${label} must be an owner-owned real directory`);
  if (privateMode && (modeOf(st) & 0o077) !== 0) fail(`${label} permissions expose private data`);
  if (writable && (modeOf(st) & 0o700) !== 0o700) fail(`${label} must be owner-writable`);
  return fs.realpathSync(dir);
}
function privateFile(file, label) {
  const st = fs.lstatSync(file);
  if (!st.isFile() || st.isSymbolicLink() || (typeof process.getuid === 'function' && st.uid !== process.getuid()) || (modeOf(st) & 0o377) !== 0) fail(`${label} must be owner-only and immutable`);
  return { bytes: fs.readFileSync(file), stat: { mode: modeOf(st), mtimeMs: st.mtimeMs, size: st.size } };
}
function writePrivate(file, bytes) {
  const parent = path.dirname(file); realDir(parent, 'private handoff directory', { privateMode: true, writable: true });
  const temp = `${file}.tmp-${crypto.randomBytes(6).toString('hex')}`;
  const fd = fs.openSync(temp, 'wx', 0o600);
  try { fs.writeFileSync(fd, bytes); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  fs.renameSync(temp, file);
  fs.chmodSync(file, 0o600);
}
function parse(verb, argv) {
  const allowed = {
    probe: new Set(['--repo', '--public']),
    qualify: new Set(['--scope', '--repo', '--clone', '--base-commit', '--base-tree', '--inventory', '--maintenance', '--archive-root', '--handoff-root', '--public']),
    'record-patch': new Set(['--owner', '--clone', '--base-commit', '--base-tree', '--handoff-root', '--public']),
    'semantic-reconcile': new Set(['--clone', '--base-commit', '--base-tree', '--handoff-root', '--public', '--reconciliation']),
  };
  if (!allowed[verb]) fail('expected probe, qualify, record-patch, or semantic-reconcile', 2);
  const result = {};
  for (let i = 0; i < argv.length; i++) {
    const key = argv[i];
    if (!allowed[verb].has(key)) fail(`unknown or wrong-verb flag: ${key}`, 2);
    if (Object.hasOwn(result, key)) fail(`duplicate flag: ${key}`, 2);
    if (i + 1 >= argv.length || argv[i + 1].startsWith('--') || argv[i + 1] === '') fail(`missing value for ${key}`, 2);
    result[key] = argv[++i];
  }
  const required = verb === 'probe' ? ['--repo', '--public'] : verb === 'qualify'
    ? ['--repo', '--clone', '--base-commit', '--base-tree', '--inventory', '--maintenance', '--archive-root', '--handoff-root', '--public']
    : verb === 'record-patch' ? ['--owner', '--clone', '--base-commit', '--base-tree', '--handoff-root', '--public']
      : ['--clone', '--base-commit', '--base-tree', '--handoff-root', '--public', '--reconciliation'];
  for (const key of required) if (!result[key]) fail(`missing required flag: ${key}`, 2);
  if (verb === 'qualify' && result['--scope'] && !['tracer', 'complete'].includes(result['--scope'])) fail('invalid scope', 2);
  if (verb === 'record-patch' && !VALID_OWNERS.has(result['--owner'])) fail('invalid owner', 2);
  if (!/^[0-9a-f]{40,64}$/.test(result['--base-commit'] ?? '') && verb !== 'probe') fail('invalid base commit', 2);
  if (!/^[0-9a-f]{40,64}$/.test(result['--base-tree'] ?? '') && verb !== 'probe') fail('invalid base tree', 2);
  return result;
}
function noPathEscape(rel) {
  if (typeof rel !== 'string' || !rel || rel.startsWith('/') || rel.includes('\\') || rel.split('/').some((part) => part === '..' || part === '' || part === '.')) fail('unsafe captured row path');
  return rel;
}
function snapshotFrom(token) {
  if (!token || !['absent', 'file', 'symlink', 'gitlink', 'unreadable'].includes(token.kind)) fail('captured snapshot kind is malformed');
  if (['absent', 'unreadable', 'gitlink'].includes(token.kind)) return { kind: token.kind, mode: token.mode ?? null, bytes: null };
  const bytes = Buffer.from(token.data ?? '', 'base64');
  if (bytes.toString('base64') !== (token.data ?? '')) fail('captured snapshot encoding is malformed');
  if (!Number.isInteger(token.mode) || token.mode < 0 || token.mode > 0o7777) fail('captured snapshot mode is malformed');
  return { kind: token.kind, mode: token.mode, bytes };
}
function treeSnapshot(repo, commit, rel) {
  const spec = `${commit}:${rel}`;
  const r = git(repo, ['show', spec], { allowFailure: true });
  if (r.status !== 0) return { kind: 'absent', mode: null, bytes: null };
  const m = git(repo, ['ls-tree', commit, '--', rel]);
  const line = out(m).split(/\s+/);
  if (line.length < 4) fail('tree entry could not be resolved');
  const mode = line[0] === '100755' ? 0o755 : line[0] === '120000' ? 0o777 : 0o644;
  return { kind: line[0] === '120000' ? 'symlink' : line[1] === 'commit' ? 'gitlink' : 'file', mode, bytes: Buffer.from(r.stdout) };
}
function same(a, b) { return a.kind === b.kind && a.mode === b.mode && ((a.bytes === null && b.bytes === null) || (a.bytes && b.bytes && a.bytes.equals(b.bytes))); }
function hashSnapshot(s) { return sha(Buffer.from(JSON.stringify({ kind: s.kind, mode: s.mode, bytes: s.bytes?.toString('base64') ?? null }))); }
function ensureClonePath(root, rel) {
  const abs = path.resolve(root, rel); if (abs !== root && !abs.startsWith(root + path.sep)) fail('captured path escapes clone root');
  let cursor = root;
  for (const part of rel.split('/').slice(0, -1)) { cursor = path.join(cursor, part); try { const st = fs.lstatSync(cursor); if (!st.isDirectory() || st.isSymbolicLink()) fail('clone path parent is not a real directory'); } catch (e) { if (e.code !== 'ENOENT') throw e; } }
  return abs;
}
function currentCloneSnapshot(root, rel) {
  const file = ensureClonePath(root, rel);
  try { const st = fs.lstatSync(file); if (st.isSymbolicLink()) return { kind: 'symlink', mode: 0o777, bytes: Buffer.from(fs.readlinkSync(file)) }; if (!st.isFile()) return { kind: 'gitlink', mode: modeOf(st), bytes: null }; return { kind: 'file', mode: modeOf(st), bytes: fs.readFileSync(file) }; }
  catch (e) { if (e.code === 'ENOENT') return { kind: 'absent', mode: null, bytes: null }; throw e; }
}
function writeCloneSnapshot(root, rel, snap) {
  const file = ensureClonePath(root, rel); fs.mkdirSync(path.dirname(file), { recursive: true });
  if (snap.kind === 'absent') { try { fs.rmSync(file, { force: true }); } catch {} return; }
  if (!['file', 'symlink'].includes(snap.kind)) fail('unsupported path kind cannot be overlaid');
  if (snap.kind === 'symlink') { const target = snap.bytes.toString('utf8'); if (!target || path.isAbsolute(target) || target.split(/[\\/]/).includes('..')) fail('unsafe symlink target in captured row'); fs.symlinkSync(target, file); }
  else { fs.writeFileSync(file, snap.bytes, { mode: snap.mode & 0o777 }); fs.chmodSync(file, snap.mode & 0o777); }
}
function mergeUnit(repo, target, base, incoming, rel) {
  if (same(target, incoming)) return { status: 'equivalent', snapshot: target };
  if (same(base, incoming)) return { status: 'unchanged', snapshot: target };
  if (same(target, base)) return { status: 'safe-overlay', snapshot: incoming };
  if (incoming.kind === 'absent' && target.kind === 'file' && same(target, base)) return { status: 'safe-overlay', snapshot: incoming };
  if ([target.kind, base.kind, incoming.kind].every((k) => ['file', 'absent'].includes(k))) {
    if (target.kind === 'absent' && base.kind === 'absent') return { status: 'safe-overlay', snapshot: incoming };
    if (incoming.kind === 'absent' && same(target, base)) return { status: 'safe-overlay', snapshot: incoming };
    if ([target, base, incoming].some((s) => s.kind !== 'file')) return { status: 'blocked-conflict', reason: 'delete/modify conflict' };
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-177-merge-'));
    try {
      const ours = path.join(dir, 'ours'); const ancestor = path.join(dir, 'base'); const theirs = path.join(dir, 'theirs');
      fs.writeFileSync(ours, target.bytes); fs.writeFileSync(ancestor, base.bytes); fs.writeFileSync(theirs, incoming.bytes);
      const result = run('git', ['merge-file', '-p', '--diff3', ours, ancestor, theirs], dir, { allowFailure: true });
      if (result.status === 0) return { status: 'safe-overlay', snapshot: { kind: 'file', mode: incoming.mode, bytes: Buffer.from(result.stdout) } };
      const output = Buffer.from(result.stdout ?? '').toString('utf8');
      if (result.status > 0 && /^(?:<{7}|\|{7}|={7}|>{7})/m.test(output)) return { status: 'blocked-conflict', reason: 'overlapping content hunks' };
      fail(`merge-file failed with status ${result.status}`);
    } finally { fs.rmSync(dir, { recursive: true, force: true }); }
  }
  return { status: 'blocked-conflict', reason: 'path kind or mode cannot be merged safely' };
}
function readArchive(archiveRoot, inventory, repo) {
  realDir(archiveRoot, 'archive root', { privateMode: true });
  if (inventory.captureId !== CAPTURE_ID) fail('inventory capture ID does not match frozen Phase176 capture');
  const dir = path.join(archiveRoot, inventory.captureId); realDir(dir, 'capture directory', { privateMode: true });
  const paths = [path.join(dir, 'manifest.json'), path.join(dir, 'verified-proof.json'), path.join(archiveRoot, '.attestations', `${inventory.captureId}.sha256`), path.join(archiveRoot, '.attestations', `${inventory.captureId}.proof.sha256`)];
  const snapshots = paths.map((p, i) => ({ path: p, ...privateFile(p, `archive input ${i + 1}`) }));
  const [manifestFile, proofFile, attFile, proofAttFile] = snapshots;
  if (attFile.bytes.toString('utf8').trim() !== sha(manifestFile.bytes) || proofAttFile.bytes.toString('utf8').trim() !== sha(proofFile.bytes)) fail('private archive attestation mismatch');
  const manifest = JSON.parse(manifestFile.bytes.toString('utf8')); const proof = JSON.parse(proofFile.bytes.toString('utf8'));
  if (manifest.format !== 1 || manifest.captureId !== inventory.captureId || proof.captureId !== inventory.captureId || proof.manifestHash !== sha(manifestFile.bytes) || proof.provenance?.verified !== true) fail('private archive manifest/proof binding failed');
  if (out(git(repo, ['rev-parse', 'HEAD'])) !== manifest.source.head || out(git(repo, ['rev-parse', 'HEAD^{tree}'])) !== manifest.source.headTree) fail('recovery source HEAD changed since Phase176 capture');
  if (manifest.rows.length !== inventory.rows.length || Object.keys(proof.rows ?? {}).length !== manifest.rows.length) fail('private archive row coverage differs from Phase176 inventory');
  const index = new Map(inventory.rows.map((row) => [row.rowId, row]));
  for (const row of manifest.rows) {
    const publicRow = index.get(row.rowId); if (!publicRow || publicRow.status !== row.xy) fail('private archive row identity differs from public inventory');
    const rel = Buffer.from(row.pathBytes, 'base64').toString('utf8'); noPathEscape(rel);
    if (publicRow.path !== rel || proof.rows[row.rowId] == null) fail('private archive row mapping or proof is incomplete');
  }
  const compare = inventory.sourceComparison.candidates.find((c) => c.commit && c.tree);
  const selected = inventory.sourceComparison.candidates.find((c) => c.commit === process.env.CROSSWAKE_177_BASE_COMMIT);
  const candidate = selected ?? compare;
  if (!candidate) fail('Phase176 has no attested merged source candidate');
  const attested = proof.provenance.candidates.find((c) => c.commit === candidate.commit && c.tree === candidate.tree && c.ancestor && c.parentsVerified);
  if (!attested || candidate.commit !== process.env.CROSSWAKE_177_BASE_COMMIT || candidate.tree !== process.env.CROSSWAKE_177_BASE_TREE) fail('requested merged source identity is not attested by Phase176 proof');
  for (const item of snapshots) {
    const now = privateFile(item.path, 'archive input after read');
    if (now.stat.mode !== item.stat.mode || now.stat.mtimeMs !== item.stat.mtimeMs || now.stat.size !== item.stat.size || !now.bytes.equals(item.bytes)) fail('sealed archive input changed during qualification');
  }
  return { manifest, proof, candidate, snapshots: snapshots.map(({ path: _path, bytes, stat }) => ({ digest: sha(bytes), mode: stat.mode, mtimeMs: stat.mtimeMs, size: stat.size })) };
}
function makePartitions(repo, archive, manifestRow) {
  const rel = noPathEscape(Buffer.from(manifestRow.pathBytes, 'base64').toString('utf8'));
  const head = treeSnapshot(repo, archive.manifest.source.head, rel);
  const indexEntries = manifestRow.index.filter((entry) => entry.stage === 0);
  if (indexEntries.length > 1) fail('captured index has duplicate stage-zero entries');
  const index = indexEntries.length ? snapshotFrom(indexEntries[0].snapshot) : { kind: 'absent', mode: null, bytes: null };
  const worktree = snapshotFrom(manifestRow.worktree);
  return { rel, partitions: { head, index, worktree } };
}
function privatePartitionRecord(rowId, rel, parts) {
  const serial = (s) => ({ kind: s.kind, mode: s.mode, bytes: s.bytes?.toString('base64') ?? null, digest: hashSnapshot(s) });
  return { rowId, rel, partitions: { head: serial(parts.head), index: serial(parts.index), worktree: serial(parts.worktree) } };
}
function snapshotFromPrivate(value) { return { kind: value.kind, mode: value.mode, bytes: value.bytes == null ? null : Buffer.from(value.bytes, 'base64') }; }
function expectedOverlay(repo, commit, row) {
  const p = row.partitions; const head = snapshotFromPrivate(p.head); const index = snapshotFromPrivate(p.index); const worktree = snapshotFromPrivate(p.worktree);
  const target = treeSnapshot(repo, commit, row.rel); const staged = mergeUnit(repo, target, head, index, row.rel);
  const final = staged.status === 'blocked-conflict' ? staged : mergeUnit(repo, staged.snapshot, index, worktree, row.rel);
  return { target, status: final.status, snapshot: final.snapshot };
}
function validateExistingOverlay(clone, baseCommit, privateBundle) {
  const staged = git(clone, ['diff', '--cached', '--quiet'], { allowFailure: true });
  if (staged.status !== 0) fail(`clone contains an unexpected staged change (git diff status ${staged.status})`);
  const status = git(clone, ['status', '--porcelain=v1', '-z', '--untracked-files=all']).stdout;
  const entries = status.toString('utf8').split('\0').filter(Boolean);
  const rowMap = new Map(privateBundle.rows.map((row) => [row.rel, row]));
  for (const entry of entries) {
    const xy = entry.slice(0, 2); const rel = entry.slice(3);
    if (xy[0] !== ' ' && xy !== '??') fail('clone contains an unexpected index change');
    const row = rowMap.get(rel); if (!row) fail('clone contains a change outside the qualified source rows');
    const expected = expectedOverlay(clone, baseCommit, row); const actual = currentCloneSnapshot(clone, rel);
    if (expected.status === 'blocked-conflict' || !same(actual, expected.snapshot)) fail('clone worktree differs from the previously qualified overlay');
  }
}
function writePublic(publicPath, binding) {
  const payload = { ...binding, bindingDigest: undefined };
  delete payload.bindingDigest;
  const digest = sha(Buffer.from(JSON.stringify(payload)));
  const final = { ...payload, bindingDigest: digest };
  fs.mkdirSync(path.dirname(publicPath), { recursive: true });
  const tmp = `${publicPath}.tmp-${crypto.randomBytes(4).toString('hex')}`;
  fs.writeFileSync(tmp, `${JSON.stringify(final, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(tmp, publicPath); fs.chmodSync(publicPath, 0o644);
  return final;
}
export function fetchAttestedCommit(clone, commit, tree, spawn = spawnSync) {
  const args = ['-C', clone, 'fetch', '--no-write-fetch-head', '--no-tags', CANONICAL_REMOTE, commit];
  const result = spawn('git', args, { encoding: null, timeout: 30000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  if (result.error) fail('canonical source fetch failed', 1, { program: 'git', stage: 'fetch', cause: 'spawn-error', errorClass: safeClass(result.error.code) });
  if (result.signal) fail('canonical source fetch terminated', 1, { program: 'git', stage: 'fetch', cause: 'signal', signal: safeClass(result.signal) });
  if (result.status !== 0) fail('canonical source fetch failed', 1, { program: 'git', stage: 'fetch', cause: 'nonzero-exit', exitCode: Number.isInteger(result.status) ? result.status : null });
  const fetchedCommit = out(git(clone, ['rev-parse', `${commit}^{commit}`]));
  const fetchedTree = out(git(clone, ['rev-parse', `${commit}^{tree}`]));
  if (fetchedCommit !== commit || fetchedTree !== tree) fail('fetched source identity does not match its attestation', 1, { program: 'git', stage: 'identity-check', cause: 'attestation-mismatch' });
  return { status: result.status, commit: fetchedCommit, tree: fetchedTree };
}
function probe(args) {
  const repo = fs.realpathSync(args['--repo']);
  const gsd = run(process.execPath, [GSD_TOOLS, 'query', 'init.new-workspace', '--ws=quality-ratchet-release'], process.cwd());
  const init = JSON.parse(out(gsd));
  for (const key of ['project_root', 'is_git_repo', 'cwd_repo_name', 'default_workspace_base']) if (!(key in init)) fail(`installed init.new-workspace response lacks ${key}`);
  const runtimeRoot = out(git(process.cwd(), ['rev-parse', '--show-toplevel']));
  if (init.project_root !== runtimeRoot || init.is_git_repo !== true || init.cwd_repo_name !== path.basename(runtimeRoot) || typeof init.default_workspace_base !== 'string') fail('installed GSD workspace response identifies a different project');
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-177-probe-'));
  try {
    const bare = path.join(tmp, 'remote.git'); run('git', ['init', '--bare', bare], tmp);
    const seeded = path.join(tmp, 'seed'); run('git', ['clone', bare, seeded], tmp);
    run('git', ['config', 'user.name', 'Fixture'], seeded); run('git', ['config', 'user.email', 'fixture@example.invalid'], seeded);
    fs.writeFileSync(path.join(seeded, 'fixture.txt'), 'real subprocess fixture\n'); run('git', ['add', 'fixture.txt'], seeded); run('git', ['commit', '-m', 'fixture'], seeded); run('git', ['push', '-u', 'origin', 'HEAD'], seeded);
    const clone = path.join(tmp, 'clone'); const cloned = run('git', ['clone', bare, clone], tmp);
    const checked = run('git', ['checkout', '-b', 'workspace/probe'], clone);
    const fetched = run('git', ['fetch', '-q', '--no-tags', 'origin', out(run('git', ['rev-parse', 'HEAD'], clone))], clone);
  const report = { probe: 'passed', gsd: { is_git_repo: init.is_git_repo, repository_name: init.cwd_repo_name, workspace_base_configured: init.default_workspace_base.length > 0 }, git: { clone: { exitCode: cloned.status }, checkout: { exitCode: checked.status }, fetch: { exitCode: fetched.status } } };
    if (process.env.CROSSWAKE_177_FIXTURE_ARCHIVE) validateFixtureArchive(process.env.CROSSWAKE_177_FIXTURE_ARCHIVE);
    writePublic(args['--public'], report); process.stdout.write(`${JSON.stringify(report)}\n`);
  } finally { fs.rmSync(tmp, { recursive: true, force: true }); }
}
function validateFixtureArchive(root) {
  realDir(root, 'fixture archive root', { privateMode: true });
  for (const file of fs.readdirSync(root, { recursive: true }).map((rel) => path.join(root, rel)).filter((p) => fs.existsSync(p) && fs.lstatSync(p).isFile())) privateFile(file, 'fixture archive input');
}
export function qualifySource(args, fetcher = fetchAttestedCommit) {
  const scope = args['--scope'] ?? 'complete'; const repo = fs.realpathSync(args['--repo']); const clone = fs.realpathSync(args['--clone']);
  const handoff = realDir(args['--handoff-root'], 'private handoff root', { privateMode: true, writable: true });
  if (repo === clone || repo.startsWith(clone + path.sep) || clone.startsWith(repo + path.sep)) fail('source and clone must be independent repositories');
  const sourceOrigin = out(git(repo, ['config', '--get', 'remote.origin.url']));
  if (sourceOrigin !== CANONICAL_REMOTE) fail('configured source origin is not canonical');
  const cloneOrigin = out(git(clone, ['config', '--get', 'remote.origin.url']));
  let resolvedCloneOrigin;
  try { resolvedCloneOrigin = fs.realpathSync(cloneOrigin); } catch { resolvedCloneOrigin = cloneOrigin; }
  if (resolvedCloneOrigin !== repo && cloneOrigin !== CANONICAL_REMOTE) fail('clone origin does not identify the source repository');
  const inventory = json(args['--inventory']); const maintenance = json(args['--maintenance']); const archived = readArchive(args['--archive-root'], inventory, repo);
  if (!Array.isArray(maintenance.rows) || maintenance.rows.length !== inventory.rows.length) fail('maintenance and inventory row coverage differs');
  const expectedIds = inventory.rows.map((r) => r.rowId).sort(); const observedIds = maintenance.rows.map((r) => r.rowId).sort();
  if (new Set(observedIds).size !== observedIds.length || JSON.stringify(expectedIds) !== JSON.stringify(observedIds)) fail('maintenance review omits or duplicates a preserved row');
  const beforeFetch = { head: out(git(clone, ['rev-parse', 'HEAD'])), index: git(clone, ['ls-files', '--stage', '-z']).stdout, status: statusEntries(clone).bytes };
  fetcher(clone, archived.candidate.commit, archived.candidate.tree);
  const afterFetch = { head: out(git(clone, ['rev-parse', 'HEAD'])), index: git(clone, ['ls-files', '--stage', '-z']).stdout, status: statusEntries(clone).bytes };
  if (beforeFetch.head !== afterFetch.head || !beforeFetch.index.equals(afterFetch.index) || !beforeFetch.status.equals(afterFetch.status)) fail('canonical fetch changed the clone checkout, index, or worktree');
  if (afterFetch.head !== args['--base-commit'] || out(git(clone, ['rev-parse', 'HEAD^{tree}'])) !== args['--base-tree']) fail('clone is not checked out at the attested source commit/tree');
  const privateRows = []; const publicRows = []; const conflicts = []; const overlays = [];
  const ownerById = new Map(maintenance.rows.map((r) => [r.rowId, r]));
  const rowById = new Map(inventory.rows.map((r) => [r.rowId, r]));
  const priorPrivate = (() => { try { return json(path.join(handoff, 'partitions.json')); } catch (e) { if (e.code === 'ENOENT') return null; throw e; } })();
  if (priorPrivate) {
    if (priorPrivate.captureId !== inventory.captureId || priorPrivate.baseCommit !== args['--base-commit'] || priorPrivate.baseTree !== args['--base-tree']) fail('existing private handoff belongs to another capture or base');
    validateExistingOverlay(clone, args['--base-commit'], priorPrivate);
  } else if (out(git(clone, ['status', '--porcelain=v1', '--untracked-files=all']))) fail('clone must be clean before its first source qualification');
  let candidates = archived.manifest.rows.filter((r) => SOURCE_OWNER.test(ownerById.get(r.rowId)?.semanticOwner ?? ''));
  if (scope === 'tracer') {
    candidates = candidates.filter((r) => {
      const { rel, partitions } = makePartitions(repo, archived, r); const target = treeSnapshot(clone, args['--base-commit'], rel);
      return target.kind === 'absent' && partitions.worktree.kind === 'file' && partitions.worktree.bytes && partitions.index.kind === 'absent';
    }).slice(0, 1);
    if (!candidates.length) fail('no untracked, source-owned worktree row can be safely qualified as tracer');
  }
  for (const row of archived.manifest.rows) {
    const { rel, partitions } = makePartitions(repo, archived, row); const maint = ownerById.get(row.rowId); const publicRow = rowById.get(row.rowId);
    privateRows.push(privatePartitionRecord(row.rowId, rel, partitions));
    if (!SOURCE_OWNER.test(maint.semanticOwner ?? '')) {
      publicRows.push({ rowId: row.rowId, status: 'preserved-out-of-source-scope' }); continue;
    }
    if (scope === 'tracer' && !candidates.some((r) => r.rowId === row.rowId)) continue;
    const target = treeSnapshot(clone, args['--base-commit'], rel);
    let staged = mergeUnit(clone, target, partitions.head, partitions.index, rel);
    let worktree = staged.status === 'blocked-conflict' ? staged : mergeUnit(clone, staged.snapshot, partitions.index, partitions.worktree, rel);
    const outcome = worktree.status === 'blocked-conflict' ? worktree : staged.status === 'blocked-conflict' ? staged : worktree;
    const decision = { rowId: row.rowId, status: outcome.status, reason: outcome.reason ?? null, owner: maint.semanticOwner, headDigest: hashSnapshot(partitions.head), indexDigest: hashSnapshot(partitions.index), worktreeDigest: hashSnapshot(partitions.worktree), targetDigest: hashSnapshot(target) };
    if (outcome.status === 'blocked-conflict') { conflicts.push({ rowId: row.rowId, path: rel, owner: maint.semanticOwner, reason: outcome.reason, missingFact: maint.missingFact, nextAction: maint.nextAction, phase176OwnerAction: publicRow.nextAction }); }
    else if (outcome.status === 'safe-overlay') overlays.push({ rel, snapshot: outcome.snapshot });
    publicRows.push({ rowId: decision.rowId, status: decision.status });
    privateRows[privateRows.length - 1].decision = decision;
  }
  for (const overlay of overlays) writeCloneSnapshot(clone, overlay.rel, overlay.snapshot);
  const privateBundle = { captureId: inventory.captureId, baseCommit: args['--base-commit'], baseTree: args['--base-tree'], archiveFiles: archived.snapshots, rows: privateRows, conflicts };
  writePrivate(path.join(handoff, 'partitions.json'), Buffer.from(JSON.stringify(privateBundle, null, 2) + '\n'));
  const tracerRow = scope === 'tracer' ? publicRows.find((r) => r.status === 'safe-overlay' || r.status === 'equivalent' || r.status === 'unchanged') : null;
  const prior = (() => { try { return json(args['--public']); } catch { return {}; } })();
  const binding = { schemaVersion: 1, phase: 177, plan: 8, captureId: inventory.captureId, baseCommit: args['--base-commit'], baseTree: args['--base-tree'], selectedRowIds: scope === 'tracer' ? candidates.map((r) => r.rowId) : publicRows.map((r) => r.rowId), selectedCount: scope === 'tracer' ? candidates.length : publicRows.length, status: conflicts.length ? 'qualified-with-blocked-rows' : scope === 'tracer' ? 'tracer-qualified' : 'complete-qualified', scope, rows: publicRows, counts: { applicable: publicRows.filter((r) => !r.status.startsWith('preserved-')).length, safeOverlay: publicRows.filter((r) => r.status === 'safe-overlay').length, equivalent: publicRows.filter((r) => r.status === 'equivalent').length, unchanged: publicRows.filter((r) => r.status === 'unchanged').length, blockedConflict: conflicts.length, preservedOutOfScope: publicRows.filter((r) => r.status.startsWith('preserved-')).length }, tracer: scope === 'tracer' ? { rowId: tracerRow?.rowId ?? candidates[0].rowId, status: tracerRow?.status ?? 'blocked-conflict', partitions: ['HEAD', 'index', 'worktree'] } : prior.tracer ?? null, patches: prior.patches ?? [] };
  const final = writePublic(args['--public'], binding);
  process.stdout.write(`${JSON.stringify({ status: final.status, scope, selectedCount: final.selectedCount, counts: final.counts, blockedRowIds: conflicts.map((x) => x.rowId) })}\n`);
}
function publicPayload(binding) { const copy = { ...binding }; delete copy.bindingDigest; return copy; }
function verifyPublicBinding(binding) {
  const payload = publicPayload(binding);
  if (typeof binding.bindingDigest !== 'string' || sha(Buffer.from(JSON.stringify(payload))) !== binding.bindingDigest) fail('public binding integrity check failed');
}
function statusEntries(repo) {
  const bytes = git(repo, ['status', '--porcelain=v1', '-z', '--untracked-files=all']).stdout;
  return { bytes, entries: bytes.toString('utf8').split('\0').filter(Boolean).map((entry) => ({ xy: entry.slice(0, 2), rel: entry.slice(3) })) };
}
function isPhaseEvidencePath(rel) { return rel.startsWith('.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/'); }
function semanticReconcile(args) {
  const clone = fs.realpathSync(args['--clone']); const handoff = realDir(args['--handoff-root'], 'private handoff root', { privateMode: true, writable: true });
  if (out(git(clone, ['rev-parse', 'HEAD'])) !== args['--base-commit'] || out(git(clone, ['rev-parse', 'HEAD^{tree}'])) !== args['--base-tree']) fail('clone base changed before semantic reconciliation');
  const binding = json(args['--public']); verifyPublicBinding(binding);
  if (binding.baseCommit !== args['--base-commit'] || binding.baseTree !== args['--base-tree'] || binding.scope !== 'complete' || binding.status !== 'qualified-with-blocked-rows') fail('source binding is not the expected complete pre-reconciliation result');
  const review = json(args['--reconciliation']); const bundle = json(path.join(handoff, 'partitions.json'));
  if (review.status !== 'semantic-selection-complete' || review.baseCommit !== args['--base-commit'] || review.baseTree !== args['--base-tree'] || review.captureId !== binding.captureId) fail('semantic selection does not match the pinned binding');
  if (review.counts?.inventoryRows !== bundle.rows.length || review.counts?.sourceRows !== 70 || review.counts?.previouslyBlockedConflicts !== 30 || review.counts?.routerModes !== 78) fail('semantic selection coverage is incomplete');
  if (bundle.captureId !== review.captureId || bundle.baseCommit !== review.baseCommit || bundle.baseTree !== review.baseTree) fail('private partitions do not match the selected source');
  let validated;
  try { validated = validateSemanticSelection({ review, bundle, binding, baseCommit: args['--base-commit'], baseTree: args['--base-tree'] }); }
  catch { fail('semantic selection, row identities, or private partition integrity failed'); }
  const selected = validated.selected; const partitions = validated.partitions;
  for (const row of review.rows) {
    const part = partitions.get(row.rowId);
    if (!part || row.preservation?.headIndexWorktreeSeparate !== true || row.preservation?.privatePartitionRetained !== true) fail('semantic selection row preservation contract failed');
  }
  const bindingRows = new Map(binding.rows.map((row) => [row.rowId, row]));
  if (bindingRows.size !== partitions.size) fail('pre-reconciliation binding row coverage differs from private partitions');
  const restore = [];
  for (const row of bundle.rows) {
    const current = currentCloneSnapshot(clone, row.rel); const expected = expectedOverlay(clone, args['--base-commit'], row); const prior = bindingRows.get(row.rowId);
    if (!prior) fail('pre-reconciliation binding omitted a preserved row');
    if (prior.status === 'safe-overlay') {
      if (expected.status !== 'safe-overlay') fail('binder-computed overlay classification changed');
      try { assertOverlayState({ selectedStatus: prior.status, actual: current, overlay: expected.snapshot, base: expected.target }); }
      catch { fail('derived overlay bytes do not match the binder-computed result'); }
      restore.push({ rel: row.rel, snapshot: expected.target });
    } else {
      try { assertOverlayState({ selectedStatus: prior.status, actual: current, overlay: expected.snapshot, base: expected.target }); }
      catch { fail('clone changed outside the exact binder-computed safe overlays'); }
    }
  }
  const observed = statusEntries(clone).entries.filter((entry) => !isPhaseEvidencePath(entry.rel)); const allowed = new Set(restore.map((r) => r.rel));
  for (const entry of observed) if (!allowed.has(entry.rel) || (entry.xy !== '??' && entry.xy !== ' M' && entry.xy !== ' D' && entry.xy !== ' M')) fail('clone contains an unbound source change');
  for (const row of restore) writeCloneSnapshot(clone, row.rel, row.snapshot);
  if (statusEntries(clone).entries.some((entry) => !isPhaseEvidencePath(entry.rel))) fail('clone did not return to the pinned clean source after exact overlay reversal');
  const resolutionBytes = fs.readFileSync(args['--reconciliation']); const resolutionDigest = sha(resolutionBytes);
  writePrivate(path.join(handoff, 'semantic-reconciliation.json'), Buffer.from(JSON.stringify({ captureId: review.captureId, baseCommit: review.baseCommit, baseTree: review.baseTree, resolutionDigest, selectedRows: review.rows.length, modeCount: review.modes.length, selectedActions: review.rows.map((row) => ({ rowId: row.rowId, action: row.selectedAction })) }, null, 2) + '\n'));
  binding.rows = review.rows.map((row) => ({ rowId: row.rowId, status: row.sourceOwned ? 'source-retained-privately' : 'preserved-out-of-source-scope' }));
  binding.status = 'complete-qualified'; binding.scope = 'complete';
  binding.counts = { applicable: review.counts.sourceRows, retainedPrivately: review.counts.sourceRows, unresolved: 0, previouslyBlockedConflicts: review.counts.previouslyBlockedConflicts, previouslySafeOverlaysNotAdopted: review.counts.previouslySafeOverlays, previouslyEquivalentRowsNotAdopted: review.counts.previouslyEquivalents, preservedOutOfScope: review.counts.outOfSourceRows };
  binding.semanticSelection = { status: 'complete', selectionCount: review.counts.sourceRows, conflictSelections: review.counts.previouslyBlockedConflicts, modeSelections: review.modes.length, policy: 'preserve captured units privately; retain exact pinned source bytes' };
  binding.patches = [];
  const final = writePublic(args['--public'], binding);
  process.stdout.write(`${JSON.stringify({ status: final.status, selectedRows: review.counts.sourceRows, preservedOutOfScope: review.counts.outOfSourceRows, previouslyBlockedConflicts: review.counts.previouslyBlockedConflicts, previouslySafeOverlaysNotAdopted: review.counts.previouslySafeOverlays, routerModes: review.modes.length, cloneClean: true })}\n`);
}
function recordPatch(args) {
  const clone = fs.realpathSync(args['--clone']); const handoff = realDir(args['--handoff-root'], 'private handoff root', { privateMode: true, writable: true });
  if (out(git(clone, ['rev-parse', 'HEAD'])) !== args['--base-commit'] || out(git(clone, ['rev-parse', 'HEAD^{tree}'])) !== args['--base-tree']) fail('clone base changed before patch recording');
  const binding = json(args['--public']); verifyPublicBinding(binding);
  if (binding.baseCommit !== args['--base-commit'] || binding.baseTree !== args['--base-tree']) fail('public binding differs from patch base');
  if (binding.status !== 'complete-qualified' || binding.scope !== 'complete' || binding.semanticSelection?.status !== 'complete' || binding.counts?.unresolved !== 0) fail('source patch requires complete semantic qualification');
  const beforeStatus = statusEntries(clone).bytes;
  const beforeIndex = git(clone, ['ls-files', '--stage', '-z']).stdout;
  if (git(clone, ['diff', '--cached', '--quiet'], { allowFailure: true }).status !== 0) fail('source patch contains staged changes');
  const tracked = git(clone, ['diff', '--binary', args['--base-commit'], '--']).stdout;
  const entries = statusEntries(clone).entries.filter((entry) => !isPhaseEvidencePath(entry.rel)); const untracked = [];
  for (const entry of entries.filter((item) => item.xy === '??')) {
    if (!entry.rel || entry.rel.startsWith('-')) fail('untracked source path cannot be safely represented');
    const snapshot = currentCloneSnapshot(clone, entry.rel);
    if (snapshot.kind !== 'file') fail('untracked source entry must be a regular file');
    const patch = run('git', ['diff', '--no-index', '--binary', '--', '/dev/null', entry.rel], clone, { allowFailure: true });
    if (![0, 1].includes(patch.status)) fail('untracked source patch could not be represented');
    untracked.push({ path: entry.rel, mode: snapshot.mode, bytes: snapshot.bytes.toString('base64'), patch: Buffer.from(patch.stdout).toString('base64') });
  }
  const patchBytes = Buffer.concat([tracked, ...untracked.map((row) => Buffer.from(row.patch, 'base64'))]); const digest = sha(patchBytes);
  const record = { schemaVersion: 1, owner: args['--owner'], baseCommit: args['--base-commit'], baseTree: args['--base-tree'], statusDigest: sha(beforeStatus), indexDigest: sha(beforeIndex), patchDigest: digest, patchBytes: patchBytes.length, untrackedFiles: untracked.length, recordedAt: new Date().toISOString() };
  const patchFile = path.join(handoff, `cumulative-${args['--owner']}.patch`); const bundleFile = path.join(handoff, `cumulative-${args['--owner']}.bundle.json`); const recordFile = path.join(handoff, `cumulative-${args['--owner']}.json`);
  writePrivate(patchFile, patchBytes);
  writePrivate(bundleFile, Buffer.from(JSON.stringify({ ...record, patchBase64: patchBytes.toString('base64'), untracked }, null, 2) + '\n'));
  writePrivate(recordFile, Buffer.from(JSON.stringify(record, null, 2) + '\n'));
  const replayRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'crosswake-177-patch-replay-'));
  try {
    const replay = path.join(replayRoot, 'repo'); run('git', ['clone', '--quiet', clone, replay], replayRoot); run('git', ['checkout', '--quiet', '--detach', args['--base-commit']], replay);
    const patchPath = path.join(replayRoot, 'cumulative.patch'); fs.writeFileSync(patchPath, patchBytes, { mode: 0o600 });
    if (patchBytes.length) run('git', ['apply', '--binary', patchPath], replay);
    for (const row of untracked) {
      const output = ensureClonePath(replay, row.path); fs.mkdirSync(path.dirname(output), { recursive: true }); fs.writeFileSync(output, Buffer.from(row.bytes, 'base64'), { mode: row.mode }); fs.chmodSync(output, row.mode);
    }
    const expected = statusEntries(clone).entries.filter((x) => !isPhaseEvidencePath(x.rel)).map((x) => x.rel).sort(); const actual = statusEntries(replay).entries.map((x) => x.rel).sort();
    if (JSON.stringify(expected) !== JSON.stringify(actual)) fail('cumulative source bundle did not restore the exact changed-path set');
    for (const rel of expected) if (!same(currentCloneSnapshot(clone, rel), currentCloneSnapshot(replay, rel))) fail('cumulative source bundle did not restore exact source bytes');
  } finally { fs.rmSync(replayRoot, { recursive: true, force: true }); }
  const afterStatus = statusEntries(clone).bytes; const afterIndex = git(clone, ['ls-files', '--stage', '-z']).stdout;
  if (!beforeStatus.equals(afterStatus) || !beforeIndex.equals(afterIndex) || !sha(fs.readFileSync(patchFile)).startsWith(digest)) fail('clone changed while recording cumulative patch');
  binding.patches = [...(binding.patches ?? []).filter((p) => p.owner !== args['--owner']), { owner: args['--owner'], status: 'recorded', changedFiles: entries.length, untrackedFiles: untracked.length, patchBytes: patchBytes.length }];
  writePublic(args['--public'], binding);
  process.stdout.write(`${JSON.stringify({ owner: args['--owner'], status: 'recorded', changedFiles: entries.length, untrackedFiles: untracked.length, patchBytes: record.patchBytes, replayVerified: true })}\n`);
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const verb = process.argv[2]; const args = parse(verb, process.argv.slice(3));
    if (verb === 'probe') probe(args);
    else if (verb === 'qualify') qualifySource(args);
    else if (verb === 'semantic-reconcile') semanticReconcile(args);
    else recordPatch(args);
  } catch (error) {
    const details = error.publicCause ?? { program: 'qualify_source', stage: 'validation', cause: error.exitCode === 2 ? 'usage-denied' : 'validation-denied', errorClass: safeClass(error.code ?? error.name) };
    process.stderr.write(`phase177 ${details.program} stage=${details.stage} cause=${details.cause}${details.exitCode == null ? '' : ` exit=${details.exitCode}`}${details.signal ? ` signal=${details.signal}` : ''}${details.errorClass ? ` class=${details.errorClass}` : ''}\n`);
    process.exitCode = error.exitCode ?? 1;
  }
}
