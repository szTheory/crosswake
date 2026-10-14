defmodule Crosswake.Shell.ShellPackage do
  @moduledoc false
  # D-16(c): resolves which crosswake-shell-core-ios a host project uses and which host-command
  # seam version it carries. Everything that cannot be established returns an error or a nil
  # seam version, never a guess; callers treat that as blocked.

  @package "crosswake-shell-core-ios"
  @swift_relative "Sources/CrosswakeShellCore/ActivationCoordinator.swift"

  @type source ::
          {:local, Path.t()} | {:remote, String.t() | nil} | {:project, Path.t()}

  @doc """
  The first published crosswake-shell-core-ios release that carries the host-command seam.

  Returns nil: no published release carries the seam yet, so a remote package dependency can
  never satisfy the gate in this phase.
  """
  @spec first_seam_release() :: String.t() | nil
  def first_seam_release, do: nil

  @doc "Package name used in every diagnostic."
  def package_name, do: @package

  @spec resolve(source()) ::
          {:ok,
           %{
             kind: :local | :remote,
             seam_version: String.t() | nil,
             version: String.t() | nil,
             location: String.t()
           }}
          | {:error, term()}
  def resolve({:local, dir}) when is_binary(dir) do
    {:ok, %{kind: :local, seam_version: seam_version_at(dir), version: nil, location: dir}}
  end

  def resolve({:remote, version}) do
    {:ok,
     %{
       kind: :remote,
       seam_version: remote_seam_version(version),
       version: version,
       location: "remote #{@package}"
     }}
  end

  def resolve({:project, managed_root}) when is_binary(managed_root) do
    project = Path.join(managed_root, "CrosswakeShell.xcodeproj/project.pbxproj")

    with {:ok, bytes} <- File.read(project) do
      cond do
        match = Regex.run(~r/relativePath = "([^"]+)";/, bytes) ->
          [_, relative] = match
          resolve({:local, Path.expand(relative, managed_root)})

        match = Regex.run(~r/minimumVersion = ([0-9][0-9A-Za-z.\-+]*);/, bytes) ->
          [_, minimum] = match
          resolve({:remote, pinned_version(managed_root) || minimum})

        true ->
          {:error, :no_package_reference}
      end
    else
      {:error, _reason} -> {:error, :no_project}
    end
  end

  @doc """
  Reads `public static let version = "X.Y.Z"` from the `public enum HostCommandSeam`
  declaration in the package's ActivationCoordinator.swift; nil when absent or malformed.
  """
  @spec seam_version_at(Path.t()) :: String.t() | nil
  def seam_version_at(package_dir) do
    with {:ok, source} <- File.read(Path.join(package_dir, @swift_relative)),
         [_, body] <- Regex.run(~r/public\s+enum\s+HostCommandSeam\s*\{(.*?)\n\}/s, source),
         [_, version] <-
           Regex.run(~r/public\s+static\s+let\s+version\s*=\s*"([^"]*)"/, body),
         {:ok, _} <- Version.parse(version) do
      version
    else
      _ -> nil
    end
  end

  @doc """
  The gate verdict for a resolved package: `:ok` or `{:error, found, location}` where `found`
  is a plain-language statement of what was established.
  """
  @spec satisfies?(map(), String.t()) :: :ok | {:error, String.t()}
  def satisfies?(%{seam_version: nil, kind: :remote, version: version}, _required) do
    {:error,
     "remote #{@package} #{version || "(version unknown)"} carries no host-command seam release"}
  end

  def satisfies?(%{seam_version: nil}, _required) do
    {:error, "no HostCommandSeam version declaration was found"}
  end

  def satisfies?(%{seam_version: found}, required) do
    if Version.compare(found, required) in [:eq, :gt],
      do: :ok,
      else: {:error, "HostCommandSeam version #{found} is older than #{required}"}
  end

  defp remote_seam_version(version) do
    with release when is_binary(release) <- first_seam_release(),
         true <- is_binary(version) and match?({:ok, _}, Version.parse(version)),
         true <- Version.compare(version, release) in [:eq, :gt] do
      Crosswake.HostCommands.seam_version()
    else
      _ -> nil
    end
  end

  defp pinned_version(managed_root) do
    managed_root
    |> Path.join("CrosswakeShell.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
    |> File.read()
    |> case do
      {:ok, bytes} ->
        with {:ok, %{"pins" => pins}} <- Jason.decode(bytes),
             %{"state" => %{"version" => version}} when is_binary(version) <-
               Enum.find(pins, &String.contains?(Map.get(&1, "location", ""), @package)) do
          version
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end
end
