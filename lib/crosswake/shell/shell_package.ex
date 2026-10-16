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

  @outside "<outside project>"
  @max_symlink_hops 32

  @doc false
  # D-06: the only form in which a package location may be printed. Inside the project it is
  # project-relative, under the home directory it is "<home>/...", anything else is
  # "<outside project>". There is deliberately no clause that returns the raw input.
  @spec display_location(term(), term()) :: String.t()
  def display_location("remote " <> _ = location, _project_root), do: location

  def display_location(location, project_root)
      when is_binary(location) and is_binary(project_root) do
    with :absolute <- Path.type(location),
         :absolute <- Path.type(project_root),
         {:ok, location_parts} <- canonical(location),
         {:ok, root_parts} <- canonical(project_root) do
      cond do
        inside?(location_parts, root_parts) ->
          # Only the inside branch of gen.shell relative_path/2 is copied: that function
          # would leak a ".." chain for paths outside the project.
          case Enum.drop(location_parts, length(root_parts)) do
            [] -> "."
            rest -> Path.join(rest)
          end

        home_rest = home_remainder(location_parts) ->
          Path.join(["<home>" | home_rest])

        true ->
          @outside
      end
    else
      _ -> @outside
    end
  end

  def display_location(_location, _project_root), do: @outside

  defp home_remainder(location_parts) do
    with home when is_binary(home) <- home_dir(),
         {:ok, home_parts} <- canonical(home),
         true <- home_parts != ["/"] and inside?(location_parts, home_parts) do
      Enum.drop(location_parts, length(home_parts))
    else
      _ -> nil
    end
  end

  defp home_dir do
    System.user_home!()
  rescue
    _ -> nil
  end

  # Component-wise containment: /p/proj-evil is not inside /p/proj.
  defp inside?(parts, prefix), do: Enum.take(parts, length(prefix)) == prefix

  # Expands the path and resolves symlinks component by component, at most 32 hops in total.
  # A nonexistent tail is kept lexically. Returns {:ok, components} or :error on hop exhaustion.
  defp canonical(path), do: walk(Path.split(Path.expand(path)), [], @max_symlink_hops)

  defp walk([], resolved, _hops), do: {:ok, Enum.reverse(resolved)}

  defp walk([part | rest], resolved, hops) do
    current = Path.join(Enum.reverse([part | resolved]))

    case File.read_link(current) do
      {:ok, target} ->
        if hops == 0 do
          :error
        else
          parent = Path.join(Enum.reverse(resolved) ++ [""])
          walk(Path.split(Path.expand(target, parent)) ++ rest, [], hops - 1)
        end

      {:error, _} ->
        walk(rest, [part | resolved], hops)
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
    |> Path.join(
      "CrosswakeShell.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
    )
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
