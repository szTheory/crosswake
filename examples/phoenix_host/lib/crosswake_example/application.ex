defmodule CrosswakeExample.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # The flag source must start first — before any child that triggers RouteGate
      # evaluation during init (RESEARCH Pitfall 2). See config.exs for the
      # companion registration, enablement, and flag-source wiring.
      CrosswakeExample.RulesteadFlagSource,
      {Phoenix.PubSub, name: CrosswakeExample.PubSub},
      CrosswakeExample.Repo,
      CrosswakeExample.Endpoint
    ]

    opts = [strategy: :one_for_one, name: CrosswakeExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
