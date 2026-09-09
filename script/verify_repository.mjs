#!/usr/bin/env node
/* Fixed argv, closed records, literal CI ownership, and redacted failures enforce D-01–D-06. */
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const manifestPath = path.join(repoRoot, "script/repository_verification_stages.json");
const workflowPath = path.join(repoRoot, ".github/workflows/crosswake-ci.yml");
const stageIds = ["repository-preflight", "root-proof", "example-host-proof", "browser-proof", "ios-package-proof", "android-package-proof", "format-proof", "warnings-proof", "repository-cleanliness"];
const manifestKeys = ["schema_version", "stages"];
const stageKeys = ["argv", "ci_owners", "cwd", "dependencies", "env", "owned_outputs", "remediation_command", "required_tools", "stage_id"];
const toolKeys = ["argv", "remediation_command", "tool", "version_regex"];
const ownerKeys = ["command", "job_id"];

function sameKeys(value, expected, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${label} must be a record`);
  const actual = Object.keys(value).sort();
  if (actual.join("\0") !== [...expected].sort().join("\0")) throw new Error(`${label} has unknown or missing keys`);
}

function safeRelative(value, label) {
  if (typeof value !== "string" || value === "" || path.isAbsolute(value) || value.split(/[\\/]/).includes("..")) throw new Error(`${label} must stay repository-relative`);
}

export function loadStageManifest(source = manifestPath) {
  return JSON.parse(readFileSync(source, "utf8"));
}

export function validateStageManifest(manifest) {
  sameKeys(manifest, manifestKeys, "manifest");
  if (manifest.schema_version !== 1 || !Array.isArray(manifest.stages) || manifest.stages.length !== stageIds.length) throw new Error("manifest must contain the complete nine-stage inventory");
  if (manifest.stages.map(stage => stage?.stage_id).join("\0") !== stageIds.join("\0")) throw new Error("stages must use the closed ordered purpose inventory");
  const ids = new Set(stageIds);
  for (const stage of manifest.stages) {
    sameKeys(stage, stageKeys, `stage ${stage?.stage_id ?? "null"}`);
    if (!Array.isArray(stage.dependencies) || !Array.isArray(stage.required_tools) || !Array.isArray(stage.argv) || stage.argv.length === 0 || !Array.isArray(stage.ci_owners) || stage.ci_owners.length === 0 || !Array.isArray(stage.owned_outputs)) throw new Error(`${stage.stage_id} contains an empty or non-array field`);
    if (stage.argv.some(part => typeof part !== "string" || part === "" || /[;&|`\n\r]/.test(part))) throw new Error(`${stage.stage_id} argv must be fixed strings without shell syntax`);
    safeRelative(stage.cwd, `${stage.stage_id} cwd`);
    sameKeys(stage.env, Object.keys(stage.env), `${stage.stage_id} env`);
    for (const [key, value] of Object.entries(stage.env)) if (!/^[A-Z][A-Z0-9_]*$/.test(key) || typeof value !== "string") throw new Error(`${stage.stage_id} env must be string key/value records`);
    if (typeof stage.remediation_command !== "string" || !stage.remediation_command) throw new Error(`${stage.stage_id} requires one remediation`);
    for (const dep of stage.dependencies) if (!ids.has(dep)) throw new Error(`${stage.stage_id} has unknown dependency ${dep}`);
    for (const tool of stage.required_tools) { sameKeys(tool, toolKeys, `${stage.stage_id} tool`); if (!Array.isArray(tool.argv) || tool.argv.length === 0 || typeof tool.version_regex !== "string") throw new Error(`${stage.stage_id} tool rule is malformed`); new RegExp(tool.version_regex); }
    for (const owner of stage.ci_owners) { sameKeys(owner, ownerKeys, `${stage.stage_id} owner`); if (!owner.job_id || !owner.command) throw new Error(`${stage.stage_id} owner is empty`); }
    for (const output of stage.owned_outputs) safeRelative(output, `${stage.stage_id} output`);
  }
  const visiting = new Set(); const visited = new Set(); const byId = new Map(manifest.stages.map(stage => [stage.stage_id, stage]));
  function visit(id) { if (visiting.has(id)) throw new Error(`dependency cycle at ${id}`); if (visited.has(id)) return; visiting.add(id); for (const dep of byId.get(id).dependencies) visit(dep); visiting.delete(id); visited.add(id); }
  for (const id of stageIds) visit(id);
  return manifest;
}

export function validateCiParity(manifest, workflowSource = readFileSync(workflowPath, "utf8")) {
  validateStageManifest(manifest);
  for (const stage of manifest.stages) for (const owner of stage.ci_owners) {
    const ownerStart = workflowSource.search(new RegExp(`^  ${owner.job_id}:`, "m"));
    const tail = ownerStart < 0 ? "" : workflowSource.slice(ownerStart);
    const nextOwner = tail.slice(1).search(/^  [a-zA-Z0-9_-]+:/m);
    const ownerBlock = nextOwner < 0 ? tail : tail.slice(0, nextOwner + 1);
    if (ownerStart < 0 || !ownerBlock.includes(owner.command)) throw new Error(`FAIL ${stage.stage_id} CI owner ${owner.job_id}; corrective-command=node --test test/js/repository_verification.test.mjs`);
  }
  return manifest;
}

export function selectStages(manifest, selection = "all") {
  validateStageManifest(manifest);
  if (selection !== "all" && !stageIds.includes(selection)) throw new Error(`unknown stage ${selection}`);
  if (selection === "all") return manifest.stages;
  const wanted = new Set(); const byId = new Map(manifest.stages.map(stage => [stage.stage_id, stage]));
  function add(id) { if (wanted.has(id)) return; for (const dep of byId.get(id).dependencies) add(dep); wanted.add(id); }
  add(selection);
  if (selection !== "repository-cleanliness") wanted.add("repository-cleanliness");
  return manifest.stages.filter(stage => wanted.has(stage.stage_id));
}

function defaultProbe(tool) {
  const result = spawnSync(tool.argv[0], tool.argv.slice(1), { cwd: repoRoot, encoding: "utf8", timeout: 15000 });
  if (result.error) return { kind: result.error.code === "ENOENT" ? "missing" : "failed-to-start" };
  return { status: result.status, stdout: `${result.stdout ?? ""}${result.stderr ?? ""}`.trim() };
}

export function runPreflight(_manifest, selected, options = {}) {
  const probe = options.probe ?? defaultProbe;
  const seen = new Set(); const records = [];
  for (const stage of selected) for (const tool of stage.required_tools) {
    if (seen.has(tool.tool)) continue; seen.add(tool.tool);
    const result = probe(tool);
    const output = String(result?.stdout ?? "");
    if (result?.kind || result?.status !== undefined && result.status !== 0 || !new RegExp(tool.version_regex).test(output)) {
      records.push({ result: "FAIL", purpose: "repository-preflight", tool: tool.tool, remediation_command: tool.remediation_command });
    }
  }
  return { status: records.length ? "FAIL" : "PASS", records };
}

export function runVerification(options = {}) {
  const manifest = validateStageManifest(options.manifest ?? loadStageManifest());
  validateCiParity(manifest, options.workflowSource ?? readFileSync(workflowPath, "utf8"));
  const selected = selectStages(manifest, options.selection ?? "all");
  const preflight = runPreflight(manifest, selected, options);
  const lines = [`${preflight.status} repository-preflight${preflight.records[0] ? ` tool=${preflight.records[0].tool}; corrective-command=${preflight.records[0].remediation_command}` : ""}`];
  const failed = new Set(preflight.status === "FAIL" ? ["repository-preflight"] : []);
  const spawn = options.spawn ?? ((command, args, spawnOptions) => spawnSync(command, args, { ...spawnOptions, encoding: "utf8", stdio: "inherit" }));
  let exitStatus = preflight.status === "FAIL" ? 1 : 0;
  for (const stage of selected) {
    if (stage.stage_id === "repository-preflight") continue;
    const blocked = stage.stage_id !== "repository-cleanliness" && stage.dependencies.some(dep => failed.has(dep));
    if (blocked) { lines.push(`BLOCKED ${stage.stage_id}; corrective-command=${stage.remediation_command}`); exitStatus = 1; continue; }
    const result = spawn(stage.argv[0], stage.argv.slice(1), { cwd: path.join(options.repoRoot ?? repoRoot, stage.cwd), env: { ...process.env, ...stage.env } });
    if (result?.error || result?.status !== 0) { failed.add(stage.stage_id); lines.push(`FAIL ${stage.stage_id}; corrective-command=${stage.remediation_command}`); exitStatus = 1; }
    else lines.push(`PASS ${stage.stage_id}`);
  }
  return { status: exitStatus, output: lines.join("\n"), records: lines };
}

function parseArgs(argv) {
  if (argv.length === 1 && argv[0] === "--all") return { selection: "all" };
  if (argv.length === 2 && argv[0] === "--stage" && stageIds.includes(argv[1])) return { selection: argv[1] };
  if (argv.length === 1 && argv[0] === "--self-test") return { selfTest: true };
  throw new Error("usage: script/verify_repository.sh (--all | --stage <purpose-id> | --self-test)");
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = parseArgs(process.argv.slice(2));
    if (args.selfTest) {
      const result = spawnSync(process.execPath, ["--test", "test/js/repository_verification.test.mjs"], { cwd: repoRoot, stdio: "inherit" });
      if (result.status !== 0) process.exit(result.status ?? 1);
      console.log("PASS repository-preflight self-test");
    } else {
      const result = runVerification({ selection: args.selection });
      console.log(result.output);
      process.exitCode = result.status;
    }
  } catch (error) {
    console.error(`FAIL repository-preflight; corrective-command=node --test test/js/repository_verification.test.mjs\n${error.message}`);
    process.exitCode = 1;
  }
}
