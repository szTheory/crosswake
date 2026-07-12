defmodule Crosswake.Guides.CapabilityClaimsTest do
  use ExUnit.Case, async: true

  @scanned_paths [
    "README.md",
    "examples/phoenix_host/README.md",
    "guides/capability_map.md",
    "guides/support_matrix.md",
    "guides/capabilities.md",
    "guides/native_shell.md",
    "guides/bridge.md",
    "guides/offline.md",
    "guides/commerce.md",
    "examples/phoenix_host/evidence/evidence-manifest.example.json",
    "brandbook/collateral/README.md"
  ]

  @optional_paths ["brandbook/collateral/README.md"]

  test "D-20/D-21 scanned public docs and evidence metadata are present" do
    for path <- @scanned_paths -- @optional_paths do
      assert File.exists?(path), "D-20/D-21: expected public claim scanner path #{path} to exist"
    end
  end

  test "D-20/D-22/D-24/D-29 public docs and evidence metadata avoid broad unsupported claims" do
    failures =
      @scanned_paths
      |> Enum.filter(&File.exists?/1)
      |> Enum.flat_map(fn path ->
        path
        |> File.read!()
        |> then(&scan_surface(path, &1))
      end)

    assert_no_failures(failures)
  end

  test "D-22 canonical capability rows cannot render deferred or docs-only rows as shipped support" do
    rows =
      Crosswake.CapabilityMap.canonical()
      |> Enum.map(&normalize_row/1)

    failures =
      Enum.flat_map(rows, fn row ->
        cond do
          row.package_owner in [:example_docs_only, :deferred] and
              row.display_label == "Available today" ->
            [
              failure("Crosswake.CapabilityMap", :deferred_rendered_as_shipped,
                detail: "#{row.id} renders as Available today"
              )
            ]

          row.package_owner in [:example_docs_only, :deferred] and row.category == :shipped ->
            [
              failure("Crosswake.CapabilityMap", :deferred_rendered_as_shipped,
                detail: "#{row.id} uses :shipped category"
              )
            ]

          row.proof_posture in [:advisory, :not_yet_proven, :unsupported] and
              row.display_label == "Available today" ->
            [
              failure("Crosswake.CapabilityMap", :weak_proof_rendered_as_shipped,
                detail: "#{row.id} uses Available today with #{row.proof_posture}"
              )
            ]

          true ->
            []
        end
      end)

    assert_no_failures(failures)
  end

  test "D-24/D-29 synthetic regressions catch native, offline, commerce, plugin, and screenshot overclaims" do
    synthetic = """
    Native mobile with no native work and generic plugin support.
    Everything works offline without journals or reconciliation.
    Live StoreKit support, Play Billing support shipped, and RevenueCat support.
    Screenshot proof confirms physical-device support and camera support.
    Purchase events unlock subscriber access before backend projection.
    """

    failures = scan_surface("synthetic/capability-overclaims.md", synthetic)

    for category <- [
          :generic_plugin_overclaim,
          :offline_overclaim,
          :commerce_provider_overclaim,
          :screenshot_proof_overclaim,
          :native_authority_overclaim,
          :entitlement_authority_overclaim
        ] do
      assert Enum.any?(failures, &(&1.category == category)),
             "expected #{inspect(category)} failure, got:\n#{format_failures(failures)}"
    end
  end

  test "D-14/D-18/D-23 screenshot wording is allowed only as collateral after route-tour assertions" do
    accepted =
      scan_surface(
        "synthetic/accepted-collateral.md",
        "Screenshots are collateral after route-tour assertions and do not prove native/device/provider behavior."
      )

    assert_no_failures(accepted)

    rejected =
      scan_surface(
        "synthetic/rejected-collateral.md",
        "Screenshot proof confirms the native shell and provider behavior."
      )

    assert Enum.any?(rejected, &(&1.category == :screenshot_proof_overclaim))
  end

  defp scan_surface(path, contents) do
    contents
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} -> line_failures(path, line, line_number) end)
  end

  defp line_failures(path, line, line_number) do
    []
    |> maybe_line_failure(
      path,
      line,
      line_number,
      ~r/\bmagic bridge\b|\bgeneric plugin support\b|\bgeneric plugin catalog\b/i,
      :generic_plugin_overclaim,
      "D-24/D-29: line presents Crosswake as a generic native plugin surface"
    )
    |> maybe_line_failure(
      path,
      line,
      line_number,
      ~r/\beverything works offline\b|\bworks offline\b.*\bwithout\b.*\b(journal|outbox|reconciliation)\b/i,
      :offline_overclaim,
      "D-19/D-24/D-33: line overstates offline behavior without journal/outbox/reconciliation proof"
    )
    |> maybe_line_failure(
      path,
      line,
      line_number,
      ~r/\blive StoreKit support\b|\bPlay Billing support shipped\b|\bRevenueCat support\b/i,
      :commerce_provider_overclaim,
      "D-12/D-24/D-34: line claims live commerce provider support"
    )
    |> maybe_line_failure(
      path,
      line,
      line_number,
      ~r/\bscreenshot proof\b|\bscreenshots? (prove|certif(?:y|ies)|confirm)/i,
      :screenshot_proof_overclaim,
      "D-14/D-18/D-23: line treats screenshots as proof instead of collateral"
    )
    |> maybe_line_failure(
      path,
      line,
      line_number,
      ~r/\bphysical-device support\b|\bcamera support\b|\bmedia-upload support\b|\bprovider authority\b|\bapp-store readiness\b/i,
      :native_authority_overclaim,
      "D-24/D-32: line launders native/device/provider authority from docs or collateral"
    )
    |> maybe_line_failure(
      path,
      line,
      line_number,
      ~r/\b(purchase|storefront|device)\b.*\b(unlocks?|grants?)\b|\bsubscriber truth\b/i,
      :entitlement_authority_overclaim,
      "D-12/D-34: line bypasses backend projection authority"
    )
    |> maybe_line_failure(
      path,
      line,
      line_number,
      ~r/\bnative mobile with no native work\b|\bwrite once, run anywhere\b/i,
      :runtime_owner_overclaim,
      "D-29/D-31: line hides runtime ownership"
    )
  end

  defp maybe_line_failure(failures, path, line, line_number, regex, category, detail) do
    if Regex.match?(regex, line) and not line_support_negated?(line) do
      [failure(path, category, line: line_number, claim: line, detail: detail) | failures]
    else
      failures
    end
  end

  defp line_support_negated?(line) do
    lowered = String.downcase(line)

    String.contains?(lowered, " not ") or
      String.starts_with?(lowered, "not ") or
      String.contains?(lowered, "does not ") or
      String.contains?(lowered, "without claiming") or
      String.contains?(lowered, "avoid copy such as") or
      String.contains?(lowered, "forbidden copy") or
      String.contains?(lowered, "what this is not") or
      String.starts_with?(String.trim_leading(line), "- “") or
      String.starts_with?(String.trim_leading(line), "- \"") or
      String.contains?(lowered, "backend projection grants entitlement authority") or
      String.contains?(lowered, "cannot ") or
      String.contains?(lowered, "never ") or
      String.contains?(lowered, "no broad ") or
      String.contains?(lowered, "instead of")
  end

  defp normalize_row(%_{} = row), do: Map.from_struct(row)
  defp normalize_row(row) when is_map(row), do: row

  defp failure(path, category, opts) do
    %{
      path: path,
      line: Keyword.get(opts, :line),
      category: category,
      claim: Keyword.get(opts, :claim),
      detail: Keyword.fetch!(opts, :detail)
    }
  end

  defp format_failures(failures) do
    Enum.map_join(failures, "\n", fn failure ->
      location = if failure.line, do: "#{failure.path}:#{failure.line}", else: failure.path
      claim = (failure.claim || "") |> to_string() |> String.trim()
      claim_suffix = if claim == "", do: "", else: " -- #{claim}"
      "- #{location} [#{failure.category}] #{failure.detail}#{claim_suffix}"
    end)
  end

  defp assert_no_failures(failures) do
    assert failures == [],
           "capability support-truth claim drift found:\n#{format_failures(failures)}"
  end
end
