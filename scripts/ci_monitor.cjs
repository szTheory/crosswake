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
  capture-required-context-snapshot <output.json>
  verify-required-context-snapshot <snapshot.json> [--live]
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

function validateEvidence(args) {
  if (!args[0]) fail("validate-evidence requires an evidence path");
  validateEvidenceObject(readJson(args[0]));
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
  const output = args[2];
  const text = [
    "# Phase 165 descriptive CI comparison",
    "",
    `Before source: \`${before.repository_sha}\``,
    `After source: \`${after.repository_sha}\``,
    "",
    "Results are descriptive. Unmatched cohorts remain not measured; exact per-job queue time is not exposed.",
    "",
  ].join("\n");
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
