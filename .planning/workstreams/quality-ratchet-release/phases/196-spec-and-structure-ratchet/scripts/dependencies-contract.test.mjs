import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { test } from "node:test";

test("six projects produce twelve isolated production declaration evaluations", () => {
  const result = spawnSync("elixir", ["script/check_runtime_dependencies.exs", "--root", ".", "--mode", "report"], {
    encoding: "utf8", timeout: 60000,
  });
  const line = result.stdout.split("\n").filter(line => line.startsWith("PHASE196_REPORT "));
  assert.equal(line.length, 1, "one closed report must describe evaluated declarations");
  const report = JSON.parse(line[0].slice("PHASE196_REPORT ".length));
  assert.equal(result.status, 0);
  assert.equal(report.counts.projects, 6);
  assert.equal(report.counts.branches, 2);
  assert.equal(report.counts.executions, 12);
  assert.ok(report.counts.declarations > 0);
  assert.deepEqual(report.findings, []);
});
