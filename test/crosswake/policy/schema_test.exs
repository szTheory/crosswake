defmodule Crosswake.Policy.SchemaTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Schema

  describe "validate!/1" do
    test "requires both id and runtime" do
      assert_raise NimbleOptions.ValidationError, ~r/required :id option not found/, fn ->
        Schema.validate!([runtime: :live_view])
      end

      assert_raise NimbleOptions.ValidationError, ~r/required :runtime option not found/, fn ->
        Schema.validate!([id: "home"])
      end
    end

    test "rejects reserved and unknown runtime values" do
      assert_raise NimbleOptions.ValidationError, ~r/reserved future extension point/, fn ->
        Schema.validate!([id: "camera", runtime: :adapter])
      end

      assert_raise NimbleOptions.ValidationError, ~r/expected one of/, fn ->
        Schema.validate!([id: "camera", runtime: :webview])
      end
    end

    test "accepts explicit cache and island contract identifiers" do
      validated =
        Schema.validate!([
          id: "library",
          runtime: :live_view,
          offline: :cached_read_only,
          cache_contract: :lesson_library_v1
        ])

      assert validated[:id] == "library"
      assert validated[:runtime] == :live_view
      assert validated[:offline] == :cached_read_only
      assert validated[:cache_contract] == "lesson_library_v1"

      validated =
        Schema.validate!([
          id: "study-session",
          runtime: :offline_island,
          offline: :local_first,
          island_contract: "study_session_v1"
        ])

      assert validated[:id] == "study-session"
      assert validated[:runtime] == :offline_island
      assert validated[:offline] == :local_first
      assert validated[:island_contract] == "study_session_v1"
    end
  end
end
