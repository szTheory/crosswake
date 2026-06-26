import Config

# D-31: In the :test environment, wire the flag_source config-indirection to
# the MockFlagSource Agent. This keeps lib/ free of any test-module reference —
# the indirection symbol (Application.compile_env) is the only bridge.
#
# Shipped default (non-test) = nil, which is the honest "no flag source configured"
# state. validate_dependency/0 gates upstream before flag_source is called, so
# nil is safe in production (a missing engine denies before any flag lookup).
if config_env() == :test do
  config :crosswake, :rulestead,
    flag_source: Crosswake.Companions.Rulestead.MockFlagSource
end
