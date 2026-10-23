# Plan85 Intent: Plan84 Local Process-Boundary Twin

## Goal

Use a local digital twin to determine why Plan84's actual Elixir-to-Node collector path
collapsed to `UNKNOWN/OBSERVATION_UNAVAILABLE`. This is a local diagnostic and shift-left
verification task. It does not retry Plan84 or create release evidence.

## Planning shape

Keep this as one integrated plan in one wave unless dependency analysis shows a real blocker. The
subprocess, fixture server, error classification, and no-side-effect assertions form one contract.

## Required coverage

- Exercise the real Mix/Elixir coordinator, spawn the real Node collector as a child process,
  and send its HTTP requests only to a loopback fixture server. Keep production requests pinned
  to the fixed GitHub API host; expose no general-purpose host, route, or credential override.
- Cover successful envelopes and distinguishable safe failure classes at the process boundary:
  child launch failure, timeout, nonzero exit, malformed/incomplete child envelope, and HTTP
  transport/response failures. Reuse existing fixed-route, redirect, body-cap, pagination,
  and schema checks where they apply.
- Use deterministic fixtures and temporary Git repositories/remotes where needed. Assert the
  observed local request count and verify the path stops before any dry-run, decision, tag, or CI
  operation.
- Persist only bounded, sanitized failure categories. Do not retain raw response bodies, auth
  data, credentials, raw child output/stderr, or sensitive filesystem paths.
- Run the durable suite in the existing CI lane if it gives recurring protection without adding
  a redundant workflow.

## Boundaries

- No GitHub access, adopter access, credential lookup/rotation, live preflight, tag push, CI
  dispatch, merge, registry mutation, or publication.
- Do not infer that the historical Plan84 request count was zero. Its occurrence/count remains
  `UNKNOWN`, and that one-use attempt remains terminal.
- A passing twin proves the local integration and failure-classification contract only. It does
  not prove current GitHub PR/tag/ruleset state, live permissions, or acceptance of an authenticated
  dry-run; the release hold and Plans45–48 remain unchanged.
- No human UAT. Evaluate all assertions and artifacts automatically.

## Completion evidence

An automated test traverses the actual Elixir-to-Node subprocess path against the loopback twin,
distinguishes the injected failure modes without leaking unsafe details, and verifies there are no
release side effects. The Plan85 summary must restate that this local result does not resolve the
live release gate.
