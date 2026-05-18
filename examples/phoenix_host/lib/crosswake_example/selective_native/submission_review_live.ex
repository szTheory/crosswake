defmodule CrosswakeExample.SelectiveNative.SubmissionReviewLive do
  use Phoenix.LiveView

  alias CrosswakeExample.SelectiveNative.Claims
  alias CrosswakeExample.SelectiveNative.Submissions

  def mount(%{"id" => id}, _session, socket) do
    # Assuming claim and submission share the same ID for this prototype
    claim = Claims.get_claim!(id)
    submission = Submissions.get_submission!(id)
    
    {:ok, assign(socket, claim: claim, submission: submission)}
  end

  def handle_event("prepare_upload", _params, socket) do
    # Transition the submission state from staged to uploaded
    # Trigger the explicit transfer.upload.prepare seam.
    {:ok, updated_submission} = Submissions.mark_submitted(socket.assigns.submission)
    {:ok, updated_claim} = Claims.mark_uploaded(socket.assigns.claim)
    
    {:noreply, assign(socket, submission: updated_submission, claim: updated_claim)}
  end

  def render(assigns) do
    ~H"""
    <div class="submission-review">
      <h1>Review Evidence</h1>
      <p>Claim: <%= @claim.title %></p>
      
      <div class="evidence-status">
        <p>Claim Status: <span class="status"><%= @claim.status %></span></p>
        <p>Submission Status: <span class="status"><%= @submission.status %></span></p>
      </div>

      <div class="actions">
        <%= if @submission.status == "staged" do %>
          <button phx-click="prepare_upload" data-crosswake-transfer="transfer.upload.prepare" class="button primary">
            Upload Evidence
          </button>
        <% else %>
          <p class="success">Evidence uploaded successfully.</p>
        <% end %>
      </div>
    </div>
    """
  end
end