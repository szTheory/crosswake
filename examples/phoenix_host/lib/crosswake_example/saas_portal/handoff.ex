defmodule CrosswakeExample.SaaSPortal.Handoff do
  @moduledoc """
  Example-host Sigra handoff issue, redeem, and revoke workflow.

  The signed envelope is only a low-sensitivity locator. This module derives
  authority from the Ecto-backed one-time ticket record and returns host-owned
  Phoenix session renewal instructions after backend redemption succeeds.
  """

  import Ecto.Query

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Contracts.AuthContext
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.Handoff, as: SigraHandoff
  alias Crosswake.Manifest
  alias Crosswake.Shell.Denial
  alias CrosswakeExample.Repo
  alias CrosswakeExample.Router
  alias CrosswakeExample.SaaSPortal.HandoffAuditEvent
  alias CrosswakeExample.SaaSPortal.HandoffTicket

  @salt "crosswake.sigra.handoff.v1"
  @secret "crosswake-example-sigra-handoff-secret"
  @issuer "crosswake_example"
  @audience "crosswake.sigra.handoff"
  @typ "crosswake.sigra.handoff.v1"
  @version "1"
  @ttl_seconds 180
  @max_age_seconds 300

  def issue(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_attrs(attrs)

    with :ok <- reject_return_to(attrs),
         {:ok, route} <- fetch_route(fetch_string(attrs, :target_route_id)),
         {:ok, issue_data} <- build_issue_data(attrs, route) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:ticket, HandoffTicket.changeset(%HandoffTicket{}, issue_data.ticket))
      |> Ecto.Multi.insert(
        :audit_event,
        HandoffAuditEvent.changeset(%HandoffAuditEvent{}, issue_data.audit_event)
      )
      |> Repo.transaction()
      |> case do
        {:ok, %{ticket: ticket}} ->
          {:ok,
           %{
             envelope: issue_data.envelope,
             signed_envelope: issue_data.signed_envelope,
             ticket: ticket,
             handoff_ref: issue_data.handoff_ref
           }}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    else
      {:deny, code, details} -> {:error, denial(code, details)}
      {:error, %Denial{} = denial} -> {:error, denial}
      {:error, reason} -> {:error, reason}
    end
  end

  def redeem(signed_envelope, attrs) when is_binary(signed_envelope) do
    attrs = normalize_attrs(attrs)

    with {:ok, payload} <- verify_envelope(signed_envelope),
         {:ok, envelope} <- SigraHandoff.new_handoff_envelope(payload),
         {:ok, ticket} <- fetch_ticket(envelope.ticket_ref, digest(signed_envelope)),
         :ok <- validate_request(envelope, ticket, attrs) do
      consume_ticket(ticket, envelope, attrs)
    else
      {:deny, code, details} -> {:error, denial(code, details)}
      {:error, %Denial{} = denial} -> {:error, denial}
      {:error, _reason} -> {:error, denial("auth.handoff.invalid_ticket", %{})}
    end
  end

  def redeem(_signed_envelope, _attrs),
    do: {:error, denial("auth.handoff.missing_ticket", %{})}

  def revoke(ticket_ref, attrs \\ %{}) when is_binary(ticket_ref) do
    attrs = normalize_attrs(attrs)
    now = now()
    reason = fetch_string(attrs, :revocation_reason) || "host_revoked"

    query =
      from(ticket in HandoffTicket,
        where:
          ticket.ticket_ref == ^ticket_ref and ticket.state == "issued" and
            is_nil(ticket.consumed_at) and is_nil(ticket.revoked_at)
      )

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:revoke, query,
      set: [state: "revoked", revoked_at: now, revocation_reason: reason, updated_at: now]
    )
    |> Ecto.Multi.run(:ticket, fn repo, %{revoke: {count, _}} ->
      if count == 1 do
        {:ok, repo.get_by!(HandoffTicket, ticket_ref: ticket_ref)}
      else
        {:error, :not_revokable}
      end
    end)
    |> Ecto.Multi.insert(:audit_event, fn %{ticket: ticket} ->
      HandoffAuditEvent.changeset(
        %HandoffAuditEvent{},
        audit_attrs(:revoke, ticket, %{
          state_before: "issued",
          state_after: "revoked",
          outcome: "allowed",
          occurred_at: now,
          request_ref: fetch_string(attrs, :request_ref) || ref("req")
        })
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{ticket: ticket}} -> {:ok, ticket}
      {:error, _step, _reason, _changes} -> {:error, denial("auth.handoff.revoked_ticket", %{})}
    end
  end

  def signing_secret, do: @secret
  def signing_salt, do: @salt
  def ttl_seconds, do: @ttl_seconds

  defp build_issue_data(attrs, route) do
    issued_at = fetch_datetime(attrs, :issued_at) || now()

    expires_at =
      DateTime.add(issued_at, fetch_integer(attrs, :ttl_seconds) || @ttl_seconds, :second)

    ticket_ref = fetch_string(attrs, :ticket_ref) || ref("hnd")
    handoff_ref = fetch_string(attrs, :handoff_ref) || ref("support:hnd")
    request_ref = fetch_string(attrs, :request_ref) || ref("req")

    projected_session_version =
      fetch_integer(attrs, :projected_session_version) || next_version(attrs)

    projected_session_ref = fetch_string(attrs, :projected_session_ref) || ref("sess")

    projected_authority =
      Map.get(attrs, :projected_authority) ||
        default_projected_authority(
          attrs,
          projected_session_ref,
          projected_session_version,
          issued_at
        )

    payload = %{
      "typ" => @typ,
      "ticket_ref" => ticket_ref,
      "version" => @version,
      "issuer" => @issuer,
      "audience" => @audience,
      "issued_at" => DateTime.to_iso8601(issued_at),
      "expires_at" => DateTime.to_iso8601(expires_at),
      "intent_kind" => fetch_atom(attrs, :intent_kind) || :session_handoff,
      "route_id" => route.id,
      "binding_kind" => fetch_atom(attrs, :binding_kind) || :session_route_intent,
      "handoff_transport" => fetch_string(attrs, :handoff_transport) || "phoenix_token"
    }

    with {:ok, envelope} <- SigraHandoff.new_handoff_envelope(payload) do
      signed_envelope = Phoenix.Token.sign(@secret, @salt, payload)
      ticket_digest = digest(signed_envelope)

      ticket = %{
        ticket_ref: ticket_ref,
        ticket_digest: ticket_digest,
        state: "issued",
        subject_ref: fetch_string!(attrs, :subject_ref),
        org_id: fetch_string!(attrs, :org_id),
        source_session_ref: fetch_string!(attrs, :source_session_ref),
        expected_session_version: fetch_integer!(attrs, :expected_session_version),
        device_ref: fetch_string(attrs, :device_ref),
        binding_kind: to_string(payload["binding_kind"]),
        intent_kind: to_string(payload["intent_kind"]),
        intent_ref: fetch_string(attrs, :intent_ref),
        source_route_id: fetch_string(attrs, :source_route_id),
        target_route_id: route.id,
        required_assurance_level: fetch_string(attrs, :required_assurance_level) || "mfa",
        required_auth_posture: fetch_string(attrs, :required_auth_posture) || "strict_recent",
        issued_at: issued_at,
        expires_at: expires_at,
        audit_correlation_ref: handoff_ref,
        projected_session_ref: projected_session_ref,
        projected_session_version: projected_session_version,
        projected_authority: projected_authority
      }

      audit_event =
        audit_attrs(:issue, struct!(HandoffTicket, ticket), %{
          state_before: nil,
          state_after: "issued",
          outcome: "allowed",
          occurred_at: issued_at,
          request_ref: request_ref
        })

      {:ok,
       %{
         envelope: envelope,
         signed_envelope: signed_envelope,
         ticket: ticket,
         audit_event: audit_event,
         handoff_ref: handoff_ref
       }}
    end
  rescue
    KeyError -> {:deny, "auth.handoff.projection_failed", %{}}
  end

  defp consume_ticket(ticket, envelope, attrs) do
    evaluated_at = fetch_datetime(attrs, :evaluated_at) || now()
    ticket_ref = ticket.ticket_ref

    query =
      from(row in HandoffTicket,
        where:
          row.ticket_ref == ^ticket_ref and row.state == "issued" and is_nil(row.consumed_at) and
            is_nil(row.revoked_at) and row.expires_at > ^evaluated_at
      )

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:consume, query,
      set: [state: "redeemed", consumed_at: evaluated_at, updated_at: evaluated_at]
    )
    |> Ecto.Multi.run(:ticket, fn repo, %{consume: {count, _}} ->
      if count == 1 do
        {:ok, repo.get_by!(HandoffTicket, ticket_ref: ticket_ref)}
      else
        {:error, lifecycle_denial(ticket, evaluated_at)}
      end
    end)
    |> Ecto.Multi.run(:redemption, fn _repo, %{ticket: consumed_ticket} ->
      build_redemption(consumed_ticket, envelope, attrs, evaluated_at)
    end)
    |> Ecto.Multi.insert(:audit_event, fn %{ticket: consumed_ticket, redemption: redemption} ->
      HandoffAuditEvent.changeset(
        %HandoffAuditEvent{},
        audit_attrs(:redeem, consumed_ticket, %{
          state_before: "issued",
          state_after: "redeemed",
          outcome: "allowed",
          occurred_at: evaluated_at,
          request_ref: fetch_string(attrs, :request_ref) || ref("req"),
          projected_session_ref: redemption.session_authority_lane.session_ref,
          session_version_after: redemption.session_authority_lane.session_version,
          assurance_after: Atom.to_string(redemption.session_authority_lane.assurance_level),
          authn_methods_after:
            Enum.map(redemption.session_authority_lane.authn_methods, &to_string/1),
          binding_result: "matched"
        })
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{redemption: redemption}} ->
        {:ok, redemption}

      {:error, :ticket, {:deny, code, details}, _changes} ->
        append_denied_audit(ticket, code, details, attrs, evaluated_at)
        {:error, denial(code, details)}

      {:error, :redemption, {:deny, code, details}, _changes} ->
        append_denied_audit(ticket, code, details, attrs, evaluated_at)
        {:error, denial(code, details)}

      {:error, _step, _reason, _changes} ->
        {:error,
         denial("auth.handoff.projection_failed", %{handoff_ref: ticket.audit_correlation_ref})}
    end
  end

  defp build_redemption(ticket, _envelope, _attrs, evaluated_at) do
    authority_attrs =
      ticket.projected_authority
      |> atomize_known_authority()
      |> Map.put_new(:as_of, DateTime.to_iso8601(evaluated_at))

    with {:ok, lane} <- Contracts.new_session_authority_lane(authority_attrs),
         {:ok, renewal} <-
           SigraHandoff.new_session_renewal_instructions(%{
             renew_session?: true,
             put_session: %{
               "crosswake_session_ref" => lane.session_ref,
               "crosswake_session_version" => lane.session_version
             },
             delete_session: [],
             projected_session_ref: lane.session_ref,
             projected_session_version: lane.session_version
           }),
         {:ok, route} <- fetch_route(ticket.target_route_id),
         :ok <- prove_route_authority(route, lane, ticket, evaluated_at) do
      SigraHandoff.new_handoff_redemption(%{
        handoff_ref: ticket.audit_correlation_ref,
        consumed_at: evaluated_at,
        session_authority_lane: lane,
        session_projection: %{
          session_ref: lane.session_ref,
          session_version: lane.session_version
        },
        session_renewal_instructions: renewal,
        route_target: %{route_id: route.id, path: route.path}
      })
    else
      {:error, %Denial{} = denial} ->
        {:error, {:deny, denial.code || "auth.handoff.projection_failed", denial.details}}

      {:error, _errors} ->
        {:error,
         {:deny, "auth.handoff.projection_failed", %{handoff_ref: ticket.audit_correlation_ref}}}

      {:deny, code, details} ->
        {:error, {:deny, code, details}}
    end
  end

  defp prove_route_authority(route, lane, ticket, evaluated_at) do
    auth_context =
      struct!(AuthContext,
        actor_id: lane.subject_ref,
        org_id: lane.org_id,
        mfa_level: lane.assurance_level,
        auth_age: Contracts.lane_auth_age_seconds(lane, evaluated_at),
        session_authority_lane: lane,
        as_of: lane.as_of
      )

    {:ok, %{manifest: manifest}} = Manifest.compile(Router)

    target = %Target{
      origin: manifest.host.origin,
      manifest_schema_version: manifest.compatibility.manifest_schema_version,
      bridge_protocol_version: manifest.compatibility.bridge_protocol_version,
      native_runtime_version: manifest.compatibility.native_runtime_version
    }

    case RouteGate.evaluate(manifest, route.id, target,
           auth_context: auth_context,
           expected_session_version: ticket.projected_session_version
         ) do
      %{status: :allow} -> :ok
      %{denial: %Denial{} = denial} -> {:error, denial}
    end
  end

  defp validate_request(envelope, ticket, attrs) do
    cond do
      ticket.state == "redeemed" or not is_nil(ticket.consumed_at) ->
        {:deny, "auth.handoff.replayed_ticket", safe_details(ticket)}

      ticket.state == "revoked" or not is_nil(ticket.revoked_at) ->
        {:deny, "auth.handoff.revoked_ticket", safe_details(ticket)}

      expired?(ticket, fetch_datetime(attrs, :evaluated_at) || now()) ->
        {:deny, "auth.handoff.expired_ticket", safe_details(ticket)}

      envelope.route_id != ticket.target_route_id or
          fetch_string(attrs, :expected_route_id) != ticket.target_route_id ->
        {:deny, "auth.handoff.route_mismatch", safe_details(ticket)}

      to_string(envelope.intent_kind) != ticket.intent_kind or
          fetch_string(attrs, :expected_intent_kind) != ticket.intent_kind ->
        {:deny, "auth.handoff.intent_mismatch", safe_details(ticket)}

      fetch_string(attrs, :source_session_ref) != ticket.source_session_ref or
          fetch_integer(attrs, :expected_session_version) != ticket.expected_session_version ->
        {:deny, "auth.handoff.binding_mismatch", safe_details(ticket)}

      true ->
        :ok
    end
  end

  defp verify_envelope(nil), do: {:deny, "auth.handoff.missing_ticket", %{}}

  defp verify_envelope(signed_envelope) do
    case Phoenix.Token.verify(@secret, @salt, signed_envelope, max_age: @max_age_seconds) do
      {:ok, %{} = payload} -> {:ok, payload}
      _other -> {:deny, "auth.handoff.invalid_ticket", %{}}
    end
  end

  defp fetch_ticket(ticket_ref, ticket_digest) do
    case Repo.get_by(HandoffTicket, ticket_ref: ticket_ref, ticket_digest: ticket_digest) do
      nil -> {:deny, "auth.handoff.invalid_ticket", %{}}
      ticket -> {:ok, ticket}
    end
  end

  defp fetch_route(route_id) when is_binary(route_id) do
    with {:ok, %{manifest: manifest}} <- Manifest.compile(Router),
         route when not is_nil(route) <- Map.get(manifest.routes, route_id) do
      {:ok, route}
    else
      _other -> {:deny, "auth.handoff.route_mismatch", %{route_binding: "manifest_known"}}
    end
  end

  defp fetch_route(_route_id), do: {:deny, "auth.handoff.route_mismatch", %{}}

  defp reject_return_to(attrs) do
    if Map.has_key?(attrs, :return_to) do
      {:deny, "auth.handoff.route_mismatch", %{route_binding: "manifest_known"}}
    else
      :ok
    end
  end

  defp lifecycle_denial(ticket, evaluated_at) do
    cond do
      ticket.state == "redeemed" or not is_nil(ticket.consumed_at) ->
        {:deny, "auth.handoff.replayed_ticket", safe_details(ticket)}

      ticket.state == "revoked" or not is_nil(ticket.revoked_at) ->
        {:deny, "auth.handoff.revoked_ticket", safe_details(ticket)}

      expired?(ticket, evaluated_at) ->
        {:deny, "auth.handoff.expired_ticket", safe_details(ticket)}

      true ->
        {:deny, "auth.handoff.invalid_ticket", %{}}
    end
  end

  defp append_denied_audit(ticket, code, details, attrs, occurred_at) do
    attrs =
      audit_attrs(:deny, ticket, %{
        state_before: ticket.state,
        state_after: ticket.state,
        outcome: "denied",
        denial_code: code,
        occurred_at: occurred_at,
        request_ref: fetch_string(attrs, :request_ref) || ref("req"),
        binding_result: Map.get(details, :binding_result) || "denied"
      })

    %HandoffAuditEvent{}
    |> HandoffAuditEvent.changeset(attrs)
    |> Repo.insert()
  end

  defp audit_attrs(type, ticket, attrs) do
    %{
      event_id: ref("hae"),
      event_type: Atom.to_string(type),
      handoff_ref: ticket.audit_correlation_ref,
      ticket_ref: ticket.ticket_ref,
      state_before: Map.get(attrs, :state_before),
      state_after: Map.get(attrs, :state_after),
      outcome: Map.fetch!(attrs, :outcome),
      denial_code: Map.get(attrs, :denial_code),
      occurred_at: Map.fetch!(attrs, :occurred_at),
      route_id: ticket.target_route_id,
      intent_kind: ticket.intent_kind,
      intent_ref: ticket.intent_ref,
      source_session_ref: ticket.source_session_ref,
      projected_session_ref: Map.get(attrs, :projected_session_ref),
      session_version_before: ticket.expected_session_version,
      session_version_after: Map.get(attrs, :session_version_after),
      assurance_after: Map.get(attrs, :assurance_after),
      authn_methods_after: %{"methods" => Map.get(attrs, :authn_methods_after, [])},
      binding_result: Map.get(attrs, :binding_result),
      request_ref: Map.fetch!(attrs, :request_ref),
      actor_kind: "backend",
      metadata: %{"handoff_transport" => "phoenix_token"}
    }
  end

  defp default_projected_authority(attrs, session_ref, session_version, now) do
    subject_ref = fetch_string!(attrs, :subject_ref)
    org_id = fetch_string!(attrs, :org_id)

    %{
      "session_ref" => session_ref,
      "subject_ref" => subject_ref,
      "org_id" => org_id,
      "state" => "active",
      "assurance_level" => fetch_string(attrs, :required_assurance_level) || "mfa",
      "authn_methods" => ["password", "totp"],
      "authenticated_at" => DateTime.to_iso8601(now),
      "last_seen_at" => DateTime.to_iso8601(now),
      "idle_expires_at" => DateTime.to_iso8601(DateTime.add(now, 1800, :second)),
      "absolute_expires_at" => DateTime.to_iso8601(DateTime.add(now, 43_200, :second)),
      "session_version" => session_version,
      "as_of" => DateTime.to_iso8601(now)
    }
  end

  defp atomize_known_authority(authority) when is_map(authority) do
    authority
    |> atomize_keys()
    |> update_atom(:state)
    |> update_atom(:assurance_level)
    |> update_authn_methods()
  end

  defp atomize_known_authority(_authority), do: %{}

  defp atomize_keys(map), do: Map.new(map, fn {key, value} -> {normalize_key(key), value} end)

  defp update_atom(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) -> Map.put(map, key, String.to_existing_atom(value))
      _other -> map
    end
  rescue
    ArgumentError -> map
  end

  defp update_authn_methods(map) do
    case Map.get(map, :authn_methods) do
      methods when is_list(methods) ->
        Map.put(map, :authn_methods, Enum.map(methods, &string_to_existing_atom/1))

      _other ->
        map
    end
  end

  defp string_to_existing_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  rescue
    ArgumentError -> value
  end

  defp string_to_existing_atom(value), do: value

  defp safe_details(ticket) do
    %{
      handoff_ref: ticket.audit_correlation_ref,
      handoff_state: ticket.state,
      handoff_kind: "session_handoff",
      binding_kind: ticket.binding_kind,
      intent_kind: ticket.intent_kind,
      route_binding: "manifest_known",
      ticket_expires_at: DateTime.to_iso8601(ticket.expires_at)
    }
  end

  defp denial(code, details) do
    Denial.new(
      reason: :step_up_required,
      code: code,
      message: "Additional authentication is required.",
      details: DenialCodes.sanitize_details(details)
    )
  end

  defp expired?(ticket, evaluated_at),
    do:
      DateTime.compare(ticket.expires_at, DateTime.truncate(evaluated_at, :second)) in [:lt, :eq]

  defp digest(value), do: "sha256:" <> Base.encode16(:crypto.hash(:sha256, value), case: :lower)

  defp ref(prefix) do
    suffix = 10 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    "#{prefix}:#{suffix}"
  end

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp next_version(attrs), do: fetch_integer!(attrs, :expected_session_version) + 1

  defp normalize_attrs(attrs) when is_list(attrs), do: attrs |> Map.new() |> normalize_attrs()

  defp normalize_attrs(attrs) when is_map(attrs),
    do: Map.new(attrs, fn {key, value} -> {normalize_key(key), value} end)

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: String.to_atom(key)
  defp normalize_key(key), do: key

  defp fetch_string!(attrs, key), do: Map.fetch!(attrs, key) |> to_string()

  defp fetch_string(attrs, key) do
    case Map.get(attrs, key) do
      nil -> nil
      value -> to_string(value)
    end
  end

  defp fetch_integer!(attrs, key) do
    case Map.fetch!(attrs, key) do
      value when is_integer(value) -> value
      value when is_binary(value) -> String.to_integer(value)
    end
  end

  defp fetch_integer(attrs, key) do
    case Map.get(attrs, key) do
      value when is_integer(value) -> value
      value when is_binary(value) -> String.to_integer(value)
      _other -> nil
    end
  end

  defp fetch_atom(attrs, key) do
    case Map.get(attrs, key) do
      value when is_atom(value) -> value
      value when is_binary(value) -> String.to_existing_atom(value)
      _other -> nil
    end
  rescue
    ArgumentError -> nil
  end

  defp fetch_datetime(attrs, key) do
    case Map.get(attrs, key) do
      %DateTime{} = datetime ->
        DateTime.truncate(datetime, :second)

      value when is_binary(value) ->
        DateTime.from_iso8601(value) |> elem(1) |> DateTime.truncate(:second)

      _other ->
        nil
    end
  rescue
    _error -> nil
  end
end
