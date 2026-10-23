import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { normalizePolicy } from './ci_evidence.mjs';

const EVIDENCE = path.dirname(fileURLToPath(import.meta.url));
const WORKSPACE = path.resolve(EVIDENCE, '../../../../../..');
const OWNER_POINTER = '/private/tmp/crosswake-178-owner-env';
const REPOSITORY = 'szTheory/crosswake';
const CANONICAL_URL = 'https://github.com/szTheory/crosswake.git';
const STAGE_ORDER = Object.freeze(['repository-preflight', 'root-proof', 'example-host-proof', 'browser-proof', 'ios-package-proof', 'android-package-proof', 'format-proof', 'warnings-proof', 'repository-cleanliness']);
export const ALLOWED_PATHS = Object.freeze([
  'README.md', 'docs/COMPANION-PUBLISH-RUNBOOK.md', 'docs/RELEASE-INCIDENT-RESPONSE.md',
  'script/collection_assertion_ledger.json', 'script/collection_assertion_remediation.json',
  'test/crosswake/guides/release_boundaries_test.exs',
  'test/crosswake/release_candidate/companion_receipt_test.exs',
  'test/crosswake/release_candidate/evidence_gate_test.exs',
].sort());
const SAFE_CAUSES = new Set([
  'missing-private-handoff', 'private-permissions', 'candidate-mismatch', 'proof-mismatch',
  'policy-mismatch', 'wrong-base', 'source-drift', 'path-set-mismatch', 'dirty-delivery-clone',
  'policy-read-inaccessible', 'malformed-policy-response', 'base-protection-missing',
  'branch-collision', 'proposal-write-failed', 'delivery-binding-exists', 'missing-authority',
  'binding-consumed', 'remote-operation-failed', 'uncertain-delivery', 'verification-failed',
]);
const isObject = x => x !== null && typeof x === 'object' && !Array.isArray(x);
const sha256 = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function fail(cause) { const e = new Error(SAFE_CAUSES.has(cause) ? cause : 'verification-failed'); e.safeCause = SAFE_CAUSES.has(cause) ? cause : 'verification-failed'; throw e; }
function readJson(file, cause = 'candidate-mismatch') { try { return JSON.parse(fs.readFileSync(file, 'utf8')); } catch { fail(cause); } }
function modeFile(file, expected) {
  let st; try { st = fs.lstatSync(file); } catch { fail('missing-private-handoff'); }
  if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o777) !== expected || st.uid !== process.getuid?.()) fail('private-permissions');
  return fs.readFileSync(file);
}
function privateRunRoot(ownerRoot, purpose) {
  const parent = path.join(ownerRoot, 'delivery-runs');
  fs.mkdirSync(parent, { recursive: true, mode: 0o700 }); fs.chmodSync(parent, 0o700);
  const dir = path.join(parent, `${purpose}-${Date.now()}-${crypto.randomUUID()}`);
  fs.mkdirSync(dir, { mode: 0o700 }); fs.chmodSync(dir, 0o700); return dir;
}
function captureProcess(captureRoot, label, bin, args, options = {}) {
  const r = spawnSync(bin, args, { encoding: null, timeout: options.timeout ?? 120000, maxBuffer: options.maxBuffer ?? 32 * 1024 * 1024, cwd: options.cwd,
    env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', ...options.env } });
  const id = `${label.replace(/[^A-Za-z0-9._-]/g, '_')}-${crypto.randomUUID()}`;
  const result = { exitStatus: r.status, signal: r.signal ?? null, errorCode: r.error?.code ?? null,
    stdout: Buffer.from(r.stdout ?? []), stderr: Buffer.from(r.stderr ?? []) };
  for (const [suffix, bytes] of [['stdout', result.stdout], ['stderr', result.stderr], ['status', Buffer.from(JSON.stringify({ exitStatus: result.exitStatus, signal: result.signal, errorCode: result.errorCode }))]]) {
    const file = path.join(captureRoot, `${id}.${suffix}`); fs.writeFileSync(file, bytes, { mode: 0o600, flag: 'wx' }); fs.chmodSync(file, 0o600);
  }
  return result;
}
function privateJson(file) { try { return JSON.parse(modeFile(file, 0o600).toString('utf8')); } catch (e) { if (e.safeCause) throw e; fail('private-permissions'); } }
function within(root, child) { const rel = path.relative(root, child); return rel === '' || (!rel.startsWith(`..${path.sep}`) && rel !== '..' && !path.isAbsolute(rel)); }
function canonicalPrivateRoot(pointer = OWNER_POINTER) {
  const bytes = modeFile(pointer, 0o600).toString('utf8');
  const raw = bytes.trim(); if (!raw || raw.includes('\n') || raw.includes('\r') || !path.isAbsolute(raw)) fail('missing-private-handoff');
  let root; try { root = fs.realpathSync(raw); } catch { fail('missing-private-handoff'); }
  const st = fs.lstatSync(root);
  const allowed = [path.resolve('/private/tmp'), fs.realpathSync(os.tmpdir())].some(base => within(base, root));
  const workspace = fs.realpathSync(WORKSPACE);
  if (!allowed || !st.isDirectory() || st.isSymbolicLink() || st.uid !== process.getuid?.() || (st.mode & 0o777) !== 0o700 || within(workspace, root) || within(root, workspace)) fail('private-permissions');
  return root;
}
function git(repo, args, bin = 'git', extra = {}, captureRoot = null) {
  const r = captureRoot ? captureProcess(captureRoot, `git-${args[0] || 'call'}`, bin, ['-C', repo, ...args], { env: extra, maxBuffer: 32 * 1024 * 1024 })
    : (() => { const x = spawnSync(bin, ['-C', repo, ...args], { encoding: null, timeout: 120000, maxBuffer: 32 * 1024 * 1024, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0', ...extra } }); return { stdout: Buffer.from(x.stdout ?? []), stderr: Buffer.from(x.stderr ?? []), exitStatus: x.status, signal: x.signal, errorCode: x.error?.code }; })();
  if (r.errorCode || r.signal || r.exitStatus !== 0) fail(extra.cause || 'source-drift');
  return { stdout: r.stdout, stderr: r.stderr, status: r.exitStatus, signal: r.signal, error: r.errorCode };
}
function gitText(repo, args, bin = 'git', extra = {}, captureRoot = null) { return git(repo, args, bin, extra, captureRoot).stdout.toString('utf8').trim(); }
function ghJson(route, bin, env = process.env, captureRoot = null, label = 'github-get', paginate = false) {
  const args = ['api', '--hostname', 'github.com']; if (paginate) args.push('--paginate', '--slurp'); args.push(route);
  const r = captureRoot ? captureProcess(captureRoot, label, bin, args, { timeout: 30000, maxBuffer: 8 * 1024 * 1024, env })
    : (() => { const x = spawnSync(bin, args, { encoding: null, timeout: 30000, maxBuffer: 8 * 1024 * 1024, env }); return { stdout: Buffer.from(x.stdout ?? []), stderr: Buffer.from(x.stderr ?? []), exitStatus: x.status, signal: x.signal, errorCode: x.error?.code }; })();
  if (r.errorCode || r.signal || r.exitStatus !== 0) {
    const stderr = r.stderr.toString('utf8');
    if (/HTTP\s+404\b/.test(stderr)) return { missing: true };
    fail('policy-read-inaccessible');
  }
  try { return JSON.parse(r.stdout.toString('utf8')); } catch { fail('malformed-policy-response'); }
}
function ownerPrivateFile(ownerRoot, file, cause = 'proof-mismatch') {
  let real; try { real = fs.realpathSync(file); } catch { fail(cause); }
  if (!within(fs.realpathSync(ownerRoot), real)) fail(cause);
  return modeFile(real, 0o600);
}
function ownerPrivateJson(ownerRoot, file, cause = 'proof-mismatch') {
  try { return JSON.parse(ownerPrivateFile(ownerRoot, file, cause).toString('utf8')); } catch (e) { if (e.safeCause) throw e; fail(cause); }
}
function requirePrivateDir(ownerRoot, dir, cause) {
  let real, st; try { real = fs.realpathSync(dir); st = fs.lstatSync(dir); } catch { fail(cause); }
  if (!within(fs.realpathSync(ownerRoot), real) || !st.isDirectory() || st.isSymbolicLink() || st.uid !== process.getuid?.() || (st.mode & 0o777) !== 0o700) fail(cause);
  return real;
}
function parseNul(bytes, cause) { if (bytes.length && bytes.at(-1) !== 0) fail(cause); return bytes.length ? bytes.toString('utf8').split('\0').slice(0, -1) : []; }
function countNul(bytes, cause) { return parseNul(bytes, cause).length; }
function verifyLocalProof(ownerRoot, proof, proofPublic, source, gitBin, adapterCapture) {
  const recordBytes = ownerPrivateFile(ownerRoot, proof.invocationRecord); const record = JSON.parse(recordBytes.toString('utf8'));
  const captureRoot = requirePrivateDir(ownerRoot, proof.captureRoot, 'proof-mismatch');
  const runRoot = requirePrivateDir(ownerRoot, proof.runRoot, 'proof-mismatch');
  if (record.schemaVersion !== 1 || record.run?.status !== 0 || record.run?.id !== proof.invocationId || record.run?.runRoot !== proof.runRoot ||
      record.run?.captureRoot !== proof.captureRoot || fs.realpathSync(record.run?.sourceRoot) !== fs.realpathSync(proof.proofRoot) ||
      fs.realpathSync(record.run?.repoRoot) !== fs.realpathSync(proof.proofRoot) || path.dirname(runRoot) !== captureRoot ||
      record.source?.commit !== source.candidateCommit || record.source?.tree !== source.candidateTree || record.source?.candidateCommit !== source.candidateCommit ||
      record.source?.candidateTree !== source.candidateTree || record.sourceAfter?.commit !== source.candidateCommit || record.sourceAfter?.tree !== source.candidateTree ||
      record.source?.indexSha256 !== proof.sourceBefore?.indexSha256 || record.source?.indexEntriesSha256 !== proof.sourceBefore?.indexEntriesSha256 ||
      record.sourceAfter?.indexSha256 !== proof.sourceAfter?.indexSha256 || record.sourceAfter?.indexEntriesSha256 !== proof.sourceAfter?.indexEntriesSha256 ||
      proof.sourceBefore?.commit !== source.candidateCommit || proof.sourceBefore?.tree !== source.candidateTree || proof.sourceAfter?.commit !== source.candidateCommit || proof.sourceAfter?.tree !== source.candidateTree) fail('proof-mismatch');
  const parseCapturedPath = (file, requiredDir = captureRoot) => {
    const bytes = ownerPrivateFile(ownerRoot, file); let real;
    try { real = fs.realpathSync(file); } catch { fail('proof-mismatch'); }
    if (!within(requiredDir, real)) fail('proof-mismatch'); return bytes;
  };
  if (parseCapturedPath(record.run.stdoutPath).toString('utf8').trimEnd().split(/\r?\n/).join('\n') !== STAGE_ORDER.map(s => `PASS ${s}`).join('\n')) fail('proof-mismatch');
  parseCapturedPath(record.run.stderrPath);
  if (parseCapturedPath(record.run.facadeStatusPath).toString('utf8').trim() !== '0') fail('proof-mismatch');
  const logsRoot = requirePrivateDir(ownerRoot, path.join(runRoot, 'logs'), 'proof-mismatch');
  const expectedLogs = STAGE_ORDER.slice(1).map(stage => `${stage}.log`).sort();
  const logs = fs.readdirSync(logsRoot).sort(); if (!same(logs, expectedLogs)) fail('proof-mismatch');
  for (const log of logs) {
    const text = ownerPrivateFile(ownerRoot, path.join(logsRoot, log)).toString('utf8');
    if (!text.startsWith('status=0\n')) fail('proof-mismatch');
  }
  for (const relative of ['git-before.z', 'git-final.z']) if (ownerPrivateFile(ownerRoot, path.join(runRoot, relative)).length !== 0) fail('proof-mismatch');
  if (proof.stageCount !== 9 || proof.executedLogCount !== 8 || proofPublic.stageCount !== 9 || proofPublic.executedLogCount !== 8 ||
      !Array.isArray(proofPublic.stages) || !same(proofPublic.stages.map(s => s.purpose), STAGE_ORDER) || proofPublic.stages.some(s => s.result !== 'PASS')) fail('proof-mismatch');

  const supplemental = [];
  for (const [slot, expected] of [['before', proof.sourceBefore], ['after', proof.sourceAfter]]) {
    const metaPath = record.supplemental?.[`${slot}Path`]; if (typeof metaPath !== 'string') fail('proof-mismatch');
    const meta = ownerPrivateJson(ownerRoot, metaPath);
    if (meta.head !== source.candidateCommit || meta.tree !== source.candidateTree || meta.indexSha256 !== expected.indexSha256 || meta.indexEntriesSha256 !== expected.indexEntriesSha256) fail('proof-mismatch');
    const indexBytes = ownerPrivateFile(ownerRoot, meta.rawIndexPath); const supplementalStatus = ownerPrivateFile(ownerRoot, meta.statusPath ?? meta.statusFile);
    const ignored = ownerPrivateFile(ownerRoot, meta.ignoredPath);
    if (sha256(indexBytes) !== meta.indexSha256 || !indexBytes.equals(ownerPrivateFile(ownerRoot, expected.rawIndexPath)) || supplementalStatus.length !== 0) fail('proof-mismatch');
    const ignoredPaths = parseNul(ignored, 'proof-mismatch');
    supplemental.push({ meta, indexBytes, status: supplementalStatus, ignored, ignoredCount: ignoredPaths.length, ignoredPaths });
  }
  const beforeIgnored = new Set(supplemental[0].ignoredPaths);
  const newIgnoredCount = supplemental[1].ignoredPaths.filter(rel => !beforeIgnored.has(rel)).length;
  if (!supplemental[0].indexBytes.equals(supplemental[1].indexBytes) || proofPublic.ignoredArtifacts?.beforeCount !== supplemental[0].ignoredCount ||
      proofPublic.ignoredArtifacts?.afterCount !== supplemental[1].ignoredCount || proofPublic.ignoredArtifacts?.newCount !== newIgnoredCount) fail('proof-mismatch');
  const proofRoot = fs.realpathSync(proof.proofRoot);
  const head = gitText(proofRoot, ['rev-parse', 'HEAD'], gitBin, {}, adapterCapture);
  const tree = gitText(proofRoot, ['rev-parse', 'HEAD^{tree}'], gitBin, {}, adapterCapture);
  const indexPath = gitText(proofRoot, ['rev-parse', '--path-format=absolute', '--git-path', 'index'], gitBin, {}, adapterCapture);
  const currentIndex = fs.readFileSync(indexPath);
  const entries = git(proofRoot, ['ls-files', '--stage', '-z'], gitBin, {}, adapterCapture).stdout;
  const status = git(proofRoot, ['status', '--porcelain=v1', '-z', '--untracked-files=all'], gitBin, {}, adapterCapture).stdout;
  const ignoredLive = git(proofRoot, ['ls-files', '--others', '--ignored', '--exclude-standard', '-z'], gitBin, {}, adapterCapture).stdout;
  if (head !== source.candidateCommit || tree !== source.candidateTree || !currentIndex.equals(supplemental[1].indexBytes) ||
      sha256(currentIndex) !== proof.sourceAfter.indexSha256 || sha256(entries) !== proof.sourceAfter.indexEntriesSha256 || status.length !== 0 ||
      !ignoredLive.equals(supplemental[1].ignored)) fail('proof-mismatch');
  return { stageOrder: STAGE_ORDER, ignoredCounts: { before: supplemental[0].ignoredCount, after: supplemental[1].ignoredCount, new: newIgnoredCount } };
}
function verifyCiBinding(ownerRoot, ci, contract, source) {
  const pointerKeys = ['branchProtection', 'effectiveRules', 'workflowIdentity', 'currentMain', 'workflowBlob'];
  if (!same(Object.keys(ci.rawResponsePointers).sort(), [...pointerKeys].sort()) || !same(Object.keys(ci.rawResponseIntegrity).sort(), [...pointerKeys, 'verifiedAgainstNormalizedValues'].sort()) || ci.rawResponseIntegrity.verifiedAgainstNormalizedValues !== true) fail('policy-mismatch');
  const seenFiles = new Set(); const captures = {};
  for (const key of pointerKeys) {
    const pointer = ci.rawResponsePointers[key]; const integrity = ci.rawResponseIntegrity[key];
    if (!isObject(pointer) || !isObject(integrity)) fail('policy-mismatch');
    const bytes = {};
    for (const name of ['stdout', 'stderr', 'status']) {
      if (typeof pointer[name] !== 'string') fail('policy-mismatch');
      const file = fs.realpathSync(pointer[name]); if (!within(fs.realpathSync(ownerRoot), file) || seenFiles.has(file)) fail('policy-mismatch'); seenFiles.add(file);
      bytes[name] = modeFile(file, 0o600);
    }
    const statusText = bytes.status.toString('utf8');
    const stdoutHash = sha256(bytes.stdout); const stderrHash = sha256(bytes.stderr); const statusHash = sha256(statusText);
    if (statusText !== '0' || integrity.status !== 0 || integrity.stdoutBytes !== bytes.stdout.length || integrity.stderrBytes !== bytes.stderr.length ||
        integrity.stdoutSha256 !== stdoutHash || integrity.stderrSha256 !== stderrHash || integrity.statusSha256 !== statusHash ||
        pointer.stdoutBytes !== bytes.stdout.length || pointer.stderrBytes !== bytes.stderr.length || pointer.stdoutSha256 !== stdoutHash || pointer.stderrSha256 !== stderrHash || pointer.statusSha256 !== statusHash) fail('policy-mismatch');
    let parsed; try { parsed = JSON.parse(bytes.stdout.toString('utf8')); } catch { parsed = bytes.stdout.toString('utf8').trim(); }
    captures[key] = parsed;
  }
  const protection = Array.isArray(captures.branchProtection) && captures.branchProtection.length === 1 ? captures.branchProtection[0] : null;
  const normalized = normalizePolicy([protection], captures.effectiveRules);
  const workflowPages = captures.workflowIdentity;
  const currentMainPages = captures.currentMain;
  const workflow = Array.isArray(workflowPages) && workflowPages.length === 1 ? workflowPages[0] : null;
  const main = Array.isArray(currentMainPages) && currentMainPages.length === 1 ? currentMainPages[0] : null;
  const blob = captures.workflowBlob;
  if (!normalized.ok || !same(normalized.required, ci.policy.normalized.required) || normalized.strict !== ci.policy.normalized.strict ||
      normalized.effectiveRuleCount !== ci.policy.normalized.effectiveRuleCount || normalized.rulesetEvidence !== ci.policy.normalized.rulesetEvidence ||
      workflow?.id !== ci.workflow.id || workflow?.path !== ci.workflow.path || workflow?.state !== 'active' ||
      main?.sha !== source.sourceBaseCommit || String(blob).replace(/\n$/, '') !== contract.workflow.source.blobOid ||
      contract.policy?.branchProtection?.strict !== normalized.strict || contract.policy?.effectiveRules?.ruleCount !== normalized.effectiveRuleCount ||
      contract.policy?.effectiveRules?.state !== normalized.rulesetEvidence) fail('policy-mismatch');
  return normalized;
}
function validatePrivateSource(privateRoot, files = {}) {
  const captureRoot = files.captureRoot || privateRunRoot(privateRoot, 'prepare-verify');
  const bindingNames = ['candidate-binding-renewed.json', 'candidate-binding.json'].filter(name => fs.existsSync(path.join(privateRoot, name)));
  if (bindingNames.length !== 1 || bindingNames[0] !== 'candidate-binding-renewed.json') fail('candidate-mismatch');
  const candidate = privateJson(path.join(privateRoot, bindingNames[0]));
  const proof = privateJson(path.join(privateRoot, 'local-proof-binding.json'));
  const ci = privateJson(path.join(privateRoot, 'ci-policy-binding.json'));
  const source = readJson(files.sourceFile || path.join(EVIDENCE, 'candidate-source.json'));
  const proofPublic = readJson(files.proofFile || path.join(EVIDENCE, 'preliminary-local-proof.json'));
  const contract = readJson(files.contractFile || path.join(EVIDENCE, 'ci-contract.json'));
  const selected = [...ALLOWED_PATHS];
  const identities = [candidate, ci].every(x => x.phase === 178 && x.schemaVersion >= 1 && x.candidateCommit === source.candidateCommit && x.candidateTree === source.candidateTree && same([...x.selectedPaths].sort(), selected));
  if (!identities || source.status !== 'source-qualified' || source.selectedCount !== 8 || !same([...source.selectedPaths].sort(), selected)) fail('candidate-mismatch');
  if (candidate.sourceBaseCommit !== source.sourceBaseCommit || candidate.sourceBaseTree !== source.sourceBaseTree) fail('wrong-base');
  if (proof.phase !== 178 || proof.schemaVersion < 1 || proof.candidateCommit !== source.candidateCommit || proof.candidateTree !== source.candidateTree || !same([...proof.selectedPaths].sort(), selected) || proof.plan !== '02' || proof.kind !== 'preliminary' || proof.stageCount !== 9 || proof.executedLogCount !== 8 ||
      proofPublic.status !== 'pass' || proofPublic.kind !== 'preliminary' || proofPublic.source?.commit !== source.candidateCommit || proofPublic.source?.tree !== source.candidateTree || proofPublic.stageCount !== 9 || proofPublic.executedLogCount !== 8 || !Array.isArray(proofPublic.stages) || proofPublic.stages.length !== 9 || proofPublic.stages.some(stage => stage.result !== 'PASS')) fail('proof-mismatch');
  if (ci.plan !== '03' || contract.status !== 'policy-observed-source-contract-ready-for-run' || contract.repository !== REPOSITORY || contract.candidate?.baseCommit !== source.sourceBaseCommit || contract.candidate?.commit !== source.candidateCommit || contract.candidate?.tree !== source.candidateTree || contract.candidate?.selectedPathCount !== 8 || contract.workflow?.source?.version !== source.candidateCommit || contract.workflow?.id !== ci.workflow?.id || ci.workflow?.repository !== REPOSITORY || ci.workflow?.path !== contract.workflow?.path || ci.policy?.targetBase !== 'main' || ci.policy?.normalized?.strict !== contract.policy?.branchProtection?.strict || ci.policy?.normalized?.effectiveRuleCount !== contract.policy?.effectiveRules?.ruleCount || ci.policy?.normalized?.rulesetEvidence !== contract.policy?.effectiveRules?.state) fail('policy-mismatch');
  verifyLocalProof(privateRoot, proof, proofPublic, source, files.gitBin || 'git', captureRoot);
  verifyCiBinding(privateRoot, ci, contract, source);
  const root = fs.realpathSync(candidate.deliveryRoot);
  if (root === fs.realpathSync(WORKSPACE) || within(fs.realpathSync(WORKSPACE), root) || within(root, fs.realpathSync(WORKSPACE)) || fs.realpathSync(proof.proofRoot) === root) fail('candidate-mismatch');
  const head = gitText(root, ['rev-parse', 'HEAD'], files.gitBin || 'git', {}, captureRoot);
  const tree = gitText(root, ['rev-parse', 'HEAD^{tree}'], files.gitBin || 'git', {}, captureRoot);
  if (git(root, ['status', '--porcelain=v1', '-z', '--untracked-files=all'], files.gitBin || 'git', {}, captureRoot).stdout.length !== 0) fail('dirty-delivery-clone');
  if (head !== source.candidateCommit) {
    const currentPaths = gitText(root, ['diff-tree', '--no-commit-id', '--name-only', '-r', source.sourceBaseCommit, head], files.gitBin || 'git', {}, captureRoot).split('\n').filter(Boolean).sort();
    if (!same(currentPaths, selected)) fail('path-set-mismatch');
    fail('source-drift');
  }
  if (tree !== source.candidateTree) fail('source-drift');
  if (gitText(root, ['rev-parse', `${source.candidateCommit}^`], files.gitBin || 'git', {}, captureRoot) !== source.sourceBaseCommit) fail('wrong-base');
  const paths = gitText(root, ['diff-tree', '--no-commit-id', '--name-only', '-r', source.sourceBaseCommit, source.candidateCommit], files.gitBin || 'git', {}, captureRoot).split('\n').filter(Boolean).sort();
  if (!same(paths, selected)) fail('path-set-mismatch');
  const numstat = gitText(root, ['diff', '--numstat', source.sourceBaseCommit, source.candidateCommit], files.gitBin || 'git', {}, captureRoot).split('\n').filter(Boolean).map(line => line.split('\t'));
  if (numstat.length !== 8 || numstat.some(row => row.length !== 3 || !/^\d+$/.test(row[0]) || !/^\d+$/.test(row[1]))) fail('path-set-mismatch');
  return { candidate, proof, ci, source, proofPublic, contract, deliveryRoot: root, paths, numstat };
}
export function validateSources(options) {
  const privateRoot = options.privateRoot || canonicalPrivateRoot(options.pointerPath);
  return validatePrivateSource(privateRoot, options);
}
function readCurrentPolicy({ ghBin, env, baseCommit, branch, captureRoot }) {
  const repository = ghJson(`repos/${REPOSITORY}`, ghBin, env, captureRoot, 'policy-repository');
  const base = ghJson(`repos/${REPOSITORY}/branches/${branch}`, ghBin, env, captureRoot, 'policy-base');
  const protectionPages = ghJson(`repos/${REPOSITORY}/branches/${branch}/protection/required_status_checks`, ghBin, env, captureRoot, 'policy-required-checks', true);
  const rulesPages = ghJson(`repos/${REPOSITORY}/rules/branches/${branch}?per_page=100`, ghBin, env, captureRoot, 'policy-effective-rules', true);
  if (repository.missing || base.missing || repository.full_name !== REPOSITORY || repository.default_branch !== branch || base.name !== branch || base.commit?.sha !== baseCommit) fail('wrong-base');
  const normalized = normalizePolicy(protectionPages, rulesPages);
  if (!normalized.ok) fail('malformed-policy-response');
  const ci = normalized.required.find(row => row.context === 'Crosswake CI');
  if (normalized.strict !== true || !ci || ci.appId !== 15368) fail('base-protection-missing');
  return { repository: REPOSITORY, base: branch, baseCommit: base.commit.sha,
    branchProtection: { strict: normalized.strict, requiredContexts: normalized.required },
    effectiveRules: { state: normalized.rulesetEvidence, count: normalized.effectiveRuleCount, fingerprint: sha256(Buffer.from(JSON.stringify({ strict: normalized.strict, required: normalized.required, rules: rulesPages }))) } };
}
function ensureBranchAvailable(branch, ghBin, env, captureRoot) {
  const result = ghJson(`repos/${REPOSITORY}/branches/${branch}`, ghBin, env, captureRoot, 'branch-collision-check');
  if (result.missing) return;
  if (result.name === branch) fail('branch-collision');
  fail('malformed-policy-response');
}
function writeAtomic(file, bytes, mode = 0o644, failCause = 'proposal-write-failed') {
  const temp = `${file}.${process.pid}.${crypto.randomBytes(6).toString('hex')}.tmp`;
  try {
    fs.mkdirSync(path.dirname(file), { recursive: true, mode: mode === 0o600 ? 0o700 : 0o755 });
    const fd = fs.openSync(temp, 'wx', mode); try { fs.writeFileSync(fd, bytes); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
    fs.chmodSync(temp, mode); fs.renameSync(temp, file);
  } catch { try { fs.unlinkSync(temp); } catch {} fail(failCause); }
}
function writePrivateAtomic(file, value) { writeAtomic(file, `${JSON.stringify(value, null, 2)}\n`, 0o600, 'private-permissions'); }
function operationCardProjection(proposal) {
  return { pushArgv: proposal.action.pushArgv, pullRequestArgvPrefix: proposal.action.pullRequest.argv,
    pullRequestBodySha256: sha256(Buffer.from(proposal.action.pullRequest.body, 'utf8')) };
}
export function publicProposalSafe(value) {
  if (!isObject(value)) return false;
  const forbiddenKey = /root|pointer|private|capture|patch|raw|invocationrecord|stdout|stderr|token|credential|bundle/i;
  const forbiddenText = /(?:\/private\/|\/Users\/[^/\s]+|\/var\/folders\/|gh[pousr]_[A-Za-z0-9_]{12,}|github_pat_[A-Za-z0-9_]{12,}|(?:token|credential|authorization)\s*[:=]\s*\S+)/i;
  const visit = x => {
    if (typeof x === 'string') return !forbiddenText.test(x);
    if (Array.isArray(x)) return x.every(visit);
    if (!isObject(x)) return true;
    return Object.entries(x).every(([key, child]) => !forbiddenKey.test(key) && visit(child));
  };
  return visit(value);
}
function proposalCard(joined, policy, branch) {
  const rows = joined.numstat.map(([added, removed, file]) => ({ file, added: Number(added), removed: Number(removed) }));
  const totals = rows.reduce((acc, row) => ({ added: acc.added + row.added, removed: acc.removed + row.removed }), { added: 0, removed: 0 });
  const title = 'Maintain release guides and assertion references';
  const body = `## What changed\n\nRefresh the release-boundary guide and incident response guidance around supported read-only status and source-bound candidate evidence. The candidate receipt remains local and does not authorize publication. Historical candidate-read and mirror-tag modes remain historical.\n\nTests invoke the receipt and evidence-gate Mix tasks directly and assert that source mismatch blocks without writing artifacts. Two assertion snapshots refresh line references by stable keys while preserving all 230 ledger keys, 52 frozen rows, and their expressions.\n\n## Validation\n\n- \`script/verify_repository.sh --all\`: 9/9 stages passed; eight retained stage logs.\n- Exact candidate: ${joined.source.candidateCommit} (${joined.source.candidateTree}).\n- Base: \`main\` at ${policy.baseCommit}.\n- Hosted CI remains pending.`;
  const pullRequestArgvPrefix = ['gh', 'pr', 'create', '--repo', `github.com/${REPOSITORY}`, '--base', 'main', '--head', `szTheory:${branch}`, '--title', title];
  return {
    schemaVersion: 1, phase: 178, plan: '04', status: 'ready-for-scoped-authorization',
    proposalId: `phase178-${joined.source.candidateCommit.slice(0, 12)}-${crypto.randomUUID()}`,
    target: { repository: REPOSITORY, canonicalUrl: CANONICAL_URL, branch, base: 'main', baseCommit: policy.baseCommit, head: joined.source.candidateCommit, tree: joined.source.candidateTree },
    diff: { pathCount: 8, added: totals.added, removed: totals.removed, paths: rows },
    validation: { preliminaryCommand: 'script/verify_repository.sh --all', stagesPassed: 9, stagesTotal: 9, stages: joined.proofPublic.stages.map(({ purpose, result }) => ({ purpose, result })), retainedLogs: 8, sourceCommit: joined.proofPublic.source.commit, sourceTree: joined.proofPublic.source.tree, policy: { observedAt: new Date().toISOString(), branchProtection: policy.branchProtection, effectiveRules: policy.effectiveRules } },
    changeSummary: 'Refresh the release-boundary guide and incident response guidance around supported read-only status and source-bound candidate evidence. The candidate receipt remains local and does not authorize publication. Historical candidate-read and mirror-tag modes remain historical. Tests invoke the receipt and evidence-gate Mix tasks directly and assert that source mismatch blocks without writing artifacts. Two assertion snapshots refresh line references by stable keys while preserving all 230 ledger keys, 52 frozen rows, and their expressions.',
    action: { type: 'ordinary-branch-and-pull-request', pushArgv: ['git', 'push', CANONICAL_URL, `${joined.source.candidateCommit}:refs/heads/${branch}`], pullRequest: { method: 'gh pr create', repo: `github.com/${REPOSITORY}`, argv: pullRequestArgvPrefix, base: 'main', head: `szTheory:${branch}`, title, body, draft: false }, prohibited: ['force push', 'delete', 'admin bypass', 'merge', 'tag', 'publication'] },
    decision: 'One plain-language allow or hold applies to this displayed branch-and-PR attempt only.',
  };
}
export async function prepareProposal(options = {}) {
  const gitBin = options.gitBin || process.env.CROSSWAKE_178_GIT_BIN || 'git';
  const ghBin = options.ghBin || process.env.CROSSWAKE_178_GH_BIN || 'gh';
  const privateRoot = options.privateRoot || canonicalPrivateRoot(options.pointerPath);
  const adapterCapture = privateRunRoot(privateRoot, 'prepare');
  const joined = validateSources({ ...options, privateRoot, gitBin, captureRoot: adapterCapture });
  const root = joined.deliveryRoot;
  const canonicalUrl = options.canonicalUrl || CANONICAL_URL;
  if (canonicalUrl !== CANONICAL_URL) fail('candidate-mismatch');
  const branch = `maintenance/phase178-${joined.source.candidateCommit.slice(0, 12)}`;
  const policy = readCurrentPolicy({ ghBin, env: options.env || process.env, baseCommit: joined.source.sourceBaseCommit, branch: 'main', captureRoot: adapterCapture });
  ensureBranchAvailable(branch, ghBin, options.env || process.env, adapterCapture);
  const proposal = proposalCard(joined, policy, branch);
  if (!publicProposalSafe(proposal)) fail('verification-failed');
  const bindingPath = path.join(privateRoot, 'delivery-binding.json');
  const outputFile = options.outputFile || path.join(EVIDENCE, 'maintenance-proposal.json');
  const observationFile = options.observationFile || path.join(path.dirname(outputFile), 'delivery-observation.json');
  if (fs.existsSync(bindingPath)) {
    const old = privateJson(bindingPath);
    if (old.state !== 'awaiting-explicit-allow-or-hold' || old.consumed) fail('delivery-binding-exists');
    const archive = path.join(privateRoot, `delivery-binding-superseded-undisplayed-${old.proposalId}.json`);
    fs.copyFileSync(bindingPath, archive, fs.constants.COPYFILE_EXCL); fs.chmodSync(archive, 0o600);
    if (fs.existsSync(outputFile)) {
      const priorCard = readJson(outputFile);
      if (priorCard.proposalId !== old.proposalId) fail('delivery-binding-exists');
      fs.renameSync(outputFile, `${outputFile}.superseded-undisplayed-${old.proposalId}.json`);
    }
    fs.renameSync(bindingPath, `${bindingPath}.superseded-undisplayed-${old.proposalId}.json`);
  }
  writeAtomic(outputFile, `${JSON.stringify(proposal, null, 2)}\n`);
  const binding = {
    schemaVersion: 1, phase: 178, plan: '04', proposalId: proposal.proposalId,
    proposalSha256: sha256(Buffer.from(`${JSON.stringify(proposal, null, 2)}\n`)),
    sourceCommit: proposal.target.head, sourceTree: proposal.target.tree, baseCommit: proposal.target.baseCommit,
    branch: proposal.target.branch, repository: proposal.target.repository, canonicalUrl: proposal.target.canonicalUrl,
    selectedPaths: ALLOWED_PATHS, operationCard: operationCardProjection(proposal), operationSha256: sha256(Buffer.from(JSON.stringify(operationCardProjection(proposal)))),
    policyFingerprint: proposal.validation.policy.effectiveRules.fingerprint, proofCaptureSetSha256: sha256(Buffer.from(JSON.stringify({ stageOrder: STAGE_ORDER, stages: proposal.validation.stages }))),
    state: 'awaiting-explicit-allow-or-hold', consumed: false,
    createdAt: new Date().toISOString(),
  };
  writeAtomic(bindingPath, `${JSON.stringify(binding, null, 2)}\n`, 0o600);
  const observation = { schemaVersion: 1, phase: 178, plan: '04', status: 'awaiting-explicit-authorization', proposalId: proposal.proposalId,
    repository: REPOSITORY, branch, head: proposal.target.head, base: 'main', baseCommit: proposal.target.baseCommit,
    remoteWrites: 0, hostedCi: 'not-started', authorization: 'not-present', nextAction: 'Prior card superseded undisplayed; display this exact branch-and-pull-request card for one plain-language allow or hold.' };
  writeAtomic(observationFile, `${JSON.stringify(observation, null, 2)}\n`);
  return { proposal, policy, bindingPath };
}

function persistObservation(file, data) { writeAtomic(file, `${JSON.stringify(data, null, 2)}\n`); }
function exactPageRecords(value, member) {
  if (!Array.isArray(value) || value.length === 0 || !value.every(Array.isArray)) fail('malformed-policy-response');
  const records = value.flat(); const ids = new Set();
  for (const item of records) {
    if (!isObject(item) || !Number.isSafeInteger(item.id) || ids.has(item.id)) fail('malformed-policy-response');
    ids.add(item.id);
  }
  return records;
}
function observePullRequest({ ghBin, env, branch, head, base, captureRoot }) {
  const result = ghJson(`repos/${REPOSITORY}/pulls?head=szTheory:${branch}&base=${base}&state=all&per_page=100`, ghBin, env, captureRoot, 'pull-request-readback', true);
  const matches = exactPageRecords(result).filter(pr => pr.head?.ref === branch);
  if (matches.length > 1) fail('branch-collision');
  return matches[0] || null;
}
function markAttempt(bindingPath, binding, state, details = {}) {
  const updated = { ...binding, state, ...details, updatedAt: new Date().toISOString() };
  writePrivateAtomic(bindingPath, updated); return updated;
}
function createOperationBinding(ownerRoot, proposal, operation, argv, details = {}) {
  const file = path.join(ownerRoot, `delivery-operation-${proposal.proposalId}-${operation}.json`);
  const value = { schemaVersion: 1, proposalId: proposal.proposalId, operation, argv, argvSha256: sha256(Buffer.from(JSON.stringify(argv))), ...details, state: 'consumed-before-write', consumedAt: new Date().toISOString() };
  const fd = fs.openSync(file, 'wx', 0o600); try { fs.writeFileSync(fd, `${JSON.stringify(value, null, 2)}\n`); fs.fsyncSync(fd); } finally { fs.closeSync(fd); }
  fs.chmodSync(file, 0o600); return file;
}
function markOperation(file, state, fields = {}) { const value = privateJson(file); writePrivateAtomic(file, { ...value, ...fields, state, updatedAt: new Date().toISOString() }); }
function ghWrite(args, bin, env, captureRoot) {
  const r = captureProcess(captureRoot, `gh-${args[0]}-${args[1]}`, bin, args, { timeout: 60000, maxBuffer: 1024 * 1024, env });
  return { ok: !r.errorCode && !r.signal && r.exitStatus === 0, status: r.exitStatus, stdout: r.stdout.toString('utf8'), stderr: r.stderr.toString('utf8') };
}
function pushBranch(root, args, gitBin, env, captureRoot) {
  const r = captureProcess(captureRoot, 'git-push', gitBin, args, { cwd: root, timeout: 120000, maxBuffer: 1024 * 1024, env });
  return { ok: !r.errorCode && !r.signal && r.exitStatus === 0, status: r.exitStatus, stdout: r.stdout.toString('utf8'), stderr: r.stderr.toString('utf8') };
}
function prReadbackMatches(pr, proposal) {
  const action = proposal.action.pullRequest;
  return isObject(pr) && pr.head?.repo?.full_name === REPOSITORY && pr.base?.repo?.full_name === REPOSITORY &&
    pr.head?.ref === proposal.target.branch && pr.head?.sha === proposal.target.head && pr.base?.ref === 'main' &&
    pr.base?.sha === proposal.target.baseCommit && pr.title === action.title && pr.body === action.body && pr.state === 'open' &&
    Number.isSafeInteger(pr.number) && pr.html_url === `https://github.com/${REPOSITORY}/pull/${pr.number}`;
}
function safeFailureObservation(proposal, status, attempted, cause, uncertain) {
  return { schemaVersion: 1, phase: 178, plan: '04', status, proposalId: proposal.proposalId,
    repository: REPOSITORY, branch: proposal.target.branch, head: proposal.target.head, base: 'main', baseCommit: proposal.target.baseCommit,
    attempted, uncertain, safeCause: cause, remoteWrites: attempted ? 'possible' : 0,
    nextAction: 'Read-only reconciliation only; do not retry this consumed attempt.' };
}
export async function deliverProposal(options = {}) {
  const gitBin = options.gitBin || 'git'; const ghBin = options.ghBin || 'gh'; const env = options.env || process.env;
  const privateRoot = options.privateRoot || canonicalPrivateRoot(options.pointerPath);
  const proposalFile = options.proposalFile || path.join(EVIDENCE, 'maintenance-proposal.json');
  const observationFile = options.observationFile || path.join(EVIDENCE, 'delivery-observation.json');
  const proposal = readJson(proposalFile); const bindingPath = path.join(privateRoot, 'delivery-binding.json'); const binding = privateJson(bindingPath);
  const proposalBytes = Buffer.from(`${JSON.stringify(proposal, null, 2)}\n`);
  const operationCard = operationCardProjection(proposal);
  if (binding.proposalId !== proposal.proposalId || binding.proposalSha256 !== sha256(proposalBytes) || !same(binding.operationCard, operationCard) || binding.operationSha256 !== sha256(Buffer.from(JSON.stringify(operationCard))) || binding.policyFingerprint !== proposal.validation?.policy?.effectiveRules?.fingerprint || binding.sourceCommit !== proposal.target?.head || binding.sourceTree !== proposal.target?.tree || binding.branch !== proposal.target?.branch || binding.baseCommit !== proposal.target?.baseCommit || binding.repository !== REPOSITORY || binding.canonicalUrl !== CANONICAL_URL || !same(binding.selectedPaths, ALLOWED_PATHS)) fail('candidate-mismatch');
  if (binding.consumed || binding.state !== 'awaiting-explicit-allow-or-hold') fail('binding-consumed');
  if (options.decision === 'hold') {
    const claim = path.join(privateRoot, `delivery-claim-${proposal.proposalId}.lock`);
    let fd; try { fd = fs.openSync(claim, 'wx', 0o600); fs.writeFileSync(fd, `${process.pid}\n`); fs.fsyncSync(fd); } catch { fail('binding-consumed'); }
    try { markAttempt(bindingPath, binding, 'held', { consumed: true, decidedAt: new Date().toISOString() });
      const held = { schemaVersion: 1, phase: 178, plan: '04', status: 'held', proposalId: proposal.proposalId, remoteWrites: 0, nextAction: 'A new exact proposal requires fresh preparation and a new displayed decision.' };
      persistObservation(observationFile, held); return held;
    } finally { try { fs.closeSync(fd); } catch {} }
  }
  if (options.decision !== 'allow' || options.authorized !== true) fail('missing-authority');
  const claimPath = path.join(privateRoot, `delivery-claim-${proposal.proposalId}.lock`);
  let claimFd;
  try { claimFd = fs.openSync(claimPath, 'wx', 0o600); fs.writeFileSync(claimFd, `${process.pid}\n`); fs.fsyncSync(claimFd); } catch { fail('binding-consumed'); }
  let writeAttempted = false;
  try {
    await new Promise(resolve => setImmediate(resolve));
    const adapterCapture = privateRunRoot(privateRoot, `deliver-${proposal.proposalId}`);
    const joined = validateSources({ ...options, privateRoot, gitBin, captureRoot: adapterCapture });
    if (joined.source.candidateCommit !== proposal.target.head || joined.source.candidateTree !== proposal.target.tree || joined.source.sourceBaseCommit !== proposal.target.baseCommit) fail('source-drift');
    const livePolicy = readCurrentPolicy({ ghBin, env, baseCommit: proposal.target.baseCommit, branch: 'main', captureRoot: adapterCapture });
    const expectedPolicy = proposal.validation.policy;
    if (!same(livePolicy.branchProtection, expectedPolicy.branchProtection) || livePolicy.effectiveRules.fingerprint !== expectedPolicy.effectiveRules.fingerprint) fail('policy-mismatch');
    ensureBranchAvailable(proposal.target.branch, ghBin, env, adapterCapture);
    const priorPr = observePullRequest({ ghBin, env, branch: proposal.target.branch, head: proposal.target.head, base: 'main', captureRoot: adapterCapture });
    if (priorPr) fail('branch-collision');
    let consumed = markAttempt(bindingPath, binding, 'consumed-before-write', { consumed: true, consumedAt: new Date().toISOString(), deliveryCaptureRoot: adapterCapture });
    let pushArgs = [...proposal.action.pushArgv.slice(1)];
    if (!same(proposal.action.pushArgv, ['git', 'push', CANONICAL_URL, `${proposal.target.head}:refs/heads/${proposal.target.branch}`])) fail('candidate-mismatch');
    if (options.fixtureMode && options.remoteUrl) pushArgs[1] = options.remoteUrl;
    const pushOperation = createOperationBinding(privateRoot, proposal, 'push', proposal.action.pushArgv);
    consumed = markAttempt(bindingPath, consumed, 'push-attempted', { pushOperation: path.basename(pushOperation) });
    writeAttempted = true;
    const push = pushBranch(joined.deliveryRoot, pushArgs, gitBin, env, adapterCapture);
    const pushWriteKnown = push.ok;
    let pushObservation;
    try { pushObservation = ghJson(`repos/${REPOSITORY}/branches/${proposal.target.branch}`, ghBin, env, adapterCapture, 'pushed-branch-readback'); }
    catch (error) { persistObservation(observationFile, safeFailureObservation(proposal, 'push-outcome-uncertain', true, error.safeCause || 'uncertain-delivery', true)); throw Object.assign(error, { safeCause: 'uncertain-delivery' }); }
    if (pushObservation.missing || pushObservation.name !== proposal.target.branch || pushObservation.commit?.sha !== proposal.target.head) {
      const cause = pushWriteKnown ? 'verification-failed' : 'uncertain-delivery';
      persistObservation(observationFile, safeFailureObservation(proposal, 'push-not-confirmed', true, cause, !pushWriteKnown)); fail(cause);
    }
    markAttempt(bindingPath, consumed, 'push-confirmed', { pushExitStatus: push.status, pushRemoteSha: pushObservation.commit.sha });
    const postPushPolicy = readCurrentPolicy({ ghBin, env, baseCommit: proposal.target.baseCommit, branch: 'main', captureRoot: adapterCapture });
    if (!same(postPushPolicy.branchProtection, expectedPolicy.branchProtection) || postPushPolicy.effectiveRules.fingerprint !== expectedPolicy.effectiveRules.fingerprint || joined.source.candidateCommit !== proposal.target.head) {
      persistObservation(observationFile, safeFailureObservation(proposal, 'push-confirmed-pr-not-attempted', true, 'policy-mismatch', false)); fail('policy-mismatch');
    }
    const prePrBranch = ghJson(`repos/${REPOSITORY}/branches/${proposal.target.branch}`, ghBin, env, adapterCapture, 'pre-pr-branch-readback');
    if (prePrBranch.missing || prePrBranch.name !== proposal.target.branch || prePrBranch.commit?.sha !== proposal.target.head) {
      persistObservation(observationFile, safeFailureObservation(proposal, 'push-confirmed-branch-drift', true, 'uncertain-delivery', true)); fail('uncertain-delivery');
    }
    const duplicateCheck = observePullRequest({ ghBin, env, branch: proposal.target.branch, head: proposal.target.head, base: 'main', captureRoot: adapterCapture });
    if (duplicateCheck) { persistObservation(observationFile, safeFailureObservation(proposal, 'push-confirmed-pr-collision', true, 'branch-collision', false)); fail('branch-collision'); }
    if (gitText(joined.deliveryRoot, ['rev-parse', 'HEAD'], gitBin, {}, adapterCapture) !== proposal.target.head || gitText(joined.deliveryRoot, ['rev-parse', 'HEAD^{tree}'], gitBin, {}, adapterCapture) !== proposal.target.tree) {
      persistObservation(observationFile, safeFailureObservation(proposal, 'push-confirmed-local-head-drift', true, 'source-drift', false)); fail('source-drift');
    }
    const publicPr = proposal.action.pullRequest;
    const bodyBytes = Buffer.from(publicPr.body, 'utf8');
    if (!Buffer.isBuffer(bodyBytes) || bodyBytes.toString('utf8') !== publicPr.body) fail('verification-failed');
    const bodyFile = path.join(adapterCapture, `pull-request-body-${crypto.randomUUID()}.txt`);
    const bodyFd = fs.openSync(bodyFile, 'wx', 0o600);
    try { fs.writeFileSync(bodyFd, bodyBytes); fs.fsyncSync(bodyFd); } finally { fs.closeSync(bodyFd); }
    fs.chmodSync(bodyFile, 0o600);
    const bodyStat = fs.lstatSync(bodyFile);
    if (!bodyStat.isFile() || bodyStat.isSymbolicLink() || (bodyStat.mode & 0o777) !== 0o600 || !fs.readFileSync(bodyFile).equals(bodyBytes)) fail('verification-failed');
    const prArgs = [...publicPr.argv.slice(1), '--body-file', bodyFile];
    if (prArgs[3] !== 'github.com/szTheory/crosswake' || !prArgs.includes('--base') || prArgs[prArgs.indexOf('--head') + 1] !== `szTheory:${proposal.target.branch}`) fail('candidate-mismatch');
    if (prArgs.includes('--body') || prArgs.at(-2) !== '--body-file' || prArgs.at(-1) !== bodyFile) fail('candidate-mismatch');
    const actualPrArgv = ['gh', ...prArgs];
    const prOperation = createOperationBinding(privateRoot, proposal, 'pull-request', actualPrArgv, { bodyFile, bodySha256: sha256(bodyBytes), bodyBytes: bodyBytes.length });
    consumed = markAttempt(bindingPath, consumed, 'pull-request-attempted', { pullRequestOperation: path.basename(prOperation) });
    writeAttempted = true;
    if (!fs.readFileSync(bodyFile).equals(bodyBytes) || sha256(fs.readFileSync(bodyFile)) !== sha256(bodyBytes)) fail('verification-failed');
    const created = ghWrite(prArgs, ghBin, env, adapterCapture);
    const observed = observePullRequest({ ghBin, env, branch: proposal.target.branch, head: proposal.target.head, base: 'main', captureRoot: adapterCapture });
    if (!observed || !prReadbackMatches(observed, proposal)) {
      const cause = observed ? 'verification-failed' : 'uncertain-delivery';
      persistObservation(observationFile, safeFailureObservation(proposal, observed ? 'pull-request-mismatch' : 'pull-request-outcome-uncertain', true, cause, !observed)); fail(cause);
    }
    const observation = { schemaVersion: 1, phase: 178, plan: '04', status: 'delivered-awaiting-hosted-ci', proposalId: proposal.proposalId, repository: REPOSITORY, branch: proposal.target.branch, head: proposal.target.head, base: 'main', baseCommit: proposal.target.baseCommit, pullRequest: { number: observed.number, url: observed.html_url, state: observed.state }, operationResults: { pushExitStatus: push.status, pullRequestExitStatus: created.status, pushObservedAt: new Date().toISOString(), pullRequestObservedAt: new Date().toISOString() }, remoteWrites: { push: 'confirmed', pullRequestCreate: 'confirmed-by-readback' }, nextAction: 'Plan05 must collect current hosted CI and join exact runner checkout evidence.' };
    markOperation(pushOperation, 'consumed-and-reconciled', { readbackSha: pushObservation.commit.sha });
    markOperation(prOperation, 'consumed-and-reconciled', { pullRequestNumber: observed.number, pullRequestUrl: observed.html_url });
    markAttempt(bindingPath, consumed, 'delivered', { deliveredAt: new Date().toISOString(), pullRequestNumber: observed.number });
    persistObservation(observationFile, observation); return observation;
  } catch (error) {
    const prior = fs.existsSync(observationFile) ? readJson(observationFile) : null;
    if (!prior || prior.proposalId !== proposal.proposalId || (writeAttempted && prior.attempted !== true)) {
      persistObservation(observationFile, safeFailureObservation(proposal, writeAttempted ? 'write-outcome-uncertain' : 'attempt-blocked', writeAttempted, error.safeCause || 'verification-failed', writeAttempted));
    }
    throw error;
  } finally { try { fs.closeSync(claimFd); } catch {} }
}

function runSelfTest() {
  if (ALLOWED_PATHS.length !== 8 || new Set(ALLOWED_PATHS).size !== 8 || !same([...ALLOWED_PATHS].sort(), ALLOWED_PATHS)) fail('path-set-mismatch');
  const sample = { phase: 178, target: { repository: REPOSITORY }, validation: { stagesPassed: 9 } };
  if (!publicProposalSafe(sample) || publicProposalSafe({ ...sample, privateRoot: '/private/x' })) fail('verification-failed');
  return true;
}
function printFailure(error) { process.stderr.write(`proposal delivery blocked: ${SAFE_CAUSES.has(error.safeCause) ? error.safeCause : 'verification-failed'}\n`); return 1; }
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const mode = process.argv[2];
  try {
    if (mode === '--self-test') { runSelfTest(); process.stdout.write('proposal delivery adapter self-test: pass\n'); }
    else if (mode === '--prepare') {
      const result = await prepareProposal();
      process.stdout.write(`proposal ready: ${result.proposal.target.repository} ${result.proposal.target.branch} (${result.proposal.diff.pathCount} paths; preliminary ${result.proposal.validation.stagesPassed}/${result.proposal.validation.stagesTotal})\n`);
    } else if (mode === '--deliver') {
      const decisionAt = process.argv.indexOf('--decision');
      const decision = decisionAt >= 0 ? process.argv[decisionAt + 1] : undefined;
      if (!decision) fail('missing-authority');
      const result = await deliverProposal({ decision, authorized: process.env.CROSSWAKE_178_AUTHORIZED_ATTEMPT === 'displayed-allow' });
      process.stdout.write(`delivery: ${result.status}\n`);
    }
    else { process.stderr.write('usage: proposal_delivery.mjs --self-test|--prepare|--deliver\n'); process.exitCode = 2; }
  } catch (error) { process.exitCode = printFailure(error); }
}
