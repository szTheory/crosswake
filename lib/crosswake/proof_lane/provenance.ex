defmodule Crosswake.ProofLane.Provenance do
  @moduledoc false

  # Reads the three provenance values the navigation-shell proof header carries.
  # Every value that cannot be known becomes an exact sentinel ("unknown" or
  # "git-unknown"); the evidence validator accepts those for advisory evidence only.

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
    # iOS manifest only; the Android manifest is frozen and not read.
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
    with git when is_binary(git) <- System.find_executable("git"),
         {out, 0} <-
           System.cmd(git, ["rev-parse", "HEAD"],
             cd: cwd,
             stderr_to_stdout: true,
             env: git_env()
           ),
         hex = String.trim(out),
         true <- Regex.match?(@hex, hex),
         # Tracked files only, so untracked build output does not erase the commit.
         # --no-optional-locks keeps the read from rewriting the index. A dirty tree
         # yields the sentinel: a HEAD that does not describe the verified code looks
         # real but is wrong.
         {"", 0} <-
           System.cmd(
             git,
             ["--no-optional-locks", "status", "--porcelain", "--untracked-files=no"],
             cd: cwd,
             stderr_to_stdout: true,
             env: git_env()
           ) do
      "git-" <> hex
    else
      _ -> "git-unknown"
    end
  rescue
    _ in [ErlangError, File.Error] -> "git-unknown"
  end

  defp git_env, do: [{"GIT_DIR", nil}, {"GIT_WORK_TREE", nil}, {"GIT_INDEX_FILE", nil}]
end
