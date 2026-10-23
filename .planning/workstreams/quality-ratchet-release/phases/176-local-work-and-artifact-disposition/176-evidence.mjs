#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const PHASE_DIR = path.dirname(fileURLToPath(import.meta.url));
const FORMAT = 1;
const DISPOSITIONS = new Set(['retain', 'already merged', 'ship as bounded maintenance', 'preserve outside the working source', 'remove as proven transient']);
const SECRET_NAME = /(?:^|\/)(?:\.env(?:\..*)?|\.npmrc|\.netrc|\.pypirc|credentials?(?:\.[^/]*)?|tokens?(?:\.[^/]*)?|id_(?:rsa|dsa|ecdsa|ed25519)|[^/]+\.(?:pem|p12|pfx|key|asc|gpg|kdbx))$/i;
const MAX_BUFFER = 64 * 1024 * 1024;
const GUARD_PATHS = [
  '.planning/workstreams/quality-ratchet-release/STATE.md',
  '.planning/workstreams/quality-ratchet-release/ROADMAP.md',
  '.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md',
  '.planning/workstreams/quality-ratchet-release/state.json',
  '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-VALIDATION.md'
];
const PHASE_REL = '.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/';

function fail(message) { throw new Error(message); }
function git(repo, args, options = {}) {
  const result = spawnSync('git', args, { cwd: repo, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' }, encoding: null, maxBuffer: MAX_BUFFER, timeout: options.timeout ?? 15000 });
  if (result.error) fail(`git ${args[0]} could not run (${result.error.code || 'spawn_error'})`);
  if (result.signal) fail(`git ${args[0]} ended by signal (${result.signal})`);
  if (result.status !== 0) fail(`git ${args[0]} failed (${result.status ?? 'unknown'})`);
  if (!Buffer.isBuffer(result.stdout)) fail(`git ${args[0]} returned no byte output`);
  return result.stdout;
}
function gitObjectHash(repo, bytes) {
  const result = spawnSync('git', ['hash-object', '--stdin'], { cwd: repo, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' }, input: bytes, encoding: null, maxBuffer: 1024, timeout: 5000 });
  if (result.error || result.signal || result.status !== 0 || !Buffer.isBuffer(result.stdout)) fail('captured index payload could not be checked against its Git object identity');
  return result.stdout.toString('ascii').trim();
}
export function probeSubprocess(args, options = {}) {
  const result = spawnSync(args[0], args.slice(1), { cwd: options.cwd, env: options.env ?? process.env, encoding: null, maxBuffer: options.maxBuffer ?? MAX_BUFFER, timeout: options.timeout ?? 5000 });
  return { error: result.error?.code ?? null, signal: result.signal ?? null, status: result.status, stdoutBytes: Buffer.isBuffer(result.stdout) ? result.stdout.length : null };
}
function sha(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function b64(value) { return Buffer.from(value).toString('base64'); }
function unb64(value) { return Buffer.from(value, 'base64'); }
function splitNul(buf) {
  const out = []; let start = 0;
  for (let i = 0; i < buf.length; i++) if (buf[i] === 0) { out.push(buf.subarray(start, i)); start = i + 1; }
  if (start !== buf.length) fail('Git returned a non-NUL-terminated record stream');
  return out;
}
function parseStatus(raw) {
  const records = splitNul(raw); const result = [];
  for (let i = 0; i < records.length; i++) {
    const r = records[i];
    if (r.length < 4 || r[2] !== 0x20) fail('Git status returned a malformed record');
    const xy = r.subarray(0, 2).toString('ascii'); const destination = r.subarray(3);
    const rename = xy.includes('R') || xy.includes('C');
    const source = rename ? records[++i] : null;
    if (rename && (!source || source.length === 0)) fail('Git rename record omitted its source path');
    result.push({ xy, path: destination, source });
  }
  return result;
}
export function parseStatusRecords(raw) {
  if (!Buffer.isBuffer(raw)) fail('status input must be a Buffer');
  return parseStatus(raw).map((r) => ({ xy: r.xy, path: Buffer.from(r.path), source: r.source && Buffer.from(r.source) }));
}
function parseIndex(raw) {
  const entries = [];
  for (const record of splitNul(raw)) {
    const tab = record.indexOf(0x09);
    if (tab < 0) fail('Git index returned a malformed stage record');
    const head = record.subarray(0, tab).toString('ascii').split(' ');
    if (head.length !== 3 || !/^\d{6}$/.test(head[0]) || !/^[0-9a-f]{40,64}$/.test(head[1]) || !/^\d$/.test(head[2])) fail('Git index returned an unsupported stage record');
    entries.push({ mode: head[0], oid: head[1], stage: Number(head[2]), path: record.subarray(tab + 1) });
  }
  return entries;
}
export function parseIndexRecords(raw) {
  if (!Buffer.isBuffer(raw)) fail('index input must be a Buffer');
  return parseIndex(raw).map(({ mode, oid, stage, path: p }) => ({ mode, oid, stage, path: Buffer.from(p) }));
}
function absoluteFromBytes(root, rel) {
  if (process.platform === 'win32') {
    const decoded = rel.toString('utf8');
    if (decoded.includes('\ufffd') || decoded.includes('\\') || path.isAbsolute(decoded) || decoded.split('/').includes('..')) fail('unsupported unsafe path bytes');
    return path.resolve(root, decoded);
  }
  if (rel.length === 0 || rel[0] === 0x2f || rel.includes(0) || rel.toString('binary').split('/').includes('..')) fail('unsafe repository path bytes');
  return Buffer.concat([Buffer.from(root + path.sep), rel]);
}
function assertNoSymlinkParents(root, rel) {
  if (process.platform === 'win32') return;
  const components = rel.toString('binary').split('/'); let current = Buffer.from(root);
  for (const component of components.slice(0, -1)) {
    current = Buffer.concat([current, Buffer.from('/'), Buffer.from(component, 'binary')]);
    try { const st = fs.lstatSync(current); if (st.isSymbolicLink() || !st.isDirectory()) fail('repository path traverses a symlink or non-directory parent; payload not read'); }
    catch (e) { if (e.code === 'ENOENT') return; throw e; }
  }
}
function safeDisplay(bytes) {
  const text = bytes.toString('utf8');
  if (Buffer.from(text, 'utf8').equals(bytes) && !/[\u0000-\u001f\u007f]/.test(text) && (!SECRET_NAME.test(text) || text === 'examples/phoenix_host/.env') && !text.startsWith('/') && !text.split('/').includes('..')) return text;
  return null;
}
function isSensitivePath(bytes) {
  const display = bytes.toString('utf8');
  if (!Buffer.from(display, 'utf8').equals(bytes)) return true;
  return SECRET_NAME.test(display) && display !== 'examples/phoenix_host/.env';
}
function fileSnapshot(abs) {
  let st;
  try { st = fs.lstatSync(abs, { bigint: true }); } catch (e) { if (e.code === 'ENOENT') return { kind: 'absent' }; fail(`filesystem metadata could not be read (${e.code || 'error'})`); }
  const mode = Number(st.mode & 0o7777n);
  if (st.isSymbolicLink()) return { kind: 'symlink', mode, bytes: fs.readlinkSync(abs, { encoding: 'buffer' }) };
  if (st.isFile()) return { kind: 'file', mode, bytes: fs.readFileSync(abs) };
  fail('unsupported filesystem object kind retained');
}
// Node has no openat(2) API. This tiny stdlib-only reader walks every path
// component from an already-open checkout directory and refuses links at all
// parent and leaf components. It never resolves the leaf through its pathname.
const NOFOLLOW_READER = String.raw`import os,sys,base64,stat,json
root=base64.b64decode(sys.argv[1]); rel=base64.b64decode(sys.argv[2]); meta=sys.argv[3]=='1'
parts=rel.split(b'/'); flags=os.O_RDONLY|getattr(os,'O_CLOEXEC',0)|getattr(os,'O_NONBLOCK',0); dflags=flags|getattr(os,'O_DIRECTORY',0)|getattr(os,'O_NOFOLLOW',0)
fd=os.open(root,dflags)
parents=[(os.fstat(fd).st_dev,os.fstat(fd).st_ino)]
try:
 for part in parts[:-1]:
  try: n=os.open(part,dflags,dir_fd=fd)
  except FileNotFoundError:
   print(json.dumps({'kind':'absent'})); sys.exit(0)
  os.close(fd); fd=n; st=os.fstat(fd); parents.append((st.st_dev,st.st_ino))
 if len(sys.argv)>5 and sys.argv[4]:
  open(sys.argv[4],'wb').close()
  while not os.path.exists(sys.argv[5]): import time; time.sleep(.005)
 leaf=parts[-1]
 try: f=os.open(leaf,flags|getattr(os,'O_NOFOLLOW',0),dir_fd=fd)
 except FileNotFoundError:
  print(json.dumps({'kind':'absent'})); sys.exit(0)
 except OSError as e:
  if e.errno not in (getattr(__import__('errno'),'ELOOP',40),getattr(__import__('errno'),'EMLINK',31)): raise
  st=os.stat(leaf,dir_fd=fd,follow_symlinks=False)
  if not stat.S_ISLNK(st.st_mode): raise
  if meta: print(json.dumps({'kind':'linkmeta','mode':stat.S_IMODE(st.st_mode),'dev':st.st_dev,'ino':st.st_ino,'size':st.st_size})); sys.exit(0)
  target=os.readlink(leaf,dir_fd=fd); target=target if isinstance(target,bytes) else os.fsencode(target)
  print(json.dumps({'kind':'symlink','mode':stat.S_IMODE(st.st_mode),'data':base64.b64encode(target).decode()})); sys.exit(0)
 try:
  file_st=os.fstat(f)
  if not stat.S_ISREG(file_st.st_mode): print(json.dumps({'kind':'unsupported'})); sys.exit(0)
  if meta: print(json.dumps({'kind':'filemeta','mode':stat.S_IMODE(file_st.st_mode),'dev':file_st.st_dev,'ino':file_st.st_ino,'size':file_st.st_size,'mtime':file_st.st_mtime_ns,'ctime':file_st.st_ctime_ns})); sys.exit(0)
  chunks=[]
  while True:
   x=os.read(f,1048576)
   if not x: break
   chunks.append(x)
  check=os.open(root,dflags)
  try:
   if (os.fstat(check).st_dev,os.fstat(check).st_ino)!=parents[0]: raise OSError('source root changed during anchored read')
   for i,part in enumerate(parts[:-1]):
    nxt=os.open(part,dflags,dir_fd=check); os.close(check); check=nxt
    st=os.fstat(check)
    if (st.st_dev,st.st_ino)!=parents[i+1]: raise OSError('source parent changed during anchored read')
  finally: os.close(check)
  print(json.dumps({'kind':'file','mode':stat.S_IMODE(file_st.st_mode),'data':base64.b64encode(b''.join(chunks)).decode(),'dev':file_st.st_dev,'ino':file_st.st_ino,'size':file_st.st_size,'mtime':file_st.st_mtime_ns,'ctime':file_st.st_ctime_ns}))
 finally: os.close(f)
finally: os.close(fd)`;
function anchoredSnapshot(root, rel, metadataOnly = false, barrier = null) {
  if (process.platform === 'win32') fail('anchored no-follow path reading is unavailable on this host');
  const result = spawnSync('python3', ['-c', NOFOLLOW_READER, b64(Buffer.from(root)), b64(Buffer.from(rel)), metadataOnly ? '1' : '0', barrier?.marker ?? '', barrier?.continueFile ?? ''], { encoding: 'utf8', maxBuffer: MAX_BUFFER, timeout: 10000 });
  if (result.error || result.signal || result.status !== 0) fail(`anchored no-follow reader failed closed (${result.error?.code ?? result.signal ?? result.status})`);
  let value; try { value = JSON.parse(result.stdout); } catch { fail('anchored no-follow reader returned malformed metadata'); }
  if (value.kind === 'absent') return { kind: 'absent' };
  if (value.kind === 'unsupported') fail('unsupported filesystem object kind retained');
  if (value.kind === 'filemeta' || value.kind === 'linkmeta') return { kind: 'unreadable', reason: 'secret-bearing path payload excluded by privacy policy', fingerprint: `${value.dev}:${value.ino}:${value.mode}:${value.size}:${value.mtime ?? ''}:${value.ctime ?? ''}` };
  const bytes = unb64(value.data);
  if (value.kind === 'file') return { kind: 'file', mode: value.mode, bytes, fingerprint: `${value.dev}:${value.ino}:${value.mode}:${value.size}:${value.mtime}:${value.ctime}` };
  if (value.kind === 'symlink') return { kind: 'symlink', mode: value.mode, bytes };
  fail('anchored no-follow reader returned unsupported object kind');
}
export function readSourceForTest(root, relative, barrier = null) { return anchoredSnapshot(root, Buffer.from(relative), false, barrier); }
function safeSourceSnapshot(root, rel, sensitive = false) {
  try { return anchoredSnapshot(root, rel, sensitive); }
  catch (error) {
    if (/unsupported filesystem object kind/.test(error.message)) return { kind: 'unreadable', reason: 'unsupported filesystem object kind retained as a limitation' };
    throw error;
  }
}
function bytesIdentity(p) { return b64(p); }
function randomOpaqueRowId() { return crypto.randomBytes(16).toString('hex'); }
function ownerPrivateDirectory(target, label, { create = false } = {}) {
  let st;
  try { st = fs.lstatSync(target); }
  catch (error) {
    if (!create || error.code !== 'ENOENT') throw error;
    fs.mkdirSync(target, { mode: 0o700 }); st = fs.lstatSync(target);
  }
  if (!st.isDirectory() || st.isSymbolicLink()) fail(`${label} must be a real directory`);
  if (typeof process.getuid === 'function' && st.uid !== process.getuid()) fail(`${label} is not owned by the current user`);
  if ((st.mode & 0o077) !== 0) fail(`${label} permissions expose private archive data`);
  return fs.realpathSync(target);
}
function privateRoot(repo, archiveRoot, allowTemporary) {
  if (!archiveRoot || typeof archiveRoot !== 'string') fail('private archive root must be explicitly selected');
  const root = path.resolve(archiveRoot); const realRepo = fs.realpathSync(repo);
  if (root === realRepo || root.startsWith(realRepo + path.sep) || realRepo.startsWith(root + path.sep)) fail('private archive must be outside the source checkout');
  const forbiddenRoots = [...new Set([os.tmpdir(), '/tmp', '/private/tmp', '/var/folders', '/private/var/folders', process.env.TMPDIR].filter(Boolean).flatMap((p) => {
    const absolute = path.resolve(p); let canonical = absolute; try { canonical = fs.realpathSync(absolute); } catch {}
    return [absolute, canonical];
  }))];
  if (!allowTemporary && /(?:^|\/)(?:Dropbox|OneDrive|Google ?Drive[^/]*|Box|iCloud(?: Drive)?|CloudStorage|Mobile Documents)(?:\/|$)/i.test(root)) fail('synchronized or shared archive roots are not accepted');
  if (!allowTemporary && forbiddenRoots.some((p) => root === p || root.startsWith(p + path.sep))) fail('temporary storage and per-session roots are fixture-only and cannot be used for durable capture');
  // Walk the complete existing ancestor chain without following any link. This
  // rejects symlink parents and any archive nested under another Git checkout.
  const missing = [];
  let cursor = root;
  while (true) {
    try {
      const st = fs.lstatSync(cursor);
      if (st.isSymbolicLink() || !st.isDirectory()) fail('archive path contains a symlink or non-directory ancestor');
      if (!allowTemporary && ((st.mode & 0o022) !== 0)) fail('archive path has a group/world-writable parent');
      if (fs.existsSync(path.join(cursor, '.git')) || fs.existsSync(path.join(cursor, '.git', 'HEAD'))) fail('archive path is inside another Git checkout');
      if (cursor === path.dirname(cursor)) break;
      cursor = path.dirname(cursor);
    } catch (error) {
      if (error.code === 'ENOENT') { missing.push(cursor); cursor = path.dirname(cursor); continue; }
      throw error;
    }
  }
  if (!allowTemporary && missing.length) fail('durable archive root and its parent directories must already exist');
  if (allowTemporary && missing.length) fail('fixture archive root must be created explicitly before capture');
  const realRoot = ownerPrivateDirectory(root, 'archive root');
  if (realRoot === realRepo || realRoot.startsWith(realRepo + path.sep) || realRepo.startsWith(realRoot + path.sep)) fail('private archive must be outside the source checkout');
  return realRoot;
}
/* replaced below */
function syncFile(file, data, mode = 0o600) {
  const fd = fs.openSync(file, 'wx', mode);
  try { fs.writeFileSync(fd, data); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  fs.chmodSync(file, mode);
}
function attestationPath(root, captureId) { return path.join(root, '.attestations', `${captureId}.sha256`); }
function fsyncDir(dir) { try { const fd = fs.openSync(dir, 'r'); fs.fsyncSync(fd); fs.closeSync(fd); } catch {} }
function snapshotToken(snapshot) {
  if (snapshot.kind === 'absent') return { kind: 'absent' };
  if (snapshot.kind === 'unreadable') return { kind: 'unreadable', reason: snapshot.reason };
  return { kind: snapshot.kind, mode: snapshot.mode, data: b64(snapshot.bytes) };
}
function snapshotEqual(a, b) { return JSON.stringify(snapshotToken(a)) === JSON.stringify(snapshotToken(b)); }
function statusNow(repo) {
  const status = git(repo, ['status', '--porcelain=v1', '-z', '--untracked-files=all']);
  const index = git(repo, ['ls-files', '--stage', '-z']);
  const head = git(repo, ['rev-parse', 'HEAD']).toString('ascii').trim();
  const tree = git(repo, ['rev-parse', 'HEAD^{tree}']).toString('ascii').trim();
  // A byte hash of `ls-files --stage -z` is the captured index identity. Do not
  // use `git write-tree`: even that read-shaped command writes a Git object.
  return { status, index, head, tree, indexRecordsHash: sha(index) };
}
function scratchGitResult(cwd, args, input) {
  return spawnSync('git', args, { cwd, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', GIT_CONFIG_NOSYSTEM: '1', GIT_CONFIG_GLOBAL: path.join(cwd, '.git', 'fixture-global-config') }, input, encoding: null, maxBuffer: MAX_BUFFER, timeout: 15000 });
}
function scratchGit(cwd, args, input) {
  const result = scratchGitResult(cwd, args, input);
  if (result.error) fail(`scratch Git ${args[0]} could not run (${result.error.code || 'spawn_error'})`);
  if (result.signal) fail(`scratch Git ${args[0]} ended by signal (${result.signal})`);
  if (result.status !== 0) fail(`scratch Git ${args[0]} failed (${result.status ?? 'unknown'})`);
  return result.stdout ?? Buffer.alloc(0);
}
function normalizeIndexRows(rows) {
  return rows.map((r) => ({ mode: r.mode, oid: r.oid, stage: r.stage, path: Buffer.from(r.path) }))
    .sort((a, b) => Buffer.compare(a.path, b.path) || a.stage - b.stage)
    .map((r) => `${r.mode}:${r.oid}:${r.stage}:${b64(r.path)}`).join('\n');
}
function normalizeStatusRows(rows) {
  return rows.map((r) => ({ xy: r.xy, path: Buffer.from(r.path), source: r.source ? Buffer.from(r.source) : null }))
    .sort((a, b) => Buffer.compare(a.path, b.path) || Buffer.compare(a.source ?? Buffer.alloc(0), b.source ?? Buffer.alloc(0)) || a.xy.localeCompare(b.xy))
    .map((r) => `${r.xy}:${b64(r.path)}:${r.source ? b64(r.source) : ''}`).join('\n');
}
function mirrorStatusConfiguration(source, scratch) {
  for (const key of ['core.filemode', 'core.symlinks', 'core.ignorecase', 'core.autocrlf', 'core.quotepath', 'status.renames', 'diff.renames']) {
    const value = scratchGitResult(source, ['config', '--get', key]);
    if (value.status === 0) scratchGit(scratch, ['config', key, value.stdout.toString('utf8').trim()]);
  }
  const sourceExclude = scratchGitResult(source, ['rev-parse', '--git-path', 'info/exclude']);
  const scratchExclude = path.resolve(scratch, scratchGit(scratch, ['rev-parse', '--git-path', 'info/exclude']).toString('utf8').trim());
  if (sourceExclude.status === 0) {
    const from = path.resolve(source, sourceExclude.stdout.toString('utf8').trim());
    try { fs.copyFileSync(from, scratchExclude); } catch (error) { if (error.code !== 'ENOENT') throw error; }
  }
  const globalExclude = scratchGitResult(source, ['config', '--path', '--get', 'core.excludesFile']);
  if (globalExclude.status === 0) scratchGit(scratch, ['config', 'core.excludesFile', globalExclude.stdout.toString('utf8').trim()]);
}
function phaseArtifactPath(repo, target, basename) {
  const root = fs.realpathSync(repo); const absolute = path.resolve(root, target); const relative = path.relative(root, absolute);
  if (relative !== `${PHASE_REL}${basename}`) fail('public artifact target is outside its exact Phase 176 owner path');
  assertNoSymlinkParents(root, Buffer.from(relative));
  try { const st = fs.lstatSync(absolute); if (st.isSymbolicLink() || !st.isFile()) fail('public artifact destination is not a regular file'); } catch (e) { if (e.code !== 'ENOENT') throw e; }
  return absolute;
}
function writePhaseArtifact(repo, target, basename, content) {
  const destination = phaseArtifactPath(repo, target, basename); const temp = `${destination}.tmp-${crypto.randomBytes(8).toString('hex')}`;
  syncFile(temp, Buffer.from(content), 0o644); fs.renameSync(temp, destination); fsyncDir(path.dirname(destination));
}
export function capture({ repo, archiveRoot, allowTemporary = false, _afterSnapshotForTest } = {}) {
  if (!repo || !archiveRoot) fail('capture requires repository and archive root');
  repo = fs.realpathSync(repo);
  const root = privateRoot(repo, archiveRoot, allowTemporary);
  const lock = path.join(root, '.capture.lock');
  let lockFd;
  try { lockFd = fs.openSync(lock, 'wx', 0o600); }
  catch { fail('archive capture is busy or an earlier interrupted attempt needs maintainer inspection'); }
  const started = new Date().toISOString();
  let attempt;
  try {
    const before = statusNow(repo);
    const statuses = parseStatus(before.status); const indexEntries = parseIndex(before.index);
    const intentPaths = new Set(statuses.filter((r) => r.xy[0] === ' ' && r.xy[1] === 'A').map((r) => bytesIdentity(r.path)));
    const guardFiles = GUARD_PATHS.map((relative) => {
      const pathBytes = Buffer.from(relative);
      assertNoSymlinkParents(repo, pathBytes);
      const entries = indexEntries.filter((e) => e.path.equals(pathBytes)).map((e) => {
        const intentToAdd = /^0+$/.test(e.oid);
        const snap = intentToAdd ? { kind: 'absent' } : { kind: e.mode === '160000' ? 'gitlink' : e.mode === '120000' ? 'symlink' : 'file', mode: Number.parseInt(e.mode, 8) & 0o777, bytes: e.mode === '160000' ? Buffer.alloc(0) : git(repo, ['cat-file', 'blob', e.oid]) };
        return { mode: e.mode, stage: e.stage, oid: e.oid, intentToAdd, snapshot: snapshotToken(snap) };
      });
      const worktree = safeSourceSnapshot(repo, pathBytes, false);
      return { pathBytes: b64(pathBytes), worktree: snapshotToken(worktree), index: entries, _fingerprint: worktree.fingerprint ?? null };
    });
    const paths = new Map();
    const addPath = (p, xy, role) => { const k = bytesIdentity(p); const old = paths.get(k) ?? { path: Buffer.from(p), xy: new Set(), roles: new Set() }; old.xy.add(xy); old.roles.add(role); paths.set(k, old); };
    for (const r of statuses) { addPath(r.path, r.xy, 'status'); if (r.source) addPath(r.source, r.xy, 'rename-source'); }
    for (const e of indexEntries) if (paths.has(bytesIdentity(e.path))) paths.get(bytesIdentity(e.path)).roles.add('index');
    const captureId = `${started.replace(/[-:.TZ]/g, '')}-${crypto.randomBytes(8).toString('hex')}`;
    attempt = path.join(root, `.partial-${captureId}`); fs.mkdirSync(attempt, { mode: 0o700 });
    const rows = [];
    for (const item of [...paths.values()].sort((a, b) => Buffer.compare(a.path, b.path))) {
      const staged = indexEntries.filter((e) => e.path.equals(item.path));
      const rowId = randomOpaqueRowId(); const abs = absoluteFromBytes(repo, item.path);
      assertNoSymlinkParents(repo, item.path);
      const sensitive = isSensitivePath(item.path);
      const gitlink = staged.find((e) => e.mode === '160000');
      const worktree = gitlink ? { kind: 'gitlink', mode: 0o755, bytes: Buffer.alloc(0), commit: gitlink.oid } : safeSourceSnapshot(repo, item.path, sensitive);
      const index = [];
      for (const ent of staged) {
        const intentToAdd = /^0+$/.test(ent.oid) || intentPaths.has(bytesIdentity(ent.path));
        const blob = sensitive || ent.mode === '160000' || intentToAdd ? Buffer.alloc(0) : git(repo, ['cat-file', 'blob', ent.oid]);
        const snapshot = sensitive ? { kind: 'unreadable', reason: 'secret-bearing index payload excluded by privacy policy' } : intentToAdd ? { kind: 'absent' } : { kind: ent.mode === '120000' ? 'symlink' : ent.mode === '160000' ? 'gitlink' : 'file', mode: Number.parseInt(ent.mode, 8) & 0o777, bytes: blob };
        index.push({ mode: ent.mode, stage: ent.stage, oid: sensitive || intentToAdd ? null : ent.oid, intentToAdd, snapshot });
      }
      rows.push({ rowId, pathBytes: item.path, xy: [...item.xy].sort().join(','), roles: [...item.roles].sort(), index, worktree, _fingerprint: worktree.fingerprint ?? null });
    }
    const rowsPublic = rows.map((r) => ({ rowId: r.rowId, path: safeDisplay(r.pathBytes), pathRef: safeDisplay(r.pathBytes) ? null : r.rowId, status: r.xy, disposition: 'retain', reason: r.worktree.kind === 'unreadable' ? (r.worktree.reason?.includes('secret-bearing') ? 'Secret-bearing path retained in place; payload was excluded by privacy policy.' : 'Path retained in place; filesystem type is unsupported for copying.') : r.worktree.kind === 'gitlink' ? 'Gitlink retained in place; nested repository contents are not copied.' : r.worktree.kind === 'absent' && r.index.length === 0 ? 'Path record retained; no readable payload unit was found.' : 'Captured for review; no disposition has been approved.', comparison: null, nextOwner: 'Phase 176 review' }));
    const after = statusNow(repo);
    if (after.head !== before.head || after.tree !== before.tree || sha(after.status) !== sha(before.status) || sha(after.index) !== sha(before.index)) fail('source changed during capture; partial archive retained for inspection, recapture required');
    for (const row of rows) {
      if (row.worktree.kind === 'gitlink') continue;
      const sensitive = isSensitivePath(row.pathBytes);
      const current = safeSourceSnapshot(repo, row.pathBytes, sensitive);
      if (row._fingerprint !== null ? current.fingerprint !== row._fingerprint : !snapshotEqual(current, row.worktree)) fail('source worktree bytes, kind, or mode changed during capture; partial archive retained, recapture required');
    }
    for (const guard of guardFiles) {
      const current = safeSourceSnapshot(repo, unb64(guard.pathBytes), false);
      if (guard._fingerprint !== null ? current.fingerprint !== guard._fingerprint : !snapshotEqual(current, snapshotFromToken(guard.worktree))) fail('GSD writer source changed during capture; partial archive retained, recapture required');
    }
    if (_afterSnapshotForTest) _afterSnapshotForTest();
    const finalStatus = statusNow(repo);
    if (finalStatus.head !== before.head || finalStatus.tree !== before.tree || sha(finalStatus.status) !== sha(before.status) || sha(finalStatus.index) !== sha(before.index)) fail('source changed during capture; partial archive retained for inspection, recapture required');
    for (const row of rows) {
      if (row.worktree.kind === 'gitlink') continue;
      const sensitive = isSensitivePath(row.pathBytes);
      const current = safeSourceSnapshot(repo, row.pathBytes, sensitive);
      if (row._fingerprint !== null ? current.fingerprint !== row._fingerprint : !snapshotEqual(current, row.worktree)) fail('source worktree bytes, kind, or mode changed during capture; partial archive retained, recapture required');
    }
    const manifest = { format: FORMAT, captureId, createdAt: started, source: { head: before.head, headTree: before.tree, indexRecordsHash: before.indexRecordsHash, statusHash: sha(before.status), indexHash: sha(before.index), statusRaw: b64(before.status), indexRaw: b64(before.index), statusRows: statuses.map((r) => ({ xy: r.xy, path: b64(r.path), source: r.source ? b64(r.source) : null })), indexEntries: indexEntries.map((e) => ({ mode: e.mode, oid: e.oid, stage: e.stage, intentToAdd: /^0+$/.test(e.oid) || intentPaths.has(bytesIdentity(e.path)), path: b64(e.path) })) }, guardFiles: guardFiles.map(({ _fingerprint, ...g }) => g), rows: rows.map(({ _fingerprint, ...r }) => ({ ...r, pathBytes: b64(r.pathBytes), worktree: snapshotToken(r.worktree), index: r.index.map((e) => ({ ...e, snapshot: snapshotToken(e.snapshot) })) })) };
    const manifestBytes = Buffer.from(JSON.stringify(manifest, null, 2) + '\n');
    syncFile(path.join(attempt, 'manifest.json'), manifestBytes, 0o400);
    const attestDir = path.join(root, '.attestations');
    try { fs.mkdirSync(attestDir, { mode: 0o700 }); } catch (error) { if (error.code !== 'EEXIST') throw error; }
    ownerPrivateDirectory(attestDir, 'private integrity attestation directory');
    syncFile(attestationPath(root, captureId), Buffer.from(`${sha(manifestBytes)}\n`), 0o400);
    fsyncDir(attempt);
    const finalDir = path.join(root, captureId);
    fs.renameSync(attempt, finalDir); fsyncDir(root);
    const result = { schema: 1, captureId, capturedAt: started, source: { head: before.head, headTree: before.tree, indexState: 'full stage records retained in private manifest' }, rows: rowsPublic, limitations: rows.filter((r) => r.worktree.kind === 'unreadable' || r.worktree.kind === 'gitlink').map((r) => ({ rowId: r.rowId, reason: r.worktree.kind === 'gitlink' ? 'gitlink commit identity retained; nested repository bytes are not copied' : 'path payload or filesystem type excluded; source remains in place' })) };
    return result;
  } finally {
    try { fs.closeSync(lockFd); } catch {}
    try { fs.unlinkSync(lock); } catch {}
    if (attempt && fs.existsSync(attempt)) { /* Partial capture stays visible for safe manual inspection. */ }
  }
}
function readManifest(archiveRoot, captureId) {
  if (!/^[0-9TZ-]+-[a-f0-9]{16}$/.test(captureId ?? '')) fail('capture ID is malformed');
  const root = ownerPrivateDirectory(path.resolve(archiveRoot), 'archive root'); const dir = path.join(root, captureId);
  const privateDir = ownerPrivateDirectory(dir, 'capture directory');
  const manifestPath = path.join(dir, 'manifest.json'); const manifestStat = fs.lstatSync(manifestPath);
  if (!manifestStat.isFile() || manifestStat.isSymbolicLink() || (manifestStat.mode & 0o377) !== 0 || (typeof process.getuid === 'function' && manifestStat.uid !== process.getuid())) fail('manifest ownership or permissions are not private and immutable');
  const manifestBytes = fs.readFileSync(manifestPath);
  const attPath = attestationPath(root, captureId); const attStat = fs.lstatSync(attPath);
  if (!attStat.isFile() || attStat.isSymbolicLink() || (attStat.mode & 0o377) !== 0 || (typeof process.getuid === 'function' && attStat.uid !== process.getuid())) fail('private integrity attestation is missing or exposed');
  const attestedHash = fs.readFileSync(attPath, 'utf8').trim();
  if (!/^[a-f0-9]{64}$/.test(attestedHash) || attestedHash !== sha(manifestBytes)) fail('private capture integrity check failed; manifest or payload was changed');
  const manifest = JSON.parse(manifestBytes.toString('utf8'));
  if (manifest.format !== FORMAT || manifest.captureId !== captureId || !Array.isArray(manifest.rows)) fail('private capture manifest is incomplete or unsupported');
  const seenPaths = new Set(); const seenIds = new Set();
  for (const row of manifest.rows) {
    if (!row || typeof row.pathBytes !== 'string' || !Array.isArray(row.index)) fail('private capture row is malformed');
    const rawPath = unb64(row.pathBytes); const key = bytesIdentity(rawPath);
    if (rawPath.length === 0 || b64(rawPath) !== row.pathBytes || !/^[a-f0-9]{32}$/.test(row.rowId ?? '')) fail('private row path identity is malformed');
    if (seenPaths.has(key)) fail('duplicate private path identity'); seenPaths.add(key);
    if (seenIds.has(row.rowId)) fail('duplicate private row identifier'); seenIds.add(row.rowId);
    const stages = new Set();
    for (const entry of row.index) {
      if (!Number.isInteger(entry.stage) || !/^\d{6}$/.test(entry.mode) || stages.has(entry.stage)) fail('private index stage identity is malformed or duplicated');
      stages.add(entry.stage);
    }
  }
  return { dir, manifest, manifestHash: sha(manifestBytes) };
}
function proofPath(dir) { return path.join(dir, 'verified-proof.json'); }
function persistVerifiedProof(root, dir, captureId, proof) {
  const bytes = Buffer.from(JSON.stringify(proof, null, 2) + '\n'); const target = proofPath(dir); const temp = `${target}.tmp-${crypto.randomBytes(6).toString('hex')}`;
  syncFile(temp, bytes, 0o400); fs.renameSync(temp, target); fsyncDir(dir);
  const attDir = path.join(root, '.attestations'); const attest = path.join(attDir, `${captureId}.proof.sha256`); const attTemp = `${attest}.tmp-${crypto.randomBytes(6).toString('hex')}`;
  syncFile(attTemp, Buffer.from(`${sha(bytes)}\n`), 0o400); fs.renameSync(attTemp, attest); fsyncDir(attDir);
}
function readVerifiedProof(root, dir, captureId, manifestHash) {
  const file = proofPath(dir); const st = fs.lstatSync(file); const bytes = fs.readFileSync(file);
  const att = path.join(root, '.attestations', `${captureId}.proof.sha256`); const ast = fs.lstatSync(att);
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o377) !== 0 || !ast.isFile() || ast.isSymbolicLink() || (ast.mode & 0o377) !== 0 || fs.readFileSync(att, 'utf8').trim() !== sha(bytes)) fail('private verification proof is missing, exposed, or stale');
  const proof = JSON.parse(bytes.toString('utf8'));
  if (proof.captureId !== captureId || proof.manifestHash !== manifestHash) fail('private verification proof does not bind to this frozen capture');
  return proof;
}
function assertNoRestorePathCollisions(rows) {
  const paths = rows.map((row) => unb64(row.pathBytes)).sort(Buffer.compare);
  for (let i = 0; i < paths.length; i++) {
    if (paths[i].length === 0 || paths[i][0] === 0x2f || paths[i].toString('binary').split('/').includes('..')) fail('restore contains an unsafe path');
    for (let j = i + 1; j < paths.length; j++) {
      if (paths[j].length > paths[i].length && paths[j].subarray(0, paths[i].length).equals(paths[i]) && paths[j][paths[i].length] === 0x2f) fail('restore contains colliding file and parent paths');
    }
  }
}
function materializeSnapshot(file, snap, root, relative) {
  assertNoSymlinkParents(root, relative);
  if (snap.kind === 'absent') return;
  const bytes = unb64(snap.data);
  if (Buffer.isBuffer(file)) {
    const slash = file.lastIndexOf(0x2f);
    if (slash >= 0) fs.mkdirSync(file.subarray(0, slash), { recursive: true });
  } else fs.mkdirSync(path.dirname(file), { recursive: true });
  if (snap.kind === 'symlink') {
    const linkTarget = process.platform === 'win32' ? bytes.toString('utf8') : bytes;
    if (process.platform === 'win32' && !Buffer.from(linkTarget).equals(bytes)) fail('unsupported non-UTF-8 symlink target on this host');
    fs.symlinkSync(linkTarget, file);
  }
  else if (snap.kind === 'file') { fs.writeFileSync(file, bytes, { mode: snap.mode & 0o7777 }); fs.chmodSync(file, snap.mode & 0o7777); }
  else fail('unsupported index object kind retained');
}
function restoreSnapshot(file, snap, root, relative) {
  assertNoSymlinkParents(root, relative);
  try { fs.rmSync(file, { force: true }); } catch {}
  materializeSnapshot(file, snap, root, relative);
}
export function verify({ repo, archiveRoot, captureId, publicPath, allowTemporary = true, _sourceCandidatesForTest = SOURCE_CANDIDATES } = {}) {
  if (!repo || !archiveRoot || !captureId) fail('verify requires repository, archive root, and capture ID');
  const verifiedArchiveRoot = privateRoot(fs.realpathSync(repo), archiveRoot, allowTemporary);
  const { dir, manifest, manifestHash } = readManifest(verifiedArchiveRoot, captureId);
  assertNoRestorePathCollisions(manifest.rows);
  const repoRoot = fs.realpathSync(repo); const now = statusNow(repoRoot);
  if (now.head !== manifest.source.head || now.tree !== manifest.source.headTree || sha(now.index) !== manifest.source.indexHash) fail('source baseline changed after capture; recapture before relying on this archive');
  const evidenceWriters = new Set([`${PHASE_REL}176-INVENTORY.json`, `${PHASE_REL}176-INVENTORY.md`]);
  for (const row of manifest.rows) {
    const rel = unb64(row.pathBytes);
    if (!evidenceWriters.has(rel.toString('utf8')) && row.worktree.kind !== 'unreadable' && row.worktree.kind !== 'gitlink') {
      assertNoSymlinkParents(repoRoot, rel);
      if (!snapshotEqual(safeSourceSnapshot(repoRoot, rel), snapshotFromToken(row.worktree))) fail('source file bytes, kind, or mode changed after capture');
    }
    for (const entry of row.index) {
      if (entry.intentToAdd || entry.mode === '160000' || entry.snapshot.kind === 'unreadable') continue;
      if (gitObjectHash(repoRoot, unb64(entry.snapshot.data)) !== entry.oid) fail('private index payload does not match its captured Git object identity');
    }
  }
  for (const guard of manifest.guardFiles ?? []) {
    if (guard.worktree.kind === 'unreadable' || guard.worktree.kind === 'gitlink') continue;
    const rel = unb64(guard.pathBytes); assertNoSymlinkParents(repoRoot, rel);
    if (!snapshotEqual(safeSourceSnapshot(repoRoot, rel), snapshotFromToken(guard.worktree))) fail('captured GSD writer source changed after capture');
    for (const entry of guard.index ?? []) {
      if (entry.intentToAdd || entry.mode === '160000') continue;
      if (gitObjectHash(repoRoot, unb64(entry.snapshot.data)) !== entry.oid) fail('private GSD index payload does not match its captured Git object identity');
    }
  }
  const baselineRows = manifest.source.statusRows;
  if (publicPath) {
    phaseArtifactPath(repoRoot, publicPath, '176-INVENTORY.json');
    const publicInventory = JSON.parse(fs.readFileSync(publicPath, 'utf8'));
    if (publicInventory.captureId !== captureId) fail('public inventory does not name the selected immutable capture');
    const ignored = Buffer.from(`${PHASE_REL}176-INVENTORY.json`);
    const expected = baselineRows.filter((r) => !unb64(r.path).equals(ignored)).map((r) => `${b64(unb64(r.path))}:${r.xy}:${r.source ?? ''}`).sort().join('\n');
    const observed = parseStatus(now.status).filter((r) => !r.path.equals(ignored) && (!r.source || !r.source.equals(ignored))).map((r) => `${b64(r.path)}:${r.xy}:${r.source ? b64(r.source) : ''}`).sort().join('\n');
    if (expected !== observed) fail('source status changed beyond the helper-owned public inventory');
  } else if (sha(now.status) !== manifest.source.statusHash) fail('source baseline changed after capture; recapture before relying on this archive');
  const scratch = fs.realpathSync(fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), 'crosswake-176-restore-')));
  let restoredUnits = 0;
  try {
    const collisions = new Map(); const unsupportedPaths = new Set(); const byPath = new Map(manifest.rows.map((r) => [bytesIdentity(unb64(r.pathBytes)), r]));
    const paths = [...byPath.keys()].map(unb64).sort(Buffer.compare);
    for (let i = 0; i < paths.length; i++) for (let j = i + 1; j < paths.length; j++) {
      if (paths[j].length > paths[i].length && paths[j].subarray(0, paths[i].length).equals(paths[i]) && paths[j][paths[i].length] === 0x2f) fail('restore contains colliding file and parent paths');
    }
    for (const row of manifest.rows) {
      const rel = unb64(row.pathBytes);
      const unsupported = row.worktree.kind === 'unreadable' || row.worktree.kind === 'gitlink' || row.index.some((e) => e.snapshot.kind === 'unreadable' || e.snapshot.kind === 'gitlink');
      if (unsupported) unsupportedPaths.add(bytesIdentity(rel));
    }
    const format = git(repoRoot, ['rev-parse', '--show-object-format']).toString('ascii').trim();
    scratchGit(scratch, ['init', '-q', `--object-format=${format}`]);
    scratchGit(scratch, ['fetch', '-q', '--no-tags', repoRoot, manifest.source.head]);
    scratchGit(scratch, ['checkout', '-q', '--detach', manifest.source.head]);
    mirrorStatusConfiguration(repoRoot, scratch);

    // Preflight every private target against the fetched base before changing
    // a byte. A Gitlink/special record is retained as a limitation, not counted
    // as a successful restore.
    for (const rel of paths) {
      const row = byPath.get(bytesIdentity(rel));
      if (!unsupportedPaths.has(bytesIdentity(rel))) assertNoSymlinkParents(scratch, rel);
      if (row.worktree.kind === 'gitlink') collisions.set(bytesIdentity(rel), 'gitlink');
    }
    for (const row of manifest.rows) {
      const rel = unb64(row.pathBytes); const key = bytesIdentity(rel);
      if (unsupportedPaths.has(key)) continue;
      const safe = absoluteFromBytes(scratch, rel); assertNoSymlinkParents(scratch, rel);
      const worktree = row.worktree;
      if (worktree.kind === 'absent') {
        try { fs.unlinkSync(safe); } catch (error) { if (error.code !== 'ENOENT') throw error; }
        restoredUnits++;
      } else {
        restoreSnapshot(safe, worktree, scratch, rel);
        const actual = fileSnapshot(safe);
        if (!snapshotEqual(actual, { kind: worktree.kind, mode: worktree.mode, bytes: unb64(worktree.data) })) fail('materialized worktree restore did not match captured kind, mode, and bytes');
        restoredUnits++;
      }
    }

    const indexEntries = manifest.source.indexEntries ?? [];
    const changedPathKeys = new Set(manifest.rows.map((row) => bytesIdentity(unb64(row.pathBytes))));
    const changedPaths = manifest.rows.map((row) => unb64(row.pathBytes));
    scratchGit(scratch, ['read-tree', manifest.source.head]);
    if (changedPaths.length) scratchGit(scratch, ['update-index', '--force-remove', '-z', '--stdin'], Buffer.concat(changedPaths.map((p) => Buffer.concat([p, Buffer.from([0])]))));
    const indexRecords = [];
    for (const entry of indexEntries) {
      const rel = unb64(entry.path); const key = bytesIdentity(rel);
      if (!changedPathKeys.has(key)) continue;
      if (unsupportedPaths.has(key)) continue;
      if ((/^0+$/.test(entry.oid) || entry.intentToAdd) && entry.stage === 0) continue; // Recreate the intent bit with git add -N below.
      let oid = entry.oid;
      if (!/^0+$/.test(oid)) {
        const present = scratchGitResult(scratch, ['cat-file', '-e', `${oid}^{blob}`]).status === 0;
        if (!present) {
          const row = byPath.get(key); const item = row?.index.find((candidate) => candidate.stage === entry.stage && candidate.oid === oid);
          if (!item || !['file', 'symlink'].includes(item.snapshot.kind)) fail('captured staged object cannot be restored without copying excluded content');
          const written = scratchGit(scratch, ['hash-object', '-w', '--stdin'], unb64(item.snapshot.data)).toString('ascii').trim();
          if (written !== oid) fail('restored staged bytes do not match their captured Git object identity');
        }
      }
      indexRecords.push({ ...entry, pathBytes: rel });
    }
    if (indexRecords.length) {
      const input = Buffer.concat(indexRecords.map((entry) => Buffer.concat([Buffer.from(`${entry.mode} ${entry.oid} ${entry.stage}\t`), entry.pathBytes, Buffer.from([0])])));
      scratchGit(scratch, ['update-index', '-z', '--index-info'], input);
      for (const entry of indexRecords) {
        if (byPath.has(bytesIdentity(entry.pathBytes))) restoredUnits++;
      }
    }
    for (const entry of indexEntries) {
      if ((/^0+$/.test(entry.oid) || entry.intentToAdd) && entry.stage === 0 && !unsupportedPaths.has(bytesIdentity(unb64(entry.path)))) {
        scratchGit(scratch, ['add', '--intent-to-add', '--pathspec-from-file=-', '--pathspec-file-nul'], Buffer.concat([unb64(entry.path), Buffer.from([0])]));
        if (byPath.has(bytesIdentity(unb64(entry.path)))) restoredUnits++;
      }
    }
    const actualIndexRaw = scratchGit(scratch, ['ls-files', '--stage', '-z']);
    const expectedIndex = normalizeIndexRows(indexEntries.filter((e) => !unsupportedPaths.has(bytesIdentity(unb64(e.path)))).map((e) => ({ ...e, path: unb64(e.path) })));
    const actualIndex = normalizeIndexRows(parseIndex(actualIndexRaw).filter((e) => !unsupportedPaths.has(bytesIdentity(e.path))));
    if (expectedIndex !== actualIndex) fail('scratch Git index stage records differ from the frozen captured index');
    if (unsupportedPaths.size === 0 && !actualIndexRaw.equals(unb64(manifest.source.indexRaw))) fail('scratch raw Git index records differ from the frozen captured records');

    const expectedStatus = normalizeStatusRows(manifest.source.statusRows.filter((r) => !unsupportedPaths.has(bytesIdentity(unb64(r.path))) && (!r.source || !unsupportedPaths.has(bytesIdentity(unb64(r.source))))).map((r) => ({ ...r, path: unb64(r.path), source: r.source ? unb64(r.source) : null })));
    const actualStatusRaw = scratchGit(scratch, ['status', '--porcelain=v1', '-z', '--untracked-files=all']);
    const actualStatus = normalizeStatusRows(parseStatus(actualStatusRaw).filter((r) => !unsupportedPaths.has(bytesIdentity(r.path)) && (!r.source || !unsupportedPaths.has(bytesIdentity(r.source)))));
    if (expectedStatus !== actualStatus) fail('scratch Git status differs from the frozen captured status rows');
    if (unsupportedPaths.size === 0 && !actualStatusRaw.equals(unb64(manifest.source.statusRaw))) fail('scratch raw Git status differs from the frozen captured records');

    const provenance = validateSourceProvenance(repoRoot, scratch, manifest, _sourceCandidatesForTest);
    const recoveredRows = Object.fromEntries(manifest.rows.map((row) => {
      const unsupported = unsupportedPaths.has(bytesIdentity(unb64(row.pathBytes)));
      const worktreeUnits = unsupported ? 0 : 1;
      const indexUnits = unsupported ? 0 : row.index.filter((e) => !(e.intentToAdd || /^0+$/.test(e.oid) && e.stage === 0)).length;
      return [row.rowId, { restoredFromFrozenCapture: !unsupported, restoredUnits: worktreeUnits + indexUnits, limitations: unsupported ? ['unsupported or unreadable path retained; not counted as restored'] : [] }];
    }));
    const proof = { schema: 1, captureId, manifestHash, createdAt: new Date().toISOString(), source: { head: manifest.source.head, tree: manifest.source.headTree, statusHash: manifest.source.statusHash, indexHash: manifest.source.indexHash }, provenance, rows: recoveredRows };
    persistVerifiedProof(verifiedArchiveRoot, dir, captureId, proof);
    if (publicPath) {
      const publicInventory = JSON.parse(fs.readFileSync(publicPath, 'utf8'));
      if (publicInventory.captureId !== captureId) fail('public inventory does not name the selected immutable capture');
      validatePublicRows(publicInventory, manifest, proof, repoRoot);
    }

    const limitations = [];
    if (!provenance.verified) limitations.push({ reason: `source comparison unresolved: ${provenance.reason}` });
    for (const r of manifest.rows) {
      if (r.worktree.kind === 'gitlink' || r.index.some((i) => i.snapshot.kind === 'gitlink')) limitations.push({ rowId: r.rowId, reason: 'gitlink commit identity retained; nested repository bytes and exact status are not restored' });
      if (r.worktree.kind === 'unreadable' || r.index.some((i) => i.snapshot.kind === 'unreadable')) {
        const reason = r.worktree.reason?.includes('unsupported filesystem object') ? 'unsupported filesystem type retained; exact status is not restored' : 'sensitive or unreadable path payload excluded; exact status is not restored';
        limitations.push({ rowId: r.rowId, reason });
      }
    }
    return { ok: true, captureId, restoredUnits, limitations, sourceProvenanceVerified: provenance.verified, sourceProvenanceReason: provenance.reason, sourceProvenanceCandidates: provenance.candidates?.map(({ commit, ancestor, parentsVerified }) => ({ commit, ancestor, parentsVerified })) ?? [] };
  } finally { fs.rmSync(scratch, { recursive: true, force: true }); }
}

export function policyFacts(policy, repoPath, { ignored = false, tracked = false } = {}) {
  const match = (matcher, value) => {
    if (matcher.kind === 'exact') return value === matcher.value;
    if (matcher.kind === 'segment') return value.split('/').includes(matcher.value);
    if (matcher.kind === 'suffix') return value.endsWith(matcher.value);
    if (matcher.kind === 'tree') return value === matcher.value || value.startsWith(matcher.value + '/');
    return false;
  };
  const ignoredMatch = policy.ignored_transient.find((x) => x.matchers.some((m) => match(m, repoPath))) ?? null;
  const intentional = policy.intentionally_tracked.find((x) => x.paths.some((p) => repoPath === p || repoPath.startsWith(p + '/'))) ?? null;
  const forbiddenRaw = policy.forbidden_tracked.find((x) => x.matchers.some((m) => match(m, repoPath))) ?? null;
  const safeFixture = policy.safe_fixtures.find((x) => x.path === repoPath) ?? null;
  const forbidden = forbiddenRaw && !(safeFixture && safeFixture.forbidden_category === forbiddenRaw.category) ? forbiddenRaw : null;
  const generated = policy.generated_contracts.filter((x) => x.canonical_source === repoPath || x.output_paths.includes(repoPath));
  return { ignored, tracked, ignoredPolicyCategory: ignoredMatch?.category ?? null, intentionallyTrackedCategory: intentional?.category ?? null, forbiddenToTrackCategory: forbidden?.category ?? null, safeFixture: safeFixture !== null, generatedContractOwners: generated.map((x) => ({ canonicalSource: x.canonical_source, regenerationArgv: x.regeneration_argv, outputs: x.output_paths })), disposable: false };
}
const SOURCE_CANDIDATES = Object.freeze(['6da6df6f9ddc0f48614fd99c50decc6dc23387c4', '2dbde2d9be8adfa36009e20bf894b00a5bb63e87', 'd0dbdf7bf196cea167ced3c50cf620bf3cb2452b']);
function optionalScratchGit(cwd, args) { return scratchGitResult(cwd, args); }
function compareRowsWithCandidates(scratch, manifest, sourceCandidates = SOURCE_CANDIDATES) {
  const comparisons = {}; const listTree = (commit) => {
    const entries = new Map(); const raw = scratchGit(scratch, ['ls-tree', '-r', '-z', '--full-tree', commit]);
    for (const record of splitNul(raw)) { const tab = record.indexOf(0x09); if (tab < 0) continue; const [mode, type, oid] = record.subarray(0, tab).toString('ascii').split(' '); entries.set(bytesIdentity(record.subarray(tab + 1)), { mode, type, oid }); }
    return entries;
  };
  const headEntries = listTree(manifest.source.head);
  for (const candidate of sourceCandidates) {
    const entries = listTree(candidate);
    const candidateTree = scratchGit(scratch, ['rev-parse', `${candidate}^{tree}`]).toString('ascii').trim();
    for (const row of manifest.rows) {
      const rel = unb64(row.pathBytes); const entry = entries.get(bytesIdentity(rel));
      if (row.worktree.kind === 'unreadable' || row.worktree.kind === 'gitlink' || row.index.some((x) => x.snapshot.kind === 'unreadable' || x.snapshot.kind === 'gitlink' || x.stage !== 0)) continue;
      const matchesEntry = (snapshot, mode, target) => {
        if (snapshot.kind === 'absent') return !target;
        if (!target || target.type !== 'blob') return false;
        const wantedMode = mode === '120000' ? '120000' : ((mode & 0o111) ? '100755' : '100644');
        if (target.mode !== wantedMode) return false;
        const oid = scratchGit(scratch, ['hash-object', '--stdin'], unb64(snapshot.data)).toString('ascii').trim();
        return oid === target.oid;
      };
      const headEntry = headEntries.get(bytesIdentity(rel)); const stage0 = row.index.find((x) => x.stage === 0);
      const headEqual = !headEntry ? !entry : !!entry && headEntry.mode === entry.mode && headEntry.type === entry.type && headEntry.oid === entry.oid;
      const indexEqual = stage0 ? matchesEntry(stage0.snapshot, stage0.mode, entry) : !entry && row.index.length === 0;
      const worktreeEqual = matchesEntry(row.worktree, row.worktree.kind === 'symlink' ? '120000' : row.worktree.mode, entry);
      const capturedHeadToIndex = stage0 ? headEntry?.mode === stage0.mode && headEntry?.oid === stage0.oid : !headEntry && row.index.length === 0;
      const capturedIndexToWorktree = stage0 ? matchesEntry(row.worktree, row.worktree.kind === 'symlink' ? '120000' : row.worktree.mode, { mode: stage0.mode === '120000' ? '120000' : ((Number.parseInt(stage0.mode, 8) & 0o111) ? '100755' : '100644'), type: 'blob', oid: stage0.oid }) : false;
      (comparisons[row.rowId] ??= { capturedHeadToIndex: capturedHeadToIndex ? 'exactly-equal' : 'different-or-no-stage-zero', capturedIndexToWorktree: capturedIndexToWorktree ? 'exactly-equal' : 'different-or-no-stage-zero', candidates: [] }).candidates.push({ commit: candidate, tree: candidateTree, headEqual, indexEqual, worktreeEqual, semanticEquivalenceReviewed: false });
    }
  }
  return comparisons;
}
function validateSourceProvenance(repo, scratch, manifest, sourceCandidates = SOURCE_CANDIDATES) {
  const remote = optionalScratchGit(repo, ['config', '--get', 'remote.origin.url']);
  if (remote.status !== 0) return { verified: false, reason: 'configured origin unavailable', defaultTip: null, candidates: [], comparisons: {} };
  scratchGit(scratch, ['remote', 'add', 'origin', remote.stdout.toString('utf8').trim()]);
  const advertised = scratchGit(scratch, ['ls-remote', '--symref', 'origin', 'HEAD']).toString('utf8');
  const ref = /^ref:\s+(refs\/heads\/[^\t]+)\tHEAD$/m.exec(advertised)?.[1];
  const tip = /^([0-9a-f]{40,64})\tHEAD$/m.exec(advertised)?.[1];
  if (!ref || !tip) return { verified: false, reason: 'origin did not advertise a symbolic default tip', defaultTip: null, candidates: [], comparisons: {} };
  const fetchTip = scratchGitResult(scratch, ['fetch', '-q', '--no-tags', 'origin', tip]);
  if (fetchTip.status !== 0) return { verified: false, reason: 'advertised default tip could not be fetched into scratch', defaultTip: null, candidates: [], comparisons: {} };
  const actualTip = scratchGit(scratch, ['rev-parse', 'FETCH_HEAD']).toString('ascii').trim();
  if (actualTip !== tip) fail('origin default tip changed between advertisement and scratch fetch');
  for (const candidate of sourceCandidates) {
    const fetched = scratchGitResult(scratch, ['fetch', '-q', '--no-tags', 'origin', candidate]);
    if (fetched.status !== 0) return { verified: false, reason: 'candidate commit objects could not be fetched into scratch', defaultTip: { ref, commit: tip, tree: scratchGit(scratch, ['rev-parse', `${tip}^{tree}`]).toString('ascii').trim() }, candidates: [], comparisons: {} };
  }
  const candidates = [];
  for (const commit of sourceCandidates) {
    const exists = optionalScratchGit(scratch, ['cat-file', '-e', `${commit}^{commit}`]);
    if (exists.status !== 0) continue;
    const tree = scratchGit(scratch, ['rev-parse', `${commit}^{tree}`]).toString('ascii').trim();
    const ancestor = optionalScratchGit(scratch, ['merge-base', '--is-ancestor', commit, tip]).status === 0;
    const parents = scratchGit(scratch, ['rev-list', '--parents', '-n', '1', commit]).toString('ascii').trim().split(/\s+/).slice(1);
    const parentsVerified = parents.length > 0 && parents.every((parent) => optionalScratchGit(scratch, ['cat-file', '-e', `${parent}^{commit}`]).status === 0 && optionalScratchGit(scratch, ['merge-base', '--is-ancestor', parent, tip]).status === 0);
    candidates.push({ commit, tree, parents, ancestor, parentsVerified });
  }
  const tipTree = scratchGit(scratch, ['rev-parse', `${tip}^{tree}`]).toString('ascii').trim();
  const comparisons = compareRowsWithCandidates(scratch, manifest, sourceCandidates);
  const verified = candidates.length === sourceCandidates.length && candidates.every((x) => x.ancestor && x.parentsVerified);
  return { verified, reason: verified ? null : 'candidate commit, parent, or default-tip ancestry validation failed', defaultTip: { ref, commit: tip, tree: tipTree }, candidates, comparisons };
}

function validateDisposition(row) {
  if (!DISPOSITIONS.has(row.disposition) || typeof row.reason !== 'string' || !row.reason.trim() || typeof row.nextOwner !== 'string' || !row.nextOwner.trim()) fail('each row needs one supported disposition, reason, and next owner/action');
  for (const text of [row.reason, row.nextOwner]) {
    if (text.length > 500 || /(?:^|\s)\/(?:Users|private|var|tmp)\//.test(text) || /\b[a-f0-9]{40,64}\b/i.test(text) || /(?:payload|symlink target|archive path|digest|file size)\s*[:=]/i.test(text)) fail('public disposition text contains private evidence detail');
  }
  if (row.disposition === 'already merged' && (!row.comparison || !/^[0-9a-f]{40,64}$/.test(row.comparison.commit ?? '') || !/^[0-9a-f]{40,64}$/.test(row.comparison.tree ?? ''))) fail('already merged requires exact commit and tree evidence');
}
function validatePublicRows(pub, manifest, proof = null, repo = null) {
  if (pub.schema !== 1 || !Array.isArray(pub.rows)) fail('public inventory schema is malformed');
  const completeInventory = typeof pub.artifactPolicySummary === 'string' || Array.isArray(pub.generatedContracts);
  if (completeInventory && pub.rows.some((r) => !r.recovery || !r.comparison || !r.policyFacts)) fail('complete inventory rows need recovery, exact-comparison, and artifact-policy facts');
  const expected = new Set(manifest.rows.map((r) => r.rowId)); const seen = new Set();
  for (const row of pub.rows) {
    if (!row || typeof row.rowId !== 'string' || seen.has(row.rowId)) fail('public row identity is malformed or duplicated');
    seen.add(row.rowId); validateDisposition(row);
    if (row.path !== null && (typeof row.path !== 'string' || SECRET_NAME.test(row.path) || row.path.startsWith('/') || row.path.split('/').includes('..'))) fail('public path is unsafe');
    const source = manifest.rows.find((r) => r.rowId === row.rowId);
    if (!source || row.status !== source.xy) fail('public status or row identity differs from the frozen capture');
    const display = safeDisplay(unb64(source.pathBytes));
    if (row.path !== display || row.pathRef !== (display ? null : row.rowId)) fail('public path mapping differs from the safe frozen identity');
    const privateComparison = proof?.provenance?.comparisons?.[row.rowId];
    if (row.disposition === 'already merged') {
      const exact = privateComparison?.candidates?.find((candidate) => candidate.commit === row.comparison.commit && candidate.tree === row.comparison.tree && candidate.indexEqual && candidate.worktreeEqual);
      if (!proof?.provenance?.verified || !exact) fail('already-merged claim has no exact per-path match in privately verified source provenance');
    }
    if (row.recovery) {
      const recovered = proof?.rows?.[row.rowId];
      if (!recovered || row.recovery.archiveReadback !== true || row.recovery.restoredFromFrozenCapture !== recovered.restoredFromFrozenCapture || JSON.stringify(row.recovery.limitations ?? []) !== JSON.stringify(recovered.limitations)) fail('public recovery claim differs from private restore proof');
    }
    if (row.comparison?.candidates) {
      if (!privateComparison || JSON.stringify(row.comparison.candidates) !== JSON.stringify(privateComparison.candidates)) fail('public per-path comparison differs from frozen Git tree comparisons');
    }
    if (row.comparison && privateComparison) {
      if (row.comparison.capturedHeadToIndex !== privateComparison.capturedHeadToIndex || row.comparison.capturedIndexToWorktree !== privateComparison.capturedIndexToWorktree) fail('public equality summary differs from frozen index/worktree bytes');
    }
    if (row.policyFacts && repo) {
      const policyPath = path.join(repo, 'script/repository_artifact_policy.json'); const policy = JSON.parse(fs.readFileSync(policyPath, 'utf8'));
      const tracked = manifest.source.indexEntries.some((entry) => unb64(entry.path).equals(unb64(source.pathBytes)));
      const ignored = spawnSync('git', ['check-ignore', '-q', '--', display ?? ''], { cwd: repo, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' }, encoding: null, timeout: 5000 }).status === 0;
      const facts = policyFacts(policy, display ?? '', { ignored, tracked });
      const expectedOwner = facts.generatedContractOwners.length ? { canonicalSource: facts.generatedContractOwners[0].canonicalSource, regenerationArgv: facts.generatedContractOwners[0].regenerationArgv, outputs: facts.generatedContractOwners[0].outputs } : null;
      for (const [actualKey, expectedValue] of [['ignoredByGit', facts.ignored], ['trackedInCapturedIndex', facts.tracked], ['ignoredPolicyCategory', facts.ignoredPolicyCategory], ['intentionallyTrackedCategory', facts.intentionallyTrackedCategory], ['forbiddenToTrackCategory', facts.forbiddenToTrackCategory], ['generatedContractOwner', expectedOwner]]) {
        if (JSON.stringify(row.policyFacts[actualKey] ?? null) !== JSON.stringify(expectedValue)) fail(`public policy fact ${actualKey} differs from the repository policy or captured index`);
      }
      const safeFixtureException = facts.safeFixture ? { path: display, purpose: policy.safe_fixtures.find((item) => item.path === display)?.purpose } : null;
      if (JSON.stringify(row.policyFacts.safeFixtureException ?? null) !== JSON.stringify(safeFixtureException)) fail('public safe-fixture exception differs from the checked-in artifact policy');
      if (row.policyFacts.obsoleteStatus !== 'not established; requires Phase 177 ownership and caller review' || row.policyFacts.disposable !== false) fail('public obsolete/disposable claim exceeds established Phase 176 ownership evidence');
    }
  }
  if (seen.size !== expected.size || [...expected].some((x) => !seen.has(x))) fail('public path rows do not exactly cover the frozen capture');
  if (completeInventory && repo) {
    const policy = JSON.parse(fs.readFileSync(path.join(repo, 'script/repository_artifact_policy.json'), 'utf8'));
    const canonical = (pub.generatedContracts ?? []).map((x) => ({ canonicalSource: x.canonicalSource, regenerationArgv: x.regenerationArgv, outputs: x.outputs }));
    const expectedContracts = policy.generated_contracts.map((x) => ({ canonicalSource: x.canonical_source, regenerationArgv: x.regeneration_argv, outputs: x.output_paths }));
    if (JSON.stringify(canonical) !== JSON.stringify(expectedContracts)) fail('generated-contract owner map differs from the checked-in policy source');
  }
}
const WRITER_DELTAS = new Set(['phase-summary', 'state-handoff', 'roadmap-handoff', 'requirements-phase176', 'state-projection', 'validation-signoff', 'phase-evidence', 'conditional-gate', 'scoped-contract-correction']);
function validateWriterLedger(ledger) {
  if (!Array.isArray(ledger)) fail('final audit requires an explicit evidence-writer ledger');
  const byPath = new Map();
  for (const item of ledger) {
    const prefix = '.planning/workstreams/quality-ratchet-release/';
    const phaseDir = `${prefix}phases/176-local-work-and-artifact-disposition/`;
    const allowedPaths = {
      'state-handoff': [`${prefix}STATE.md`],
      'roadmap-handoff': [`${prefix}ROADMAP.md`],
      'requirements-phase176': [`${prefix}REQUIREMENTS.md`],
      'state-projection': [`${prefix}state.json`],
      'validation-signoff': [`${phaseDir}176-VALIDATION.md`],
      'phase-summary': [`${phaseDir}176-01-SUMMARY.md`, `${phaseDir}176-02-SUMMARY.md`],
      'phase-evidence': [`${phaseDir}176-INVENTORY.json`, `${phaseDir}176-INVENTORY.md`],
      'scoped-contract-correction': [`${phaseDir}176-evidence.mjs`, `${phaseDir}176-evidence.test.mjs`],
      'conditional-gate': ['176-VERIFICATION.md', '176-SECURITY.md', '176-REVIEW.md', '176-REVIEW-DISPOSITION.md', '176-REVIEW-FIX.md', '176-UAT.md', '176-LEARNINGS.md'].map((name) => `${phaseDir}${name}`)
    };
    if (!item || typeof item.path !== 'string' || !WRITER_DELTAS.has(item.allowedDelta) || !allowedPaths[item.allowedDelta]?.includes(item.path) || typeof item.owner !== 'string' || !item.owner.trim()) fail('writer ledger entry lacks an exact owned Phase 176 path, owner, or allowed delta');
    if (item.allowedDelta === 'conditional-gate') {
      const receipt = item.producerReceipt;
      if (item.conditionMet !== true || !receipt || receipt.path !== item.path || typeof receipt.captureId !== 'string' || typeof receipt.observedStatus !== 'string' || !receipt.observedStatus.trim()) fail('conditional writer lacks a true condition and artifact-bound producer receipt');
    }
    if (byPath.has(item.path)) fail('writer ledger has duplicate paths');
    byPath.set(item.path, item);
  }
  return byPath;
}
function snapshotFromToken(snap) {
  if (snap.kind === 'absent' || snap.kind === 'unreadable') return { kind: snap.kind };
  return { kind: snap.kind, mode: snap.mode, bytes: unb64(snap.data) };
}
function normalizedIndex(entries) { return entries.map((e) => `${e.stage}:${e.mode}:${e.oid}`).sort().join('\n'); }
function checkScopedWriter(repo, relative, allowedDelta, manifest) {
  const guard = manifest.guardFiles?.find((g) => unb64(g.pathBytes).toString('utf8') === relative);
  if (!guard || guard.worktree.kind !== 'file') fail(`writer path lacks a readable frozen source: ${relative}`);
  const relativeBytes = Buffer.from(relative); assertNoSymlinkParents(repo, relativeBytes);
  const beforeBytes = unb64(guard.worktree.data); const after = safeSourceSnapshot(repo, relativeBytes);
  if (after.kind !== 'file') fail(`writer output changed file kind: ${relative}`);
  const before = beforeBytes.toString('utf8'); const afterText = after.bytes.toString('utf8');
  if (!Buffer.from(before).equals(beforeBytes) || !Buffer.from(afterText).equals(after.bytes)) fail(`writer source is not UTF-8 text: ${relative}`);
  if (allowedDelta === 'state-handoff') validateStateDocumentDelta(before, afterText);
  else if (allowedDelta === 'roadmap-handoff') validateRoadmapDocumentDelta(before, afterText);
  else if (allowedDelta === 'state-projection') {
    const parsed = JSON.parse(afterText);
    if (afterText !== JSON.stringify(parsed, null, 2) + '\n') fail('state.json is not in the installed two-space JSON plus newline format');
    validateStateJsonDelta(JSON.parse(before), parsed);
  }
  else if (allowedDelta === 'requirements-phase176') validateRequirementsDelta(before, afterText);
  else if (allowedDelta === 'validation-signoff') validateValidationDelta(before, afterText);
  else if (allowedDelta === 'conditional-gate' && relative.endsWith('176-UAT.md')) validateUat(JSON.parse(afterText));
  return { path: relative, ownerDelta: allowedDelta, changed: true };
}
export function audit({ repo, archiveRoot, captureId, publicPath, final = false, renderedPath, uatPath, allowTemporary = true, _afterSidecarForTest } = {}) {
  if (!repo || !archiveRoot || !captureId || !publicPath) fail('audit requires repository, archive root, capture ID, and public inventory');
  const verifiedArchiveRoot = privateRoot(fs.realpathSync(repo), archiveRoot, allowTemporary);
  const { dir, manifest, manifestHash } = readManifest(verifiedArchiveRoot, captureId);
  const proof = readVerifiedProof(verifiedArchiveRoot, dir, captureId, manifestHash);
  const sidecarPath = path.join(dir, 'final-audit.json');
  if (final) { try { fs.unlinkSync(sidecarPath); } catch (error) { if (error.code !== 'ENOENT') throw error; } }
  const repoRootForAudit = fs.realpathSync(repo);
  const safePublicPath = phaseArtifactPath(repoRootForAudit, publicPath, '176-INVENTORY.json');
  const pub = JSON.parse(fs.readFileSync(safePublicPath, 'utf8')); validatePublicRows(pub, manifest, proof, repoRootForAudit);
  if (renderedPath) {
    const safeRenderedPath = phaseArtifactPath(repoRootForAudit, renderedPath, '176-INVENTORY.md');
    if (!fs.existsSync(safeRenderedPath)) fail('rendered inventory is missing');
    const expected = render(pub); if (fs.readFileSync(safeRenderedPath, 'utf8') !== expected) fail('rendered inventory differs from its JSON source');
  }
  if (uatPath && fs.existsSync(uatPath)) validateUat(JSON.parse(fs.readFileSync(uatPath, 'utf8')));
  if (!final) {
    const repoRoot = repoRootForAudit; const live = statusNow(repoRoot);
    if (live.head !== manifest.source.head || live.tree !== manifest.source.headTree || !live.index.equals(unb64(manifest.source.indexRaw))) fail('source HEAD, tree, or full index changed after frozen capture');
    const excluded = new Set([path.relative(repoRoot, safePublicPath), ...(renderedPath ? [path.relative(repoRoot, phaseArtifactPath(repoRoot, renderedPath, '176-INVENTORY.md'))] : [])].map((p) => b64(Buffer.from(p))));
    const expectedStatus = manifest.source.statusRows.filter((r) => !excluded.has(r.path)).map((r) => `${r.path}:${r.xy}:${r.source ?? ''}`).sort().join('\n');
    const observedStatus = parseStatus(live.status).filter((r) => !excluded.has(b64(r.path)) && (!r.source || !excluded.has(b64(r.source)))).map((r) => `${b64(r.path)}:${r.xy}:${r.source ? b64(r.source) : ''}`).sort().join('\n');
    if (expectedStatus !== observedStatus) fail('source Git status changed beyond the named inventory/render artifacts');
    for (const row of manifest.rows) {
      if (excluded.has(row.pathBytes) || ['unreadable', 'gitlink'].includes(row.worktree.kind)) continue;
      if (!snapshotEqual(safeSourceSnapshot(repoRoot, unb64(row.pathBytes)), snapshotFromToken(row.worktree))) fail('captured source bytes, kind, or mode changed after verification');
    }
    for (const guard of manifest.guardFiles ?? []) if (!['unreadable', 'gitlink'].includes(guard.worktree.kind) && !snapshotEqual(safeSourceSnapshot(repoRoot, unb64(guard.pathBytes)), snapshotFromToken(guard.worktree))) fail('captured GSD writer bytes changed after verification');
  }
  if (final) {
    const repoRoot = fs.realpathSync(repo); const current = statusNow(repoRoot);
    if (current.head !== manifest.source.head || current.tree !== manifest.source.headTree) fail('source HEAD or tree changed after frozen capture');
    if (!current.index.equals(unb64(manifest.source.indexRaw))) fail('the complete Git index changed after frozen capture, including writer-owned paths');
    const writers = validateWriterLedger(pub.writerLedger);
    const baseRows = new Map(manifest.rows.map((r) => [bytesIdentity(unb64(r.pathBytes)), r]));
    const guardFiles = new Map((manifest.guardFiles ?? []).map((g) => [bytesIdentity(unb64(g.pathBytes)), g]));
    const currentStatuses = parseStatus(current.status); const currentByPath = new Map();
    for (const record of currentStatuses) { currentByPath.set(bytesIdentity(record.path), record.xy); if (record.source) currentByPath.set(bytesIdentity(record.source), record.xy); }
    for (const writer of writers.values()) if (writer.allowedDelta === 'conditional-gate') {
      const key = bytesIdentity(Buffer.from(writer.path));
      const observed = currentByPath.get(key); const receipt = writer.producerReceipt;
      if (!observed || receipt.captureId !== captureId || receipt.observedStatus !== observed) fail('conditional gate producer receipt is stale or does not match observed Git status');
      const file = safeSourceSnapshot(repoRoot, Buffer.from(writer.path));
      if (file.kind !== 'file') fail('conditional gate artifact is not a readable regular file');
      const prior = baseRows.get(key) ?? guardFiles.get(key);
      if (prior && snapshotEqual(file, snapshotFromToken(prior.worktree))) fail('conditional gate artifact was not produced after the frozen capture');
      if (writer.path.endsWith('176-UAT.md')) validateUat(JSON.parse(file.bytes.toString('utf8')));
      writer._privateReceipt = { path: writer.path, sha256: sha(file.bytes), observedStatus: observed, captureId };
    }
    const currentIndex = parseIndex(current.index); const currentIndexByPath = new Map();
    for (const entry of currentIndex) { const k = bytesIdentity(entry.path); const list = currentIndexByPath.get(k) ?? []; list.push(entry); currentIndexByPath.set(k, list); }
    const observedDeltas = []; const writerFrozen = new Map();
    for (const key of baseRows.keys()) {
      const display = safeDisplay(unb64(key));
      if (!currentByPath.has(key) && !(display && writers.has(display))) fail('a captured changed path disappeared from final status without an owned writer');
    }
    for (const [key, xy] of currentByPath) {
      const relBytes = unb64(key); const display = safeDisplay(relBytes); const writer = display ? writers.get(display) : null;
      const captured = baseRows.get(key); const guard = guardFiles.get(key);
      if (!captured && !guard && !writer) fail('final audit found an unowned changed path');
      if (writer) {
        const writerSnapshot = safeSourceSnapshot(repoRoot, relBytes);
        if (writerSnapshot.kind !== 'file') fail('owned writer output must be a readable regular file');
        if (writer.allowedDelta === 'scoped-contract-correction') {
          const binding = safeSourceSnapshot(verifiedArchiveRoot, Buffer.from(`${captureId}/scoped-writer-corrections.json`));
          if (binding.kind !== 'file' || binding.mode !== 0o400) fail('scoped contract correction lacks a private immutable binding');
          const approvals = JSON.parse(binding.bytes.toString('utf8'));
          const original = baseRows.get(key);
          const approval = approvals.files?.find((item) => item.path === writer.path);
          if (approvals.captureId !== captureId || !original || original.worktree.kind !== 'file' || !approval || approval.originalHash !== sha(unb64(original.worktree.data)) || approval.correctedHash !== sha(writerSnapshot.bytes) || writerSnapshot.mode !== original.worktree.mode) fail('scoped contract correction differs from its reviewed exact original/current binding');
        }
        writerFrozen.set(writer.path, writerSnapshot);
        if (['state-handoff', 'roadmap-handoff', 'requirements-phase176', 'state-projection', 'validation-signoff'].includes(writer.allowedDelta)) observedDeltas.push(checkScopedWriter(repoRoot, writer.path, writer.allowedDelta, manifest));
        else {
          observedDeltas.push({ path: writer.path, ownerDelta: writer.allowedDelta, changed: true, privateReceipt: writer._privateReceipt ?? null });
        }
        const frozen = baseRows.get(key) ?? guard;
        if (frozen && normalizedIndex(currentIndexByPath.get(key) ?? []) !== normalizedIndex(frozen.index ?? [])) fail('final audit found an index change on a writer-owned path');
        continue;
      }
      if (captured && xy !== captured.xy) fail('final audit found an unowned status change for a captured path');
      const original = captured ?? guard;
      if (original.worktree.kind !== 'unreadable' && original.worktree.kind !== 'gitlink') {
        assertNoSymlinkParents(repoRoot, relBytes);
        const actual = safeSourceSnapshot(repoRoot, relBytes);
        if (!snapshotEqual(actual, snapshotFromToken(original.worktree))) fail('final audit found an unowned worktree byte, kind, or mode change');
      }
      if (normalizedIndex(currentIndexByPath.get(key) ?? []) !== normalizedIndex(original.index ?? [])) fail('final audit found an unowned index change');
    }
    const before = sha(current.status);
    const sidecar = { captureId, auditedAt: new Date().toISOString(), sourceHead: current.head, statusHash: before, result: 'pass', observedDeltas };
    const sidecarPath = path.join(dir, 'final-audit.json');
    const assertFrozenAfterWrite = () => {
      const latest = statusNow(repoRoot);
      if (latest.head !== manifest.source.head || latest.tree !== manifest.source.headTree || !latest.index.equals(unb64(manifest.source.indexRaw)) || sha(latest.status) !== before) fail('source Git state changed while final audit was recording its result');
      for (const row of manifest.rows) {
        if (['unreadable', 'gitlink'].includes(row.worktree.kind)) continue;
        const writerPath = unb64(row.pathBytes).toString('utf8');
        if (writerFrozen.has(writerPath)) continue;
        const latestBytes = safeSourceSnapshot(repoRoot, unb64(row.pathBytes));
        if (!snapshotEqual(latestBytes, snapshotFromToken(row.worktree))) fail('captured worktree bytes, kind, or mode changed while final audit was recording its result');
      }
      for (const guard of manifest.guardFiles ?? []) {
        if (['unreadable', 'gitlink'].includes(guard.worktree.kind)) continue;
        const latestBytes = safeSourceSnapshot(repoRoot, unb64(guard.pathBytes));
        if (!snapshotEqual(latestBytes, snapshotFromToken(guard.worktree))) {
          const writer = writers.get(unb64(guard.pathBytes).toString('utf8'));
          if (!writer) fail('captured guard bytes changed while final audit was recording its result');
          checkScopedWriter(repoRoot, writer.path, writer.allowedDelta, manifest);
        }
      }
      for (const [writerPath, snapshot] of writerFrozen) {
        if (!snapshotEqual(safeSourceSnapshot(repoRoot, Buffer.from(writerPath)), snapshot)) fail('owned writer output bytes, kind, or mode changed while final audit was recording its result');
      }
    };
    assertFrozenAfterWrite();
    const tmp = `${sidecarPath}.tmp-${crypto.randomBytes(6).toString('hex')}`;
    try {
      syncFile(tmp, Buffer.from(JSON.stringify(sidecar, null, 2) + '\n')); fs.renameSync(tmp, sidecarPath); fsyncDir(dir);
      if (_afterSidecarForTest) _afterSidecarForTest();
      assertFrozenAfterWrite();
    } catch (error) {
      try { fs.unlinkSync(sidecarPath); } catch {}
      try { fs.unlinkSync(tmp); } catch {}
      throw error;
    }
  }
  return { ok: true, captureId, rows: pub.rows.length, final, limitations: pub.limitations ?? [] };
}
export const EXPECTED_UAT_ASSERTIONS = Object.freeze(['176-coverage', '176-private-restore', '176-source-provenance', '176-policy-ownership', '176-phase177-handoff']);
export function validateUat(value) {
  if (!value || !Array.isArray(value.assertions)) fail('UAT assertion ledger is malformed');
  if (value.assertions.length === 0) fail('UAT assertion ledger is empty');
  const ids = value.assertions.map((assertion) => assertion?.id);
  if (new Set(ids).size !== ids.length) fail('UAT assertion IDs are duplicated');
  for (const assertion of value.assertions) {
    if (!assertion || typeof assertion.id !== 'string' || typeof assertion.required !== 'boolean' || !['passed', 'failed', 'pending'].includes(assertion.status)) fail('malformed required UAT assertion');
    if (assertion.required && assertion.status !== 'passed') fail('required UAT assertion is failed or pending');
  }
  if (value.humanOnlyUnmet !== undefined && typeof value.humanOnlyUnmet !== 'boolean') fail('UAT human-only result is malformed');
  if (value.humanOnlyUnmet === true) fail('human-only UAT assertion remains unmet');
  for (const expected of EXPECTED_UAT_ASSERTIONS) if (!ids.includes(expected)) fail(`UAT is missing expected Phase 176 assertion ${expected}`);
  for (const id of ids) if (!EXPECTED_UAT_ASSERTIONS.includes(id)) fail(`UAT contains an unexpected Phase 176 assertion ${id}`);
  return true;
}
function normalizedHandoffSection(text, heading = '## Exact Next Action') {
  const escaped = heading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const matches = [...text.matchAll(new RegExp(`^${escaped}[ \\t]*\\r?$`, 'gm'))];
  if (matches.length !== 1) fail('handoff section anchor is missing or duplicated');
  const start = matches[0].index + matches[0][0].length;
  const rest = text.slice(start);
  const next = /^##[ \t]+[^\n]*$/m.exec(rest);
  const section = rest.slice(0, next ? next.index : rest.length);
  const lines = section.split(/(?<=\n)/);
  let command = -1;
  for (let i = 0; i < lines.length; i++) if (/^`[^`]+`\r?\n?$/.test(lines[i].trimEnd())) { command = i; break; }
  if (command < 0) fail('handoff command anchor is missing');
  let first = command + 1;
  while (first < lines.length && /^\s*$/.test(lines[first])) first++;
  if (first >= lines.length) fail('active handoff paragraph is missing');
  let end = first;
  while (end < lines.length && !/^\s*$/.test(lines[end])) end++;
  const commandText = lines[command];
  const activeParagraph = lines.slice(first, end).join('').trim();
  lines[command] = '<MUTABLE_ACTIVE_COMMAND>\n';
  lines.splice(first, end - first, '<MUTABLE_ACTIVE_PARAGRAPH>\n');
  return { normalized: text.slice(0, start) + lines.join('') + text.slice(start + section.length), commandText: commandText.trim(), activeParagraph };
}
export function validateStateBodyDelta(before, after) {
  let left = before, right = after;
  [left, right] = normalizeOptionalSectionFields(left, right, '## Current Position', ['Phase', 'Plan', 'Status', 'Last activity']);
  [left, right] = normalizeOptionalSectionFields(left, right, '## Session', ['**Last session:**', '**Stopped at:**', '**Resume file:**']);
  const a = normalizedHandoffSection(left); const b = normalizedHandoffSection(right);
  if (a.normalized !== b.normalized) fail('STATE.md changed outside its command and active handoff paragraph');
  if (!b.commandText.includes('176') && !b.commandText.includes('177')) fail('STATE.md command does not name the active Phase 176/177 handoff');
  for (const sentence of a.activeParagraph.match(/[^.!?]+[.!?]?/g) ?? []) {
    const clean = sentence.trim();
    if (clean && !/(?:Phase 176|phase 176|176-0[12]|Plan 0[12]|GSD)/.test(clean) && !b.activeParagraph.includes(clean)) fail('active handoff paragraph rewrote a captured non-Phase-176 clause');
  }
  return true;
}
export function validateRoadmapBodyDelta(before, after) {
  let left = before, right = after;
  [left, right] = normalizeRoadmapLines(left, right);
  const a = normalizedHandoffSection(left); const b = normalizedHandoffSection(right);
  if (a.normalized !== b.normalized) fail('ROADMAP.md changed outside its command and active handoff paragraph');
  if (!b.commandText.includes('176') && !b.commandText.includes('177')) fail('ROADMAP.md command does not name the active Phase 176/177 handoff');
  return true;
}
function normalizeOptionalSectionFields(a, b, heading, labels) {
  const normalize = (text) => {
    const escaped = heading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const re = new RegExp(`^${escaped}[ \\t]*\\r?\\n`, 'm');
    const m = re.exec(text); if (!m) return text;
    const bodyStart = m.index + m[0].length; const tail = text.slice(bodyStart); const next = /^##[ \t]+[^\n]*$/m.exec(tail); const bodyEnd = bodyStart + (next ? next.index : tail.length);
    let count = 0; const body = text.slice(bodyStart, bodyEnd).replace(/^([^\n]*?)(\r?\n)?$/gm, (line, whole, ending = '') => {
      for (const label of labels) {
        const pattern = label.startsWith('**') ? new RegExp(`^${label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*.*$`) : new RegExp(`^${label}:\\s*.*$`);
        if (pattern.test(whole)) { count++; return `<MUTABLE:${label}>${ending}`; }
      }
      return line;
    });
    if (count !== labels.length) fail(`mutable fields missing or duplicated in ${heading}`);
    return text.slice(0, m.index) + m[0] + body + text.slice(bodyEnd);
  };
  return [normalize(a), normalize(b)];
}
function normalizeRoadmapLines(a, b) {
  const normalize = (text) => {
    let lines = text.split(/(?<=\n)/); const found = { status: 0, checklist: 0, p176: 0, p177: 0 };
    let inV24 = false, inProgress = false;
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (/^## v24\.0 Repository Cleanup & Maintenance\s*$/.test(line.trimEnd())) { inV24 = true; inProgress = false; continue; }
      if (/^## /.test(line)) {
        inProgress = /^## Progress/.test(line);
        if (/^## v(?!24\.)/.test(line) || /^## Phase 17[7-9]/.test(line)) inV24 = false;
      }
      if (inV24 && /^\*\*Status:\*/.test(line)) { found.status++; lines[i] = '<MUTABLE:V24_STATUS>\n'; }
      if (inV24 && /^- \[[ xX]\] \*\*Phase 176:/.test(line)) { found.checklist++; lines[i] = line.replace(/^- \[[ xX]\]/, '- [MUTABLE]'); }
      if (inProgress && /^\|\s*176\./.test(line)) {
        found.p176++; const cells = line.split('|'); if (cells.length < 6) fail('Phase 176 progress row is malformed');
        cells[2] = '<MUTABLE_PLANS>'; cells[3] = '<MUTABLE_STATUS>'; cells[4] = '<MUTABLE_COMPLETED>'; lines[i] = cells.join('|');
      }
      if (inProgress && /^\|\s*177\./.test(line)) {
        found.p177++; const cells = line.split('|'); if (cells.length < 6) fail('Phase 177 progress row is malformed');
        cells[3] = '<MUTABLE_STATUS>'; lines[i] = cells.join('|');
      }
    }
    for (const [key, count] of Object.entries(found)) if (count > 1) fail(`duplicate ROADMAP mutable anchor: ${key}`);
    return lines.join('');
  };
  return [normalize(a), normalize(b)];
}
function normalizeFrontmatterPair(before, after, allowedKeys, label) {
  const normalize = (text) => {
    const m = /^(---\r?\n)([\s\S]*?)(\r?\n---)([\s\S]*)$/.exec(text);
    if (!m) fail(`${label} frontmatter is missing`);
    const lines = m[2].split(/(?<=\n)/); const counts = new Map(allowedKeys.map((k) => [k, 0]));
    const normalized = lines.map((line) => {
      const match = /^(\s*)([A-Za-z0-9_.-]+):(.*?)(\r?\n)?$/.exec(line);
      if (!match || !counts.has(match[2])) return line;
      counts.set(match[2], counts.get(match[2]) + 1); return `${match[1]}${match[2]}:<MUTABLE>${match[4] ?? ''}`;
    });
    for (const [key, n] of counts) if (n > 1) fail(`${label} mutable key duplicated: ${key}`);
    return `${m[1]}${normalized.join('')}${m[3]}`;
  };
  return [normalize(before), normalize(after)];
}
export function validateStateDocumentDelta(before, after) {
  const keys = ['current_phase', 'current_phase_name', 'status', 'stopped_at', 'last_updated', 'last_activity', 'last_activity_desc', 'completed_phases', 'completed_plans', 'percent', 'last_completed_phase', 'current_plan'];
  const [a, b] = normalizeFrontmatterPair(before, after, keys, 'STATE.md');
  if (a !== b) fail('STATE.md frontmatter changed outside named Phase 176/177 keys');
  validateStateBodyDelta(before.replace(/^---[\s\S]*?---\r?\n/, ''), after.replace(/^---[\s\S]*?---\r?\n/, ''));
  return true;
}
export function validateRoadmapDocumentDelta(before, after) {
  const [a, b] = normalizeRoadmapLines(before, after);
  const [ha, hb] = [normalizedHandoffSection(a), normalizedHandoffSection(b)];
  if (ha.normalized !== hb.normalized) fail('ROADMAP.md changed outside named Phase 176/177 rows and active handoff');
  if (ha.commandText === hb.commandText && a !== b) fail('ROADMAP.md mutable span did not contain the Phase 176/177 handoff');
  return true;
}
export function validateRequirementsDelta(before, after) {
  const normalize = (text) => {
    for (const id of ['MAINT-01', 'MAINT-02', 'MAINT-04']) {
      const re = new RegExp(`^(- \\[)[ xX](\\] \\*\\*${id}:.*)$`, 'gm'); let count = 0;
      text = text.replace(re, (_, a, b) => { count++; return `${a}<MUTABLE>${b}`; });
      if (count !== 1) fail(`REQUIREMENTS.md ${id} trace anchor missing or duplicated`);
      const table = new RegExp(`^(\\| ${id} \\| Phase 176 \\| )[^|\\r\\n]+(\\|)$`, 'gm');
      let rows = 0;
      text = text.replace(table, (_, a, b) => { rows++; return `${a}<MUTABLE>${b}`; });
      if (rows !== 1) fail(`REQUIREMENTS.md ${id} table anchor missing or duplicated`);
    }
    return text;
  };
  if (normalize(before) !== normalize(after)) fail('REQUIREMENTS.md changed outside Phase 176 requirement status');
  return true;
}
export function validateValidationDelta(before, after) {
  const allowed = ['status', 'nyquist_compliant', 'wave_0_complete']; const [a, b] = normalizeFrontmatterPair(before, after, allowed, '176-VALIDATION.md');
  if (a !== b) fail('176-VALIDATION.md changed outside named validation keys');
  const body = (text) => text.replace(/^---[\s\S]*?---\r?\n/, '');
  const taskIds = ['176-01 Task 1', '176-01 Task 2', '176-01 Task 3', '176-02 Task 1', '176-02 Task 2', '176-02 Task 3', 'Post-GSD orchestration gate'];
  const normalizeTasks = (text) => {
    const lines = text.split(/(?<=\n)/); const found = new Map(taskIds.map((id) => [id, 0]));
    for (let i = 0; i < lines.length; i++) {
      if (!/^\|\s*(?:176-0[12] Task [123]|Post-GSD orchestration gate)\b/.test(lines[i])) continue;
      const id = taskIds.find((key) => lines[i].includes(key)); if (!id) continue;
      const cells = lines[i].split('|'); if (cells.length !== 10) fail('validation task-map row shape changed');
      found.set(id, found.get(id) + 1); cells[7] = '<MUTABLE_FILE_EXISTS>'; cells[8] = '<MUTABLE_STATUS>'; lines[i] = cells.join('|');
    }
    if ([...found.values()].some((n) => n !== 1)) fail('validation task-map row is missing or duplicated');
    return lines.join('');
  };
  const normalizeSignoff = (text) => {
    const start = text.indexOf('## Validation Sign-Off'); if (start < 0) fail('validation sign-off section is missing');
    const prefix = text.slice(0, start); let tail = text.slice(start); const auditAt = tail.search(/^## (?:GSD Validation Audits|Validation Audit \d{4}-\d{2}-\d{2})/m);
    let signoff = auditAt < 0 ? tail : tail.slice(0, auditAt); const audit = auditAt < 0 ? '' : tail.slice(auditAt);
    let approvalCount = 0;
    signoff = signoff.replace(/^(- \[)[ xX](\] .*)$/gm, '$1<MUTABLE>$2').replace(/^(\*\*Approval:\*\*)[^\n]*(\r?\n?)$/gm, (_, label, ending) => { approvalCount++; return `${label}<MUTABLE>${ending}`; });
    if (approvalCount !== 1) fail('validation approval value is missing or duplicated');
    if (audit) {
      const installed = /^(?:## Validation Audit \d{4}-\d{2}-\d{2}\r?\n\r?\n\| Metric \| Count \|\r?\n\|---\|---\|\r?\n\| Gaps found \| \d+ \|\r?\n\| Resolved \| \d+ \|\r?\n\| Escalated \| \d+ \|\r?\n\s*)+$/.test(audit);
      const legacy = /^## GSD Validation Audits\r?\n\r?\n- Gaps found: \d+\r?\n- Gaps resolved: \d+\r?\n- Gaps escalated: \d+\r?\n\s*$/.test(audit);
      if (!installed && !legacy) fail('GSD Validation Audits must record exact numeric gaps found, resolved, and escalated');
    }
    const beforeAt = before.search(/^## (?:GSD Validation Audits|Validation Audit \d{4}-\d{2}-\d{2})/m);
    const beforeAudit = beforeAt < 0 ? '' : before.slice(beforeAt);
    if (beforeAudit && !audit.startsWith(beforeAudit)) fail('GSD Validation Audits history is append-only');
    return { base: `${normalizeTasks(prefix)}${signoff.trimEnd()}`, audit };
  };
  const normalizedBefore = normalizeSignoff(body(before)); const normalizedAfter = normalizeSignoff(body(after));
  if (normalizedBefore.base !== normalizedAfter.base) fail('176-VALIDATION.md changed outside seven task-map tail cells, sign-off checkboxes/approval, or append-only numeric GSD audit');
  return true;
}
export function validateStateJsonDelta(before, after) {
  const exact = (o, keys) => o && JSON.stringify(Object.keys(o)) === JSON.stringify(keys);
  const top = ['contract', 'flavor', 'milestone', 'phases', 'next', 'updated_at'];
  if (!exact(before, top) || !exact(after, top) || !exact(before.next, ['command', 'label', 'reason']) || !exact(after.next, ['command', 'label', 'reason'])) fail('state.json key shape/order differs from installed publisher contract');
  if (before.contract !== after.contract || before.flavor !== after.flavor || before.milestone !== after.milestone || before.phases.length !== 3 || after.phases.length !== 3) fail('state.json identity changed');
  if (!/^\d{4}-\d\d-\d\dT/.test(after.updated_at) || !Number.isFinite(Date.parse(after.updated_at))) fail('state.json updated_at is not ISO date-time');
  for (let i = 0; i < 3; i++) {
    const a = before.phases[i], b = after.phases[i];
    if (!exact(a, ['number', 'name', 'status']) || !exact(b, ['number', 'name', 'status']) || a.number !== b.number || a.name !== b.name) fail('state.json phase identity/order changed');
    if (i === 2 && JSON.stringify(a) !== JSON.stringify(b)) fail('Phase 178 projection changed');
    if (i === 0 && !['pending', 'in_progress', 'complete'].includes(b.status)) fail('Phase 176 status is invalid');
    if (i === 1 && !['pending', 'in_progress'].includes(b.status)) fail('Phase 177 status is invalid');
  }
  for (const key of ['command', 'label', 'reason']) if (typeof after.next[key] !== 'string') fail('state.json next action is malformed');
  return true;
}
export function render(pub) {
  const rows = pub.rows ?? []; const unreadable = rows.filter((r) => (r.recovery?.limitations ?? []).length > 0 || /unreadable|unsupported/.test(r.reason ?? '')).length;
  const semantic = rows.filter((r) => r.disposition === 'retain' && (r.comparison?.candidates ?? []).some((c) => c.semanticEquivalenceReviewed === false)).length;
  const otherUnknown = rows.filter((r) => r.disposition === 'retain' && !((r.recovery?.limitations ?? []).length > 0) && !(r.comparison?.candidates ?? []).some((c) => c.semanticEquivalenceReviewed === false)).length;
  const lines = [`# Local Work Inventory (${pub.capturedAt?.slice(0, 10) ?? 'undated'})`, '', `Coverage: ${rows.length} captured path rows.`, `Findings: ${rows.filter((r) => r.disposition !== 'retain').length} have a proposed bounded disposition.`, `Unknowns: ${rows.filter((r) => r.disposition === 'retain').length} retained (${semantic} need semantic review, ${unreadable} are unreadable or unsupported, ${otherUnknown} have another unresolved cause).`, `Source changed or removed: no.`, `Next action: follow the Phase 177 owner/action table below.`, `Machine-readable evidence: [176-INVENTORY.json](176-INVENTORY.json).`, '', '## Dispositions', ''];
  for (const row of rows) {
    const recovery = row.recovery ? ` Recovery: ${row.recovery.restoredFromFrozenCapture ? 'restored from frozen capture' : 'retained as an explicit limitation'}${row.recovery.limitations?.length ? ` (${row.recovery.limitations.map(escapeMarkdown).join('; ')})` : ''}.` : ' Recovery: not yet established.';
    const equality = row.comparison ? ` Equality: HEAD→index ${escapeMarkdown(row.comparison.capturedHeadToIndex ?? 'not compared')}; index→worktree ${escapeMarkdown(row.comparison.capturedIndexToWorktree ?? 'not compared')}.` : ' Equality: not compared.';
    const candidates = row.comparison?.candidates ?? [];
    const sourceMatch = ` Published comparisons: ${candidates.filter((c) => c.indexEqual && c.worktreeEqual).length}/${candidates.length} exact index-and-worktree matches; semantic equivalence ${candidates.some((c) => c.semanticEquivalenceReviewed === false) ? 'unreviewed' : 'not established'}.`;
    const facts = row.policyFacts;
    const policy = facts ? ` Policy: ${escapeMarkdown(facts.intentionallyTrackedCategory ?? facts.ignoredPolicyCategory ?? facts.forbiddenToTrackCategory ?? 'no match')}; Git ignored ${facts.ignoredByGit ? 'yes' : 'no'}; disposable ${facts.disposable ? 'yes' : 'not proven'}.` : ' Policy: not yet classified.';
    lines.push(`- ${row.path ? `\`${escapeMarkdown(row.path)}\`` : `Opaque row ${row.rowId}`}: **${row.disposition}** — ${escapeMarkdown(row.reason)}${equality}${sourceMatch}${recovery}${policy} Next owner: ${escapeMarkdown(row.nextOwner)}.`);
  }
  const contracts = pub.generatedContracts ?? rows.flatMap((r) => r.policyFacts?.generatedContractOwners ?? []);
  if (contracts.length) {
    lines.push('', '## Generated Contract Ownership', '');
    for (const item of contracts) {
      const commands = (item.regenerationArgv ?? []).map((argv) => `\`${argv.map(escapeMarkdown).join(' ')}\``).join(', ');
      lines.push(`- Canonical source: \`${escapeMarkdown(item.canonicalSource)}\`; regeneration: ${commands || 'not declared'}; outputs: ${(item.outputs ?? []).map((p) => `\`${escapeMarkdown(p)}\``).join(', ')}.`);
      if (item.semanticSources) lines.push(`  Semantic sources: ${item.semanticSources.map((p) => `\`${escapeMarkdown(p)}\``).join(', ')}; drift check: ${escapeMarkdown(item.driftCheckOwner ?? 'not established')}.`);
    }
  }
  if (pub.artifactPolicySummary) {
    lines.push('', '## Artifact Policy', '', `Ignored, tracked, forbidden, obsolete and disposable status are recorded independently. ${escapeMarkdown(pub.artifactPolicySummary)}`);
  }
  lines.push('', '## Phase 177 Owner and Action Table', '', '| Unit | Disposition | Next action | Owner |', '|---|---|---|---|');
  for (const row of rows) lines.push(`| ${row.path ? `\`${escapeMarkdown(row.path)}\`` : `Opaque row ${row.rowId}`} | ${escapeMarkdown(row.disposition)} | ${escapeMarkdown(row.nextAction ?? row.nextOwner)} | ${escapeMarkdown(row.nextOwner)} |`);
  return lines.join('\n') + '\n';
}
function escapeMarkdown(s) { return String(s).replace(/[\r\n]+/g, ' ').replace(/[\\`*_{}\[\]()#+.!|>]/g, '\\$&').replace(/</g, '&lt;'); }
function parseArgs(argv) {
  const [command, ...tail] = argv; const opts = { command };
  for (let i = 0; i < tail.length; i++) { if (tail[i] === '--final') { opts.final = true; continue; } if (tail[i].startsWith('--')) { const k = tail[i].slice(2).replace(/-([a-z])/g, (_, c) => c.toUpperCase()); opts[k] = tail[++i]; } }
  return opts;
}
function cli() {
  const a = parseArgs(process.argv.slice(2)); let out;
  if (a.command === 'capture') { out = capture({ repo: a.repo, archiveRoot: a.archiveRoot, allowTemporary: a.fixtureTemp === 'true' }); if (a.public) writePhaseArtifact(a.repo, a.public, '176-INVENTORY.json', JSON.stringify(out, null, 2) + '\n'); }
  else if (a.command === 'verify') { const pubPath = phaseArtifactPath(a.repo, a.public, '176-INVENTORY.json'); out = verify({ repo: a.repo, archiveRoot: a.archiveRoot, captureId: a.captureId ?? JSON.parse(fs.readFileSync(pubPath, 'utf8')).captureId, publicPath: pubPath, allowTemporary: a.fixtureTemp === 'true' }); }
  else if (a.command === 'audit') { const pubPath = phaseArtifactPath(a.repo, a.public, '176-INVENTORY.json'); const mdPath = a.rendered ? phaseArtifactPath(a.repo, a.rendered, '176-INVENTORY.md') : undefined; out = audit({ repo: a.repo, archiveRoot: a.archiveRoot, captureId: a.captureId ?? JSON.parse(fs.readFileSync(pubPath, 'utf8')).captureId, publicPath: pubPath, renderedPath: mdPath, final: a.final, allowTemporary: a.fixtureTemp === 'true' }); }
  else if (a.command === 'render') { const pubPath = phaseArtifactPath(a.repo, a.public, '176-INVENTORY.json'); const pub = JSON.parse(fs.readFileSync(pubPath, 'utf8')); out = render(pub); if (a.output) writePhaseArtifact(a.repo, a.output, '176-INVENTORY.md', out); else process.stdout.write(out); return; }
  else fail('usage: 176-evidence.mjs capture|verify|audit|render --repo PATH --archive-root PATH [--capture-id ID] [--public PATH]');
  process.stdout.write(JSON.stringify(out, null, 2) + '\n');
}
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { cli(); } catch (e) { process.stderr.write(`176 evidence: ${e.message}\n`); process.exitCode = 1; }
}
