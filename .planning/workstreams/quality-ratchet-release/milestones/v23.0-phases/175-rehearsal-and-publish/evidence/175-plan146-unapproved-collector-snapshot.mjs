import { createHash } from "node:crypto";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn, spawnSync } from "node:child_process";
import { createInterface } from "node:readline";
import {
  buildCreateArgs,
  runPreflight,
  validateExactHeadPreflightScope,
} from "./plan105_mirror_tag_collector.mjs";

function cleanGitEnv(helper = null) {
  const env = {
    PATH: process.env.PATH ?? "",
    HOME: process.env.HOME ?? "",
    GIT_TERMINAL_PROMPT: "0",
    GIT_ASKPASS: "false",
    GIT_CONFIG_NOSYSTEM: "1",
    GIT_CONFIG_GLOBAL: "/dev/null",
  };
  if (helper) {
    env.GIT_CONFIG_COUNT = "1";
    env.GIT_CONFIG_KEY_0 = "credential.https://github.com.helper";
    env.GIT_CONFIG_VALUE_0 = helper;
  }
  return env;
}


function credentialHelperDetails(processImpl) {
  try {
    const result = processImpl("git", ["config", "--get-regexp", "^credential\\.https://github\\.com\\.helper$"], {
      cwd: tmpdir(), encoding: "utf8", timeout: 5_000, maxBuffer: 4_096, windowsHide: true,
      env: { PATH: process.env.PATH ?? "", HOME: process.env.HOME ?? "", GIT_CONFIG_NOSYSTEM: "1" },
    });
    if (result.error) return { helper: null, git_operations: "UNKNOWN", failure_code: "HELPER_FAILED" };
    if (result.status !== 0 || typeof result.stdout !== "string" || Buffer.byteLength(result.stdout, "utf8") > 4_096) {
      return { helper: null, git_operations: 1 };
    }
    const lines = result.stdout.split(/\r?\n/).filter(Boolean);
    if (lines.length !== 1) return { helper: null, git_operations: 1 };
    const match = lines[0].match(/^credential\.https:\/\/github\.com\.helper\s+(.+)$/i);
    if (!match || !["osxkeychain", "manager-core", "manager"].includes(match[1].trim())) {
      return { helper: null, git_operations: 1 };
    }
    return { helper: match[1].trim(), git_operations: 1 };
  } catch {
    return { helper: null, git_operations: "UNKNOWN", failure_code: "HELPER_FAILED" };
  }
}

function credentialHelper() {
  return credentialHelperDetails().helper;
}

function validCredential(value) {
  return value && typeof value === "object" && !Array.isArray(value) &&
    typeof value.username === "string" && value.username.length > 0 && value.username.length <= 256 &&
    !/[\r\n\0]/.test(value.username) && typeof value.password === "string" &&
    value.password.length > 0 && value.password.length <= 4096 && !/[\r\n\0]/.test(value.password);
}

export function configuredCredential(processImpl = spawnSync) {
  const helperResult = credentialHelperDetails(processImpl);
  const helper = helperResult.helper;
  if (helperResult.failure_code) return helperResult;
  // The macOS Keychain helper can open a system prompt when the keychain is locked.
  // Do not invoke it from this bounded, unattended path.
  if (!helper || helper === "osxkeychain") return { git_operations: helperResult.git_operations };
  try {
    const result = processImpl("git", ["credential", "fill"], {
      cwd: tmpdir(), input: "protocol=https\nhost=github.com\n\n", encoding: "utf8",
      timeout: 5_000, maxBuffer: 4_096, windowsHide: true,
      env: {
        ...cleanGitEnv(helper), GCM_INTERACTIVE: "never", GCM_MODAL_PROMPT: "0",
      },
    });
    if (result.error) return { git_operations: "UNKNOWN", failure_code: "HELPER_FAILED" };
    if (result.status !== 0 || typeof result.stdout !== "string" ||
        Buffer.byteLength(result.stdout, "utf8") > 4_096) {
      return { git_operations: helperResult.git_operations + 1 };
    }
    const fields = new Map();
    for (const line of result.stdout.split(/\r?\n/).filter(Boolean)) {
      const split = line.indexOf("=");
      if (split < 1) return { git_operations: helperResult.git_operations + 1 };
      const key = line.slice(0, split);
      if (!["protocol", "host", "username", "password", "path", "oauth_refresh_token"].includes(key) || fields.has(key)) {
        return { git_operations: helperResult.git_operations + 1 };
      }
      fields.set(key, line.slice(split + 1));
    }
    const credential = { username: fields.get("username"), password: fields.get("password"), helper };
    return validCredential(credential)
      ? { ...credential, git_operations: helperResult.git_operations + 1 }
      : { git_operations: helperResult.git_operations + 1 };
  } catch {
    return { git_operations: "UNKNOWN", failure_code: "HELPER_FAILED" };
  }
}


const SOURCE = "https://github.com/szTheory/crosswake.git";
const MIRROR = "https://github.com/szTheory/crosswake-shell-core-ios.git";
const SOURCE_REF = "refs/tags/ios-core-v0.2.6";
const TARGET_REF = "refs/tags/v0.2.6";
const PRIOR_REF = "refs/tags/v0.2.5";
const SOURCE_OID = "998742856a37a97ae7247f6c532f9c154ea20885";
const SPLIT_OID = "424ab96ede1b92f2b751b54bce04c6e607f0f3c8";
const TREE_OID = "b80f3bf00ef61708120b062bc88738fed88294a9";
const LIMITS = Object.freeze({
  process_ms: 30_000,
  total_ms: 300_000,
  output_bytes: 65_536,
  input_bytes: 65_536,
  processes: 8,
});
const ZERO_COUNTS = Object.freeze({
  public_requests: 0,
  git_operations: 0,
  credential_helper_checks: 0,
  permission_checks: 0,
  dry_run_attempts: 0,
  tag_attempts: 0,
  readback_checks: 0,
  ci_requests: 0,
  request_count_unknown: false,
});
const DENIED_KEYS = new Set([
  "token", "access_token", "refresh_token", "password", "credential", "credential_value",
  "login", "username", "raw_response", "raw_stream", "private_path", "account_id", "device_id",
  "argv", "stdout", "stderr", "path",
]);

const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");
const canonical = (value) => {
  if (Array.isArray(value)) return `[${value.map(canonical).join(",")}]`;
  if (value && typeof value === "object") {
    return `{${Object.keys(value).sort().map((key) => `${JSON.stringify(key)}:${canonical(value[key])}`).join(",")}}`;
  }
  return JSON.stringify(value);
};
const digestObject = (value) => sha256(canonical(value));
const safeProjection = (value) => {
  if (Array.isArray(value)) return value.every(safeProjection);
  if (!value || typeof value !== "object") return true;
  return Object.entries(value).every(([key, item]) => !DENIED_KEYS.has(key.toLowerCase()) && safeProjection(item));
};
const exactKeys = (value, keys) => value && typeof value === "object" && !Array.isArray(value) &&
  canonical(Object.keys(value).sort()) === canonical([...keys].sort());
const knownCount = (value) => Number.isSafeInteger(value) && value >= 0;
const same = (left, right) => canonical(left) === canonical(right);

function exactPreview(preview) {
  return exactKeys(preview, ["accepted", "row_count", "oid", "ref", "force", "delete", "stderr_class"]) &&
    preview.accepted === true && preview.row_count === 1 && preview.oid === SPLIT_OID &&
    preview.ref === TARGET_REF && preview.force === false && preview.delete === false &&
    preview.stderr_class === "EMPTY";
}

function currentResultMatches(current, receipt) {
  return current && current.status === "PREFLIGHT_READY" && current.diagnostic === null &&
    exactKeys(current.counts, ["public_requests", "git_operations", "credential_helper_checks", "permission_checks",
      "dry_run_attempts", "tag_attempts", "ci_requests", "request_count_unknown"]) &&
    ["public_requests", "git_operations", "credential_helper_checks", "permission_checks", "dry_run_attempts"]
      .every((key) => knownCount(current.counts[key])) && current.counts.tag_attempts === 0 &&
    current.counts.ci_requests === 0 &&
    current.counts?.request_count_unknown === false && same(current.facts, receipt.facts) &&
    same(current.dry_run, receipt.dry_run) && exactPreview(current.dry_run) &&
    current.facts?.split_oid === SPLIT_OID && current.facts?.mirror_main_oid === SPLIT_OID &&
    current.facts?.mirror_prior_tag_oid === SPLIT_OID && current.facts?.target_state === "ABSENT" &&
    current.facts?.policy_complete === true && current.facts?.tag_policy === "CREATE_ONLY_ALLOWED" &&
    current.facts?.push_permission === "TRUE" && ["ADMIN", "WRITE", "MAINTAIN"].includes(current.facts?.permission_role) &&
    current.facts?.identity_match === "TRUE" && current.facts?.endpoint === MIRROR;
}

export const validateCurrentResult = currentResultMatches;

function addCurrentCounts(counts, current) {
  for (const key of ["public_requests", "git_operations", "credential_helper_checks", "permission_checks", "dry_run_attempts"]) {
    if (!knownCount(current?.counts?.[key])) counts.request_count_unknown = true;
    else counts[key] += current.counts[key];
  }
  if (current?.counts?.request_count_unknown !== false) counts.request_count_unknown = true;
}

function validReadback(readback) {
  return exactKeys(readback, ["target_oid", "main_oid", "prior_tag_oid"]) &&
    readback.target_oid === SPLIT_OID && readback.main_oid === SPLIT_OID && readback.prior_tag_oid === SPLIT_OID;
}

function result(status, counts, extras = {}) {
  const value = {
    schema: "crosswake-plan146-apply-result/v1",
    status,
    counts: { ...counts },
    intent_sha256: null,
    readback: null,
    failure_reason: null,
    ...extras,
  };
  if (!safeProjection(value)) return { schema: "crosswake-plan146-apply-result/v1", status: "UNKNOWN", counts: unknownCounts(), intent_sha256: null, readback: null, failure_reason: "RUNNER_UNAVAILABLE" };
  return value;
}

function unknownCounts() {
  return {
    public_requests: "UNKNOWN",
    git_operations: "UNKNOWN",
    credential_helper_checks: "UNKNOWN",
    permission_checks: "UNKNOWN",
    dry_run_attempts: "UNKNOWN",
    tag_attempts: "UNKNOWN",
    readback_checks: "UNKNOWN",
    ci_requests: 0,
    request_count_unknown: true,
  };
}

/** One production state machine; adapters are the only side-effect boundary. */
export async function runAttempt(receipt, authorization, adapters) {
  const counts = { ...ZERO_COUNTS,
    git_operations: adapters?.startup_git_operations ?? 0,
    credential_helper_checks: adapters?.startup_helper_checks ?? 0 };
  if (!receipt || receipt.schema !== "crosswake-plan136-preflight/v1" || receipt.status !== "PREFLIGHT_READY" ||
      authorization?.decision !== "ALLOW" || !/^[0-9a-f]{64}$/.test(authorization?.sha256 ?? "") ||
      !adapters || typeof adapters.snapshot !== "function" || typeof adapters.preparePush !== "function" ||
      typeof adapters.persistIntent !== "function" || typeof adapters.pushOnce !== "function" ||
      typeof adapters.readback !== "function" || !safeProjection({ receipt, authorization })) {
    return result("BLOCKED", counts);
  }

  let first;
  try { first = await adapters.snapshot("preview"); }
  catch { return result("BLOCKED", unknownCounts()); }
  addCurrentCounts(counts, first);
  if (!currentResultMatches(first, receipt)) return result("BLOCKED", counts, { failure_reason: currentFailure(first, receipt) });

  try {
    const prepared = await adapters.preparePush();
    if (prepared !== true && prepared?.ok !== true) {
      if (knownCount(prepared?.git_operations)) counts.git_operations += prepared.git_operations;
      else counts.request_count_unknown = true;
      if (prepared?.request_count_unknown === true) counts.request_count_unknown = true;
      return result("BLOCKED", counts, { failure_reason: "SOURCE_PREPARATION_FAILED" });
    }
    if (knownCount(prepared?.git_operations)) counts.git_operations += prepared.git_operations;
    else counts.request_count_unknown = true;
  } catch { return result("BLOCKED", { ...counts, request_count_unknown: true }); }

  const intentBody = {
    schema: "crosswake-plan146-write-intent/v1",
    attempt_id: authorization.attempt_id,
    scope_sha256: authorization.scope_sha256,
    card_sha256: authorization.card_sha256,
    plan140_result_sha256: authorization.plan140_result_sha256,
    collector_sha256: authorization.collector_sha256,
    authorization_sha256: authorization.sha256,
    oid: SPLIT_OID,
    target_ref: TARGET_REF,
    force: false,
    delete: false,
    facts_sha256: digestObject(receipt.facts),
    preview_sha256: digestObject(receipt.dry_run),
    counts: { ...counts },
  };
  const intent = { ...intentBody, sha256: digestObject(intentBody) };
  let persisted;
  try { persisted = await adapters.persistIntent(intent); }
  catch { return result("UNKNOWN", unknownCounts()); }
  if (persisted !== true) return result("UNKNOWN", unknownCounts());

  let beforePush;
  try { beforePush = await adapters.snapshot("immediate-prewrite"); }
  catch { return result("BLOCKED", unknownCounts()); }
  addCurrentCounts(counts, beforePush);
  if (!currentResultMatches(beforePush, receipt)) return result("BLOCKED", counts, { intent_sha256: intent.sha256, failure_reason: currentFailure(beforePush, receipt) });

  let pushInvoked = false;
  let push;
  try {
    const pushOutcome = await adapters.pushOnce();
    if (typeof pushOutcome === "string") {
      push = pushOutcome;
      pushInvoked = true;
    }
    else {
      push = pushOutcome?.result;
      pushInvoked = pushOutcome?.push_invoked !== false;
      if (knownCount(pushOutcome?.git_operations)) counts.git_operations += pushOutcome.git_operations;
      else counts.request_count_unknown = true;
    }
  }
  catch {
    const uncertainCounts = {
      ...counts,
      tag_attempts: "UNKNOWN",
      git_operations: "UNKNOWN",
      request_count_unknown: true,
      readback_checks: 1,
    };
    try {
      const later = await adapters.readback();
      const laterReadback = later?.readback ?? later;
      return result("UNKNOWN", uncertainCounts, { intent_sha256: intent.sha256, readback: laterReadback });
    } catch {
      return result("UNKNOWN", uncertainCounts, { intent_sha256: intent.sha256 });
    }
  }
  counts.tag_attempts = pushInvoked ? 1 : 0;
  if (!pushInvoked) return result("BLOCKED", counts, { intent_sha256: intent.sha256 });
  if (push === "REJECTED") return result("REJECTED", counts, { intent_sha256: intent.sha256 });
  let readback;
  try {
    counts.readback_checks += 1;
    const readbackOutcome = await adapters.readback();
    readback = readbackOutcome?.readback ?? readbackOutcome;
    if (knownCount(readbackOutcome?.git_operations)) counts.git_operations += readbackOutcome.git_operations;
    else if (readbackOutcome?.readback) counts.request_count_unknown = true;
  }
  catch {
    return result("UNKNOWN", { ...counts, git_operations: "UNKNOWN", request_count_unknown: true },
      { intent_sha256: intent.sha256 });
  }
  if (push !== "ACCEPTED") {
    return result("UNKNOWN", counts, { intent_sha256: intent.sha256, readback });
  }
  return result(validReadback(readback) ? "TAG_VERIFIED" : "DISCREPANCY", counts,
    { intent_sha256: intent.sha256, readback });
}

async function boundedProcess(command, args, options, timeoutMs = LIMITS.process_ms) {
  return new Promise((resolve) => {
    let child;
    let started = false;
    let settled = false;
    let overflow = false;
    let total = 0;
    const stdout = [];
    const stderr = [];
    const timer = setTimeout(() => {
      child?.kill("SIGKILL");
      finish(null, true);
    }, Math.min(LIMITS.process_ms, timeoutMs));
    const finish = (status, timedOut = false) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      resolve({
        started,
        exitObserved: !timedOut && status !== null,
        status: timedOut ? null : status,
        stdout: Buffer.concat(stdout),
        stderr: Buffer.concat(stderr),
        overflow,
      });
    };
    try {
      child = spawn(command, args, { ...options, shell: false, windowsHide: true, stdio: ["ignore", "pipe", "pipe"] });
      child.once("spawn", () => { started = true; });
      child.stdout.on("data", (chunk) => {
        total += chunk.length;
        if (total > LIMITS.output_bytes) overflow = true;
        if (Buffer.concat(stdout).length < LIMITS.output_bytes) stdout.push(chunk.subarray(0, LIMITS.output_bytes));
      });
      child.stderr.on("data", (chunk) => {
        total += chunk.length;
        if (total > LIMITS.output_bytes) overflow = true;
        if (Buffer.concat(stderr).length < LIMITS.output_bytes) stderr.push(chunk.subarray(0, LIMITS.output_bytes));
      });
      child.once("error", () => finish(null));
      child.once("close", (code) => finish(code));
    } catch { finish(null); }
  });
}

const gitEnv = (credential) => ({
  PATH: process.env.PATH ?? "",
  HOME: process.env.HOME ?? "",
  GIT_TERMINAL_PROMPT: "0",
  GIT_ASKPASS: "false",
  GIT_CONFIG_NOSYSTEM: "1",
  GIT_CONFIG_GLOBAL: "/dev/null",
  GIT_CONFIG_COUNT: "2",
  GIT_CONFIG_KEY_0: "credential.helper",
  GIT_CONFIG_VALUE_0: "",
  GIT_CONFIG_KEY_1: "http.https://github.com/.extraheader",
  GIT_CONFIG_VALUE_1: `Authorization: Basic ${Buffer.from(`${credential.username}:${credential.password}`, "utf8").toString("base64")}`,
});

function parseRefs(bytes, expected) {
  if (!Buffer.isBuffer(bytes) || bytes.length > LIMITS.output_bytes) return null;
  const text = bytes.toString("utf8");
  if (!Buffer.from(text, "utf8").equals(bytes)) return null;
  const found = new Map();
  for (const line of text.split(/\r?\n/).filter(Boolean)) {
    const match = /^([0-9a-f]{40})\t(.+)$/.exec(line);
    if (!match || !expected.includes(match[2]) || found.has(match[2])) return null;
    found.set(match[2], match[1]);
  }
  return found;
}

export function adaptPreflight(current) {
  if (!exactKeys(current, ["facts", "dry_run", "counts", "diagnostic"])) return null;
  return { ...current, status: current.diagnostic === null ? "PREFLIGHT_READY" : "BLOCKED" };
}

function currentFailure(current, receipt) {
  if (!current || current.status !== "PREFLIGHT_READY") return "PREFLIGHT_UNAVAILABLE";
  if (current.diagnostic !== null) return "PREFLIGHT_UNAVAILABLE";
  if (!same(current.facts, receipt.facts)) return "FACTS_CHANGED";
  if (!same(current.dry_run, receipt.dry_run) || !exactPreview(current.dry_run)) return "PREVIEW_MISMATCH";
  return "COUNTS_OR_CONTRACT_INVALID";
}

export function createProductionAdapters(scope, credential, input, reader, preflight = runPreflight) {
  let prepared = null;
  const startedAt = Date.now();
  const requireTime = () => Date.now() - startedAt <= LIMITS.total_ms;
  const snapshot = async () => {
    if (!requireTime()) throw new Error("limit");
    const current = await preflight(scope, {
      credentialProvider: async () => ({ ...credential, git_operations: 0 }),
    });
    // The helper was acquired once at startup; cached provider calls do not run it.
    if (!current?.counts) return null;
    current.counts.credential_helper_checks = 0;
    return adaptPreflight(current);
  };
  return {
    startup_git_operations: credential.git_operations,
    startup_helper_checks: 1,
    snapshot,
    async preparePush() {
      if (!requireTime()) return false;
      const nodeTmp = await mkdtemp(join(tmpdir(), "crosswake-plan146-"));
      const repo = join(nodeTmp, "source");
      const env = gitEnv(credential);
      const commands = [
        ["git", ["clone", "--quiet", "--no-checkout", "--no-tags", SOURCE, repo], nodeTmp],
        ["git", ["-C", repo, "fetch", "--quiet", "--no-tags", "origin", SOURCE_REF], nodeTmp],
        ["git", ["-C", repo, "checkout", "--quiet", "--detach", SOURCE_OID], nodeTmp],
        ["git", ["-C", repo, "subtree", "split", "--quiet", "--prefix=packages/crosswake-shell-core-ios", SOURCE_OID], nodeTmp],
        ["git", ["-C", repo, "remote", "add", "mirror", MIRROR], nodeTmp],
      ];
      let operations = 0;
      for (const [command, args, cwd] of commands) {
        if (operations >= LIMITS.processes) {
          await rm(nodeTmp, { recursive: true, force: true }).catch(() => {});
          return { ok: false, git_operations: operations, request_count_unknown: true };
        }
        operations += 1;
        const run = await boundedProcess(command, args, { cwd, env });
        if (!run.started || !run.exitObserved || run.status !== 0 || run.overflow || run.stderr.length) {
          await rm(nodeTmp, { recursive: true, force: true }).catch(() => {});
          return { ok: false, git_operations: operations, request_count_unknown: false };
        }
        if (args.includes("split") && run.stdout.toString("utf8").trim() !== SPLIT_OID) {
          await rm(nodeTmp, { recursive: true, force: true }).catch(() => {});
          return { ok: false, git_operations: operations, request_count_unknown: false };
        }
      }
      prepared = { nodeTmp, repo };
      return { ok: true, git_operations: operations };
    },
    async persistIntent(intent) {
      process.stdout.write(`${JSON.stringify({ type: "write-intent", intent })}\n`);
      const ack = await reader.next();
      return ack?.type === "intent-durable" && ack.sha256 === intent.sha256;
    },
    async pushOnce() {
      if (!prepared || !requireTime()) return { result: "UNKNOWN", git_operations: 0, push_invoked: false };
      const args = buildCreateArgs(SPLIT_OID, "mirror", TARGET_REF);
      if (!args) return { result: "UNKNOWN", git_operations: 0, push_invoked: false };
      const run = await boundedProcess("git", ["-C", prepared.repo, ...args], { cwd: prepared.repo, env: gitEnv(credential) });
      if (!run.started || !run.exitObserved || run.status === null || run.overflow || run.stderr.length) return { result: "UNKNOWN", git_operations: 1, push_invoked: true };
      if (run.status !== 0) return { result: "REJECTED", git_operations: 1, push_invoked: true };
      const lines = run.stdout.toString("utf8").trimEnd().split("\n");
      const row = `*\t${TARGET_REF}:${TARGET_REF}\t[new tag]`;
      return { result: (lines.length === 1 && lines[0] === row) ||
        (lines.length === 2 && lines[0] === `To ${MIRROR}` && lines[1] === row) ? "ACCEPTED" : "UNKNOWN", git_operations: 1, push_invoked: true };
    },
    async readback() {
      if (!prepared || !requireTime()) throw new Error("limit");
      const priorPeeled = `${PRIOR_REF}^{} ` .trim();
      const targetPeeled = `${TARGET_REF}^{} ` .trim();
      const wanted = ["refs/heads/main", PRIOR_REF, priorPeeled, TARGET_REF, targetPeeled];
      const args = ["-C", prepared.repo, "ls-remote", MIRROR, ...wanted];
      const run = await boundedProcess("git", args, { cwd: prepared.repo, env: gitEnv(credential) });
      if (!run.started || !run.exitObserved || run.status !== 0 || run.overflow || run.stderr.length) throw new Error("readback");
      const refs = parseRefs(run.stdout, wanted);
      if (!refs) throw new Error("readback");
      return {
        readback: {
          target_oid: refs.get(TARGET_REF) ?? refs.get(targetPeeled) ?? null,
          main_oid: refs.get("refs/heads/main") ?? null,
          prior_tag_oid: refs.get(PRIOR_REF) ?? refs.get(priorPeeled) ?? null,
        },
        git_operations: 1,
      };
    },
    async cleanup() {
      if (prepared) await rm(prepared.nodeTmp, { recursive: true, force: true }).catch(() => {});
    },
  };
}

function fixtureAdapters(receipt, fixture, reader) {
  if (!fixture || !["success", "ambiguous-delivery"].includes(fixture.scenario)) return null;
  const counts = {
    public_requests: 16, git_operations: 19, credential_helper_checks: 1, permission_checks: 3,
    dry_run_attempts: 1, tag_attempts: 0, ci_requests: 0,
  };
  let snapshotCount = 0;
  return {
    async snapshot() {
      snapshotCount += 1;
      return {
        status: "PREFLIGHT_READY", diagnostic: null,
        facts: receipt.facts, dry_run: receipt.dry_run, counts: { ...counts, request_count_unknown: false },
      };
    },
    async preparePush() { return { ok: true, git_operations: 5 }; },
    async persistIntent(intent) {
      process.stdout.write(`${JSON.stringify({ type: "write-intent", intent })}\n`);
      const ack = await reader.next();
      return ack?.type === "intent-durable" && ack.sha256 === intent.sha256;
    },
    async pushOnce() { return { result: fixture.scenario === "success" ? "ACCEPTED" : "AMBIGUOUS", git_operations: 1, push_invoked: true }; },
    async readback() {
      return {
        readback: {
          target_oid: "424ab96ede1b92f2b751b54bce04c6e607f0f3c8",
          main_oid: "424ab96ede1b92f2b751b54bce04c6e607f0f3c8",
          prior_tag_oid: "424ab96ede1b92f2b751b54bce04c6e607f0f3c8",
        },
        git_operations: 1,
      };
    },
    get snapshotCount() { return snapshotCount; },
  };
}

function makeReader() {
  const lines = createInterface({ input: process.stdin, crlfDelay: Infinity });
  const pending = [];
  const waiting = [];
  lines.on("line", (line) => {
    if (waiting.length) waiting.shift()(line);
    else pending.push(line);
  });
  return {
    async next() {
      const line = pending.shift() ?? await new Promise((resolve) => waiting.push(resolve));
      if (Buffer.byteLength(line, "utf8") > LIMITS.input_bytes) return null;
      try { return JSON.parse(line); } catch { return null; }
    },
    close() { lines.close(); },
  };
}

async function main() {
  const reader = makeReader();
  let adapters = null;
  try {
    const request = await reader.next();
    if (!request || !exactKeys(request, ["operation", "scope", "plan146_scope", "receipt", "authorization", "adapter_fixture"]) ||
        request.operation !== "apply" || !validateExactHeadPreflightScope(request.scope) ||
        request.receipt?.status !== "PREFLIGHT_READY" || request.authorization?.decision !== "ALLOW" ||
        !await validAuthorization(request.plan146_scope, request.scope, request.receipt, request.authorization) ||
        !safeProjection({ receipt: request.receipt, plan146_scope: request.plan146_scope, authorization: request.authorization })) throw new Error("blocked");

    if (process.env.MIX_ENV === "test") {
      adapters = fixtureAdapters(request.receipt, request.adapter_fixture, reader);
    } else {
      const supplied = configuredCredential();
      if (!validCredential(supplied)) {
        const counts = { ...ZERO_COUNTS, credential_helper_checks: 1,
          git_operations: supplied?.git_operations ?? "UNKNOWN" };
        counts.request_count_unknown = counts.git_operations === "UNKNOWN";
        process.stdout.write(`${JSON.stringify({ type: "terminal", result: result("BLOCKED", counts, { failure_reason: "CREDENTIAL_UNAVAILABLE" }) })}\n`);
        return;
      }
      const credential = Object.freeze(supplied);
      adapters = createProductionAdapters(request.scope, credential, request, reader);
    }
    if (!adapters) throw new Error("adapter");
    const output = await runAttempt(request.receipt, request.authorization, adapters);
    await adapters.cleanup?.();
    process.stdout.write(`${JSON.stringify({ type: "terminal", result: output })}\n`);
  } catch {
    await adapters?.cleanup?.();
    process.stdout.write(`${JSON.stringify({ type: "terminal", result: result("UNKNOWN", unknownCounts(), { failure_reason: "RUNNER_UNAVAILABLE" }) })}\n`);
  } finally {
    reader.close();
  }
}

async function validAuthorization(plan146Scope, plan140Scope, receipt, authorization) {
  const plan146Keys = ["schema", "attempt_id", "created_at_utc", "plan140", "facts_sha256", "preview_sha256",
    "source_oid", "split_oid", "target_ref", "mirror_main_oid", "mirror_prior_tag_oid", "collector_sha256",
    "counts", "posture", "sha256"];
  const receiptKeys = ["attempt_id", "authorization_sha256", "counts", "diagnostic", "dry_run", "facts",
    "observed_at_utc", "posture", "reason", "schema", "scope_sha256", "sha256", "status"];
  if (!exactKeys(plan146Scope, plan146Keys) || !exactKeys(authorization, ["schema", "attempt_id", "decision", "scope_sha256", "card_sha256",
    "collector_sha256", "plan140_result_sha256", "created_at_utc", "sha256"]) || !exactKeys(receipt, receiptKeys) ||
      plan146Scope.schema !== "crosswake-plan146-tag-scope/v1" || !/^[0-9a-f]{32}$/.test(plan146Scope.attempt_id ?? "") ||
      !Number.isFinite(Date.parse(plan146Scope.created_at_utc ?? "")) ||
      plan146Scope.sha256 !== digestObject(Object.fromEntries(Object.entries(plan146Scope).filter(([key]) => key !== "sha256"))) ||
      !exactKeys(plan146Scope.plan140, ["attempt_id", "scope_sha256", "authorization_sha256", "result_sha256", "collector_sha256", "observed_at_utc"]) ||
      plan146Scope.plan140.attempt_id !== "9438fec143ddb1beda7168e002b2a12f" ||
      plan146Scope.plan140.scope_sha256 !== plan140Scope.sha256 ||
      plan146Scope.facts_sha256 !== digestObject(receipt.facts) || plan146Scope.preview_sha256 !== digestObject(receipt.dry_run) ||
      plan146Scope.source_oid !== SOURCE_OID || plan146Scope.split_oid !== SPLIT_OID || plan146Scope.target_ref !== TARGET_REF ||
      plan146Scope.mirror_main_oid !== receipt.facts?.mirror_main_oid ||
      plan146Scope.mirror_prior_tag_oid !== receipt.facts?.mirror_prior_tag_oid ||
      plan146Scope.posture === undefined || !same(plan146Scope.posture, receipt.posture) ||
      !same(plan146Scope.counts, ZERO_COUNTS) || receipt.schema !== "crosswake-plan136-preflight/v1" ||
      receipt.status !== "PREFLIGHT_READY" || receipt.diagnostic !== null ||
      receipt.sha256 !== digestObject(Object.fromEntries(Object.entries(receipt).filter(([key]) => key !== "sha256"))) ||
      receipt.attempt_id !== plan146Scope.plan140.attempt_id || receipt.scope_sha256 !== plan146Scope.plan140.scope_sha256 ||
      receipt.authorization_sha256 !== plan146Scope.plan140.authorization_sha256 ||
      authorization.schema !== "crosswake-plan146-tag-authorization/v1" || authorization.decision !== "ALLOW" ||
      authorization.attempt_id !== plan146Scope.attempt_id || authorization.scope_sha256 !== plan146Scope.sha256 ||
      !/^[0-9a-f]{64}$/.test(authorization.card_sha256 ?? "") ||
      !Number.isFinite(Date.parse(authorization.created_at_utc ?? "")) ||
      authorization.collector_sha256 !== plan146Scope.collector_sha256 ||
      authorization.plan140_result_sha256 !== plan146Scope.plan140.result_sha256 ||
      authorization.plan140_result_sha256 !== receipt.sha256 ||
      authorization.sha256 !== digestObject(Object.fromEntries(Object.entries(authorization).filter(([key]) => key !== "sha256")))) {
    return false;
  }
  try {
    const currentScript = await readFile(new URL(import.meta.url));
    return sha256(currentScript) === plan146Scope.collector_sha256;
  } catch { return false; }
}

if (process.argv[1]?.endsWith("plan146_tag_apply.mjs")) void main();
