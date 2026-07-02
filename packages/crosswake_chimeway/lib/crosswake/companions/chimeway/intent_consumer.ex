defmodule Crosswake.Companions.Chimeway.IntentConsumer do
  @moduledoc """
  Behaviour for host registry/resolver to implement intent and state checks
  for notification opens.
  """

  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.OpenResolution

  @doc """
  Consume and resolve a notification open intent.
  """
  @callback consume_intent(NotificationOpenEvidence.t()) ::
              {:ok, OpenResolution.t()} | {:error, map() | keyword()}
end
