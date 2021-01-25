
[![License - MIT](https://img.shields.io/badge/license-MIT-green)](https://github.com/integratedb/integrate/blob/main/LICENSE.md)
![Status - Alpha](https://img.shields.io/badge/status-alpha-red)
[![CI Build Status](https://circleci.com/gh/integratedb/integrate.svg?style=shield)](https://circleci.com/gh/integratedb/integrate)

# IntegrateDB

> "Learn the rules like a pro, so you can break them like an artist."\
> — Picasso

IntegrateDB is a database sharing system. It provides integration primitives and data ownership and migration controls. Use it to integrate services directly through a Postgres database.

- [Usage](https://hexdocs.pm/integratedb/usage.html)
- [Installation](https://hexdocs.pm/integratedb/installation.html)
- [Support](https://hexdocs.pm/integratedb/support.html)

## Why would I want to do that?

> "Most software architects that I respect take the view that integration databases should be avoided."\
> — Martin Fowler

Integration databases are typically regarded as a smell. They "don't scale" and either block changes or break apps. Instead, services are integrated using APIs and message-buses. This comes at a cost. Additional work to serialize, transfer, validate and map data through multiple layers. Operational complexity to deploy and coordinate those layers.

IntegrateDB takes a different approach. Rather than building extra layers to mitigate architectural concerns, it mitigates those concerns directly. This leads to faster development and simpler systems — fewer layers, less code and less plumbing.

## How exactly does it work?

*Note: IntegrateDB is currently alpha stage software. Features still need to be implemented. The design, syntax and interfaces may change. See the [Known Issues](KNOWN_ISSUES.md) for context.*

Using IntegrateDB, applications explicitly declare the data shape (tables, columns, types) that they need access to. IntegrateDB then:

1. scopes database access credentials so that applications can only access data they declare
2. validates DDL migrations to allow safe schema evolution without breaking data dependencies
3. makes it easy to subscribe to and handle notifications when data is changed by another application

### Deploy and create stakeholder

Imagine that you have a web application with a Postgres database and that you want to integrate a reporting system. Deploy IntegrateDB, bootstrap a root user and create a `Stakeholder` representing your secondary application:

```sh
curl -X POST -d '{"name": "reporter"}' \
    -H "Content-Type: application/json" \
    -H "Bearer: <auth token>" \
    /api/v1/stakeholders
```

This creates a Postgres database user (`reporter`) with access scoped to its own private DDL schema (`reporter.*`) and returns the database user credentials:

```js
{
  "data": {
    "credentials": {
      "username": "reporter",
      "password": "<long random string>",
      // ...
    },
    // ... 
  }
}
```

Save the credentials (somewhere safe!) and provide them as the database access credentials to the reporting application. I.e.: the application should connect directly to the database as this user.

### Declare data dependencies

Now, say that your reporting application is interested in orders placed by customers. It can declare a claim on the relevant tables by `PUT`ing something like the following configuration to `/api/v1/stakeholders/:stakeholder_id/claims`:

```js
{
  "data": {
    "match": [
      {
        "path": "public.orders",
        "fields": ["*"]
      },
      {
        "path": "public.customers",
        "fields": ["id", "user_id"]
      }
    ]
  }
}
```

Or it can achieve the same thing **and** register to receive a notification when any relevant data changes with:

```js
{
  "data": {
    "match": [
      {
        "path": "public.orders",
        "events": ["*"],
        "fields": ["*"],
        "channels": ["*"]
      },
      {
        "path": "public.customers",
        "events": ["INSERT", "UPDATE", "DELETE"],
        "fields": ["id", "user_id"],
        "channels": ["SOCKET", "WEBHOOK", "REDIS"]
      }
    ],
    "channels": [
      // ... notification channel configuration
    ]
  }
}
```

In both cases, having registered the configuration, the `reporter` application will be granted read access to the whole `public.orders` table and the `id` and `user_id` of the `public.customers` table. The difference with the notifications is that the application will also be notified when the relevant data is added or changed, with the requested fields (and their values) included as a record in the notification payload.

So that's how applications register as stakeholders, get dynamically scoped access credentials, declare data dependencies and register for notifications. Now for the payoff: migration control.

### Migration control

IntegrateDB adds a user defined function (by default named `integratedb_validate_migration`) to your Postgres database. Call this at the end of your migration (i.e.: as the last statement within the transaction) and it will prevent the migration from being applied if the resulting DDL schema doesn't provide the declared data dependencies.

This works with whichever language or migration tool you prefer. An example using straight SQL:

```sql
BEGIN;
ALTER TABLE foos DROP COLUMN name;
SELECT integratedb_validate_migration();
COMMIT;

-- Or to rollback
BEGIN;
ALTER TABLE foos ADD COLUMN name varchar(255);
SELECT integratedb_sync();
COMMIT;

```

A higher level language example using [Ecto.Migration](#):

```elixir
defmodule ExampleMigration.AlterFoos do
  use Ecto.Migration

  def change do
    alter table(:foos) do
      remove :name
    end

    execute "SELECT integratedb_validate_migration()", "SELECT integratedb_sync()"
  end
end
```

It's a smart function: it understands the difference between additive and destructive migrations and it allows you to configure options in order to explicitly facilitiate schema changes.

### Schema evolution

With API-based integration, the theory is that you can handle changes to data structure using versioning. I.e.: you publish multiple versions of an API endpoint or your business logic handles variations of a data structure.

With IntegrateDB, you can update your data dependency configuration (claims and notifications both work the same way) to:

1. allow `alternatives`, enabling changes / alterations
2. make tables, columns and types `optional`, enabling deletions

Alternatives, work at the table and column level. For example:

```js
// from
"match": {
  "path": "public.orders",
  "fields": [
    "product_id",
    "quantity"
  ]
}

// to
"match": {
  "alternatives": [
    {
      "path": "public.orders",
      "fields": [
        "product_uuid",
        "quantity"
      ]
    },
    {
      "path": "public.legacy_orders",
      "fields": [
        {
          "alternatives": [
            "product_id",
            "product_uuid"
          ]
        },
        "quantity"
      ]
    }
  ]
}
```

For optional, you add `"optional": true`:

```js
// from
"match": {
  "path": "public.foos",
  "fields": ["*"]
}

// to
"match": {
  "path": "public.foos",
  "fields": ["*"],
  "optional": true
}

// and from
"fields": [
  "user_id"
]

// to
"fields": [
  {"name": "user_id", "optional": true}
]
```

Alternatives and optionals are designed as tools to help navigate a migration whilst still being as explicit and static / defined as possible about data dependencies. Once the database has been migrated and the new data is flowing, it's recommened to remove the alternatives and optionals from your integration config — as you would remove the code handling the legacy orders from your app.

## Next steps

See the documentation for more information:

- [Usage](https://hexdocs.pm/integratedb/usage.html)
- [Installation](https://hexdocs.pm/integratedb/installation.html)
- [Support](https://hexdocs.pm/integratedb/support.html)

## License

IntegrateDB is released under the [MIT license](LICENSE.md).

## Contribute

IntegrateDB is an [Elixir](https://elixir-lang.org) application based on[Phoenix](https://www.phoenixframework.org) and [Broadway](https://github.com/dashbitco/broadway).

The project is maintained by [James Arthur (@thruflo)](https://github.com/thruflo). Contributions are welcome. Please raise an issue or a PR to discuss. Make sure you write tests and run `mix format`.

Note that IntegrateDB only supports Postgres (version 10 or above), mainly because we use [logical replication](https://www.postgresql.org/docs/current/logical-replication.html) and [schemas](https://www.postgresql.org/docs/current/ddl-schemas.html).

### Develop

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

See the [documentation](https://hexdocs.pm/integratedb) for more information.
