#!/usr/bin/env node
// Phase-only tooling. Scratch contains tools or synthetic git fixtures, never candidate product state.
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { closeSync, existsSync, lstatSync, mkdirSync, mkdtempSync, openSync, readFileSync, readdirSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const PHASE = ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet";
const SOURCE = `${PHASE}/196-EVIDENCE/execution-source.json`;
const CONTROLS = `${PHASE}/196-EVIDENCE/measurement-controls.json`;
const AMENDMENT = `${PHASE}/196-EVIDENCE/source-amendment-13-14.json`;
const AMENDED_PLANS = [13, 14].map((n) => `${PHASE}/196-${n}-PLAN.md`);
const RESOLUTION = `${PHASE}/196-EVIDENCE/MUEX-ATTEMPT-RESOLUTION.md`;
// One reviewed historical amendment, not a caller-authored exception registry.
const REVIEWED_AMENDMENT = {
  commit: "dad4d998c63da02ef6c80d4745cd3c4659e20cb9",
  parent: "52bebc6cfd774f2dbf35e80074135ffa7303cb95",
  sourceCommit: "8b613331f6b81419e1e4eb928355d5a20692e1ff",
  sourceSha256: "4395af905530c1d1bd5680276faf2e6586f21352bfaf65c4bf7a807bf6c16aec",
};
const REPLAN_EVIDENCE = `${PHASE}/196-EVIDENCE/source-amendment-15-17.json`;
const REPLAN_PLANS = [15, 16, 17].map((n) => `${PHASE}/196-${n}-PLAN.md`);
// Second fixed reviewed identity (SPEC-04 move to v29.0 and replan of 196-15..17). Like
// REVIEWED_AMENDMENT it is a constant, never a caller-supplied registry or override.
// base: newest ancestor whose 15/16/17 plans hold their execution-source.json hashes.
const REVIEWED_REPLAN = {
  base: "90a809ce43adec4fb2b04ae38e658854317c9d9c",
  commit: "f04c98cff8188099ac58ea21f78bdde129dc31c6",
  paths: REPLAN_PLANS,
};
const PRIVACY = ".planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/privacy-193.sh";
const SELF = `${PHASE}/scripts/measure-main.mjs`;
const OWNER_ROOT = realpathSync(path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../../../../../.."));
const BRANCH = "fix/spec-structure-ratchet";
const PRESERVED = "docs/195-closeout";
const RECEIPTS = ["privacy-push-195.txt", "privacy-push2-195.txt"].map((name) =>
  `.planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/${name}`);
const sha = (bytes) => createHash("sha256").update(bytes).digest("hex");
const sorted = (xs) => [...xs].sort();
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
class Refusal extends Error { constructor(code) { super(code); this.code = code; } }
function need(value, code) { if (!value) throw new Refusal(code); }
function child(root, command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root, encoding: "utf8", timeout: 30_000, maxBuffer: 16 * 1024 * 1024,
    ...options,
  });
  if (result.error?.code === "ETIMEDOUT") throw new Refusal("child_timeout");
  need(!result.error && result.signal === null && Number.isInteger(result.status), "child_interrupted");
  return result;
}
function git(root, args, options = {}) {
  const result = child(root, "git", args, options);
  need(result.status === 0, "git_command_failed");
  return result.stdout.trimEnd();
}
function fullRef(root, ref) {
  need(typeof ref === "string" && /^(?:HEAD|[A-Za-z0-9][A-Za-z0-9._/\-]*)$/.test(ref), "invalid_ref");
  const value = git(root, ["rev-parse", "--verify", `${ref}^{commit}`]);
  need(/^[0-9a-f]{40}$/.test(value), "invalid_commit");
  return value;
}
function rel(value) {
  need(typeof value === "string" && value.length > 0 && !path.isAbsolute(value) &&
    !value.split("/").some((part) => ["", ".", ".."].includes(part)) && !/[\r\n\t\0]/.test(value), "invalid_path");
  return value;
}
function fileAt(root, name) {
  rel(name);
  const target = path.join(root, name);
  need(existsSync(target) && lstatSync(target).isFile() && realpathSync(target).startsWith(`${realpathSync(root)}/`), "source_file_missing");
  return readFileSync(target);
}
function object(root, ref, name) {
  rel(name);
  const result = child(root, "git", ["show", `${ref}:${name}`], { encoding: null });
  need(result.status === 0, "source_object_missing");
  return result.stdout;
}
function names(root, ref) {
  return git(root, ["ls-tree", "-r", "--name-only", ref]).split("\n").filter(Boolean).map(rel);
}
function sourceRoster(root, ref) {
  return git(root, ["ls-tree", "-r", ref]).split("\n").filter(Boolean).map((line) => {
    const match = /^(\d+) blob ([0-9a-f]{40})\t(.+)$/.exec(line);
    need(match && ["100644", "100755"].includes(match[1]), "unsupported_tree_entry");
    return { path: rel(match[3]), blob: match[2] };
  }).filter(({ path: p }) => !p.startsWith(".planning/"));
}
function ancestry(root, ancestor, descendant) {
  need(child(root, "git", ["merge-base", "--is-ancestor", ancestor, descendant]).status === 0, "main_not_ancestor");
}
function noTrackedChanges(root) {
  need(git(root, ["diff", "--name-only"]) === "" && git(root, ["diff", "--cached", "--name-only"]) === "", "dirty_tracked_source");
}
function sourceRecord(root, { main, preserved, transfer, original }) {
  const mainSha = fullRef(root, main);
  const preservedSha = fullRef(root, preserved);
  const transferSha = fullRef(root, transfer);
  const changed = git(root, ["diff", "--name-only", mainSha, preservedSha]).split("\n").filter(Boolean);
  need(changed.length > 0 && changed.every((p) => p.startsWith(".planning/")), "mixed_preservation_scope");
  const preservedFiles = changed.map((name) => ({ path: name, sha256: sha(object(root, preservedSha, name)) }));
  const protectedFiles = preservedFiles.filter(({ path: p }) => RECEIPTS.includes(p) ||
    (p.startsWith(`${PHASE}/`) && p.endsWith(".md")));
  const roster = sourceRoster(root, mainSha);
  return {
    schema_version: 1, main_ref: "origin/main", main_sha: mainSha, branch: BRANCH,
    original_head: fullRef(root, original), preserved_ref: PRESERVED, preserved_sha: preservedSha,
    transfer_sha: transferSha, preserved_files: preservedFiles, protected_files: protectedFiles,
    source_roster: roster, source_count: roster.length,
    source_roster_sha256: sha(JSON.stringify(roster)),
    tool_versions: { node: process.version, git: git(root, ["--version"]) },
  };
}
function reviewedAmendment(root, record, reviewed) {
  if (!existsSync(path.join(root, AMENDMENT))) {
    need(child(root, "git", ["merge-base", "--is-ancestor", reviewed.commit, "HEAD"]).status !== 0, "amendment_evidence_missing");
    return new Map();
  }
  need(sha(fileAt(root, SOURCE)) === reviewed.sourceSha256 &&
    sha(object(root, reviewed.sourceCommit, SOURCE)) === reviewed.sourceSha256 &&
    sha(object(root, "HEAD", SOURCE)) === reviewed.sourceSha256, "amendment_source_mismatch");
  ancestry(root, reviewed.sourceCommit, reviewed.parent);
  ancestry(root, record.transfer_sha, reviewed.parent);
  ancestry(root, reviewed.commit, "HEAD");
  need(git(root, ["rev-list", "--parents", "-n", "1", reviewed.commit]) === `${reviewed.commit} ${reviewed.parent}`, "amendment_parent_mismatch");
  const changedProtected = git(root, ["diff", "--name-only", reviewed.parent, reviewed.commit, "--", ...record.protected_files.map((f) => f.path)]).split("\n").filter(Boolean);
  need(same(changedProtected, AMENDED_PLANS), "amendment_scope_mismatch");
  const entries = AMENDED_PLANS.map((name) => {
    const original = record.protected_files.find((f) => f.path === name);
    need(original && sha(object(root, reviewed.parent, name)) === original.sha256, "amendment_baseline_mismatch");
    const after = sha(object(root, reviewed.commit, name));
    need(after !== original.sha256, "amendment_empty");
    need(sha(fileAt(root, name)) === after && sha(object(root, "HEAD", name)) === after, "amendment_stale");
    return { path: name, before_sha256: original.sha256, after_sha256: after };
  });
  const resolutionHash = sha(object(root, reviewed.commit, RESOLUTION));
  need(sha(fileAt(root, RESOLUTION)) === resolutionHash && sha(object(root, "HEAD", RESOLUTION)) === resolutionHash, "amendment_resolution_mismatch");
  const expected = {
    schema_version: 1, purpose: "reviewed_plan13_14_local_attempt_configuration",
    source_receipt_sha256: reviewed.sourceSha256, source_receipt_commit: reviewed.sourceCommit,
    preserved_sha: record.preserved_sha, transfer_sha: record.transfer_sha,
    amendment_commit: reviewed.commit, amendment_parent: reviewed.parent,
    resolution: { path: RESOLUTION, sha256: resolutionHash }, paths: entries,
  };
  let evidence;
  try { evidence = JSON.parse(fileAt(root, AMENDMENT)); } catch { throw new Refusal("amendment_evidence_invalid"); }
  need(same(evidence, expected), "amendment_evidence_mismatch");
  need(sha(fileAt(root, AMENDMENT)) === sha(object(root, "HEAD", AMENDMENT)), "amendment_evidence_uncommitted");
  return new Map(entries.map((entry) => [entry.path, entry.after_sha256]));
}
function reviewedReplan(root, record, reviewed, replan) {
  if (!existsSync(path.join(root, REPLAN_EVIDENCE))) {
    need(child(root, "git", ["merge-base", "--is-ancestor", replan.commit, "HEAD"]).status !== 0, "replan_evidence_missing");
    return new Map();
  }
  // Identity: an unreachable replan is stale; a wrong or non-ancestor base is a scope error.
  need(child(root, "git", ["merge-base", "--is-ancestor", replan.commit, "HEAD"]).status === 0, "replan_stale");
  need(/^[0-9a-f]{40}$/.test(replan.base) && /^[0-9a-f]{40}$/.test(replan.commit), "replan_scope_mismatch");
  need(child(root, "git", ["merge-base", "--is-ancestor", replan.base, replan.commit]).status === 0 && replan.base !== replan.commit, "replan_scope_mismatch");
  need(child(root, "git", ["merge-base", "--is-ancestor", reviewed.commit, replan.base]).status === 0, "replan_scope_mismatch");
  // The delta covers EVERY phase Markdown path and both Phase195 receipts, not only record.protected_files.
  const changed = git(root, ["diff", "--name-only", replan.base, replan.commit, "--", PHASE, ...RECEIPTS]).split("\n").filter(Boolean)
    .filter((name) => RECEIPTS.includes(name) || (name.startsWith(`${PHASE}/`) && name.endsWith(".md")));
  need(same(sorted(changed), sorted(replan.paths)), "replan_scope_mismatch");
  const entries = replan.paths.map((name) => {
    const original = record.protected_files.find((f) => f.path === name);
    need(original && sha(object(root, replan.base, name)) === original.sha256, "replan_scope_mismatch");
    const after = sha(object(root, replan.commit, name));
    need(after !== original.sha256, "replan_scope_mismatch");
    need(sha(fileAt(root, name)) === after && sha(object(root, "HEAD", name)) === after, "replan_stale");
    return { path: name, before_sha256: original.sha256, after_sha256: after };
  });
  need(sha(fileAt(root, SOURCE)) === reviewed.sourceSha256 && sha(object(root, "HEAD", SOURCE)) === reviewed.sourceSha256, "replan_evidence_mismatch");
  const expected = {
    schema_version: 1, purpose: "reviewed_plan15_17_spec04_move_replan",
    source_receipt_sha256: reviewed.sourceSha256, source_receipt_commit: reviewed.sourceCommit,
    preserved_sha: record.preserved_sha, transfer_sha: record.transfer_sha,
    replan_base: replan.base, replan_commit: replan.commit, paths: entries,
  };
  let evidence;
  try { evidence = JSON.parse(fileAt(root, REPLAN_EVIDENCE)); } catch { throw new Refusal("replan_evidence_mismatch"); }
  need(same(evidence, expected), "replan_evidence_mismatch");
  let committed;
  try { committed = object(root, "HEAD", REPLAN_EVIDENCE); } catch { throw new Refusal("replan_evidence_uncommitted"); }
  need(sha(fileAt(root, REPLAN_EVIDENCE)) === sha(committed), "replan_evidence_uncommitted");
  return new Map(entries.map((entry) => [entry.path, entry.after_sha256]));
}
function verifySourceAt(root, record, reviewed = REVIEWED_AMENDMENT, replan = REVIEWED_REPLAN) {
  need((reviewed === REVIEWED_AMENDMENT && replan === REVIEWED_REPLAN) || realpathSync(root) !== OWNER_ROOT, "test_adapter_on_repository");
  need(record?.schema_version === 1 && record.branch === BRANCH && record.main_ref === "origin/main" && record.preserved_ref === PRESERVED, "unrecognized_source_state");
  need(fullRef(root, "origin/main") === record.main_sha, "main_ref_mismatch");
  need(git(root, ["branch", "--show-current"]) === BRANCH, "wrong_branch");
  need(fullRef(root, PRESERVED) === record.preserved_sha, "preserved_ref_mismatch");
  ancestry(root, record.main_sha, "HEAD"); ancestry(root, record.transfer_sha, "HEAD");
  ancestry(root, record.original_head, record.preserved_sha);
  const roster = sourceRoster(root, record.main_sha);
  need(Array.isArray(record.source_roster) && record.source_roster.length > 0, "empty_source_roster");
  need(same(roster, record.source_roster) && roster.length === record.source_count && sha(JSON.stringify(roster)) === record.source_roster_sha256, "source_roster_mismatch");
  // Preparation is immutable; later committed product work is verified against its own HEAD.
  need(git(root, ["diff", "--name-only", record.main_sha, record.transfer_sha, "--", ":!.planning"]) === "", "unexpected_supported_code");
  const changes = git(root, ["diff", "--name-only", "HEAD"]).split("\n").filter(Boolean);
  const staged = git(root, ["diff", "--cached", "--name-only"]).split("\n").filter(Boolean);
  need([...changes, ...staged].every((p) => p.startsWith(".planning/")), "dirty_supported_code");
  need(Array.isArray(record.preserved_files) && record.preserved_files.length > 0, "empty_preservation");
  const expected = git(root, ["diff", "--name-only", record.main_sha, record.preserved_sha]).split("\n").filter(Boolean);
  need(same(expected, record.preserved_files.map((entry) => entry.path)) && expected.every((p) => p.startsWith(".planning/")), "preservation_scope_mismatch");
  for (const item of record.preserved_files) {
    need(sha(object(root, record.preserved_sha, item.path)) === item.sha256 &&
      sha(object(root, record.transfer_sha, item.path)) === item.sha256, "preservation_hash_mismatch");
    need(existsSync(path.join(root, rel(item.path))), "preserved_file_lost");
  }
  const protectedFiles = record.preserved_files.filter(({ path: p }) => RECEIPTS.includes(p) ||
    (p.startsWith(`${PHASE}/`) && p.endsWith(".md")));
  need(same(protectedFiles, record.protected_files) && RECEIPTS.every((p) => protectedFiles.some((f) => f.path === p)), "protected_scope_mismatch");
  // The replan scope is judged first so an extra edit to a 13/14 plan inside the replan commit reports replan_scope_mismatch.
  const replans = reviewedReplan(root, record, reviewed, replan);
  const amendments = reviewedAmendment(root, record, reviewed);
  need([...replans.keys()].every((name) => !amendments.has(name)), "replan_scope_mismatch");
  for (const item of protectedFiles) need(sha(fileAt(root, item.path)) === (replans.get(item.path) ?? amendments.get(item.path) ?? item.sha256), "protected_hash_mismatch");
  // Independently hash the worktree as well: a clean index alone is not evidence.
  for (const item of sourceRoster(root, "HEAD")) {
    const bytes = fileAt(root, item.path);
    const blob = createHash("sha1").update(`blob ${bytes.length}\0`).update(bytes).digest("hex");
    need(blob === item.blob, "supported_blob_mismatch");
  }
  return true;
}
function parse(argv) {
  const [mode, ...rest] = argv;
  const opts = {};
  need(["prepare", "verify-source", "source-controls", "capture-controls", "self-test", "capture"].includes(mode), "invalid_mode");
  for (let i = 0; i < rest.length; i += 2) {
    need(/^--[a-z-]+$/.test(rest[i]) && rest[i + 1] && !Object.hasOwn(opts, rest[i].slice(2)), "invalid_arguments");
    opts[rest[i].slice(2)] = rest[i + 1];
  }
  return { mode, opts };
}
function fixture() {
  const root = mkdtempSync(path.join(tmpdir(), "cw196-fixture-"));
  const put = (name, value) => { mkdirSync(path.dirname(path.join(root, name)), { recursive: true }); writeFileSync(path.join(root, name), value); };
  const g = (...args) => git(root, ["-c", "core.hooksPath=/dev/null", "-c", "commit.gpgsign=false", ...args]);
  g("init", "-b", "main");
  g("config", "user.name", "Fixture"); g("config", "user.email", "fixture@users.noreply.github.com");
  put("lib/subject.ex", "defmodule Fixture do\n  def value, do: :ok\nend\n");
  g("add", "lib/subject.ex"); g("commit", "-m", "fixture main");
  const main = fullRef(root, "HEAD");
  g("fetch", ".", "main:refs/remotes/origin/main");
  g("switch", "-c", PRESERVED);
  for (const name of RECEIPTS) put(name, "privacy: clean files 1\n");
  put(`${PHASE}/196-01-PLAN.md`, "fixture source plan\n");
  put(`${PHASE}/196-CONTEXT.md`, "fixture source context\n");
  for (const name of AMENDED_PLANS) put(name, "fixture original criteria\n\n## Ordering and interfaces\n");
  for (const name of REPLAN_PLANS) put(name, "fixture original replan source\n\n## Ordering and interfaces\n");
  g("add", ".planning"); g("commit", "-m", "fixture preserved planning");
  const preserved = fullRef(root, "HEAD");
  g("switch", "-c", BRANCH, main); g("cherry-pick", preserved);
  const record = sourceRecord(root, { main, preserved, transfer: "HEAD", original: preserved });
  return { root, put, g, record, cleanup: () => rmSync(root, { recursive: true, force: true }) };
}
// Fixed tool capsules, not arbitrary user-supplied commands. Guards must report one
// PHASE196_REPORT JSON line in report mode: {schema_version:1,guard,scanned_files,
// counts:{files:N,...},findings:[{file,category,count}]}. Only these closed fields
// are retained; normal tool output is hashed, never copied into proof artifacts.
const CAPSULES = {
  absence: { command: "elixir", files: ["script/check_absence_is_not_success.exs", "script/absence_collection_ast.exs", "script/fixtures/absence_collection_baseline.exs"], args: ["--collections-mode", "report"] },
  compile: { command: "elixir", files: ["script/check_compile_structure.exs", "script/fixtures/compile_cycle_baseline.exs"], args: ["--mode", "report"] },
  rescue: { command: "elixir", files: ["script/check_rescue_boundaries.exs", "script/fixtures/rescue_boundary_exceptions.exs"], args: ["--mode", "report"] },
  dependencies: { command: "elixir", files: ["script/check_runtime_dependencies.exs", "script/evaluate_runtime_dependencies.exs", "script/fixtures/runtime_dependency_baseline.exs"], args: ["--mode", "report"] },
  grammar: { command: process.execPath, files: ["test/js/ci_secret_masking.test.mjs"], mainFiles: ["script/verify_repository.mjs"], args: [] },
};
const COUNT_KEYS = new Set("files tests projects branches executions workflows references candidates supported denied unknown findings cycles compile_cycles compile_connected_cycles all_cycles declarations dependencies rescues exceptions collections".split(" "));
const FINDING_KEYS = new Set("parse_error read_error scope_empty scope_mismatch guard_failure unsafe_collection literal_true glob_without_count compile_cycle compile_connected_cycle cycle_limit manifest_missing manifest_stale source_coverage broad_rescue rescue_exception_mismatch dependency_added dependency_removed dependency_classification missing_justification project_roster denied_statement unknown_statement mask_order mask_missing".split(" "));
function walk(root, base) {
  const target = path.join(root, base);
  if (!existsSync(target)) return [];
  need(lstatSync(target).isDirectory(), "invalid_subject_directory");
  const result = [];
  for (const entry of readdirSync(target, { withFileTypes: true })) {
    if ([".git", "node_modules", "_build", "deps", ".build", "build", ".gradle"].includes(entry.name)) continue;
    const name = `${base}/${entry.name}`;
    if (entry.isDirectory()) result.push(...walk(root, name));
    else if (entry.isFile()) result.push(rel(name));
    else need(!entry.isSymbolicLink(), "symlink_subject");
  }
  return result;
}
function subjectPredicate(guard, name) {
  if (guard === "absence") return /^(?:test\/|packages\/crosswake_[^/]+\/test\/).*\.exs$/.test(name) ||
    /^\.planning\/(?:todos|seeds)\/[^/]+\.md$/.test(name) || /^\.planning\/.*\/deferred-items\.md$/.test(name);
  if (guard === "compile") return /^lib\/.*\.ex$/.test(name);
  if (guard === "rescue") return /^lib\/crosswake\/(?:bridge|policy|router|offline|manifest|compatibility)(?:\.ex|\/.*\.ex)$/.test(name);
  if (guard === "dependencies") return name === "mix.exs" || /^packages\/crosswake_[^/]+\/mix\.exs$/.test(name);
  return /^\.github\/workflows\/[^/]+\.ya?ml$/.test(name);
}
function discover(root, guard) {
  const bases = guard === "absence" ? ["test", "packages", ".planning"] :
    guard === "grammar" ? [".github/workflows"] : guard === "dependencies" ? ["packages"] : ["lib"];
  const files = bases.flatMap((base) => walk(root, base));
  if (guard === "dependencies" && existsSync(path.join(root, "mix.exs"))) files.push("mix.exs");
  return sorted(files.filter((name) => subjectPredicate(guard, name)));
}
function subjectHashes(root, main, files) {
  need(files.length > 0 && new Set(files).size === files.length, "empty_subject_scope");
  return files.map((name) => {
    const expected = sha(object(root, main, name));
    need(sha(fileAt(root, name)) === expected, "subject_object_mismatch");
    return { path: name, sha256: expected };
  });
}
function inventory(root) {
  const tracked = git(root, ["ls-files", "-z"]).split("\0").filter(Boolean).map((name) => ({ path: rel(name), sha256: sha(fileAt(root, name)) }));
  const untracked = git(root, ["ls-files", "--others", "--exclude-standard", "-z"]).split("\0").filter(Boolean).map((name) => ({ path: rel(name), sha256: sha(fileAt(root, name)) }));
  return {
    branch: git(root, ["branch", "--show-current"]), head: fullRef(root, "HEAD"),
    index: sha(git(root, ["ls-files", "--stage"])), tracked, untracked,
  };
}
function privacy(root, paths, script = path.join(root, PRIVACY)) {
  need(paths.length > 0, "empty_privacy_scope");
  const result = child(root, "bash", [script, ...paths.map((name) => path.join(root, rel(name)))], { timeout: 120_000 });
  need(result.status === 0, "privacy_refused");
  return { exit: result.status, files: paths.length };
}
function mutableProcessLines(output) {
  return output.split("\n").filter((line) =>
    /(?:^|[\s/])(?:mix|muex|swift|xcodebuild|gradle|gradlew|beam\.smp)(?:\s|$)/.test(line) ||
    /(?:node\s+.*(?:--test|verify_repository\.mjs|vector-controls\.mjs|muex-pilot\.mjs))/.test(line));
}
function noMutableProcesses(root) {
  const result = child(root, "ps", ["-axo", "pid=,comm=,args="]);
  need(result.status === 0, "process_inventory_unavailable");
  const related = repositoryMutableProcessLines(root, result.stdout, (pid) => {
    const cwd = child(root, "lsof", ["-a", "-p", pid, "-d", "cwd", "-Fn"]);
    if (cwd.status !== 0) return null;
    const paths = cwd.stdout.split("\n").filter((line) => line.startsWith("n")).map((line) => line.slice(1));
    return paths.length === 1 ? paths[0] : null;
  });
  need(related.length === 0, "mutable_process_active");
}
function repositoryMutableProcessLines(root, output, cwdFor) {
  const canonical = realpathSync(root);
  return mutableProcessLines(output).filter((line) => {
    const pid = /^\s*(\d+)\s/.exec(line)?.[1];
    if (!pid) return true;
    const cwd = cwdFor(pid);
    // A missing cwd cannot establish isolation. Explicit repository arguments
    // are related even when a runner was launched from an external directory.
    if (!cwd || [canonical, path.resolve(root)].some((base) => line.includes(`${base}/`) || line.includes(`${base} `))) return true;
    let actual;
    try {
      // lsof still identifies an unlinked cwd. Resolve its existing parent;
      // absence of that parent remains unknown and therefore blocking.
      actual = existsSync(cwd) ? realpathSync(cwd) : path.join(realpathSync(path.dirname(cwd)), path.basename(cwd));
    } catch { return true; }
    return actual === canonical || actual.startsWith(`${canonical}/`);
  });
}
function runGuard(root, command, args, timeout) {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, { cwd: root, detached: true, stdio: ["ignore", "pipe", "pipe"], env: { ...process.env, MIX_ENV: "test" } });
    let stdout = "", stderr = "", terminal = false;
    const stop = (code) => {
      if (terminal) return;
      terminal = true;
      try { process.kill(-proc.pid, "SIGKILL"); } catch { /* Child may already have exited. */ }
      cleanup(); reject(new Refusal(code));
    };
    const onSignal = () => stop("capture_interrupted");
    const timer = setTimeout(() => stop("child_timeout"), timeout);
    const signals = ["SIGINT", "SIGTERM", "SIGHUP"];
    for (const signal of signals) process.once(signal, onSignal);
    function cleanup() { clearTimeout(timer); for (const signal of signals) process.removeListener(signal, onSignal); }
    proc.stdout.on("data", (bytes) => { stdout += bytes; if (stdout.length > 16 * 1024 * 1024) stop("child_output_limit"); });
    proc.stderr.on("data", (bytes) => { stderr += bytes; if (stderr.length > 16 * 1024 * 1024) stop("child_output_limit"); });
    proc.on("error", () => stop("child_start_failed"));
    proc.on("close", (status, signal) => {
      if (terminal) return;
      terminal = true; cleanup();
      if (signal || !Number.isInteger(status)) reject(new Refusal("child_interrupted"));
      else resolve({ status, stdout, stderr });
    });
  });
}
function reportFrom(result, guard, files) {
  need([0, 1].includes(result.status), "guard_process_failed");
  const records = result.stdout.split("\n").filter((line) => line.startsWith("PHASE196_REPORT "));
  need(records.length === 1, "guard_report_missing");
  let report;
  try { report = JSON.parse(records[0].slice("PHASE196_REPORT ".length)); } catch { throw new Refusal("guard_report_malformed"); }
  need(same(sorted(Object.keys(report)), ["counts", "findings", "guard", "scanned_files", "schema_version"]), "guard_report_schema");
  need(report.schema_version === 1 && report.guard === guard, "guard_report_identity");
  need(Array.isArray(report.scanned_files) && same(sorted(report.scanned_files), files), "guard_coverage_mismatch");
  need(report.counts && !Array.isArray(report.counts) && report.counts.files === files.length &&
    Object.entries(report.counts).every(([key, value]) => COUNT_KEYS.has(key) && Number.isSafeInteger(value) && value >= 0), "guard_count_invalid");
  need(Array.isArray(report.findings), "guard_findings_invalid");
  for (const finding of report.findings) {
    need(finding && same(sorted(Object.keys(finding)), ["category", "count", "file"]) && files.includes(finding.file) &&
      FINDING_KEYS.has(finding.category) && Number.isSafeInteger(finding.count) && finding.count > 0, "guard_finding_invalid");
  }
  need(result.status === 0 || report.findings.length > 0, "nonzero_without_findings");
  return report;
}
async function captureAt(root, options, adapters = {}) {
  need(Object.keys(adapters).length === 0 || realpathSync(root) !== OWNER_ROOT, "test_adapter_on_repository");
  const rawLock = path.resolve(root, git(root, ["rev-parse", "--git-path", "phase196-measure-main.lock"]));
  const lock = path.join(realpathSync(path.dirname(rawLock)), path.basename(rawLock));
  need(lock.startsWith(`${realpathSync(root)}/.git/`), "unsupported_git_directory");
  let fd;
  try { fd = openSync(lock, "wx", 0o600); } catch { throw new Refusal("capture_lock_unavailable"); }
  try { return await captureUnlocked(root, options, adapters); }
  finally { closeSync(fd); rmSync(lock); }
}
async function captureUnlocked(root, options, adapters) {
  need(Object.keys(options).every((key) => ["guard", "candidate", "output"].includes(key)), "invalid_arguments");
  const guard = options.guard;
  need(Object.hasOwn(CAPSULES, guard), "unknown_guard");
  const output = rel(options.output);
  need(output.startsWith(`${PHASE}/196-EVIDENCE/`) && output.endsWith(".json"), "output_outside_evidence");
  need(git(root, ["branch", "--show-current"]) === BRANCH, "wrong_branch");
  need(git(root, ["worktree", "list", "--porcelain"]).split("\n").filter((line) => line.startsWith("worktree ")).length === 1, "multiple_checkouts");
  noTrackedChanges(root);
  const candidate = fullRef(root, options.candidate);
  need(candidate === fullRef(root, "HEAD"), "candidate_not_head");
  (adapters.processCheck ?? noMutableProcesses)(root);
  git(root, ["fetch", "origin", "main"]);
  const main = fullRef(root, "origin/main");
  need(!adapters.expectedMain || adapters.expectedMain === main, "wrong_main_sha");
  ancestry(root, main, candidate);
  if (!adapters.privacyScript) for (const name of [PRIVACY, PRIVACY.replace("privacy-193.sh", "paths-193.sh")]) {
    need(sha(fileAt(root, name)) === sha(object(root, main, name)), "privacy_tool_changed");
  }
  const saved = inventory(root);
  const changed = git(root, ["diff", "--name-only", "--diff-filter=ACMRT", main, candidate]).split("\n").filter(Boolean);
  const privacyBefore = privacy(root, changed, adapters.privacyScript);
  const scratch = mkdtempSync(path.join(tmpdir(), "cw196-tools-"));
  const spec = adapters.spec ?? CAPSULES[guard];
  let detached = false, report, run, subjects, tools;
  const started = Date.now();
  try {
    tools = [...spec.files.map((name) => [candidate, name, "candidate"]), ...(spec.mainFiles ?? []).map((name) => [main, name, "main"])].map(([ref, name, origin]) => {
      const bytes = object(root, ref, name);
      const target = path.join(scratch, rel(name));
      mkdirSync(path.dirname(target), { recursive: true }); writeFileSync(target, bytes);
      return { path: name, origin, blob: git(root, ["rev-parse", `${ref}:${name}`]), sha256: sha(bytes) };
    });
    need(tools.length > 0 && tools[0].origin === "candidate", "empty_tool_capsule");
    git(root, ["switch", "--detach", main]); detached = true;
    need(fullRef(root, "HEAD") === main && git(root, ["branch", "--show-current"]) === "", "wrong_detached_source");
    noTrackedChanges(root);
    const files = (adapters.discover ?? discover)(root, guard);
    const expectedFiles = sorted(names(root, main).filter((name) => (adapters.subjectPredicate ?? subjectPredicate)(guard, name)));
    need(files.length > 0, "empty_subject_scope");
    need(same(files, expectedFiles), "subject_scope_mismatch");
    subjects = subjectHashes(root, main, files);
    const entry = path.join(scratch, spec.files[0]);
    const args = guard === "grammar" && !adapters.spec ? [entry, "--phase196-census-root", root] : [entry, ...spec.args, "--root", root];
    run = await runGuard(root, spec.command, args, adapters.timeout ?? 300_000);
    need(fullRef(root, "HEAD") === main && git(root, ["branch", "--show-current"]) === "", "guard_changed_source_ref");
    noTrackedChanges(root);
    need(same(subjects, subjectHashes(root, main, files)) && same((adapters.discover ?? discover)(root, guard), files), "subject_changed");
    for (const tool of tools) need(sha(readFileSync(path.join(scratch, tool.path))) === tool.sha256, "tool_capsule_changed");
    report = reportFrom(run, guard, files);
    // The detached report stays outside the checkout until restoration is proved.
    writeFileSync(path.join(scratch, "report.json"), `${JSON.stringify(report)}\n`);
  } finally {
    try {
      if (detached) {
        need(git(root, ["diff", "--name-only"]) === "" && git(root, ["diff", "--cached", "--name-only"]) === "", "restoration_dirty_source");
        (adapters.restore ?? ((where, branch) => git(where, ["switch", branch])))(root, saved.branch);
      }
      need(same(inventory(root), saved), "restoration_inventory_mismatch");
    } catch {
      throw new Refusal("restoration_failed");
    } finally {
      rmSync(scratch, { recursive: true, force: true });
    }
  }
  const privacyAfter = privacy(root, changed, adapters.privacyScript);
  const receipt = {
    schema_version: 1, guard, candidate_sha: candidate, main_ref: "origin/main", main_sha: main,
    guard_blob: tools[0].blob, guard_sha256: tools[0].sha256, tools,
    subject_count: subjects.length, subjects, subject_sha256: sha(JSON.stringify(subjects)),
    command: [path.basename(spec.command), spec.files[0], ...(guard === "grammar" && !adapters.spec ? ["--phase196-census-root", "<actual-main>"] : [...spec.args, "--root", "<actual-main>"])],
    process_exit: run.status, stdout_sha256: sha(run.stdout), stderr_sha256: sha(run.stderr),
    counts: report.counts, findings: report.findings,
    restoration: { branch: saved.branch, head: saved.head, index_sha256: saved.index,
      tracked_count: saved.tracked.length, tracked_sha256: sha(JSON.stringify(saved.tracked)),
      untracked_count: saved.untracked.length, untracked_sha256: sha(JSON.stringify(saved.untracked)) },
    privacy_before: privacyBefore, privacy_after: privacyAfter, duration_ms: Date.now() - started,
  };
  // Reject output symlinks and parent traversal, including a symlinked parent.
  const parent = path.dirname(path.join(root, output));
  let ancestor = parent;
  while (!existsSync(ancestor)) ancestor = path.dirname(ancestor);
  need(realpathSync(ancestor) === realpathSync(root) || realpathSync(ancestor).startsWith(`${realpathSync(root)}/`), "unsafe_output_path");
  mkdirSync(parent, { recursive: true });
  need(realpathSync(parent).startsWith(`${realpathSync(root)}/`) && (!existsSync(path.join(root, output)) || lstatSync(path.join(root, output)).isFile()), "unsafe_output_path");
  const publication = mkdtempSync(path.join(tmpdir(), "cw196-publication-"));
  try {
    const bytes = `${JSON.stringify(receipt, null, 2)}\n`;
    const staged = path.join(publication, "receipt.json"); writeFileSync(staged, bytes);
    need(child(root, "bash", [adapters.privacyScript ?? path.join(root, PRIVACY), staged], { timeout: 120_000 }).status === 0, "privacy_refused");
    writeFileSync(path.join(root, output), bytes);
  } finally { rmSync(publication, { recursive: true, force: true }); }
  return receipt;
}
function captureFixture() {
  const f = fixture();
  f.g("remote", "add", "origin", ".");
  f.put("lib/subject.ex", "defmodule Fixture do\n  def value, do: :candidate\nend\n");
  f.report = { schema_version: 1, guard: "absence", scanned_files: ["lib/subject.ex"], counts: { files: 1 }, findings: [] };
  f.guard = (extra = "", report = f.report, status = 0) => {
    f.put("script/fixture-guard.mjs", `import {execFileSync} from 'node:child_process';\nimport {readFileSync,writeFileSync} from 'node:fs';\nimport assert from 'node:assert/strict';\nassert.equal(execFileSync('git',['branch','--show-current'],{encoding:'utf8'}).trim(),'');\nassert.ok(readFileSync('lib/subject.ex','utf8').includes(':ok'));\n${extra}\nprocess.stdout.write('PHASE196_REPORT '+JSON.stringify(${JSON.stringify(report)})+'\\n');\nprocess.exitCode=${status};\n`);
    f.g("add", "script/fixture-guard.mjs", "lib/subject.ex"); f.g("commit", "--allow-empty", "-m", "fixture candidate tool");
  };
  f.guard();
  f.options = { guard: "absence", candidate: "HEAD", output: `${PHASE}/196-EVIDENCE/fixture-report.json` };
  f.adapters = {
    privacyScript: path.join(process.cwd(), PRIVACY), processCheck: () => {},
    spec: { command: process.execPath, files: ["script/fixture-guard.mjs"], args: [] },
    discover: (root) => sorted(walk(root, "lib").filter((p) => p.endsWith(".ex"))),
    subjectPredicate: (_guard, name) => /^lib\/.*\.ex$/.test(name),
  };
  return f;
}
function captureTests() {
  test("process isolation rejects repository and unknown cwd while ignoring foreign processes", () => {
    const f = captureFixture(); try {
      const row = "20 beam.smp beam.smp\n";
      assert.equal(repositoryMutableProcessLines(f.root, row, () => f.root).length, 1);
      assert.equal(repositoryMutableProcessLines(f.root, row, () => null).length, 1);
      assert.equal(repositoryMutableProcessLines(f.root, row, () => path.dirname(f.root)).length, 0);
      assert.equal(repositoryMutableProcessLines(f.root, row, () => path.join(path.dirname(f.root), "removed-foreign-cwd")).length, 0);
      assert.equal(repositoryMutableProcessLines(f.root, row, () => path.join(f.root, "removed-cwd")).length, 1);
      assert.equal(repositoryMutableProcessLines(f.root, row, () => "/unavailable-parent/unknown").length, 1);
      assert.equal(repositoryMutableProcessLines(f.root, `20 beam.smp beam.smp ${f.root}/test\n`, () => path.dirname(f.root)).length, 1);
    } finally { f.cleanup(); }
  });
  test("process isolation discriminates real mutable child working directories in real git fixtures", async () => {
    const local = captureFixture(), foreign = captureFixture();
    let proc;
    const start = async (cwd) => {
      proc = spawn(process.execPath, ["-e", "setInterval(()=>{},1000)", "--", "--test"], { cwd, stdio: "ignore" });
      await new Promise((resolve, reject) => { proc.once("spawn", resolve); proc.once("error", reject); });
    };
    const stop = async () => {
      const ended = new Promise((resolve) => proc.once("close", resolve));
      proc.kill("SIGTERM"); await ended; proc = null;
    };
    try {
      await start(foreign.root);
      assert.doesNotThrow(() => noMutableProcesses(local.root));
      await stop();
      await start(local.root);
      assert.throws(() => noMutableProcesses(local.root), { code: "mutable_process_active" });
      await stop();
      assert.doesNotThrow(() => noMutableProcesses(local.root));
    } finally { if (proc) await stop(); local.cleanup(); foreign.cleanup(); }
  });
  test("capture refuses wrong fetched source before executing guard", async () => {
    const f = captureFixture(); try {
      await assert.rejects(captureAt(f.root, f.options, { ...f.adapters, expectedMain: "0".repeat(40) }), { code: "wrong_main_sha" });
    } finally { f.cleanup(); }
  });
  test("capture reads actual main and restores candidate branch plus protected and untracked bytes", async () => {
    const f = captureFixture(); try {
      f.put("untracked-record.txt", "retained synthetic record\n");
      const before = inventory(f.root);
      const result = await captureAt(f.root, f.options, f.adapters);
      assert.equal(result.main_sha, f.record.main_sha);
      assert.equal(result.process_exit, 0); assert.equal(result.subject_count, 1);
      assert.equal(result.guard_sha256, sha(object(f.root, result.candidate_sha, "script/fixture-guard.mjs")));
      const after = inventory(f.root);
      assert.deepEqual(after.tracked, before.tracked); assert.equal(after.head, before.head);
      assert.equal(after.branch, before.branch); assert.equal(after.index, before.index);
      assert.deepEqual(after.untracked.filter((entry) => entry.path !== f.options.output), before.untracked);
      // Recapture exercises an existing, untracked output without a detach collision.
      await captureAt(f.root, f.options, f.adapters);
      assert.equal(fullRef(f.root, "HEAD"), before.head);
    } finally { f.cleanup(); }
  });
  test("capture preserves a report-mode finding exit without treating it as process success", async () => {
    const f = captureFixture(); try {
      f.guard("", { ...f.report, findings: [{ file: "lib/subject.ex", category: "unsafe_collection", count: 1 }] }, 1);
      const result = await captureAt(f.root, f.options, f.adapters);
      assert.equal(result.process_exit, 1); assert.equal(result.findings.length, 1);
    } finally { f.cleanup(); }
  });
  const controls = [
    ["empty inventory", "empty_subject_scope", (_f, a) => { a.discover = () => []; }],
    ["failed child", "guard_process_failed", (f) => { f.guard("", f.report, 7); }],
    ["interrupted child", "child_interrupted", (f) => { f.guard("process.kill(process.pid,'SIGTERM');"); }],
    ["child timeout", "child_timeout", (f, a) => { f.guard("await new Promise(r=>setTimeout(r,10000));"); a.timeout = 50; }],
    ["restoration failure", "restoration_failed", (_f, a) => { a.restore = () => {}; }],
    ["uncommitted candidate", "dirty_tracked_source", (f) => { f.put("script/fixture-guard.mjs", "changed\n"); }],
    ["candidate revision mismatch", "candidate_not_head", (f) => { f.options.candidate = f.record.main_sha; }],
    ["coverage omission", "guard_coverage_mismatch", (f) => { f.guard("", { ...f.report, scanned_files: [] }); }],
    ["zero file count", "guard_count_invalid", (f) => { f.guard("", { ...f.report, counts: { files: 0 } }); }],
    ["caller success field", "guard_report_schema", (f) => { f.guard("", { ...f.report, success: true }); }],
    ["unrecognized finding", "guard_finding_invalid", (f) => { f.guard("", { ...f.report, findings: [{file:"lib/subject.ex",category:"fixture_sensitive_value",count:1}] }); }],
    ["nonzero without findings", "nonzero_without_findings", (f) => { f.guard("", f.report, 1); }],
    ["changed capsule", "tool_capsule_changed", (f) => { f.guard("writeFileSync(new URL(import.meta.url),'changed');"); }],
    ["active mutable suite", "mutable_process_active", (_f, a) => { a.processCheck = () => { need(mutableProcessLines('20 mix test\n').length === 0, 'mutable_process_active'); }; }],
  ];
  for (const [name, code, change] of controls) test(`capture refuses ${name}`, async () => {
    const f = captureFixture(); try {
      const adapters = { ...f.adapters }; change(f, adapters);
      const before = inventory(f.root);
      await assert.rejects(captureAt(f.root, f.options, adapters), { code });
      assert.equal(existsSync(path.join(f.root, f.options.output)), false);
      if (code !== "restoration_failed") {
        assert.equal(git(f.root, ["branch", "--show-current"]), BRANCH);
        assert.equal(fullRef(f.root, "HEAD"), before.head);
      }
    } finally { f.cleanup(); }
  });
  test("capture does not retain arbitrary child output", async () => {
    const f = captureFixture(); try {
      const canary = "synthetic-private-output-canary";
      f.guard(`console.log('${canary}'); console.error('${canary}');`);
      const result = await captureAt(f.root, f.options, f.adapters);
      assert.equal(JSON.stringify(result).includes(canary), false);
      assert.equal(result.stdout_sha256.length, 64); assert.equal(result.stderr_sha256.length, 64);
    } finally { f.cleanup(); }
  });
  test("capture restores the saved branch after its own process receives termination", async () => {
    const f = captureFixture();
    const readyRoot = mkdtempSync(path.join(tmpdir(), "cw196-signal-"));
    const ready = path.join(readyRoot, "ready");
    let proc;
    try {
      f.guard("writeFileSync(process.env.CW196_TEST_READY,'ready'); await new Promise(r=>setTimeout(r,10000));");
      const driver = `const {captureAt}=await import(process.env.CW196_TEST_HELPER);\ntry { await captureAt(process.env.CW196_TEST_ROOT,JSON.parse(process.env.CW196_TEST_OPTIONS),{privacyScript:process.env.CW196_TEST_PRIVACY,processCheck:()=>{},spec:{command:process.execPath,files:['script/fixture-guard.mjs'],args:[]},discover:()=>['lib/subject.ex'],subjectPredicate:(_g,p)=>p==='lib/subject.ex'}); process.exitCode=0; } catch(e) {console.log(e.code);process.exitCode=3;}\n`;
      proc = spawn(process.execPath, ["--input-type=module", "-e", driver], {
        cwd: f.root, env: { ...process.env, CW196_TEST_READY: ready, CW196_TEST_HELPER: import.meta.url,
          CW196_TEST_ROOT: f.root, CW196_TEST_OPTIONS: JSON.stringify(f.options), CW196_TEST_PRIVACY: f.adapters.privacyScript },
        stdio: ["ignore", "pipe", "pipe"],
      });
      let stdout = ""; proc.stdout.on("data", (bytes) => { stdout += bytes; });
      const closed = new Promise((resolve) => proc.once("close", (code) => resolve(code)));
      const deadline = Date.now() + 5000;
      while (!existsSync(ready) && Date.now() < deadline) await new Promise((resolve) => setTimeout(resolve, 10));
      assert.equal(existsSync(ready), true, "real guard must start before termination");
      proc.kill("SIGTERM");
      assert.equal(await closed, 3); assert.equal(stdout.trim(), "capture_interrupted");
      assert.equal(git(f.root, ["branch", "--show-current"]), BRANCH);
      assert.equal(existsSync(path.join(f.root, f.options.output)), false);
      noTrackedChanges(f.root);
    } finally {
      if (proc?.exitCode === null) proc.kill("SIGKILL");
      f.cleanup(); rmSync(readyRoot, { recursive: true, force: true });
    }
  });
  test("capture preserves a prior receipt when publication privacy is refused", async () => {
    const f = captureFixture(); try {
      f.put(f.options.output, "previous retained report\n");
      f.put("privacy-policy.sh", "#!/bin/sh\ncase \"$1\" in */receipt.json) exit 1;; esac\nexit 0\n");
      await assert.rejects(captureAt(f.root, f.options, { ...f.adapters, privacyScript: path.join(f.root, "privacy-policy.sh") }), { code: "privacy_refused" });
      assert.equal(fileAt(f.root, f.options.output).toString(), "previous retained report\n");
      assert.equal(git(f.root, ["branch", "--show-current"]), BRANCH);
    } finally { f.cleanup(); }
  });
  test("capture refuses a concurrent capture lock without altering the checkout", async () => {
    const f = captureFixture(); try {
      f.put(".git/phase196-measure-main.lock", "held by another attempt\n");
      const before = inventory(f.root);
      await assert.rejects(captureAt(f.root, f.options, f.adapters), { code: "capture_lock_unavailable" });
      assert.deepEqual(inventory(f.root), before);
    } finally { f.cleanup(); }
  });
}
function amendedFixture() {
  const f = fixture();
  const sourceBytes = `${JSON.stringify(f.record, null, 2)}\n`;
  f.put(SOURCE, sourceBytes); f.g("add", SOURCE); f.g("commit", "-m", "fixture immutable receipt");
  const parent = fullRef(f.root, "HEAD");
  const entries = AMENDED_PLANS.map((name) => {
    const before = fileAt(f.root, name);
    const after = before.toString().replace("## Ordering and interfaces", "## Resolved attempt contract\n\nSame criteria, carried aggregate budget, no new authority.\n\n## Ordering and interfaces");
    assert.notEqual(after, before.toString()); f.put(name, after);
    return { path: name, before_sha256: sha(before), after_sha256: sha(after) };
  });
  f.put(RESOLUTION, "Synthetic reviewed local configuration; criteria and aggregate clock unchanged.\n");
  f.g("add", ...AMENDED_PLANS, RESOLUTION); f.g("commit", "-m", "fixture reviewed amendment");
  const commit = fullRef(f.root, "HEAD");
  f.reviewed = { commit, parent, sourceCommit: parent, sourceSha256: sha(sourceBytes) };
  f.evidence = {
    schema_version: 1, purpose: "reviewed_plan13_14_local_attempt_configuration",
    source_receipt_sha256: sha(sourceBytes), source_receipt_commit: parent,
    preserved_sha: f.record.preserved_sha, transfer_sha: f.record.transfer_sha,
    amendment_commit: commit, amendment_parent: parent,
    resolution: { path: RESOLUTION, sha256: sha(fileAt(f.root, RESOLUTION)) }, paths: entries,
  };
  f.saveEvidence = () => f.put(AMENDMENT, `${JSON.stringify(f.evidence, null, 2)}\n`);
  f.saveEvidence(); f.g("add", AMENDMENT); f.g("commit", "-m", "fixture amendment evidence");
  return f;
}
function sourceTests() {
  test("source verifier accepts independently established clean source", () => {
    const f = fixture(); try { assert.equal(verifySourceAt(f.root, f.record), true); } finally { f.cleanup(); }
  });
  test("source verifier rejects wrong main SHA", () => {
    const f = fixture(); try {
      assert.throws(() => verifySourceAt(f.root, { ...f.record, main_sha: f.record.preserved_sha }), { code: "main_ref_mismatch" });
    } finally { f.cleanup(); }
  });
  const controls = [
    ["empty source roster", "empty_source_roster", (f) => { f.record.source_roster = []; }],
    ["source roster hash mismatch", "source_roster_mismatch", (f) => { f.record.source_roster_sha256 = "0".repeat(64); }],
    ["lost receipt", "preserved_file_lost", (f) => { rmSync(path.join(f.root, RECEIPTS[0])); }],
    ["altered receipt", "protected_hash_mismatch", (f) => { f.put(RECEIPTS[0], "changed\n"); }],
    ["wrong preservation hash", "preservation_hash_mismatch", (f) => { f.record.preserved_files[0].sha256 = "0".repeat(64); }],
    ["wrong branch", "wrong_branch", (f) => { f.g("switch", "main"); }],
    ["unexpected supported change", "dirty_supported_code", (f) => { f.put("lib/subject.ex", "changed\n"); }],
    ["unrecognized state", "unrecognized_source_state", (f) => { f.record.schema_version = 9; }],
  ];
  for (const [name, code, change] of controls) test(`source verifier rejects ${name}`, () => {
    const f = fixture(); try { change(f); assert.throws(() => verifySourceAt(f.root, f.record), { code }); } finally { f.cleanup(); }
  });
  test("source verifier accepts only the reviewed committed two-plan amendment and preserves original receipt", () => {
    const f = amendedFixture(); try {
      const original = fileAt(f.root, SOURCE);
      assert.equal(verifySourceAt(f.root, f.record, f.reviewed), true);
      assert.deepEqual(fileAt(f.root, SOURCE), original);
      for (const item of f.record.protected_files) assert.equal(sha(object(f.root, f.record.preserved_sha, item.path)), item.sha256);
    } finally { f.cleanup(); }
  });
  const amendments = [
    ["extra protected path", "protected_hash_mismatch", (f) => { f.put(`${PHASE}/196-CONTEXT.md`, "unreviewed change\n"); }],
    ["altered protected receipt", "protected_hash_mismatch", (f) => { f.put(RECEIPTS[0], "unreviewed receipt\n"); }],
    ["later committed plan edit", "amendment_stale", (f) => { f.put(AMENDED_PLANS[0], "later unreviewed edit\n"); f.g("add", AMENDED_PLANS[0]); f.g("commit", "-m", "fixture stale amendment"); }],
    ["dirty amended plan", "amendment_stale", (f) => { f.put(AMENDED_PLANS[1], "dirty plan\n"); }],
    ["restored original instead of amended plan", "amendment_stale", (f) => { f.put(AMENDED_PLANS[0], object(f.root, f.record.preserved_sha, AMENDED_PLANS[0])); }],
    ["changed resolution", "amendment_resolution_mismatch", (f) => { f.put(RESOLUTION, "different budget\n"); }],
    ["rewritten original receipt", "amendment_source_mismatch", (f) => { f.put(SOURCE, "{}\n"); }],
    ["wrong evidence hash", "amendment_evidence_mismatch", (f) => { f.evidence.paths[0].after_sha256 = "0".repeat(64); f.saveEvidence(); }],
    ["extra evidence path", "amendment_evidence_mismatch", (f) => { f.evidence.paths.push({ ...f.evidence.paths[0], path: `${PHASE}/196-CONTEXT.md` }); f.saveEvidence(); }],
    ["different amendment evidence", "amendment_evidence_mismatch", (f) => { f.evidence.amendment_commit = f.record.transfer_sha; f.saveEvidence(); }],
    ["malformed amendment evidence", "amendment_evidence_invalid", (f) => { f.put(AMENDMENT, "{broken\n"); }],
    ["missing amendment evidence", "amendment_evidence_missing", (f) => { rmSync(path.join(f.root, AMENDMENT)); }],
    ["uncommitted evidence bytes", "amendment_evidence_uncommitted", (f) => { f.put(AMENDMENT, `${JSON.stringify(f.evidence, null, 4)}\n`); }],
    ["wrong amendment parent", "amendment_parent_mismatch", (f) => { f.reviewed.parent = fullRef(f.root, "HEAD"); }],
    ["additional protected amendment at reviewed commit", "amendment_scope_mismatch", (f) => {
      f.reviewed.parent = fullRef(f.root, "HEAD");
      f.put(`${PHASE}/196-CONTEXT.md`, "extra review scope\n"); f.g("add", `${PHASE}/196-CONTEXT.md`); f.g("commit", "-m", "fixture extra amendment");
      f.reviewed.commit = fullRef(f.root, "HEAD");
    }],
    ["unreachable reviewed amendment", "main_not_ancestor", (f) => {
      f.g("switch", "-c", "fixture-unrelated", f.record.main_sha);
      f.put("isolated.txt", "unrelated\n"); f.g("add", "isolated.txt"); f.g("commit", "-m", "fixture unrelated commit");
      f.reviewed.commit = fullRef(f.root, "HEAD"); f.g("switch", BRANCH);
    }],
  ];
  for (const [name, code, change] of amendments) test(`source verifier refuses ${name}`, () => {
    const f = amendedFixture(); try { change(f); assert.throws(() => verifySourceAt(f.root, f.record, f.reviewed), { code }); } finally { f.cleanup(); }
  });
}
function replanTests() {
  const unrelated = (f, name) => {
    f.g("switch", "-c", name, f.record.main_sha);
    f.put("isolated-replan.txt", "unrelated\n"); f.g("add", "isolated-replan.txt"); f.g("commit", "-m", "fixture unrelated replan commit");
    const sha1 = fullRef(f.root, "HEAD"); f.g("switch", BRANCH);
    return sha1;
  };
  function replanFixture(extra = () => {}) {
    const f = amendedFixture();
    f.put(`${PHASE}/196-01-SUMMARY.md`, "fixture summary\n");
    f.put(`${PHASE}/196-SOURCE-VERIFIER-FOLLOWUP.md`, "fixture followup\n");
    f.put(`${PHASE}/196-EVIDENCE/MUEX-DECISION.md`, "fixture decision\n");
    f.put(`${PHASE}/196-PLAN-CHECK.md`, "fixture plan check\n");
    f.g("add", ".planning"); f.g("commit", "-m", "fixture replan base");
    const base = fullRef(f.root, "HEAD");
    const entries = REPLAN_PLANS.map((name) => {
      const before = fileAt(f.root, name);
      const after = `${before}\nReplanned: the recorded move changes no authority.\n`;
      f.put(name, after);
      return { path: name, before_sha256: sha(before), after_sha256: sha(after) };
    });
    extra(f);
    f.g("add", ".planning"); f.g("commit", "-m", "fixture replan");
    const commit = fullRef(f.root, "HEAD");
    f.replan = { base, commit, paths: REPLAN_PLANS };
    f.replanEvidence = {
      schema_version: 1, purpose: "reviewed_plan15_17_spec04_move_replan",
      source_receipt_sha256: f.reviewed.sourceSha256, source_receipt_commit: f.reviewed.sourceCommit,
      preserved_sha: f.record.preserved_sha, transfer_sha: f.record.transfer_sha,
      replan_base: base, replan_commit: commit, paths: entries,
    };
    f.saveReplan = () => f.put(REPLAN_EVIDENCE, `${JSON.stringify(f.replanEvidence, null, 2)}\n`);
    f.saveReplan(); f.g("add", REPLAN_EVIDENCE); f.g("commit", "-m", "fixture replan evidence");
    return f;
  }
  test("source verifier accepts the reviewed committed replan delta, keeps the 13/14 amendment and the original receipt", () => {
    const f = replanFixture(); try {
      const original = fileAt(f.root, SOURCE);
      assert.equal(verifySourceAt(f.root, f.record, f.reviewed, f.replan), true);
      assert.deepEqual(fileAt(f.root, SOURCE), original);
      for (const item of f.record.protected_files) assert.equal(sha(object(f.root, f.record.preserved_sha, item.path)), item.sha256);
    } finally { f.cleanup(); }
  });
  test("replan fixture override is inaccessible on the actual repository", () => {
    assert.throws(() => verifySourceAt(OWNER_ROOT, {}, REVIEWED_AMENDMENT, { ...REVIEWED_REPLAN, commit: "0".repeat(40) }), { code: "test_adapter_on_repository" });
    assert.throws(() => verifySourceAt(OWNER_ROOT, {}, { ...REVIEWED_AMENDMENT }, REVIEWED_REPLAN), { code: "test_adapter_on_repository" });
  });
  const scope = [
    ["a listed protected context path", `${PHASE}/196-CONTEXT.md`],
    ["a listed protected earlier plan", `${PHASE}/196-01-PLAN.md`],
    ["a listed protected amended plan", AMENDED_PLANS[0]],
    ["a Phase195 privacy receipt", RECEIPTS[0]],
    ["an unlisted summary", `${PHASE}/196-01-SUMMARY.md`],
    ["an unlisted follow-up document", `${PHASE}/196-SOURCE-VERIFIER-FOLLOWUP.md`],
    ["an unlisted evidence document", `${PHASE}/196-EVIDENCE/MUEX-DECISION.md`],
    ["the plan-check document, which is outside the pin", `${PHASE}/196-PLAN-CHECK.md`],
  ];
  for (const [name, target] of scope) test(`source verifier refuses a replan commit that also edits ${name}`, () => {
    const f = replanFixture((g) => g.put(target, "unreviewed replan edit\n")); try {
      assert.throws(() => verifySourceAt(f.root, f.record, f.reviewed, f.replan), { code: "replan_scope_mismatch" });
    } finally { f.cleanup(); }
  });
  const replans = [
    ["later committed plan edit", "replan_stale", (f) => { f.put(REPLAN_PLANS[0], "later unreviewed edit\n"); f.g("add", REPLAN_PLANS[0]); f.g("commit", "-m", "fixture stale replan"); }],
    ["dirty replanned plan", "replan_stale", (f) => { f.put(REPLAN_PLANS[1], "dirty plan\n"); }],
    ["restored original instead of replanned plan", "replan_stale", (f) => { f.put(REPLAN_PLANS[2], object(f.root, f.record.preserved_sha, REPLAN_PLANS[2])); }],
    ["wrong replan identity", "replan_scope_mismatch", (f) => { f.replan = { ...f.replan, commit: f.reviewed.commit }; }],
    ["unreachable replan commit", "replan_stale", (f) => { f.replan = { ...f.replan, commit: unrelated(f, "fixture-unrelated-commit") }; }],
    ["non-ancestor replan base", "replan_scope_mismatch", (f) => { f.replan = { ...f.replan, base: unrelated(f, "fixture-unrelated-base") }; }],
    ["missing replan evidence", "replan_evidence_missing", (f) => { rmSync(path.join(f.root, REPLAN_EVIDENCE)); }],
    ["malformed replan evidence", "replan_evidence_mismatch", (f) => { f.put(REPLAN_EVIDENCE, "{broken\n"); }],
    ["uncommitted replan evidence bytes", "replan_evidence_uncommitted", (f) => { f.put(REPLAN_EVIDENCE, `${JSON.stringify(f.replanEvidence, null, 4)}\n`); }],
    ["wrong replan evidence hash", "replan_evidence_mismatch", (f) => { f.replanEvidence.paths[0].after_sha256 = "0".repeat(64); f.saveReplan(); }],
    ["extra replan evidence path", "replan_evidence_mismatch", (f) => { f.replanEvidence.paths.push({ ...f.replanEvidence.paths[0], path: `${PHASE}/196-CONTEXT.md` }); f.saveReplan(); }],
    ["different replan evidence commit", "replan_evidence_mismatch", (f) => { f.replanEvidence.replan_commit = f.record.transfer_sha; f.saveReplan(); }],
    ["wrong replan evidence purpose", "replan_evidence_mismatch", (f) => { f.replanEvidence.purpose = "reviewed_plan13_14_local_attempt_configuration"; f.saveReplan(); }],
  ];
  for (const [name, code, change] of replans) test(`source verifier refuses ${name}`, () => {
    const f = replanFixture(); try { change(f); assert.throws(() => verifySourceAt(f.root, f.record, f.reviewed, f.replan), { code }); } finally { f.cleanup(); }
  });
}
function selfTest(root) {
  const started = Date.now();
  const suites = [];
  for (const mode of ["source-controls", "capture-controls"]) {
    const run = child(root, process.execPath, [path.join(root, SELF), mode], { timeout: 60_000 });
    const total = Number(/^# tests (\d+)$/m.exec(run.stdout)?.[1] ?? 0);
    const passed = Number(/^# pass (\d+)$/m.exec(run.stdout)?.[1] ?? 0);
    const failed = Number(/^# fail (\d+)$/m.exec(run.stdout)?.[1] ?? -1);
    const names = [...run.stdout.matchAll(/^# Subtest: (.+)$/gm)].map((match) => match[1]);
    need(run.status === 0 && total > 0 && passed === total && failed === 0 && names.length === total, "self_test_failed");
    suites.push({ mode, command: ["node", SELF, mode], process_exit: run.status, tests: total, passed, failed,
      controls: names, stdout_sha256: sha(run.stdout), stderr_sha256: sha(run.stderr) });
  }
  const result = {
    schema_version: 1, helper_sha256: sha(fileAt(root, SELF)), duration_ms: Date.now() - started,
    tests: suites.reduce((sum, suite) => sum + suite.tests, 0), suites,
    fixture_contract: "disposable_git_repositories_and_real_child_processes",
    production_guard_measurements: 0,
  };
  writeFileSync(path.join(root, CONTROLS), `${JSON.stringify(result, null, 2)}\n`);
  console.log(`measure-main: controls passed ${result.tests}`);
}
async function main() {
  const { mode, opts } = parse(process.argv.slice(2));
  if (mode === "source-controls") { sourceTests(); replanTests(); return; }
  if (mode === "capture-controls") { captureTests(); return; }
  const root = git(process.cwd(), ["rev-parse", "--show-toplevel"]);
  need(realpathSync(root) === realpathSync(process.cwd()), "wrong_working_directory");
  if (mode === "prepare") {
    const record = sourceRecord(root, { main: "origin/main", preserved: PRESERVED, transfer: opts.transfer, original: opts.original });
    verifySourceAt(root, record);
    mkdirSync(path.dirname(path.join(root, SOURCE)), { recursive: true });
    writeFileSync(path.join(root, SOURCE), `${JSON.stringify(record, null, 2)}\n`);
    console.log(`measure-main: prepared source ${record.source_count}`);
  } else if (mode === "verify-source") {
    const record = JSON.parse(fileAt(root, SOURCE));
    verifySourceAt(root, record);
    console.log(`measure-main: verified source ${record.source_count}`);
  } else if (mode === "self-test") {
    need(Object.keys(opts).length === 0, "invalid_arguments");
    selfTest(root);
  } else if (mode === "capture") {
    const result = await captureAt(root, opts);
    console.log(`measure-main: captured ${result.guard} files ${result.subject_count} exit ${result.process_exit}`);
  } else throw new Refusal("invalid_mode");
}
if (path.resolve(process.argv[1] ?? "") === fileURLToPath(import.meta.url)) {
  main().catch((error) => { console.error(`measure-main: refused ${error instanceof Refusal ? error.code : "internal_error"}`); process.exitCode = 1; });
}
export { captureAt };
