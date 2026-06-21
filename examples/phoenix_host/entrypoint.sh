#!/bin/sh
set -eu

# The deps/_build named volumes start empty on first boot and shadow the copies
# baked into the image, so (re)materialise them here. deps.get is a no-op once the
# path dep + hex deps are present; deps.compile/compile are incremental afterwards,
# making container restarts fast while still satisfying the named-volume cache.
mix deps.get
mix deps.compile
mix compile

# Idempotent DB provisioning against the named SQLite volume, then boot.
mix ecto.create --quiet
mix ecto.migrate --quiet
mix run priv/repo/seeds.exs
exec mix phx.server
