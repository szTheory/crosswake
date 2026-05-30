import Config

config :phoenix, :json_library, Jason

config :crosswake_example,
  ecto_repos: [CrosswakeExample.Repo]

config :crosswake_example, CrosswakeExample.Repo,
  database: Path.expand("../crosswake_example.db", Path.dirname(__ENV__.file)),
  pool_size: 5,
  stacktrace: true,
  # show_sensitive_data_on_connection_error: true  # dev only — omitted (applies to all Mix envs)

config :crosswake_example, CrosswakeExample.Router,
  url: [host: "example.crosswake.invalid", scheme: "https", port: 443]

# Register the Rulestead companion in the Crosswake companion dispatch loop.
# This is read by Doctor.phase_38_companion_seam_findings/0 and
# RouteGate.prepend_gate_evaluation_findings/3 at runtime.
config :crosswake, :companions, [Crosswake.Companions.Rulestead]

# Enable the Rulestead companion for this host. This config map is passed to
# Crosswake.Companions.Rulestead.enabled?/1 — defaults to false (fail-closed)
# when not configured, so this key must be present to activate the companion.
#
# Local dev workflow — drive gate states via IEx:
#   alias Crosswake.Companions.Rulestead.MockFlagSource
#   MockFlagSource.set_flag(:rulestead, :gated)          # -> :gate_denied denial
#   MockFlagSource.set_flag(:rulestead, {:rolling_out, 50})  # -> :gate_denied (rolling out)
#   MockFlagSource.set_flag(:rulestead, :killed)         # -> :kill_switch_active denial
#   MockFlagSource.delete_flag(:rulestead)               # clear flag
#   MockFlagSource.reset()                               # clear all flags
# Then visit /gating/beta-feature to observe the gate response across states.
config :crosswake, :rulestead, %{enabled: true}
