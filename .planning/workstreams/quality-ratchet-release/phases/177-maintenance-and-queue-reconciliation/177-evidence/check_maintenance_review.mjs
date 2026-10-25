#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { createHash } from "node:crypto";
import { fileURLToPath } from "node:url";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const PHASE_DIR = path.dirname(HERE);
const DEFAULT_INVENTORY = path.resolve(PHASE_DIR, "../176-local-work-and-artifact-disposition/176-INVENTORY.json");

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function roleFor(row) {
  const p = row.path;
  if (p.startsWith(".github/workflows/")) return "workflow owner";
  if (p.startsWith(".planning/tmp/") || p.startsWith(".tmp/")) return "repository maintainer; producing invocation and run owner are not established";
  if (p.startsWith(".planning/")) return "quality-ratchet-release planning owner";
  if (p.startsWith("lib/mix/tasks/")) return "release Mix task owner";
  if (p.startsWith("lib/crosswake/")) return "release/runtime module owner";
  if (p.startsWith("script/")) return "verification and release-script owner";
  if (p.startsWith("test/support/")) return "test fixture owner";
  if (p.startsWith("test/")) return "test owner";
  if (p === "AGENTS.md" || p === ".tool-versions") return "repository maintenance owner";
  return "repository owner";
}

function behaviorFor(row) {
  const p = row.path;
  if (p.startsWith(".github/workflows/")) return "workflow orchestration, job gates, and referenced proof dependencies";
  if (p.startsWith(".planning/tmp/") || p.startsWith(".tmp/")) return "captured execution artifact with producer/provenance not yet established";
  if (p.startsWith(".planning/")) return "planning, state, policy, or historical evidence artifact";
  if (p.startsWith("lib/mix/tasks/")) return "Mix task entry point, option/mode dispatch, and delegated behavior";
  if (p.startsWith("lib/crosswake/release_candidate/")) return "release candidate evidence, authorization, observation, or apply behavior";
  if (p === "lib/crosswake/release_status.ex") return "package-family release status aggregation and exit contract";
  if (p.startsWith("lib/crosswake/")) return "runtime or verification module behavior";
  if (p.startsWith("script/release_candidate/")) return "release evidence runner, collector, or subprocess behavior";
  if (p.startsWith("script/")) return "repository verification or release automation behavior";
  if (p.startsWith("test/support/")) return "shared release evidence fixture behavior";
  if (p.startsWith("test/")) return "asserted implementation, workflow, or denial contract";
  if (p === "AGENTS.md") return "active maintainer and agent instructions";
  if (p === ".tool-versions") return "toolchain selection and reproducibility";
  return "captured repository behavior; exact contract requires review";
}

function exactCandidate(c) {
  return { commit: c.commit, tree: c.tree };
}

function makeRowReview(row, inventory) {
  const edgePaths = [...new Set((row.ownershipEdges ?? []).map((edge) => edge.path))];
  const isArtifact = row.path.startsWith(".planning/") || row.path.startsWith(".tmp/");
  const missingFact = isArtifact
    ? `The producing invocation, active consumer, and unique historical value for ${row.path} have not all been established.`
    : `The captured hunk and behavior in ${row.path} have not been compared semantically with each exact merged candidate and mapped to a verified replacement.`;
  const edgeAction = edgePaths.length
    ? `Trace the captured behavior in ${row.path} through all ${edgePaths.length} recorded owner edges, inspect dynamic and workflow callers, then compare exact source bytes and behavior against every listed candidate before changing disposition.`
    : `Identify the producer/consumer and inspect the captured behavior in ${row.path}; compare its exact source bytes and behavior against every listed candidate before changing disposition.`;
  const candidates = inventory.sourceComparison.candidates.map((c) => {
    const match = row.comparison.candidates.find((item) => item.commit === c.commit && item.tree === c.tree);
    return {
      ...exactCandidate(c),
      headEqual: match?.headEqual === true,
      indexEqual: match?.indexEqual === true,
      worktreeEqual: match?.worktreeEqual === true,
      semanticEquivalenceReviewed: match?.semanticEquivalenceReviewed === true,
    };
  });
  return {
    rowId: row.rowId,
    path: row.path,
    capturedStatus: row.status,
    disposition: "retain",
    behaviorId: `captured-path:${row.rowId}`,
    behavior: behaviorFor(row),
    semanticStatus: "candidate-source-unavailable",
    semanticEvidence: {
      phase176Comparison: "per-row exact comparison flags and sanitized owner edges are available",
      exactMergedSourceBytes: "unavailable in this checkout; none of the three compared commit objects is present",
      capturedPrivateBytes: "not read; Phase176 restore proof is the retained recovery evidence",
      semanticEquivalence: "not established",
    },
    semanticOwner: row.nextOwner || roleFor(row),
    ownershipEdges: edgePaths,
    phase176OwnerAction: row.nextAction,
    partitions: {
      headToIndex: row.comparison.capturedHeadToIndex,
      indexToWorktree: row.comparison.capturedIndexToWorktree,
      candidateComparisons: candidates,
      preservedSeparately: true,
      recovery: row.recovery,
    },
    nextAction: edgeAction,
    missingFact,
    retirementEligible: false,
  };
}

function supportedStatusTrace() {
  return {
    behaviorId: "supported:crosswake.release.status",
    name: "crosswake.release.status",
    status: "supported",
    entryPoint: "Mix.Tasks.Crosswake.Release.Status.run/1, exposed as mix crosswake.release.status",
    implementation: "Crosswake.ReleaseStatus.build/1, render/1, and exit_code/1",
    sourceEvidence: [
      "lib/mix/tasks/crosswake.release.status.ex:32-46 parses only strict json/live/source_receipt options and rejects invalid options",
      "lib/crosswake/release_status.ex:72-99 reads the manifest root version once and threads it into candidate evaluation",
      "lib/crosswake/release_status.ex:197-237 reports failed checks and unverifiable checks distinctly; unverifiable exits 3",
      "test/mix/tasks/crosswake_release_status_test.ex exercises the Mix task output and exit contract",
    ],
    actualCallers: [
      "README.md:151 documents the operator invocation",
      "docs/COMPANION-PUBLISH-RUNBOOK.md:48-50 documents local, JSON, and live invocations",
      "guides/companion_compatibility.md:36,73 links public registry truth to the status command",
    ],
    exposure: [
      "mix.exs package files includes lib, which exposes the Mix task implementation in the package",
      "README.md and the companion runbook document the command for maintainers",
    ],
    exposureIsNotSupportProof: true,
    guards: [
      "strict OptionParser allowlist rejects invalid command options",
      "the manifest root entry is the single candidate-version source in the status computation",
      "unknown live observations remain unverifiable and exit 3 rather than being treated as clean",
      "the task only observes status; it does not capture, approve, publish, or recover a candidate",
    ],
    replacement: "none; this is the retained supported read-only path",
    preservation: "retain the task, status module, caller-facing docs, and exit-contract tests",
    verification: "source trace completed by inspection; execution is deferred to the qualified isolated source surface",
    nextAction: "Keep the supported status path available; validate it from an exact clean source surface in Phase178.",
  };
}

function supportedGenericPath(name, module, callers, guards, nextAction) {
  return {
    behaviorId: `supported:${name}`,
    name,
    status: "supported",
    entryPoint: `Mix.Tasks.${module}.run/1, exposed as mix ${name}`,
    implementation: `lib/mix/tasks/${name.replaceAll(".", ".")}.ex`,
    actualCallers: callers,
    exposure: ["Mix task is exposed through the package's lib file set", ...callers],
    exposureIsNotSupportProof: true,
    guards,
    replacement: "none; retained as the generic supported release surface under D-04",
    preservation: "keep current task and its existing tests/callers",
    verification: "caller and implementation traced by source inspection; execution belongs to the qualified isolated source surface",
    nextAction,
  };
}

function captureModes(source, routerName) {
  const start = source.indexOf("case opts[:mode] do");
  const end = source.indexOf("\n  defp ", start);
  if (start < 0 || end < 0) return [];
  const section = source.slice(start, end);
  const found = [];
  const re = /^\s*"([a-z0-9-]+)"\s*->\s*(.+)$/gm;
  for (const match of section.matchAll(re)) {
    const mode = match[1];
    const handler = match[2].trim();
    found.push({ mode, handler, owner: routerName });
  }
  return found;
}

function routerEvidence(repoRoot, relativePath) {
  const bytes = fs.readFileSync(path.join(repoRoot, relativePath));
  const modes = captureModes(bytes.toString("utf8"), relativePath).map(({ mode, handler }) => ({ mode, handler }));
  return {
    path: relativePath,
    sha256: createHash("sha256").update(bytes).digest("hex"),
    modeCount: modes.length,
    modes,
    sourceScope: "current recovery-checkout mode dispatch snapshot; not an exact merged-source qualification",
  };
}

function modeCandidate(entry, file, task) {
  const inspection = /inspect/.test(entry.mode);
  const blocked = /raise\(/.test(entry.handler);
  const purpose = inspection
    ? "local inspection of attempt or historical evidence"
    : /prepare/.test(entry.mode)
      ? "prepare or reserve local attempt evidence"
      : /decision|authorize|hold/.test(entry.mode)
        ? "consume a one-use decision or authorization"
        : /apply/.test(entry.mode)
          ? "run a bounded external or simulated apply route"
          : /preflight|run|fake|trigger/.test(entry.mode)
            ? "perform a bounded preflight, collection, or continuation"
            : "mode-specific release maintenance behavior";
  const missingFacts = [
    "whether this exact attempt/mode reached a terminal outcome and whether its unique bytes are preserved",
    "all direct, aliased, dynamically composed, shell, workflow, stage, package, documentation, and test callers",
    "whether a proposed replacement performs the same required job and preserves the archived verdict",
  ];
  return {
    behaviorId: `candidate:${task}:${entry.mode}`,
    entryPoint: `mix ${task} --mode ${entry.mode}`,
    mode: entry.mode,
    handler: entry.handler,
    purpose,
    owner: file,
    terminalAttemptEvidence: "not established by this bounded source trace",
    supportAndExposure: {
      directMixTask: "discoverable Mix task with a mode allowlist",
      packageMembership: "Mix package includes lib; exposure only, not proof this mode is supported",
      callers: "this mode's dispatch arm is a known call edge; external/dynamic callers remain under review",
      callerReviewComplete: false,
    },
    callerReview: {
      directMixTaskAndModeDispatch: "observed in the current router",
      aliasesAndDynamicMixTaskNames: "not fully traced",
      subprocessShellWorkflowAndStageCallers: "not fully traced",
      packageMembership: "exposure signal only",
      generatedDocsGuidesPublicDocsAndTests: "not fully traced per mode",
      literalGrepAbsenceMeansUnreachable: false,
    },
    replacement: { entryPoint: null, requiredJob: "not established; no replacement is selected" },
    archivePreservation: "retain implementation and historical inspection paths pending artifact-reader comparison",
    verification: blocked ? "dispatcher explicitly rejects this mode; verify denial-before-side-effect invariant in isolated source surface" : "not run in protected recovery checkout",
    disposition: "retained_pending_proof",
    retirementEligible: false,
    nextAction: `Trace ${entry.mode} through its handler, exact attempt evidence, complete caller graph and reader/replacement before considering any retirement.`,
    missingFacts,
    knownDispatcherEntry: `${file} mode arm delegates to ${entry.handler}`,
  };
}

export function buildReview(inventory, { repoRoot = path.resolve(PHASE_DIR, "../../../../.."), now = new Date() } = {}) {
  const statusTask = supportedStatusTrace();
  const supportedPaths = [
    statusTask,
    supportedGenericPath(
      "crosswake.release.candidate",
      "Crosswake.Release.Candidate",
      [".github/workflows/ios-mirror-backfill.yml:313 invokes exact-candidate evaluation", "docs/COMPANION-PUBLISH-RUNBOOK.md:100 documents the exact-ref command"],
      ["requires an explicit version and full ref; candidate evaluation is read-only"],
      "Retain exact-candidate evaluation and recheck its callers and guards in the isolated surface.",
    ),
    supportedGenericPath(
      "crosswake.release.receipt",
      "Crosswake.Release.Receipt",
      ["test/crosswake/release_candidate/companion_receipt_test.ex exercises the task with bounded input/output paths"],
      ["strict input/output options and local receipt validation"],
      "Retain the generic receipt writer and verify its bounded local-file contract in the isolated surface.",
    ),
    supportedGenericPath(
      "crosswake.release.gate",
      "Crosswake.Release.Gate",
      ["script/release_candidate/require_release_evidence.sh dynamically invokes mix crosswake.release.gate with validated exact evidence"],
      ["required evidence is checked before the exact authorization gate; missing values fail closed"],
      "Retain the generic evidence gate and dynamic shell caller; verify the composed invocation and denial behavior in the isolated surface.",
    ),
  ];

  const candidateRelative = "lib/mix/tasks/crosswake.release.candidate_read.ex";
  const mirrorRelative = "lib/mix/tasks/crosswake.release.mirror_tag_026.ex";
  const candidateFile = path.join(repoRoot, candidateRelative);
  const mirrorFile = path.join(repoRoot, mirrorRelative);
  const candidates = [];
  const modeRouterEvidence = [];
  if (fs.existsSync(candidateFile)) {
    const evidence = routerEvidence(repoRoot, candidateRelative);
    modeRouterEvidence.push(evidence);
    candidates.push(...evidence.modes
      .map((entry) => modeCandidate(entry, candidateRelative, "crosswake.release.candidate_read")));
  }
  if (fs.existsSync(mirrorFile)) {
    const evidence = routerEvidence(repoRoot, mirrorRelative);
    modeRouterEvidence.push(evidence);
    candidates.push(...evidence.modes
      .map((entry) => modeCandidate(entry, mirrorRelative, "crosswake.release.mirror_tag_026")));
  }

  return {
    schemaVersion: 1,
    phase: "177",
    plan: "177-01",
    generatedAt: now.toISOString(),
    captureId: inventory.captureId,
    status: "partial_retention_review",
    scope: "Local preservation and release behavior evidence only; no source retirement or Phase178 verification is claimed.",
    privacy: {
      fieldsAllowed: ["opaque Phase176 rowId", "repository-relative source path", "source commit/tree identity", "owner role", "sanitized behavior and action"],
      privateRecoveryMaterialIncluded: false,
      rawPayloadsCredentialsAndDeviceOrAccountIdentifiersIncluded: false,
    },
    sourceComparison: {
      inventoryPath: ".planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json",
      captureId: inventory.captureId,
      captureHeadOid: inventory.source.head,
      captureHeadTreeOid: inventory.source.headTree,
      candidates: inventory.sourceComparison.candidates.map(exactCandidate),
      provenance: "Identities and reachability attestations are copied from the frozen Phase176 inventory; the Phase177 recovery checkout did not independently refresh the remote source.",
    },
    partitionPolicy: {
      headToIndexAndIndexToWorktreeRemainSeparate: true,
      source: "Phase176 per-row comparison records",
      recovery: "Phase176 recoveryVerification and each row's recovery result; private archive pointer and payload bytes omitted",
      semanticEquivalenceReviewed: false,
      dispositionRule: "No candidate equality or semantic review is established; retain every unique captured row pending the recorded action.",
    },
    rows: inventory.rows.map((row) => makeRowReview(row, inventory)),
    supportedPaths,
    modeRouterEvidence,
    retirementCandidates: candidates,
    gates: {
      sourceChangeEligibleCandidates: 0,
      reason: "No candidate has complete terminal-attempt, dynamic caller, replacement-job, archive-reader, and isolated verification evidence.",
      phase178Claimed: false,
      requirementCompletionClaimed: false,
    },
  };
}

function privacyIssues(review) {
  const text = JSON.stringify(review);
  const issues = [];
  if (/(?:^|["\s])\/(?:Users|private|tmp|var)\//.test(text)) issues.push("absolute or private path present");
  if (/"(?:rawBody|rawPayload|credentials?|tokens?|privateArchivePointer|payloadBytes)"\s*:/i.test(text)) issues.push("sensitive field name present");
  return issues;
}

function candidateIsProven(candidate) {
  return Boolean(
    candidate.terminalAttemptEvidence && candidate.terminalAttemptEvidence !== "not established by this bounded source trace" &&
    candidate.supportAndExposure?.callerReviewComplete === true &&
    Array.isArray(candidate.supportAndExposure?.callers) && candidate.supportAndExposure.callers.length > 0 &&
    candidate.replacement?.entryPoint && candidate.replacement?.requiredJob && candidate.replacement.requiredJob !== "unspecified" &&
    candidate.archivePreservation && /verified|preserved/i.test(candidate.archivePreservation) &&
    candidate.verification && !/not run/i.test(candidate.verification)
  );
}

export function validateReview(review, inventory, { mode = "complete", repoRoot = null } = {}) {
  const issues = [];
  if (!isRecord(review) || !isRecord(inventory)) return ["review and inventory must be JSON objects"];
  if (review.schemaVersion !== 1) issues.push("unsupported review schemaVersion");
  if (review.captureId !== inventory.captureId) issues.push("captureId does not match the frozen Phase176 inventory");
  if (review.sourceComparison?.captureHeadOid !== inventory.source?.head || review.sourceComparison?.captureHeadTreeOid !== inventory.source?.headTree) {
    issues.push("source identity does not match the frozen Phase176 capture");
  }
  const expectedCandidates = (inventory.sourceComparison?.candidates ?? []).map(exactCandidate);
  if (JSON.stringify(review.sourceComparison?.candidates) !== JSON.stringify(expectedCandidates)) issues.push("candidate commit/tree identities differ from Phase176 provenance");
  issues.push(...privacyIssues(review));

  const sourceRows = inventory.rows ?? [];
  const rows = review.rows ?? [];
  const expected = new Map(sourceRows.map((row) => [row.rowId, row]));
  const seen = new Set();
  const rowBehaviorIds = new Set();
  for (const row of rows) {
    if (seen.has(row.rowId)) issues.push(`duplicate rowId ${row.rowId}`);
    seen.add(row.rowId);
    const source = expected.get(row.rowId);
    if (!source) {
      issues.push(`unknown rowId ${row.rowId}`);
      continue;
    }
    if (row.path !== source.path) issues.push(`rowId ${row.rowId} path does not match its captured identity`);
    if (row.disposition !== "retain") issues.push(`rowId ${row.rowId} must remain retained until complete comparison is proven`);
    if (!row.behaviorId || !row.behavior || !row.semanticOwner) issues.push(`rowId ${row.rowId} is missing behavior or semantic owner`);
    if (row.behaviorId && rowBehaviorIds.has(row.behaviorId)) issues.push(`duplicate behaviorId ${row.behaviorId}`);
    rowBehaviorIds.add(row.behaviorId);
    if (!row.nextAction || !row.missingFact) issues.push(`rowId ${row.rowId} requires a concrete next action and exact missing fact`);
    if (row.semanticStatus !== "reviewed" && !row.semanticEvidence?.exactMergedSourceBytes) issues.push(`rowId ${row.rowId} lacks a precise semantic-review limitation`);
    if (row.partitions?.headToIndex !== source.comparison?.capturedHeadToIndex || row.partitions?.indexToWorktree !== source.comparison?.capturedIndexToWorktree) {
      issues.push(`rowId ${row.rowId} partition comparison differs from the frozen inventory`);
    }
    if (row.partitions?.preservedSeparately !== true) issues.push(`rowId ${row.rowId} collapses captured byte partitions`);
    const expectedPartitionCandidates = (source.comparison?.candidates ?? []).map((item) => ({
      ...exactCandidate(item),
      headEqual: item.headEqual === true,
      indexEqual: item.indexEqual === true,
      worktreeEqual: item.worktreeEqual === true,
      semanticEquivalenceReviewed: item.semanticEquivalenceReviewed === true,
    }));
    if (JSON.stringify(row.partitions?.candidateComparisons) !== JSON.stringify(expectedPartitionCandidates) || expectedPartitionCandidates.length !== expectedCandidates.length) issues.push(`rowId ${row.rowId} lacks the complete exact-source identities or has byte/semantic facts that differ from Phase176`);
    if (row.semanticStatus !== "reviewed" && row.disposition !== "retain") issues.push(`rowId ${row.rowId} cannot leave retain while its behavior is unresolved`);
    if (row.retirementEligible === true) issues.push(`rowId ${row.rowId} cannot be marked retirement eligible by this preservation review`);
  }

  const missing = [...expected.keys()].filter((id) => !seen.has(id));
  if (mode === "tracer") {
    if (rows.length < 1) issues.push("tracer requires an exercised Phase176 row");
  } else if (missing.length) {
    issues.push(`missing ${missing.length} captured row(s): ${missing.slice(0, 5).join(", ")}`);
  }

  const behaviorIds = new Set();
  const candidates = review.retirementCandidates ?? [];
  const sourceModes = (review.modeRouterEvidence ?? []).flatMap((source) => {
    if (!source.path || !/^[a-f0-9]{64}$/.test(source.sha256 ?? "") || source.modeCount !== source.modes?.length) {
      issues.push(`mode router evidence is incomplete for ${source.path ?? "(missing path)"}`);
    }
    if (repoRoot && source.path && fs.existsSync(path.join(repoRoot, source.path))) {
      const fresh = routerEvidence(repoRoot, source.path);
      if (fresh.sha256 !== source.sha256 || JSON.stringify(fresh.modes) !== JSON.stringify(source.modes)) issues.push(`mode router evidence is stale for ${source.path}`);
    } else if (repoRoot && source.path) {
      issues.push(`mode router source is missing: ${source.path}`);
    }
    return (source.modes ?? []).map((entry) => `${source.path}:${entry.mode}`);
  });
  if (new Set(sourceModes).size !== sourceModes.length) issues.push("duplicate mode in the recorded source router roster");
  const recordedModeIds = candidates.map((candidate) => `${candidate.owner}:${candidate.mode}`);
  if (mode === "complete" && (sourceModes.length === 0 || recordedModeIds.length !== sourceModes.length || sourceModes.some((id) => !recordedModeIds.includes(id)))) {
    issues.push("retirement-candidate behavior set is reduced or differs from the recorded mode-router roster");
  }
  for (const candidate of candidates) {
    if (!candidate.behaviorId || behaviorIds.has(candidate.behaviorId)) issues.push(`duplicate or missing candidate behaviorId ${candidate.behaviorId ?? "(empty)"}`);
    behaviorIds.add(candidate.behaviorId);
    if (!candidate.owner || !candidate.entryPoint || !candidate.nextAction) issues.push(`candidate ${candidate.behaviorId} is missing owner, entry point, or action`);
    if (candidate.supportAndExposure?.packageMembership && !candidate.supportAndExposure?.callers) issues.push(`candidate ${candidate.behaviorId} has package inclusion without caller evidence`);
    if (candidate.supportEvidence?.length === 1 && /package includes|package inclusion/i.test(candidate.supportEvidence[0])) issues.push(`candidate ${candidate.behaviorId} treats package inclusion as support evidence`);
    if (candidate.callerReview?.literalGrepAbsenceMeansUnreachable === true) issues.push(`candidate ${candidate.behaviorId} treats literal-grep absence as unreachability proof`);
    if (candidate.disposition === "retired" && !candidateIsProven(candidate)) issues.push(`candidate ${candidate.behaviorId} is marked retired without terminal, caller, replacement, preservation, and verification proof`);
    if (candidate.disposition !== "retired" && (!Array.isArray(candidate.missingFacts) || candidate.missingFacts.length === 0)) issues.push(`candidate ${candidate.behaviorId} must name missing facts while retained`);
  }

  const status = (review.supportedPaths ?? []).find((entry) => entry.name === "crosswake.release.status");
  if (!status) issues.push("supported crosswake.release.status trace is missing");
  else {
    if (!status.entryPoint || !status.implementation || !Array.isArray(status.actualCallers) || status.actualCallers.length < 1) issues.push("supported status trace needs entry point, implementation, and actual callers");
    if (!Array.isArray(status.guards) || status.guards.length < 2) issues.push("supported status trace needs named fail-closed/source guards");
    if (status.exposureIsNotSupportProof !== true) issues.push("status package exposure must be distinguished from support evidence");
    if (status.status !== "supported" || !status.nextAction) issues.push("supported status path needs an explicit retained action");
  }
  if (mode === "complete" && (!review.gates || review.gates.sourceChangeEligibleCandidates !== 0 || review.gates.phase178Claimed !== false || review.gates.requirementCompletionClaimed !== false)) {
    issues.push("complete review must explicitly keep unproven candidates, Phase178, and requirement completion closed");
  }
  return issues;
}

function usage() {
  return "Usage: node check_maintenance_review.mjs --tracer <review.json> [--inventory <176-INVENTORY.json>] | --complete <review.json> [--inventory <176-INVENTORY.json>] | --seed [--inventory <176-INVENTORY.json>]";
}

function main(args) {
  const flagIndex = args.findIndex((arg) => ["--tracer", "--complete", "--seed"].includes(arg));
  if (flagIndex < 0) throw new Error(usage());
  const mode = args[flagIndex].slice(2);
  const reviewPath = mode === "seed" ? path.join(HERE, "maintenance-review.json") : args[flagIndex + 1];
  const inventoryIndex = args.indexOf("--inventory");
  const inventoryPath = inventoryIndex >= 0 ? args[inventoryIndex + 1] : DEFAULT_INVENTORY;
  if (!reviewPath || (mode !== "seed" && reviewPath.startsWith("--"))) throw new Error(usage());
  const inventory = JSON.parse(fs.readFileSync(inventoryPath, "utf8"));
  if (mode === "seed") {
    const repoRoot = path.resolve(HERE, "../../../../../../");
    const report = buildReview(inventory, { repoRoot });
    fs.writeFileSync(reviewPath, `${JSON.stringify(report, null, 2)}\n`, { mode: 0o644 });
    fs.chmodSync(reviewPath, 0o644);
  }
  const review = JSON.parse(fs.readFileSync(reviewPath, "utf8"));
  const repoRoot = path.resolve(HERE, "../../../../../../");
  const errors = validateReview(review, inventory, { mode, repoRoot: mode === "seed" ? null : repoRoot });
  if (errors.length) {
    for (const error of errors) console.error(`ERROR: ${error}`);
    process.exitCode = 1;
  } else {
    console.log(`PASS ${mode}: ${review.rows.length}/${inventory.rows.length} Phase176 rows retained; ${review.retirementCandidates.length} mode candidates retained pending proof; ${review.supportedPaths.length} supported generic paths recorded.`);
  }
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    main(process.argv.slice(2));
  } catch (error) {
    console.error(`ERROR: ${error.message}`);
    process.exitCode = 2;
  }
}
