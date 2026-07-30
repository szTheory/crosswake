defmodule CrosswakeExample.Layouts do
  use Phoenix.Component

  alias CrosswakeExample.PageTitle

  def root(assigns) do
    assigns =
      assign_new(assigns, :page_title, fn ->
        PageTitle.crosswake("Example Host")
      end)

    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <link rel="stylesheet" href="/css/tokens.css" />
        <link rel="stylesheet" href="/css/app.css" />
        <.live_title default={@page_title}>{@page_title}</.live_title>
      </head>
      <body>
        {@inner_content}
        <script type="module">
          import {Socket} from "/phoenix/phoenix.mjs";
          import {LiveSocket} from "/phoenix_live_view/phoenix_live_view.esm.js";
          import {CrosswakeBridge} from "/crosswake/crosswake.esm.js";

          const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
          const params = csrfToken ? {_csrf_token: csrfToken} : {};
          const liveSocket = new LiveSocket("/live", Socket, {params, hooks: {CrosswakeBridge}});
          liveSocket.connect();
          window.liveSocket = liveSocket;
        </script>
      </body>
    </html>
    """
  end

  @doc """
  The single Crosswake bridge hook element.

  Declared ONCE, here in the layout module, and rendered once per page by whichever
  LiveView attached the bridge. LiveView broadcasts every `push_event` to every
  mounted hook on the page, so a second element would post every bridge request to
  the shell twice — the hook's module-scoped single-owner guard exists for exactly
  that hazard, and this component is how the host avoids relying on it.

  It is a component rather than markup in `root/1` because a LiveView binds hooks
  only inside its own container: an element placed in the ROOT layout is a sibling
  of `[data-phx-main]`, never a descendant, so its `phx-hook` is never mounted and
  every push would silently fall through to the server's wiring deadline. Hosts with
  a conventional Phoenix app layout (which renders INSIDE the LiveView container) can
  put the element there instead — this host has no app layout.
  """
  def crosswake_bridge(assigns) do
    ~H"""
    <div id="crosswake-bridge" phx-hook="CrosswakeBridge" phx-update="ignore"></div>
    """
  end
end
