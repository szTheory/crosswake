defmodule Crosswake.Policy.SchemaTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Schema

  describe "validate!/1" do
    test "requires both id and runtime" do
      assert_raise NimbleOptions.ValidationError, ~r/id/, fn ->
        Schema.validate!([runtime: :live_view])
      end

      assert_raise NimbleOptions.ValidationError, ~r/runtime/, fn ->
        Schema.validate!([id: "home"])
      end
    end

    test "rejects reserved and unknown runtime values" do
      assert_raise NimbleOptions.ValidationError, ~r/runtime/, fn ->
        Schema.validate!([id: "camera", runtime: :adapter])
      end

      assert_raise NimbleOptions.ValidationError, ~r/runtime/, fn ->
        Schema.validate!([id: "camera", runtime: :webview])
      end
    end
  end
end
