defmodule Crosswake.ReleaseCandidate.PackageSourceRefTest do
  use ExUnit.Case, async: true

  @head String.duplicate("a", 40)
  @tag_sha String.duplicate("b", 40)
  @script Path.expand("../../../script/release_candidate/package_source_ref.sh", __DIR__)

  @tag :tmp_dir
  test "published companions resolve their release tag independently of candidate head", ctx do
    {output, status} = run(ctx.tmp_dir, "published", "crosswake_sigra", "public")
    assert status == 0
    assert String.trim(output) == @tag_sha
  end

  @tag :tmp_dir
  test "only unpublished candidate packages may fall back to candidate source", ctx do
    assert {String.trim(@head) <> "\n", 0} ==
             run(ctx.tmp_dir, "absent", "crosswake_sigra", "candidate")

    assert {"", 1} == run(ctx.tmp_dir, "absent", "crosswake_sigra", "public")
  end

  @tag :tmp_dir
  test "provider failure and missing tagged objects fail closed", ctx do
    for scenario <- ["provider_failed", "missing_object"] do
      {_output, status} = run(ctx.tmp_dir, scenario, "crosswake_sigra", "candidate")
      assert status != 0
    end
  end

  @tag :tmp_dir
  test "core remains bound to independently checked candidate commit", ctx do
    assert {@head <> "\n", 0} == run(ctx.tmp_dir, "provider_failed", "crosswake", "public")
  end

  defp run(tmp, scenario, package, mode) do
    shim = Path.join(tmp, "git")

    File.write!(shim, """
    #!/bin/bash
    shift 2
    case "$1" in
      ls-remote)
        case "$SOURCE_TEST_SCENARIO" in
          provider_failed) exit 7 ;;
          absent) exit 0 ;;
          *) printf '%s\\t%s\\n' '#{@tag_sha}' 'refs/tags/crosswake_sigra-v0.1.3' ;;
        esac ;;
      cat-file) exit 0 ;;
      rev-parse)
        [ "$SOURCE_TEST_SCENARIO" != missing_object ] || exit 9
        printf '%s\\n' '#{@tag_sha}' ;;
      *) exit 10 ;;
    esac
    """)

    File.chmod!(shim, 0o755)

    System.cmd("bash", [@script, tmp, package, "0.1.3", @head, mode],
      env: [{"PATH", tmp <> ":" <> System.get_env("PATH")}, {"SOURCE_TEST_SCENARIO", scenario}],
      stderr_to_stdout: true
    )
  end
end
