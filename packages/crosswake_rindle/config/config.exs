import Config

# Unlike crosswake_rulestead (which wires a :rulestead_flag_source config-indirection
# to a MockFlagSource Agent in :test), the Rindle adapter has NO flag-source mock:
# Crosswake.Companions.Rindle reads only Application.get_env(:crosswake, :rindle, %{})
# directly (see lib/crosswake/companions/rindle.ex), gated upstream by
# validate_dependency/0 + Code.ensure_loaded?(Rindle).
#
# This file is intentionally minimal — it exists so the package has the standard
# config/ entrypoint and so the moved tests (132-03) have a place to add any
# rindle-specific test wiring if needed. Keep additions minimal and test-scoped.
if config_env() == :test do
  # No rindle-specific test config indirection required at this time.
  :ok
end
