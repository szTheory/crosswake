defmodule CrosswakeExample.SelectiveNative.Fixtures do
  alias CrosswakeExample.SelectiveNative.Claims

  def seed do
    Claims.create_claim(%{title: "Broken windshield", status: "pending"})
    Claims.create_claim(%{title: "Hail damage", status: "pending"})
  end
end
