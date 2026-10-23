# Phase 175: Rehearsal and Publish - Pattern Map

**Mapped:** 2026-10-03
**Files analyzed:** 5 implementation/test files
**Analogs found:** 5 / 5

## Scope Mapped

Plan75's rulesets-only correction replaces Plan73's retired tag-protection dependency in the
existing read-only preflight path. The existing rulesets list and repository permission reads stay
within the current route allowlists. The Mix reducer, closed evidence contract, coordinator
defaults, and fixtures must agree on the revised rulesets-plus-permission policy shape. An
incomplete list, pagination, permission, or exact-tag applicability observation must remain
UNKNOWN and cannot produce `PREFLIGHT_READY`.

The research also calls for updating the existing Plan73/Plan74 planning contract where it requires
legacy protection. Treat `175-73-PLAN.md` and `175-74-PLAN.md` as planning outputs; their past
summaries and evidence remain historical and unchanged. No implementation analog is needed for
those planning edits.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` | controller / CLI adapter | request-response | same file's Plan73 preflight and `plan73_policy_snapshot!/4` | exact |
| `script/release_candidate/ios_tag_source_collector.mjs` | utility / process adapter | request-response | same file's `plan73-api` route, pagination, and response projection | exact |
| `lib/crosswake/release_candidate/ios_mirror_tag_repair.ex` | service / coordinator | transform, request-response | same file's bounded stage reducer and Plan73 policy defaults | exact |
| `lib/crosswake/release_candidate/ios_tag_source_evidence.ex` | utility / evidence validator | transform | same file's `valid_plan73_policy?/1` and Plan73 pair validator | exact |
| `test/crosswake/release_candidate/ios_mirror_tag_repair_test.exs` | test | transform, request-response | same file's Plan73 contract, offline inspector, and fake adapter fixtures | exact |

All five analog paths above are git-tracked source files. The current active `175-PATTERNS.md`
path was absent from the worktree when this map was written; the dated pre-refresh pattern archive
is historical context, not the Plan75 assignment.

## Pattern Assignments

### `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` (controller / CLI adapter, request-response)

**Analog:** This file's Plan73 preflight adapter and `plan73_policy_snapshot!/4`.

**Imports and task boundary** (lines 1-6):

```elixir
defmodule Mix.Tasks.Crosswake.Release.MirrorTag026 do
  use Mix.Task

  alias Crosswake.ReleaseCandidate.IosMirrorTagRepair, as: Repair
  alias Crosswake.ReleaseCandidate.IosTagSourceEvidence, as: Evidence
```

**Authorization and injected test seam** (lines 83-106): production preflight checks the dedicated
Plan73 read token before it builds the production adapter, while tests may supply the injected
adapter. Preserve this boundary and the exact read-authorization input when changing policy
collection.

**Stable double-snapshot pattern** (lines 371-389): collect policy twice, require equal policy,
digest, page count, and complete flags, then expose a digest only for a complete stable result.
Keep this equality check; Plan74 must only consume a newly validated `PREFLIGHT_READY` pair.

**Current policy reducer** (lines 424-485): the first API request reads rulesets, a second request
reads the retired `/tags/protection` route, and another reads repository permissions. `complete`,
the digest input, provenance, and legacy count/status fields depend on both policy sources. Remove
the retired request and its dependent facts. Keep the rulesets request, repository read-permission
fact, complete pagination, canonical sanitized digest input, and exact start/end comparison. Do not
turn the current list projection into an exact-tag applicability claim when required fields are
missing or malformed.

**Bounded API adapter pattern** (lines 708-735): `plan73_api!/5` uses the existing collector request
boundary with a remaining-deadline timeout and accepts only a bounded decoded envelope. Reuse it;
do not add another host, query surface, credential source, or provider abstraction.

### `script/release_candidate/ios_tag_source_collector.mjs` (utility / process adapter, request-response)

**Analog:** This file's `plan73-api` operation.

**Imports and closed request envelope** (lines 1-24, 51-69): use the existing Node built-ins,
explicit operation set, capped input/stdout, exact request-key check, and generic failure envelope.
Do not return provider bodies or exception text to the caller.

**Route authorization** (lines 84-103):

```javascript
const PLAN73_ROUTES = [
  /^\/repos\/szTheory\/crosswake-shell-core-ios\/rulesets(?:\?per_page=100&page=[1-9][0-9]*)?$/,
  /^\/repos\/szTheory\/crosswake-shell-core-ios\/tags\/protection(?:\?per_page=100&page=[1-9][0-9]*)?$/,
  /^\/repos\/szTheory\/crosswake-shell-core-ios$/,
];

function validPlan73ApiRequest(request) {
  const token = request.env?.CROSSWAKE_PLAN73_READ_TOKEN;
  return request.command === "github-api" && request.args.length === 1 &&
    typeof token === "string" && token.trim().length > 0 &&
    PLAN73_ROUTES.some((route) => route.test(request.args[0])) &&
    request.timeout_ms <= 30_000 && request.stdout_mode === "retain";
}
```

Remove the retired route from this allowlist and from the parallel Elixir allowlist. Keep the
existing rulesets and repository routes and all current method, host, token, timeout, response-size,
and pagination limits. A removed route must be rejected before `fetch`.

**Pagination and response projection** (lines 151-214, 238-249, 287-314): requests are limited to
forward pages, bounded response bytes, and an allowlisted projection. Keep the rulesets projection's
bounded `id`, `name`, `target`, `enforcement`, `conditions`, and `rules` values, but validate the
required policy/applicability shape before marking policy complete. Remove the `/tags/protection`
projection branch. If the approved list response cannot establish whether the observed rulesets
apply to `refs/tags/v0.2.6`, return an incomplete/UNKNOWN result. Do not add a detail endpoint
without a separate scope decision.

### `lib/crosswake/release_candidate/ios_mirror_tag_repair.ex` (service / coordinator, transform and request-response)

**Analog:** This file's bounded Plan73 preflight coordinator.

**Stage result sanitization** (lines 432-514): stage callbacks are invoked once, exceptions and
throws collapse to an empty bounded result, and `safe_preflight_stage/2` projects only the known
fields. Keep the `:tag_policy` projection to `policy_complete`, `policy_sha256`, `policy`, and
`policy_end`; invalid completeness values become `UNKNOWN` and invalid digests become `nil`.

**Policy defaults and route allowlist** (lines 397-429, 876-896): the initial `policy` and
`policy_end` maps are closed incomplete defaults, with ruleset completeness and pagination false,
permission false, and digest unavailable. Remove the three `legacy_protection_*` fields from both
maps and remove the retired route regex from the fixed route list. Preserve the closed rulesets and
permission facts and default every unobserved condition to non-ready.

### `lib/crosswake/release_candidate/ios_tag_source_evidence.ex` (utility / evidence validator, transform)

**Analog:** This file's Plan73 artifact/policy validation.

**Closed policy schema** (`valid_plan73_policy?/1`, lines 3941-3960):

```elixir
defp valid_plan73_policy?(policy) when is_map(policy) do
  exact_string_keys?(
    policy,
    ~w(complete rulesets_complete ruleset_pages ruleset_count pagination_complete cursor_progress legacy_protection_observed legacy_protection_status legacy_protection_count repository_read_permission provenance sha256)
  ) and
    policy["complete"] == true and policy["rulesets_complete"] == true and
    is_integer(policy["ruleset_pages"]) and policy["ruleset_pages"] in 1..20 and
    is_integer(policy["ruleset_count"]) and policy["ruleset_count"] in 0..100 and
    policy["pagination_complete"] == true and
    policy["cursor_progress"] == true and
    policy["legacy_protection_observed"] == true and
    policy["legacy_protection_status"] in ["ENABLED", "DISABLED", "ABSENT"] and
    is_integer(policy["legacy_protection_count"]) and
    policy["legacy_protection_count"] in 0..20 and
    policy["repository_read_permission"] == true and
    policy["provenance"] == ["rulesets", "legacy_protection", "effective_permissions"] and
    digest?(policy["sha256"])
end
```

Delete only the retired fields and their legacy-specific validation. Keep exact-key rejection,
bounded integer ranges, required pagination/cursor completion, effective read permission, and digest
validation. Change provenance to exactly `["rulesets", "effective_permissions"]`.

**Pair and digest binding** (`validate_plan73_preflight!/1`, lines 3655-3727): validate both policy
snapshots through the revised closed validator, require `policy == policy_end`, and bind
`policy_sha256` to `policy["sha256"]`. A retired key, unknown key, stale digest, unequal snapshot,
or incomplete applicability evidence must prevent `PREFLIGHT_READY`. Preserve the current
`crosswake-plan73-mirror-tag-026-preflight/v1` schema because no preflight pair was issued.

### `test/crosswake/release_candidate/ios_mirror_tag_repair_test.exs` (test, transform and request-response)

**Analog:** This file's Plan73 fixture, fake preflight callbacks, pair validator, and offline inspector
tests.

**Positive and drift cases** (lines 666-710): keep the complete-snapshot acceptance test and the
per-field source/split/mirror/PR/policy mutation cases. The fixture deliberately records required
CI as `FAILURE` while candidate readiness remains `BLOCKED`; preserve that distinction.

**Injected stage pattern** (lines 809-831): the fake adapter supplies each stage as a callback and
returns only the corresponding facts. Keep policy tests isolated behind the `tag_policy` callback so
they do not make GitHub calls.

**Current policy fixture** (lines 900-929): both `policy` and `policy_end` include the three retired
legacy fields and the old provenance value. Remove those keys from both fixtures, update provenance,
and recompute the policy digest basis consistently.

Add deterministic cases for one and multiple rulesets pages; empty rulesets with complete pagination;
parent-provided and tag-target rules as represented by the approved list response; absent or
malformed applicability fields; repeated/nonadvancing pagination; false repository read permission;
start/end ruleset or permission drift; unknown retired keys and stale digests; retired-route
rejection before network; and Plan74 `--require-ready` rejection for every non-ready or invalid pair.
Keep these tests fake-only and preserve the historical failed-CI/readiness split.

## Shared Patterns

### Bounded read authority

**Sources:** `lib/mix/tasks/crosswake.release.mirror_tag_026.ex:83-106`,
`script/release_candidate/ios_tag_source_collector.mjs:84-103`,
`lib/crosswake/release_candidate/ios_mirror_tag_repair.ex:876-896`
**Apply to:** Plan73 policy collection.

Keep the dedicated Plan73 read authorization, exact existing API routes, bounded GET request,
timeouts, response caps, and forward-only pagination. Remove both legacy route entries and its
projection. Do not consult stored `gh` login, `GH_TOKEN`, or `GITHUB_TOKEN`; do not perform a live
request as part of local validation.

### Complete and stable policy evidence

**Sources:** `lib/mix/tasks/crosswake.release.mirror_tag_026.ex:371-389,424-485`,
`lib/crosswake/release_candidate/ios_tag_source_evidence.ex:3655-3727,3941-3960`
**Apply to:** Mix reducer, coordinator defaults, validator, and tests.

Hash only the canonical sanitized rulesets observation and effective read permission. Require full
pagination, valid fields that establish exact-tag applicability, true repository read permission,
equal start/end snapshots, and matching policy digests. Missing or malformed facts remain UNKNOWN;
they do not become empty/false observations or `PREFLIGHT_READY`.

### Closed projection and local test seams

**Sources:** `lib/crosswake/release_candidate/ios_mirror_tag_repair.ex:432-514`,
`test/crosswake/release_candidate/ios_mirror_tag_repair_test.exs:666-710,809-929`
**Apply to:** policy evidence and Plan74 readiness validation.

Use injected stage callbacks and synthetic ruleset pages. Keep raw provider responses, exception
text, and credentials out of receipts and CLI output. The Plan74 inspector must consume only a
freshly validated Plan73 artifact/lifecycle pair; the prior safe-blocked Plan74 outcome remains
historical and unchanged.

## No Analog Found

None for the five implementation/test files. The approved list response's exact-tag applicability
semantics are not demonstrated by the local code; the planner should retain UNKNOWN if the bounded
fields are insufficient and request a scope decision before adding another endpoint.

## Metadata

**Analog search scope:** Plan73 Mix task, Node source collector, Plan73 repair coordinator, shared
Plan73 evidence validator, and focused ExUnit suite.
**Tracked source files verified:** 5 / 5.
**Pattern extraction date:** 2026-10-03.
**Remote calls/tests:** none performed.
