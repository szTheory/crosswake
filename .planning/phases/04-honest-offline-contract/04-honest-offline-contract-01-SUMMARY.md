# Phase 4 Plan 04-01 Summary

## Outcome

Crosswake now distinguishes cached read-only degradation from the study-session
offline-island workflow in both route policy and manifest route truth.

## What Changed

- `lib/crosswake/policy/schema.ex`
  - Added additive `cache_contract` and `island_contract` route options.
- `lib/crosswake/policy/route.ex`
  - Normalized the new contract fields and added route-local validation so cache
    contracts stay on cached routes and island contracts stay on local-first
    offline-island routes.
- `lib/crosswake/manifest/types.ex`
  - Added typed `CacheContract` and `IslandContract` structs, threaded them
    through `RouteEntry`, and serialized them through `to_map/1`.
- `lib/crosswake/manifest/builder.ex`
  - Compiled normalized route contract data into explicit cached-route and
    study-session island manifest payloads.
- `test/support/router_fixtures.ex`
  - Updated fixtures so the managed router now includes one cached library route
    and one study-session offline island route.
- `test/crosswake/policy/schema_test.exs`
- `test/crosswake/policy/route_test.exs`
- `test/crosswake/manifest/manifest_test.exs`
  - Added coverage for explicit cache and island contract truth plus invalid
    route combinations.

## Verification

- `mix test test/crosswake/policy/schema_test.exs test/crosswake/policy/route_test.exs`
- `mix test test/crosswake/manifest/manifest_test.exs`
- `rg -n 'cache_contract|island_contract|cached_read_only|local_first' lib/crosswake/policy/schema.ex lib/crosswake/policy/route.ex test/support/router_fixtures.ex test/crosswake/policy/schema_test.exs test/crosswake/policy/route_test.exs lib/crosswake/manifest/types.ex lib/crosswake/manifest/builder.ex test/crosswake/manifest/manifest_test.exs`

## Notes

- The route fixtures needed one cleanup pass because nested defaults leaked the
  offline-island posture into an unrelated native-screen example. The final
  fixture keeps the study-session exemplar explicit and avoids that inheritance
  ambiguity.
