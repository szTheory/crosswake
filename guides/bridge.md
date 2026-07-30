# Bounded Bridge

Crosswake exposes one typed, versioned, request/reply-only bridge. It stays deliberately
small even after Phase 5, and its public framing is family-first rather than
command-first:

- `app.info.get`
- `haptics.impact`
- `permissions.status`
- `files.pick`
- `transfer.download`
- `transfer.export`
- `transfer.import`
- `transfer.upload.prepare`

The public families behind that posture are `app_info`, `haptics`, `permissions.status`, and, later,
`share`. This bounded bridge contract stays family-first. Concrete bridge commands remain lower-level protocol details. Everything
else is denied. The bridge is not navigation authority, not render synchronization,
and not a generic plugin bus. `deep_link` remains manifest-first shell activation truth, not route-local bridge or navigation authority.

Route policy declares the family (`"haptics"`); the bridge dispatches the command
(`"haptics.impact"`). These stay two distinct vocabularies on purpose — one names
what a route is authorized to do, the other names what goes over the wire. A route
that still declares the older dotted command id as its capability keeps authorizing
indefinitely (no compile-time warning, no removal); `mix crosswake.doctor` names
any route still doing so, alongside the family id to write instead.

## The Adopter API

You never build a wire envelope by hand. A LiveView that has attached the bridge calls
`Crosswake.Bridge.push/3` with a capability family and receives a typed
`Crosswake.Bridge.Reply` in its own `handle_info/2`.

### Attach first — `push/3` raises on a socket that never did

`Crosswake.Bridge.push/3` raises `Crosswake.Bridge.NotMountedError` when the socket
never called `Crosswake.Bridge.attach/1`. Crosswake never guesses a route id, so this
is a named, loud, install-time failure rather than a silent no-op. It is the one new
failure surface every adopter hits exactly once.

```elixir
def mount(_params, _session, socket) do
  socket =
    socket
    |> assign(crosswake_manifest: MyAppWeb.Crosswake.Policy.manifest(), crosswake_route_id: "saas-approval")
    |> Crosswake.Bridge.attach()

  {:ok, socket}
end
```

`attach/1` requires `:crosswake_manifest` and `:crosswake_route_id` to already be
assigned. `on_mount: Crosswake.Bridge` works too, provided it runs after whatever hook
assigns those two — `on_mount` hooks in a `live_session` run in declared order.

### `push/3` — the only entry point

```elixir
# Fire-and-forget: no `ref:`, so no reply is delivered and no handle_info clause is needed.
Crosswake.Bridge.push(socket, "haptics", payload: %{"style" => "light"})

# Correlated: `ref:` is an opaque handle echoed back on delivery.
Crosswake.Bridge.push(socket, "file_picker", ref: {:pick, upload_id}, payload: %{"transfer_id" => id})
```

Options are `:ref`, `:payload`, and `:timeout` (default `10_000` ms; pass `:infinity` to
opt a human-in-the-loop control out of the server-side backstop). `push/3` returns the
socket immediately and is chainable; the reply always arrives later.

There is deliberately no `available?/2` or `connected?/1`. A pre-check invites
`if available?, do: push, else: fallback` — a three-way branch by the back door that
reintroduces exactly the branching this contract exists to collapse.

### `handle_info/2` — where every reply lands

```elixir
def handle_info({:crosswake_bridge, {:pick, upload_id}, %Crosswake.Bridge.Reply{} = reply}, socket) do
  case reply do
    %{status: :ok, payload: payload} ->
      {:noreply, attach_picked_files(socket, upload_id, payload)}

    %{status: :deny, denial: %Crosswake.Shell.Denial{} = denial} ->
      {:noreply, put_flash(socket, :error, denial.message)}
  end
end
```

There is no configuration in which a push resolves to silence. No shell, an unwired
hook, and a shell refusal each deliver exactly one typed reply, collapsed onto the same
`Crosswake.Shell.Denial` shape at `status` and distinguished only at `reason`. The
`:shell_unreachable` reason carries a `details.failing_moment` naming which of
`:no_transport`, `:hook_not_wired`, `:reply_timeout`, or `:transport_error` happened.

### `resolve/2` — when two answer sources race

When a native reply and an on-page fallback click can both answer the same ask, call
`Crosswake.Bridge.resolve/2` from the fallback handler. It is an atomic
compare-and-delete — safe because a LiveView is one serialized process — so whichever
answer arrives first wins and the other finds nothing to resolve.

```elixir
def handle_event("picked_in_fallback", params, socket) do
  {:noreply, socket |> Crosswake.Bridge.resolve({:pick, params["id"]}) |> apply_fallback(params)}
end
```

Do NOT route both answer sources into the same event name to "deduplicate" them — that
guarantees the same mutation runs twice. `resolve/2` is the only mechanism, and a
second call for the same ref is a no-op that never raises.

### Wiring the client half

The bridge needs the library-owned hook on the page. `mix crosswake.install` patches the
endpoint's static plug and prints the rest; `mix crosswake.gen.bridge_hook` prints all
three fragments on demand. See
[guides/install.md](install.md#step-1b-wire-the-bridge-hook).

An in-flight ask does not survive a LiveView reconnect: a fresh `attach/1` mints a new
epoch, so a reply minted under the previous epoch is dropped rather than replayed into a
LiveView that never asked for it. The recovery path is the fallback UI rebuilt from
assigns, not resurrecting the stale ask.

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
- `permissions.status` for one-shot prerequisite checks scoped to the `notifications` alias only
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
