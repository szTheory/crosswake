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
        <.live_title default={@page_title}>{@page_title}</.live_title>
      </head>
      <body>
        {@inner_content}
        <script type="module">
          import {Socket} from "/phoenix/phoenix.mjs";
          import {LiveSocket} from "/phoenix_live_view/phoenix_live_view.esm.js";

          const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
          const params = csrfToken ? {_csrf_token: csrfToken} : {};
          const liveSocket = new LiveSocket("/live", Socket, {params});
          liveSocket.connect();
          window.liveSocket = liveSocket;
        </script>
      </body>
    </html>
    """
  end
end
