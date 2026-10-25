import { readFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../../../../../../');
const paths = {
  project: '.planning/PROJECT.md',
  handoff: '.planning/workstreams/quality-ratchet-release/.continue-here.md',
  state: '.planning/workstreams/quality-ratchet-release/STATE.md',
  roadmap: '.planning/workstreams/quality-ratchet-release/ROADMAP.md',
  verification: '.planning/workstreams/quality-ratchet-release/phases/177-maintenance-and-queue-reconciliation/177-VERIFICATION.md',
  archive: '.planning/workstreams/quality-ratchet-release/milestones/v23.0-phases/175-rehearsal-and-publish/175-VERIFICATION.md',
  requirements: '.planning/workstreams/quality-ratchet-release/milestones/v23.0-REQUIREMENTS.md',
  adopter: '.planning/workstreams/first-b2c-adopter-readiness/STATE.md',
};

const commandFor = {
  177: '$gsd-execute-phase 177 --ws quality-ratchet-release',
  178: '$gsd-discuss-phase 178 --ws quality-ratchet-release',
};

async function read(root, relativePath) {
  return readFile(resolve(root, relativePath), 'utf8');
}

function requireText(errors, text, pattern, description) {
  if (!pattern.test(text)) errors.push(description);
}

function section(text, heading, nextHeading) {
  const start = text.indexOf(heading);
  if (start < 0) return '';
  const end = nextHeading ? text.indexOf(nextHeading, start + heading.length) : -1;
  return text.slice(start, end < 0 ? undefined : end);
}

function checkLink(errors, sourceFile, text, targetPath, root) {
  const match = [...text.matchAll(/\[[^\]]+\]\(([^)]+\.md)\)/g)]
    .find(([, link]) => resolve(root, dirname(sourceFile), link) === resolve(root, targetPath));
  if (!match) errors.push(`${sourceFile} must link to ${targetPath}`);
}

function exactAction(text, nextHeading) {
  const actionSection = section(text, '## Exact Next Action', nextHeading);
  return [...actionSection.matchAll(/`(\$gsd-[^`]+)`/g)].map(([, command]) => command);
}

function activeMode(errors, state, roadmap, verification) {
  const currentPhase = Number(state.match(/^current_phase:\s*(\d+)\s*$/m)?.[1]);
  const lastCompleted = Number(state.match(/^last_completed_phase:\s*(\d+)\s*$/m)?.[1]);
  const status = state.match(/^status:\s*(.+)$/m)?.[1] ?? '';
  const currentPlan = Number(state.match(/^current_plan:\s*(\d+)\s*$/m)?.[1]);
  const stateAction = exactAction(state, '## Project Reference');
  const roadmapAction = exactAction(roadmap);
  if (stateAction.length !== 1) errors.push(`STATE must contain one exact next action; found ${stateAction.length}`);
  if (roadmapAction.length !== 1) errors.push(`ROADMAP must contain one exact next action; found ${roadmapAction.length}`);
  if (stateAction.length !== 1 || roadmapAction.length !== 1 || stateAction[0] !== roadmapAction[0]) {
    errors.push('STATE and ROADMAP exact next actions must agree without competing commands');
  }

  const expected = commandFor[currentPhase];
  if (!expected) {
    errors.push(`Unsupported active quality phase in STATE: ${currentPhase || 'missing'}`);
    return null;
  }
  if (stateAction.length === 1 && stateAction[0] !== expected) {
    errors.push(`STATE action does not match Phase ${currentPhase}: expected ${expected}`);
  }
  if (roadmapAction.length === 1 && roadmapAction[0] !== expected) {
    errors.push(`ROADMAP action does not match Phase ${currentPhase}: expected ${expected}`);
  }

  const phase177Complete = /\|\s*177\. Maintenance and Queue Reconciliation\s*\|\s*8\/8\s*\|\s*Complete\s*\|/i.test(roadmap);
  if (currentPhase === 177) {
    if (lastCompleted !== 176) errors.push('Phase 177 handoff requires Phase 176 as the last completed phase');
    if (!/verification in progress|ready to execute/i.test(status)) errors.push('Phase 177 STATE status must describe active execution or verification');
    if (phase177Complete) errors.push('STATE still points to Phase 177 although ROADMAP marks it complete');
    if (/\|\s*177\. Maintenance and Queue Reconciliation\s*\|[^\n]*\|\s*Complete\s*\|/i.test(roadmap)) {
      errors.push('Phase 177 cannot be marked complete while STATE still points to it');
    }
    return 177;
  }

  if (lastCompleted !== 177) errors.push('Phase 178 requires Phase 177 to be recorded as last completed');
  if (!/awaiting discussion|ready for discussion/i.test(status) || currentPlan !== 0) {
    errors.push('Phase 178 handoff requires an awaiting-discussion status with no active plan');
  }
  if (!phase177Complete) errors.push('Phase 178 requires ROADMAP to record Phase 177 complete');
  if (!/status:\s*passed\b/i.test(verification) || !/score:\s*27\/27/i.test(verification)) {
    errors.push('Phase 178 requires the passed 27/27 Phase 177 verification report');
  }
  if (!/\|\s*178\. Clean Checkout and Final CI\s*\|\s*0\/TBD\s*\|\s*Not started\s*\|/i.test(roadmap)) {
    errors.push('Phase 178 must remain not started while its discussion is next');
  }
  return 178;
}

function expectedActiveCopy(mode) {
  if (mode === 177) return {
    stage: /Phase 177[\s\S]*verification in progress/i,
    continue: /Phase 177[\s\S]*verification in progress/i,
    active: /Phase 177 verification is in progress[\s\S]*MAINT-07\/08 remain assigned to Phase 178/i,
  };
  if (mode === 178) return {
    stage: /Phase 177 is complete[\s\S]*Phase 178 is awaiting discussion/i,
    continue: /Phase 177 is complete[\s\S]*Phase 178 is awaiting discussion/i,
    active: /Phase 177 validated MAINT-03, MAINT-05, and MAINT-06[\s\S]*Phase 178 is awaiting discussion[\s\S]*MAINT-07\/08/i,
  };
  return null;
}

export async function checkGuidance(root = repoRoot) {
  const errors = [];
  const [project, handoff, state, roadmap, verification, archive, requirements, adopter] = await Promise.all([
    read(root, paths.project), read(root, paths.handoff), read(root, paths.state),
    read(root, paths.roadmap), read(root, paths.verification), read(root, paths.archive),
    read(root, paths.requirements), read(root, paths.adopter),
  ]);

  const projectNextGoals = section(project, '## Next Milestone Goals', '## Earlier Shipped Milestone');
  const currentState = section(project, '## Current State', '##');
  const workstreams = section(project, '## Active Workstreams', '## Current State');
  const activeRequirements = section(project, '### Active', '<details>');
  const mode = activeMode(errors, state, roadmap, verification);
  const expected = expectedActiveCopy(mode);
  const stateNext = section(state, '## Exact Next Action', '## Project Reference');

  requireText(errors, projectNextGoals, /v24\.0[\s\S]*Phase 177[\s\S]*Phase 178/, 'PROJECT next milestone guidance must distinguish Phase 177 maintenance from Phase 178 proof');
  requireText(errors, project, /\[STATE\]\(workstreams\/quality-ratchet-release\/STATE\.md\)/, 'PROJECT must link to the quality workstream STATE');
  requireText(errors, project, /\[ROADMAP\]\(workstreams\/quality-ratchet-release\/ROADMAP\.md\)/, 'PROJECT must link to the quality workstream ROADMAP');
  requireText(errors, handoff, /\[STATE\.md\]\(STATE\.md\)/, 'continue-here must defer the exact command to STATE.md');
  requireText(errors, handoff, /\[ROADMAP\.md\]\(ROADMAP\.md\)/, 'continue-here must link to ROADMAP.md');

  if (expected) {
    requireText(errors, workstreams, expected.stage, `PROJECT Active Workstreams must describe Phase ${mode} from STATE`);
    requireText(errors, currentState, mode === 177
      ? /v24\.0 — ACTIVE[\s\S]*Phase 177[\s\S]*verification in progress[\s\S]*Phase 178/
      : /v24\.0 — ACTIVE[\s\S]*Phase 177 is complete[\s\S]*Phase 178 is awaiting discussion/,
    `PROJECT Current State must describe Phase ${mode} from STATE`);
    requireText(errors, handoff, expected.continue, `continue-here must describe Phase ${mode} from STATE`);
    requireText(errors, activeRequirements, expected.active, `PROJECT Active requirements must describe Phase ${mode} ownership`);
  }

  const projectActiveText = `${projectNextGoals}\n${workstreams}\n${currentState}\n${activeRequirements}`;
  if (/\$gsd-/.test(projectActiveText)) errors.push('PROJECT active guidance duplicates a volatile command owned by STATE.md');
  if (/\$gsd-/.test(handoff)) errors.push('continue-here duplicates a volatile command owned by STATE.md');
  if (stateNext.match(/\$gsd-/g)?.length !== 1) errors.push('STATE exact next action must not contain duplicate commands');

  checkLink(errors, paths.project, project, paths.state, root);
  checkLink(errors, paths.project, project, paths.roadmap, root);
  for (const [label, text] of [['STATE.md', handoff], ['ROADMAP.md', handoff]]) {
    const match = [...text.matchAll(/\[[^\]]+\]\(([^)]+\.md)\)/g)]
      .find(([, link]) => link.endsWith(label));
    if (!match || resolve(root, dirname(paths.handoff), match[1]) !== resolve(root, '.planning/workstreams/quality-ratchet-release', label)) {
      errors.push(`continue-here ${label} link must resolve to this workstream`);
    }
  }

  requireText(errors, project, /Phase 175 retains 8\/9[\s\S]*REL-10/, 'PROJECT must preserve the archived Phase 175 8/9 and REL-10 result');
  requireText(errors, archive, /score_passed: 8[\s\S]*score_total: 9[\s\S]*REL-10: BREACHED/, 'Phase 175 verification must retain its 8/9 historical breach');
  requireText(errors, requirements, /42\/43 satisfied; REL-10 remains unchecked[\s\S]*?REL-10 remains unchecked\/BREACHED/, 'v23 requirements must retain the REL-10 historical exception');
  requireText(errors, adopter, /PARKED[\s\S]*TODO-002 remains open[\s\S]*source-bound signed-device run/, 'adopter workstream must retain its parked external gate');

  return { errors, mode };
}

if (process.argv.includes('--active')) {
  const { errors, mode } = await checkGuidance();
  if (errors.length) {
    console.error(`Active guidance check failed:\n- ${errors.join('\n- ')}`);
    process.exitCode = 1;
  } else {
    console.log(`Checked active Phase ${mode} pointers against STATE and ROADMAP, the Phase 178 boundary, archived Phase 175 verdict, and parked adopter gate. All checks passed. Unknown: Phase ${mode === 177 ? '177 delivery and queue results' : '178 final-source and CI results'} remain to be established. Next action: follow the exact command in the workstream STATE.md.`);
  }
}
