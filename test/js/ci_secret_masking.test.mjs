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

function runSeededChild(s) {
  return spawnStage(process.execPath, ["-e", CHILD], {
    env: { PATH: process.env.PATH, CW_SEED_LINES: JSON.stringify(seedLines(s)) }
  });
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
  assert.deepEqual(leaked, [], `leaked: ${leaked.length} seeded value(s) reached the tail`);
});

test("masking keeps failure diagnosis and key or header names", () => {
  const result = runSeededChild(seedValues());
  const tail = rootProofFailureTail("failed", result);
  assert.match(tail, /1\) test something/);
  assert.match(tail, /root-proof failure tail \(failed;/);
  assert.match(tail, /Finished in/);
  for (const name of ["Authorization", "Cookie", "aws_secret_access_key"]) {
    assert.ok(tail.includes(name), `${name} name survives`);
  }
  assert.ok(tail.includes("***"));
});

test("short values are masked but 2-character words are left alone", () => {
  const s = seedValues();
  const masked = maskSecretShapes(`${frag("tok", "en")}=${s.short}`);
  assert.equal(leakedSecrets(masked, [s.short]).length, 0);
  assert.equal(masked, `${frag("tok", "en")}=***`);
  const plain = `${frag("tok", "en")}: ok`;
  assert.equal(maskSecretShapes(plain), plain);
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
const isMaskLine = (line, name) => new RegExp(`::add-mask::\\$\\{?${name}\\}?`).test(line);

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
  assert.equal(r.status, 0, `derivation child failed: ${r.stderr}`);
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
  assert.deepEqual(leaked, [], `leaked: ${leaked.length} value(s) reached the step log`);

  const stripped = script.split("\n").filter((l) => !l.includes("::add-mask::")).join("\n");
  const control = leakedSecrets(runnerMaskedLog(runDerivation(stripped, user, pass), [user, pass]), watched);
  assert.ok(control.length >= 1, "control: without add-mask the derived token must leak");
});

test("derivationScript refuses to extract network lines", () => {
  const text = fixture(`TOKEN=$(curl -s "$MAVEN_PASSWORD")`);
  assert.throws(() => derivationScript(text, ["TOKEN"]), /refusing/);
});
