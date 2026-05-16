defmodule Crosswake.SupportMatrix do
  @moduledoc """
  Canonical support-matrix truth shared across manifest generation, doctor, and docs.
  """

  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix

  @statuses [:supported, :verification_required, :unsupported]

  @spec canonical(keyword()) :: SupportMatrix.t()
  def canonical(opts \\ []) do
    Types.new_support_matrix(
      phoenix: [
        support_entry("phoenix", Keyword.get(opts, :phoenix_version, "~> 1.8"), :supported,
          proof: "phase-2-proof-lane",
          notes: "Phoenix host install and manifest generation are the stable baseline."
        )
      ],
      live_view: [
        support_entry(
          "phoenix_live_view",
          Keyword.get(opts, :live_view_version, "~> 1.1"),
          :supported,
          proof: "phase-2-proof-lane",
          notes: "LiveView remains server-owned and route-first."
        )
      ],
      ios: [
        support_entry("ios", Keyword.get(opts, :ios_version, "17.0"), :verification_required,
          proof: "script/verify_generated_ios_shell.sh",
          notes:
            "Host-owned shell boot is only published after the generated-project proof hook passes."
        )
      ],
      android: [
        support_entry(
          "android",
          Keyword.get(opts, :android_version, "26"),
          :verification_required,
          proof: "script/verify_generated_android_shell.sh",
          notes:
            "Host-owned shell boot is only published after the generated-project proof hook passes."
        )
      ],
      shells: [
        support_entry("ios_shell", Keyword.get(opts, :ios_shell_version, "0.1.0"), :unsupported,
          proof: "script/verify_generated_ios_shell.sh",
          notes: "Unsupported until both platform proof hooks have passed together."
        ),
        support_entry(
          "android_shell",
          Keyword.get(opts, :android_shell_version, "0.1.0"),
          :unsupported,
          proof: "script/verify_generated_android_shell.sh",
          notes: "Unsupported until both platform proof hooks have passed together."
        )
      ]
    )
  end

  @spec validate(SupportMatrix.t()) :: [map()]
  def validate(%SupportMatrix{} = support_matrix) do
    []
    |> validate_categories_present(support_matrix)
    |> validate_exact_statuses(support_matrix)
    |> validate_narrow_baseline(support_matrix)
  end

  @spec statuses() :: [atom()]
  def statuses, do: @statuses

  @spec fetch_status(SupportMatrix.t(), atom(), String.t()) ::
          {:ok, SupportEntry.status()} | :error
  def fetch_status(%SupportMatrix{} = support_matrix, category, version) when is_atom(category) do
    support_matrix
    |> Map.fetch!(category)
    |> Enum.find_value(:error, fn
      %SupportEntry{version: ^version, status: status} -> {:ok, status}
      _other -> nil
    end)
  end

  defp validate_categories_present(errors, %SupportMatrix{} = support_matrix) do
    Enum.reduce([:phoenix, :live_view, :ios, :android, :shells], errors, fn category, acc ->
      if Map.get(support_matrix, category, []) == [] do
        [
          %{
            key: category,
            message: "support matrix is missing #{category} baseline entries",
            hint: "add at least one #{category} entry to the canonical support matrix"
          }
          | acc
        ]
      else
        acc
      end
    end)
  end

  defp validate_exact_statuses(errors, %SupportMatrix{} = support_matrix) do
    support_matrix
    |> categories()
    |> Enum.reduce(errors, fn {category, entries}, acc ->
      Enum.reduce(entries, acc, fn %SupportEntry{status: status} = entry, inner_acc ->
        if status in @statuses do
          inner_acc
        else
          [
            %{
              key: category,
              message:
                "support entry #{entry.target}@#{entry.version} uses unsupported status #{inspect(status)}",
              hint: "use exactly :supported, :verification_required, or :unsupported"
            }
            | inner_acc
          ]
        end
      end)
    end)
  end

  defp validate_narrow_baseline(errors, %SupportMatrix{} = support_matrix) do
    counts = %{
      phoenix: 1,
      live_view: 1,
      ios: 1,
      android: 1,
      shells: 2
    }

    Enum.reduce(counts, errors, fn {category, expected_count}, acc ->
      actual_count = support_matrix |> Map.fetch!(category) |> length()

      if actual_count == expected_count do
        acc
      else
        [
          %{
            key: category,
            message:
              "support matrix for #{category} must stay narrow and proof-oriented (expected #{expected_count}, got #{actual_count})",
            hint:
              "keep the first public support matrix to one active Phoenix line, one LiveView line, one iOS floor, one Android floor, and two exact shell artifact entries"
          }
          | acc
        ]
      end
    end)
  end

  defp categories(%SupportMatrix{} = support_matrix) do
    [
      {:phoenix, support_matrix.phoenix},
      {:live_view, support_matrix.live_view},
      {:ios, support_matrix.ios},
      {:android, support_matrix.android},
      {:shells, support_matrix.shells}
    ]
  end

  defp support_entry(target, version, status, opts) do
    Types.new_support_entry(
      target: target,
      version: version,
      status: status,
      proof: Keyword.get(opts, :proof),
      notes: Keyword.get(opts, :notes)
    )
  end
end
