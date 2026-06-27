import Config

# D-31: In the :test environment, wire the flag_source config-indirection to
# the MockFlagSource Agent. This keeps lib/ free of any test-module reference —
# Application.get_env is the only bridge between lib/ and the test module.
#
# Uses a dedicated config key [:rulestead, :flag_source] so the test setup's
# Application.put_env(:crosswake, :rulestead, %{enabled: true}) does not
# overwrite this setting. The flag_source is read via:
#   Application.get_env(:crosswake, :rulestead_flag_source, nil)
#
# Shipped default (non-test) = nil, which is the honest "no flag source configured"
# state. validate_dependency/0 gates upstream before flag_source is called, so
# nil is safe in production (a missing engine denies before any flag lookup, D-02).
if config_env() == :test do
  config :crosswake, :rulestead_flag_source, Crosswake.Companions.Rulestead.MockFlagSource
end
