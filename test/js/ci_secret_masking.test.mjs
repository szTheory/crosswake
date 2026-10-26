/* REL-03: secret values never reach CI output. Seeds are synthetic and built from fragments at runtime. */
import assert from "node:assert/strict";
import { test } from "node:test";

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
