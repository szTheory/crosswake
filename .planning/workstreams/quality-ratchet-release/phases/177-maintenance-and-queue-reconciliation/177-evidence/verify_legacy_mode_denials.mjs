#!/usr/bin/env node
import { readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const candidateReview = JSON.parse(readFileSync(path.join(here, 'candidate-read-review.json'), 'utf8'));
const mirrorReview = JSON.parse(readFileSync(path.join(here, 'mirror-router-review.json'), 'utf8'));
const clone = process.env.CROSSWAKE_177_SOURCE_CLONE;
if (!clone) throw new Error('Phase177 source clone is not configured');
const routerTasks = new Map([
  ['lib/mix/tasks/crosswake.release.candidate_read.ex', 'crosswake.release.candidate_read'],
  ['lib/mix/tasks/crosswake.release.mirror_tag_026.ex', 'crosswake.release.mirror_tag_026'],
]);
const records = mirrorReview.modeRecords;
if (!Array.isArray(records) || !records.length || new Set(records.map((row) => row.mode)).size !== records.length) throw new Error('preserved router selector roster is invalid');
const roster = records.map((row) => {
  const task = routerTasks.get(row.routerPath);
  if (!task || row.pinnedSourceRouterPresent !== false || row.retirementClaim !== false) throw new Error('preserved router mode is not eligible for resolution-denial proof');
  return { task, mode: row.mode };
});
const candidateCount = roster.filter((row) => row.task === 'crosswake.release.candidate_read').length;
const mirrorCount = roster.filter((row) => row.task === 'crosswake.release.mirror_tag_026').length;
if (candidateCount === 0 || mirrorCount === 0 || candidateReview.plan93?.pinnedRouterPresent !== false) throw new Error('historical selector family inventory is incomplete');

function command(args) {
  const result = spawnSync('git', ['-C', clone, ...args], { encoding: 'utf8', timeout: 30000, env: { ...process.env, GIT_OPTIONAL_LOCKS: '0' } });
  if (result.error || result.signal || result.status !== 0) throw new Error('source status inspection failed');
  return result.stdout;
}
const before = {
  head: command(['rev-parse', 'HEAD']).trim(),
  branch: command(['rev-parse', '--abbrev-ref', 'HEAD']).trim(),
  index: command(['ls-files', '--stage', '-z']),
  status: command(['status', '--porcelain=v1', '-z', '--untracked-files=all']),
};

const elixir = String.raw`
roster = System.fetch_env!("CROSSWAKE_177_DENIAL_ROSTER") |> Jason.decode!()
aliases = Mix.Project.config() |> Keyword.get(:aliases, []) |> Map.new()
absent = Enum.all?(roster, fn row ->
  Mix.Task.get(row["task"]) == nil and not Map.has_key?(aliases, String.to_atom(row["task"]))
end)
unless absent, do: raise("a preserved selector unexpectedly resolves in the pinned source")
results = Enum.map(roster, fn row ->
  try do
    Mix.Task.run(row["task"], ["--mode", row["mode"]])
    :unexpected_return
  rescue
    error in Mix.NoTaskError -> {:denied, error.__struct__}
  end
end)
unless Enum.all?(results, &match?({:denied, Mix.NoTaskError}, &1)), do: raise("a selector did not fail at Mix task resolution")
IO.puts("PHASE177_DENIAL:" <> Jason.encode!(%{
  exercised: length(roster),
  candidateRead: Enum.count(roster, &(&1["task"] == "crosswake.release.candidate_read")),
  mirrorTag: Enum.count(roster, &(&1["task"] == "crosswake.release.mirror_tag_026")),
  deniedAtResolution: length(results),
  denialClass: "Mix.NoTaskError",
  parsedOptions: false,
  authorityRead: false,
  writerInvoked: false,
  networkInvoked: false,
  evidenceWritten: false
}))
`;
const result = spawnSync('mix', ['run', '--no-deps-check', '-e', elixir], {
  cwd: clone,
  encoding: 'utf8',
  timeout: 120000,
  env: { ...process.env, CROSSWAKE_177_DENIAL_ROSTER: JSON.stringify(roster) },
});
if (result.error || result.signal || result.status !== 0) {
  const cause = result.error?.code ?? (result.signal ? `signal-${result.signal}` : `exit-${result.status}`);
  throw new Error(`pinned Mix denial proof failed (${cause})`);
}
const proofLine = result.stdout.split(/\r?\n/).find((line) => line.startsWith('PHASE177_DENIAL:'));
if (!proofLine) throw new Error('pinned Mix denial proof produced no structured result');
const proof = JSON.parse(proofLine.slice('PHASE177_DENIAL:'.length));
if (proof.exercised !== roster.length || proof.deniedAtResolution !== roster.length || proof.denialClass !== 'Mix.NoTaskError' || proof.parsedOptions || proof.authorityRead || proof.writerInvoked || proof.networkInvoked || proof.evidenceWritten) throw new Error('pinned Mix denial proof did not satisfy the resolution boundary');
const after = {
  head: command(['rev-parse', 'HEAD']).trim(),
  branch: command(['rev-parse', '--abbrev-ref', 'HEAD']).trim(),
  index: command(['ls-files', '--stage', '-z']),
  status: command(['status', '--porcelain=v1', '-z', '--untracked-files=all']),
};
if (before.head !== after.head || before.branch !== after.branch || before.index !== after.index || before.status !== after.status) throw new Error('pinned source checkout, index, or working status changed during denial proof');
const publicProof = {
  schemaVersion: 1,
  phase: 177,
  result: 'all-preserved-selectors-denied-at-resolution',
  sourceIdentity: { commit: after.head, branchDetached: after.branch === 'HEAD' },
  selectorPopulation: { total: proof.exercised, candidateRead: proof.candidateRead, mirrorTag: proof.mirrorTag },
  denial: { class: proof.denialClass, atResolution: proof.deniedAtResolution, optionsParsed: proof.parsedOptions, authorityRead: proof.authorityRead, writerInvoked: proof.writerInvoked, networkInvoked: proof.networkInvoked, evidenceWritten: proof.evidenceWritten },
  checkoutUnchanged: true,
};
process.stdout.write(`${JSON.stringify(publicProof, null, 2)}\n`);
