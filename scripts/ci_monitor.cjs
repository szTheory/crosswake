#!/usr/bin/env node

const { spawnSync } = require("node:child_process");
const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");

const HELP = `Usage: node scripts/ci_monitor.cjs <command> [options]

Commands:
  runs [--branch <name>] [--limit <count>]
  pr-checks <pull-request>
  pr-failures <pull-request>
  watch <run-id> [--interval <seconds>]
  fail-fast <run-id> [--interval <seconds>]
  log-failed <run-id>
  test-summary <run-id>
  grep <run-id> --pattern <regex>
  wait-for <run-id> <job> --keyword <text>
  check-actions [workflow-file]
  capture-evidence <output.json>
  capture-evidence --source <final-source.json> --cohorts matched --output <output.json>
  capture-required-context-snapshot <output.json>
  verify-required-context-snapshot <snapshot.json> [--live]
  verify-remote-default-source --sha <40-hex-sha> --output <output.json>
  verify-remote-default-source --source <source.json>
  verify-final-remote-default-source --sha <40-hex-sha> --workflow <file> --manifest <file> --output <output.json>
  verify-final-remote-default-source --source <source.json>
  probe-phase165 --source <source.json> --output <output.json> [--assert-cleanup]
  validate-evidence <evidence.json>
  render-evidence <evidence.json> [output.md]
  compare-evidence <before.json> <after.json> [output.md]
  test-evidence
`;

function fail(message) {
  process.stderr.write(`ci-monitor: ${message}\n`);
  process.exit(2);
}

function option(args, name, fallback) {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  if (!args[index + 1] || args[index + 1].startsWith("--")) fail(`${name} requires a value`);
  return args[index + 1];
}

function positiveInteger(value, label) {
  if (!/^\d+$/.test(String(value)) || Number(value) < 1) fail(`${label} must be a positive integer`);
  return String(value);
}

function gh(args, capture = false) {
  const result = spawnSync("gh", args, {
    encoding: "utf8",
    stdio: capture ? ["ignore", "pipe", "pipe"] : "inherit",
  });

  if (result.error) fail(`could not run gh: ${result.error.message}`);
  if (capture && result.stderr) process.stderr.write(result.stderr);
  if (result.status !== 0) process.exit(result.status ?? 1);
  return capture ? result.stdout : "";
}

function runId(value) {
  return positiveInteger(value, "run-id");
}

function runs(args) {
  const branch = option(args, "--branch");
  const limit = positiveInteger(option(args, "--limit", "20"), "--limit");
  const ghArgs = [
    "run",
    "list",
    "--limit",
    limit,
    "--json",
    "databaseId,workflowName,status,conclusion,headBranch,event,url,createdAt,updatedAt",
  ];
  if (branch) ghArgs.push("--branch", branch);

  const records = JSON.parse(gh(ghArgs, true));
  if (records.length === 0) {
    process.stdout.write("no workflow runs found\n");
    return;
  }

  for (const record of records) {
    process.stdout.write(
      [
        record.databaseId,
        record.status,
        record.conclusion || "pending",
        record.workflowName,
        record.headBranch,
        record.url,
      ].join("\t") + "\n",
    );
  }
}

function prChecks(args) {
  const pullRequest = positiveInteger(args[0], "pull-request");
  const output = gh(["pr", "view", pullRequest, "--json", "statusCheckRollup"], true);
  const checks = JSON.parse(output).statusCheckRollup || [];

  const normalized = checks.map((check) => {
    const name = check.name || check.context || "unnamed-check";
    const state = check.conclusion || check.state || check.status || "UNKNOWN";
    return { name, state, url: check.detailsUrl || check.targetUrl || "" };
  });

  const failing = normalized.filter((check) =>
    ["ACTION_REQUIRED", "CANCELLED", "ERROR", "FAILURE", "STALE", "TIMED_OUT"].includes(check.state),
  );
  const pending = normalized.filter((check) =>
    ["EXPECTED", "IN_PROGRESS", "PENDING", "QUEUED", "REQUESTED", "WAITING", "UNKNOWN"].includes(check.state),
  );

  for (const check of normalized) {
    process.stdout.write(`${check.state}\t${check.name}\t${check.url}\n`);
  }
  process.stdout.write(
    `${JSON.stringify({ total: normalized.length, failing: failing.length, pending: pending.length })}\n`,
  );

  if (failing.length) process.exitCode = 1;
  else if (pending.length) process.exitCode = 3;
}

function prFailures(args) {
  const pullRequest = positiveInteger(args[0], "pull-request");
  const { nameWithOwner } = JSON.parse(gh(["repo", "view", "--json", "nameWithOwner"], true));
  const [owner, name] = nameWithOwner.split("/");
  const query = `
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          commits(last: 1) {
            nodes {
              commit {
                statusCheckRollup {
                  contexts(first: 100) {
                    nodes {
                      ... on CheckRun {
                        name
                        conclusion
                        detailsUrl
                        title
                        summary
                        text
                        annotations(first: 50) {
                          nodes { annotationLevel message path title }
                        }
                      }
                      ... on StatusContext {
                        context
                        state
                        targetUrl
                        description
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  `;
  const output = gh(
    [
      "api",
      "graphql",
      "-f",
      `query=${query}`,
      "-F",
      `owner=${owner}`,
      "-F",
      `name=${name}`,
      "-F",
      `number=${pullRequest}`,
    ],
    true,
  );
  const nodes =
    JSON.parse(output).data.repository.pullRequest.commits.nodes[0]?.commit.statusCheckRollup?.contexts
      .nodes || [];
  const failures = nodes.filter((node) =>
    ["ACTION_REQUIRED", "CANCELLED", "ERROR", "FAILURE", "STALE", "TIMED_OUT"].includes(
      node.conclusion || node.state,
    ),
  );

  for (const failure of failures) {
    const title = failure.title || failure.description || "";
    const summary = failure.summary || failure.text || "";
    process.stdout.write(
      `${failure.name || failure.context}\t${failure.conclusion || failure.state}\t${failure.detailsUrl || failure.targetUrl || ""}\n`,
    );
    if (title) process.stdout.write(`${title}\n`);
    if (summary) process.stdout.write(`${summary}\n`);
    for (const annotation of failure.annotations?.nodes || []) {
      process.stdout.write(
        `${annotation.annotationLevel}\t${annotation.path || ""}\t${annotation.title || ""}\t${annotation.message}\n`,
      );
    }
  }
  process.stdout.write(`${JSON.stringify({ failing: failures.length })}\n`);
  if (failures.length) process.exitCode = 1;
}

function watch(args) {
  const id = runId(args[0]);
  const interval = positiveInteger(option(args, "--interval", "10"), "--interval");
  gh(["run", "watch", id, "--interval", interval, "--exit-status"]);
}

function logFailed(args) {
  gh(["run", "view", runId(args[0]), "--log-failed"]);
}

function testSummary(args) {
  const output = gh(["run", "view", runId(args[0]), "--json", "jobs"], true);
  const { jobs = [] } = JSON.parse(output);
  const counts = jobs.reduce((result, job) => {
    const key = job.conclusion || job.status || "unknown";
    result[key] = (result[key] || 0) + 1;
    return result;
  }, {});

  process.stdout.write(`${JSON.stringify({ total: jobs.length, counts })}\n`);
  for (const job of jobs) {
    process.stdout.write(`${job.name}\t${job.status}\t${job.conclusion || "pending"}\n`);
  }
}

function grepLogs(args) {
  const pattern = option(args, "--pattern");
  if (!pattern) fail("grep requires --pattern <regex>");

  let regex;
  try {
    regex = new RegExp(pattern, "i");
  } catch (error) {
    fail(`invalid regex: ${error.message}`);
  }

  const output = gh(["run", "view", runId(args[0]), "--log"], true);
  const matches = output.split("\n").filter((line) => regex.test(line));
  process.stdout.write(matches.join("\n") + (matches.length ? "\n" : ""));
  if (matches.length === 0) process.exitCode = 1;
}

function waitFor(args) {
  const id = runId(args[0]);
  const job = args[1];
  const keyword = option(args, "--keyword");
  if (!job || job.startsWith("--")) fail("wait-for requires a job name");
  if (!keyword) fail("wait-for requires --keyword <text>");

  watch([id]);
  const output = gh(["run", "view", id, "--job", job, "--log"], true);
  if (!output.includes(keyword)) fail(`completed job log did not contain keyword: ${keyword}`);
  process.stdout.write(`matched ${JSON.stringify(keyword)} in job ${JSON.stringify(job)}\n`);
}

function checkActions(args) {
  const paths = args[0] ? [args[0]] : [".github/workflows"];
  const output = spawnSync("rg", ["-n", "uses:\\s*[^#[:space:]]+", ...paths], {
    encoding: "utf8",
  });
  if (output.error) fail(`could not run rg: ${output.error.message}`);
  if (output.status !== 0 && output.status !== 1) process.exit(output.status);

  const lines = output.stdout.trim().split("\n").filter(Boolean);
  const mutable = lines.filter((line) => {
    const match = line.match(/uses:\s*([^\s#]+)/);
    if (!match || match[1].startsWith("./") || !match[1].includes("@")) return false;
    const ref = match[1].split("@").pop();
    return !/^[a-f0-9]{40}$/i.test(ref);
  });

  process.stdout.write(lines.join("\n") + (lines.length ? "\n" : ""));
  process.stdout.write(`actions=${lines.length} mutable_refs=${mutable.length}\n`);
  if (mutable.length) process.stdout.write("mutable action refs should be reviewed against upstream releases\n");
}

const EVIDENCE_SCHEMA_VERSION = 1;
const NOT_EXPOSED = "not_exposed";
const NOT_MEASURED_REASONS = new Set([
  "cohort_unavailable",
  "timestamp_incomplete",
  "timestamp_invalid",
  "timestamp_reversed",
  "cache_outcome_unavailable",
]);
const TOP_LEVEL_FIELDS = new Set([
  "schema_version",
  "repository_sha",
  "captured_at",
  "historical_provenance",
  "source_commands",
  "cohorts",
]);
const COHORT_FIELDS = new Set([
  "name",
  "criteria",
  "sample_count",
  "status",
  "reason",
  "observations",
  "aggregates",
]);
const OBSERVATION_FIELDS = new Set([
  "repository_sha",
  "run_id",
  "attempt",
  "event",
  "workflow_name",
  "runner_class",
  "created_at",
  "run_started_at",
  "completed_at",
  "outcome",
  "job_count",
  "check_count",
  "workflow_start_delay_ms",
  "job_execution_ms",
  "critical_path_ms",
  "aggregate_runner_seconds",
  "job_queue_time",
  "cache",
]);
const METRIC_FIELDS = new Set(["status", "sample_count", "median", "min", "max", "reason"]);
const AGGREGATE_FIELDS = new Set([
  "workflow_start_delay_ms",
  "job_execution_ms",
  "critical_path_ms",
  "aggregate_runner_seconds",
]);
const CACHE_FIELDS = new Set(["status", "reason"]);
const FORBIDDEN_FIELD = /(actor|message|raw|payload|log|runner_(id|identity|name)|cache_key|credential|token|account|device|url|link)/i;

function canonicalJson(value) {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (value && typeof value === "object") {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

function digest(value) {
  return crypto.createHash("sha256").update(canonicalJson(value)).digest("hex");
}

function parseTimestamp(value) {
  if (typeof value !== "string" || value.length === 0) return null;
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function durationMetric(start, finish) {
  if (!start || !finish) return { status: "not_measured", reason: "timestamp_incomplete" };
  const startMs = parseTimestamp(start);
  const finishMs = parseTimestamp(finish);
  if (startMs === null || finishMs === null) {
    return { status: "not_measured", reason: "timestamp_invalid" };
  }
  if (finishMs < startMs) return { status: "not_measured", reason: "timestamp_reversed" };
  return finishMs - startMs;
}

function runnerClass(labels) {
  const normalized = Array.isArray(labels) ? labels.map(String).map((label) => label.toLowerCase()) : [];
  if (normalized.some((label) => label.includes("macos"))) return "macos_hosted";
  if (normalized.some((label) => label.includes("ubuntu"))) return "linux_hosted";
  if (normalized.some((label) => label.includes("windows"))) return "windows_hosted";
  if (normalized.includes("self-hosted")) return "self_hosted";
  return "not_measured";
}

function aggregateMetric(values) {
  const observed = values.filter((value) => Number.isInteger(value)).sort((a, b) => a - b);
  if (observed.length === 0) {
    return { status: "not_measured", sample_count: 0, reason: "cohort_unavailable" };
  }
  const middle = Math.floor(observed.length / 2);
  const median =
    observed.length % 2 === 1
      ? observed[middle]
      : Math.trunc((observed[middle - 1] + observed[middle]) / 2);
  return {
    status: "observed",
    sample_count: observed.length,
    median,
    min: observed[0],
    max: observed[observed.length - 1],
  };
}

function aggregateObservations(observations) {
  const fields = [
    "workflow_start_delay_ms",
    "job_execution_ms",
    "critical_path_ms",
    "aggregate_runner_seconds",
  ];
  return Object.fromEntries(fields.map((field) => [field, aggregateMetric(observations.map((row) => row[field]))]));
}

function ensureFields(object, allowed, label) {
  if (!object || typeof object !== "object" || Array.isArray(object)) throw new Error(`${label} must be an object`);
  for (const key of Object.keys(object)) {
    if (FORBIDDEN_FIELD.test(key) || !allowed.has(key)) throw new Error(`${label} contains a forbidden or unknown field`);
  }
}

function validateMetric(metric, label) {
  ensureFields(metric, METRIC_FIELDS, label);
  if (!Number.isInteger(metric.sample_count) || metric.sample_count < 0) throw new Error(`${label} has invalid sample_count`);
  if (metric.status === "observed") {
    if (metric.sample_count < 1 || ![metric.median, metric.min, metric.max].every(Number.isInteger)) {
      throw new Error(`${label} has invalid observed values`);
    }
    if (metric.min > metric.median || metric.median > metric.max) throw new Error(`${label} has invalid range`);
  } else if (metric.status === "not_measured") {
    if (!NOT_MEASURED_REASONS.has(metric.reason)) throw new Error(`${label} has invalid not_measured reason`);
  } else {
    throw new Error(`${label} has invalid status`);
  }
}

function validateEvidenceObject(evidence) {
  ensureFields(evidence, TOP_LEVEL_FIELDS, "evidence");
  if (evidence.schema_version !== EVIDENCE_SCHEMA_VERSION) throw new Error("unsupported evidence schema_version");
  if (!/^[0-9a-f]{40}$/.test(evidence.repository_sha || "")) throw new Error("invalid repository_sha");
  if (parseTimestamp(evidence.captured_at) === null) throw new Error("invalid captured_at");
  if (evidence.historical_provenance !== "SEED-007 is historical context only") {
    throw new Error("invalid historical_provenance");
  }
  if (!Array.isArray(evidence.source_commands) || !evidence.source_commands.every((item) => typeof item === "string" && item.length > 0)) {
    throw new Error("invalid source_commands");
  }
  if (!Array.isArray(evidence.cohorts) || evidence.cohorts.length === 0) throw new Error("invalid cohorts");
  const names = evidence.cohorts.map((cohort) => cohort.name);
  if (new Set(names).size !== names.length || [...names].sort().join("\0") !== names.join("\0")) {
    throw new Error("cohorts must be unique and sorted");
  }
  for (const cohort of evidence.cohorts) {
    ensureFields(cohort, COHORT_FIELDS, "cohort");
    if (typeof cohort.name !== "string" || typeof cohort.criteria !== "string") throw new Error("invalid cohort identity");
    if (!Number.isInteger(cohort.sample_count) || cohort.sample_count < 0) throw new Error("invalid cohort sample_count");
    if (!Array.isArray(cohort.observations) || cohort.observations.length !== cohort.sample_count) {
      throw new Error("cohort sample_count mismatch");
    }
    if (cohort.status === "not_measured") {
      if (cohort.sample_count !== 0 || !NOT_MEASURED_REASONS.has(cohort.reason)) throw new Error("invalid unavailable cohort");
    } else if (cohort.status !== "observed" || cohort.sample_count === 0 || Object.hasOwn(cohort, "reason")) {
      throw new Error("invalid observed cohort");
    }
    ensureFields(cohort.aggregates, AGGREGATE_FIELDS, "aggregates");
    for (const [name, metric] of Object.entries(cohort.aggregates)) validateMetric(metric, `aggregate ${name}`);
    for (const observation of cohort.observations) {
      ensureFields(observation, OBSERVATION_FIELDS, "observation");
      if (observation.repository_sha !== evidence.repository_sha) throw new Error("observation repository_sha mismatch");
      if (!Number.isInteger(observation.run_id) || observation.run_id < 1) throw new Error("invalid run_id");
      if (!Number.isInteger(observation.attempt) || observation.attempt < 1) throw new Error("invalid attempt");
      if (observation.job_queue_time !== NOT_EXPOSED) throw new Error("job_queue_time must be not_exposed");
      ensureFields(observation.cache, CACHE_FIELDS, "cache");
      if (observation.cache.status !== "not_measured" || observation.cache.reason !== "cache_outcome_unavailable") {
        throw new Error("invalid cache observation");
      }
    }
  }
  return evidence;
}

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch (_error) {
    throw new Error("could not read valid JSON input");
  }
}

function writeCanonical(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, { flag: "w" });
}

function sha256Bytes(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function gitBlob(ref, file) {
  const result = spawnSync("git", ["show", `${ref}:${file}`], { encoding: null });
  if (result.error || result.status !== 0) throw new Error(`could not read ${file} at the bound source`);
  return result.stdout;
}

const REMOTE_SOURCE_FIELDS = new Set([
  "schema_version",
  "repository_sha",
  "default_branch",
  "workflow_digests",
  "verified_at",
  "source_command",
]);
const REMOTE_WORKFLOW_FILES = [
  ".github/workflows/cancel-obsolete-crosswake-ci.yml",
  ".github/workflows/crosswake-ci.yml",
];

function validateRemoteSource(source, compareLocal = true) {
  ensureFields(source, REMOTE_SOURCE_FIELDS, "remote-default source");
  if (source.schema_version !== 1 || !/^[0-9a-f]{40}$/.test(source.repository_sha || "")) {
    throw new Error("invalid remote-default source identity");
  }
  if (!/^[A-Za-z0-9._/-]+$/.test(source.default_branch || "") || parseTimestamp(source.verified_at) === null) {
    throw new Error("invalid remote-default source branch or timestamp");
  }
  if (typeof source.source_command !== "string" || !source.source_command.startsWith("gh api repos/")) {
    throw new Error("invalid remote-default source command");
  }
  if (!source.workflow_digests || typeof source.workflow_digests !== "object" || Array.isArray(source.workflow_digests)) {
    throw new Error("invalid workflow digests");
  }
  const names = Object.keys(source.workflow_digests).sort();
  if (names.join("\0") !== REMOTE_WORKFLOW_FILES.join("\0")) throw new Error("remote workflow set is not exact");
  for (const file of names) {
    const value = source.workflow_digests[file];
    if (!/^[0-9a-f]{64}$/.test(value || "")) throw new Error("invalid workflow digest");
    if (compareLocal && sha256Bytes(fs.readFileSync(file)) !== value) {
      throw new Error(`local completed workflow differs from bound source: ${file}`);
    }
  }
  return source;
}

function verifyRemoteDefaultSource(args) {
  const sourcePath = option(args, "--source");
  if (sourcePath) {
    validateRemoteSource(readJson(sourcePath));
    process.stdout.write("remote-default source: valid\n");
    return;
  }
  const expectedSha = option(args, "--sha");
  const output = option(args, "--output");
  if (!expectedSha || !output) fail("verify-remote-default-source requires --sha and --output");
  if (!/^[0-9a-f]{40}$/.test(expectedSha)) fail("--sha must be an exact 40-character lowercase SHA");
  const supplied = process.env.PHASE165_REMOTE_DEFAULT_SHA;
  if (supplied !== expectedSha) fail("--sha must equal PHASE165_REMOTE_DEFAULT_SHA exactly");
  const { repository, defaultBranch } = repoIdentity();
  const sourceCommand = `gh api repos/${repository}/git/ref/heads/${defaultBranch}`;
  const remoteSha = gh(["api", `repos/${repository}/git/ref/heads/${defaultBranch}`, "--jq", ".object.sha"], true).trim();
  if (remoteSha !== expectedSha) fail("remote default tip moved from PHASE165_REMOTE_DEFAULT_SHA");
  const fetch = spawnSync("git", ["fetch", "origin", expectedSha], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
  if (fetch.error || fetch.status !== 0) fail("could not fetch the exact remote-default SHA");
  const workflowDigests = {};
  for (const file of REMOTE_WORKFLOW_FILES) {
    const remoteDigest = sha256Bytes(gitBlob(expectedSha, file));
    const localDigest = sha256Bytes(fs.readFileSync(file));
    if (remoteDigest !== localDigest) fail(`remote workflow differs from completed local revision: ${file}`);
    workflowDigests[file] = remoteDigest;
  }
  const source = {
    schema_version: 1,
    repository_sha: expectedSha,
    default_branch: defaultBranch,
    workflow_digests: workflowDigests,
    verified_at: new Date().toISOString(),
    source_command: sourceCommand,
  };
  validateRemoteSource(source);
  writeCanonical(output, source);
  process.stdout.write(`verified immutable remote-default source: ${expectedSha}\n`);
}

const FINAL_SOURCE_FIELDS = new Set([
  "schema_version",
  "repository_sha",
  "default_branch",
  "workflow_digest",
  "manifest_digest",
  "verified_at",
  "source_command",
]);

function validateFinalRemoteSource(source) {
  ensureFields(source, FINAL_SOURCE_FIELDS, "final remote-default source");
  if (source.schema_version !== 1 || !/^[0-9a-f]{40}$/.test(source.repository_sha || "")) {
    throw new Error("invalid final remote-default source identity");
  }
  if (!/^[A-Za-z0-9._/-]+$/.test(source.default_branch || "") || parseTimestamp(source.verified_at) === null) {
    throw new Error("invalid final remote-default source branch or timestamp");
  }
  if (![source.workflow_digest, source.manifest_digest].every((value) => /^[0-9a-f]{64}$/.test(value || ""))) {
    throw new Error("invalid final remote-default blob digest");
  }
  if (typeof source.source_command !== "string" || !source.source_command.startsWith("gh api repos/")) {
    throw new Error("invalid final remote-default source command");
  }
  return source;
}

function runFinalStructureChecks(workflowPath, manifestPath) {
  if (workflowPath !== ".github/workflows/crosswake-ci.yml" || manifestPath !== "script/ci_leaf_manifest.json") {
    throw new Error("final source verification requires the canonical workflow and manifest paths");
  }
  const manifest = readJson(manifestPath);
  if (!Array.isArray(manifest.legacy_compatibility_contexts) || manifest.legacy_compatibility_contexts.length !== 0) {
    throw new Error("legacy compatibility manifest authority survives in final source");
  }
  const proofIds = new Set((manifest.proof_leaves || []).map((leaf) => leaf.leaf_id));
  const controlIds = new Set((manifest.required_control_nodes || []).map((node) => node.node_id));
  if (!proofIds.has("brand-structural") || proofIds.has("brand-visual") || controlIds.has("brand-visual")) {
    throw new Error("final brand authority is not exact");
  }
  const workflowText = fs.readFileSync(workflowPath, "utf8");
  if (!workflowText.includes("brand-visual") || /\n\s+compat-[^:]+:/m.test(workflowText)) {
    throw new Error("final workflow compatibility/advisory structure is not exact");
  }
  const checker = spawnSync("python3", ["script/check_ci_leaf_manifest.py", "--self-test"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (checker.error || checker.status !== 0) throw new Error("final workflow/manifest structure validation failed");
  const protection = spawnSync(
    "script/check_required_checks_registered.sh",
    ["--policy", "script/required_check_policy.json", "--state", "target", "--live"],
    { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] },
  );
  if (protection.error || protection.status !== 0) throw new Error("live target branch protection is not exact");
}

function verifyFinalRemoteDefaultSource(args) {
  const sourcePath = option(args, "--source");
  const workflowPath = option(args, "--workflow", ".github/workflows/crosswake-ci.yml");
  const manifestPath = option(args, "--manifest", "script/ci_leaf_manifest.json");
  const source = sourcePath ? validateFinalRemoteSource(readJson(sourcePath)) : null;
  const expectedSha = source ? source.repository_sha : option(args, "--sha");
  const output = option(args, "--output");
  if (!expectedSha || (!sourcePath && !output)) {
    fail("verify-final-remote-default-source requires --source or --sha and --output");
  }
  if (!/^[0-9a-f]{40}$/.test(expectedSha)) fail("final --sha must be an exact 40-character lowercase SHA");
  if (process.env.PHASE165_FINAL_REMOTE_DEFAULT_SHA !== expectedSha) {
    fail("final source SHA must equal PHASE165_FINAL_REMOTE_DEFAULT_SHA exactly");
  }

  const { repository, defaultBranch } = repoIdentity();
  const sourceCommand = `gh api repos/${repository}/git/ref/heads/${defaultBranch}`;
  const remoteSha = gh(["api", `repos/${repository}/git/ref/heads/${defaultBranch}`, "--jq", ".object.sha"], true).trim();
  if (remoteSha !== expectedSha) fail("remote default tip moved from PHASE165_FINAL_REMOTE_DEFAULT_SHA");
  if (source && source.default_branch !== defaultBranch) fail("final source default branch changed");

  const fetch = spawnSync("git", ["fetch", "origin", expectedSha], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"],
  });
  if (fetch.error || fetch.status !== 0) fail("could not fetch the exact final remote-default SHA");
  const workflowDigest = sha256Bytes(gitBlob(expectedSha, workflowPath));
  const manifestDigest = sha256Bytes(gitBlob(expectedSha, manifestPath));
  if (workflowDigest !== sha256Bytes(fs.readFileSync(workflowPath))) fail("final remote workflow differs from local Plan 12 state");
  if (manifestDigest !== sha256Bytes(fs.readFileSync(manifestPath))) fail("final remote manifest differs from local Plan 12 state");
  if (source && (source.workflow_digest !== workflowDigest || source.manifest_digest !== manifestDigest)) {
    fail("final source record digests no longer match the exact remote blobs");
  }
  runFinalStructureChecks(workflowPath, manifestPath);

  if (!sourcePath) {
    const record = validateFinalRemoteSource({
      schema_version: 1,
      repository_sha: expectedSha,
      default_branch: defaultBranch,
      workflow_digest: workflowDigest,
      manifest_digest: manifestDigest,
      verified_at: new Date().toISOString(),
      source_command: sourceCommand,
    });
    writeCanonical(output, record);
  }
  process.stdout.write(`verified final immutable remote-default source: ${expectedSha}\n`);
}

function ghSoft(args) {
  return spawnSync("gh", args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] });
}

function sleepMs(milliseconds) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds);
}

function apiJson(endpoint) {
  return JSON.parse(gh(["api", endpoint], true));
}

function createProbeRef(repository, branch, sha) {
  gh(["api", "--method", "POST", `repos/${repository}/git/refs`, "-f", `ref=refs/heads/${branch}`, "-f", `sha=${sha}`], true);
}

function putProbeFile(repository, branch, file, content, message) {
  let existingSha;
  const existing = ghSoft(["api", `repos/${repository}/contents/${file}?ref=${encodeURIComponent(branch)}`, "--jq", ".sha"]);
  if (existing.status === 0) existingSha = existing.stdout.trim();
  const args = [
    "api", "--method", "PUT", `repos/${repository}/contents/${file}`,
    "-f", `message=${message}`, "-f", `content=${Buffer.from(content).toString("base64")}`, "-f", `branch=${branch}`,
  ];
  if (existingSha) args.push("-f", `sha=${existingSha}`);
  return JSON.parse(gh(args, true)).commit.sha;
}

function openProbePr(defaultBranch, branch, title) {
  gh(["pr", "create", "--base", defaultBranch, "--head", branch, "--title", title, "--body", "Bounded Phase 165 CI observation probe. This PR is closed and its branch deleted automatically."], true);
  return Number(JSON.parse(gh(["pr", "view", branch, "--json", "number"], true)).number);
}

function findRun(repository, branch, sha) {
  const encoded = encodeURIComponent(branch);
  const runs = apiJson(`repos/${repository}/actions/workflows/crosswake-ci.yml/runs?event=pull_request&branch=${encoded}&per_page=50`).workflow_runs || [];
  return runs.find((run) => run.head_sha === sha) || null;
}

function waitForRun(repository, branch, sha, timeoutMs = 10 * 60 * 1000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const run = findRun(repository, branch, sha);
    if (run) return run;
    sleepMs(5000);
  }
  throw new Error("timed out waiting for Crosswake CI request");
}

function readRun(repository, id) {
  return apiJson(`repos/${repository}/actions/runs/${id}`);
}

function waitForRunState(repository, id, predicate, timeoutMs = 55 * 60 * 1000) {
  const deadline = Date.now() + timeoutMs;
  let run;
  while (Date.now() < deadline) {
    run = readRun(repository, id);
    if (predicate(run)) return run;
    sleepMs(10000);
  }
  throw new Error(`timed out waiting for run ${id}`);
}

function runJobs(repository, id) {
  return apiJson(`repos/${repository}/actions/runs/${id}/jobs?filter=all&per_page=100`).jobs || [];
}

function assertProbeJobs(run, jobs, manifest, docsOnly) {
  const byName = new Map(jobs.map((job) => [job.name, job]));
  if (byName.size !== jobs.length) throw new Error("probe emitted duplicate job display names");
  const umbrella = byName.get("Crosswake CI");
  if (!umbrella || umbrella.conclusion !== "success") throw new Error("Crosswake CI umbrella did not succeed");
  const classify = byName.get("classify-change");
  if (!classify || classify.conclusion !== "success") throw new Error("classification control did not succeed");
  const activeProof = [];
  const skippedProof = [];
  for (const leaf of manifest.proof_leaves) {
    const job = byName.get(leaf.display_name);
    if (!job) throw new Error(`missing expected proof leaf: ${leaf.display_name}`);
    if (job.conclusion === "skipped") skippedProof.push(leaf.leaf_id);
    else if (job.conclusion === "success") activeProof.push(leaf.leaf_id);
    else throw new Error(`proof leaf did not close successfully: ${leaf.display_name}`);
  }
  if (docsOnly) {
    if (activeProof.join("\0") !== "documentation-contracts") throw new Error("documentation probe scheduled an unrelated proof leaf");
    if (skippedProof.length !== manifest.proof_leaves.length - 1) throw new Error("documentation probe skip set is incomplete");
  } else if (activeProof.length !== manifest.proof_leaves.length || skippedProof.length !== 0) {
    throw new Error("executable probe did not schedule the complete proof union");
  }
  return { activeProof, skippedProof, umbrella };
}

function validateLiveObservation(value) {
  const allowedTop = new Set(["schema_version", "repository_sha", "captured_at", "source_reference", "umbrella_context", "docs_probe", "full_probe", "cancellation", "cleanup"]);
  ensureFields(value, allowedTop, "live observation");
  if (value.schema_version !== 1 || !/^[0-9a-f]{40}$/.test(value.repository_sha || "") || parseTimestamp(value.captured_at) === null) throw new Error("invalid live observation identity");
  if (value.source_reference !== "remote-default-source.json" || value.umbrella_context !== "Crosswake CI") throw new Error("invalid live observation authority");
  const probeFields = new Set(["pr_number", "run_id", "classification", "umbrella_result", "active_proof_leaves", "skipped_proof_leaves", "observed_job_count"]);
  for (const name of ["docs_probe", "full_probe"]) {
    const probe = value[name];
    ensureFields(probe, probeFields, name);
    if (!Number.isInteger(probe.pr_number) || !Number.isInteger(probe.run_id) || probe.umbrella_result !== "success") throw new Error(`invalid ${name} result`);
    if (!Array.isArray(probe.active_proof_leaves) || !Array.isArray(probe.skipped_proof_leaves)) throw new Error(`invalid ${name} leaves`);
  }
  const cancellationFields = new Set(["pr_number", "lower_run_id", "newer_run_id", "lower_run_cancelled", "newer_run_authoritative", "same_pr_workflow", "requested_controller_observed", "runner_consumption_observed", "bounded_controller_action"]);
  ensureFields(value.cancellation, cancellationFields, "cancellation");
  const c = value.cancellation;
  if (!(c.lower_run_id < c.newer_run_id) || c.lower_run_cancelled !== true || c.newer_run_authoritative !== true || c.same_pr_workflow !== true || c.requested_controller_observed !== true || c.runner_consumption_observed !== true || c.bounded_controller_action !== true) throw new Error("monotonic cancellation evidence is incomplete");
  ensureFields(value.cleanup, new Set(["pull_requests_closed", "branches_deleted"]), "cleanup");
  if (value.cleanup.pull_requests_closed !== true || value.cleanup.branches_deleted !== true) throw new Error("probe cleanup was not proven");
  return value;
}

function controllerObserved(repository, since, lowerId) {
  const runs = apiJson(`repos/${repository}/actions/workflows/cancel-obsolete-crosswake-ci.yml/runs?event=workflow_run&per_page=50`).workflow_runs || [];
  return runs.some((run) => Date.parse(run.created_at) >= Date.parse(since) && ["queued", "in_progress", "completed"].includes(run.status) && run.id > 0 && lowerId > 0);
}

function probePhase165(args) {
  const sourcePath = option(args, "--source");
  const output = option(args, "--output");
  const assertCleanup = args.includes("--assert-cleanup");
  if (!sourcePath || !output) fail("probe-phase165 requires --source and --output");
  const source = validateRemoteSource(readJson(sourcePath));
  const { repository, defaultBranch } = repoIdentity();
  if (defaultBranch !== source.default_branch) fail("default branch differs from bound source");
  const remoteTip = gh(["api", `repos/${repository}/git/ref/heads/${defaultBranch}`, "--jq", ".object.sha"], true).trim();
  if (remoteTip !== source.repository_sha) fail("remote default tip moved after source verification");
  const manifest = readJson("script/ci_leaf_manifest.json");
  const nonce = `${Date.now()}-${process.pid}`;
  const docsBranch = `phase165-probe-docs-${nonce}`;
  const fullBranch = `phase165-probe-full-${nonce}`;
  const opened = [];
  const branches = [];
  let result;
  let cleanupOk = false;
  try {
    createProbeRef(repository, docsBranch, source.repository_sha); branches.push(docsBranch);
    const docsSha = putProbeFile(repository, docsBranch, `.planning/phase165-live-probe-${nonce}.md`, "# Phase 165 live documentation probe\n\nNon-sensitive bounded classifier fixture.\n", "test: add bounded Phase 165 docs probe");
    const docsPr = openProbePr(defaultBranch, docsBranch, "Phase 165 bounded documentation probe"); opened.push(docsPr);
    let docsRun = waitForRun(repository, docsBranch, docsSha);
    docsRun = waitForRunState(repository, docsRun.id, (run) => run.status === "completed");
    const docsJobs = runJobs(repository, docsRun.id);
    const docs = assertProbeJobs(docsRun, docsJobs, manifest, true);

    createProbeRef(repository, fullBranch, source.repository_sha); branches.push(fullBranch);
    const fullFile = `test/fixtures/ci/phase165-live-probe-${nonce}.txt`;
    const fullSha = putProbeFile(repository, fullBranch, fullFile, "phase165 executable probe 1\n", "test: add bounded Phase 165 executable probe");
    const fullPr = openProbePr(defaultBranch, fullBranch, "Phase 165 bounded executable probe"); opened.push(fullPr);
    let fullRun = waitForRun(repository, fullBranch, fullSha);
    fullRun = waitForRunState(repository, fullRun.id, (run) => run.status === "completed");
    const fullJobs = runJobs(repository, fullRun.id);
    const full = assertProbeJobs(fullRun, fullJobs, manifest, false);

    const lowerSha = putProbeFile(repository, fullBranch, fullFile, "phase165 executable probe 2\n", "test: request lower Phase 165 cancellation probe");
    let lowerRun = waitForRun(repository, fullBranch, lowerSha);
    lowerRun = waitForRunState(repository, lowerRun.id, (run) => run.status === "in_progress" || run.status === "completed", 15 * 60 * 1000);
    if (lowerRun.status === "completed") throw new Error("lower cancellation probe completed before inversion could be observed");
    const lowerJobsAtUpdate = runJobs(repository, lowerRun.id);
    const runnerConsumptionObserved = lowerJobsAtUpdate.some((job) => job.status === "in_progress" || job.status === "completed");
    if (!runnerConsumptionObserved) throw new Error("lower run had not consumed a runner before newer request");
    const newerSha = putProbeFile(repository, fullBranch, fullFile, "phase165 executable probe 3\n", "test: request newer Phase 165 authoritative probe");
    let newerRun = waitForRun(repository, fullBranch, newerSha);
    const lowerFinal = waitForRunState(repository, lowerRun.id, (run) => run.status === "completed", 15 * 60 * 1000);
    if (lowerFinal.conclusion !== "cancelled") throw new Error("strict lower run was not cancelled");
    newerRun = waitForRunState(repository, newerRun.id, (run) => run.status === "in_progress" || run.status === "completed", 15 * 60 * 1000);
    if (newerRun.conclusion === "cancelled") throw new Error("newer authoritative run was cancelled");
    const controller = controllerObserved(repository, lowerRun.created_at, lowerRun.id);
    if (!controller) throw new Error("requested-event controller timing was not observed");

    result = {
      schema_version: 1,
      repository_sha: source.repository_sha,
      captured_at: new Date().toISOString(),
      source_reference: path.basename(sourcePath),
      umbrella_context: "Crosswake CI",
      docs_probe: { pr_number: docsPr, run_id: docsRun.id, classification: "documentation_only", umbrella_result: docs.umbrella.conclusion, active_proof_leaves: docs.activeProof, skipped_proof_leaves: docs.skippedProof, observed_job_count: docsJobs.length },
      full_probe: { pr_number: fullPr, run_id: fullRun.id, classification: "full_proof", umbrella_result: full.umbrella.conclusion, active_proof_leaves: full.activeProof, skipped_proof_leaves: full.skippedProof, observed_job_count: fullJobs.length },
      cancellation: { pr_number: fullPr, lower_run_id: lowerRun.id, newer_run_id: newerRun.id, lower_run_cancelled: true, newer_run_authoritative: true, same_pr_workflow: lowerRun.workflow_id === newerRun.workflow_id, requested_controller_observed: true, runner_consumption_observed: true, bounded_controller_action: true },
      cleanup: { pull_requests_closed: false, branches_deleted: false },
    };
  } finally {
    let prsClosed = true;
    for (const number of opened) if (ghSoft(["pr", "close", String(number), "--delete-branch"]).status !== 0) prsClosed = false;
    let branchesDeleted = true;
    for (const branch of branches) {
      const check = ghSoft(["api", `repos/${repository}/git/ref/heads/${branch}`]);
      if (check.status === 0 && ghSoft(["api", "--method", "DELETE", `repos/${repository}/git/refs/heads/${branch}`]).status !== 0) branchesDeleted = false;
      if (ghSoft(["api", `repos/${repository}/git/ref/heads/${branch}`]).status === 0) branchesDeleted = false;
    }
    cleanupOk = prsClosed && branchesDeleted;
    if (result) result.cleanup = { pull_requests_closed: prsClosed, branches_deleted: branchesDeleted };
  }
  if (assertCleanup && !cleanupOk) fail("probe cleanup could not be proven");
  validateLiveObservation(result);
  writeCanonical(output, result);
  process.stdout.write("Phase 165 live probes passed and cleanup was verified\n");
}

function repoIdentity() {
  const repository = JSON.parse(gh(["repo", "view", "--json", "nameWithOwner,defaultBranchRef"], true));
  return { repository: repository.nameWithOwner, defaultBranch: repository.defaultBranchRef.name };
}

function captureRequiredContextSnapshot(args) {
  const output = args[0];
  if (!output) fail("capture-required-context-snapshot requires an output path");
  const { repository, defaultBranch } = repoIdentity();
  const sha = gh(["api", `repos/${repository}/commits/${defaultBranch}`, "--jq", ".sha"], true).trim();
  const protection = JSON.parse(
    gh(["api", `repos/${repository}/branches/${defaultBranch}/protection/required_status_checks`], true),
  );
  const requiredContexts = [...new Set(protection.contexts || [])].sort();
  const authority = {
    schema_version: 1,
    repository_sha: sha,
    default_branch: defaultBranch,
    strict: protection.strict === true,
    required_contexts: requiredContexts,
  };
  const snapshot = {
    ...authority,
    captured_at: new Date().toISOString(),
    source_command: `gh api repos/${repository}/branches/${defaultBranch}/protection/required_status_checks`,
    source_digest: digest(authority),
  };
  writeCanonical(output, snapshot);
  process.stdout.write(`captured strict required-context snapshot: ${requiredContexts.length} contexts\n`);
}

const SNAPSHOT_FIELDS = new Set([
  "schema_version",
  "repository_sha",
  "default_branch",
  "strict",
  "required_contexts",
  "captured_at",
  "source_command",
  "source_digest",
]);

function validateSnapshot(snapshot) {
  ensureFields(snapshot, SNAPSHOT_FIELDS, "required-context snapshot");
  if (snapshot.schema_version !== 1 || !/^[0-9a-f]{40}$/.test(snapshot.repository_sha || "")) {
    throw new Error("invalid required-context snapshot identity");
  }
  if (snapshot.strict !== true || parseTimestamp(snapshot.captured_at) === null) throw new Error("invalid required-context strictness");
  if (!Array.isArray(snapshot.required_contexts) || snapshot.required_contexts.length === 0) {
    throw new Error("invalid required_contexts");
  }
  const sorted = [...new Set(snapshot.required_contexts)].sort();
  if (sorted.length !== snapshot.required_contexts.length || sorted.join("\0") !== snapshot.required_contexts.join("\0")) {
    throw new Error("required_contexts must be unique and sorted");
  }
  const authority = {
    schema_version: snapshot.schema_version,
    repository_sha: snapshot.repository_sha,
    default_branch: snapshot.default_branch,
    strict: snapshot.strict,
    required_contexts: snapshot.required_contexts,
  };
  if (snapshot.source_digest !== digest(authority)) throw new Error("required-context source_digest mismatch");
  return authority;
}

function verifyRequiredContextSnapshot(args) {
  if (!args[0]) fail("verify-required-context-snapshot requires a snapshot path");
  const snapshot = readJson(args[0]);
  const expected = validateSnapshot(snapshot);
  if (args.includes("--live")) {
    const { repository, defaultBranch } = repoIdentity();
    const sha = gh(["api", `repos/${repository}/commits/${defaultBranch}`, "--jq", ".sha"], true).trim();
    const protection = JSON.parse(
      gh(["api", `repos/${repository}/branches/${defaultBranch}/protection/required_status_checks`], true),
    );
    const actual = {
      schema_version: 1,
      repository_sha: sha,
      default_branch: defaultBranch,
      strict: protection.strict === true,
      required_contexts: [...new Set(protection.contexts || [])].sort(),
    };
    if (canonicalJson(actual) !== canonicalJson(expected)) throw new Error("live required-context authority drifted from snapshot");
  }
  process.stdout.write("required-context snapshot: valid\n");
}

function captureEvidence(args) {
  if (args.includes("--source")) return captureMatchedFinalEvidence(args);
  const output = args[0];
  if (!output) fail("capture-evidence requires an output path");
  const { repository, defaultBranch } = repoIdentity();
  const sha = gh(["api", `repos/${repository}/commits/${defaultBranch}`, "--jq", ".sha"], true).trim();
  const runsCommand = `gh api repos/${repository}/actions/runs?branch=${defaultBranch}&per_page=20`;
  const runs = JSON.parse(gh(["api", `repos/${repository}/actions/runs?branch=${defaultBranch}&per_page=20`], true)).workflow_runs || [];
  const selected = runs
    .filter((run) => ["push", "schedule", "workflow_dispatch"].includes(run.event) && run.head_sha === sha)
    .slice(0, 10);
  const observations = selected.map((run) => {
    const jobsCommand = `repos/${repository}/actions/runs/${run.id}/jobs?per_page=100`;
    const jobs = JSON.parse(gh(["api", jobsCommand], true)).jobs || [];
    const durations = jobs.map((job) => durationMetric(job.started_at, job.completed_at));
    const integerDurations = durations.filter(Number.isInteger);
    const runnerClasses = [...new Set(jobs.map((job) => runnerClass(job.labels)))].sort();
    const runStartDelay = durationMetric(run.created_at, run.run_started_at);
    const criticalPath = durationMetric(run.run_started_at, run.updated_at);
    return {
      repository_sha: sha,
      run_id: run.id,
      attempt: run.run_attempt || 1,
      event: run.event,
      workflow_name: run.name || run.path || "unknown_workflow",
      runner_class: runnerClasses.length === 1 ? runnerClasses[0] : runnerClasses.length > 1 ? "mixed" : "not_measured",
      created_at: run.created_at,
      run_started_at: run.run_started_at,
      completed_at: run.updated_at,
      outcome: run.conclusion || run.status || "unknown",
      job_count: jobs.length,
      check_count: jobs.length,
      workflow_start_delay_ms: runStartDelay,
      job_execution_ms: integerDurations.length ? integerDurations.reduce((sum, value) => sum + value, 0) : { status: "not_measured", reason: "cohort_unavailable" },
      critical_path_ms: criticalPath,
      aggregate_runner_seconds: integerDurations.length ? Math.trunc(integerDurations.reduce((sum, value) => sum + value, 0) / 1000) : { status: "not_measured", reason: "cohort_unavailable" },
      job_queue_time: NOT_EXPOSED,
      cache: { status: "not_measured", reason: "cache_outcome_unavailable" },
    };
  }).sort((left, right) => left.run_id - right.run_id);

  function unavailable(name, criteria) {
    const empty = [];
    return {
      name,
      criteria,
      sample_count: 0,
      status: "not_measured",
      reason: "cohort_unavailable",
      observations: empty,
      aggregates: aggregateObservations(empty),
    };
  }

  const cohorts = [
    unavailable("documentation_only_pr", "pull_request run at the captured source SHA whose validated diff is documentation_only"),
    unavailable("full_proof_executable_pr", "pull_request run at the captured source SHA whose validated diff includes executable content"),
    {
      name: "main_bound_automation",
      criteria: "push, schedule, or workflow_dispatch run on the captured default-branch source SHA before Phase 165 topology mutation",
      sample_count: observations.length,
      status: observations.length ? "observed" : "not_measured",
      ...(observations.length ? {} : { reason: "cohort_unavailable" }),
      observations,
      aggregates: aggregateObservations(observations),
    },
  ];
  const evidence = {
    schema_version: EVIDENCE_SCHEMA_VERSION,
    repository_sha: sha,
    captured_at: new Date().toISOString(),
    historical_provenance: "SEED-007 is historical context only",
    source_commands: [runsCommand, `gh api repos/${repository}/actions/runs/{run_id}/jobs?per_page=100`],
    cohorts,
  };
  validateEvidenceObject(evidence);
  writeCanonical(output, evidence);
  process.stdout.write(`captured sanitized evidence: ${observations.length} observations\n`);
}

function sanitizedRunObservation(repository, sha, run) {
  const jobs = apiJson(`repos/${repository}/actions/runs/${run.id}/jobs?per_page=100`).jobs || [];
  const durations = jobs.map((job) => durationMetric(job.started_at, job.completed_at));
  const integerDurations = durations.filter(Number.isInteger);
  const runnerClasses = [...new Set(jobs.map((job) => runnerClass(job.labels)))].sort();
  return {
    repository_sha: sha,
    run_id: run.id,
    attempt: run.run_attempt || 1,
    event: run.event,
    workflow_name: run.name || run.path || "unknown_workflow",
    runner_class: runnerClasses.length === 1 ? runnerClasses[0] : runnerClasses.length > 1 ? "mixed" : "not_measured",
    created_at: run.created_at,
    run_started_at: run.run_started_at,
    completed_at: run.updated_at,
    outcome: run.conclusion || run.status || "unknown",
    job_count: jobs.length,
    check_count: jobs.length,
    workflow_start_delay_ms: durationMetric(run.created_at, run.run_started_at),
    job_execution_ms: integerDurations.length
      ? integerDurations.reduce((sum, value) => sum + value, 0)
      : { status: "not_measured", reason: "cohort_unavailable" },
    critical_path_ms: durationMetric(run.run_started_at, run.updated_at),
    aggregate_runner_seconds: integerDurations.length
      ? Math.trunc(integerDurations.reduce((sum, value) => sum + value, 0) / 1000)
      : { status: "not_measured", reason: "cohort_unavailable" },
    job_queue_time: NOT_EXPOSED,
    cache: { status: "not_measured", reason: "cache_outcome_unavailable" },
  };
}

function unavailableCohort(name, criteria) {
  return {
    name,
    criteria,
    sample_count: 0,
    status: "not_measured",
    reason: "cohort_unavailable",
    observations: [],
    aggregates: aggregateObservations([]),
  };
}

function captureMatchedFinalEvidence(args) {
  const sourcePath = option(args, "--source");
  const cohortsMode = option(args, "--cohorts");
  const output = option(args, "--output");
  if (!sourcePath || cohortsMode !== "matched" || !output) {
    fail("final capture-evidence requires --source, --cohorts matched, and --output");
  }
  verifyFinalRemoteDefaultSource(["--source", sourcePath]);
  const source = validateFinalRemoteSource(readJson(sourcePath));
  const { repository, defaultBranch } = repoIdentity();
  if (source.default_branch !== defaultBranch) fail("final evidence default branch differs from bound source");
  const runsCommand = `gh api repos/${repository}/actions/runs?branch=${defaultBranch}&per_page=20`;
  const runs = apiJson(`repos/${repository}/actions/runs?branch=${defaultBranch}&per_page=20`).workflow_runs || [];
  const observations = runs
    .filter((run) => ["push", "schedule", "workflow_dispatch"].includes(run.event) && run.head_sha === source.repository_sha)
    .slice(0, 10)
    .map((run) => sanitizedRunObservation(repository, source.repository_sha, run))
    .sort((left, right) => left.run_id - right.run_id);
  const mainCriteria =
    "push, schedule, or workflow_dispatch run on the captured default-branch source SHA after Phase 165 topology mutation";
  const cohorts = [
    unavailableCohort(
      "documentation_only_pr",
      "pull_request run at the captured source SHA whose validated diff is documentation_only",
    ),
    unavailableCohort(
      "full_proof_executable_pr",
      "pull_request run at the captured source SHA whose validated diff includes executable content",
    ),
    observations.length
      ? {
          name: "main_bound_automation",
          criteria: mainCriteria,
          sample_count: observations.length,
          status: "observed",
          observations,
          aggregates: aggregateObservations(observations),
        }
      : unavailableCohort("main_bound_automation", mainCriteria),
  ];
  const evidence = {
    schema_version: EVIDENCE_SCHEMA_VERSION,
    repository_sha: source.repository_sha,
    captured_at: new Date().toISOString(),
    historical_provenance: "SEED-007 is historical context only",
    source_commands: [runsCommand, `gh api repos/${repository}/actions/runs/{run_id}/jobs?per_page=100`],
    cohorts,
  };
  validateEvidenceObject(evidence);
  writeCanonical(output, evidence);
  process.stdout.write(`captured matched final evidence: ${observations.length} main-bound observations\n`);
}

function validateEvidence(args) {
  if (!args[0]) fail("validate-evidence requires an evidence path");
  const value = readJson(args[0]);
  if (Object.hasOwn(value, "docs_probe")) validateLiveObservation(value);
  else validateEvidenceObject(value);
  process.stdout.write("evidence: valid\n");
}

function displayMetric(metric, unit) {
  if (metric.status === "not_measured") return `not measured (${metric.reason})`;
  return `observed; sample count ${metric.sample_count}; median ${metric.median} ${unit}; range ${metric.min}-${metric.max} ${unit}`;
}

function renderEvidenceText(evidence, title = "Phase 165 pre-change CI evidence") {
  validateEvidenceObject(evidence);
  const lines = [
    `# ${title}`,
    "",
    `Captured source: \`${evidence.repository_sha}\``,
    "",
    `${evidence.historical_provenance}. Timing is descriptive and is not a merge threshold.`,
    "",
    "Exact per-job queue time: **not exposed** by the retained API fields.",
    "",
    "## Source commands",
    "",
    ...evidence.source_commands.map((command) => `- Source command: \`${command}\``),
  ];
  for (const cohort of evidence.cohorts) {
    lines.push("", `## ${cohort.name}`, "", `Criteria: ${cohort.criteria}`, "", `Sample count: ${cohort.sample_count}`);
    if (cohort.status === "not_measured") {
      lines.push("", `Status: not measured (${cohort.reason}).`);
    }
    lines.push(
      "",
      "| Metric | Result |",
      "| --- | --- |",
      `| Workflow start delay | ${displayMetric(cohort.aggregates.workflow_start_delay_ms, "ms")} |`,
      `| Job execution | ${displayMetric(cohort.aggregates.job_execution_ms, "ms")} |`,
      `| Critical path | ${displayMetric(cohort.aggregates.critical_path_ms, "ms")} |`,
      `| Aggregate runner time | ${displayMetric(cohort.aggregates.aggregate_runner_seconds, "s")} |`,
    );
  }
  return `${lines.join("\n")}\n`;
}

function renderEvidence(args) {
  if (!args[0]) fail("render-evidence requires an evidence path");
  const output = args[1] || args[0].replace(/\.json$/i, ".md");
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, renderEvidenceText(readJson(args[0])));
  process.stdout.write(`rendered evidence: ${output}\n`);
}

function compareEvidence(args) {
  if (!args[0] || !args[1]) fail("compare-evidence requires before and after evidence paths");
  const before = validateEvidenceObject(readJson(args[0]));
  const after = validateEvidenceObject(readJson(args[1]));
  const output = option(args, "--output", args[2] && !args[2].startsWith("--") ? args[2] : undefined);
  const lines = [
    "# Phase 165 descriptive CI comparison",
    "",
    `Before source: \`${before.repository_sha}\``,
    `After source: \`${after.repository_sha}\``,
    "",
    "Results are descriptive. Unmatched cohorts remain not measured; exact per-job queue time is not exposed.",
    "No causal conclusion is supported by these observations, and no timing value is a merge threshold.",
    "",
    "## Source commands",
    "",
    ...before.source_commands.map((command) => `- Before source command: \`${command}\``),
    ...after.source_commands.map((command) => `- After source command: \`${command}\``),
  ];
  const afterByName = new Map(after.cohorts.map((cohort) => [cohort.name, cohort]));
  for (const prior of before.cohorts) {
    const current = afterByName.get(prior.name);
    if (!current) throw new Error(`after evidence omits cohort ${prior.name}`);
    const criteriaMatch = prior.criteria === current.criteria;
    const comparisonStatus = !criteriaMatch
      ? "not measured (`not_measured`: criteria_mismatch)"
      : prior.status === "observed" && current.status === "observed"
        ? "observed matched cohorts"
        : "not measured (`not_measured`: cohort_unavailable)";
    const countMetric = (cohort, field) => aggregateMetric(cohort.observations.map((row) => row[field]));
    const workflows = (cohort) => [...new Set(cohort.observations.map((row) => row.workflow_name))].sort();
    const runners = (cohort) => [...new Set(cohort.observations.map((row) => row.runner_class))].sort();
    const cacheSummary = (cohort) => {
      if (cohort.observations.length === 0) return "not measured (cohort_unavailable)";
      const outcomes = [...new Set(cohort.observations.map((row) => `${row.cache.status} (${row.cache.reason})`))].sort();
      return outcomes.join(", ");
    };
    lines.push(
      "",
      `## ${prior.name}`,
      "",
      `Comparison status: **${comparisonStatus}**.`,
      "",
      `Before criteria: ${prior.criteria}`,
      "",
      `After criteria: ${current.criteria}`,
      "",
      `Sample count: before ${prior.sample_count}; after ${current.sample_count}.`,
      "",
      "### Workflow/job/check counts",
      "",
      `- Before workflows: ${workflows(prior).length} (${workflows(prior).join(", ") || "not measured"})`,
      `- After workflows: ${workflows(current).length} (${workflows(current).join(", ") || "not measured"})`,
      `- Before jobs: ${displayMetric(countMetric(prior, "job_count"), "jobs")}`,
      `- After jobs: ${displayMetric(countMetric(current, "job_count"), "jobs")}`,
      `- Before checks: ${displayMetric(countMetric(prior, "check_count"), "checks")}`,
      `- After checks: ${displayMetric(countMetric(current, "check_count"), "checks")}`,
      "",
      "### Runner classes",
      "",
      `- Before: ${runners(prior).join(", ") || "not measured (cohort_unavailable)"}`,
      `- After: ${runners(current).join(", ") || "not measured (cohort_unavailable)"}`,
      "",
      "### Timing",
      "",
      "| Metric | Before | After |",
      "| --- | --- | --- |",
      `| Workflow delay | ${displayMetric(prior.aggregates.workflow_start_delay_ms, "ms")} | ${displayMetric(current.aggregates.workflow_start_delay_ms, "ms")} |`,
      `| Job execution | ${displayMetric(prior.aggregates.job_execution_ms, "ms")} | ${displayMetric(current.aggregates.job_execution_ms, "ms")} |`,
      `| Critical path | ${displayMetric(prior.aggregates.critical_path_ms, "ms")} | ${displayMetric(current.aggregates.critical_path_ms, "ms")} |`,
      `| Runner time | ${displayMetric(prior.aggregates.aggregate_runner_seconds, "s")} | ${displayMetric(current.aggregates.aggregate_runner_seconds, "s")} |`,
      "",
      "### Cache outcomes",
      "",
      `- Before: ${cacheSummary(prior)}`,
      `- After: ${cacheSummary(current)}`,
    );
  }
  const text = `${lines.join("\n")}\n`;
  if (output) {
    fs.mkdirSync(path.dirname(output), { recursive: true });
    fs.writeFileSync(output, text);
  } else process.stdout.write(text);
}

function testEvidence() {
  const equal = durationMetric("2026-01-01T00:00:00Z", "2026-01-01T00:00:00Z");
  if (equal !== 0) throw new Error("equal timestamps must produce zero milliseconds");
  if (durationMetric("2026-01-02T00:00:00Z", "2026-01-01T00:00:00Z").reason !== "timestamp_reversed") {
    throw new Error("reversed timestamps must be not_measured");
  }
  if (durationMetric(null, "2026-01-01T00:00:00Z").reason !== "timestamp_incomplete") {
    throw new Error("incomplete timestamps must be not_measured");
  }
  const singleton = aggregateMetric([7]);
  if (singleton.sample_count !== 1 || singleton.median !== 7 || singleton.min !== 7 || singleton.max !== 7) {
    throw new Error("singleton aggregate is invalid");
  }
  const ordered = canonicalJson(aggregateMetric([9, 1, 5]));
  const reordered = canonicalJson(aggregateMetric([5, 9, 1]));
  if (ordered !== reordered) throw new Error("aggregate ordering is not deterministic");
  for (const key of ["unknown", "actor", "message", "raw_payload", "log_text", "runner_identity", "cache_key", "token", "account_identifier", "device_identifier", "revealing_link"]) {
    let rejected = false;
    try {
      ensureFields({ [key]: "SENSITIVE-FIXTURE-VALUE" }, TOP_LEVEL_FIELDS, "fixture");
    } catch (error) {
      rejected = true;
      if (error.message.includes("SENSITIVE-FIXTURE-VALUE")) throw new Error("rejection echoed a field value");
    }
    if (!rejected) throw new Error("forbidden evidence fixture was accepted");
  }
  const authority = {
    schema_version: 1,
    repository_sha: "a".repeat(40),
    default_branch: "main",
    strict: true,
    required_contexts: ["alpha", "beta"],
  };
  const snapshot = {
    ...authority,
    captured_at: "2026-01-01T00:00:00Z",
    source_command: "gh api fixture",
    source_digest: digest(authority),
  };
  validateSnapshot(snapshot);
  for (const changed of [
    { ...snapshot, strict: false },
    { ...snapshot, repository_sha: "b".repeat(40) },
    { ...snapshot, required_contexts: ["beta", "alpha"] },
    { ...snapshot, required_contexts: ["alpha", "gamma"] },
  ]) {
    let rejected = false;
    try {
      validateSnapshot(changed);
    } catch (_error) {
      rejected = true;
    }
    if (!rejected) throw new Error("required-context negative fixture was accepted");
  }
  const finalSource = {
    schema_version: 1,
    repository_sha: "a".repeat(40),
    default_branch: "main",
    workflow_digest: "b".repeat(64),
    manifest_digest: "c".repeat(64),
    verified_at: "2026-01-01T00:00:00Z",
    source_command: "gh api repos/example/project/git/ref/heads/main",
  };
  validateFinalRemoteSource(finalSource);
  for (const changed of [
    { ...finalSource, repository_sha: "moving-branch" },
    { ...finalSource, workflow_digest: "short" },
    { ...finalSource, actor: "SENSITIVE-FIXTURE-VALUE" },
  ]) {
    let rejected = false;
    try {
      validateFinalRemoteSource(changed);
    } catch (error) {
      rejected = true;
      if (error.message.includes("SENSITIVE-FIXTURE-VALUE")) throw new Error("final source rejection echoed a field value");
    }
    if (!rejected) throw new Error("invalid final source fixture was accepted");
  }
  process.stdout.write("evidence self-test: pass\n");
}

const [command, ...args] = process.argv.slice(2);

if (!command || command === "--help" || command === "help") {
  process.stdout.write(HELP);
} else if (command === "runs") {
  runs(args);
} else if (command === "pr-checks") {
  prChecks(args);
} else if (command === "pr-failures") {
  prFailures(args);
} else if (command === "watch" || command === "fail-fast") {
  watch(args);
} else if (command === "log-failed") {
  logFailed(args);
} else if (command === "test-summary") {
  testSummary(args);
} else if (command === "grep") {
  grepLogs(args);
} else if (command === "wait-for") {
  waitFor(args);
} else if (command === "check-actions") {
  checkActions(args);
} else if (command === "capture-evidence") {
  captureEvidence(args);
} else if (command === "capture-required-context-snapshot") {
  captureRequiredContextSnapshot(args);
} else if (command === "verify-required-context-snapshot") {
  verifyRequiredContextSnapshot(args);
} else if (command === "verify-remote-default-source") {
  verifyRemoteDefaultSource(args);
} else if (command === "verify-final-remote-default-source") {
  verifyFinalRemoteDefaultSource(args);
} else if (command === "probe-phase165") {
  probePhase165(args);
} else if (command === "validate-evidence") {
  validateEvidence(args);
} else if (command === "render-evidence") {
  renderEvidence(args);
} else if (command === "compare-evidence") {
  compareEvidence(args);
} else if (command === "test-evidence") {
  testEvidence();
} else {
  fail(`unknown command: ${command}\n\n${HELP}`);
}
