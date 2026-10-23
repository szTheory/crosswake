# Phase 175: Rehearsal and Publish - Pattern Map

**Mapped:** 2026-09-24
**Scope:** Corrective planning after the ordinary `0.2.4` partial release.
**Files classified:** 9 groups. **Analogs found:** 9 / 9.

The 2026-09-18 map is preserved as `175-PATTERNS-ARCHIVE-2026-09-18.md`. This map covers D-39–D-42. Every source analog below was verified as git-tracked with `git ls-files`.

## File Classification

| New/modified file or artifact | Role | Data flow | Closest tracked analog | Match |
|---|---|---|---|---|
| `.github/workflows/release-please.yml` iOS job | config | event-driven | same file's rollup runtime setup; `.github/workflows/ios-mirror-backfill.yml` | exact |
| `script/release_candidate/android_publication.sh` | utility/service | request-response, external publish | same script's modes; release guard outputs | exact |
| `script/check_release_workflow_integrity.exs` | utility | batch validation | same file's release and recovery checks | exact |
| `test/crosswake/proof/phase175_release_recovery_test.exs` | test | transform | same file's fixture mutation tests | exact |
| `.github/workflows/hex-publish.yml` | config | event-driven, artifact | existing candidate rehearsal | exact |
| `.github/workflows/ios-mirror-backfill.yml` | config | event-driven, artifact | existing candidate rehearsal and attestation | exact |
| `.github/workflows/maven-publish-fire-drill.yml` | config | event-driven, disposable external write | existing isolated drill | exact |
| replacement `175-21-PLAN.md` and successor evidence | plan/evidence | request-response, batch | current plan; historical `175-fresh-core-release-run-0.2.4.json` | role-match |
| active requirements, roadmap, state | planning config | batch | respective active workstream files | exact |

## Pattern Assignments

### Ordinary iOS Mix/runtime: `.github/workflows/release-please.yml`

**Analog:** `.github/workflows/ios-mirror-backfill.yml:135-143` provisions the rehearsal after exact checkout:

```yaml
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
  with:
    ref: ${{ inputs.candidate_head }}
    fetch-depth: 0
    persist-credentials: false
- uses: ./.github/actions/setup-elixir-cache
  with:
    mix-env: test
```

The composite installs the pinned Beam runtime from `.tool-versions` (`.github/actions/setup-elixir-cache/action.yml:60-71`). The ordinary rollup has a smaller direct pattern: pinned `erlef/setup-beam`, `version-file: .tool-versions`, `version-type: strict`, then `mix deps.get --check-locked` (`release-please.yml:824-837`). Supply equivalent preparation inside `publish-ios-core` after its exact tag checkout and before `ios_mirror.sh publish` (`:565-600`). Preserve SSH and atomic mirror arguments. Require a job-scoped scanner assertion and missing-setup mutation; the candidate rehearsal does not prove the ordinary job environment.

### Maven ordinary identity: `script/release_candidate/android_publication.sh`

**Analog:** `release-please.yml:35-45,95-120,623-637` sends `approved_head`, `approved_tree`, `merge_oid`, `candidate_receipt`, and `approved_version` from the exact canonical receipt guard to the ordinary Maven job.

**Existing mode and validation shape** (`android_publication.sh:24-66`):

```bash
--execute) [ "$MODE" = "observe" ] || usage; MODE="publish"; shift ;;
--recover) [ "$MODE" = "observe" ] || usage; MODE="recovery"; shift ;;
[ "$(git -C "$RELEASE_ROOT" rev-parse HEAD)" = "$SOURCE_REF" ]
parent_line=$(git -C "$RELEASE_ROOT" rev-list --parents -n 1 "$SOURCE_REF")
[ "$(printf '%s\n' "$parent_line" | awk '{print NF}')" -eq 3 ]
[ "$(printf '%s\n' "$parent_line" | awk '{print $3}')" = "$APPROVED_HEAD" ]
[ "$(git -C "$RELEASE_ROOT" rev-parse "${SOURCE_REF}^{tree}")" = "$APPROVED_TREE" ]
```

Lines 48-51 currently compare every invocation to fixed `PHASE168_*` identity. Confine that equality to recovery while preserving its pin. Ordinary `--execute` must still require exact checkout, two-parent merge, second-parent head, equal merge/head tree, Gradle version, and receipt bound to the approved guard. A 64-hex shape check alone cannot bind the receipt. Specify an independent binding and negative cases. Reuse the non-publishing `observe` exit (`:63-66`) for identity checks; preserve the recovery public-POM preflight (`:68-84`).

### Structural guard and mutation proof

**Analogs:** `script/check_release_workflow_integrity.exs:1510-1583` checks ordinary job dependencies and checkout; `:1586-1623` checks partial-release truth; `:1642-1688` protects Phase 168 recovery pins. Add job-local iOS runtime ordering and ordinary Maven guard-output binding checks without weakening recovery.

**Test pattern** (`test/crosswake/proof/phase175_release_recovery_test.exs:141-194`):

```elixir
release = File.read!(@release_workflow)
assert_failure!(
  @receipt_authority,
  release_workflow:
    Fixtures.replace_in_job(release, "approved-release-guard", needle, replacement)
)
```

`Fixtures.replace_in_job` and `Fixtures.replace_once!` fail if the mutation target is absent (`:1-7`). Extend with missing iOS setup, wrong Maven merge/head/tree/receipt/version/source, and removed recovery-pin seeds. Include an accepted current-candidate observe case so this is more than rejection-only proof.

### Safe rehearsals and canonical successor receipt

**Hex:** `.github/workflows/hex-publish.yml:97-115` accepts exact candidate head/tree/base/receipt/run ID. Require the fresh successor artifact with `package_count=6` and `external_state_changed=false`.

**iOS:** `.github/workflows/ios-mirror-backfill.yml:110-184` validates candidate identity, installs Mix, runs `ios_mirror.sh candidate`, asserts `state=PASS`, `authorization_result=PROVEN`, and `external_state_changed=false`, then emits `candidate-rehearsal-ios` with workflow and observation digests. Use its existing attestation path to establish the canonical exact-head receipt before merge. Bind remote base/head/tree and workflow identity.

**Maven:** `.github/workflows/maven-publish-fire-drill.yml:1-56,86-135` is isolated `workflow_dispatch` with `contents: read`, exact candidate checks, a run-unique disposable coordinate, signed artifacts, and VALIDATED→DROP. Record the candidate PR head before and after; require equality. The existing Phase 175 tests (`test/crosswake/proof/phase175_release_recovery_test.exs:21-80`) seed failures for Release Please and PR mutation coupling.

### Successor ordinary-run proof and planning artifacts

`release-please.yml:753-805` makes `exact-public-proof` depend on ordinary Hex, iOS, Maven, and both clean-room jobs, passing `lane: ordinary` and approved identity (`:786-793`). `linked-release-rollup` reads all six same-run child results (`:795-857`). `lib/crosswake/release_candidate/workflow.ex:4-47` returns `COMPLETE` only for six successes and `PARTIAL` when a public coordinate survives a failed or skipped child.

The replacement plan must demand one successor run ID proving three core publications, successful exact-public proof, and six-child `COMPLETE`, then independent registry responses. Keep `0.2.4` permanently `PARTIAL` with Hex only; its skipped proof and consumed Gate 2 cannot be repaired or reused. The later companion publish is a separate gate and fact. Update active requirements, roadmap, state, and replacement plan language together while preserving historic incidents.

## Shared Patterns

- **Exact candidate authority:** `release-please.yml:84-120` requires a two-parent merge, matching head/tree, one unexpired canonical receipt, matching base/head/tree, zero external mutation, and SHA-256 digest. Missing receipt blocks publication.
- **Fail-closed preflight:** `android_publication.sh:45-66` validates before Gradle; `ios-mirror-backfill.yml:125-169` validates before mirror evaluation.
- **Fresh gate evidence:** successor-specific run IDs, remote OIDs, runbook ancestry, receipt provenance, false mutation flags, and independent target absence precede a new Gate 2. D-41 consumes the `0.2.4` approval.
- **Historical truth:** No recovery job or later run may alter the recorded `0.2.4` `PARTIAL` result.

## No Analog Found

There is no existing independently bound ordinary Maven receipt check once the Phase 168 equality is moved to recovery. The planner must design that trust boundary and require both a current-candidate positive observe case and wrong-digest rejection. The approved guard's validated digest (`release-please.yml:95-120`) is the authority; syntactic validity is insufficient.

## Metadata

**Analog search scope:** tracked release workflows, composite action, release-candidate scripts, integrity scanner, Phase 175 proof tests, linked-rollup module, current context and research.
**Pattern extraction date:** 2026-09-24.
**Planning boundary:** No CI dispatch, registry write, merge, publication, or reuse of a consumed gate.

## REL-17 Pattern Addendum (2026-09-26)

The earlier map describes the pre-REL-17 evidence path. Preserve those analogs and use these
additions for the shared candidate-bound gate:

### Evidence domain and I/O boundary

- `lib/crosswake/release_candidate/evidence_input.ex` is the nearest input-normalization seam for
  candidate receipts. Keep parsing/normalization explicit and preserve source identity; do not let
  callers supply a self-certified `valid: true` flag.
- Implement the six-condition decision as a pure Elixir function over an explicit operation and
  evidence value. Keep `gh api`, Hex/registry fetches, artifact reads, and YAML/workflow wiring in
  adapters. This gives ExUnit a deterministic input for both the full positive case and one mutation
  per required field.
- `Mix.Task` and the existing release-status task are the operator precedent. There is no active
  Phoenix/Plug surface or durable database requirement; adding Ecto would duplicate retained
  workflow artifacts and turn an evidence contract into a new state service.

### Guard wiring and exact-object precedent

- `script/check_release_runbook_ancestry.sh` plus
  `test/crosswake/proof/phase175_runbook_ancestry_test.exs` demonstrate exact Git-object validation
  and seeded ancestry mutations. Reuse this for condition 6, extending its invocation only where the
  current base/head/merge identities require it.
- `script/check_release_workflow_integrity.exs` is the recurring structural-check pattern. Extend it
  to require the shared evidence gate at linked, recovery, and companion publication entry points;
  a validator test without call-site wiring is not a release control.
- `test/crosswake/proof/phase175_release_recovery_test.exs` and
  `test/crosswake/release_candidate/workflow_test.exs` are the closest fixture/mutation patterns.
  Include removal/bypass mutations per publisher and mutations for empty registry bodies, wrong
  response-table/run binding, changed policy, stale OIDs, and admin bypass.
- Retain the established error vocabulary: missing/uncertain evidence is BLOCKED; an already
  published partial transaction stays PARTIAL; COMPLETE is reserved for all six same-run children.

### Evidence stages

1. **Before merge:** live base/head, merge readiness, CI and required-check policy, exact candidate
   receipt digest, leg run ID, raw registry response plus nonempty parse, matching response-table
   row, and runbook ancestry on the fetched base/head.
2. **After merge, before publisher:** bind the actual merge OID, verify normal protected-path/no
   admin-bypass evidence and runbook ancestry on base/head/merge, re-fetch mutable policy/status, and
   require the same immutable candidate/operation evidence envelope.

Do not project a pre-merge snapshot across the merge boundary. Existing GitHub workflows expose
separate authorization and side-effect points; preserve them and add the shared gate at every
publisher rather than introducing a dashboard or generic retry path.

**Pattern extraction date:** 2026-09-26 (REL-17 supplement; original 2026-09-24 map preserved).
