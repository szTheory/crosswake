# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CrosswakeExample.Repo.insert!(%CrosswakeExample.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
#
# The offline study island does not get server-side proof data here. Its
# cards and review outbox are app-owned browser state seeded by
# priv/static/offline_study.js so the v12 proof exercises IndexedDB,
# reconnect-triggered flush, and /study/sync honestly.

result = CrosswakeExample.Showcase.Reset.reset!()

IO.puts("Showcase server reset complete.")
IO.puts("counts=#{Jason.encode!(result.counts)}")
IO.puts("digest=#{result.digest}")
IO.puts("browser_state_reset=#{result.browser_state_reset}")
IO.puts("Browser offline state remains app-owned and is not reset server-side.")
