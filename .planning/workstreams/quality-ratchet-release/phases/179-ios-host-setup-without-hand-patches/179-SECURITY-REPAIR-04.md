# Phase 179 — Managed Identity Variable Repair

The independent audit of `09dcb71` reproduced a higher-precedence managed bundle-variable override in actual Xcode: migration accepted it and one observed identity cell matched the override instead of the original declaration. T-179-05 remained open.

`0bb97c2` adds shell/proof variable-mask regressions. Before production repair the graph suite had **9 tests / 2 failures**, both new variable-mask cases. The Node proof-migration control and shell legacy-migration Xcode control also inject unconditional/conditional managed variable masks; their actual post-fix settings oracle remains the original ordinary declaration.

`492eb79` removes and post-validates all five managed bundle-variable names in project and target build settings, including SDK-conditional forms, through the same semantic byte-span rules as the other identity/signing settings.

Final candidate HEAD: `492eb79535097d512c4ce8e19bcd6192f014032d`; tree: `1b9de97292bdc957662e03625c5630827d3dea7d`. No tracked product changes remain uncommitted; only copied planning context is untracked.

Focused verification on these source bytes:

- Graph/managed/proof and maintained ledger/frozen-guard suites: **66 tests, 0 failures**.
- Actual Phoenix host and shell migration/Xcode suites: **9 tests, 0 failures**.
- Pinned Node/Xcode suite: **5 tests, 0 failures**, including both 20-cell signing matrices and reformatted/variable-masked proof migration.
- Compilation with warnings as errors, formatting and Git whitespace checks passed.
- Inventory remains **235** classified rows preserving all prior **231** keys and the original **52** frozen guards.

One Node setup attempt failed because a replacement PATH omitted `asdf` required by the Mix shim. Its private diagnostic established that cause; the normal PATH was preserved with Node 22.14 prefixed, and the complete suite then passed. Raw diagnostic output was removed after the safe cause was recorded. This was a harness setup failure, not a product observation.

Independent re-audits and final broad leaves remain pending on this commit. Earlier missing-output observations and missing pre-fix RED evidence are unchanged and are not reinterpreted.
