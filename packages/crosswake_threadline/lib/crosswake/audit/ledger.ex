defmodule Crosswake.Audit.Ledger do
  @moduledoc """
  Defines the core Audit Ledger contract struct and HMAC anonymization helper.
  """

  @type t :: %__MODULE__{
          thread_id: String.t() | nil,
          correlation_id: String.t() | nil,
          route_id: String.t() | nil,
          actor_ref: String.t() | nil,
          actor_kind: String.t() | nil,
          event_class: String.t() | nil,
          event_type: String.t() | nil,
          outcome: String.t() | nil,
          provenance: String.t() | nil,
          occurred_at: DateTime.t() | nil,
          recorded_at: DateTime.t() | nil,
          idempotency_key: String.t() | nil,
          metadata: map() | nil,
          row_hash: String.t() | nil,
          prev_hash: String.t() | nil
        }

  defstruct [
    :thread_id,
    :correlation_id,
    :route_id,
    :actor_ref,
    :actor_kind,
    :event_class,
    :event_type,
    :outcome,
    :provenance,
    :occurred_at,
    :recorded_at,
    :idempotency_key,
    :metadata,
    :row_hash,
    :prev_hash
  ]

  @doc """
  Computes an HMAC-SHA256 of the given `id` using a secret.

  If `opts[:secret]` is provided, it is used as the secret.
  Otherwise, it falls back to `Application.get_env(:crosswake, :audit_hmac_secret)`.

  Raises `ArgumentError` if no secret is available.
  Returns the HMAC as a lowercase base16 string.
  """
  @spec actor_ref(any(), keyword()) :: String.t()
  def actor_ref(id, opts \\ []) do
    secret = opts[:secret] || Application.get_env(:crosswake, :audit_hmac_secret)

    unless secret do
      raise ArgumentError,
        "Missing HMAC secret for Crosswake.Audit.Ledger.actor_ref/2. " <>
          "Provide it via the :secret option (actor_ref(id, secret: \"...\")) " <>
          "or set Application.put_env(:crosswake, :audit_hmac_secret, \"...\") in your config."
    end

    :crypto.mac(:hmac, :sha256, secret, to_string(id))
    |> Base.encode16(case: :lower)
  end
end
