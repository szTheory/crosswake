defmodule CrosswakeExample.Flashcards.DeckLive.Index do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.Flashcards

  @impl true
  def mount(_params, _session, socket) do
    decks = Flashcards.list_decks()
    {:ok, assign(socket, decks: decks, page_title: PageTitle.learn("Decks"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <link rel="stylesheet" href="/css/tokens.css" />
    <link rel="stylesheet" href="/css/brands.css" />
    <link rel="stylesheet" href="/css/app.css" />
    <div class="page-container">
      <h1 class="page-title">Flashcard Decks</h1>

      <div class="grid grid-cols-2">
        <%= for deck <- @decks do %>
          <div class="card" id={"deck-#{deck.id}"}>
            <div class="card-header">
              <h2 class="card-title"><%= deck.title %></h2>
              <span class="badge">runtime: live_view</span>
            </div>
            <p class="text-sm"><%= deck.description %></p>
            <div class="card-actions">
              <a href={"/decks/#{deck.id}"} class="btn-primary">View Deck</a>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
