#!/usr/bin/env node
// Phase-only verifier for Phase 196. Node built-ins only; no Muex, no network write, no merge in any scoped self-test.
// One file on purpose: the candidate identity hashes this whole file, so there is no partial-file carve-out.
// Verdicts are derived from committed git objects and real child processes, never from caller-authored values.
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, lstatSync, mkdtempSync, readFileSync, readdirSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const PHASE = ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet";
const WORKSTREAM = ".planning/workstreams/quality-ratchet-release";
const EVIDENCE = `${PHASE}/196-EVIDENCE`;
const SELF = `${PHASE}/scripts/phase-evidence.mjs`;
const MEASURE = `${PHASE}/scripts/measure-main.mjs`;
const ROADMAP = `${WORKSTREAM}/ROADMAP.md`;
const REQUIREMENTS = `${WORKSTREAM}/REQUIREMENTS.md`;
const OWNER_ROOT = realpathSync(path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../../.."));
// The commit that preserved the halted pilot evidence. Every roster path must equal its blob at this anchor.
const ANCHOR = "90a809ce43adec4fb2b04ae38e658854317c9d9c";
const ROSTER_COUNT = 32;
const IN_SCOPE = ["SPEC-01", "SPEC-02", "SPEC-03", "SPEC-05", "ARCH-01", "ARCH-02", "ARCH-03"];
const MOVED = "SPEC-04";
const RECEIVER = "v29.0";
const REQUIRED_STATEMENT = "SPEC-04 (Muex pilot) moved intact to v29.0 by recorded roadmap change; both attempts and the 5/5 accepted controls are preserved, and no adopt/drop verdict was made.";
const ROSTER_FIXED = [`${PHASE}/fixtures/muex-real-report.json`, `${PHASE}/scripts/muex-pilot.mjs`,
  `${PHASE}/196-13-SUMMARY.md`, `${PHASE}/196-14-SUMMARY.md`, `${PHASE}/196-14-PLAN.md`];

const sha = (bytes) => createHash("sha256").update(bytes).digest("hex");
const sorted = (xs) => [...xs].sort();
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
class Refusal extends Error { constructor(code, detail) { super(code); this.code = code; this.detail = detail; } }
function need(value, code, detail) { if (!value) throw new Refusal(code, detail); }
function rel(value) {
  need(typeof value === "string" && value.length > 0 && !path.isAbsolute(value) &&
    !value.split("/").some((part) => ["", ".", ".."].includes(part)) && !/[\r\n\t\0]/.test(value), "invalid_path");
  return value;
}

// ---------------------------------------------------------------- processes
function sync(root, command, args, options = {}) {
  const result = spawnSync(command, args, { cwd: root, encoding: "utf8", timeout: 60_000, maxBuffer: 64 * 1024 * 1024, ...options });
  if (result.error?.code === "ETIMEDOUT") throw new Refusal("child_timeout");
  need(!result.error && result.signal === null && Number.isInteger(result.status), "child_interrupted");
  return result;
}
function git(root, args, options = {}) {
  const result = sync(root, "git", args, options);
  need(result.status === 0, "git_command_failed");
  return options.encoding === null ? result.stdout : result.stdout.trimEnd();
}
function gitTry(root, args, options = {}) {
  const result = sync(root, "git", args, options);
  return result.status === 0 ? (options.encoding === null ? result.stdout : result.stdout.trimEnd()) : null;
}
function object(root, ref, name) {
  rel(name);
  const bytes = gitTry(root, ["show", `${ref}:${name}`], { encoding: null });
  need(bytes !== null, "source_object_missing");
  return bytes;
}
function worktree(root, name) {
  rel(name);
  const target = path.join(root, name);
  need(existsSync(target) && lstatSync(target).isFile(), "worktree_file_missing");
  return readFileSync(target);
}
function ref40(root, ref) {
  need(typeof ref === "string" && /^(?:HEAD|[A-Za-z0-9][A-Za-z0-9._/\-]*)$/.test(ref), "invalid_ref");
  const value = git(root, ["rev-parse", "--verify", `${ref}^{commit}`]);
  need(/^[0-9a-f]{40}$/.test(value), "invalid_commit");
  return value;
}
// Async child with its own process group: a deadline or a signal kills the whole group, and the
// result reports whether any member survived. Used for every candidate/landed child and by the self-tests.
function runChild(root, command, args, { env = {}, timeout = 600_000, maxBuffer = 256 * 1024 * 1024, cwd = root, inheritEnv = true } = {}) {
  return new Promise((resolve) => {
    const started = Date.now();
    let proc;
    try {
      proc = spawn(command, args, { cwd, detached: true, stdio: ["ignore", "pipe", "pipe"], env: { ...(inheritEnv ? process.env : {}), NO_COLOR: "1", ...env } });
    } catch { resolve({ status: null, signal: null, timedOut: false, startFailed: true, stdout: "", stderr: "", ms: 0, groupGone: true }); return; }
    let stdout = "", stderr = "", done = false, timedOut = false, overflow = false;
    const kill = () => { try { process.kill(-proc.pid, "SIGKILL"); } catch { /* group already gone */ } };
    const timer = setTimeout(() => { timedOut = true; kill(); }, timeout);
    const take = (which) => (bytes) => {
      if (which === "o") stdout += bytes; else stderr += bytes;
      if (stdout.length + stderr.length > maxBuffer && !overflow) { overflow = true; kill(); }
    };
    proc.stdout.on("data", take("o")); proc.stderr.on("data", take("e"));
    const finish = (status, signal, startFailed = false) => {
      if (done) return;
      done = true; clearTimeout(timer);
      let groupGone = true;
      try { process.kill(-proc.pid, 0); groupGone = false; } catch { groupGone = true; }
      if (!groupGone) { kill(); }
      resolve({ status, signal, timedOut, overflow, startFailed, stdout, stderr, ms: Date.now() - started, groupGone });
    };
    proc.on("error", () => finish(null, null, true));
    proc.on("close", (status, signal) => finish(status, signal));
  });
}

// ---------------------------------------------------------------- SPEC-04 claim scan
// Paragraph-scoped. Structured fields are authoritative; prose only refuses an affirmative claim.
const SCOPE_RE = /\b(?:SPEC-04|Muex|pilot)\b/i;
const VERB_RE = /\b(?:complete|completed|pass|passed|satisfied|adopt|adopted|drop|dropped|delivered)\b/i;
const MARK_RE = /\b(?:not|no|never|without|neither|nor|pending|moved)\b/i;
const NAMED_RE = /\b(?!SPEC-04\b)[A-Z]{2,6}-\d{2,3}\b/;
const sentencesOf = (text) => text.split(/(?<=[.!?])\s+|[;\n]/).map((s) => s.trim()).filter(Boolean);
const clausesOf = (sentence) => sentence.split(/,|\||\b(?:and|but|while)\b/i);
function sentenceRefuses(sentence) {
  return clausesOf(sentence).some((clause) => VERB_RE.test(clause) && !MARK_RE.test(clause));
}
// Markdown: blank-line blocks, each table row alone, each frontmatter line alone.
function markdownGroups(text) {
  const lines = text.split("\n");
  const out = [];
  let i = 0;
  if (lines[0] === "---") {
    const end = lines.indexOf("---", 1);
    if (end > 0) { for (let k = 1; k < end; k += 1) out.push(lines[k]); i = end + 1; }
  }
  let buffer = [];
  const flush = () => { if (buffer.length > 0) out.push(buffer.join("\n")); buffer = []; };
  for (; i < lines.length; i += 1) {
    if (lines[i].trim() === "") flush();
    else if (/^\s*\|/.test(lines[i])) { flush(); out.push(lines[i]); }
    else buffer.push(lines[i]);
  }
  flush();
  return [out];
}
// JSON: every string value is a paragraph; "directly following" means the next string among siblings.
function jsonGroups(value, groups = []) {
  const children = Array.isArray(value) ? value : value && typeof value === "object" ? Object.values(value) : [];
  groups.push(children.filter((child) => typeof child === "string"));
  for (const child of children) if (child && typeof child === "object") jsonGroups(child, groups);
  return groups;
}
function proseFindings(groups) {
  const findings = [];
  for (const group of groups) {
    group.forEach((paragraph, index) => {
      const inScope = SCOPE_RE.test(paragraph);
      const followsScope = index > 0 && SCOPE_RE.test(group[index - 1]);
      for (const sentence of sentencesOf(paragraph)) {
        const evaluate = inScope || (followsScope && !NAMED_RE.test(sentence));
        if (evaluate && sentenceRefuses(sentence)) findings.push(sentence.slice(0, 80));
      }
    });
  }
  return findings;
}
function structuredJson(value, trail = []) {
  if (Array.isArray(value)) {
    const key = trail[trail.length - 1] ?? "";
    if (/requirement/i.test(key) && !/moved/i.test(key)) need(!value.includes(MOVED), "spec04_in_requirements");
    value.forEach((item) => structuredJson(item, trail));
  } else if (value && typeof value === "object") {
    const key = trail[trail.length - 1] ?? "";
    if (/requirement/i.test(key) && !/moved/i.test(key)) need(!Object.hasOwn(value, MOVED), "spec04_in_requirements");
    if (Object.hasOwn(value, "spec04")) {
      const spec = value.spec04;
      need(spec && typeof spec === "object" && spec.disposition === "moved_to_v29", "spec04_disposition");
      for (const bad of ["pass", "passed", "fail", "failed", "drop", "dropped", "adopt", "adopted", "complete", "completed"]) {
        need(!Object.hasOwn(spec, bad), "spec04_disposition");
      }
    }
    for (const [name, child] of Object.entries(value)) structuredJson(child, [...trail, name]);
  }
}
function frontmatterOf(text) {
  const lines = text.split("\n");
  if (lines[0] !== "---") return [];
  const end = lines.indexOf("---", 1);
  return end > 0 ? lines.slice(1, end) : [];
}
function listField(lines, key) {
  const at = lines.findIndex((line) => line.startsWith(`${key}:`));
  if (at < 0) return null;
  const items = [];
  const inline = lines[at].slice(key.length + 1);
  items.push(...(inline.match(/[A-Z]{2,6}-\d{2,3}/g) ?? []));
  for (let k = at + 1; k < lines.length && /^\s+-\s/.test(lines[k]); k += 1) items.push(...(lines[k].match(/[A-Z]{2,6}-\d{2,3}/g) ?? []));
  return items;
}
// kind: "markdown" (plan/summary/review text) or "json" (evidence). Throws the first specific refusal.
function scanClaims(text, kind) {
  need(typeof text === "string", "claim_scan_input");
  if (kind === "json") {
    let value;
    try { value = JSON.parse(text); } catch { throw new Refusal("claim_scan_input"); }
    structuredJson(value);
    const findings = proseFindings(jsonGroups(value));
    need(findings.length === 0, "spec04_prose_claim", findings[0]);
    return { paragraphs: jsonGroups(value).flat().length };
  }
  const front = frontmatterOf(text);
  for (const key of ["requirements", "requirements-completed", "requirements_completed"]) {
    need(!(listField(front, key) ?? []).includes(MOVED), "spec04_in_requirements");
  }
  const groups = markdownGroups(text);
  const findings = proseFindings(groups);
  need(findings.length === 0, "spec04_prose_claim", findings[0]);
  return { paragraphs: groups[0].length };
}

// ---------------------------------------------------------------- preserved roster and disposition
function rosterPaths(root, ref) {
  const names = git(root, ["ls-tree", "-r", "--name-only", ref, "--", `${EVIDENCE}/`]).split("\n").filter(Boolean);
  const muex = names.filter((name) => /^(?:MUEX-|muex-)/.test(name.slice(EVIDENCE.length + 1)));
  const fixed = ROSTER_FIXED.filter((name) => gitTry(root, ["cat-file", "-e", `${ref}:${name}`]) !== null);
  return sorted([...muex, ...fixed]);
}
function rosterDigest(entries) {
  return sha(JSON.stringify(sorted(entries.map((e) => e.path)).map((p) => ({ path: p, sha256: entries.find((e) => e.path === p).anchor }))));
}
function loadRoster(root, ref) {
  const anchorPaths = rosterPaths(root, ANCHOR);
  const refPaths = rosterPaths(root, ref);
  const roster = anchorPaths.map((name) => ({
    path: name, anchor: sha(object(root, ANCHOR, name)),
    head: refPaths.includes(name) ? sha(object(root, ref, name)) : null,
    worktree: existsSync(path.join(root, name)) ? sha(worktree(root, name)) : null,
  }));
  const untracked = git(root, ["ls-files", "--others", "--exclude-standard", "--", EVIDENCE, `${PHASE}/fixtures`, `${PHASE}/scripts`])
    .split("\n").filter(Boolean).filter((name) => /(?:^|\/)(?:MUEX-|muex)/.test(name));
  const listing = (base) => (existsSync(base) ? readdirSync(base).sort() : []);
  return {
    roster, refPaths, untracked,
    baselineTracked: git(root, ["ls-tree", "-r", "--name-only", ref, "--", `${EVIDENCE}/muex-baseline/`]).split("\n").filter(Boolean).map((n) => path.basename(n)),
    baselineWorktree: listing(path.join(root, EVIDENCE, "muex-baseline")),
  };
}
function loadInputs(root, ref = "HEAD") {
  const text = (name) => object(root, ref, name).toString("utf8");
  const summaryNames = git(root, ["ls-tree", "--name-only", ref, `${PHASE}/`]).split("\n").filter((n) => /\/196-\d\d-SUMMARY\.md$/.test(n));
  return {
    ref, roadmap: text(ROADMAP), requirements: text(REQUIREMENTS),
    plans: Object.fromEntries([15, 16, 17].map((n) => [n, text(`${PHASE}/196-${n}-PLAN.md`)])),
    summaries: Object.fromEntries(summaryNames.map((n) => [path.basename(n), text(n)])),
    ...loadRoster(root, ref), registry: REGISTRY,
  };
}
function registryNamesMuex(registry) {
  return registry.some((entry) => /muex/i.test(JSON.stringify([entry.command, entry.args, entry.cwd])));
}
function checkStructured(inputs) {
  const { roadmap, requirements } = inputs;
  // ROADMAP: the Phase 196 Requirements line is exactly the seven IDs; the Moved line names SPEC-04 and v29.0.
  const section = roadmap.split(/^### Phase /m).find((part) => part.startsWith("196:"));
  need(section, "roadmap_requirements_line");
  const reqLine = section.split("\n").find((line) => line.startsWith("**Requirements**:"));
  need(reqLine && !reqLine.includes(MOVED) && same((reqLine.match(/[A-Z]{2,6}-\d{2,3}/g) ?? []), IN_SCOPE), "roadmap_requirements_line");
  const movedLine = section.split("\n").find((line) => line.startsWith("**Moved**:"));
  need(movedLine && movedLine.includes(MOVED) && movedLine.includes(RECEIVER), "roadmap_moved_missing");
  // REQUIREMENTS: unchecked SPEC-04 bullet with its moved note and the moved traceability row.
  const bullet = requirements.split("\n").find((line) => /^- \[.\] \*\*SPEC-04\*\*/.test(line));
  need(bullet, "spec04_checkbox_checked");
  need(/^- \[ \] /.test(bullet), "spec04_checkbox_checked");
  need(bullet.includes(`Moved intact to ${RECEIVER}`), "spec04_moved_note_missing");
  const rows = requirements.split("\n").filter((line) => /^\| SPEC-04 \|/.test(line));
  need(rows.length === 1 && rows[0] === `| SPEC-04 | ${RECEIVER} | Moved (criteria intact) |`, "spec04_traceability_status");
  // Plans 15-17 and every 196 SUMMARY must keep SPEC-04 out of their requirement lists.
  for (const [n, text] of Object.entries(inputs.plans)) {
    need(!(listField(frontmatterOf(text), "requirements") ?? []).includes(MOVED), "plan_requirements_list", n);
  }
  for (const [name, text] of Object.entries(inputs.summaries)) {
    need(!(listField(frontmatterOf(text), "requirements-completed") ?? []).includes(MOVED), "summary_requirements_completed", name);
  }
}
function checkRoster(inputs) {
  const { roster, refPaths, untracked, baselineTracked, baselineWorktree } = inputs;
  need(roster.length === ROSTER_COUNT && refPaths.length === ROSTER_COUNT, "roster_count");
  need(same(sorted(roster.map((e) => e.path)), sorted(refPaths)), "roster_count");
  for (const entry of roster) {
    need(entry.head === entry.anchor, "roster_byte_changed");
    need(entry.worktree === entry.anchor, "roster_worktree_changed");
  }
  need(untracked.length === 0, "roster_untracked");
  need(same(baselineTracked, ["result.json"]) && same(baselineWorktree, ["result.json"]), "muex_report_present");
  need(!registryNamesMuex(inputs.registry), "registry_muex_pilot");
}
function checkDisposition(inputs) {
  checkStructured(inputs);
  checkRoster(inputs);
  return {
    spec04: { disposition: "moved_to_v29", receiver: RECEIVER, anchor_commit: ANCHOR, roster_count: inputs.roster.length, roster_digest: rosterDigest(inputs.roster) },
  };
}
function sourceRoster(root, ref) {
  return git(root, ["ls-tree", "-r", ref]).split("\n").filter(Boolean).map((line) => {
    const match = /^(\d+) blob ([0-9a-f]{40})\t(.+)$/.exec(line);
    need(match && ["100644", "100755"].includes(match[1]), "unsupported_tree_entry");
    return { path: rel(match[3]), blob: match[2] };
  }).filter(({ path: p }) => !p.startsWith(".planning/"));
}
// Candidate identity: supported-source roster + whole-file hashes of both tools + preserved roster digest.
// Commits that touch only other .planning paths leave it unchanged; any tool or supported-source edit changes it.
function candidateIdentity(root, ref = "HEAD", { requireClean = true } = {}) {
  const roster = sourceRoster(root, ref);
  if (requireClean) {
    const changed = [...git(root, ["diff", "--name-only", "HEAD"]).split("\n"), ...git(root, ["diff", "--cached", "--name-only"]).split("\n")].filter(Boolean);
    need(changed.every((name) => name.startsWith(".planning/")), "dirty_supported_code");
  }
  const tool = (name) => {
    const committed = sha(object(root, ref, name));
    if (requireClean) need(sha(worktree(root, name)) === committed, "tool_not_committed");
    return committed;
  };
  const preserved = loadRoster(root, ref).roster;
  return {
    source_roster_sha256: sha(JSON.stringify(roster)), source_count: roster.length,
    phase_evidence_sha256: tool(SELF), measure_main_sha256: tool(MEASURE),
    preserved_roster_sha256: rosterDigest(preserved),
  };
}
function disposition(root, ref = "HEAD") {
  const verdict = checkDisposition(loadInputs(root, ref));
  return { ...verdict, candidate_identity: candidateIdentity(root, ref) };
}

// ---------------------------------------------------------------- candidate registry (completed in the candidate task)
const REGISTRY = [];

// ---------------------------------------------------------------- scoped self-tests
const DEADLINE_MS = 20_000;
async function realChildControls() {
  // A real tiny Node child for success, failure, timeout and cleanup. No Muex, no native build, no suite.
  const ok = await runChild(OWNER_ROOT, process.execPath, ["-e", "process.stdout.write('ok')"], { timeout: 5_000 });
  assert.equal(ok.status, 0); assert.equal(ok.stdout, "ok"); assert.equal(ok.groupGone, true);
  const bad = await runChild(OWNER_ROOT, process.execPath, ["-e", "process.exit(3)"], { timeout: 5_000 });
  assert.equal(bad.status, 3);
  const hang = await runChild(OWNER_ROOT, process.execPath, ["-e", "require('node:child_process').spawn(process.execPath,['-e','setInterval(()=>{},1000)'],{stdio:'ignore'});setInterval(()=>{},1000)"], { timeout: 400 });
  assert.equal(hang.timedOut, true); assert.equal(hang.status, null);
  await new Promise((resolve) => setTimeout(resolve, 100));
  assert.equal(hang.groupGone, true, "grandchild must not outlive the group");
}
const ACCEPTED_PROSE = [
  REQUIRED_STATEMENT,
  "SPEC-04 was not completed in v28.",
  `${REQUIRED_STATEMENT} SPEC-04 was not completed in v28.`,
  "The terminal baseline never completed, so no verdict was made and nothing was adopted or dropped.",
  "SPEC-04 is not complete.",
];
const REFUSED_PROSE = [
  "SPEC-04 is complete.",
  "SPEC-04 adopted for local advisory use.",
  "The Muex pilot passed.",
  "SPEC-04 dropped after the timeout.",
  "SPEC-04 is complete, moved to v29.",
  "SPEC-04 is complete and not pending.",
  "SPEC-04 moved to v29. It is complete.",
  "SPEC-04 moved to v29.0. It is complete.",
  "SPEC-04 is tracked for v29.0. The pilot passed.",
  "| SPEC-04 | moved to v29 | complete |",
  "| SPEC-04 | complete | moved to v29 |",
  "SPEC-04 moved to v29.\n\nIt is complete.",
  "SPEC-04 moved to v29.\n\nPassed.",
  "SPEC-04 moved to v29.\n\nAdopted.",
];
function proseControls() {
  for (const text of ACCEPTED_PROSE) {
    assert.doesNotThrow(() => scanClaims(text, "markdown"), `accepted markdown: ${text}`);
    assert.doesNotThrow(() => scanClaims(JSON.stringify({ note: text }), "json"), `accepted json: ${text}`);
  }
  for (const text of REFUSED_PROSE) {
    assert.throws(() => scanClaims(text, "markdown"), { code: "spec04_prose_claim" }, `refused markdown: ${text}`);
  }
  // JSON containers: each string value is a paragraph; the next sibling string follows an in-scope one.
  for (const text of REFUSED_PROSE.filter((t) => !t.includes("\n\n") && !t.startsWith("|"))) {
    assert.throws(() => scanClaims(JSON.stringify({ note: text }), "json"), { code: "spec04_prose_claim" }, `refused json: ${text}`);
  }
  assert.throws(() => scanClaims(JSON.stringify({ note: "SPEC-04 moved to v29.", next: "It is complete." }), "json"), { code: "spec04_prose_claim" });
  assert.throws(() => scanClaims(JSON.stringify({ note: "| SPEC-04 | complete | moved to v29 |" }), "json"), { code: "spec04_prose_claim" });
  // Another requirement named as the subject is not swept into the preceding paragraph.
  assert.doesNotThrow(() => scanClaims("SPEC-04 moved to v29.\n\nSPEC-01 passed.", "markdown"));
  assert.doesNotThrow(() => scanClaims("The build completed and Crosswake CI passed.\n\nSPEC-04 moved to v29.", "markdown"));
  // A marker in another clause or sentence never exempts a completion verb.
  assert.throws(() => scanClaims("SPEC-04 is complete, and no change was needed.", "markdown"), { code: "spec04_prose_claim" });
  assert.throws(() => scanClaims("Nothing is pending; SPEC-04 passed.", "markdown"), { code: "spec04_prose_claim" });
  // Structured fields are authoritative.
  assert.throws(() => scanClaims(JSON.stringify({ spec04: { disposition: "passed" } }), "json"), { code: "spec04_disposition" });
  assert.throws(() => scanClaims(JSON.stringify({ spec04: { disposition: "moved_to_v29", adopted: true } }), "json"), { code: "spec04_disposition" });
  assert.throws(() => scanClaims(JSON.stringify({ requirements: ["SPEC-01", "SPEC-04"] }), "json"), { code: "spec04_in_requirements" });
  assert.doesNotThrow(() => scanClaims(JSON.stringify({ requirements: IN_SCOPE, moved: ["SPEC-04"], spec04: { disposition: "moved_to_v29", receiver: RECEIVER } }), "json"));
  assert.throws(() => scanClaims("---\nrequirements-completed: [SPEC-01, SPEC-04]\n---\n\nbody\n", "markdown"), { code: "spec04_in_requirements" });
  assert.doesNotThrow(() => scanClaims("---\nrequirements-completed: []\nstatus: complete\n---\n\nbody\n", "markdown"));
}
function structuredControls(genuine) {
  const clone = () => structuredClone(genuine);
  const refuses = (code, mutate, check = checkDisposition) => {
    const copy = clone(); mutate(copy);
    assert.throws(() => check(copy), { code }, code);
  };
  const verdict = checkDisposition(genuine);
  assert.equal(verdict.spec04.disposition, "moved_to_v29"); assert.equal(verdict.spec04.receiver, RECEIVER);
  assert.equal(verdict.spec04.roster_count, ROSTER_COUNT);
  assert.equal(Object.hasOwn(verdict.spec04, "passed"), false);
  refuses("spec04_checkbox_checked", (i) => { i.requirements = i.requirements.replace("- [ ] **SPEC-04**", "- [x] **SPEC-04**"); });
  refuses("spec04_traceability_status", (i) => { i.requirements = i.requirements.replace("| SPEC-04 | v29.0 | Moved (criteria intact) |", "| SPEC-04 | v28.0 | Complete |"); });
  refuses("roadmap_requirements_line", (i) => { i.roadmap = i.roadmap.replace("**Requirements**: SPEC-01, SPEC-02, SPEC-03, SPEC-05,", "**Requirements**: SPEC-01, SPEC-02, SPEC-03, SPEC-04, SPEC-05,"); });
  refuses("roadmap_moved_missing", (i) => { i.roadmap = i.roadmap.replace(/^\*\*Moved\*\*:.*$/m, ""); });
  refuses("summary_requirements_completed", (i) => { i.summaries["196-02-SUMMARY.md"] = i.summaries["196-02-SUMMARY.md"].replace("requirements-completed: []", "requirements-completed: [SPEC-04]"); });
  refuses("plan_requirements_list", (i) => { i.plans[16] = i.plans[16].replace('requirements: ["SPEC-01"', 'requirements: ["SPEC-04","SPEC-01"'); });
  refuses("muex_report_present", (i) => { i.baselineWorktree = ["result.json", "report.json"]; });
  refuses("muex_report_present", (i) => { i.baselineTracked = ["result.json", "report.json"]; });
  refuses("roster_byte_changed", (i) => { i.roster[0].head = "0".repeat(64); });
  refuses("roster_worktree_changed", (i) => { i.roster[5].worktree = "0".repeat(64); });
  refuses("roster_worktree_changed", (i) => { i.roster[5].worktree = null; });
  refuses("roster_untracked", (i) => { i.untracked = [`${EVIDENCE}/muex-attempt2/extra.json`]; });
  refuses("roster_count", (i) => { i.roster.pop(); i.refPaths.pop(); });
  refuses("roster_count", (i) => { i.refPaths.push(`${EVIDENCE}/muex-extra.json`); });
  refuses("registry_muex_pilot", (i) => { i.registry = [{ command: "node", args: [`${PHASE}/scripts/muex-pilot.mjs`, "baseline"], cwd: "." }]; });
  assert.throws(() => scanClaims(JSON.stringify({ spec04: { disposition: "adopted" } }), "json"), { code: "spec04_disposition" });
}
async function selfTestDisposition(root) {
  const started = Date.now();
  const genuine = loadInputs(root, "HEAD");
  structuredControls(genuine);
  proseControls();
  await realChildControls();
  assert.ok(Date.now() - started < DEADLINE_MS, "disposition scope exceeded its deadline");
  return { scope: "disposition", ms: Date.now() - started };
}
const SCOPES = { disposition: selfTestDisposition };
async function selfTest(root, scope) {
  need(scope === undefined || Object.hasOwn(SCOPES, scope), "unknown_scope");
  const names = scope ? [scope] : Object.keys(SCOPES);
  const results = [];
  for (const name of names) results.push(await SCOPES[name](root));
  console.log(`phase-evidence: self-test passed ${results.map((r) => `${r.scope} ${r.ms}ms`).join(", ")}`);
}

// ---------------------------------------------------------------- CLI
function parseArgs(argv) {
  const [mode, ...rest] = argv;
  const opts = {};
  for (let i = 0; i < rest.length; i += 2) {
    need(/^--[a-z-]+$/.test(rest[i]) && rest[i + 1] && !Object.hasOwn(opts, rest[i].slice(2)), "invalid_arguments");
    opts[rest[i].slice(2)] = rest[i + 1];
  }
  return { mode, opts };
}
async function main() {
  const { mode, opts } = parseArgs(process.argv.slice(2));
  const root = git(process.cwd(), ["rev-parse", "--show-toplevel"]);
  need(realpathSync(root) === realpathSync(process.cwd()), "wrong_working_directory");
  if (mode === "self-test") {
    need(Object.keys(opts).every((key) => key === "scope"), "invalid_arguments");
    await selfTest(root, opts.scope);
  } else if (mode === "disposition") {
    need(Object.keys(opts).length === 0, "invalid_arguments");
    console.log(JSON.stringify(disposition(root), null, 2));
  } else throw new Refusal("invalid_mode");
}
if (path.resolve(process.argv[1] ?? "") === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(`phase-evidence: refused ${error instanceof Refusal ? error.code : "internal_error"}${error instanceof Refusal && error.detail ? ` (${String(error.detail).slice(0, 80)})` : ""}`);
    if (!(error instanceof Refusal) && process.env.PHASE_EVIDENCE_DEBUG === "1") console.error(error);
    process.exitCode = 1;
  });
}
export { scanClaims, disposition, candidateIdentity, checkDisposition, runChild, sha, Refusal };
