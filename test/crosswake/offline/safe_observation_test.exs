defmodule Crosswake.Offline.SafeObservationTest do
  # Mix-task proofs can temporarily change the VM-wide cwd during parallel tests,
  # which makes this module's runtime struct lookups miss the project code path.
  use ExUnit.Case, async: false

  alias Crosswake.Offline.SafeObservation

  @valid %{
    route_id: "route-0123456789abcdef",
    runtime: :offline_island,
    lifecycle: :replayed,
    outcome: :accepted,
    denial: :none,
    measurements: %{event_count: 1},
    configuration: :configured,
    adapter_readiness: :blocked
  }

  @fields [
    :route_id,
    :runtime,
    :lifecycle,
    :outcome,
    :denial,
    :measurements,
    :configuration,
    :adapter_readiness
  ]
  @domains [
    runtime: [:offline_island],
    lifecycle: [:started, :replayed, :stopped, :blocked],
    outcome: [:accepted, :rejected, :conflict, :blocked],
    denial: [:none, :scope_inactive, :sigra_denied, :route_denied, :feature_denied],
    configuration: [:configured, :unconfigured, :ready, :blocked, :unavailable],
    adapter_readiness: [:configured, :unconfigured, :ready, :blocked, :unavailable]
  ]
  @measurement_keys [:attempt_count, :event_count, :duration_ms]

  test "rejects a trailing LF at constructor and every forged projection boundary" do
    attrs = Map.put(@valid, :route_id, @valid.route_id <> "\n")
    assert_rejected(attrs, "CW-SAFE-OBSERVATION-ROUTE", :route_id, :trailing_lf)
  end

  test "every declared enum is accepted and preserved by exact projections" do
    assert length(@domains) == 6
    assert Enum.sum(Enum.map(@domains, fn {_, values} -> length(values) end)) == 24

    for {field, values} <- @domains do
      assert MapSet.size(MapSet.new(values)) == length(values)

      for value <- values do
        assert_accepted(Map.put(@valid, field, value))
      end
    end

    # Shared names such as :blocked are intentional. Every other domain stays closed.
    vocabulary = @domains |> Enum.flat_map(&elem(&1, 1)) |> Enum.uniq()
    assert length(vocabulary) == 17

    rejected =
      for {field, allowed} <- @domains,
          value <- vocabulary,
          value not in allowed,
          do: {field, value}

    assert length(rejected) == 78

    for {field, value} <- rejected do
      assert_rejected(Map.put(@valid, field, value), rule(field), field, :cross_domain)
    end
  end

  test "every field rejects hostile encodings and wrong types across all boundaries" do
    assert length(@fields) == 8
    assert MapSet.new(@fields) == MapSet.new(Map.keys(@valid))

    for field <- @fields do
      base = if field == :route_id, do: @valid.route_id, else: "closed"
      variants = hostile_variants(base)
      assert length(variants) == 14
      assert MapSet.size(MapSet.new(variants, &elem(&1, 0))) == 14

      for {id, value} <- variants do
        assert_rejected(Map.put(@valid, field, value), rule(field), field, id)
      end
    end
  end

  test "all field keys are required atoms and unknown raw keys never get copied" do
    assert length(@fields) == 8

    for field <- @fields do
      assert_rejected(Map.delete(@valid, field), "CW-SAFE-OBSERVATION-KEY", :input, :missing)

      attrs = @valid |> Map.delete(field) |> Map.put(Atom.to_string(field), @valid[field])
      assert_rejected(attrs, "CW-SAFE-OBSERVATION-KEY", :input, :string_field)
    end

    extra_keys = [:scope_ref, "scope_ref", :unknown, 42]
    assert length(extra_keys) == 4

    for key <- extra_keys do
      attrs = Map.put(@valid, key, probe())
      assert_rejected(attrs, "CW-SAFE-OBSERVATION-KEY", :input, :extra_key)
    end
  end

  test "route grammar rejects adjacency and Unicode lookalikes with exact errors" do
    variants = [
      {:short, "route-" <> String.duplicate("a", 15)},
      {:long, "route-" <> String.duplicate("a", 17)},
      {:uppercase, "route-" <> String.duplicate("A", 16)},
      {:nonhex, "route-" <> String.duplicate("g", 16)},
      {:prefix, "x" <> @valid.route_id},
      {:suffix, @valid.route_id <> "x"},
      {:nul, @valid.route_id <> <<0>>},
      {:unicode_hex, "route-" <> String.duplicate("а", 16)},
      {:unicode_prefix, "ｒoute-0123456789abcdef"}
    ]

    assert length(variants) == 9

    for {id, value} <- variants do
      assert_rejected(Map.put(@valid, :route_id, value), rule(:route_id), :route_id, id)
    end

    assert_accepted(Map.put(@valid, :route_id, "route-" <> String.duplicate("0", 16)))
    assert_accepted(Map.put(@valid, :route_id, "route-" <> String.duplicate("f", 16)))
  end

  test "every measurement key has exact integer bounds and rejects hostile keys and values" do
    assert @measurement_keys == [:attempt_count, :event_count, :duration_ms]

    for key <- @measurement_keys do
      for value <- [0, 1_000_000] do
        assert_accepted(Map.put(@valid, :measurements, %{key => value}))
      end

      bad_values =
        [{:over, 1_000_001}, {:negative, -1}, {:float_zero, 0.0}, {:float_bound, 1_000_000.0}] ++
          Enum.reject(hostile_variants("measurement"), fn {id, _} -> id == :integer end)

      assert length(bad_values) == 17

      for {id, value} <- bad_values do
        attrs = Map.put(@valid, :measurements, %{key => value})
        assert_rejected(attrs, rule(:measurements), :measurements, id)
      end

      bad_keys = [
        {:string, Atom.to_string(key)},
        {:lf, Atom.to_string(key) <> "\n"},
        {:crlf, Atom.to_string(key) <> "\r\n"},
        {:unicode, "ｍ" <> Atom.to_string(key)},
        {:nested, {key}},
        {:unknown, :unknown},
        {:integer, 1},
        {nil, nil}
      ]

      assert length(bad_keys) == 8

      for {id, bad_key} <- bad_keys do
        # Valid siblings cannot conceal an unknown key in a nonempty map.
        attrs = Map.put(@valid, :measurements, Map.put(%{key => 1}, bad_key, probe()))
        assert_rejected(attrs, rule(:measurements), :measurements, id)
      end
    end

    assert_accepted(Map.put(@valid, :measurements, %{}))
  end

  test "top-level nonmaps and structs fail closed at every public entry point" do
    inputs = [nil, [], "", probe(), 1, 1.0, true, ~D[2026-01-01]]
    assert length(inputs) == 8

    for input <- inputs, operation <- operations() do
      assert operation.(input) ==
               {:error,
                %SafeObservation.Error{rule_id: "CW-SAFE-OBSERVATION-INPUT", path: :input}}
    end

    assert {:ok, observation} = SafeObservation.new(@valid)

    assert SafeObservation.new(observation) ==
             {:error, %SafeObservation.Error{rule_id: "CW-SAFE-OBSERVATION-INPUT", path: :input}}
  end

  test "input and measurement insertion order cannot alter any accepted projection" do
    measurements = [attempt_count: 0, event_count: 1_000_000, duration_ms: 19]
    attrs = Map.put(@valid, :measurements, Map.new(measurements))
    reversed = attrs |> Map.to_list() |> Enum.reverse() |> Map.new()
    reversed = Map.put(reversed, :measurements, measurements |> Enum.reverse() |> Map.new())
    left = assert_accepted(attrs)
    right = assert_accepted(reversed)
    assert left == right
  end

  test "constructs only declared bounded values and produces distinct exact projections" do
    assert {:ok, observation} = SafeObservation.new(@valid)

    assert {:ok, telemetry} = SafeObservation.to_telemetry(observation)

    assert telemetry == %{
             route_id: "route-0123456789abcdef",
             runtime: :offline_island,
             lifecycle: :replayed,
             outcome: :accepted,
             denial: :none,
             event_count: 1
           }

    assert {:ok, doctor} = SafeObservation.to_doctor(observation)

    assert doctor == %{
             configuration: :configured,
             adapter_readiness: :blocked
           }
  end

  test "rejects unknown keys without echoing the rejected value" do
    assert {:error, error} = SafeObservation.new(Map.put(@valid, :scope_ref, "CANARY-SCOPE"))
    assert error.rule_id == "CW-SAFE-OBSERVATION-KEY"
    refute inspect(error) =~ "CANARY"
  end

  test "revalidates every forged struct projection without echoing a canary" do
    forged_cases = [
      %{field: :route_id, value: "CANARY-ROUTE"},
      %{field: :outcome, value: :canary_outcome},
      %{field: :adapter_readiness, value: :canary_readiness},
      %{field: :measurements, value: %{event_count: "CANARY-MEASUREMENT"}},
      %{field: :measurements, value: %{event_count: 1, nested: %{canary: "CANARY-NESTED"}}},
      %{field: :extra_field, value: "CANARY-EXTRA"}
    ]

    for %{field: field, value: value} <- forged_cases do
      forged =
        case field do
          :extra_field -> Map.put(struct!(SafeObservation, @valid), field, value)
          _ -> Map.put(struct!(SafeObservation, @valid), field, value)
        end

      for projection <- [
            &SafeObservation.to_telemetry/1,
            &SafeObservation.to_logger/1,
            &SafeObservation.to_doctor/1
          ] do
        assert {:error, error} = projection.(forged)
        assert %SafeObservation.Error{rule_id: rule_id, path: path} = error
        assert is_binary(rule_id)
        assert is_atom(path)
        refute inspect(error) =~ "CANARY"
      end
    end
  end

  defp assert_accepted(attrs) do
    assert {:ok, observation} = SafeObservation.new(attrs)
    assert Map.from_struct(observation) == attrs
    assert SafeObservation.validate(observation) == {:ok, observation}

    replay = Map.take(attrs, [:route_id, :runtime, :lifecycle, :outcome, :denial])
    replay = Map.merge(replay, attrs.measurements)
    doctor = Map.take(attrs, [:configuration, :adapter_readiness])
    assert SafeObservation.to_telemetry(observation) == {:ok, replay}
    assert SafeObservation.to_logger(observation) == {:ok, replay}
    assert SafeObservation.to_doctor(observation) == {:ok, doctor}
    {observation, replay, doctor}
  end

  defp assert_rejected(attrs, rule_id, path, id) do
    expected = {:error, %SafeObservation.Error{rule_id: rule_id, path: path}}
    forged = Map.put(attrs, :__struct__, SafeObservation)

    output =
      ExUnit.CaptureLog.capture_log(fn ->
        results = [SafeObservation.new(attrs)] ++ Enum.map(projections(), & &1.(forged))
        assert length(results) == 5

        for result <- results do
          # Avoid rejected operands in assertion diagnostics, including the RED controls.
          assert result == expected, "closed rejection mismatch: #{id}/#{path}"
          assert result |> elem(1) |> Map.from_struct() == %{rule_id: rule_id, path: path}
          refute inspect(result) =~ probe()
          proof = Jason.encode!(%{case_id: id, result: "rejected", rule: rule_id, path: path})
          refute proof =~ probe()
        end
      end)

    assert output == "", "rejection emitted a log: #{id}/#{path}"
  end

  defp projections do
    [
      &SafeObservation.validate/1,
      &SafeObservation.to_telemetry/1,
      &SafeObservation.to_logger/1,
      &SafeObservation.to_doctor/1
    ]
  end

  defp operations, do: [(&SafeObservation.new/1) | projections()]

  defp hostile_variants(base) do
    [
      {:hostile, probe()},
      {:lf, base <> "\n"},
      {:crlf, base <> "\r\n"},
      {:prefix, probe() <> base},
      {:suffix, base <> probe()},
      {nil, nil},
      {:empty, ""},
      {:list, [probe()]},
      {:nested_map, %{nested: probe()}},
      {:integer, 1},
      {:float, 1.0},
      {:atom, :unknown_closed_value},
      {:unicode, "ｃ" <> base},
      {:invalid_encoding, <<255>>}
    ]
  end

  defp probe, do: Enum.join(["REJECTED", "OBSERVATION", "PROBE"], "-")
  defp rule(:route_id), do: "CW-SAFE-OBSERVATION-ROUTE"
  defp rule(:measurements), do: "CW-SAFE-OBSERVATION-MEASUREMENT"

  defp rule(field) when field in [:configuration, :adapter_readiness],
    do: "CW-SAFE-OBSERVATION-READINESS"

  defp rule(_), do: "CW-SAFE-OBSERVATION-VALUE"
end
