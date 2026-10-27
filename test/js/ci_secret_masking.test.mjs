/* REL-03: secret values never reach CI output. Seeds are synthetic and built from fragments at runtime. */
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { maskSecretShapes, ROOT_PROOF_TAIL_BYTES, ROOT_PROOF_TAIL_LINES, rootProofFailureTail, spawnStage } from "../../script/verify_repository.mjs";

const frag = (...parts) => parts.join("");

function seedValues() {
  return {
    authHeader: frag("fake", "Auth", "Hdr", "Val7"),
    bareBearer: frag("fake", "Bare", "Bearer", "Val8"),
    awsUnderscore: frag("fake", "Aws", "Under", "Val9"),
    awsDash: frag("fake", "Aws", "Dash", "Val1"),
    cookie: frag("fake", "Cookie", "Val2"),
    setCookie: frag("fake", "SetCk", "Val3"),
    short: frag("q", "7", "z"),
    gh: frag("gh", "p_", "A".repeat(10), "b".repeat(10), "C".repeat(10), "d".repeat(8)),
    hex: frag("he", "x_", "f".repeat(12), "9".repeat(12))
  };
}

function seedLines(s) {
  return [
    `Authorization: Bearer ${s.authHeader}`,
    `proxy sent Bearer ${s.bareBearer} upstream`,
    `${frag("aws_", "secret_", "access_", "key")}=${s.awsUnderscore}`,
    `${frag("secret-", "access-", "key")}: ${s.awsDash}`,
    `Cookie: session=${s.cookie}`,
    `Set-Cookie: sid=${s.setCookie}; Path=/`,
    `${frag("tok", "en")}=${s.short}`,
    `leaked gh ${s.gh}`,
    `leaked hex ${s.hex}`
  ];
}

export function leakedSecrets(output, seeds) {
  return seeds.filter((seed) => output.includes(seed));
}

const CHILD = `
const { writeSync } = require("node:fs");
const lines = JSON.parse(process.env.CW_SEED_LINES);
for (const l of lines) { writeSync(1, l + "\\n"); writeSync(2, l + "\\n"); }
writeSync(1, "  1) test something (Mod)\\n     Assertion with == failed\\nFinished in 0.1 seconds\\n");
process.exit(2);
`;

function runChildLines(lines) {
  return spawnStage(process.execPath, ["-e", CHILD], {
    env: { PATH: process.env.PATH, CW_SEED_LINES: JSON.stringify(lines) }
  });
}

// Exactly the public tail's normalization/concatenation/line-then-code-unit window, without masking.
// The exported historical BYTE constant bounds JS string units in the production API.
function rawTailWindow(result) {
  const text = `${result.stdout ?? ""}${result.stderr ?? ""}`.replace(/\u001b\[[0-9;?]*[ -/]*[@-~]/g, "");
  return text.split("\n").slice(-ROOT_PROOF_TAIL_LINES).join("\n").slice(-ROOT_PROOF_TAIL_BYTES);
}

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

function workflowCredentialInventory() {
  const listed = spawnSync("git", ["ls-files", "--", ".github/workflows/*.yml", ".github/workflows/*.yaml"], {
    cwd: repoRoot,
    encoding: "utf8"
  });
  if (listed.status !== 0) return { secretNames: [], envAliases: [] };

  const secretNames = new Set();
  const envAliases = new Set();
  const files = listed.stdout.split("\n").filter(Boolean);
  for (const file of files) {
    const source = readFileSync(path.join(repoRoot, file), "utf8");
    for (const match of source.matchAll(/\$\{\{\s*secrets\.([A-Za-z_][A-Za-z0-9_]*)\s*\}\}/g)) secretNames.add(match[1]);
    for (const match of source.matchAll(/\$\{\{\s*secrets\s*\[\s*(["'])([A-Za-z_][A-Za-z0-9_]*)\1\s*\]\s*\}\}/g)) secretNames.add(match[2]);
    if (/\$\{\{\s*github\.token\s*\}\}/i.test(source)) secretNames.add("GITHUB_TOKEN");
    for (const line of source.split("\n")) {
      if (!/\$\{\{\s*(?:secrets(?:\.|\s*\[)|github\.token)/i.test(line)) continue;
      const alias = line.match(/^\s*(?:-\s*)?([A-Za-z_][A-Za-z0-9_]*)\s*:/);
      if (alias) envAliases.add(alias[1]);
    }
  }
  return { secretNames: [...secretNames].sort(), envAliases: [...envAliases].sort() };
}

function round3InventoryRows() {
  const inventory = workflowCredentialInventory();
  let index = 0;
  return [
    ...inventory.secretNames.map((identifier) => ({ kind: "workflow secret name", identifier, seed: frag("fake", "Workflow", "Secret", String(++index).padStart(3, "0"), "Val") })),
    ...inventory.envAliases.map((identifier) => ({ kind: "secret-bound env alias", identifier, seed: frag("fake", "Workflow", "Alias", String(++index).padStart(3, "0"), "Val") }))
  ];
}

const MASK_PERF_CHILD = `
import { maskSecretShapes } from "./script/verify_repository.mjs";
let input = "";
for await (const chunk of process.stdin) input += chunk;
const row = JSON.parse(input);
const fastestMs = (text) => {
  let best = Infinity;
  for (let i = 0; i < 3; i += 1) {
    const started = performance.now();
    maskSecretShapes(text);
    best = Math.min(best, performance.now() - started);
  }
  return best;
};
const prose = "ordinary diagnostic prose ".repeat(Math.ceil(row.input.length / 27)).slice(0, row.input.length);
const baselineMs = fastestMs(prose);
const measuredMs = fastestMs(row.input);
const boundMs = Math.max(250, 10 * baselineMs);
process.stdout.write(JSON.stringify({ label: row.label, length: row.input.length, measuredMs, baselineMs, boundMs }));
if (measuredMs > boundMs) process.exitCode = 2;
`;

function measureRound3Padding(row, source = MASK_PERF_CHILD) {
  const result = spawnSync(process.execPath, ["--input-type=module", "-e", source], {
    cwd: repoRoot,
    env: { PATH: process.env.PATH },
    encoding: "utf8",
    input: JSON.stringify(row),
    timeout: 2000,
    maxBuffer: 64 * 1024
  });
  if (result.error?.code === "ETIMEDOUT") assert.fail(`padding child timed out: ${row.label}`);
  assert.ok(!result.error, `padding child failed: ${row.label}`);
  let metric;
  try { metric = JSON.parse(result.stdout); } catch { assert.fail(`padding child returned no metric: ${row.label}`); }
  assert.ok(metric.label === row.label && result.status === 0, `padding bound failed: ${row.label} (${Math.round(metric.measuredMs)} ms; bound ${Math.round(metric.boundMs)} ms)`);
  return metric;
}

function reportMetric(t, metric) {
  t.diagnostic(`perf-row ${metric.label} length ${metric.length} baseline ${metric.baselineMs.toFixed(3)} candidate ${metric.measuredMs.toFixed(3)} bound ${metric.boundMs.toFixed(3)} ms`);
  if (metric.measuredMs > 25) t.diagnostic(`perf-alert ${metric.label} candidate ${metric.measuredMs.toFixed(3)} ms`);
}

const ROUND3_PADDING_FAMILIES = [
  { name: "token", prefix: "token:" },
  { name: "authorization", prefix: "Authorization:" },
  { name: "cookie", prefix: "Cookie:" },
  { name: "generic", prefix: "password=" },
  { name: "secret_access_key", prefix: "SecretAccessKey:" }
];
const ROUND3_PADDING_WHITESPACE = [
  { name: "space", make: (n) => " ".repeat(n) },
  { name: "tab", make: (n) => "\t".repeat(n) },
  { name: "mixed", make: (n) => " \t".repeat(Math.ceil(n / 2)).slice(0, n) }
];
const ROUND3_PADDING_SIZES = [10000, 20000, 40000, 200000];

test("round3 structural repository signing assignment", () => {
  const rows = [
    { identifier: frag("ORG_GRADLE_PROJECT_", "signing", "InMemory", "Key"), seed: frag("fake", "Repository", "Signing", "Seed", "Val31") },
    { identifier: frag("MIRROR_", "DEPLOY_", "KEY"), seed: frag("fake", "Repository", "Mirror", "Seed", "Val32") },
    { identifier: frag("signing", "InMemory", "Key", "Password"), seed: frag("fake", "Repository", "Signing", "Password", "Val33") },
    { identifier: frag("Secret", "Access", "Key"), seed: frag("fake", "Repository", "Access", "Seed", "Val34") }
  ];
  const result = runChildLines([...rows.map((row) => `${row.identifier}=${row.seed}`), "  1) test something (RepositoryTest)", "Finished in 0.1 seconds"]);
  const raw = `${result.stdout}${result.stderr}`;
  const rawTail = rawTailWindow(result);
  const tail = rootProofFailureTail("failed", result);
  const rawHits = rows.filter((row) => rawTail.includes(row.seed)).length;
  const maskedHits = rows.filter((row) => tail.includes(row.seed)).length;
  const readableNames = rows.filter((row) => tail.includes(row.identifier)).length;
  assert.ok(result.status === 2, "signing child did not fail as required");
  assert.ok(rawHits === rows.length, `raw tail window contains ${rawHits} of ${rows.length} repository signing seeds`);
  assert.ok(maskedHits === 0, `masked tail contains ${maskedHits} of ${rows.length} repository signing seeds`);
  assert.ok(readableNames === rows.length, `tail preserves ${readableNames} of ${rows.length} repository signing identifiers`);
  assert.ok(tail.includes("test something") && tail.includes("Finished in"), "failure diagnostics disappeared");
});

test("round3 inventory all workflow secret names", () => {
  const rows = round3InventoryRows();
  const inventory = workflowCredentialInventory();
  const secretRowCount = rows.filter((row) => row.kind === "workflow secret name").length;
  const aliasRowCount = rows.filter((row) => row.kind === "secret-bound env alias").length;
  assert.ok(inventory.secretNames.length > 0 && secretRowCount === inventory.secretNames.length, "workflow secret-name inventory is empty or incomplete");
  assert.ok(inventory.envAliases.length > 0 && aliasRowCount === inventory.envAliases.length, "secret-bound env-alias inventory is empty or incomplete");
  const lines = rows.map((row) => `${row.identifier}: ${row.seed}`);
  const outcome = runRound3TailRows(rows.map((row, index) => ({ ...row, name: `inventory ${index}`, seeds: [row.seed], line: () => lines[index] })));
  assertRound3TailRows(outcome, "workflow inventory");
  const { result, rawTail, tail } = outcome;
  const rawHits = rows.filter((row) => rawTail.includes(row.seed)).length;
  const maskedHits = rows.filter((row) => tail.includes(row.seed)).length;
  const readableNames = rows.filter((row) => tail.includes(row.identifier)).length;
  assert.ok(result.status === 2, "workflow-inventory child did not fail as required");
  assert.ok(rawHits === rows.length, `raw tail window contains ${rawHits} of ${rows.length} inventory seeds`);
  assert.ok(maskedHits === 0, `masked tail contains ${maskedHits} of ${rows.length} inventory seeds`);
  assert.ok(readableNames === rows.length, `tail preserves ${readableNames} of ${rows.length} inventory identifiers`);
  assert.ok(tail.includes("test something") && tail.includes("Finished in"), "failure diagnostics disappeared");
});

test("round3 padding credential whitespace matrix", { timeout: 55000 }, (t) => {
  let rowCount = 0;
  for (const family of ROUND3_PADDING_FAMILIES) {
    for (const whitespace of ROUND3_PADDING_WHITESPACE) {
      for (const size of ROUND3_PADDING_SIZES) {
        const label = `${family.name}/${whitespace.name}/${size}`;
        const metric = measureRound3Padding({ label, input: `${family.prefix}${whitespace.make(size)}x` });
        rowCount += 1;
        reportMetric(t, metric);
      }
    }
  }
  assert.ok(rowCount > 0, "padding family executed zero rows");
});

const round3Fake = (family, index) => frag("fake", "Round3", family, "Seed", String(index).padStart(2, "0"), "Val");
const ROUND3_CONTAINER_ROWS = [
  { name: "cookie inspect arrow list", line: () => `result: %{"cookie" => ["sid=${round3Fake("CookieMap", 1)}"]}`, seeds: [round3Fake("CookieMap", 1)] },
  { name: "set-cookie inspect arrow list", line: () => `result: %{"set-cookie" => ["sid=${round3Fake("SetCookie", 2)}; path=/"]}`, seeds: [round3Fake("SetCookie", 2)] },
  { name: "request cookies inspect map", line: () => `req_cookies: %{"_app_key" => "${round3Fake("ReqCookies", 3)}"}`, seeds: [round3Fake("ReqCookies", 3)] },
  { name: "response cookies inspect nested map", line: () => `resp_cookies: %{"sid" => %{value: "${round3Fake("RespCookies", 4)}"}}`, seeds: [round3Fake("RespCookies", 4)] },
  { name: "password list with two values", line: () => `password: ["${round3Fake("PasswordList", 5)}", "${round3Fake("PasswordList", 6)}"]`, seeds: [round3Fake("PasswordList", 5), round3Fake("PasswordList", 6)] },
  { name: "tokens list with two values", line: () => `tokens: ["${round3Fake("TokensList", 7)}", "${round3Fake("TokensList", 8)}"]`, seeds: [round3Fake("TokensList", 7), round3Fake("TokensList", 8)] },
  { name: "uppercase sigil", line: () => `token: ~S"${round3Fake("Sigil", 9)}"`, seeds: [round3Fake("Sigil", 9)] },
  { name: "bitstring value", line: () => `token: <<"${round3Fake("Bitstring", 10)}">>`, seeds: [round3Fake("Bitstring", 10)] },
  { name: "nested inspect values", line: () => `password: %{value: "${round3Fake("Nested", 11)}", nested: %{token: "${round3Fake("Nested", 12)}"}}`, seeds: [round3Fake("Nested", 11), round3Fake("Nested", 12)] },
  { name: "nested JSON object", line: () => `{"password": {"v": "${round3Fake("JsonNested", 13)}"}}`, seeds: [round3Fake("JsonNested", 13)] },
  { name: "unquoted multi-word value", line: () => `password: ${round3Fake("Multiword", 14)} ${round3Fake("Multiword", 15)}`, seeds: [round3Fake("Multiword", 14), round3Fake("Multiword", 15)] },
  { name: "CRLF continuation", line: () => `password:\r\n  %{value: "${round3Fake("Crlf", 16)}"}`, seeds: [round3Fake("Crlf", 16)] },
  { name: "ANSI wrapped storage cookie", line: () => `\u001b[31mcookies: [{ name: 'sid', value: '${round3Fake("StorageCookie", 17)}' }]\u001b[0m`, seeds: [round3Fake("StorageCookie", 17)] },
  { name: "malformed nested container", line: () => `password: %{value: "${round3Fake("Malformed", 18)}", nested: ["${round3Fake("Malformed", 19)}"`, seeds: [round3Fake("Malformed", 18), round3Fake("Malformed", 19)] }
];

const ROUND3_NAME_VALUE_ROWS = [
  { name: "JSON token record", line: () => `{"name":"token","value":"${round3Fake("NameValue", 20)}"}`, seeds: [round3Fake("NameValue", 20)], valueKey: '"value"' },
  { name: "JSON uppercase secret record", line: () => `{"name":"SECRET_ACCESS_KEY","value":"${round3Fake("NameValue", 21)}"}`, seeds: [round3Fake("NameValue", 21)], valueKey: '"value"' },
  { name: "JavaScript password record", line: () => `{ name: 'password', value: '${round3Fake("NameValue", 22)}' }`, seeds: [round3Fake("NameValue", 22)], valueKey: "value" },
  { name: "unrelated record control", line: () => `{ name: 'feature', value: 'readable' }`, seeds: [], valueKey: "value", control: true }
];

const LONG_TUPLE_KEY = frag("token_", "x".repeat(80));
const ROUND3_TUPLE_ROWS = [
  { name: "atom tuple wrapped LF", line: () => `{:token,\n  "${round3Fake("Tuple", 23)}"\n}`, seeds: [round3Fake("Tuple", 23)] },
  { name: "quoted tuple wrapped CRLF", line: () => `{"password",\r\n  "${round3Fake("Tuple", 24)}"\r\n}`, seeds: [round3Fake("Tuple", 24)] },
  { name: "long atom tuple", line: () => `{:${LONG_TUPLE_KEY}, "${round3Fake("Tuple", 25)}"}`, seeds: [round3Fake("Tuple", 25)] },
  { name: "tuple container value", line: () => `{:cookie, %{"sid" => ["${round3Fake("Tuple", 26)}"]}}`, seeds: [round3Fake("Tuple", 26)] },
  { name: "tuple sigil value", line: () => `{:token, ~s(${round3Fake("Tuple", 27)})}`, seeds: [round3Fake("Tuple", 27)] }
];

function runRound3TailRows(rows, { diagnosticsBeforeLast = false } = {}) {
  const windows = rows.map((row) => {
    const lines = [row.line()];
    const diagnostics = ["  1) test something (RepositoryTest)", "Finished in 0.1 seconds"];
    if (diagnosticsBeforeLast) lines.unshift(...diagnostics);
    else lines.push(...diagnostics);
    const result = runChildLines(lines);
    return { row, result, rawTail: rawTailWindow(result), tail: rootProofFailureTail("failed", result) };
  });
  const result = { status: windows.every((w) => w.result.status === 2) ? 2 : -1 };
  const seeds = rows.flatMap((row) => row.seeds);
  return { result, rows, seeds, windows, rawTail: windows.map((w) => w.rawTail).join("\n"), tail: windows.map((w) => w.tail).join("\n") };
}

function assertRound3TailRows(outcome, family) {
  const rawHits = outcome.seeds.filter((seed) => outcome.rawTail.includes(seed)).length;
  const maskedHits = outcome.seeds.filter((seed) => outcome.tail.includes(seed)).length;
  const leakingRows = outcome.rows.filter((row) => row.seeds.some((seed) => outcome.tail.includes(seed))).map((row) => row.name);
  assert.ok(outcome.rows.length > 0 && outcome.seeds.length > 0, `${family} family executed zero rows`);
  assert.ok(outcome.result.status === 2, `${family} child did not fail as required`);
  assert.ok(rawHits === outcome.seeds.length, `${family} raw tail window contains ${rawHits} of ${outcome.seeds.length} seeds`);
  for (const window of outcome.windows ?? []) assert.ok(window.row.seeds.every((seed) => window.rawTail.includes(seed)), `${family} raw tail window missing a row seed`);
  assert.ok(maskedHits === 0, `${family} masked tail contains ${maskedHits} of ${outcome.seeds.length} seeds (${leakingRows.join(", ")})`);
}

test("round3 container inspect values", () => {
  const outcome = runRound3TailRows(ROUND3_CONTAINER_ROWS, { diagnosticsBeforeLast: true });
  assertRound3TailRows(outcome, "container inspect");
  assert.ok(outcome.tail.includes("test something") && outcome.tail.includes("Finished in"), "complete-container diagnostics disappeared");
});

test("round3 name-value record isolation", () => {
  const outcome = runRound3TailRows(ROUND3_NAME_VALUE_ROWS);
  assertRound3TailRows(outcome, "name-value record");
  const keyRows = outcome.rows.filter((row) => row.valueKey);
  const preservedKeys = keyRows.filter((row) => outcome.tail.includes(row.valueKey)).length;
  assert.ok(preservedKeys === keyRows.length, `tail preserves ${preservedKeys} of ${keyRows.length} value keys`);
  assert.ok(outcome.tail.includes("readable"), "unrelated name-value record changed");
});

test("round3 tuple wrapped values", () => {
  const outcome = runRound3TailRows(ROUND3_TUPLE_ROWS);
  assertRound3TailRows(outcome, "tuple wrapped values");
  assert.ok(outcome.tail.includes("test something") && outcome.tail.includes("Finished in"), "tuple diagnostics disappeared");
});

function runSeededChild(s) {
  return runChildLines(seedLines(s));
}

test("seeded secrets from a spawned child never reach the root-proof tail", () => {
  const s = seedValues();
  const seeds = Object.values(s);
  const result = runSeededChild(s);
  assert.equal(result.status, 2);
  const raw = `${result.stdout}${result.stderr}`;
  assert.equal(leakedSecrets(raw, seeds).length, seeds.length, "detector must see every seed in raw output");
  const tail = rootProofFailureTail("failed", result);
  const leaked = leakedSecrets(tail, seeds);
  assert.ok(leaked.length === 0, `leaked: ${leaked.length} seeded value(s) reached the tail`);
});

// ---------------------------------------------------------------------------------------------
// Gap shapes (195-14): one row per leak shape. Every seed is fragment-built, at least 8 characters,
// fake/FAKE-prefixed and unique, so a substring match cannot pass or fail by accident. Assertions
// that can see a seed are assert.ok on a computed boolean with a shape-and-count message, because
// node:test prints comparison operands and a red CI log is public.
// ---------------------------------------------------------------------------------------------
const AWS_KEY = frag("AWS_", "SECRET_", "ACCESS_", "KEY");
const AWS_KEY_LOWER = frag("secret_", "access_", "key");
const gapAwsDq = frag("fake", "Dq", "Quoted", "Val1");
const gapAwsSq = frag("fake", "Sq", "Quoted", "Val2");
const PW = frag("pass", "word");
const TK = frag("tok", "en");
const SKB = frag("SECRET_", "KEY_", "BASE");
const BS = String.fromCharCode(92);
const mwA = frag("fake", "Multi", "Alpha1");
const mwB = frag("fake", "Multi", "Bravo2");
const mwC = frag("fake", "Multi", "Charlie3");
const jsA = frag("fake", "Json", "Alpha4");
const jsB = frag("fake", "Json", "Bravo5");
const exA = frag("fake", "Arrow", "Alpha6");
const exB = frag("fake", "Arrow", "Bravo7");
const kwA = frag("fake", "Kwlist", "Alpha8");
const kwB = frag("fake", "Kwlist", "Bravo9");
const skbV = frag("fake", "Skb", "Value10");
const escA = frag("fake", "Esc", "First11");
const escB = frag("fake", "Esc", "Second12");
const unA = frag("fake", "Unterm", "First13");
const unB = frag("fake", "Unterm", "Second14");
const ckV = frag("fake", "Cookie", "Curl15");
const scV = frag("fake", "Setck", "Curl16");
const dgV = frag("fake", "Digest", "Resp17");
const uiV = frag("fake", "Userinfo", "Pw18");
const jwA = frag("fake", "Jwt", "Head19");
const jwB = frag("fake", "Jwt", "Body20");
const jwC = frag("fake", "Jwt", "Sig21");
const kidV = frag("FAKE", "KEYID", "1234567");
const ejA = frag("fake", "Escjson", "Alpha22");
const ejB = frag("fake", "Escjson", "Bravo23");
const eaV = frag("fake", "Escauth", "Val24");
const tpV = frag("fake", "Tup", "Atom25");
const tqA = frag("fake", "Tup", "Quoted26");
const tqB = frag("fake", "Tup", "Quoted27");
const taV = frag("fake", "Tup", "Auth28");
const bqV = frag("fake", "Bear", "Quote29");
const brV = frag("fake", "Bear", "Realm30");
const nlV = frag("fake", "Next", "Line31");
const ncV = frag("fake", "Next", "Crlf32");
const ybA = frag("fake", "Yaml", "Block33");
const ybB = frag("fake", "Yaml", "Block34");
const cfV = frag("fake", "Cli", "Flag35");
const cqA = frag("fake", "Cli", "Quoted36");
const cqB = frag("fake", "Cli", "Quoted37");
const cuV = frag("fake", "Curl", "Short38");
const clV = frag("fake", "Curl", "Long39");
const tdV = frag("fake", "Double", "Eq40");
const SK = frag("s", "k-");
const XOXB = frag("xo", "xb-");
const NPM = frag("np", "m_");
const GHP = frag("gh", "p_");
const skpV = frag("fake", "Skp", "Proj41");
const skvV = frag("fake", "Skv", "Ant42");
const xbV = frag("fake", "Xox", "Bot43");
const npmV = frag("fake", "Npm", "Tok44", "x".repeat(24));
// PEM markers are assembled so no source line holds a contiguous five-dash marker or key-block literal.
const DASH5 = "-".repeat(5);
const PEM_B = frag(DASH5, "BEG", "IN ", "PRIV", "ATE", " KEY", DASH5);
const PEM_E = frag(DASH5, "EN", "D ", "PRIV", "ATE", " KEY", DASH5);
const PEM_BR = frag(DASH5, "BEG", "IN ", "RSA ", "PRIV", "ATE", " KEY", DASH5);
const PEM_BE = frag(DASH5, "BEG", "IN ", "ENCRYPTED ", "PRIV", "ATE", " KEY", DASH5);
const PEM_EE = frag(DASH5, "EN", "D ", "ENCRYPTED ", "PRIV", "ATE", " KEY", DASH5);
const PEM_IV = frag("A1B2", "C3D4", "E5F6", "0718", "9A0B", "1C2D", "3E4F", "5061");
const pemB1 = frag("fake", "Pem", "Body51");
const pemB2 = frag("fake", "Pem", "Body52");
const pemB3 = frag("fake", "Pem", "Body53");
const pemB4 = frag("fake", "Pem", "Body54");
const pemB5 = frag("fake", "Pem", "Body55");
const PGP_BEGIN = frag(DASH5, "BEG", "IN ", "PGP ", "PRIV", "ATE ", "KEY ", "BLOCK", DASH5);
const PGP_END = frag(DASH5, "END PGP ", "PRIV", "ATE ", "KEY ", "BLOCK", DASH5);
const OTHER_PRIVATE_KEY_END = frag(DASH5, "END RSA ", "PRIV", "ATE ", "KEY", DASH5);
const round3ArmorFake = (index) => frag("fake", "Round3", "Armor", "Seed", String(index).padStart(2, "0"), "Val");
const ROUND3_ARMOR_COMPLETE_ROWS = [
  { name: "PGP ordinary LF with blank body line", line: () => `${PGP_BEGIN}  \n\n  ${round3ArmorFake(31)}!?\n${PGP_END}\nAFTER_ARMOR_SAFE_LF`, seeds: [round3ArmorFake(31)], after: "AFTER_ARMOR_SAFE_LF" },
  { name: "PGP same-line body and end", line: () => `${PGP_BEGIN}${round3ArmorFake(32)}${PGP_END}\nAFTER_ARMOR_SAFE_SAME_LINE`, seeds: [round3ArmorFake(32)], after: "AFTER_ARMOR_SAFE_SAME_LINE" },
  { name: "PGP arbitrary timestamp prefix and body alphabet", line: () => `2026-10-26T12:00:00Z WARN ${PGP_BEGIN}\nbody-${round3ArmorFake(33)}_+/=?\n${PGP_END}\nAFTER_ARMOR_SAFE_PREFIX`, seeds: [round3ArmorFake(33)], after: "AFTER_ARMOR_SAFE_PREFIX" },
  { name: "existing private key CRLF with whitespace body", line: () => `${PEM_B} \r\n \r\n${round3ArmorFake(34)} !?\r\n${PEM_E}\r\nAFTER_ARMOR_SAFE_CRLf`, seeds: [round3ArmorFake(34)], after: "AFTER_ARMOR_SAFE_CRLf" },
  { name: "PGP bare CR layout", line: () => `${PGP_BEGIN}\r${round3ArmorFake(35)}\r${PGP_END}\rAFTER_ARMOR_SAFE_CR`, seeds: [round3ArmorFake(35)], after: "AFTER_ARMOR_SAFE_CR" },
  { name: "PGP literal backslash newline layout", line: () => `${PGP_BEGIN}${String.fromCharCode(92)}n${round3ArmorFake(36)}${String.fromCharCode(92)}n${PGP_END}${String.fromCharCode(92)}nAFTER_ARMOR_SAFE_LITERAL`, seeds: [round3ArmorFake(36)], after: "AFTER_ARMOR_SAFE_LITERAL" },
  { name: "PGP double-escaped newline layout", line: () => `${PGP_BEGIN}${String.fromCharCode(92).repeat(2)}n${round3ArmorFake(37)}${String.fromCharCode(92).repeat(2)}n${PGP_END}${String.fromCharCode(92).repeat(2)}nAFTER_ARMOR_SAFE_DOUBLE`, seeds: [round3ArmorFake(37)], after: "AFTER_ARMOR_SAFE_DOUBLE" },
  { name: "PGP prefixed same-line body", line: () => `[ci] ${PGP_BEGIN} ${round3ArmorFake(38)} ${PGP_END}\nAFTER_ARMOR_SAFE_PREFIXED_SAME`, seeds: [round3ArmorFake(38)], after: "AFTER_ARMOR_SAFE_PREFIXED_SAME" }
];
const ROUND3_ARMOR_INCOMPLETE_ROWS = [
  { name: "PGP missing end", line: () => `${PGP_BEGIN}\n${round3ArmorFake(39)}\nmissing end body remains hidden`, seeds: [round3ArmorFake(39)] },
  { name: "PGP mismatched end label", line: () => `${PGP_BEGIN}\n${round3ArmorFake(40)}\n${OTHER_PRIVATE_KEY_END}\nwrong end must remain hidden`, seeds: [round3ArmorFake(40)] }
];

test("round3 private key armor complete layouts", (t) => {
  let rowCount = 0;
  for (const row of ROUND3_ARMOR_COMPLETE_ROWS) {
    const outcome = runRound3TailRows([row]);
    assertRound3TailRows(outcome, row.name);
    assert.ok(outcome.tail.includes(row.after), `${row.name} lost safe post-END diagnostics`);
    rowCount += 1;
  }
  assert.ok(rowCount > 0, "private-key armor family executed zero rows");
});

test("round3 private key armor malformed boundaries", () => {
  let rowCount = 0;
  for (const row of ROUND3_ARMOR_INCOMPLETE_ROWS) {
    const outcome = runRound3TailRows([row], { diagnosticsBeforeLast: true });
    assertRound3TailRows(outcome, row.name);
    assert.ok(outcome.tail.includes("test something") && outcome.tail.includes("Finished in"), `${row.name} lost preceding failure diagnostics`);
    rowCount += 1;
  }
  assert.ok(rowCount > 0, "malformed armor family executed zero rows");
});

test("round3 armor bounded adversaries", (t) => {
  const bs = String.fromCharCode(92);
  const rows = [
    { label: "armor/repeated-begin", input: `${`${PGP_BEGIN}\n`.repeat(5000)}body` },
    { label: "armor/missing-end", input: `${PGP_BEGIN}\n${"A".repeat(200000)}` },
    { label: "armor/mixed-prefix-escape", input: `[ci] ${PGP_BEGIN}${bs.repeat(2)}n${"A".repeat(80)}${bs}n${PGP_END}${bs.repeat(2)}n`.repeat(1000) }
  ];
  for (const row of rows) {
    const metric = measureRound3Padding(row);
    reportMetric(t, metric);
  }
  assert.ok(rows.length > 0, "armor bounded family executed zero rows");
});

const ueV = frag("fake", "Userinfo", "Empty56");
const usA = frag("fake", "Userinfo", "Slash57");
const usB = frag("fake", "Userinfo", "Slash58");
const kidPre = frag("FAKE", "PREFIX", "123456");
const kidTrail = frag("FAKE", "TRAIL", "1234567");
const j2A = frag("fake", "Jwt", "Two59");
const j2B = frag("fake", "Jwt", "Two60");
const qkV = frag("fake", "Query", "Key61");
const qsV = frag("fake", "Query", "Sig62");
const qaV = frag("fake", "Query", "Amz63");
const ckaV = frag("fake", "Cookie", "Assign64");
const ckhV = frag("fake", "Cookies", "Head65");
const scrV = frag("fake", "Secrets", "Assign66");
const pkV = frag("fake", "Privkey", "Assign67");
const pwsV = frag("fake", "Passwords", "Assign68");
const litV = frag("fake", "Literal", "Prefixed69");

export const GAP_SHAPES = [
  {
    name: "aws_key_double_quoted",
    seeds: [gapAwsDq],
    line: `${AWS_KEY}="${gapAwsDq}"`,
    expected: `${AWS_KEY}="***"`
  },
  {
    name: "aws_key_single_quoted",
    seeds: [gapAwsSq],
    line: `${AWS_KEY_LOWER} = '${gapAwsSq}'`,
    expected: `${AWS_KEY_LOWER} = '***'`
  },
  {
    name: "password_multiword_quoted",
    seeds: [mwA, mwB, mwC],
    line: `${PW} = "${mwA} ${mwB} ${mwC}"`,
    expected: `${PW} = "***"`
  },
  {
    name: "json_password_multiword",
    seeds: [jsA, jsB],
    line: `{"${PW}":"${jsA} ${jsB}"}`,
    expected: `{"${PW}":"***"}`
  },
  {
    name: "elixir_map_arrow",
    seeds: [exA, exB],
    line: `%{"${PW}" => "${exA} ${exB}"}`,
    expected: `%{"${PW}" => "***"}`
  },
  {
    name: "elixir_keyword_multiword",
    seeds: [kwA, kwB],
    line: `[${PW}: "${kwA} ${kwB}"]`,
    expected: `[${PW}: "***"]`
  },
  {
    name: "secret_key_base",
    seeds: [skbV],
    line: `${SKB}=${skbV}`,
    expected: `${SKB}=***`
  },
  {
    name: "escaped_quote_value",
    seeds: [escA, escB],
    line: `${PW} = "${escA}${BS}"${escB}"`,
    expected: `${PW} = "***"`
  },
  {
    name: "unterminated_quote_value",
    seeds: [unA, unB],
    line: `${TK} = "${unA} ${unB}`,
    expected: `${TK} = "***`
  },
  {
    name: "cookie_midline_curl",
    seeds: [ckV],
    line: `curl -H "Cookie: sid=${ckV}" https://host.example/x`,
    expected: `curl -H "Cookie: ***`
  },
  {
    name: "set_cookie_curl_verbose",
    seeds: [scV],
    line: `< Set-Cookie: sid=${scV}; HttpOnly`,
    expected: `< Set-Cookie: ***`
  },
  {
    name: "digest_authorization",
    seeds: [dgV],
    line: `Authorization: Digest username="u", response="${dgV}"`,
    expected: `Authorization: ***`
  },
  {
    name: "url_userinfo",
    seeds: [uiV],
    line: `fetch https://user:${uiV}@host.example/repo.git`,
    expected: `fetch https://user:***@host.example/repo.git`
  },
  {
    name: "jwt",
    seeds: [jwA, jwB, jwC],
    line: `got eyJ${jwA}.${jwB}.${jwC} end`,
    expected: `got eyJ*** end`
  },
  {
    name: "aws_access_key_id",
    seeds: [kidV],
    line: `key id AKIA${kidV}`,
    expected: `key id AKIA***`
  },
  {
    name: "escaped_json_multiword",
    seeds: [ejA, ejB],
    line: `{${BS}"${PW}${BS}":${BS}"${ejA} ${ejB}${BS}"}`,
    expected: `{${BS}"${PW}${BS}":${BS}"***${BS}"}`
  },
  {
    name: "escaped_json_authorization",
    seeds: [eaV],
    line: `{${BS}"authorization${BS}":${BS}"Bearer ${eaV}${BS}"}`,
    expected: `{${BS}"authorization${BS}":***`
  },
  {
    name: "elixir_tuple_atom",
    seeds: [tpV],
    line: `{:${TK}, "${tpV}"}`,
    expected: `{:${TK}, "***"}`
  },
  {
    name: "elixir_tuple_quoted_key",
    seeds: [tqA, tqB],
    line: `{"${PW}", "${tqA} ${tqB}"}`,
    expected: `{"${PW}", "***"}`
  },
  {
    name: "elixir_tuple_authorization",
    seeds: [taV],
    line: `{"authorization", "Basic ${taV}"}`,
    expected: `{"authorization", "***"}`
  },
  {
    name: "bearer_quoted",
    seeds: [bqV],
    line: `sent Bearer "${bqV}" upstream`,
    expected: `sent Bearer "***" upstream`
  },
  {
    name: "bearer_realm",
    seeds: [brV],
    line: `WWW-Authenticate: Bearer realm="${brV}"`,
    expected: `WWW-Authenticate: Bearer ***`
  },
  {
    name: "next_line_value",
    seeds: [nlV],
    line: `${PW}:\n  ${nlV}`,
    expected: `${PW}:\n  ***`
  },
  {
    name: "next_line_value_crlf",
    seeds: [ncV],
    line: `${PW}:\r\n  ${ncV}`,
    expected: `${PW}:\r\n  ***`
  },
  {
    name: "yaml_block_scalar",
    seeds: [ybA, ybB],
    line: `${PW}: |\n  ${ybA}\n  ${ybB}\nnext: ok`,
    expected: `${PW}: |\n  ***\n  ***\nnext: ok`
  },
  {
    name: "cli_flag_space",
    seeds: [cfV],
    line: `run --${PW} ${cfV} --verbose`,
    expected: `run --${PW} *** --verbose`
  },
  {
    name: "cli_flag_quoted",
    seeds: [cqA, cqB],
    line: `run --api-key "${cqA} ${cqB}" --verbose`,
    expected: `run --api-key "***" --verbose`
  },
  {
    name: "curl_user_short",
    seeds: [cuV],
    line: `curl -u deploy:${cuV} https://host.example/x`,
    expected: `curl -u deploy:*** https://host.example/x`
  },
  {
    name: "curl_user_long",
    seeds: [clV],
    line: `curl --user deploy:${clV} https://host.example/x`,
    expected: `curl --user deploy:*** https://host.example/x`
  },
  {
    name: "token_double_equals",
    seeds: [tdV],
    line: `assert ${TK} == "${tdV}"`,
    expected: `assert ${TK} == "***"`
  },
  {
    name: "sk_project_key",
    seeds: [skpV],
    line: `use ${SK}proj-${skpV} now`,
    expected: `use ${SK}*** now`
  },
  {
    name: "sk_versioned_key",
    seeds: [skvV],
    line: `use ${SK}ant-api03-${skvV} now`,
    expected: `use ${SK}*** now`
  },
  {
    name: "slack_bot_token",
    seeds: [xbV],
    line: `slack ${XOXB}${xbV} sent`,
    expected: `slack ${XOXB}*** sent`
  },
  {
    name: "npm_token",
    seeds: [npmV],
    line: `npm ${NPM}${npmV} ok`,
    expected: `npm ${NPM}*** ok`
  },
  {
    name: "pem_multiline",
    seeds: [pemB1, pemB2],
    line: `${PEM_B}\n${pemB1}\n${pemB2}\n${PEM_E}\nafter pem line`,
    expected: `${PEM_B}***\nafter pem line`
  },
  {
    name: "pem_no_end",
    seeds: [pemB3],
    line: `${PEM_BR}\n${pemB3}\nFinished in 0.1 seconds`,
    expected: `${PEM_BR}***`
  },
  {
    name: "pem_escaped_newlines",
    seeds: [pemB4],
    line: `"${PEM_B}${BS}n${pemB4}${BS}n${PEM_E}${BS}n"`,
    expected: `"${PEM_B}***${BS}n"`
  },
  {
    name: "pem_encrypted_headers",
    seeds: [pemB5],
    line: `${PEM_BE}\nProc-Type: 4,ENCRYPTED\nDEK-Info: AES-128-CBC,${PEM_IV}\n\n${pemB5}\n${PEM_EE}`,
    expected: `${PEM_BE}***`
  },
  {
    name: "url_empty_user",
    seeds: [ueV],
    line: `fetch https://:${ueV}@host.example/x`,
    expected: `fetch https://:***@host.example/x`
  },
  {
    name: "url_slash_password",
    seeds: [usA, usB],
    line: `fetch https://user:${usA}/${usB}@host.example/x`,
    expected: `fetch https://user:***@host.example/x`
  },
  {
    name: "aws_key_id_prefixed",
    seeds: [kidPre],
    line: `key_AKIA${kidPre}`,
    expected: `key_AKIA***`
  },
  {
    name: "aws_key_id_trailing",
    seeds: [kidTrail],
    line: `id AKIA${kidTrail}QQ`,
    expected: `id AKIA***QQ`
  },
  {
    name: "jwt_two_segment",
    seeds: [j2A, j2B],
    line: `got eyJ${j2A}.${j2B} end`,
    expected: `got eyJ*** end`
  },
  {
    name: "query_key",
    seeds: [qkV],
    line: `GET /x?key=${qkV}&page=2`,
    expected: `GET /x?key=***&page=2`
  },
  {
    name: "query_sig",
    seeds: [qsV],
    line: `GET /x?a=1&sig=${qsV}`,
    expected: `GET /x?a=1&sig=***`
  },
  {
    name: "amz_signature",
    seeds: [qaV],
    line: `GET /x?X-Amz-Signature=${qaV}`,
    expected: `GET /x?X-Amz-Signature=***`
  },
  {
    name: "cookie_assign",
    seeds: [ckaV],
    line: `cookie=${ckaV}`,
    expected: `cookie=***`
  },
  {
    name: "cookies_header",
    seeds: [ckhV],
    line: `cookies: ${ckhV}`,
    expected: `cookies: ***`
  },
  {
    name: "secrets_assign",
    seeds: [scrV],
    line: `secrets=${scrV}`,
    expected: `secrets=***`
  },
  {
    name: "privatekey_assign",
    seeds: [pkV],
    line: `privatekey=${pkV}`,
    expected: `privatekey=***`
  },
  {
    name: "passwords_assign",
    seeds: [pwsV],
    line: `passwords=${pwsV}`,
    expected: `passwords=***`
  },
  {
    name: "literal_prefixed_value",
    seeds: [litV],
    line: `${TK}: nil${litV}`,
    expected: `${TK}: ***`
  }
];

const gapSeedCount = () => GAP_SHAPES.reduce((n, row) => n + row.seeds.length, 0);

for (const row of GAP_SHAPES) {
  test(`gap shape ${row.name} is masked`, () => {
    const masked = maskSecretShapes(row.line);
    const rawHasAll = leakedSecrets(row.line, row.seeds).length === row.seeds.length;
    const maskedHits = leakedSecrets(masked, row.seeds).length;
    assert.ok(rawHasAll, `gap shape ${row.name}: detector missed a seed in the raw line`);
    assert.ok(maskedHits === 0, `gap shape ${row.name}: ${maskedHits} of ${row.seeds.length} seeds present after masking`);
    if (masked !== row.expected) {
      let mismatchAt = 0;
      while (mismatchAt < Math.min(masked.length, row.expected.length) && masked[mismatchAt] === row.expected[mismatchAt]) mismatchAt += 1;
      const expectedCode = row.expected.codePointAt(mismatchAt) ?? -1;
      const actualCode = masked.codePointAt(mismatchAt) ?? -1;
      assert.ok(false, `gap shape ${row.name}: output differs at ${mismatchAt}, expected/actual lengths ${row.expected.length}/${masked.length}, code points ${expectedCode}/${actualCode}`);
    }
  });
}

test("gap seeds are distinctive", () => {
  const seen = new Set();
  for (const row of GAP_SHAPES) {
    for (const seed of row.seeds) {
      const fail = (rule) => assert.ok(false, `indistinct seed in ${row.name}: ${rule}`);
      if (seed.length < 8) fail("shorter than 8 characters");
      if (!/^(fake[A-Z]|FAKE[A-Z0-9])/.test(seed)) fail("missing fake/FAKE prefix");
      if (seen.has(seed)) fail("not unique across rows");
      seen.add(seed);
      if (CHILD.includes(seed)) fail("appears in the child script text");
      for (const other of GAP_SHAPES) {
        if (other.expected.includes(seed)) fail("appears in an expected string");
        if (other !== row && other.line.includes(seed)) fail("appears in another row's line");
      }
    }
  }
});

test("gap shapes from a spawned child never reach the root-proof tail", () => {
  assertRound3TailRows(runRound3TailRows(GAP_SHAPES.map((row) => ({ ...row, line: () => row.line }))), "gap shapes");
});

const PROSE_LINES = [
  { name: "boolean container", text: "{:ok, %{token: true, password: nil}}" },
  { name: "short numeric container", text: "{:ok, %{token: 1}}" },
  { name: "token expired for user", text: "token expired for user" },
  { name: "password mismatch for account", text: "password mismatch for account" },
  { name: "secret not found in vault", text: "secret not found in vault" },
  { name: "authorization failed for request", text: "authorization failed for request" },
  { name: "cookie jar is empty", text: "cookie jar is empty" },
  { name: "  1) test token refresh rejects expired password (Crosswake.AuthTest)", text: "  1) test token refresh rejects expired password (Crosswake.AuthTest)" },
  { name: "token_count: 300", text: "token_count: 300" },
  { name: "the api key rotation runs nightly", text: "the api key rotation runs nightly" },
  { name: "token: ok", text: "token: ok" },
  { name: "bearer_line_end", text: "auth scheme is Bearer\nnextline stays visible" },
  { name: "invalid token, retrying now", text: "invalid token, retrying now" },
  { name: "password, then username", text: "password, then username" },
  { name: "use --password-file ./pw.txt for input", text: "use --password-file ./pw.txt for input" },
  { name: "key_before_test_line", text: "last field password:\n  1) test login works (AuthTest)" },
  { name: "key_before_finished_line", text: "token=\nFinished in 0.2 seconds" },
  { name: "task-runner12345 started", text: "task-runner12345 started" },
  { name: "kiosk-mode-settings applied", text: "kiosk-mode-settings applied" },
  { name: "npm_config_cache is set", text: "npm_config_cache is set" },
  { name: "token: nil", text: "token: nil" },
  { name: "password: nil", text: "password: nil" },
  { name: "token: true", text: "token: true" },
  { name: "password: false", text: "password: false" },
  { name: '"token":null', text: '"token":null' },
  { name: "token: undefined", text: "token: undefined" },
  { name: "%{token: nil, password: nil}", text: "%{token: nil, password: nil}" },
  { name: "preauthorization: pending review", text: "preauthorization: pending review" }
];

// Over-masks accepted as the safe direction. Each is pinned exactly so it can never drift silently.
const ACCEPTED_OVERMASK = [
  { name: "bearer_required", text: "bearer token is required", expected: "bearer *** is required", reason: "a short bearer value cannot be distinguished from the word token" },
  { name: "bearer_authentication_error", text: "Bearer authentication failed", expected: "Bearer *** failed", reason: "short bearer credentials retain protection" },
  { name: "bearer_scheme_error", text: "the Bearer scheme is not supported", expected: "the Bearer *** is not supported", reason: "scheme is indistinguishable from a short bearer value" },
  { name: "changeset_minimum", text: "password: should be at least 12 character(s)", expected: "password: ***", reason: "credential assignment context consumes the complete diagnostic value" },
  { name: "changeset_blank", text: "* password: can't be blank", expected: "* password: ***", reason: "the full value is hidden without tearing at the apostrophe" },
  { name: "invalid_token_error", text: "** (ArgumentError) invalid token: expected a binary", expected: "** (ArgumentError) invalid token: ***", reason: "credential assignment prose is indistinguishable from a multiword secret" },
  { name: "refresh_token_prose", text: "refresh token: rotated", expected: "refresh token: ***", reason: "short assignment values remain protected" },
  { name: "use_token_prose", text: "use token: foo", expected: "use token: ***", reason: "short assignment values remain protected" },
  { name: "cookie_number", text: "cookie: 1", expected: "cookie: ***", reason: "cookie header content is opaque" },
  { name: "credential_missing", text: "credential: missing", expected: "credential: ***", reason: "credential assignment content is opaque" },
  { name: "numeric_token", text: "token: 123", expected: "token: ***", reason: "numeric secrets are possible" },
  { name: "numeric_tuple", text: "{:token, 123}", expected: "{:token, ***}", reason: "numeric secrets remain hidden while the known tuple closer survives" },
  { name: "atom_container", text: "[token: :bad]", expected: "[token: ***]", reason: "atom-valued secrets remain hidden while the known list closer survives" },
  { name: "jwt_version_prose", text: "version eyJ1.2", expected: "version eyJ***", reason: "a short JWT-shaped version cannot safely be distinguished" },
  { name: "jwt_word_prose", text: "eyJhello.world", expected: "eyJ***", reason: "JWT-shaped diagnostic words remain masked" },
  { name: "lone_private_key_marker", text: PEM_B, expected: `${PEM_B}***`, reason: "unterminated armor deliberately consumes EOF" },
  { name: "ps_user_flag", text: "ps -u root:wheel", expected: "ps -u root:***", reason: "the existing separated user flag contract conservatively covers commandless diagnostics" },
  { name: "short_user_flag", text: "-u admin:admin", expected: "-u admin:***", reason: "commandless short user credentials remain protected" },
  { name: "code_assert_token_equals", text: 'code: assert token == "expected-value"', expected: 'code: assert token == "***"' },
  { name: "key_then_plain_line", text: "enter password:\nnext line text", expected: "enter password:\n***" },
  { name: "cli_negated_flag", text: "run --no-password prompt", expected: "run --no-password ***" },
  { name: "url_port_scoped_path", text: "https://registry.example:443/@scope/pkg", expected: "https://registry.example:***@scope/pkg" },
  { name: "secrets_inherit", text: "secrets: inherit", expected: "secrets: ***" },
  { name: "numeric_value", text: "max_token: 1000", expected: "max_token: ***" },
  { name: "authorization_header_prose", text: "Authorization: required for route", expected: "Authorization: ***" },
  { name: "cookie_colon_prose", text: "stale cookie: expired at line", expected: "stale cookie: ***" },
  { name: "private_key_missing_end_consumes_eof", text: `${PGP_BEGIN}\n${round3ArmorFake(41)}\nAFTER_ARMOR_MALFORMED_LOST`, expected: `${PGP_BEGIN}***`, reason: "without a matching END marker, later diagnostic content has no trusted boundary" },
  { name: "private_key_mismatched_end_consumes_eof", text: `${PGP_BEGIN}\n${round3ArmorFake(42)}\n${OTHER_PRIVATE_KEY_END}\nAFTER_ARMOR_MISMATCH_LOST`, expected: `${PGP_BEGIN}***`, reason: "a different key label does not close the armor block, so later content is consumed" }
];

for (const row of ACCEPTED_OVERMASK) {
  test(`accepted over-mask pinned: ${row.name}`, () => {
    if (row.name.startsWith("private_key_")) assert.ok(row.reason, `accepted over-mask ${row.name} needs a rationale`);
    assert.ok(maskSecretShapes(row.text) === row.expected, `accepted over-mask ${row.name} drifted`);
  });
}

for (const row of PROSE_LINES) {
  test(`prose round-trips unchanged: ${row.name}`, () => {
    assert.ok(maskSecretShapes(row.text) === row.text, `prose row ${row.name} changed`);
  });
}

const LINEAR_INPUTS = [
  { name: "blank_lines", input: () => "\n".repeat(200000) },
  { name: "whitespace_lines", input: () => " \t\n".repeat(100000) },
  { name: "keyword_no_separator", input: () => "token ".repeat(100000) },
  { name: "unterminated_quote", input: () => `${PW} = "` + "a b ".repeat(100000) },
  { name: "userinfo_no_at", input: () => "https://" + "u:".repeat(100000) },
  { name: "jwt_segments", input: () => "eyJaaaaa.".repeat(100000) },
  { name: "jwt_hyphen_run", input: () => "eyJ-".repeat(50000) },
  { name: "escaped_key_repeat", input: () => `${BS}"${PW}${BS}":`.repeat(30000) },
  { name: "escaped_value_backslashes", input: () => `{${BS}"${PW}${BS}":${BS}"` + BS.repeat(200000) },
  { name: "tuple_comma_repeat", input: () => `{:${TK}, `.repeat(30000) },
  { name: "cli_flag_repeat", input: () => `--${PW} `.repeat(30000) },
  { name: "curl_user_repeat", input: () => "-u a:".repeat(50000) },
  { name: "nextline_keys", input: () => `${PW}:\n`.repeat(30000) },
  { name: "bearer_quote_unterminated", input: () => 'Bearer "' + "a b ".repeat(100000) },
  { name: "double_equals_repeat", input: () => `${TK} ==`.repeat(40000) },
  { name: "sk_dash_run", input: () => `${SK}` + "-a".repeat(100000) },
  { name: "xox_repeat", input: () => XOXB.repeat(40000) },
  { name: "pem_body_no_end", input: () => PEM_B + "\nAAAA".repeat(40000) },
  { name: "pem_begin_repeat", input: () => PEM_B.repeat(8000) },
  { name: "pem_escaped_run", input: () => PEM_B + `${BS}nA`.repeat(70000) },
  { name: "userinfo_repeated_scheme", input: () => "://a:".repeat(50000) },
  { name: "query_key_repeat", input: () => "?key=".repeat(50000) },
  { name: "akia_run", input: () => "AKIA".repeat(50000) },
  { name: "backslash_run", input: () => `${PW} = "` + BS.repeat(200000) },
  { name: "doubled_quotes", input: () => `${PW} = ` + '""'.repeat(100000) },
  { name: "escaped_quote_run", input: () => `${PW} = "` + `${BS}"`.repeat(100000) },
  { name: "mixed_quotes", input: () => `${PW} = '` + `"'${BS}`.repeat(70000) },
  { name: "literal_exemption_repeat", input: () => `${TK}: nil `.repeat(20000) }
];

// Fresh minimum-of-three baseline and candidate per isolated row; 2-second deadline bounds even
// catastrophic rules. The 250 ms floor discriminates these quadratics, not every linear constant regression.
const BASELINE_INPUT = "the quick brown fox jumps over the lazy dog\n".repeat(5000);

test("linear time baseline", (t) => {
  assert.ok(BASELINE_INPUT.length >= 200000, "baseline input is too short");
  reportMetric(t, measureRound3Padding({ label: "plain_baseline", input: BASELINE_INPUT }));
});

for (const row of LINEAR_INPUTS) {
  test(`linear time: ${row.name}`, (t) => {
    const input = row.input();
    assert.ok(input.length >= 200000, `linear input ${row.name} is too short`);
    reportMetric(t, measureRound3Padding({ label: row.name, input }));
  });
}

// Every retained matching family has a positive, a nonmatch, and a pathological input.
// Rule order may change; these exercise observable families rather than private regex sources.
const RULE_ADVERSARIES = [
  ["nextline", () => `password:\n${round3Fake("Rule", 1)}`, "key_before_finished_line", "nextline_keys"],
  ["armor", () => `${PEM_B}\n${round3Fake("Rule", 2)}\n${PEM_E}`, "token expired for user", "pem_begin_repeat"],
  ["name_value", () => `{"name":"token","value":"${round3Fake("Rule", 3)}"}`, "password mismatch for account", "escaped_key_repeat"],
  ["tuple", () => `{:token, "${round3Fake("Rule", 4)}"}`, "invalid token, retrying now", "tuple_comma_repeat"],
  ["structural", () => `signingInMemoryKey=${round3Fake("Rule", 5)}`, "token_count: 300", "double_equals_repeat"],
  ["authorization", () => `Authorization: ${round3Fake("Rule", 6)}`, "authorization failed for request", "keyword_no_separator"],
  ["cookie", () => `Cookie: ${round3Fake("Rule", 7)}`, "cookie jar is empty", "nextline_keys"],
  ["bearer", () => `Bearer ${round3Fake("Rule", 8)}`, "token expired for user", "bearer_quote_unterminated"],
  ["secret_access_key", () => `secret_access_key=${round3Fake("Rule", 9)}`, "secret not found in vault", "whitespace_lines"],
  ["github", () => seedValues().gh, "task-runner12345 started", "akia_run"],
  ["hex", () => seedValues().hex, "token_count: 300", "backslash_run"],
  ["sk", () => `${SK}${round3Fake("Rule", 10)}`, "kiosk-mode-settings applied", "sk_dash_run"],
  ["slack", () => `${XOXB}${round3Fake("Rule", 11)}`, "token_count: 300", "xox_repeat"],
  ["npm", () => `${frag("np", "m_")}${"A".repeat(36)}`, "npm_config_cache is set", "cli_flag_repeat"],
  ["userinfo", () => `https://user:${round3Fake("Rule", 12)}@example.invalid`, "token_count: 300", "userinfo_repeated_scheme"],
  ["jwt", () => `${frag("ey", "J")}${round3Fake("Rule", 13)}.body.signature`, "token_count: 300", "jwt_hyphen_run"],
  ["aws", () => `${frag("AK", "IA")}${"A".repeat(16)}`, "token_count: 300", "akia_run"],
  ["query", () => `?key=${round3Fake("Rule", 14)}`, "token_count: 300", "query_key_repeat"],
  ["cli", () => `--password ${round3Fake("Rule", 15)}`, "use --password-file ./pw.txt for input", "cli_flag_repeat"],
  ["curl", () => `curl -u user:${round3Fake("Rule", 16)}`, "token_count: 300", "curl_user_repeat"],
  ["generic", () => `token=${round3Fake("Rule", 17)}`, "token: ok", "literal_exemption_repeat"]
];

test("round3 rule family adversaries", { timeout: 55000 }, (t) => {
  assert.ok(RULE_ADVERSARIES.length > 0, "rule inventory empty");
  for (const [label, positive, proseName, pathological] of RULE_ADVERSARIES) {
    const prose = PROSE_LINES.find((row) => row.name === proseName);
    const input = LINEAR_INPUTS.find((row) => row.name === pathological);
    assert.ok(prose && input, `rule ${label} has an empty case group`);
    assert.ok(maskSecretShapes(positive()) !== positive(), `rule ${label} positive did not match`);
    assert.ok(maskSecretShapes(prose.text) === prose.text, `rule ${label} nonmatch changed`);
    reportMetric(t, measureRound3Padding({ label: `rule/${label}`, input: input.input() }));
  }
});

test("round3 separator head adversaries", { timeout: 55000 }, (t) => {
  const heads = ["token", "Authorization", "Cookie", "password", "SecretAccessKey"];
  const separators = [":", "=", "=>", "==", "==="];
  let count = 0;
  for (const head of heads) for (const separator of separators) for (const whitespace of ROUND3_PADDING_WHITESPACE) {
    const label = `separator/${head}/${separator.length}/${separator === "=>" ? "arrow" : separator[0] === ":" ? "colon" : "equals"}/${whitespace.name}`;
    reportMetric(t, measureRound3Padding({ label, input: `${head}${separator}${whitespace.make(200000)}x` }));
    count += 1;
  }
  assert.ok(count > 0, "separator family empty");
});

test("round3 timing quadratic copied control", () => {
  const quadratic = MASK_PERF_CHILD.replace('import { maskSecretShapes } from "./script/verify_repository.mjs";', 'const maskSecretShapes = (text) => /token:[ \\t]*[ \\t]*$/.test(text);');
  assert.ok(quadratic !== MASK_PERF_CHILD, "quadratic copy was not changed");
  assert.throws(() => measureRound3Padding({ label: "quadratic_copy", input: `token:${" ".repeat(200000)}x` }, quadratic), /timed out|bound failed/, "quadratic copy passed timing gate");
});

test("ANSI-wrapped and CRLF secrets never reach the tail", () => {
  const v1 = frag("fake", "Ansi", "Crlf70");
  const v2 = frag("fake", "Ansi", "Crlf71");
  const v3 = frag("fake", "Ansi", "Crlf72");
  const stdout = `\u001b[31m${PW}=${v1}\u001b[0m\r\n\u001b[33m${TK}: "${v2} ${v3}"\u001b[0m\r\n`;
  const tail = rootProofFailureTail("failed", { stdout, stderr: "" });
  const hits = leakedSecrets(tail, [v1, v2, v3]).length;
  assert.ok(hits === 0, `ANSI/CRLF case: ${hits} of 3 values reached the tail`);
  assert.ok(tail.includes("***"), "ANSI/CRLF case: masked marker missing");
});

test("a value cut by the tail byte window never appears", () => {
  const V = frag("fake", "CutWindow", "Q".repeat(56), "fakeEnd1");
  const vLine = `${PW}="${V}"`;
  const remaining = 40;
  const joinedTarget = ROOT_PROOF_TAIL_BYTES - remaining - 1;
  const fillers = Array.from({ length: ROOT_PROOF_TAIL_LINES - 1 }, (_, i) => `filler ${String(i).padStart(3, "0")} `.padEnd(100, "-"));
  const fixedLen = fillers.slice(0, ROOT_PROOF_TAIL_LINES - 2).join("\n").length + 1;
  fillers[ROOT_PROOF_TAIL_LINES - 2] = "z".repeat(joinedTarget - fixedLen);
  const text = [vLine, ...fillers].join("\n");
  const unmaskedTail = text.split("\n").slice(-ROOT_PROOF_TAIL_LINES).join("\n");
  const cutInside = unmaskedTail.length - ROOT_PROOF_TAIL_BYTES === vLine.length - remaining;
  assert.ok(cutInside, "byte window cut does not land inside the value line (test setup)");
  assert.ok(rawTailWindow({ stdout: text }).includes(V.slice(-8)), "byte-cut fragment is outside the unmasked window");
  const out = rootProofFailureTail("failed", { stdout: text, stderr: "" });
  const hits = [V, V.slice(-8)].filter((frag8) => out.includes(frag8)).length;
  assert.ok(hits === 0, `window case: ${hits} of 2 value fragments reached the tail`);
  assert.ok(out.includes("***"), "window case: masked marker missing");
});

test("masking keeps failure diagnosis and key or header names", () => {
  const result = runSeededChild(seedValues());
  const tail = rootProofFailureTail("failed", result);
  assert.ok(/1\) test something/.test(tail), "failing test line survives");
  assert.ok(/root-proof failure tail \(failed;/.test(tail), "tail header survives");
  assert.ok(/Finished in/.test(tail), "Finished-in line survives");
  for (const name of ["Authorization", "Cookie", "aws_secret_access_key"]) {
    assert.ok(tail.includes(name), `${name} name survives`);
  }
  assert.ok(tail.includes("***"));
});

test("short values are masked but 2-character words are left alone", () => {
  const s = seedValues();
  const masked = maskSecretShapes(`${frag("tok", "en")}=${s.short}`);
  assert.equal(leakedSecrets(masked, [s.short]).length, 0);
  assert.ok(masked === `${frag("tok", "en")}=***`, "short value mask output changed");
  const plain = `${frag("tok", "en")}: ok`;
  assert.equal(maskSecretShapes(plain), plain);
});

test("a short GitHub token is masked", () => {
  const short = frag("q9", "Zx", "7k");
  const masked = maskSecretShapes(`leaked ${GHP}${short}`);
  assert.ok(masked === `leaked ${GHP}***`, "short GitHub token mask output changed");
});

test("maskSecretShapes edge cases are byte-stable", () => {
  assert.equal(maskSecretShapes(""), "");
  const clean = "ordinary line\n  1) test a (B)\nFinished in 0.3 seconds\n";
  assert.equal(maskSecretShapes(clean), clean);
});

// ---------------------------------------------------------------------------------------------
// Derived-secret guard: a shell variable computed from a secret-bound env value is NOT auto-masked
// by Actions, so it must be registered with ::add-mask:: before any other line uses it.
// Line-based scan (no YAML dependency); one-assignment-per-line is the workflow convention.
// ---------------------------------------------------------------------------------------------
const workflowDir = path.join(repoRoot, ".github/workflows");
const indentOf = (line) => line.length - line.trimStart().length;
const ASSIGN = /^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$/;
const refsVar = (text, name) => new RegExp(`\\$\\{?${name}\\b`).test(text);
// Supported convention: one unconditional stdout echo, at the assignment's block indentation.
// This is deliberately not a Bash parser. Declarations, append/read/printf, GITHUB_ENV,
// multiple assignments and inline derivations remain GR-06's Phase 196 receiver.
const isMaskLine = (line, name) => {
  const ref = `(?:${name}|\\{${name}\\})`;
  const bare = `::add-mask::\\$${ref}`;
  const dq = `"::add-mask::\\$${ref}"`;
  return new RegExp(`^[ \\t]*echo[ \\t]+(?:${bare}|${dq})(?:;)?(?:[ \\t]+#.*)?[ \\t]*$`).test(line);
};

const CREDENTIAL_REFERENCE = /\$\{\{\s*(?:secrets(?:\.[A-Za-z_]\w*|\s*\[\s*(["'])[A-Za-z_]\w*\1\s*\])|github\.token)\s*\}\}/i;

export function secretBoundKeys(workflowText) {
  const keys = new Set();
  for (const line of workflowText.split("\n")) {
    const m = /^\s*([A-Za-z_][A-Za-z0-9_]*):\s*/.exec(line);
    if (m && CREDENTIAL_REFERENCE.test(line.slice(m[0].length))) keys.add(m[1]);
  }
  return keys;
}

// End (exclusive) of the `run: |` block containing line index i.
function runBlockBounds(lines, i) {
  let start = -1;
  for (let k = i; k >= 0; k -= 1) {
    if (/^\s*(?:-\s+)?run:\s*[|>][+-]?\s*$/.test(lines[k])) { start = k; break; }
  }
  if (start < 0) return null;
  const base = indentOf(lines[start].replace(/^(\s*)-\s+/, "$1  "));
  let end = start + 1;
  while (end < lines.length && (lines[end].trim() === "" || indentOf(lines[end]) > base)) end += 1;
  return { start, end };
}

export function derivedSecretAssignments(workflowText) {
  const lines = workflowText.split("\n");
  const secrets = secretBoundKeys(workflowText);
  const found = [];
  const derived = new Map();
  lines.forEach((line, index) => {
    const m = ASSIGN.exec(line);
    if (!m) return; // ASSIGN requires equals before any RHS colon; YAML declarations cannot match.
    const [, name, rhs] = m;
    const bounds = runBlockBounds(lines, index);
    if (!bounds) return;
    // One level of transitivity: depth 1 derives from a secret-bound key, depth 2 from a depth-1 value.
    // Depth-2 values are not sources (a deployment id from an authenticated call is not itself a secret).
    let from = null;
    let depth = 0;
    for (const key of secrets) if (refsVar(rhs, key)) { from = key; depth = 1; break; }
    if (from === null && CREDENTIAL_REFERENCE.test(rhs)) { from = "credential reference"; depth = 1; }
    if (from === null) {
      for (const [key, d] of derived) if (d === 1 && refsVar(rhs, key)) { from = key; depth = 2; break; }
    }
    if (from !== null) {
      derived.set(name, depth);
      found.push({ name, from, index, line: index + 1, bounds });
    }
  });
  return found;
}

// Conservative lexical fences, not evaluation: no registration across control syntax, heredocs,
// continuations or compound commands. Prior balanced standalone subshells may precede the slice;
// any open/ambiguous enclosing region leaves registration unproved.
function supportedRegistration(lines, assignment, maskIndex) {
  const { index, bounds } = assignment;
  const bodyIndent = Math.min(...lines.slice(bounds.start + 1, bounds.end).filter((l) => l.trim()).map(indentOf));
  if (indentOf(lines[index]) !== bodyIndent || indentOf(lines[maskIndex]) !== bodyIndent) return false;
  let depth = 0;
  for (let k = bounds.start + 1; k < index; k += 1) {
    const line = lines[k].trim();
    if (line.startsWith("#")) continue;
    if (/<<|\\$/.test(line)) return false;
    const singleSubshell = /^\(\s+[^()]*\)\s*$/.test(line);
    const singleLoop = /^(?:for|while|until)\b.*\bdone\b/.test(line);
    if (!singleSubshell && !singleLoop && /^(?:if|for|while|until|case|function)\b|^[A-Za-z_]\w*\s*\(\s*\)\s*\{|^[({]/.test(line)) depth += 1;
    if (/^(?:fi|done|esac|[})])(?:\s|;|$)/.test(line) || /\bdone\s*\)\s*$/.test(line)) depth -= 1;
    if (depth < 0) return false;
  }
  if (depth !== 0) return false;
  for (let k = index + 1; k <= maskIndex; k += 1) {
    const line = lines[k].trim();
    if (line === "" || line.startsWith("#")) continue;
    if (indentOf(lines[k]) !== bodyIndent) return false;
    if (/^(?:if|then|else|elif|fi|for|while|until|do|done|case|esac|function)\b|^[A-Za-z_]\w*\s*\(\s*\)\s*\{|^[({}]|<<|&&|\|\||\\$/.test(line)) return false;
    if (k !== maskIndex && /[;|&]/.test(line) && !ASSIGN.test(line)) return false;
  }
  return true;
}

export function derivedSecretViolations(workflowText) {
  const lines = workflowText.split("\n");
  const violations = [];
  for (const a of derivedSecretAssignments(workflowText)) {
    let masked = false;
    let usedFirst = false;
    for (let k = a.index + 1; k < a.bounds.end; k += 1) {
      if (isMaskLine(lines[k], a.name) && supportedRegistration(lines, a, k)) { masked = true; break; }
      if (refsVar(lines[k], a.name)) { usedFirst = true; break; }
    }
    if (!masked || usedFirst) violations.push({ name: a.name, line: a.line, reason: usedFirst ? "used before add-mask" : "no add-mask" });
  }
  return violations;
}

const NO_NETWORK = /\b(curl|wget)\b|\bgh /;

export function derivationScript(workflowText, vars) {
  const lines = workflowText.split("\n");
  const picked = [];
  for (const name of vars) {
    const idx = lines.findIndex((l) => new RegExp(`^\\s*${name}=`).test(l));
    assert.ok(idx >= 0, `assignment for ${name} not found`);
    picked.push(idx);
    const bounds = runBlockBounds(lines, idx);
    const mask = lines.findIndex((l, k) => k > idx && bounds && k < bounds.end && isMaskLine(l, name) && supportedRegistration(lines, { index: idx, bounds }, k));
    if (mask >= 0) picked.push(mask);
  }
  const script = [...new Set(picked)].sort((a, b) => a - b).map((k) => lines[k].trim());
  for (const l of script) if (NO_NETWORK.test(l)) throw new Error("refusing to run network line");
  return script.join("\n");
}

export function runnerMaskedLog(text, preMasked) {
  const registered = new Set(preMasked.filter((v) => v !== ""));
  const out = [];
  for (const line of text.split("\n")) {
    const m = /^::add-mask::(.*)$/.exec(line);
    if (m) { if (m[1] !== "") registered.add(m[1]); continue; }
    let masked = line;
    for (const v of [...registered].sort((a, b) => b.length - a.length)) masked = masked.split(v).join("***");
    out.push(masked);
  }
  return out.join("\n");
}

const fireDrillPath = path.join(workflowDir, "maven-publish-fire-drill.yml");
const fireDrill = () => readFileSync(fireDrillPath, "utf8");
const workflowFiles = () => readdirSync(workflowDir).filter((f) => f.endsWith(".yml") || f.endsWith(".yaml")).sort();

const FIXTURE_HEAD = [
  "jobs:",
  "  j:",
  "    steps:",
  "      - name: x",
  "        env:",
  "          MAVEN_PASSWORD: ${{ secrets.SOME_FAKE_SECRET }}",
  "          FOO: plain",
  "        run: |",
  "          set -eu"
];
const fixture = (...body) => [...FIXTURE_HEAD, ...body.map((l) => `          ${l}`)].join("\n");

test("derivedSecretViolations accepts a masked derivation", () => {
  const text = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo "::add-mask::$TOKEN"`, `echo "use $TOKEN"`);
  assert.equal(derivedSecretAssignments(text).length, 1);
  assert.deepEqual(derivedSecretViolations(text), []);
});

test("derivedSecretViolations rejects a single-quoted add-mask", () => {
  const text = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo '::add-mask::$TOKEN'`, `echo "use $TOKEN"`);
  const v = derivedSecretViolations(text);
  assert.equal(v.length, 1);
  assert.equal(v[0].name, "TOKEN");
});

test("derivedSecretViolations rejects an unterminated add-mask quote", () => {
  const text = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo "::add-mask::$TOKEN`, `echo "use $TOKEN"`);
  const v = derivedSecretViolations(text);
  assert.equal(v.length, 1);
  assert.equal(v[0].name, "TOKEN");
});

test("derivedSecretViolations accepts an unquoted add-mask", () => {
  const text = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo ::add-mask::$TOKEN`, `echo "use $TOKEN"`);
  assert.deepEqual(derivedSecretViolations(text), []);
});

test("derivationScript skips a single-quoted add-mask line", () => {
  const text = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo '::add-mask::$TOKEN'`, `echo "use $TOKEN"`);
  assert.ok(!derivationScript(text, ["TOKEN"]).includes("::add-mask::"), "a single-quoted mask line was extracted");
});

test("derivedSecretViolations rejects a prefix-collision mask", () => {
  const text = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo "::add-mask::$TOKEN_ID"`, `echo "use $TOKEN"`);
  const v = derivedSecretViolations(text);
  assert.equal(v.length, 1);
  assert.equal(v[0].name, "TOKEN");
});

test("derivedSecretViolations ignores a commented-out mask", () => {
  const text = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `# echo "::add-mask::$TOKEN"`, `echo "use $TOKEN"`);
  const v = derivedSecretViolations(text);
  assert.equal(v.length, 1);
  assert.equal(v[0].name, "TOKEN");
});

test("derivedSecretViolations accepts a braced mask", () => {
  const text = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo "::add-mask::\${TOKEN}"`, `echo "use $TOKEN"`);
  assert.deepEqual(derivedSecretViolations(text), []);
});

test("derivedSecretViolations flags a missing or late add-mask", () => {
  const missing = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo "use $TOKEN"`);
  const v1 = derivedSecretViolations(missing);
  assert.equal(v1.length, 1);
  assert.equal(v1[0].name, "TOKEN");
  const late = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo "use $TOKEN"`, `echo "::add-mask::$TOKEN"`);
  const v2 = derivedSecretViolations(late);
  assert.equal(v2.length, 1);
  assert.equal(v2[0].name, "TOKEN");
});

test("derived chains are tracked and non-secret env keys are ignored", () => {
  const chain = fixture(`TOKEN=$(printf '%s' "$MAVEN_PASSWORD" | base64)`, `echo "::add-mask::$TOKEN"`, `AUTH="Authorization: Bearer $TOKEN"`, `echo hi`);
  const v = derivedSecretViolations(chain);
  assert.equal(v.length, 1);
  assert.equal(v[0].name, "AUTH");
  const plain = fixture(`X=$(echo $FOO)`, `echo "$X"`);
  assert.equal(derivedSecretAssignments(plain).length, 0);
  assert.deepEqual(derivedSecretViolations(plain), []);
});

test("live workflow tree: non-empty floor and zero violations", (t) => {
  let total = 0;
  let references = 0;
  let aliases = 0;
  const bad = [];
  for (const f of workflowFiles()) {
    const text = readFileSync(path.join(workflowDir, f), "utf8");
    total += derivedSecretAssignments(text).length;
    references += text.split("\n").filter((line) => CREDENTIAL_REFERENCE.test(line)).length;
    aliases += secretBoundKeys(text).size;
    for (const v of derivedSecretViolations(text)) bad.push(`${f}:${v.line} ${v.name} (${v.reason})`);
  }
  assert.ok(total >= 1, "scan must find at least one derived assignment, else it is vacuous");
  assert.ok(references > 0 && aliases > 0, "live credential census empty");
  t.diagnostic(`live census references ${references}; aliases ${aliases}; derived ${total}; violations ${bad.length}`);
  assert.deepEqual(bad, [], `unmasked derived secrets: ${bad.join("; ")}`);
});

test("runnerMaskedLog drops add-mask lines and masks later occurrences only", () => {
  const log = runnerMaskedLog(["before val123", "::add-mask::val123", "after val123"].join("\n"), []);
  assert.equal(log, ["before val123", "after ***"].join("\n"));
  assert.equal(runnerMaskedLog("pre pw1", ["pw1"]), "pre ***");
});

function runDerivation(script, user, pass) {
  const body = `${script}\necho "use: $AUTH"\necho "token: $TOKEN"\necho "use: $AUTH" >&2\n`;
  const r = spawnSync("bash", ["-c", `set -euo pipefail\n${body}`], {
    encoding: "utf8",
    env: { PATH: process.env.PATH, MAVEN_USERNAME: user, MAVEN_PASSWORD: pass }
  });
  assert.ok(r.status === 0, `derivation child exited ${r.status}, stderr withheld`);
  return `${r.stdout}${r.stderr}`;
}

test("live fire-drill derivation never leaks seeded or derived values into the emulated step log", () => {
  const user = frag("fake", "Mvn", "User", "Val4");
  const pass = frag("fake", "Mvn", "Pass", "Val5");
  const token = Buffer.from(`${user}:${pass}`).toString("base64");
  const script = derivationScript(fireDrill(), ["TOKEN", "AUTH"]);
  const watched = [user, pass, token, `Bearer ${token}`];

  const protectedLog = runnerMaskedLog(runDerivation(script, user, pass), [user, pass]);
  const leaked = leakedSecrets(protectedLog, watched);
  assert.ok(leaked.length === 0, `leaked: ${leaked.length} value(s) reached the step log`);

  const stripped = script.split("\n").filter((l) => !l.includes("::add-mask::")).join("\n");
  const control = leakedSecrets(runnerMaskedLog(runDerivation(stripped, user, pass), [user, pass]), watched);
  assert.ok(control.length >= 1, "control: without add-mask the derived token must leak");
});

test("derivationScript refuses to extract network lines", () => {
  const text = fixture(`TOKEN=$(curl -s "$MAVEN_PASSWORD")`);
  assert.throws(() => derivationScript(text, ["TOKEN"]), /refusing/);
});

test("round3 raw window and inventory controls", () => {
  const seed = round3Fake("Window", 1);
  const oversized = runRound3TailRows([{ name: "early byte seed", line: () => `password=${seed}\n${"z".repeat(ROOT_PROOF_TAIL_BYTES + 1)}`, seeds: [seed] }]);
  assert.ok(oversized.rawTail.length <= ROOT_PROOF_TAIL_BYTES, "raw window must enforce the byte cap");
  assert.throws(() => assertRound3TailRows(oversized, "early byte control"), /raw tail window/, "out-of-byte-window seed qualified");
  const earlyLine = runRound3TailRows([{ name: "early line seed", line: () => `password=${seed}\n${"safe line\n".repeat(ROOT_PROOF_TAIL_LINES + 1)}`, seeds: [seed] }]);
  assert.throws(() => assertRound3TailRows(earlyLine, "early line control"), /raw tail window/, "out-of-line-window seed qualified");
  assert.throws(() => assertRound3TailRows({ rows: [], seeds: [], result: { status: 2 }, rawTail: "", tail: "" }, "empty inventory"), /zero rows/);
  const valid = runRound3TailRows([{ name: "identity control", line: () => `password=${seed}`, seeds: [seed] }]);
  assertRound3TailRows(valid, "valid window");
  assert.throws(() => assertRound3TailRows({ ...valid, tail: valid.rawTail }, "removed mask"), /masked tail/);
  const groups = new Map([["window", [1]], ["diagnostic", [1]], ["timing", [1]]]);
  const requireGroups = (map) => { for (const group of ["window", "diagnostic", "timing"]) assert.ok(map.get(group)?.length > 0, "required case group missing"); };
  requireGroups(groups);
  for (const group of groups.keys()) { const omitted = new Map(groups); omitted.delete(group); assert.throws(() => requireGroups(omitted), /required case group missing/); }
});

test("round3 guard exact stdout registration", () => {
  const forms = ['echo "::add-mask::$TOKEN"', 'echo ::add-mask::$TOKEN', 'echo "::add-mask::${TOKEN}"; # supported', 'echo ::add-mask::${TOKEN} # supported'];
  assert.ok(forms.length > 0, "registration family empty");
  for (const [index, form] of forms.entries()) {
    const text = fixture('TOKEN=$(printf %s "$MAVEN_PASSWORD" | base64)', form, 'echo "$TOKEN"');
    assert.ok(derivedSecretViolations(text).length === 0, `exact stdout form ${index} rejected`);
    const script = derivationScript(text, ["TOKEN"]);
    const seed = round3Fake("Registration", index);
    const result = spawnSync("bash", ["-c", `${script}\necho "$TOKEN"`], { encoding: "utf8", env: { PATH: process.env.PATH, MAVEN_PASSWORD: seed } });
    const derived = Buffer.from(seed).toString("base64");
    assert.ok(result.status === 0 && !runnerMaskedLog(result.stdout, [seed]).includes(derived), `stdout emulator form ${index} failed`);
  }
});

test("round3 guard rejected execution contexts", () => {
  const masks = [
    'echo "::add-mask::$TOKEN" >/dev/null', 'echo "::add-mask::$TOKEN" > /tmp/x',
    'echo "::add-mask::$TOKEN" >&2', 'echo "::add-mask::$TOKEN" 2>&1',
    'echo "::add-mask::$TOKEN" | cat >/dev/null', 'echo "::add-mask::$TOKEN"x',
    'echo ::add-mask::$TOKEN.suffix', 'echo "::add-mask::$TOKEN" extra',
    '# echo "::add-mask::$TOKEN"', '  echo "::add-mask::$TOKEN"',
    'if true; then\n  echo "::add-mask::$TOKEN"\nfi',
    'if true; then\necho "::add-mask::$TOKEN"\nfi',
    'if false; then echo "::add-mask::$TOKEN"; fi',
    'f() {\necho "::add-mask::$TOKEN"\n}',
    'function f { echo "::add-mask::$TOKEN"; }',
    "cat <<'EOF'\necho \"::add-mask::$TOKEN\"\nEOF",
    '(\necho "::add-mask::$TOKEN"\n)',
    'true && echo "::add-mask::$TOKEN"',
    'echo "::add-mask::$TOKEN"; true', '::add-mask::$TOKEN'
  ];
  assert.ok(masks.length > 0, "rejection family empty");
  for (const [index, mask] of masks.entries()) {
    const text = fixture('TOKEN=$(printf %s "$MAVEN_PASSWORD" | base64)', ...mask.split("\n"), 'echo "$TOKEN"');
    assert.ok(derivedSecretViolations(text).length === 1, `unproved context ${index} accepted`);
    assert.ok(!derivationScript(text, ["TOKEN"]).includes("::add-mask::"), `unproved context ${index} extracted`);
  }
  const control = fixture('if false; then', 'TOKEN="$MAVEN_PASSWORD"', 'fi', 'echo "::add-mask::$TOKEN"');
  assert.ok(derivedSecretViolations(control).length === 1, "ambiguous region accepted");
});

test("round3 references bracket and github token", () => {
  const refs = ['${{ secrets.NAME }}', "${{ secrets['NAME'] }}", '${{ secrets["NAME"] }}', '${{ github.token }}'];
  assert.ok(refs.length > 0, "reference family empty");
  for (const [index, ref] of refs.entries()) {
    const direct = fixture(`AUTH="Authorization: ${ref}"`, 'echo "::add-mask::$AUTH"');
    assert.ok(derivedSecretAssignments(direct).length === 1 && derivedSecretViolations(direct).length === 0, `direct reference ${index} missed`);
    assert.ok(derivedSecretViolations(direct.replace('echo "::add-mask::$AUTH"', "")).length === 1, `reference ${index} negative control missed`);
    const alias = fixture('TOKEN="$BOUND"', 'echo "::add-mask::$TOKEN"').replace('FOO: plain', `BOUND: ${ref}`);
    assert.ok(secretBoundKeys(alias).has("BOUND") && derivedSecretAssignments(alias).length === 1 && derivedSecretViolations(alias).length === 0, `env reference ${index} missed`);
  }
});

// Complete finite inventory of the forms named in GAP2 IN-01/04. No claim about arbitrary
// credentials: bare values require these provider, header, identifier, URL or CLI contexts.
const RESIDUAL_FORMS = [
  ...[
    ["gitlab", frag("gl", "pat-")], ["stripe_secret", frag("sk_", "live_")],
    ["stripe_restricted", frag("rk_", "live_")], ["stripe_webhook", frag("wh", "sec_")],
    ["google_api", frag("AI", "za")], ["twilio", frag("S", "K")]
  ].map(([name, prefix], index) => {
    const seed = name === "twilio" ? frag("a1".repeat(16)) : round3Fake("Provider", index);
    return { name, family: "provider", line: () => `provider output ${prefix}${seed}`, seeds: [seed] };
  }),
  { name: "slack_webhook", family: "provider", line: () => `https://hooks.slack.com/services/${round3Fake("Slack", 1)}/${round3Fake("Slack", 2)}/${round3Fake("Slack", 3)}`, seeds: [1, 2, 3].map((n) => round3Fake("Slack", n)) },
  { name: "azure_account_key", family: "identifier", line: () => `DefaultEndpointsProtocol=https;AccountKey=${round3Fake("Azure", 1)}==;EndpointSuffix=example.invalid`, seeds: [round3Fake("Azure", 1)] },
  ...["docker -p ", "sshpass -p ", "mysql -p", "mix hex.publish --key ", "curl --user=deploy:", "curl -udeploy:", "curl --user deploy:", "curl -u deploy:", "openssl -pass pass:"].map((prefix, index) => ({ name: `cli_${index}`, family: "cli", line: () => `${prefix}${round3Fake("Cli", index)}`, seeds: [round3Fake("Cli", index)] })),
  ...["pwd", "pass", "pw", "DB_PASS", "DB_PWD", "_auth", "session_id"].map((key, index) => ({ name: `alias_${key}`, family: "identifier", line: () => `${key}=${round3Fake("Alias", index)}`, seeds: [round3Fake("Alias", index)] })),
  ...["?code=", "?sig%3D=", "?AWSAccessKeyId=", "?password%3D", "?password%3D="].map((prefix, index) => ({ name: `query_${index}`, family: "query", line: () => `https://example.invalid/${prefix}${round3Fake("QueryEncoding", index)}`, seeds: [round3Fake("QueryEncoding", index)] })),
  { name: "url_user_only", family: "url", line: () => `https://${round3Fake("UserOnly", 1)}@example.invalid`, seeds: [round3Fake("UserOnly", 1)] },
  { name: "url_long_user_password", family: "url", line: () => `https://${"u".repeat(600)}:${round3Fake("LongPass", 1)}${"p".repeat(600)}@example.invalid`, seeds: [round3Fake("LongPass", 1)] },
  { name: "url_password_spaces", family: "url", line: () => `https://user:${round3Fake("SpacePass", 1)} ${round3Fake("SpacePass", 2)}@example.invalid`, seeds: [round3Fake("SpacePass", 1), round3Fake("SpacePass", 2)] },
  { name: "url_encoded_colon", family: "url", line: () => `https://user%3A${round3Fake("EncodedUser", 1)}@example.invalid`, seeds: [round3Fake("EncodedUser", 1)] },
  { name: "url_encoded_at", family: "url", line: () => `https://${round3Fake("EncodedAt", 1)}%40example.invalid`, seeds: [round3Fake("EncodedAt", 1)] },
  { name: "full_width_separator", family: "encoding", line: () => `password：${round3Fake("FullWidth", 1)}`, seeds: [round3Fake("FullWidth", 1)] },
  { name: "csi_key_erase", family: "encoding", line: () => `password\u001b[0K=${round3Fake("CsiErase", 1)}`, seeds: [round3Fake("CsiErase", 1)] },
  { name: "csi_inside_key", family: "encoding", line: () => `pass\u001b[?25lword\u001b[1;2H： ["${round3Fake("CsiInside", 1)}"]\r\n`, seeds: [round3Fake("CsiInside", 1)] },
  { name: "bearer_next_line", family: "authorization", line: () => `Bearer\n${round3Fake("BearerNext", 1)}`, seeds: [round3Fake("BearerNext", 1)] },
  { name: "bearer_colon", family: "authorization", line: () => `bearer: ${round3Fake("BearerColon", 1)}`, seeds: [round3Fake("BearerColon", 1)] },
  { name: "basic_standalone", family: "authorization", line: () => `Basic ${round3Fake("Basic", 1)}`, seeds: [round3Fake("Basic", 1)] },
  ...["a-", "x_", "access_token_", "jwt-"].map((prefix, index) => ({ name: `jwt_prefix_${index}`, family: "jwt", line: () => `${prefix}${frag("ey", "J")}${round3Fake("JwtBoundary", index)}.body.signature`, seeds: [round3Fake("JwtBoundary", index)] })),
  { name: "jwt_upper_header", family: "jwt", line: () => `${frag("EY", "J")}${round3Fake("JwtUpper", 1)}.body.signature`, seeds: [round3Fake("JwtUpper", 1)] }
];

test("round3 residual named credential forms", () => {
  for (const family of ["provider", "identifier", "cli", "query", "url", "encoding", "authorization", "jwt"]) {
    const rows = RESIDUAL_FORMS.filter((row) => row.family === family);
    assert.ok(rows.length > 0, `residual ${family} family empty`);
    assertRound3TailRows(runRound3TailRows(rows), `residual ${family}`);
  }
});

test("round3 residual exact diagnostic pins", () => {
  const rows = [
    { text: `Bearer\n${round3Fake("ExactBearer", 1)}`, expected: "Bearer\n***" },
    { text: `Basic ${round3Fake("ExactBasic", 1)}`, expected: "Basic ***" },
    { text: `token\u001b[0K=${round3Fake("ExactCsi", 1)}`, expected: "token=***" },
    { text: "ordinary：prose stays readable", expected: "ordinary：prose stays readable" },
    { text: "Basic authentication failed", expected: "Basic *** failed" }
  ];
  for (const [index, row] of rows.entries()) assert.ok(maskSecretShapes(row.text) === row.expected, `residual exact diagnostic ${index} changed`);
});
