# iPhone rehearsal and physical proof

Run the reference rehearsal first:

```bash
bin/crosswake-ios-rehearsal
```

It starts the checked-in Phoenix host, opens `/learnloop/study/session` in iPhone
Simulator, and runs the reference iOS checks. This is advisory simulator evidence;
it does not establish physical-device support or promote an artifact.
If Docker cannot allocate its project network, the command safely falls back to a
local Phoenix process and keeps it available for the open Simulator route; stop that
fallback later with `bin/crosswake-ios-rehearsal --stop`.

For a real host, generate the proof lane, move the generated
`physical_iphone/physical_iphone_proof_host.ex` skeleton into the host application,
and implement its callbacks with sanitized route inventory plus real signed-device and
backend evidence. Configure that host-owned module as
`:physical_iphone_proof_host`. The supplied skeleton is deliberately blocked until
each callback is implemented.

When the host wiring is ready, the operator flow is:

1. Connect, unlock, and trust exactly one signed iPhone.
2. Place the validated private handoff at
   `~/.config/crosswake/first-adopter-handoff.json` (or set its path override).
3. Run the physical-proof command from the host repository. It discovers the
   single connected iPhone and a private LAN endpoint for the local reference
   host when no explicit overrides are supplied.

The wrapper first prints an aggregate safe readiness report. It contains stable rule
IDs only, never account references, route paths, tokens, credentials, raw callback
data, or device identifiers. Ambiguous or unreachable local setup remains
blocked. If readiness succeeds it invokes the existing
host-owned physical proof and promotion command. A simulator run can never satisfy
that promotion gate.
