defmodule CrosswakeExample.SaaSPortal.SettingsLive do
  use Phoenix.LiveView

  alias CrosswakeExample.PageTitle

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: PageTitle.admin("Profile Settings"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section>
      <h1>Profile settings</h1>
      <p>
        {@current_saas_user.name} is signed in as {@current_saas_user.role}. This stays a normal
        authenticated LiveView route rather than a diagnostics lab or shell-owned profile surface.
      </p>

      <dl>
        <dt>Email</dt>
        <dd>{@current_saas_user.email}</dd>
        <dt>Account</dt>
        <dd>{@current_saas_account.name}</dd>
        <dt>Shell posture</dt>
        <dd>Route unavailable remains explicit when activation fails closed.</dd>
      </dl>
    </section>
    """
  end
end
