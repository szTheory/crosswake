# Phase 175: Source Diagnosis Follow-up - Research

**Researched:** 2026-09-30; reconciled against final D-62–D-65 decisions
**Domain:** Git subtree source readiness, bounded Elixir/Mix process evidence, maintainer diagnostics
**Confidence:** HIGH for the local contracts and official Git/Elixir documentation; MEDIUM for an unexecuted follow-up design

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

The prior D-01 through D-53 decisions remain binding. Their complete verbatim text remains in `175-CONTEXT.md`; D-54 through D-65 below govern this follow-up's source and conditional evidence chain. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:74-438,781-875]

- **D-54:** Classify stdout with a closed, bounded grammar. Permit zero or one exact
  `To https://github.com/szTheory/crosswake-shell-core-ios.git` line as framing only. Require
  exactly one tab-separated porcelain status row with flag `*`, the fresh expected split object,
  destination `refs/tags/v0.2.6`, and `[new tag]`. Reject every other line, extra or malformed
  status row, nonterminal blank line, invalid/truncated decoding, and output-limit overflow. A zero
  exit code or a matching tuple surrounded by unknown output is not a pass. Do not retry an
  ambiguous invocation.
- **D-55:** Capture stdout and stderr separately. Exit status and complete stdout determine the
  dry-run verdict; nonzero exit always blocks. Stderr is diagnostic-only and is never parsed,
  echoed, excerpted, or persisted: retain only `EMPTY` or `NONEMPTY_UNINTERPRETED`. Nonempty stderr
  alone neither proves nor denies the target-ref result.
- **D-56:** Keep the receipt small, bounded, versioned, and privacy-safe. Record the Git version as
  diagnostic metadata, never as authority; also record parser schema version, expected-banner and
  status-row counts, unexpected/malformed stdout counts,
  truncation/limit state, and the two-state stderr classification, alongside the accepted tuple and
  existing invocation/exit facts. Use fixed low-cardinality block reasons and digest only the
  sanitized canonical receipt. Never persist raw output, snippets, raw command/environment,
  credentials/helper configuration, or hashes of raw output. Keep this a maintainer-facing text/
  JSON evidence path; no Phoenix/Plug/Ecto surface, dashboard, generic release API, retry UI, or new
  permanent CI lane is required. Use explicit words and stable reason codes so status never depends
  on color alone.
- **D-57 — Preserve and classify the source-boundary failure.** Keep the Plan 175-53 outcome at
  `SOURCE` / `FULL_CLONE_SPLIT_FAILED`. A new diagnostic attempt may distinguish invocation
  failure, nonzero exit, and invalid or missing split OID using bounded fields, with exit status
  when available and explicit full-history and commit-availability checks. Unknown facts remain
  unknown; do not reinterpret this as a dry-run failure.
- **D-58 — Bound recovery to one isolated attempt.** Plan one new isolated full-clone attempt. Allow
  at most one narrowly scoped local correction only if the bounded evidence proves a clone or
  invocation setup defect. Otherwise stop and require a reviewed source, path, or policy correction.
  No automatic retry, repeated driver invocation, or split-algorithm change.
- **D-59 — Require a fresh evidence chain before any dry-run.** If the split succeeds, the new plan
  must begin a complete fresh read-only preflight and calculate a new digest. Persist the durable
  reservation before no more than one authenticated `git push --dry-run --porcelain`, and invoke it
  only after every preflight gate passes. Then perform the plan's post-observations and independent
  audit. A passing dry-run grants no tag-write, merge, Gate 2, recovery, or publication authority.
- **D-60 — Keep the failure receipt bounded and private.** Persist only fixed low-cardinality
  classifications, nullable exit status, normalized Git version, and bounded boolean/count facts
  for history, source commit, OID, and split availability. Preserve unknown separately from false.
  Never print or persist raw stdout/stderr, command arguments, environment, local paths, remote
  details, credentials, helper configuration, or hashes of raw output. Keep the receipt versioned
  and digest only its sanitized canonical representation.
- **D-61 — Keep maintainer diagnostics user-centered and proportionate.** Use the existing
  maintainer text/JSON surface to show a stable reason code and one safe next action. Keep command
  execution at the Mix/shell boundary and classification pure and deterministic where applicable.
  This does not warrant Phoenix, Plug, Ecto, a dashboard, generic release API, retry UI, or permanent
  CI lane absent evidence of a recurring contract. Use explicit wording; never rely on color alone.

- **D-62 — Check required source facts before reservation.** In the separate follow-up plan,
  verify the `git subtree` command is available, the isolated clone has full history, the selected
  source commit is available, and the package-prefix tree exists at that commit. Record each check
  as true, false, or unknown. False or unknown blocks before reservation; passing checks do not
  guarantee that the split will succeed.
- **D-63 — Preserve the one-shot source operation and its attribution.** If all required checks
  pass in that reviewed plan, retain the existing subtree split algorithm, arguments, selected
  source, and stop rule; invoke it no more than once. Keep command execution at the Elixir Mix/shell
  boundary with explicit arguments and working directory. If code changes are justified, use a
  private process seam and pure classifier rather than a public Git abstraction. No retry, algorithm
  change, or continuation into a release side effect follows from this discussion.
- **D-64 — Never infer a cause from Git's human output.** Do not parse, retain, or display raw
  stdout/stderr. A nonzero exit without a direct bounded explanation remains `NONZERO_EXIT` with
  cause unknown. Preserve unknown separately from false, and do not expose arguments, paths,
  environment, remotes, credentials, or raw-output hashes in durable evidence or operator output.
- **D-65 — Explain the known facts and one safe next step.** Project the existing validated receipt
  into the existing text and JSON surfaces: stable reason and stage, source result, exit status when
  observed, explicit cause-unknown wording when applicable, and one next action (`REVIEW_SOURCE_SETUP`).
  Keep the wording calm, specific, and aligned to `brandbook/BRAND-SPEC.md`; color must not carry
  meaning alone. Add no UI, new taxonomy, or permanent CI lane without a recurring contract.

**Accepted D-64 clarification (subsequent user decision):** The prohibition above governs human diagnostic output and raw-stream retention/display. It permits strict, transient parsing of two operation-result surfaces only: the one successful subtree split OID and the exact D-54 porcelain stream. No human diagnostic text or stderr is parsed, persisted, or displayed. D-56 separately requires normalized `git --version` metadata from a distinct diagnostic query; that query also needs a strict safe-value grammar and cannot become source or porcelain verdict authority. The original D-64 text is retained verbatim above so the planner can see why this narrow clarification is required. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc; CITED: https://git-scm.com/docs/git-push; CITED: https://git-scm.com/docs/git-version; VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:438-462,867-875]

**New locked decisions for the Plan 175-69 follow-up (copied verbatim from `175-CONTEXT.md:1192-1210`):**

- **D-84 — Preserve bounded source outcomes independently.** Record a closed, low-cardinality
  observation state for each required source (PR identity, run roster, selected attempt jobs,
  required-check rollup, REST declarations, GraphQL declarations, workflow bytes, and final PR
  identity). Preserve only successfully normalized bounded facts, source completion state, and safe
  counts. If a source is not reached because a prerequisite is unavailable, represent it explicitly
  as not attempted; do not collapse earlier evidence into a generic all-UNKNOWN shape. The aggregate
  result remains UNKNOWN/BLOCKED unless every required source is complete, fresh, and identity
  matched.
- **D-85 — Keep failure diagnostics private and actionable.** Translate transport and decode
  failures into stable allowlisted reason codes and bounded source states. Never retain or render raw
  provider bodies, error messages, argv, endpoints, credentials, environment, local paths, or
  stdout/stderr. Text and JSON must show the same safe source completeness and one next action; an
  unavailable count remains UNKNOWN rather than zero. This is a maintainer CLI contract, with no
  Plug/Phoenix route, Ecto persistence, UI, or provider abstraction.
- **D-86 — Permit one fresh reviewed evidence attempt only.** After the local change is fake-tested
  and a new plan is independently reviewed, allow that plan to make at most one bounded
  read-only exact-head collection using a new attempt and immutable artifact/lifecycle pair. On any
  uncertainty, persist a sanitized UNKNOWN result and stop; no retry, rerun, source operation, tag,
  merge, Gate 2, recovery, registry write, or publication follows.

### the agent's Discretion

- Final file naming and internal section ordering within `docs/RELEASE-INCIDENT-RESPONSE.md`, beyond
  the structural constraints in D-15 and D-16.
- Exact wording of the three checkpoint prompts, subject to D-08 through D-11.
- Implementation shape of the `assertFullScope` helper and the version-literal CI check.
- Wave decomposition and task granularity within the structure recorded here.

### Deferred Ideas (OUT OF SCOPE)

- [Resolved 2026-09-26; see addendum below] Reconcile stale `.continue-here.md` resume metadata and
  the missing root `.planning/HANDOFF.json` as workstream-scoped GSD bookkeeping. This does not
  widen Phase 175 or change its release hold.
- Generating the version-specific parts of the release docs from `RELEASE-LEDGER.jsonl` — the ledger
  already has the right shape, but this is a codegen investment disproportionate to Phase 175's docs
  scope. Backlog.
- A docs freshness test asserting documentation claims against live registry state — catches semantic
  drift rather than just literal version numbers, but needs scheduled network calls in CI. Belongs in
  a future docs-freshness phase, not in the one-way-door phase.
- Auditing whether the SHAs pinned in Wave 0 are themselves correct, latest, or uncompromised — a
  separate audit step, SEED candidate per D-29.
- Extending the scope-cardinality gate beyond `scripts/ci_monitor.cjs` to other checks in the repo —
  SEED candidate per D-29.
- Querying the GitHub dependents graph to put the companion blast-radius comparison on a firmer
  footing than Hex download counts — would retire Assumption A1 but requires scraping; not needed to
  proceed.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research support |
|---|---|---|
| REL-13 | “A fresh successor core candidate publishes through one authorized ordinary version-generalized run to Hex, the iOS mirror, and Maven, each confirmed independently.” | This research helps establish a truthful iOS source boundary; it grants no REL-13 release action. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:70] |
| REL-17 | “Linked release, recovery, and companion publishers share one fail-closed validator over an immutable per-operation evidence envelope bound to the canonical receipt digest, exact candidate, leg, and run.” | Preserve the existing validator and release hold; source checks are evidence inputs, not a second authorization path. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:74] |
</phase_requirements>

## Summary

Plan 175-54's canonical receipt says `"stage":"BLOCKED_PREFLIGHT"`, `"boundary":"SOURCE"`, `"reason":"FULL_CLONE_SPLIT_FAILED"`, `"result":"NONZERO_EXIT"`, `"exit_status":1`, `"oid_count":0`, `"full_history":"TRUE"`, `"source_commit_available":"TRUE"`, and `"process_started":"TRUE"`. The receipt has `"split_oid":null`, `"invocations_reserved":0` for the later dry run, `"attempts":0` for writes, and `"decision":null`. It does not record whether the package prefix tree existed at the selected commit. These are facts about that one terminal attempt; exit 1 does not prove its root cause. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan54.json:1] The Plan 175-54 summary confirms that command output was not retained and no downstream preflight or mutation followed. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-54-SUMMARY.md:49-67]

**Primary recommendation:** Plan one separate evidence-only follow-up: four read-only source checks before reservation, at most one unchanged split if all four are `TRUE`, and terminal bounded classification on source failure. Permit the complete fresh preflight, new digest, single durably reserved authenticated porcelain dry run, post-observations, and independent audit only if that split passes. Preserve a narrowly proven setup correction under D-58; otherwise stop. The final artifact remains evidence, with zero writes and no release decision. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:784-803,834-875]

The current release bar remains open: `REL-13` and `REL-17` are pending, Plans 175-45 through 175-48 remain blocked, and no Phase 175 plan is runnable. Planning this follow-up does not replay Plans 175-49 through 175-54. [VERIFIED: .planning/workstreams/quality-ratchet-release/STATE.md:53-65; .planning/workstreams/quality-ratchet-release/ROADMAP.md:520-539]

## Project Constraints (from AGENTS.md)

- Use the active `quality-ratchet-release` workstream, preserve the phase's existing release hold, and keep the parked adopter workstream parked. [VERIFIED: AGENTS.md:6-16,68-78; .planning/workstreams/first-b2c-adopter-readiness/STATE.md:21-45]
- Keep Crosswake a Phoenix-first route-policy/runtime-contract library. This follow-up is maintainer release evidence, so it adds no runtime ownership, native, Android, sync, dashboard, brand-polish, or adopter-facing feature surface. [VERIFIED: AGENTS.md:18-50]
- Persist only bounded, privacy-safe evidence. Never expose identifying adopter data, raw payloads, credentials, account/device identifiers, Git arguments, paths, remotes, or raw process output in this diagnostic. [VERIFIED: AGENTS.md:52-64; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:867-875]
- Fail closed on missing or ambiguous evidence. Automate reproducible verification; add a permanent CI check only for a recurring contract with stable, actionable results. Reserve human approval for irreversible trust actions. [VERIFIED: AGENTS.md:38-42,79-88]
- If this follow-up changes a governing decision, update requirements, roadmap, state, and support truth together. The present research changes no decision. [VERIFIED: AGENTS.md:89-91]

## Architectural Responsibility Map

| Capability | Primary owner | Secondary owner | Why |
|---|---|---|---|
| Source readiness | Private maintainer process adapter in an isolated local clone | Git plumbing | The four observations must describe the exact environment where split would run. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:856-865] |
| Source operation | Existing shell/Mix boundary | Git subtree | Keep the selected source and options fixed, and reserve before the one allowed invocation. [VERIFIED: script/release_candidate/ios_mirror.sh:65-70; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:861-866] |
| Classification and receipt validation | Pure Elixir module | Versioned receipt writer | The current classifier is deterministic and validates exact keys; a follow-up can extend it privately for the new facts. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:4-42,69-97] |
| Conditional preflight and dry run | New plan's evidence procedure | Git remotes, current PR and policy facts | Source success is only an entry condition; fresh exact-candidate facts and a new digest must precede one authenticated dry-run reservation. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:427-463,807-821] |
| Post-observations and independent audit | New plan's read-only evidence procedure | Canonical receipt | Recheck mutable facts and audit the final evidence independently; the outcome offers no tag decision or write. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:807-821] |
| Maintainer explanation | Existing Mix text/JSON projection | Canonical sanitized receipt | The user needs known facts, unknown cause, and one safe next action, with no new authority surface. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:1-25,43-70; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:871-875] |

Phoenix, Plug, Ecto, and graphical UI have no ownership in this flow: there is no request, database record, or end-user screen to serve. The job is a low-frequency local maintainer CLI/evidence task. Adding those tiers would create another state and disclosure surface without helping the release proof. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:736-741,875-881]

## Standard Stack

| Component | Observed version or contract | Use | Confidence |
|---|---|---|---|
| Git and `git-subtree` | Local Git reported `git version 2.41.0`; a `git-subtree` executable is present under this Git installation's exec path. The future isolated clone must still be checked. | Read-only readiness checks, unchanged one-shot split, and conditional exact `git push --dry-run --porcelain` evidence. | HIGH for this workstation observation; only MEDIUM for the future isolated environment. [VERIFIED: read-only `git --version`, `git --exec-path`, and executable-file inspection on 2026-09-30; CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc; CITED: https://git-scm.com/docs/git-push] |
| Elixir / Mix | Local `Elixir 1.19.5` and `Mix 1.19.5`, with Erlang/OTP 27; `mix.exs` declares `elixir: "~> 1.19"`. | Existing task edge, `System.cmd/3`, pure classifier, and ExUnit verification. | HIGH. [VERIFIED: read-only `elixir --version`, `mix --version` on 2026-09-30; mix.exs:10-15; CITED: https://hexdocs.pm/elixir/System.html#cmd/3] |
| Existing project code | `Crosswake.ReleaseCandidate.IosTagSourceEvidence.classify!/1` and `validate_receipt!/1`; `Mix.Tasks.Crosswake.Release.Status`. | Extend the private contract only as the new receipt requires; reuse existing text/JSON conventions. | HIGH. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:69-97; lib/mix/tasks/crosswake.release.status.ex:29-70] |

No external package is needed or recommended. No package legitimacy gate applies. [VERIFIED: the four required facts are covered by installed Git commands, Elixir's standard library, and existing project code cited above]

## Architecture Patterns

### Bounded source and conditional evidence flow

```text
reviewed source follow-up
  -> isolated clone and selected source commit
  -> read-only checks: subtree executable, history, commit, prefix tree
  -> any FALSE/UNKNOWN: terminal SOURCE receipt + one safe explanation
  -> all TRUE: durable one-invocation reservation
      -> one unchanged git subtree split
      -> pure bounded result classification
      -> failed/ambiguous: terminal SOURCE receipt and stop
      -> exact split commit: complete new read-only preflight
          -> fresh canonical digest; all exact-candidate gates pass
          -> durable dry-run reservation and readback
          -> at most one authenticated git push --dry-run --porcelain
          -> complete bounded stdout classification; separate stderr class
          -> planned post-observations and independent audit
          -> validated sanitized receipt, fixed text/JSON explanation, zero writes
          -> stop before any tag decision, merge, Gate 2, recovery, or publication
```

The one narrowly scoped local correction in D-58 is available only when bounded observations prove a clone or invocation setup defect. It must stay within the reviewed attempt's explicit identity and stop rule; source/path/policy uncertainty or a correction requiring an unplanned repeat stops for separate review. No automatic retry or changed split algorithm is justified. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:784-821]

The `git subtree` manual says `split` extracts synthetic history for a selected prefix and local commit; on success it prints one commit ID on stdout. It also guarantees repeatability only for the same history and settings. Preserve the existing `"--prefix=packages/crosswake-shell-core-ios"` and `"$SOURCE_REF"` invocation shape from `ios_mirror.sh`; changing options would break attribution to the existing mirror contract. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc; VERIFIED: script/release_candidate/ios_mirror.sh:65-70]

The successful split OID has **no documented output-free recovery path under that unchanged invocation**. `--branch` would create a ref and change options; recomputing synthetic history would replace Git's algorithm with new logic. The accepted D-64 clarification therefore allows a private, bounded success parser: only after the split process itself exits 0, require exactly one 40-lowercase-hex OID and no other stdout bytes beyond its line ending, then verify that OID is a local commit. The current source classifier already requires `"oid_count":1`, `"oid_well_formed":"TRUE"`, `"split_commit_available":"TRUE"`, and a valid `"split_oid"` to return `"PASS"`. Any extra/malformed/truncated stdout, nonzero exit, unknown object, or incomplete observation remains terminal at `SOURCE`; no raw bytes or failure prose enter the receipt. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc; CITED: https://git-scm.com/docs/git-cat-file; VERIFIED: script/release_candidate/ios_mirror.sh:65-70; lib/crosswake/release_candidate/ios_tag_source_evidence.ex:6-14,194-245]

### Four pre-reservation observations

| Check | Preferred read-only evidence | Classification discipline |
|---|---|---|
| Subtree command available | Do not query and parse `git --exec-path` output: D-64 only authorizes transient parsing of the successful split OID and exact porcelain. Inspect the explicitly configured absolute `GIT_EXEC_PATH` by filesystem metadata; require regular executable `git-subtree` and readable `git-sh-setup`, then pass that same environment value to every Git child. If unset/unresolvable, classify `UNKNOWN`; if its helper is provably absent/nonexecutable, classify `FALSE`. Also reject `git subtree --help`: Git 2.41 rewrites `git cmd --help` into Git's help path before helper dispatch, so success does not prove the helper exists. | Presence under the exact configured helper path is `TRUE`; proven absence is `FALSE`; unset or ambiguous configuration is `UNKNOWN`. Do not use a split call as a capability probe. [CITED: https://git-scm.com/docs/git; CITED: https://raw.githubusercontent.com/git/git/v2.41.0/git.c; VERIFIED: read-only `git --exec-path` and executable-file inspection on 2026-09-30] |
| Full history | Inspect the fresh clone's expected `.git` directory and `.git/shallow` entry using filesystem metadata only. A regular shallow marker is `FALSE`; an expected directory with a proven absent marker is `TRUE`; symlink/unexpected gitdir topology or metadata errors are `UNKNOWN`. | A filesystem fact avoids parsing `git rev-parse --is-shallow-repository` stdout and does not imply that every required object exists. [CITED: https://git-scm.com/docs/git-clone; VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-55-PLAN.md:116] |
| Selected commit and source-tag identity | In the same full clone, classify only process-start/exit facts from `git cat-file -e <selected>^{commit}`, `git cat-file -e refs/tags/ios-core-v0.2.6^{commit}`, and both `git merge-base --is-ancestor <selected> refs/tags/ios-core-v0.2.6` / reversed operands. The selected-source fact is `TRUE` only when object checks and both ancestry checks exit 0; after both commits and full history are proven, ancestry status 1 proves an identity mismatch (`FALSE`); other nonzero statuses are `UNKNOWN`. | These documented machine statuses re-establish the reviewed tag-to-commit binding without reading OID or diagnostic output. [CITED: https://git-scm.com/docs/git-cat-file; CITED: https://git-scm.com/docs/git-merge-base] |
| Prefix tree at that commit | Run `git cat-file tree <selected>:packages/crosswake-shell-core-ios/` and classify only the process/exit result; the trailing slash requires a directory entry and explicit `tree` type. | Stdout and stderr are discarded; nonzero is `UNKNOWN` absent independent direct absence evidence. Do not use `cat-file -t` output or parse an `ls-tree` listing. [CITED: https://git-scm.com/docs/git-cat-file; CITED: https://raw.githubusercontent.com/git/git/v2.41.0/tree-walk.c; VERIFIED: script/release_candidate/ios_mirror.sh:65-68] |

The four facts are separately represented, though the selected-tag identity check uses proven full-history and commit-existence facts to distinguish mismatch from unknown. The Plan 175-54 receipt already established `"full_history":"TRUE"` and `"source_commit_available":"TRUE"` for its retired attempt; it does not establish those facts for a new clone, and it does not contain a prefix-tree fact. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan54.json:1] A failed or absent check blocks before the durable split reservation; all four passing only allow the separately reviewed one-shot source operation. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:856-866]

### Elixir process seam and attribution

`System.cmd/3` passes argv without shell interpolation, but its returned output does not provide a separately tagged stderr stream. The plan's private Node collector therefore drains and discards both precondition streams, returning only process-start and exit facts for readiness probes. It retains capped stdout bytes transiently only for the two D-64-authorized operation protocols: successful subtree split OID and exact D-54 porcelain. It never merges/parses human diagnostics. The existing shell adapter pipes `git subtree split` through `tail -1`, which can accept unclassified preceding stdout and obscure split exit attribution; the follow-up keeps its source/prefix/algorithm fixed while requiring one full bounded success stream. [CITED: https://hexdocs.pm/elixir/System.html#cmd/3; CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc; VERIFIED: script/release_candidate/ios_mirror.sh:65-70]

Use the current pure classifier's exact-key validation as the model. Its source observations quote `"process_started"`, `"split_invocations_reserved"`, `"exit_status"`, `"full_history"`, `"source_commit_available"`, and `"split_oid"`; its result vocabulary includes `"NONZERO_EXIT"`, `"OBSERVATION_UNKNOWN"`, and `"PASS"`. Any new fields require a new private versioned receipt schema and exact validator updates, with old Plan 175-54 receipt validity preserved. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:4-42,69-97,194-245]

### Maintainer output and developer experience

Validate the canonical receipt first, then derive both text and JSON from the same bounded projection. For the already observed result, the human message should convey: source blocked, split exited 1, cause unknown, review source setup. Keep the machine fields bound to the existing literal values `"BLOCKED_PREFLIGHT"`, `"SOURCE"`, `"FULL_CLONE_SPLIT_FAILED"`, `"NONZERO_EXIT"`, and `"REVIEW_SOURCE_SETUP"`; these values are quoted verbatim from the receipt and classifier, not proposed new labels. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan54.json:1; lib/crosswake/release_candidate/ios_tag_source_evidence.ex:11-23] The current Mix release-status task already accepts `--json`, builds one status, renders either JSON or human text, prints it before choosing a nonzero exit, and documents the read-only exit behavior. Reuse that output discipline rather than creating a new dashboard or generic API. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:1-25,29-70]

The ratified brand spec calls for error messages that are “Calm, specific, actionable” and technical writing that is precise and candid. Status must be intelligible without color. A fixed next action avoids making the maintainer interpret raw Git diagnostics under release pressure. [VERIFIED: brandbook/BRAND-SPEC.md:239-265,449-455]

### Conditional fresh preflight and porcelain dry run

An exact source success is the entry condition for the **same new plan's** fresh read-only preflight. Capture the source and mirror ref maps and their sanitized digests, source tag commit, mirror main and prior tag, absence of the proposed target tag, exact source/read/write target identity, PR head/base/readiness and required CI, effective policy and digest, helper identity, and push permission. The existing receipt validator requires these facts for `"complete":"TRUE"`; its literal fields include `"source_map_sha256"`, `"mirror_map_sha256"`, `"source_tag_commit"`, `"mirror_main"`, `"mirror_prior_tag"`, `"target_absent"`, `"pr_head"`, `"pr_base"`, `"pr_ready"`, `"required_ci"`, `"policy_sha256"`, `"helper_identity"`, and `"push_permission"`. Reobserve mutable facts for this new attempt; no earlier receipt, ref map, or digest can be promoted. If any required fact is missing, stale, changed, or ambiguous, retain `"BLOCKED_PREFLIGHT"`, zero writes, and a null decision. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:44-61,269-298; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:427-436,807-821]

After every preflight gate passes, compute a **new** digest over only the canonical sanitized evidence. Persist and read back a durable one-invocation reservation before at most one authenticated `git push --dry-run --porcelain`. An inability to persist/read back, an unknown invocation state, or a nonzero process exit blocks without retry. Git documents that `--dry-run` sends no ref updates and `--porcelain` emits tab-separated per-ref status on stdout. Those Git flags make a controlled observation possible, but exit 0 alone does not establish the target-ref result. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:427-463,807-821; CITED: https://git-scm.com/docs/git-push]

Parse the **entire** bounded stdout by D-54's closed grammar: permit zero or one exact `To https://github.com/szTheory/crosswake-shell-core-ios.git` framing line; require exactly one tab-separated status row with flag `*`, the **newly proven** split OID, destination `refs/tags/v0.2.6`, and `[new tag]`. Reject every other line, duplicate/extra/malformed status, nonterminal blank line, invalid or truncated decoding, and output-limit overflow. The accepted literals `"*"`, `"refs/tags/v0.2.6"`, and `"[new tag]"` are already enforced by the current validator. A matching row amid unknown text remains blocked. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:438-449; lib/crosswake/release_candidate/ios_tag_source_evidence.ex:328-334; CITED: https://git-scm.com/docs/git-push]

Capture stderr separately. It cannot provide a verdict or a root-cause label; retain only `"EMPTY"` or `"NONEMPTY_UNINTERPRETED"`. Nonempty stderr alone neither proves nor denies the one-ref result. The small versioned receipt records parser schema, bounded banner/status/unexpected/malformed counts, byte-limit and truncation flags, the accepted tuple if proven, exit facts, and normalized Git version as diagnostics. Never persist or echo raw stdout/stderr, snippets, command/environment/remote details, helper configuration, or raw-output hashes. The current validator quotes parser schema `"ios-tag-porcelain/v1"` and diagnostic fields `"banner_count"`, `"status_count"`, `"unexpected_count"`, `"malformed_count"`, `"stdout_overflow"`, `"stdout_truncated"`, and `"stderr_class"`. The accepted D-64 clarification leaves this D-54 porcelain parser intact: it consumes documented machine status, not human diagnostics. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:438-462; lib/crosswake/release_candidate/ios_tag_source_evidence.ex:50-57,300-324; CITED: https://git-scm.com/docs/git-push]

### Git version metadata must stay diagnostic

Git documents that `git --version` prints its version to stdout, but does not promise the project's exact retained string grammar. D-56 requires version metadata and says it is never authority. A strict parser is appropriate **before persistence** so arbitrary version output cannot become a log sink: the current validator accepts only `"git version "` followed by two to four dot-separated numeric components (`~r/\Agit version \d+(?:\.\d+){1,3}\z/`) or `nil`. Parse transiently, retain only the normalized accepted value, and discard raw bytes; an unexpected format is unknown diagnostic metadata, not permission to persist the raw string. [CITED: https://git-scm.com/docs/git-version; VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:4-10,573-577; VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:449-462]

There is a specific D-56 reconciliation for the planner: `accepted_dry_run?/2` currently requires `valid_git_version?(dry_run["git_version"])`, even though the receipt's field-level validator permits `nil`. That makes version formatting an implicit proof gate. The follow-up should preserve strict normalization for any stored value while aligning accepted dry-run classification with D-56's “diagnostic metadata, never as authority” rule; a missing/unrecognized version alone must not be mislabeled as an unsuccessful exact porcelain result. Keep the distinction explicit in tests and preserve validation of historical receipts. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:300-324,459-467,573-577; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:449-462]

If the dry-run evidence qualifies, perform the planned post-observations and **independent audit** against the same new attempt and digest. Recheck mutable source/mirror/PR/policy facts and compare them with preflight; fail closed on change or audit incompleteness. A complete audit produces only a proven evidence artifact. It still leaves tag writes, merge, Gate 2, recovery, publication, and any tag decision for a separately authorized plan. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:427-436,807-821; lib/crosswake/release_candidate/ios_tag_source_evidence.ex:336-355]

## Tradeoffs and Cross-Ecosystem Lessons

| Approach | Benefit | Failure mode / cost | Recommendation |
|---|---|---|---|
| Preserve only the opaque `"NONZERO_EXIT"` result | Minimal code and honest uncertainty. | Omits directly checkable setup facts; a maintainer receives little direction. | Keep as terminal fallback after all bounded checks pass and split still fails. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:846-855] |
| Parse Git stderr for a named root cause | Appears more specific. | `git subtree` documents a success commit ID, not a machine failure taxonomy; raw messages can contain private execution context. | Reject under D-64. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc; VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:867-870] |
| Check four preconditions before reservation | Direct, reproducible facts and early block for false/unknown. | More small probes; success is not a guarantee that split will succeed. | Select under D-62. [CITED: https://git-scm.com/docs/git-rev-parse; CITED: https://git-scm.com/docs/git-cat-file; VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:856-860] |
| Stop immediately after a successful split | Shorter plan and fewer authenticated steps. | Leaves the accepted D-59 evidence chain incomplete and would require another separately planned start with fresh facts. | Reject for this follow-up; proceed conditionally through audit in the same new plan. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:807-821] |
| Add a broad Git wrapper, second diagnostic taxonomy, or permanent CI lane | Could help if many call sites share a recurring contract. | Adds maintenance and potentially a competing authority surface for one held release investigation. | Defer until recurring evidence justifies it. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:853-875; AGENTS.md:79-88] |

GitHub's own checkout action fetches only one commit by default and calls for `fetch-depth: 0` to fetch all history. This is a useful CI footgun to check at the actual isolated clone, not a diagnosis of Plan 175-54: its receipt said full history was `TRUE`. Even `fetch-depth: 0` cannot substitute for checking the selected commit and prefix tree directly. [CITED: https://github.com/actions/checkout; VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan54.json:1]

## Don't Hand-Roll

| Problem | Do not build | Use instead | Why |
|---|---|---|---|
| Git history and object inspection | A parser over `git log`, `git show`, `git ls-tree`, or error prose | `.git/shallow` metadata, `git cat-file` exit status, and bidirectional `git merge-base --is-ancestor` exit statuses | Git supplies documented repository/object commands; readiness outputs are discarded, and only status facts cross into classification. [CITED: https://git-scm.com/docs/git-cat-file; CITED: https://git-scm.com/docs/git-merge-base; CITED: https://git-scm.com/docs/git-clone] |
| External process invocation | Shell command-string interpolation in Elixir | `System.cmd/3` with argv and `:cd` | Direct argument passing reduces quoting surprises and gives a real exit status. [CITED: https://hexdocs.pm/elixir/System.html#cmd/3] |
| Release authority | A second source-diagnostic approval gate | Existing REL-17 validator and separate reviewed downstream plans | The source receipt establishes local facts only. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:74; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:834-843] |

## Common Pitfalls

1. **Treating nonzero as a cause.** Exit 1 proves the command failed, not why. Keep cause unknown when all four readiness facts pass. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan54.json:1; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:867-870]
2. **Collapsing unknown into false.** An unavailable probe may mean an invocation or repository problem. The current classifier already has a literal `"UNKNOWN"` tri-state and `"OBSERVATION_UNKNOWN"` result; preserve that distinction in new fields. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:10-14,194-215]
3. **Using the worktree instead of the selected commit.** A directory visible now does not prove the prefix tree existed at the exact selected source commit. Check `<selected>:<prefix>` in the isolated clone. [CITED: https://git-scm.com/docs/git-cat-file; VERIFIED: script/release_candidate/ios_mirror.sh:65-68]
4. **Trusting checkout configuration as proof.** `fetch-depth: 0` is the intended full-history setting, but a later clone or fetch can have different state. Observe the same clone that would execute split. [CITED: https://github.com/actions/checkout; CITED: https://git-scm.com/docs/git-rev-parse]
5. **Losing exit attribution in a pipeline.** The existing `split | tail -1` code can accept the last line while ignoring preceding stdout and obscuring the split's own exit. A private process edge must require exit 0 and exactly one documented OID before it can record `"PASS"`. [VERIFIED: script/release_candidate/ios_mirror.sh:65-70; lib/crosswake/release_candidate/ios_tag_source_evidence.ex:194-245; CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc]
6. **Stopping the plan too early or promoting evidence too far.** A passing source split enters the same new plan's fresh preflight; a complete, fresh digest and all gates can then permit one durably reserved authenticated dry run and independent audit. None of these observations grants a tag decision/write, merge, Gate 2, registry, or publication. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:807-821,834-843]
7. **Scoring a partial porcelain parse as a pass.** Exit 0 and one matching row remain blocked if any other stdout is unclassified, malformed, truncated, or over limit. A nonzero exit always blocks; stderr only supplies the two-state diagnostic class. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:438-462; CITED: https://git-scm.com/docs/git-push]
8. **Using Git version prose as either authority or an output sink.** The current strict allowlist protects the receipt, but the accepted-dry-run predicate requires a recognized version string. Normalize version separately from split/porcelain results, and reconcile that hidden gate with D-56's diagnostic-only rule. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:4-10,459-467,573-577; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:449-462; CITED: https://git-scm.com/docs/git-version]

## Code Examples

These are patterns for the planner, not commands executed in this research. Keep each process private and reduce only filesystem facts or process-start/exit results to bounded tri-states. Never inspect precondition stdout. [CITED: https://git-scm.com/docs/git; https://git-scm.com/docs/git-merge-base]

```elixir
case collector.status_only(git, ["cat-file", "-e", selected_commit <> "^{commit}"], cwd: clone) do
  %{started: true, exit_status: 0} -> "TRUE"
  %{started: true, exit_status: status} when is_integer(status) -> "UNKNOWN"
  _ -> "UNKNOWN"
end
```

The collector does not return stdout or stderr in `status_only` mode. For exact source-tag identity, require exit 0 from commit object checks and both `git merge-base --is-ancestor` directions; Git documents exit 0 for ancestor and 1 for non-ancestor, while other error statuses remain `UNKNOWN`. [CITED: https://git-scm.com/docs/git-cat-file; CITED: https://git-scm.com/docs/git-merge-base]

The package-prefix probe similarly returns only `started` and `exit_status` for `git cat-file tree <selected>:packages/crosswake-shell-core-ios/`; the final slash requires a directory entry and the explicit type requests a tree. No OID/path/error output is read. The `GIT_EXEC_PATH` executable preflight inspects `File.Stat` type/access/mode metadata via `File.lstat/1` or `File.stat/1` and returns no path; ambiguous executable permission is UNKNOWN. [CITED: https://git-scm.com/docs/git-cat-file; CITED: https://raw.githubusercontent.com/git/git/v2.41.0/tree-walk.c; CITED: https://git-scm.com/docs/git; CITED: https://hexdocs.pm/elixir/File.Stat.html]

## Environment Availability

| Dependency | Local observation on 2026-09-30 | Follow-up rule |
|---|---|---|
| Git | `git version 2.41.0` was present. | Recheck within the new isolated clone; the local repository observation cannot stand in for that clone. [VERIFIED: read-only `git --version` on 2026-09-30; VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:856-860] |
| `git-subtree` | An executable was present in this Git installation's exec path. | Check the same capability in the planned execution environment before reservation. [VERIFIED: read-only `git --exec-path` and executable-file inspection on 2026-09-30] |
| Elixir / Mix | Both reported `1.19.5` with Erlang/OTP 27. | No new runtime or package is required for the proposed private boundary. [VERIFIED: read-only `elixir --version` and `mix --version` on 2026-09-30; mix.exs:10-15] |

The four source checks require no registry credential. The conditional preflight and one authenticated remote dry run require fresh remote/PR/policy observations and the existing authorized credential context; `--dry-run` sends no ref updates. Neither this research nor the recorded Plan 175-54 attempt exercised that conditional path. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:807-821; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-54-SUMMARY.md:67-71; CITED: https://git-scm.com/docs/git-push]

## Validation Architecture

The project enables `workflow.nyquist_validation: true`; existing focused source classifier cases use ExUnit. This research ran no implementation tests and made no source or release attempt. [VERIFIED: .planning/config.json:10-13; test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:1-5,25-105]

| Contract | Planned automated evidence | Scope |
|---|---|---|
| Four readiness states | Synthetic private-runner cases for each `TRUE`, `FALSE`, `UNKNOWN`, plus all-pass ordering and pre-reservation block. | No real source split in a unit case. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:856-866] |
| One-shot attribution | Fake process result cases: never started, nonzero, zero with missing/malformed OID, and valid OID; assert reservation before invocation and never a retry. | Existing ExUnit classifier fixtures provide a pattern. [VERIFIED: test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:25-105,181-205] |
| Accepted D-64 machine-result boundary | Feed bounded synthetic split stdout with one exact OID, extra lines, malformed/truncated bytes, and nonzero exit; require only the exact exit-0 OID to survive in a PASS receipt. Assert raw stdout/stderr never appear in text/JSON or durable evidence. | This resolves successful split attribution without interpreting Git's human diagnostics. [CITED: https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc; VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:194-245] |
| Conditional complete preflight | Synthetic fresh ref-map/target/PR/policy/permission facts; assert missing, changed, stale, or unknown values block before dry-run reservation and a passing split alone is insufficient. | Use a new attempt and digest, never a Plan 175-49..54 receipt. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:269-298; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:427-463,807-821] |
| One authenticated dry-run and full-stream classifier | Fake reservation readback failure, process nonzero, extra/unknown line, duplicate status, malformed tabs, invalid encoding, truncation/overflow, exact one-row success, and stderr empty/nonempty. Assert one invocation maximum. | Parser cases should consume bounded synthetic byte streams; no remote dry-run in unit cases. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:438-462; lib/crosswake/release_candidate/ios_tag_source_evidence.ex:300-334] |
| Git version diagnostic | Feed the existing strict grammar, an unexpected suffix/multiline value, and missing metadata; assert only normalized values persist and version alone does not decide the porcelain verdict after the D-56 reconciliation. | The version query is separate from split and dry-run streams. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:4-10,459-467,573-577; CITED: https://git-scm.com/docs/git-version] |
| Post-observations and independent audit | Compare fresh post facts and digest to preflight; inject changed/unknown observations and incomplete audit, then assert blocked result. | Even a proven audit leaves zero writes and null decision. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:336-360; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:807-821] |
| Receipt and privacy | Exact-key validation rejects extra path/output/remote/credential fields; digest canonical sanitized bytes, and preserve old receipt validation. | Existing tests reject `"raw_output"`, `"remote_url"`, and unsafe error echo. [VERIFIED: test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:116-164] |
| Maintainer projection | Compare human/JSON values from one fixture receipt; assert unknown-cause wording, one action, and nonzero status after output. | Existing Mix task prints before exit. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:43-70] |

The planner may use the focused command `mix test test/crosswake/release_candidate/ios_tag_source_evidence_test.exs` for existing and extended classifier cases; a new private runner test belongs next to that file if code is added. This is a proposed command, not a test result. [VERIFIED: test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:1-5; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-54-SUMMARY.md:54-61]

## Security Domain

| Applicable concern | Plan implication |
|---|---|
| Access control / least authority | Source readiness is read-only; only the conditional preflight may reach one authenticated dry run after durable reservation. Do not treat it as publication authority; existing REL-17 remains the release authorization path. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:74; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:807-821,834-843] |
| Input validation | Accept only the exact selected source, bounded tri-states, normalized status/version values, and exact receipt keys. Reject unknown additions before serialization. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:4-42,69-97,125-137] |
| Information disclosure | Command output, args, clone paths, environment, remotes, credentials, and raw-output hashes must not enter durable or operator output. Test unsafe-field rejection. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:867-875; test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:116-164] |
| Integrity and repudiation | Reserve the one invocation durably, read it back, and digest only canonical sanitized evidence; preserve old receipts as immutable historical records. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:861-866; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-54-SUMMARY.md:58-67] |

ASVS authentication and access-control lenses apply to the conditional authenticated dry-run permission boundary; input validation applies to exact Git output and receipt parsing. The existing SHA-256 digest is an integrity binding, not a reason to invent a new cryptographic scheme. Application session management is outside this maintainer task, and REL-17 still governs actual publication. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:74; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:438-462,727-741]

## Open Questions for the Separately Reviewed Plan

1. **RESOLVED — Plan 175-55:** `ios_tag_source_runner.ex` owns the private sequential probes, reservations and audit flow; `ios_tag_source_evidence.ex` owns pure closed v3/v4 validation and classification; the Node collector owns bounded process transport only. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-55-PLAN.md:1-36,128-170]
2. **RESOLVED — Plan 175-55:** If a required source fact is false/unknown, or the one reserved split does not yield exactly one valid successful OID, stop at SOURCE, keep cause unknown absent a directly observed fact, and require a separately reviewed plan before another source attempt. Plan 175-55 alone may continue after exact source PASS through one fresh preflight and at most one authenticated dry-run; it grants no tag or release authority. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:861-875; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-55-PLAN.md:91-124,174-208]
3. **RESOLVED — Plan 175-55:** Do not use `git subtree --help` for helper availability because Git rewrites `git cmd --help` to its help path before dispatch. Inspect an explicit `GIT_EXEC_PATH` and its helper files directly; if it is unset/unresolved, classify `UNKNOWN` and stop before reservation. Do not parse `git --exec-path` output. [CITED: https://git-scm.com/docs/git; https://raw.githubusercontent.com/git/git/v2.41.0/git.c]
4. **RESOLVED — Plan 175-55:** Re-establish source tag identity through exit-only commit-existence and bidirectional `git merge-base --is-ancestor` checks in the new full clone. Git specifies status 0 for ancestor, 1 for non-ancestor, and other nonzero for errors; no OID/output parser is added. Fetch the reviewed tag explicitly from the fixed public source URL into the private clone. [CITED: https://git-scm.com/docs/git-merge-base; https://git-scm.com/docs/git-clone]
5. **RESOLVED — Plan 175-55:** The package-prefix check is `git cat-file tree <selected>:packages/crosswake-shell-core-ios/` with the trailing slash. Treat it as exit-only evidence and discard both streams. Git's trailing-slash tree walk requires a directory entry; the explicit `tree` type ensures the selected object is a tree. [CITED: https://git-scm.com/docs/git-cat-file; https://raw.githubusercontent.com/git/git/v2.41.0/tree-walk.c]

## Sources and Confidence

- **Primary, HIGH for documented semantics:** [Git subtree manual](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc), [Git command/exec-path behavior](https://git-scm.com/docs/git), [Git clone](https://git-scm.com/docs/git-clone), [Git cat-file](https://git-scm.com/docs/git-cat-file), [Git merge-base](https://git-scm.com/docs/git-merge-base), [Git push](https://git-scm.com/docs/git-push), [Git version](https://git-scm.com/docs/git-version), [Git 2.41 dispatch source](https://raw.githubusercontent.com/git/git/v2.41.0/git.c), [Elixir `System.cmd/3`](https://hexdocs.pm/elixir/System.html#cmd/3), [Mix.Shell](https://hexdocs.pm/mix/Mix.Shell.html), and [actions/checkout](https://github.com/actions/checkout). Accessed 2026-09-30. The Git object/repository manuals include version history spanning the observed Git 2.41 family; the live subtree manual is an upstream source but does not provide a machine failure taxonomy. [CITED: https://git-scm.com/docs/git-cat-file; https://git-scm.com/docs/git-merge-base; https://git-scm.com/docs/git-push; https://git-scm.com/docs/git-version; https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc]
- **Project truth, HIGH:** `175-CONTEXT.md`, active quality `REQUIREMENTS.md`/`ROADMAP.md`/`STATE.md`, Plan 175-54 summary and sanitized receipt, `ios_mirror.sh`, the source classifier and ExUnit cases, release-status Mix task, `AGENTS.md`, and current `brandbook/BRAND-SPEC.md`; all were read in this session. [VERIFIED: paths and line ranges cited inline above]
- **Design recommendation, MEDIUM:** The proposed small process seam and exact four-probe ordering are derived from locked D-62 through D-65 and official command contracts. They have not been implemented or run against a new isolated clone. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:856-875]

**Assumptions log:** None used as a locked fact. The future split outcome and its root cause are unknown; the next plan must report observations rather than guess. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-ios-tag-026-plan54.json:1]

---

## Addendum — Exact-head evidence collection (2026-10-02)

### Immediate planning recommendation

Treat D-77 through D-83 in `175-CONTEXT.md` as the locked scope for the next reviewed plan. Create one fresh, immutable, read-only attempt that binds the selected PR and exact head/base OIDs to a digest of workflow bytes transiently fetched at that head, one run ID and attempt, its complete job roster, all required-check observations, and effective required-context declarations. Exhaust REST and GraphQL pagination; reconcile page totals, cursor progress, unique identities, and observed contexts against declarations. Bind status contexts to the head commit and workflow checks to the exact run attempt. Check the aggregate dependency contract against those same-head workflow bytes. D-78 keeps incomplete, pending, inaccessible, stale, changed, duplicate, or ambiguous observations at `UNKNOWN/BLOCKED`; its sole derived-aggregate exception requires the complete exact attempt to prove the parity leaf is the only independent failure and all other independent checks pass. [VERIFIED: `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1110-1122`]

The plan excludes a CI rerun, source split, push dry-run, tag or merge, Gate 2, recovery, registry write, and publication. Preserve Plan55 as `UNKNOWN`, REL-13 and REL-17 as `OPEN`, candidate readiness as `BLOCKED`, and the release hold as `ACTIVE`; any unresolved merge-policy fact remains separate and unknown. [VERIFIED: `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1123-1148`; `.planning/workstreams/quality-ratchet-release/STATE.md:58-59`]

### Architecture, DX, and validation guidance

Keep collection at the existing private Elixir/Mix boundary: `decode_gh_json(args, runner \\ &System.cmd/3)` is the local injected process seam, and the current `api? = List.first(args) == "api"` branch preserves `gh api` arguments without adding `--jq .`. Reuse that seam only with argument-shape coverage for pagination flags; pass decoded bounded facts into the pure evidence classifier. Do not turn `mix crosswake.release.status` into a hidden-network command or introduce a new HTTP dependency, Plug/Phoenix request path, Ecto store, dashboard, or generic provider layer. [VERIFIED: `lib/crosswake/release_candidate/ios_tag_source_runner.ex:1489-1514`; `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1129-1135`]

The maintainer’s job is to see which candidate and run were examined, whether evidence is complete/current, what is proven or unknown, and one safe next action. Render one sanitized classification as both human-readable text and JSON, using the established status words (`BLOCKED`, `STALE`, `READY FOR APPROVAL`, `PARTIAL`, `COMPLETE`). Keep argv, provider responses, credentials, environment, paths, and raw streams out of receipts and output; create a new opaque attempt/schema/artifact with a write-ahead, read-back-verified lifecycle. This is a CLI/operator surface, so no consumer UI or adopter route is involved; keep wording calm, explicit, actionable, and understandable without color. [VERIFIED: `lib/mix/tasks/crosswake.release.status.ex:19-21`; `.planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1136-1148`; `brandbook/BRAND-SPEC.md:3,239-265,454`]

Plan automated fake-response coverage for head/run/attempt mismatch, missing or duplicate pages/identities, count or declaration disagreement, pending/independent failure, invalid workflow bytes, and the narrow aggregate exception. This research performed no live repository reads, CI operations, or tests; it establishes no remote fact or release eligibility.

### Official references

- [GitHub REST rules](https://docs.github.com/en/rest/repos/rules) and [REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api)
- [Elixir `System.cmd/3`](https://hexdocs.pm/elixir/System.html#cmd/3) and [Mix tasks](https://mix.hexdocs.pm/main/Mix.Task.html)

---

## Addendum — Bounded partial observations after Plan 175-68 (2026-10-02)

**Scope and confidence.** D-84 through D-86 above are the locked decisions for this follow-up. This addendum recommends an implementation shape; it does not reinterpret the immutable Plan68 result or report a new remote observation. Confidence is **HIGH** for the inspected Elixir code and official language/API behavior, **MEDIUM** for the proposed v2 result model until its fake cases and one separately reviewed read-only attempt run. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1178-1219; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-68-SUMMARY.md:40-59]

### Primary recommendation and responsibility map

Implement a **new, private, versioned observation envelope** around the existing injected `gh` request function. Record the eight source outcomes independently; keep a normalized fact only after that source passes its complete parser and identity checks. Stop issuing reads on the first unavailable source, mark later sources as not attempted, seal one sanitized UNKNOWN artifact, and explain the failing source with one safe next action. On a fully observed attempt, run the existing exact-head, freshness, declaration, and aggregate predicates; the release disposition stays BLOCKED. Preserve Plan68's v1 validator and artifact byte for byte. Only after deterministic local fake tests and independent plan review may a new plan execute one fresh read-only attempt. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1192-1210]

| Capability | Owner | Boundary |
|---|---|---|
| Bounded remote reads and transport classification | Existing private `IosTagSourceRunner` Mix/process edge | Keep `decode_gh_json/2` and injected request function; map its tagged errors to a closed reason before any artifact or output. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:1499-1525,6690-6694] |
| Source outcome accumulation | Private runner, explicit sequential state | Record each completed stage before attempting the next. The current `plan68_collect_from_pr/3` instead uses one `with` chain, and `plan68_collect_facts/2` maps any downstream error to fallback facts. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:6787-6799,6881-6902] |
| Eligibility, schema, digest, projection | Pure `IosTagSourceEvidence` functions | Validate exact keys and cross-field invariants, then derive status and both text/JSON views from the same sealed artifact. The existing v1 builder, validator, and projection already establish this division. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:1221-1325] |
| User interface | Explicit maintainer Mix command | One command and one artifact pair; no request route, Ecto persistence, or end-user screen. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1200-1219] |

The Elixir documentation explicitly warns that `with` flattens failed matches into one `else` block and that variables bound inside `with` are unavailable there. That is precisely why a single chain cannot retain an already normalized run when a later GraphQL or workflow read fails. Use a small explicit accumulator and tagged results at each stage; do not add a generic provider abstraction or an exception-driven failure path. [CITED: https://elixir.hexdocs.pm/1.19.2/Kernel.SpecialForms.html; VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:6881-6902]

### Recommended source-result contract

The **proposed new schema vocabulary** is `COMPLETE`, `UNAVAILABLE`, and `NOT_ATTEMPTED` per source. These are new design values, not a claim that they already exist in v1. A source is `COMPLETE` only after its entire bounded response set is normalized; a GitHub response that is merely successful at the transport layer is insufficient. `UNAVAILABLE` covers attempted transport, decoding, shape, pagination, identity, or limit failure, with one allowlisted category. `NOT_ATTEMPTED` covers all later stages after a failed prerequisite and carries no fabricated counts. A complete source may contain a real failing check or run: source completeness describes observation quality, while the classifier decides eligibility. This separation follows the locked D-84/D-85 semantics. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1192-1205]

| Fixed source key (proposed) | Complete fact retained | Dependency and unavailable handling |
|---|---|---|
| `initial_pr` | Validated state, head/base OIDs and refs | First; on failure, every later source is `NOT_ATTEMPTED`. |
| `run_roster` | Exact-head normalized selected run, attempt, freshness inputs, complete safe count | Needs initial PR head/base. A missing selected completed run is unavailable, never a zero-job success. |
| `attempt_jobs` | Full selected-attempt normalized job set and safe count | Needs selected run ID/attempt; partial page sets remain transient and yield `UNAVAILABLE`. |
| `required_checks` | Full exact-head rollup and `isRequired` facts, safe count | Needs head/base and selected attempt for check-run binding; a GraphQL `errors` member makes this source unavailable even if `data` is present. |
| `rest_declarations` | Complete normalized REST policy declarations and source provenance | Needs base ref; incomplete or ambiguous pagination is unavailable. |
| `graphql_declarations` | Complete normalized base branch-protection declarations and provenance | Needs base ref/OID; GraphQL errors or missing rule data are unavailable. |
| `workflow` | Fixed workflow path, digest of the same transient decoded bytes used by the aggregate parser, bounded parser counts | Needs exact head; no workflow bytes or response envelope persist. |
| `final_pr` | Final validated identity and equality result against initial PR | Last; an actual mismatch is a directly observed mismatch, but still makes the whole observation UNKNOWN. |

The current v1 source-of-truth literally declares `"crosswake-plan68-exact-head/v1"`, `"pr_number"`, `"pr_head"`, `"pr_base"`, `"run_id"`, `"run_attempt"`, `"job_total"`, `"jobs"`, `"checks"`, `"rest_declarations_complete"`, `"graphql_declarations_complete"`, `"declarations"`, and `"workflow_sha256"`. Its allowed policy-source literals are `"GRAPHQL_BRANCH_PROTECTION"` and `"REST_BRANCH_RULES"`. Preserve those v1 meanings and validators for historical receipts, while adding a separate v2 schema and path for the new attempt. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:136-170] The v1 artifact digest, lifecycle, and narrow legacy unknown-shape compatibility must remain valid; the new validator must not let a v1 receipt masquerade as v2 or recompute a historical digest. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:1263-1285,1607-1631; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-68-SUMMARY.md:41-49]

Use one fixed eight-entry outcome map or ordered list with exact keys. Each entry should have `state`, a closed `reason`, and a count only if the source completed and the count was proven. Avoid a generic `details`, `message`, or `metadata` field. Proposed reason categories are `ok`, `transport_unavailable`, `decode_invalid`, `response_invalid`, `pagination_incomplete`, `limit_exceeded`, `identity_mismatch`, and `prerequisite_unavailable`; normalize the existing transport results before they cross the evidence boundary. The existing `decode_gh_json/2` literally returns `{:error, :invalid_json}`, `{:error, :output_oversized}`, or `{:error, :command_unavailable}` and discards error output; those low-level atoms can map to the closed categories without exposing provider prose. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:1499-1525] These proposed names can be refined during planning; the invariant is a small exact vocabulary and a deterministic one-to-one explanation for the attempted source.

**Counts and partial data:** `0` means a complete source proved zero records; `UNKNOWN` means no complete source count exists. Do not retain a count from page one of an incomplete roster or an error response. Retain only fully normalized source facts; if a later stage fails, the already completed source facts remain, with an explicit `UNAVAILABLE` entry for the failing stage and `NOT_ATTEMPTED` for later stages. A final PR mismatch invalidates overall eligibility but does not erase earlier historical observations. GitHub's REST pagination guide says the `link` header communicates more pages and can be absent for single-page results; GraphQL connections use `pageInfo.endCursor` and `hasNextPage`. GitHub also documents that GraphQL resource limits may return partial results plus an error. Therefore, source `COMPLETE` must require the existing page/count/cursor/uniqueness checks and rejection of any GraphQL `errors`, not just a successful HTTP or CLI exit. [CITED: https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api; CITED: https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api; CITED: https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api; VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:6996-7025,7583-7659]

### Implementation guidance and fail-closed derivation

1. Start with a fresh internal v2 result whose eight source states are `NOT_ATTEMPTED`, counts are `UNKNOWN`, and no earlier artifact is read as input. Reserve and read back a new opaque lifecycle identity before the first remote request, as the Plan68 runner currently does. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:6690-6727; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1187-1210]
2. For each fixed stage, call only the existing injected read adapter, normalize its entire source response within existing caps, then append a `COMPLETE` outcome and its allowlisted facts. On a tagged error or rescued unexpected exception, append `UNAVAILABLE` with a closed reason, stop immediately, and leave all later stages `NOT_ATTEMPTED`. Do not print/log the exception or transport output. Preserve the current read-only command-shape allowlist. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:1499-1525,6881-6902; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1200-1210]
3. Give the v2 pure validator cross-field rules: fixed source order and exact keys; `COMPLETE` implies fully normalized bounded facts and a known count where relevant; `UNAVAILABLE` implies one safe reason and no unvalidated partial facts; `NOT_ATTEMPTED` implies prerequisite failure and no count/facts; no later complete entry after the first unavailable entry under this stop policy. Validate head/run/attempt binding, source-provenanced declaration union, required-context reconciliation, workflow digest and aggregate predicate only when all inputs are complete. Any incomplete, stale, changed, pending, contradictory, or ambiguous source keeps `observation_status` UNKNOWN, `candidate_readiness` BLOCKED, `release_hold` ACTIVE, and `merge_policy_status` UNKNOWN. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1192-1210; lib/crosswake/release_candidate/ios_tag_source_evidence.ex:1263-1285,1468-1598]
4. Seal only the validated canonical v2 artifact and separate lifecycle path. Validate artifact digest, exclusive path, lifecycle event order/readback, attempt ID, terminal classification, and privacy allowlist locally. Keep the temporary explicit collection Mix task only for the reviewed attempt, then remove it after local artifact validation. The historical v1 pair is immutable. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:6690-6782; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-68-PLAN.md:120-184; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1180-1210]

**Code example, using the existing tagged-result shape:** the runner currently returns `{:ok, pr}` or `{:error, :pr_identity_unavailable}` from `plan68_read_pr/1`, and the current page collector returns `{:error, :incomplete_pages}`. These literal values appear in source; the following is a design sketch for the new accumulator, not a copied function. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:6787-6799,6847-6879,6996-7025]

```elixir
# Proposed private pattern; normalize the source before updating the accumulator.
case read_and_normalize.(request) do
  {:ok, facts} -> {:cont, put_complete(acc, source, facts)}
  {:error, reason} -> {:halt, put_unavailable(acc, source, closed_reason(reason))}
end
```

An explicit `case` or `Enum.reduce_while/3` over the fixed stage order is idiomatic here because the accumulator is the diagnostic product. `with` remains useful *inside* one source parser, where a failed match should discard that source's partial data. [CITED: https://elixir.hexdocs.pm/1.19.2/Kernel.SpecialForms.html; CITED: https://hexdocs.pm/elixir/Enum.html#reduce_while/3]

### Maintainer DX and validation architecture

Project one validated v2 artifact into both text and JSON. Put overall status and hold first, then eight short source rows in execution order with state, safe count (or `UNKNOWN`), and one allowlisted reason on the unavailable row. End with one safe next action, such as reviewing the separate evidence plan for the named source; never suggest an automatic retry or release action. Text must work without color; JSON must carry the same source order and values. The current v1 projection already derives JSON and human text from a validated artifact and prints `"UNKNOWN"` for unavailable counts; reuse that discipline. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:1295-1355; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1200-1219; brandbook/BRAND-SPEC.md:239-265]

The existing project has `workflow.nyquist_validation: true`, ExUnit runner/evidence tests, injected fake requests, a fake GraphQL partial-error case, oversize workflow canary, lifecycle validation, and second-attempt rejection. Extend those focused files; no new package, networked test, permanent CI lane, or UI test is needed. [VERIFIED: .planning/config.json:9-14; test/crosswake/release_candidate/ios_tag_source_runner_test.exs:2003-2160; test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:664-785]

| Requirement | Deterministic fake assertion |
|---|---|
| D-84 | Inject one failure at each of the eight source boundaries; all prior complete facts and counts survive, the failing source is unavailable, and later sources are not attempted. Check the request trace stops at the intended boundary. |
| D-84/D-85 | Incomplete page, duplicate ID, unstable total, cursor stall, GraphQL `errors` with partial `data`, oversize workflow, and malformed decode never store partial source records or a false zero. |
| D-85 | Insert a private canary in provider body, error text, argv, and exception message; assert it is absent from artifact bytes, lifecycle, text, and JSON. Assert unknown counts render as `UNKNOWN`; text and JSON show identical source outcomes and next action. |
| D-84/D-86 | Complete fixture still proves only the narrow aggregate observation; freshness/head/attempt/policy changes keep UNKNOWN/BLOCKED. Old Plan68 v1 artifact and digest still validate unchanged. A second invocation against an occupied v2 path makes zero requests. |
| D-86 | Local artifact/lifecycle validator checks exact new path, opaque attempt, canonical digest, and terminal order. After independent review, one fresh read-only collection is the only live step; inspect its sealed artifact without repeating the collector. |

Use the two existing focused test commands at planning time: `mix test test/crosswake/release_candidate/ios_tag_source_runner_test.exs test/crosswake/release_candidate/ios_tag_source_evidence_test.exs` for local deterministic behavior, then a local artifact validator for the one new pair. This research ran no tests or GitHub repository/API calls. [VERIFIED: test/crosswake/release_candidate/ios_tag_source_runner_test.exs:1854-2160; test/crosswake/release_candidate/ios_tag_source_evidence_test.exs:664-785]

### Pitfalls, security, and state inventory

- **False source certainty:** A transport success with partial GraphQL data, a partial REST page, or a valid count before the final page does not establish `COMPLETE`. Treat only fully normalized source sets as complete. [CITED: https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api; CITED: https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api]
- **Error laundering:** Do not copy `gh` output or exception strings into reason codes or operator messages. The current `decode_gh_json/2` merges stderr into a transient output buffer and maps nonzero/oversize/invalid JSON to bounded atoms; the new envelope must retain only an allowlisted derived category. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:1499-1525]
- **Premature aggregate interpretation:** A completed parity leaf or a valid workflow digest does not promote an incomplete required-check or policy set. Compute the existing aggregate exception only after all eight sources complete and final identity matches. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:1540-1598; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1192-1210]
- **Schema collision:** Do not add fields to the Plan68 v1 exact-key contract, overwrite its artifact path, or alter its digest. The new plan needs its own schema and exclusive paths. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_evidence.ex:1263-1285; lib/crosswake/release_candidate/ios_tag_source_runner.ex:6698-6705]

Security lenses: ASVS V4 access control applies to keeping the `gh` command allowlist read-only and withholding release authority; V5 input validation applies to exact schema, response caps, pagination, and identity binding; V6 cryptography applies only to the existing canonical SHA-256 integrity binding, with no new crypto. V2 authentication remains the existing GitHub CLI credential boundary; V3 application sessions do not apply to this local maintainer command. Sensitive response bodies and diagnostics cross the provider boundary only transiently, and no raw provider data enters the durable artifact or operator output. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-68-PLAN.md:187-216; lib/crosswake/release_candidate/ios_tag_source_runner.ex:1499-1525; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1200-1210]

| Runtime-state category | Follow-up action |
|---|---|
| Stored data | Preserve the existing Plan68 v1 artifact and lifecycle; create a new v2 pair. No migration or rewrite of the old pair. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-68-SUMMARY.md:25-49] |
| Live service config | No service configuration change is in the locked D-84–D-86 scope; branch policy is read as evidence only. This research did not inspect remote service state. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1192-1210] |
| OS-registered state | No registration change is in scope; the command remains a temporary local Mix task. This research did not inspect OS registration. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1200-1210] |
| Secrets/env vars | Continue using the existing `gh` credential context for the later reviewed read; no credential name/value enters evidence. This research did not inspect secret stores. [VERIFIED: lib/crosswake/release_candidate/ios_tag_source_runner.ex:1499-1525; .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-CONTEXT.md:1200-1210] |
| Build artifacts | Mix may compile the temporary task for the reviewed attempt; remove its source module afterward. Do not treat a compiled artifact as evidence or release authority. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-68-PLAN.md:120-184] |

No external package is recommended, so no package-legitimacy or registry check applies. `gh`, Elixir, and Mix executables were present in this local research environment on 2026-10-02; their versions and remote credentials were not probed here. The existing `mix.exs` literal declares `elixir: "~> 1.19"`; a future plan should use this project environment and the existing Jason dependency, not install a new HTTP client. [VERIFIED: read-only `command -v gh`, `command -v elixir`, and `command -v mix` on 2026-10-02; VERIFIED: mix.exs:10-15,49-61]

**Open observation:** Plan68 retained no causal source or request count, so this research cannot identify which live source failed; the new attempt may also end UNKNOWN. The new model will make *that* attempt diagnosable, while granting no source operation, CI rerun, or release permission. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-68-SUMMARY.md:38-59]

**Primary sources consulted on 2026-10-02:** [Elixir `with` and `else`](https://elixir.hexdocs.pm/1.19.2/Kernel.SpecialForms.html), [Elixir `Enum.reduce_while/3`](https://hexdocs.pm/elixir/Enum.html#reduce_while/3), [GitHub REST pagination](https://docs.github.com/en/rest/using-the-rest-api/using-pagination-in-the-rest-api), [GitHub GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api), [GitHub GraphQL rate and resource limits](https://docs.github.com/en/graphql/overview/rate-limits-and-query-limits-for-the-graphql-api), [Mix tasks](https://mix.hexdocs.pm/main/Mix.Task.html). Context7 MCP and `ctx7` CLI were unavailable, so official documentation pages were used. The research-plan seam selected Context7 for Elixir/Mix and web search for GitHub; the confidence seam rated verified web-search findings MEDIUM. No package or API was installed or invoked. [VERIFIED: read-only tool availability checks and `gsd-tools query research-plan` / `classify-confidence` on 2026-10-02]
