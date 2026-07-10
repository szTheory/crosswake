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
        <.live_title default={@page_title}>{@page_title}</.live_title>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
