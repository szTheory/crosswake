import Config

# Production-env config for the example host. config.exs already sets the
# env-agnostic endpoint (server: true, secret_key_base, adapter) and repo, and
# runtime.exs sets the HTTP bind/port and SQLite path for every Mix env, so prod
# only adds the prod-specific deltas. This file exists primarily so the example
# compiles under MIX_ENV=prod — the guard-02 prod-route-absence gate compiles the
# host in prod to prove no test-only (/_e2e) routes leak into a production build.
config :logger, level: :info

# No code reloader or dev/test affordances in prod.
config :phoenix, :plug_init_mode, :compile
