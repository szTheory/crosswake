/* Repository verification is a closed purpose inventory, never a shell-command API (D-01–D-06). */
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import {
  loadStageManifest,
  runPreflight,
  runVerification,
  selectStages,
  validateCiParity,
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

test("production manifest is closed, ordered, fixed, and has literal CI owners", () => {
  const manifest = loadStageManifest();
  assert.deepEqual(manifest.stages.map(stage => stage.stage_id), expectedIds);
  assert.equal(validateStageManifest(manifest), manifest);
  assert.equal(validateCiParity(manifest), manifest);

  for (const stage of manifest.stages) {
    assert(Array.isArray(stage.argv) && stage.argv.length > 0);
    assert.equal(typeof stage.cwd, "string");
    assert.equal(Array.isArray(stage.ci_owners), true);
    assert(stage.ci_owners.length > 0);
    assert(!stage.argv.some(part => /[;&|`]/.test(part)));
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
    workflowSource: readFileSync(new URL("../../.github/workflows/crosswake-ci.yml", import.meta.url), "utf8")
  });
  assert.equal(result.status, 0);
  assert.match(result.output, /PASS repository-cleanliness/);
});
