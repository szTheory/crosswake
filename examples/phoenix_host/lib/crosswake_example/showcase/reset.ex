defmodule CrosswakeExample.Showcase.Reset do
  @moduledoc """
  Server-side showcase reset orchestrator for the Phoenix example host.

  The reset mutates only fixed server-owned resources. Browser-owned IndexedDB
  and outbox state remain reset by the Playwright helpers that own browser state.
  """

  alias CrosswakeExample.Flashcards
  alias CrosswakeExample.SelectiveNative.Fixtures, as: NativeFixtures
  alias CrosswakeExample.Showcase.Fixtures

  @browser_state_reset false

  def reset! do
    counts = %{
      saas_admin: Fixtures.reset_saas_admin!(),
      field_service_native_pressure: NativeFixtures.seed(),
      learning_training: Flashcards.reset_seed!()
    }

    %{
      counts: counts,
      digest: digest(counts),
      browser_state_reset: @browser_state_reset
    }
  end

  defp digest(counts) do
    [
      "browser_state_reset=#{@browser_state_reset}",
      count_components(counts),
      Fixtures.saas_admin_digest_components(),
      NativeFixtures.digest_components(),
      Flashcards.seed_digest_components()
    ]
    |> List.flatten()
    |> Enum.join("|")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp count_components(counts) do
    counts
    |> flatten_counts([])
    |> Enum.sort()
  end

  defp flatten_counts(map, path) when is_map(map) do
    map
    |> Enum.flat_map(fn {key, value} -> flatten_counts(value, path ++ [key]) end)
  end

  defp flatten_counts(value, path) do
    ["count.#{Enum.map_join(path, ".", &to_string/1)}=#{inspect(value)}"]
  end
end
