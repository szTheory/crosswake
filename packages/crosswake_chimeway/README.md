# crosswake_chimeway

Chimeway notification companion adapter for [Crosswake](https://hexdocs.pm/crosswake) — the route-policy and runtime-contract library for Phoenix apps that go mobile.

This package extracts `Crosswake.Companions.Chimeway` into a standalone Hex dependency so hosts can choose their companion integrations without modifying core. The module namespace (`Crosswake.Companions.Chimeway`) and the adopter touch-point (`config :crosswake, :companions, [...]`) are unchanged — extraction is non-breaking.

## Installation

Add `crosswake_chimeway` to your `mix.exs`:

```elixir
defp deps do
  [
    {:crosswake, "~> 0.1"},
    {:crosswake_chimeway, "~> 0.1"}
  ]
end
```

Then configure the companion in your application:

```elixir
config :crosswake, :companions, [Crosswake.Companions.Chimeway]
```

## Package-family discipline

`crosswake_chimeway` is part of the Crosswake package family. Core (`crosswake`) never compile-depends on a companion; companions never depend on each other. See the [companion contract guide](https://hexdocs.pm/crosswake/companion_contract.html) for the stable seam surface.
