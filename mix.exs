defmodule Crosswake.MixProject do
  use Mix.Project

  @version "0.2.0" # x-release-please-version
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake,
      version: @version,
      name: "crosswake",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Shared test fixtures (test/support/*.ex) are compiled once as project
  # modules in the test env, instead of being loaded per-file via
  # Code.require_file/2. The latter races during parallel test compilation —
  # multiple test files requiring the same fixture concurrently intermittently
  # fails with {:error, :enoent}.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    # D-21: No companion-conditional dep blocks. Core names no companion in any env.
    # The conditional env-hack blocks were deleted in Phase 130 — companions now live
    # as standalone Hex packages (crosswake_rulestead in Phase 130, crosswake_rindle in
    # Phase 132, crosswake_sigra in Phase 137, crosswake_chimeway in Phase 138). Their
    # dependencies are declared in the companion's own mix.exs. The dress-rehearsal for
    # each companion runs via `mix companions.test` alias (runs each package's own test
    # lane separately).
    [
      {:jason, "~> 1.4"},
      {:nimble_options, "~> 1.1"},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:telemetry, "~> 1.0"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      # Phase 154: required by Phoenix.LiveViewTest (element/2, render/1 parsing) the
      # moment core ships a real Phoenix.LiveViewTest round trip (test/support/
      # bridge_live_view_case.ex) — phoenix_live_view's own installed runtime raises
      # naming this exact package if it is absent.
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  # D-26: Root aliases so contributors never need a bare `cd`.
  # mix companions.test — runs each companion's own test lane (rulestead + rindle + sigra + chimeway + threadline).
  #   Each lane's default tag exclusions apply (engine-present advisory + example-host
  #   tests are excluded). Adapter-behavior tests run with the engine in the lane's lock.
  # mix verify — runs companions.test + core hermetic test lane (excludes advisory tags).
  defp aliases do
    [
      "companions.test": [
        # deps.get each package first so the alias is self-sufficient on a fresh checkout
        # (the lanes only fetch one package's deps; `mix test` does not auto-fetch).
        "cmd --cd packages/crosswake_rulestead mix deps.get",
        "cmd --cd packages/crosswake_rulestead mix test",
        "cmd --cd packages/crosswake_rindle mix deps.get",
        "cmd --cd packages/crosswake_rindle mix test",
        "cmd --cd packages/crosswake_sigra mix deps.get",
        "cmd --cd packages/crosswake_sigra mix test",
        "cmd --cd packages/crosswake_chimeway mix deps.get",
        "cmd --cd packages/crosswake_chimeway mix test",
        "cmd --cd packages/crosswake_threadline mix deps.get",
        "cmd --cd packages/crosswake_threadline mix test"
      ],
      verify: [
        "companions.test",
        "test --exclude requires_example_host --exclude advisory_only"
      ]
    ]
  end

  defp description do
    "Route policy and runtime contracts for Phoenix apps that go mobile."
  end

  defp package do
    [
      name: "crosswake",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake",
        "GitHub" => @source_url
      },
      files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides),
      exclude_patterns: ["brandbook"]
    ]
  end

  defp docs do
    [
      logo: "brandbook/logo/crosswake-mark.svg",
      favicon: "brandbook/logo/favicon.svg",
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"],
      before_closing_head_tag: &before_closing_head_tag/1,
      before_closing_body_tag: &before_closing_body_tag/1,
      extras: [
        "README.md",
        "guides/see_it_run.md",
        "guides/physical_iphone_handoff.md",
        "guides/architecture.md",
        "guides/code-walkthrough.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides/install.md",
        "guides/route_policy.md",
        "guides/web_to_mobile_migration.md",
        "guides/troubleshooting.md",
        "guides/support_matrix.md",
        "guides/capability_map.md",
        "guides/adopter_profiles.md",
        "guides/adoption.md",
        "guides/user_flows.md",
        "guides/capabilities.md",
        "guides/bridge.md",
        "guides/offline.md",
        "guides/tokens.md",
        "guides/commerce.md",
        "guides/companions.md",
        "guides/companion_contract.md",
        "guides/companion_compatibility.md",
        "guides/compatibility.md",
        "guides/native_shell.md",
        "guides/native_shell_upgrade.md",
        "guides/android_uat.md",
        "guides/packs.md",
        "guides/threadline.md",
        "guides/telemetry.md"
      ],
      groups_for_modules: [
        Policy: [Crosswake.Policy, Crosswake.Router],
        Bridge: ~r/Crosswake\.Bridge(\.|$)/,
        Manifest: [Crosswake.Manifest],
        Capabilities: ~r/Crosswake\.(Commerce|Offline|Packs)/,
        "Companion Contract": [
          Crosswake.Companion,
          Crosswake.Companion.State,
          Crosswake.Compatibility.Finding,
          Crosswake.Compatibility.Target,
          Crosswake.Manifest.Types.RouteEntry
        ],
        "Telemetry": [
          Crosswake.Telemetry,
          Crosswake.Offline.Telemetry
        ]
      ],
      groups_for_extras: [
        Start: [
          "README.md",
          "guides/see_it_run.md",
          "guides/physical_iphone_handoff.md",
          "guides/architecture.md",
          "guides/code-walkthrough.md",
          "guides/route_policy.md",
          "guides/install.md"
        ],
        Adopt: [
          "guides/web_to_mobile_migration.md",
          "guides/user_flows.md",
          "guides/adopter_profiles.md",
          "guides/adoption.md"
        ],
        "Runtime Owners": [
          "guides/native_shell.md",
          "guides/bridge.md",
          "guides/capabilities.md",
          "guides/offline.md",
          "guides/packs.md",
          "guides/tokens.md",
          "guides/commerce.md"
        ],
        Truth: [
          "guides/troubleshooting.md",
          "guides/support_matrix.md",
          "guides/capability_map.md",
          "guides/compatibility.md",
          "guides/android_uat.md"
        ],
        "Telemetry": [
          "guides/telemetry.md"
        ],
        "Extension Authors": [
          "guides/companion_contract.md",
          "guides/companion_compatibility.md"
        ],
        "Advanced/Companions": [
          "guides/companions.md",
          "guides/threadline.md",
          "CHANGELOG.md",
          "LICENSE"
        ]
      ]
    ]
  end

  defp before_closing_head_tag(:html) do
    ~S"""
    <script defer src="https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.min.js" integrity="sha384-yQ4mmBBT+vhTAwjFH0toJXNYJ6O4usWnt6EPIdWwrRvx2V/n5lXuDZQwQFeSFydF" crossorigin="anonymous"></script>
    <style>
      .crosswake-mermaid {
        max-width: 100%;
        overflow-x: auto;
        padding-block: 0.75rem;
        background: transparent;
      }

      .crosswake-mermaid svg {
        display: block;
        min-width: 38rem;
        max-width: 100%;
        height: auto;
        margin-inline: auto;
        background: transparent;
      }

      @media (prefers-reduced-motion: reduce) {
        .crosswake-mermaid,
        .crosswake-mermaid * {
          scroll-behavior: auto !important;
          transition-duration: 0.01ms !important;
          animation-duration: 0.01ms !important;
          animation-iteration-count: 1 !important;
        }
      }
    </style>
    """
  end

  defp before_closing_head_tag(_formatter), do: ""

  defp before_closing_body_tag(:html) do
    ~S"""
    <script>
      (() => {
        if (window.crosswakeMermaidController) return;

        const controller = {
          queue: Promise.resolve(),
          counter: 0,
          dark: null,
          observer: null,
          warned: false
        };

        const themeVariables = (dark) => dark ? {
          background: "#09141A",
          primaryColor: "#0F1E26",
          primaryTextColor: "#F7F1E6",
          primaryBorderColor: "#254855",
          secondaryColor: "#162B35",
          secondaryTextColor: "#F7F1E6",
          secondaryBorderColor: "#254855",
          tertiaryColor: "#0F1E26",
          tertiaryTextColor: "#F7F1E6",
          tertiaryBorderColor: "#254855",
          lineColor: "#4E9A8E",
          textColor: "#F7F1E6",
          mainBkg: "#0F1E26",
          nodeBorder: "#254855",
          clusterBkg: "#162B35",
          clusterBorder: "#254855",
          titleColor: "#F7F1E6",
          edgeLabelBackground: "#09141A"
        } : {
          background: "#F7F1E6",
          primaryColor: "#F7F1E6",
          primaryTextColor: "#09141A",
          primaryBorderColor: "#254855",
          secondaryColor: "#EFE6D6",
          secondaryTextColor: "#09141A",
          secondaryBorderColor: "#254855",
          tertiaryColor: "#C9D4CF",
          tertiaryTextColor: "#09141A",
          tertiaryBorderColor: "#254855",
          lineColor: "#2B756A",
          textColor: "#09141A",
          mainBkg: "#F7F1E6",
          nodeBorder: "#254855",
          clusterBkg: "#EFE6D6",
          clusterBorder: "#254855",
          titleColor: "#09141A",
          edgeLabelBackground: "#F7F1E6"
        };

        const warnOnce = (message, error) => {
          if (controller.warned) return;
          controller.warned = true;
          console.warn(`[crosswake docs] ${message}; showing Mermaid source instead.`, error);
        };

        const fallback = (source, output, error) => {
          if (output) output.remove();
          source.hidden = false;
          warnOnce("Mermaid rendering failed", error);
        };

        const renderAll = async () => {
          const sources = Array.from(document.querySelectorAll("pre > code.mermaid"))
            .map((code) => ({code, source: code.parentElement}));

          if (sources.length === 0) return;

          if (!window.mermaid) {
            sources.forEach(({source}) => {
              const output = source.nextElementSibling;
              fallback(
                source,
                output && output.classList.contains("crosswake-mermaid") ? output : null,
                new Error("pinned Mermaid renderer unavailable")
              );
            });
            return;
          }

          const dark = document.body.classList.contains("dark");
          window.mermaid.initialize({
            startOnLoad: false,
            securityLevel: "strict",
            theme: "base",
            flowchart: {htmlLabels: false},
            themeVariables: themeVariables(dark)
          });

          for (const {code, source} of sources) {
            let output = source.nextElementSibling;
            if (!output || !output.classList.contains("crosswake-mermaid")) {
              output = document.createElement("div");
              output.className = "crosswake-mermaid";
              source.insertAdjacentElement("afterend", output);
            }

            try {
              const id = `crosswake-mermaid-${Date.now()}-${++controller.counter}`;
              const rendered = await window.mermaid.render(id, code.textContent);
              output.innerHTML = rendered.svg;
              output.dataset.theme = dark ? "dark" : "light";
              const svg = output.querySelector("svg");
              if (svg) svg.setAttribute("role", "img");
              if (rendered.bindFunctions) rendered.bindFunctions(output);
              source.hidden = true;
            } catch (error) {
              fallback(source, output, error);
            }
          }
        };

        const queueRender = () => {
          controller.queue = controller.queue.catch(() => undefined).then(renderAll);
          return controller.queue;
        };

        const observeTheme = () => {
          if (controller.observer || !document.body) return;
          controller.dark = document.body.classList.contains("dark");
          controller.observer = new MutationObserver(() => {
            const dark = document.body.classList.contains("dark");
            if (dark !== controller.dark) {
              controller.dark = dark;
              queueRender();
            }
          });
          controller.observer.observe(document.body, {attributes: true, attributeFilter: ["class"]});
        };

        const boot = () => {
          observeTheme();
          queueRender();
        };

        window.crosswakeMermaidController = controller;
        window.addEventListener("exdoc:loaded", boot);

        if (document.readyState === "loading") {
          document.addEventListener("DOMContentLoaded", boot, {once: true});
        } else {
          boot();
        }
      })();
    </script>
    """
  end

  defp before_closing_body_tag(_formatter), do: ""
end
