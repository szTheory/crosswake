# Phase 172 — External API Coverage

No external API integration: in-repo manifest schema loosening and release-artifact verification logic over Elixir modules, shell scripts and a python observation-assembly step.

## Why there is no coverage matrix here

Phase 172 changes the shape of a manifest the repository produces and consumes itself, and changes
how an already-existing comparison is graded. It introduces no new external service, no new SDK, no
new HTTP client, and no new authentication surface.

The only outbound network call anywhere near this phase is the pre-existing `mix hex.package fetch`
in `script/verify_companion_cleanroom.sh`'s exact-public re-fetch loop. This phase does not add it,
does not change its arguments, does not change the endpoint it reaches, and does not change how its
failure is handled — the loop's package and version arguments come from the same per-package
approved-manifest lookup they came from before. Only a second field (`candidate_ref`) is read from
that same already-open local file, alongside the version the loop already reads.

The one genuinely new command this phase adds is `git rev-parse HEAD` against the local repository
(`MATRIX_PUBLIC_REF`, decision D-172-B). That is a local process invocation of a tool already
load-bearing throughout this pipeline, not an API integration.

`mix`, `elixir`, `jq`, `git`, `python3` and `bash` are all pre-existing load-bearing dependencies of
the unmodified pipeline. This phase adds none of them and adds no package-manager install step.

Fabricating a capability matrix for an API this phase does not add would be an assertion with
nothing inside it — the defect class milestone v23.0 exists to remove. This declaration is the
positive statement that the matrix is absent by fact, not by omission.
