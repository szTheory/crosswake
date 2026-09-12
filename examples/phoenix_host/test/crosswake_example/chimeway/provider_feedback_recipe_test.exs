unless Code.ensure_loaded?(Oban.Job) do
  defmodule Oban.Job do
    @moduledoc false
    defstruct args: %{}
  end
end

unless Code.ensure_loaded?(Oban.Worker) do
  defmodule Oban.Worker do
    @moduledoc false

    @callback perform(Oban.Job.t()) :: term()

    defmacro __using__(_opts) do
      quote do
        @behaviour Oban.Worker
      end
    end
  end
end

defmodule MyApp.Notifications do
  @moduledoc false

  def put_provider_feedback_opts(opts),
    do: Process.put({__MODULE__, :provider_feedback_opts}, opts)

  def authenticated_provider_feedback_opts!(_feedback),
    do: Process.get({__MODULE__, :provider_feedback_opts}, [])
end

defmodule CrosswakeExample.Chimeway.ProviderFeedbackRecipeTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Crosswake.Companions.Chimeway.Contracts
  alias Crosswake.Companions.Chimeway.Redaction
  alias CrosswakeExample.Chimeway.Registry
  alias CrosswakeExample.Chimeway.TokenBinding
  alias CrosswakeExample.Chimeway.TokenBindingEvent
  alias CrosswakeExample.Repo

  @readme Path.expand("../../../README.md", __DIR__)
  @app_identity_ref "com.example.crosswake.recipe"

  setup_all do
    recipe = provider_feedback_recipe!()
    Code.compile_string(recipe, @readme)
    {:ok, recipe: recipe}
  end

  setup do
    on_exit(fn -> Process.delete({MyApp.Notifications, :provider_feedback_opts}) end)
    :ok
  end

  test "README recipe compiles and executes advisory feedback through both public boundaries",
       %{recipe: recipe} do
    refute recipe =~ "Contracts.ProviderFeedback.from_attrs"
    assert recipe =~ "Redaction.feedback_from_provider_attrs"
    assert recipe =~ "Registry.apply_provider_feedback"
    assert recipe =~ "authenticated_provider_feedback_opts!"

    correlation_id = unique_ref("advisory")
    MyApp.Notifications.put_provider_feedback_opts([])

    assert :ok =
             perform(%{
               "feedback" =>
                 feedback_attrs(:delivery_accepted, correlation_id: correlation_id)
             })

    assert %TokenBindingEvent{
             event_type: :feedback,
             feedback_event: :delivery_accepted,
             proof_class: :advisory
           } = Repo.get_by!(TokenBindingEvent, correlation_id: correlation_id)
  end

  test "README recipe invalidates only the exact authenticated session binding" do
    fingerprint = unique_ref("shared_fingerprint")
    ctx = session_context()
    other_ctx = session_context()

    assert {:ok, %{binding: target}} = bind(ctx, fingerprint, "shared-token", @app_identity_ref)

    assert {:ok, %{binding: control}} =
             bind(other_ctx, fingerprint, "shared-token", "com.example.crosswake.control")

    MyApp.Notifications.put_provider_feedback_opts(session_scope(ctx, target.binding_ref))

    assert :ok =
             perform(%{
               "feedback" =>
                 feedback_attrs("Unregistered",
                   token_ref: "shared-token",
                   token_fingerprint: fingerprint
                 )
             })

    assert %TokenBinding{state: :revoked, reason: :provider_unregistered} =
             Repo.get_by!(TokenBinding, binding_ref: target.binding_ref)

    assert %TokenBinding{state: :active} =
             Repo.get_by!(TokenBinding, binding_ref: control.binding_ref)
  end

  test "README recipe denies stale and mismatched authority without mutating the binding" do
    fingerprint = unique_ref("deny_fingerprint")
    ctx = session_context()
    assert {:ok, %{binding: target}} = bind(ctx, fingerprint, unique_ref("token"), @app_identity_ref)

    exact = session_scope(ctx, target.binding_ref)

    mismatches = [
      Keyword.put(exact, :binding_ref, unique_ref("wrong_binding")),
      Keyword.put(exact, :installation_ref, unique_ref("wrong_installation")),
      Keyword.put(exact, :app_identity_ref, "com.example.crosswake.wrong"),
      Keyword.put(exact, :session_version, ctx.session_version + 1),
      Keyword.put(exact, :authenticated_context, session_context())
    ]

    for scope <- mismatches do
      MyApp.Notifications.put_provider_feedback_opts(scope)

      assert {:error, :no_active_bindings} =
               perform(%{
                 "feedback" =>
                   feedback_attrs("Unregistered", token_fingerprint: fingerprint)
               })

      assert %TokenBinding{state: :active} =
               Repo.get_by!(TokenBinding, binding_ref: target.binding_ref)
    end
  end

  test "README recipe accepts installation authority without session fields and recursively sanitizes evidence" do
    raw_token = unique_ref("raw_token_must_not_escape")
    provider_payload = unique_ref("provider_payload_must_not_escape")
    ctx = installation_context()
    fingerprint = unique_ref("installation_fingerprint")

    assert {:ok, %{binding: target}} = bind(ctx, fingerprint, unique_ref("token"), @app_identity_ref)

    MyApp.Notifications.put_provider_feedback_opts(
      authenticated_context: ctx,
      binding_ref: target.binding_ref,
      installation_ref: ctx.installation_ref,
      app_identity_ref: @app_identity_ref
    )

    attrs =
      feedback_attrs("Unregistered",
        token_fingerprint: fingerprint,
        metadata: %{
          safe_detail: :kept,
          nested: %{token: raw_token, provider_payload: %{body: provider_payload}},
          list: [%{raw_token: raw_token}],
          keyword: [authorization: provider_payload]
        }
      )

    assert {:ok, feedback} = Redaction.feedback_from_provider_attrs(attrs)
    assert feedback.metadata == %{safe_detail: :kept}
    refute inspect(Contracts.to_map(feedback)) =~ raw_token
    refute inspect(Contracts.to_map(feedback)) =~ provider_payload

    assert :ok = perform(%{"feedback" => attrs})

    assert %TokenBinding{state: :revoked} =
             Repo.get_by!(TokenBinding, binding_ref: target.binding_ref)

    durable =
      Repo.all(from event in TokenBindingEvent, where: event.binding_ref == ^target.binding_ref)
      |> inspect()

    refute durable =~ raw_token
    refute durable =~ provider_payload
  end

  defp provider_feedback_recipe! do
    readme = File.read!(@readme)

    case Regex.run(
           ~r/Provider feedback handling example:\s+```elixir\n(?<recipe>.*?)\n```/s,
           readme,
           capture: ["recipe"]
         ) do
      [recipe] -> recipe
      _ -> flunk("README provider-feedback recipe block is missing")
    end
  end

  defp session_context do
    %{
      subject_scope: :subject_session,
      subject_ref: unique_ref("subject"),
      org_ref: unique_ref("org"),
      installation_ref: unique_ref("installation"),
      session_ref: unique_ref("session"),
      session_version: 1,
      actor_kind: :backend,
      correlation_id: unique_ref("correlation")
    }
  end

  defp installation_context do
    session_context()
    |> Map.put(:subject_scope, :subject_installation)
    |> Map.put(:session_ref, nil)
    |> Map.put(:session_version, nil)
  end

  defp bind(ctx, fingerprint, token_ref, app_identity_ref) do
    Registry.bind_or_rotate(
      ctx,
      %{
        token_ref: token_ref,
        token_fingerprint: fingerprint,
        provider: :apns,
        platform: :ios,
        environment: :production,
        installation_ref: ctx.installation_ref,
        notification_status: :granted,
        observed_at: "2026-09-12T12:00:00Z",
        metadata: %{}
      },
      app_identity_ref: app_identity_ref
    )
  end

  defp session_scope(ctx, binding_ref) do
    [
      authenticated_context: ctx,
      binding_ref: binding_ref,
      installation_ref: ctx.installation_ref,
      app_identity_ref: @app_identity_ref,
      session_ref: ctx.session_ref,
      session_version: ctx.session_version
    ]
  end

  defp feedback_attrs(reason, overrides) do
    overrides
    |> Map.new()
    |> Map.merge(%{
      provider: :apns,
      platform: :ios,
      environment: :production,
      reason: reason,
      occurred_at: "2026-09-12T12:01:00Z"
    })
  end

  defp perform(args) do
    apply(MyApp.Workers.ChimewayProviderFeedbackWorker, :perform, [%Oban.Job{args: args}])
  end

  defp unique_ref(prefix),
    do: "#{prefix}_#{System.unique_integer([:positive, :monotonic])}"
end
