defmodule CrosswakeExample.LocalFirst.StudyHistoryLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle
  alias CrosswakeExample.LocalFirst.Study

  def mount(_params, _session, socket) do
    events = Study.list_events()
    {:ok, assign(socket, events: events, page_title: PageTitle.learn("Study History"))}
  end

  def render(assigns) do
    ~H"""
    <div class="study-history">
      <h1>Study History (Cached Read-Only)</h1>
      <p>This lane provides a read-only view of the historically synchronized study events.</p>
      
      <%= if Enum.empty?(@events) do %>
        <p>No study history available.</p>
      <% else %>
        <ul class="event-list">
          <%= for event <- @events do %>
            <li class="event-item">
              <strong>Card #<%= event.card_id %></strong>
              <span>Rating: <%= event.rating %></span>
              <span class={"status status-#{event.status}"}>[<%= event.status %>]</span>
              <span class="mutation-id" style="font-size: 0.8em; color: gray;">
                ID: <%= event.client_mutation_id %>
              </span>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end
end
