#!/usr/bin/env node
// Phase-only tooling. Scratch contains tools or synthetic git fixtures, never candidate product state.
import assert from "node:assert/strict";
import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { test } from "node:test";

const PHASE = ".planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet";
const SOURCE = `${PHASE}/196-EVIDENCE/execution-source.json`;
const CONTROLS = `${PHASE}/196-EVIDENCE/measurement-controls.json`;
const PRIVACY = ".planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/privacy-193.sh";
const SELF = `${PHASE}/scripts/measure-main.mjs`;
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
    need(match && match[1] === "100644" || match && match[1] === "100755", "unsupported_tree_entry");
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
function verifySourceAt(root, record) {
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
  for (const item of protectedFiles) need(sha(fileAt(root, item.path)) === item.sha256, "protected_hash_mismatch");
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
    need(/^--[a-z-]+$/.test(rest[i]) && rest[i + 1] && !(rest[i] in opts), "invalid_arguments");
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
  g("add", ".planning"); g("commit", "-m", "fixture preserved planning");
  const preserved = fullRef(root, "HEAD");
  g("switch", "-c", BRANCH, main); g("cherry-pick", preserved);
  const record = sourceRecord(root, { main, preserved, transfer: "HEAD", original: preserved });
  return { root, put, g, record, cleanup: () => rmSync(root, { recursive: true, force: true }) };
}
async function captureAt(root, options, adapters = {}) {
  return { schema_version: 1 };
}
function captureFixture() {
  const f = fixture();
  f.g("remote", "add", "origin", ".");
  f.put("script/fixture-guard.mjs", `process.stdout.write('PHASE196_REPORT '+JSON.stringify({schema_version:1,guard:'absence',scanned_files:['lib/subject.ex'],counts:{files:1},findings:[]})+'\\n');\n`);
  f.g("add", "script/fixture-guard.mjs"); f.g("commit", "-m", "fixture candidate tool");
  f.options = { guard: "absence", candidate: "HEAD", output: `${PHASE}/196-EVIDENCE/fixture-report.json` };
  return f;
}
function captureTests() {
  test("capture refuses wrong fetched source before executing guard", async () => {
    const f = captureFixture(); try {
      await assert.rejects(captureAt(f.root, f.options, { expectedMain: "0".repeat(40) }), { code: "wrong_main_sha" });
    } finally { f.cleanup(); }
  });
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
}
async function main() {
  const { mode, opts } = parse(process.argv.slice(2));
  if (mode === "source-controls") { sourceTests(); return; }
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
  } else throw new Refusal("mode_not_implemented");
}
if (path.resolve(process.argv[1] ?? "") === fileURLToPath(import.meta.url)) {
  main().catch((error) => { console.error(`measure-main: refused ${error instanceof Refusal ? error.code : "internal_error"}`); process.exitCode = 1; });
}
