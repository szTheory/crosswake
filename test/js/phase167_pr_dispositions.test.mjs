import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { spawnSync } from "node:child_process";
import {
  appendFileSync,
  copyFileSync,
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
const expectedHandoffPaths = [
  ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-resolution.json",
  ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-08-SUMMARY.md",
  ".planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-VERIFICATION.md",
  ".planning/workstreams/quality-ratchet-release/ROADMAP.md",
  ".planning/workstreams/quality-ratchet-release/STATE.md",
];
const runtimePaths = [
  ".planning/workstreams/quality-ratchet-release/config.json",
  ".planning/workstreams/quality-ratchet-release/milestone.lock",
  ".planning/workstreams/quality-ratchet-release/state.json",
];

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
  const result = spawnSync("git", args, { cwd, encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout.trim();
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
  for (const relative of runtimePaths) {
    const destination = path.join(repository, relative);
    mkdirSync(path.dirname(destination), { recursive: true });
    copyFileSync(path.join(root, relative), destination);
  }
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

test("local reconciliation accepts the retained scope and clean synthetic repository", () => {
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
