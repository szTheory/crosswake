defmodule CrosswakeExample.SelectiveNative.ClaimsLive do
  use Phoenix.LiveView

  alias CrosswakeExample.SelectiveNative.Claims

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Refresh if needed
    end

    {:ok, assign(socket, claims: Claims.list_claims())}
  end

  def render(assigns) do
    ~H"""
    <div class="claims-list">
      <h1>Active Claims</h1>
      <ul>
        <%= for claim <- @claims do %>
          <li>
            <.link navigate={"/native/claims/#{claim.id}"}>
              <strong><%= claim.title %></strong>
            </.link>
            <span class="status"><%= claim.status %></span>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end
end