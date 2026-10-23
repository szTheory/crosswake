# Phase 175: Rehearsal and Publish — Research

**Researched:** 2026-10-07
**Domain:** Release preflight evidence, bounded GitHub/Git reads, attempt lifecycle
**Confidence:** HIGH for local contracts/tests; MEDIUM for any future live-read boundary.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

> **D-107 — Wait for independent evidence; keep the release held.** Do not create another plan or provider attempt solely to recover from Plan82's unavailable response. Re-enter Phase 175 only when a genuinely new, independently produced, machine-verifiable signal supplies current, decision-relevant facts for the same exact candidate. At that point, use a fresh plan and preserve the existing review, authorization, attempt, and evidence boundaries. A new signal does not itself satisfy REL-13/14/15/17 or authorize a CI rerun, Gate 2, merge, recovery, registry action, tag write, or publication. Do not substitute a candidate. No recurring CI lane is added for this one-time readiness reconciliation. [VERIFIED: 175-CONTEXT.md:1732-1739]

> A new passing CI receipt is a sufficient trigger, but a newly verified exact-candidate ref change or discrepancy can also trigger planning. Neither trigger proves readiness. [VERIFIED: 175-CONTEXT.md:1799-1803]

> This opens planning only; Plan92's attempt stays terminal. Plan88 remains halted, Plan89 remains blocked by Plan88, and Plans46–48 remain held. [VERIFIED: .continue-here.md:18-26]

### the agent's Discretion

- Final file naming and internal section ordering within `docs/RELEASE-INCIDENT-RESPONSE.md`, beyond
  the structural constraints in D-15 and D-16.
- Exact wording of the three checkpoint prompts, subject to D-08 through D-11.
- Implementation shape of the `assertFullScope` helper and the version-literal CI check.
- Wave decomposition and task granularity within the structure recorded here. [VERIFIED: 175-CONTEXT.md:516-523]

### Deferred Ideas (OUT OF SCOPE)

- [Resolved 2026-09-26; see addendum below] Reconcile stale `.continue-here.md` resume metadata and
  the missing root `.planning/HANDOFF.json` as workstream-scoped GSD bookkeeping. This does not widen
  Phase 175 or change its release hold.
- Generating the version-specific parts of the release docs from `RELEASE-LEDGER.jsonl` — the ledger
  already has the right shape, but this is a codegen investment disproportionate to Phase 175's docs
  scope. Backlog.
- A docs freshness test asserting documentation claims against live registry state — catches
  semantic drift rather than just literal version numbers, but needs scheduled network calls in CI.
  Belongs in a future docs-freshness phase, not in the one-way-door phase.
- Auditing whether the SHAs pinned in Wave 0 are themselves correct, latest, or uncompromised — a
  separate audit step, SEED candidate per D-29.
- Extending the scope-cardinality gate beyond `scripts/ci_monitor.cjs` to other checks in the repo —
  SEED candidate per D-29.
- Querying the GitHub dependents graph to put the companion blast-radius comparison on a firmer
  footing than Hex download counts — would retire Assumption A1 but requires scraping; not needed to
  proceed. [VERIFIED: 175-CONTEXT.md:829-848]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| REL-10 | A retire/backfill runbook covering Hex, the iOS mirror, and Maven is committed before the first publish of this milestone — **BREACHED at Gate 1 (2026-09-19):** commit d3401e51 existed only on divergent local main; PR #147's base, head, and publish-triggering merge omitted both that commit and the runbook file. The first publish cannot be made retroactively compliant. Exact-remote ancestry is now mandatory before any remaining publish. | Preserve the breach; do not claim repair or authorize publication. |
| REL-11 | All three publish legs are rehearsed to the last safe step — through mix hex.build not hex.publish, through subtree extraction not tag push. | Complete; no rehearsal work in successor. |
| REL-12 | The lower-blast-radius held companion PR publishes live as the fire-drill for the repaired clean-room lane — satisfied by crosswake_rulestead 0.1.1; direct Hex and clean-room proof are recorded in Phase 175 Plan 07. Gate 1's separate REL-10 breach remains. | Complete; no companion action in successor. |
| REL-13 | A fresh successor core candidate publishes through one authorized ordinary version-generalized run to Hex, the iOS mirror, and Maven, each confirmed independently. The 0.2.2 preparation failed before publication; 0.2.3 and 0.2.4 remain separate PARTIAL incidents, and 0.2.4 is Hex-only with no recovery path under this requirement. | Current ref gap is only an input to fresh read-only preflight. |
| REL-14 | exact-public-proof executes and passes in that same successor ordinary run, confirmed by its run and artifact evidence rather than workflow inspection. The skipped 0.2.4 proof cannot be repaired retroactively. | Not part of preflight; no CI rerun authorized. |
| REL-15 | That successor run's linked release rollup reports COMPLETE from all six core children, and the second held companion PR publishes with a separate direct Hex confirmation and gate. | Downstream release and companion gates remain held. |
| REL-16 | A multi-registry partial-failure response table exists before the first publish, not derived during an incident. | Complete; policy context only. |
| REL-17 | Linked release, recovery, and companion publishers share one fail-closed validator over an immutable per-operation evidence envelope bound to the canonical receipt digest, exact candidate, leg, and run. It checks all six Gate 1 conditions, retains the raw registry response with a nonempty parse and matching response-table row, re-fetches mutable facts at authorization and immediately before each side effect, and binds the actual merge OID after merge. Missing, stale, mismatched, incomplete, or bypassed evidence blocks; the historical gap remains recorded and is not treated as retroactively fixed. | This read path uses similar principles but does not satisfy REL-17. |
| DOC-04 | docs/COMPANION-PUBLISH-RUNBOOK.md's "this pipeline only publishes 0.2.1" section is deleted the moment it becomes false — not softened. | Complete; no work needed. |
| DOC-06 | Residual splitsh-lite references are removed; git subtree split is documented as the durable mirror-split mechanism. | Complete; no work needed. |

Requirement source: REQUIREMENTS.md:69-82; statuses: REQUIREMENTS.md:179-189. Prose values above quote requirement definitions; typography and inline-code delimiters are omitted in table cells.
</phase_requirements>

## Summary

The D-107 signal is a fresh planning trigger for exact PR #219, not release readiness or permission to read/write remotely. It records base "e51698528dc667ef89beb951e4eb1ec91da74981", head "696a27a3be1fcd56efe70923dc0ce286a1c41c6d", source tag "ios-core-v0.2.6" at "998742856a37a97ae7247f6c532f9c154ea20885", and mirror tag "v0.2.6" with state "absent". The check-roster endpoint state is "unavailable" and the only listed CI run has conclusion "failure". [VERIFIED: evidence/175-public-candidate-signal-20261007.json:9-45; STATE.md:24-26]

Plan92 cannot continue: attempt "73fbfd33f8d969cc9f8bc303fa9cb50d" is terminally held as "TRIGGER_UNVERIFIED" with zero requests, read intent and invocations. Its gate requires a new passing candidate CI run, complete passing check roster, matching artifact and receipt; even a self-consistent local bundle stays "UNVERIFIED" because the origin is not authenticated locally. The newly recorded ref discrepancy opens planning under D-107 but cannot enter the consumed Plan92 path or satisfy its narrower CI-artifact predicate. [VERIFIED: 175-92-SUMMARY.md; plan87_mirror_tag.ex:149-169,171-207,1666-1764]

**Primary recommendation:** Plan a distinct, bounded, read-only candidate preflight with a fresh attempt and collision-safe evidence family. Treat the supplied signal as scope context, not fresh authenticated proof. Any live read requires a new exact-scope ALLOW after plan review. Reuse Plan87's fixed-origin GET/Git collector and Plan91's operation accounting only after new paths and contract are bound in fake tests. Keep tag creation as a later, separate exact decision after current source, split, mirror, PR, policy and permission facts pass. No CI dispatch, tag, merge, publish or release-state change belongs in this successor. [VERIFIED: STATE.md:24-26,103-109; 175-89-PLAN.md:64-87]

## Project Constraints (from AGENTS.md)

- Preserve fail-closed denials and flag silent degradation.
- Keep diagnostics/evidence on the existing CLI surface.
- Keep credentials, account identifiers, raw provider output and revealing adopter details out of artifacts/logs.
- Default to zero-human verification; automate evidence evaluation. Human action is limited to unavoidable external approval or irreversible trust decisions.
- Add checks to CI only when recurring/stable; record this one-time reconciliation in phase evidence.
- Use explicit quality-ratchet-release handoff; never route around held plans by generic count-based progress.
- No credential access, provider read, CI rerun, tag write, merge, registry or release action is authorized. [VERIFIED: AGENTS.md; STATE.md:24-26,103-109]

No project-local skill files were found under .codex/skills or .agents/skills. No external package is needed.

## Standard Stack

| Component | Version | Purpose | Why standard |
|---|---|---|---|
| Elixir / Mix | 1.19.5 installed | Scope/lifecycle coordinator, evidence validation, offline inspection | Existing release task/ExUnit stack; mix.exs requires ~> 1.19. [VERIFIED: mix.exs:1-17; local mix --version] |
| Node.js | v22.14.0 installed | Fixed-origin collector and fake transport | Existing .mjs code and built-in node:test; no new dependency. [VERIFIED: package.json; plan87_mirror_ref.test.mjs:1-10; local node --version] |
| Git | 2.41.0 installed | Temporary-repository split proof; future authorized source read | Existing mirror parity uses git subtree split. [VERIFIED: 175-CONTEXT.md:1377-1402; local git --version] |

No packages are added or needed; legitimacy audit is not applicable.

## Architecture and Reuse

| Component | Reuse | Do not reuse |
|---|---|---|
| Plan87 coordinator | Scope digest, exclusive synced writes, directory confinement, fake adapter seam, lifecycle and offline inspection. [VERIFIED: lib/crosswake/release_candidate/plan87_mirror_tag.ex:20,104-143,1552-1569,2117-2148] | paths/1 resolves fixed 175-plan87-tag-026 names. Exact values: @read_scope "175-plan87-tag-026-read-scope.json"; @preflight "175-plan87-tag-026-preflight.json"; @preflight_lifecycle "175-plan87-tag-026-preflight.lifecycle.jsonl"; @outcome "175-plan87-tag-026-outcome.json"; @outcome_lifecycle "175-plan87-tag-026-outcome.lifecycle.jsonl". [VERIFIED: plan87_mirror_tag.ex:6-10,82-100] |
| Plan90 contract / Node collector | Fixed API origin, closed GET allowlist, finite limits, fake fetch/Git. [VERIFIED: script/release_candidate/plan87_mirror_ref.mjs:8-32,248-267] | Contract's exact current target is "refs/tags/v0.2.6". READ explicitly rejects POST: if (authority === "READ" && !allowedRoute(method, pathname, authority) || (authority === "READ" && method !== "GET")) return fail("ROUTE_NOT_ALLOWED"); [VERIFIED: plan87_mirror_ref.mjs:13-18,248-267,345-367] |
| Plan91 journals | Reuse attempt/scope-bound parent and child journals, fsync boundaries, exact-or-UNKNOWN recomputation. [VERIFIED: 175-91-SUMMARY.md; plan87_mirror_tag.ex:1058-1107,1132-1153] | Local invocation is not provider receipt. Any changed scope/contract requires a fresh scope and authorization. |
| Plan92 path-set code/tests | Reuse attempt-derived basenames, sealed digest, exact keys, collision refusal, temporary-root fakes and held inspection. [VERIFIED: plan87_mirror_tag.ex:102-143,1605-1617,2080-2095; plan87_mirror_tag_test.exs:150-180,238-306] | Do not reuse attempt 73fbfd33f8d969cc9f8bc303fa9cb50d, its path set/scope/HOLD, or trigger decision. Exact values include schema "crosswake-plan92-path-set/v1", path pattern "175-plan92-<attempt>-path-set.json", and reason "TRIGGER_UNVERIFIED". [VERIFIED: plan87_mirror_tag.ex:110-118,1605-1617,1850-1851,2098-2115] |
| Plan88 / Plan89 | Reuse only their separation: complete fresh read preflight before separate exact write authorization. [VERIFIED: 175-89-PLAN.md:64-87] | Plan88 terminal/halted; prior ALLOW cannot transfer. Plan89 remains blocked. [VERIFIED: STATE.md:24-30,103-109] |

### Data Flow

Local supplied signal → local scope/path validation → exact-scope ALLOW → Elixir attempt reservation → fixed Node GET and bounded Git read → attempt-bound journals → offline inspector → READY/BLOCKED/UNKNOWN.

Only separately authorized reads reach GitHub/remote Git. A distinct later write decision gates any tag POST.

A local hash binds bytes; it does not authenticate origin. Plan92 explicitly calls its bundle metadata self-asserted. [VERIFIED: plan87_mirror_tag.ex:149-169]

### Collision Safety

Generate a fresh random 32-character lowercase hex attempt. Existing source: def new_attempt, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower); Plan92 validates Regex.match?(~r/\A[0-9a-f]{32}\z/, attempt_id). [VERIFIED: plan87_mirror_tag.ex:20,104-106]

Use a new distinct evidence family beneath the canonical Phase 175 evidence directory. Bind an exact path set to attempt, root, schema and current contract digest; derive each name from the path set; reserve using exclusive create, sync and readback. Stop on collision, path escape, symlink, extra key or changed digest. Never select “latest,” overwrite earlier evidence, or use Plan87 fixed paths. [VERIFIED: plan87_mirror_tag.ex:104-143,1552-1569,2080-2095,2117-2148]

Reserve parent/child journals before any possible external operation; append and sync each observed boundary. Missing or ambiguous terminal events stay UNKNOWN. [VERIFIED: 175-91-SUMMARY.md; plan87_mirror_tag.ex:1058-1153]

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---|---|---|---|
| Canonical evidence hashing / exact keys | Second JSON digest or permissive parser | Existing Plan87 evidence digest and closed validators | Maintains shared Elixir/Node binding. |
| Remote requests | Arbitrary host/URL helper or ad-hoc curl | Existing fixed-origin Node collector | Preserves route/method bounds and sanitized accounting. |
| Subtree OID | Custom splitter or guessed OID | Existing git subtree split path and temporary repo tests | OID/tree must derive from exact source history. |
| Operation tracking | Counter-only logs or request booleans | Plan91 durable journals and offline recomputation | Separates local invocation from provider receipt. |
| Attempt selection | “Newest evidence” glob/latest pointer | New attempt ID and sealed path set | Prevents stale or cross-attempt scope selection. |

**Key insight:** SHA-256 is integrity/binding, not source authentication.

## Common Pitfalls

1. **Planning trigger mistaken for readiness.** D-107 allows a verified exact-candidate ref discrepancy to reopen planning; it proves no passing readiness/policy/publication gate. Keep REL-13/14/15/17 open, readiness blocked, merge-policy unknown, release hold active. [VERIFIED: 175-CONTEXT.md:1799-1813; STATE.md:24-26]
2. **Consumed attempt resumed.** Plan92's terminal scope/hold/path set/lifecycle are immutable. Create a fresh plan/attempt; never reuse Plan88 ALLOW. [VERIFIED: STATE.md:24-30,103-109]
3. **Integrity mislabeled as origin proof.** Self-asserted URL/digest/cross-file hash is not authenticated provider provenance. Do not make local consistency yield verified external signal. [VERIFIED: plan87_mirror_tag.ex:149-169; 175-92-SUMMARY.md]
4. **Read scope reaches mutation.** Keep READ GET-only; fresh read cannot invoke tag creation, CI, merge or release. Tag write requires separate exact ref/OID approval. [VERIFIED: plan87_mirror_ref.mjs:248-267,458-463; 175-89-PLAN.md:71-87]
5. **Missing output scored as zero.** Missing journals/child terminal records cannot prove no request. Use reserved journals and exact-or-UNKNOWN accounting. [VERIFIED: 175-91-SUMMARY.md; plan87_mirror_tag.ex:1058-1153]

## Recommended Successor Sequence

1. Local-only: validate supplied signal shape, candidate tuple, declared method/status and digest; preserve its bytes. Treat it as planning input, not authenticated proof.
2. Local fake proof: test new path set, exclusive reservation, scope/authorization, fake Node transport, journals and offline inspector in temporary roots. Assert no real credential, provider, remote Git, CI or write callbacks.
3. Fresh authorization: after plan review, require ALLOW bound to attempt, path-set/scope/contract digests, candidate tuple and read bounds. No prior ALLOW transfers.
4. At most one bounded read if later separately authorized; refresh current PR/ref/policy/permission and source/split facts. Any ambiguity terminates the attempt.
5. Separate later write plan only if fresh preflight confirms target absent and all exact gates pass. Do not combine with this read.

This is planning guidance, not permission for a live read. The supplied signal states credential_used false, source status 200, mirror status 404, CI conclusion failure and check roster unavailable. [VERIFIED: evidence/175-public-candidate-signal-20261007.json:4-7,19-45]

## Code Examples

Existing exact-value excerpt: "crosswake-plan92-path-set/v1", "175-plan92-<attempt>-read-scope.json", "175-plan92-<attempt>-preflight.json", and "175-plan92-<attempt>-hold.json". [VERIFIED: plan87_mirror_tag.ex:110-118,1605-1617]

Existing attempt-generator code (verbatim): def new_attempt, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower). [VERIFIED: plan87_mirror_tag.ex:20]

    def new_attempt, do: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)

For a new attempt family, preserve the random-ID property but derive distinct filenames and scopes; do not call the fixed-path prepare flow directly.

## Validation Architecture

workflow.nyquist_validation is "true" in .planning/config.json. [VERIFIED: .planning/config.json:10-15] Do not add/run tests during research; identify existing checks only.

| Check | Command |
|---|---|
| ExUnit focused | MIX_ENV=test mix test test/crosswake/release_candidate/plan87_mirror_tag_test.exs --max-cases 1 |
| Node focused | node --test script/release_candidate/plan87_mirror_ref.test.mjs |
| Format / syntax | mix format --check-formatted <changed Elixir files>; node --check script/release_candidate/plan87_mirror_ref.mjs |

Tests should cover temporary-root path collisions, path-set/authorization substitution, callback counters remaining zero on invalid evidence, fake API/Git success and ambiguous failure, lifecycle tampering, and byte-preservation of prior attempts. The above commands/results are recorded in Plans91/92 summaries; they were not run during this research.

### Phase Requirement Test Map

| Requirement | Local proof |
|---|---|
| REL-10/11/12/16, DOC-04/06 | Inspect state/requirements; compare historical evidence bytes; no release action. |
| REL-13 | Extend focused ExUnit fake coordinator tests for the new scope family. |
| REL-14/15 | Assert no same-run proof/rollup/companion completion claims; inspect posture. |
| REL-17 | ExUnit and Node tamper, path, lifecycle, authorization, read/write separation tests. |

No Wave 0 gap for fake-only proof. Fakes cannot establish live remote state.

## Security Domain

Security enforcement defaults on. Retain no raw response bodies, tokens, local paths or actor identity. The ASVS mapping below is a local threat mapping and was not checked against external ASVS documentation in this no-provider research pass. [ASSUMED]

| ASVS category | Applies | Control |
|---|---|---|
| V2 Authentication | Yes, for a future live read | Validate authorization before credential callback; no credential inspection for local proof. |
| V3 Session Management | No | CLI does not manage end-user sessions. |
| V4 Access Control | Yes | Exact one-use scope, fixed-origin GET-only transport, separate create authorization. |
| V5 Input Validation | Yes | Closed keys, strict attempt/OID/ref forms, path confinement, candidate binding and response bounds. |
| V6 Cryptography | Yes | SHA-256 for binding only; do not claim origin proof from unkeyed digest. |

| Threat | STRIDE | Mitigation |
|---|---|---|
| Path/scope substitution | Tampering/elevation | Attempt-derived path set, strict root/digest, exclusive synced create. |
| READ to POST | Elevation | Distinct operation authority and later exact write decision. |
| Child-process ambiguity | Repudiation/tampering | Durable journals; preserve UNKNOWN where completion/receipt is unobserved. |
| Sensitive output leak | Information disclosure | Closed sanitized records; omit raw body, token, actor and environment. |

## Environment Availability

| Dependency | Available | Version | Fallback |
|---|---|---|---|
| Mix / Elixir | Yes | 1.19.5 | None |
| Node.js | Yes | v22.14.0 | None |
| Git | Yes | 2.41.0 | None for local proof |
| GitHub API / remote Git | Not contacted/probed | — | Fakes prove local behavior only |

## Sources

- AGENTS.md — project constraints.
- REQUIREMENTS.md:69-82,179-189 — requirements/status.
- STATE.md:24-30,103-109 — current handoff.
- .continue-here.md:10-32 — Plan92 stop and planning-only signal.
- evidence/175-public-candidate-signal-20261007.json:1-68 — sanitized signal.
- lib/crosswake/release_candidate/plan87_mirror_tag.ex and plan87_mirror_tag_evidence.ex — path, validation, accounting, trigger.
- lib/mix/tasks/crosswake.release.mirror_tag_026.ex — mode/path option dispatch.
- script/release_candidate/plan87_read_scope_contract.json and plan87_mirror_ref.mjs — fixed read scope, limits and transport.
- test/crosswake/release_candidate/plan87_mirror_tag_test.exs and script/release_candidate/plan87_mirror_ref.test.mjs — fake/local tests.
- 175-87/90/91/92-SUMMARY.md — implementation and prior local checks.
- No external docs/provider/credentials/remote Git/CI/registry were accessed.

## Assumptions Log

| # | Assumption | Risk |
|---|---|---|
| A1 | Read-only preflight should be a distinct successor; any tag create remains a later separately authorized decision. | Combining could let stale read evidence authorize one-way mutation; preserve Plan88/89 separation. |
| A2 | Observed local Elixir/Node/Git versions remain available at execution. | Toolchain drift may require command adjustment. |
| A3 | The V2–V6 ASVS mapping is appropriate for this release-preflight threat surface. | An authoritative ASVS review could refine the security checklist; no external security documentation was consulted. |

## Open Questions

1. **(RESOLVED — plan contract only; no read authorized.)** A later read requires a new exact `ALLOW` bound to the displayed Plan93 attempt ID, path-set digest, scope digest, fixed-contract digest, and candidate tuple. The 2026-10-07 signal is planning input only and is not cryptographic origin proof or read authority. This resolution defines the future decision format; it does not grant it.
2. **(DEFERRED — outside Plan93.)** Whether a tag create is needed remains unknown until a separately authorized fresh preflight confirms source, split, target, policy, and permission facts. Do not plan an OID from the signal alone; any later tag decision requires its own plan and authorization.

## Metadata

**Confidence:** Standard stack HIGH (source/runtime inspection); architecture HIGH (implementation inspected); pitfalls HIGH (terminal record/tests); mutable remote facts MEDIUM (supplied signal not re-fetched).
**Research date:** 2026-10-07
**Valid until:** 7 days for mutable candidate facts; local code findings until source changes.
