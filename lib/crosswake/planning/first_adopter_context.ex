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

  @non_file_routes [
    %{path: "host-supplied route rows", destination: :host_private, scan?: false},
    %{path: "CROSSWAKE_PRIVATE_ADOPTER_TERMS", destination: :secret_only, scan?: false},
    %{path: "git history", destination: :forbidden, scan?: false},
    %{path: "external sources", destination: :forbidden, scan?: false},
    %{path: "prompt lineage", destination: :forbidden, scan?: false},
    %{path: "superseded brand seeds", destination: :forbidden, scan?: false},
    %{path: "raw fixtures and evidence", destination: :forbidden, scan?: false}
  ]

  @artifact_globs [
    %{glob: "AGENTS.md", destination: :durable},
    %{glob: ".planning/ADR-FIRST-B2C-ADOPTER.md", destination: :durable},
    %{glob: ".planning/DECISIONS.md", destination: :durable},
    %{glob: ".planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md", destination: :durable},
    %{glob: ".planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md", destination: :durable},
    %{glob: ".planning/MILESTONES.md", destination: :durable},
    %{glob: ".planning/PROJECT.md", destination: :durable},
    %{
      glob: ".planning/workstreams/first-b2c-adopter-readiness/REQUIREMENTS.md",
      destination: :durable
    },
    %{
      glob: ".planning/workstreams/first-b2c-adopter-readiness/ROADMAP.md",
      destination: :durable
    },
    %{
      glob: ".planning/workstreams/first-b2c-adopter-readiness/STATE.md",
      destination: :durable
    },
    %{glob: ".planning/milestones/v20.0-REQUIREMENTS.md", destination: :durable},
    %{glob: ".planning/milestones/v20.0-ROADMAP.md", destination: :durable},
    %{
      glob:
        ".planning/workstreams/first-b2c-adopter-readiness/phases/158-adoption-reset-and-route-map/158-*.md",
      destination: :durable
    },
    %{
      glob: ".planning/todos/TODO-002-first-b2c-adopter-route-inputs.md",
      destination: :fast_changing
    },
    %{glob: ".planning/FIRST-B2C-ADOPTER-LINEAR-ISSUE-DRAFTS.md", destination: :fast_changing},
    %{glob: "lib/crosswake/capability_map.ex", destination: :public},
    %{glob: "lib/crosswake/support_matrix/support_matrix.ex", destination: :public},
    %{glob: "guides/capability_map.md", destination: :public},
    %{glob: "guides/support_matrix.md", destination: :public}
  ]

  @scannable_extensions ~w(
    .bak .bat .c .css .eex .ex .exs .gradle .heex .html .java .js .json .kt .kts .lock .md .mjs
    .orig .pbxproj .plist .properties .py .sh .svg .swift .tape .toml .ts .tsx .txt .xcscheme .xml .yaml .yml
  )
  @physical_evidence_completion_marker ".planning/workstreams/first-b2c-adopter-readiness/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/.complete"
  @reference_host_pronunciation_aiff "examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff"
  @known_excluded_binary_paths ~w(
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/deck-dark.png
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/deck-focus-ring.png
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/deck-light.png
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/gen-dark.png
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/gen-focus-dark.png
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/gen-light.png
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/host-dark.png
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/host-focus-ring.png
    .planning/milestones/v10.0-phases/108-consumer-normalization/render/host-light.png
    .planning/milestones/v19.0-phases/147-arc-fixture-and-showcase-foundation/uat-screenshots/desktop-dark-reduced.png
    .planning/milestones/v19.0-phases/147-arc-fixture-and-showcase-foundation/uat-screenshots/desktop-light.png
    .planning/milestones/v19.0-phases/147-arc-fixture-and-showcase-foundation/uat-screenshots/mobile-dark-reduced.png
    .planning/milestones/v19.0-phases/147-arc-fixture-and-showcase-foundation/uat-screenshots/mobile-light.png
    .planning/milestones/v19.0-phases/148-demo-app-brand-fixture-direction/uat-screenshots/showcase-desktop.png
    .planning/milestones/v19.0-phases/148-demo-app-brand-fixture-direction/uat-screenshots/showcase-mobile-dark.png
    brandbook/collateral/apple-touch-icon.png
    brandbook/collateral/favicon-32.png
    brandbook/collateral/see-it-run/see-it-run.gif
    brandbook/collateral/see-it-run/web-bridge-proof.png
    brandbook/collateral/see-it-run/web-home.png
    brandbook/collateral/see-it-run/web-offline.png
    brandbook/collateral/social-card.png
    crosswake-checkpoint-24c8389.bundle
    examples/ios_shell_host/CrosswakeShell/Resources/pronunciation-pack-fixture.bin
    examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/card-image.png
    examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/pronunciation-pack-fixture.bin
    packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/pronunciation-pack-fixture.bin
  )
  @prose_extensions ~w(.html .md .svg .txt .xml)
  @commercial_context ~r/\b(?:amount|cost|dollar|fee|payment|price|revenue|subscription|usd)\b/i
  @commercial_amount ~r/\$\s*\d+(?:\.\d{1,2})?\b/
  @multi_digit_or_decimal_commercial_amount ~r/\$\s*(?:\d{2,}|\d+\.\d{1,2})\b/

  @doc "Returns the complete, stable path-to-destination routing matrix."
  @spec routing_matrix() :: [map()]
  def routing_matrix do
    File.cwd!()
    |> classification_result()
    |> elem(0)
    |> Enum.map(&Map.take(&1, [:path, :destination, :scan?]))
    |> Kernel.++(@non_file_routes)
    |> Enum.sort_by(& &1.path)
  end

  @doc "Returns repository paths that are eligible for the generic public scan."
  @spec active_paths() :: [String.t()]
  def active_paths do
    routing_matrix()
    |> Enum.filter(& &1.scan?)
    |> Enum.map(& &1.path)
  end

  @doc "Returns destination-tagged globs for repository artifacts that must be scanned."
  @spec artifact_globs() :: [map()]
  def artifact_globs, do: Enum.sort_by(@artifact_globs, & &1.glob)

  @doc "Discovers approved regular files below a repository root in deterministic path order."
  @spec discover_paths(Path.t()) :: [String.t()]
  def discover_paths(root) when is_binary(root) do
    root
    |> classification_result()
    |> elem(0)
    |> Enum.filter(& &1.scan?)
    |> Enum.map(& &1.path)
  end

  @doc "Scans approved repository files without returning private terms or file contents."
  @spec scan_filesystem(Path.t(), [String.t()]) :: [map()]
  def scan_filesystem(root, terms) when is_binary(root) and is_list(terms) do
    {entries, routing_violations} = classification_result(root)

    entries
    |> filesystem_routing_violations(routing_violations)
    |> Kernel.++(filesystem_content_violations(entries, terms))
    |> sort_violations()
  end

  @doc "Checks generic public/durable privacy boundaries without reading the filesystem."
  @spec scan(%{required(String.t()) => String.t()}) :: [map()]
  def scan(contents_by_path) when is_map(contents_by_path) do
    File.cwd!()
    |> classification_result()
    |> elem(0)
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
      {
        "privacy.identifying_field",
        ~r/\b(?:customer[-_ ]?(?:email|name|address)|legal[-_ ]?name)\b[ \t]*(?::|=>|=)/i
      }
    ]
    |> maybe_add_commercial_detail(path, contents)
    |> Enum.flat_map(fn {rule_id, pattern} ->
      if Regex.match?(pattern, contents), do: [%{rule_id: rule_id, path: path}], else: []
    end)
  end

  defp maybe_add_commercial_detail(patterns, path, contents) do
    if commercial_detail?(path, contents) do
      [{"privacy.commercial_detail", @commercial_amount} | patterns]
    else
      patterns
    end
  end

  defp commercial_detail?(path, contents) do
    if Path.extname(path) in @prose_extensions do
      Regex.match?(@multi_digit_or_decimal_commercial_amount, contents) or
        Enum.any?(String.split(contents, "\n"), &single_digit_commercial_line?/1)
    else
      false
    end
  end

  defp single_digit_commercial_line?(line) do
    Regex.match?(~r/\$\s*\d\b/, line) and Regex.match?(@commercial_context, line)
  end

  defp destination_violations(:public, path, contents) do
    public_phrase = Regex.match?(~r/\bfirst[[:space:]]+adopter\b/i, contents)
    hyphenated_phrase = Regex.match?(~r/\bfirst-adopter(?!-)\b/i, contents)
    codename = String.contains?(contents, "First B2C Adopter")

    []
    |> maybe_add(not public_phrase, "privacy.public_phrase", path)
    |> maybe_add(hyphenated_phrase, "privacy.public_phrase_hyphenated", path)
    |> maybe_add(codename, "privacy.public_codename", path)
  end

  defp destination_violations(_destination, _path, _contents), do: []

  defp private_term_scanned?(%{scan?: true}), do: true

  defp private_term_scanned?(_entry), do: false

  defp maybe_add(violations, true, rule_id, path),
    do: [%{rule_id: rule_id, path: path} | violations]

  defp maybe_add(violations, false, _rule_id, _path), do: violations

  defp sort_violations(violations), do: Enum.sort_by(violations, &{&1.rule_id, &1.path})

  defp classification_result(root) do
    expanded_root = Path.expand(root)

    case repository_candidates(expanded_root) do
      {:ok, candidates} ->
        candidates
        |> Enum.reduce({[], []}, fn path, {entries, violations} ->
          case classify_candidate(expanded_root, path) do
            {:entry, entry} -> {[entry | entries], violations}
            {:violation, violation} -> {entries, [violation | violations]}
          end
        end)
        |> then(fn {entries, violations} ->
          {Enum.sort_by(entries, & &1.path), sort_violations(violations)}
        end)

      :error ->
        {[], [%{rule_id: "routing.repository_enumeration_failed", path: "repository"}]}
    end
  end

  defp repository_candidates(root) do
    try do
      case System.cmd(
             "git",
             ["-C", root, "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
             stderr_to_stdout: true
           ) do
        {output, 0} -> {:ok, String.split(output, <<0>>, trim: true) |> Enum.uniq()}
        _ -> :error
      end
    rescue
      _ -> :error
    end
  end

  defp classify_candidate(root, path) do
    with true <- safe_relative_path?(path),
         absolute_path <- Path.expand(path, root),
         true <- contained_in_root?(absolute_path, root),
         {:ok, %{type: :regular}} <- File.lstat(absolute_path) do
      case classify_repository_path(path) do
        {:scan, destination} ->
          {:entry,
           %{
             path: path,
             absolute_path: absolute_path,
             destination: destination,
             scan?: true
           }}

        {:excluded, destination} ->
          {:entry,
           %{
             path: path,
             absolute_path: absolute_path,
             destination: destination,
             scan?: false
           }}

        :unclassified ->
          {:violation, %{rule_id: "routing.unclassified_path", path: path}}
      end
    else
      _ -> {:violation, %{rule_id: "routing.unsafe_candidate_path", path: safe_path(path)}}
    end
  end

  defp classify_repository_path(path) do
    cond do
      ignored_build_or_dependency_path?(path) -> {:excluded, :forbidden}
      destination = named_destination(path) -> {:scan, destination}
      path == @physical_evidence_completion_marker -> {:scan, :durable}
      path == @reference_host_pronunciation_aiff -> {:excluded, :host_private}
      path in @known_excluded_binary_paths -> {:excluded, :forbidden}
      explicit_exclusion_path?(path) -> {:excluded, :forbidden}
      phase_artifact_path?(path) -> {:scan, :durable}
      scannable_text_path?(path) -> {:scan, :durable}
      true -> :unclassified
    end
  end

  defp named_destination(path) do
    @artifact_globs
    |> Enum.find_value(fn %{glob: glob, destination: destination} ->
      if glob == path, do: destination
    end)
  end

  defp phase_artifact_path?(path) do
    scannable_text_path?(path) and
      String.match?(path, ~r/^\.planning\/phases\/[0-9]+(?:\.[0-9]+)?-[^\/]+\/.+$/)
  end

  defp scannable_text_path?(path) do
    extension = Path.extname(path)

    extension in @scannable_extensions or
      path in [
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "gen_manifest.exs",
        "mix.exs",
        "mix.lock",
        "package.json",
        ".formatter.exs",
        ".gitignore",
        ".tool-versions"
      ] or
      Path.basename(path) in [
        ".dockerignore",
        ".env",
        ".gitkeep",
        "Dockerfile",
        "gradlew",
        "LICENSE",
        "crosswake-ios-rehearsal",
        "crosswake-physical-iphone"
      ]
  end

  defp explicit_exclusion_path?(path) do
    String.starts_with?(path, [
      "evidence/",
      "artifacts/raw/",
      "test/fixtures/",
      "test/support/fixtures/",
      "priv/fixtures/"
    ])
  end

  defp ignored_build_or_dependency_path?(path),
    do: String.starts_with?(path, ["_build/", "deps/", "node_modules/"])

  defp safe_relative_path?(path) do
    Path.type(path) == :relative and path not in ["", "."] and
      not String.contains?(path, <<0>>) and
      Enum.all?(Path.split(path), &(&1 not in ["", ".", ".."]))
  end

  defp contained_in_root?(absolute_path, root),
    do: String.starts_with?(absolute_path, root <> "/")

  defp safe_path(path) when is_binary(path) do
    if safe_relative_path?(path), do: path, else: "candidate"
  end

  defp filesystem_routing_violations(entries, routing_violations) do
    duplicate_violations =
      entries
      |> Enum.group_by(& &1.path)
      |> Enum.flat_map(fn {path, matches} ->
        if length(matches) == 1, do: [], else: [%{rule_id: "routing.duplicate_path", path: path}]
      end)

    unclassified_violations =
      entries
      |> Enum.reject(&(&1.destination in @required_destinations))
      |> Enum.map(&%{rule_id: "routing.unclassified_path", path: &1.path})

    routing_violations ++ duplicate_violations ++ unclassified_violations
  end

  defp filesystem_content_violations(entries, terms) do
    normalized_terms = normalize_private_terms(terms)

    entries
    |> Enum.filter(& &1.scan?)
    |> Enum.uniq_by(& &1.path)
    |> Enum.flat_map(fn %{path: path, absolute_path: absolute_path} = entry ->
      case File.read(absolute_path) do
        {:ok, contents} ->
          policy_violations(entry, contents) ++
            private_term_violations(path, contents, normalized_terms)

        {:error, _reason} ->
          [%{rule_id: "routing.unreadable_path", path: path}]
      end
    end)
  end

  defp policy_violations(%{path: path, destination: destination}, contents),
    do: generic_violations(path, contents) ++ destination_violations(destination, path, contents)

  defp normalize_private_terms(terms) do
    terms
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.downcase/1)
    |> Enum.uniq()
  end

  defp private_term_violations(_path, _contents, []), do: []

  defp private_term_violations(path, contents, terms) do
    if Enum.any?(terms, &String.contains?(String.downcase(contents), &1)) do
      [%{rule_id: "privacy.private_term", path: path}]
    else
      []
    end
  end
end
