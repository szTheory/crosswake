defmodule Crosswake.Proof.Phase164ExUnitOwnershipTest do
  @moduledoc """
  CIG-02: every intended ExUnit file must contain a runnable test owned by a merge-blocking class.

  Ownership comes from parsed ExUnit tags, never comments, strings, neighboring modules, or copied
  file counts. The default/hermetic class owns ordinary tests; the dedicated example-host class
  owns executable `:requires_example_host` tests.
  """
  use ExUnit.Case, async: true

  @script "script/check_exunit_ownership.exs"

  defp prepare_tree!(tmp, source, opts \\ []) do
    path = Keyword.get(opts, :path, "test/sample_test.exs")
    full_path = Path.join(tmp, path)
    File.mkdir_p!(Path.dirname(full_path))
    File.write!(full_path, source)

    workflow = Path.join(tmp, ".github/workflows/crosswake-ci.yml")
    File.mkdir_p!(Path.dirname(workflow))

    default_lane =
      unless Keyword.get(opts, :without_default_lane, false) do
        """
          phase130-core-hermetic-proof:
            name: phase130-core-hermetic-proof
            runs-on: ubuntu-latest
            steps:
              - run: mix test --exclude requires_example_host --exclude advisory_only
        """
      end

    example_lane =
      unless Keyword.get(opts, :without_example_lane, false) do
        """
          proof-requires-example-host:
            name: proof-requires-example-host
            runs-on: ubuntu-latest
            steps:
              - run: script/check_example_host_isolation.sh --matrix-only
              - run: mix test --only requires_example_host
        """
      end

    File.write!(workflow, "name: Crosswake CI\njobs:\n#{default_lane}#{example_lane}")

    path
  end

  defp run_detector(root) do
    System.cmd("elixir", [@script, "--root", root], stderr_to_stdout: true)
  end

  test "the live test tree has a merge-blocking owner for every intended file" do
    {out, status} = run_detector(".")

    assert status == 0, out
    assert out =~ "all intended ExUnit files are owned"
    refute out =~ ~r/\b\d+ files?\b/
  end

  @tag :tmp_dir
  test "an ordinary runnable test belongs to the default hermetic class", %{tmp_dir: tmp} do
    prepare_tree!(tmp, """
    defmodule DefaultOwnedTest do
      use ExUnit.Case
      test "runs by default", do: assert(true)
    end
    """)

    {out, status} = run_detector(tmp)

    assert status == 0, out
    assert out =~ "default/hermetic"
  end

  @tag :tmp_dir
  test "the default hermetic class fails closed when its broad merge-blocking lane is missing", %{
    tmp_dir: tmp
  } do
    prepare_tree!(
      tmp,
      """
      defmodule DefaultWithoutLaneTest do
        use ExUnit.Case
        test "would be unowned", do: assert(true)
      end
      """,
      without_default_lane: true
    )

    {out, status} = run_detector(tmp)

    assert status == 1
    assert out =~ "missing-execution-class"
    assert out =~ "crosswake-ci.yml"
    assert out =~ "phase130-core-hermetic-proof"
    assert out =~ "restore phase130-core-hermetic-proof"
  end

  @tag :tmp_dir
  test "module-level and per-test example-host tags belong to the dedicated class", %{
    tmp_dir: tmp
  } do
    prepare_tree!(tmp, """
    defmodule ModuleTaggedTest do
      use ExUnit.Case
      @moduletag :requires_example_host
      test "module owned", do: assert(true)
    end

    defmodule PerTestTaggedTest do
      use ExUnit.Case
      @tag requires_example_host: true
      test "test owned", do: assert(true)
    end
    """)

    {out, status} = run_detector(tmp)

    assert status == 0, out
    assert out =~ "requires_example_host"
  end

  @tag :tmp_dir
  test "an exclusion-only file is unowned with path, effective exclusion, and remediation", %{
    tmp_dir: tmp
  } do
    path =
      prepare_tree!(tmp, """
      defmodule SkippedOnlyTest do
        use ExUnit.Case
        @moduletag :skip
        test "not in a merge lane", do: assert(true)
      end
      """)

    {out, status} = run_detector(tmp)

    assert status == 1
    assert out =~ "unowned-exunit-file"
    assert out =~ path
    assert out =~ "skip"
    assert out =~ "remove/move the exclusion"
    assert out =~ "add the class to a merge-blocking lane"
  end

  @tag :tmp_dir
  test "comments and strings cannot confer example-host ownership", %{tmp_dir: tmp} do
    path =
      prepare_tree!(tmp, """
      defmodule LexicalLookalikeTest do
        use ExUnit.Case
        @moduletag :skip
        # @tag :requires_example_host
        @message "@moduletag :requires_example_host"
        test "still advisory only", do: assert(@message != "")
      end
      """)

    {out, status} = run_detector(tmp)

    assert status == 1
    assert out =~ "unowned-exunit-file"
    assert out =~ path
    refute out =~ "owned by requires_example_host"
  end

  @tag :tmp_dir
  test "empty and malformed test sources fail closed with their paths", %{tmp_dir: tmp} do
    empty = prepare_tree!(tmp, "# no executable tests\n", path: "test/empty_test.exs")
    malformed = prepare_tree!(tmp, "defmodule Broken do\n", path: "test/broken_test.exs")

    {out, status} = run_detector(tmp)

    assert status == 1
    assert out =~ "no-runnable-tests"
    assert out =~ empty
    assert out =~ "malformed-exunit-source"
    assert out =~ malformed
  end

  @tag :tmp_dir
  test "the example-host class fails closed when its merge-blocking lane is missing", %{
    tmp_dir: tmp
  } do
    prepare_tree!(
      tmp,
      """
      defmodule HostWithoutLaneTest do
        use ExUnit.Case
        @moduletag :requires_example_host
        test "would be unowned", do: assert(true)
      end
      """,
      without_example_lane: true
    )

    {out, status} = run_detector(tmp)

    assert status == 1
    assert out =~ "missing-execution-class"
    assert out =~ "crosswake-ci.yml"
    assert out =~ "proof-requires-example-host"
  end
end
