#!/usr/bin/env node
// One-time phase proof. No dependencies, mutation of source, or caller-authored proof input.
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { createHash, randomBytes } from 'node:crypto';
import { chmodSync, closeSync, existsSync, lstatSync, mkdtempSync, openSync, readFileSync, readlinkSync, readSync, readdirSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const WS = 'quality-ratchet-release';
const PHASE = `.planning/workstreams/${WS}/phases/195-pipeline-repair-and-hygiene`;
const RECEIPT = `${PHASE}/195-EVIDENCE/gap3-delivery.json`;
const REPORT = `${PHASE}/195-REVIEW-GAP3.md`;
const PROOF = `${PHASE}/195-EVIDENCE/gap3-main-proof.json`;
const SOURCE = ['script/verify_repository.mjs', 'test/js/ci_secret_masking.test.mjs'];
const SELF = fileURLToPath(import.meta.url);
const SHA = /^[0-9a-f]{40}$/;
const DIGEST = /^[0-9a-f]{64}$/;
const MAX = 8 * 1024 * 1024;
const PRE_FIX = '7621c0ce0c38edec76cc54209eccf5acf40feddf';
const FAMILIES = [
  'round3 structural repository signing assignment', 'round3 inventory all workflow secret names',
  'round3 padding credential whitespace matrix', 'round3 container inspect values',
  'round3 name-value record isolation', 'round3 tuple wrapped values',
  'round3 private key armor complete layouts', 'round3 private key armor malformed boundaries',
  'round3 armor bounded adversaries', 'round3 guard exact stdout registration',
  'round3 guard rejected execution contexts', 'round3 references bracket and github token',
  'round3 raw window and inventory controls', 'round3 timing quadratic copied control',
  'round3 residual named credential forms', 'round3 residual exact diagnostic pins',
  'round3 residual rule adversaries', 'round3 rule family adversaries',
  'round3 separator head adversaries', 'seeded secrets from a spawned child never reach the root-proof tail',
  'gap seeds are distinctive', 'gap shapes from a spawned child never reach the root-proof tail',
  'linear time baseline', 'masking keeps failure diagnosis and key or header names',
  'maskSecretShapes edge cases are byte-stable', 'live workflow tree: non-empty floor and zero violations',
  'live fire-drill derivation never leaks seeded or derived values into the emulated step log',
  'derivationScript refuses to extract network lines',
  'derivedSecretViolations rejects a single-quoted add-mask',
  'derivedSecretViolations rejects a prefix-collision mask',
  'derivedSecretViolations ignores a commented-out mask',
  'round3 review curl missing separators bounded', 'round3 review keyed armor priority',
  'round3 review name value record boundaries', 'round3 review name value unrelated records',
  'round3 review escaped json containers', 'round3 review identifier and cli parity',
  'round3 review quoted value continuations', 'round3 review persistent stdout context',
  'round3 review sigil diagnostic boundaries'
];
const FINDINGS = [
  'ORIG-CR-01', 'ORIG-CR-02', 'ORIG-WR-01', 'ORIG-WR-02', 'ORIG-WR-03',
  ...Array.from({ length: 10 }, (_, i) => `GAP1-GR-${String(i + 1).padStart(2, '0')}`),
  'GAP2-CR-01', 'GAP2-CR-02',
  ...Array.from({ length: 6 }, (_, i) => `GAP2-WR-${String(i + 1).padStart(2, '0')}`),
  ...Array.from({ length: 4 }, (_, i) => `GAP2-IN-${String(i + 1).padStart(2, '0')}`),
  ...Array.from({ length: 7 }, (_, i) => `GAP3-CR-${String(i + 1).padStart(2, '0')}`), 'GAP3-WR-01'
];
const CONTROL_KEYS = ['rawWindow', 'identity', 'preFix', 'removedAddMask', 'quadratic'];
function requireThat(ok, label) { if (!ok) throw new Error(label); }
function digest(value) { return createHash('sha256').update(value).digest('hex'); }
function exact(obj, keys) {
  requireThat(obj && typeof obj === 'object' && !Array.isArray(obj), 'schema_object');
  requireThat(Object.keys(obj).sort().join('|') === [...keys].sort().join('|'), 'schema_keys');
}
function integer(value, min = 0) { requireThat(Number.isSafeInteger(value) && value >= min, 'schema_number'); }
function sha(value, nullable = false) { requireThat((nullable && value === null) || SHA.test(value), 'schema_sha'); }
function safePath(value) {
  requireThat(typeof value === 'string' && value.length <= 240 && /^[A-Za-z0-9_.\/-]+$/.test(value)
    && !value.startsWith('/') && !value.split('/').includes('..') && !value.split('/').includes('.'), 'schema_path');
}
function decision(value) {
  exact(value, ['answer', 'consumed']);
  requireThat(['pending', 'allow', 'hold', 'not-required'].includes(value.answer) && typeof value.consumed === 'boolean', 'schema_decision');
}
function schema(r) {
  exact(r, ['version', 'ws', 'requirement', 'status', 'refs', 'pr', 'review', 'privacy', 'approvals', 'delivery', 'safeUntracked']);
  requireThat(r.version === 1 && r.ws === WS && r.requirement === 'REL-03' && ['candidate', 'merged'].includes(r.status), 'schema_identity');
  exact(r.refs, ['base', 'fix', 'reviewed', 'pr', 'synthetic', 'merge', 'main', 'docs']);
  for (const key of Object.keys(r.refs)) sha(r.refs[key], ['merge', 'main'].includes(key));
  exact(r.pr, ['number', 'branch', 'base', 'runId', 'runHead', 'deleteBranchOnMerge']);
  integer(r.pr.number, 1); integer(r.pr.runId, 1); sha(r.pr.runHead);
  requireThat(/^fix\/[a-z0-9._-]+$/.test(r.pr.branch) && r.pr.base === 'main' && typeof r.pr.deleteBranchOnMerge === 'boolean', 'schema_pr');
  exact(r.review, ['sha256', 'head', 'openHigh', 'openCritical', 'rows', 'decisions']);
  requireThat(DIGEST.test(r.review.sha256), 'schema_digest'); sha(r.review.head);
  integer(r.review.openHigh); integer(r.review.openCritical);
  requireThat(Array.isArray(r.review.rows) && r.review.rows.length >= FINDINGS.length && r.review.rows.length < 100, 'schema_rows');
  const ids = new Set();
  for (const row of r.review.rows) {
    exact(row, ['id', 'status', 'cases', 'receiver']);
    requireThat((FINDINGS.includes(row.id) || /^GAP3-[A-Z]{2}-\d{2}$/.test(row.id)) && !ids.has(row.id), 'schema_finding'); ids.add(row.id);
    requireThat(['fixed', 'accepted'].includes(row.status), 'finding_open');
    requireThat(Array.isArray(row.cases) && row.cases.length > 0 && row.cases.length < 20 && new Set(row.cases).size === row.cases.length, 'schema_cases');
    for (const name of row.cases) requireThat(typeof name === 'string' && name.length <= 180 && /^[A-Za-z0-9 :_.,()/'=-]+$/.test(name), 'schema_case');
    requireThat(row.status === 'accepted' ? row.id === 'GAP1-GR-06' && row.receiver === 'phase196' : row.receiver === null, 'deferral_unaccepted');
  }
  requireThat(FINDINGS.every(id => ids.has(id)), 'finding_missing');
  // New deferrals need a new bounded decision protocol; they cannot masquerade as old debt.
  requireThat(Array.isArray(r.review.decisions) && r.review.decisions.length === 0, 'new_deferral_requires_decision');
  exact(r.privacy, ['head', 'status', 'sha256', 'path']); sha(r.privacy.head);
  requireThat(r.privacy.status === 'pass' && DIGEST.test(r.privacy.sha256), 'privacy_failed'); safePath(r.privacy.path);
  requireThat(r.privacy.path.startsWith(`${PHASE}/195-EVIDENCE/`), 'privacy_path');
  if (r.approvals !== null) {
    const a = r.approvals;
    exact(a, ['attempt', 'displayedAt', 'prNumber', 'branch', 'deleteBranchOnMerge', 'head', 'base', 'synthetic', 'runId', 'merge', 'deletion']);
    requireThat(/^[0-9a-f]{32}$/.test(a.attempt) && /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(a.displayedAt), 'schema_attempt');
    for (const key of ['head', 'base', 'synthetic']) sha(a[key]); integer(a.runId, 1); decision(a.merge); decision(a.deletion);
    integer(a.prNumber, 1); requireThat(a.branch === r.pr.branch && typeof a.deleteBranchOnMerge === 'boolean', 'schema_approval_scope');
  }
  exact(r.delivery, ['status', 'merge', 'head', 'autoDeleted']);
  requireThat(['not-attempted', 'merged', 'uncertain', 'refused'].includes(r.delivery.status) && typeof r.delivery.autoDeleted === 'boolean', 'schema_delivery');
  sha(r.delivery.merge, true); sha(r.delivery.head);
  requireThat(Array.isArray(r.safeUntracked) && new Set(r.safeUntracked).size === r.safeUntracked.length && r.safeUntracked.length <= 100, 'schema_inventory');
  for (const entry of r.safeUntracked) { safePath(entry); requireThat(!entry.startsWith('.git/'), 'untracked_scope'); }
  return r;
}

function processResult(r, label) {
  requireThat(!r.error && !r.signal && r.status === 0, r.error?.code === 'ETIMEDOUT' ? 'child_timeout' : label);
  requireThat(Buffer.byteLength(r.stdout || '') + Buffer.byteLength(r.stderr || '') <= MAX, 'child_output_limit');
  return r.stdout || '';
}
// A watchdog owns a whole process group, so timed-out Node test workers cannot outlive proof.
const WATCHDOG = `
const {spawn}=require('node:child_process'); const {readFileSync}=require('node:fs');
const c=JSON.parse(readFileSync(0,'utf8')); let stdout='',stderr='',size=0,error=null;
const child=spawn(c.command,c.args,{cwd:c.cwd,env:process.env,detached:true,stdio:['pipe','pipe','pipe']});
const kill=code=>{error={code};try{process.kill(-child.pid,'SIGKILL')}catch{child.kill('SIGKILL')}};
const timer=setTimeout(()=>kill('ETIMEDOUT'),c.timeout);
const collect=key=>chunk=>{size+=chunk.length;if(size>c.max){kill('OUTPUT_LIMIT');return}if(key==='out')stdout+=chunk.toString();else stderr+=chunk.toString()};
child.stdout.on('data',collect('out'));child.stderr.on('data',collect('err'));
child.on('error',()=>{error={code:'SPAWN_FAILED'}});child.stdin.on('error',()=>{});child.stdin.end(c.input||'');
child.on('close',(status,signal)=>{clearTimeout(timer);process.stdout.write(JSON.stringify({status,signal,error,stdout,stderr}))});
`;
function run(command, args, options = {}) {
  const timeout = options.timeout || 120000;
  const env = options.env || { PATH: process.env.PATH, HOME: process.env.HOME,
    ...(command === 'gh' && process.env.GH_TOKEN ? { GH_TOKEN: process.env.GH_TOKEN } : {}),
    ...(command === 'gh' && process.env.GITHUB_TOKEN ? { GITHUB_TOKEN: process.env.GITHUB_TOKEN } : {}) };
  const wrapper = spawnSync(process.execPath, ['-e', WATCHDOG], { encoding: 'utf8', timeout: timeout + 5000, maxBuffer: 6 * MAX + 1024,
    env, input: JSON.stringify({ command, args, cwd: options.cwd || process.cwd(), input: options.input || '', timeout, max: MAX }) });
  requireThat(!wrapper.error && wrapper.status === 0, 'process_watchdog_failed');
  let result; try { result = JSON.parse(wrapper.stdout); } catch { throw new Error('process_watchdog_invalid'); }
  return processResult(result, 'child_failed');
}
function git(...args) { return run('git', args).trim(); }
function json(command, args) { try { return JSON.parse(run(command, args)); } catch { throw new Error('readback_invalid'); } }
function file(relative) { return readFileSync(relative); }
function readReceipt() { try { return schema(JSON.parse(file(RECEIPT))); } catch (e) { if (/^[a-z_]+$/.test(e.message)) throw e; throw new Error('receipt_invalid'); } }
function requiredCases(r) { return [...new Set([...FAMILIES, ...r.review.rows.flatMap(row => row.cases)])]; }
function identity(r) {
  requireThat([r.refs.reviewed, r.refs.pr, r.review.head, r.privacy.head, r.pr.runHead, r.delivery.head].every(value => value === r.refs.fix), 'head_mismatch');
  requireThat(r.refs.synthetic !== r.refs.fix, 'synthetic_conflated');
  requireThat(r.review.openHigh === 0 && r.review.openCritical === 0, 'review_open');
}
function permission(r, consumed = false, now = Date.now()) {
  const a = r.approvals;
  requireThat(a && a.prNumber === r.pr.number && a.branch === r.pr.branch && a.deleteBranchOnMerge === r.pr.deleteBranchOnMerge
    && a.head === r.refs.fix && a.base === r.refs.base && a.synthetic === r.refs.synthetic && a.runId === r.pr.runId, 'permission_scope');
  const age = now - Date.parse(a.displayedAt);
  requireThat(Number.isFinite(age) && age >= 0 && (consumed || age < 30 * 60 * 1000), 'permission_stale');
  requireThat(a.merge.answer === 'allow' && a.merge.consumed === consumed, 'permission_merge');
  requireThat(r.pr.deleteBranchOnMerge
    ? a.deletion.answer === 'allow' && a.deletion.consumed === (consumed && r.delivery.autoDeleted)
    : a.deletion.answer === 'not-required' && !a.deletion.consumed, 'permission_deletion');
}
function readRepository() {
  const repo = json('gh', ['api', 'repos/{owner}/{repo}', '--jq', '{full_name,delete_branch_on_merge}']);
  requireThat(typeof repo.full_name === 'string' && /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo.full_name), 'repository_identity');
  return repo;
}
function live(r, landed = false) {
  identity(r);
  const repo = readRepository();
  const pr = json('gh', ['pr', 'view', String(r.pr.number), '--json', 'headRefOid,headRefName,baseRefOid,baseRefName,state,isDraft,mergeable,mergeStateStatus,reviewDecision,mergeCommit,mergedAt']);
  requireThat(repo.delete_branch_on_merge === r.pr.deleteBranchOnMerge && pr.headRefOid === r.refs.fix && pr.headRefName === r.pr.branch && pr.baseRefName === 'main' && !pr.isDraft, 'pr_identity');
  const workflow = json('gh', ['api', `repos/${repo.full_name}/actions/runs/${r.pr.runId}`, '--jq', '{head_sha,event,status,conclusion,name,check_suite_id}']);
  requireThat(workflow.head_sha === r.refs.fix && workflow.event === 'pull_request' && workflow.status === 'completed' && workflow.conclusion === 'success' && workflow.name === 'Crosswake CI', 'ci_identity');
  const checks = json('gh', ['pr', 'checks', String(r.pr.number), '--required', '--json', 'name,state,workflow,link']);
  requireThat(Array.isArray(checks) && checks.length > 0 && checks.every(check => check.state === 'SUCCESS' && check.workflow === 'Crosswake CI' && check.link?.includes(`/actions/runs/${r.pr.runId}/job/`)) && checks.some(check => check.name === 'Crosswake CI'), 'required_checks');
  const jobs = json('gh', ['api', `repos/${repo.full_name}/actions/runs/${r.pr.runId}/jobs?per_page=100`, '--jq', '{total_count,jobs:[.jobs[]|{id,name,conclusion}]}']);
  requireThat(jobs.total_count === jobs.jobs?.length, 'ci_jobs_incomplete');
  const classify = jobs.jobs.find(job => job.name === 'classify-change');
  requireThat(classify?.conclusion === 'success' && Number.isSafeInteger(classify.id), 'ci_checkout_missing');
  // Read the actual job log privately without gh's user-cache write. Logs may contain ANSI;
  // only checkoutIdentity's fixed verdict survives, never the downloaded log text.
  checkoutIdentity(run('gh', ['api', '--allow-escape-sequences', `repos/${repo.full_name}/actions/jobs/${classify.id}/logs`]), r.refs.synthetic);
  const threads = json('gh', ['api', 'graphql', '-f', `query=query { repository(owner: "${repo.full_name.split('/')[0]}", name: "${repo.full_name.split('/')[1]}") { pullRequest(number: ${r.pr.number}) { reviewThreads(first: 100) { pageInfo { hasNextPage } nodes { isResolved } } } } }`]);
  const reviewThreads = threads.data?.repository?.pullRequest?.reviewThreads;
  requireThat(reviewThreads && !reviewThreads.pageInfo.hasNextPage && reviewThreads.nodes.every(row => row.isResolved), 'review_unresolved');
  requireThat(pr.reviewDecision !== 'CHANGES_REQUESTED', 'review_changes_requested');
  requireThat(git('rev-parse', r.pr.branch) === r.refs.fix, 'local_head_mismatch');
  requireThat(git('merge-base', r.refs.base, r.refs.fix) === r.refs.base, 'base_not_contained');
  requireThat(git('diff', '--name-only', `${r.refs.base}...${r.refs.fix}`).split('\n').sort().join('|') === [...SOURCE].sort().join('|'), 'changed_file_scope');
  requireThat(digest(file(REPORT)) === r.review.sha256 && file(REPORT).toString().includes(r.refs.fix), 'review_binding');
  const tableRows = file(REPORT).toString().split('\n').filter(line => line.startsWith('|')).map(line => line.split('|').map(cell => cell.trim().replace(/^`|`$/g, '')));
  for (const row of r.review.rows) {
    const matches = tableRows.filter(cells => cells.includes(row.id));
    requireThat(matches.length === 1 && matches[0].includes(row.status), 'review_disposition_mismatch');
  }
  const reportIds = [...file(REPORT).toString().matchAll(/\bGAP3-[A-Z]{2}-\d{2}\b/g)].map(match => match[0]);
  requireThat(reportIds.every(id => r.review.rows.some(row => row.id === id)), 'review_new_finding_omitted');
  requireThat(digest(file(r.privacy.path)) === r.privacy.sha256, 'privacy_binding');
  requireThat(git('merge-base', r.refs.docs, 'HEAD') === r.refs.docs, 'docs_binding');
  const names = registeredCases(r.refs.fix);
  requireThat(requiredCases(r).every(name => names.includes(name)), 'case_not_in_source');
  if (landed) {
    requireThat(pr.state === 'MERGED' && pr.mergeCommit?.oid === r.refs.merge && r.delivery.status === 'merged' && r.delivery.merge === r.refs.merge && r.status === 'merged', 'merge_not_recorded');
    permission(r, true);
    const mergedAt = Date.parse(pr.mergedAt), displayedAt = Date.parse(r.approvals.displayedAt);
    requireThat(Number.isFinite(mergedAt) && mergedAt >= displayedAt && mergedAt - displayedAt < 30 * 60 * 1000, 'merge_permission_stale');
    const remote = git('ls-remote', 'origin', `refs/heads/${r.pr.branch}`).split(/\s+/)[0];
    requireThat(r.delivery.autoDeleted ? remote === '' : remote === r.refs.fix, 'deletion_readback');
  } else {
    requireThat(r.delivery.status === 'not-attempted' && r.delivery.merge === null && !r.delivery.autoDeleted && r.status === 'candidate', 'delivery_not_ready');
    requireThat(pr.state === 'OPEN' && pr.mergeable === 'MERGEABLE' && pr.mergeStateStatus === 'CLEAN' && pr.baseRefOid === r.refs.base, 'pr_not_ready');
    const remote = git('ls-remote', 'origin', `refs/heads/${r.pr.branch}`).split(/\s+/)[0];
    requireThat(remote === r.refs.fix && git('ls-remote', 'origin', 'refs/heads/main').split(/\s+/)[0] === r.refs.base, 'remote_head_mismatch');
    requireThat(git('ls-remote', 'origin', `refs/pull/${r.pr.number}/merge`).split(/\s+/)[0] === r.refs.synthetic, 'synthetic_mismatch');
  }
  return repo;
}
function checkoutIdentity(log, expected) {
  requireThat(log.split('\n').some((line, i, lines) => line.includes('git log -1 --format=%H') && lines.slice(i + 1, i + 4).some(next => next.trim().endsWith(expected))), 'ci_checkout_mismatch');
}

function tap(output, required) {
  const successes = new Set();
  const failures = output.match(/^\s*not ok \d+ /gm) || [];
  for (const match of output.matchAll(/^\s*ok \d+ - (.+)$/gm)) if (!/\s#\s*(SKIP|TODO)\b/i.test(match[1])) successes.add(match[1].replace(/\s+#.*$/, ''));
  const count = /^# tests (\d+)$/m.exec(output);
  const passed = /^# pass (\d+)$/m.exec(output);
  const failed = /^# fail (\d+)$/m.exec(output);
  const skipped = /^# skipped (\d+)$/m.exec(output);
  requireThat(count && passed && failed && skipped && +count[1] > 0 && +passed[1] === +count[1] && +failed[1] === 0 && +skipped[1] === 0 && failures.length === 0, 'tap_floor');
  requireThat(required.every(name => successes.has(name)), 'tap_family_missing');
  return { tests: +count[1], cases: successes.size };
}
function metricLabels(source) {
  const labels = new Set(['plain_baseline']);
  for (const family of ['token', 'authorization', 'cookie', 'generic', 'secret_access_key'])
    for (const whitespace of ['space', 'tab', 'mixed']) for (const size of [10000, 20000, 40000, 200000]) labels.add(`${family}/${whitespace}/${size}`);
  for (const head of ['token', 'Authorization', 'Cookie', 'password', 'SecretAccessKey'])
    for (const separator of [':', '=', '=>', '==', '===']) for (const whitespace of ['space', 'tab', 'mixed'])
      labels.add(`separator/${head}/${separator.length}/${separator === '=>' ? 'arrow' : separator === ':' ? 'colon' : 'equals'}/${whitespace}`);
  const block = name => new RegExp(`const ${name} = \\[([\\s\\S]*?)\\n\\];`).exec(source)?.[1] || '';
  for (const match of block('LINEAR_INPUTS').matchAll(/name: "([a-z0-9_]+)"/g)) labels.add(match[1]);
  for (const name of ['RULE_ADVERSARIES', 'RESIDUAL_RULE_ADVERSARIES'])
    for (const match of block(name).matchAll(/^\s*\["([a-z0-9_]+)"/gm)) labels.add(`${name === 'RULE_ADVERSARIES' ? 'rule' : 'residual'}/${match[1]}`);
  for (const match of source.matchAll(/label: "((?:armor|review)\/[a-z_-]+)"/g)) labels.add(match[1]);
  requireThat(labels.size >= 202, 'timing_source_floor');
  return labels;
}
function metrics(output, allowed) {
  const rows = [];
  for (const match of output.matchAll(/# perf-row ([A-Za-z0-9_\/-]+) length (\d+) baseline ([\d.]+) candidate ([\d.]+) bound ([\d.]+) ms/g)) {
    const row = { label: match[1], length: +match[2], baselineMs: +match[3], candidateMs: +match[4], boundMs: +match[5] };
    requireThat(allowed.has(row.label), 'timing_unknown_label');
    requireThat(Object.values(row).slice(1).every(value => Number.isFinite(value) && value >= 0) && row.candidateMs <= row.boundMs + 0.002 && row.boundMs >= 250, 'timing_invalid'); rows.push(row);
  }
  requireThat(rows.length >= 202, 'timing_floor');
  requireThat(new Set(rows.map(row => row.label)).size === rows.length && [...allowed].every(label => rows.some(row => row.label === label)), 'timing_family_missing');
  return rows;
}
function controls(value) {
  exact(value, [...CONTROL_KEYS, 'maskedLeaks']);
  for (const key of CONTROL_KEYS) integer(value[key], 1);
  requireThat(value.maskedLeaks === 0, 'masked_leak');
  return value;
}
function clean() { requireThat(git('status', '--porcelain=v1', '--untracked-files=no') === '', 'tracked_dirty'); }
function inventory() { return git('ls-files', '--others', '-z').split('\0').filter(Boolean).sort(); }
function snapshot(paths) {
  return paths.map(name => {
    requireThat(!path.isAbsolute(name) && !name.split('/').includes('..'), 'untracked_unsafe');
    const stat = lstatSync(name);
    requireThat(stat.isFile() || stat.isSymbolicLink(), 'untracked_unsafe');
    let hash;
    if (stat.isSymbolicLink()) hash = digest(readlinkSync(name));
    else {
      const fd = openSync(name, 'r'), hasher = createHash('sha256'), chunk = Buffer.alloc(65536);
      try { let bytes; while ((bytes = readSync(fd, chunk, 0, chunk.length, null)) > 0) hasher.update(chunk.subarray(0, bytes)); hash = hasher.digest('hex'); }
      finally { closeSync(fd); }
    }
    return [name, stat.isSymbolicLink() ? 'symlink' : 'file', hash, stat.mode & 0o777];
  });
}
function sameInventory(expected) {
  requireThat(JSON.stringify(snapshot(inventory())) === JSON.stringify(expected), 'untracked_changed');
}
function checkMainSnapshot(expected, actual) {
  requireThat(actual.clean && actual.detached && actual.head === expected.main && actual.origin === expected.main, 'main_changed');
  requireThat(actual.blobs.length === 2 && actual.disk.length === 2 && expected.blobs.every((blob, i) => actual.blobs[i] === blob && actual.disk[i] === blob), 'source_blob_mismatch');
}
function mainIdentity(expected) {
  checkMainSnapshot(expected, { clean: git('status', '--porcelain=v1', '--untracked-files=no') === '',
    detached: git('rev-parse', '--abbrev-ref', 'HEAD') === 'HEAD',
    head: git('rev-parse', 'HEAD'), origin: git('rev-parse', 'origin/main'),
    blobs: SOURCE.map(name => git('rev-parse', `HEAD:${name}`)), disk: SOURCE.map(name => git('hash-object', name)) });
}
function harnessSource(source, root, productionUrl) {
  const transformed = source.replace('import { test } from "node:test";', 'const registered = []; const test = name => registered.push(name);')
    .replace('from "../../script/verify_repository.mjs"', `from ${JSON.stringify(productionUrl)}`)
    .replace(/const repoRoot = [^;]+;/, `const repoRoot = ${JSON.stringify(root)};`);
  requireThat(transformed !== source && !transformed.includes('import { test } from "node:test";') && !transformed.includes('from "../../script/verify_repository.mjs"'), 'harness_export');
  return transformed + '\nexport { registered, RESIDUAL_FORMS, runRound3TailRows, assertRound3TailRows, round3InventoryRows, measureRound3Padding, MASK_PERF_CHILD, runDerivation, fireDrill };\n';
}
function registeredCases(ref) {
  const scratch = mkdtempSync(path.join(tmpdir(), 'gap3-register-'));
  try {
    const production = path.join(scratch, 'candidate.mjs'), harness = path.join(scratch, 'harness.mjs');
    writeFileSync(production, git('show', `${ref}:${SOURCE[0]}`), { mode: 0o400 });
    writeFileSync(harness, harnessSource(git('show', `${ref}:${SOURCE[1]}`), process.cwd(), pathToFileURL(production).href), { mode: 0o400 });
    const names = JSON.parse(run(process.execPath, ['--input-type=module', '-e', `import {registered} from ${JSON.stringify(pathToFileURL(harness).href)};process.stdout.write(JSON.stringify(registered));`]));
    requireThat(Array.isArray(names) && names.length >= 190 && names.every(name => typeof name === 'string') && new Set(names).size === names.length, 'registered_case_floor');
    return names;
  } finally { rmSync(scratch, { recursive: true, force: true }); }
}

function controlsSource(productionUrl) {
  return `
import assert from 'node:assert/strict';
import * as h from './harness.mjs';
import { maskSecretShapes as oldMask } from './pre-fix.mjs';
import { maskSecretShapes as mainMask } from ${JSON.stringify(productionUrl)};
const counts = { rawWindow: 0, identity: 0, preFix: 0, removedAddMask: 0, quadratic: 0 };
let maskedLeaks = 0;
assert.ok(h.RESIDUAL_FORMS.length >= 45 && h.round3InventoryRows().length > 0);
for (const row of h.RESIDUAL_FORMS) {
  const result = h.runRound3TailRows([row]); h.assertRound3TailRows(result, 'main');
  assert.ok(row.seeds.every(seed => result.rawTail.includes(seed))); counts.rawWindow++;
  maskedLeaks += row.seeds.filter(seed => result.tail.includes(seed) || mainMask(row.line()).includes(seed)).length;
  assert.throws(() => h.assertRound3TailRows({ ...result, tail: result.rawTail }, 'identity')); counts.identity++;
  if (row.seeds.some(seed => oldMask(row.line()).includes(seed))) counts.preFix++;
}
assert.ok(counts.preFix > 0);
assert.equal(maskedLeaks,0);
const user = ['fake','Gap3','User'].join(''); const pass = ['fake','Gap3','Pass'].join('');
const token = Buffer.from(user + ':' + pass).toString('base64');
const script = h.derivationScript(h.fireDrill(), ['TOKEN','AUTH']);
assert.ok(!h.runnerMaskedLog(h.runDerivation(script,user,pass),[user,pass]).includes(token));
const removed = script.split('\\n').filter(line => !line.includes('::add-mask::')).join('\\n');
assert.ok(h.runnerMaskedLog(h.runDerivation(removed,user,pass),[user,pass]).includes(token)); counts.removedAddMask++;
const quadratic = h.MASK_PERF_CHILD.replace('import { maskSecretShapes } from "./script/verify_repository.mjs";', 'const maskSecretShapes = text => /token:[ \\t]*[ \\t]*$/.test(text);');
assert.notEqual(quadratic,h.MASK_PERF_CHILD);
assert.throws(() => h.measureRound3Padding({label:'quadratic_copy',input:'token:'+' '.repeat(200000)+'x'},quadratic), /timed out|bound failed/); counts.quadratic++;
process.stdout.write(JSON.stringify({...counts,maskedLeaks}));
`;
}

// The only private continuation always executes real children. No mocked I/O parameter exists.
async function privateProof() {
  requireThat(process.env.CW_GAP3_PRIVATE && realpathSync(SELF).startsWith(`${realpathSync(tmpdir())}${path.sep}`), 'private_context');
  const state = JSON.parse(readFileSync(0, 'utf8'));
  exact(state, ['nonce', 'main', 'blobs', 'required', 'helperDigest']);
  requireThat(state.nonce === process.env.CW_GAP3_PRIVATE && digest(file(SELF)) === state.helperDigest, 'private_identity');
  sha(state.main); requireThat(state.blobs.length === 2, 'private_blobs');
  mainIdentity(state);
  const scratch = path.dirname(SELF);
  const testSource = file(SOURCE[1]).toString();
  const productionUrl = pathToFileURL(path.resolve(SOURCE[0])).href;
  const harness = harnessSource(testSource, process.cwd(), productionUrl);
  writeFileSync(path.join(scratch, 'harness.mjs'), harness, { mode: 0o400 });
  const registered = JSON.parse(run(process.execPath, ['--input-type=module', '-e', `import { registered } from ${JSON.stringify(pathToFileURL(path.join(scratch, 'harness.mjs')).href)}; process.stdout.write(JSON.stringify(registered));`]));
  requireThat(Array.isArray(registered) && registered.length >= 190 && new Set(registered).size === registered.length && state.required.every(name => registered.includes(name)), 'registered_case_floor');
  const quickOutput = run(process.execPath, ['--test', '--test-reporter=tap', SOURCE[1]], { timeout: 180000 });
  const quick = tap(quickOutput, registered);
  const timing = metrics(quickOutput, metricLabels(file(SOURCE[1]).toString()));
  const census = /# live census references (\d+); aliases (\d+); derived (\d+); violations (\d+)/.exec(quickOutput);
  requireThat(census && +census[1] > 0 && +census[2] > 0 && +census[3] > 0 && +census[4] === 0, 'workflow_census_missing');
  const workflow = { references: +census[1], aliases: +census[2], derived: +census[3], violations: +census[4] };
  const fullFiles = readdirSync('test/js').filter(name => name.endsWith('.mjs')).sort().map(name => `test/js/${name}`);
  requireThat(fullFiles.length > 1, 'suite_floor');
  const full = tap(run(process.execPath, ['--test', '--test-reporter=tap', ...fullFiles], { timeout: 240000 }), registered);
  requireThat(full.tests > quick.tests, 'suite_floor');
  // Copies preserve actual-main imports and never modify tracked source.
  writeFileSync(path.join(scratch, 'pre-fix.mjs'), git('show', `${PRE_FIX}:${SOURCE[0]}`), { mode: 0o400 });
  const code = controlsSource(productionUrl);
  writeFileSync(path.join(scratch, 'controls.mjs'), code, { mode: 0o400 });
  const verdicts = controls(JSON.parse(run(process.execPath, [path.join(scratch, 'controls.mjs')], { timeout: 90000 })));
  mainIdentity(state);
  process.stdout.write(JSON.stringify({ quick, full, timing, workflow, controls: verdicts }));
}

function landed(r) {
  live(r, true); clean();
  const docsRef = git('symbolic-ref', '--short', 'HEAD');
  requireThat(docsRef === 'docs/195-closeout', 'docs_ref_required');
  const docsSha = git('rev-parse', 'HEAD');
  const expectedInventory = snapshot(inventory());
  const covered = name => r.safeUntracked.some(entry => entry.endsWith('/') ? name.startsWith(entry) : name === entry);
  requireThat(expectedInventory.every(row => covered(row[0])) && r.safeUntracked.every(entry => expectedInventory.some(row => entry.endsWith('/') ? row[0].startsWith(entry) : row[0] === entry)), 'untracked_not_listed');
  run('git', ['fetch', 'origin', 'main']);
  const main = git('rev-parse', 'origin/main');
  requireThat(main === r.refs.main, 'main_receipt_mismatch');
  requireThat(git('merge-base', r.refs.merge, main) === r.refs.merge, 'merge_not_on_main');
  const parents = git('rev-list', '--parents', '-n', '1', r.refs.merge).split(' ').slice(1);
  requireThat(parents.length === 2 && parents[0] === r.refs.base && parents[1] === r.refs.fix, 'merge_parents');
  const blobs = SOURCE.map(name => git('rev-parse', `${main}:${name}`));
  requireThat(blobs.every((blob, i) => blob === git('rev-parse', `${r.refs.fix}:${SOURCE[i]}`)), 'main_source_changed');
  for (const tree of [main, docsSha]) {
    const tracked = git('ls-tree', '-r', '--name-only', tree).split('\n');
    const ancestors = new Set();
    for (const name of tracked) { const parts = name.split('/'); for (let i = 1; i <= parts.length; i++) ancestors.add(parts.slice(0, i).join('/')); }
    const trackedSet = new Set(tracked);
    for (const [name] of expectedInventory) {
      requireThat(!ancestors.has(name), 'untracked_collision');
      const parts = name.split('/');
      for (let i = 1; i < parts.length; i++) requireThat(!trackedSet.has(parts.slice(0, i).join('/')), 'untracked_collision');
    }
  }
  requireThat(git('merge-base', main, docsSha) === main, 'docs_not_reconciled');
  const scratch = mkdtempSync(path.join(tmpdir(), 'gap3-proof-'));
  const copy = path.join(scratch, 'proof.mjs');
  writeFileSync(copy, file(SELF), { mode: 0o400 }); chmodSync(copy, 0o400);
  const helperDigest = digest(file(SELF));
  const nonce = randomBytes(32).toString('hex');
  let switched = false; let result; let failure;
  try {
    clean(); sameInventory(expectedInventory);
    run('git', ['switch', '--detach', main]); switched = true;
    const state = { nonce, main, blobs, required: requiredCases(r), helperDigest };
    mainIdentity(state);
    result = JSON.parse(run(process.execPath, [copy, '--_proof', '--ws', WS], {
      input: JSON.stringify(state), timeout: 600000,
      env: { PATH: process.env.PATH, HOME: process.env.HOME, CW_GAP3_PRIVATE: nonce }
    }));
    exact(result, ['quick', 'full', 'timing', 'workflow', 'controls']); controls(result.controls);
    mainIdentity(state); sameInventory(expectedInventory);
    run('git', ['fetch', 'origin', 'main']);
    requireThat(git('rev-parse', 'origin/main') === main && git('ls-remote', 'origin', 'refs/heads/main').split(/\s+/)[0] === main, 'main_changed');
    requireThat(digest(file(copy)) === helperDigest, 'helper_changed');
  } catch (e) { failure = e; }
  finally {
    if (switched) {
      try {
        clean(); sameInventory(expectedInventory);
        requireThat(git('rev-parse', docsRef) === docsSha && git('rev-parse', 'HEAD') === main, 'restoration_identity');
        run('git', ['switch', docsRef]);
        clean(); sameInventory(expectedInventory);
        requireThat(git('rev-parse', 'HEAD') === docsSha && digest(file(SELF)) === helperDigest, 'restoration_identity');
      } catch { failure = new Error('restoration_blocked'); }
    }
    rmSync(scratch, { recursive: true, force: true });
  }
  if (failure) throw failure;
  requireThat(realpathSync(path.dirname(PROOF)) === path.resolve(path.dirname(PROOF)) && (!existsSync(PROOF) || (lstatSync(PROOF).isFile() && !lstatSync(PROOF).isSymbolicLink())), 'proof_path_unsafe');
  // This object is constructed only after actual children and successful restoration.
  const output = { version: 1, ws: WS, requirement: 'REL-03', verdict: 'pass', main, merge: r.refs.merge,
    fix: r.refs.fix, blobs, helperDigest, receiptDigest: digest(file(RECEIPT)), reviewDigest: r.review.sha256,
    invocation: randomBytes(16).toString('hex'), executedAt: new Date().toISOString(), ...result };
  writeFileSync(PROOF, `${JSON.stringify(output, null, 2)}\n`, { mode: 0o600 });
  return { verdict: 'pass', tests: result.full.tests, controls: CONTROL_KEYS.length };
}

function selfTest() {
  let passed = 0;
  const reject = fn => { assert.throws(fn); passed++; };
  const hash = 'a'.repeat(40), base = 'b'.repeat(40), synthetic = 'c'.repeat(40);
  const r = { version: 1, ws: WS, requirement: 'REL-03', status: 'candidate',
    refs: { base, fix: hash, reviewed: hash, pr: hash, synthetic, merge: null, main: null, docs: base },
    pr: { number: 1, branch: 'fix/example', base: 'main', runId: 1, runHead: hash, deleteBranchOnMerge: true },
    review: { sha256: 'd'.repeat(64), head: hash, openHigh: 0, openCritical: 0, rows: FINDINGS.map(id => ({ id, status: 'fixed', cases: [FAMILIES[0]], receiver: null })), decisions: [] },
    privacy: { head: hash, status: 'pass', sha256: 'd'.repeat(64), path: `${PHASE}/195-EVIDENCE/privacy.txt` },
    approvals: { attempt: 'e'.repeat(32), displayedAt: new Date().toISOString(), prNumber: 1, branch: 'fix/example', deleteBranchOnMerge: true, head: hash, base, synthetic, runId: 1, merge: { answer: 'allow', consumed: false }, deletion: { answer: 'allow', consumed: false } },
    delivery: { status: 'not-attempted', merge: null, head: hash, autoDeleted: false }, safeUntracked: [] };
  schema(r); identity(r); permission(r); passed++;
  const altered = fn => { const copy = structuredClone(r); fn(copy); return copy; };
  for (const mutate of [x => { x.proof = { verdict: 'pass' }; }, x => { x.ws = 'other'; }, x => { x.refs.fix = '/private/path'; },
    x => { x.review.rows.pop(); }, x => { x.review.rows[0].receiver = 'new'; }, x => { x.review.decisions.push('accepted'); },
    x => { x.safeUntracked.push('../unsafe'); }, x => { x.pr.unknown = 'raw'; }, x => { x.review.rows[0].cases = []; }]) reject(() => schema(altered(mutate)));
  for (const mutate of [x => { x.refs.reviewed = base; }, x => { x.refs.synthetic = hash; }, x => { x.pr.runHead = base; }, x => { x.review.openHigh = 1; }, x => { x.privacy.head = base; }]) reject(() => identity(altered(mutate)));
  for (const mutate of [x => { x.approvals = null; }, x => { x.approvals.head = base; }, x => { x.approvals.base = hash; },
    x => { x.approvals.synthetic = hash; }, x => { x.approvals.runId = 2; }, x => { x.approvals.prNumber = 2; }, x => { x.approvals.branch = 'fix/other'; },
    x => { x.approvals.deleteBranchOnMerge = false; }, x => { x.approvals.merge.answer = 'hold'; },
    x => { x.approvals.merge.consumed = true; }, x => { x.approvals.deletion.answer = 'hold'; }, x => { x.approvals.deletion.consumed = true; },
    x => { x.approvals.displayedAt = new Date(Date.now() - 3600000).toISOString(); }]) reject(() => permission(altered(mutate)));
  const report = names => names.map((name, index) => `ok ${index + 1} - ${name}`).join('\n') + `\n# tests ${names.length}\n# pass ${names.length}\n# fail 0\n# skipped 0\n`;
  tap(report(FAMILIES), FAMILIES); passed++;
  reject(() => tap(report([]), FAMILIES));
  for (const name of FAMILIES) reject(() => tap(report([...FAMILIES.filter(item => item !== name), 'old successful test']), FAMILIES));
  reject(() => tap(report(FAMILIES).replace(`- ${FAMILIES[0]}`, `- ${FAMILIES[0]} # SKIP`), FAMILIES));
  for (const key of CONTROL_KEYS) reject(() => controls({ maskedLeaks: 0, ...Object.fromEntries(CONTROL_KEYS.filter(item => item !== key).map(item => [item, 1])) }));
  reject(() => controls({ maskedLeaks: 0, ...Object.fromEntries(CONTROL_KEYS.map(key => [key, 0])) }));
  reject(() => controls({ maskedLeaks: 1, ...Object.fromEntries(CONTROL_KEYS.map(key => [key, 1])) }));
  reject(() => processResult({ status: 1, stdout: 'green' }, 'child_failed'));
  reject(() => processResult({ status: null, error: { code: 'ETIMEDOUT' } }, 'child_failed'));
  reject(() => processResult({ status: 0, stdout: 'x'.repeat(MAX + 1) }, 'child_failed'));
  checkoutIdentity(`checkout\tgit log -1 --format=%H\ncheckout\t${synthetic}`, synthetic); passed++;
  reject(() => checkoutIdentity(`checkout\tgit log -1 --format=%H\ncheckout\t${hash}`, synthetic));
  reject(() => checkoutIdentity(`unrelated ${synthetic}`, synthetic));
  // Pure identity predicates below are also called by the actual detached-main guard.
  const expected = { main: hash, blobs: ['blob1', 'blob2'] };
  const actual = { clean: true, detached: true, head: hash, origin: hash, blobs: ['blob1', 'blob2'], disk: ['blob1', 'blob2'] };
  checkMainSnapshot(expected, actual); passed++;
  for (const override of [{ clean: false }, { detached: false }, { head: base }, { origin: base }, { blobs: ['wrong', 'blob2'] }, { disk: ['blob1', 'wrong'] }])
    reject(() => checkMainSnapshot(expected, { ...actual, ...override }));
  reject(() => metrics('old successful tests', new Set()));
  reject(() => metrics('# perf-row private_label length 1 baseline 1 candidate 1 bound 250 ms', new Set()));
  reject(() => run(process.execPath, ['-e', 'process.exit(1)']));
  reject(() => run(process.execPath, ['-e', 'setInterval(()=>{},1000)'], { timeout: 100 }));
  // Real scratch smoke test exercises the same exporter, actual candidate module, and
  // exported workflow emulator without detaching or producing a main-proof artifact.
  // Phase artifacts live on docs, whose production tree intentionally precedes the fix.
  const candidateRef = git('rev-parse', 'refs/heads/fix/secret-mask-structural');
  const scratch = mkdtempSync(path.join(tmpdir(), 'gap3-selftest-'));
  try {
    const source = git('show', `${candidateRef}:${SOURCE[1]}`);
    writeFileSync(path.join(scratch, 'candidate.mjs'), git('show', `${candidateRef}:${SOURCE[0]}`));
    writeFileSync(path.join(scratch, 'harness.mjs'), harnessSource(source, process.cwd(), pathToFileURL(path.join(scratch, 'candidate.mjs')).href));
    const smoke = `import assert from 'node:assert/strict'; import * as h from ${JSON.stringify(pathToFileURL(path.join(scratch, 'harness.mjs')).href)};
      assert.ok(h.registered.length >= 181 && h.RESIDUAL_FORMS.length >= 45 && h.round3InventoryRows().length > 0);
      assert.equal(typeof h.runDerivation,'function'); const script=h.derivationScript(h.fireDrill(),['TOKEN','AUTH']);
      const u=['fake','Smoke','User'].join(''),p=['fake','Smoke','Pass'].join(''),v=Buffer.from(u+':'+p).toString('base64');
      assert.ok(!h.runnerMaskedLog(h.runDerivation(script,u,p),[u,p]).includes(v));
      const removed=script.split('\\n').filter(line=>!line.includes('::add-mask::')).join('\\n');
      assert.ok(h.runnerMaskedLog(h.runDerivation(removed,u,p),[u,p]).includes(v)); process.stdout.write('ok');`;
    requireThat(run(process.execPath, ['--input-type=module', '-e', smoke]).trim() === 'ok', 'harness_smoke');
    writeFileSync(path.join(scratch, 'pre-fix.mjs'), git('show', `${PRE_FIX}:${SOURCE[0]}`));
    writeFileSync(path.join(scratch, 'controls.mjs'), controlsSource(pathToFileURL(path.join(scratch, 'candidate.mjs')).href));
    controls(JSON.parse(run(process.execPath, [path.join(scratch, 'controls.mjs')], { timeout: 15000 }))); passed++;
    const labels = metricLabels(source); requireThat(labels.size >= 202, 'timing_source_floor'); passed++;
  } finally { rmSync(scratch, { recursive: true, force: true }); }
  return { verdict: 'pass', selfTests: passed };
}

try {
  const args = process.argv.slice(2);
  requireThat(args.length === 3 && args[1] === '--ws' && args[2] === WS, 'arguments_invalid');
  const mode = args[0];
  if (mode === '--self-test') process.stdout.write(`${JSON.stringify(selfTest())}\n`);
  else if (mode === '--_proof') await privateProof();
  else {
    requireThat(['candidate', 'gate', 'landed'].includes(mode), 'mode_invalid');
    requireThat(realpathSync(process.cwd()) === git('rev-parse', '--show-toplevel'), 'repository_root_required');
    const receipt = readReceipt();
    if (mode === 'landed') process.stdout.write(`${JSON.stringify(landed(receipt))}\n`);
    else { live(receipt); if (mode === 'gate') permission(receipt); process.stdout.write(`${JSON.stringify({ verdict: 'pass', mode })}\n`); }
  }
} catch (error) {
  // Never forward subprocess output, arbitrary exception messages, paths, or payloads.
  const label = /^[a-z_]{1,60}$/.test(error.message) ? error.message : 'verification_failed';
  process.stderr.write(`${JSON.stringify({ verdict: 'fail', label })}\n`); process.exitCode = 1;
}
