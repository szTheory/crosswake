import Config

# Sigra has no flag-source config indirection — unlike rulestead (MockFlagSource Agent)
# or chimeway, the Sigra adapter reads auth context directly from the companion callback
# arguments, not from Application.get_env config indirection.
#
# This file is intentionally minimal — it exists so the package has the standard
# config/ entrypoint and so the moved tests (137-03) have a place to add any
# sigra-specific test wiring if needed. Keep additions minimal and test-scoped.
if config_env() == :test do
  # No sigra-specific test config indirection required at this time.
  :ok
end
