# Source-verifier reconciliation after the terminal pilot

The actual source verifier now passes against the committed phase state: `measure-main: verified source 1359`, exit0. This reconciles provenance only. Phase196 remains13/17 complete, plan14 halted, plans15–17 blocked and all eight requirements pending. There is no eligible execution command until the recorded SPEC-04 roadmap disposition is resolved.

The audit found exactly two mismatches among25 protected files:196-13-PLAN.md and196-14-PLAN.md. Their identical four-line “Resolved attempt contract” insertion is the reviewed commit `dad4d998c63da02ef6c80d4745cd3c4659e20cb9`, parent `52bebc6cfd774f2dbf35e80074135ffa7303cb95`. Its resolution document retains the official `--no-tce`, original full acceptance criteria and carried340269.58370900154ms within the same1800000ms ceiling. This follow-up creates no attempt or allowance to rerun that now-terminal pilot.

The original `196-EVIDENCE/execution-source.json` is unchanged, SHA256 `4395af905530c1d1bd5680276faf2e6586f21352bfaf65c4bf7a807bf6c16aec`, originally committed at `8b613331f6b81419e1e4eb928355d5a20692e1ff`. Its preserved baseline `101e853a0fafdcec4675afceb8fcf6c48db98762`, transfer `784fe638afbe93bb1bd5ba80110fd03fa31fc589` and every original protected hash remain authoritative.

One fixed sidecar, `196-EVIDENCE/source-amendment-13-14.json`, records the reviewed commit/parent, immutable receipt identity, exact two paths' before/after hashes and resolution-document hash. The verifier checks old bytes at the immutable preservation and transfer, old bytes again at the amendment parent, exact protected-path delta at the reviewed commit, ancestry, and current plus HEAD bytes against the reviewed new objects. It validates the sidecar's exact schema/content and committed bytes; the original receipt and resolution text must also match their pinned git objects. All other23 protected files continue to require their original hashes. This is one historical amendment allowance, not a registry or a general permission to edit protected plans.

Code/evidence commit: `00cc1f3b` (`fix(196): verify exact committed plan13 and plan14 amendment`). Files are the phase helper, matching measurement-controls receipt and the one amendment sidecar. The helper's fixture override is inaccessible on the actual repository; production uses the fixed reviewed identity.

Verification commands from repository root:

```sh
node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs self-test
node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs verify-source
node --check .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs
git diff --check
```

Results: self-test exit0,50 controls passed (27 source,23 capture); actual verify-source exit0,1359 original supported-source records; syntax/diff checks exit0. Real git fixtures prove acceptance of the legitimate committed amendment and rejection of extra protected paths, altered protected receipts, later committed or dirty plan changes, stale original restoration, changed resolution, rewritten original receipt, wrong evidence hashes, extra evidence paths, wrong amendment identities, malformed/missing/uncommitted evidence, wrong parent, extra protected amendment scope and unreachable amendment commits. The existing clean-source and capture/refusal controls remain green. `measurement-controls.json` hashes the current helper and retains the measured per-suite results.

Every commit used fresh conditional absolute per-file privacy scans before and after. No Muex, Mix or native suite was run, no aggregate clock was reset, no roadmap or requirement changed, and no push, PR, merge, publish, tag or branch deletion occurred. The state update records only resolution of this source-verifier mismatch and preserves the terminal handoff.
