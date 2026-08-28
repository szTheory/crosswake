#!/usr/bin/env node

const { spawnSync } = require("node:child_process");

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
} else {
  fail(`unknown command: ${command}\n\n${HELP}`);
}
