defmodule Mix.Tasks.Crosswake.Gen.BridgeHook do
  @moduledoc """
  Teaches you how to wire the library-owned bridge hook — and, with `--eject`,
  writes a host-owned copy you then own forever.

  ## Why this task refuses by default

  Run with no flag, this task writes NOTHING and prints the three wiring fragments.
  The refusal IS the feature (D-33): the hook is the primary onboarding surface for
  the bridge, and a refusal you hit while reaching for a generator teaches more
  reliably than a guide nobody opens.

  Crosswake's own package-design rule is: use generators when adopters need editable
  app code, and keep security- and protocol-sensitive behavior library-owned. The
  no-component-tier anti-feature governs PRESENTATION — things adopters restyle.
  `priv/static/crosswake.esm.js` is not presentation: it is the client half of a
  versioned wire protocol whose one job is deciding whether a denial gets synthesized
  when there is no shell (D-30, D-31). A host-owned copy of that file means silent
  protocol drift on the exact code that decides whether the fail-closed contract
  holds.

  It also would not work here. The reference host has NO bundler at all — its endpoint
  serves dependency JavaScript through `Plug.Static` and its layout imports from a
  bare `<script type="module">` — so a generator writing into `assets/js/` would write
  into a directory nothing builds (D-32). That is why the eject target is the host's
  own `priv/static/`, not its assets tree.

  ## Usage

      mix crosswake.gen.bridge_hook            # refuses, prints the wiring
      mix crosswake.gen.bridge_hook --eject    # writes a stamped host-owned copy

  ## Options

    * `--eject` — write a host-owned copy carrying a protocol-version stamp
    * `--dir` — the target host directory (defaults to the current directory)
    * `--path` — the eject destination relative to `--dir`
      (defaults to `priv/static/crosswake.esm.js`)

  ## The stamp

  An ejected copy carries a protocol-version header. `mix crosswake.doctor` compares
  that stamp against `Crosswake.Bridge.Contract.version/0` and warns when the copy has
  fallen behind the protocol it speaks (T-154-26). Re-running the eject never
  clobbers a host-owned copy and never duplicates the stamp.
  """
  use Mix.Task

  alias Crosswake.Bridge.Contract
  alias Crosswake.Install.Patcher

  @shortdoc "Prints the bridge hook wiring; writes a host-owned copy only with --eject"

  @switches [eject: :boolean, dir: :string, path: :string]

  @default_eject_path "priv/static/crosswake.esm.js"

  @stamp_prefix "/* crosswake:bridge-hook:ejected"

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    dir = Path.expand(opts[:dir] || File.cwd!())
    relative_path = opts[:path] || @default_eject_path

    if opts[:eject] do
      eject(dir, relative_path)
    else
      refuse_and_teach(relative_path)
    end
  end

  # ---------------------------------------------------------------------------
  # The refusal — the primary teaching surface (D-33)
  # ---------------------------------------------------------------------------

  defp refuse_and_teach(relative_path) do
    [plug_block, layout_import, hooks_map, hook_element] = wiring_fragments()

    Mix.shell().info("""
    Crosswake did not generate anything, on purpose.

    The bridge hook is library-owned. It ships from the Crosswake package's own
    static directory as one dependency-free ESM file with no build step, and it is
    NOT published to a second package registry — a second registry would open a
    second version axis on the exact file that decides whether a missing shell
    produces an honest denial.

    Wire the shipped file instead. Three fragments, all of them host-owned:

    1. Endpoint — serve the hook (this one `mix crosswake.install` can patch for you):

    #{plug_block}

    2. Layout — import the hook and register it in the socket's hooks map:

           #{layout_import}
           #{hooks_map}

    3. Layout — one hook element per page (client events broadcast to EVERY mounted
       hook, so a second element would post every request to the shell twice):

           #{hook_element}

    Then confirm the wiring with:

        mix crosswake.doctor

    If you genuinely need a host-owned copy — a patched transport, a vendored
    build — eject one:

        mix crosswake.gen.bridge_hook --eject

    The ejected copy is written to #{relative_path} and carries a protocol-version
    stamp so `mix crosswake.doctor` can tell you when it has fallen behind the
    protocol it speaks. You own it from that moment on.
    """)
  end

  # ---------------------------------------------------------------------------
  # The eject — a deliberately inconvenient escape valve
  # ---------------------------------------------------------------------------

  defp eject(dir, relative_path) do
    destination = Path.join(dir, relative_path)

    case File.read(destination) do
      {:ok, _existing} ->
        Mix.shell().info("""
          reused #{relative_path} (host-owned; the eject never clobbers your copy)

        Delete the file and re-run the eject to take a fresh stamped copy.
        """)

        :reused

      {:error, :enoent} ->
        File.mkdir_p!(Path.dirname(destination))
        File.write!(destination, stamped_hook_source(relative_path))

        Mix.shell().info("""
          created #{relative_path} (stamped protocol #{Contract.version()})

        You now own this file. `mix crosswake.doctor` warns when its stamp falls
        behind Crosswake.Bridge.Contract.version/0 — that warning is the only thing
        standing between an ejected copy and silent protocol drift.

        Serve it from your own endpoint and import it from your layout:

            import {#{Patcher.hook_name()}} from "/#{served_path(relative_path)}";
        """)

        :created

      {:error, reason} ->
        Mix.raise("could not write #{destination}: #{:file.format_error(reason)}")
    end
  end

  defp stamped_hook_source(relative_path) do
    stamp(relative_path) <> "\n" <> hook_source()
  end

  defp stamp(relative_path) do
    """
    #{@stamp_prefix} protocol=#{Contract.version()}
     *
     * Host-owned copy of the Crosswake bridge hook, ejected to #{relative_path}.
     * You own this file: Crosswake will never rewrite it, and re-running
     * `mix crosswake.gen.bridge_hook --eject` reuses it rather than clobbering it.
     *
     * The `protocol=` value above is the wire protocol this copy speaks.
     * `mix crosswake.doctor` compares it against Crosswake.Bridge.Contract.version/0
     * and warns when this copy has fallen behind. Do not edit the stamp by hand —
     * a stamp that lies is worse than no stamp at all.
     */
    """
  end

  @doc false
  @spec stamp_prefix() :: String.t()
  def stamp_prefix, do: @stamp_prefix

  defp served_path(relative_path) do
    relative_path
    |> Path.relative_to("priv/static")
    |> String.trim_leading("/")
  end

  defp hook_source do
    source_path()
    |> File.read!()
  end

  defp source_path do
    app_path = Application.app_dir(:crosswake, "priv/static/crosswake.esm.js")

    if File.exists?(app_path) do
      app_path
    else
      Path.join(File.cwd!(), "priv/static/crosswake.esm.js")
    end
  end

  defp wiring_fragments do
    [import_line, hooks_map_line, hook_element] = Patcher.layout_wiring_lines()

    [Patcher.endpoint_static_plug_block("  "), import_line, hooks_map_line, hook_element]
  end
end
