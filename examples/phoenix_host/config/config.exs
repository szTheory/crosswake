import Config

config :phoenix, :json_library, Jason

config :crosswake_example,
  ecto_repos: [CrosswakeExample.Repo]

config :crosswake_example, CrosswakeExample.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  server: true,
  secret_key_base: String.duplicate("a", 64),
  live_view: [signing_salt: "crosswake"]

config :crosswake_example, CrosswakeExample.Repo,
  pool_size: 5

# show_sensitive_data_on_connection_error: true  # dev only — omitted (applies to all Mix envs)

config :crosswake_example, CrosswakeExample.Router,
  url: [host: "example.crosswake.invalid", scheme: "https", port: 443]

# Register the companions in the Crosswake companion dispatch loop. This is read by
# Doctor.phase_38_companion_seam_findings/0 and
# RouteGate.prepend_gate_evaluation_findings/3 at runtime.
#
# Sigra is the host's auth authority — it is the only module in the tree with
# `auth_authority?/0 == true`. RouteGate scans this list for one
# (route_gate.ex:261-283) and, finding none, fails CLOSED with a
# `dependency_missing` denial, which Compatibility maps to `:step_up_required`.
# It was omitted when sigra was extracted to its own package in v17.0, which left
# every auth-predicated route in the example host denied.
config :crosswake, :companions, [
  Crosswake.Companions.Rulestead,
  Crosswake.Companions.Sigra
]

# Enable the Rulestead companion for this host. This config map is passed to
# Crosswake.Companions.Rulestead.enabled?/1 — defaults to false (fail-closed)
# when not configured, so this key must be present to activate the companion.
config :crosswake, :rulestead, %{enabled: true}

# Sigra reads this map via Sigra.enabled?/1 (sigra.ex:33,52) and, like Rulestead,
# defaults to false (fail-closed) when absent — so registering the module above is
# necessary but not sufficient; this key must be present too.
config :crosswake, :sigra, %{enabled: true}

# Wire the host's flag source: the Rulestead adapter resolves this at runtime via
# Application.get_env(:crosswake, :rulestead_flag_source) and calls get_flag/1. The
# adapter fail-opens the gate if this is unset, so an adopter that wants gating must
# point it at a running flag-source process (here the example's own — see application.ex).
#
# Local dev workflow — drive gate states via IEx:
#   alias CrosswakeExample.RulesteadFlagSource, as: Flags
#   Flags.set_flag(:rulestead, :gated)              # -> :gate_denied denial
#   Flags.set_flag(:rulestead, {:rolling_out, 50})  # -> :gate_denied (rolling out)
#   Flags.set_flag(:rulestead, :killed)             # -> :kill_switch_active denial
#   Flags.delete_flag(:rulestead)                   # clear flag
#   Flags.reset()                                   # clear all flags
# Then visit /gating/beta-feature to observe the gate response across states.
config :crosswake, :rulestead_flag_source, CrosswakeExample.RulesteadFlagSource

import_config "#{config_env()}.exs"
