import Config

# Chimeway has no flag-source config indirection — unlike rulestead (MockFlagSource Agent),
# the Chimeway adapter reads notification config directly from the companion callback
# arguments, not from Application.get_env config indirection.
#
# This file is intentionally minimal — it exists so the package has the standard
# config/ entrypoint and so the moved tests (138-02) have a place to add any
# chimeway-specific test wiring if needed. Keep additions minimal and test-scoped.
if config_env() == :test do
  # No chimeway-specific test config indirection required at this time.
  :ok
end
