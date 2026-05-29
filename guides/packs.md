# Packs And Transfers

Crosswake Phase 5 adds one explicit required-pack contract, one explicit transfer
contract, and one explicit native-capture handoff. It does not widen the project into
generic asset management, generic uploads, or `:adapter` breadth.

If you are evaluating whether your app needs one explicit native route with route-
local packs and transfers, read
[guides/adopter_profiles.md](adopter_profiles.md)
first, then use this guide for the concrete seam contract.

## Required Packs

Routes can declare versioned packs in route policy. The manifest owns the canonical
pack registry, and shells only activate a route after required packs verify as usable.

Visible required-pack states:

- `checking`
- `not_installed`
- `installing`
- `available`
- `stale`
- `invalidating`
- `failed`

The route-facing CTA stays explicit: `Install Required Pack`. If the shell cannot resolve or install the required pack, activation fails closed with `pack_incompatible` rather than silently degrading into a generic web container.

## Transfer Seams

Transfer commands are semantic, route-local, and foreground-first:

- `transfer.import`
- `transfer.export`
- `transfer.download`
- `transfer.upload.prepare`

Visible transfer states stay explicit:

- `queued`
- `preparing`
- `transferring`
- `awaiting_network`
- `verifying`
- `complete`
- `failed`
- `canceled`

`awaiting_network` means the transfer cannot continue until connectivity returns. It
does not promise hidden background completion.

## Native Capture Handoff

Crosswake publishes one `:native_screen` media-capture escape hatch.

- The runtime label stays visible as `Native capture`.
- Media can be captured and staged locally.
- `staged` is not the same as `transferred`.
- A captured file only becomes transferable after an explicit `transfer.upload.prepare`.

Crosswake does not turn native capture into generic WebView upload ownership and does
not silently fall back to another runtime.

## Proof Posture

The public artifact class is the checked-in example hosts:

- `bash script/verify_phase5_example_hosts.sh`

Generated-host verification remains secondary and should stay green alongside it:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

Read [guides/support_matrix.md](support_matrix.md)
for the proof-backed support posture and
[guides/native_shell.md](native_shell.md) for the
runtime ownership boundary.
