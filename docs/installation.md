
# Installation

IntegrateDB is an [Elixir](https://elixir-lang.org) application based on [Phoenix](https://www.phoenixframework.org) and [Broadway](https://github.com/dashbitco/broadway). 

You can install it using:

- [Docker](#install-using-docker)
- [mix release](#install-using-mix-release)
- [locally for development](#install-locally-for-development)

## Postgres (prerequisite)

IntegrateDB requires that you are running a [PostgreSQL database](https://www.postgresql.org), version >= 10.0.

IntegrateDB only supports Postgres. It does not support other RDBMS systems like MySQL or SQL Server. It may possibly support other Postgres compatible databases but only if they support [logical replication](https://www.postgresql.org/docs/current/logical-replication.html) and [schemas](https://www.postgresql.org/docs/current/ddl-schemas.html).

### Enable logical replication

Your postgres must run with logical replication enabled. This can be enabled manually:

```sql
ALTER SYSTEM SET wal_level = 'logical'; # and then restart the db
```

Or by running the `mix enable_logical_replication` or `mix db.setup` tasks provided by IntegrateDB.

### Provide necessary capabilities

Currently (this is a [Known Issue](https://github.com/integratedb/integrate/blog/mian/KNOWN_ISSUES.md)) IntegrateDB needs to start with `SUPERUSER` permission in order to create a publication for all tables. This is a bug and will be fixed but for now, start with:

```sql
CREATE USER integratedb WITH SUPERUSER LOGIN PASSWORD '...';
```

Once you've run the initial migrations, you can downgrade to:

```sql
ALTER ROLE integratedb NOSUPERUSER CREATEROLE REPLICATION;
```

## Install using Docker

From the repo root, build the docker image:

```sh
docker build -t integratedb .
```

You can then push or run locally with e.g.:

```sh
docker run -it \
    -e HOST="example.com" \
    -e PORT="4000" \
    -e DATABASE_URL="postgres//user:pwd@host:port/db" \
    -e SECRET_KEY_BASE="..." \
    integratedb:latest
```

You can see the required environment variables in [config/runtime.exs](https://github.com/integratedb/integrate/blob/main/config/runtime.exs). Note that the application is configured to enforce SSL / HSTS but is not configured to terminate SSL. As a result, it expects to be deployed behind a reverse proxy that is terminating the TLS (like Nginx, or a cluster ingress).

## Install using mix release

As an Elixir app, you can build a standalone binary using `mix release`. The [Dockerfile](https://github.com/integratedb/integrate/blob/main/Dockerfile) is a good example but in short, assuming your build machine has the same architecture as your deployment target:

```sh
MIX_ENV=prod mix do deps.get, deps.compile, compile, release
./_build/prod/rel/integratedb up
```

## Install locally for development

See [shell.nix](shell.nix).

Once you have a working environment, install the Elixir dependencies and ensure your Postgres has logical replication enabled (requires a db restart):

```sh
mix deps.get
mix db.setup
```

Run the migrations:

```sh
mix db.migrate
```

Run the tests:

```sh
mix test
```

Run the app:

```sh
mix phx.server
```

## Next steps

See the [Usage](usage.md) guide.
