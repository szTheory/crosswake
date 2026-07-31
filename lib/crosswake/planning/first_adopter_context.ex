defmodule Crosswake.Planning.FirstAdopterContext do
  @moduledoc """
  Routes first-adopter planning context to its permitted destination and provides
  deterministic, browser-free privacy checks for repository-facing material.

  Host-private values, secret inputs, and forbidden discovery sources are recorded
  as non-scanned boundaries so they cannot accidentally become repository content.
  """

  @required_destinations [
    :durable,
    :public,
    :fast_changing,
    :host_private,
    :secret_only,
    :forbidden
  ]

  @routing_matrix [
    %{path: ".planning/ADR-FIRST-B2C-ADOPTER.md", destination: :durable, scan?: true},
    %{path: ".planning/DECISIONS.md", destination: :durable, scan?: true},
    %{path: ".planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md", destination: :durable, scan?: true},
    %{
      path: ".planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md",
      destination: :durable,
      scan?: true
    },
    %{path: ".planning/PROJECT.md", destination: :durable, scan?: true},
    %{path: ".planning/REQUIREMENTS.md", destination: :durable, scan?: true},
    %{path: ".planning/ROADMAP.md", destination: :durable, scan?: true},
    %{path: ".planning/STATE.md", destination: :durable, scan?: true},
    %{path: ".planning/MILESTONES.md", destination: :durable, scan?: true},
    %{path: ".planning/milestones/v20.0-ROADMAP.md", destination: :durable, scan?: true},
    %{path: ".planning/milestones/v20.0-REQUIREMENTS.md", destination: :durable, scan?: true},
    %{
      path: ".planning/phases/158-adoption-reset-and-route-map/158-CONTEXT.md",
      destination: :durable,
      scan?: true
    },
    %{
      path: ".planning/phases/158-adoption-reset-and-route-map/158-01-PLAN.md",
      destination: :durable,
      scan?: true
    },
    %{
      path: ".planning/phases/158-adoption-reset-and-route-map/158-01-SUMMARY.md",
      destination: :durable,
      scan?: true
    },
    %{
      path: ".planning/phases/158-adoption-reset-and-route-map/158-02-PLAN.md",
      destination: :durable,
      scan?: true
    },
    %{
      path: ".planning/phases/158-adoption-reset-and-route-map/158-02-SUMMARY.md",
      destination: :durable,
      scan?: true
    },
    %{
      path: ".planning/phases/158-adoption-reset-and-route-map/158-03-PLAN.md",
      destination: :durable,
      scan?: true
    },
    %{
      path: ".planning/todos/TODO-002-first-b2c-adopter-route-inputs.md",
      destination: :fast_changing,
      scan?: true
    },
    %{
      path: ".planning/FIRST-B2C-ADOPTER-LINEAR-ISSUE-DRAFTS.md",
      destination: :fast_changing,
      scan?: true
    },
    %{path: "AGENTS.md", destination: :durable, scan?: true},
    %{path: "lib/crosswake/capability_map.ex", destination: :public, scan?: true},
    %{path: "guides/capability_map.md", destination: :public, scan?: true},
    %{path: "lib/crosswake/support_matrix/support_matrix.ex", destination: :public, scan?: true},
    %{path: "guides/support_matrix.md", destination: :public, scan?: true},
    %{path: "host-supplied route rows", destination: :host_private, scan?: false},
    %{path: "CROSSWAKE_PRIVATE_ADOPTER_TERMS", destination: :secret_only, scan?: false},
    %{path: "git history", destination: :forbidden, scan?: false},
    %{path: "external sources", destination: :forbidden, scan?: false},
    %{path: "prompt lineage", destination: :forbidden, scan?: false},
    %{path: "superseded brand seeds", destination: :forbidden, scan?: false},
    %{path: "raw fixtures and evidence", destination: :forbidden, scan?: false}
  ]

  @doc "Returns the complete, stable path-to-destination routing matrix."
  @spec routing_matrix() :: [map()]
  def routing_matrix, do: Enum.sort_by(@routing_matrix, & &1.path)

  @doc "Returns repository paths that are eligible for the generic public scan."
  @spec active_paths() :: [String.t()]
  def active_paths do
    routing_matrix()
    |> Enum.filter(& &1.scan?)
    |> Enum.map(& &1.path)
  end

  @doc "Checks generic public/durable privacy boundaries without reading the filesystem."
  @spec scan(%{required(String.t()) => String.t()}) :: [map()]
  def scan(contents_by_path) when is_map(contents_by_path) do
    routing_matrix()
    |> Enum.filter(& &1.scan?)
    |> Enum.flat_map(fn %{path: path, destination: destination} ->
      contents = Map.get(contents_by_path, path, "")
      generic_violations(path, contents) ++ destination_violations(destination, path, contents)
    end)
    |> sort_violations()
  end

  @doc "Checks caller-supplied private terms without returning a term or matching content."
  @spec scan_private_terms(%{required(String.t()) => String.t()}, [String.t()]) :: [map()]
  def scan_private_terms(contents_by_path, terms)
      when is_map(contents_by_path) and is_list(terms) do
    normalized_terms =
      terms
      |> Enum.filter(&is_binary/1)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.downcase/1)
      |> Enum.uniq()

    routing_matrix()
    |> Enum.filter(&private_term_scanned?/1)
    |> Enum.flat_map(fn %{path: path} ->
      contents = contents_by_path |> Map.get(path, "") |> String.downcase()

      if Enum.any?(normalized_terms, &String.contains?(contents, &1)) do
        [%{rule_id: "privacy.private_term", path: path}]
      else
        []
      end
    end)
    |> sort_violations()
  end

  @doc false
  @spec validate_routing_matrix([map()]) :: [map()]
  def validate_routing_matrix(matrix) when is_list(matrix) do
    paths = Enum.map(matrix, &Map.get(&1, :path))

    duplicate_violations =
      paths
      |> Enum.frequencies()
      |> Enum.filter(fn {path, count} -> is_binary(path) and count > 1 end)
      |> Enum.map(fn {path, _count} -> %{rule_id: "routing.duplicate_path", path: path} end)

    unclassified_violations =
      matrix
      |> Enum.filter(fn entry -> Map.get(entry, :destination) not in @required_destinations end)
      |> Enum.map(fn entry ->
        %{rule_id: "routing.unclassified_path", path: Map.get(entry, :path, "unknown")}
      end)

    empty_destination_violations =
      @required_destinations
      |> Enum.reject(fn destination ->
        Enum.any?(matrix, &(Map.get(&1, :destination) == destination))
      end)
      |> Enum.map(fn destination ->
        %{rule_id: "routing.required_destination_empty", path: Atom.to_string(destination)}
      end)

    (duplicate_violations ++ unclassified_violations ++ empty_destination_violations)
    |> sort_violations()
  end

  defp generic_violations(path, contents) do
    [
      {"privacy.commercial_detail", ~r/\$\s*\d+/},
      {"privacy.identifying_field", ~r/customer[-_ ]?(email|name|address)|legal[-_ ]?name/i}
    ]
    |> Enum.flat_map(fn {rule_id, pattern} ->
      if Regex.match?(pattern, contents), do: [%{rule_id: rule_id, path: path}], else: []
    end)
  end

  defp destination_violations(:public, path, contents) do
    public_phrase = Regex.match?(~r/first adopter|first-adopter/i, contents)
    codename = String.contains?(contents, "First B2C Adopter")

    []
    |> maybe_add(not public_phrase, "privacy.public_phrase", path)
    |> maybe_add(codename, "privacy.public_codename", path)
  end

  defp destination_violations(_destination, _path, _contents), do: []

  # Planning commands may deliberately name the secret-input environment variable and
  # a synthetic canary. They receive generic phrase scans, while the privileged term
  # comparison remains limited to repository-facing context rather than self-matching
  # the validation instruction.
  defp private_term_scanned?(%{scan?: true, path: path}),
    do: not String.ends_with?(path, "-PLAN.md")

  defp private_term_scanned?(_entry), do: false

  defp maybe_add(violations, true, rule_id, path),
    do: [%{rule_id: rule_id, path: path} | violations]

  defp maybe_add(violations, false, _rule_id, _path), do: violations

  defp sort_violations(violations), do: Enum.sort_by(violations, &{&1.rule_id, &1.path})
end
