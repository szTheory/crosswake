defmodule CrosswakeExample.Chimeway.Registry do
  @moduledoc """
  Synchronous Phoenix-owned Chimeway token binding lifecycle API.

  Implements TOKN-03 lifecycle transitions via named `Ecto.Multi` operations:
  - `bind_or_rotate/3` — initial bind, same-token refresh, or token rotation
  - `revoke_for_logout/2` — session-scoped logout revocation
  - `revoke_for_session_revocation/2` — session-ref/version-keyed revocation
  - `revoke_for_permission_loss/2` — notification permission revocation
  - `apply_provider_feedback/2` — APNs/FCM provider feedback normalization
  - `prune_stale/1` — staleness pruning without history deletion

  All lifecycle changes are atomic: the mutable binding projection and
  append-only audit event are updated in a single `Ecto.Multi` transaction.
  Chimeway telemetry fires only after `Repo.transaction/1` returns `{:ok, changes}`.

  Token possession does not choose subject, org, or session identity.
  Backend context supplies those fields exclusively.

  Raw APNs/FCM token material is never persisted. Only `token_ref` and
  `token_fingerprint` cross into binding rows, audit rows, or telemetry.

  Provider feedback normalizes into canonical Chimeway reasons (e.g.
  `:provider_unregistered`, `:provider_invalid_token`) without leaking
  provider-native enum values into public lifecycle state.
  """

  import Ecto.Query

  @behaviour Crosswake.Companions.Chimeway.IntentConsumer

  alias Crosswake.Companions.Chimeway.Contracts
  alias Crosswake.Companions.Chimeway.Contracts.NotificationOpenEvidence
  alias Crosswake.Companions.Chimeway.Contracts.ProviderFeedback
  alias Crosswake.Companions.Chimeway.Contracts.TokenEvidence
  alias Crosswake.Companions.Chimeway.Redaction
  alias Crosswake.Companions.Chimeway.Telemetry
  alias CrosswakeExample.Chimeway.MetadataSanitizer
  alias CrosswakeExample.Chimeway.NotificationOpenIntent
  alias CrosswakeExample.Chimeway.NotificationOpenIntentEvent
  alias CrosswakeExample.Chimeway.TokenBinding
  alias CrosswakeExample.Chimeway.TokenBindingEvent
  alias CrosswakeExample.Repo

  # ---------------------------------------------------------------------------
  # Public API — bind, refresh, rotate
  # ---------------------------------------------------------------------------

  @doc """
  Binds, refreshes, or rotates a notification token for the given backend context.

  `context` must be a backend-owned map with at minimum:
    - `:subject_scope` — `:subject_session` or `:subject_installation`
    - `:subject_ref` — backend identity ref
    - `:org_ref` — org ref
    - `:installation_ref` — installation ref (may also come from evidence)
    - `:actor_kind` — `:backend`

  For `:subject_session` scope, `context` must also include:
    - `:session_ref` — session ref
    - `:session_version` — non-negative integer session version

  `evidence` must be a `%TokenEvidence{}` struct or a safe map with:
    - `:token_ref`, `:token_fingerprint`, `:provider`, `:platform`, `:environment`,
      `:notification_status`, `:observed_at`

  Returns:
    - `{:ok, %{binding: binding, audit_event: event, result: result}}` for initial bind
    - `{:ok, %{binding: binding, audit_event: event, result: result}}` for refresh
    - `{:ok, %{binding: binding, audit_events: events, result: result}}` for rotation
    - `{:error, reason}` on validation or transaction failure
  """
  @spec bind_or_rotate(map(), TokenEvidence.t() | map(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def bind_or_rotate(context, evidence, opts \\ []) do
    with {:ok, ctx} <- validate_context(context),
         {:ok, ev} <- normalize_evidence(evidence),
         {:ok, scope} <- binding_scope(ctx, ev, opts) do
      retry_busy_transaction(fn -> do_bind_or_rotate(ctx, ev, scope, opts) end)
    end
  end

  # ---------------------------------------------------------------------------
  # Public API — revocation flows
  # ---------------------------------------------------------------------------

  @doc """
  Revokes all active `:subject_session` bindings for the backend context.

  Targets bindings where `subject_ref`, `org_ref`, and optionally `session_ref`
  match. Appends `:revoked` audit evidence in the same transaction.

  Returns:
    - `{:ok, %{bindings: bindings, audit_events: events, result: result}}`
    - `{:error, :no_active_bindings}` if no active bindings matched
    - `{:error, reason}` on transaction failure
  """
  @spec revoke_for_logout(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def revoke_for_logout(context, opts \\ []) do
    with {:ok, ctx} <- validate_context(context) do
      do_revoke_for_logout(ctx, opts)
    end
  end

  @doc """
  Revokes active bindings for a specific session ref, optionally respecting
  `session_version` so newer sessions survive revocation.

  Returns:
    - `{:ok, %{bindings: bindings, audit_events: events, result: result}}`
    - `{:error, :no_active_bindings}` if no matching active bindings
    - `{:error, reason}` on transaction failure
  """
  @spec revoke_for_session_revocation(String.t(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def revoke_for_session_revocation(session_ref, opts \\ []) when is_binary(session_ref) do
    do_revoke_for_session_revocation(session_ref, opts)
  end

  @doc """
  Revokes active bindings for the given context due to notification permission loss.

  Sets `state: :revoked, reason: :permission_denied` and
  `notification_status: :denied`. Appends `:revoked` audit evidence.

  Returns:
    - `{:ok, %{bindings: bindings, audit_events: events, result: result}}`
    - `{:error, :no_active_bindings}` if no matching active bindings
    - `{:error, reason}` on transaction failure
  """
  @spec revoke_for_permission_loss(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def revoke_for_permission_loss(context, opts \\ []) do
    with {:ok, ctx} <- validate_context(context),
         {:ok, scope} <- permission_loss_scope(ctx, opts) do
      retry_busy_transaction(fn -> do_revoke_for_permission_loss(ctx, scope, opts) end)
    end
  end

  # ---------------------------------------------------------------------------
  # Public API — provider feedback
  # ---------------------------------------------------------------------------

  @doc """
  Applies normalized provider feedback to active bindings matched by
  `token_fingerprint` (and optionally `token_ref`).

  Accepts either a `%ProviderFeedback{}` struct or raw provider attrs normalized
  through `Crosswake.Companions.Chimeway.Redaction.feedback_from_provider_attrs/1`.

  Feedback-only events (`:credentials_invalid`, `:provider_throttled`,
  `:provider_unavailable`, `:delivery_accepted`, `:delivery_failed`) write an
  audit `:feedback` row without mutating binding state.

  Invalidating events map to:
    - `:token_unregistered` → `{:revoked, :provider_unregistered}`
    - `:token_invalid` → `{:invalid, :provider_invalid_token}`
    - `:environment_mismatch` → `{:invalid, :environment_mismatch}`
    - `:app_identity_mismatch` → `{:invalid, :app_identity_mismatch}`

  Returns:
    - `{:ok, %{bindings: bindings, audit_events: events, result: result}}`
    - `{:ok, %{audit_event: event, result: result}}` for non-invalidating feedback
    - `{:error, reason}` on failure
  """
  @spec apply_provider_feedback(ProviderFeedback.t() | map(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def apply_provider_feedback(feedback, opts \\ []) do
    with {:ok, fb} <- normalize_feedback(feedback) do
      do_apply_provider_feedback(fb, opts)
    end
  end

  # ---------------------------------------------------------------------------
  # Public API — staleness pruning
  # ---------------------------------------------------------------------------

  @doc """
  Marks active bindings last seen before `stale_before:` as stale.

  Sets `state: :stale, reason: :staleness_pruned` without deleting rows.
  Appends `:stale` audit evidence in the same transaction.

  Options:
    - `:stale_before` — `DateTime` threshold (required)
    - `:subject_ref` — optional filter by subject
    - `:org_ref` — optional filter by org

  Returns:
    - `{:ok, %{bindings: bindings, audit_events: events, result: result}}`
    - `{:ok, %{bindings: [], audit_events: [], result: result}}` if no stale rows
    - `{:error, reason}` on failure
  """
  @spec prune_stale(keyword()) :: {:ok, map()} | {:error, term()}
  def prune_stale(opts \\ []) do
    do_prune_stale(opts)
  end

  # ---------------------------------------------------------------------------
  # Implementation: bind_or_rotate
  # ---------------------------------------------------------------------------

  defp do_bind_or_rotate(ctx, ev, scope, opts) do
    now = utc_now()

    same_token_query =
      from(b in TokenBinding,
        where:
          b.token_fingerprint == ^ev.token_fingerprint and
            b.provider == ^ev.provider and
            b.platform == ^ev.platform and
            b.environment == ^ev.environment and
            b.app_identity_ref == ^scope.app_identity_ref and
            b.installation_ref == ^scope.installation_ref and
            b.subject_scope == ^ctx.subject_scope and
            b.session_ref == ^scope.session_ref and
            b.session_version == ^scope.session_version and
            b.subject_ref == ^ctx.subject_ref and
            b.org_ref == ^ctx.org_ref and
            b.state == :active
      )

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:existing_same_token, fn repo, _changes ->
        {:ok, repo.one(same_token_query)}
      end)
      |> Ecto.Multi.run(:displaced_bindings, fn repo, %{existing_same_token: same} ->
        if is_nil(same) do
          displaced_query =
            from(b in TokenBinding,
              where:
                b.subject_ref == ^ctx.subject_ref and
                  b.org_ref == ^ctx.org_ref and
                  b.installation_ref == ^scope.installation_ref and
                  b.provider == ^ev.provider and
                  b.platform == ^ev.platform and
                  b.environment == ^ev.environment and
                  b.app_identity_ref == ^scope.app_identity_ref and
                  b.subject_scope == ^ctx.subject_scope and
                  b.session_version == ^scope.session_version and
                  b.state == :active
            )

          displaced_query =
            case ctx[:subject_scope] do
              :subject_session ->
                where(displaced_query, [b], b.session_ref == ^scope.session_ref)

              _ ->
                displaced_query
            end

          {:ok, repo.all(displaced_query)}
        else
          {:ok, []}
        end
      end)
      |> Ecto.Multi.run(:supersede_displaced, fn repo, %{displaced_bindings: displaced} ->
        if Enum.empty?(displaced) do
          {:ok, []}
        else
          now_dt = now
          binding_refs = Enum.map(displaced, & &1.binding_ref)

          {count, _} =
            repo.update_all(
              from(b in TokenBinding,
                where:
                  b.binding_ref in ^binding_refs and b.state == :active and
                    b.subject_ref == ^ctx.subject_ref and b.org_ref == ^ctx.org_ref and
                    b.installation_ref == ^scope.installation_ref and b.provider == ^ev.provider and
                    b.platform == ^ev.platform and b.environment == ^ev.environment and
                    b.app_identity_ref == ^scope.app_identity_ref and
                    b.session_ref == ^scope.session_ref and
                    b.session_version == ^scope.session_version
              ),
              set: [
                state: :superseded,
                reason: :token_rotated,
                superseded_at: now_dt,
                updated_at: now_dt
              ]
            )

          {:ok, count}
        end
      end)
      |> Ecto.Multi.run(:binding, fn repo,
                                     %{existing_same_token: same, displaced_bindings: displaced} ->
        if same do
          # Same-token refresh: update only mutable fields per D-17
          {_count, _rows} =
            repo.update_all(
              from(b in TokenBinding,
                where:
                  b.id == ^same.id and b.binding_ref == ^same.binding_ref and
                    b.subject_ref == ^ctx.subject_ref and b.org_ref == ^ctx.org_ref and
                    b.installation_ref == ^scope.installation_ref and b.provider == ^ev.provider and
                    b.platform == ^ev.platform and b.environment == ^ev.environment and
                    b.app_identity_ref == ^scope.app_identity_ref and
                    b.session_ref == ^scope.session_ref and
                    b.session_version == ^scope.session_version and
                    b.state == :active
              ),
              set: [
                last_seen_at: now,
                notification_status: ev.notification_status,
                app_identity_posture: ev.app_identity_posture || same.app_identity_posture,
                metadata:
                  MetadataSanitizer.sanitize(merge_metadata(same.metadata, ev.metadata || %{})),
                updated_at: now
              ]
            )

          {:ok, repo.get!(TokenBinding, same.id)}
        else
          # New binding or rotation — WR-04: use correct reason for rotation
          is_rotation = not Enum.empty?(displaced)
          reason = if is_rotation, do: :token_rotated, else: :initial_bind

          binding_attrs =
            build_binding_attrs(ctx, ev, scope, now, reason)

          changeset = TokenBinding.changeset(%TokenBinding{}, binding_attrs)
          repo.insert(changeset)
        end
      end)
      |> Ecto.Multi.run(:audit_events, fn repo, changes ->
        same = changes.existing_same_token
        binding = changes.binding
        displaced = changes.displaced_bindings

        cond do
          same ->
            # Refresh: single :observed audit row
            event_attrs =
              build_audit_attrs(
                %{
                  event_type: :observed,
                  binding_ref: binding.binding_ref,
                  token_ref: binding.token_ref,
                  token_fingerprint: binding.token_fingerprint,
                  provider: binding.provider,
                  platform: binding.platform,
                  environment: binding.environment,
                  installation_ref: binding.installation_ref,
                  subject_scope: binding.subject_scope,
                  state_before: :active,
                  state_after: :active,
                  reason: :initial_bind,
                  notification_status: ev.notification_status,
                  app_identity_posture: ev.app_identity_posture || :unknown,
                  occurred_at: now,
                  correlation_id: ev.correlation_id || ctx[:correlation_id],
                  actor_kind: :backend,
                  proof_class: :hermetic
                },
                opts
              )

            case repo.insert(TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs)) do
              {:ok, event} -> {:ok, [event]}
              {:error, changeset} -> {:error, changeset}
            end

          not Enum.empty?(displaced) ->
            # Rotation: :revoked events for displaced + :bound event for new binding
            now_dt = now

            supersede_events =
              Enum.map(displaced, fn displaced_binding ->
                build_audit_attrs(
                  %{
                    event_type: :rotated,
                    binding_ref: displaced_binding.binding_ref,
                    token_ref: displaced_binding.token_ref,
                    token_fingerprint: displaced_binding.token_fingerprint,
                    provider: displaced_binding.provider,
                    platform: displaced_binding.platform,
                    environment: displaced_binding.environment,
                    installation_ref: displaced_binding.installation_ref,
                    subject_scope: displaced_binding.subject_scope,
                    state_before: :active,
                    state_after: :superseded,
                    reason: :token_rotated,
                    notification_status: displaced_binding.notification_status,
                    app_identity_posture: displaced_binding.app_identity_posture,
                    occurred_at: now_dt,
                    correlation_id: ev.correlation_id || ctx[:correlation_id],
                    actor_kind: :backend,
                    proof_class: :hermetic
                  },
                  opts
                )
              end)

            # WR-04: rotated binding must record :token_rotated reason, not :initial_bind
            bound_event_attrs =
              build_audit_attrs(
                %{
                  event_type: :bound,
                  binding_ref: binding.binding_ref,
                  token_ref: binding.token_ref,
                  token_fingerprint: binding.token_fingerprint,
                  provider: binding.provider,
                  platform: binding.platform,
                  environment: binding.environment,
                  installation_ref: binding.installation_ref,
                  subject_scope: binding.subject_scope,
                  state_before: nil,
                  state_after: :active,
                  reason: :token_rotated,
                  notification_status: ev.notification_status,
                  app_identity_posture: ev.app_identity_posture || :unknown,
                  occurred_at: now_dt,
                  correlation_id: ev.correlation_id || ctx[:correlation_id],
                  actor_kind: :backend,
                  proof_class: :hermetic
                },
                opts
              )

            all_event_attrs = supersede_events ++ [bound_event_attrs]

            events =
              Enum.reduce_while(all_event_attrs, [], fn event_attrs, acc ->
                case repo.insert(TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs)) do
                  {:ok, event} -> {:cont, [event | acc]}
                  {:error, changeset} -> {:halt, {:error, changeset}}
                end
              end)

            case events do
              {:error, changeset} -> {:error, changeset}
              events -> {:ok, Enum.reverse(events)}
            end

          true ->
            # Initial bind: single :bound audit event
            event_attrs =
              build_audit_attrs(
                %{
                  event_type: :bound,
                  binding_ref: binding.binding_ref,
                  token_ref: binding.token_ref,
                  token_fingerprint: binding.token_fingerprint,
                  provider: binding.provider,
                  platform: binding.platform,
                  environment: binding.environment,
                  installation_ref: binding.installation_ref,
                  subject_scope: binding.subject_scope,
                  state_before: nil,
                  state_after: :active,
                  reason: :initial_bind,
                  notification_status: ev.notification_status,
                  app_identity_posture: ev.app_identity_posture || :unknown,
                  occurred_at: now,
                  correlation_id: ev.correlation_id || ctx[:correlation_id],
                  actor_kind: :backend,
                  proof_class: :hermetic
                },
                opts
              )

            case repo.insert(TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs)) do
              {:ok, event} -> {:ok, [event]}
              {:error, changeset} -> {:error, changeset}
            end
        end
      end)
      |> Repo.transaction()

    case result do
      {:ok,
       %{
         binding: binding,
         audit_events: [event],
         existing_same_token: same,
         displaced_bindings: []
       }}
      when not is_nil(same) ->
        # Refresh
        result_struct = build_binding_result(:bound, binding, event)

        Telemetry.execute(
          [:crosswake, :notification, :token, :observed],
          %{},
          telemetry_meta(binding, event)
        )

        {:ok, %{binding: binding, audit_event: event, result: result_struct}}

      {:ok, %{binding: binding, audit_events: [event], displaced_bindings: []}} ->
        # Initial bind
        result_struct = build_binding_result(:bound, binding, event)

        Telemetry.execute(
          [:crosswake, :notification, :token, :bound],
          %{},
          telemetry_meta(binding, event)
        )

        {:ok, %{binding: binding, audit_event: event, result: result_struct}}

      {:ok, %{binding: binding, audit_events: events}} ->
        # Rotation
        result_struct = build_binding_result(:rotated, binding, List.last(events))

        Telemetry.execute(
          [:crosswake, :notification, :token, :rotated],
          %{},
          telemetry_meta(binding, List.last(events))
        )

        {:ok, %{binding: binding, audit_events: events, result: result_struct}}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Implementation: revoke_for_logout
  # ---------------------------------------------------------------------------

  defp do_revoke_for_logout(ctx, opts) do
    # WR-03: require session_ref to prevent silent widening to subject+org-wide revocation.
    # Callers wanting to revoke all sessions for a subject/org must opt in explicitly.
    case ctx[:session_ref] do
      session_ref when is_binary(session_ref) and byte_size(session_ref) > 0 ->
        do_revoke_for_logout_scoped(ctx, session_ref, opts)

      _ ->
        {:error, {:session_ref, :required}}
    end
  end

  defp do_revoke_for_logout_scoped(ctx, session_ref, opts) do
    now = utc_now()

    query =
      from(b in TokenBinding,
        where:
          b.subject_ref == ^ctx.subject_ref and
            b.org_ref == ^ctx.org_ref and
            b.session_ref == ^session_ref and
            b.state == :active
      )

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:active_bindings, fn repo, _changes ->
        {:ok, repo.all(query)}
      end)
      |> Ecto.Multi.run(:revoke, fn repo, %{active_bindings: bindings} ->
        if Enum.empty?(bindings) do
          {:error, :no_active_bindings}
        else
          binding_refs = Enum.map(bindings, & &1.binding_ref)

          {count, _} =
            repo.update_all(
              from(b in TokenBinding,
                where: b.binding_ref in ^binding_refs and b.state == :active
              ),
              set: [
                state: :revoked,
                reason: :logout_revoked,
                revoked_at: now,
                updated_at: now
              ]
            )

          {:ok, count}
        end
      end)
      |> Ecto.Multi.run(:bindings, fn repo, %{active_bindings: bindings} ->
        binding_refs = Enum.map(bindings, & &1.binding_ref)
        # WR-02: order_by so telemetry zip aligns with events (which are sorted by binding_ref)
        {:ok,
         repo.all(
           from(b in TokenBinding,
             where: b.binding_ref in ^binding_refs,
             order_by: b.binding_ref
           )
         )}
      end)
      |> Ecto.Multi.run(:audit_events, fn repo, %{active_bindings: pre_bindings} ->
        insert_revocation_events(repo, pre_bindings, :logout_revoked, now, ctx, opts)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{bindings: bindings, audit_events: events}} ->
        result_struct =
          Contracts.new_binding_result!(%{
            status: :revoked,
            binding_ref: List.first(bindings, %{binding_ref: "bulk"}).binding_ref,
            state: :revoked,
            reason: :logout_revoked
          })

        # WR-02: key events by binding_ref for correct per-binding telemetry attribution
        events_by_ref = Map.new(events, &{&1.binding_ref, &1})

        for binding <- bindings,
            event = events_by_ref[binding.binding_ref],
            not is_nil(event) do
          Telemetry.execute(
            [:crosswake, :notification, :token, :revoked],
            %{},
            telemetry_meta(binding, event)
          )
        end

        {:ok, %{bindings: bindings, audit_events: events, result: result_struct}}

      {:error, :revoke, :no_active_bindings, _changes} ->
        {:error, :no_active_bindings}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Implementation: revoke_for_session_revocation
  # ---------------------------------------------------------------------------

  defp do_revoke_for_session_revocation(session_ref, opts) do
    now = utc_now()
    session_version = opts[:session_version]

    query =
      from(b in TokenBinding,
        where: b.session_ref == ^session_ref and b.state == :active
      )

    # If session_version supplied, only revoke rows with version <= session_version
    # so newer session versions survive (D-21)
    query =
      case session_version do
        version when is_integer(version) ->
          where(query, [b], is_nil(b.session_version) or b.session_version <= ^version)

        _ ->
          query
      end

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:active_bindings, fn repo, _changes ->
        {:ok, repo.all(query)}
      end)
      |> Ecto.Multi.run(:revoke, fn repo, %{active_bindings: bindings} ->
        if Enum.empty?(bindings) do
          {:error, :no_active_bindings}
        else
          binding_refs = Enum.map(bindings, & &1.binding_ref)

          {count, _} =
            repo.update_all(
              from(b in TokenBinding,
                where: b.binding_ref in ^binding_refs and b.state == :active
              ),
              set: [
                state: :revoked,
                reason: :session_revoked,
                revoked_at: now,
                updated_at: now
              ]
            )

          {:ok, count}
        end
      end)
      |> Ecto.Multi.run(:bindings, fn repo, %{active_bindings: bindings} ->
        binding_refs = Enum.map(bindings, & &1.binding_ref)
        # WR-02: order_by so telemetry zip aligns with events (which are sorted by binding_ref)
        {:ok,
         repo.all(
           from(b in TokenBinding,
             where: b.binding_ref in ^binding_refs,
             order_by: b.binding_ref
           )
         )}
      end)
      |> Ecto.Multi.run(:audit_events, fn repo, %{active_bindings: pre_bindings} ->
        ctx = %{subject_ref: nil, org_ref: nil, correlation_id: opts[:correlation_id]}
        insert_revocation_events(repo, pre_bindings, :session_revoked, now, ctx, opts)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{bindings: bindings, audit_events: events}} ->
        result_struct =
          Contracts.new_binding_result!(%{
            status: :revoked,
            binding_ref: List.first(bindings, %{binding_ref: "bulk"}).binding_ref,
            state: :revoked,
            reason: :session_revoked
          })

        # WR-02: key events by binding_ref for correct per-binding telemetry attribution
        events_by_ref = Map.new(events, &{&1.binding_ref, &1})

        for binding <- bindings,
            event = events_by_ref[binding.binding_ref],
            not is_nil(event) do
          Telemetry.execute(
            [:crosswake, :notification, :token, :revoked],
            %{},
            telemetry_meta(binding, event)
          )
        end

        {:ok, %{bindings: bindings, audit_events: events, result: result_struct}}

      {:error, :revoke, :no_active_bindings, _changes} ->
        {:error, :no_active_bindings}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Implementation: revoke_for_permission_loss
  # ---------------------------------------------------------------------------

  defp do_revoke_for_permission_loss(ctx, scope, opts) do
    now = utc_now()

    query =
      from(b in TokenBinding,
        where:
          b.binding_ref == ^scope.binding_ref and
            b.subject_ref == ^ctx.subject_ref and
            b.org_ref == ^ctx.org_ref and
            b.subject_scope == ^ctx.subject_scope and
            b.installation_ref == ^scope.installation_ref and
            b.provider == ^scope.provider and
            b.platform == ^scope.platform and
            b.environment == ^scope.environment and
            b.app_identity_ref == ^scope.app_identity_ref and
            b.session_ref == ^scope.session_ref and
            b.session_version == ^scope.session_version and
            b.state == :active
      )

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:active_bindings, fn repo, _changes ->
        {:ok, repo.all(query)}
      end)
      |> Ecto.Multi.run(:revoke, fn repo, %{active_bindings: bindings} ->
        if Enum.empty?(bindings) do
          {:error, :no_active_bindings}
        else
          binding_refs = Enum.map(bindings, & &1.binding_ref)

          {count, _} =
            repo.update_all(
              from(b in TokenBinding,
                where:
                  b.binding_ref in ^binding_refs and b.binding_ref == ^scope.binding_ref and
                    b.subject_ref == ^ctx.subject_ref and b.org_ref == ^ctx.org_ref and
                    b.subject_scope == ^ctx.subject_scope and
                    b.installation_ref == ^scope.installation_ref and
                    b.provider == ^scope.provider and
                    b.platform == ^scope.platform and b.environment == ^scope.environment and
                    b.app_identity_ref == ^scope.app_identity_ref and
                    b.session_ref == ^scope.session_ref and
                    b.session_version == ^scope.session_version and
                    b.state == :active
              ),
              set: [
                state: :revoked,
                reason: :permission_denied,
                notification_status: :denied,
                revoked_at: now,
                updated_at: now
              ]
            )

          {:ok, count}
        end
      end)
      |> Ecto.Multi.run(:bindings, fn repo, %{active_bindings: bindings} ->
        binding_refs = Enum.map(bindings, & &1.binding_ref)
        # WR-02: order_by so telemetry zip aligns with events (which are sorted by binding_ref)
        {:ok,
         repo.all(
           from(b in TokenBinding,
             where: b.binding_ref in ^binding_refs,
             order_by: b.binding_ref
           )
         )}
      end)
      |> Ecto.Multi.run(:audit_events, fn repo, %{active_bindings: pre_bindings} ->
        insert_permission_loss_events(repo, pre_bindings, now, ctx, opts)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{bindings: bindings, audit_events: events}} ->
        result_struct =
          Contracts.new_binding_result!(%{
            status: :revoked,
            binding_ref: List.first(bindings, %{binding_ref: "bulk"}).binding_ref,
            state: :revoked,
            reason: :permission_denied
          })

        # WR-02: key events by binding_ref for correct per-binding telemetry attribution
        events_by_ref = Map.new(events, &{&1.binding_ref, &1})

        for binding <- bindings,
            event = events_by_ref[binding.binding_ref],
            not is_nil(event) do
          Telemetry.execute(
            [:crosswake, :notification, :token, :revoked],
            %{},
            telemetry_meta(binding, event)
          )
        end

        {:ok, %{bindings: bindings, audit_events: events, result: result_struct}}

      {:error, :revoke, :no_active_bindings, _changes} ->
        {:error, :no_active_bindings}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Implementation: apply_provider_feedback
  # ---------------------------------------------------------------------------

  defp do_apply_provider_feedback(fb, opts) do
    now = utc_now()
    {binding_state, binding_reason} = feedback_to_lifecycle(fb.feedback_event)

    case binding_state do
      nil ->
        # Non-invalidating feedback: audit-only
        do_feedback_audit_only(fb, now, opts)

      _ ->
        do_feedback_invalidate(fb, binding_state, binding_reason, now, opts)
    end
  end

  defp do_feedback_audit_only(fb, now, opts) do
    event_attrs =
      build_audit_attrs(
        %{
          event_type: :feedback,
          binding_ref: fb.token_ref || "unknown",
          token_ref: fb.token_ref,
          token_fingerprint: fb.token_fingerprint,
          provider: fb.provider,
          platform: fb.platform,
          environment: fb.environment,
          feedback_event: fb.feedback_event,
          state_before: nil,
          state_after: nil,
          reason: nil,
          notification_status: nil,
          app_identity_posture: fb.app_identity_posture,
          occurred_at: now,
          correlation_id: fb.correlation_id,
          actor_kind: :provider,
          proof_class: :advisory
        },
        opts
      )

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:audit_event, fn repo, _changes ->
        repo.insert(TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs))
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{audit_event: event}} ->
        result_struct =
          Contracts.new_binding_result!(%{
            status: :bound,
            binding_ref: fb.token_ref || "unknown",
            state: :active,
            reason: :initial_bind
          })

        Telemetry.execute(
          [:crosswake, :notification, :provider, :feedback],
          %{},
          %{
            provider: fb.provider,
            platform: fb.platform,
            environment: fb.environment,
            feedback_event: fb.feedback_event,
            proof_class: :advisory,
            correlation_id: fb.correlation_id
          }
        )

        {:ok, %{audit_event: event, result: result_struct}}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  # CR-01: Builds a provider/platform/environment-scoped query for the given
  # feedback struct. Fails closed when no token selector is present — avoids
  # unbounded fan-out across the whole active set.
  defp feedback_target_query(fb) do
    fp = fb.token_fingerprint
    tr = fb.token_ref

    cond do
      is_binary(fp) and byte_size(fp) > 0 ->
        {:ok,
         from(b in TokenBinding,
           where:
             b.state == :active and b.token_fingerprint == ^fp and
               b.provider == ^fb.provider and b.platform == ^fb.platform and
               b.environment == ^fb.environment
         )}

      is_binary(tr) and byte_size(tr) > 0 ->
        {:ok,
         from(b in TokenBinding,
           where:
             b.state == :active and b.token_ref == ^tr and
               b.provider == ^fb.provider and b.platform == ^fb.platform and
               b.environment == ^fb.environment
         )}

      true ->
        {:error, :feedback_missing_token_selector}
    end
  end

  defp do_feedback_invalidate(fb, binding_state, binding_reason, now, opts) do
    with {:ok, query} <- feedback_target_query(fb) do
      result =
        Ecto.Multi.new()
        |> Ecto.Multi.run(:active_bindings, fn repo, _changes ->
          {:ok, repo.all(query)}
        end)
        |> Ecto.Multi.run(:invalidate, fn repo, %{active_bindings: bindings} ->
          # WR-01: fail instead of reporting fabricated success on zero matches
          if Enum.empty?(bindings) do
            {:error, :no_active_bindings}
          else
            binding_refs = Enum.map(bindings, & &1.binding_ref)

            terminal_ts_field =
              case binding_state do
                :revoked -> [revoked_at: now]
                :invalid -> [invalidated_at: now]
                :stale -> [stale_at: now]
                _ -> []
              end

            {count, _} =
              repo.update_all(
                from(b in TokenBinding,
                  where: b.binding_ref in ^binding_refs and b.state == :active
                ),
                set:
                  [
                    state: binding_state,
                    reason: binding_reason,
                    updated_at: now
                  ] ++ terminal_ts_field
              )

            {:ok, count}
          end
        end)
        |> Ecto.Multi.run(:bindings, fn repo, %{active_bindings: bindings} ->
          binding_refs = Enum.map(bindings, & &1.binding_ref)
          # WR-02: order by binding_ref so telemetry zip aligns with events
          {:ok,
           repo.all(
             from(b in TokenBinding,
               where: b.binding_ref in ^binding_refs,
               order_by: b.binding_ref
             )
           )}
        end)
        |> Ecto.Multi.run(:audit_events, fn repo, %{active_bindings: pre_bindings} ->
          event_type =
            case binding_state do
              :revoked -> :revoked
              _ -> :invalidated
            end

          # WR-02: sort pre_bindings by binding_ref to match :bindings re-query order
          sorted_pre_bindings = Enum.sort_by(pre_bindings, & &1.binding_ref)

          events =
            Enum.reduce_while(sorted_pre_bindings, [], fn pre_binding, acc ->
              event_attrs =
                build_audit_attrs(
                  %{
                    event_type: event_type,
                    binding_ref: pre_binding.binding_ref,
                    token_ref: pre_binding.token_ref,
                    token_fingerprint: pre_binding.token_fingerprint,
                    provider: pre_binding.provider,
                    platform: pre_binding.platform,
                    environment: pre_binding.environment,
                    installation_ref: pre_binding.installation_ref,
                    subject_scope: pre_binding.subject_scope,
                    state_before: :active,
                    state_after: binding_state,
                    reason: binding_reason,
                    feedback_event: fb.feedback_event,
                    notification_status: pre_binding.notification_status,
                    app_identity_posture:
                      fb.app_identity_posture || pre_binding.app_identity_posture,
                    occurred_at: now,
                    correlation_id: fb.correlation_id,
                    actor_kind: :provider,
                    proof_class: :advisory
                  },
                  opts
                )

              case repo.insert(TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs)) do
                {:ok, event} -> {:cont, [event | acc]}
                {:error, changeset} -> {:halt, {:error, changeset}}
              end
            end)

          case events do
            {:error, changeset} -> {:error, changeset}
            events -> {:ok, Enum.reverse(events)}
          end
        end)
        |> Repo.transaction()

      case result do
        {:ok, %{bindings: bindings, audit_events: events}} ->
          telemetry_event =
            case binding_state do
              :revoked -> [:crosswake, :notification, :token, :revoked]
              _ -> [:crosswake, :notification, :token, :invalidated]
            end

          # WR-02: key events by binding_ref for correct per-binding telemetry attribution
          events_by_ref = Map.new(events, &{&1.binding_ref, &1})

          for binding <- bindings,
              event = events_by_ref[binding.binding_ref],
              not is_nil(event) do
            Telemetry.execute(
              telemetry_event,
              %{},
              telemetry_meta(binding, event)
            )
          end

          # Also emit provider feedback telemetry
          Telemetry.execute(
            [:crosswake, :notification, :provider, :feedback],
            %{},
            %{
              provider: fb.provider,
              platform: fb.platform,
              environment: fb.environment,
              feedback_event: fb.feedback_event,
              proof_class: :advisory,
              correlation_id: fb.correlation_id
            }
          )

          result_struct =
            Contracts.new_binding_result!(%{
              status: :invalidated,
              binding_ref: List.first(bindings).binding_ref,
              state: binding_state,
              reason: binding_reason
            })

          {:ok, %{bindings: bindings, audit_events: events, result: result_struct}}

        {:error, :invalidate, :no_active_bindings, _changes} ->
          {:error, :no_active_bindings}

        {:error, _step, reason, _changes} ->
          {:error, reason}
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Implementation: prune_stale
  # ---------------------------------------------------------------------------

  defp do_prune_stale(opts) do
    stale_before = opts[:stale_before]

    unless stale_before do
      raise ArgumentError, "prune_stale/1 requires :stale_before option"
    end

    now = utc_now()

    query =
      from(b in TokenBinding,
        where: b.state == :active and b.last_seen_at < ^stale_before
      )

    query =
      case opts[:subject_ref] do
        subject_ref when is_binary(subject_ref) ->
          where(query, [b], b.subject_ref == ^subject_ref)

        _ ->
          query
      end

    query =
      case opts[:org_ref] do
        org_ref when is_binary(org_ref) ->
          where(query, [b], b.org_ref == ^org_ref)

        _ ->
          query
      end

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:active_bindings, fn repo, _changes ->
        {:ok, repo.all(query)}
      end)
      |> Ecto.Multi.run(:mark_stale, fn repo, %{active_bindings: bindings} ->
        if Enum.empty?(bindings) do
          {:ok, 0}
        else
          binding_refs = Enum.map(bindings, & &1.binding_ref)

          {count, _} =
            repo.update_all(
              from(b in TokenBinding,
                where: b.binding_ref in ^binding_refs and b.state == :active
              ),
              set: [
                state: :stale,
                reason: :staleness_pruned,
                stale_at: now,
                updated_at: now
              ]
            )

          {:ok, count}
        end
      end)
      |> Ecto.Multi.run(:bindings, fn repo, %{active_bindings: bindings} ->
        binding_refs = Enum.map(bindings, & &1.binding_ref)
        # WR-02: order_by so telemetry zip aligns with events (which are sorted by binding_ref)
        {:ok,
         repo.all(
           from(b in TokenBinding,
             where: b.binding_ref in ^binding_refs,
             order_by: b.binding_ref
           )
         )}
      end)
      |> Ecto.Multi.run(:audit_events, fn repo, %{active_bindings: pre_bindings} ->
        if Enum.empty?(pre_bindings) do
          {:ok, []}
        else
          # WR-02: sort by binding_ref so event order matches the order_by :bindings re-query
          sorted_pre_bindings = Enum.sort_by(pre_bindings, & &1.binding_ref)

          events =
            Enum.reduce_while(sorted_pre_bindings, [], fn pre_binding, acc ->
              event_attrs =
                build_audit_attrs(
                  %{
                    event_type: :stale,
                    binding_ref: pre_binding.binding_ref,
                    token_ref: pre_binding.token_ref,
                    token_fingerprint: pre_binding.token_fingerprint,
                    provider: pre_binding.provider,
                    platform: pre_binding.platform,
                    environment: pre_binding.environment,
                    installation_ref: pre_binding.installation_ref,
                    subject_scope: pre_binding.subject_scope,
                    state_before: :active,
                    state_after: :stale,
                    reason: :staleness_pruned,
                    notification_status: pre_binding.notification_status,
                    app_identity_posture: pre_binding.app_identity_posture,
                    occurred_at: now,
                    correlation_id: opts[:correlation_id],
                    actor_kind: :maintenance,
                    proof_class: :hermetic
                  },
                  opts
                )

              case repo.insert(TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs)) do
                {:ok, event} -> {:cont, [event | acc]}
                {:error, changeset} -> {:halt, {:error, changeset}}
              end
            end)

          case events do
            {:error, changeset} -> {:error, changeset}
            events -> {:ok, Enum.reverse(events)}
          end
        end
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{bindings: bindings, audit_events: events}} ->
        # WR-02: key events by binding_ref for correct per-binding telemetry attribution
        events_by_ref = Map.new(events, &{&1.binding_ref, &1})

        for binding <- bindings,
            event = events_by_ref[binding.binding_ref],
            not is_nil(event) do
          Telemetry.execute(
            [:crosswake, :notification, :token, :stale],
            %{},
            telemetry_meta(binding, event)
          )
        end

        result_struct =
          Contracts.new_binding_result!(%{
            status: :stale,
            binding_ref: List.first(bindings, %{binding_ref: "bulk_prune"}).binding_ref,
            state: :stale,
            reason: :staleness_pruned
          })

        {:ok, %{bindings: bindings, audit_events: events, result: result_struct}}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Implementation: Notification Open Intent
  # ---------------------------------------------------------------------------

  @doc """
  Issues a one-time notification open intent.
  """
  def issue_notification_open_intent(attrs) do
    intent_changeset = NotificationOpenIntent.changeset(%NotificationOpenIntent{}, attrs)

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:intent, intent_changeset)
      |> Ecto.Multi.run(:event, fn repo, %{intent: intent} ->
        event_changeset =
          NotificationOpenIntentEvent.changeset(%NotificationOpenIntentEvent{}, %{
            open_intent_id: intent.id,
            event_type: "issued",
            occurred_at: utc_now(),
            details: %{}
          })

        repo.insert(event_changeset)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{intent: intent, event: event}} ->
        {:ok, %{intent: intent, event: event}}

      {:error, _step, changeset, _changes} ->
        {:error, changeset}
    end
  end

  @doc """
  Consumes a notification open intent, returning its resolution state.
  """
  @impl Crosswake.Companions.Chimeway.IntentConsumer
  def consume_intent(%NotificationOpenEvidence{} = evidence) do
    now = utc_now()

    intent_query =
      from(i in NotificationOpenIntent,
        where: i.open_ref == ^evidence.open_ref
      )

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:intent, fn repo, _changes ->
        case repo.one(intent_query) do
          nil -> {:error, :not_found}
          intent -> {:ok, intent}
        end
      end)
      |> Ecto.Multi.run(:validate, fn _repo, %{intent: intent} ->
        cond do
          intent.state != "issued" ->
            {:error, :replayed}

          DateTime.compare(intent.expires_at, now) == :lt ->
            {:error, :expired}

          intent.binding_ref != evidence.binding_ref ->
            {:error, :binding_mismatch}

          true ->
            {:ok, :valid}
        end
      end)
      |> Ecto.Multi.run(:binding, fn repo, %{intent: intent} ->
        binding_query =
          from(b in TokenBinding,
            where: b.binding_ref == ^intent.binding_ref and b.state == :active
          )

        case repo.one(binding_query) do
          nil -> {:error, :revoked}
          binding -> {:ok, binding}
        end
      end)
      |> Ecto.Multi.update(:consume, fn %{intent: intent} ->
        NotificationOpenIntent.changeset(intent, %{
          state: "consumed",
          consumed_at: now
        })
      end)
      |> Ecto.Multi.run(:event, fn repo, %{consume: intent} ->
        event_changeset =
          NotificationOpenIntentEvent.changeset(%NotificationOpenIntentEvent{}, %{
            open_intent_id: intent.id,
            event_type: "consumed",
            occurred_at: now,
            details: %{}
          })

        repo.insert(event_changeset)
      end)
      |> Repo.transaction()

    case result do
      {:ok, %{consume: intent}} ->
        {:ok,
         Contracts.new_open_resolution!(%{
           open_ref: evidence.open_ref,
           state: :valid,
           route_id: intent.route_id,
           action_ref: intent.action_ref || "tap",
           resolved_at: now
         })}

      {:error, :intent, :not_found, _changes} ->
        {:ok,
         Contracts.new_open_resolution!(%{
           open_ref: evidence.open_ref,
           state: :invalid,
           resolved_at: now
         })}

      {:error, :binding, :revoked, _changes} ->
        {:ok,
         Contracts.new_open_resolution!(%{
           open_ref: evidence.open_ref,
           state: :binding_revoked,
           resolved_at: now
         })}

      {:error, :validate, reason, _changes} ->
        {:ok,
         Contracts.new_open_resolution!(%{
           open_ref: evidence.open_ref,
           state: reason,
           resolved_at: now
         })}
    end
  end

  # ---------------------------------------------------------------------------
  # Helper: context validation
  # ---------------------------------------------------------------------------

  defp validate_context(context) when is_map(context) do
    with {:ok, subject_ref} <- required_string(context, :subject_ref),
         {:ok, org_ref} <- required_string(context, :org_ref) do
      ctx = %{
        subject_ref: subject_ref,
        org_ref: org_ref,
        subject_scope: Map.get(context, :subject_scope, :subject_installation),
        installation_ref: Map.get(context, :installation_ref),
        session_ref: Map.get(context, :session_ref),
        session_version: Map.get(context, :session_version),
        actor_kind: Map.get(context, :actor_kind, :backend),
        correlation_id: Map.get(context, :correlation_id)
      }

      {:ok, ctx}
    end
  end

  defp validate_context(_context), do: {:error, :invalid_context}

  # The app identity ref is the APNs topic/app identity supplied by the authenticated
  # host command. It is part of the durable authority scope, not token metadata.
  defp binding_scope(ctx, ev, opts) do
    with {:ok, app_identity_ref} <- required_option_string(opts, :app_identity_ref),
         {:ok, installation_ref} <-
           required_string(
             %{installation_ref: ev.installation_ref || ctx.installation_ref},
             :installation_ref
           ) do
      {:ok,
       %{
         installation_ref: installation_ref,
         app_identity_ref: app_identity_ref,
         session_ref: ctx.session_ref,
         session_version: ctx.session_version
       }}
    end
  end

  defp permission_loss_scope(ctx, opts) do
    with {:ok, binding_ref} <- required_option_string(opts, :binding_ref),
         {:ok, installation_ref} <- required_option_string(opts, :installation_ref),
         {:ok, provider} <- required_option(opts, :provider),
         {:ok, platform} <- required_option(opts, :platform),
         {:ok, environment} <- required_option(opts, :environment),
         {:ok, app_identity_ref} <- required_option_string(opts, :app_identity_ref) do
      {:ok,
       %{
         binding_ref: binding_ref,
         installation_ref: installation_ref,
         provider: provider,
         platform: platform,
         environment: environment,
         app_identity_ref: app_identity_ref,
         session_ref: ctx.session_ref,
         session_version: ctx.session_version
       }}
    end
  end

  # ---------------------------------------------------------------------------
  # Helper: evidence normalization
  # ---------------------------------------------------------------------------

  defp normalize_evidence(%TokenEvidence{} = ev), do: {:ok, ev}

  defp normalize_evidence(attrs) when is_map(attrs) do
    with :ok <- reject_raw_token_keys(attrs) do
      ev = %TokenEvidence{
        provider: attrs[:provider],
        platform: attrs[:platform],
        environment: attrs[:environment],
        installation_ref: attrs[:installation_ref],
        token_ref: attrs[:token_ref],
        token_fingerprint: attrs[:token_fingerprint],
        notification_status: attrs[:notification_status],
        observed_at: attrs[:observed_at] || now_iso8601(),
        app_identity_posture: attrs[:app_identity_posture],
        correlation_id: attrs[:correlation_id],
        metadata: MetadataSanitizer.sanitize(attrs[:metadata] || %{})
      }

      {:ok, ev}
    end
  end

  defp normalize_evidence(_ev), do: {:error, :invalid_evidence}

  # ---------------------------------------------------------------------------
  # Helper: feedback normalization
  # ---------------------------------------------------------------------------

  defp normalize_feedback(%ProviderFeedback{} = fb), do: {:ok, fb}

  defp normalize_feedback(attrs) when is_map(attrs) do
    Redaction.feedback_from_provider_attrs(attrs)
  end

  defp normalize_feedback(_fb), do: {:error, :invalid_feedback}

  # ---------------------------------------------------------------------------
  # Helper: feedback event to lifecycle mapping
  # ---------------------------------------------------------------------------

  defp feedback_to_lifecycle(:token_unregistered), do: {:revoked, :provider_unregistered}
  defp feedback_to_lifecycle(:token_invalid), do: {:invalid, :provider_invalid_token}
  defp feedback_to_lifecycle(:environment_mismatch), do: {:invalid, :environment_mismatch}
  defp feedback_to_lifecycle(:app_identity_mismatch), do: {:invalid, :app_identity_mismatch}
  # Non-invalidating feedback events
  defp feedback_to_lifecycle(:credentials_invalid), do: {nil, nil}
  defp feedback_to_lifecycle(:provider_throttled), do: {nil, nil}
  defp feedback_to_lifecycle(:provider_unavailable), do: {nil, nil}
  defp feedback_to_lifecycle(:delivery_accepted), do: {nil, nil}
  defp feedback_to_lifecycle(:delivery_failed), do: {nil, nil}
  defp feedback_to_lifecycle(_other), do: {nil, nil}

  # ---------------------------------------------------------------------------
  # Helper: binding attrs builder
  # ---------------------------------------------------------------------------

  # WR-04: accept reason so rotation callers can pass :token_rotated
  defp build_binding_attrs(ctx, ev, scope, now, reason) do
    %{
      binding_ref: unique_ref("bnd"),
      subject_scope: ctx.subject_scope,
      subject_ref: ctx.subject_ref,
      org_ref: ctx.org_ref,
      session_ref: ctx[:session_ref],
      session_version: ctx[:session_version],
      installation_ref: scope.installation_ref,
      provider: ev.provider,
      platform: ev.platform,
      environment: ev.environment,
      app_identity_posture: ev.app_identity_posture || :unknown,
      app_identity_ref: scope.app_identity_ref,
      token_ref: ev.token_ref,
      token_fingerprint: ev.token_fingerprint,
      notification_status: ev.notification_status,
      state: :active,
      reason: reason,
      bound_at: now,
      last_seen_at: now,
      audit_correlation_ref: ctx[:correlation_id] || unique_ref("corr"),
      metadata: MetadataSanitizer.sanitize(ev.metadata || %{})
    }
  end

  # ---------------------------------------------------------------------------
  # Helper: audit event attrs builder
  # ---------------------------------------------------------------------------

  defp build_audit_attrs(attrs, _opts) do
    # Drop nil state fields to avoid changeset issues
    base = %{
      event_ref: unique_ref("evt"),
      event_type: attrs[:event_type],
      binding_ref: attrs[:binding_ref],
      token_ref: attrs[:token_ref],
      token_fingerprint: attrs[:token_fingerprint],
      provider: attrs[:provider],
      platform: attrs[:platform],
      environment: attrs[:environment],
      installation_ref: attrs[:installation_ref],
      subject_scope: attrs[:subject_scope],
      state_after: attrs[:state_after],
      reason: attrs[:reason],
      feedback_event: attrs[:feedback_event],
      notification_status: attrs[:notification_status],
      app_identity_posture: attrs[:app_identity_posture],
      occurred_at: attrs[:occurred_at] || utc_now(),
      correlation_id: attrs[:correlation_id],
      actor_kind: attrs[:actor_kind] || :backend,
      proof_class: attrs[:proof_class] || :hermetic,
      metadata: MetadataSanitizer.sanitize(attrs[:metadata] || %{})
    }

    # Only include state_before if not nil (optional field in schema)
    case attrs[:state_before] do
      nil -> base
      state_before -> Map.put(base, :state_before, state_before)
    end
  end

  # ---------------------------------------------------------------------------
  # Helper: revocation audit event insertion
  # ---------------------------------------------------------------------------

  defp insert_revocation_events(repo, pre_bindings, reason, now, ctx, opts) do
    # WR-02: sort by binding_ref so event order matches the order_by :bindings re-query
    sorted_pre_bindings = Enum.sort_by(pre_bindings, & &1.binding_ref)

    events =
      Enum.reduce_while(sorted_pre_bindings, [], fn pre_binding, acc ->
        event_attrs =
          build_audit_attrs(
            %{
              event_type: :revoked,
              binding_ref: pre_binding.binding_ref,
              token_ref: pre_binding.token_ref,
              token_fingerprint: pre_binding.token_fingerprint,
              provider: pre_binding.provider,
              platform: pre_binding.platform,
              environment: pre_binding.environment,
              installation_ref: pre_binding.installation_ref,
              subject_scope: pre_binding.subject_scope,
              state_before: :active,
              state_after: :revoked,
              reason: reason,
              notification_status: pre_binding.notification_status,
              app_identity_posture: pre_binding.app_identity_posture,
              occurred_at: now,
              correlation_id: ctx[:correlation_id],
              actor_kind: :backend,
              proof_class: :hermetic
            },
            opts
          )

        case repo.insert(TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs)) do
          {:ok, event} -> {:cont, [event | acc]}
          {:error, changeset} -> {:halt, {:error, changeset}}
        end
      end)

    case events do
      {:error, changeset} -> {:error, changeset}
      events -> {:ok, Enum.reverse(events)}
    end
  end

  defp insert_permission_loss_events(repo, pre_bindings, now, ctx, opts) do
    # WR-02: sort by binding_ref so event order matches the order_by :bindings re-query
    sorted_pre_bindings = Enum.sort_by(pre_bindings, & &1.binding_ref)

    events =
      Enum.reduce_while(sorted_pre_bindings, [], fn pre_binding, acc ->
        event_attrs =
          build_audit_attrs(
            %{
              event_type: :revoked,
              binding_ref: pre_binding.binding_ref,
              token_ref: pre_binding.token_ref,
              token_fingerprint: pre_binding.token_fingerprint,
              provider: pre_binding.provider,
              platform: pre_binding.platform,
              environment: pre_binding.environment,
              installation_ref: pre_binding.installation_ref,
              subject_scope: pre_binding.subject_scope,
              state_before: :active,
              state_after: :revoked,
              reason: :permission_denied,
              notification_status: :denied,
              app_identity_posture: pre_binding.app_identity_posture,
              occurred_at: now,
              correlation_id: ctx[:correlation_id],
              actor_kind: :backend,
              proof_class: :hermetic
            },
            opts
          )

        case repo.insert(TokenBindingEvent.changeset(%TokenBindingEvent{}, event_attrs)) do
          {:ok, event} -> {:cont, [event | acc]}
          {:error, changeset} -> {:halt, {:error, changeset}}
        end
      end)

    case events do
      {:error, changeset} -> {:error, changeset}
      events -> {:ok, Enum.reverse(events)}
    end
  end

  # ---------------------------------------------------------------------------
  # Helper: binding result constructor
  # ---------------------------------------------------------------------------

  defp build_binding_result(status, binding, event) do
    Contracts.new_binding_result!(%{
      status: status,
      binding_ref: binding.binding_ref,
      token_ref: binding.token_ref,
      token_fingerprint: binding.token_fingerprint,
      state: binding.state,
      reason: binding.reason,
      event_ref: event && event.event_ref,
      correlation_id: binding.audit_correlation_ref
    })
  end

  # ---------------------------------------------------------------------------
  # Helper: telemetry metadata builder
  # ---------------------------------------------------------------------------

  defp telemetry_meta(binding, event) do
    %{
      provider: binding.provider,
      platform: binding.platform,
      environment: binding.environment,
      state: binding.state,
      reason: binding.reason,
      notification_status: binding.notification_status,
      app_identity_posture: binding.app_identity_posture,
      subject_scope: binding.subject_scope,
      proof_class: event && event.proof_class,
      correlation_id: binding.audit_correlation_ref
    }
  end

  # ---------------------------------------------------------------------------
  # Helper: validators
  # ---------------------------------------------------------------------------

  defp required_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, {key, :required}}
    end
  end

  defp required_option_string(opts, key) do
    case opts[key] do
      value when is_binary(value) and byte_size(value) > 0 -> {:ok, value}
      _ -> {:error, {key, :required}}
    end
  end

  defp required_option(opts, key) do
    case opts[key] do
      nil -> {:error, {key, :required}}
      value -> {:ok, value}
    end
  end

  # SQLite serializes concurrent writes in the example host. Preserve the same
  # exact-CAS semantics as PostgreSQL while retrying only transient local lock
  # contention, so a lifecycle command never becomes a process crash.
  defp retry_busy_transaction(fun, attempts \\ 3)

  defp retry_busy_transaction(fun, attempts) do
    fun.()
  rescue
    error in Exqlite.Error ->
      if attempts > 0 and String.contains?(Exception.message(error), "Database busy") do
        Process.sleep((4 - attempts) * 10)
        retry_busy_transaction(fun, attempts - 1)
      else
        reraise error, __STACKTRACE__
      end
  end

  defp reject_raw_token_keys(attrs) do
    forbidden = [:token, :raw_token, :device_token, :registration_token, :apns_token, :fcm_token]

    case Enum.find(forbidden, &Map.has_key?(attrs, &1)) do
      nil -> :ok
      key -> {:error, {key, :raw_token_field_forbidden}}
    end
  end

  # ---------------------------------------------------------------------------
  # Helper: metadata merge
  # ---------------------------------------------------------------------------

  defp merge_metadata(existing, incoming) do
    Map.merge(existing || %{}, incoming || %{})
  end

  # ---------------------------------------------------------------------------
  # Helpers: refs, timestamps
  # ---------------------------------------------------------------------------

  defp unique_ref(prefix) do
    suffix = 8 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    "#{prefix}:#{suffix}"
  end

  defp utc_now, do: DateTime.utc_now() |> DateTime.truncate(:second)

  defp now_iso8601, do: utc_now() |> DateTime.to_iso8601()
end
