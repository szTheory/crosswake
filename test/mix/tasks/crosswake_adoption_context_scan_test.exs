defmodule Mix.Tasks.Crosswake.AdoptionContext.ScanTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Mix.Tasks.Crosswake.AdoptionContext.Scan

  test "scans a clean supplied root" do
    with_temporary_root(fn root ->
      assert capture_io(fn -> Scan.run(["--root", root]) end) =~ "adoption context scan passed"
    end)
  end

  test "raises stable generic rule and relative path without file content" do
    with_temporary_root(fn root ->
      path = "guides/capability_map.md"
      write_file(root, path, "amount " <> "$" <> "10")

      error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

      assert error.message =~ "privacy.commercial_detail #{path}"
      refute error.message =~ "amount"
    end)
  end

  test "rejects zero, one-digit, two-digit, and decimal dollar amounts without echoing matches" do
    with_temporary_root(fn root ->
      path = "guides/capability_map.md"

      for amount <- ["$" <> "0", "$" <> "1", "$" <> "10", "$" <> "1.25"] do
        write_file(root, path, "first adopter amount #{amount}")

        error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

        assert error.message == "privacy.commercial_detail #{path}"
        refute error.message =~ amount
        refute error.message =~ "amount"
      end
    end)
  end

  test "detects single-digit commercial prose but accepts shell positional placeholders" do
    zero = "$" <> "0"
    one = "$" <> "1"

    for path <- ["notes/price.md", "notes/price.html", "notes/price.svg"] do
      with_temporary_root(fn root ->
        write_file(root, path, "commercial amount #{zero} or #{one}")

        error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

        assert error.message == "privacy.commercial_detail #{path}"
        refute error.message =~ zero
        refute error.message =~ one
      end)
    end

    with_temporary_root(fn root ->
      write_file(root, "script/positional-placeholder.sh", "printf '%s' \"#{one}\"\n")
      assert capture_io(fn -> Scan.run(["--root", root]) end) =~ "adoption context scan passed"
    end)
  end

  test "raises the hyphenated public phrase rule and path without echoing matched text" do
    with_temporary_root(fn root ->
      path = "guides/capability_map.md"
      hyphenated_phrase = Enum.join(["first", "adopter"], "-")
      write_file(root, path, "#{hyphenated_phrase} route ownership")

      error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

      assert error.message =~ "privacy.public_phrase #{path}"
      assert error.message =~ "privacy.public_phrase_hyphenated #{path}"
      refute error.message =~ hyphenated_phrase
      refute error.message =~ "route ownership"
    end)
  end

  test "raises the identifying-field rule and path without echoing a synthetic value" do
    with_temporary_root(fn root ->
      path = "guides/capability_map.md"
      synthetic_value = Enum.join(["synthetic", "value"], "-")
      write_file(root, path, "first adopter " <> "customer" <> "Email: #{synthetic_value}")

      error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

      assert error.message == "privacy.identifying_field #{path}"
      refute error.message =~ synthetic_value
      refute error.message =~ "customerEmail"
    end)
  end

  test "raises stable private rule and path for unregistered guide and later-phase artifacts without echoing secret-backed content" do
    with_temporary_root(fn root ->
      term = Enum.join(["task", "private", "canary"], "-")

      paths = [
        "guides/unregistered-adoption-note.md",
        ".planning/phases/159-host-reusable-proof-lane/159-NOTES.md"
      ]

      Enum.each(paths, &write_file(root, &1, "prefix #{term} suffix"))

      with_private_terms(term, fn ->
        error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

        assert error.message ==
                 paths
                 |> Enum.map(&"privacy.private_term #{&1}")
                 |> Enum.sort()
                 |> Enum.join("\n")

        refute error.message =~ term
        refute error.message =~ "prefix"
      end)
    end)
  end

  test "scans textual SVG artifacts without echoing secret-backed content" do
    with_temporary_root(fn root ->
      path = "guides/route-ownership.svg"
      term = Enum.join(["svg", "private", "canary"], "-")
      write_file(root, path, "<svg><text>#{term}</text></svg>")

      with_private_terms(term, fn ->
        error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

        assert error.message == "privacy.private_term #{path}"
        refute error.message =~ term
        refute error.message =~ "<svg>"
      end)
    end)
  end

  test "raises sorted private-term paths for action, script, and future-phase candidates" do
    with_temporary_root(fn root ->
      term = Enum.join(["process", "only", "private", "term"], "-")

      paths = [
        ".github/actions/private-check.yml",
        "script/private-check.sh",
        ".planning/phases/999-future-proof/999-NOTES.md"
      ]

      Enum.each(paths, &write_file(root, &1, "prefix #{term} suffix"))

      with_private_terms(term, fn ->
        error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

        assert error.message ==
                 paths
                 |> Enum.map(&"privacy.private_term #{&1}")
                 |> Enum.sort()
                 |> Enum.join("\n")

        refute error.message =~ term
        refute error.message =~ "prefix"
      end)
    end)
  end

  test "raises commercial-detail privacy violations for prose artifacts" do
    with_temporary_root(fn root ->
      paths = [
        "guides/unregistered-commercial-note.md",
        "lib/crosswake/unregistered_commercial_scan.ex",
        ".github/actions/unregistered-commercial-scan.yml",
        "script/unregistered-commercial-scan.sh",
        ".planning/phases/999-future-proof/999-COMMERCIAL-NOTES.md"
      ]

      commercial_detail = "amount " <> "$" <> "10"
      Enum.each(paths, &write_file(root, &1, commercial_detail))

      error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

      assert error.message ==
               Enum.filter(paths, &(Path.extname(&1) == ".md"))
               |> Enum.map(&"privacy.commercial_detail #{&1}")
               |> Enum.sort()
               |> Enum.join("\n")

      refute error.message =~ commercial_detail
      refute error.message =~ "amount"
    end)
  end

  test "fails closed when private terms are required but unavailable" do
    with_temporary_root(fn root ->
      with_private_terms(nil, fn ->
        error =
          assert_raise Mix.Error, fn ->
            Scan.run(["--root", root, "--require-private-terms"])
          end

        assert error.message == "privacy.private_terms_required secret.input"
      end)
    end)
  end

  test "workflow runs the protected scan only for trusted provenance and blocks fork bypasses" do
    workflow = File.read!(".github/workflows/hex-page-proof.yml")

    trusted_condition =
      "github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository"

    fork_condition =
      "github.event_name == 'pull_request' && github.event.pull_request.head.repo.full_name != github.repository"

    assert workflow =~ "name: Enforce protected first-adopter private-term gate"
    assert workflow =~ "if: #{trusted_condition}"

    assert workflow =~
             "CROSSWAKE_PRIVATE_ADOPTER_TERMS: ${{ secrets.CROSSWAKE_PRIVATE_ADOPTER_TERMS }}"

    assert workflow =~ "mix crosswake.adoption_context.scan --require-private-terms"

    assert workflow =~ "name: Block untrusted fork protected-check bypass"
    assert workflow =~ "if: #{fork_condition}"
    assert workflow =~ "privacy.private_terms_trusted_maintainer_required"
    refute workflow =~ "pull_request_target"
  end

  defp with_temporary_root(fun) do
    root = Path.join(System.tmp_dir!(), "crosswake-scan-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    {_, 0} = System.cmd("git", ["init", "-q", root])

    try do
      fun.(root)
    after
      File.rm_rf!(root)
    end
  end

  defp write_file(root, path, contents) do
    absolute_path = Path.join(root, path)
    File.mkdir_p!(Path.dirname(absolute_path))
    File.write!(absolute_path, contents)
  end

  defp with_private_terms(value, fun) do
    previous = System.get_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS")

    if value,
      do: System.put_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS", value),
      else: System.delete_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS")

    try do
      fun.()
    after
      if previous,
        do: System.put_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS", previous),
        else: System.delete_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS")
    end
  end
end
