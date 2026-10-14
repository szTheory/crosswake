defmodule Crosswake.Shell.IOSHostOriginMode do
  @moduledoc false
  # Bounded reconcile of the Crosswake-owned local-loopback block in the host-owned
  # CrosswakeShell/Info.plist (182 D-06, D-08, D-23). Pure functions over bytes.
  #
  # Rules:
  #   * The only thing this module ever inserts or strips is the exact block below.
  #   * Under no declared mode a host-owned ATS dict (without the marker) is never touched.
  #   * Under :local_loopback any other ATS shape, forbidden ATS key, or a missing/duplicated
  #     LSRequiresIPhoneOS anchor is a conflict; callers must leave the file unchanged.

  @anchor "    <key>LSRequiresIPhoneOS</key>\n    <true/>"
  @block "\n    <key>NSAppTransportSecurity</key>\n    <dict>\n        <key>NSAllowsLocalNetworking</key>\n        <true/>\n    </dict>\n    <key>CrosswakeOriginMode</key>\n    <string>local_loopback</string>"
  @forbidden_ats_keys ~w(NSAllowsArbitraryLoads NSAllowsArbitraryLoadsInWebContent NSAllowsArbitraryLoadsForMedia NSExceptionDomains)
  @ats_key "NSAppTransportSecurity"
  @marker_key "CrosswakeOriginMode"
  @repair "review and remove or merge the host edit to NSAppTransportSecurity or CrosswakeOriginMode in CrosswakeShell/Info.plist, then rerun mix crosswake.gen.shell ios"
  @banner "Local loopback build for Simulator demonstration. Not physical, adopter, or release evidence."

  @doc "Exact bytes the template splices after the LSRequiresIPhoneOS anchor."
  def block(:local_loopback), do: @block

  def forbidden_ats_keys, do: @forbidden_ats_keys
  def readme_banner, do: @banner

  @doc "Classify the plist: local block, no Crosswake signal, or a conflicting shape."
  def inspect_plist(bytes) when is_binary(bytes) do
    blocks = count(bytes, @block)
    ats = count(bytes, @ats_key)
    markers = count(bytes, @marker_key)

    cond do
      blocks == 1 and ats == 1 and markers == 1 ->
        {:ok, %{mode: :local_loopback, host_ats: false}}

      blocks == 0 and markers == 0 ->
        {:ok, %{mode: nil, host_ats: ats > 0}}

      true ->
        conflict()
    end
  end

  def inspect_plist(_), do: conflict()

  @doc "Desired plist bytes for a declared mode (nil or :local_loopback)."
  def desired(bytes, nil) when is_binary(bytes) do
    case inspect_plist(bytes) do
      {:ok, %{mode: :local_loopback}} ->
        finish(:binary.replace(bytes, @block, ""), nil)

      {:ok, _} ->
        {:ok, bytes}

      error ->
        error
    end
  end

  def desired(bytes, :local_loopback) when is_binary(bytes) do
    with false <- Enum.any?(@forbidden_ats_keys, &String.contains?(bytes, &1)),
         {:ok, inspection} <- inspect_plist(bytes) do
      case inspection do
        %{mode: :local_loopback} ->
          {:ok, bytes}

        %{mode: nil, host_ats: true} ->
          conflict()

        %{mode: nil} ->
          if count(bytes, @anchor) == 1 do
            finish(:binary.replace(bytes, @anchor, @anchor <> @block), :local_loopback)
          else
            conflict()
          end
      end
    else
      true -> conflict()
      error -> error
    end
  end

  def desired(_, _), do: conflict()

  @doc "True when the declared mode disagrees with what the plist read/inspection shows."
  def mismatch?(declared, {:ok, %{mode: mode}}), do: declared != mode
  def mismatch?(:local_loopback, _), do: true
  def mismatch?(nil, {:error, %{cause: "info_plist_conflict"}}), do: true
  def mismatch?(nil, _), do: false

  def check_line(origin, :local_loopback) when is_binary(origin) do
    "origin mode: local loopback (#{origin}); Simulator only; not production-ready; before distributing, switch to your HTTPS production origin and regenerate"
  end

  def check_line(_origin, _mode), do: nil

  def conflict_message,
    do: %{cause: "info_plist_conflict", repair: @repair}

  defp finish(candidate, mode) do
    expected = if mode == :local_loopback, do: :local_loopback, else: nil

    case inspect_plist(candidate) do
      {:ok, %{mode: ^expected}} -> {:ok, candidate}
      _ -> conflict()
    end
  end

  defp conflict, do: {:error, conflict_message()}

  defp count(bytes, pattern), do: length(:binary.matches(bytes, pattern))
end
