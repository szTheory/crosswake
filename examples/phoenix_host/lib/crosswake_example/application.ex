defmodule CrosswakeExample.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # MockFlagSource must start first — before any child that triggers RouteGate
      # evaluation during init (RESEARCH Pitfall 2). See config.exs for the
      # companion registration and enablement config.
      Crosswake.Companions.Rulestead.MockFlagSource,
      {Phoenix.PubSub, name: CrosswakeExample.PubSub},
      CrosswakeExample.Repo
    ]

    opts = [strategy: :one_for_one, name: CrosswakeExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
