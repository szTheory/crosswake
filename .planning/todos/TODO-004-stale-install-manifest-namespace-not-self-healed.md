---
id: TODO-004
title: Stale install_manifest.json namespace is neither migrated nor re-derived on upgrade
status: open
created: 2026-09-14
severity: low
surfaced_by: First B2C Adopter device-proof report (CW-REQ-M6)
relates_to: SEED-013, 0.2.1 namespace-derivation fix
---

# Stale `install_manifest.json` namespace is not migrated or self-healed

## Outcome

An adopter upgrading across the namespace-derivation fix either gets a migrated manifest, a
re-derived namespace at read time, or a `doctor` finding that names the real cause.

## The defect

0.2.1 fixed namespace derivation — `mix crosswake.install` now derives the web namespace from the
router's actual `defmodule` instead of reconstructing it from the OTP app name, preserving
mixed-case names. Good fix.

But a manifest written by the **older** version still carries the wrong namespace, and nothing
migrates it or re-derives it. The adopter got:

```
Error loading module 'Elixir.<Adopterweb>.Crosswake.Policy':
  module name in object code is 'Elixir.<AdopterWeb>.Crosswake.Policy'
```

The message points at `lib/`. The stale value is in `priv/crosswake/install_manifest.json`.

Re-running `mix crosswake.install` is **not** an available fix: it rewrites the host-owned router
and policy module. The adopter hand-patched the manifest.

## Ask (pick one, cheapest first)

1. Have `mix crosswake.doctor` detect the mismatch and say so in those terms — *"install manifest
   names X, compiled module is Y — re-run `mix crosswake.install`"*.
2. Re-derive the namespace at read time rather than trusting the stored value.
3. Migrate the manifest on upgrade.

Option 1 alone converts a debugging session into a one-line diagnosis and is the smallest change.

## Code touchpoints

- `lib/crosswake/install/manifest.ex`
- `lib/crosswake/doctor/doctor.ex`
- `lib/mix/tasks/crosswake.install.ex`
- `lib/mix/tasks/crosswake.doctor.ex`
