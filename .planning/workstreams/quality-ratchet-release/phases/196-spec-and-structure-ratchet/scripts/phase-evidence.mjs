#!/usr/bin/env node
// Phase-only verifier for Phase 196. Node built-ins only; no Muex, no network write, no merge in any scoped self-test.
// One file on purpose: the candidate identity hashes this whole file, so there is no partial-file carve-out.
// Verdicts are derived from committed git objects and real child processes, never from caller-authored values.
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, realpathSync, renameSync, rmSync, writeFileSync } from "node:fs";
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

// ---------------------------------------------------------------- candidate registry (filled below)
const REGISTRY = [];
// ---------------------------------------------------------------- promotion inventory (D-02)
// Only final-hash, actual-main-measured stable guards become required. Report/advisory lanes stay advisory.
const CI_WORKFLOW = ".github/workflows/crosswake-ci.yml";
const STAGES_FILE = "script/repository_verification_stages.json";
const EXCLUDED_TAGS = ["advisory_only", "engine_present", "requires_example_host", "collateral_binaries", "generated_manifest", "requires_xcodebuild"];
const PROMOTION = [
  { guard: "absence", file: "script/check_absence_is_not_success.exs", receipt: `${EVIDENCE}/main-absence.json`,
    caller: "test/crosswake/proof/absence_is_not_success_test.exs", stage: "root-proof", job: "phase130-core-hermetic-proof", change: "default_flipped" },
  { guard: "compile", file: "script/check_compile_structure.exs", receipt: `${EVIDENCE}/main-compile.json`,
    caller: "test/crosswake/proof/compile_structure_ratchet_test.exs", stage: "root-proof", job: "phase130-core-hermetic-proof", change: "already_required" },
  { guard: "rescue", file: "script/check_rescue_boundaries.exs", receipt: `${EVIDENCE}/main-rescue.json`,
    caller: "test/crosswake/proof/rescue_boundary_ratchet_test.exs", stage: "root-proof", job: "phase130-core-hermetic-proof", change: "already_required" },
  { guard: "dependencies", file: "script/check_runtime_dependencies.exs", receipt: `${EVIDENCE}/main-dependencies.json`,
    caller: "test/crosswake/proof/runtime_dependency_ratchet_test.exs", stage: "root-proof", job: "phase130-core-hermetic-proof", change: "already_required" },
  { guard: "grammar", file: "test/js/ci_secret_masking.test.mjs", receipt: `${EVIDENCE}/main-grammar.json`,
    caller: "test/js/ci_secret_masking.test.mjs", stage: null, job: "guard-01-e2e-honesty", ciStep: "node --test test/js/*.mjs", change: "already_required" },
];
const generation = (root, commit) => Number(git(root, ["rev-list", "--count", commit]));
function newestCommit(root, ref, name) {
  const value = git(root, ["log", "-n", "1", "--format=%H", ref, "--", name]);
  need(/^[0-9a-f]{40}$/.test(value), "promotion_history_missing");
  return value;
}
function gatherPromotion(root, ref = "HEAD") {
  const stages = JSON.parse(object(root, ref, STAGES_FILE).toString("utf8")).stages;
  const workflow = object(root, ref, CI_WORKFLOW).toString("utf8");
  return PROMOTION.map((entry) => {
    const guardBlob = git(root, ["rev-parse", `${ref}:${entry.file}`]);
    let receiptBlob = null;
    try { receiptBlob = JSON.parse(object(root, ref, entry.receipt).toString("utf8")).guard_blob ?? null; } catch { receiptBlob = null; }
    const callerExists = gitTry(root, ["cat-file", "-e", `${ref}:${entry.caller}`]) !== null;
    const callerText = callerExists ? object(root, ref, entry.caller).toString("utf8") : "";
    const stage = entry.stage ? stages.find((s) => s.stage_id === entry.stage) : null;
    const jobBlock = workflow.split(/^  (?=[A-Za-z0-9_-]+:\n)/m).find((block) => block.startsWith(`${entry.job}:`)) ?? "";
    const guardText = object(root, ref, entry.file).toString("utf8");
    const order = entry.change === "default_flipped" ? {
      flip: generation(root, newestCommit(root, ref, entry.file)),
      capture: generation(root, newestCommit(root, ref, entry.receipt)),
      caller: generation(root, newestCommit(root, ref, entry.caller)),
    } : null;
    return {
      guard: entry.guard, guard_file: entry.file, guard_blob: guardBlob, receipt_guard_blob: receiptBlob,
      caller: entry.caller, caller_exists: callerExists,
      caller_excluded_tags: EXCLUDED_TAGS.filter((tag) => new RegExp(`@(?:module)?tag :${tag}\\b|@(?:module)?tag ${tag}:`).test(callerText)),
      stage: entry.stage, stage_owned: entry.stage === null ? true : Boolean(stage && stage.argv.join(" ") === "mix verify" && stage.ci_owners.some((o) => o.job_id === entry.job)),
      job: entry.job, job_owned: jobBlock !== "" && (entry.ciStep ? jobBlock.includes(entry.ciStep) : true),
      change: entry.change,
      default_enforce: entry.change === "default_flipped"
        ? (guardText.match(/collections_mode, "enforce"\)/g) ?? []).length === 2 && !/collections_mode, "report"\)/.test(guardText) : undefined,
      order,
    };
  });
}
function checkPromotion(entries) {
  need(Array.isArray(entries) && entries.length === PROMOTION.length, "promotion_inventory_incomplete");
  for (const e of entries) {
    need(["default_flipped", "already_required"].includes(e.change), "promotion_change_unknown");
    need(typeof e.receipt_guard_blob === "string" && e.receipt_guard_blob.length === 40, "measured_receipt_missing", e.guard);
    need(e.receipt_guard_blob === e.guard_blob, "stale_measured_blob", e.guard);
    need(e.caller_exists, "caller_missing", e.guard);
    need(e.caller_excluded_tags.length === 0, "caller_excluded", e.guard);
    need(e.stage_owned && e.job_owned, "stage_unowned", e.guard);
    if (e.change === "default_flipped") {
      need(e.default_enforce === true, "flip_missing", e.guard);
      need(e.order && e.order.flip < e.order.capture, "flip_without_recapture", e.guard);
      need(e.order.capture <= e.order.caller, "premature_wiring", e.guard);
    } else {
      need(e.order === null && e.default_enforce === undefined, "wiring_change_on_already_required", e.guard);
    }
  }
  return entries.map((e) => ({ guard: e.guard, guard_blob: e.guard_blob, receipt_guard_blob: e.receipt_guard_blob, caller: e.caller, stage: e.stage, job: e.job, change: e.change }));
}

// ---------------------------------------------------------------- candidate: environment routes
const NODE_VERSION = "v22.14.0";
const NPM_VERSION = "10.9.2";
const JDK_HOME = "/opt/homebrew/opt/openjdk@17";
async function versionOf(env, command, args) {
  const result = await runChild(OWNER_ROOT, command, args, { env, timeout: 30_000 });
  return result.status === 0 ? `${result.stdout}${result.stderr}`.trim() : null;
}
// Node route: the repository asdf toolchain when it asserts exactly, else a SHA-256-verified official tarball in
// tool scratch. Both routes apply only to the child environment; no repository, global or asdf state changes.
async function nodeRoute(scratchParent = tmpdir()) {
  const asdf = { };
  const [node, npm] = [await versionOf(asdf, "node", ["--version"]), await versionOf(asdf, "npm", ["--version"])];
  if (node === NODE_VERSION && npm === NPM_VERSION) return { route: "asdf", env: {}, node, npm };
  const arch = process.arch === "arm64" ? "arm64" : "x64";
  const name = `node-${NODE_VERSION}-darwin-${arch}.tar.gz`;
  const scratch = mkdtempSync(path.join(scratchParent, "cw196-node-"));
  const base = `https://nodejs.org/dist/${NODE_VERSION}`;
  const get = (file) => runChild(scratch, "curl", ["--fail", "--silent", "--show-error", "--location", "--max-time", "300", "-o", file, `${base}/${file}`], { timeout: 330_000 });
  const [tar, sums] = [await get(name), await get("SHASUMS256.txt")];
  if (tar.status !== 0 || sums.status !== 0) return { route: "tarball", blocked: "download_failed", scratch };
  const expected = readFileSync(path.join(scratch, "SHASUMS256.txt"), "utf8").split("\n").map((l) => l.trim().split(/\s+/)).find(([, file]) => file === name)?.[0];
  if (!expected || sha(readFileSync(path.join(scratch, name))) !== expected) return { route: "tarball", blocked: "checksum_mismatch", scratch };
  const extract = await runChild(scratch, "tar", ["-xzf", name], { timeout: 120_000 });
  if (extract.status !== 0) return { route: "tarball", blocked: "extract_failed", scratch };
  const bin = path.join(scratch, name.replace(/\.tar\.gz$/, ""), "bin");
  const env = { PATH: `${bin}:${process.env.PATH}` };
  const [n2, p2] = [await versionOf(env, "node", ["--version"]), await versionOf(env, "npm", ["--version"])];
  if (n2 !== NODE_VERSION || p2 !== NPM_VERSION) return { route: "tarball", blocked: "version_assertion_failed", scratch };
  return { route: "tarball", env, node: n2, npm: p2, scratch };
}
async function jdkRoute() {
  const env = { JAVA_HOME: JDK_HOME, PATH: `${JDK_HOME}/bin:${process.env.PATH}` };
  const out = await versionOf(env, "java", ["-version"]);
  const major = /version "(\d+)(?:\.|")/.exec(out ?? "")?.[1];
  if (major !== "17") return { route: "jdk17", blocked: "java_major_not_17" };
  return { route: "jdk17", env, java_major: 17 };
}

// ---------------------------------------------------------------- candidate: process-result adapters
// Counts come from the child's own summary output, never from a caller-authored value.
function parseExUnit(output) {
  // Each tail counter is read independently so the order of "excluded" and "skipped" cannot hide an exclusion.
  const total = { tests: 0, failures: 0, excluded: 0, skipped: 0, invalid: 0, summaries: 0 };
  for (const m of output.matchAll(/^(?:(\d+) doctests?, )?(\d+) tests?, (\d+) failures?([^\n]*)$/gm)) {
    const tail = m[4];
    total.tests += Number(m[2]) + Number(m[1] ?? 0); total.failures += Number(m[3]);
    total.excluded += Number(/(\d+) excluded/.exec(tail)?.[1] ?? 0);
    total.skipped += Number(/(\d+) skipped/.exec(tail)?.[1] ?? 0);
    total.invalid += Number(/(\d+) invalid/.exec(tail)?.[1] ?? 0);
    total.summaries += 1;
  }
  total.failures += total.invalid;
  return total;
}
function parseNodeTest(output) {
  const pick = (name) => Number(new RegExp(`^# ${name} (\\d+)$`, "m").exec(output)?.[1] ?? NaN);
  return { tests: pick("tests"), failures: pick("fail"), excluded: pick("skipped") + pick("todo"), skipped: pick("skipped"), summaries: Number.isNaN(pick("tests")) ? 0 : 1 };
}
function parseVector(output, mode) {
  const lines = output.split("\n");
  const controls = lines.filter((l) => new RegExp(`^vector-control ${mode}\\b.*: discriminating failure$`).test(l)).length;
  const summary = new RegExp(`^vector-controls ${mode}: (.+)$`, "m").exec(output)?.[1] ?? "";
  const loaded = Number(/loaded (\d+)/.exec(summary)?.[1] ?? NaN);
  const completed = Number(/completed (\d+)/.exec(summary)?.[1] ?? NaN);
  const owners = Number(/(\d+) (?:JVM )?owners restored/.exec(summary)?.[1] ?? NaN);
  return { tests: controls, failures: 0, excluded: 0, skipped: 0, summaries: summary ? 1 : 0, loaded, completed, owners, restored: /restored/.test(summary) };
}
function parseStage(output, stage) {
  const passed = new RegExp(`^PASS ${stage}$`, "m").test(output);
  const bad = /^(?:FAIL|BLOCKED) /m.test(output);
  return { tests: null, failures: bad ? 1 : 0, excluded: 0, skipped: 0, summaries: passed ? 1 : 0, stage_pass: passed };
}
function parseScript(output) {
  return { tests: null, failures: 0, excluded: 0, skipped: 0, summaries: 1, enforce: /collections mode=enforce /.test(output), delta0: /delta=0\b/.test(output), ok: (output.match(/^\[crosswake\] OK:/gm) ?? []).length };
}
// Swift: the final XCTest "All tests" line plus any swift-testing "Test run with N tests" line.
function parseSwift(output) {
  const executed = [...output.matchAll(/Executed (\d+) tests?, with (?:(\d+) tests? skipped and )?(\d+) failures?/g)].pop();
  const testing = [...output.matchAll(/Test run with (\d+) tests?/g)].pop();
  const testingFailed = /Test run with \d+ tests? .*failed/.test(output);
  return {
    tests: Number(executed?.[1] ?? 0) + Number(testing?.[1] ?? 0), failures: Number(executed?.[3] ?? 0) + (testingFailed ? 1 : 0),
    excluded: 0, skipped: Number(executed?.[2] ?? 0), summaries: executed || testing ? 1 : 0,
  };
}
// Gradle: fresh JUnit XML only (never console totals). Each element is { text, mtimeMs }.
function sumJunit(files, sinceMs) {
  const total = { tests: 0, failures: 0, excluded: 0, skipped: 0, summaries: 0 };
  for (const { text, mtimeMs } of files) {
    if (mtimeMs < sinceMs) continue;
    const attrs = /<testsuite\s+([^>]+)>/.exec(text)?.[1];
    if (!attrs) continue;
    const read = (name) => Number(new RegExp(`${name}="(\\d+)"`).exec(attrs)?.[1] ?? NaN);
    const [tests, failures, errors, skipped] = [read("tests"), read("failures"), read("errors"), read("skipped")];
    if ([tests, failures, errors, skipped].some(Number.isNaN)) continue;
    total.tests += tests; total.failures += failures + errors; total.skipped += skipped; total.summaries += 1;
  }
  return total;
}
function freshJunit(root, dir, sinceMs) {
  const base = path.join(root, dir);
  if (!existsSync(base)) return sumJunit([], sinceMs);
  const files = readdirSync(base).filter((name) => /^TEST-.*\.xml$/.test(name)).sort()
    .map((name) => ({ text: readFileSync(path.join(base, name), "utf8"), mtimeMs: lstatSync(path.join(base, name)).mtimeMs }));
  return sumJunit(files, sinceMs);
}
const PARSERS = { exunit: parseExUnit, "node-test": parseNodeTest, vector: parseVector, stage: parseStage, script: parseScript, swift: parseSwift };

// ---------------------------------------------------------------- candidate: registry
// Pins are executed/excluded expectations per child. A change to any pin changes this file's hash and stales the candidate.
const MIX = (args, extra = {}) => ({ command: "mix", args, cwd: ".", ...extra });
const MIXTEST = (id, files, req, pin, extra = {}) => ({ id, req, kind: "exunit", route: "plain", ...MIX(["test", ...files], extra), expect: pin });
const VEC = (mode, route, pin, req = ["SPEC-01"]) => ({ id: `vector-${mode}`, req, kind: "vector", route, command: "node", args: [`${PHASE}/scripts/vector-controls.mjs`, mode], cwd: ".", mode, expect: pin });
const STAGE = (stage, route = "plain", { expect = {}, ...extra } = {}) => ({ id: stage, req: [], kind: "stage", route, command: "script/verify_repository.sh", args: ["--stage", stage], cwd: ".", stage, expect: { stage_pass: true, ...expect }, ...extra });
const ANDROID_PACKAGE = "packages/crosswake-shell-core-android";
const MANIFEST_PATH = "examples/phoenix_host/playwright-artifacts/route-tour/evidence-manifest.json";
const REGISTRY_NODE_TEST_FILES = "test/js/*.mjs";
const CANDIDATE_REGISTRY = [
  STAGE("format-proof"), STAGE("warnings-proof"), STAGE("repository-cleanliness"), STAGE("example-host-proof", "plain", { timeout: 3_600_000 }),
  STAGE("root-proof", "plain", { timeout: 3_600_000 }),
  // The facade exposes only its PASS marker, so the full core suite is also run directly for its own counts.
  { id: "root-core-suite", req: [], kind: "exunit", route: "plain", command: "mix", cwd: ".", env: { MIX_ENV: "test" }, timeout: 1_800_000,
    args: ["test", "--exclude", "phase41_nested_process", "--exclude", "requires_example_host", "--exclude", "advisory_only", "--seed", "748644", "--max-cases", "8"],
    expect: { minTests: 2500, failures: 0, maxExcluded: 150 } },
  // The producer is credited only when its manifest is fresh (written during this child's run).
  STAGE("browser-proof", "node", { timeout: 1_800_000, env: { GITHUB_ACTIONS: "true" }, envFromRepo: "crosswake_version", expect: { manifest_fresh: true } }),
  STAGE("ios-package-proof", "plain", { timeout: 3_600_000 }),
  { id: "ios-package-counts", req: [], kind: "swift", route: "plain", command: "swift", args: ["test"], cwd: "packages/crosswake-shell-core-ios", timeout: 1_800_000, expect: { tests: 89, failures: 0, excluded: 0, skipped: 2 } },
  STAGE("android-package-proof", "jdk", { timeout: 3_600_000 }),
  { id: "android-package-counts", req: [], kind: "gradle-xml", route: "jdk", command: "./gradlew", args: ["--no-daemon", "cleanTestDebugUnitTest", "testDebugUnitTest"], cwd: ANDROID_PACKAGE, timeout: 1_800_000,
    // Gradle reports an unchanged test task UP-TO-DATE and executes nothing; the clean rule forces execution and fresh XML.
    env: { CROSSWAKE_ANDROID_CONNECTED_TESTS: "0" }, expect: { tests: 12, failures: 0, excluded: 0, skipped: 0 } },
  { id: "node-tests", req: [], kind: "node-test", route: "plain", command: "node", args: ["--test", `@glob:${REGISTRY_NODE_TEST_FILES}`], cwd: ".", expect: { tests: 344, failures: 0, excluded: 0 } },
  { id: "format-explicit", req: [], kind: "format", route: "plain", command: "mix", args: ["format", "--check-formatted", "@changed-elixir"], cwd: ".", expect: { minFiles: 1 } },
  // SPEC-01 enabled lanes: the real producer's manifest, then the manifest test with the path set (11 tests, 0 excluded).
  MIXTEST("manifest-lane", ["test/crosswake/guides/evidence_manifest_test.exs"], ["SPEC-01"], { tests: 11, failures: 0, excluded: 0 },
    { route: "node", envFromRepo: "manifest_path" }),
  { id: "threadline-lane", req: ["SPEC-01"], kind: "exunit", route: "plain", command: "mix", cwd: ".",
    args: ["cmd", "--cd", "packages/crosswake_threadline", "mix", "test", "test/crosswake/proof/phase139_threadline_cleanroom_test.exs"],
    env: { MIX_INCLUDE_THREADLINE_PLUG: "1" }, expect: { tests: 5, failures: 0, excluded: 0 } },
  // The default (disabled) lanes stay as visible optional-skip evidence and are never credited as positive proof.
  { ...MIXTEST("manifest-lane-default", ["test/crosswake/guides/evidence_manifest_test.exs"], [], { tests: 10, failures: 0, excluded: 1 }), credit: "optional_skip_visible" },
  { id: "threadline-lane-default", req: [], kind: "exunit", route: "plain", command: "mix", cwd: ".", credit: "optional_skip_visible",
    args: ["cmd", "--cd", "packages/crosswake_threadline", "mix", "test", "test/crosswake/proof/phase139_threadline_cleanroom_test.exs"], expect: { tests: 4, failures: 0, excluded: 1 } },
  MIXTEST("wire-contract", ["test/crosswake/bridge/contract_test.exs", "test/crosswake/contract/contract_drift_test.exs"], ["SPEC-01"], { tests: 19, failures: 0, excluded: 0 }),
  { id: "wire-version", req: ["SPEC-01"], kind: "version", route: "plain", command: "mix", cwd: ".", env: { MIX_ENV: "test" },
    args: ["run", "--no-start", "-e", "IO.puts(Crosswake.Bridge.ProtocolVersion.version())"], expect: { lastLine: "1.1.0" } },
  VEC("elixir", "plain", { tests: 4, failures: 0, loaded: 15, completed: 9, restored: true }),
  VEC("swift-request", "plain", { tests: 4, failures: 0, loaded: 15, completed: 14, restored: true }),
  VEC("swift-reply", "plain", { tests: 4, failures: 0, minOwners: 1, restored: true }),
  VEC("swift-metadata", "plain", { tests: 9, failures: 0, minOwners: 1, restored: true }),
  VEC("swift-topology", "plain", { tests: 5, failures: 0, minOwners: 1, restored: true }),
  VEC("kotlin-request", "jdk", { tests: 4, failures: 0, minOwners: 1, restored: true }),
  VEC("kotlin-other", "jdk", { tests: 8, failures: 0, minOwners: 1, restored: true }),
  { id: "absence-enforce", req: ["SPEC-02"], kind: "script", route: "plain", command: "elixir", args: ["script/check_absence_is_not_success.exs", "--collections-mode", "enforce"], cwd: ".", expect: { enforce: true, delta0: true, minOk: 2 } },
  MIXTEST("absence-test", ["test/crosswake/proof/absence_is_not_success_test.exs"], ["SPEC-02"], { tests: 59, failures: 0, excluded: 0 }),
  MIXTEST("journal", ["test/crosswake/offline/journal_test.exs"], ["SPEC-03"], { tests: 4, failures: 0, excluded: 0 }),
  MIXTEST("safe-observation", ["test/crosswake/offline/safe_observation_test.exs"], ["SPEC-03"], { tests: 11, failures: 0, excluded: 0 }),
  MIXTEST("policy-compiler", ["test/crosswake/policy/compiler_test.exs"], ["SPEC-05"], { tests: 9, failures: 0, excluded: 0 }),
  MIXTEST("policy-product-route", ["test/crosswake/policy/finite_product_test.exs", "test/crosswake/policy/compiler_test.exs", "test/crosswake/policy/route_test.exs"], ["SPEC-05"], { tests: 28, failures: 0, excluded: 0 }),
  { id: "compile-force", req: ["ARCH-01"], kind: "compile", route: "plain", command: "mix", args: ["compile", "--force", "--warnings-as-errors"], cwd: ".", env: { MIX_ENV: "test" }, expect: { minCompiled: 1 } },
  { id: "xref-compile-connected", req: ["ARCH-01"], kind: "xref", route: "plain", command: "mix", args: ["xref", "graph", "--format", "cycles", "--label", "compile-connected", "--fail-above", "0"], cwd: ".", env: { MIX_ENV: "test" }, expect: {} },
  MIXTEST("compile-structure", ["test/crosswake/proof/compile_structure_ratchet_test.exs"], ["ARCH-01"], { tests: 15, failures: 0, excluded: 0 }),
  MIXTEST("location-router", ["test/crosswake/bridge/location_diagnostics_test.exs", "test/crosswake/router_test.exs"], ["ARCH-02"], { tests: 6, failures: 0, excluded: 0 }),
  MIXTEST("compatibility", ["test/crosswake/compatibility/compatibility_test.exs"], ["ARCH-02"], { tests: 17, failures: 0, excluded: 0 }),
  MIXTEST("rescue-boundary", ["test/crosswake/proof/rescue_boundary_ratchet_test.exs"], ["ARCH-02"], { tests: 30, failures: 0, excluded: 0 }),
  MIXTEST("runtime-dependencies", ["test/crosswake/proof/runtime_dependency_ratchet_test.exs"], ["ARCH-03"], { tests: 25, failures: 0, excluded: 0 }),
  { id: "secret-masking", req: ["SPEC-02", "GR-06"], kind: "node-test", route: "plain", command: "node", args: ["--test", "test/js/ci_secret_masking.test.mjs"], cwd: ".", expect: { tests: 207, failures: 0, excluded: 0 } },
];
REGISTRY.push(...CANDIDATE_REGISTRY);
const REQUIREMENT_MAP_KEYS = [...IN_SCOPE, "GR-06"];
function requirementMap(children) {
  const map = Object.fromEntries(REQUIREMENT_MAP_KEYS.map((key) => [key, []]));
  for (const child of children) for (const key of child.req ?? []) if (Object.hasOwn(map, key) && child.credit !== "optional_skip_visible") map[key].push(child.id);
  return map;
}
// A result is credited only when it ran, passed and executed at least one test (or the stage marker for facade stages).
function judgeChild(entry, result) {
  const e = entry.expect;
  const fail = (code) => ({ status: "fail", reason: code });
  if (result.preflightBlocked) return { status: "preflight-blocked", reason: result.preflightBlocked };
  if (result.timedOut) return fail("child_timeout");
  if (result.status !== 0) return fail("child_exit_nonzero");
  if (result.overflow) return fail("child_output_limit");
  if (result.groupGone === false) return fail("child_group_survived");
  const c = result.counts;
  if (entry.kind === "version") return result.lastLine === e.lastLine ? { status: "pass" } : fail("wire_version_mismatch");
  if (entry.kind === "format") return Number.isSafeInteger(result.files) && result.files >= e.minFiles ? { status: "pass" } : fail("format_scope_empty");
  if (entry.kind === "compile") return Number.isSafeInteger(result.compiled) && result.compiled >= e.minCompiled ? { status: "pass" } : fail("compile_nothing_compiled");
  if (entry.kind === "xref") return result.xrefClean === true ? { status: "pass" } : fail("xref_unproven");
  if (!c || c.summaries < 1) return fail("no_summary");
  if (entry.kind === "stage") {
    if (!(c.stage_pass === true && c.failures === 0)) return fail("stage_not_passed");
    if (e.manifest_fresh && result.manifestFresh !== true) return fail("producer_manifest_not_fresh");
    return { status: "pass" };
  }
  if (entry.kind === "script") {
    return c.enforce === e.enforce && c.delta0 === e.delta0 && c.ok >= e.minOk ? { status: "pass" } : fail("script_output_mismatch");
  }
  if (c.failures !== 0) return fail("child_failures");
  if (e.tests !== undefined && c.tests !== e.tests) return fail("test_count_mismatch");
  if (e.minTests !== undefined && !(c.tests >= e.minTests)) return fail("zero_or_low_executed");
  if (!(c.tests > 0)) return fail("zero_executed");
  if (e.excluded !== undefined && c.excluded !== e.excluded) return fail("excluded_above_pin");
  if (e.maxExcluded !== undefined && c.excluded > e.maxExcluded) return fail("excluded_above_pin");
  if (e.skipped !== undefined && c.skipped !== e.skipped) return fail("skipped_above_pin");
  if (e.anyExcluded === true && !(c.excluded > 0)) return fail("optional_lane_not_visibly_skipped");
  if (entry.kind === "vector") {
    if (e.restored && !c.restored) return fail("vector_not_restored");
    if (e.loaded !== undefined && c.loaded !== e.loaded) return fail("vector_loaded_mismatch");
    if (e.completed !== undefined && c.completed !== e.completed) return fail("vector_completed_mismatch");
    if (e.minOwners !== undefined && !(c.owners >= e.minOwners)) return fail("vector_owners_missing");
  }
  return { status: "pass" };
}
// Verdict over a set of judged children: every registry entry present exactly once, all pass, map non-empty.
function judgeCandidate(registry, children) {
  const ids = registry.map((e) => e.id);
  need(same(sorted(children.map((c) => c.id)), sorted(ids)) && new Set(children.map((c) => c.id)).size === ids.length, "registry_child_omitted");
  const bad = children.filter((c) => c.status !== "pass");
  const map = requirementMap(registry.map((e) => ({ ...e, ...children.find((c) => c.id === e.id) })));
  for (const key of REQUIREMENT_MAP_KEYS) {
    need(map[key].length > 0 && map[key].every((id) => children.find((c) => c.id === id)?.status === "pass" && children.find((c) => c.id === id)?.counted === true), "requirement_unmapped", key);
  }
  return { verdict: bad.length === 0 ? "pass" : "fail", failing: bad.map((c) => ({ id: c.id, status: c.status, reason: c.reason })), requirement_map: map };
}
function identityEqual(a, b) { return same(a, b); }
function reviewState(text) {
  need(typeof text === "string" && text.length > 0, "review_missing");
  const iterations = Number(/^Iterations: (\d+)\s*$/m.exec(text)?.[1] ?? NaN);
  need(Number.isInteger(iterations) && iterations >= 1 && iterations <= 3, "review_iterations");
  const rows = text.split("\n").filter((line) => /^\| R-\d+ \|/.test(line)).map((line) => line.split("|").map((c) => c.trim()));
  const open = rows.filter((cells) => cells[3] === "open");
  const openHigh = open.filter((cells) => ["high", "critical"].includes(cells[2]));
  return { iterations, findings: rows.length, open: open.length, open_high: openHigh.length };
}

// ---------------------------------------------------------------- candidate: runner
const BRANCH = "fix/spec-structure-ratchet";
// The landed-restoration fix branch is a second place the candidate may run, because the tool is part of the candidate identity.
const CANDIDATE_BRANCHES = [BRANCH, "fix/196-landed-restoration"];
const PRIVACY = `.planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/privacy-193.sh`;
const CANDIDATE = `${EVIDENCE}/candidate.json`;
const REVIEW = `${PHASE}/196-REVIEW.md`;
const DELIVERY = `${EVIDENCE}/delivery.json`;
const LANDED = `${EVIDENCE}/landed.json`;
const PR_BODY = `${EVIDENCE}/pr-body.md`;
function privacyScan(root, files) {
  need(files.length > 0, "empty_privacy_scope");
  const result = sync(root, "bash", [path.join(root, PRIVACY), ...files.map((name) => (path.isAbsolute(name) ? name : path.join(root, rel(name))))], { timeout: 120_000 });
  need(result.status === 0, "privacy_refused");
  return { exit: result.status, files: files.length };
}
function supportedTreeClean(root) {
  const changed = [...git(root, ["diff", "--name-only", "HEAD"]).split("\n"), ...git(root, ["diff", "--cached", "--name-only"]).split("\n")].filter(Boolean);
  const untracked = git(root, ["ls-files", "--others", "--exclude-standard"]).split("\n").filter(Boolean);
  return [...changed, ...untracked].every((name) => name.startsWith(".planning/"));
}
// The main commit PR 260 was displayed against (the first parent of its merge commit). The explicit-format child reads
// the Elixir files changed since it, not since origin/main: before the merge the two are the same commit, and after the
// merge origin/main contains the work, so a diff against it is empty and the child would prove nothing (found when the
// candidate rerun refused format_scope_empty on a branch with no Elixir change against the merged main).
const FORMAT_BASE = "4ebe37fe893f8ef420379d1f27c83bca37c0ce33";
function expandArgs(root, args, formatBase = FORMAT_BASE) {
  return args.flatMap((arg) => {
    if (arg === "@changed-elixir") {
      const files = git(root, ["diff", "--name-only", "--diff-filter=ACMRT", formatBase, "HEAD", "--", "*.ex", "*.exs"]).split("\n").filter(Boolean)
        .filter((name) => existsSync(path.join(root, name)));
      return files;
    }
    if (arg.startsWith("@glob:")) {
      const [dir, pattern] = [path.posix.dirname(arg.slice(6)), path.posix.basename(arg.slice(6))];
      const re = new RegExp(`^${pattern.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, "[^/]*")}$`);
      return sorted(readdirSync(path.join(root, dir)).filter((name) => re.test(name))).map((name) => `${dir}/${name}`);
    }
    return [arg];
  });
}
function crosswakeVersion(root) {
  const text = object(root, "HEAD", "mix.exs").toString("utf8");
  const version = /^  @version "([^"]+)"/m.exec(text)?.[1];
  need(version, "version_unreadable");
  return version;
}
async function runEntry(root, entry, routes) {
  const route = entry.route === "node" ? routes.node() : entry.route === "jdk" ? routes.jdk() : null;
  const resolved = route ? await route : null;
  if (resolved?.blocked) return { preflightBlocked: `${resolved.route}:${resolved.blocked}` };
  const env = { ...(resolved?.env ?? {}), ...(entry.env ?? {}) };
  if (entry.envFromRepo === "crosswake_version") env.CROSSWAKE_VERSION = crosswakeVersion(root);
  if (entry.envFromRepo === "manifest_path") {
    const manifest = path.join(root, MANIFEST_PATH);
    if (!existsSync(manifest)) return { preflightBlocked: "manifest_not_produced" };
    env.CROSSWAKE_EVIDENCE_MANIFEST_PATH = manifest;
  }
  const args = expandArgs(root, entry.args);
  if (entry.kind === "format" && args.length <= 2) return { status: 0, files: 0, counts: null, groupGone: true, ms: 0 };
  const startedAt = Date.now() - 1000;
  const run = await runChild(root, entry.command, args, { env, timeout: entry.timeout ?? 1_200_000, cwd: path.join(root, entry.cwd) });
  const output = `${run.stdout}\n${run.stderr}`;
  const result = { status: run.status, timedOut: run.timedOut, overflow: run.overflow, groupGone: run.groupGone, ms: run.ms, output_sha256: sha(output), route: resolved?.route ?? null };
  if (entry.kind === "format") result.files = args.length - 2;
  if (entry.kind === "compile") result.compiled = Number(/Compiling (\d+) files? \(\.ex\)/.exec(output)?.[1] ?? 0);
  if (entry.kind === "xref") result.xrefClean = run.status === 0;
  if (entry.kind === "version") result.lastLine = run.stdout.split("\n").map((line) => line.trim()).filter(Boolean).pop() ?? "";
  if (entry.stage === "browser-proof") {
    const manifest = path.join(root, MANIFEST_PATH);
    result.manifestFresh = existsSync(manifest) && lstatSync(manifest).mtimeMs >= startedAt;
  }
  const parser = PARSERS[entry.kind];
  if (entry.kind === "gradle-xml") { result.counts = freshJunit(root, `${entry.cwd}/build/test-results/testDebugUnitTest`, startedAt); return result; }
  result.counts = parser ? (entry.kind === "vector" ? parser(output, entry.mode) : entry.kind === "stage" ? parser(output, entry.stage) : parser(output)) : null;
  return result;
}
async function runRegistry(root, registry, { progress = true, only = null, afterChild = null } = {}) {
  const cache = {};
  const routes = { node: () => (cache.node ??= nodeRoute()), jdk: () => (cache.jdk ??= jdkRoute()) };
  const children = [];
  try {
    for (const entry of registry.filter((e) => !only || only.includes(e.id))) {
      if (progress) console.error(`phase-evidence: running ${entry.id}`);
      let result;
      try { result = await runEntry(root, entry, routes); } catch (error) { result = { status: null, runError: error instanceof Refusal ? error.code : "internal_error", ms: 0 }; }
      const judged = result.runError ? { status: "fail", reason: result.runError } : judgeChild(entry, result);
      const clean = supportedTreeClean(root);
      const status = clean ? judged.status : "fail";
      const reason = clean ? judged.reason : "child_dirtied_supported_source";
      const c = result.counts ?? {};
      children.push({
        id: entry.id, req: entry.req ?? [], credit: entry.credit ?? "positive", kind: entry.kind, route: result.route ?? entry.route,
        status, ...(reason ? { reason } : {}), exit: result.status ?? null, ms: result.ms ?? 0,
        tests: c.tests ?? null, failures: c.failures ?? null, excluded: c.excluded ?? null, skipped: c.skipped ?? null,
        ...(entry.kind === "vector" ? { loaded: c.loaded, completed: c.completed, owners: c.owners } : {}),
        ...(entry.kind === "version" ? { output: result.lastLine } : {}),
        ...(entry.kind === "compile" ? { compiled: result.compiled } : {}),
        counted: status === "pass" && (c.tests === null || c.tests === undefined || c.tests > 0),
        output_sha256: result.output_sha256 ?? null,
      });
      // Called after every child so a caller can persist what exists before anything later can refuse.
      if (afterChild) afterChild(children.slice(), entry);
    }
  } finally {
    for (const key of ["node"]) if (cache[key]) { const r = await cache[key]; if (r?.scratch) rmSync(r.scratch, { recursive: true, force: true }); }
  }
  const routesUsed = {};
  for (const key of ["node", "jdk"]) if (cache[key]) { const r = await cache[key]; routesUsed[key] = r.blocked ? { route: r.route, blocked: r.blocked } : { route: r.route, ...(r.node ? { node: r.node, npm: r.npm } : { java_major: r.java_major }) }; }
  return { children, routes: routesUsed };
}
async function candidate(root, { observe = false, only = null } = {}) {
  need(CANDIDATE_BRANCHES.includes(git(root, ["branch", "--show-current"])), "wrong_branch");
  need(supportedTreeClean(root), "dirty_supported_code");
  const identity = candidateIdentity(root, "HEAD");
  const disp = checkDisposition(loadInputs(root, "HEAD"));
  const reviewText = existsSync(path.join(root, REVIEW)) ? readFileSync(path.join(root, REVIEW), "utf8") : null;
  const review = observe && reviewText === null ? null : reviewState(reviewText);
  need(observe || review.open_high === 0, "review_high_open");
  git(root, ["fetch", "origin", "main"]);
  need(only === null || observe, "only_requires_observe");
  const run = await runRegistry(root, REGISTRY, { only });
  need(identityEqual(candidateIdentity(root, "HEAD"), identity), "candidate_identity_moved");
  need(same(checkDisposition(loadInputs(root, "HEAD")), disp), "disposition_moved");
  // A subset observation (calibration only) is never judged, never written and never a verdict.
  const judged = only ? { verdict: "observed_subset", failing: run.children.filter((c) => c.status !== "pass").map((c) => ({ id: c.id, status: c.status, reason: c.reason })), requirement_map: {} } : judgeCandidate(REGISTRY, run.children);
  const wire = run.children.find((c) => c.id === "wire-version");
  const record = {
    schema_version: 1, purpose: "phase196_candidate", head_sha: ref40(root, "HEAD"), main_sha: ref40(root, "origin/main"),
    candidate_identity: identity, spec04: disp.spec04, moved: [MOVED],
    routes: run.routes, wire_version: wire?.output ?? null,
    native_claim_ceiling: "jvm_hermetic_and_swift_package_only_never_device",
    children: run.children, requirement_map: judged.requirement_map, failing: judged.failing,
    review: review ? { path: REVIEW, ...review, sha256: sha(reviewText) } : null, verdict: judged.verdict,
  };
  const text = `${JSON.stringify(record, null, 2)}\n`;
  scanClaims(text, "json");
  if (reviewText) scanClaims(reviewText, "markdown");
  if (observe) { console.log(text); return record; }
  const scratch = mkdtempSync(path.join(tmpdir(), "cw196-candidate-"));
  try {
    const staged = path.join(scratch, "candidate.json"); writeFileSync(staged, text);
    privacyScan(root, [staged]);
    writeFileSync(path.join(root, CANDIDATE), text);
  } finally { rmSync(scratch, { recursive: true, force: true }); }
  console.log(`phase-evidence: candidate ${record.verdict} children ${record.children.length}${judged.failing.length ? ` failing ${judged.failing.map((f) => `${f.id}:${f.reason}`).join(",")}` : ""}`);
  need(record.verdict === "pass", "candidate_failed", judged.failing.map((f) => f.id).join(","));
  return record;
}

// ---------------------------------------------------------------- gates (196-16 pr-open/ready, 196-17 merge/approval-binding/landed)
// Pure validators take an explicit context so scoped self-tests exercise them with isolated inputs and never
// touch a remote. Live adapters (gh, git) fill the same context shape. Remote state is always re-read, never assumed.
const APPROVAL_REF = "refs/crosswake/196-17-approval";
const EVIDENCE_BRANCH = "docs/196-landed-evidence";
const POLL_SECONDS = 60;
const POLL_MAX = 90;
const MERGE_SCOPE = "merge_pr_to_main";
const SHA40 = /^[0-9a-f]{40}$/;
function spec04Claims(deliveryText, bodyText) {
  if (deliveryText !== null) scanClaims(deliveryText, "json");
  if (bodyText !== null) { scanClaims(bodyText, "markdown"); need(bodyText.includes(REQUIRED_STATEMENT), "required_statement_missing"); }
}
function sameIdentity(ctx) {
  need(ctx.candidate && ctx.candidate.verdict === "pass", "candidate_not_passed");
  need(identityEqual(ctx.identityNow, ctx.candidate.candidate_identity), "candidate_stale");
  need(same(ctx.dispositionNow.spec04, ctx.candidate.spec04), "disposition_changed");
  need(ctx.dispositionNow.spec04.roster_digest === ctx.candidate.candidate_identity.preserved_roster_sha256, "roster_digest_changed");
}
// pr-open: reviewed current-base head, remote read-back, fresh privacy scan, exact body and delivery claims.
function gatePrOpen(ctx) {
  sameIdentity(ctx);
  need(SHA40.test(ctx.localHead) && ctx.remoteHead === ctx.localHead, "remote_sha_mismatch");
  need(ctx.privacyExit === 0, "privacy_scan_failed");
  need(ctx.baseContained === true, "base_behind");
  need(ctx.review && ctx.review.open_high === 0, "review_high_open");
  spec04Claims(ctx.deliveryText, ctx.bodyText);
  const delivery = JSON.parse(ctx.deliveryText);
  need(delivery.spec04?.disposition === "moved_to_v29" && same(delivery.spec04, ctx.candidate.spec04), "delivery_disposition_mismatch");
  need(ctx.pr && ctx.pr.state === "OPEN" && ctx.pr.baseRefName === "main" && ctx.pr.headRefOid === ctx.localHead, "pr_head_mismatch");
  need(ctx.pr.body === ctx.bodyText, "pr_body_mismatch");
  need(ctx.pr.title && /^fix\(196\)/.test(ctx.pr.title), "pr_title_type");
  return { stage: "pr-open", head: ctx.localHead, pr: ctx.pr.number };
}
// ready: required checks on the PR head, synthetic merge identity reported separately, no open high finding.
function gateReady(ctx) {
  sameIdentity(ctx);
  need(ctx.pr && ctx.pr.state === "OPEN" && SHA40.test(ctx.pr.headRefOid), "pr_head_mismatch");
  need(ctx.remoteHead === ctx.pr.headRefOid && ctx.localHead === ctx.pr.headRefOid, "remote_sha_mismatch");
  need(Array.isArray(ctx.requiredContexts) && ctx.requiredContexts.length > 0, "required_checks_empty");
  need(Array.isArray(ctx.checkRuns) && ctx.checkRuns.length > 0, "check_inventory_empty");
  need(ctx.checkRuns.every((run) => run.head_sha === ctx.pr.headRefOid), "check_head_mismatch");
  for (const name of ctx.requiredContexts) {
    const runs = ctx.checkRuns.filter((run) => run.name === name);
    need(runs.length > 0, "required_check_missing", name);
    need(runs.every((run) => run.status === "completed"), "required_check_pending", name);
    need(runs.every((run) => run.conclusion === "success"), "required_check_failed", name);
  }
  need(!ctx.checkRuns.some((run) => run.status === "completed" && ["failure", "timed_out", "cancelled", "action_required"].includes(run.conclusion) && ctx.requiredContexts.includes(run.name)), "required_check_failed");
  need(SHA40.test(ctx.syntheticSha ?? "") && ctx.syntheticSha !== ctx.pr.headRefOid, "synthetic_identity_conflated");
  need(ctx.externalOpenHigh === 0, "external_high_open");
  need(ctx.review && ctx.review.open_high === 0, "review_high_open");
  need(ctx.protectedBypass !== true, "protected_branch_bypass");
  return { stage: "ready", head: ctx.pr.headRefOid, synthetic: ctx.syntheticSha, checks: ctx.checkRuns.length };
}
function checkMergeCommand(argv, head) {
  const list = argv.map(String);
  need(list[0] === "gh" && list[1] === "pr" && list[2] === "merge", "merge_command_shape");
  need(list.includes("--merge") && !list.includes("--squash") && !list.includes("--rebase"), "merge_method");
  const at = list.indexOf("--match-head-commit");
  need(at > 0 && list[at + 1] === head, "merge_head_guard_missing");
  need(!list.includes("--delete-branch") && !list.includes("-d") && !list.includes("--admin"), "merge_forbidden_flag");
}
// The final head/base/tip read and the merge call must be adjacent in the recorded step ledger.
function checkBackToBack(steps) {
  const read = steps.findIndex((s) => s === "final-read");
  const merge = steps.findIndex((s) => s === "merge-call");
  need(read >= 0 && merge === read + 1 && steps.filter((s) => s === "merge-call").length === 1, "steps_between_read_and_write");
}
function gateMerge(ctx) {
  // Order is fixed: every other check first, the head/base/tip read last.
  sameIdentity(ctx);
  need(ctx.deleteBranchOnMerge === false, "auto_delete_on_or_unreadable");
  need(ctx.attempt && ctx.attempt.scope === MERGE_SCOPE && Object.keys(ctx.attempt).every((k) => ["scope", "pr", "head", "base", "decision", "consumed"].includes(k)), "approval_scope_mismatch");
  need(ctx.attempt.decision === "allow" && ctx.attempt.consumed === false, "approval_not_fresh_allow");
  need(SHA40.test(ctx.attempt.head) && SHA40.test(ctx.attempt.base), "attempt_identity_malformed");
  checkMergeCommand(ctx.mergeArgv, ctx.attempt.head);
  need(ctx.final && ctx.final.prHead === ctx.attempt.head, "head_moved_after_display");
  need(ctx.final.prBase === ctx.attempt.base, "base_moved_since_display");
  need(ctx.final.mainTip === ctx.attempt.base, "base_moved_since_display");
  need(ctx.final.prOpen === true, "pr_not_open");
  if (ctx.steps) checkBackToBack(ctx.steps);
  return { stage: "merge", head: ctx.attempt.head, base: ctx.attempt.base };
}
// approval-binding: decision_recorded (196-17-02) or durable (196-17-03, before the write).
function gateApprovalBinding(ctx) {
  const a = ctx.attempt;
  need(a && a.scope === MERGE_SCOPE && a.decision === "allow" && a.consumed === false, "approval_not_fresh_allow");
  need(Number.isInteger(a.pr) && SHA40.test(a.head) && SHA40.test(a.base) && typeof a.at === "string", "attempt_identity_malformed");
  need(ctx.remotePrHead === a.head, "head_moved_after_display");
  need(ctx.prBase === a.base, "base_moved_since_display");
  if (ctx.state === "decision_recorded") return { stage: "approval-binding", state: "decision_recorded", head: a.head };
  need(ctx.state === "durable", "approval_state_unknown");
  const ref = ctx.approvalRef;
  need(ref && ref.exists, "approval_ref_missing");
  need(ref.parent === a.head, "approval_ref_wrong_parent");
  need(same(ref.diffPaths, [DELIVERY]), "approval_ref_extra_diff");
  need(ref.pushed === false, "approval_ref_pushed");
  need(ref.marker && ref.marker.status === "consuming" && ref.marker.pr === a.pr && ref.marker.head === a.head && ref.marker.base === a.base, "approval_marker_mismatch");
  need(ref.otherConsuming !== true, "approval_other_attempt_consuming");
  return { stage: "approval-binding", state: "durable", head: a.head };
}
// landed: two-parent merge, second parent the approved head, first parent the displayed base (else base drift).
function judgeMergeCommit(commit) {
  need(commit && Array.isArray(commit.parents) && commit.parents.length === 2, "merge_not_two_parent");
  need(commit.parents[1] === commit.attempt.head, "merge_excludes_approved_head");
  if (commit.parents[0] !== commit.attempt.base) return { landed_as_displayed: false, base_drift_at_write: true };
  return { landed_as_displayed: true, base_drift_at_write: false };
}
function checkLandedPlan(plan) {
  need(plan.registryComplete === true && plan.children === REGISTRY.length, "landed_registry_incomplete");
  need(plan.pushTarget === EVIDENCE_BRANCH && plan.pushTarget !== "main", "landed_push_target");
  need(plan.evidenceBase === plan.mergeCommit, "landed_evidence_base");
  need(plan.restored === true && plan.dirty === false, "landed_restoration");
  need(plan.consumedWrittenOn === EVIDENCE_BRANCH, "consumed_record_location");
  need(plan.validationUnchanged === true, "validation_modified");
}
function reconcileMarker(state) {
  // A leftover consuming marker is reconciled by reading remote state, never by retrying the write.
  if (state.marker?.status !== "consuming") return "none";
  if (state.remote.merged && state.remote.mergedHead === state.marker.head) return "landed_continue";
  return "unconsumed_uncertain";
}

// ---------------------------------------------------------------- live adapters (gh/git reads; the only write is the guarded merge call)
function ghJson(root, args) {
  const result = sync(root, "gh", args, { timeout: 90_000 });
  need(result.status === 0, "gh_failed");
  try { return JSON.parse(result.stdout); } catch { throw new Refusal("gh_output_malformed"); }
}
function repoSlug(root) {
  const url = git(root, ["remote", "get-url", "origin"]);
  const match = /github\.com[:/]([A-Za-z0-9._-]+\/[A-Za-z0-9._-]+?)(?:\.git)?$/.exec(url);
  need(match, "remote_unrecognized");
  return match[1];
}
function readJsonFile(root, name, code) {
  try { return JSON.parse(worktree(root, name).toString("utf8")); } catch { throw new Refusal(code); }
}
function readText(root, name, code) {
  try { return worktree(root, name).toString("utf8"); } catch { throw new Refusal(code); }
}
function livePr(root, number) {
  need(Number.isInteger(number) && number > 0, "pr_number_missing");
  const view = ghJson(root, ["pr", "view", String(number), "--json", "number,state,title,body,baseRefName,baseRefOid,headRefOid"]);
  const api = ghJson(root, ["api", `repos/${repoSlug(root)}/pulls/${number}`]);
  return { ...view, merge_commit_sha: api.merge_commit_sha ?? null };
}
function liveCheckRuns(root, sha) {
  const result = sync(root, "gh", ["api", "--paginate", `repos/${repoSlug(root)}/commits/${sha}/check-runs?per_page=100`, "--jq", ".check_runs[] | {name,status,conclusion,head_sha,app_id:.app.id}"], { timeout: 120_000 });
  need(result.status === 0, "gh_failed");
  return result.stdout.split("\n").filter(Boolean).map((line) => JSON.parse(line));
}
function liveDeleteBranchOnMerge(root) {
  const result = sync(root, "gh", ["api", `repos/${repoSlug(root)}`, "--jq", ".delete_branch_on_merge"], { timeout: 60_000 });
  if (result.status !== 0) return null;
  const value = result.stdout.trim();
  return value === "false" ? false : value === "true" ? true : null;
}
function remoteHead(root, branch) {
  const out = gitTry(root, ["ls-remote", "origin", `refs/heads/${branch}`]);
  return out ? out.split(/\s+/)[0] : null;
}
function currentIdentity(root) {
  return { identityNow: candidateIdentity(root, "HEAD"), dispositionNow: checkDisposition(loadInputs(root, "HEAD")) };
}
function liveReview(root) { return reviewState(readText(root, REVIEW, "review_missing")); }
function requiredContexts(root) {
  return JSON.parse(object(root, "HEAD", "script/required_check_policy.json").toString("utf8")).target_contexts;
}
function readApprovalRef(root, attempt) {
  const sha = gitTry(root, ["rev-parse", "--verify", `${APPROVAL_REF}^{commit}`]);
  if (!sha) return { exists: false };
  let marker = null;
  try { marker = JSON.parse(git(root, ["show", `${APPROVAL_REF}:${DELIVERY}`])).approval ?? null; } catch { marker = null; }
  const pushed = (gitTry(root, ["ls-remote", "origin", APPROVAL_REF]) ?? "") !== "";
  return {
    exists: true, parent: git(root, ["rev-parse", `${APPROVAL_REF}^`]),
    diffPaths: git(root, ["diff", "--name-only", `${APPROVAL_REF}^`, APPROVAL_REF]).split("\n").filter(Boolean),
    pushed, marker, otherConsuming: Boolean(marker && attempt && marker.head !== attempt.head && marker.status === "consuming"),
  };
}
async function runGate(root, opts) {
  const stage = opts.stage;
  need(["pr-open", "ready", "merge", "approval-binding"].includes(stage), "unknown_stage");
  const delivery = readJsonFile(root, DELIVERY, "delivery_missing");
  const candidateRecord = readJsonFile(root, CANDIDATE, "candidate_missing");
  const base = { ...currentIdentity(root), candidate: candidateRecord, review: liveReview(root), localHead: ref40(root, "HEAD") };
  const number = delivery.pr?.number ?? delivery.attempt?.pr;
  if (stage === "pr-open") {
    git(root, ["fetch", "origin", "main"]);
    const changed = git(root, ["diff", "--name-only", "--diff-filter=ACMRT", "origin/main", "HEAD"]).split("\n").filter(Boolean);
    const branch = git(root, ["branch", "--show-current"]);
    const ctx = {
      ...base, remoteHead: remoteHead(root, branch), privacyExit: privacyScan(root, changed).exit,
      baseContained: child0(root, ["merge-base", "--is-ancestor", "origin/main", "HEAD"]),
      deliveryText: readText(root, DELIVERY, "delivery_missing"), bodyText: readText(root, PR_BODY, "pr_body_missing"),
      pr: livePr(root, number),
    };
    return gatePrOpen(ctx);
  }
  if (stage === "ready") {
    const readyOnce = () => {
      const pr = livePr(root, number);
      const policy = requiredContexts(root);
      const runs = liveCheckRuns(root, pr.headRefOid);
      const branch = git(root, ["branch", "--show-current"]);
      return gateReady({ ...base, pr, remoteHead: remoteHead(root, branch), requiredContexts: policy, checkRuns: runs, syntheticSha: pr.merge_commit_sha,
        externalOpenHigh: (delivery.external_findings ?? []).filter((f) => ["high", "critical"].includes(f.severity) && f.status === "open").length,
        protectedBypass: delivery.protected_branch_bypass === true });
    };
    if (opts.poll !== "yes") return readyOnce();
    // Bounded polling: every 60 s, at most 90 polls. Run this as a background process; progress lands in the git dir.
    const notes = path.join(root, git(root, ["rev-parse", "--git-dir"]), "phase196-ready-poll.log");
    for (let poll = 1; poll <= POLL_MAX; poll += 1) {
      try { const result = readyOnce(); writeFileSync(notes, `poll ${poll}/${POLL_MAX} success\n`, { flag: "a" }); return result; } catch (error) {
        const code = error instanceof Refusal ? error.code : "internal_error";
        writeFileSync(notes, `poll ${poll}/${POLL_MAX} ${code}\n`, { flag: "a" });
        if (!["required_check_pending", "required_check_missing", "check_inventory_empty"].includes(code)) throw error;
      }
      if (poll < POLL_MAX) await new Promise((resolve) => setTimeout(resolve, POLL_SECONDS * 1000));
    }
    throw new Refusal("ready_pending_bound_expired");
  }
  const attempt = delivery.attempt;
  if (stage === "approval-binding") {
    const pr = livePr(root, attempt?.pr);
    const durable = opts.state === "durable";
    return gateApprovalBinding({ attempt, state: durable ? "durable" : "decision_recorded", remotePrHead: pr.headRefOid, prBase: pr.baseRefOid, approvalRef: durable ? readApprovalRef(root, attempt) : null });
  }
  // merge: all other checks first, the head/base/tip read last, then (only with --execute yes) the guarded merge call.
  const consuming = delivery.approval ?? null;
  const mergeArgv = ["gh", "pr", "merge", String(attempt?.pr), "--merge", "--match-head-commit", String(attempt?.head)];
  const steps = [];
  const ctx = { ...base, deleteBranchOnMerge: liveDeleteBranchOnMerge(root), attempt: attempt ? { ...attempt } : null, mergeArgv, steps };
  if (ctx.attempt) { delete ctx.attempt.at; ctx.attempt.consumed = consuming?.status === "consumed"; }
  steps.push("final-read");
  git(root, ["fetch", "origin", "main"]);
  const pr = livePr(root, attempt?.pr);
  ctx.final = { prHead: pr.headRefOid, prBase: pr.baseRefOid, mainTip: ref40(root, "origin/main"), prOpen: pr.state === "OPEN" };
  steps.push("merge-call");
  const verdict = gateMerge(ctx);
  if (opts.execute !== "yes") { steps.pop(); return { ...verdict, executed: false }; }
  const result = sync(root, mergeArgv[0], mergeArgv.slice(1), { timeout: 120_000 });
  need(result.status === 0, "merge_call_failed");
  return { ...verdict, executed: true };
}
function child0(root, args) { return sync(root, "git", args).status === 0; }

// ---------------------------------------------------------------- landed (196-17-03): reconcile once, prove actual main, retain evidence
function readMergeCommit(root, sha, attempt) {
  const line = git(root, ["rev-list", "--parents", "-n", "1", sha]).split(" ");
  need(line[0] === sha, "merge_commit_unreadable");
  return { sha, parents: line.slice(1), attempt };
}
function inventoryHash(root) {
  return sha(JSON.stringify({
    branch: git(root, ["branch", "--show-current"]), head: ref40(root, "HEAD"), index: sha(git(root, ["ls-files", "--stage"])),
    tracked: git(root, ["ls-files", "-z"]).split("\0").filter(Boolean).map((name) => [name, sha(worktree(root, name))]),
  }));
}
// ---- isolated landed run
const LANDED_WORKTREE = "crosswake-196-landed";
const LANDED_LEDGER = "crosswake-196-landed-children.json";
// Only path-independent fetched inputs are cloned (copy-on-write where the volume supports it) into the worktree, so the
// main checkout's copies are only read. Build outputs are never cloned: SwiftPM module caches record the absolute build
// path and refuse a moved copy, and stale Gradle or Mix output could be credited by a child. Every build starts cold,
// as it does in CI. A fetched input that is absent is not warmed; the child then fetches it or fails closed.
const WARM_NAMES = new Set(["deps", "node_modules", "local.properties"]);
function commonGitDir(root) { return path.resolve(root, git(root, ["rev-parse", "--git-common-dir"])); }
// Per-child results persist to a file in the git dir after every child. Earlier ledgers are rotated, never overwritten.
function landedLedger(root) {
  const file = path.join(commonGitDir(root), LANDED_LEDGER);
  let record = { schema_version: 1, purpose: "phase196_landed_children", children: [] };
  return {
    file,
    start(patch) {
      if (existsSync(file)) {
        const stamp = (() => { try { return String(JSON.parse(readFileSync(file, "utf8")).started_at ?? "").replace(/[^0-9A-Za-z]/g, ""); } catch { return ""; } })();
        let n = 0, target;
        do { target = file.replace(/\.json$/, `.${stamp || "earlier"}${n ? `-${n}` : ""}.json`); n += 1; } while (existsSync(target));
        renameSync(file, target);
      }
      record = { ...record, children: [], started_at: new Date().toISOString(), ...patch };
      writeFileSync(file, `${JSON.stringify(record, null, 2)}\n`);
    },
    update(patch) { record = { ...record, ...patch }; writeFileSync(file, `${JSON.stringify(record, null, 2)}\n`); },
  };
}
function warmCaches(root, wt) {
  const listed = git(root, ["ls-files", "--others", "--ignored", "--exclude-standard", "--directory", "-z"], { timeout: 120_000 }).split("\0").filter(Boolean);
  const warmed = [];
  for (const entry of listed) {
    const name = entry.replace(/\/$/, "");
    if (!WARM_NAMES.has(path.posix.basename(name)) || name.startsWith(".planning/") || name.startsWith(".git/")) continue;
    rel(name);
    mkdirSync(path.dirname(path.join(wt, name)), { recursive: true });
    const target = path.join(wt, name);
    let result = sync(root, "cp", ["-cR", path.join(root, name), target], { timeout: 600_000 });
    if (result.status !== 0) { rmSync(target, { recursive: true, force: true }); result = sync(root, "cp", ["-R", path.join(root, name), target], { timeout: 600_000 }); }
    need(result.status === 0, "landed_cache_warm_failed", name);
    warmed.push(name);
  }
  return warmed;
}
function removeLandedWorktree(root, wt) {
  sync(root, "git", ["worktree", "remove", "--force", wt], { timeout: 300_000 });
  if (existsSync(wt)) rmSync(wt, { recursive: true, force: true });
  sync(root, "git", ["worktree", "prune"]);
  return !existsSync(wt) && !git(root, ["worktree", "list", "--porcelain"]).split("\n").includes(`worktree ${wt}`);
}
async function runLandedRegistry(root, mergeSha, { registry, prepare = null, afterChild = null, ledger = landedLedger(root), progress = true } = {}) {
  need(SHA40.test(mergeSha), "invalid_commit");
  const wt = path.join(commonGitDir(root), LANDED_WORKTREE);
  // A directory left by a killed run is ours (fixed name under the git dir), so it is replaced, never trusted.
  if (existsSync(wt)) need(removeLandedWorktree(root, wt), "landed_worktree_stale");
  ledger.start({ merge_commit: mergeSha, worktree: wt, phase: "created", warmed: [], registry_size: registry.length });
  let run;
  try {
    git(root, ["worktree", "add", "--detach", wt, mergeSha], { timeout: 300_000 });
    need(ref40(wt, "HEAD") === mergeSha && supportedTreeClean(wt), "landed_detach_failed");
    if (prepare) prepare(wt);
    const warmed = warmCaches(root, wt);
    ledger.update({ phase: "running", warmed });
    run = await runRegistry(wt, registry, { progress, afterChild: (children, entry) => {
      ledger.update({ children });
      if (afterChild) afterChild(children, entry);
    } });
    ledger.update({ children: run.children, routes: run.routes, phase: "complete" });
  } catch (error) {
    ledger.update({ phase: "refused", refusal: error instanceof Refusal ? error.code : "internal_error" });
    throw error;
  } finally {
    let removed = false;
    try { removed = removeLandedWorktree(root, wt); } catch { removed = false; }
    ledger.update({ cleanup: removed ? "removed" : "failed" });
    if (!removed) console.error(`phase-evidence: landed worktree not removed at ${wt}`);
  }
  return run;
}
async function landed(root) {
  need(supportedTreeClean(root), "dirty_supported_code");
  const original = { branch: git(root, ["branch", "--show-current"]), head: ref40(root, "HEAD") };
  need(original.branch !== "", "landed_requires_branch");
  const before = inventoryHash(root);
  const candidateRecord = readJsonFile(root, CANDIDATE, "candidate_missing");
  const delivery = JSON.parse(git(root, ["show", `${APPROVAL_REF}:${DELIVERY}`]));
  const attempt = delivery.attempt;
  const marker = delivery.approval ?? null;
  need(attempt && marker, "approval_record_missing");
  git(root, ["fetch", "origin", "main"]);
  const pr = livePr(root, attempt.pr);
  const mergedHead = pr.state === "MERGED" ? attempt.head : null;
  const outcome = reconcileMarker({ marker, remote: { merged: pr.state === "MERGED", mergedHead } });
  need(outcome === "landed_continue", "attempt_not_merged_unconsumed_uncertain");
  const mergeSha = pr.merge_commit_sha;
  need(SHA40.test(mergeSha ?? "") && child0(root, ["merge-base", "--is-ancestor", mergeSha, "origin/main"]), "merge_not_on_main");
  const judgement = judgeMergeCommit(readMergeCommit(root, mergeSha, attempt));
  // The registry runs in an isolated linked worktree of the merge commit under the git dir. The main checkout is
  // never switched or written, so the restoration checks below hold by construction and stay as asserted invariants.
  let idMatches, disp;
  const prepare = (wt) => {
    // The landed proof uses the committed tools at the merge commit, so identity is recomputed there.
    const identity = candidateIdentity(wt, "HEAD");
    idMatches = identityEqual(identity, candidateRecord.candidate_identity);
    disp = checkDisposition(loadInputs(wt, "HEAD"));
    need(disp.spec04.roster_digest === candidateRecord.spec04.roster_digest, "roster_digest_changed");
  };
  const ledger = landedLedger(root);
  let run;
  try {
    run = await runLandedRegistry(root, mergeSha, { registry: REGISTRY, prepare, ledger });
    need(ref40(root, "HEAD") === original.head && git(root, ["branch", "--show-current"]) === original.branch && inventoryHash(root) === before, "landed_restoration_failed");
  } catch (error) {
    ledger.update({ refusal: error instanceof Refusal ? error.code : "internal_error" });
    throw error;
  }
  const verdict = judgeCandidate(REGISTRY, run.children);
  const landedRecord = {
    schema_version: 1, purpose: "phase196_landed", merge_commit: mergeSha, merge_parents: readMergeCommit(root, mergeSha, attempt).parents,
    approved_head: attempt.head, displayed_base: attempt.base, ...judgement,
    candidate_identity_matches: idMatches, spec04: disp.spec04, moved: [MOVED], routes: run.routes,
    native_claim_ceiling: "jvm_hermetic_and_swift_package_only_never_device",
    children: run.children, requirement_map: verdict.requirement_map, failing: verdict.failing, verdict: verdict.verdict,
  };
  const consumed = { ...delivery, approval: { ...marker, status: "consumed", merge_commit: mergeSha } };
  const inputs = [
    "# Phase 196 verification inputs", "",
    `Merge commit: ${mergeSha}. Approved head: ${attempt.head}. Displayed base: ${attempt.base}.`, "",
    "The seven requirements SPEC-01, SPEC-02, SPEC-03, SPEC-05, ARCH-01, ARCH-02, ARCH-03 and GR-06 are pending phase verification.", "",
    REQUIRED_STATEMENT, "", "Plan 196-14 is retired, not executed to completion.", "",
    `Per-task results: ${verdict.verdict}; children ${run.children.length}; failing ${verdict.failing.length}.`, "",
    "Next command: `$gsd-verify-work 196 --ws quality-ratchet-release`", "",
  ].join("\n");
  const [landedText, deliveryText] = [`${JSON.stringify(landedRecord, null, 2)}\n`, `${JSON.stringify(consumed, null, 2)}\n`];
  scanClaims(landedText, "json"); scanClaims(deliveryText, "json"); scanClaims(inputs, "markdown");
  const planCheck = { registryComplete: run.children.length === REGISTRY.length, children: run.children.length, pushTarget: EVIDENCE_BRANCH, evidenceBase: mergeSha, mergeCommit: mergeSha,
    restored: true, dirty: false, consumedWrittenOn: EVIDENCE_BRANCH, validationUnchanged: sha(object(root, original.head, `${PHASE}/196-VALIDATION.md`)) === sha(worktree(root, `${PHASE}/196-VALIDATION.md`)) };
  checkLandedPlan(planCheck);
  git(root, ["switch", "-c", EVIDENCE_BRANCH, mergeSha]);
  try {
    const files = [[LANDED, landedText], [DELIVERY, deliveryText], [`${PHASE}/196-VERIFICATION-INPUTS.md`, inputs]];
    for (const [name, text] of files) writeFileSync(path.join(root, name), text);
    privacyScan(root, files.map(([name]) => name));
    git(root, ["add", "--", ...files.map(([name]) => name)]);
    git(root, ["commit", "-q", "-m", "docs(196): record actual-main phase evidence"]);
  } finally { git(root, ["switch", original.branch]); }
  need(ref40(root, "HEAD") === original.head, "landed_restoration_failed");
  console.log(`phase-evidence: landed ${verdict.verdict} base_drift_at_write=${judgement.base_drift_at_write} evidence_branch=${EVIDENCE_BRANCH}`);
  need(verdict.verdict === "pass" && judgement.landed_as_displayed, "landed_failed");
  return landedRecord;
}

// ---------------------------------------------------------------- scoped self-tests: promotion, candidate, merge, landed
function fixtureRepo() {
  const root = mkdtempSync(path.join(tmpdir(), "cw196-pe-"));
  const g = (...args) => git(root, ["-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", ...args]);
  g("init", "-q", "-b", "main"); g("config", "user.name", "Fixture"); g("config", "user.email", "fixture@users.noreply.github.com");
  const put = (name, text) => writeFileSync(path.join(root, name), text);
  put("a.txt", "a\n"); g("add", "a.txt"); g("commit", "-q", "-m", "base");
  return { root, g, put, cleanup: () => rmSync(root, { recursive: true, force: true }) };
}
async function selfTestPromotion(root) {
  const started = Date.now();
  const before = git(root, ["status", "--porcelain", "--", EVIDENCE]);
  const genuine = gatherPromotion(root, "HEAD");
  const inventory = checkPromotion(genuine);
  assert.equal(inventory.length, PROMOTION.length);
  assert.equal(inventory.filter((e) => e.change === "default_flipped").length, 1);
  assert.equal(inventory.find((e) => e.guard === "absence").change, "default_flipped");
  const refuses = (code, mutate) => {
    const copy = structuredClone(genuine); mutate(copy);
    assert.throws(() => checkPromotion(copy), { code }, code);
  };
  const absence = (i) => i.find((e) => e.guard === "absence");
  refuses("stale_measured_blob", (i) => { absence(i).receipt_guard_blob = "0".repeat(40); });
  refuses("stale_measured_blob", (i) => { i.find((e) => e.guard === "compile").guard_blob = "1".repeat(40); });
  refuses("measured_receipt_missing", (i) => { absence(i).receipt_guard_blob = null; });
  refuses("flip_without_recapture", (i) => { absence(i).order = { flip: 9, capture: 9, caller: 10 }; });
  refuses("flip_without_recapture", (i) => { absence(i).order = { flip: 10, capture: 9, caller: 11 }; });
  refuses("premature_wiring", (i) => { absence(i).order = { flip: 1, capture: 5, caller: 4 }; });
  refuses("flip_missing", (i) => { absence(i).default_enforce = false; });
  refuses("caller_missing", (i) => { i[1].caller_exists = false; });
  refuses("caller_excluded", (i) => { i[2].caller_excluded_tags = ["advisory_only"]; });
  refuses("stage_unowned", (i) => { i[3].stage_owned = false; });
  refuses("stage_unowned", (i) => { i[4].job_owned = false; });
  refuses("wiring_change_on_already_required", (i) => { i[1].order = { flip: 1, capture: 2, caller: 3 }; });
  refuses("promotion_change_unknown", (i) => { i[1].change = "advisory_to_required"; });
  assert.throws(() => checkPromotion(genuine.slice(1)), { code: "promotion_inventory_incomplete" });
  assert.equal(PROMOTION.some((e) => /muex/i.test(JSON.stringify(e))), false);
  await realChildControls();
  assert.equal(git(root, ["status", "--porcelain", "--", EVIDENCE]), before, "promotion scope must write no receipt");
  assert.ok(Date.now() - started < DEADLINE_MS, "promotion scope exceeded its deadline");
  return { scope: "promotion", ms: Date.now() - started };
}
function checkRegistry(registry) {
  need(new Set(registry.map((e) => e.id)).size === registry.length, "registry_duplicate_id");
  need(!registryNamesMuex(registry), "registry_muex_pilot");
  const map = requirementMap(registry);
  for (const key of REQUIREMENT_MAP_KEYS) need(map[key].length > 0, "requirement_unmapped", key);
  need(!Object.hasOwn(map, MOVED), "spec04_in_requirements");
  for (const e of registry) {
    need(["plain", "node", "jdk"].includes(e.route), "registry_route");
    need(e.expect && typeof e.expect === "object", "registry_pin_missing", e.id);
    if (["exunit", "node-test", "vector", "swift", "gradle-xml"].includes(e.kind)) need(e.expect.tests !== undefined || e.expect.minTests !== undefined, "registry_pin_missing", e.id);
    if (["exunit", "node-test", "swift", "gradle-xml"].includes(e.kind)) need(e.expect.failures === 0 && (e.expect.excluded !== undefined || e.expect.maxExcluded !== undefined || e.expect.anyExcluded === true), "registry_pin_missing", e.id);
  }
  const by = (id) => registry.find((e) => e.id === id);
  need(by("manifest-lane")?.expect.tests === 11 && by("manifest-lane").expect.excluded === 0 && by("manifest-lane").route === "node", "manifest_lane_pin");
  need(by("threadline-lane")?.expect.tests === 5 && by("threadline-lane").expect.excluded === 0 && by("threadline-lane").env?.MIX_INCLUDE_THREADLINE_PLUG === "1", "threadline_lane_pin");
  need(by("wire-version")?.expect.lastLine === "1.1.0", "wire_version_pin");
  need(["browser-proof"].every((id) => by(id)?.route === "node") && ["android-package-proof", "vector-kotlin-request", "vector-kotlin-other"].every((id) => by(id)?.route === "jdk"), "route_pin");
  const order = registry.map((e) => e.id);
  need(order.indexOf("browser-proof") >= 0 && order.indexOf("browser-proof") < order.indexOf("manifest-lane"), "producer_before_manifest");
  need(by("browser-proof")?.expect.manifest_fresh === true, "producer_freshness_pin");
  for (const id of ["root-core-suite", "ios-package-counts", "android-package-counts"]) need(by(id) !== undefined, "count_child_missing", id);
  return true;
}
async function selfTestCandidate(root) {
  const started = Date.now();
  const before = git(root, ["status", "--porcelain", "--", EVIDENCE]);
  assert.equal(checkRegistry(REGISTRY), true);
  assert.equal(NODE_VERSION, "v22.14.0"); assert.equal(NPM_VERSION, "10.9.2"); assert.equal(JDK_HOME, "/opt/homebrew/opt/openjdk@17");
  // Registry shape refusals on in-memory copies.
  const registry = () => structuredClone(REGISTRY);
  assert.throws(() => checkRegistry(registry().filter((e) => e.id !== "manifest-lane")), { code: "manifest_lane_pin" });
  assert.throws(() => checkRegistry(registry().filter((e) => e.id !== "threadline-lane")), { code: "threadline_lane_pin" });
  assert.throws(() => checkRegistry(registry().filter((e) => !["journal", "safe-observation"].includes(e.id))), { code: "requirement_unmapped" });
  assert.throws(() => checkRegistry([...registry(), { id: "x", req: [], kind: "script", route: "plain", command: "node", args: [`${PHASE}/scripts/muex-pilot.mjs`], cwd: ".", expect: {} }]), { code: "registry_muex_pilot" });
  assert.throws(() => checkRegistry(registry().map((e) => (e.id === "manifest-lane" ? { ...e, expect: { ...e.expect, tests: 10, excluded: 1 } } : e))), { code: "manifest_lane_pin" });
  assert.throws(() => checkRegistry(registry().map((e) => (e.id === "journal" ? { ...e, expect: {} } : e))), { code: "registry_pin_missing" });
  // Process-result adapter on genuine captured and genuinely generated output.
  const exunit = parseExUnit("Finished in 30.4 seconds (30.4s async, 0.00s sync)\n59 tests, 0 failures\n");
  assert.deepEqual([exunit.tests, exunit.failures, exunit.excluded], [59, 0, 0]);
  assert.equal(parseExUnit("Finished in 0.1 seconds\n11 tests, 0 failures, 1 excluded\n").excluded, 1);
  assert.equal(parseExUnit("nothing summarised").summaries, 0);
  // Swift: genuine captured XCTest and swift-testing summary lines.
  const swiftOut = "\t Executed 6 tests, with 2 tests skipped and 0 failures (0 unexpected) in 0.002 (0.002) seconds\nTest Suite 'All tests' passed at 2026-10-28 11:31:34.756.\n\t Executed 89 tests, with 2 tests skipped and 0 failures (0 unexpected) in 0.042 (0.046) seconds\n\u2714 Test run with 0 tests in 0 suites passed after 0.001 seconds.\n";
  assert.deepEqual([parseSwift(swiftOut).tests, parseSwift(swiftOut).skipped, parseSwift(swiftOut).failures], [89, 2, 0]);
  assert.equal(parseSwift("\t Executed 3 tests, with 1 failures (0 unexpected) in 0.1 seconds\n").failures, 1);
  assert.equal(parseSwift("no summary").summaries, 0);
  // Gradle: genuine JUnit XML header; stale files are never credited.
  const junit = `<?xml version="1.0" encoding="UTF-8"?>\n<testsuite name="dev.crosswake.shell.core.BridgeReplyLegTest" tests="3" skipped="0" failures="0" errors="0" timestamp="2026-10-28T15:31:49" hostname="Mac" time="0.005">\n`;
  assert.deepEqual([sumJunit([{ text: junit, mtimeMs: 2000 }], 1000).tests, sumJunit([{ text: junit, mtimeMs: 2000 }], 1000).summaries], [3, 1]);
  assert.equal(sumJunit([{ text: junit, mtimeMs: 500 }], 1000).summaries, 0);
  assert.equal(sumJunit([{ text: junit.replace('errors="0"', 'errors="2"'), mtimeMs: 2000 }], 1000).failures, 2);
  assert.equal(sumJunit([{ text: "<broken>", mtimeMs: 2000 }], 1000).summaries, 0);
  assert.equal(parseExUnit("12 tests, 0 failures, 2 skipped, 3 excluded\n").excluded, 3);
  assert.equal(parseExUnit("12 tests, 0 failures, 3 excluded, 2 skipped\n").skipped, 2);
  assert.equal(parseExUnit("3 doctests, 12 tests, 0 failures\n").tests, 15);
  assert.equal(parseExUnit("12 tests, 0 failures, 1 invalid\n").failures, 1);
  const scratch = mkdtempSync(path.join(tmpdir(), "cw196-cand-"));
  try {
    const file = path.join(scratch, "tiny.test.mjs");
    writeFileSync(file, "import test from 'node:test';\ntest('one',()=>{});\ntest('two',()=>{});\n");
    const real = await runChild(scratch, process.execPath, ["--test", file], { timeout: 15_000 });
    const parsed = parseNodeTest(real.stdout);
    assert.equal(real.status, 0); assert.deepEqual([parsed.tests, parsed.failures], [2, 0]);
    writeFileSync(file, "import test from 'node:test';\ntest('bad',()=>{throw new Error('x')});\n");
    const failing = await runChild(scratch, process.execPath, ["--test", file], { timeout: 15_000 });
    assert.notEqual(failing.status, 0);
  } finally { rmSync(scratch, { recursive: true, force: true }); }
  // judgeChild refusals: zero execution, failure, excluded tagged positive test, failed preflight.
  const manifest = REGISTRY.find((e) => e.id === "manifest-lane");
  const good = { status: 0, groupGone: true, counts: { tests: 11, failures: 0, excluded: 0, skipped: 0, summaries: 1 } };
  assert.equal(judgeChild(manifest, good).status, "pass");
  assert.equal(judgeChild(manifest, { ...good, counts: { ...good.counts, tests: 10, excluded: 1 } }).reason, "test_count_mismatch");
  assert.equal(judgeChild(manifest, { ...good, counts: { ...good.counts, tests: 11, excluded: 1 } }).reason, "excluded_above_pin");
  assert.equal(judgeChild(manifest, { ...good, counts: { ...good.counts, tests: 0 } }).reason, "test_count_mismatch");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "journal"), { ...good, counts: { ...good.counts, tests: 0 } }).reason, "test_count_mismatch");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "journal"), { ...good, counts: { ...good.counts, tests: 3 } }).reason, "test_count_mismatch");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "vector-swift-reply"), { ...good, counts: { ...good.counts, tests: 0, restored: true, owners: 1 } }).reason, "test_count_mismatch");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "root-core-suite"), { ...good, counts: { ...good.counts, tests: 0 } }).reason, "zero_or_low_executed");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "node-tests"), { ...good, counts: { ...good.counts, tests: 0 } }).reason, "test_count_mismatch");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "journal"), { ...good, status: 2 }).reason, "child_exit_nonzero");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "journal"), { ...good, counts: { ...good.counts, tests: 5, failures: 1 } }).reason, "child_failures");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "journal"), { ...good, counts: null }).reason, "no_summary");
  assert.equal(judgeChild(manifest, { preflightBlocked: "asdf:version_assertion_failed" }).status, "preflight-blocked");
  // The producer stage is credited only with a fresh manifest; facade markers alone are not enough.
  const browser = REGISTRY.find((e) => e.id === "browser-proof");
  const stageOk = { status: 0, groupGone: true, counts: { stage_pass: true, failures: 0, summaries: 1 } };
  assert.equal(judgeChild(browser, { ...stageOk, manifestFresh: true }).status, "pass");
  assert.equal(judgeChild(browser, { ...stageOk, manifestFresh: false }).reason, "producer_manifest_not_fresh");
  assert.equal(judgeChild(browser, { ...stageOk, counts: { ...stageOk.counts, stage_pass: false }, manifestFresh: true }).reason, "stage_not_passed");
  const coreSuite = REGISTRY.find((e) => e.id === "root-core-suite");
  assert.equal(judgeChild(coreSuite, { ...good, counts: { ...good.counts, tests: 3000, excluded: 79 } }).status, "pass");
  assert.equal(judgeChild(coreSuite, { ...good, counts: { ...good.counts, tests: 3000, excluded: 400 } }).reason, "excluded_above_pin");
  assert.equal(judgeChild(coreSuite, { ...good, counts: { ...good.counts, tests: 5 } }).reason, "zero_or_low_executed");
  const ios = REGISTRY.find((e) => e.id === "ios-package-counts");
  assert.equal(judgeChild(ios, { ...good, counts: { tests: 89, failures: 0, excluded: 0, skipped: 2, summaries: 1 } }).status, "pass");
  assert.equal(judgeChild(ios, { ...good, counts: { tests: 89, failures: 0, excluded: 0, skipped: 5, summaries: 1 } }).reason, "skipped_above_pin");
  assert.equal(judgeChild(ios, { ...good, counts: { tests: 0, failures: 0, excluded: 0, skipped: 0, summaries: 1 } }).reason, "test_count_mismatch");
  const android = REGISTRY.find((e) => e.id === "android-package-counts");
  assert.equal(judgeChild(android, { ...good, counts: { tests: 12, failures: 0, excluded: 0, skipped: 0, summaries: 4 } }).status, "pass");
  assert.equal(judgeChild(android, { ...good, counts: { tests: 0, failures: 0, excluded: 0, skipped: 0, summaries: 0 } }).reason, "no_summary");
  assert.equal(android.args.includes("cleanTestDebugUnitTest"), true);
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "wire-version"), { status: 0, groupGone: true, lastLine: "1.0.0" }).reason, "wire_version_mismatch");
  assert.equal(judgeChild(REGISTRY.find((e) => e.id === "wire-version"), { status: 0, groupGone: true, lastLine: "1.1.0" }).status, "pass");
  // judgeCandidate: omitted child, failing child, missing mapping, preflight-blocked FAIL.
  const children = REGISTRY.map((e) => ({ id: e.id, status: "pass", counted: true }));
  assert.equal(judgeCandidate(REGISTRY, children).verdict, "pass");
  assert.throws(() => judgeCandidate(REGISTRY, children.slice(1)), { code: "registry_child_omitted" });
  assert.equal(judgeCandidate(REGISTRY, children.map((c) => (c.id === "browser-proof" ? { ...c, status: "preflight-blocked" } : c))).verdict, "fail");
  assert.equal(judgeCandidate(REGISTRY, children.map((c) => (c.id === "format-proof" ? { ...c, status: "fail" } : c))).verdict, "fail");
  assert.throws(() => judgeCandidate(REGISTRY, children.map((c) => (c.id === "journal" || c.id === "safe-observation" ? { ...c, status: "fail" } : c))), { code: "requirement_unmapped" });
  assert.throws(() => judgeCandidate(REGISTRY, children.map((c) => (c.id === "journal" || c.id === "safe-observation" ? { ...c, counted: false } : c))), { code: "requirement_unmapped" });
  // Stale identity, changed disposition and a SPEC-04 claim in a candidate record all refuse.
  const identity = { source_roster_sha256: "a", phase_evidence_sha256: "b", measure_main_sha256: "c", preserved_roster_sha256: "d" };
  const spec04 = { disposition: "moved_to_v29", receiver: RECEIVER, roster_digest: "d" };
  const ctx = { candidate: { verdict: "pass", candidate_identity: identity, spec04 }, identityNow: identity, dispositionNow: { spec04 } };
  assert.doesNotThrow(() => sameIdentity(ctx));
  assert.throws(() => sameIdentity({ ...ctx, identityNow: { ...identity, phase_evidence_sha256: "z" } }), { code: "candidate_stale" });
  assert.throws(() => sameIdentity({ ...ctx, identityNow: { ...identity, measure_main_sha256: "z" } }), { code: "candidate_stale" });
  assert.throws(() => sameIdentity({ ...ctx, candidate: { ...ctx.candidate, verdict: "fail" } }), { code: "candidate_not_passed" });
  assert.throws(() => sameIdentity({ ...ctx, dispositionNow: { spec04: { ...spec04, disposition: "adopted" } } }), { code: "disposition_changed" });
  assert.throws(() => scanClaims(JSON.stringify({ spec04: { disposition: "moved_to_v29" }, requirement_map: { x: 1 }, requirements: ["SPEC-04"] }), "json"), { code: "spec04_in_requirements" });
  // Review gate: findings and iterations are machine-read; an open high or critical finding blocks.
  const review = (rows, n = 1) => `# Review\n\nIterations: ${n}\n\n| ID | Severity | Status | Finding |\n|----|----------|--------|---------|\n${rows}\n`;
  assert.equal(reviewState(review("| R-01 | low | fixed | x |")).open_high, 0);
  assert.equal(reviewState(review("| R-01 | high | open | x |\n| R-02 | critical | open | y |")).open_high, 2);
  assert.equal(reviewState(review("| R-01 | high | fixed | x |")).open_high, 0);
  assert.throws(() => reviewState(review("| R-01 | low | fixed | x |", 4)), { code: "review_iterations" });
  assert.throws(() => reviewState(""), { code: "review_missing" });
  assert.equal(git(root, ["status", "--porcelain", "--", EVIDENCE]), before, "candidate scope must write no receipt");
  assert.ok(Date.now() - started < DEADLINE_MS, "candidate scope exceeded its deadline");
  return { scope: "candidate", ms: Date.now() - started };
}
async function selfTestMerge(root) {
  const started = Date.now();
  const H = "a".repeat(40), B = "b".repeat(40), M = "c".repeat(40);
  const identity = { source_roster_sha256: "a", phase_evidence_sha256: "b", measure_main_sha256: "c", preserved_roster_sha256: "d" };
  const spec04 = { disposition: "moved_to_v29", receiver: RECEIVER, roster_digest: "d" };
  const base = { candidate: { verdict: "pass", candidate_identity: identity, spec04 }, identityNow: identity, dispositionNow: { spec04 }, review: { open_high: 0 } };
  const argv = ["gh", "pr", "merge", "7", "--merge", "--match-head-commit", H];
  const attempt = { scope: MERGE_SCOPE, pr: 7, head: H, base: B, decision: "allow", consumed: false };
  const merge = { ...base, deleteBranchOnMerge: false, attempt, mergeArgv: argv, final: { prHead: H, prBase: B, mainTip: B, prOpen: true }, steps: ["final-read", "merge-call"] };
  assert.equal(gateMerge(merge).stage, "merge");
  const refuses = (code, ctx, fn = gateMerge) => assert.throws(() => fn(ctx), { code }, code);
  refuses("head_moved_after_display", { ...merge, final: { ...merge.final, prHead: "d".repeat(40) } });
  refuses("base_moved_since_display", { ...merge, final: { ...merge.final, prBase: M } });
  refuses("base_moved_since_display", { ...merge, final: { ...merge.final, mainTip: M } });
  refuses("steps_between_read_and_write", { ...merge, steps: ["final-read", "tool-step", "merge-call"] });
  refuses("steps_between_read_and_write", { ...merge, steps: ["merge-call", "final-read"] });
  refuses("auto_delete_on_or_unreadable", { ...merge, deleteBranchOnMerge: true });
  refuses("auto_delete_on_or_unreadable", { ...merge, deleteBranchOnMerge: null });
  refuses("approval_scope_mismatch", { ...merge, attempt: { ...attempt, scope: "merge_and_publish" } });
  refuses("approval_scope_mismatch", { ...merge, attempt: { ...attempt, tag: "v1" } });
  refuses("approval_not_fresh_allow", { ...merge, attempt: { ...attempt, consumed: true } });
  refuses("approval_not_fresh_allow", { ...merge, attempt: { ...attempt, decision: "hold" } });
  refuses("candidate_stale", { ...merge, identityNow: { ...identity, source_roster_sha256: "z" } });
  refuses("disposition_changed", { ...merge, dispositionNow: { spec04: { ...spec04, disposition: "dropped" } } });
  refuses("pr_not_open", { ...merge, final: { ...merge.final, prOpen: false } });
  refuses("merge_head_guard_missing", { ...merge, mergeArgv: ["gh", "pr", "merge", "7", "--merge"] });
  refuses("merge_forbidden_flag", { ...merge, mergeArgv: [...argv, "--delete-branch"] });
  refuses("merge_forbidden_flag", { ...merge, mergeArgv: [...argv, "--admin"] });
  refuses("merge_method", { ...merge, mergeArgv: ["gh", "pr", "merge", "7", "--squash", "--match-head-commit", H] });
  // approval-binding: decision_recorded and durable.
  const bind = { attempt: { ...attempt, at: "2026-10-28T00:00:00Z" }, remotePrHead: H, prBase: B, state: "decision_recorded" };
  assert.equal(gateApprovalBinding(bind).state, "decision_recorded");
  const ref = { exists: true, parent: H, diffPaths: [DELIVERY], pushed: false, marker: { status: "consuming", pr: 7, head: H, base: B }, otherConsuming: false };
  assert.equal(gateApprovalBinding({ ...bind, state: "durable", approvalRef: ref }).state, "durable");
  const durable = (change) => ({ ...bind, state: "durable", approvalRef: { ...ref, ...change } });
  refuses("head_moved_after_display", { ...bind, remotePrHead: M }, gateApprovalBinding);
  refuses("approval_not_fresh_allow", { ...bind, attempt: { ...bind.attempt, decision: "hold" } }, gateApprovalBinding);
  refuses("approval_not_fresh_allow", { ...bind, attempt: { ...bind.attempt, consumed: true } }, gateApprovalBinding);
  refuses("approval_ref_missing", durable({ exists: false }), gateApprovalBinding);
  refuses("approval_ref_wrong_parent", durable({ parent: M }), gateApprovalBinding);
  refuses("approval_ref_extra_diff", durable({ diffPaths: [DELIVERY, "lib/x.ex"] }), gateApprovalBinding);
  refuses("approval_ref_pushed", durable({ pushed: true }), gateApprovalBinding);
  refuses("approval_marker_mismatch", durable({ marker: { status: "consumed", pr: 7, head: H, base: B } }), gateApprovalBinding);
  refuses("approval_other_attempt_consuming", durable({ otherConsuming: true }), gateApprovalBinding);
  // pr-open and ready on isolated inputs.
  const body = `Change summary.\n\n${REQUIRED_STATEMENT}\n`;
  const delivery = JSON.stringify({ spec04: { ...spec04 }, pr: { number: 7 } });
  const open = { ...base, localHead: H, remoteHead: H, privacyExit: 0, baseContained: true, bodyText: body, deliveryText: delivery,
    pr: { number: 7, state: "OPEN", baseRefName: "main", headRefOid: H, body, title: "fix(196): spec and structure ratchet" } };
  assert.equal(gatePrOpen(open).stage, "pr-open");
  refuses("remote_sha_mismatch", { ...open, remoteHead: M }, gatePrOpen);
  refuses("privacy_scan_failed", { ...open, privacyExit: 1 }, gatePrOpen);
  refuses("base_behind", { ...open, baseContained: false }, gatePrOpen);
  refuses("candidate_stale", { ...open, identityNow: { ...identity, phase_evidence_sha256: "z" } }, gatePrOpen);
  refuses("required_statement_missing", { ...open, bodyText: "Change summary.\n", pr: { ...open.pr, body: "Change summary.\n" } }, gatePrOpen);
  refuses("spec04_prose_claim", { ...open, bodyText: `${body}\nThe Muex pilot passed.\n`, pr: { ...open.pr, body: `${body}\nThe Muex pilot passed.\n` } }, gatePrOpen);
  refuses("spec04_disposition", { ...open, deliveryText: JSON.stringify({ spec04: { disposition: "adopted" } }) }, gatePrOpen);
  refuses("pr_head_mismatch", { ...open, pr: { ...open.pr, headRefOid: M } }, gatePrOpen);
  refuses("pr_body_mismatch", { ...open, pr: { ...open.pr, body: "different" } }, gatePrOpen);
  refuses("review_high_open", { ...open, review: { open_high: 1 } }, gatePrOpen);
  const run = (name, status, conclusion, sha = H) => ({ name, status, conclusion, head_sha: sha });
  const ready = { ...base, localHead: H, remoteHead: H, pr: { state: "OPEN", headRefOid: H }, requiredContexts: ["Crosswake CI"], checkRuns: [run("Crosswake CI", "completed", "success")], syntheticSha: M, externalOpenHigh: 0 };
  assert.equal(gateReady(ready).stage, "ready");
  refuses("check_inventory_empty", { ...ready, checkRuns: [] }, gateReady);
  refuses("required_checks_empty", { ...ready, requiredContexts: [] }, gateReady);
  refuses("required_check_missing", { ...ready, checkRuns: [run("Other", "completed", "success")] }, gateReady);
  refuses("required_check_pending", { ...ready, checkRuns: [run("Crosswake CI", "in_progress", null)] }, gateReady);
  refuses("required_check_failed", { ...ready, checkRuns: [run("Crosswake CI", "completed", "failure")] }, gateReady);
  refuses("check_head_mismatch", { ...ready, checkRuns: [run("Crosswake CI", "completed", "success", M)] }, gateReady);
  refuses("synthetic_identity_conflated", { ...ready, syntheticSha: H }, gateReady);
  refuses("external_high_open", { ...ready, externalOpenHigh: 1 }, gateReady);
  refuses("protected_branch_bypass", { ...ready, protectedBypass: true }, gateReady);
  assert.equal(POLL_SECONDS, 60); assert.equal(POLL_MAX, 90);
  await realChildControls();
  assert.ok(Date.now() - started < DEADLINE_MS, "merge scope exceeded its deadline");
  return { scope: "merge", ms: Date.now() - started };
}
// Isolation controls (fix-forward for the 2026-10-29 actual-main refusal): a child that rewrites a tracked evidence
// file must not disturb the main checkout, per-child results survive any refusal, and the linked worktree is always removed.
function landedFixture() {
  const f = fixtureRepo();
  f.put(".gitignore", "_build/\ndeps/\n"); f.g("add", ".gitignore");
  mkdirSync(path.join(f.root, ".planning/ev"), { recursive: true });
  f.put(".planning/ev/x-vectors.json", `${JSON.stringify({ d: 1 })}\n`); f.g("add", ".planning/ev/x-vectors.json");
  f.g("commit", "-q", "-m", "evidence receipt");
  mkdirSync(path.join(f.root, "_build"), { recursive: true }); f.put("_build/cache.txt", "stale build output\n");
  mkdirSync(path.join(f.root, "deps"), { recursive: true }); f.put("deps/cache.txt", "fetched\n");
  const rewrite = "require('fs').writeFileSync('.planning/ev/x-vectors.json', JSON.stringify({ d: Date.now() }) + '\\n');" +
    "console.log(require('fs').existsSync('deps/cache.txt') && !require('fs').existsSync('_build/cache.txt') ? 'warm' : 'cold');";
  const child = (id, code, lastLine) => ({ id, req: [], kind: "version", route: "plain", command: process.execPath, args: ["-e", code], cwd: ".", expect: { lastLine } });
  return { ...f, rewrite, child, mergeSha: ref40(f.root, "HEAD") };
}
async function landedIsolationControls() {
  const f = landedFixture();
  try {
    const gitDir = path.resolve(f.root, git(f.root, ["rev-parse", "--git-common-dir"]));
    const wt = path.join(gitDir, "crosswake-196-landed");
    const receipt = () => readFileSync(path.join(f.root, ".planning/ev/x-vectors.json"), "utf8");
    const worktrees = () => git(f.root, ["worktree", "list", "--porcelain"]).split("\n").filter((l) => l.startsWith("worktree ")).length;
    const ledger = () => JSON.parse(readFileSync(path.join(gitDir, "crosswake-196-landed-children.json"), "utf8"));
    const before = { inventory: inventoryHash(f.root), receipt: receipt(), branch: git(f.root, ["branch", "--show-current"]), head: ref40(f.root, "HEAD") };
    // The old in-place procedure: detach in the main checkout, run a receipt-rewriting child, switch back. The edit follows the checkout.
    f.g("switch", "-q", "--detach", f.mergeSha);
    await runChild(f.root, process.execPath, ["-e", f.rewrite], { timeout: 5_000 });
    f.g("switch", "-q", "main");
    assert.notEqual(inventoryHash(f.root), before.inventory, "the in-place procedure is the defect: it leaves the receipt rewritten");
    f.g("checkout", "--", ".planning/ev/x-vectors.json");
    assert.equal(inventoryHash(f.root), before.inventory);
    // Isolated run: the child rewrites its own receipt, the main checkout is untouched, results persist, the worktree is gone.
    const ok = await runLandedRegistry(f.root, f.mergeSha, { registry: [f.child("rewrite", f.rewrite, "warm")], progress: false });
    assert.equal(ok.children.length, 1); assert.equal(ok.children[0].status, "pass");
    assert.equal(inventoryHash(f.root), before.inventory, "a landed run must leave the main inventory unchanged");
    assert.equal(receipt(), before.receipt); assert.equal(git(f.root, ["branch", "--show-current"]), before.branch); assert.equal(ref40(f.root, "HEAD"), before.head);
    assert.equal(existsSync(wt), false); assert.equal(worktrees(), 1);
    assert.equal(ledger().children.length, 1); assert.equal(ledger().phase, "complete"); assert.equal(ledger().cleanup, "removed");
    assert.deepEqual(ledger().warmed, ["deps"], "fetched inputs are cloned into the worktree and build output never is");
    // A failing child is judged, kept in the ledger, and the run continues to the next child.
    const failing = await runLandedRegistry(f.root, f.mergeSha, { registry: [f.child("bad", "process.exit(3)", "x"), f.child("after", f.rewrite, "warm")], progress: false });
    assert.deepEqual(failing.children.map((c) => `${c.id}:${c.status}`), ["bad:fail", "after:pass"]);
    assert.deepEqual(ledger().children.map((c) => `${c.id}:${c.status}`), ["bad:fail", "after:pass"]);
    assert.equal(existsSync(wt), false); assert.equal(inventoryHash(f.root), before.inventory);
    // A refusal after the first child still leaves that child on disk, and cleanup runs.
    await assert.rejects(runLandedRegistry(f.root, f.mergeSha, { registry: [f.child("one", f.rewrite, "warm")], progress: false,
      afterChild: (children) => { need(children.length < 1, "landed_probe_refusal"); } }), { code: "landed_probe_refusal" });
    assert.deepEqual(ledger().children.map((c) => c.id), ["one"]); assert.equal(ledger().refusal, "landed_probe_refusal");
    assert.equal(existsSync(wt), false); assert.equal(worktrees(), 1); assert.equal(inventoryHash(f.root), before.inventory);
    // A refusal before any child (identity or roster check) is recorded and cleaned up too.
    await assert.rejects(runLandedRegistry(f.root, f.mergeSha, { registry: [f.child("never", f.rewrite, "warm")], progress: false,
      prepare: () => { throw new Refusal("roster_digest_changed"); } }), { code: "roster_digest_changed" });
    assert.deepEqual(ledger().children, []); assert.equal(ledger().refusal, "roster_digest_changed");
    assert.equal(existsSync(wt), false); assert.equal(worktrees(), 1);
    // A stale worktree directory from a killed run is replaced, not trusted, and earlier ledgers are rotated, never overwritten.
    f.g("worktree", "add", "-q", "--detach", wt, f.mergeSha); writeFileSync(path.join(wt, "stale.txt"), "stale\n");
    const again = await runLandedRegistry(f.root, f.mergeSha, { registry: [f.child("fresh", f.rewrite, "warm")], progress: false });
    assert.equal(again.children[0].status, "pass"); assert.equal(existsSync(wt), false); assert.equal(worktrees(), 1);
    assert.ok(readdirSync(gitDir).filter((name) => /^crosswake-196-landed-children\..+\.json$/.test(name)).length >= 3, "earlier ledgers are rotated");
    assert.equal(inventoryHash(f.root), before.inventory);
  } finally { f.cleanup(); }
}
// The explicit-format child must stay non-empty after the work lands: once the merge commit is on main, a diff against
// origin/main is empty by construction, so the changed Elixir files are read against the recorded base instead.
function formatScopeControls() {
  const f = fixtureRepo();
  try {
    const base = ref40(f.root, "HEAD");
    f.g("switch", "-q", "-c", "feature"); f.put("x.ex", "defmodule X do\nend\n"); f.put("y.exs", ":ok\n"); f.put("note.txt", "n\n");
    f.g("add", "x.ex", "y.exs", "note.txt"); f.g("commit", "-q", "-m", "feature");
    f.g("switch", "-q", "main"); f.g("merge", "-q", "--no-ff", "-m", "merge feature", "feature");
    f.g("update-ref", "refs/remotes/origin/main", ref40(f.root, "HEAD"));
    assert.equal(git(f.root, ["diff", "--name-only", "origin/main", "HEAD"]), "", "after the merge the diff against origin/main is empty");
    const args = expandArgs(f.root, ["format", "--check-formatted", "@changed-elixir"], base);
    assert.deepEqual(args, ["format", "--check-formatted", "x.ex", "y.exs"]);
    assert.deepEqual(expandArgs(f.root, ["format", "--check-formatted", "@changed-elixir"], ref40(f.root, "HEAD")), ["format", "--check-formatted"]);
    assert.match(FORMAT_BASE, /^[0-9a-f]{40}$/);
  } finally { f.cleanup(); }
}
async function selfTestLanded(root) {
  const started = Date.now();
  const f = fixtureRepo();
  try {
    f.g("switch", "-q", "-c", "feature"); f.put("b.txt", "b\n"); f.g("add", "b.txt"); f.g("commit", "-q", "-m", "feature");
    const head = ref40(f.root, "HEAD");
    f.g("switch", "-q", "main");
    const base = ref40(f.root, "HEAD");
    f.g("merge", "-q", "--no-ff", "-m", "merge feature", "feature");
    const merged = ref40(f.root, "HEAD");
    const attempt = { head, base };
    const commit = readMergeCommit(f.root, merged, attempt);
    assert.equal(commit.parents.length, 2);
    assert.deepEqual(judgeMergeCommit(commit), { landed_as_displayed: true, base_drift_at_write: false });
    // Base drift: main advanced after display, so the first parent differs and the approved attempt is not "landed as displayed".
    f.g("reset", "-q", "--hard", base); f.put("c.txt", "c\n"); f.g("add", "c.txt"); f.g("commit", "-q", "-m", "main advanced");
    f.g("merge", "-q", "--no-ff", "-m", "merge feature late", "feature");
    assert.deepEqual(judgeMergeCommit(readMergeCommit(f.root, ref40(f.root, "HEAD"), attempt)), { landed_as_displayed: false, base_drift_at_write: true });
    assert.throws(() => judgeMergeCommit({ parents: [base], attempt }), { code: "merge_not_two_parent" });
    assert.throws(() => judgeMergeCommit({ parents: [base, "e".repeat(40)], attempt }), { code: "merge_excludes_approved_head" });
    // Restoration predicate: detach, change a tracked byte, and the inventory hash must differ.
    const before = inventoryHash(f.root);
    f.g("switch", "-q", "--detach", base);
    f.g("switch", "-q", "main");
    assert.equal(inventoryHash(f.root), before);
    f.put("a.txt", "changed\n");
    assert.notEqual(inventoryHash(f.root), before);
  } finally { f.cleanup(); }
  const plan = { registryComplete: true, children: REGISTRY.length, pushTarget: EVIDENCE_BRANCH, evidenceBase: "m", mergeCommit: "m", restored: true, dirty: false, consumedWrittenOn: EVIDENCE_BRANCH, validationUnchanged: true };
  assert.doesNotThrow(() => checkLandedPlan(plan));
  const refuses = (code, change) => assert.throws(() => checkLandedPlan({ ...plan, ...change }), { code }, code);
  refuses("landed_registry_incomplete", { registryComplete: false });
  refuses("landed_registry_incomplete", { children: REGISTRY.length - 1 });
  refuses("landed_push_target", { pushTarget: "main" });
  refuses("landed_evidence_base", { evidenceBase: "main-tip" });
  refuses("landed_restoration", { dirty: true });
  refuses("landed_restoration", { restored: false });
  refuses("consumed_record_location", { consumedWrittenOn: "main" });
  refuses("validation_modified", { validationUnchanged: false });
  assert.equal(reconcileMarker({ marker: null, remote: {} }), "none");
  assert.equal(reconcileMarker({ marker: { status: "consuming", head: "h" }, remote: { merged: true, mergedHead: "h" } }), "landed_continue");
  assert.equal(reconcileMarker({ marker: { status: "consuming", head: "h" }, remote: { merged: false } }), "unconsumed_uncertain");
  assert.equal(reconcileMarker({ marker: { status: "consuming", head: "h" }, remote: { merged: true, mergedHead: "other" } }), "unconsumed_uncertain");
  assert.throws(() => scanClaims(JSON.stringify({ spec04: { disposition: "moved_to_v29" }, note: "SPEC-04 is complete." }), "json"), { code: "spec04_prose_claim" });
  assert.throws(() => scanClaims("The pilot passed.", "markdown"), { code: "spec04_prose_claim" });
  formatScopeControls();
  await landedIsolationControls();
  await realChildControls();
  assert.ok(Date.now() - started < DEADLINE_MS, "landed scope exceeded its deadline");
  return { scope: "landed", ms: Date.now() - started };
}

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
const SCOPES = { disposition: selfTestDisposition, promotion: selfTestPromotion, candidate: selfTestCandidate, merge: selfTestMerge, landed: selfTestLanded };
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
  } else if (mode === "promotion") {
    need(Object.keys(opts).length === 0, "invalid_arguments");
    console.log(JSON.stringify(checkPromotion(gatherPromotion(root)), null, 2));
  } else if (mode === "candidate") {
    need(Object.keys(opts).every((key) => ["observe", "only"].includes(key)), "invalid_arguments");
    await candidate(root, { observe: opts.observe === "yes", only: opts.only ? opts.only.split(",") : null });
  } else if (mode === "gate") {
    need(Object.keys(opts).every((key) => ["stage", "poll", "execute", "state"].includes(key)), "invalid_arguments");
    console.log(JSON.stringify(await runGate(root, opts)));
  } else if (mode === "landed") {
    need(Object.keys(opts).length === 0, "invalid_arguments");
    await landed(root);
  } else throw new Refusal("invalid_mode");
}
if (path.resolve(process.argv[1] ?? "") === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(`phase-evidence: refused ${error instanceof Refusal ? error.code : "internal_error"}${error instanceof Refusal && error.detail ? ` (${String(error.detail).slice(0, 80)})` : ""}`);
    if (!(error instanceof Refusal) && process.env.PHASE_EVIDENCE_DEBUG === "1") console.error(error);
    process.exitCode = 1;
  });
}
export { scanClaims, disposition, candidateIdentity, checkDisposition, checkPromotion, runChild, sha, Refusal, runLandedRegistry, REGISTRY };
