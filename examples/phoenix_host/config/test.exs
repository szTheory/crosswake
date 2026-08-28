import Config

# Test env config. The endpoint (server: true, secret_key_base), HTTP port (4700,
# overridable via PORT), and the SQLite database path are all set by config.exs +
# runtime.exs, which apply to every Mix env. The e2e/route-tour harness drives a
# real running server against a shared SQLite DB (no Ecto sandbox — see
# test/test_helper.exs), so no sandbox pool is configured here.

# Keep test-server logs quiet so Playwright output stays readable.
config :logger, level: :warning

config :crosswake_example,
  offline_study_replay_authority: CrosswakeExample.E2E.ReplayAuthority

# The generated proof-lane contract exercises the same Phoenix transaction
# fixture used by the physical-proof backend producer. This is test-only; it is
# never a runtime authority source.
config :crosswake,
       :proof_lane_host_authority,
       CrosswakeExample.LocalFirst.PhysicalIphoneAuthority
