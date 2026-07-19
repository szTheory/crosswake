defmodule CrosswakeExample.PageTitle do
  @moduledoc """
  Browser title helpers for the example host.

  Titles keep demo-app brands distinct while preserving Crosswake as the
  parent product in browser chrome.
  """

  alias CrosswakeExample.Showcase.Branding

  @parent "Crosswake"

  @spec crosswake(String.t()) :: String.t()
  def crosswake(page), do: join([page, @parent])

  @spec admin(String.t()) :: String.t()
  def admin(page), do: demo(page, :saas_admin)

  @spec field(String.t()) :: String.t()
  def field(page), do: demo(page, :field_service)

  @spec learn(String.t()) :: String.t()
  def learn(page), do: demo(page, :learning_training)

  @spec demo(String.t(), atom()) :: String.t()
  def demo(page, brand_id) do
    join([page, Branding.brand_for!(brand_id).name, @parent])
  end

  defp join(parts), do: Enum.join(parts, " · ")
end
