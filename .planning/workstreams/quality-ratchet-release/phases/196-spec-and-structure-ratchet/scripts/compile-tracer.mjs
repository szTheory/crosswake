import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";

test("fresh bridge graph has no compile-connected cycle", () => {
  const env = { ...process.env, MIX_ENV: "test" };
  const compile = spawnSync("mix", ["compile", "--force", "--warnings-as-errors"], { env, encoding: "utf8" });
  assert.equal(compile.status, 0, "fresh compilation succeeds");
  const graph = spawnSync("mix", ["xref", "graph", "--format", "cycles", "--label", "compile-connected", "--fail-above", "0"], { env, encoding: "utf8" });
  assert.equal(graph.status, 0, "compile-connected threshold must be zero");
});
