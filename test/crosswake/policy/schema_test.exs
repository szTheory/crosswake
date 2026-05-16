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
      assert [
               id: "library",
               runtime: :live_view,
               offline: :cached_read_only,
               cache_contract: "lesson_library_v1"
             ] =
               Schema.validate!([
                 id: "library",
                 runtime: :live_view,
                 offline: :cached_read_only,
                 cache_contract: :lesson_library_v1
               ])

      assert [
               id: "study-session",
               runtime: :offline_island,
               offline: :local_first,
               island_contract: "study_session_v1"
             ] =
               Schema.validate!([
                 id: "study-session",
                 runtime: :offline_island,
                 offline: :local_first,
                 island_contract: "study_session_v1"
               ])
    end
  end
end
