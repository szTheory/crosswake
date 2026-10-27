#!/usr/bin/env node
/* Fixed argv, closed records, literal CI ownership, and redacted failures enforce D-01–D-06. */
import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";
import path from "node:path";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
export const STAGE_MAX_BUFFER_BYTES = 16 * 1024 * 1024;
const manifestPath = path.join(repoRoot, "script/repository_verification_stages.json");
const artifactPolicyPath = path.join(repoRoot, "script/repository_artifact_policy.json");
const workflowPath = path.join(repoRoot, ".github/workflows/crosswake-ci.yml");
const stageIds = ["repository-preflight", "root-proof", "example-host-proof", "browser-proof", "ios-package-proof", "android-package-proof", "format-proof", "warnings-proof", "repository-cleanliness"];
const manifestKeys = ["schema_version", "stages"];
const stageKeys = ["argv", "ci_owners", "cwd", "dependencies", "env", "owned_outputs", "remediation_command", "required_tools", "stage_id", "timeout_ms"];
const toolKeys = ["argv", "remediation_command", "tool", "version_regex"];
const ownerKeys = ["command", "job_id"];
const artifactPolicyKeys = ["schema_version", "ignored_transient", "intentionally_tracked", "generated_contracts", "forbidden_tracked", "safe_fixtures"];
const matcherKeys = ["kind", "value"];
const generatedContractKeys = ["canonical_source", "output_paths", "regeneration_argv", "remediation_command"];
export const BROWSER_DIAGNOSTIC_MODE = "phase167_post_412";
const browserDiagnosticJobs = ["e2e-proof", "route-tour-proof"];
const browserDiagnosticCategories = [
  "browser_assertion_failed",
  "browser_configuration_failed",
  "browser_process_error",
  "browser_process_exit_nonzero",
  "browser_process_signal",
  "browser_server_start_failed",
  "browser_test_timeout"
];
const browserDiagnosticKeys = ["category", "job", "owner", "schema_version"];
const exampleHostDiagnosticSeeds = new Set([17, 101, 1009]);
const exampleHostDiagnosticClasses = new Set(["tagged", "complete"]);
const exampleHostDiagnosticKinds = ["command_failure", "owned_temp_residue", "tracked_path_residue"];
const exampleHostDiagnosticKeys = ["class", "exit_code", "kind", "owner", "schema_version", "seed"];
const pythonChildStageOwners = new Set(["root-proof", "example-host-proof"]);

export function spawnStage(command, args, options) {
  return spawnSync(command, args, {
    ...options,
    encoding: "utf8",
    maxBuffer: STAGE_MAX_BUFFER_BYTES
  });
}

export const ROOT_PROOF_TAIL_LINES = 150;
export const ROOT_PROOF_TAIL_BYTES = 24 * 1024;
const ROOT_PROOF_DETAIL_LINES = 120;
const ROOT_PROOF_DETAIL_BYTES = 16 * 1024;

// A credential value: a backslash-escaped double-quoted span (`\\"v\\"`, JSON inside a string), a double- or
// single-quoted span (backslash escapes honoured, masked to end of line when the quote is never closed)
// or an unquoted run of 3+ non-space, non-quote characters. An unquoted value that is exactly `nil`, `true`,
// `false`, `null` or `undefined` (any case, then whitespace, `,;)]}` or end of text) is a literal, not a secret,
// and stays readable; a longer value starting with one of those words is still masked. Groups are named so adding one cannot shift
// another. Unrolled loops with disjoint alternatives keep matching linear (no nested quantifier overlap).
const LITERAL_VALUE = `(?:${["nil", "true", "false", "null", "undefined"].map((w) => [...w].map((c) => `[${c}${c.toUpperCase()}]`).join("")).join("|")})`;
const SECRET_VALUE_SOURCE = String.raw`(?:(?<escOpen>\\+")(?<escBody>[^\\\n]*(?:\\(?!")[^\\\n]*)*)(?<escClose>(?:\\+")?)|"(?<dqBody>[^"\\\n]*(?:\\[^\n]?[^"\\\n]*)*)(?<dqClose>"?)|'(?<sqBody>[^'\\\n]*(?:\\[^\n]?[^'\\\n]*)*)(?<sqClose>'?)|(?<bare>(?!${LITERAL_VALUE}(?=[\s,;)\]}]|$))[^\s"']{3,}))`;

// Replacer for a (prefix, value) match built from SECRET_VALUE_SOURCE: quotes survive around `***`.
// The value groups are read by name from the trailing groups object; only the prefix is positional.
function maskValue(match, prefix, ...rest) {
  const g = rest[rest.length - 1];
  if (g.bare !== undefined) return `${prefix}***`;
  if (g.escOpen !== undefined) return `${prefix}${g.escOpen}***${g.escClose}`;
  if (g.dqBody !== undefined) return `${prefix}"***${g.dqClose}`;
  return `${prefix}'***${g.sqClose}`;
}

// Optional quote after a key: a plain quote or a backslash-escaped one (key inside an escaped JSON string).
const KEY_QUOTE = String.raw`(?:\\*["'])?`;

// Credential vocabulary shared by the generic, tuple, CLI-flag and next-line rules. `authorization` carries a
// left boundary so `preauthorization` is not a credential key (an underscore or hyphen before it still is).
const CREDENTIAL_WORDS = String.raw`tokens?|secret[_-]key[_-]base|secret[_-]key|secrets?|passwords?|passwd|passphrase|api[_-]?key|private[_-]?key|credentials?|cookies?|(?<![A-Za-z0-9])authorization`;

// These workflow names are credential-bearing even though their spelling does not contain a
// credential family word. Keep only reviewed identifiers here; workflow YAML is inventory input
// for tests and is never read by the diagnostic path.
const REVIEWED_CREDENTIAL_IDENTIFIER_ALIASES = new Set([
  "CROSSWAKE_PLAY_BILLING_SANDBOX_READY",
  "CROSSWAKE_STOREKIT_SANDBOX_READY",
  "MAVEN_USERNAME",
  "ORG_GRADLE_PROJECT_MAVENCENTRALUSERNAME"
]);
const CREDENTIAL_FAMILY_TOKENS = new Set(["token", "secret", "password", "passwd", "passphrase", "credential", "cookie", "authorization"]);
const KEY_QUALIFIER_TOKENS = new Set(["api", "auth", "access", "private", "deploy", "signing", "memory"]);
const CREDENTIAL_METADATA_SUFFIXES = new Set(["count", "length", "size"]);
function credentialIdentifierTokens(identifier) {
  return String(identifier)
    .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1 $2")
    .split(/[^A-Za-z0-9]+/)
    .filter(Boolean)
    .map((token) => token.toLowerCase());
}

function isCredentialIdentifier(identifier) {
  if (REVIEWED_CREDENTIAL_IDENTIFIER_ALIASES.has(String(identifier).replace(/[^A-Za-z0-9]/g, "_").toUpperCase())) return true;
  const tokens = credentialIdentifierTokens(identifier);
  if (CREDENTIAL_METADATA_SUFFIXES.has(tokens.at(-1))) return false;
  if (tokens.some((token) => CREDENTIAL_FAMILY_TOKENS.has(token) || CREDENTIAL_FAMILY_TOKENS.has(token.replace(/s$/, "")))) return true;
  return tokens.includes("key") && tokens.some((token) => KEY_QUALIFIER_TOKENS.has(token));
}

// Broad identifier capture followed by a value is classified structurally. The lookahead after
// the separator makes a failed short bare value disjoint from the whitespace scan.
const STRUCTURAL_CREDENTIAL_RULE = new RegExp(
  `((?<![A-Za-z0-9_-])(?<identifier>[A-Za-z_][A-Za-z0-9_-]*)[ \\t]*(?:=>|[:=]{1,3})[ \\t]*(?=\\S))${SECRET_VALUE_SOURCE}`,
  "gi"
);
const STRUCTURAL_KEY_LINE = new RegExp(
  `(?<![A-Za-z0-9_-])(?<identifier>[A-Za-z_][A-Za-z0-9_-]*)[ \\t]*(?:=>|[:=])[ \\t]*(?:(?:[|>][+-]?[0-9]?[+-]?)[ \\t]*)?\\r?$`,
  "i"
);

function maskStructuralCredential(match, prefix, identifier, ...rest) {
  if (!isCredentialIdentifier(identifier)) return match;
  return maskValue(match, prefix, rest[rest.length - 1]);
}

const CREDENTIAL_ASSIGNMENT_PREFIX = /(?<![A-Za-z0-9_-])(?:(?<quote>["'])(?<quotedIdentifier>[A-Za-z_][A-Za-z0-9_-]*)\k<quote>|(?<identifier>[A-Za-z_][A-Za-z0-9_-]*))[ \t]*(?:=>|[:=]{1,3})[ \t]*/g;
const CREDENTIAL_TUPLE_PREFIX = /\{[ \t]*(?::(?<atom>[A-Za-z0-9_-]+)|(?<quote>["'])(?<quoted>[A-Za-z0-9_-]+)\k<quote>)[ \t]*,[ \t]*/g;
const STRUCTURAL_TUPLE_KEY_LINE = /^\s*\{\s*(?::(?<atom>[A-Za-z0-9_-]+)|(?:"(?<double>[A-Za-z0-9_-]+)"|'(?<single>[A-Za-z0-9_-]+)'))\s*,\s*$/;

function readQuotedValueEnd(text, start) {
  let quoteAt = start;
  while (text[quoteAt] === "\\") quoteAt += 1;
  const quote = text[quoteAt];
  if (quote !== "'" && quote !== '"') return null;
  let i = quoteAt + 1;
  while (i < text.length) {
    if (text[i] === "\\") { i += 2; continue; }
    if (text[i] === quote) {
      let closeStart = i;
      while (closeStart > quoteAt + 1 && text[closeStart - 1] === "\\") closeStart -= 1;
      return { end: i + 1, replacement: `${text.slice(start, quoteAt + 1)}***${text.slice(closeStart, i + 1)}` };
    }
    i += 1;
  }
  let end = text.indexOf("\n", start);
  if (end < 0) end = text.length;
  return { end, replacement: `${text.slice(start, quoteAt + 1)}***` };
}

function skipQuotedSpan(text, start) {
  const quote = text[start];
  let i = start + 1;
  while (i < text.length) {
    if (text[i] === "\\") { i += 2; continue; }
    if (text[i] === quote) return i + 1;
    i += 1;
  }
  return -1;
}

function readContainerStart(text, start) {
  if (text.startsWith("%{", start) || text.startsWith("#{", start)) return { prefix: text.slice(start, start + 2), opener: "{", openAt: start + 1 };
  if (text.startsWith("<<", start)) return { prefix: "<<", opener: "<<", openAt: start };
  const paired = { "{": "}", "[": "]", "(": ")" };
  if (Object.hasOwn(paired, text[start])) return { prefix: text[start], opener: text[start], openAt: start };
  if (text[start] === "~" && /[A-Za-z]/.test(text[start + 1] ?? "")) {
    const delimiterAt = start + 2;
    const delimiter = text[delimiterAt];
    const sigilClosers = { "{": "}", "[": "]", "(": ")", "<": ">", "|": "|", "/": "/", "'": "'", '"': '"' };
    if (Object.hasOwn(sigilClosers, delimiter)) return { prefix: text.slice(start, delimiterAt + 1), opener: delimiter, openAt: delimiterAt };
  }
  return null;
}

function readBalancedCredentialValue(text, start) {
  const container = readContainerStart(text, start);
  if (!container) return null;
  const closerFor = { "{": "}", "[": "]", "(": ")", "<<": ">>" };
  const initialCloser = closerFor[container.opener] ?? container.opener;
  const stack = [initialCloser];
  let i = container.openAt + container.opener.length;
  while (i < text.length) {
    const top = stack[stack.length - 1];
    if ((top === "'" || top === '"') && text[i] === top) {
      const end = i + 1;
      stack.pop();
      if (stack.length === 0) return { end, replacement: `${container.prefix}***${top}` };
      i = end;
      continue;
    }
    if (text[i] === "'" || text[i] === '"' || text[i] === "`") {
      const end = skipQuotedSpan(text, i);
      if (end < 0) return { end: text.length, replacement: `${container.prefix}***` };
      i = end;
      continue;
    }
    if (text[i] === "\\") { i += 2; continue; }
    if (text.startsWith("<<", i)) { stack.push(">>"); i += 2; continue; }
    if (text[i] === "{" || text[i] === "[" || text[i] === "(") {
      stack.push(closerFor[text[i]]);
      i += 1;
      continue;
    }
    if (text.startsWith(">>", i) || text[i] === "}" || text[i] === "]" || text[i] === ")") {
      const closer = text.startsWith(">>", i) ? ">>" : text[i];
      if (closer !== top) return { end: text.length, replacement: `${container.prefix}***` };
      const end = i + closer.length;
      stack.pop();
      if (stack.length === 0) return { end, replacement: `${container.prefix}***${closer}` };
      i = end;
      continue;
    }
    i += 1;
  }
  return { end: text.length, replacement: `${container.prefix}***` };
}

function looksLikeAssignmentAfterComma(text, commaAt) {
  let i = commaAt + 1;
  while (text[i] === " " || text[i] === "\t" || text[i] === "\r" || text[i] === "\n") i += 1;
  if (text[i] === '"' || text[i] === "'") {
    const quote = text[i++];
    while (/[A-Za-z0-9_-]/.test(text[i] ?? "")) i += 1;
    if (text[i] !== quote) return false;
    i += 1;
  } else {
    if (!/[A-Za-z_]/.test(text[i] ?? "")) return false;
    i += 1;
    while (/[A-Za-z0-9_-]/.test(text[i] ?? "")) i += 1;
  }
  while (text[i] === " " || text[i] === "\t") i += 1;
  return text.startsWith("=>", i) || text[i] === ":" || text[i] === "=";
}

function readBareCredentialValue(text, start, { tuple = false, multiword = false } = {}) {
  let i = start;
  while (i < text.length) {
    const char = text[i];
    if (char === "\r" || char === "\n" || char === "}" || char === "]" || char === ")" || char === ";") break;
    if (char === "," && (tuple || looksLikeAssignmentAfterComma(text, i))) break;
    i += 1;
  }
  let end = i;
  while (end > start && (text[end - 1] === " " || text[end - 1] === "\t")) end -= 1;
  const value = text.slice(start, end);
  if (value === "" || /^(?:nil|true|false|null|undefined)$/i.test(value)) return null;
  if (value.length < 3 && !/[ \t]/.test(value)) return null;
  if (!multiword && value.length < 3) return null;
  return { end, replacement: "***" };
}

function readCompleteCredentialValue(text, start, options = {}) {
  return readBalancedCredentialValue(text, start)
    ?? readQuotedValueEnd(text, start)
    ?? readBareCredentialValue(text, start, options);
}

function maskStructuredCredentialAssignments(text) {
  const rule = new RegExp(CREDENTIAL_ASSIGNMENT_PREFIX.source, "g");
  let result = "";
  let cursor = 0;
  let match;
  while ((match = rule.exec(text)) !== null) {
    const identifier = match.groups.quotedIdentifier ?? match.groups.identifier;
    if (!isCredentialIdentifier(identifier)) continue;
    const valueStart = rule.lastIndex;
    const value = readCompleteCredentialValue(text, valueStart, { multiword: true });
    if (!value) continue;
    result += text.slice(cursor, valueStart) + value.replacement;
    cursor = value.end;
    rule.lastIndex = value.end;
  }
  return cursor === 0 ? text : result + text.slice(cursor);
}

function maskCredentialNameValueRecords(text) {
  const flatObject = /\{[^{}]*\}/g;
  const nameValuePrefix = /(?:["']?name["']?)\s*:\s*(["'])(?<name>[A-Za-z0-9_-]+)\1\s*,\s*(?:["']?value["']?)\s*:\s*/i;
  return text.replace(flatObject, (record) => {
    const match = nameValuePrefix.exec(record);
    if (!match || !isCredentialIdentifier(match.groups.name)) return record;
    const valueStart = match.index + match[0].length;
    const value = readCompleteCredentialValue(record, valueStart, { multiword: true });
    if (!value) return record;
    return record.slice(0, valueStart) + value.replacement + record.slice(value.end);
  });
}

function maskCredentialTupleValues(text) {
  const rule = new RegExp(CREDENTIAL_TUPLE_PREFIX.source, "g");
  let result = "";
  let cursor = 0;
  let match;
  while ((match = rule.exec(text)) !== null) {
    const identifier = match.groups.atom ?? match.groups.quoted;
    if (!isCredentialIdentifier(identifier)) continue;
    const valueStart = rule.lastIndex;
    const value = readCompleteCredentialValue(text, valueStart, { tuple: true, multiword: true });
    if (!value) continue;
    result += text.slice(cursor, valueStart) + value.replacement;
    cursor = value.end;
    rule.lastIndex = value.end;
  }
  return cursor === 0 ? text : result + text.slice(cursor);
}

// PEM private-key block: the BEGIN marker survives, then body items (each starts with a line break, real or a
// literal backslash-n) until a line that is not base64, a Proc-Type/DEK-Info header or blank, then an optional END
// marker. The dashes are a quantifier so this source never holds a literal marker.
const PEM_LB = String.raw`(?:\r?\n|\\n)`;
const PEM_EOL = `(?=${PEM_LB}|$)`;
const PEM_KEY = String.raw`(?:[A-Z]{2,12} ){0,3}PRIVATE[ ]KEY-{5}`;
const PEM_ITEM = `${PEM_LB}[ \\t]*(?:[A-Za-z0-9+/=]+${PEM_EOL}|(?:Proc-Type|DEK-Info):(?:[^\\r\\n\\\\]|\\\\(?!n))*|${PEM_EOL})`;
const PEM_RULE = new RegExp(`(-{5}BEGIN ${PEM_KEY})(?:${PEM_ITEM})*(?:${PEM_LB}-{5}END ${PEM_KEY})?`, "g");

// Query-string credentials: `?key=`, `&sig=`, `&signature=` and the X-Amz signing parameters, value to `&`, `#` or space.
const QUERY_CREDENTIAL_RULE = /([?&](?:key|sig|signature|X-Amz-Signature|X-Amz-Credential|X-Amz-Security-Token)=)[^&#\s"']{3,}/gi;

const AUTHORIZATION_RULE = new RegExp(`((?<![A-Za-z0-9])authorization${KEY_QUOTE}[ \\t]*[:=][ \\t]*)[^\\n]+`, "gi");
const COOKIE_RULE = new RegExp(`(\\bcookies?${KEY_QUOTE}[ \\t]*:[ \\t]*)[^\\n]+`, "gi");
const SECRET_ACCESS_KEY_RULE = new RegExp(`((?:aws_)?secret[_-]access[_-]key${KEY_QUOTE}[ \\t]*[:=][ \\t]*(?=\\S))${SECRET_VALUE_SOURCE}`, "gi");
// Bearer: a quoted value keeps its quotes around `***`; `realm="v"` style (non-space run then a quoted span)
// and a 3+ character bare run become `***`. The separator is `[ \t]+`, so a line-final `Bearer` never reaches the next line.
const BEARER_RULE = /\b(bearer[ \t]+)(?:"(?<dq>[^"\n]*)(?<dqc>"?)|'(?<sq>[^'\n]*)(?<sqc>'?)|[^\s"']*(?:"[^"\n]*"?|'[^'\n]*'?)|[^\s"']{3,})/gi;
function maskBearer(match, prefix, ...rest) {
  const g = rest[rest.length - 1];
  if (g.dq !== undefined) return `${prefix}"***${g.dqc}`;
  if (g.sq !== undefined) return `${prefix}'***${g.sqc}`;
  return `${prefix}***`;
}
// Elixir tuple `{:token, "v"}` / `{"password", "v"}`: an atom or a closed-quote key, then a comma. A comma after a
// bare word (`invalid token, retrying`) never qualifies.
const TUPLE_RULE = new RegExp(
  `((?::[A-Za-z0-9_-]{0,64}?(?:${CREDENTIAL_WORDS})(?:\\\\*["'])?|["'][A-Za-z0-9_-]{0,64}?(?:${CREDENTIAL_WORDS})\\\\*["'])[ \\t]*,[ \\t]*)${SECRET_VALUE_SOURCE}`,
  "gi"
);
// CLI flag `--<name containing a credential word> <value>`; `--password-file` (name continues) does not match.
const CLI_FLAG_RULE = new RegExp(`(--[A-Za-z0-9_-]{0,64}?(?:${CREDENTIAL_WORDS})[ \\t]+)${SECRET_VALUE_SOURCE}`, "gi");
// curl basic auth `-u user:<v>` / `--user user:<v>`.
const CURL_USER_RULE = new RegExp(`((?<![^ \\t\\n])(?:-u|--user)[ \\t]+[^\\s:]{1,256}:)${SECRET_VALUE_SOURCE}`, "g");
const GENERIC_CREDENTIAL_RULE = new RegExp(
  `((?:${CREDENTIAL_WORDS})${KEY_QUOTE}[ \\t]*(?:=>|[:=]{1,3})[ \\t]*(?=\\S))${SECRET_VALUE_SOURCE}`,
  "gi"
);
const STRUCTURAL_LINE = /^\s*\d+\) (?:test|doctest|property) |^Finished in /;

// First pass: when a line ends in a credential key plus separator, the value sits on a following line. Mask the
// next non-blank line, then every following non-blank line indented deeper than the key line. One forward pass.
// ExUnit numbered test lines and `Finished in` lines are never masked and end the run.
function maskNextLineValues(text) {
  const lines = text.split("\n");
  let keyIndent = -1;
  let waiting = false;
  let active = false;
  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const body = line.endsWith("\r") ? line.slice(0, -1) : line;
    if (STRUCTURAL_LINE.test(line)) { active = false; waiting = false; continue; }
    if (active && body.trim() === "") continue;
    const indent = body.length - body.trimStart().length;
    if (active && (waiting || indent > keyIndent)) {
      lines[i] = `${body.slice(0, indent)}***${line.length > body.length ? "\r" : ""}`;
      waiting = false;
      continue;
    }
    active = false;
    const keyLine = STRUCTURAL_KEY_LINE.exec(line);
    if (keyLine && isCredentialIdentifier(keyLine.groups.identifier)) { active = true; waiting = true; keyIndent = indent; }
    const tupleLine = STRUCTURAL_TUPLE_KEY_LINE.exec(line);
    const tupleIdentifier = tupleLine?.groups.atom ?? tupleLine?.groups.double ?? tupleLine?.groups.single;
    if (tupleIdentifier && isCredentialIdentifier(tupleIdentifier)) { active = true; waiting = true; keyIndent = indent; }
  }
  return lines.join("\n");
}

// Masks credential-shaped values, keeping key and header names so failures stay diagnosable.
// Shapes, in rule order (every rule is linear-time; prose without a separator is untouched):
//   0. next-line pass: a line ending in a credential key plus `:`, `=`, `=>` or a YAML block indicator masks the
//      next non-blank line and following lines indented deeper (ExUnit `N) test` and `Finished in` lines never)
//   p. PEM private-key block: text after the BEGIN marker through the END marker (body lines and headers; with no
//      END marker only the body lines, so the next non-body line survives), real or literal-backslash-n line breaks
//   a. `Authorization:` / `Proxy-Authorization:` header (any scheme, Digest included), value to end of line
//   b. `Cookie:` / `Cookies:` / `Set-Cookie:` header at any position, value to end of line
//   c. `Bearer <v>`: bare run, quoted span (quotes kept) or `realm="v"` style, on one line
//   d. `(aws_)secret[_-]access[_-]key` = quoted or unquoted value
//   e. provider tokens, prefix kept: `gh[pousr]_` / `github_pat_` (6+ characters), `hex_` (8+), and, after a
//      non-alphanumeric character, `sk-` (8+ of `A-Za-z0-9_-`, project and versioned forms), Slack `xox[abprs]-`
//      (8+) and `npm_` plus exactly 36 letters or digits (`task-runner12345`, `npm_config_cache` stay readable)
//   f. URL userinfo password (`scheme://user:<v>@host`; empty user and a `/` in the password allowed, parts bounded)
//   g. JWTs (`eyJ` + two or three base64url segments; no base64url character before it, so a hyphenated run stays linear)
//   h. AWS access key IDs (`AKIA` / `ASIA` + 16 characters, any non-uppercase/digit character before)
//   q. query credentials (`?key=`, `&sig=`, `&signature=`, `X-Amz-Signature|Credential|Security-Token`)
//   i. Elixir tuples with an atom or closed-quote credential key and a comma (`{:token, "v"}`)
//   j. CLI flags `--<name with a credential word> <v>` (not `--password-file`)
//   k. curl basic auth `-u user:<v>` / `--user user:<v>`
//   l. generic credential keys (token, secret, secret_key[_base], password, passwd, passphrase, api key,
//      private key, credential[s], authorization) followed by `=>`, `:`/`=` (up to `==`) and a quoted
//      (multi-word, escaped, unterminated, backslash-escaped JSON `\\"v\\"`) or 3+ character unquoted value; the
//      key itself may be wrapped in plain or backslash-escaped quotes (rules a, b, d, i, l)
// Deliberately unmasked: unquoted nil/true/false/null/undefined after a credential key (whole value only), and
// `preauthorization` (authorization needs a non-alphanumeric character before it).
// Accepted over-masks (pinned in the tests as ACCEPTED_OVERMASK): `code: assert token == "x"`, a key line
// followed by plain text, `--no-password prompt`, a port before a path containing `@`, `secrets: inherit`,
// numeric values (`max_token: 1000`), `Authorization: required for route`, `stale cookie: expired at line`.
export function maskSecretShapes(text) {
  let masked = maskNextLineValues(String(text ?? ""));
  masked = maskCredentialNameValueRecords(masked);
  masked = maskCredentialTupleValues(masked);
  masked = maskStructuredCredentialAssignments(masked);
  return masked.replace(STRUCTURAL_CREDENTIAL_RULE, maskStructuralCredential)
    .replace(PEM_RULE, "$1***")
    .replace(AUTHORIZATION_RULE, "$1***")
    .replace(COOKIE_RULE, "$1***")
    .replace(BEARER_RULE, maskBearer)
    .replace(SECRET_ACCESS_KEY_RULE, maskValue)
    .replace(/(gh[pousr]_|github_pat_)[A-Za-z0-9_]{6,}/g, "$1***")
    .replace(/(hex_)[A-Za-z0-9_]{8,}/g, "$1***")
    .replace(/(?<![A-Za-z0-9])(sk-)[A-Za-z0-9_-]{8,}/g, "$1***")
    .replace(/(?<![A-Za-z0-9])(xox[abprs]-)[A-Za-z0-9-]{8,}/g, "$1***")
    .replace(/(?<![A-Za-z0-9])(npm_)[A-Za-z0-9]{36}(?![A-Za-z0-9])/g, "$1***")
    .replace(/(:\/\/[^/\s:@]{0,256}:)[^\s@]{1,256}@/g, "$1***@")
    .replace(/(?<![A-Za-z0-9_-])eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)?/g, "eyJ***")
    .replace(/(?<![A-Z0-9])(A[KS]IA)[A-Z0-9]{16}/g, "$1***")
    .replace(QUERY_CREDENTIAL_RULE, "$1***")
    .replace(TUPLE_RULE, maskValue)
    .replace(CLI_FLAG_RULE, maskValue)
    .replace(CURL_USER_RULE, maskValue)
    .replace(GENERIC_CREDENTIAL_RULE, maskValue);
}

// Hosted-CI diagnosability: when the root proof fails, print the ExUnit failure details
// (from the first numbered failure to the "Finished in" line) and a bounded tail of its own
// test output (the run root, and with it the full log, is removed afterwards).
// Credential-shaped values are masked once via maskSecretShapes; nothing is printed on success.
export function rootProofFailureTail(outcome, result) {
  const text = maskSecretShapes(`${String(result?.stdout ?? "")}${String(result?.stderr ?? "")}`.replace(/\u001b\[[0-9;]*m/g, ""));
  const lines = text.split("\n");
  let details = "";
  const first = lines.findIndex((line) => /^\s*1\) (test|doctest|property) /.test(line));
  if (first >= 0) {
    const finished = lines.findIndex((line, index) => index > first && /^Finished in /.test(line));
    const section = lines.slice(first, finished > first ? finished : first + ROOT_PROOF_DETAIL_LINES);
    details = section.slice(0, ROOT_PROOF_DETAIL_LINES).join("\n");
    if (details.length > ROOT_PROOF_DETAIL_BYTES) details = details.slice(0, ROOT_PROOF_DETAIL_BYTES);
    details = `--- root-proof failure details (first ${ROOT_PROOF_DETAIL_LINES} lines max) ---\n${details}\n--- end root-proof failure details ---\n`;
  }
  let tail = lines.slice(-ROOT_PROOF_TAIL_LINES).join("\n");
  if (tail.length > ROOT_PROOF_TAIL_BYTES) tail = tail.slice(-ROOT_PROOF_TAIL_BYTES);
  return `${details}--- root-proof failure tail (${outcome}; last ${ROOT_PROOF_TAIL_LINES} lines max) ---\n${tail}\n--- end root-proof failure tail ---\n`;
}

function emitRootProofFailureTail(outcome, result) {
  try { process.stderr.write(rootProofFailureTail(outcome, result)); } catch { /* diagnostics must never change the verdict */ }
}

function sameKeys(value, expected, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error(`${label} must be a record`);
  const actual = Object.keys(value).sort();
  if (actual.join("\0") !== [...expected].sort().join("\0")) throw new Error(`${label} has unknown or missing keys`);
}

function safeRelative(value, label) {
  if (typeof value !== "string" || value === "" || path.isAbsolute(value) || value.split(/[\\/]/).includes("..")) throw new Error(`${label} must stay repository-relative`);
}

export function browserDiagnosticContext(environment = process.env) {
  const mode = environment.CROSSWAKE_BROWSER_DIAGNOSTIC_MODE;
  const job = environment.CROSSWAKE_BROWSER_DIAGNOSTIC_JOB;
  if (mode === undefined && job === undefined) return null;
  if (mode !== BROWSER_DIAGNOSTIC_MODE) throw new Error("browser diagnostic mode is unknown");
  if (!browserDiagnosticJobs.includes(job)) throw new Error("browser diagnostic job is unknown");
  return { mode, job };
}

export function validateBrowserDiagnostic(value) {
  sameKeys(value, browserDiagnosticKeys, "browser diagnostic");
  if (value.schema_version !== 1 || value.owner !== "browser" || !browserDiagnosticCategories.includes(value.category) || !browserDiagnosticJobs.includes(value.job)) throw new Error("browser diagnostic value is outside the closed schema");
  return value;
}

export function classifyBrowserFailure(result, context) {
  if (!context || !browserDiagnosticJobs.includes(context.job)) throw new Error("browser diagnostic context is invalid");
  const output = `${String(result?.stdout ?? "")}\n${String(result?.stderr ?? "")}`;
  let category;
  if (result?.error) category = "browser_process_error";
  else if (result?.signal) category = "browser_process_signal";
  else if (/config(?:uration)? error|playwright\.config/i.test(output)) category = "browser_configuration_failed";
  else if (/webserver|server.*(?:failed|timeout|timed out)/i.test(output)) category = "browser_server_start_failed";
  else if (/test timeout|timed out.*test/i.test(output)) category = "browser_test_timeout";
  else if (/expect(?:ed|\()|assertion/i.test(output)) category = "browser_assertion_failed";
  else category = "browser_process_exit_nonzero";
  return validateBrowserDiagnostic({ schema_version: 1, owner: "browser", category, job: context.job });
}

export function validateExampleHostDiagnostic(value) {
  sameKeys(value, exampleHostDiagnosticKeys, "example-host diagnostic");
  const validExitCode = Number.isInteger(value.exit_code) && value.exit_code >= 0 && value.exit_code <= 255;
  const exitCodeMatchesKind = value.kind === "command_failure" ? validExitCode : value.exit_code === null;
  if (
    value.schema_version !== 1 ||
    value.owner !== "example-host-proof" ||
    !exampleHostDiagnosticSeeds.has(value.seed) ||
    !exampleHostDiagnosticClasses.has(value.class) ||
    !exampleHostDiagnosticKinds.includes(value.kind) ||
    !exitCodeMatchesKind
  ) throw new Error("example-host diagnostic value is outside the closed schema");
  return value;
}

export function classifyExampleHostFailure(result) {
  const output = `${String(result?.stdout ?? "")}\n${String(result?.stderr ?? "")}`;
  const commandFailure = output.match(/^\[crosswake\] FAIL example-host-isolation seed=(17|101|1009) class=(tagged|complete) exit=(\d+)$/m);
  if (commandFailure) {
    return validateExampleHostDiagnostic({
      schema_version: 1,
      owner: "example-host-proof",
      seed: Number(commandFailure[1]),
      class: commandFailure[2],
      kind: "command_failure",
      exit_code: Number(commandFailure[3])
    });
  }

  const residueFailure = output.match(/^\[crosswake\] FAIL example-host-isolation seed=(17|101|1009) class=(tagged|complete) residue=(owned-temp|tracked-path) path=.+$/m);
  if (residueFailure) {
    return validateExampleHostDiagnostic({
      schema_version: 1,
      owner: "example-host-proof",
      seed: Number(residueFailure[1]),
      class: residueFailure[2],
      kind: residueFailure[3] === "owned-temp" ? "owned_temp_residue" : "tracked_path_residue",
      exit_code: null
    });
  }

  return null;
}

export function loadStageManifest(source = manifestPath) {
  return JSON.parse(readFileSync(source, "utf8"));
}

export function loadArtifactPolicy(source = artifactPolicyPath) {
  return JSON.parse(readFileSync(source, "utf8"));
}

function validateMatchers(records, label) {
  if (!Array.isArray(records) || records.length === 0) throw new Error(`${label} must be non-empty`);
  const categories = records.map(record => record?.category);
  if (categories.join("\0") !== [...categories].sort().join("\0") || new Set(categories).size !== categories.length) throw new Error(`${label} categories must be unique and ordered`);
  for (const record of records) {
    sameKeys(record, ["category", "matchers", "remediation_command"], `${label} record`);
    if (typeof record.category !== "string" || !record.category || !Array.isArray(record.matchers) || record.matchers.length === 0 || typeof record.remediation_command !== "string" || !record.remediation_command) throw new Error(`${label} record is empty`);
    for (const matcher of record.matchers) {
      sameKeys(matcher, matcherKeys, `${label} matcher`);
      if (!["exact", "segment", "suffix", "tree"].includes(matcher.kind)) throw new Error(`${label} matcher kind is unknown`);
      safeRelative(matcher.value, `${label} matcher`);
    }
  }
}

function pathsOverlap(left, right) {
  return left === right || left.startsWith(`${right}/`) || right.startsWith(`${left}/`);
}

export function validateArtifactPolicy(policy) {
  sameKeys(policy, artifactPolicyKeys, "artifact policy");
  if (policy.schema_version !== 1) throw new Error("artifact policy schema is unsupported");
  validateMatchers(policy.ignored_transient, "ignored transient");
  validateMatchers(policy.forbidden_tracked, "forbidden tracked");
  if (!Array.isArray(policy.intentionally_tracked) || policy.intentionally_tracked.length === 0 || !Array.isArray(policy.generated_contracts) || policy.generated_contracts.length === 0 || !Array.isArray(policy.safe_fixtures)) throw new Error("artifact policy classes must be non-empty arrays");

  const matcherIds = [];
  for (const records of [policy.ignored_transient, policy.forbidden_tracked]) for (const record of records) for (const matcher of record.matchers) matcherIds.push(`${matcher.kind}\0${matcher.value}`);
  if (new Set(matcherIds).size !== matcherIds.length) throw new Error("artifact policy matchers overlap");

  const trackedCategories = policy.intentionally_tracked.map(record => record?.category);
  if (trackedCategories.join("\0") !== [...trackedCategories].sort().join("\0") || new Set(trackedCategories).size !== trackedCategories.length) throw new Error("intentionally tracked categories must be unique and ordered");
  for (const record of policy.intentionally_tracked) {
    sameKeys(record, ["category", "paths", "purpose"], "intentionally tracked record");
    if (!record.category || !record.purpose || !Array.isArray(record.paths) || record.paths.length === 0 || record.paths.join("\0") !== [...record.paths].sort().join("\0")) throw new Error("intentionally tracked record is empty or unordered");
    for (const trackedPath of record.paths) safeRelative(trackedPath, "intentionally tracked path");
  }
  for (const fixture of policy.safe_fixtures) {
    sameKeys(fixture, ["forbidden_category", "path", "purpose"], "safe fixture");
    safeRelative(fixture.path, "safe fixture path");
    if (!fixture.forbidden_category || !fixture.purpose) throw new Error("safe fixture is empty");
  }
  const canonicalSources = [];
  const generatedOutputs = [];
  for (const contract of policy.generated_contracts) {
    sameKeys(contract, generatedContractKeys, "generated contract");
    safeRelative(contract.canonical_source, "generated canonical source");
    if (!Array.isArray(contract.regeneration_argv) || contract.regeneration_argv.length === 0 || !Array.isArray(contract.output_paths) || contract.output_paths.length === 0 || contract.output_paths.join("\0") !== [...contract.output_paths].sort().join("\0") || new Set(contract.output_paths).size !== contract.output_paths.length || typeof contract.remediation_command !== "string" || !contract.remediation_command) throw new Error("generated contract record is empty, duplicated, or unordered");
    for (const argv of contract.regeneration_argv) if (!Array.isArray(argv) || argv.length === 0 || argv.some(part => typeof part !== "string" || !part || /[;&|`\n\r]/.test(part))) throw new Error("generated contract argv must be fixed");
    for (const output of contract.output_paths) safeRelative(output, "generated output");
    canonicalSources.push(contract.canonical_source);
    generatedOutputs.push(...contract.output_paths);
  }
  if (new Set(canonicalSources).size !== canonicalSources.length) throw new Error("generated canonical sources must be unique");
  for (let index = 0; index < generatedOutputs.length; index += 1) for (let other = index + 1; other < generatedOutputs.length; other += 1) if (pathsOverlap(generatedOutputs[index], generatedOutputs[other])) throw new Error("generated outputs must be unique and non-overlapping");
  for (const source of canonicalSources) for (const output of generatedOutputs) if (pathsOverlap(source, output)) throw new Error("generated sources and outputs must not overlap");
  return policy;
}

export function validateStageManifest(manifest) {
  sameKeys(manifest, manifestKeys, "manifest");
  if (manifest.schema_version !== 1 || !Array.isArray(manifest.stages) || manifest.stages.length !== stageIds.length) throw new Error("manifest must contain the complete nine-stage inventory");
  if (manifest.stages.map(stage => stage?.stage_id).join("\0") !== stageIds.join("\0")) throw new Error("stages must use the closed ordered purpose inventory");
  const ids = new Set(stageIds);
  for (const stage of manifest.stages) {
    sameKeys(stage, stageKeys, `stage ${stage?.stage_id ?? "null"}`);
    if (!Array.isArray(stage.dependencies) || !Array.isArray(stage.required_tools) || !Array.isArray(stage.argv) || stage.argv.length === 0 || !Array.isArray(stage.ci_owners) || stage.ci_owners.length === 0 || !Array.isArray(stage.owned_outputs)) throw new Error(`${stage.stage_id} contains an empty or non-array field`);
    if (!Number.isSafeInteger(stage.timeout_ms) || stage.timeout_ms < 1000 || stage.timeout_ms > 3600000) throw new Error(`${stage.stage_id} timeout must be between one second and one hour`);
    if (stage.argv.some(part => typeof part !== "string" || part === "" || /[;&|`\n\r]/.test(part))) throw new Error(`${stage.stage_id} argv must be fixed strings without shell syntax`);
    safeRelative(stage.cwd, `${stage.stage_id} cwd`);
    sameKeys(stage.env, Object.keys(stage.env), `${stage.stage_id} env`);
    for (const [key, value] of Object.entries(stage.env)) if (!/^[A-Z][A-Z0-9_]*$/.test(key) || typeof value !== "string") throw new Error(`${stage.stage_id} env must be string key/value records`);
    if (typeof stage.remediation_command !== "string" || !stage.remediation_command) throw new Error(`${stage.stage_id} requires one remediation`);
    for (const dep of stage.dependencies) if (!ids.has(dep)) throw new Error(`${stage.stage_id} has unknown dependency ${dep}`);
    for (const tool of stage.required_tools) { sameKeys(tool, toolKeys, `${stage.stage_id} tool`); if (!Array.isArray(tool.argv) || tool.argv.length === 0 || typeof tool.version_regex !== "string") throw new Error(`${stage.stage_id} tool rule is malformed`); new RegExp(tool.version_regex); }
    for (const owner of stage.ci_owners) { sameKeys(owner, ownerKeys, `${stage.stage_id} owner`); if (!owner.job_id || !owner.command) throw new Error(`${stage.stage_id} owner is empty`); }
    for (const output of stage.owned_outputs) safeRelative(output, `${stage.stage_id} output`);
  }
  const visiting = new Set(); const visited = new Set(); const byId = new Map(manifest.stages.map(stage => [stage.stage_id, stage]));
  function visit(id) { if (visiting.has(id)) throw new Error(`dependency cycle at ${id}`); if (visited.has(id)) return; visiting.add(id); for (const dep of byId.get(id).dependencies) visit(dep); visiting.delete(id); visited.add(id); }
  for (const id of stageIds) visit(id);
  return manifest;
}

export function validateCiParity(manifest, workflowSource = readFileSync(workflowPath, "utf8")) {
  validateStageManifest(manifest);
  for (const stage of manifest.stages) for (const owner of stage.ci_owners) {
    const ownerStart = workflowSource.search(new RegExp(`^  ${owner.job_id}:`, "m"));
    const tail = ownerStart < 0 ? "" : workflowSource.slice(ownerStart);
    const nextOwner = tail.slice(1).search(/^  [a-zA-Z0-9_-]+:/m);
    const ownerBlock = nextOwner < 0 ? tail : tail.slice(0, nextOwner + 1);
    if (ownerStart < 0 || !ownerBlock.includes(owner.command)) throw new Error(`FAIL ${stage.stage_id} CI owner ${owner.job_id}; corrective-command=node --test test/js/repository_verification.test.mjs`);
  }
  return manifest;
}

export function selectStages(manifest, selection = "all") {
  validateStageManifest(manifest);
  if (selection !== "all" && !stageIds.includes(selection)) throw new Error(`unknown stage ${selection}`);
  if (selection === "all") return manifest.stages;
  const wanted = new Set(); const byId = new Map(manifest.stages.map(stage => [stage.stage_id, stage]));
  function add(id) { if (wanted.has(id)) return; for (const dep of byId.get(id).dependencies) add(dep); wanted.add(id); }
  add(selection);
  if (selection !== "repository-cleanliness") wanted.add("repository-cleanliness");
  return manifest.stages.filter(stage => wanted.has(stage.stage_id));
}

function defaultProbe(tool) {
  const result = spawnSync(tool.argv[0], tool.argv.slice(1), { cwd: repoRoot, encoding: "utf8", timeout: 15000 });
  if (result.error) return { kind: result.error.code === "ENOENT" ? "missing" : "failed-to-start" };
  return { status: result.status, stdout: `${result.stdout ?? ""}${result.stderr ?? ""}`.trim() };
}

export function runPreflight(_manifest, selected, options = {}) {
  const probe = options.probe ?? defaultProbe;
  const tools = new Map(); const records = [];
  for (const stage of selected) for (const tool of stage.required_tools) {
    const current = tools.get(tool.tool);
    if (current) current.required_by.push(stage.stage_id);
    else tools.set(tool.tool, { rule: tool, required_by: [stage.stage_id] });
  }
  for (const { rule: tool, required_by } of tools.values()) {
    let result;
    try {
      result = probe(tool);
    } catch {
      result = { kind: "failed-to-start" };
    }
    const output = String(result?.stdout ?? "");
    if (result?.kind || result?.status !== undefined && result.status !== 0 || !new RegExp(tool.version_regex).test(output)) {
      records.push({ result: "FAIL", purpose: "repository-preflight", tool: tool.tool, required_by, remediation_command: tool.remediation_command });
    }
  }
  return { status: records.length ? "FAIL" : "PASS", records };
}

function renderSummary(records) {
  const byPurpose = new Map();
  for (const record of records) byPurpose.set(record.purpose, record);
  return [...byPurpose.values()].map(record => {
    if (record.result === "PASS") return `PASS ${record.purpose}`;

    const diagnostic = record.diagnostic?.owner === "browser"
      ? `\nBROWSER_DIAGNOSTIC ${JSON.stringify(validateBrowserDiagnostic(record.diagnostic))}`
      : record.diagnostic?.owner === "example-host-proof"
        ? `\nEXAMPLE_HOST_DIAGNOSTIC ${JSON.stringify(validateExampleHostDiagnostic(record.diagnostic))}`
        : "";
    return `${record.result} ${record.purpose}${record.category ? ` category=${record.category}` : ""}${record.path ? ` path=${JSON.stringify(record.path)}` : ""}; corrective-command=${record.remediation_command}${diagnostic}`;
  }).join("\n");
}

function validateRunRoot(runRoot, root, captureRoot) {
  if (!path.isAbsolute(runRoot) || !path.basename(runRoot).startsWith("crosswake-repository-verify.")) throw new Error("invalid invocation root");
  if (lstatSync(runRoot).isSymbolicLink()) throw new Error("invocation root may not be a symlink");
  const parent = realpathSync(path.dirname(runRoot));
  const validParent = parent === realpathSync(tmpdir()) || (captureRoot && parent === realpathSync(captureRoot));
  if (isInside(root, runRoot) || !validParent) throw new Error("invocation root has an invalid parent");
  chmodSync(runRoot, 0o700);
}

function gitSnapshot(root, destination) {
  const result = spawnSync("git", ["status", "--porcelain=v1", "-z", "--untracked-files=all"], { cwd: root, env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" }, encoding: null, maxBuffer: 16 * 1024 * 1024 });
  if (result.error || result.status !== 0 || !Buffer.isBuffer(result.stdout)) throw new Error("Git status snapshot failed");
  writeFileSync(destination, result.stdout, { mode: 0o600 });
  return result.stdout;
}

function gitPathSet(root) {
  const result = spawnSync("git", ["status", "--porcelain=v1", "-z", "--untracked-files=all"], { cwd: root, env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" }, encoding: null, maxBuffer: 16 * 1024 * 1024 });
  if (result.error || result.status !== 0 || !Buffer.isBuffer(result.stdout)) throw new Error("Git path inspection failed");
  const fields = result.stdout.toString("utf8").split("\0").filter(Boolean);
  const paths = new Set();
  for (let index = 0; index < fields.length; index += 1) {
    const field = fields[index];
    if (field.length < 4) throw new Error("Git path record is malformed");
    paths.add(field.slice(3));
    if (field[0] === "R" || field[0] === "C" || field[1] === "R" || field[1] === "C") index += 1;
  }
  return paths;
}

function matcherApplies(matcher, relativePath) {
  if (matcher.kind === "exact") return relativePath === matcher.value;
  if (matcher.kind === "suffix") return relativePath.endsWith(matcher.value);
  if (matcher.kind === "segment") return relativePath.split("/").includes(matcher.value);
  return relativePath === matcher.value || relativePath.startsWith(`${matcher.value}/`);
}

function trackedPaths(root) {
  const result = spawnSync("git", ["ls-files", "-z"], { cwd: root, env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" }, encoding: null, maxBuffer: 16 * 1024 * 1024 });
  if (result.error || result.status !== 0 || !Buffer.isBuffer(result.stdout)) throw new Error("Git tracked-path inspection failed");
  return result.stdout.toString("utf8").split("\0").filter(Boolean).sort();
}

function artifactFailure(policy, root) {
  const safe = new Set(policy.safe_fixtures.map(fixture => fixture.path));
  for (const relativePath of trackedPaths(root)) {
    if (safe.has(relativePath)) continue;
    for (const record of policy.forbidden_tracked) {
      if (record.matchers.some(matcher => matcherApplies(matcher, relativePath))) {
        return { category: record.category, path: relativePath, remediation_command: record.remediation_command };
      }
    }
  }
  return null;
}

function generatedContractFailure(policy, root, options = {}) {
  const generatorSpawn = options.generatorSpawn ?? ((command, args, spawnOptions) => spawnSync(command, args, { ...spawnOptions, encoding: "utf8" }));
  const tracked = new Set(trackedPaths(root));
  for (const contract of policy.generated_contracts) {
    const snapshots = new Map();
    const beforePaths = gitPathSet(root);
    const source = path.resolve(root, contract.canonical_source);
    if (!tracked.has(contract.canonical_source) || !isInside(root, source) || !existsSync(source) || lstatSync(source).isSymbolicLink()) return { category: "generated_contract_missing", path: contract.canonical_source, remediation_command: contract.remediation_command };
    for (const relativePath of contract.output_paths) {
      const absolute = path.resolve(root, relativePath);
      if (!isInside(root, absolute) || !existsSync(absolute) || lstatSync(absolute).isSymbolicLink()) return { category: "generated_contract_missing", path: relativePath, remediation_command: contract.remediation_command };
      snapshots.set(relativePath, readFileSync(absolute));
    }

    let failure = null;
    try {
      for (const argv of contract.regeneration_argv) {
        const result = generatorSpawn(argv[0], argv.slice(1), { cwd: root, env: process.env, timeout: 300000 });
        if (!result || result.error || result.signal != null || result.status !== 0) {
          failure = { category: "generated_contract_generation_failed", path: contract.canonical_source, remediation_command: contract.remediation_command };
          break;
        }
      }
      if (!failure) {
        for (const [relativePath, original] of snapshots) {
          const absolute = path.join(root, relativePath);
          if (!existsSync(absolute) || !readFileSync(absolute).equals(original)) {
            failure = { category: "generated_contract_drift", path: relativePath, remediation_command: contract.remediation_command };
            break;
          }
        }
      }
      if (!failure) {
        const allowed = new Set(contract.output_paths);
        const extra = [...gitPathSet(root)].filter(relativePath => !beforePaths.has(relativePath) && !allowed.has(relativePath)).sort()[0];
        if (extra) failure = { category: "generated_contract_unregistered", path: extra, remediation_command: contract.remediation_command };
      }
    } finally {
      for (const [relativePath, original] of snapshots) writeFileSync(path.join(root, relativePath), original);
    }
    if (failure) return failure;
  }
  return null;
}

function runRepositoryCleanliness(stage, policy, root, spawn, options = {}) {
  const declared = spawn(stage.argv[0], stage.argv.slice(1), {
    cwd: path.join(root, stage.cwd),
    env: { ...process.env, ...stage.env },
    timeout: stage.timeout_ms,
    killSignal: "SIGTERM"
  });
  if (!declared || declared.error || declared.signal != null || declared.status !== 0) return declared;
  const forbidden = artifactFailure(policy, root);
  if (forbidden) return { status: 1, ...forbidden };
  if (!options.verifyGeneratedContracts) return { status: 0 };
  const generated = generatedContractFailure(policy, root, options);
  return generated ? { status: 1, ...generated } : { status: 0 };
}

function isInside(root, candidate) {
  return candidate === root || candidate.startsWith(`${root}${path.sep}`);
}

function nearestExistingParent(candidate) {
  let current = path.dirname(candidate);
  while (!existsSync(current)) {
    const parent = path.dirname(current);
    if (parent === current) throw new Error("owned output has no existing parent");
    current = parent;
  }
  return current;
}

function cleanupCreatedOutputs(root, createdOutputs) {
  const canonicalRoot = realpathSync(root);
  for (const output of createdOutputs) {
    if (!existsSync(output)) continue;
    if (!isInside(canonicalRoot, output)) throw new Error("owned output escaped repository");
    const parent = realpathSync(nearestExistingParent(output));
    if (!isInside(canonicalRoot, parent)) throw new Error("owned output parent escaped repository");
    if (lstatSync(output).isSymbolicLink()) throw new Error("owned output may not be a symlink");
    rmSync(output, { recursive: true, force: true });
  }
}

function setResult(records, purpose, result, remediation_command) {
  const current = records.find(record => record.purpose === purpose);
  if (current) {
    current.result = result;
    current.remediation_command = remediation_command;
  } else records.push({ purpose, result, remediation_command });
}

export function runVerification(options = {}) {
  const manifest = validateStageManifest(options.manifest ?? loadStageManifest());
  validateCiParity(manifest, options.workflowSource ?? readFileSync(workflowPath, "utf8"));
  const enforceArtifactPolicy = options.enforceArtifactPolicy !== false;
  const root = realpathSync(options.repoRoot ?? repoRoot);
  const artifactPolicy = enforceArtifactPolicy ? validateArtifactPolicy(options.artifactPolicy ?? loadArtifactPolicy()) : null;
  const selection = options.selection ?? "all";
  const processEnvironment = options.processEnvironment ?? process.env;
  const browserDiagnostic = browserDiagnosticContext(processEnvironment);
  const selected = selectStages(manifest, selection);
  const verifyGeneratedContracts = selection === "all" || selection === "repository-cleanliness";
  const suppliedRunRoot = Boolean(options.runRoot);
  const runRoot = options.runRoot ?? mkdtempSync(path.join(tmpdir(), "crosswake-repository-verify."));
  const records = [];
  const cleanliness = manifest.stages.find(stage => stage.stage_id === "repository-cleanliness");
  let before;
  let exitStatus = 0;

  try {
    validateRunRoot(runRoot, root, options.captureRoot);
    mkdirSync(path.join(runRoot, "logs"), { recursive: true, mode: 0o700 });
    before = gitSnapshot(root, path.join(runRoot, "git-before.z"));
  } catch {
    const record = { result: "FAIL", purpose: "repository-preflight", remediation_command: "node --test test/js/repository_verification.test.mjs" };
    return { status: 1, output: renderSummary([record]), records: [record] };
  }

  if (selection === "all" && before.length > 0) {
    const record = { result: "FAIL", purpose: "repository-cleanliness", remediation_command: "git status --short" };
    try { gitSnapshot(root, path.join(runRoot, "git-final.z")); } catch { /* The same fail-closed result applies. */ }
    if (!suppliedRunRoot) rmSync(runRoot, { recursive: true, force: true });
    return { status: 1, output: renderSummary([record]), records: [record] };
  }

  const createdOutputs = new Set();
  for (const stage of selected) for (const output of stage.owned_outputs) {
    const absolute = path.resolve(root, output);
    if (!isInside(root, absolute)) throw new Error("owned output escaped repository");
    if (!existsSync(absolute)) createdOutputs.add(absolute);
  }

  const preflight = runPreflight(manifest, selected, options);
  const preflightRemediation = preflight.records[0]?.remediation_command ?? manifest.stages[0].remediation_command;
  records.push({ result: preflight.status, purpose: "repository-preflight", remediation_command: preflightRemediation });
  const nonpassing = new Set();
  const globallyBlocked = preflight.records.some(record => record.required_by.includes("repository-preflight"));
  const preflightBlocked = new Set(preflight.records.flatMap(record => record.required_by));
  const spawn = options.spawn ?? spawnStage;
  exitStatus = preflight.status === "FAIL" ? 1 : 0;

  try {
    for (const stage of selected) {
      if (stage.stage_id === "repository-preflight") continue;
      const blocked = stage.stage_id !== "repository-cleanliness" && (globallyBlocked || preflightBlocked.has(stage.stage_id) || stage.dependencies.some(dep => dep !== "repository-preflight" && nonpassing.has(dep)));
      if (blocked) {
        nonpassing.add(stage.stage_id);
        records.push({ result: "BLOCKED", purpose: stage.stage_id, remediation_command: stage.remediation_command });
        exitStatus = 1;
        continue;
      }
      let result;
      try {
        const stageEnv = { ...processEnvironment, ...stage.env };
        if (pythonChildStageOwners.has(stage.stage_id)) {
          stageEnv.PYTHONDONTWRITEBYTECODE = "1";
        }
        if (stage.stage_id === "browser-proof") {
          const browserOutputRoot = process.env.GITHUB_ACTIONS === "true"
            ? path.join(root, "examples/phoenix_host")
            : runRoot;
          stageEnv.CROSSWAKE_REPOSITORY_VERIFY = "1";
          stageEnv.CROSSWAKE_PLAYWRIGHT_REPORT_DIR = path.join(browserOutputRoot, "playwright-report");
          stageEnv.CROSSWAKE_PLAYWRIGHT_RESULT_DIR = path.join(browserOutputRoot, "test-results");
          stageEnv.CROSSWAKE_PLAYWRIGHT_ARTIFACT_DIR = path.join(browserOutputRoot, "playwright-artifacts");
        }
        result = stage.stage_id === "repository-cleanliness" && enforceArtifactPolicy
          ? runRepositoryCleanliness(stage, artifactPolicy, root, spawn, {
              ...options,
              verifyGeneratedContracts
            })
          : spawn(stage.argv[0], stage.argv.slice(1), {
              cwd: path.join(root, stage.cwd),
              env: stageEnv,
              timeout: stage.timeout_ms,
              killSignal: "SIGTERM"
            });
      } catch (error) {
        result = { error, status: null, stdout: "", stderr: "" };
      }
      const outcome = result?.error ? `error=${result.error.code ?? result.error.name ?? "unknown"}` : result?.signal ? `signal=${result.signal}` : `status=${String(result?.status)}`;
      writeFileSync(path.join(runRoot, "logs", `${stage.stage_id}.log`), `${outcome}\n${String(result?.stdout ?? "")}${String(result?.stderr ?? "")}`, { mode: 0o600 });
      const passed = result && !result.error && result.signal == null && Number.isInteger(result.status) && result.status === 0;
      if (!passed && stage.stage_id === "root-proof" && process.env.GITHUB_ACTIONS === "true") emitRootProofFailureTail(outcome, result);
      const stageResult = passed ? "PASS" : "FAIL";
      const diagnostic = !passed && stage.stage_id === "browser-proof" && browserDiagnostic
        ? classifyBrowserFailure(result, browserDiagnostic)
        : !passed && stage.stage_id === "example-host-proof"
          ? classifyExampleHostFailure(result)
          : undefined;
      records.push({
        result: stageResult,
        purpose: stage.stage_id,
        remediation_command: result?.remediation_command ?? stage.remediation_command,
        category: result?.category,
        path: result?.path,
        ...(diagnostic ? { diagnostic } : {})
      });
      if (!passed) { nonpassing.add(stage.stage_id); exitStatus = 1; }
    }
  } finally {
    try {
      cleanupCreatedOutputs(root, createdOutputs);
    } catch {
      setResult(records, "repository-cleanliness", "FAIL", cleanliness.remediation_command);
      exitStatus = 1;
    }
    try {
      const final = gitSnapshot(root, path.join(runRoot, "git-final.z"));
      if (!final.equals(before)) {
        setResult(records, "repository-cleanliness", "FAIL", cleanliness.remediation_command);
        exitStatus = 1;
      }
    } catch {
      setResult(records, "repository-cleanliness", "FAIL", cleanliness.remediation_command);
      exitStatus = 1;
    }
  }

  const output = renderSummary(records);
  if (!suppliedRunRoot) rmSync(runRoot, { recursive: true, force: true });
  return { status: exitStatus, output, records };
}

function parseArgs(argv) {
  if (argv.length === 1 && argv[0] === "--all") return { selection: "all" };
  if (argv.length === 2 && argv[0] === "--stage" && stageIds.includes(argv[1])) return { selection: argv[1] };
  if (argv.length === 1 && argv[0] === "--self-test") return { selfTest: true };
  throw new Error("usage: script/verify_repository.sh (--all | --stage <purpose-id> | --self-test)");
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    const args = parseArgs(process.argv.slice(2));
    if (args.selfTest) {
      const result = spawnSync(process.execPath, ["--test", "test/js/repository_verification.test.mjs"], { cwd: repoRoot, stdio: "inherit" });
      if (result.status !== 0) process.exit(result.status ?? 1);
      console.log("PASS repository-preflight self-test");
    } else {
      const runRoot = process.env.CROSSWAKE_REPOSITORY_RUN_ROOT;
      const captureRoot = process.env.CROSSWAKE_REPOSITORY_CAPTURE_ROOT;
      const result = runVerification({ selection: args.selection, ...(runRoot ? { runRoot, captureRoot } : {}) });
      console.log(result.output);
      process.exitCode = result.status;
    }
  } catch (error) {
    console.error(`FAIL repository-preflight; corrective-command=node --test test/js/repository_verification.test.mjs\n${error.message}`);
    process.exitCode = 1;
  }
}
