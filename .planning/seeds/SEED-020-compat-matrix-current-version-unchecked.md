---
id: SEED-020
title: The compatibility matrix's Current Version cell is outside the drift test's scope, and it drifted
status: dormant
severity: medium
trigger_when: >-
  Surface when hardening proof quality, when publishing any companion package, or
  when adding a check whose scope covers only part of the artifact it polices.
  NOT blocking.
created: 2026-09-17
related: [SEED-018, SEED-019]
---

# SEED-020: a published package is documented as unpublished, through a green merge-blocking gate

## The finding

`guides/companion_compatibility.md` lists `crosswake_rindle` with a `Current Version` of
`unpublished`, and states in prose:

> A cell reading `unpublished` means the package is extracted and wired into the release
> graph in this repository but has never been published to hex.pm — it cannot be added to
> a project yet, and it has no hexdocs page. `crosswake_rindle` is in that state today.

That is false. Measured against the live registry on 2026-09-17:

```
GET https://hex.pm/api/packages/crosswake_rindle              -> 200
GET https://hex.pm/api/packages/crosswake_rindle/releases/0.1.0 -> 200
```

`crosswake_rindle 0.1.0` is published, carries a description, an Apache-2.0 license, and a
hexdocs link in its own Hex metadata.

## Why nothing caught it

The matrix IS guarded by a merge-blocking test —
`test/crosswake/proof/phase132_compat_matrix_drift_test.exs` — and that test is green. It is
green because of what it compares. Its contract comment in the guide is explicit:

```
<!-- compat-03 contract: col1=Hex Package, requirement cell = "Requires `crosswake`";
     do not reorder columns without updating phase132_compat_matrix_drift_test.exs -->
```

The test diffs the **`Requires crosswake`** cell against each package's `mix.exs`. The
**`Current Version`** cell is guarded by nothing but a hand-edit warning:

```
<!-- Current Version: do not hand-edit; keep this aligned with package mix.exs / release manifest.
     Use mix crosswake.release.status --live for public registry presence. -->
```

A comment instructing a human not to hand-edit is not a check. The one column that makes a
public claim about registry state is the one column the drift test does not read.

## Why this is the milestone's own defect class, one column over

SEED-018: an assertion examined an empty collection and passed.
SEED-019: a scope *selector* silently emptied, so the assertion never ran.
SEED-020: the assertion runs, against a real non-empty subject, and passes — but the subject
is column 4, and the false claim is in column 3.

All three are the same failure viewed from different distances: a green check whose green
says nothing about the thing that was wrong. This is the first of the three where the
uncovered fact is **public-facing** — an adopter reading the matrix would plan around
`crosswake_rindle` being unavailable to them when it is available.

## How it surfaced

Not by any check in this repository. A downstream host session asked which crosswake and
companion versions were current; answering that question against the live registry rather
than from the guide is what exposed the divergence.

## The remediation shape

The `Current Version` column asserts registry state, so it must be checked against registry
state — not against `mix.exs`, which is what the package intends to publish, not what is
published. Two candidate shapes:

1. Extend `phase132_compat_matrix_drift_test.exs` to read the `Current Version` cell and
   compare it against `mix crosswake.release.status --live`, tagged so the hermetic lane
   skips the network leg and a scheduled lane enforces it.
2. Keep the merge-blocking test hermetic and give the live comparison its own scheduled
   workflow, failing loudly rather than reporting a skip (cf. XPUB-05/XPUB-07: a missing
   signal must never be expressed as a skipped job).

Option 2 is the better fit for this repo — the drift test's value is that it is fast and
merge-blocking, and a network dependency in that lane would erode it.

Whichever is chosen it needs the usual non-vacuity proof: mutate a `Current Version` cell to
a wrong value and observe the check go red. A check over this column that has never been
seen failing would be the fourth instance of the same class, not a fix for the third.

## Measured scope of the gap (2026-09-17)

Every `Current Version` cell in the matrix, against the live registry:

```
crosswake_rulestead   guide 0.1.0        registry 0.1.0        agree
crosswake_rindle      guide unpublished  registry 0.1.0        DIVERGED
crosswake_sigra       guide 0.1.3        registry 0.1.3        agree
crosswake_chimeway    guide 0.1.0        registry 0.1.0        agree
crosswake_threadline  guide 0.1.0        registry 0.1.0        agree
```

One confirmed instance out of five cells. Core itself (`crosswake 0.2.1`) is documented
outside this matrix and is correct.
