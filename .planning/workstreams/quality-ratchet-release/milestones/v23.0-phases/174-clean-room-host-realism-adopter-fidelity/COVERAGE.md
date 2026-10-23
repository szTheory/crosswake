# Phase 174 — External API Coverage

No external API integration: in-repo shell-harness host generation, a Mix task's exit-code
classification, and a closed in-repo proof-lane assertion vocabulary.

## Why there is no coverage matrix here

The `api-coverage.cjs` detector was run over this phase's ROADMAP section and returned
`{"detected": false, "signals": []}`. That result is recorded here rather than left implicit, and
the reasoned declaration below is the positive statement that the matrix is absent by fact, not by
omission.

Phase 174 changes three things: how `script/verify_companion_cleanroom.sh`'s legacy positional code
path generates its throwaway host (a route with capability metadata, an `mix crosswake.install`
invocation, and `step=` log markers), how
`Mix.Tasks.Crosswake.ProofLane.PhysicalIphone` maps a failure rule onto a process exit code, and
whether `Crosswake.ProofLane.PhysicalIphoneContract` carries a haptics assertion. It introduces no
new external service, no new SDK, no new HTTP client, and no new authentication surface.

The outbound network calls in scope — `mix hex.package fetch`, `mix deps.get`, and the Hex release
metadata read at the top of `verify_companion_cleanroom.sh` — are all pre-existing. This phase does
not add them, does not change their arguments, does not change the endpoint they reach, and does not
change how their failure is handled. The `crosswake_rindle 0.1.0` release this phase proves against
is read through that same unmodified path.

One new workflow (`clean-room-proof-rehearsal.yml`) is added, but it reaches nothing the existing
`clean-room-proof-*` lanes do not already reach: it runs the identical
`bash script/verify_companion_cleanroom.sh` invocation on the same runner image, under the same
`contents: read` grant, so an operator can execute the lane without waiting for a release-please
publish to create one.

`mix`, `elixir`, `git`, `jq`, `python3`, `bash`, and `gh` are pre-existing load-bearing dependencies
of the unmodified pipeline. This phase adds none of them and adds no package-manager install step.

Fabricating a capability matrix for an API this phase does not add would be an assertion with
nothing inside it — the defect class milestone v23.0 exists to remove.
