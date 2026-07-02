# crosswake_threadline

Threadline audit and correlation observer for [Crosswake](https://hexdocs.pm/crosswake) — the route-policy and runtime-contract library for Phoenix apps that go mobile.

This package extracts `Crosswake.Threadline.*`, `Crosswake.Audit.Ledger`, `Crosswake.Plug.Threadline`, and `Crosswake.Live.Threadline` into a standalone Hex dependency so hosts can adopt threadline audit/correlation as a Hex dependency. The module namespaces and the adopter touch-points (`plug Crosswake.Plug.Threadline`, `on_mount: Crosswake.Live.Threadline`) are unchanged — extraction is non-breaking.

## Installation

Add `crosswake_threadline` to your `mix.exs`:

```elixir
defp deps do
  [
    {:crosswake, "~> 0.1"},
    {:crosswake_threadline, "~> 0.1"},
    # Optional — only needed if you use Crosswake.Plug.Threadline:
    {:plug, "~> 1.0"},
    # Optional — only needed if you use Crosswake.Live.Threadline:
    {:phoenix_live_view, "~> 1.1"}
  ]
end
```

> After adding the optional `:plug` or `:phoenix_live_view` deps, run:
> `mix deps.compile --force crosswake_threadline`
> (stale-BEAM caveat: optional deps are not compiled by default until forced.)

## Usage

### Plug (HTTP thread_id propagation)

```elixir
plug Crosswake.Plug.Threadline
```

### LiveView (thread_id metadata bridge)

```elixir
on_mount {Crosswake.Live.Threadline, :default}
```

### Audit Ledger (host-owned schema generation)

Generate the host-owned Ecto schema and migration:

```sh
mix crosswake.gen.audit
```

### Threadline CLI (timeline visualization)

```sh
mix crosswake.threadline --thread-id <id>
mix crosswake.threadline --actor-ref <ref>
```

### Configuration (durable posture)

```elixir
config :crosswake,
  audit_repo: MyApp.Repo,
  audit_ledger: MyApp.Audit.Ledger,
  audit_hmac_secret: "your-secret-here"
```
