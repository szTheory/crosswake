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

    ensure_file(controller_dest, controller_content)
    ensure_file(root_layout_dest, root_layout_content)
    ensure_file(page_dest, page_content)
    ensure_file(js_dest, js_content)

    Mix.shell().info("""
    Offline UI components generated successfully!

    Next steps:
    1. Mount the OfflineController in your router (typically in your main browser pipeline):
       get "/offline", #{app_module}Web.OfflineController, :index

    2. Update your tailwind.config.js to include the Crosswake brand colors (if you haven't already):
       // This enables classes like text-cw-wake-700 and bg-cw-brass-500
       theme: {
         extend: {
           colors: {
             'cw-wake': {
               50: '#f0f5fa',
               100: '#e1ecf4',
               200: '#c3d8e9',
               300: '#a5c4df',
               400: '#87b0d4',
               500: '#699cc9',
               600: '#4b88bf',
               700: '#3c6d99',
               800: '#2d5273',
               900: '#1e364d',
             },
             'cw-brass': {
               50: '#fcf8f2',
               100: '#f9f1e6',
               200: '#f3e3cd',
               300: '#edd5b4',
               400: '#e7c79b',
               500: '#e1b982',
               600: '#dbab69',
               700: '#c59a5e',
               800: '#af8954',
               900: '#997849',
             }
           }
         }
       }

    3. Ensure the offline.js is imported in your assets/js/app.js:
       import "./offline"
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
