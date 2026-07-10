defmodule CrosswakeExample.Flashcards.DeckLive.Show do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.Flashcards

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    deck = Flashcards.get_deck!(id)
    {:ok, assign(socket, deck: deck, page_title: PageTitle.learn(deck.title))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <link rel="stylesheet" href="/css/tokens.css" />
    <link rel="stylesheet" href="/css/app.css" />
    <div class="page-container">
      <div class="card" id={"deck-#{@deck.id}"}>
        <div class="card-header">
          <h1 class="page-title"><%= @deck.title %></h1>
          <span class="badge">runtime: live_view</span>
          <span class="badge">offline: cached_read_only</span>
        </div>

        <p class="text-sm" style="margin-bottom: 24px;"><%= @deck.description %></p>

        <div class="card-actions">
          <a href="/decks" class="btn-secondary" style="margin-right: 12px;">Back to Decks</a>
          <button type="button" class="btn-primary" phx-click="download_pack">
            Download Pack
          </button>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("download_pack", _params, socket) do
    # Placeholder for download action
    {:noreply, socket}
  end
end
