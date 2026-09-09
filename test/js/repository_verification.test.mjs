/* Repository verification is a closed purpose inventory, never a shell-command API (D-01–D-06). */
import assert from "node:assert/strict";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { execFileSync, spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import path from "node:path";
import { test } from "node:test";

import {
  loadArtifactPolicy,
  loadStageManifest,
  runPreflight,
  runVerification,
  selectStages,
  validateCiParity,
  validateArtifactPolicy,
  validateStageManifest
} from "../../script/verify_repository.mjs";

const root = new URL("../../", import.meta.url);
const fixture = JSON.parse(
  readFileSync(new URL("../fixtures/repository_quality/stage-cases.json", import.meta.url), "utf8")
);
const expectedIds = [
  "repository-preflight",
  "root-proof",
  "example-host-proof",
  "browser-proof",
  "ios-package-proof",
  "android-package-proof",
  "format-proof",
  "warnings-proof",
  "repository-cleanliness"
];

function clone(value) {
  return structuredClone(value);
}

function makeRepository() {
  const directory = mkdtempSync(path.join(tmpdir(), "crosswake-repository-quality-test-"));
  execFileSync("git", ["init", "--quiet"], { cwd: directory });
  execFileSync("git", ["config", "user.email", "repository-quality@example.invalid"], { cwd: directory });
  execFileSync("git", ["config", "user.name", "Repository Quality Test"], { cwd: directory });
  writeFileSync(path.join(directory, "tracked.txt"), "tracked\n");
  execFileSync("git", ["add", "tracked.txt"], { cwd: directory });
  execFileSync("git", ["commit", "--quiet", "-m", "fixture"], { cwd: directory });
  return directory;
}

function verificationOptions(repoRoot, overrides = {}) {
  return {
    manifest: loadStageManifest(),
    selection: "repository-cleanliness",
    probe: tool => ({ stdout: fixture.tool_versions[tool.tool] }),
    spawn: () => ({ status: 0, stdout: "", stderr: "" }),
    repoRoot,
    enforceArtifactPolicy: false,
    workflowSource: readFileSync(new URL("../../.github/workflows/crosswake-ci.yml", import.meta.url), "utf8"),
    ...overrides
  };
}

test("production manifest is closed, ordered, fixed, and has literal CI owners", () => {
  const manifest = loadStageManifest();
  const artifactPolicy = loadArtifactPolicy();
  assert.deepEqual(manifest.stages.map(stage => stage.stage_id), expectedIds);
  assert.equal(validateStageManifest(manifest), manifest);
  assert.equal(validateCiParity(manifest), manifest);
  assert.equal(validateArtifactPolicy(artifactPolicy), artifactPolicy);

  for (const stage of manifest.stages) {
    assert(Array.isArray(stage.argv) && stage.argv.length > 0);
    assert.equal(typeof stage.cwd, "string");
    assert.equal(Array.isArray(stage.ci_owners), true);
    assert(stage.ci_owners.length > 0);
    assert(!stage.argv.some(part => /[;&|`]/.test(part)));
  }
});

test("artifact policy rejects unknown, empty, unordered, duplicate, and overlapping records", () => {
  const mutations = [
    policy => { policy.future_class = []; },
    policy => { policy.ignored_transient = []; },
    policy => { policy.intentionally_tracked.reverse(); },
    policy => { policy.forbidden_tracked.push(clone(policy.forbidden_tracked[0])); },
    policy => { policy.forbidden_tracked[0].matchers.push(clone(policy.ignored_transient[0].matchers[0])); },
    policy => { policy.generated_contracts[0].output_paths.reverse(); }
  ];

  for (const mutate of mutations) {
    const policy = clone(loadArtifactPolicy());
    mutate(policy);
    assert.throws(() => validateArtifactPolicy(policy));
  }
});

test("focused root selection closes over preflight and unconditional cleanliness", () => {
  const selected = selectStages(loadStageManifest(), "root-proof");
  assert.deepEqual(selected.map(stage => stage.stage_id), [
    "repository-preflight",
    "root-proof",
    "repository-cleanliness"
  ]);
  assert.deepEqual(selected[1].argv, ["mix", "verify"]);
});

test("manifest rejects malformed, arbitrary, and disconnected records", () => {
  const mutations = [
    manifest => manifest.stages.push(clone(manifest.stages[0])),
    manifest => { manifest.stages[0].surprise = true; },
    manifest => { manifest.stages[0].stage_id = "unknown-stage"; },
    manifest => { manifest.stages.reverse(); },
    manifest => { manifest.stages[1].dependencies = ["missing-stage"]; },
    manifest => { manifest.stages[0].dependencies = ["root-proof"]; },
    manifest => { manifest.stages[1].argv = "mix verify"; },
    manifest => { manifest.stages[1].cwd = "../outside"; },
    manifest => { manifest.stages[1].ci_owners = []; },
    manifest => { manifest.stages[1] = null; },
    manifest => { manifest.stages = []; }
  ];

  for (const mutate of mutations) {
    const manifest = clone(loadStageManifest());
    mutate(manifest);
    assert.throws(() => validateStageManifest(manifest));
  }
  assert.throws(() => validateStageManifest(null));
});

test("CI parity rejects missing owners and copied-command drift with one correction", () => {
  const missing = clone(loadStageManifest());
  missing.stages[1].ci_owners[0].job_id = "not-a-real-job";
  assert.throws(() => validateCiParity(missing), /corrective-command=/);

  const drifted = clone(loadStageManifest());
  drifted.stages[1].ci_owners[0].command = "mix test changed";
  assert.throws(() => validateCiParity(drifted), /corrective-command=/);
});

test("preflight rejects exact missing and wrong tools without starting proof commands", () => {
  const manifest = loadStageManifest();
  const started = [];
  const missing = runPreflight(manifest, selectStages(manifest, "root-proof"), {
    probe: tool => tool.tool === "node" ? { kind: "missing" } : { stdout: fixture.tool_versions[tool.tool] },
    onProofStart: id => started.push(id),
    secretValues: [fixture.secret_sentinel]
  });
  assert.equal(missing.status, "FAIL");
  assert.deepEqual(started, []);
  assert(!JSON.stringify(missing).includes(fixture.secret_sentinel));
});

test("single selected stage renders normal PASS records", () => {
  const manifest = loadStageManifest();
  const result = runVerification({
    manifest,
    selection: "repository-cleanliness",
    probe: tool => ({ stdout: fixture.tool_versions[tool.tool] }),
    spawn: () => ({ status: 0, stdout: "", stderr: "" }),
    repoRoot: new URL(".", root).pathname,
    enforceArtifactPolicy: false,
    workflowSource: readFileSync(new URL("../../.github/workflows/crosswake-ci.yml", import.meta.url), "utf8")
  });
  assert.equal(result.status, 0);
  assert.match(result.output, /PASS repository-cleanliness/);
});

test("every required identity has exact missing, wrong-version, and failed-start controls", () => {
  const manifest = loadStageManifest();
  const selected = selectStages(manifest, "all");
  const tools = [...new Set(selected.flatMap(stage => stage.required_tools.map(tool => tool.tool)))];
  assert.deepEqual(tools.sort(), ["bash", "elixir", "erl", "git", "gradle-wrapper", "java", "node", "npm", "swift", "xcodebuild"]);

  for (const target of tools) {
    for (const kind of fixture.failure_kinds) {
      const result = runPreflight(manifest, selected, {
        probe: tool => tool.tool === target
          ? kind === "wrong-version" ? { stdout: "version 0.0-secretless" } : { kind }
          : { stdout: fixture.tool_versions[tool.tool] }
      });
      assert.equal(result.status, "FAIL", `${target} ${kind}`);
      assert(result.records.some(record => record.tool === target), `${target} is named`);
    }
  }
});

test("complete-run Apple absence blocks only iOS and keeps independent stages observable", () => {
  const manifest = loadStageManifest();
  const repository = makeRepository();
  const started = [];
  try {
    const result = runVerification({
      manifest,
      selection: "all",
      probe: tool => ["swift", "xcodebuild"].includes(tool.tool)
        ? { kind: "missing", stdout: fixture.secret_sentinel }
        : { stdout: fixture.tool_versions[tool.tool] },
      spawn: (command, argv) => { started.push([command, ...argv].join(" ")); return { status: 0, stdout: "", stderr: "" }; },
      repoRoot: repository,
      enforceArtifactPolicy: false,
      workflowSource: readFileSync(new URL("../../.github/workflows/crosswake-ci.yml", import.meta.url), "utf8")
    });

    assert.equal(result.status, 1);
    assert.match(result.output, /FAIL repository-preflight; corrective-command=xcode-select --install/);
    assert.match(result.output, /BLOCKED ios-package-proof/);
    assert.match(result.output, /PASS root-proof/);
    assert.match(result.output, /PASS repository-cleanliness/);
    assert(!started.includes("swift test"));
    assert(!result.output.includes(fixture.secret_sentinel));
  } finally {
    rmSync(repository, { recursive: true, force: true });
  }
});

test("focused independent selections do not probe unrelated Apple or Android tools", () => {
  const manifest = loadStageManifest();
  const probed = [];
  runPreflight(manifest, selectStages(manifest, "root-proof"), {
    probe: tool => { probed.push(tool.tool); return { stdout: fixture.tool_versions[tool.tool] }; }
  });
  assert.deepEqual(probed, ["bash", "git", "node", "elixir", "erl"]);
});

test("browser stage supplies explicit repository mode and invocation-owned outputs", () => {
  const repository = makeRepository();
  const runRoot = mkdtempSync(path.join(tmpdir(), "crosswake-repository-verify.test-"));
  let browserEnvironment;
  try {
    const result = runVerification(verificationOptions(repository, {
      selection: "browser-proof",
      runRoot,
      spawn: (command, argv, options) => {
        if ([command, ...argv].join(" ") === "npx playwright test") browserEnvironment = options.env;
        return { status: 0, stdout: "", stderr: "" };
      }
    }));

    assert.equal(result.status, 0);
    assert.equal(browserEnvironment.CROSSWAKE_REPOSITORY_VERIFY, "1");
    assert.equal(browserEnvironment.CROSSWAKE_PLAYWRIGHT_REPORT_DIR, path.join(runRoot, "playwright-report"));
    assert.equal(browserEnvironment.CROSSWAKE_PLAYWRIGHT_RESULT_DIR, path.join(runRoot, "test-results"));
    assert.equal(browserEnvironment.CROSSWAKE_PLAYWRIGHT_ARTIFACT_DIR, path.join(runRoot, "playwright-artifacts"));
  } finally {
    rmSync(runRoot, { recursive: true, force: true });
    rmSync(repository, { recursive: true, force: true });
  }
});

test("dependency failure recursively blocks descendants while independent stages continue", () => {
  const manifest = clone(loadStageManifest());
  const repository = makeRepository();
  manifest.stages.find(stage => stage.stage_id === "example-host-proof").dependencies = ["root-proof"];
  manifest.stages.find(stage => stage.stage_id === "browser-proof").dependencies = ["example-host-proof"];
  const started = [];

  try {
    const result = runVerification({
      manifest,
      selection: "all",
      probe: tool => ({ stdout: fixture.tool_versions[tool.tool] }),
      spawn: (command, argv) => {
        const stage = manifest.stages.find(candidate => candidate.argv[0] === command && candidate.argv.slice(1).join("\0") === argv.join("\0"));
        started.push(stage.stage_id);
        return stage.stage_id === fixture.dependency_case.failed
          ? { status: 9, stdout: "root detail", stderr: "root error" }
          : { status: 0, stdout: "ok", stderr: "" };
      },
      repoRoot: repository,
      enforceArtifactPolicy: false,
      workflowSource: readFileSync(new URL("../../.github/workflows/crosswake-ci.yml", import.meta.url), "utf8")
    });

    assert.equal(result.status, 1);
    for (const stageId of fixture.dependency_case.blocked) {
      assert.match(result.output, new RegExp(`BLOCKED ${stageId}`));
      assert(!started.includes(stageId));
    }
    for (const stageId of fixture.dependency_case.independent) {
      assert.match(result.output, new RegExp(`PASS ${stageId}`));
      assert(started.includes(stageId));
    }
  } finally {
    rmSync(repository, { recursive: true, force: true });
  }
});

test("timeout and malformed process outcomes fail closed and retain full logs", () => {
  const cases = new Map([
    ["ordinary-nonzero", { status: 7, stdout: "ordinary output", stderr: "ordinary error" }],
    ["spawn-error", { error: Object.assign(new Error("spawn refused"), { code: "EACCES" }), status: null, stdout: "", stderr: "" }],
    ["signal", { status: null, signal: "SIGTERM", stdout: "signal output", stderr: "" }],
    ["timeout", { error: Object.assign(new Error("timed out"), { code: "ETIMEDOUT" }), status: null, stdout: "timeout output", stderr: "" }],
    ["malformed-result", null]
  ]);

  for (const kind of fixture.process_failures) {
    const runRoot = mkdtempSync(path.join(tmpdir(), "crosswake-repository-verify.test-"));
    try {
      const result = runVerification({
        manifest: loadStageManifest(),
        selection: "repository-cleanliness",
        probe: tool => ({ stdout: fixture.tool_versions[tool.tool] }),
        spawn: () => cases.get(kind),
        repoRoot: new URL(".", root).pathname,
        enforceArtifactPolicy: false,
        runRoot,
        workflowSource: readFileSync(new URL("../../.github/workflows/crosswake-ci.yml", import.meta.url), "utf8")
      });

      assert.equal(result.status, 1, kind);
      assert.match(result.output, /FAIL repository-cleanliness/, kind);
      const log = readFileSync(path.join(runRoot, "logs/repository-cleanliness.log"), "utf8");
      if (cases.get(kind)?.stdout) assert.match(log, new RegExp(cases.get(kind).stdout), kind);
      if (cases.get(kind)?.stderr) assert.match(log, new RegExp(cases.get(kind).stderr), kind);
    } finally {
      rmSync(runRoot, { recursive: true, force: true });
    }
  }
});

test("git complete mode rejects a dirty baseline before proof work", () => {
  const repository = makeRepository();
  const started = [];
  try {
    writeFileSync(path.join(repository, "dirty.txt"), "dirty\n");
    const result = runVerification(verificationOptions(repository, {
      selection: "all",
      spawn: (...args) => { started.push(args); return { status: 0, stdout: "", stderr: "" }; }
    }));

    assert.equal(result.status, 1);
    assert.deepEqual(started, []);
    assert.equal(result.output, "FAIL repository-cleanliness; corrective-command=git status --short");
    assert.doesNotMatch(result.output, /clean baseline/i);
  } finally {
    rmSync(repository, { recursive: true, force: true });
  }
});

test("git focused mode preserves dirty unusual-byte state and NUL snapshots", () => {
  const repository = makeRepository();
  const runRoot = mkdtempSync(path.join(tmpdir(), "crosswake-repository-verify."));
  try {
    for (const name of [" leading-space", "-leading-dash", "line\nbreak", "utf8-λ"]) {
      writeFileSync(path.join(repository, name), fixture.secret_sentinel);
    }
    execFileSync("git", ["add", "tracked.txt"], { cwd: repository });
    const indexBefore = readFileSync(path.join(repository, ".git/index"));
    const result = runVerification(verificationOptions(repository, { runRoot }));

    assert.equal(result.status, 0);
    const before = readFileSync(path.join(runRoot, "git-before.z"));
    const final = readFileSync(path.join(runRoot, "git-final.z"));
    assert(before.includes(0));
    assert.deepEqual(final, before);
    assert.deepEqual(readFileSync(path.join(repository, ".git/index")), indexBefore);
    assert(!result.output.includes(fixture.secret_sentinel));
  } finally {
    rmSync(runRoot, { recursive: true, force: true });
    rmSync(repository, { recursive: true, force: true });
  }
});

test("cleanup removes only outputs created by this invocation on failure and interruption", () => {
  for (const outcome of [{ status: 4 }, { status: null, signal: "SIGINT" }]) {
    const repository = makeRepository();
    const manifest = clone(loadStageManifest());
    manifest.stages.find(stage => stage.stage_id === "repository-cleanliness").owned_outputs = ["owned-cache"];
    try {
      const result = runVerification(verificationOptions(repository, {
        manifest,
        spawn: () => {
          mkdirSync(path.join(repository, "owned-cache"));
          writeFileSync(path.join(repository, "owned-cache/detail"), fixture.secret_sentinel);
          return { ...outcome, stdout: "", stderr: "" };
        }
      }));
      assert.equal(result.status, 1);
      assert.equal(existsSync(path.join(repository, "owned-cache")), false);
      assert(!result.output.includes(fixture.secret_sentinel));
    } finally {
      rmSync(repository, { recursive: true, force: true });
    }
  }
});

test("cleanup preserves pre-existing caches byte-for-byte", () => {
  const repository = makeRepository();
  const manifest = clone(loadStageManifest());
  manifest.stages.find(stage => stage.stage_id === "repository-cleanliness").owned_outputs = ["owned-cache"];
  try {
    mkdirSync(path.join(repository, "owned-cache"));
    writeFileSync(path.join(repository, "owned-cache/existing"), "preserve-exactly\n");
    const result = runVerification(verificationOptions(repository, { manifest }));
    assert.equal(result.status, 0);
    assert.equal(readFileSync(path.join(repository, "owned-cache/existing"), "utf8"), "preserve-exactly\n");
  } finally {
    rmSync(repository, { recursive: true, force: true });
  }
});

test("cleanup refuses symlink escape and invalid run-root prefix", () => {
  const repository = makeRepository();
  const outside = mkdtempSync(path.join(tmpdir(), "crosswake-repository-outside-"));
  const manifest = clone(loadStageManifest());
  manifest.stages.find(stage => stage.stage_id === "repository-cleanliness").owned_outputs = ["owned-cache"];
  try {
    const symlinkResult = runVerification(verificationOptions(repository, {
      manifest,
      spawn: () => {
        symlinkSync(outside, path.join(repository, "owned-cache"));
        return { status: 0, stdout: "", stderr: "" };
      }
    }));
    assert.equal(symlinkResult.status, 1);
    assert.equal(existsSync(path.join(repository, "owned-cache")), true);
    assert.match(symlinkResult.output, /FAIL repository-cleanliness/);

    const invalidRoot = mkdtempSync(path.join(tmpdir(), "invalid-repository-root."));
    try {
      const invalidResult = runVerification(verificationOptions(repository, { runRoot: invalidRoot }));
      assert.equal(invalidResult.status, 1);
      assert.match(invalidResult.output, /FAIL repository-preflight/);
    } finally {
      rmSync(invalidRoot, { recursive: true, force: true });
    }
  } finally {
    rmSync(path.join(repository, "owned-cache"), { force: true });
    rmSync(outside, { recursive: true, force: true });
    rmSync(repository, { recursive: true, force: true });
  }
});

test("summary reports one bounded remediation per non-pass purpose without secrets", () => {
  const manifest = clone(loadStageManifest());
  const repository = makeRepository();
  manifest.stages.find(stage => stage.stage_id === "example-host-proof").dependencies = ["root-proof"];
  try {
    const result = runVerification({
      ...verificationOptions(repository),
      manifest,
      selection: "all",
      probe: tool => ["node", "elixir"].includes(tool.tool)
        ? { kind: "missing", stdout: fixture.secret_sentinel }
        : { stdout: fixture.tool_versions[tool.tool] },
      spawn: () => ({ status: 0, stdout: fixture.secret_sentinel.repeat(1000), stderr: "" })
    });

    const nonPass = result.output.split("\n").filter(line => /^(FAIL|BLOCKED) /.test(line));
    assert(nonPass.length > 0);
    assert(nonPass.every(line => (line.match(/corrective-command=/g) ?? []).length === 1));
    assert.equal(new Set(nonPass.map(line => line.split(/[ ;]/, 2).join(" "))).size, nonPass.length);
    assert(result.output.length < 4096);
    assert(!result.output.includes(fixture.secret_sentinel));
  } finally {
    rmSync(repository, { recursive: true, force: true });
  }
});

test("generated-contract production runner preserves index and restores bytes", () => {
  const repository = makeRepository();
  const generator = `
import { existsSync, readFileSync, writeFileSync } from "node:fs";
const dev = process.argv.includes("--dev");
const source = readFileSync("source.txt", "utf8").trim();
writeFileSync(dev ? "out-dev.txt" : "out-default.txt", source + (dev ? ":dev\\n" : ":default\\n"));
if (existsSync("fail-generator")) process.exit(7);
`;

  const artifactPolicy = {
    schema_version: 1,
    ignored_transient: [{
      category: "ignored_test",
      matchers: [{ kind: "tree", value: "ignored" }],
      remediation_command: "Remove only invocation-created test output"
    }],
    intentionally_tracked: [{
      category: "tracked_test",
      paths: ["generate.mjs", "source.txt"],
      purpose: "Generated-contract production-runner fixture"
    }],
    generated_contracts: [{
      canonical_source: "source.txt",
      regeneration_argv: [["node", "generate.mjs"], ["node", "generate.mjs", "--dev"]],
      output_paths: ["out-default.txt", "out-dev.txt"],
      remediation_command: "node generate.mjs && node generate.mjs --dev"
    }],
    forbidden_tracked: [{
      category: "forbidden_test",
      matchers: [{ kind: "suffix", value: ".secret" }],
      remediation_command: "git rm --cached -- <repository-relative-path>"
    }],
    safe_fixtures: []
  };

  try {
    writeFileSync(path.join(repository, "generate.mjs"), generator);
    writeFileSync(path.join(repository, "source.txt"), "v1\n");
    writeFileSync(path.join(repository, "out-default.txt"), "v1:default\n");
    writeFileSync(path.join(repository, "out-dev.txt"), "v1:dev\n");
    execFileSync("git", ["add", "generate.mjs", "source.txt", "out-default.txt", "out-dev.txt"], { cwd: repository });
    execFileSync("git", ["commit", "--quiet", "-m", "generated fixture"], { cwd: repository });

    writeFileSync(path.join(repository, "tracked.txt"), "staged-preserved\n");
    execFileSync("git", ["add", "tracked.txt"], { cwd: repository });
    const indexBefore = readFileSync(path.join(repository, ".git/index"));
    const stagedBefore = execFileSync("git", ["diff", "--cached", "--raw", "-z"], { cwd: repository });

    const passing = runVerification(verificationOptions(repository, { artifactPolicy, enforceArtifactPolicy: true }));
    assert.equal(passing.status, 0);
    assert.deepEqual(readFileSync(path.join(repository, "out-default.txt")), Buffer.from("v1:default\n"));
    assert.deepEqual(readFileSync(path.join(repository, ".git/index")), indexBefore);
    assert.deepEqual(execFileSync("git", ["diff", "--cached", "--raw", "-z"], { cwd: repository }), stagedBefore);

    writeFileSync(path.join(repository, "source.txt"), "v2\n");
    const drifted = runVerification(verificationOptions(repository, { artifactPolicy, enforceArtifactPolicy: true }));
    assert.equal(drifted.status, 1);
    assert.match(drifted.output, /generated_contract_drift/);
    assert.match(drifted.output, /out-default\.txt/);
    assert.doesNotMatch(drifted.output, /v2/);
    assert.deepEqual(readFileSync(path.join(repository, "out-default.txt")), Buffer.from("v1:default\n"));
    assert.deepEqual(readFileSync(path.join(repository, "out-dev.txt")), Buffer.from("v1:dev\n"));
    assert.deepEqual(readFileSync(path.join(repository, ".git/index")), indexBefore);

    writeFileSync(path.join(repository, "fail-generator"), "trigger\n");
    const failed = runVerification(verificationOptions(repository, { artifactPolicy, enforceArtifactPolicy: true }));
    assert.equal(failed.status, 1);
    assert.deepEqual(readFileSync(path.join(repository, "out-default.txt")), Buffer.from("v1:default\n"));
    assert.deepEqual(readFileSync(path.join(repository, "out-dev.txt")), Buffer.from("v1:dev\n"));
    assert.deepEqual(readFileSync(path.join(repository, ".git/index")), indexBefore);
    assert.deepEqual(execFileSync("git", ["diff", "--cached", "--raw", "-z"], { cwd: repository }), stagedBefore);
  } finally {
    rmSync(repository, { recursive: true, force: true });
  }
});

test("capture self-test proves exact-commit isolation, dirty source success, and evidence rejection", () => {
  const script = new URL("../../script/capture_repository_verification_evidence.sh", import.meta.url).pathname;
  const result = spawnSync(script, ["--self-test"], {
    cwd: new URL("../..", import.meta.url),
    encoding: "utf8",
    timeout: 120_000
  });
  const output = `${result.stdout ?? ""}${result.stderr ?? ""}`;

  assert.equal(result.status, 0, output);
  for (const fixtureName of [
    "wrong-sha",
    "untracked-object",
    "failing-child",
    "altered-index",
    "residue",
    "forbidden-evidence-key",
    "symlink-escape",
    "dirty-source-success"
  ]) {
    assert.match(output, new RegExp(`PASS capture-self-test ${fixtureName}`));
  }
  assert.match(output, /PASS capture-self-test complete cases=8/);
});

test("evidence environment self-test locks Darwin arm64 tools and confinement", () => {
  const lockPath = new URL("../../script/repository_evidence_toolchain.json", import.meta.url);
  const stagesPath = new URL("../../script/repository_verification_stages.json", import.meta.url);
  const script = new URL("../../script/run_repository_evidence_environment.sh", import.meta.url).pathname;
  const result = spawnSync(script, ["--self-test"], {
    cwd: new URL("../..", import.meta.url),
    encoding: "utf8",
    timeout: 120_000
  });
  const output = `${result.stdout ?? ""}${result.stderr ?? ""}`;

  assert.equal(result.status, 0, output);
  const lock = JSON.parse(readFileSync(lockPath, "utf8"));
  assert.deepEqual(
    Object.keys(lock).sort(),
    ["architecture", "artifacts", "os", "python_packages", "schema_version"].sort()
  );
  assert.equal(lock.os, "Darwin");
  assert.equal(lock.architecture, "arm64");
  assert.deepEqual(lock.artifacts.map(artifact => [artifact.id, artifact.version]), [
    ["erlang", "27.3"],
    ["elixir", "1.19.5-otp-27"],
    ["node", "22.14.0"],
    ["java", "17.0.20.1+1"]
  ]);
  assert.deepEqual(lock.python_packages, [
    {
      id: "pyyaml",
      version: "6.0.3",
      url: "https://files.pythonhosted.org/packages/ae/92/861f152ce87c452b11b9d0977952259aa7df792d71c1053365cc7b09cc08/pyyaml-6.0.3-cp39-cp39-macosx_11_0_arm64.whl",
      authority_project: "PyYAML",
      asset: "pyyaml-6.0.3-cp39-cp39-macosx_11_0_arm64.whl",
      sha256: "c3355370a2c156cffb25e876646f149d5d68f5e0a3ce86a5084dd0b64a994917",
      import_name: "yaml"
    }
  ]);
  const stages = JSON.parse(readFileSync(stagesPath, "utf8")).stages;
  const rootProbe = stages.find(stage => stage.stage_id === "root-proof").required_tools.find(tool => tool.tool === "erl");
  const androidProbe = stages.find(stage => stage.stage_id === "android-package-proof").required_tools.find(tool => tool.tool === "java");
  assert.equal(rootProbe.argv[3], 'io:format("~s", [erlang:system_info(otp_release)]), halt().');
  assert.equal(androidProbe.version_regex, 'version "17\\.');
  for (const fixtureName of [
    "exact-version-selection",
    "checksum-rejection",
    "source-pin-rejection",
    "archive-entry-escape",
    "path-containment",
    "failure-cleanup",
    "forbidden-global-write",
    "missing-apple-tool",
    "cleanup-escape"
  ]) {
    assert.match(output, new RegExp(`PASS evidence-environment-self-test ${fixtureName}`));
  }
  assert.match(output, /PASS evidence-environment-self-test pinned-python-package/);
  assert.match(output, /PASS evidence-environment-self-test complete cases=10/);
});

test("CI inventory requires declared PyYAML and never performs an unpinned runtime install", () => {
  const source = readFileSync(new URL("../../script/list_merge_blocking_checks.py", import.meta.url), "utf8");

  assert.doesNotMatch(source, /pip[^\n]*(?:install|pyyaml)/i);
  assert.match(source, /PyYAML is required/);
});
