---
id: TODO-006
title: Generated shell ships a .invalid origin into the installed .app — every cold start is user-visibly broken
status: open
created: 2026-09-14
severity: high
surfaced_by: First B2C Adopter manifest report (CW-REQ-M1), verified against this repo
relates_to: TODO-007, SEED-013, SEED-014
---

# Generated shell bundles an unreachable `.invalid` origin

## Outcome

An adopter following the documented generate-then-host path gets a shell that cold-starts to their
own origin, without hand-editing a generated file.

## The defect (verified in this repo, 2026-09-14)

`mix crosswake.gen.shell ios` scaffolds the example host's fixtures into the adopter's tree —
`native/ios/crosswake_shell/Fixtures/crosswake_manifest.json` and `route_activation.json` — built
from `Crosswake.Manifest.Types` `@default_origin "https://example.crosswake.invalid"`
(`lib/crosswake/manifest/types.ex:772`), via `lib/crosswake/shell/fixtures.ex`.

The generated Xcode project makes `Fixtures` a **resource group of the app target**, so both files
ship inside the installed `.app`.

`.invalid` is a reserved TLD and can never resolve.

## User-visible consequence

On every cold start the shell resolves routes against that manifest. Hotwire Native treats the
origin as an external domain and presents a **system browser sheet** reading
`example.crosswake.invalid`, then "server not found", then "frame load interrupted". The user must
dismiss the sheet and hit Retry before the navigator's real `startLocation` is reached.

Reproduced on a physical device across two separate launches, on a build that was correct in every
other layer.

## Ask

1. A documented mix task an adopter runs **in their own host app** that emits a production
   `crosswake_manifest.json` (plus the activation record) carrying the host's real origin and the
   host's own `RouteTable` entries, suitable for bundling into the generated shell.
   `mix crosswake.contract.gen` does not serve this — its `@moduledoc` targets crosswake-repo paths
   only, and `--dev` writes crosswake's own dev fixtures (localhost / 10.0.2.2).
2. `mix crosswake.gen.shell` should either not scaffold example fixtures into the adopter's app
   target at all, or scaffold them somewhere that is **not a shipped resource**.
3. **Fail loudly** if a `.invalid` origin is still present at build time. A generated shell that
   would boot against `example.crosswake.invalid` should not be able to reach a device silently.

The concept already exists on the Elixir side: `Crosswake.Compatibility` models
`manifest_source: :bundled | :cached | :remote` (`lib/crosswake/compatibility/compatibility.ex:52`).
What is missing is the adopter-side `RouteTable` → production manifest path.

## Adopter workaround (and why it makes this more load-bearing, not less)

They hand-patched the bundled manifest — origin and `allowlisted_origins` swapped to their real
origin, `dashboard` path `/dashboard` → `/`. That is a hand-edit of a generated file that the next
`mix crosswake.gen.shell ios` will clobber: a permanent-by-default workaround, which is precisely
what this request exists to prevent.

## Incidental, from the same report (no action requested, worth a guide line)

`priv/templates/crosswake/shell/ios/Info.plist.eex` ships `WKAppBoundDomains` as a single
`example.com` entry. Correct as a capability-grant instinct, but any adopter behind an SSO/identity
proxy needs a second entry — `limitsNavigationsToAppBoundDomains = true` blocks the login hop to a
third-party auth domain. A line in the install guide about auth-provider domains would save the
diagnosis.
