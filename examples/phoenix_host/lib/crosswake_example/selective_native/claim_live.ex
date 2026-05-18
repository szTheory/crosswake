defmodule CrosswakeExample.SelectiveNative.ClaimLive do
  use Phoenix.LiveView

  alias CrosswakeExample.SelectiveNative.Claims

  def mount(%{"id" => id}, _session, socket) do
    claim = Claims.get_claim!(id)
    {:ok, assign(socket, claim: claim)}
  end

  def render(assigns) do
    ~H"""
    <div class="claim-detail">
      <h1>Claim Detail: <%= @claim.title %></h1>
      <p>Status: <span class="status"><%= @claim.status %></span></p>
      
      <div class="actions">
        <.link navigate={"/native/claims/#{@claim.id}/capture"} class="button">
          Start Native Capture
        </.link>
      </div>
    </div>
    """
  end
end