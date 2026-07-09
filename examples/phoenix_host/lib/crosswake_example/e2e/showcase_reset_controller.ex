defmodule CrosswakeExample.E2E.ShowcaseResetController do
  use Phoenix.Controller, formats: [:json]

  alias CrosswakeExample.Showcase.Reset

  def create(conn, _params) do
    json(conn, Reset.reset!())
  end
end
