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
      write_file(root, path, "amount $10")

      error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

      assert error.message =~ "privacy.commercial_detail #{path}"
      refute error.message =~ "amount"
    end)
  end

  test "raises stable private rule and path for future planning artifacts without echoing secret-backed content" do
    with_temporary_root(fn root ->
      term = Enum.join(["task", "private", "canary"], "-")

      paths = [
        ".planning/phases/158-adoption-reset-and-route-map/158-90-PLAN.md",
        ".planning/phases/158-adoption-reset-and-route-map/158-90-SUMMARY.md",
        ".planning/phases/158-adoption-reset-and-route-map/158-VALIDATION.md"
      ]

      Enum.each(paths, &write_file(root, &1, "prefix #{term} suffix"))

      with_private_terms(term, fn ->
        error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

        for path <- paths do
          assert error.message =~ "privacy.private_term #{path}"
        end

        refute error.message =~ term
        refute error.message =~ "prefix"
      end)
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
