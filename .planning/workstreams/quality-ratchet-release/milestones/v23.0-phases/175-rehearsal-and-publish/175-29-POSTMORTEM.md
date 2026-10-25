# Postmortem: successor core release 0.2.5

**Status:** PARTIAL; incident controls repaired locally; no recovery or retry authorized  
**Run:** ordinary Release Please run `36083361945`, after merge `405acd0f2d5476dc81f1ad1252a1661fa235c735`  
**Evidence:** `175-SUCCESSOR-CORE-RUN.md` and `evidence/175-successor-core-{run,registry}.json`

## Impact

The one authorized ordinary run published Hex `crosswake` 0.2.5 and iOS tag `v0.2.5`. Maven did
not publish and its POM was observed absent (HTTP 404). The iOS clean-room proof failed, so Android
and exact-public proof were skipped and both rollups remained PARTIAL. The Gate 2 token was
consumed by this run. No retry or recovery occurred. Central Portal state was not independently
observed.

## Causes supported by evidence

1. **Receipt roster disagreement.** The iOS attestation workflow uploaded
   `candidate-receipt.json`, `candidate-receipt.md`, and `artifacts.json`. The Maven consumer
   allowed only the JSON receipt and `artifacts.json`. It rejected the expected Markdown member
   before Java setup and before Maven credentials or publication. The producer and consumer each
   encoded a different contract.
2. **Proof topology mismatch.** The old iOS proof installed Crosswake as a global Mix archive and
   invoked the generator from the checked-out repository. It therefore did not model a host
   application declaring Crosswake as a package dependency. A local external Mix host using the
   source dependency generated the shell successfully, including with Jason available in the
   resolved dependency graph. The revised local proof then installed exact Hex 0.2.5 into a fresh
   external host, compiled its dependency graph, generated the shell, and read the generated JSON
   manifest successfully. This supports a proof-topology defect; it does not establish that the
   old published package itself was defective.

## Contributing conditions

- Static workflow checks did not compare the producer's uploaded file list to the consumer's
  accepted roster.
- The clean-room label described isolation from the build checkout, but the invocation still used
  an archive-installed task and the repository's own Mix project context.
- The authorized publication gate relied on preceding rehearsals whose proof topology differed
  from the subsequent consumer proof.

## Corrective and preventative actions

- Centralize the exact receipt roster assertion and exercise exact, missing, extra, and nested
  file cases in ExUnit. Keep this guard before Java setup and all Maven credentials.
- Exercise iOS generation from a newly created external Mix host with an exact Hex version pin;
  confirm the resolved Hex package version and generated manifest before Swift compilation.
- Assert workflow wiring so the artifact producer's three upload paths and both consumers remain
  aligned, and so archive-only proof cannot return silently.
- For future candidates, treat producer-consumer artifact compatibility and consumer-topology
  proof as pre-publication gates. Require fresh candidate evidence and separate authorization for
  any new one-way release action.

## Follow-up state

Local controls are implemented in Plan 175-33. Plans 175-30, 175-31, and 175-32 depend on the
failed 0.2.5 publication/proof path and are superseded. Plan 175-29 and its evidence remain
unchanged as the authoritative PARTIAL record. Any successor candidate must start with fresh
planning, rehearsal, and a new explicit authorization. No release or registry mutation is part of
this postmortem.
