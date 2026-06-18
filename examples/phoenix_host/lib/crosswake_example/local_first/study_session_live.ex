defmodule CrosswakeExample.LocalFirst.StudySessionLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      current_card_id: 1
    )}
  end

  def handle_event("rate", %{"rating" => _rating}, socket) do
    # Progress to next card (simulating local state)
    next_card_id = socket.assigns.current_card_id + 1

    {:noreply, assign(socket, current_card_id: next_card_id)}
  end

  def render(assigns) do
    ~H"""
    <div class="study-session">
      <h1>Study Session (Offline Island)</h1>
      <p>This lane simulates offline capability where state progresses locally.</p>

      <div class="flashcard card">
        <h2>Card #<%= @current_card_id %></h2>
        <p>What is the capital of Elixir?</p>

        <div class="actions">
          <button phx-click="rate" phx-value-rating="hard" class="button">Hard</button>
          <button phx-click="rate" phx-value-rating="good" class="button primary">Good</button>
        </div>
      </div>
    </div>
    """
  end
end
