defmodule Crosswake.Companions.Sigra.StepUpCeremony do
  @moduledoc """
  Shared Sigra step-up ceremony decision core.

  This module is pure and transport-agnostic. It turns route-auth evaluator
  outcomes into allow, challenge, or deny decisions while host callbacks own
  persistence, challenge UI routing, and session mutation.
  """

  alias Crosswake.Companions.Sigra.Contracts.AuthContext
  alias Crosswake.Companions.Sigra.Contracts.SessionAuthorityLane
  alias Crosswake.Compatibility.Finding
  alias Crosswake.Companions.Sigra.Evaluator
  alias Crosswake.Companions.Sigra.StepUp
  alias Crosswake.Manifest.Types.RouteEntry

  @challengeable_codes [
    "auth.step_up.insufficient_assurance",
    "auth.step_up.stale_auth"
  ]

  @spec evaluate_or_issue(RouteEntry.t(), AuthContext.t() | nil, keyword()) ::
          {:allow, map()}
          | {:challenge, StepUp.StepUpIntentRecord.t(), StepUp.StepUpChallenge.t()}
          | {:deny, Finding.t()}
  def evaluate_or_issue(%RouteEntry{} = route, auth_context, opts \\ []) do
    evaluator_result =
      Keyword.get_lazy(opts, :evaluator_result, fn ->
        Evaluator.evaluate_route_auth(route, auth_context, opts)
      end)

    case evaluator_result do
      {:allow, %{facts: facts}} ->
        {:allow, facts}

      {:allow, result} ->
        {:allow, %{result: result}}

      {:deny, %Finding{axis: :auth, code: code} = finding}
      when code in @challengeable_codes ->
        issue_challenge(route, auth_context, finding, opts)

      {:deny, %Finding{axis: :auth} = finding} ->
        {:deny, finding}
    end
  end

  defp issue_challenge(route, auth_context, finding, opts) do
    case Keyword.fetch(opts, :issue_intent) do
      {:ok, issue_intent} when is_function(issue_intent, 1) ->
        issue_intent.(issue_attrs(route, auth_context, finding, opts))
        |> normalize_issue_result()

      _missing ->
        {:deny, finding}
    end
  end

  defp normalize_issue_result(
         {:ok,
          %{
            intent: %StepUp.StepUpIntentRecord{} = intent,
            challenge: %StepUp.StepUpChallenge{} = challenge
          }}
       ) do
    {:challenge, intent, challenge}
  end

  # Open Question 1 resolved: host issue_intent error contract is {:error, Finding.t()}.
  # Task 3 updates the host callers (step_up_plug.ex / step_up_on_mount.ex) to match.
  defp normalize_issue_result({:error, %Finding{axis: :auth} = finding}), do: {:deny, finding}

  defp normalize_issue_result(_other) do
    {:deny,
     %Finding{
       axis: :auth,
       code: "auth.step_up_intent.projection_failed",
       message: "route requires stronger or fresher backend authentication context",
       details: %{}
     }}
  end

  defp issue_attrs(%RouteEntry{} = route, auth_context, %Finding{axis: :auth} = finding, opts) do
    lane = authority_lane(auth_context)

    %{
      source_route_id: Keyword.get(opts, :source_route_id, route.id),
      return_route_id: Keyword.get(opts, :return_route_id, route.id),
      subject_ref: lane && lane.subject_ref,
      org_id: lane && lane.org_id,
      source_session_ref: lane && lane.session_ref,
      expected_session_version:
        Keyword.get(opts, :expected_session_version) || (lane && lane.session_version),
      required_assurance_level: route.auth_min_level || :mfa,
      required_auth_posture: route.auth_posture || :strict_recent,
      # T-137-06: MUST read finding.details["max_auth_age_seconds"] — dropping this lookup
      # silently removes the step-up max-age constraint (Elevation of Privilege regression).
      max_auth_age_seconds:
        route.requires_recent_auth || Map.get(finding.details, "max_auth_age_seconds") || 300,
      challenge_kind: Keyword.get(opts, :challenge_kind, :host_confirm_password),
      route_denial_code: finding.code,
      request_ref: Keyword.get(opts, :request_ref)
    }
  end

  defp authority_lane(%AuthContext{session_authority_lane: %SessionAuthorityLane{} = lane}),
    do: lane

  defp authority_lane(_auth_context), do: nil
end
