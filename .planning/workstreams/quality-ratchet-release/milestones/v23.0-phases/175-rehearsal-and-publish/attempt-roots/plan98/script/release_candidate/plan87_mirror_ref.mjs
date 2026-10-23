import { spawnSync } from "node:child_process";
import { appendFileSync, closeSync, fsyncSync, lstatSync, mkdtempSync, openSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { randomBytes, createHash } from "node:crypto";

const CONTRACT_SHA256 = "ecc3ddfc8bb5da278c26bebf30c9abd2420921fb631fb3c1acde73530d7116e2";
const CONTRACT_BYTES = readFileSync(new URL("./plan87_read_scope_contract.json", import.meta.url));
const CONTRACT = JSON.parse(CONTRACT_BYTES.toString("utf8"));
const API_ORIGIN = "https://api.github.com";
const API_VERSION = "2022-11-28";
const SOURCE = "/repos/szTheory/crosswake";
const MIRROR = "/repos/szTheory/crosswake-shell-core-ios";
const TARGET_REF = "refs/tags/v0.2.6";
const MAX_RESPONSE_BYTES = 32768;
const MAX_TIMEOUT_MS = 10000;
const MAX_PAGES = 4;

const EXPECTED_ROUTES = [
  { method: "GET", path: SOURCE + "/git/ref/tags/ios-core-v0.2.6" },
  { method: "GET", path: SOURCE + "/pulls/219" },
  { method: "GET", path: SOURCE + "/git/commits/{oid40}" },
  { method: "GET", path: SOURCE + "/git/tags/{oid40}" },
  { method: "GET", path: MIRROR + "/git/ref/heads/main" },
  { method: "GET", path: MIRROR + "/git/ref/tags/v0.2.5" },
  { method: "GET", path: MIRROR + "/git/ref/tags/v0.2.6" },
  { method: "GET", path: MIRROR + "/git/commits/{oid40}" },
  { method: "GET", path: MIRROR + "/collaborators/{login39}/permission" },
  { method: "GET", path: "/user" },
  { method: "GET", path: MIRROR + "/rulesets?page={1..4}&per_page=100" }
];

function canonical(value) {
  if (Array.isArray(value)) return "[" + value.map(canonical).join(",") + "]";
  if (value && typeof value === "object") {
    return "{" + Object.keys(value).sort().map((key) => JSON.stringify(key) + ":" + canonical(value[key])).join(",") + "}";
  }
  return JSON.stringify(value);
}

function contractValid() {
  const digest = createHash("sha256").update(CONTRACT_BYTES).digest("hex");
  return digest === CONTRACT_SHA256 &&
    Object.keys(CONTRACT).sort().join(",") === "api_bounds,api_origin,comparison_pin,git_bounds,main_ref,mirror_repository,operation_accounting,permission_route_template,prior_ref,purpose,routes,ruleset_query,schema,source_git_remote,source_git_tag_ref,source_repository,source_tag,subtree_prefix,target_ref" &&
    CONTRACT.schema === "crosswake-plan87-read-contract/v2" &&
    canonical(CONTRACT.operation_accounting) === canonical({
      schema: "crosswake-plan87-operation-accounting/v1",
      event_keys: ["attempt_id", "scope_sha256", "sequence", "operation_id", "operation", "state", "status"],
      parent_operations: ["port"],
      child_operations: ["api_fetch", "git_spawn"],
      delivery_states: ["UNKNOWN", "RESPONSE_OBSERVED"],
      max_events: 128,
      max_journal_bytes: 32768
    }) &&
    CONTRACT.api_origin === API_ORIGIN && CONTRACT.source_repository === "szTheory/crosswake" &&
    CONTRACT.mirror_repository === "szTheory/crosswake-shell-core-ios" &&
    CONTRACT.source_tag === "ios-core-v0.2.6" && CONTRACT.target_ref === TARGET_REF &&
    CONTRACT.source_git_remote === "https://github.com/szTheory/crosswake.git" &&
    CONTRACT.source_git_tag_ref === "refs/tags/ios-core-v0.2.6" &&
    CONTRACT.subtree_prefix === "packages/crosswake-shell-core-ios" &&
    CONTRACT.prior_ref === "refs/tags/v0.2.5" && CONTRACT.main_ref === "refs/heads/main" &&
    CONTRACT.permission_route_template === "/repos/szTheory/crosswake-shell-core-ios/collaborators/{opaque_actor}/permission" &&
    canonical(CONTRACT.routes) === canonical(EXPECTED_ROUTES) &&
    canonical(CONTRACT.api_bounds) === canonical({ max_requests: 32, http_timeout_ms: 10000, max_response_bytes: 32768, max_ruleset_pages: 4, ruleset_page_size: 100, port_timeout_ms: 240000, max_port_output_bytes: 32768 }) &&
    canonical(CONTRACT.git_bounds) === canonical({ clone_timeout_ms: 180000, fetch_timeout_ms: 60000, split_timeout_ms: 120000, other_timeout_ms: 20000, max_buffer_bytes: 8192, max_stdout_bytes: 4096 }) &&
    canonical(CONTRACT.ruleset_query) === canonical({ pages: [1, 2, 3, 4], per_page: 100, additional_query: false }) &&
    canonical(CONTRACT.comparison_pin) === canonical({
      observed_at: "2026-10-06", purpose: "historical_planning_only", pull_request: 219,
      base_oid: "e51698528dc667ef89beb951e4eb1ec91da74981",
      head_oid: "696a27a3be1fcd56efe70923dc0ce286a1c41c6d",
      tree_oid: "5279cae1daa1fbff3437b673df8ca231fb07c91f"
    });
}

export function validatePathSet(pathSet) {
  if (!pathSet || typeof pathSet !== "object" || Array.isArray(pathSet)) return false;
  const keys = "attempt_id,contract_sha256,evidence_root,files,schema,sha256";
  if (Object.keys(pathSet).sort().join(",") !== keys ||
      pathSet.schema !== "crosswake-plan92-path-set/v1" ||
      !/^[0-9a-f]{32}$/.test(pathSet.attempt_id ?? "") ||
      pathSet.contract_sha256 !== CONTRACT_SHA256 ||
      !["evidence", ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence"].includes(pathSet.evidence_root) ||
      !pathSet.files || typeof pathSet.files !== "object" || Array.isArray(pathSet.files)) return false;
  const expected = {
    read_scope: `175-plan92-${pathSet.attempt_id}-read-scope.json`,
    preflight_lifecycle: `175-plan92-${pathSet.attempt_id}-preflight.lifecycle.jsonl`,
    parent_journal: `175-plan87-ops-${pathSet.attempt_id}-{scope_sha256}-parent.jsonl`,
    child_journal: `175-plan87-ops-${pathSet.attempt_id}-{scope_sha256}-child.jsonl`,
    read_authorization: `175-plan92-${pathSet.attempt_id}-read-authorization.json`,
    preflight: `175-plan92-${pathSet.attempt_id}-preflight.json`,
    outcome: `175-plan92-${pathSet.attempt_id}-outcome.json`,
    outcome_lifecycle: `175-plan92-${pathSet.attempt_id}-outcome.lifecycle.jsonl`,
    hold: `175-plan92-${pathSet.attempt_id}-hold.json`
  };
  if (canonical(pathSet.files) !== canonical(expected)) return false;
  const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(pathSet).filter(([key]) => key !== "sha256")))).digest("hex");
  return pathSet.sha256 === digest;
}

export function validatePlan93PathSet(pathSet) {
  if (!pathSet || typeof pathSet !== "object" || Array.isArray(pathSet)) return false;
  const keys = "attempt_id,contract_sha256,evidence_root,files,history_manifest_sha256,schema,sha256";
  if (Object.keys(pathSet).sort().join(",") !== keys ||
      pathSet.schema !== "crosswake-plan93-path-set/v1" ||
      !/^[0-9a-f]{32}$/.test(pathSet.attempt_id ?? "") ||
      pathSet.contract_sha256 !== CONTRACT_SHA256 ||
      !/^[0-9a-f]{64}$/.test(pathSet.history_manifest_sha256 ?? "") ||
      !["evidence", ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence"].includes(pathSet.evidence_root) ||
      !pathSet.files || typeof pathSet.files !== "object" || Array.isArray(pathSet.files)) return false;
  const attempt = pathSet.attempt_id;
  const expected = {
    read_scope: `175-plan93-${attempt}-read-scope.json`,
    history_manifest: `175-plan93-${attempt}-history-manifest.json`,
    preflight_lifecycle: `175-plan93-${attempt}-preflight.lifecycle.jsonl`,
    parent_journal: `175-plan93-ops-${attempt}-{scope_sha256}-parent.jsonl`,
    child_journal: `175-plan93-ops-${attempt}-{scope_sha256}-child.jsonl`,
    read_authorization: `175-plan93-${attempt}-read-authorization.json`,
    preflight: `175-plan93-${attempt}-preflight.json`,
    hold: `175-plan93-${attempt}-hold.json`
  };
  if (canonical(pathSet.files) !== canonical(expected)) return false;
  const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(pathSet).filter(([key]) => key !== "sha256")))).digest("hex");
  return pathSet.sha256 === digest;
}

const PLAN94_CANDIDATE = Object.freeze({
  version: "0.2.7",
  base_oid: "e51698528dc667ef89beb951e4eb1ec91da74981",
  head_oid: "696a27a3be1fcd56efe70923dc0ce286a1c41c6d",
  tree_oid: "5279cae1daa1fbff3437b673df8ca231fb07c91f"
});

export function validatePlan94PathSet(pathSet) {
  return validatePlanBoundPathSet(pathSet, "plan94");
}

export function validatePlan95PathSet(pathSet) {
  return validatePlanBoundPathSet(pathSet, "plan95");
}

export function validatePlan97PathSet(pathSet) {
  return validatePlanBoundPathSet(pathSet, "plan97");
}

function validatePlanBoundPathSet(pathSet, plan) {
  if (!pathSet || typeof pathSet !== "object" || Array.isArray(pathSet)) return false;
  if (Object.keys(pathSet).sort().join(",") !== "attempt_id,contract_sha256,evidence_root,files,schema,sha256" ||
      pathSet.schema !== `crosswake-${plan}-path-set/v1` ||
      !/^[0-9a-f]{32}$/.test(pathSet.attempt_id ?? "") ||
      pathSet.contract_sha256 !== CONTRACT_SHA256 ||
      !["evidence", ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence"].includes(pathSet.evidence_root) ||
      !pathSet.files || typeof pathSet.files !== "object" || Array.isArray(pathSet.files)) return false;
  const attempt = pathSet.attempt_id;
  const expected = {
    read_scope: `175-${plan}-${attempt}-read-scope.json`,
    preflight_lifecycle: `175-${plan}-${attempt}-preflight.lifecycle.jsonl`,
    parent_journal: `175-${plan}-ops-${attempt}-{scope_sha256}-parent.jsonl`,
    child_journal: `175-${plan}-ops-${attempt}-{scope_sha256}-child.jsonl`,
    ...(plan === "plan97" ? { read_authorization: `175-plan97-${attempt}-read-authorization.json` } : {}),
    preflight: `175-${plan}-${attempt}-preflight.json`
  };
  if (canonical(pathSet.files) !== canonical(expected)) return false;
  const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(pathSet).filter(([key]) => key !== "sha256")))).digest("hex");
  return pathSet.sha256 === digest;
}

export function validatePlan94ReadScope(scope, suppliedDigest, pathSet) {
  return validatePlanBoundReadScope(scope, suppliedDigest, pathSet, "plan94");
}

export function validatePlan95ReadScope(scope, suppliedDigest, pathSet) {
  return validatePlanBoundReadScope(scope, suppliedDigest, pathSet, "plan95");
}

export function validatePlan97ReadScope(scope, suppliedDigest, pathSet) {
  return validatePlanBoundReadScope(scope, suppliedDigest, pathSet, "plan97");
}

function planScopedContract(plan) {
  if (plan !== "plan97") return CONTRACT;
  return {
    ...CONTRACT,
    routes: CONTRACT.routes.filter((route) =>
      !["/user", "/repos/szTheory/crosswake-shell-core-ios/collaborators/{login39}/permission",
        "/repos/szTheory/crosswake-shell-core-ios/rulesets?page={1..4}&per_page=100"].includes(route.path))
  };
}

function validatePlanBoundReadScope(scope, suppliedDigest, pathSet, plan) {
  const pathSetValid = plan === "plan95" ? validatePlan95PathSet(pathSet) :
    plan === "plan97" ? validatePlan97PathSet(pathSet) : validatePlan94PathSet(pathSet);
  if (!contractValid() || !pathSetValid || !scope || typeof scope !== "object" || Array.isArray(scope)) return false;
  const keys = "attempt_id,candidate,contract,contract_sha256,path_set_sha256,purpose,read_intent,request_count,schema,scope_path,sha256,status";
  if (Object.keys(scope).sort().join(",") !== keys || scope.schema !== `crosswake-${plan}-read-scope/v1` ||
      scope.attempt_id !== pathSet.attempt_id || scope.path_set_sha256 !== pathSet.sha256 ||
      scope.contract_sha256 !== CONTRACT_SHA256 || canonical(scope.contract) !== canonical(planScopedContract(plan)) ||
      canonical(scope.candidate) !== canonical(PLAN94_CANDIDATE) || scope.purpose !== "one fresh v0.2.6 mirror-parity and v0.2.7 candidate observation" ||
      scope.scope_path !== `${pathSet.evidence_root}/${pathSet.files.read_scope}` || scope.request_count !== 0 ||
      scope.read_intent !== false || scope.status !== "PENDING") return false;
  const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(scope).filter(([key]) => key !== "sha256")))).digest("hex");
  return scope.sha256 === digest && suppliedDigest === digest;
}

const PLAN93_CANDIDATE = Object.freeze({
  version: "0.2.7",
  base_oid: "e51698528dc667ef89beb951e4eb1ec91da74981",
  head_oid: "696a27a3be1fcd56efe70923dc0ce286a1c41c6d",
  tree_oid: "5279cae1daa1fbff3437b673df8ca231fb07c91f"
});

export function validatePlan93Authorization(authorization, scope, pathSet) {
  if (!authorization || typeof authorization !== "object" || Array.isArray(authorization) ||
      !validatePlan93PathSet(pathSet) || !validateReadScope(scope, scope?.sha256, pathSet)) return false;
  const keys = "attempt_id,candidate,contract_sha256,decision,path_set_sha256,schema,scope_sha256,sha256";
  if (Object.keys(authorization).sort().join(",") !== keys ||
      authorization.schema !== "crosswake-plan93-read-authorization/v1" ||
      authorization.decision !== "ALLOW" ||
      authorization.attempt_id !== scope.attempt_id ||
      authorization.path_set_sha256 !== pathSet.sha256 ||
      authorization.scope_sha256 !== scope.sha256 ||
      authorization.contract_sha256 !== CONTRACT_SHA256 ||
      canonical(authorization.candidate) !== canonical(PLAN93_CANDIDATE)) return false;
  const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(authorization).filter(([key]) => key !== "sha256")))).digest("hex");
  return authorization.sha256 === digest;
}

export function validatePlan97Authorization(authorization, scope, pathSet) {
  if (!authorization || typeof authorization !== "object" || Array.isArray(authorization) ||
      !validatePlan97ReadScope(scope, scope?.sha256, pathSet)) return false;
  const keys = "attempt_id,candidate,contract_sha256,decision,path_set_sha256,schema,scope_sha256,sha256";
  if (Object.keys(authorization).sort().join(",") !== keys ||
      authorization.schema !== "crosswake-plan97-read-authorization/v1" ||
      authorization.decision !== "ALLOW" || authorization.attempt_id !== scope.attempt_id ||
      authorization.path_set_sha256 !== pathSet.sha256 || authorization.scope_sha256 !== scope.sha256 ||
      authorization.contract_sha256 !== CONTRACT_SHA256 ||
      canonical(authorization.candidate) !== canonical(PLAN94_CANDIDATE)) return false;
  const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(authorization).filter(([key]) => key !== "sha256")))).digest("hex");
  return authorization.sha256 === digest;
}

export function validateReadScope(scope, suppliedDigest, pathSet) {
  if (pathSet?.schema === "crosswake-plan94-path-set/v1") {
    return validatePlan94ReadScope(scope, suppliedDigest, pathSet);
  }
  if (pathSet?.schema === "crosswake-plan95-path-set/v1") {
    return validatePlan95ReadScope(scope, suppliedDigest, pathSet);
  }
  if (pathSet?.schema === "crosswake-plan97-path-set/v1") {
    return validatePlan97ReadScope(scope, suppliedDigest, pathSet);
  }
  if (pathSet?.schema === "crosswake-plan93-path-set/v1") {
    if (!contractValid() || !validatePlan93PathSet(pathSet) || !scope || typeof scope !== "object" || Array.isArray(scope)) return false;
    const expectedKeys = "attempt_id,candidate,contract,contract_sha256,history_manifest_sha256,path_set_sha256,purpose,read_intent,request_count,schema,scope_path,sha256,signal_sha256,status";
    if (Object.keys(scope).sort().join(",") !== expectedKeys ||
        scope.schema !== "crosswake-plan93-read-scope/v1" || scope.attempt_id !== pathSet.attempt_id ||
        scope.path_set_sha256 !== pathSet.sha256 || scope.history_manifest_sha256 !== pathSet.history_manifest_sha256 ||
        scope.status !== "PENDING" || scope.request_count !== 0 || scope.read_intent !== false ||
        scope.scope_path !== `${pathSet.evidence_root}/${pathSet.files.read_scope}` ||
        scope.purpose !== "one fresh v0.2.7 exact-candidate read-only preflight" ||
        scope.contract_sha256 !== CONTRACT_SHA256 || canonical(scope.contract) !== canonical(CONTRACT) ||
        canonical(scope.candidate) !== canonical(PLAN93_CANDIDATE) ||
        scope.signal_sha256 !== "b89e06c0b739dae6da6f77f1015d1df476987bfa7b4964ab2ea6cc7ea78746e2") return false;
    const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(scope).filter(([key]) => key !== "sha256")))).digest("hex");
    return scope.sha256 === digest && suppliedDigest === digest;
  }
  if (pathSet) {
    if (!contractValid() || !validatePathSet(pathSet) || !scope || typeof scope !== "object" || Array.isArray(scope)) return false;
    const expectedKeys = "attempt_id,candidate,contract,contract_sha256,path_set_sha256,purpose,request_count,schema,scope_path,sha256,status";
    if (Object.keys(scope).sort().join(",") !== expectedKeys ||
        scope.schema !== "crosswake-plan92-read-scope/v1" || scope.attempt_id !== pathSet.attempt_id ||
        scope.path_set_sha256 !== pathSet.sha256 || scope.status !== "PENDING" || scope.request_count !== 0 ||
        scope.scope_path !== `${pathSet.evidence_root}/${pathSet.files.read_scope}` ||
        scope.contract_sha256 !== CONTRACT_SHA256 || canonical(scope.contract) !== canonical(CONTRACT) ||
        canonical(scope.candidate) !== canonical({
          version: "0.2.7",
          base_oid: "e51698528dc667ef89beb951e4eb1ec91da74981",
          head_oid: "696a27a3be1fcd56efe70923dc0ce286a1c41c6d",
          tree_oid: "5279cae1daa1fbff3437b673df8ca231fb07c91f"
        })) return false;
    const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(scope).filter(([key]) => key !== "sha256")))).digest("hex");
    return scope.sha256 === digest && suppliedDigest === digest;
  }
  if (!contractValid() || !scope || typeof scope !== "object" || Array.isArray(scope)) return false;
  const expectedKeys = "attempt_id,contract,contract_sha256,purpose,request_count,schema,scope_path,sha256,status";
  if (Object.keys(scope).sort().join(",") !== expectedKeys ||
      scope.schema !== "crosswake-plan87-read-scope/v2" ||
      !/^[0-9a-f]{32}$/.test(scope.attempt_id ?? "") || scope.status !== "PENDING" ||
      scope.request_count !== 0 || scope.purpose !== CONTRACT.purpose ||
      scope.scope_path !== ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan87-tag-026-read-scope.json" ||
      scope.contract_sha256 !== CONTRACT_SHA256 || canonical(scope.contract) !== canonical(CONTRACT)) return false;
  const digest = createHash("sha256").update(canonical(Object.fromEntries(Object.entries(scope).filter(([key]) => key !== "sha256")))).digest("hex");
  return scope.sha256 === digest && suppliedDigest === digest;
}

export function createOperationJournal(root, attemptId, scopeSha256, { reserved = false, pathSet, scope, authorization } = {}) {
  if (!/^[0-9a-f]{32}$/.test(attemptId ?? "") || !/^[0-9a-f]{64}$/.test(scopeSha256 ?? "")) {
    throw new TypeError("invalid operation journal binding");
  }
  const directory = resolve(root);
  const plan93 = pathSet?.schema === "crosswake-plan93-path-set/v1";
  const plan94 = pathSet?.schema === "crosswake-plan94-path-set/v1";
  const plan95 = pathSet?.schema === "crosswake-plan95-path-set/v1";
  const plan97 = pathSet?.schema === "crosswake-plan97-path-set/v1";
  if (plan93 && (!validateReadScope(scope, scopeSha256, pathSet) ||
      !validatePlan93Authorization(authorization, scope, pathSet) || pathSet.attempt_id !== attemptId)) {
    throw new TypeError("invalid Plan93 authorization");
  }
  if (plan94 && (!validatePlan94ReadScope(scope, scopeSha256, pathSet) || pathSet.attempt_id !== attemptId)) {
    throw new TypeError("invalid Plan94 read scope");
  }
  if (plan95 && (!validatePlan95ReadScope(scope, scopeSha256, pathSet) || pathSet.attempt_id !== attemptId)) {
    throw new TypeError("invalid Plan95 read scope");
  }
  if (plan97 && (!validatePlan97ReadScope(scope, scopeSha256, pathSet) || pathSet.attempt_id !== attemptId ||
      !validatePlan97Authorization(authorization, scope, pathSet))) {
    throw new TypeError("invalid Plan97 authorization");
  }
  const journalName = plan93 || plan94 || plan95 || plan97
    ? pathSet.files.child_journal.replace("{scope_sha256}", scopeSha256)
    : `175-plan87-ops-${attemptId}-${scopeSha256}-child.jsonl`;
  const path = join(directory, journalName);
  const assertAuthorized = () => {
    if (plan93 && (!validateReadScope(scope, scopeSha256, pathSet) || !validatePlan93Authorization(authorization, scope, pathSet))) {
      throw new Error("Plan93 authorization invalid");
    }
    if (plan94 && !validatePlan94ReadScope(scope, scopeSha256, pathSet)) throw new Error("Plan94 scope invalid");
    if (plan95 && !validatePlan95ReadScope(scope, scopeSha256, pathSet)) throw new Error("Plan95 scope invalid");
    if (plan97 && (!validatePlan97ReadScope(scope, scopeSha256, pathSet) || !validatePlan97Authorization(authorization, scope, pathSet))) throw new Error("Plan97 authorization invalid");
  };
  let sequence = 0;
  let operationSequence = 0;
  let bytes = 0;
  let initial;
  if (reserved) {
    const stat = lstatSync(path);
    if (!stat.isFile() || stat.size !== 0) throw new Error("reserved operation journal invalid");
    initial = openSync(path, "a");
  } else {
    initial = openSync(path, "wx");
  }
  fsyncSync(initial);
  closeSync(initial);

  return Object.freeze({
    path,
    assertAuthorized,
    newOperationId(operation) {
      if (!readContract.operation_accounting.child_operations.includes(operation)) throw new Error("operation journal event invalid");
      operationSequence += 1;
      return `${operation}-${attemptId}-${operationSequence}`;
    },
    append(operationId, operation, state, status) {
      assertAuthorized();
      const allowed = readContract.operation_accounting;
      if (!allowed.child_operations.includes(operation) ||
          !["intent", "invoked", "response_observed", "completed", "failed", "unknown", "fetch_rejected", "timeout", "malformed_json", "invalid_response", "oversized_response", "spawn_failed", "nonzero_exit", "invalid_output", "interrupted"].includes(state) ||
          !["UNKNOWN", "RESPONSE_OBSERVED", "FAILURE_OBSERVED", "SPAWN_OBSERVED", "EXIT_OBSERVED", "FETCH_REJECTED", "TIMEOUT", "MALFORMED_JSON", "INVALID_RESPONSE", "RESPONSE_TOO_LARGE", "SPAWN_FAILURE", "NONZERO_EXIT", "INVALID_OUTPUT", "INTERRUPTED"].includes(status) && !/^HTTP_[1-5][0-9]{2}$/.test(status) ||
          sequence >= allowed.max_events) throw new Error("operation journal event invalid");
      const event = {
        attempt_id: attemptId,
        scope_sha256: scopeSha256,
        sequence: sequence + 1,
        operation_id: operationId,
        operation,
        state,
        status
      };
      const line = JSON.stringify(event) + "\n";
      if (bytes + Buffer.byteLength(line, "utf8") > allowed.max_journal_bytes) {
        throw new Error("operation journal limit");
      }
      let fd;
      try {
        fd = openSync(path, "a");
        appendFileSync(fd, line, "utf8");
        fsyncSync(fd);
        bytes += Buffer.byteLength(line, "utf8");
        sequence += 1;
      } finally {
        if (fd !== undefined) closeSync(fd);
      }
      return event.sequence;
    }
  });
}

function fail(code) {
  return { ok: false, code };
}

function allowedRoute(method, pathname, authority = "CREATE_REF") {
  const parsed = new URL(pathname, API_ORIGIN);
  if (parsed.origin !== API_ORIGIN) return false;
  if (method === "GET") {
    const fixed = new Set([
      SOURCE + "/git/ref/tags/ios-core-v0.2.6",
      MIRROR + "/git/ref/heads/main",
      MIRROR + "/git/ref/tags/v0.2.5",
      MIRROR + "/git/ref/tags/v0.2.6",
      SOURCE + "/pulls/219",
      MIRROR + "/rulesets"
    ]).has(parsed.pathname) || new RegExp("^" + SOURCE + "/git/commits/[0-9a-f]{40}$").test(parsed.pathname);
    const tagObjectPath = new RegExp("^" + SOURCE + "/git/tags/[0-9a-f]{40}$");
    const mirrorCommitPath = new RegExp("^" + MIRROR + "/git/commits/[0-9a-f]{40}$");
    const permissionPath = new RegExp("^" + MIRROR + "/collaborators/[A-Za-z0-9-]{1,39}/permission$");
    const expanded = fixed || tagObjectPath.test(parsed.pathname) || mirrorCommitPath.test(parsed.pathname) ||
      permissionPath.test(parsed.pathname) || parsed.pathname === "/user";
    if (!expanded) return false;
    if (parsed.pathname === MIRROR + "/rulesets") {
      const page = parsed.searchParams.get("page");
      const perPage = parsed.searchParams.get("per_page");
      return parsed.searchParams.size === 2 && /^[1-9][0-9]*$/.test(page ?? "") &&
        Number(page) <= MAX_PAGES && perPage === "100";
    }
    return parsed.search === "";
  }

  return authority === "CREATE_REF" && method === "POST" && parsed.pathname === MIRROR + "/git/refs" &&
    parsed.search === "";
}

function allowedPlan94Route(method, pathname) {
  if (method !== "GET") return false;
  const parsed = new URL(pathname, API_ORIGIN);
  if (parsed.origin !== API_ORIGIN || parsed.search !== "") return false;
  return new Set([
    SOURCE + "/git/ref/tags/ios-core-v0.2.6",
    MIRROR + "/git/ref/heads/main",
    MIRROR + "/git/ref/tags/v0.2.5",
    MIRROR + "/git/ref/tags/v0.2.6",
    SOURCE + "/pulls/219"
  ]).has(parsed.pathname) ||
    new RegExp("^" + SOURCE + "/git/commits/[0-9a-f]{40}$").test(parsed.pathname) ||
    new RegExp("^" + SOURCE + "/git/tags/[0-9a-f]{40}$").test(parsed.pathname) ||
    new RegExp("^" + MIRROR + "/git/commits/[0-9a-f]{40}$").test(parsed.pathname);
}

function allowedPlan97Route(method, pathname) {
  return allowedPlan94Route(method, pathname);
}

export function isPlan94RouteAllowed(method, pathname) {
  return allowedPlan94Route(method, pathname);
}

function safeRefResult(status, body, ref) {
  if (status === 404) return { ok: true, status, state: "ABSENT" };
  if (status < 200 || status >= 300 || !body || typeof body !== "object") {
    return fail("RESPONSE_UNAVAILABLE");
  }

  const responseRef = typeof body.ref === "string" ? body.ref : null;
  const oid = body.object && typeof body.object.sha === "string" ? body.object.sha : null;
  if (responseRef !== ref || !/^[0-9a-f]{40}$/.test(oid ?? "")) {
    return fail("RESPONSE_INVALID");
  }
  return {
    ok: true,
    status,
    state: "PRESENT",
    ref: responseRef,
    oid,
    objectType: typeof body.object.type === "string" ? body.object.type : "UNKNOWN"
  };
}

export function createTransport({ token, fetchImpl = globalThis.fetch, timeoutMs = MAX_TIMEOUT_MS, authority = "CREATE_REF", scope, scopeSha256, pathSet, authorization, journal } = {}) {
  if (!(["READ", "CREATE_REF"].includes(authority)) || (authority === "READ" && !validateReadScope(scope, scopeSha256, pathSet))) {
    throw new TypeError("invalid read scope");
  }
  if (authority === "READ" && pathSet?.schema === "crosswake-plan93-path-set/v1" && !validatePlan93Authorization(authorization, scope, pathSet)) {
    throw new TypeError("invalid authorization");
  }
  if (authority === "READ" && pathSet?.schema === "crosswake-plan97-path-set/v1" && !validatePlan97Authorization(authorization, scope, pathSet)) {
    throw new TypeError("invalid authorization");
  }
  if (typeof fetchImpl !== "function" || !Number.isInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > MAX_TIMEOUT_MS) {
    throw new TypeError("invalid transport configuration");
  }
  if (journal && authority !== "READ") throw new TypeError("operation accounting is READ-only");

  let requestCount = 0;
  async function request(method, pathname, body) {
    if (authority === "READ" && !validateReadScope(scope, scopeSha256, pathSet)) return fail("SCOPE_INVALID");
    if (authority === "READ" && pathSet?.schema === "crosswake-plan93-path-set/v1" && !validatePlan93Authorization(authorization, scope, pathSet)) return fail("AUTHORIZATION_INVALID");
    if (authority === "READ" && pathSet?.schema === "crosswake-plan97-path-set/v1" && !validatePlan97Authorization(authorization, scope, pathSet)) return fail("AUTHORIZATION_INVALID");
    if (["crosswake-plan94-path-set/v1", "crosswake-plan95-path-set/v1"].includes(pathSet?.schema) &&
        !allowedPlan94Route(method, pathname)) return fail("ROUTE_NOT_ALLOWED");
    if (pathSet?.schema === "crosswake-plan97-path-set/v1" &&
        (!validatePlan97Authorization(authorization, scope, pathSet) || !allowedPlan97Route(method, pathname))) return fail("ROUTE_NOT_ALLOWED");
    if (!allowedRoute(method, pathname, authority) || (authority === "READ" && method !== "GET")) return fail("ROUTE_NOT_ALLOWED");
    if (requestCount >= limits.maxRequests) return fail("REQUEST_LIMIT");
    requestCount += 1;
    if (method === "POST") {
      if (!body || Object.keys(body).sort().join(",") !== "ref,sha" || body.ref !== TARGET_REF ||
          !/^[0-9a-f]{40}$/.test(body.sha ?? "")) return fail("REQUEST_INVALID");
    } else if (body !== undefined) {
      return fail("REQUEST_INVALID");
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    let operationId;
    let invoked = false;
    let responseObserved = false;
    let response;
    let bytes;
    try {
      operationId = journal?.newOperationId("api_fetch");
      journal?.append(operationId, "api_fetch", "intent", "UNKNOWN");
      journal?.assertAuthorized?.();
      const pending = fetchImpl(API_ORIGIN + pathname, {
        method,
        headers: {
          accept: "application/vnd.github+json",
          "x-github-api-version": API_VERSION,
          ...(token ? { authorization: "Bearer " + token } : {}),
          ...(method === "POST" ? { "content-type": "application/json" } : {})
        },
        ...(body === undefined ? {} : { body: JSON.stringify(body) }),
        redirect: "error",
        signal: controller.signal
      });
      invoked = true;
      journal?.append(operationId, "api_fetch", "invoked", "UNKNOWN");
      response = await pending;
      responseObserved = true;
      const responseStatus = Number.isInteger(response?.status) && response.status >= 100 && response.status <= 599
        ? `HTTP_${response.status}` : "INVALID_RESPONSE";
      journal?.append(operationId, "api_fetch", responseStatus === "INVALID_RESPONSE" ? "invalid_response" : "response_observed", responseStatus);
      if (responseStatus === "INVALID_RESPONSE") return fail("RESPONSE_INVALID");
      const reader = response.body?.getReader?.();
      if (reader) {
        const chunks = [];
        let size = 0;
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          size += value.byteLength;
          if (size > MAX_RESPONSE_BYTES) {
            await reader.cancel().catch(() => {});
            journal?.append(operationId, "api_fetch", "oversized_response", "RESPONSE_TOO_LARGE");
            return fail("RESPONSE_TOO_LARGE");
          }
          chunks.push(value);
        }
        bytes = Buffer.concat(chunks.map((chunk) => Buffer.from(chunk))).toString("utf8");
      } else {
        bytes = await response.text();
        if (Buffer.byteLength(bytes, "utf8") > MAX_RESPONSE_BYTES) {
          journal?.append(operationId, "api_fetch", "oversized_response", "RESPONSE_TOO_LARGE");
          return fail("RESPONSE_TOO_LARGE");
        }
      }
    } catch {
      if (!invoked) return fail("ACCOUNTING_UNAVAILABLE");
      try {
        const state = controller.signal.aborted ? "timeout" : responseObserved ? "failed" : "fetch_rejected";
        const status = controller.signal.aborted ? "TIMEOUT" : responseObserved ? "FAILURE_OBSERVED" : "FETCH_REJECTED";
        journal?.append(operationId, "api_fetch", state, status);
      } catch { return fail("ACCOUNTING_UNAVAILABLE"); }
      return fail("REQUEST_UNKNOWN");
    } finally {
      clearTimeout(timer);
    }

    let parsed = null;
    if (bytes !== "") {
      try {
        parsed = JSON.parse(bytes);
      } catch {
        journal?.append(operationId, "api_fetch", "malformed_json", "MALFORMED_JSON");
        return fail("RESPONSE_INVALID");
      }
    }
    const result = { ok: true, status: response.status, body: parsed };
    journal?.append(operationId, "api_fetch", "completed", "RESPONSE_OBSERVED");
    return result;
  }

  return Object.freeze({
    async readSourceTag() {
      const result = await request("GET", SOURCE + "/git/ref/tags/ios-core-v0.2.6");
      const safe = result.ok ? safeRefResult(result.status, result.body, "refs/tags/ios-core-v0.2.6") : result;
      return safe.state === "ABSENT" ? fail("SOURCE_REF_UNAVAILABLE") : safe;
    },
    async readMirrorMain() {
      const result = await request("GET", MIRROR + "/git/ref/heads/main");
      const safe = result.ok ? safeRefResult(result.status, result.body, "refs/heads/main") : result;
      return safe.state === "ABSENT" ? fail("MIRROR_REF_UNAVAILABLE") : safe;
    },
    async readMirrorPriorTag() {
      const result = await request("GET", MIRROR + "/git/ref/tags/v0.2.5");
      const safe = result.ok ? safeRefResult(result.status, result.body, "refs/tags/v0.2.5") : result;
      return safe.state === "ABSENT" ? fail("MIRROR_REF_UNAVAILABLE") : safe;
    },
    async readTargetRef() {
      const result = await request("GET", MIRROR + "/git/ref/tags/v0.2.6");
      return result.ok ? safeRefResult(result.status, result.body, TARGET_REF) : result;
    },
    async readPullRequest() {
      const result = await request("GET", SOURCE + "/pulls/219");
      if (!result.ok || result.status < 200 || result.status >= 300 || !result.body) return fail("RESPONSE_UNAVAILABLE");
      const pr = result.body;
      const head = pr.head?.sha;
      const base = pr.base?.sha;
      if (pr.number !== 219 || !["open", "closed"].includes(pr.state) ||
          !/^[0-9a-f]{40}$/.test(head ?? "") || !/^[0-9a-f]{40}$/.test(base ?? "") ||
          typeof head !== "string") return fail("RESPONSE_INVALID");
      const commit = await request("GET", SOURCE + "/git/commits/" + head);
      const tree = commit.ok && commit.status >= 200 && commit.status < 300
        ? commit.body?.tree?.sha
        : null;
      if (!/^[0-9a-f]{40}$/.test(tree ?? "")) return fail("RESPONSE_INVALID");
      return { ok: true, status: result.status, number: 219, state: pr.state.toUpperCase(), head, base, tree };
    },
    async readPlan94PullRequest() {
      const result = await request("GET", SOURCE + "/pulls/219");
      if (!result.ok || result.status < 200 || result.status >= 300 || !result.body) return fail("RESPONSE_UNAVAILABLE");
      const pr = result.body;
      const head = pr.head?.sha;
      const base = pr.base?.sha;
      if (pr.number !== 219 || !["open", "closed"].includes(pr.state) ||
          !/^[0-9a-f]{40}$/.test(head ?? "") || !/^[0-9a-f]{40}$/.test(base ?? "")) return fail("RESPONSE_INVALID");
      const commit = await request("GET", SOURCE + "/git/commits/" + head);
      const tree = commit.ok && commit.status >= 200 && commit.status < 300 ? commit.body?.tree?.sha : null;
      if (!/^[0-9a-f]{40}$/.test(tree ?? "")) return fail("RESPONSE_INVALID");
      return { ok: true, status: result.status, number: 219, state: pr.state.toUpperCase(), head, base, tree,
        draft: pr.draft === true, merged: pr.merged === true || typeof pr.merged_at === "string" };
    },
    async peelSourceTag(oid) {
      if (!/^[0-9a-f]{40}$/.test(oid ?? "")) return fail("OBJECT_ID_INVALID");
      let current = oid;
      for (let depth = 0; depth < 6; depth += 1) {
        const result = await request("GET", SOURCE + "/git/tags/" + current);
        if (!result.ok || result.status < 200 || result.status >= 300 || !result.body?.object) {
          return fail("TAG_OBJECT_UNAVAILABLE");
        }
        const next = result.body.object.sha;
        const type = result.body.object.type;
        if (!/^[0-9a-f]{40}$/.test(next ?? "")) return fail("TAG_OBJECT_INVALID");
        if (type === "commit") return { ok: true, tagObject: oid, commit: next };
        if (type !== "tag") return fail("TAG_OBJECT_INVALID");
        current = next;
      }
      return fail("TAG_DEPTH_LIMIT");
    },
    async readMirrorCommit(oid) {
      if (!/^[0-9a-f]{40}$/.test(oid ?? "")) return fail("OBJECT_ID_INVALID");
      const result = await request("GET", MIRROR + "/git/commits/" + oid);
      if (!result.ok || result.status < 200 || result.status >= 300 ||
          result.body?.sha !== oid || !/^[0-9a-f]{40}$/.test(result.body?.tree?.sha ?? "")) {
        return fail("MIRROR_OBJECT_UNAVAILABLE");
      }
      return { ok: true, oid, tree: result.body.tree.sha };
    },
    async readActor() {
      const result = await request("GET", "/user");
      const login = result.ok && result.status >= 200 && result.status < 300
        ? result.body?.login
        : null;
      if (typeof login !== "string" || !/^[A-Za-z0-9-]{1,39}$/.test(login)) return fail("ACTOR_UNAVAILABLE");
      return { ok: true, login };
    },
    async readPermission(login) {
      if (typeof login !== "string" || !/^[A-Za-z0-9-]{1,39}$/.test(login)) return fail("ACTOR_INVALID");
      const result = await request("GET", MIRROR + "/collaborators/" + login + "/permission");
      const permission = result.ok && result.status >= 200 && result.status < 300
        ? result.body?.permission
        : null;
      if (!["admin", "write", "maintain", "triage", "read", "none"].includes(permission)) {
        return fail("PERMISSION_UNAVAILABLE");
      }
      return { ok: true, permission: permission.toUpperCase() };
    },
    async listRules(page) {
      if (!Number.isInteger(page) || page < 1 || page > MAX_PAGES) return fail("PAGE_LIMIT");
      const result = await request("GET", MIRROR + "/rulesets?page=" + page + "&per_page=100");
      if (!result.ok || result.status < 200 || result.status >= 300 || !Array.isArray(result.body)) {
        return fail("RESPONSE_UNAVAILABLE");
      }
      return {
        ok: true,
        status: result.status,
        page,
        complete: result.body.length < 100,
        rules: result.body.slice(0, 100).map((rule) => ({
          id: Number.isInteger(rule.id) ? rule.id : null,
          target: typeof rule.target === "string" ? rule.target : "UNKNOWN",
          enforcement: typeof rule.enforcement === "string" ? rule.enforcement : "UNKNOWN",
          include: Array.isArray(rule.conditions?.ref_name?.include)
            ? rule.conditions.ref_name.include.filter((v) => typeof v === "string").slice(0, 32)
            : [],
          exclude: Array.isArray(rule.conditions?.ref_name?.exclude)
            ? rule.conditions.ref_name.exclude.filter((v) => typeof v === "string").slice(0, 32)
            : [],
          ruleTypes: Array.isArray(rule.rules)
            ? rule.rules.map((v) => typeof v.type === "string" ? v.type : "UNKNOWN").slice(0, 32)
            : []
        }))
      };
    },
    async createTargetRef(sha) {
      const result = await request("POST", MIRROR + "/git/refs", { ref: TARGET_REF, sha });
      if (!result.ok || result.status !== 201) return fail(result.code ?? "CREATE_REJECTED");
      return safeRefResult(result.status, result.body, TARGET_REF);
    }
  });
}

export const limits = Object.freeze({
  maxResponseBytes: MAX_RESPONSE_BYTES,
  maxTimeoutMs: MAX_TIMEOUT_MS,
  maxPages: MAX_PAGES,
  maxRequests: 32,
  portTimeoutMs: 240000,
  maxPortOutputBytes: 32768,
  gitCloneTimeoutMs: 180000,
  gitFetchTimeoutMs: 60000,
  gitSplitTimeoutMs: 120000,
  gitOtherTimeoutMs: 20000,
  gitMaxBufferBytes: 8192,
  gitMaxStdoutBytes: 4096
});

export const contract = Object.freeze({ apiOrigin: API_ORIGIN, targetRef: TARGET_REF });
export const readContract = CONTRACT;

const GIT_STAGES = Object.freeze([
  "CLONE", "FETCH", "TAG_OBJECT", "SOURCE_COMMIT", "SOURCE_TREE",
  "PREFIX_TREE", "SUBTREE_SPLIT", "SPLIT_TREE", "SPLIT_OBJECT"
]);
const GIT_REASONS = Object.freeze([
  "SPAWN_FAILURE", "TIMEOUT", "INTERRUPTED", "NONZERO_EXIT", "INVALID_OUTPUT", "UNKNOWN"
]);
const GIT_FAILURE_METADATA = new WeakMap();

function gitFailure(reason) {
  const safeReason = GIT_REASONS.includes(reason) ? reason : "UNKNOWN";
  const error = new Error("GIT_OPERATION_FAILED");
  error.reason = safeReason;
  GIT_FAILURE_METADATA.set(error, { reason: safeReason });
  return error;
}

function stagedGitFailure(stage, reason) {
  const error = gitFailure(reason);
  const safeStage = GIT_STAGES.includes(stage) ? stage : "UNKNOWN";
  error.stage = safeStage;
  GIT_FAILURE_METADATA.set(error, { stage: safeStage, reason: error.reason });
  return error;
}

export function projectGitFailure(error) {
  const metadata = error && typeof error === "object" ? GIT_FAILURE_METADATA.get(error) : undefined;
  return {
    stage: GIT_STAGES.includes(metadata?.stage) ? metadata.stage : "UNKNOWN",
    reason: GIT_REASONS.includes(metadata?.reason) ? metadata.reason : "UNKNOWN"
  };
}

export function git(args, cwd, timeout = 20000, journal, spawnImpl = spawnSync) {
  const operationId = journal?.newOperationId("git_spawn");
  journal?.append(operationId, "git_spawn", "intent", "UNKNOWN");
  let result;
  try {
    journal?.assertAuthorized?.();
    result = spawnImpl("git", args, {
    cwd,
    encoding: "utf8",
    timeout,
    maxBuffer: 8192,
    windowsHide: true,
    shell: false,
    env: {
      PATH: process.env.PATH ?? "/usr/bin:/bin",
      HOME: tmpdir(),
      GIT_TERMINAL_PROMPT: "0",
      GIT_CONFIG_NOSYSTEM: "1",
      GIT_CONFIG_GLOBAL: "/dev/null",
      GIT_CONFIG_COUNT: "1",
      GIT_CONFIG_KEY_0: "core.hooksPath",
      GIT_CONFIG_VALUE_0: "/dev/null"
    }
    });
    journal?.append(operationId, "git_spawn", "invoked", "SPAWN_OBSERVED");
  } catch {
    journal?.append(operationId, "git_spawn", "invoked", "SPAWN_OBSERVED");
    journal?.append(operationId, "git_spawn", "spawn_failed", "SPAWN_FAILURE");
    throw gitFailure("SPAWN_FAILURE");
  }
  if (!result || typeof result !== "object") {
    journal?.append(operationId, "git_spawn", "invalid_output", "INVALID_OUTPUT");
    throw gitFailure("INVALID_OUTPUT");
  }
  if (result.error) {
    const timeout = result.error.code === "ETIMEDOUT";
    journal?.append(operationId, "git_spawn", timeout ? "timeout" : "spawn_failed", timeout ? "TIMEOUT" : "SPAWN_FAILURE");
    throw gitFailure(timeout ? "TIMEOUT" : "SPAWN_FAILURE");
  }
  if (result.status === null) {
    journal?.append(operationId, "git_spawn", "interrupted", "INTERRUPTED");
    throw gitFailure("INTERRUPTED");
  }
  if (!Number.isInteger(result.status)) {
    journal?.append(operationId, "git_spawn", "invalid_output", "INVALID_OUTPUT");
    throw gitFailure("INVALID_OUTPUT");
  }
  if (result.status !== 0) {
    journal?.append(operationId, "git_spawn", "nonzero_exit", "NONZERO_EXIT");
    throw gitFailure("NONZERO_EXIT");
  }
  if (result.stdout !== undefined && result.stdout !== null && typeof result.stdout !== "string") {
    journal?.append(operationId, "git_spawn", "invalid_output", "INVALID_OUTPUT");
    throw gitFailure("INVALID_OUTPUT");
  }
  if (Buffer.byteLength(result.stdout ?? "") > CONTRACT.git_bounds.max_stdout_bytes) {
    journal?.append(operationId, "git_spawn", "invalid_output", "INVALID_OUTPUT");
    throw gitFailure("INVALID_OUTPUT");
  }
  const output = (result.stdout ?? "").trim();
  if (output.length > CONTRACT.git_bounds.max_stdout_bytes) {
    journal?.append(operationId, "git_spawn", "invalid_output", "INVALID_OUTPUT");
    throw gitFailure("INVALID_OUTPUT");
  }
  journal?.append(operationId, "git_spawn", "completed", "EXIT_OBSERVED");
  return output;
}

async function snapshot(transport) {
  const [sourceTag, main, priorTag, target, pullRequest, actor] = await Promise.all([
    transport.readSourceTag(),
    transport.readMirrorMain(),
    transport.readMirrorPriorTag(),
    transport.readTargetRef(),
    transport.readPullRequest(),
    transport.readActor()
  ]);
  if (![sourceTag, main, priorTag, pullRequest, actor].every((value) => value.ok) ||
      !target.ok || !["ABSENT", "PRESENT"].includes(target.state)) throw new Error("SNAPSHOT_UNAVAILABLE");

  const permission = await transport.readPermission(actor.login);
  if (!permission.ok) throw new Error("PERMISSION_UNAVAILABLE");

  const rules = [];
  let complete = false;
  for (let page = 1; page <= MAX_PAGES; page += 1) {
    const result = await transport.listRules(page);
    if (!result.ok) throw new Error("POLICY_UNAVAILABLE");
    rules.push(...result.rules);
    if (result.complete) {
      complete = true;
      break;
    }
  }

  return {
    sourceTag,
    main,
    priorTag,
    target,
    pullRequest,
    actor: actor.login,
    permission: permission.permission,
    rules,
    rulesComplete: complete
  };
}

function matchesPattern(pattern, ref) {
  if (pattern === "~ALL" || pattern === "*") return true;
  if (typeof pattern !== "string" || pattern.length > 200) return true;
  const escaped = Array.from(pattern, (character) => {
    if (character === "*") return ".*";
    if (character === "?") return ".";
    if (".+^{}()|[]\\".includes(character)) return "\\" + character;
    return character;
  }).join("");
  try {
    return new RegExp("^" + escaped + "$").test(ref);
  } catch {
    return true;
  }
}

function tagRuleApplies(rule) {
  if (rule.target !== "tag" || rule.enforcement !== "active") return false;
  const included = rule.include.length === 0 || rule.include.some((pattern) => matchesPattern(pattern, TARGET_REF));
  const excluded = rule.exclude.some((pattern) => matchesPattern(pattern, TARGET_REF));
  return included && !excluded;
}

function runGitSplit(journal, gitImpl = git) {
  const clone = mkdtempSync(join(tmpdir(), "crosswake-plan87-"));
  const runStage = (stage, args, cwd, timeout) => {
    try {
      return gitImpl(args, cwd, timeout, journal);
    } catch (error) {
      const metadata = error && typeof error === "object" ? GIT_FAILURE_METADATA.get(error) : undefined;
      const reason = GIT_REASONS.includes(metadata?.reason) ? metadata.reason : "UNKNOWN";
      throw stagedGitFailure(stage, reason);
    }
  };
  const oid = (stage, value) => {
    if (!/^[0-9a-f]{40}$/.test(value ?? "")) throw stagedGitFailure(stage, "INVALID_OUTPUT");
    return value;
  };
  try {
    runStage("CLONE", ["clone", "--quiet", "--no-checkout", "--no-tags", CONTRACT.source_git_remote, clone], tmpdir(), CONTRACT.git_bounds.clone_timeout_ms);
    runStage("FETCH", ["-C", clone, "fetch", "--quiet", "--no-tags", "origin",
      CONTRACT.source_git_tag_ref + ":" + CONTRACT.source_git_tag_ref], tmpdir(), CONTRACT.git_bounds.fetch_timeout_ms);
    const sourceTagObject = oid("TAG_OBJECT", runStage("TAG_OBJECT", ["-C", clone, "rev-parse", CONTRACT.source_git_tag_ref], tmpdir(), 20000));
    const sourceCommit = oid("SOURCE_COMMIT", runStage("SOURCE_COMMIT", ["-C", clone, "rev-parse", CONTRACT.source_git_tag_ref + "^{}"], tmpdir(), 20000));
    const sourceTree = oid("SOURCE_TREE", runStage("SOURCE_TREE", ["-C", clone, "rev-parse", sourceCommit + "^{tree}"], tmpdir(), 20000));
    const prefixTree = oid("PREFIX_TREE", runStage("PREFIX_TREE", ["-C", clone, "rev-parse", sourceCommit + ":" + CONTRACT.subtree_prefix], tmpdir(), 20000));
    const splitOid = oid("SUBTREE_SPLIT", runStage("SUBTREE_SPLIT", ["-C", clone, "subtree", "split", "--quiet", "--prefix=" + CONTRACT.subtree_prefix, sourceCommit], tmpdir(), CONTRACT.git_bounds.split_timeout_ms));
    const splitTree = oid("SPLIT_TREE", runStage("SPLIT_TREE", ["-C", clone, "rev-parse", splitOid + "^{tree}"], tmpdir(), 20000));
    runStage("SPLIT_OBJECT", ["-C", clone, "cat-file", "-e", splitOid + "^{commit}"], tmpdir(), 20000);
    return { sourceTagObject, sourceCommit, sourceTree, prefixTree, splitOid, splitTree };
  } finally {
    rmSync(clone, { recursive: true, force: true });
  }
}

async function plan94Snapshot(transport) {
  const [sourceTag, main, priorTag, target, pullRequest] = await Promise.all([
    transport.readSourceTag(), transport.readMirrorMain(), transport.readMirrorPriorTag(),
    transport.readTargetRef(), transport.readPlan94PullRequest()
  ]);
  if (![sourceTag, main, priorTag, pullRequest].every((value) => value.ok) || !target.ok ||
      !["ABSENT", "PRESENT"].includes(target.state)) throw new Error("SNAPSHOT_UNAVAILABLE");
  return { sourceTag, main, priorTag, target, pullRequest };
}

export async function collectPlan94Facts(scope, scopeSha256, pathSet, journal, { fetchImpl = globalThis.fetch, gitImpl = git } = {}) {
  if (!validatePlan94ReadScope(scope, scopeSha256, pathSet)) return fail("SCOPE_INVALID");
  return collectPlanBoundFacts(scope, scopeSha256, pathSet, journal, { fetchImpl, gitImpl });
}

export async function collectPlan95Facts(scope, scopeSha256, pathSet, journal, { fetchImpl = globalThis.fetch, gitImpl = git } = {}) {
  if (!validatePlan95ReadScope(scope, scopeSha256, pathSet)) return fail("SCOPE_INVALID");
  return collectPlanBoundFacts(scope, scopeSha256, pathSet, journal, { fetchImpl, gitImpl });
}

export async function collectPlan97Facts(scope, scopeSha256, pathSet, authorization, journal, { fetchImpl = globalThis.fetch, gitImpl = git } = {}) {
  if (!validatePlan97Authorization(authorization, scope, pathSet)) return fail("AUTHORIZATION_INVALID");
  const transport = createTransport({ authority: "READ", scope, scopeSha256, pathSet, authorization, journal, fetchImpl });
  let before;
  try {
    before = await plan94Snapshot(transport);
  } catch {
    return fail("OBSERVATION_UNAVAILABLE");
  }
  const firstFacts = {
    source_tag_oid: before.sourceTag.oid,
    source_commit_oid: null,
    source_tree_oid: null,
    source_prefix_tree_oid: null,
    split_oid: null,
    split_tree_oid: null,
    local_object_present: null,
    mirror_object_present: null,
    mirror_main_oid: before.main.oid,
    mirror_prior_tag_oid: before.priorTag.oid,
    target_state: before.target.state,
    pr_number: before.pullRequest.number,
    pr_state: before.pullRequest.state,
    pr_draft: before.pullRequest.draft,
    pr_merged: before.pullRequest.merged,
    pr_base_oid: before.pullRequest.base,
    pr_head_oid: before.pullRequest.head,
    pr_tree_oid: before.pullRequest.tree,
    observation_start: randomBytes(16).toString("hex"),
    observation_end: null
  };
  let source;
  try {
    source = runGitSplit(journal, gitImpl);
  } catch (error) {
    const diagnostic = projectGitFailure(error);
    if (diagnostic.stage === "UNKNOWN" || diagnostic.reason === "UNKNOWN") return fail("OBSERVATION_UNAVAILABLE");
    return {
      ok: true,
      facts: firstFacts,
      observation_scope: "FIRST_SNAPSHOT_ONLY",
      diagnostic
    };
  }
  if (source.sourceTagObject !== before.sourceTag.oid || source.prefixTree !== source.splitTree) return fail("SOURCE_SPLIT_MISMATCH");
  const mirrorObject = await transport.readMirrorCommit(source.splitOid);
  if (!mirrorObject.ok || mirrorObject.tree !== source.splitTree) return fail("MIRROR_OBJECT_UNAVAILABLE");
  let after;
  try {
    after = await plan94Snapshot(transport);
  } catch {
    return fail("OBSERVATION_UNAVAILABLE");
  }
  if (canonical(before) !== canonical(after)) return fail("OBSERVATIONS_CHANGED");
  return {
    ok: true,
    facts: {
      ...firstFacts,
      source_commit_oid: source.sourceCommit,
      source_tree_oid: source.sourceTree,
      source_prefix_tree_oid: source.prefixTree,
      split_oid: source.splitOid,
      split_tree_oid: source.splitTree,
      local_object_present: true,
      mirror_object_present: true,
      observation_end: randomBytes(16).toString("hex")
    },
    observation_scope: "MATCHING_PAIR",
    diagnostic: null
  };
}

async function collectPlanBoundFacts(scope, scopeSha256, pathSet, journal, { fetchImpl, gitImpl }) {
  const transport = createTransport({ authority: "READ", scope, scopeSha256, pathSet, journal, fetchImpl });
  const before = await plan94Snapshot(transport);
  const source = runGitSplit(journal, gitImpl);
  if (source.sourceTagObject !== before.sourceTag.oid || source.prefixTree !== source.splitTree) {
    throw new Error("SOURCE_SPLIT_MISMATCH");
  }
  const mirrorObject = await transport.readMirrorCommit(source.splitOid);
  if (!mirrorObject.ok || mirrorObject.tree !== source.splitTree) throw new Error("MIRROR_OBJECT_UNAVAILABLE");
  const after = await plan94Snapshot(transport);
  if (canonical(before) !== canonical(after)) throw new Error("OBSERVATIONS_CHANGED");

  const id = () => randomBytes(16).toString("hex");
  const pr = before.pullRequest;
  return {
    ok: true,
    facts: {
      source_tag_oid: source.sourceTagObject,
      source_commit_oid: source.sourceCommit,
      source_tree_oid: source.sourceTree,
      source_prefix_tree_oid: source.prefixTree,
      split_oid: source.splitOid,
      split_tree_oid: source.splitTree,
      local_object_present: true,
      mirror_object_present: true,
      mirror_main_oid: before.main.oid,
      mirror_prior_tag_oid: before.priorTag.oid,
      target_state: before.target.state,
      pr_number: pr.number,
      pr_state: pr.state,
      pr_draft: pr.draft,
      pr_merged: pr.merged,
      pr_base_oid: pr.base,
      pr_head_oid: pr.head,
      pr_tree_oid: pr.tree,
      observation_start: id(),
      observation_end: id()
    }
  };
}

async function collectFacts(token, scope, scopeSha256, pathSet, journal, authorization) {
  if (!token) return fail("CREDENTIAL_UNAVAILABLE");
  const transport = createTransport({ token, authority: "READ", scope, scopeSha256, pathSet, authorization, journal });
  const before = await snapshot(transport);
  const source = runGitSplit(journal);
  if (source.sourceTagObject !== before.sourceTag.oid) throw new Error("SOURCE_TAG_MISMATCH");
  const mirrorObject = await transport.readMirrorCommit(source.splitOid);
  if (!mirrorObject.ok || mirrorObject.tree !== source.splitTree) throw new Error("MIRROR_OBJECT_UNAVAILABLE");
  const after = await snapshot(transport);
  if (canonical(before) !== canonical(after)) throw new Error("OBSERVATIONS_CHANGED");

  const applicableTagRules = before.rules.filter(tagRuleApplies);
  const permissionAllowed = ["ADMIN", "WRITE", "MAINTAIN"].includes(before.permission);
  const ruleFactsComplete = before.rules.every((rule) =>
    Number.isInteger(rule.id) && ["branch", "tag"].includes(rule.target) &&
    ["active", "evaluate", "disabled"].includes(rule.enforcement)
  );
  const policyComplete = before.rulesComplete && ruleFactsComplete &&
    applicableTagRules.length === 0 && permissionAllowed;
  const policyDigest = createHash("sha256").update(canonical({
    rules: before.rules,
    permission: before.permission,
    applicableTagRules: applicableTagRules.map((rule) => rule.id)
  })).digest("hex");
  const id = () => randomBytes(16).toString("hex");
  return {
    ok: true,
    facts: {
      source_tag_oid: source.sourceTagObject,
      source_commit_oid: source.sourceCommit,
      source_tree_oid: source.sourceTree,
      source_prefix_tree_oid: source.prefixTree,
      split_oid: source.splitOid,
      split_tree_oid: source.splitTree,
      local_object_present: true,
      mirror_object_present: true,
      mirror_main_oid: before.main.oid,
      mirror_prior_tag_oid: before.priorTag.oid,
      target_state: before.target.state,
      pr_number: before.pullRequest.number,
      pr_state: before.pullRequest.state,
      pr_base_oid: before.pullRequest.base,
      pr_head_oid: before.pullRequest.head,
      pr_tree_oid: before.pullRequest.tree,
      policy_complete: policyComplete,
      policy_digest: policyDigest,
      write_permission: policyComplete ? "ALLOWED" : permissionAllowed ? "UNKNOWN" : "DENIED",
      observation_start: id(),
      observation_end: id()
    }
  };
}

async function dispatch(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) return fail("REQUEST_INVALID");
  if (input.operation === "plan97-collect") {
    if (Object.keys(input).sort().join(",") !== "authorization,operation,path_set,scope,scope_sha256") return fail("REQUEST_INVALID");
    if (!validatePlan97Authorization(input.authorization, input.scope, input.path_set)) return fail("AUTHORIZATION_INVALID");
    const accountingRoot = join(process.cwd(), input.path_set.evidence_root);
    const journal = createOperationJournal(accountingRoot, input.scope.attempt_id, input.scope_sha256, {
      reserved: true, pathSet: input.path_set, scope: input.scope, authorization: input.authorization
    });
    try {
      return await collectPlan97Facts(input.scope, input.scope_sha256, input.path_set, input.authorization, journal);
    } catch {
      return fail("OBSERVATION_UNAVAILABLE");
    }
  }
  if (input.operation === "plan95-collect") {
    if (Object.keys(input).sort().join(",") !== "operation,path_set,scope,scope_sha256") return fail("REQUEST_INVALID");
    if (!validatePlan95ReadScope(input.scope, input.scope_sha256, input.path_set)) return fail("SCOPE_INVALID");
    const accountingRoot = join(process.cwd(), input.path_set.evidence_root);
    const journal = createOperationJournal(accountingRoot, input.scope.attempt_id, input.scope_sha256, {
      reserved: true, pathSet: input.path_set, scope: input.scope
    });
    try {
      return await collectPlan95Facts(input.scope, input.scope_sha256, input.path_set, journal);
    } catch {
      return fail("OBSERVATION_UNAVAILABLE");
    }
  }
  if (input.operation === "plan94-collect") {
    if (Object.keys(input).sort().join(",") !== "operation,path_set,scope,scope_sha256") return fail("REQUEST_INVALID");
    if (!validatePlan94ReadScope(input.scope, input.scope_sha256, input.path_set)) return fail("SCOPE_INVALID");
    const accountingRoot = join(process.cwd(), input.path_set.evidence_root);
    const journal = createOperationJournal(accountingRoot, input.scope.attempt_id, input.scope_sha256, {
      reserved: true, pathSet: input.path_set, scope: input.scope
    });
    try {
      return await collectPlan94Facts(input.scope, input.scope_sha256, input.path_set, journal);
    } catch {
      return fail("OBSERVATION_UNAVAILABLE");
    }
  }
  if (input.operation === "plan93-collect") {
    const expected = "authorization,operation,path_set,scope,scope_sha256";
    const actual = Object.keys(input).sort().join(",");
    if (actual !== expected && actual !== "operation,path_set,scope,scope_sha256") return fail("REQUEST_INVALID");
    if (!validateReadScope(input.scope, input.scope_sha256, input.path_set)) return fail("SCOPE_INVALID");
    if (actual !== expected) return fail("AUTHORIZATION_INVALID");
    if (!validatePlan93Authorization(input.authorization, input.scope, input.path_set)) return fail("AUTHORIZATION_INVALID");
    const token = process.env.CROSSWAKE_PLAN87_READ_TOKEN;
    if (!token) return fail("CREDENTIAL_UNAVAILABLE");
    const accountingRoot = join(process.cwd(), input.path_set.evidence_root);
    const journal = createOperationJournal(accountingRoot, input.scope.attempt_id, input.scope_sha256, {
      reserved: true,
      pathSet: input.path_set,
      scope: input.scope,
      authorization: input.authorization
    });
    return collectFacts(token, input.scope, input.scope_sha256, input.path_set, journal, input.authorization);
  }
  if (input.operation === "collect" || input.operation === "recheck") {
    const legacy = Object.keys(input).sort().join(",") === "operation,scope,scope_sha256" &&
      validateReadScope(input.scope, input.scope_sha256);
    const pathBound = Object.keys(input).sort().join(",") === "operation,path_set,scope,scope_sha256" &&
      validateReadScope(input.scope, input.scope_sha256, input.path_set);
    if (!legacy && !pathBound) return fail("SCOPE_INVALID");
    const token = process.env.CROSSWAKE_PLAN87_READ_TOKEN;
    if (!token) return fail("CREDENTIAL_UNAVAILABLE");
    const accountingRoot = join(process.cwd(), ".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence");
    const journal = createOperationJournal(accountingRoot, input.scope.attempt_id, input.scope_sha256, {
      reserved: Boolean(input.path_set)
    });
    return collectFacts(token, input.scope, input.scope_sha256, input.path_set, journal);
  }
  if (input.operation === "create") {
    if (Object.keys(input).sort().join(",") !== "oid,operation,ref" || input.ref !== TARGET_REF) return fail("REQUEST_INVALID");
    const token = process.env.CROSSWAKE_PLAN87_WRITE_TOKEN;
    if (!token) return fail("CREDENTIAL_UNAVAILABLE");
    const result = await createTransport({ token }).createTargetRef(input.oid);
    return result.ok ? { ok: true, result: "CREATED" } : fail(result.code);
  }
  if (input.operation === "read") {
    if (Object.keys(input).length !== 1) return fail("REQUEST_INVALID");
    const token = process.env.CROSSWAKE_PLAN87_READ_TOKEN;
    if (!token) return fail("CREDENTIAL_UNAVAILABLE");
    const result = await createTransport({ token }).readTargetRef();
    return result.ok ? { ok: true, state: result.state, oid: result.oid ?? null } : fail(result.code);
  }
  return fail("OPERATION_NOT_ALLOWED");
}

async function main() {
  return await new Promise((resolveMain) => {
    let input = "";
    let completed = false;
    const finish = async (raw) => {
      if (completed) return;
      completed = true;
      process.stdin.pause();
      process.stdin.destroy();
      let result;
      try {
        result = await dispatch(JSON.parse(raw));
      } catch {
        result = fail("OPERATION_UNKNOWN");
      }
      process.stdout.write(JSON.stringify(result) + "\n", resolveMain);
    };
    process.stdin.on("data", (chunk) => {
      if (completed) return;
      input += chunk.toString("utf8");
      if (Buffer.byteLength(input, "utf8") > 8192) {
        completed = true;
        process.stdin.destroy();
        process.stdout.write(JSON.stringify(fail("INPUT_TOO_LARGE")) + "\n", resolveMain);
        return;
      }
      const newline = input.indexOf("\n");
      if (newline >= 0) {
        const raw = input.slice(0, newline).trim();
        if (input.slice(newline + 1).trim() !== "") {
          completed = true;
          process.stdin.destroy();
          process.stdout.write(JSON.stringify(fail("REQUEST_INVALID")) + "\n", resolveMain);
        } else {
          void finish(raw);
        }
      }
    });
    process.stdin.on("end", () => {
      if (input.trim() !== "") void finish(input.trim());
      else if (!completed) {
        completed = true;
        process.stdout.write(JSON.stringify(fail("REQUEST_INVALID")) + "\n", resolveMain);
      }
    });
  });
}

if (process.argv[1] && pathToFileURL(resolve(process.argv[1])).href === import.meta.url) {
  await main();
}
