---
phase: 175
phase_name: "rehearsal-and-publish"
project: "Crosswake"
generated: "2026-10-10"
counts:
  decisions: 2
  lessons: 11
  patterns: 3
  surprises: 3
missing_artifacts: []
---

# Phase 175 Learnings

Execution position and eligible commands belong to the active workstream STATE.md. Dated lessons and historical handoffs here do not authorize repeating completed attempts.

This file preserves the earlier extraction through Plan126 and adds focused lessons from Plans137–143. It is not a full reread of Phase175: 20 older plans have no matching summary files.

## Decisions

- Keep one-use external read approvals tied to the exact attempt and hashes. After a read returns UNKNOWN, do not retry it or reuse its approval. **Why:** each attempt is consumed once, and repeating a read before fixing a local error path produced the same empty result. **Source:** `175-125-SUMMARY.md`, `175-126-SUMMARY.md`.
- Keep dry-run acceptance narrow and based on actual Git output: exactly one expected new-tag row, optionally the fixed `To` banner, and optionally one final `Done` line. Reject all other extra lines. **Why:** a local bare-repository reproduction showed `Done` is Git's standard successful porcelain trailer. **Source:** `175-139-SUMMARY.md` and its sanitized evidence.

## Lessons

- An all-UNKNOWN result with no diagnostic does not by itself mean GitHub or credentials failed. In Plan126, that shape is produced when the Elixir layer cannot accept a Node collector result; the wrapper erases whether the cause was process startup, process exit, invalid output, or an exception. **Context:** `safe_current_collect/2` maps those paths to `:unavailable`, then the normalizer writes all read counts as UNKNOWN and the diagnostic as null. **Source:** `plan105_mirror_tag.ex` lines 1111–1165 and 2242–2256; Plan126's `read-result.json`.
- A repair to one collector path does not automatically repair its sibling. Plan115 documented broad collector exceptions; Plan116 added diagnostics to the older preflight path. Plan126 created a separate current-read wrapper, then tested its generic invalid-result fallback without preserving a safe reason. **Source:** `175-115-SUMMARY.md`, `175-116-SUMMARY.md`, `175-126-PLAN.md`.
- The loop was: fix the older reader, introduce a separate reader with a new wrapper, test valid UNKNOWN values but not wrapper failures, then spend another one-use read approval and get the same empty result. Put failure-mode tests at every wrapper boundary before asking for another read. **Source:** Plans115–116 summaries, Plan124 summary, Plan126 plan and summary.
- Fix and fake-test the local boundary before another external read. Carry existing authorization when its scope includes the read; request human action only for an actually missing external approval or credential. Preserve only a closed failure stage/code and counts the wrapper can actually know; never retain raw output or credentials. **Context:** Plan126 fixed the later valid-UNKNOWN path, but did not cover this earlier collector invocation path. **Source:** `175-126-PLAN.md`, `175-126-SUMMARY.md`.
- Lead user-facing evidence with ordinary language: name the check, its result, what is unknown and why, whether anything changed, and what can happen next. Put internal labels after that. **Context:** the Plan137 handoff used status codes without explaining that the preview had shown the expected new-tag line but its full output was rejected; the user could not tell what happened. **Source:** `175-138-SUMMARY.md`, “Lesson for future handoffs.”
- Name the operation directly: “PR #235 has 42 passing CI checks; six jobs are running.” Say what passed or failed, the concrete reason and the next action. Avoid “current evidence”, “last recorded evidence” and “last recorded live check”. The user rejected all three as cryptic. Source: direct user feedback, 2026-10-10/11.
- Before telling the user to run a selected wave, check GSD's computed dependency wave, not just the plan's manually assigned wave label. A `--wave` filter uses the dependency index; the wrong number can select no plans and look like a stall. **Context:** Plan143 was labeled Wave46 but GSD indexed it as Wave4; checking before dispatch exposed the mismatch. **Source:** `phase-plan-index 175`, 2026-10-10.
- When work is paused for a user's one-use choice, say plainly that it is waiting on the user, put the exact reply options and their effects first, and then give the exact resume command for a new session. Do not call the pause “done,” imply there is no next step, or bury the choice in status jargon. **Context:** the user asked what to do after repeated summaries named internal evidence without a clear follow-up. **Source:** Plan140/Wave43 handoff, 2026-10-10.
- A recognized line does not establish why the complete output was rejected. If the raw output was not retained, state that exact limitation and do not guess at extra lines or formatting. **Context:** Plan137 preserved a row count and safe status code, but not the preview text needed to identify the difference. **Source:** `175-137-SUMMARY.md`, “What happened, in plain language.”
- When a real command's output was not retained, a local reproduction can show a plausible cause but cannot prove it was the historical cause. Say which lines the local command produced, which fix followed, and what remains unconfirmed. **Source:** `175-139-SUMMARY.md`.
- Passing fake-path tests does not prove the production decision and apply path exists. Before creating an approval card, verify the exact production choice binding, durable write intent, bounded apply, uncertain-delivery handling, and terminal readback are implemented and exercised through injected boundaries. **Context:** Plan141's fake tests and card preparation passed, but Task3 could not bind the user's allow because those production modes were absent; no external call occurred. **Source:** `175-141-SUMMARY.md`.

## Patterns

- When the collector process is part of a bounded read, keep its failure boundary visible in sanitized form. Test the cases “returned error,” “raised exception,” and “invalid response” with fakes before creating a new read scope. **When to use:** any workflow where a local wrapper launches an external-read collector and the final artifact must explain safe failures. **Source:** Plan126 source audit and `175-126-SUMMARY.md`.
- For dry-run parsing, inject the expected output plus an extra line or blank line through the real parser; assert the result stays denied and no write or CI operation follows. **When to use:** whenever a release preview has strict output-shape requirements. **Source:** `175-138-PLAN.md`, `175-138-SUMMARY.md`.
- For command-output parsers, capture a safe local reproduction of the producer's standard output shape before labeling a line malformed; keep regression cases for both the real success envelope and nearby invalid envelopes. **When to use:** when production output text was discarded or a parser's expected format is uncertain. **Source:** `175-139-PLAN.md`, `175-139-SUMMARY.md`.

## Surprises

- Plan126's fake suite passed and repaired UNKNOWN-map normalization, yet the next read still produced the same generic result because the outer Elixir collector wrapper had a separate catch-all. **Impact:** we spent another one-use approval without learning which substep failed. **Source:** `175-126-PLAN.md`, `175-126-SUMMARY.md`, and the sealed Plan126 result.
- The first Plan138 regression expected a nonzero exit to reach the policy fallback. The runner had already recorded `PROCESS_EXIT_NONZERO`, so that earlier diagnosis correctly took precedence. **Impact:** the test was corrected to preserve existing behavior before the focused run passed. **Source:** `175-138-SUMMARY.md`.
- Plan138 initially treated Git's final `Done` line as an unexpected extra line. A temporary local bare-repository dry run showed that line is part of normal successful porcelain output, which Plan137's parser would reject. The Plan137 raw bytes are gone, so the local match is a likely explanation, not confirmation. **Source:** `175-139-SUMMARY.md` and the sanitized evidence record.

## Earlier Plan126 repair result

The Elixir-to-Node wrapper repair is complete. Fake tests cover a returned timeout, raised exception, invalid output, and an arbitrary error string; the sealed results retain only allowlisted codes and keep uncertain counts UNKNOWN. The focused ExUnit file passed 31 tests, and compile, format, and scoped diff checks passed. No external read was made. The exact lower-level cause of Plan126's completed read is still not recoverable from its saved result.

## Historical Plan141–143 handoff — superseded

This paragraph records the old Plan143 position and is not a current next action. The mirror-tag repair has since completed once in Plan148. Plan141 displayed a tag card, but its `allow` was not bound and no external operation occurred. Plan142 then added and verified the local decision, durable intent, bounded apply, readback, and terminal inspection paths. Plan143 is now planned and independently checked to use that path for one exact mirror-tag attempt. GSD indexes it in Wave4, so `--wave 46` would select nothing. No new card or attempt has been created. The exact next command is `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 4`; execution will display a new card and wait for a fresh plain `allow` or `hold` for that card. **Sources:** `175-141-SUMMARY.md`, `175-142-SUMMARY.md`, `175-143-PLAN.md`, `175-143-PLAN-CHECK.md`, and `phase-plan-index 175`.


## Continue local work without repeated permission requests

When an external runner stops, diagnose and repair a demonstrated local defect autonomously. Test the real production startup path with external boundaries denied; adapter-only success misses credential selection. Use the configured noninteractive helper rather than assuming a token variable. Preserve history through additive versioned collectors. State what failed, what was fixed, checks passed and the next action in ordinary words. Ask only for a genuinely new external one-use decision required by AGENTS; never ask again for routine local planning, implementation or checks.


## Workflow reset after repeated approval requests

### Decisions

Keep one active release sequence and one handoff. Retire superseded tag Plans89/106 administratively; preserve every existing attempt and the pending Plan145 card. Source: user request to clean up and return to OpenGSD; workflow-reset report.

### Lessons

A safe stop is an execution result, not a reason to make the user repeatedly restart the agent. Complete authorized local follow-up work without prompting. Separate observation evidence and irreversible authority internally; request decisions at the irreversible leg. Sources: CONTEXT D-07, D-96–99; Plans119–145; direct user feedback.

### Patterns

Archive obsolete handoffs, keep the phase's actual remaining outcomes visible, and close dead routes as superseded without claiming execution or requirement success. Source: STATE/ROADMAP conflicts and the phase-plan-index exposing Plan106 as ready despite its unmet receipt.

### Surprises

Repeatedly safe collectors accumulated 145 plan filenames while four release requirements stayed open. More proof infrastructure did not translate into release progress. Production startup still had an untested credential assumption until Plan144. Source: artifact inventory and Plan144 regression report.

## 2026-10-11 — Exercise real dependency contracts before a trust gate

The approved Plan145 attempt stopped before a tag push. runPreflight returns a raw four-field object, but the apply validator demanded a status field; fixture snapshots had invented it, hiding the production mismatch. Source review also found an incorrect push porcelain row and omitted Done trailer. The Plan146 repair tests the real production adapter shape and actual local Git output, reuses the existing vetted parser, and preserves safe failure reasons. Source: Plan145/146 summaries and local repair audit.

Lesson: test the actual dependency return shape and subprocess output before displaying a write proposal. Happy-path fixtures must match those contracts. Do not spend repeated user approvals discovering deterministic local mismatches. A preliminary unapproved reservation was retired rather than silently rebinding its collector digest. No consumed choice transfers.

## 2026-10-11 — Explicit standing authorization overrides repetitive human checkpoints

The user explicitly authorizes the remaining OpenGSD release workflow. Record that instruction and bind each concrete operation internally; do not demand repeated allow replies because old skill/planning text expects them. Consumed operation bindings remain immutable; fresh current-fact, policy and permission checks remain mandatory. Source: PHASE175-STANDING-AUTHORIZATION.md and this session's explicit instruction.

Plan148 created and independently verified the missing v0.2.6 tag after a bounded object-preparation repair. CI then passed, but the seven-day candidate proof artifact had expired; the agent refreshed that specific proof job without asking again. Hex/iOS/Maven rehearsals and their artifacts passed. Known-zero-write repairs and routine evidence refreshes belong inside the authorized delivery flow, not a sequence of user approvals.

## Authorization is settled; automated failure is separate

The user authorized the remaining Phase175 workflow. Do not translate an automated guard failure into a new conversational allow request. Ordinary run38105590960 failed before all publishers; describe it as an API collection failure, not a permission decision. Identify the failed read before claiming its cause. Sanitized local capture must preserve merged-actor presence with a fixed nonidentifying marker; removing login entirely changes the collector predicate and creates a false local failure. Preserve the original failed capture and make a distinct corrected read-only capture.

## Run release checks with the credential they actually need

The ordinary release guard used the default workflow token to read branch protection, an Administration read endpoint. The dedicated BRANCH_PROTECTION_READ_TOKEN already existed and its audit run38034757106 passed. Repair the shared collector to use that credential only for exact repository policy URLs, and supply it at all existing gate boundaries. Local CLI checks using a more privileged credential did not prove that the workflow token could perform those reads. Also keep Release Please in proposal-only mode when the strict guard has no consumed candidate context; a repair push must not release the older pending merged PR219. Test the patched remote source rather than trusting the stale dirty checkout workflow.

## Patch dependency locks and their snapshots together

The Decimal3.1.2 patch passed both audits, but broad CI rejected its unchanged exact-lock snapshot expecting3.1.0. Update that expectation in the same patch and run the repository-local snapshot test before pushing. All seven snapshot tests now pass. Preserve the full lock assertion rather than removing it. GitHub CLI job-log reads now reject terminal escapes by default; capture logs in memory with the explicit CLI flag and strip control sequences before extracting bounded assertions. Do not mistake that local read refusal for unavailable provider logs or a new permission gate.

## Retire an abandoned release proposal before generating its successor

Release Please refused to propose a successor while unpublished merged PR219 retained autorelease: pending. After proving that its ordinary run skipped every publisher and all three targets were absent, remove only that stale pending label. Do not mark it released. A distinct proposal-only run can then generate a fresh candidate under the repaired guard. This cleanup changed proposal metadata; it did not retry the failed publication or reuse its consumed authorization. PR222 now owns fresh CI and release checks.

## Run fixture subprocesses without inherited publisher authorization

A full candidate CI run and three rehearsals passed, but the ordinary Hex job runs tests after loading live REL17 context. Two fixture subprocesses inherited that context, changing their denial paths and stopping Hex before publication while the native siblings published0.2.8. Explicitly remove all inherited REL17 variables only in those subprocess environments before applying fixture inputs. Keep parent publisher authority and original assertions intact. Exact-source negative control reproduced2failures in20tests; repaired tests passed20/20 under the same loaded release settings. Verify test boundaries with the production environment present. Preserve the partial release and use a distinct normal successor; do not rerun consumed release authority.

## Exercise public consumer commands before another publication

Core0.2.9 reached Hex, the iOS mirror and Maven in one ordinary run. Native proof then failed because the iOS job invoked SwiftPM in a generated Xcode project and the Android job generated outside a consumer host with its required dependencies. The exact-public workflow also lacked dependency bootstrap and treated Hex's output argument as a filename rather than a directory. Run the repaired commands against already-public packages before another release; publication success alone does not prove the consumer path.

## Bind unchanged companion versions to their published source

The five public host profiles passed twice, but strict package comparison blocked every companion. The family builder archived companions under umask077, changing shipped file permissions, and rebuilt unchanged versions from current monorepo source. Threadline's current changelog also differs from its published version. Independently resolve each unchanged companion's versioned release tag, archive with original permissions, and retain each package's source ref in both CI and rehearsal. Core stays bound to the candidate head; a new unpublished companion version uses its own candidate head. Public proof resolves tags independently and never copies observed refs from the approved manifest. Rebuilding all five published tags matched actual public metadata and payloads exactly. Keep digest and source comparisons strict.

## Make companion receipt production and consumption agree

The companion receipt builder existed without a hosted workflow artifact path. The release guard also compared its normalized CI source digest to a different full CI receipt schema. Host the existing package-scoped receipt through the existing attestation workflow, validate actual same-head CI and rehearsal artifacts plus target absence, and derive the normalized CI digest independently in the guard. This receipt creates no publication authority; planned companion publication remains held until actual core COMPLETE.

## Compare hosted candidate artifacts with public baselines before publication

The local release-tag rebuild and public consumer proof passed, but Linux candidate CI built companion files as0664 because Git archive's default tar.umask differs from the local extractor's masking behavior. Preserve canonical Git modes with an explicit tar.umask=0022 and permission-preserving extraction; do not trust the runner's defaults. The existing Hex-page job also used a shallow checkout that omitted older tagged source objects. Give this existing artifact consumer full history/tags. A real archive fixture measures0664 before the override and0644 after it. Download and compare the actual hosted candidate rows against public companion baselines before advancing a release; candidate-local host success alone cannot expose mismatched published bytes. Disable a queued repair merge before revising its exact source, then use a new binding for the new head.

## Validate GitHub workflow context placement before relying on static checks

GitHub rejected the whole iOS authority workflow because runner.temp appeared in job-level env. Existing static integrity checks and all49candidateCI jobs passed without parsing that context. Actionlint reproduces the provider error and passes after moving OUTPUT_DIR into step env; the focused regression fails against original source and passes against the fix. Check workflow syntax/context with actionlint before remote publication prerequisites. Record rejected dispatches and inspect provider runs before any new attempt; never label an unobserved dispatch successful.

Before remote source writes, run the formatter on changed Elixir files, focused regressions and actionlint against every workflow context. PR229 first source omitted formatting and unnecessarily started another full CI cycle. Finish these local checks before creating or revising a PR. Existing workflow integrity assertions are not a substitute for GitHub expression validation.

## Retry only the condition that can recover

Android0.2.10 failed lint but repeated the whole build forty times while describing every failure as Maven propagation. Poll the exact external coordinate first, then run the build once and preserve its actual failure. The recurring generated-shell CI already owns this proof; include lint there so resource compatibility defects are caught before publishing. Do not use lint suppression or reduce the full release build to hide a demonstrated defect.

## Preserve executable permissions in remote repairs

When creating Git tree entries through the GitHub API, copy each existing file mode from the trusted base tree. Defaulting all entries to100644 removes executable permissions from shell scripts and breaks direct CI invocations. Audit the exact changed-file set and script modes before opening or updating the repair PR; new shell helpers should use100755. PR230 preserves these modes before merge.

## Check template maintenance before CI

After any existing shell template edit, run the standard template-version bump task and the drift check along with generator/diff tests before updating the PR. An unchanged template hash caused the same failure across eight full library CI jobs after native builds already passed. Use tracked CI for Git-dependent full-suite assertions; an archive alone lacks their repository metadata.

### Read the approved release source before diagnosing a new defect

The dirty root checkout predates the shipped companion CI projection fix. Comparing its old guard to the new producer falsely suggested another repair. The actual approved PR232 workflow already derives the correct compact CI digest and checks the same run/head. Inspect the fetched approved object first; do not propose another repair from stale local source. No remote change was made for this mistaken diagnosis.

## Diagnose browser infrastructure failures before changing source

Chimeway CI failed only when Chromium tried to capture a screenshot; its trace contains no application assertion failure and its browser test sources match the green core candidate. Finish the whole CI run, retain the bounded diagnosis, and permit one targeted job rerun under standing authorization if no other defect appears. Do not open another repair PR or weaken browser assertions from this single infrastructure error. A repeated failure needs diagnosis. CI reruns never substitute for retrying a failed publication.

Local archive checks also need honest limits: one release fixture derives Git HEAD and fails outside a repository. The same 94-test guard suite passed in a tracked checkout whose tests, libraries, scripts and workflows match the approved source byte for byte. Use that tracked result and preserve the archive failure.

## Check publisher ancestry from the runner checkout

Chimeway0.1.1 passed local ancestry checks but its publisher used a depth1 tag checkout. The shared gate correctly blocked before the Hex command. All five existing companion publishers now fetch full history; their existing checks reject missing history and depths1/2 through15mutations. Keep the failed ordinary run and consumed decision; use a fresh successor proposal and receipt instead of retrying publication.

## Keep frozen assertion references stable during guide regressions

Five added scalar assertions shifted support-matrix line references and broke the existing230-site inventory and frozen remediation check. Moving them into a separate final test preserves every old reference. The revised source passes100focused tests and2,065tracked full-suite tests with78excluded. Run the inventory, frozen-reference regressions and a tracked full suite before sending a related source revision to CI. The guide must still match its canonical renderer and reject the old wording.


## Keep shipped proof separate from local-only fixes

A successful local phase record does not show that the same code reached the release branch. The milestone audit found the matrix installer call and its old regression only in the dirty checkout; the actual approved release source still skipped that installer in the matrix. Read the exact Git object used by CI/publish, then promote only the missing existing contract. Preserve newer source-ref, package-fetch and shell repairs when doing so; copying the stale local script wholesale would undo them.

PR237 carries six added harness lines and four recurring source regressions. Original approved source fails the positive installer test; repaired source passes it and the other three mutations. Actual hosted candidate output has ten successful installer-before-doctor pairs. This correction requires a protected source merge, not another core publication. Keep the prior ordinary core/package results and history unchanged.
