FROM elixir:1.11.3-alpine AS build

# Install build dependencies.
RUN apk add --no-cache build-base git

# Prepare build dir.
WORKDIR /app

# Install hex + rebar.
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV.
ENV MIX_ENV=prod

# Install mix dependencies.
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# Compile and build release.
COPY lib lib
COPY priv priv
RUN mix do compile, release

# Prepare release image.
FROM alpine:3.13 AS app
RUN apk add --no-cache ncurses-libs

WORKDIR /app
RUN chown nobody:nobody /app
USER nobody:nobody
COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/integratedb ./
RUN chmod +x bin/integratedb

# Provide an entrypoint that supports `up`, `migrate` and `rollback` commands.
COPY --chown=nobody:nobody docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]

# Default to `up` which runs any new migrations and starts the server.
CMD ["up"]
