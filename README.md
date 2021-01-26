
[![CI Build Status](https://circleci.com/gh/integratedb/integrate.svg?style=shield)](https://circleci.com/gh/integratedb/integrate)
[![License - MIT](https://img.shields.io/badge/license-MIT-green)](https://github.com/integratedb/integrate/blob/main/LICENSE.md)
![Status - Alpha](https://img.shields.io/badge/status-alpha-red)

# IntegrateDB

> "Learn the rules like a pro, so you can break them like an artist."\
> — Picasso

IntegrateDB is a database sharing system. It provides integration primitives and data ownership and migration controls. Use it to integrate applications directly through a Postgres database.

- [Installation](https://hexdocs.pm/integratedb/installation.html)
- [Usage](https://hexdocs.pm/integratedb/usage.html)
- [Support](https://hexdocs.pm/integratedb/support.html)

## Why would I want to do that?

> "Most software architects that I respect take the view that integration databases should be avoided."\
> — Martin Fowler

Integration databases are typically regarded as a smell. They "don't scale" and either block changes or break apps. Instead, services are integrated using APIs and message-buses. This comes at a cost. Additional work to serialize, transfer, validate and map data through multiple layers. Operational complexity to deploy and coordinate those layers.

IntegrateDB takes a different approach. Rather than building extra layers to mitigate architectural concerns, it mitigates those concerns directly. This leads to faster development and simpler systems — fewer layers, less code and less plumbing.

## How exactly does it work?

> *Note: IntegrateDB is currently alpha stage software. See the [Known Issues](https://github.com/integratedb/integrate/blob/main/KNOWN_ISSUES.md) for context.*

Using IntegrateDB, applications explicitly declare the data shape (tables, columns, types) that they need access to.

IntegrateDB then:

1. scopes database access credentials so that applications can only access data they declare
2. validates DDL migrations to allow safe schema evolution without breaking data dependencies
3. makes it easy to subscribe to and handle notifications when data is changed by another application

### Example - integrate a reporting application

Imagine that you have a primary web application with a Postgres database and that you want to integrate a reporting system. Assume you've [installed IntegrateDB](https://hexdocs.pm/integratedb/installation.html) and [bootstrapped a root user](https://hexdocs.pm/integratedb/usage.html). You then start by creating a `Stakeholder` representing your secondary reporting application:

```sh
curl -X POST -H "..." -d '{"name": "reporter"}' /api/v1/stakeholders
```

This creates a Postgres database user (`reporter`) with access scoped to its own private DDL schema (`reporter.*`) and returns the database user credentials in the response data:

```js
{
  "data": {
    "credentials": {
      "username": "reporter", 
      "password": "... randomly generated ...",
    }
  }
}
```

Save the credentials (somewhere safe!) and provide them to your reporting application as the database user and password it should use to connect directly to the Postgres database.

### Declare data dependencies

Now, say that your reporting application is interested in orders placed by customers. It can declare a claim on the relevant data by `PUT`ing the following to `/api/v1/stakeholders/:stakeholder_id/claims`:

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

With this configuration, the `reporter` application will be granted read access to the whole `public.orders` table and the `id` and `user_id` of the `public.customers` table. You will also soon be able to register for notifications when claimed data changes [using an extension of the same syntax](https://hexdocs.pm/integratedb/usage.html#notifications).

So that's how applications register as stakeholders, get dynamically scoped access credentials and declare data dependencies. Now for the payoff: migration control.

### Migration control

IntegrateDB [adds a function](https://hexdocs.pm/integratedb/usage.html#migration-control) called `integratedb_validate_migration()` to your Postgres database. Call this at the end of your migration and it will prevent the migration from being applied if the DDL schema changes it's about to commit would break any declared data dependencies for any stakeholder application.

This works with whichever language or migration tool you prefer. For example, in raw SQL:

```sql
BEGIN;
ALTER TABLE foos DROP COLUMN name;
SELECT integratedb_validate_migration();
COMMIT;
```

It's a smart function: it understands the difference between additive and destructive migrations and it allows you to configure options in order to [explicitly facilitiate schema evolution](https://hexdocs.pm/integratedb/usage.html#schema-evolution).

## Next steps

See the guides for more information:

- [Installation](https://hexdocs.pm/integratedb/installation.html)
- [Usage](https://hexdocs.pm/integratedb/usage.html)
- [Support](https://hexdocs.pm/integratedb/support.html)

## License

IntegrateDB is released under the [MIT license](https://github.com/integratedb/integrate/blob/main/LICENSE.md).

## Contribute

IntegrateDB is an [Elixir](https://elixir-lang.org) application based on [Phoenix](https://www.phoenixframework.org) and [Broadway](https://github.com/dashbitco/broadway). The project is maintained on GitHub at [github.com/integratedb](https://github.com/integratedb) by [James Arthur (@thruflo)](https://github.com/thruflo).

Contributions, feedback and bug reports are welcome. Please [raise an issue](https://github.com/integratedb/integrate/issues/new) or start a PR to discuss. If you do contribute code, please write tests and run `mix format`.
