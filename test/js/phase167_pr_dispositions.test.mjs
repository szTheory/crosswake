import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

test("self-test covers seven ordinary PRs and separate recovery", () => {
  const result = spawnSync(
    "python3",
    ["script/check_phase167_pr_dispositions.py", "--self-test"],
    { cwd: root, encoding: "utf8" },
  );

  assert.equal(result.status, 0, result.stderr);
  assert.match(
    result.stdout,
    /phase167-pr-dispositions-self-test: PASS count=[1-9][0-9]*/,
  );
});
