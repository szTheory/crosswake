#!/bin/sh
set -e

mix ecto.create --quiet
mix ecto.migrate --quiet
mix run priv/repo/seeds.exs
exec mix phx.server
