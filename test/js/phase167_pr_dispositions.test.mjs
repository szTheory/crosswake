import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import {
  appendFileSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readFileSync,
  rmSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const script = "script/check_phase167_pr_dispositions.py";
const evidenceRoot = path.join(
  root,
  ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence",
);
const resolutionPath = path.join(evidenceRoot, "phase167-closeout-resolution.json");
const scopePath = path.join(evidenceRoot, "phase167-closeout-scope.json");
const deferMarker = "<!-- crosswake-phase167-release-only-deferred-phase168 -->";
const expectedHandoffPaths = [
  ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-resolution.json",
  ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-08-SUMMARY.md",
  ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-VERIFICATION.md",
  ".planning/workstreams/quality-ratchet-release/ROADMAP.md",
  ".planning/workstreams/quality-ratchet-release/STATE.md",
];
const expectedPhase168PathBlobs = [
  {
    path: ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-resolution.json",
    mode: "100644",
    blob: "78920bb2990121c7b5705a17fa5866a9b41f73be",
  },
  {
    path: ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-08-SUMMARY.md",
    mode: "100644",
    blob: "512786c4b492084696a6df308be7e8cf1a55bbe7",
  },
  {
    path: ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-VERIFICATION.md",
    mode: "100644",
    blob: "dd146c148ef78d8cb06ed93433ced4e4b929a066",
  },
  {
    path: ".planning/workstreams/quality-ratchet-release/ROADMAP.md",
    mode: "100644",
    blob: "ea598f1f65f4e61b40b496dfd4136d1b773ceb19",
  },
  {
    path: ".planning/workstreams/quality-ratchet-release/STATE.md",
    mode: "100644",
    blob: "54c6e8c4eda10b3ebb84ace0b1687cf1e3540524",
  },
];
const runtimePaths = [
  ".planning/workstreams/quality-ratchet-release/config.json",
  ".planning/workstreams/quality-ratchet-release/milestone.lock",
  ".planning/workstreams/quality-ratchet-release/state.json",
];
const runtimeLockFixture = path.join(
  root,
  "test/fixtures/phase167_runtime_authority/milestone.lock",
);
const historicalRuntimeState = {
  contract: "1.0.0",
  flavor: "core",
  milestone: "v22.0 — Quality Ratchet & Release Readiness",
  phases: [
    { number: "164", name: "Dependency Security and Gate Authority", status: "complete" },
    { number: "165", name: "Efficient and Maintainable CI", status: "complete" },
    { number: "166", name: "Clean-Checkout Engineering Quality", status: "complete" },
    { number: "167", name: "Documentation and Pull-Request Reconciliation", status: "in_progress" },
    { number: "168", name: "0.2.1 Release Candidate Readiness", status: "pending" },
  ],
  next: {
    command: "/gsd:progress --next",
    label: "Advance to the next step",
    reason: "Phase 167 of 5 · 60% · executing",
  },
  updated_at: "2026-09-10T21:42:01.912Z",
};

function json(pathname) {
  return JSON.parse(readFileSync(pathname, "utf8"));
}

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

function clone(value) {
  return structuredClone(value);
}

function writeJson(directory, name, value) {
  const pathname = path.join(directory, name);
  writeFileSync(pathname, `${JSON.stringify(value, null, 2)}\n`, "utf8");
  return pathname;
}

function runValidator(args, options = {}) {
  return spawnSync("python3", [script, ...args], {
    cwd: root,
    encoding: "utf8",
    env: { ...process.env, PYTHONDONTWRITEBYTECODE: "1", ...options.env },
  });
}

function assertPass(result, output) {
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.equal(result.stdout, `${output}\n`);
  assert.equal(result.stderr, "");
}

function assertClosedFailure(result, output) {
  assert.equal(result.status, 1, result.stderr || result.stdout);
  assert.equal(result.stdout, `${output}\n`);
  assert.equal(result.stderr, "");
}

function commentPage(nodes, totalCount, hasPreviousPage, startCursor) {
  return {
    data: {
      repository: {
        pullRequest: {
          number: 57,
          comments: {
            nodes,
            pageInfo: { hasPreviousPage, startCursor },
            totalCount,
          },
        },
      },
    },
  };
}

function runCommentPagination(pages, { failAt = null } = {}) {
  const temporary = mkdtempSync(path.join(tmpdir(), "crosswake-phase167-pagination-"));
  try {
    const fakeBin = path.join(temporary, "bin");
    mkdirSync(fakeBin);
    const fixturePath = writeJson(temporary, "pages.json", { pages, failAt });
    const statePath = path.join(temporary, "state");
    const fakeGh = path.join(fakeBin, "gh");
    writeFileSync(
      fakeGh,
      `#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "node:fs";
const fixture = JSON.parse(readFileSync(process.env.PHASE167_PAGINATION_FIXTURE, "utf8"));
const index = existsSync(process.env.PHASE167_PAGINATION_STATE)
  ? Number(readFileSync(process.env.PHASE167_PAGINATION_STATE, "utf8"))
  : 0;
writeFileSync(process.env.PHASE167_PAGINATION_STATE, String(index + 1));
const query = process.argv.find((value) => value.startsWith("query=")) ?? "";
if (!query.includes("comments(last: 100, before: $before)") ||
    !query.includes("pageInfo { hasPreviousPage startCursor }") ||
    !query.includes("totalCount")) process.exit(88);
if (fixture.failAt === index) process.exit(89);
if (index >= fixture.pages.length) process.exit(90);
process.stdout.write(JSON.stringify(fixture.pages[index]));
`,
      { mode: 0o755 },
    );
    return runValidator(["--verify-comment-pagination", "57"], {
      env: {
        PATH: `${fakeBin}${path.delimiter}${process.env.PATH}`,
        PHASE167_PAGINATION_FIXTURE: fixturePath,
        PHASE167_PAGINATION_STATE: statePath,
      },
    });
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
}

function closeoutArgs(receipt = resolutionPath, extra = []) {
  return ["--verify-closeout-resolution", receipt, ...extra];
}

function reconciliationArgs(receipt = resolutionPath, scope = scopePath, extra = []) {
  return ["--verify-local-reconciliation", receipt, "--scope", scope, ...extra];
}

function closeoutObservation(receipt) {
  return {
    schema_version: 1,
    kind: "phase167_closeout_observation",
    default_oid: receipt.current_observation.default_oid,
    open_pr_numbers: receipt.current_observation.open_pr_numbers,
    closeout_pr: {
      number: receipt.closeout.pr_number,
      state: "MERGED",
      head_oid: receipt.closeout.tested_head_oid,
      base_oid: receipt.closeout.tested_base_oid,
      merge_oid: receipt.closeout.merge_commit_oid,
    },
    crosswake_ci: receipt.closeout.crosswake_ci,
    ordinary_prs: receipt.current_observation.ordinary_prs,
    recovery_transactions: receipt.current_observation.recovery_transactions,
  };
}

function mutateReceipt(directory, name, change) {
  const receipt = json(resolutionPath);
  change(receipt);
  return writeJson(directory, `${name}.json`, receipt);
}

function git(args, cwd) {
  const result = spawnSync("git", args, {
    cwd,
    encoding: "utf8",
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: "Crosswake Test",
      GIT_AUTHOR_EMAIL: "crosswake-test@example.invalid",
      GIT_COMMITTER_NAME: "Crosswake Test",
      GIT_COMMITTER_EMAIL: "crosswake-test@example.invalid",
    },
  });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout.trim();
}

function phase168EntryLandingRepository() {
  const temporary = mkdtempSync(path.join(tmpdir(), "crosswake-phase168-entry-"));
  const repository = path.join(temporary, "repository");
  git(["clone", "--quiet", "--shared", root, repository], temporary);

  const base = "30ca31ed3f4be23ae6e4d115d8d0f6273aae220a";
  git(["read-tree", base], repository);
  for (const record of expectedPhase168PathBlobs) {
    git(["update-index", "--add", "--cacheinfo", record.mode, record.blob, record.path], repository);
  }
  const candidateTree = git(["write-tree"], repository);
  const candidate = git(["commit-tree", candidateTree, "-p", base, "-m", "Phase 168 entry candidate"], repository);
  const merge = git(["commit-tree", candidateTree, "-p", base, "-p", candidate, "-m", "Phase 168 entry merge"], repository);
  const receipt = {
    schema_version: 1,
    kind: "phase168_entry_landing",
    handoff_owner: "phase_168_first_reversible_landing",
    path_blobs: expectedPhase168PathBlobs,
    observed_default_before_oid: base,
    candidate: {
      pr_number: 168,
      base_oid: base,
      head_oid: candidate,
      tree_oid: candidateTree,
    },
    crosswake_ci: {
      name: "Crosswake CI",
      run_id: 1,
      head_oid: candidate,
      status: "COMPLETED",
      conclusion: "SUCCESS",
    },
    merge: {
      oid: merge,
      parent_oids: [base, candidate],
      tree_oid: candidateTree,
    },
    observed_default_after_oid: merge,
    external_state_changed: true,
  };
  const receiptPath = writeJson(temporary, "phase168-entry-landing.json", receipt);
  return { temporary, repository, receipt, receiptPath };
}

function localReconciliationRepository() {
  const temporary = mkdtempSync(path.join(tmpdir(), "crosswake-phase167-local-"));
  const repository = path.join(temporary, "repository");
  git(["clone", "--quiet", "--shared", root, repository], temporary);

  if (git(["branch", "--show-current"], repository) !== "agent-phase167-fixforward") {
    git(["switch", "--quiet", "--create", "agent-phase167-fixforward"], repository);
  }

  const receipt = json(resolutionPath);
  git(["branch", "--force", "main", receipt.pre_reconciliation.expected_local_main_after_oid], repository);
  const runtimeSources = new Map([
    [runtimePaths[0], path.join(root, runtimePaths[0])],
    [runtimePaths[1], runtimeLockFixture],
  ]);
  for (const [relative, source] of runtimeSources) {
    const destination = path.join(repository, relative);
    mkdirSync(path.dirname(destination), { recursive: true });
    copyFileSync(source, destination);
  }
  writeJson(
    path.dirname(path.join(repository, runtimePaths[2])),
    path.basename(runtimePaths[2]),
    historicalRuntimeState,
  );
  return { temporary, repository };
}

test("self-test covers seven ordinary PRs and separate recovery", () => {
  const result = runValidator(["--self-test"]);

  assert.equal(result.status, 0, result.stderr);
  assert.match(
    result.stdout,
    /phase167-pr-dispositions-self-test: PASS count=[1-9][0-9]*/,
  );
});

test("closeout resolution accepts the retained offline authority", () => {
  const result = runValidator(closeoutArgs());

  assertPass(
    result,
    "phase167-closeout-resolution: PASS ordinary=7 recovery=4 handoff=5",
  );
});

test("closeout resolution binds scope bytes to the exact tested Git blob", () => {
  const temporary = mkdtempSync(path.join(tmpdir(), "crosswake-phase167-scope-blob-"));
  try {
    const scope = json(scopePath);
    const reserializedScope = path.join(temporary, "reserialized-scope.json");
    writeFileSync(reserializedScope, `${JSON.stringify(scope)}\n`, "utf8");
    const receipt = mutateReceipt(temporary, "reserialized-scope-receipt", (value) => {
      value.scope.sha256 = sha256(readFileSync(reserializedScope));
    });

    assertClosedFailure(
      runValidator(closeoutArgs(receipt, ["--scope", reserializedScope])),
      "phase167-closeout-resolution: FAIL closed_failure",
    );
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("closeout live observations are injectable without GitHub or network access", () => {
  const temporary = mkdtempSync(path.join(tmpdir(), "crosswake-phase167-observation-"));
  try {
    const receipt = json(resolutionPath);
    const observation = writeJson(
      temporary,
      "observation.json",
      closeoutObservation(receipt),
    );
    const fakeBin = path.join(temporary, "bin");
    mkdirSync(fakeBin);
    const forbiddenGh = path.join(fakeBin, "gh");
    writeFileSync(forbiddenGh, "#!/bin/sh\necho network-was-used >&2\nexit 97\n", {
      mode: 0o755,
    });

    const result = runValidator(closeoutArgs(resolutionPath, ["--observation", observation]), {
      env: { PATH: `${fakeBin}${path.delimiter}${process.env.PATH}` },
    });

    assertPass(
      result,
      "phase167-closeout-resolution: PASS ordinary=7 recovery=4 handoff=5 observation=injected",
    );
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("closeout resolution fails closed on every retained authority boundary", async (t) => {
  const temporary = mkdtempSync(path.join(tmpdir(), "crosswake-phase167-closeout-negative-"));
  const receipt = json(resolutionPath);
  const otherOid = receipt.scope.payload_source_oid;
  const otherTree = receipt.scope.payload_source_tree;
  const cases = [
    ["baseline digest", (value) => { value.baseline.sha256 = "0".repeat(64); }],
    ["scope digest", (value) => { value.scope.sha256 = "0".repeat(64); }],
    ["tested head", (value) => {
      value.closeout.tested_head_oid = otherOid;
      value.closeout.crosswake_ci.head_oid = otherOid;
    }],
    ["CI head", (value) => { value.closeout.crosswake_ci.head_oid = otherOid; }],
    ["CI conclusion", (value) => { value.closeout.crosswake_ci.conclusion = "FAILURE"; }],
    ["CI context total", (value) => { value.closeout.crosswake_ci.successful_contexts = 46; }],
    ["merge parent order", (value) => { value.closeout.merge_parent_oids.reverse(); }],
    ["merge ancestry", (value) => {
      value.closeout.merge_commit_oid = otherOid;
      value.closeout.fresh_default_oid = otherOid;
      value.closeout.candidate_reachable_from_fresh_default = true;
    }],
    ["tested and merge tree identity", (value) => { value.closeout.merge_tree_oid = otherTree; }],
    ["fresh default tree identity", (value) => { value.closeout.fresh_default_tree_oid = otherTree; }],
    ["ordinary baseline cardinality", (value) => { value.baseline.ordinary_numbers.pop(); }],
    ["recovery baseline cardinality", (value) => { value.baseline.recovery_numbers.pop(); }],
    ["ordinary observation cardinality", (value) => { value.current_observation.ordinary_prs.pop(); }],
    ["recovery observation cardinality", (value) => { value.current_observation.recovery_transactions.pop(); }],
    ["handoff path set", (value) => { value.phase_168_handoff.paths.pop(); }],
    ["handoff order", (value) => { value.phase_168_handoff.paths.reverse(); }],
    ["handoff owner", (value) => { value.phase_168_handoff.owner = "phase_167"; }],
  ];

  try {
    for (const [name, change] of cases) {
      await t.test(name, () => {
        const candidate = clone(receipt);
        change(candidate);
        const pathname = writeJson(temporary, `${name.replaceAll(" ", "-")}.json`, candidate);
        assertClosedFailure(
          runValidator(closeoutArgs(pathname)),
          "phase167-closeout-resolution: FAIL closed_failure",
        );
      });
    }
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("closeout diagnostics are stable, privacy-safe, and non-echoing", () => {
  const temporary = mkdtempSync(path.join(tmpdir(), "crosswake-phase167-private-"));
  const canary = "PRIVATE_CLOSEOUT_CANARY_DO_NOT_ECHO";
  try {
    const pathname = mutateReceipt(temporary, "private", (value) => {
      value.untrusted_private_value = canary;
    });
    const result = runValidator(closeoutArgs(pathname));

    assertClosedFailure(result, "phase167-closeout-resolution: FAIL closed_failure");
    assert.doesNotMatch(`${result.stdout}${result.stderr}`, new RegExp(canary));
    assert.doesNotMatch(`${result.stdout}${result.stderr}`, /https?:\/\//);
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("local reconciliation accepts the tracked Phase 167 runtime authority fixture", () => {
  assert.equal(existsSync(runtimeLockFixture), true, "tracked runtime authority fixture is missing");
  const { temporary, repository } = localReconciliationRepository();
  try {
    const result = runValidator(reconciliationArgs(resolutionPath, scopePath, ["--repository", repository]));

    assertPass(
      result,
      "phase167-local-reconciliation: PASS branch=agent-phase167-fixforward runtime=3",
    );
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("local reconciliation rejects current runtime drift from the pinned receipt hashes", () => {
  const { temporary, repository } = localReconciliationRepository();
  try {
    copyFileSync(
      path.join(root, runtimePaths[1]),
      path.join(repository, runtimePaths[1]),
    );
    const result = runValidator(reconciliationArgs(resolutionPath, scopePath, ["--repository", repository]));

    assertClosedFailure(
      result,
      "phase167-local-reconciliation: FAIL closed_failure",
    );
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("local reconciliation rejects ref, scope, index, runtime, and clean-state drift", async (t) => {
  const { temporary, repository } = localReconciliationRepository();
  const receipt = json(resolutionPath);
  const originalMain = receipt.pre_reconciliation.expected_local_main_after_oid;
  const trackedPath = "README.md";
  const trackedBytes = readFileSync(path.join(repository, trackedPath));
  const extraPath = path.join(repository, "phase167-private-extra.tmp");

  async function rejects(name, args = reconciliationArgs(resolutionPath, scopePath, ["--repository", repository])) {
    await t.test(name, () => {
      assertClosedFailure(
        runValidator(args),
        "phase167-local-reconciliation: FAIL closed_failure",
      );
    });
  }

  try {
    const wrongBranch = mutateReceipt(temporary, "wrong-branch", (value) => {
      value.pre_reconciliation.phase_branch = "main";
    });
    await rejects("phase branch receipt", reconciliationArgs(wrongBranch, scopePath, ["--repository", repository]));

    const wrongMain = mutateReceipt(temporary, "wrong-main", (value) => {
      value.pre_reconciliation.expected_local_main_after_oid = value.scope.payload_source_oid;
    });
    await rejects("local main receipt", reconciliationArgs(wrongMain, scopePath, ["--repository", repository]));

    const wrongTip = mutateReceipt(temporary, "wrong-tip", (value) => {
      value.pre_reconciliation.phase_branch_tip = value.pre_reconciliation.local_main_before_oid;
    });
    await rejects("phase tip reachability", reconciliationArgs(wrongTip, scopePath, ["--repository", repository]));

    const wrongRuntime = mutateReceipt(temporary, "wrong-runtime", (value) => {
      value.pre_reconciliation.runtime_hashes[runtimePaths[0]] = "0".repeat(64);
    });
    await rejects("runtime hash receipt", reconciliationArgs(wrongRuntime, scopePath, ["--repository", repository]));

    const mutatedScope = json(scopePath);
    mutatedScope.payload_scope[0].blob = "0".repeat(40);
    const mutatedScopePath = writeJson(temporary, "mutated-scope.json", mutatedScope);
    const matchingScopeDigest = mutateReceipt(temporary, "matching-mutated-scope", (value) => {
      value.scope.sha256 = sha256(readFileSync(mutatedScopePath));
    });
    await rejects(
      "scope bytes despite matching digest",
      reconciliationArgs(matchingScopeDigest, mutatedScopePath, ["--repository", repository]),
    );

    git(["branch", "--force", "main", receipt.scope.payload_source_oid], repository);
    await rejects("local main ref");
    git(["branch", "--force", "main", originalMain], repository);

    git(["update-index", "--force-remove", "--", trackedPath], repository);
    await rejects("index residue");
    git(["add", "--", trackedPath], repository);

    appendFileSync(path.join(repository, trackedPath), "\nphase167 tracked residue\n");
    await rejects("tracked worktree residue");
    writeFileSync(path.join(repository, trackedPath), trackedBytes);

    writeFileSync(extraPath, "PRIVATE_LOCAL_CANARY_DO_NOT_ECHO\n", "utf8");
    await rejects("unexpected untracked residue");
    unlinkSync(extraPath);

    unlinkSync(path.join(repository, runtimePaths[1]));
    await rejects("missing runtime file");
    copyFileSync(runtimeLockFixture, path.join(repository, runtimePaths[1]));

    writeFileSync(path.join(repository, runtimePaths[0]), "{}\n", "utf8");
    await rejects("runtime file bytes");
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("local reconciliation diagnostics do not echo private receipt values or paths", () => {
  const temporary = mkdtempSync(path.join(tmpdir(), "crosswake-phase167-local-private-"));
  const canary = "PRIVATE_LOCAL_RECEIPT_CANARY_DO_NOT_ECHO";
  try {
    const pathname = mutateReceipt(temporary, canary, (value) => {
      value.pre_reconciliation.untrusted_private_value = canary;
    });
    const result = runValidator(reconciliationArgs(pathname));

    assertClosedFailure(result, "phase167-local-reconciliation: FAIL closed_failure");
    assert.doesNotMatch(`${result.stdout}${result.stderr}`, new RegExp(canary));
    assert.doesNotMatch(`${result.stdout}${result.stderr}`, /https?:\/\//);
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("the closeout handoff fixture remains the exact fixed five paths", () => {
  const receipt = json(resolutionPath);
  assert.deepEqual(receipt.phase_168_handoff.paths, expectedHandoffPaths);
  assert.equal(receipt.phase_168_handoff.owner, "phase_168_first_reversible_landing");
});

test("Phase 168 entry landing accepts only the exact five-blob graph", () => {
  const { temporary, repository, receiptPath } = phase168EntryLandingRepository();
  try {
    assertPass(
      runValidator([
        "--verify-phase168-entry-landing",
        receiptPath,
        "--repository",
        repository,
      ]),
      "phase168-entry-landing: PASS paths=5 observation=offline external_state_changed=true",
    );
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("Phase 168 entry landing rejects every changed authority field", async (t) => {
  const { temporary, repository, receipt } = phase168EntryLandingRepository();
  const cases = [
    ["unknown field", (value) => { value.untrusted = "PRIVATE_ENTRY_CANARY_DO_NOT_ECHO"; }],
    ["handoff owner", (value) => { value.handoff_owner = "phase_167"; }],
    ["path mode", (value) => { value.path_blobs[0].mode = "100755"; }],
    ["path blob", (value) => { value.path_blobs[0].blob = "0".repeat(40); }],
    ["default before", (value) => { value.observed_default_before_oid = value.candidate.head_oid; }],
    ["candidate base", (value) => { value.candidate.base_oid = value.candidate.head_oid; }],
    ["candidate head", (value) => { value.candidate.head_oid = value.observed_default_before_oid; }],
    ["candidate tree", (value) => { value.candidate.tree_oid = value.observed_default_before_oid; }],
    ["CI name", (value) => { value.crosswake_ci.name = "Other CI"; }],
    ["CI run", (value) => { value.crosswake_ci.run_id = 0; }],
    ["CI head", (value) => { value.crosswake_ci.head_oid = value.observed_default_before_oid; }],
    ["CI status", (value) => { value.crosswake_ci.status = "IN_PROGRESS"; }],
    ["CI conclusion", (value) => { value.crosswake_ci.conclusion = "FAILURE"; }],
    ["merge oid", (value) => { value.merge.oid = value.candidate.head_oid; }],
    ["merge parents", (value) => { value.merge.parent_oids.reverse(); }],
    ["merge tree", (value) => { value.merge.tree_oid = value.observed_default_before_oid; }],
    ["default after", (value) => { value.observed_default_after_oid = value.candidate.head_oid; }],
    ["external state", (value) => { value.external_state_changed = false; }],
  ];

  try {
    for (const [name, change] of cases) {
      await t.test(name, () => {
        const candidate = clone(receipt);
        change(candidate);
        const pathname = writeJson(temporary, `${name.replaceAll(" ", "-")}.json`, candidate);
        assertClosedFailure(
          runValidator([
            "--verify-phase168-entry-landing",
            pathname,
            "--repository",
            repository,
          ]),
          "phase168-entry-landing: FAIL closed_failure",
        );
      });
    }
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});

test("live deferral-marker authority traverses more than 100 comments", () => {
  const recent = Array.from({ length: 100 }, (_, index) => ({
    id: `recent-${index}`,
    body: "ordinary comment",
  }));
  const result = runCommentPagination([
    commentPage(recent, 101, true, "cursor-older"),
    commentPage([{ id: "old-marker", body: deferMarker }], 101, false, "cursor-oldest"),
  ]);

  assertPass(
    result,
    `phase167-comment-pagination: PASS pr=57 complete=true markers=1 digest=${sha256(deferMarker)}`,
  );
});

test("live deferral-marker authority blocks incomplete pagination", async (t) => {
  const nodes = [{ id: "recent-1", body: "ordinary comment" }];
  const blocked = "phase167-comment-pagination: BLOCKED pr=57 correction=retry_cursor_complete_comment_fetch";
  const cases = [
    ["malformed cursor", [commentPage(nodes, 2, true, null)], {}],
    [
      "repeated cursor",
      [
        commentPage(nodes, 3, true, "cursor-repeat"),
        commentPage([{ id: "older-1", body: "ordinary comment" }], 3, true, "cursor-repeat"),
      ],
      {},
    ],
    [
      "total mismatch",
      [
        commentPage(nodes, 2, true, "cursor-older"),
        commentPage([{ id: "older-1", body: deferMarker }], 3, false, "cursor-oldest"),
      ],
      {},
    ],
    [
      "duplicate page",
      [
        commentPage(nodes, 2, true, "cursor-older"),
        commentPage(nodes, 2, false, "cursor-oldest"),
      ],
      {},
    ],
    [
      "page fetch failure",
      [commentPage(nodes, 2, true, "cursor-older")],
      { failAt: 1 },
    ],
  ];

  for (const [name, pages, options] of cases) {
    await t.test(name, () => {
      const result = runCommentPagination(pages, options);
      assert.equal(result.status, 1, result.stderr || result.stdout);
      assert.equal(result.stdout, `${blocked}\n`);
      assert.equal(result.stderr, "");
      assert.doesNotMatch(`${result.stdout}${result.stderr}`, /ordinary comment|old-marker|recent-1/);
    });
  }
});
