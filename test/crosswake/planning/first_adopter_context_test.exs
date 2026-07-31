defmodule Crosswake.Planning.FirstAdopterContextTest do
  use ExUnit.Case, async: true

  alias Crosswake.Planning.FirstAdopterContext

  @v20_paths [
    ".planning/MILESTONES.md",
    ".planning/milestones/v20.0-ROADMAP.md",
    ".planning/milestones/v20.0-REQUIREMENTS.md"
  ]

  test "routing matrix classifies every active path once with non-empty required destinations" do
    matrix = FirstAdopterContext.routing_matrix()
    paths = FirstAdopterContext.active_paths()

    assert paths ==
             matrix
             |> Enum.filter(& &1.scan?)
             |> Enum.map(& &1.path)

    assert paths == Enum.sort(paths)
    assert Enum.all?(paths, &File.exists?/1)
    assert FirstAdopterContext.validate_routing_matrix(matrix) == []

    for destination <- [
          :durable,
          :public,
          :fast_changing,
          :host_private,
          :secret_only,
          :forbidden
        ] do
      assert Enum.any?(matrix, &(&1.destination == destination)),
             "routing matrix must retain a #{destination} destination"
    end

    duplicate = [%{path: "AGENTS.md", destination: :durable} | matrix]

    assert [%{rule_id: "routing.duplicate_path", path: "AGENTS.md"}] =
             FirstAdopterContext.validate_routing_matrix(duplicate)

    missing_destination = Enum.map(matrix, &Map.put(&1, :destination, nil))

    assert Enum.any?(
             FirstAdopterContext.validate_routing_matrix(missing_destination),
             fn violation ->
               violation.rule_id == "routing.unclassified_path"
             end
           )

    empty_public = Enum.reject(matrix, &(&1.destination == :public))

    assert [%{rule_id: "routing.required_destination_empty", path: "public"}] =
             FirstAdopterContext.validate_routing_matrix(empty_public)
  end

  test "public and durable scans enforce the phrase split with stable rule and path violations" do
    contents = contents_by_path()

    assert FirstAdopterContext.scan(contents) == []

    public_path = "guides/capability_map.md"

    assert [%{rule_id: "privacy.public_phrase", path: ^public_path}] =
             FirstAdopterContext.scan(Map.put(contents, public_path, "route ownership"))

    assert [%{rule_id: "privacy.public_codename", path: ^public_path}] =
             FirstAdopterContext.scan(
               Map.put(contents, public_path, "First B2C Adopter first adopter route ownership")
             )
  end

  test "public scans reject the hyphenated spelling with stable rule and path violations" do
    public_path = "guides/capability_map.md"
    contents = Map.new(FirstAdopterContext.active_paths(), &{&1, "first adopter"})
    hyphenated_phrase = Enum.join(["first", "adopter"], "-")

    assert [%{rule_id: "privacy.public_phrase_hyphenated", path: ^public_path}] =
             FirstAdopterContext.scan(
               Map.put(
                 contents,
                 public_path,
                 "#{hyphenated_phrase} first adopter route ownership"
               )
             )

    assert [
             %{rule_id: "privacy.public_phrase", path: ^public_path},
             %{rule_id: "privacy.public_phrase_hyphenated", path: ^public_path}
           ] =
             FirstAdopterContext.scan(Map.put(contents, public_path, hyphenated_phrase))

    refute inspect(FirstAdopterContext.scan(Map.put(contents, public_path, hyphenated_phrase))) =~
             hyphenated_phrase
  end

  test "identifying-field scans require assignment context while retaining supported key shapes" do
    path = "AGENTS.md"
    contents = Map.new(FirstAdopterContext.active_paths(), &{&1, "first adopter"})

    safe_prose =
      "A customer-name-like validation concept is safe review prose without a field assignment."

    assert FirstAdopterContext.scan(Map.put(contents, path, safe_prose)) == []

    for field <- [
          "customer" <> "_email:",
          "customer" <> "-name =",
          "customer" <> " address =>",
          "customer" <> "Email:",
          "legal" <> "Name ="
        ] do
      assert [%{rule_id: "privacy.identifying_field", path: ^path}] =
               FirstAdopterContext.scan(Map.put(contents, path, "#{field} synthetic"))
    end
  end

  test "live registered artifacts scan clean while the Phase 158 review remains discovered" do
    review_path = ".planning/phases/158-adoption-reset-and-route-map/158-REVIEW.md"

    assert review_path in FirstAdopterContext.discover_paths(File.cwd!())
    assert FirstAdopterContext.scan(contents_by_path()) == []
  end

  test "private-term scan never echoes configured terms or matched content" do
    private_term = Enum.join(["context", "only", "sentinel"], "-")
    path = "AGENTS.md"
    contents = Map.put(contents_by_path(), path, "prefix #{private_term} suffix")

    assert [%{rule_id: "privacy.private_term", path: ^path}] =
             FirstAdopterContext.scan_private_terms(contents, [private_term])

    refute inspect(FirstAdopterContext.scan_private_terms(contents, [private_term])) =~
             private_term
  end

  test "configured private terms are parsed case-insensitively at the caller seam" do
    private_terms =
      System.get_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS", "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    assert FirstAdopterContext.scan_private_terms(contents_by_path(), private_terms) == []
  end

  test "filesystem discovery scans unregistered repository artifacts without echoing private canaries" do
    private_term = Enum.join(["synthetic", "private", "canary"], "-")

    paths = [
      "guides/unregistered-adoption-note.md",
      ".planning/phases/159-host-reusable-proof-lane/159-NOTES.md",
      ".github/workflows/unregistered-scan.yml",
      "lib/crosswake/unregistered_scan.ex",
      "test/crosswake/unregistered_scan_test.exs"
    ]

    with_temporary_repository(paths, "safe prefix #{private_term} safe suffix", fn root ->
      assert Enum.sort(paths) == FirstAdopterContext.discover_paths(root)

      assert paths
             |> Enum.map(&%{rule_id: "privacy.private_term", path: &1})
             |> Enum.sort_by(& &1.path) ==
               FirstAdopterContext.scan_filesystem(root, [private_term])

      refute inspect(FirstAdopterContext.scan_filesystem(root, [private_term])) =~ private_term
    end)
  end

  test "filesystem discovery scans tracked action, script, and future-phase text by default" do
    private_term = Enum.join(["process", "only", "private", "term"], "-")

    scanned_paths = [
      ".github/actions/private-check.yml",
      "script/private-check.sh",
      ".planning/phases/999-future-proof/999-NOTES.md"
    ]

    excluded_paths = [
      "test/fixtures/raw-evidence.md",
      "evidence/capture.bin"
    ]

    with_temporary_repository(
      scanned_paths ++ excluded_paths,
      "prefix #{private_term} suffix",
      fn root ->
        assert Enum.sort(scanned_paths) == FirstAdopterContext.discover_paths(root)

        assert scanned_paths
               |> Enum.map(&%{rule_id: "privacy.private_term", path: &1})
               |> Enum.sort_by(& &1.path) ==
                 FirstAdopterContext.scan_filesystem(root, [private_term])

        results = FirstAdopterContext.scan_filesystem(root, [private_term])
        refute inspect(results) =~ private_term
        refute inspect(results) =~ "prefix"
      end
    )
  end

  test "filesystem discovery fails closed for repository enumeration and unclassified text paths" do
    with_temporary_repository(["notes/unclassified.opaque"], "safe", fn root ->
      assert [
               %{rule_id: "routing.unclassified_path", path: "notes/unclassified.opaque"}
             ] = FirstAdopterContext.scan_filesystem(root, [])
    end)

    missing_root =
      Path.join(System.tmp_dir!(), "crosswake-missing-#{System.unique_integer([:positive])}")

    assert [
             %{rule_id: "routing.repository_enumeration_failed", path: "repository"}
           ] = FirstAdopterContext.scan_filesystem(missing_root, [])
  end

  test "filesystem discovery excludes raw fixtures and rejects symlink candidates before reads" do
    private_term = Enum.join(["fixture", "private", "canary"], "-")

    with_temporary_repository(["test/fixtures/raw.md"], private_term, fn root ->
      assert FirstAdopterContext.discover_paths(root) == []
      assert FirstAdopterContext.scan_filesystem(root, [private_term]) == []
    end)

    with_temporary_repository(["guides/target.md"], "safe", fn root ->
      link = Path.join(root, "guides/link.md")
      :ok = File.ln_s("target.md", link)
      {_, 0} = System.cmd("git", ["-C", root, "add", "guides/link.md"])

      assert [
               %{rule_id: "routing.unsafe_candidate_path", path: "guides/link.md"}
             ] = FirstAdopterContext.scan_filesystem(root, [])
    end)
  end

  test "filesystem discovery includes current Phase 158 planning artifacts" do
    discovered = FirstAdopterContext.discover_paths(File.cwd!())

    assert ".planning/phases/158-adoption-reset-and-route-map/158-VALIDATION.md" in discovered

    for path <-
          Path.wildcard(".planning/phases/158-adoption-reset-and-route-map/158-*-PLAN.md") ++
            Path.wildcard(".planning/phases/158-adoption-reset-and-route-map/158-*-SUMMARY.md") do
      assert path in discovered
    end
  end

  test "governing documents keep GET-6, the Alpha split, reversal conditions, stop list, and execution state discoverable" do
    assert File.read!("AGENTS.md") =~ ".planning/ADR-FIRST-B2C-ADOPTER.md"

    adr = File.read!(".planning/ADR-FIRST-B2C-ADOPTER.md")
    assert adr =~ "GET-6"
    assert adr =~ "Two independent active adopters"
    assert adr =~ "separately funded business-line mandate"
    assert adr =~ "web-only"
    assert adr =~ "Android"

    roadmap = File.read!(".planning/ROADMAP.md")
    assert roadmap =~ "Physical-iPhone Adoption Proof"
    assert roadmap =~ "2026-08-18"

    state = File.read!(".planning/STATE.md")
    assert state =~ "current_phase: 158"
    assert state =~ "Phase: 158 (adoption-reset-and-route-map)"
  end

  test "v20 remains stopped and partial while phases 156 and 157 stay outside active v21 scope" do
    v20_contents = Enum.map_join(@v20_paths, "\n", &File.read!/1)

    assert v20_contents =~ ~r/stopped\s*\/\s*partial|stopped\/partial/i
    assert v20_contents =~ "Phases 156-157"
    assert v20_contents =~ "not a shipped release"
    assert v20_contents =~ "no completion tag"

    active_v21 =
      File.read!(".planning/ROADMAP.md")
      |> String.split("## Frozen and stopped work", parts: 2)
      |> hd()

    refute active_v21 =~ ~r/Phase 156|Phase 157/
  end

  test "TODO-002 remains open until sanitized route rows are supplied" do
    todo = File.read!(".planning/todos/TODO-002-first-b2c-adopter-route-inputs.md")
    assert todo =~ ~r/status:\s*open/i
    assert todo =~ "sanitized"
  end

  defp contents_by_path do
    FirstAdopterContext.active_paths()
    |> Map.new(&{&1, File.read!(&1)})
  end

  defp with_temporary_repository(paths, contents, fun) do
    root = Path.join(System.tmp_dir!(), "crosswake-context-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)

    try do
      Enum.each(paths, fn path ->
        absolute_path = Path.join(root, path)
        File.mkdir_p!(Path.dirname(absolute_path))
        File.write!(absolute_path, contents)
      end)

      {_, 0} = System.cmd("git", ["init", "-q", root])
      {_, 0} = System.cmd("git", ["-C", root, "add", "-A"])
      fun.(root)
    after
      File.rm_rf!(root)
    end
  end
end
