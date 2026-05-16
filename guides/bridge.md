# Bounded Bridge

Crosswake Phase 3 exposes one typed, versioned, request/reply-only bridge. It is deliberately small:

- `app.info.get`
- `haptics.impact`
- `files.pick`

Everything else is denied. The bridge is not navigation authority, not render synchronization, and not a generic plugin bus.

## Request Envelope

Every request carries:

- `protocol`: `crosswake.bridge`
- `version`: bridge protocol version
- `command`: one of the three bounded commands
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
