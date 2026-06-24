# Build context is the REPO ROOT (see docker-compose.yml `context: ../..`), because the
# example host depends on the parent crosswake library via `{:crosswake, path: "../.."}`.
# The in-container layout mirrors the repo (lib at /app, example at
# /app/examples/phoenix_host) so the path dep resolves identically to native dev.
#
# Stage 1: build — deps layer keyed on mix.exs/mix.lock so source edits don't
# re-trigger deps.get/compile. Uses glibc Debian base (required for the ecto_sqlite3
# / exqlite C NIF, which Alpine/musl cannot build safely).
FROM hexpm/elixir:1.19.5-erlang-27.3.4-debian-bookworm-20260610-slim AS build

# build-essential + git: exqlite compiles a C NIF via elixir_make (needs cc/make).
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app/examples/phoenix_host
ENV MIX_ENV=dev

RUN mix local.hex --force && mix local.rebar --force

# Deps layer: copy the parent lib's manifests + source (the path dep) and the
# example's manifests first, then fetch — cached unless any mix.exs/mix.lock changes.
COPY mix.exs mix.lock /app/
COPY lib /app/lib
COPY priv /app/priv
COPY examples/phoenix_host/mix.exs examples/phoenix_host/mix.lock /app/examples/phoenix_host/
RUN mix deps.get

# Example source after deps so source edits don't invalidate the deps cache layer.
COPY examples/phoenix_host/config /app/examples/phoenix_host/config
COPY examples/phoenix_host/lib /app/examples/phoenix_host/lib
COPY examples/phoenix_host/priv /app/examples/phoenix_host/priv
RUN mix deps.compile && mix compile

# Stage 2: runtime image — same base for NIF binary compatibility. build-essential
# is retained because the runtime entrypoint repopulates the (initially empty) named
# deps/_build volumes on first boot, which recompiles the exqlite NIF.
FROM hexpm/elixir:1.19.5-erlang-27.3.4-debian-bookworm-20260610-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app/examples/phoenix_host
ENV MIX_ENV=dev

# Copy the compiled lib + example and the Mix home from the build stage.
COPY --from=build /app /app
COPY --from=build /root/.mix /root/.mix

# Entrypoint: provision deps (into the named volume) then DB, then phx.server.
COPY examples/phoenix_host/entrypoint.sh ./
RUN chmod +x entrypoint.sh

EXPOSE 4700
CMD ["./entrypoint.sh"]
