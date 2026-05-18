defmodule CrosswakeExample.SelectiveNative.ClaimCaptureLive do
  use Phoenix.LiveView

  alias CrosswakeExample.SelectiveNative.Claims

  def mount(%{"id" => id}, _session, socket) do
    claim = Claims.get_claim!(id)
    # The native shell handles the actual capture UI, so this LiveView
    # serves as the fallback/host context when mounted.
    {:ok, assign(socket, claim: claim)}
  end

  def render(assigns) do
    ~H"""
    <div class="native-capture-fallback">
      <h1>Capture Evidence for <%= @claim.title %></h1>
      <p>Please use the native mobile application to capture media.</p>
      <.link navigate={"/native/submissions/#{@claim.id}/review"} class="button">
        Simulate Capture Completion (Proceed to Review)
      </.link>
    </div>
    """
  end
end