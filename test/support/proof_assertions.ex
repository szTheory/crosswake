defmodule Crosswake.TestSupport.ProofAssertions do
  @moduledoc false

  import ExUnit.Assertions

  @volatile_keys ~w(evaluated_at generated_at generated_on timestamp inserted_at updated_at)a
  @volatile_suffixes ["_at", "_on", "_timestamp"]

  def stable_id_message(id, subject, source, observed, path, hint, posture) do
    """
    [#{id}] subject=#{subject} source=#{source} observed=#{observed} path=#{path} hint=#{hint} posture=#{posture}
    """
    |> String.trim()
  end

  def assert_normalized_json_fixture(id, json_payload, fixture_path, opts \\ []) do
    normalized_actual =
      json_payload
      |> Jason.decode!()
      |> normalize()

    normalized_expected =
      fixture_path
      |> File.read!()
      |> Jason.decode!()
      |> normalize()

    assert normalized_actual == normalized_expected,
           stable_id_message(
             id,
             Keyword.get(opts, :subject, "normalized json contract"),
             Keyword.fetch!(opts, :source),
             "normalized payload differs from fixture",
             Keyword.get(opts, :path, fixture_path),
             Keyword.fetch!(opts, :hint),
             Keyword.fetch!(opts, :posture)
           )
  end

  def assert_file_exact(id, path, expected, opts \\ []) do
    actual = File.read!(path)

    assert actual == expected,
           stable_id_message(
             id,
             Keyword.get(opts, :subject, "generated file parity"),
             Keyword.fetch!(opts, :source),
             "file bytes differ from canonical output",
             path,
             Keyword.fetch!(opts, :hint),
             Keyword.fetch!(opts, :posture)
           )
  end

  def assert_contains_exact(id, path, needle, opts \\ []) do
    body = File.read!(path)

    assert String.contains?(body, needle),
           stable_id_message(
             id,
             Keyword.get(opts, :subject, "authored docs parity"),
             Keyword.fetch!(opts, :source),
             "missing expected text: #{needle}",
             path,
             Keyword.fetch!(opts, :hint),
             Keyword.fetch!(opts, :posture)
           )
  end

  defp normalize(value) when is_map(value) do
    value
    |> Enum.reject(fn {key, _v} -> volatile_key?(key) end)
    |> Enum.map(fn {key, v} -> {key, normalize(v)} end)
    |> Enum.sort_by(fn {key, _v} -> key end)
  end

  defp normalize(value) when is_list(value), do: Enum.map(value, &normalize/1)
  defp normalize(value), do: value

  defp volatile_key?(key) when is_atom(key), do: volatile_key?(Atom.to_string(key))

  defp volatile_key?(key) when is_binary(key) do
    key in Enum.map(@volatile_keys, &Atom.to_string/1) or
      Enum.any?(@volatile_suffixes, &String.ends_with?(key, &1))
  end
end
