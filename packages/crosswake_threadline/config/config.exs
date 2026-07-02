import Config

# Threadline has no flag-source config indirection — threadline is a pure OTP
# audit/correlation observer. It reads Application env for audit_repo/audit_ledger
# at runtime (via mix crosswake.threadline), not via any config mock indirection.
#
# This file is intentionally minimal — it exists so the package has the standard
# config/ entrypoint and so the moved tests (139-02) have a place to add any
# threadline-specific test wiring if needed. Keep additions minimal and test-scoped.
if config_env() == :test do
  # No threadline-specific test config indirection required at this time.
  :ok
end
