# SEED-009 — Sigra hosted-session interoperability release

**Priority:** next eligible `crosswake_sigra` companion release; do not publish before the
implementation and independent verification gates below pass.

## Source of truth

Before planning or changing code, read Sigra’s
`.planning/phases/239-hosted-session-interop/239-CROSSWAKE-HANDOFF.md`. This Crosswake
seed records the release dependency only; the Sigra handoff owns the detailed D-01, D-02,
and D-05 contract requirements.

## Required outcome

- Implement the companion changes and focused tests required by D-01/D-02/D-05.
- Preserve backend-owned, opaque session and subject references; return data, OAuth callback
  data, credentials, raw tokens, provider payloads, and grant flags remain non-authoritative.
- Prepare a public `crosswake_sigra` Hex release only after the required contract and
  `AuthReturn` commands pass from the exact release commit.
- Publish one immutable public Git tag and the corresponding public Hex package. Do not
  publish a tag or package as a placeholder.

## Release handoff

After publication, provide Sigra only the package version, immutable Git tag, and full commit
SHA. Sigra independently clones that SHA, checks Hex checksum/package metadata, and reruns its
required contract and `AuthReturn` commands before consuming the release.

## Boundaries

- This is a companion interoperability release, not physical-iPhone evidence and not a reason to
  weaken Phase 162’s external gate.
- Never use a synthetic organization sentinel for personal accounts.
- Keep release artifacts and documentation free of account identifiers, credentials, tokens, and
  provider payloads.
