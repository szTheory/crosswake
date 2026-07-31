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

  test "raises stable private rule and path without echoing secret-backed content" do
    with_temporary_root(fn root ->
      term = Enum.join(["task", "private", "canary"], "-")
      path = ".planning/phases/158-adoption-reset-and-route-map/158-90-PLAN.md"
      write_file(root, path, "prefix #{term} suffix")

      with_private_terms(term, fn ->
        error = assert_raise Mix.Error, fn -> Scan.run(["--root", root]) end

        assert error.message =~ "privacy.private_term #{path}"
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
