defmodule CrosswakeExample.Chimeway.MetadataSanitizer do
  @moduledoc """
  Closed metadata persistence boundary for Chimeway token binding and audit rows.

  Binding and audit rows retain lifecycle-safe facts in their explicit typed
  columns. Generic caller metadata has no durable contract and is always
  discarded without inspection or traversal.
  """

  @doc """
  Projects untrusted token-binding and audit metadata to the empty durable contract.

  Explicit binding and event schema columns remain the only durable lifecycle
  evidence. Caller metadata is never retained, inspected, or traversed.
  """
  @spec sanitize(term()) :: %{}
  def sanitize(_metadata), do: %{}

  @doc """
  Projects untrusted notification-open metadata to the empty durable contract.

  Notification opens retain their explicit schema fields and host-authoritative
  lifecycle events only. Caller metadata is never retained, inspected, or
  traversed at this persistence boundary.
  """
  @spec sanitize_notification_open(term()) :: %{}
  def sanitize_notification_open(_metadata), do: %{}
end
