defmodule Crosswake.Test.GitObjectAt do
  @moduledoc """
  Reads a file's bytes at a recorded commit, fetching that one commit when the
  checkout does not hold it.

  Ratchet receipts pin the actual-main commit they were measured on, and their
  tests re-read each subject at that commit. A developer clone holds the commit;
  a CI proof job's shallow checkout does not, and `git show` there exits 128.
  This helper fetches the single missing commit (`--depth=1`) and reads again.

  It never degrades to a skip: when the commit still cannot be read after the
  fetch, it raises naming the commit, the path and git's own error. A missing
  pinned commit must fail the proof, not shrink it to nothing.
  """

  @sha ~r/\A[0-9a-f]{40}\z/

  @doc "Return the bytes of `path` at full commit `sha` in the repository at `root`."
  @spec read!(Path.t(), String.t(), String.t()) :: binary()
  def read!(root, sha, path) do
    unless is_binary(sha) and sha =~ @sha do
      raise ArgumentError, "pinned commit must be a 40-character sha, got: #{inspect(sha)}"
    end

    unless present?(root, sha) do
      fetch(root, sha)
    end

    case System.cmd("git", ["show", sha <> ":" <> path], cd: root, stderr_to_stdout: true) do
      {bytes, 0} ->
        bytes

      {output, code} ->
        raise "cannot read #{path} at pinned commit #{sha} (git exit #{code}): #{String.trim(output)}"
    end
  end

  defp present?(root, sha) do
    {_, code} =
      System.cmd("git", ["cat-file", "-e", sha <> "^{commit}"], cd: root, stderr_to_stdout: true)

    code == 0
  end

  defp fetch(root, sha) do
    case System.cmd("git", ["fetch", "--quiet", "--no-tags", "--depth=1", "origin", sha],
           cd: root,
           stderr_to_stdout: true
         ) do
      {_, 0} ->
        :ok

      {output, code} ->
        raise "pinned commit #{sha} is not in this checkout and fetching it failed " <>
                "(git exit #{code}): #{String.trim(output)}"
    end
  end
end
