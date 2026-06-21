# Stage 1: build — deps layer keyed on mix.exs/mix.lock so source edits don't
# re-trigger deps.get/compile. Uses glibc Debian base (required for ecto_sqlite3 NIF).
FROM hexpm/elixir:1.19.5-erlang-27.3-debian-bookworm-20250630-slim AS build

WORKDIR /app
ENV MIX_ENV=dev

RUN mix local.hex --force && mix local.rebar --force

# Deps layer: copy lock files first, fetch deps — cached unless mix.exs/mix.lock changes
COPY mix.exs mix.lock ./
RUN mix deps.get

# Source: copy after deps so source edits don't invalidate the deps cache layer
COPY config/ config/
COPY lib/ lib/
COPY priv/ priv/

RUN mix deps.compile

# Stage 2: runtime image — same base for NIF binary compatibility
FROM hexpm/elixir:1.19.5-erlang-27.3-debian-bookworm-20250630-slim

WORKDIR /app
ENV MIX_ENV=dev

# Copy compiled app and Mix home from the build stage
COPY --from=build /app /app
COPY --from=build /root/.mix /root/.mix

# Entrypoint: idempotent DB provisioning then phx.server
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

EXPOSE 4700
CMD ["./entrypoint.sh"]
