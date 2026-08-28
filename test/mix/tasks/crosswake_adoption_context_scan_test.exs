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

  test "workflow runs the repository privacy scan without a secret-backed denylist" do
    workflow = File.read!(".github/workflows/hex-page-proof.yml")

    assert workflow =~ "name: Enforce first-adopter privacy gate"
    assert workflow =~ "run: mix crosswake.adoption_context.scan"
    refute workflow =~ "CROSSWAKE_PRIVATE_ADOPTER_TERMS"
    refute workflow =~ "require-private-terms"
  end

  test "scans only the approved marker and host AIFF while rejecting arbitrary binary peers" do
    completion_marker =
      ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/.complete"

    reference_aiff =
      "examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff"

    with_temporary_root(fn root ->
      write_file(root, completion_marker, "safe")
      write_file(root, reference_aiff, "safe")

      assert capture_io(fn -> Scan.run(["--root", root]) end) =~ "adoption context scan passed"
    end)

    for path <- [
          "examples/phoenix_host/native/ios/OtherBundle/pronunciation.aiff",
          "artifacts/capture.bin"
        ] do
      with_temporary_root(fn root ->
        write_file(root, path, "safe")

        error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

        assert error.message == "routing.unclassified_path #{path}"
      end)
    end
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
end
