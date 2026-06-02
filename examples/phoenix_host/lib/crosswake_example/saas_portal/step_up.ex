defmodule CrosswakeExample.SaaSPortal.StepUp do
  @moduledoc """
  Example-host Sigra step-up issue, challenge, consume, cancel, and revoke workflow.

  The signed locator is only a low-sensitivity pointer. Authority comes from the
  server-side intent row and the projected `SessionAuthorityLane`.
  """

  import Ecto.Query

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Contracts.AuthContext
  alias Crosswake.Companions.Sigra.DenialCodes
  alias Crosswake.Companions.Sigra.StepUp, as: SigraStepUp
  alias Crosswake.Manifest
  alias Crosswake.Shell.Denial
  alias CrosswakeExample.Repo
  alias CrosswakeExample.Router
  alias CrosswakeExample.SaaSPortal.StepUpAuditEvent
  alias CrosswakeExample.SaaSPortal.StepUpIntent

  @salt "crosswake.sigra.step_up.v1"
  @secret "crosswake-example-sigra-step-up-secret"
  @issuer "crosswake_example"
  @audience "crosswake.sigra.step_up"
  @typ "crosswake.sigra.step_up.v1"
  @version "1"
  @ttl_seconds 300
  @max_age_seconds 600

  def issue(attrs) when is_map(attrs) or is_list(attrs) do
    attrs = normalize_attrs(attrs)

    with :ok <- reject_return_to(attrs),
         {:ok, source_route} <- fetch_route(fetch_string(attrs, :source_route_id)),
         {:ok, return_route} <- fetch_route(fetch_string(attrs, :return_route_id)),
         {:ok, issue_data} <- build_issue_data(attrs, source_route, return_route) do
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:intent, StepUpIntent.changeset(%StepUpIntent{}, issue_data.intent))
      |> Ecto.Multi.insert(
        :audit_event,
        StepUpAuditEvent.changeset(%StepUpAuditEvent{}, issue_data.audit_event)
      )
      |> Repo.transaction()
      |> case do
        {:ok, %{intent: intent}} ->
          {:ok,
           %{
             locator: issue_data.locator,
             signed_locator: issue_data.signed_locator,
             intent: intent,
             step_up_intent_ref: issue_data.step_up_intent_ref
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

  def challenge(signed_locator, attrs \\ %{}) when is_binary(signed_locator) do
    attrs = normalize_attrs(attrs)
    now = fetch_datetime(attrs, :evaluated_at) || now()

    with {:ok, payload} <- verify_locator(signed_locator),
         {:ok, locator} <- SigraStepUp.new_step_up_intent_locator(payload),
         {:ok, intent} <- fetch_intent(locator.intent_ref, digest(signed_locator)),
         :ok <- validate_challengeable(locator, intent, attrs, now) do
      query =
        from(row in StepUpIntent,
          where:
            row.id == ^intent.id and row.state == "issued" and is_nil(row.consumed_at) and
              is_nil(row.canceled_at) and is_nil(row.revoked_at) and row.expires_at > ^now
        )

      Ecto.Multi.new()
      |> Ecto.Multi.update_all(:challenge, query,
        set: [state: "challenged", challenged_at: now, updated_at: now]
      )
      |> Ecto.Multi.run(:intent, fn repo, %{challenge: {count, _}} ->
        if count == 1, do: {:ok, repo.get!(StepUpIntent, intent.id)}, else: {:error, :stale}
      end)
      |> Ecto.Multi.insert(:audit_event, fn %{intent: challenged_intent} ->
        StepUpAuditEvent.changeset(
          %StepUpAuditEvent{},
          audit_attrs(:challenge, challenged_intent, %{
            state_before: "issued",
            state_after: "challenged",
            outcome: "allowed",
            occurred_at: now,
            request_ref: fetch_string(attrs, :request_ref) || ref("req"),
            binding_result: "matched"
          })
        )
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{intent: challenged_intent}} ->
          SigraStepUp.new_step_up_challenge(%{
            challenge_ref: challenged_intent.audit_correlation_ref,
            intent_ref: challenged_intent.audit_correlation_ref,
            challenge_kind: String.to_atom(challenged_intent.challenge_kind),
            challenge_route_id: challenged_intent.source_route_id,
            return_route_id: challenged_intent.return_route_id,
            required_assurance_level:
              String.to_existing_atom(challenged_intent.required_assurance_level),
            max_auth_age_seconds: challenged_intent.max_auth_age_seconds,
            issued_at: challenged_intent.issued_at,
            expires_at: challenged_intent.expires_at,
            message: "Additional authentication is required.",
            support_ref: challenged_intent.audit_correlation_ref
          })

        {:error, _step, _reason, _changes} ->
          {:error, denial("auth.step_up_intent.invalid_intent", safe_details(intent))}
      end
    else
      {:deny, code, details} -> {:error, denial(code, details)}
      {:error, {:deny, code, details}} -> {:error, denial(code, details)}
      {:error, %Denial{} = denial} -> {:error, denial}
      {:error, _reason} -> {:error, denial("auth.step_up_intent.invalid_intent", %{})}
    end
  end

  def consume(signed_locator, attrs) when is_binary(signed_locator) do
    attrs = normalize_attrs(attrs)
    evaluated_at = fetch_datetime(attrs, :evaluated_at) || now()

    with {:ok, payload} <- verify_locator(signed_locator),
         {:ok, locator} <- SigraStepUp.new_step_up_intent_locator(payload),
         {:ok, intent} <- fetch_intent(locator.intent_ref, digest(signed_locator)),
         :ok <- validate_consume_request(locator, intent, attrs, evaluated_at),
         {:ok, completion} <- build_completion(intent, attrs, evaluated_at) do
      consume_intent(intent, completion, attrs, evaluated_at)
    else
      {:deny, code, details} -> {:error, denial(code, details)}
      {:error, {:deny, code, details}} -> {:error, denial(code, details)}
      {:error, %Denial{} = denial} -> {:error, denial}
      {:error, _reason} -> {:error, denial("auth.step_up_intent.invalid_intent", %{})}
    end
  end

  def consume(_signed_locator, _attrs),
    do: {:error, denial("auth.step_up_intent.missing_intent", %{})}

  def cancel(intent_ref, attrs \\ %{}) when is_binary(intent_ref) do
    transition_intent(intent_ref, :cancel, "canceled", :canceled_at, :cancellation_reason, attrs)
  end

  def revoke(intent_ref, attrs \\ %{}) when is_binary(intent_ref) do
    transition_intent(intent_ref, :revoke, "revoked", :revoked_at, :revocation_reason, attrs)
  end

  def signing_secret, do: @secret
  def signing_salt, do: @salt
  def ttl_seconds, do: @ttl_seconds

  defp build_issue_data(attrs, source_route, return_route) do
    issued_at = fetch_datetime(attrs, :issued_at) || now()

    expires_at =
      DateTime.add(issued_at, fetch_integer(attrs, :ttl_seconds) || @ttl_seconds, :second)

    intent_ref = fetch_string(attrs, :intent_ref) || ref("sup")
    step_up_intent_ref = fetch_string(attrs, :step_up_intent_ref) || ref("support:sup")
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
      "intent_ref" => intent_ref,
      "version" => @version,
      "issuer" => @issuer,
      "audience" => @audience,
      "issued_at" => DateTime.to_iso8601(issued_at),
      "expires_at" => DateTime.to_iso8601(expires_at),
      "source_route_id" => source_route.id,
      "return_route_id" => return_route.id,
      "challenge_kind" => fetch_string(attrs, :challenge_kind) || "host_confirm_password",
      "step_up_transport" => fetch_string(attrs, :step_up_transport) || "phoenix_token"
    }

    with {:ok, locator} <- SigraStepUp.new_step_up_intent_locator(payload) do
      signed_locator = Phoenix.Token.sign(@secret, @salt, payload)
      locator_digest = digest(signed_locator)

      intent = %{
        intent_ref: intent_ref,
        locator_digest: locator_digest,
        state: "issued",
        subject_ref: fetch_string!(attrs, :subject_ref),
        org_id: fetch_string!(attrs, :org_id),
        source_session_ref: fetch_string!(attrs, :source_session_ref),
        expected_session_version: fetch_integer!(attrs, :expected_session_version),
        device_ref: fetch_string(attrs, :device_ref),
        source_route_id: source_route.id,
        return_route_id: return_route.id,
        return_params: Map.get(attrs, :return_params, %{}),
        required_assurance_level: fetch_string(attrs, :required_assurance_level) || "mfa",
        required_auth_posture: fetch_string(attrs, :required_auth_posture) || "strict_recent",
        max_auth_age_seconds: fetch_integer(attrs, :max_auth_age_seconds) || 300,
        challenge_kind: payload["challenge_kind"],
        issued_at: issued_at,
        expires_at: expires_at,
        audit_correlation_ref: step_up_intent_ref,
        projected_session_ref: projected_session_ref,
        projected_session_version: projected_session_version,
        projected_authority: projected_authority
      }

      audit_event =
        audit_attrs(:issue, struct!(StepUpIntent, intent), %{
          state_before: nil,
          state_after: "issued",
          outcome: "allowed",
          occurred_at: issued_at,
          request_ref: request_ref
        })

      {:ok,
       %{
         locator: locator,
         signed_locator: signed_locator,
         intent: intent,
         audit_event: audit_event,
         step_up_intent_ref: step_up_intent_ref
       }}
    end
  rescue
    KeyError -> {:deny, "auth.step_up_intent.projection_failed", %{}}
  end

  defp consume_intent(intent, completion, attrs, evaluated_at) do
    query =
      from(row in StepUpIntent,
        where:
          row.id == ^intent.id and row.state in ["issued", "challenged"] and
            is_nil(row.consumed_at) and is_nil(row.canceled_at) and is_nil(row.revoked_at) and
            row.expires_at > ^evaluated_at
      )

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:consume, query,
      set: [state: "consumed", consumed_at: evaluated_at, updated_at: evaluated_at]
    )
    |> Ecto.Multi.run(:intent, fn repo, %{consume: {count, _}} ->
      if count == 1 do
        {:ok, repo.get!(StepUpIntent, intent.id)}
      else
        {:error, lifecycle_denial(intent, evaluated_at)}
      end
    end)
    |> Ecto.Multi.insert(:audit_event, fn %{intent: consumed_intent} ->
      StepUpAuditEvent.changeset(
        %StepUpAuditEvent{},
        audit_attrs(:consume, consumed_intent, %{
          state_before: intent.state,
          state_after: "consumed",
          outcome: "allowed",
          occurred_at: evaluated_at,
          request_ref: fetch_string(attrs, :request_ref) || ref("req"),
          projected_session_ref: completion.session_authority_lane.session_ref,
          session_version_after: completion.session_authority_lane.session_version,
          assurance_after: Atom.to_string(completion.session_authority_lane.assurance_level),
          authn_methods_after:
            Enum.map(completion.session_authority_lane.authn_methods, &to_string/1),
          binding_result: "matched"
        })
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{intent: consumed_intent}} ->
        {:ok, %{completion | step_up_intent_ref: consumed_intent.audit_correlation_ref}}

      {:error, :intent, {:deny, code, details}, _changes} ->
        append_denied_audit(intent, code, details, attrs, evaluated_at)
        {:error, denial(code, details)}

      {:error, _step, _reason, _changes} ->
        {:error, denial("auth.step_up_intent.projection_failed", safe_details(intent))}
    end
  end

  defp build_completion(intent, attrs, evaluated_at) do
    authority_attrs =
      intent.projected_authority
      |> atomize_known_authority()
      |> Map.put_new(:as_of, DateTime.to_iso8601(evaluated_at))

    with {:ok, lane} <- Contracts.new_session_authority_lane(authority_attrs),
         {:ok, renewal} <-
           SigraStepUp.new_session_renewal_instructions(%{
             renew_session?: true,
             rotate_csrf?: true,
             put_session: %{
               "crosswake_session_ref" => lane.session_ref,
               "crosswake_session_version" => lane.session_version
             },
             delete_session: ["crosswake_step_up_intent_ref", "crosswake_step_up_challenge"],
             projected_session_ref: lane.session_ref,
             projected_session_version: lane.session_version,
             live_socket_invalidation: %{reason: :step_up_completed}
           }),
         {:ok, route} <- fetch_route(intent.return_route_id),
         :ok <- prove_route_authority(route, lane, intent, evaluated_at) do
      SigraStepUp.new_step_up_completion(%{
        step_up_intent_ref: intent.audit_correlation_ref,
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
        append_denied_audit(
          intent,
          denial.code || "auth.step_up_intent.projection_failed",
          denial.details,
          attrs,
          evaluated_at
        )

        {:error, {:deny, denial.code || "auth.step_up_intent.projection_failed", denial.details}}

      {:error, _errors} ->
        append_denied_audit(
          intent,
          "auth.step_up_intent.projection_failed",
          safe_details(intent),
          attrs,
          evaluated_at
        )

        {:error, {:deny, "auth.step_up_intent.projection_failed", safe_details(intent)}}

      {:deny, code, details} ->
        append_denied_audit(intent, code, details, attrs, evaluated_at)
        {:error, {:deny, code, details}}
    end
  end

  defp transition_intent(intent_ref, event_type, state, timestamp_field, reason_field, attrs) do
    attrs = normalize_attrs(attrs)
    now = fetch_datetime(attrs, :evaluated_at) || now()
    reason = fetch_string(attrs, reason_field) || "host_#{state}"

    query =
      from(row in StepUpIntent,
        where:
          row.intent_ref == ^intent_ref and row.state in ["issued", "challenged"] and
            is_nil(row.consumed_at) and is_nil(row.canceled_at) and is_nil(row.revoked_at)
      )

    set_fields = [
      {:state, state},
      {:updated_at, now},
      {timestamp_field, now},
      {reason_field, reason}
    ]

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:transition, query, set: set_fields)
    |> Ecto.Multi.run(:intent, fn repo, %{transition: {count, _}} ->
      if count == 1,
        do: {:ok, repo.get_by!(StepUpIntent, intent_ref: intent_ref)},
        else: {:error, :stale}
    end)
    |> Ecto.Multi.insert(:audit_event, fn %{intent: intent} ->
      StepUpAuditEvent.changeset(
        %StepUpAuditEvent{},
        audit_attrs(event_type, intent, %{
          state_before: "issued",
          state_after: state,
          outcome: "allowed",
          occurred_at: now,
          request_ref: fetch_string(attrs, :request_ref) || ref("req")
        })
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{intent: intent}} ->
        {:ok, intent}

      {:error, _step, _reason, _changes} ->
        {:error, denial("auth.step_up_intent.#{state}_intent", %{})}
    end
  end

  defp validate_challengeable(locator, intent, attrs, evaluated_at) do
    cond do
      lifecycle_denied?(intent, evaluated_at) ->
        lifecycle_denial(intent, evaluated_at)

      locator.source_route_id != intent.source_route_id or
          fetch_string(attrs, :expected_source_route_id) not in [nil, intent.source_route_id] ->
        {:deny, "auth.step_up_intent.route_mismatch", safe_details(intent)}

      locator.return_route_id != intent.return_route_id ->
        {:deny, "auth.step_up_intent.route_mismatch", safe_details(intent)}

      to_string(locator.challenge_kind) != intent.challenge_kind ->
        {:deny, "auth.step_up_intent.binding_mismatch", safe_details(intent)}

      true ->
        :ok
    end
  end

  defp validate_consume_request(locator, intent, attrs, evaluated_at) do
    cond do
      lifecycle_denied?(intent, evaluated_at) ->
        lifecycle_denial(intent, evaluated_at)

      locator.source_route_id != intent.source_route_id or
        locator.return_route_id != intent.return_route_id or
          fetch_string(attrs, :expected_return_route_id) != intent.return_route_id ->
        {:deny, "auth.step_up_intent.route_mismatch", safe_details(intent)}

      to_string(locator.challenge_kind) != intent.challenge_kind or
          fetch_string(attrs, :expected_challenge_kind) != intent.challenge_kind ->
        {:deny, "auth.step_up_intent.challenge_failed", safe_details(intent)}

      fetch_string(attrs, :source_session_ref) != intent.source_session_ref or
          fetch_integer(attrs, :expected_session_version) != intent.expected_session_version ->
        {:deny, "auth.step_up_intent.binding_mismatch", safe_details(intent)}

      true ->
        :ok
    end
  end

  defp lifecycle_denied?(intent, evaluated_at) do
    intent.state == "consumed" or not is_nil(intent.consumed_at) or intent.state == "canceled" or
      not is_nil(intent.canceled_at) or intent.state == "revoked" or not is_nil(intent.revoked_at) or
      expired?(intent, evaluated_at)
  end

  defp lifecycle_denial(intent, evaluated_at) do
    cond do
      intent.state == "consumed" or not is_nil(intent.consumed_at) ->
        {:deny, "auth.step_up_intent.consumed_intent", safe_details(intent)}

      intent.state == "canceled" or not is_nil(intent.canceled_at) ->
        {:deny, "auth.step_up_intent.canceled_intent", safe_details(intent)}

      intent.state == "revoked" or not is_nil(intent.revoked_at) ->
        {:deny, "auth.step_up_intent.revoked_intent", safe_details(intent)}

      expired?(intent, evaluated_at) ->
        {:deny, "auth.step_up_intent.expired_intent", safe_details(intent)}

      true ->
        {:deny, "auth.step_up_intent.invalid_intent", %{}}
    end
  end

  defp verify_locator(nil), do: {:deny, "auth.step_up_intent.missing_intent", %{}}

  defp verify_locator(signed_locator) do
    case Phoenix.Token.verify(@secret, @salt, signed_locator, max_age: @max_age_seconds) do
      {:ok, %{} = payload} -> {:ok, payload}
      _other -> {:deny, "auth.step_up_intent.invalid_intent", %{}}
    end
  end

  defp fetch_intent(intent_ref, locator_digest) do
    case Repo.get_by(StepUpIntent, intent_ref: intent_ref, locator_digest: locator_digest) do
      nil -> {:deny, "auth.step_up_intent.invalid_intent", %{}}
      intent -> {:ok, intent}
    end
  end

  defp fetch_route(route_id) when is_binary(route_id) do
    with {:ok, %{manifest: manifest}} <- Manifest.compile(Router),
         route when not is_nil(route) <- Map.get(manifest.routes, route_id) do
      {:ok, route}
    else
      _other -> {:deny, "auth.step_up_intent.route_mismatch", %{route_binding: "manifest_known"}}
    end
  end

  defp fetch_route(_route_id), do: {:deny, "auth.step_up_intent.route_mismatch", %{}}

  defp reject_return_to(attrs) do
    if Map.has_key?(attrs, :return_to) do
      {:deny, "auth.step_up_intent.invalid_intent", %{route_binding: "manifest_known"}}
    else
      :ok
    end
  end

  defp prove_route_authority(route, lane, intent, evaluated_at) do
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
           expected_session_version: intent.projected_session_version
         ) do
      %{status: :allow} -> :ok
      %{denial: %Denial{} = denial} -> {:error, denial}
    end
  end

  defp append_denied_audit(intent, code, details, attrs, occurred_at) do
    attrs =
      audit_attrs(:deny, intent, %{
        state_before: intent.state,
        state_after: intent.state,
        outcome: "denied",
        denial_code: code,
        occurred_at: occurred_at,
        request_ref: fetch_string(attrs, :request_ref) || ref("req"),
        binding_result: Map.get(details, :binding_result) || "denied"
      })

    %StepUpAuditEvent{}
    |> StepUpAuditEvent.changeset(attrs)
    |> Repo.insert()
  end

  defp audit_attrs(type, intent, attrs) do
    %{
      event_id: ref("sua"),
      event_type: Atom.to_string(type),
      step_up_intent_ref: intent.audit_correlation_ref,
      intent_ref: intent.intent_ref,
      state_before: Map.get(attrs, :state_before),
      state_after: Map.get(attrs, :state_after),
      outcome: Map.fetch!(attrs, :outcome),
      denial_code: Map.get(attrs, :denial_code),
      occurred_at: Map.fetch!(attrs, :occurred_at),
      route_id: intent.return_route_id,
      challenge_kind: intent.challenge_kind,
      source_session_ref: intent.source_session_ref,
      projected_session_ref: Map.get(attrs, :projected_session_ref),
      session_version_before: intent.expected_session_version,
      session_version_after: Map.get(attrs, :session_version_after),
      assurance_after: Map.get(attrs, :assurance_after),
      authn_methods_after: %{"methods" => Map.get(attrs, :authn_methods_after, [])},
      binding_result: Map.get(attrs, :binding_result),
      request_ref: Map.fetch!(attrs, :request_ref),
      actor_kind: "backend",
      metadata: %{"step_up_transport" => "phoenix_token"}
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

  defp safe_details(intent) do
    %{
      step_up_intent_ref: intent.audit_correlation_ref,
      intent_state: intent.state,
      challenge_kind: intent.challenge_kind,
      route_binding: "manifest_known",
      intent_expires_at: DateTime.to_iso8601(intent.expires_at)
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

  defp expired?(intent, evaluated_at),
    do:
      DateTime.compare(intent.expires_at, DateTime.truncate(evaluated_at, :second)) in [:lt, :eq]

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
