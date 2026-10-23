import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import { validateReview } from "./check_maintenance_review.mjs";

const candidate = {
  commit: "6da6df6f9ddc0f48614fd99c50decc6dc23387c4",
  tree: "e83165776220d727da07f4b02bd9d9de35e61bcc",
};

function fixture() {
  const inventory = {
    captureId: "capture-fixture",
    source: { head: "d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377", headTree: "7b9cbda27f4f0f0d7ed9e0aab9b6c29f9d5d8c24" },
    sourceComparison: { candidates: [candidate] },
    rows: [{
      rowId: "a1b2c3d4",
      path: "lib/mix/tasks/crosswake.release.status.ex",
      status: " M",
      disposition: "retain",
      comparison: { capturedHeadToIndex: "exactly-equal", capturedIndexToWorktree: "different-or-no-stage-zero", candidates: [candidate] },
      ownershipEdges: [{ path: "lib/crosswake/release_status.ex", relationship: "implementation owner" }],
    }],
  };
  const review = {
    schemaVersion: 1,
    phase: "177",
    captureId: "capture-fixture",
    sourceComparison: {
      captureHeadOid: inventory.source.head,
      captureHeadTreeOid: inventory.source.headTree,
      candidates: [candidate],
    },
    rows: [{
      rowId: "a1b2c3d4",
      path: "lib/mix/tasks/crosswake.release.status.ex",
      disposition: "retain",
      behaviorId: "captured-path:a1b2c3d4",
      behavior: "Mix task entry point and status option dispatch",
      semanticStatus: "unreviewed",
      semanticEvidence: { exactMergedSourceBytes: "unavailable in the fixture; no equivalence asserted" },
      semanticOwner: "release Mix task owner",
      ownershipEdges: ["lib/crosswake/release_status.ex"],
      partitions: {
        headToIndex: "exactly-equal",
        indexToWorktree: "different-or-no-stage-zero",
        candidateComparisons: [{ ...candidate, headEqual: false, indexEqual: false, worktreeEqual: false, semanticEquivalenceReviewed: false }],
        preservedSeparately: true,
        recoveryEvidence: "Phase176 frozen inventory recoveryVerification",
      },
      nextAction: "Compare this captured path's content and mode with each listed source tree, then map each changed behavior to the implementation and test edges before any disposition change.",
      missingFact: "The captured hunk-to-behavior comparison against the exact candidate trees has not been performed.",
    }],
    supportedPaths: [{
      behaviorId: "supported:crosswake.release.status",
      name: "crosswake.release.status",
      status: "supported",
      entryPoint: "Mix.Tasks.Crosswake.Release.Status.run/1 via mix crosswake.release.status",
      implementation: "Crosswake.ReleaseStatus.build/1 and exit_code/1",
      actualCallers: ["README.md operator command", "docs/COMPANION-PUBLISH-RUNBOOK.md operator command"],
      exposure: ["mix.exs package files includes lib", "README and runbook document the command"],
      exposureIsNotSupportProof: true,
      guards: ["OptionParser strict allowlist rejects invalid options", "manifest root version is read once as the candidate version", "unverifiable checks return exit 3 and do not count as clean"],
      nextAction: "Keep this read-only operator path available and verify it from an exact clean source surface in Phase178.",
    }],
    modeRouterEvidence: [{ path: "router.ex", sha256: "a".repeat(64), modeCount: 1, modes: [{ mode: "fixture-mode", handler: "inspect_mode(opts)" }] }],
    retirementCandidates: [{
      behaviorId: "candidate:router:fixture-mode",
      entryPoint: "mix crosswake.release.router --mode fixture-mode",
      mode: "fixture-mode",
      purpose: "bounded historical behavior",
      owner: "router.ex",
      terminalAttemptEvidence: "not established by this bounded source trace",
      supportAndExposure: { directMixTask: "mode dispatch", packageMembership: "exposure only", callers: "incomplete", callerReviewComplete: false },
      callerReview: { literalGrepAbsenceMeansUnreachable: false },
      replacement: { entryPoint: null, requiredJob: "not established" },
      archivePreservation: "retain implementation and historical inspection paths pending artifact-reader comparison",
      verification: "not run in protected recovery checkout",
      disposition: "retained_pending_proof",
      retirementEligible: false,
      nextAction: "Trace the exact attempt, all callers, replacement job, archive reader, and isolated verification.",
      missingFacts: ["terminal attempt", "dynamic callers", "replacement and archive verification"],
    }],
  };
  return { inventory, review };
}

test("tracer accepts one real row and a supported status trace with distinct byte partitions", () => {
  const { inventory, review } = fixture();
  assert.deepEqual(validateReview(review, inventory, { mode: "tracer" }), []);
});

test("tracer accepts a real Phase176 rowId with its exact captured candidate identities", () => {
  const inventory = JSON.parse(fs.readFileSync(new URL("../../176-local-work-and-artifact-disposition/176-INVENTORY.json", import.meta.url), "utf8"));
  const sourceRow = inventory.rows[0];
  const { review } = fixture();
  review.captureId = inventory.captureId;
  review.sourceComparison = {
    captureHeadOid: inventory.source.head,
    captureHeadTreeOid: inventory.source.headTree,
    candidates: inventory.sourceComparison.candidates.map(({ commit, tree }) => ({ commit, tree })),
  };
  review.rows[0] = {
    ...review.rows[0],
    rowId: sourceRow.rowId,
    path: sourceRow.path,
    capturedStatus: sourceRow.status,
    semanticOwner: sourceRow.nextOwner,
    ownershipEdges: sourceRow.ownershipEdges.map((edge) => edge.path),
    phase176OwnerAction: sourceRow.nextAction,
    partitions: {
      headToIndex: sourceRow.comparison.capturedHeadToIndex,
      indexToWorktree: sourceRow.comparison.capturedIndexToWorktree,
      candidateComparisons: sourceRow.comparison.candidates.map((item) => ({
        commit: item.commit,
        tree: item.tree,
        headEqual: item.headEqual,
        indexEqual: item.indexEqual,
        worktreeEqual: item.worktreeEqual,
        semanticEquivalenceReviewed: item.semanticEquivalenceReviewed,
      })),
      preservedSeparately: true,
      recoveryEvidence: "Phase176 frozen inventory row recovery result",
    },
  };
  assert.deepEqual(validateReview(review, inventory, { mode: "tracer" }), []);
});

test("tracer rejects a fabricated rowId", () => {
  const { inventory, review } = fixture();
  review.rows[0].rowId = "invented-row";
  assert.ok(validateReview(review, inventory, { mode: "tracer" }).some((issue) => issue.includes("rowId")));
});

test("tracer rejects a missing semantic owner", () => {
  const { inventory, review } = fixture();
  review.rows[0].semanticOwner = "";
  assert.ok(validateReview(review, inventory, { mode: "tracer" }).some((issue) => issue.includes("owner")));
});

test("complete mode rejects omitted and duplicate captured rows", () => {
  const { inventory, review } = fixture();
  inventory.rows.push({ ...inventory.rows[0], rowId: "e5f6a7b8", path: "test/status_test.ex" });
  assert.ok(validateReview(review, inventory, { mode: "complete" }).some((issue) => issue.includes("missing")));
  review.rows.push({ ...review.rows[0] });
  assert.ok(validateReview(review, inventory, { mode: "complete" }).some((issue) => issue.includes("duplicate")));
});

test("complete mode rejects duplicate behavior identities", () => {
  const { inventory, review } = fixture();
  review.rows.push({ ...review.rows[0], rowId: "second-row", path: "test/other_test.exs" });
  inventory.rows.push({ ...inventory.rows[0], rowId: "second-row", path: "test/other_test.exs" });
  assert.ok(validateReview(review, inventory, { mode: "complete" }).some((issue) => issue.includes("duplicate behaviorId")));
});

test("package inclusion alone cannot establish supported behavior or retirement", () => {
  const { inventory, review } = fixture();
  review.retirementCandidates.push({
    behaviorId: "old-launcher",
    entryPoint: "mix crosswake.release.old_launcher",
    purpose: "one-use write attempt",
    disposition: "retained_pending_proof",
    owner: "release operations owner",
    terminalAttemptEvidence: "",
    supportEvidence: ["mix.exs package includes lib"],
    callers: [],
    replacement: { entryPoint: "new helper", requiredJob: "unspecified" },
    archivePreservation: "not inspected",
    verification: "not run",
    nextAction: "Identify the terminal attempt and actual dynamic callers, then prove a full replacement and retained archive verdict before reconsidering.",
    missingFacts: ["terminal attempt identity and dynamic caller/replacement proof"],
  });
  const errors = validateReview(review, inventory, { mode: "complete" });
  assert.ok(errors.some((issue) => issue.includes("package inclusion")));
});

test("literal caller search absence cannot authorize retirement", () => {
  const { inventory, review } = fixture();
  review.retirementCandidates.push({
    behaviorId: "old-dynamic-launcher",
    entryPoint: "mix crosswake.release.old_dynamic_launcher",
    purpose: "bounded maintenance mode",
    disposition: "retired",
    owner: "release task owner",
    terminalAttemptEvidence: "terminal run recorded",
    supportAndExposure: { callerReviewComplete: false, callers: [], packageMembership: "included in lib" },
    callerReview: { literalGrepAbsenceMeansUnreachable: true },
    replacement: { entryPoint: "replacement task", requiredJob: "same required job" },
    archivePreservation: "reader verified against preserved archive",
    verification: "verified",
    nextAction: "none",
    missingFacts: [],
  });
  const errors = validateReview(review, inventory, { mode: "tracer" });
  assert.ok(errors.some((issue) => issue.includes("literal-grep absence")));
  assert.ok(errors.some((issue) => issue.includes("marked retired without")));
});
