defmodule Crosswake.Shell.DenialTest do
  use ExUnit.Case, async: true

  alias Crosswake.Compatibility
  alias Crosswake.Compatibility.Finding
  alias Crosswake.Shell.Denial

  describe "reasons/0" do
    test "includes :notification_open_denied" do
      assert :notification_open_denied in Denial.reasons()
    end

    test "includes :shell_unreachable as the 14th closed reason (Phase 154, D-12)" do
      assert :shell_unreachable in Denial.reasons()
      assert length(Denial.reasons()) == 14
    end
  end

  describe "new/1" do
    test "can create a denial with :notification_open_denied reason" do
      denial = Denial.new(
        reason: :notification_open_denied,
        code: "notification.open.expired",
        message: "The notification has expired."
      )

      assert denial.reason == :notification_open_denied
      assert denial.code == "notification.open.expired"
      assert denial.message == "The notification has expired."
    end

    test ":shell_unreachable defaults details.failing_moment to :hook_not_wired when absent (D-12)" do
      denial =
        Denial.new(
          reason: :shell_unreachable,
          code: "shell_unreachable",
          message: "No shell answered."
        )

      assert denial.reason == :shell_unreachable
      assert denial.details == %{failing_moment: :hook_not_wired}
    end

    test ":shell_unreachable accepts all four documented failing_moment variants (D-12)" do
      for moment <- [:no_transport, :reply_timeout, :transport_error, :hook_not_wired] do
        denial =
          Denial.new(
            reason: :shell_unreachable,
            code: "shell_unreachable",
            message: "No shell answered.",
            details: %{failing_moment: moment}
          )

        assert denial.details.failing_moment == moment
      end
    end

    test ":shell_unreachable does not overwrite an explicitly supplied failing_moment" do
      denial =
        Denial.new(
          reason: :shell_unreachable,
          code: "shell_unreachable",
          message: "No shell answered.",
          details: %{failing_moment: :transport_error, extra: "kept"}
        )

      assert denial.details == %{failing_moment: :transport_error, extra: "kept"}
    end
  end

  describe "Compatibility.finding_to_denial/2 never yields :shell_unreachable (D-15)" do
    @known_axes [
      :route,
      :active_route,
      :entry,
      :notification_open,
      :origin,
      :bridge_command,
      :capability_registry,
      :capability_version,
      :pack_version,
      :auth,
      :some_unrecognized_future_axis
    ]

    test "no known or unknown axis produces a :shell_unreachable denial" do
      for axis <- @known_axes do
        finding = %Finding{axis: axis, message: "synthetic finding for #{inspect(axis)}"}
        denial = Compatibility.finding_to_denial(finding)

        refute denial.reason == :shell_unreachable,
               "finding_to_denial/2 must never produce :shell_unreachable — it has no Finding axis " <>
                 "and no companion path (D-15), but axis #{inspect(axis)} did"
      end
    end
  end
end
