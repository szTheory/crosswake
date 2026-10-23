import test from 'node:test';
import assert from 'node:assert/strict';
import { cp, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkGuidance } from './check_active_guidance.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '../../../../../../');
const paths = [
  '.planning/PROJECT.md',
  '.planning/workstreams/quality-ratchet-release/.continue-here.md',
  '.planning/workstreams/quality-ratchet-release/STATE.md',
  '.planning/workstreams/quality-ratchet-release/ROADMAP.md',
  '.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-VERIFICATION.md',
  '.planning/workstreams/quality-ratchet-release/milestones/v23.0-phases/175-rehearsal-and-publish/175-VERIFICATION.md',
  '.planning/workstreams/quality-ratchet-release/milestones/v23.0-REQUIREMENTS.md',
  '.planning/workstreams/first-b2c-adopter-readiness/STATE.md',
];

async function fixture(t) {
  const dir = await mkdtemp(join(tmpdir(), 'crosswake-active-guidance-'));
  t.after(() => rm(dir, { recursive: true, force: true }));
  for (const path of paths) {
    const destination = join(dir, path);
    await mkdir(dirname(destination), { recursive: true });
    await cp(join(root, path), destination);
  }
  return dir;
}

async function replace(dir, path, from, to) {
  const target = join(dir, path);
  const content = await readFile(target, 'utf8');
  assert.ok(content.includes(from), `fixture must contain ${from}`);
  await writeFile(target, content.replaceAll(from, to));
}

async function phase177InProgress(dir) {
  const state = '.planning/workstreams/quality-ratchet-release/STATE.md';
  const roadmap = '.planning/workstreams/quality-ratchet-release/ROADMAP.md';
  const project = '.planning/PROJECT.md';
  const handoff = '.planning/workstreams/quality-ratchet-release/.continue-here.md';
  await replace(dir, state, 'current_phase: 178', 'current_phase: 177');
  await replace(dir, state, 'current_phase_name: Clean Checkout and Final CI', 'current_phase_name: Maintenance and Queue Reconciliation');
  await replace(dir, state, 'status: Phase 178 awaiting discussion', 'status: Phase 177 verification in progress');
  await replace(dir, state, 'stopped_at: Phase 177 complete; Phase 178 awaiting discussion', 'stopped_at: Phase 177 verification remains');
  await replace(dir, state, 'last_completed_phase: 177', 'last_completed_phase: 176');
  await replace(dir, state, '`$gsd-discuss-phase 178 --ws quality-ratchet-release`', '`$gsd-execute-phase 177 --ws quality-ratchet-release`');
  await replace(dir, state, 'Phase: 178 — Clean Checkout and Final CI', 'Phase: 177 (Maintenance and Queue Reconciliation) — VERIFICATION IN PROGRESS');
  await replace(dir, roadmap, '**Status:** Phases 176 and 177 complete; Phase 178 awaiting discussion.', '**Status:** Phase 176 complete; Phase 177 verification in progress.');
  await replace(dir, roadmap, '| 177. Maintenance and Queue Reconciliation | 8/8 | Complete    | 2026-10-12 |', '| 177. Maintenance and Queue Reconciliation | 8/8 | Verification in progress | — |');
  await replace(dir, roadmap, '`$gsd-discuss-phase 178 --ws quality-ratchet-release`', '`$gsd-execute-phase 177 --ws quality-ratchet-release`');
  await replace(dir, project, '**Current stage:** Phase 177 is complete; Phase 178 is awaiting discussion. MAINT-03, MAINT-05, and MAINT-06 were validated in Phase 177. Phase 178 owns exact final-source verification and hosted CI bound to that commit.', '**Current stage:** Phase 177 verification in progress; Phase 178 owns exact final-source verification and hosted CI bound to that commit.');
  await replace(dir, project, '**v24.0 — ACTIVE.** Phase 177 is complete; MAINT-03, MAINT-05, and MAINT-06 were validated. Phase 178 is awaiting discussion and owns exact clean-checkout verification and CI bound to that same final source commit.', '**v24.0 — ACTIVE.** Phase 177 verification in progress; Phase 178 owns exact clean-checkout verification and CI bound to that same final source commit.');
  await replace(dir, project, 'v24.0 Repository Cleanup & Maintenance is active. Phase 176 validated MAINT-01, MAINT-02, and MAINT-04; Phase 177 validated MAINT-03, MAINT-05, and MAINT-06. Phase 178 is awaiting discussion and owns MAINT-07/08: exact clean-checkout verification and CI bound to the same final source.', 'v24.0 Repository Cleanup & Maintenance is active. Phase 177 verification is in progress; MAINT-07/08 remain assigned to Phase 178.');
  await replace(dir, handoff, 'status: awaiting_discussion', 'status: ready_to_execute');
  await replace(dir, handoff, 'Phase 177 is complete, with MAINT-03, MAINT-05, and MAINT-06 validated. Phase 178 is awaiting discussion', 'Phase 177 verification in progress. Phase 178 owns');
  await replace(dir, handoff, 'The independent Phase 177 verification passed 27/27 must-haves.', 'Phase 177 verification and security repairs remain.');
  await replace(dir, handoff, 'Last fully passed release phase before the v23 archive: 174.', 'Last fully passed phase: 174.');
  const verification = '.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-VERIFICATION.md';
  await replace(dir, verification, 'status: passed', 'status: gaps_found');
  await replace(dir, verification, 'score: 27/27 must-haves verified', 'score: 26/27 must-haves verified');
}

test('current Phase 178 handoff passes only after Phase 177 completion is recorded', async (t) => {
  const dir = await fixture(t);
  const result = await checkGuidance(dir);
  assert.deepEqual(result.errors, []);
  assert.equal(result.mode, 178);
});

test('valid Phase 177 verification handoff passes while completion is pending', async (t) => {
  const dir = await fixture(t);
  await phase177InProgress(dir);
  const result = await checkGuidance(dir);
  assert.deepEqual(result.errors, []);
  assert.equal(result.mode, 177);
});

test('Phase 178 is rejected if the Phase 177 completion record is missing', async (t) => {
  const dir = await fixture(t);
  await replace(dir, '.planning/workstreams/quality-ratchet-release/STATE.md', 'last_completed_phase: 177', 'last_completed_phase: 176');
  const result = await checkGuidance(dir);
  assert.match(result.errors.join('\n'), /Phase 177 to be recorded as last completed/);
});

test('Phase 178 is rejected when the Phase 177 verification does not support completion', async (t) => {
  const dir = await fixture(t);
  const verification = '.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-VERIFICATION.md';
  await replace(dir, verification, 'status: passed', 'status: gaps_found');
  const result = await checkGuidance(dir);
  assert.match(result.errors.join('\n'), /passed 27\/27 Phase 177 verification/);
});

test('STATE and ROADMAP mismatch is rejected even when STATE names Phase 178', async (t) => {
  const dir = await fixture(t);
  await replace(dir, '.planning/workstreams/quality-ratchet-release/ROADMAP.md', '`$gsd-discuss-phase 178 --ws quality-ratchet-release`', '`$gsd-execute-phase 177 --ws quality-ratchet-release`');
  const result = await checkGuidance(dir);
  assert.match(result.errors.join('\n'), /STATE and ROADMAP exact next actions must agree/);
});

test('duplicate exact action in STATE is rejected', async (t) => {
  const dir = await fixture(t);
  await replace(
    dir,
    '.planning/workstreams/quality-ratchet-release/STATE.md',
    '## Project Reference',
    'Exact next command: `$gsd-discuss-phase 178 --ws quality-ratchet-release`\n\n## Project Reference',
  );
  const result = await checkGuidance(dir);
  assert.match(result.errors.join('\n'), /one exact next action|duplicate commands/);
});

test('softened Phase 175 REL-10 verdict is rejected', async (t) => {
  const dir = await fixture(t);
  await replace(
    dir,
    '.planning/workstreams/quality-ratchet-release/milestones/v23.0-phases/175-rehearsal-and-publish/175-VERIFICATION.md',
    'REL-10: BREACHED',
    'REL-10: SATISFIED',
  );
  const result = await checkGuidance(dir);
  assert.match(result.errors.join('\n'), /REL-10|8\/9|historical/i);
});

test('missing parked-adopter gate evidence is rejected', async (t) => {
  const dir = await fixture(t);
  await replace(
    dir,
    '.planning/workstreams/first-b2c-adopter-readiness/STATE.md',
    'TODO-002 remains open',
    'TODO-002 is complete',
  );
  const result = await checkGuidance(dir);
  assert.match(result.errors.join('\n'), /adopter|parked|external gate/i);
});
