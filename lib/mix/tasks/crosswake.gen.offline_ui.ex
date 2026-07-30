defmodule Mix.Tasks.Crosswake.Gen.OfflineUi do
  @moduledoc """
  Generates host-owned offline UI components.

  Creates offline page and layouts in the host Phoenix application.

  ## Options

    * `--dir` - the target directory (defaults to current directory)
    * `--app` - the target application module name (defaults to auto-detect)
  """
  use Mix.Task

  @shortdoc "Generates host-owned offline UI components"

  @switches [dir: :string, app: :string]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    app_module = opts[:app] || get_app_module()
    app_snake = Macro.underscore(app_module)

    dir = Path.expand(opts[:dir] || File.cwd!())

    web_dir = Path.join([dir, "lib", "#{app_snake}_web"])
    
    controller_dest = Path.join([web_dir, "controllers", "offline_controller.ex"])
    root_layout_dest = Path.join([web_dir, "components", "layouts", "offline_root.html.heex"])
    page_dest = Path.join([web_dir, "controllers", "offline_html", "offline_page.html.heex"])
    js_dest = Path.join([dir, "assets", "js", "offline.js"])

    controller_template = get_template_path("offline_controller.ex.eex")
    root_layout_template = get_template_path("offline_root.html.heex.eex")
    page_template = get_template_path("offline_page.html.heex.eex")
    js_template = get_template_path("offline.js.eex")

    web_module = Module.concat([app_module <> "Web"])

    controller_content = EEx.eval_file(controller_template, web_module: web_module)
    root_layout_content = EEx.eval_file(root_layout_template, web_module: web_module)
    page_content = EEx.eval_file(page_template, web_module: web_module)
    js_content = EEx.eval_file(js_template, web_module: web_module)

    offline_css_dest = Path.join([dir, "priv", "static", "assets", "offline.css"])

    ensure_file(controller_dest, controller_content)
    ensure_file(root_layout_dest, root_layout_content)
    ensure_file(page_dest, page_content)
    ensure_file(js_dest, js_content)
    ensure_file(offline_css_dest, File.read!(get_offline_css_path()))

    Mix.shell().info("""
    Offline UI components generated successfully!

    Next steps:
    1. Mount the OfflineController in your router (typically in your main browser pipeline):
       get "/offline", #{app_module}Web.OfflineController, :index

    2. The generator has copied offline.css into priv/static/assets/. This file is
       host-owned and editable. Re-running the generator will NOT update it
       (no-clobber). To pick up upstream style changes, delete the file and
       re-run: mix crosswake.gen.offline_ui

       tokens.css is NOT copied — it is served directly by Crosswake at
       /crosswake/tokens.css once `mix crosswake.install` has patched your
       endpoint. The generated layout already links that URL.

    3. If your host bundles JavaScript, configure esbuild to include offline.js
       as a separate entry point:
       args: ~w(js/app.js js/offline.js --bundle --target=es2017 --outdir=../priv/static/assets ...)
       (No CSS build step required — offline.css is served as a static file.)
    """)
  end

  defp get_template_path(filename) do
    path = Application.app_dir(:crosswake, "priv/templates/crosswake/offline_ui/#{filename}")
    if File.exists?(path) do
      path
    else
      Path.join(File.cwd!(), "priv/templates/crosswake/offline_ui/#{filename}")
    end
  end

  defp get_offline_css_path do
    path = Application.app_dir(:crosswake, "priv/static/crosswake/offline.css")
    if File.exists?(path) do
      path
    else
      Path.join(File.cwd!(), "priv/static/crosswake/offline.css")
    end
  end

  defp get_app_module do
    case Mix.Project.config()[:app] do
      nil -> "MyApp"
      app -> app |> to_string() |> Macro.camelize()
    end
  end

  defp ensure_file(path, contents) do
    File.mkdir_p!(Path.dirname(path))

    case File.read(path) do
      {:ok, _existing} ->
        Mix.shell().info("  reused #{Path.relative_to_cwd(path)}")
        :reused

      {:error, :enoent} ->
        File.write!(path, contents)
        Mix.shell().info("  created #{Path.relative_to_cwd(path)}")
        :created

      {:error, reason} ->
        Mix.raise("could not create #{path}: #{:file.format_error(reason)}")
    end
  end
end
