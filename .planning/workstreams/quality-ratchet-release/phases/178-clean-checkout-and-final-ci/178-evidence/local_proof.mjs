import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const PHASE = 178;
const PLAN = '02';
const POINTER = '/private/tmp/crosswake-178-owner-env';
const EVIDENCE_DIR = path.dirname(fileURLToPath(import.meta.url));
const WORKSPACE_ROOT = path.resolve(EVIDENCE_DIR, '../../../../../..');
const ORDER = Object.freeze([
  'repository-preflight', 'root-proof', 'example-host-proof', 'browser-proof',
  'ios-package-proof', 'android-package-proof', 'format-proof', 'warnings-proof',
  'repository-cleanliness'
]);
const ALLOWED_RECORD_KEYS = new Set(['schemaVersion', 'testFixture', 'source', 'sourceAfter', 'run', 'supplemental', 'secretSentinels']);
const SAFE_CAUSES = new Set([
  'invalid-private-record', 'candidate-mismatch', 'invocation-failed', 'invocation-nonzero', 'facade-status-mismatch', 'output-missing',
  'output-not-complete', 'stage-log-missing', 'stage-log-failed', 'stage-log-permissions',
  'snapshot-missing', 'source-drift', 'raw-index-drift', 'dirty-source', 'ignored-output-unapproved',
  'private-permissions', 'secret-leakage', 'write-failed'
]);

function fail(cause) {
  const error = new Error(SAFE_CAUSES.has(cause) ? cause : 'invocation-failed');
  error.safeCause = SAFE_CAUSES.has(cause) ? cause : 'invocation-failed';
  throw error;
}

function sha(bytes) { return crypto.createHash('sha256').update(bytes).digest('hex'); }
function privateFile(file) {
  let st;
  try { st = fs.lstatSync(file); } catch { fail('snapshot-missing'); }
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o077) !== 0) fail('private-permissions');
  return fs.readFileSync(file);
}
function privateDirectory(dir) {
  let st;
  try { st = fs.lstatSync(dir); } catch { fail('snapshot-missing'); }
  if (!st.isDirectory() || st.isSymbolicLink() || (st.mode & 0o077) !== 0) fail('private-permissions');
}
function writePrivate(file, bytes) {
  fs.mkdirSync(path.dirname(file), { recursive: true, mode: 0o700 });
  const fd = fs.openSync(file, 'w', 0o600);
  try { fs.writeFileSync(fd, bytes); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  fs.chmodSync(file, 0o600);
}
function readJson(file) {
  try { return JSON.parse(privateFile(file).toString('utf8')); } catch (error) {
    if (error.safeCause) throw error;
    fail('invalid-private-record');
  }
}
function isWithin(root, candidate) {
  const relative = path.relative(root, candidate);
  return relative === '' || (!relative.startsWith(`..${path.sep}`) && relative !== '..' && !path.isAbsolute(relative));
}
function ownerRoot(pointerPath = POINTER, recoveryRoot = WORKSPACE_ROOT) {
  const pointer = privateFile(pointerPath).toString('utf8').trim();
  if (!pointer || !path.isAbsolute(pointer) || pointer.includes('\n') || pointer.includes('\r')) fail('invalid-private-record');
  let canonical, tempRoot;
  try {
    canonical = fs.realpathSync(pointer);
    tempRoot = fs.realpathSync(os.tmpdir());
  } catch { fail('invalid-private-record'); }
  const allowed = [path.resolve('/private/tmp'), tempRoot].some(root => isWithin(root, canonical));
  const recovery = fs.realpathSync(recoveryRoot);
  if (!allowed || canonical === recovery || isWithin(canonical, recovery) || isWithin(recovery, canonical)) fail('candidate-mismatch');
  privateDirectory(canonical);
  return canonical;
}
function candidateBinding({ pointerPath = POINTER, recoveryRoot = WORKSPACE_ROOT, gitReader = runGit } = {}) {
  const root = ownerRoot(pointerPath, recoveryRoot);
  const names = ['candidate-binding-renewed.json', 'candidate-binding.json'];
  const existing = names.filter(name => fs.existsSync(path.join(root, name)));
  if (existing.length !== 1) fail('candidate-mismatch');
  const binding = readJson(path.join(root, existing[0]));
  const hex40 = /^[0-9a-f]{40}$/;
  if (![1, 2].includes(binding.schemaVersion) || binding.phase !== 178 || binding.plan !== '01' ||
      !hex40.test(binding.candidateCommit) || !hex40.test(binding.candidateTree) ||
      !Array.isArray(binding.selectedPaths) || binding.selectedPaths.length !== 8 ||
      typeof binding.proofRoot !== 'string' || typeof binding.deliveryRoot !== 'string') fail('candidate-mismatch');
  let publicSource;
  try { publicSource = JSON.parse(fs.readFileSync(path.join(EVIDENCE_DIR, 'candidate-source.json'), 'utf8')); } catch { fail('candidate-mismatch'); }
  if (publicSource.status !== 'source-qualified' || publicSource.candidateCommit !== binding.candidateCommit ||
      publicSource.candidateTree !== binding.candidateTree || publicSource.selectedCount !== binding.selectedPaths.length ||
      JSON.stringify([...publicSource.selectedPaths].sort()) !== JSON.stringify([...binding.selectedPaths].sort())) fail('candidate-mismatch');
  let proofRoot, deliveryRoot, tempRoot;
  try {
    proofRoot = fs.realpathSync(binding.proofRoot);
    deliveryRoot = fs.realpathSync(binding.deliveryRoot);
    tempRoot = fs.realpathSync(os.tmpdir());
  } catch { fail('candidate-mismatch'); }
  const privateRoots = [path.resolve('/private/tmp'), tempRoot];
  if ([proofRoot, deliveryRoot].some(rootPath => !privateRoots.some(privateRoot => isWithin(privateRoot, rootPath)))) fail('candidate-mismatch');
  const recovery = fs.realpathSync(recoveryRoot);
  if ([proofRoot, deliveryRoot].some(rootPath => rootPath === recovery || isWithin(rootPath, recovery) || isWithin(recovery, rootPath))) fail('candidate-mismatch');
  for (const [repo, expectedHead, expectedTree] of [[proofRoot, binding.candidateCommit, binding.candidateTree], [deliveryRoot, binding.candidateCommit, binding.candidateTree]]) {
    const stat = fs.lstatSync(repo);
    if (!stat.isDirectory() || stat.isSymbolicLink() || gitReader(repo, ['rev-parse', '--show-toplevel']).toString('utf8').trim() !== repo ||
        gitReader(repo, ['rev-parse', 'HEAD']).toString('utf8').trim() !== expectedHead ||
        gitReader(repo, ['rev-parse', 'HEAD^{tree}']).toString('utf8').trim() !== expectedTree) fail('candidate-mismatch');
  }
  return { ...binding, ownerPrivateRoot: root, proofRoot, deliveryRoot };
}
function finalSourceBinding(file) {
  if (!file) fail('candidate-mismatch');
  const binding = readJson(file);
  const candidate = candidateBinding();
  const hex40 = /^[0-9a-f]{40}$/;
  if (binding.schemaVersion !== 1 || binding.phase !== 178 || binding.plan !== '05' ||
      binding.candidateCommit !== candidate.candidateCommit || binding.candidateTree !== candidate.candidateTree ||
      !hex40.test(binding.finalCommit) || !hex40.test(binding.finalTree) ||
      typeof binding.proofRoot !== 'string') fail('candidate-mismatch');
  let finalRoot;
  try { finalRoot = fs.realpathSync(binding.proofRoot); } catch { fail('candidate-mismatch'); }
  const tempRoot = fs.realpathSync(os.tmpdir());
  const recovery = fs.realpathSync(WORKSPACE_ROOT);
  if (finalRoot === candidate.proofRoot ||
      ![path.resolve('/private/tmp'), tempRoot].some(root => isWithin(root, finalRoot)) ||
      finalRoot === recovery || isWithin(finalRoot, recovery) || isWithin(recovery, finalRoot) ||
      fs.realpathSync(runGit(finalRoot, ['rev-parse', '--show-toplevel']).toString('utf8').trim()) !== finalRoot ||
      runGit(finalRoot, ['rev-parse', 'HEAD']).toString('utf8').trim() !== binding.finalCommit ||
      runGit(finalRoot, ['rev-parse', 'HEAD^{tree}']).toString('utf8').trim() !== binding.finalTree) fail('candidate-mismatch');
  return { ...binding, proofRoot: finalRoot, candidateBase: true };
}
function runGit(root, args) {
  const result = spawnSync('git', ['-C', root, ...args], {
    env: supplementalGitEnv(), encoding: null, timeout: 120000,
    maxBuffer: 128 * 1024 * 1024
  });
  if (result.error || result.signal || result.status !== 0) fail('snapshot-missing');
  return Buffer.from(result.stdout ?? []);
}
function supplementalGitEnv(base = process.env) { return { ...base, GIT_OPTIONAL_LOCKS: '0' }; }
function status(root) { return runGit(root, ['status', '--porcelain=v1', '-z', '--untracked-files=all']); }
function ignored(root) { return runGit(root, ['ls-files', '--others', '--ignored', '--exclude-standard', '-z']); }
function indexIdentity(root) {
  const indexPath = runGit(root, ['rev-parse', '--path-format=absolute', '--git-path', 'index']).toString('utf8').trim();
  let raw;
  try { raw = fs.readFileSync(indexPath); } catch { fail('snapshot-missing'); }
  const entries = runGit(root, ['ls-files', '--stage', '-z']);
  return { indexSha256: sha(raw), indexEntriesSha256: sha(entries), indexBytes: raw };
}
function pathsFromNul(bytes) {
  if (bytes.length && bytes[bytes.length - 1] !== 0) fail('snapshot-missing');
  return bytes.toString('utf8').split('\0').filter(Boolean);
}
function snapshot(root, destination, captureRoot) {
  const canonicalRoot = fs.realpathSync(root);
  const canonicalCapture = fs.realpathSync(captureRoot);
  if (canonicalRoot === canonicalCapture || canonicalRoot.startsWith(`${canonicalCapture}${path.sep}`) || canonicalCapture.startsWith(`${canonicalRoot}${path.sep}`)) fail('invalid-private-record');
  const head = runGit(canonicalRoot, ['rev-parse', 'HEAD']).toString('utf8').trim();
  const tree = runGit(canonicalRoot, ['rev-parse', 'HEAD^{tree}']).toString('utf8').trim();
  const { indexSha256, indexEntriesSha256, indexBytes } = indexIdentity(canonicalRoot);
  const statusPath = path.join(captureRoot, `supplemental-${destination}.z`);
  const ignoredPath = path.join(captureRoot, `ignored-${destination}.z`);
  writePrivate(statusPath, status(canonicalRoot));
  writePrivate(ignoredPath, ignored(canonicalRoot));
  const rawIndexPath = path.join(captureRoot, `supplemental-${destination}.index`);
  writePrivate(rawIndexPath, indexBytes);
  const metaPath = path.join(captureRoot, `supplemental-${destination}.json`);
  writePrivate(metaPath, `${JSON.stringify({ head, tree, indexSha256, indexEntriesSha256, statusPath, ignoredPath, rawIndexPath })}\n`);
  return { metaPath, head, tree, indexSha256, indexEntriesSha256 };
}
function within(root, candidate) {
  const relative = path.relative(root, candidate);
  return relative !== '' && !relative.startsWith(`..${path.sep}`) && relative !== '..' && !path.isAbsolute(relative);
}
function matchIgnored(matcher, rel) {
  if (matcher.kind === 'exact') return rel === matcher.value;
  if (matcher.kind === 'suffix') return rel.endsWith(matcher.value);
  if (matcher.kind === 'segment') return rel.split('/').includes(matcher.value);
  if (matcher.kind === 'tree') return rel === matcher.value || rel.startsWith(`${matcher.value}/`);
  return false;
}
function ignoredPolicyRecord(policy, rel) {
  return policy.ignored_transient.find(record => record.matchers.some(matcher => matchIgnored(matcher, rel)));
}
function isOwnedOutput(rel, outputs) {
  return outputs.some(output => rel === output || rel.startsWith(`${output}/`));
}
function validateLocalToolingEntry(repoRoot, rel) {
  if (path.isAbsolute(rel) || rel.split('/').some(part => !part || part === '.' || part === '..')) fail('ignored-output-unapproved');
  const root = fs.realpathSync(repoRoot);
  const segments = rel.split('/');
  let current = root;
  for (const [index, segment] of segments.entries()) {
    current = path.join(current, segment);
    let stat;
    try { stat = fs.lstatSync(current); } catch { fail('ignored-output-unapproved'); }
    if (stat.isSymbolicLink() || stat.uid !== process.getuid?.()) fail('ignored-output-unapproved');
    if (index < segments.length - 1 && !stat.isDirectory()) fail('ignored-output-unapproved');
    if (index === segments.length - 1 && !stat.isFile()) fail('ignored-output-unapproved');
  }
  const real = fs.realpathSync(current);
  if (!within(root, real)) fail('ignored-output-unapproved');
}
function validateIgnored(repoRoot, beforeBytes, afterBytes, policy, manifest) {
  const before = pathsFromNul(beforeBytes).sort();
  const after = pathsFromNul(afterBytes).sort();
  const beforeSet = new Set(before);
  const owned = manifest.stages.flatMap(stage => stage.owned_outputs);
  for (const rel of before) {
    if (!ignoredPolicyRecord(policy, rel)) fail('ignored-output-unapproved');
  }
  for (const rel of after) {
    const policyRecord = ignoredPolicyRecord(policy, rel);
    if (!policyRecord) fail('ignored-output-unapproved');
    if (!beforeSet.has(rel) && !isOwnedOutput(rel, owned)) {
      if (policyRecord.category !== 'ignored_local_tooling') fail('ignored-output-unapproved');
      validateLocalToolingEntry(repoRoot, rel);
    }
  }
  return { beforeCount: before.length, afterCount: after.length, newCount: after.filter(rel => !beforeSet.has(rel)).length };
}
function validateMode(file, expected = 0o600) {
  const st = fs.lstatSync(file);
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o777) !== expected) fail('private-permissions');
}
function readSupplemental(metaFile, captureRoot) {
  const meta = readJson(metaFile);
  for (const key of ['head', 'tree', 'indexSha256', 'indexEntriesSha256']) if (typeof meta[key] !== 'string') fail('snapshot-missing');
  const statusFile = meta.statusPath ?? meta.statusFile;
  const ignoredFile = meta.ignoredPath;
  const rawIndexFile = meta.rawIndexPath;
  if (typeof statusFile !== 'string' || typeof ignoredFile !== 'string' || typeof rawIndexFile !== 'string') fail('snapshot-missing');
  const canonicalCapture = fs.realpathSync(captureRoot);
  for (const file of [metaFile, statusFile, ignoredFile, rawIndexFile]) {
    const real = fs.realpathSync(file);
    if (!within(canonicalCapture, real)) fail('invalid-private-record');
  }
  const statusBytes = privateFile(statusFile);
  const ignoredBytes = privateFile(ignoredFile);
  const rawIndexBytes = privateFile(rawIndexFile);
  if (sha(rawIndexBytes) !== meta.indexSha256) fail('raw-index-drift');
  return { head: meta.head, tree: meta.tree, indexSha256: meta.indexSha256, indexEntriesSha256: meta.indexEntriesSha256, rawIndexBytes, status: statusBytes, ignored: ignoredBytes };
}
function defaultProofOutput(kind) {
  return path.join(EVIDENCE_DIR, kind === 'final' ? 'final-local-proof.json' : 'preliminary-local-proof.json');
}
function parseFacadeOutput(output) {
  if (/\b(?:FAIL|BLOCKED)\b/.test(output) || /self-test/i.test(output)) fail('output-not-complete');
  const lines = output.trimEnd().split(/\r?\n/);
  if (lines.length !== ORDER.length) fail('output-not-complete');
  const actual = [];
  for (const line of lines) {
    const match = /^PASS ([a-z][a-z0-9-]*)$/.exec(line);
    if (!match) fail('output-not-complete');
    actual.push(match[1]);
  }
  if (JSON.stringify(actual) !== JSON.stringify(ORDER)) fail('output-not-complete');
  return actual;
}
function stageCause(purpose, result, runRoot) {
  if (result === 'BLOCKED') return 'blocked-by-prerequisite';
  if (purpose === 'repository-preflight') return 'prerequisite-failed';
  if (purpose === 'repository-cleanliness') return 'cleanliness-failed';
  try {
    const log = privateFile(path.join(runRoot, 'logs', `${purpose}.log`)).toString('utf8');
    const first = log.split('\n', 1)[0];
    if (purpose === 'android-package-proof' && /SDK location not found|ANDROID_HOME environment variable|sdk\.dir path/i.test(log)) return 'android-sdk-unavailable';
    if (purpose === 'android-package-proof' && /different paths to the Android Preferences folder|ANDROID_SDK_HOME.{0,120}ANDROID_USER_HOME|AndroidLocationsBuildService\.AndroidDirectoryCreator/i.test(log)) return 'android-sdk-preferences-conflict';
    if (purpose === 'android-package-proof' && /metrics.{0,120}(?:EACCES|EPERM|Permission denied)|(?:EACCES|EPERM|Permission denied).{0,120}metrics/i.test(log)) return 'gradle-metrics-path-denied';
    if (purpose === 'root-proof' && /sha256sum(?::|\s).*(?:not found|command not found)/i.test(log)) return 'sha256sum-unavailable';
    if (purpose === 'browser-proof' && /SIGTRAP|signal=SIGTRAP/i.test(log)) return 'browser-launch-sigtrap';
    if (purpose === 'ios-package-proof' && /sandbox_apply.{0,120}(?:EPERM|Permission denied)|(?:EPERM|Permission denied).{0,120}sandbox_apply/i.test(log)) return 'swift-sandbox-denied';
    if (purpose === 'format-proof' && /release_boundaries_test\.exs/.test(log)) return 'approved-guide-needs-formatting';
    if (/^status=[1-9][0-9]*$/.test(first)) return 'child-exit-nonzero';
    if (/^error=[A-Z0-9_]+$/.test(first)) return 'child-start-failed';
    if (/^signal=[A-Z0-9]+$/.test(first)) return 'child-terminated';
  } catch { return 'stage-evidence-missing'; }
  return 'stage-failed';
}
function writeBlockedProjection(recordPath, outputPath, kind, finalBindingPath, error) {
  if (!['preliminary', 'final'].includes(kind)) return false;
  const record = readJson(recordPath);
  const initial = candidateBinding();
  const binding = kind === 'preliminary' ? initial : finalSourceBinding(finalBindingPath);
  const expectedCommit = kind === 'preliminary' ? initial.candidateCommit : binding.finalCommit;
  const expectedTree = kind === 'preliminary' ? initial.candidateTree : binding.finalTree;
  if (!record.run || !record.source || record.source.candidateCommit !== initial.candidateCommit || record.source.candidateTree !== initial.candidateTree ||
      record.source.commit !== expectedCommit || record.source.tree !== expectedTree) return false;
  const runId = String(record.run.id ?? '');
  if (!/^[A-Za-z0-9._-]{1,80}$/.test(runId)) return false;
  let outcomes = [];
  try {
    const raw = privateFile(record.run.stdoutPath).toString('utf8');
    outcomes = raw.split(/\r?\n/).flatMap(line => {
      const match = /^(FAIL|BLOCKED) ([a-z][a-z0-9-]*)(?:[;\s]|$)/.exec(line);
      if (!match || !ORDER.includes(match[2])) return [];
      return [{ purpose: match[2], result: match[1], cause: stageCause(match[2], match[1], record.run.runRoot) }];
    });
  } catch { /* The allowlisted generic cause below reports missing output. */ }
  const rawIndexDrift = record.sourceAfter.indexSha256 !== record.source.indexSha256;
  const sourceDrift = record.sourceAfter.commit !== record.source.commit || record.sourceAfter.tree !== record.source.tree ||
    rawIndexDrift || record.sourceAfter.indexEntriesSha256 !== record.source.indexEntriesSha256;
  let observedStages = [];
  try {
    observedStages = privateFile(record.run.stdoutPath).toString('utf8').split(/\r?\n/).flatMap(line => {
      const match = /^(PASS|FAIL|BLOCKED) ([a-z][a-z0-9-]*)(?:[;\s]|$)/.exec(line);
      return match && ORDER.includes(match[2]) ? [{ purpose: match[2], result: match[1] }] : [];
    });
  } catch { /* The projection stays safe if private stdout is unavailable. */ }
  const projection = {
    schemaVersion: 1, phase: PHASE, plan: PLAN, kind, status: 'blocked',
    command: 'script/verify_repository.sh --all',
    source: { commit: expectedCommit, tree: expectedTree }, runId,
    sourceIntegrity: sourceDrift ? 'changed' : 'unchanged',
    ...(observedStages.length ? { observedStages } : {}),
    blockedStages: outcomes,
    cause: rawIndexDrift ? 'raw-index-drift' : sourceDrift ? 'source-drift' : outcomes.length ? 'stage-evidence-failed' : (SAFE_CAUSES.has(error?.safeCause) ? error.safeCause : 'evidence-incomplete'),
    privateEvidence: 'owner-private-retained'
  };
  const absoluteOutput = path.resolve(outputPath || defaultProofOutput(kind));
  fs.mkdirSync(path.dirname(absoluteOutput), { recursive: true });
  const tmp = `${absoluteOutput}.tmp-${crypto.randomBytes(5).toString('hex')}`;
  fs.writeFileSync(tmp, `${JSON.stringify(projection, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(tmp, absoluteOutput); fs.chmodSync(absoluteOutput, 0o644);
  return true;
}
function collect(recordPath, outputPath, kind, finalBindingPath, options = {}) {
  if (!['preliminary', 'final'].includes(kind)) fail('invalid-private-record');
  const record = readJson(recordPath);
  if (Object.keys(record).some(key => !ALLOWED_RECORD_KEYS.has(key)) || record.schemaVersion !== 1 || !record.run || !record.source || !record.sourceAfter || !record.supplemental) fail('invalid-private-record');
  const preliminaryBinding = candidateBinding();
  const binding = kind === 'preliminary' ? preliminaryBinding : finalSourceBinding(finalBindingPath);
  let sourceRoot, boundRoot;
  try { sourceRoot = fs.realpathSync(record.run.sourceRoot); boundRoot = fs.realpathSync(binding.proofRoot); } catch { fail('candidate-mismatch'); }
  const expectedCommit = kind === 'preliminary' ? preliminaryBinding.candidateCommit : binding.finalCommit;
  const expectedTree = kind === 'preliminary' ? preliminaryBinding.candidateTree : binding.finalTree;
  const fixtureBinding = options.allowFixture === true && record.testFixture === true && /^fixture-run-/.test(String(record.run.id));
  if (sourceRoot !== boundRoot || record.source.candidateCommit !== preliminaryBinding.candidateCommit || record.source.candidateTree !== preliminaryBinding.candidateTree ||
      (!fixtureBinding && (record.source.commit !== expectedCommit || record.source.tree !== expectedTree))) fail('candidate-mismatch');
  let runRoot, captureRoot;
  try { runRoot = fs.realpathSync(record.run.runRoot); captureRoot = fs.realpathSync(record.run.captureRoot); } catch { fail('invalid-private-record'); }
  privateDirectory(runRoot); privateDirectory(path.join(runRoot, 'logs')); privateDirectory(captureRoot);
  if (path.dirname(runRoot) !== captureRoot || !path.basename(runRoot).startsWith('crosswake-repository-verify.')) fail('invalid-private-record');
  if (record.run.status !== 0) fail('invocation-nonzero');
  if (record.sourceAfter.commit !== record.source.commit || record.sourceAfter.tree !== record.source.tree ||
      record.sourceAfter.indexEntriesSha256 !== record.source.indexEntriesSha256) fail('source-drift');
  if (record.sourceAfter.indexSha256 !== record.source.indexSha256) fail('raw-index-drift');
  if (privateFile(record.run.facadeStatusPath).toString('utf8').trim() !== '0') fail('facade-status-mismatch');
  let stdoutPath;
  try { stdoutPath = fs.realpathSync(record.run.stdoutPath); } catch { fail('output-missing'); }
  if (!within(captureRoot, stdoutPath)) fail('invalid-private-record');
  validateMode(stdoutPath);
  let stderrPath;
  try { stderrPath = fs.realpathSync(record.run.stderrPath); } catch { fail('output-missing'); }
  if (!within(captureRoot, stderrPath)) fail('invalid-private-record');
  validateMode(stderrPath);
  const output = privateFile(stdoutPath).toString('utf8').trimEnd();
  const stderr = privateFile(stderrPath).toString('utf8');
  const stages = parseFacadeOutput(output);
  const sentinels = Array.isArray(record.secretSentinels) ? record.secretSentinels : [];
  if (sentinels.some(value => typeof value !== 'string' || value.length === 0)) fail('invalid-private-record');
  for (const text of [output, stderr, ...fs.readdirSync(path.join(runRoot, 'logs')).map(name => privateFile(path.join(runRoot, 'logs', name)).toString('utf8'))]) {
    if (sentinels.some(secret => text.includes(secret))) fail('secret-leakage');
  }
  const logNames = fs.readdirSync(path.join(runRoot, 'logs')).sort();
  const expectedLogs = ORDER.slice(1).map(stage => `${stage}.log`).sort();
  if (JSON.stringify(logNames) !== JSON.stringify(expectedLogs)) fail('stage-log-missing');
  for (const name of logNames) {
    const file = path.join(runRoot, 'logs', name);
    validateMode(file);
    const log = privateFile(file).toString('utf8');
    if (!/^status=0\n/.test(log)) fail('stage-log-failed');
    if (sentinels.some(secret => log.includes(secret))) fail('secret-leakage');
  }
  const beforeStatus = privateFile(path.join(runRoot, 'git-before.z'));
  const afterStatus = privateFile(path.join(runRoot, 'git-final.z'));
  if (beforeStatus.length !== 0 || afterStatus.length !== 0) fail('dirty-source');
  const supplementalBefore = readSupplemental(record.supplemental.beforePath, captureRoot);
  const supplementalAfter = readSupplemental(record.supplemental.afterPath, captureRoot);
  const source = record.source;
  for (const item of [supplementalBefore, supplementalAfter]) {
    if (item.head !== source.commit || item.tree !== source.tree || item.indexEntriesSha256 !== source.indexEntriesSha256) fail('source-drift');
    if (item.indexSha256 !== source.indexSha256) fail('raw-index-drift');
    if (item.status.length !== 0) fail('dirty-source');
  }
  let repoRoot;
  try { repoRoot = fs.realpathSync(record.run.repoRoot); } catch { fail('invalid-private-record'); }
  const current = {
    head: runGit(repoRoot, ['rev-parse', 'HEAD']).toString('utf8').trim(),
    tree: runGit(repoRoot, ['rev-parse', 'HEAD^{tree}']).toString('utf8').trim(),
    ...indexIdentity(repoRoot),
    status: status(repoRoot),
    ignored: ignored(repoRoot)
  };
  if (current.head !== supplementalAfter.head || current.tree !== supplementalAfter.tree || current.indexEntriesSha256 !== supplementalAfter.indexEntriesSha256) fail('source-drift');
  if (current.indexSha256 !== supplementalAfter.indexSha256 || !supplementalBefore.rawIndexBytes.equals(supplementalAfter.rawIndexBytes)) fail('raw-index-drift');
  if (current.status.length !== 0) fail('dirty-source');
  if (!current.ignored.equals(supplementalAfter.ignored)) fail('ignored-output-unapproved');
  const policy = JSON.parse(fs.readFileSync(path.join(binding.proofRoot, 'script/repository_artifact_policy.json'), 'utf8'));
  const manifest = JSON.parse(fs.readFileSync(path.join(binding.proofRoot, 'script/repository_verification_stages.json'), 'utf8'));
  const ignoredCounts = validateIgnored(repoRoot, supplementalBefore.ignored, supplementalAfter.ignored, policy, manifest);
  const runId = String(record.run.id ?? '');
  if (!/^[A-Za-z0-9._-]{1,80}$/.test(runId)) fail('invalid-private-record');
  const proof = {
    schemaVersion: 1,
    phase: PHASE,
    plan: PLAN,
    kind,
    status: 'pass',
    command: 'script/verify_repository.sh --all',
    source: { commit: source.commit, tree: source.tree },
    runId,
    stages: stages.map(purpose => ({ purpose, result: 'PASS' })),
    stageCount: stages.length,
    executedLogCount: logNames.length,
    ignoredArtifacts: ignoredCounts,
    privateEvidence: 'owner-private-retained'
  };
  const absoluteOutput = path.resolve(outputPath || PUBLIC_OUTPUT);
  fs.mkdirSync(path.dirname(absoluteOutput), { recursive: true });
  const tmp = `${absoluteOutput}.tmp-${crypto.randomBytes(5).toString('hex')}`;
  fs.writeFileSync(tmp, `${JSON.stringify(proof, null, 2)}\n`, { mode: 0o600 });
  fs.renameSync(tmp, absoluteOutput); fs.chmodSync(absoluteOutput, 0o644);
  return proof;
}
function selfTest() {
  if (ORDER.length !== 9 || ORDER[0] !== 'repository-preflight' || ORDER.at(-1) !== 'repository-cleanliness') fail('output-not-complete');
  console.log('PASS local-proof self-test');
}
function main(argv) {
  if (argv.length === 1 && argv[0] === '--self-test') { selfTest(); return; }
  if (argv.length === 1 && argv[0] === '--collect') {
    const kind = process.env.CROSSWAKE_178_PROOF_KIND;
    const proof = collect(process.env.CROSSWAKE_178_INVOCATION_RECORD, process.env.CROSSWAKE_178_PUBLIC_OUTPUT || defaultProofOutput(kind), kind, process.env.CROSSWAKE_178_FINAL_SOURCE_BINDING);
    console.log(`PASS local-proof collect ${proof.kind}`);
    return;
  }
  if (argv.length === 2 && argv[0] === '--snapshot' && ['before', 'after'].includes(argv[1])) {
    const result = snapshot(process.env.CROSSWAKE_178_SOURCE_ROOT, argv[1], process.env.CROSSWAKE_178_CAPTURE_ROOT);
    console.log(`PASS local-proof snapshot ${argv[1]} ${result.head.slice(0, 12)}`);
    return;
  }
  fail('invalid-private-record');
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try { main(process.argv.slice(2)); }
  catch (error) {
    if (process.argv.length === 3 && process.argv[2] === '--collect') {
      const kind = process.env.CROSSWAKE_178_PROOF_KIND;
      try { writeBlockedProjection(process.env.CROSSWAKE_178_INVOCATION_RECORD, process.env.CROSSWAKE_178_PUBLIC_OUTPUT || defaultProofOutput(kind), kind, process.env.CROSSWAKE_178_FINAL_SOURCE_BINDING, error); } catch { /* Preserve a generic safe cause if even the bound projection cannot be written. */ }
    }
    console.error(`FAIL local-proof ${error.safeCause ?? 'invocation-failed'} error=${['ENOENT', 'EACCES', 'EEXIST', 'ENOTDIR'].includes(error.code) ? error.code : error.name}`); process.exitCode = 1;
  }
}

export { candidateBinding, collect, defaultProofOutput, finalSourceBinding, parseFacadeOutput, snapshot, supplementalGitEnv, writeBlockedProjection };
