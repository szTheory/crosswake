# Phase 171 — External API Coverage

No external API integration: CI/release-pipeline plumbing over in-repo workflow YAML, Elixir modules and shell scripts.

## Why there is no coverage matrix here

Phase 171 changes how an already-declared version is derived and compared inside the repository's own
release graph. It introduces no new external service, no new SDK, no new HTTP client, and no new
authentication surface.

The only outbound network calls this phase touches are pre-existing registry probes already in the
tree — the Hex, Maven and iOS-mirror negative controls in `.github/workflows/ios-mirror-backfill.yml`'s
`attest-candidate-receipt` job, and the read-only registry probes in `lib/crosswake/release_status.ex`.
Both are parameterized by this phase, not introduced by it: the request shapes, the endpoints and the
expected status codes are unchanged. Only the version segment interpolated into each URL moves from a
hardcoded literal to a supplied or declared value.

`elixir`, `mix`, `jq`, `git`, `gh` and `curl` are all pre-existing load-bearing dependencies of the
unmodified pipeline. This phase adds none of them and adds no package-manager install step.
