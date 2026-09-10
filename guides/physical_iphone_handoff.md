# iPhone rehearsal and physical proof

**Blocked — sanitized route policy and signed-device proof are required before this host can be promoted.**
Retained reference evidence is dated, source-bound, and does not verify the first adopter's host.
See the [current first adopter claim layers](support_matrix.md#first-adopter-readiness) before
starting host-specific proof.

**Reference rehearsal:** retained source-bound evidence records one bounded reference-host
flow from 2026-08-27 on iOS 26.6. It is past-tense evidence for that source and runtime
line only; it cannot be transferred to another host.

**First adopter activation:** remains blocked until sanitized route policy validates and
a fresh source-bound signed-device run passes for that host. Reference, fixture, and
simulator evidence cannot satisfy this activation gate.

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
