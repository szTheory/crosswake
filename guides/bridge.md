# Bounded Bridge

Crosswake exposes one typed, versioned, request/reply-only bridge. It stays deliberately
small even after Phase 5, and its public framing is family-first rather than
command-first:

- `app.info.get`
- `haptics.impact`
- `files.pick`
- `transfer.download`
- `transfer.export`
- `transfer.import`
- `transfer.upload.prepare`

The public families behind that posture are `app_info`, `haptics`, and, later,
`share`. This bounded bridge contract stays family-first. Concrete bridge commands remain lower-level protocol details. Everything
else is denied. The bridge is not navigation authority, not render synchronization,
and not a generic plugin bus. `deep_link` remains manifest-first shell activation truth, not route-local bridge or navigation authority.

## Request Envelope

Every request carries:

- `protocol`: `crosswake.bridge`
- `version`: bridge protocol version
- `command`: one of the bounded commands above
- `capability`: must match the command's manifest-backed capability id
- `route_id`: requested route identity
- `active_route_id`: current active route identity
- `origin`: caller origin
- `native_runtime_version`: shipped shell runtime version
- `correlation_id`: request/reply correlation id
- `capabilities`: capability versions available in the shell
- `installed_packs`: installed pack versions available in the shell
- `payload`: command payload

## Enforcement

Before any side effect runs, Crosswake checks:

- The active route matches `route_id`
- The route exists in the manifest
- The origin is allowlisted for the route
- The bridge protocol and native runtime versions are compatible
- The command is in the bounded Phase 3 allowlist
- The route declares the capability
- The manifest capability registry provides the capability version
- The shell exposes that capability version
- The route's declared packs are compatible with the shell

If any check fails, Crosswake returns a typed denial reply and executes no side effect.

## Transfer Boundary

The transfer commands stay semantic and route-local.

- `transfer.import` means the route explicitly asked to import user-chosen media or files.
- `transfer.export` means the route explicitly asked to hand owned content out.
- `transfer.download` means the route explicitly asked for a download seam.
- `transfer.upload.prepare` means staged local media is ready to enter a foreground-first upload path.

Transfer execution is foreground-first. States remain explicit: `queued`, `preparing`,
`transferring`, `awaiting_network`, `verifying`, `complete`, `failed`, and `canceled`.
Crosswake does not promise silent background reconciliation or generic file authority.

The bridge examples that remain honest in this posture are family-first:

- `app_info` for one-shot app metadata reads
- `haptics` for low-frequency confirmation signals
- `share` as a future semantic handoff family once Crosswake publishes a truthful
  route-local share contract beyond compatibility-only command seams

## Denial Reasons

Bridge denials reuse the shared shell denial vocabulary:

- `compatibility_mismatch`
- `undeclared_capability`
- `unavailable_capability`
- `origin_denied`
- `inactive_route`
- `pack_incompatible`

## Reply Shape

Successful replies return:

- `protocol`
- `version`
- `command`
- `route_id`
- `correlation_id`
- `status: "ok"`
- `payload`

Denied replies return the same fields with `status: "deny"` plus a nested typed denial payload containing the stable reason, code, message, route id, and optional hint.
