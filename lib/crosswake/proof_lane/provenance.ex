defmodule Crosswake.ProofLane.Provenance do
  @moduledoc false

  # Reads the three provenance values the navigation-shell proof header carries.
  # Every value that cannot be known becomes an exact sentinel ("unknown" or
  # "git-unknown"); the evidence validator accepts those for advisory evidence only.

  alias Crosswake.ProofLane.GitPins

  @hex ~r/^[0-9a-f]{40}([0-9a-f]{24})?$/

  @spec read(Path.t()) :: %{
          crosswake_version: String.t(),
          template_version: String.t(),
          commit_ref: String.t()
        }
  def read(cwd) do
    %{
      crosswake_version: crosswake_version(),
      template_version: template_version(cwd),
      commit_ref: commit_ref(cwd)
    }
  end

  @doc false
  @spec crosswake_version() :: String.t()
  def crosswake_version do
    _ = Application.load(:crosswake)

    case Application.spec(:crosswake, :vsn) do
      nil -> "unknown"
      vsn -> to_string(vsn)
    end
  end

  @doc false
  @spec template_version(Path.t()) :: String.t()
  def template_version(cwd) do
    # iOS manifest only; the Android manifest is not read by this provenance check.
    path = Path.join([cwd, "native", "ios", "crosswake_shell", ".crosswake", "shell.json"])

    with {:ok, bytes} <- File.read(path),
         {:ok, %{"template_version" => n}} when is_integer(n) and n in 1..99_999_999 <-
           Jason.decode(bytes) do
      Integer.to_string(n)
    else
      _ -> generator_template_version()
    end
  end

  defp generator_template_version do
    case Mix.Tasks.Crosswake.Gen.Shell.template_version() do
      n when is_integer(n) and n in 1..99_999_999 -> Integer.to_string(n)
      _ -> "unknown"
    end
  end

  @doc false
  @spec commit_ref(Path.t()) :: String.t()
  def commit_ref(cwd) do
    # stderr is folded into the captured output only so it never reaches the console;
    # the output is used solely through a hex regex match (D-05).
    # A folder that is not itself the work-tree root (a nested host) is never given the
    # enclosing repository's commit.
    with git when is_binary(git) <- System.find_executable("git"),
         {top, 0} <- git(git, cwd, ["rev-parse", "--show-toplevel"]),
         true <- work_tree_root?(String.trim_trailing(top, "\n"), cwd),
         {out, 0} <- git(git, cwd, ["rev-parse", "HEAD"]),
         hex = String.trim(out),
         true <- Regex.match?(@hex, hex),
         # Tracked files only, so untracked build output does not erase the commit.
         # --no-optional-locks (in the pins) keeps the read from rewriting the index. A dirty
         # tree yields the sentinel: a HEAD that does not describe the verified code looks
         # real but is wrong.
         {"", 0} <- git(git, cwd, ["status", "--porcelain", "--untracked-files=no"]) do
      "git-" <> hex
    else
      _ -> "git-unknown"
    end
  rescue
    _ in [ErlangError, File.Error] -> "git-unknown"
  end

  defp git(git, cwd, args) do
    System.cmd(git, GitPins.pins() ++ args,
      cd: cwd,
      stderr_to_stdout: true,
      env: GitPins.spawn_env()
    )
  end

  # Same folder means the same {device, inode}, so a symlinked or /var vs /private/var
  # spelling of the root still matches without a string compare.
  defp work_tree_root?(top, cwd) do
    with {:ok, a} <- File.stat(top),
         {:ok, b} <- File.stat(cwd) do
      {a.major_device, a.inode} == {b.major_device, b.inode}
    else
      _ -> false
    end
  end
end
