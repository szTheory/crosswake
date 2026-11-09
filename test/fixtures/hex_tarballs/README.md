# Real Hex tarball fixtures

Three real Hex tarballs used by `test/crosswake/release_candidate/artifact_real_tarball_test.exs`.
`SHA256SUMS` records the hash of each file when it was produced. It is provenance, not a value the
test pins: the test asserts relations and shape only and reads every version from the fixtures.

## Provenance

Produced on 2026-11-09 (Phase 201, plan 01). Each download went into its own empty scratch
directory first and nothing was executed there.

Public tarballs, fetched from the Hex registry mirror:

```bash
curl -sSf -o crosswake_rulestead-0.1.1.public.tar https://repo.hex.pm/tarballs/crosswake_rulestead-0.1.1.tar
curl -sSf -o crosswake-0.2.13.public.tar          https://repo.hex.pm/tarballs/crosswake-0.2.13.tar
```

Hex 2.6+ rebuild of the rulestead tag, with isolated Mix and Hex homes so the global Hex is
untouched. The recorded Hex version for this rebuild is **2.7.0** (`mix hex.info` printed
`Hex: 2.7.0`, `Elixir: 1.19.5`, `OTP: 27.3`). The tag `crosswake_rulestead-v0.1.1` resolves to
commit `096371e3008d19da775c0d561d092fb3d349b26e`.

```bash
S=$(mktemp -d); export MIX_HOME=$S/mix HEX_HOME=$S/hex
mix local.hex --force && mix hex.info | head -1
git archive crosswake_rulestead-v0.1.1 packages/crosswake_rulestead | tar -x -C "$S"
( cd "$S/packages/crosswake_rulestead" && \
  ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.19.5-otp-27 CROSSWAKE_RELEASE=1 HEX_OFFLINE=1 \
  mix hex.build --output crosswake_rulestead-0.1.1.rebuild.tar )
```

Fixture names carry no Hex version on purpose. If a later regeneration installs a newer Hex, update
the version recorded in this section; the test reads the version from the fixture's own metadata.

## Why these fixtures

- The public `crosswake_rulestead` 0.1.1 tarball was built before Hex 2.6.0 and has no `build_env`
  metadata key.
- The rebuild of the same tag under Hex 2.6 or later carries `build_env` `[{"hex", V}]`. Together the
  two reproduce, on real data, the five companion `digest_mismatch` findings of release run
  42639651064: same package, same tag, same payload, different recorded builder.
- The public `crosswake` 0.2.13 core tarball was published by Hex 2.7.0 and carries Hex 2.7.0's
  `build_env`. It is the real-data control that the core's `build_env` still counts toward its
  digest (user decision 2026-11-09, companions only).
- AGENTS.md: "Test adapters against the dependency's real output, not invented fixtures."
  The synthetic fixtures in `artifact_test.exs` never carried a Hex-written `build_env`, which is why
  the defect was not caught before release.

All three are this repository's own public Apache-2.0 packages. No adopter data is involved.
