
# Usage

This guide explains how to use an [installed instance of IntegrateDB](https://hexdocs.pm/integratedb/installation.html). It covers the following topics:

- [Users](#users)
- [Stakeholders](#stakeholders)
- [Claims](#claims)
- [Notifications](#notifications)
- [Migration control](#migration-control)
- [Schema evolution](#schema-evolution)


## Users

IntegrateDB is a web application with a JSON API. In order to interact with it, you need to create and authenticate as a user.

### Bootstrapping the root user

When IntegrateDB is first installed, it doesn't have any users. The first step is to create a root user. This does not require authentication.

Make a `POST` request to `/api/v1/users` with a payload like:

```json
{
  "user": {
    "username": "example", 
    "password": "..."
  }
}
```

For example:

```sh
export ENDPOINT="https://your-integrate-db-instance"

curl -X POST -H "Content-Type: application/json" \
  -d '{"user": {"username": "example", "password": "<your password>"}}' \
  $ENDPOINT/api/v1/users
```

This will return a response like:

```json
{
  "data": {
    "id": 1,
    "token": "<bearer token>",
    "refreshToken": "<refresh token>",
  }
}
```

Where:

- `id` is the user id
- `token` is a bearer token for authentication
- `refreshToken` is a refresh token you can use to get a new bearer token

Once the root user is created, access is locked down and all API endpoints require user authentication.

### Authenticating requests

You can authenticate requests to the API using your bearer token. Test this by listing all users using a `GET` request to `/api/v1/users`:

```sh
export AUTH_HEADER="Authorization: Bearer <your bearer token>"
export JSON_HEADER="Content-Type: application/json"

curl -H $AUTH_HEADER -H $JSON_HEADER http://localhost:4000/api/v1/users
```

Which in this case will return:

```json
{
  "data": [
    {
      "id": 1, 
      "username": "example"
    }
  ]
}
```

### Generating new tokens

You can login and and renew your token using:

- `POST {"data": {"username": "...", "password": "...""}} /api/v1/auth/login`
- `POST {data: "<renew token>"} /api/v1/auth/renew`

Both return the same response data as create user:

```json
{
  "data": {
    "id": 1,
    "token": "<bearer token>",
    "refreshToken": "<refresh token>",
  }
}
```

### Managing users

You have standard CRUD resources on users:

- `GET /api/v1/users` to list all users
- `GET /api/v1/users/:id` to view a user
- `POST {data} /api/v1/users` to create a new user
- `PUT {data} /api/v1/users/:id` to update a user
- `DELETE /api/v1/users/:id` to delete a user

Once you have a user, the next step is to create one or more stakeholder applications.


## Stakeholders

Stakeholders represent applications you want to integrate via a Postgres database. You can create stakeholders for every application that needs access to the database, or you can have a primary application that manages your database and then only create stakeholders for the secondary applications that you want to integrate via the database.

Stakeholders have a unique `name` that is used to create and kept in sync with a Postgres database user and a Postgres DDL schema. The name must confirm to this regex `~r/^[a-zA-Z_]{1}\w{0,31}$/`.

### Create stakeholder

Make a `POST` request to `/api/v1/stakeholders` with a payload like:

```json
{
  "stakeholder": {
    "name": "example"
  }
}
```

For example:

```sh
curl -X POST -H $AUTH_HEADER -H $JSON_HEADER  \
  -d '{"stakeholder": {"name": "example"}}' \
  $ENDPOINT/api/v1/stakeholders
```

This creates a Postgres database user (`example`) with access scoped to its own private DDL schema (`example.*`) and returns the database user credentials in the response data:

```json
{
  "data": {
    "id": 1,
    "name": "example",
    "credentials": {
      "username": "example",
      "password": "<randomly generated password>"
    }
  }
}
```

The generated credentials contain the database user and password that your `example` application should use when connecting directly to the shared Postgres database. For example, it could connect using a connection string like `postgres://example:<your randomly generated password>@host:port/db`.

Note that this is the **only time you will see the credentials**. They are not stored by IntegrateDB, nor are they available to query from either IntegrateDB or Postgres. As a result, you must save the credentials from the create stakeholder response (somewhere safe, like in a password manager or a cluster secret).

### Managing stakeholders

You also have standard CRUD resources on stakeholders:

- `GET /api/v1/stakeholders` to list all stakeholders
- `GET /api/v1/stakeholders/:id` to view a stakeholder
- `POST {data} /api/v1/stakeholders` to create a new stakeholder
- `PUT {data} /api/v1/stakeholders/:id` to update a stakeholder
- `DELETE /api/v1/stakeholders/:id` to delete a stakeholder

The next section walks through how to configure data access and declare data dependencies for a Stakeholder application using Claims.


## Claims

Stakeholder applications have full access to resources in their own DDL schema by default. For example, this allows a stakeholder called `example` to create tables and read and write data in the `example.*` schema. This in itself can be useful as a mechanism for persistence and integration.

However, the real power of IntegrateDB is to facilitate sharing of data between applications. Typically, this involves accessing data in a public or other private schema that may be created and managed by another application. For example, you may have a primary application writing data to `public.orders` and you may want a reporting or fulfillment service to be able to read and respond to the data written there.

To enable this, IntegrateDB allows Stakeholder applications to **claim a subset of the data** in the Postgres database. This does two things:

1. it declares that the Stakeholder depends on the claimed data shape
2. it grants the Stakeholder application access to it

As expanded on in the [Migration control](#migration-control) and [Schema evolution](#schema-evolution) sections, declaring a dependency ensures that the claimed data shape (i.e.: tables and columns) exists — both at the time when the claim is established and ongoing as the database schema evolves.

Note that data access is currently **read only**, i.e.: IntegrateDB grants the Stakeholder's database user "SELECT" permission on the relevant tables and columns. Other permissions may be added in future but at the moment they are regarded as an anti-pattern. Instead, we recommend writing data to tables within the Stakeholder's DDL schema and granting access to that data to other applications that need to access it.

### Specifying claims

You create and overwrite claims by `PUT`ing a specification document to `/api/v1/stakeholders/:stakeholder_id/claims`.

For example, the following will claim all of the columns in the `public.orders` table and the `id` and `user_id` columns in the `public.customers` table:

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

As you can see from the `"*"` specifying "all columns" of the `public.orders` table, specification documents can contain values that are expanded by looking at the actual structure of the database (querying the `information_schema`). This structure can evolve over time, so IntegrateDB works by storing the original spec document and then expanding and re-syncing actual database claims every time the DDL changes (i.e.: after a migration).

#### Top-level `match` array

Specification documents must have a top-level `match` array where each `match` object specifies a data claim.

#### Match objects

Match objects must have a `path` and can optionally have `fields`, `alternatives` and an `optional` flag.

#### Path syntax

Path values must be fully qualified strings refering to tables in the `schema_name.table_name` format.

One special case is that you are allowed to claim all of the tables in a schema using `schema_name.*` **iff** you also claim all fields. So this match object is valid:

```json
{
  "path": "public.*",
  "fields": ["*"] 
}
```

This is not:

```json
{
  "path": "public.*",
  "fields": ["id", "inserted_at"] 
}
```

#### Field syntax

Fields refer to database columns. A match object's `fields` array can contain column name strings, e.g.:

```json
{
  "path": "public.foos",
  "fields": ["id", "inserted_at"] 
}
```

Or field objects that must have a `name` and can have `type`, `min_length`, `is_nullable`, `alternatives` and `optional`. For example, the following are all valid:

```json
{
  "path": "public.foos",
  "fields": [
    {"name": "id"},
    {"name": "uid", "type": "uuid"},
    {"name": "info", "min_length": 255},
    {"name": "inserted_at", "is_nullable": "false"},
    {"name": "extra_info", "optional": true}
  ]
}
```

In this example, the `public.foos` table must have:

- an `id` column of any type
- an `uid` column that is a `uuid` type
- an `info` column that has a minimum maximum length ([see below](#minimum-maximum-length)!) of `255`
- an `inserted_at` column that must not be nullable
- and optionally an `extra_info` column of any type

Currently, if you specify it, the `type` value must be the literal string stored in the `information_schema.columns` `data_type` for the column, such as:

```text
bigint
boolean
character varying
integer
numeric
text
timestamp with time zone
timestamp without time zone
uuid
```

You can see the values in your database using e.g.:

```sql
SELECT distinct(data_type)
  FROM information_schema.columns 
  ORDER BY data_type;
```

Or to introspect the columns in a specific table using a query like:

```sql
SELECT table_schema, table_name, column_name, data_type,
  case when character_maximum_length is not null
    then character_maximum_length
    else numeric_precision
  end as max_length
  FROM information_schema.columns 
  WHERE table_schema = 'public'
    AND table_name = 'foos'
  ORDER BY (table_schema, table_name, column_name);
```

#### Minimum maximum length

Field objects that specify a `min_length` are essentially saying "this column's character length or numeric precision must be at least this value". This allows you to protect against column changes that truncate data. For example, say you have a `varchar(40)` column and a field specifying `min_length: 40`. If a migration tries to truncate the column to a `varchar(30)` then it will fail.

#### What happens when a field is not fully specified?

Fields can be specified with as little as a name:

```json
"fields": ["id"]
```

Or as a fully fleshed out column spec:

```json
"fields": [
  {"name": "id", "type": "bigint", "min_length": 64, "is_nullable": false}
]
```

When storing claims for fields that are not fully specified, IntegrateDB populates the field properties from the current state of the database (i.e.: from the `information_schema.columns` table). This means that a configuration like `"fields": ["id"]` declares a dependency that snapshots the current field, precision and nullability of the `id` field in the database. If the column is altered, for example to increase the size of a varchar or to set it to non nullable, then the claim will automatically adjust to track the new reality and prevent any data regressions.

### Validating specification documents

The IntegrateDB application processes and validates the spec in three stages.

1. JSON schema validation
2. Ecto.Changeset validation
3. Database validation

The full syntax and structure for specification documents is defined and validated by the JSON schema at [priv/spec/spec.schema.json](https://github.com/integratedb/integrate/blob/main/priv/spec/spec.schema.json). This schema is applied first and you will see errors like:

```json
{
  "errors": {
    "detail": [
      ["Schema does not allow additional properties.", "#/name"],
      ["Required property match was not present.","#"]
    ]
  }
}
```

IntegrateDB then casts the document to a `Integrate.Specification.Spec` which applies some changeset validation that should not normally be triggered. Lastly, the spec is expanded and compared against the database. To pass and be stored, all of the paths and fields claimed in the spec must exist in the database and the database must match any column properties (`type`, `min_length`, `is_nullable`) specified.

At this point, you may see errors like:

```json
{
  "errors": {
    "claims": [{
      "alternatives": [{
        "columns": [{
          "alternatives": [{
            "type": [
              "path: `public.foos`, field: `id`: specified value `int` does not match existing column value `bigint`."
            ]
          }]
        }]
      }]
    }]
  }
}
```

These error messages need to be improved but hopefully there's enough in there at the moment for you to figure out what's going on.


## Notifications

> Note: Notifications are not currently implemented. This is top of the [Known Issues](https://github.com/integratedb/integrate/blob/main/KNOWN_ISSUES.md) list.

Notifications are envisaged as being specified just like claims but with additional match attributes for `events` and notification `channels`. In addition, the specification data should have an additional `channels` section for notification channel configuration and the data should be PUT to `/api/v1/stakeholders/:stakeholder_id/notifications` rather than `.../claims`.

This will see the configuration looking like this:

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

The implementation will use the existing `Broadway` based replication pipeline at `Integrate.Replication` and will remove the need for `SUPERUSER` permissions by dynamically adding tables to the logical replication publication.


## Migration control

So far, we've covered bootstrapping a root user, creating a stakeholder application and declaring data dependencies and access requirements as claims. This machinery now allows us to validate migrations in order to ensure data dependencies continue to be met when the database structure (DDL) is changing.

IntegrateDB adds three functions to your Postgres database:

- [integratedb_sync()](https://github.com/integratedb/integrate/blob/main/priv/sql/integratedb_sync.sql)
- [integratedb_unmet_claims()](https://github.com/integratedb/integrate/blob/main/priv/sql/integratedb_unmet_claims.sql)
- [integratedb_validate_migration()](https://github.com/integratedb/integrate/blob/main/priv/sql/integratedb_validate_migration.sql)

`SELECT integratedb_sync()` tells IntegrateDB to re-expand and re-sync all of the claims from the stored specifications. It's useful when you want to manually sync IntegrateDB with the state of the database, for example following a migration rollback.

`SELECT * from integratedb_unmet_claims()` runs a query looking for all claims that are unmet by the current state of the database. You can call this yourself for debugging purposes.

`SELECT integratedb_validate_migration()` validates the current state of the database by calling `integratedb_unmet_claims()`. If there are unmet claims, it raises an exception with logging. If not, it calls `integratedb_sync()` to update claims in line with the new state of the database. 

Calling `integratedb_validate_migration()` at the end of your migration (i.e.: as the last statement within the transaction) prevents the migration from being applied if the resulting DDL schema doesn't provide the declared data dependencies. This works with whichever language or migration tool you prefer.

An example using straight SQL:

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

An example using [Ecto.Migration](https://hexdocs.pm/ecto_sql/Ecto.Migration.html):

```elixir
defmodule ExampleMigration.AlterFoos do
  use Ecto.Migration

  def up do
    alter table(:foos) do
      remove :name
    end
  end

  def down do
    alter table(:foos) do
      add :name, :string
    end
  end

  def before_commit do
    execute "SELECT integratedb_validate_migration()",
            "SELECT integratedb_sync()"
  end
end
```

Including an `integratedb_validate_migration()` at the end of your migration ensures that the database fulfils the claimed data dependencies. It essentially applies constraints to your database that reduce regressions caused by schema migrations. The next section walks through how these constraints can be relaxed in order to explicitly enable schema evolution.

## Schema evolution

With API-based integration, the theory is that you can handle changes to data structure using versioning. I.e.: you publish multiple versions of an API endpoint or your business logic handles variations of a data structure. With IntegrateDB, you can update your data dependency configuration (claims and notifications both work the same way) to:

1. allow `alternatives`, enabling changes / alterations
2. make tables and columns `optional`, enabling deletions

Alternatives work at the table and column level. For example:

```js
// from
"match": {
  "path": "public.orders",
  "fields": ["product_id", "quantity"]
}

// to
"match": {
  "alternatives": [
    {
      "path": "public.orders",
      "fields": ["product_uuid", "quantity"]
    },
    {
      "path": "public.legacy_orders",
      "fields": [
        {
          "alternatives": ["product_id", "product_uuid"]
        },
        "quantity"
      ]
    }
  ]
}
```

As do optionals:

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
"fields": ["user_id"]

// to
"fields": [
  {"name": "user_id", "optional": true}
]
```

Alternatives and optionals are designed as tools to help navigate a migration whilst still being as explicit and static / defined as possible about data dependencies. Once the database has been migrated and the new data is flowing, it's recommened to remove the alternatives and optionals from your integration config — as you would remove the code handling the legacy orders from your app.

## Next steps

Get started with [Installation](installation.md) and find out about the [Support](support.md) available for your project.
