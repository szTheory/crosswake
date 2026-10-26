/* REL-03: secret values never reach CI output. Seeds are synthetic and built from fragments at runtime. */
import assert from "node:assert/strict";
import { readdirSync, readFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { maskSecretShapes, rootProofFailureTail, spawnStage } from "../../script/verify_repository.mjs";

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
const lines = JSON.parse(process.env.CW_SEED_LINES);
for (const l of lines) { console.log(l); console.error(l); }
console.log("  1) test something (Mod)");
console.log("     Assertion with == failed");
console.log("Finished in 0.1 seconds");
process.exit(2);
`;

function runChildLines(lines) {
  return spawnStage(process.execPath, ["-e", CHILD], {
    env: { PATH: process.env.PATH, CW_SEED_LINES: JSON.stringify(lines) }
  });
}

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
    assert.ok(masked === row.expected, `gap shape ${row.name}: output differs from expected, ${maskedHits} of ${row.seeds.length} seeds present`);
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
  const result = runChildLines(GAP_SHAPES.map((row) => row.line));
  const allSeeds = GAP_SHAPES.flatMap((row) => row.seeds);
  assert.ok(result.status === 2, `gap child exited ${result.status}, expected 2`);
  const raw = `${result.stdout}${result.stderr}`;
  assert.ok(leakedSecrets(raw, allSeeds).length === allSeeds.length, "detector must see every gap seed in raw child output");
  const tail = rootProofFailureTail("failed", result);
  const leakedNames = GAP_SHAPES.filter((row) => leakedSecrets(tail, row.seeds).length > 0).map((row) => row.name);
  const k = allSeeds.filter((seed) => tail.includes(seed)).length;
  assert.ok(k === 0, `leaked: ${k} of ${gapSeedCount()} gap seed(s) reached the tail: ${leakedNames.join(", ")}`);
});

const PROSE_LINES = [
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
  { name: "npm_config_cache is set", text: "npm_config_cache is set" }
];

// Over-masks accepted as the safe direction. Each is pinned exactly so it can never drift silently.
const ACCEPTED_OVERMASK = [
  { name: "code_assert_token_equals", text: 'code: assert token == "expected-value"', expected: 'code: assert token == "***"' },
  { name: "key_then_plain_line", text: "enter password:\nnext line text", expected: "enter password:\n***" },
  { name: "cli_negated_flag", text: "run --no-password prompt", expected: "run --no-password ***" }
];

for (const row of ACCEPTED_OVERMASK) {
  test(`accepted over-mask pinned: ${row.name}`, () => {
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
  { name: "escaped_key_repeat", input: () => `${BS}"${PW}${BS}":`.repeat(30000) },
  { name: "escaped_value_backslashes", input: () => `{${BS}"${PW}${BS}":${BS}"` + BS.repeat(200000) },
  { name: "tuple_comma_repeat", input: () => `{:${TK}, `.repeat(30000) },
  { name: "cli_flag_repeat", input: () => `--${PW} `.repeat(30000) },
  { name: "curl_user_repeat", input: () => "-u a:".repeat(50000) },
  { name: "nextline_keys", input: () => `${PW}:\n`.repeat(30000) },
  { name: "bearer_quote_unterminated", input: () => 'Bearer "' + "a b ".repeat(100000) },
  { name: "double_equals_repeat", input: () => `${TK} ==`.repeat(40000) },
  { name: "sk_dash_run", input: () => `${SK}` + "-a".repeat(100000) },
  { name: "xox_repeat", input: () => XOXB.repeat(40000) }
];

for (const row of LINEAR_INPUTS) {
  test(`linear time: ${row.name}`, (t) => {
    const input = row.input();
    assert.ok(input.length >= 200000, `linear input ${row.name} is too short`);
    const started = performance.now();
    maskSecretShapes(input);
    const ms = Math.round(performance.now() - started);
    t.diagnostic(`perf ${row.name} ms ${ms}`);
    assert.ok(ms < 1500, `linear time ${row.name}: ${ms} ms, budget 1500 ms`);
  });
}

test("a value cut by the tail byte window never appears", () => {
  const V = frag("fake", "CutWindow", "Q".repeat(56), "fakeEnd1");
  const vLine = `${PW}="${V}"`;
  const remaining = 40;
  const joinedTarget = 24 * 1024 - remaining - 1;
  const fillers = Array.from({ length: 149 }, (_, i) => `filler ${String(i).padStart(3, "0")} `.padEnd(100, "-"));
  const fixedLen = fillers.slice(0, 148).join("\n").length + 1;
  fillers[148] = "z".repeat(joinedTarget - fixedLen);
  const text = [vLine, ...fillers].join("\n");
  const unmaskedTail = text.split("\n").slice(-150).join("\n");
  const cutInside = unmaskedTail.length - 24 * 1024 === vLine.length - remaining;
  assert.ok(cutInside, "byte window cut does not land inside the value line (test setup)");
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
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const workflowDir = path.join(repoRoot, ".github/workflows");
const indentOf = (line) => line.length - line.trimStart().length;
const ASSIGN = /^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$/;
const refsVar = (text, name) => new RegExp(`\\$\\{?${name}\\b`).test(text);
// Matches only an uncommented line: optional `echo`, then `::add-mask::` plus the variable (optionally braced)
// either unquoted or inside double quotes whose closing quote follows the name directly. A single-quoted
// form (the shell would not expand the variable) and an unterminated double quote never match, and
// `$TOKEN_ID` never masks `$TOKEN`.
const isMaskLine = (line, name) => {
  const ref = `(?:${name}|\\{${name}\\})`;
  const bare = `::add-mask::\\$${ref}(?![A-Za-z0-9_])`;
  const dq = `"::add-mask::\\$${ref}"`;
  return new RegExp(`^\\s*(?:echo\\s+)?(?:${bare}|${dq})`).test(line);
};

export function secretBoundKeys(workflowText) {
  const keys = new Set();
  for (const line of workflowText.split("\n")) {
    const m = /^\s*([A-Za-z_][A-Za-z0-9_]*):\s*.*\$\{\{\s*secrets\./.exec(line);
    if (m) keys.add(m[1]);
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
    if (!m || /:\s*\$\{\{/.test(line) || /^\s*[A-Za-z_]\w*:\s/.test(line)) return;
    const [, name, rhs] = m;
    const bounds = runBlockBounds(lines, index);
    if (!bounds) return;
    // One level of transitivity: depth 1 derives from a secret-bound key, depth 2 from a depth-1 value.
    // Depth-2 values are not sources (a deployment id from an authenticated call is not itself a secret).
    let from = null;
    let depth = 0;
    for (const key of secrets) if (refsVar(rhs, key)) { from = key; depth = 1; break; }
    if (from === null && /\$\{\{\s*secrets\./.test(rhs)) { from = "secrets"; depth = 1; }
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

export function derivedSecretViolations(workflowText) {
  const lines = workflowText.split("\n");
  const violations = [];
  for (const a of derivedSecretAssignments(workflowText)) {
    let masked = false;
    let usedFirst = false;
    for (let k = a.index + 1; k < a.bounds.end; k += 1) {
      if (isMaskLine(lines[k], a.name)) { masked = true; break; }
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
    const mask = lines.findIndex((l, k) => k > idx && isMaskLine(l, name));
    if (mask >= 0) picked.push(mask);
  }
  const script = [...new Set(picked)].sort((a, b) => a - b).map((k) => lines[k].trim());
  for (const l of script) if (NO_NETWORK.test(l)) throw new Error(`refusing to run network line: ${l.slice(0, 40)}`);
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

test("live workflow tree: non-empty floor and zero violations", () => {
  let total = 0;
  const bad = [];
  for (const f of workflowFiles()) {
    const text = readFileSync(path.join(workflowDir, f), "utf8");
    total += derivedSecretAssignments(text).length;
    for (const v of derivedSecretViolations(text)) bad.push(`${f}:${v.line} ${v.name} (${v.reason})`);
  }
  assert.ok(total >= 1, "scan must find at least one derived assignment, else it is vacuous");
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
