defmodule Crosswake.Shell.DenialTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.Denial

  describe "reasons/0" do
    test "includes :notification_open_denied" do
      assert :notification_open_denied in Denial.reasons()
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
  end
end
