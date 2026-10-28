defmodule Crosswake.Proof.GitObjectAtTest do
  use ExUnit.Case, async: true

  alias Crosswake.Test.GitObjectAt

  @moduletag :tmp_dir

  test "reads a pinned commit the checkout already holds", %{tmp_dir: dir} do
    {origin, [first, _second]} = origin(dir)

    assert GitObjectAt.read!(origin, first, "subject.txt") == "first\n"
  end

  test "fetches a pinned commit a shallow checkout lacks, then reads it", %{tmp_dir: dir} do
    {origin, [first, _second]} = origin(dir)
    shallow = Path.join(dir, "shallow")
    git!(dir, ["clone", "--quiet", "--depth=1", "file://" <> origin, shallow])

    assert {_, code} =
             System.cmd("git", ["cat-file", "-e", first <> "^{commit}"],
               cd: shallow,
               stderr_to_stdout: true
             )

    assert code != 0

    assert GitObjectAt.read!(shallow, first, "subject.txt") == "first\n"
  end

  test "raises when the pinned commit cannot be fetched", %{tmp_dir: dir} do
    {origin, _} = origin(dir)
    shallow = Path.join(dir, "shallow")
    git!(dir, ["clone", "--quiet", "--depth=1", "file://" <> origin, shallow])
    missing = String.duplicate("0", 39) <> "1"

    error =
      assert_raise RuntimeError, fn -> GitObjectAt.read!(shallow, missing, "subject.txt") end

    assert error.message =~ "pinned commit #{missing} is not in this checkout"
  end

  test "raises when the path does not exist at the pinned commit", %{tmp_dir: dir} do
    {origin, [first, _]} = origin(dir)

    error = assert_raise RuntimeError, fn -> GitObjectAt.read!(origin, first, "absent.txt") end
    assert error.message =~ "cannot read absent.txt at pinned commit #{first}"
  end

  test "rejects a pin that is not a full sha", %{tmp_dir: dir} do
    {origin, [first, _]} = origin(dir)

    assert_raise ArgumentError, fn -> GitObjectAt.read!(origin, "main", "subject.txt") end
    assert_raise ArgumentError, fn -> GitObjectAt.read!(origin, first <> "\n", "subject.txt") end
  end

  defp origin(dir) do
    origin = Path.join(dir, "origin")
    File.mkdir_p!(origin)
    git!(origin, ["init", "--quiet", "--initial-branch=main"])

    shas =
      for content <- ["first\n", "second\n"] do
        File.write!(Path.join(origin, "subject.txt"), content)
        git!(origin, ["add", "subject.txt"])

        git!(origin, [
          "-c",
          "user.name=fixture",
          "-c",
          "user.email=fixture@example.invalid",
          "commit",
          "--quiet",
          "-m",
          content
        ])

        origin |> git!(["rev-parse", "HEAD"]) |> String.trim()
      end

    {origin, shas}
  end

  defp git!(cd, args) do
    {output, 0} = System.cmd("git", args, cd: cd, stderr_to_stdout: true)
    output
  end
end
