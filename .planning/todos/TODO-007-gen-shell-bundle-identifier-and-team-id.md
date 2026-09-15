---
id: TODO-007
title: mix crosswake.gen.shell should accept --bundle-identifier and --team-id
status: open
created: 2026-09-14
severity: medium
surfaced_by: First B2C Adopter manifest report (CW-REQ-M2), verified against this repo
relates_to: TODO-003 (blocked on this), TODO-006, SEED-013
---

# `gen.shell` has no way to take provisioning facts

## Outcome

`mix crosswake.gen.shell ios --bundle-identifier <id> --team-id <TEAM_ID>` writes both into the
generated project **and** records them in `.crosswake/shell.json`, so regenerating is lossless.

## The defect (verified in this repo, 2026-09-14)

`lib/mix/tasks/crosswake.gen.shell.ex:14` reads:

```elixir
@switches [target: :string, router: :string, local: :boolean, diff: :boolean]
```

No `--bundle-identifier`, no `--team-id`. The generated `project.pbxproj` ships
`PRODUCT_BUNDLE_IDENTIFIER = dev.crosswake.shell` and `DEVELOPMENT_TEAM = ""`.

## Why it matters

Both facts have to be hand-edited into `project.pbxproj`. Meanwhile `.crosswake/shell.json` records
`apple_provisioning: {status: "deferred", bundle_identifier: null, team_id: null}` and stamps itself
"do not hand-edit — regenerate to update" — but regenerating would not populate it either. The
divergence is **unresolvable from the adopter side**. They left it stale and recorded it as a known
downstream divergence rather than silently patching a file the library declares it owns.

`shell.json`'s own `source_of_truth` field already points at the adopter's provisioning record, so
the fix may be as small as reading it from there on regenerate.

## Sequencing

**TODO-003 depends on this.** Turning on code signing for the generated test targets requires a team
id at generation time. Land M2 first, or land both together.
