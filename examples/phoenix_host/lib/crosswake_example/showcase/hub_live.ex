defmodule CrosswakeExample.Showcase.HubLive do
  use Phoenix.LiveView

  alias CrosswakeExample.Showcase.Catalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, lanes: Catalog.lanes())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <link rel="stylesheet" href="/css/tokens.css" />
    <link rel="stylesheet" href="/css/app.css" />

    <main class="showcase-shell">
      <section class="showcase-intro" aria-labelledby="showcase-heading">
        <p class="showcase-kicker">Crosswake example host</p>
        <div class="showcase-intro-copy">
          <h1 id="showcase-heading">Phoenix routes, native where it matters.</h1>
          <p>
            Three seeded lanes show which runtime owns each route: LiveView, offline island,
            or native-pressure path.
          </p>
        </div>
        <a class="btn-primary showcase-primary-cta" href="#showcase-lanes">Explore Showcase</a>
      </section>

      <section id="showcase-lanes" class="showcase-lane-grid" aria-label="Showcase lanes">
        <article :for={lane <- @lanes} id={"showcase-lane-#{lane.id}"} class="card showcase-lane-card">
          <p class="text-mono showcase-route"><%= lane.primary_path %></p>

          <div class="showcase-card-head">
            <h2><%= lane.heading %></h2>
            <a class="btn-secondary showcase-lane-cta" href={lane_href(lane)}>
              <%= lane.primary_cta %>
            </a>
          </div>

          <p class="showcase-card-body"><%= lane.body %></p>

          <div class="showcase-badge-row" aria-label={"#{lane.heading} runtime and support labels"}>
            <span
              :for={label <- lane.runtime_labels}
              class={["badge", "showcase-badge", badge_class(label)]}
            >
              <%= label %>
            </span>
            <span
              :for={label <- lane.support_labels}
              class={["badge", "showcase-badge", badge_class(label)]}
            >
              <%= label %>
            </span>
          </div>

          <ul class="showcase-chip-list" aria-label={"#{lane.heading} capabilities"}>
            <li :for={chip <- lane.capability_chips}><%= chip %></li>
          </ul>

          <p class="showcase-boundary-warning"><%= lane.boundary_note %></p>
          <p class="showcase-v20-note"><%= lane.v20_pressure_note %></p>
        </article>
      </section>

      <section class="showcase-proof-strip" aria-labelledby="proof-routes-heading">
        <div>
          <h2 id="proof-routes-heading">Proof routes stay one click deeper</h2>
          <p>
            Use these routes to inspect route-owner semantics, offline behavior, and bounded
            bridge proof after the showcase explains the product shape.
          </p>
        </div>

        <nav class="showcase-proof-links" aria-label="Proof routes">
          <a class="btn-secondary" href="/offline">View Offline Study Proof</a>
          <a class="btn-secondary" href="/bridge-proof">View Bridge Proof</a>
          <a class="btn-secondary" href="/native/claims">View Native-Pressure Routes</a>
        </nav>
      </section>
    </main>
    """
  end

  defp lane_href(%{id: :field_service}), do: "/native/claims"
  defp lane_href(%{primary_path: path}), do: path

  defp badge_class(label) do
    cond do
      label =~ "LiveView" -> "showcase-badge-liveview"
      label =~ "Offline" or label =~ "Local-first" or label =~ "Cached" -> "showcase-badge-offline"
      label =~ "Native" or label =~ "native" -> "showcase-badge-native"
      label =~ "Proof" -> "showcase-badge-bridge"
      label =~ "Future" or label =~ "Demo" or label =~ "Sensitive" -> "showcase-badge-sensitive"
      true -> "showcase-badge-support"
    end
  end
end
