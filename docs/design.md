
# IntegrateDB - Design

## 1. What is the problem?

[Martin Fowler on integration databases](https://martinfowler.com/bliki/IntegrationDatabase.html):

> An integration database is a database which acts as the data store for multiple applications, and thus integrates data across these applications (in contrast to an [ApplicationDatabase](https://martinfowler.com/bliki/ApplicationDatabase.html)).
>
> An integration database needs a schema that takes all its client applications into account. The resulting schema is either more general, more complex or both - because it has to unify what should be separate [BoundedContexts](https://martinfowler.com/bliki/BoundedContext.html). The database usually is controlled by a separate organization to those that develop applications and database changes are more complex because they have to be negotiated between the database group and the various applications.
>
> The benefit of this is that sharing data between applications does not require an extra layer of integration services on the applications. Any changes to data made in a single application are made available to all applications at the time of database commit - thus keeping the applications' data use better synchronized.
>
> On the whole integration databases lead to serious problems becaue the database becomes a point of coupling between the applications that access it. This is usually a deep coupling that significantly increases the risk involved in changing those applications and making it harder to evolve them. As a result most software architects that I respect take the view that integration databases should be avoided.

According to this account, the challenges include:

- having a database schema that takes all client applications into account
- controlling that schema and negotiating database changes
- making it harder to change and evolve applications

Another typical view of the "cons" of integration databases is found at [victor.4devs.io](https://victor.4devs.io/en/architecture/integration-database.html), with the less hand wavy points being:

- no clear API
- no ownership of data
- changes to schemas/tables by one service can affect other services
- introduces the fear of change

And here's a critical one from [Ben Morris](https://www.ben-morris.com/a-shared-database-is-still-an-anti-pattern-no-matter-what-the-justification):

> A shared database is still an anti-pattern, no matter what the justification

- makes it difficult to define and enforce clear boundaries between systems
- difficult to define data schema that can be used by multiple applications
- melting pot of logic and data that doesn’t have any clear responsibilities
- unable to refactor because of the potential impact on secondary systems
- difficult to make changes without causing regression
- political difficulties with multiple stakeholders
- performance bottlenecks / potential for locks and deadlocks
- single point of failure

He notes:

> Even well-designed applications with carefully-constructed data abstractions will fall victim to this paralysis in time. They are particularly vulnerable to secondary applications with less disciplined data strategies where data is accessed directly.
> 
> This crude access will undermine any carefully-planned abstractions and application-level concerns such as security or caching will be impossible to enforce.

### 1.1. Grouping the challenges

Boiling these down, we get the following themes:

1. database schema that supports multiple applications
2. need to enforce clear data and schema ownership
3. technical impact of schema evolution on other applications
4. human side of coordinating schema evolution and negotiating changes
5. performance bottlenecks / single point of failure

#### 1.1.1. Multi-application schema

This seems like a straightforward point: if applications are sharing a database then that database needs to support both their needs. However, there is a distinction between "sharing" a database and "integrating" through a database. You can integrate using a database without that being your only database. In addition, you can define multiple relational [schemas](https://www.postgresql.org/docs/current/ddl-schemas.html) inside the same RDBMS.

There's also a slightly philosophical point:

> "Bad programmers worry about the code. Good programmers worry about data structures and their relationships."
> ― Linus Torvalds 

If the data that's being shared is in it's "natural" form, and two or more applications both need it, then perhaps the applications "should" be able to work with it. In a sense, validating the schema against multiple applications might actually help arrive at better structures and relationships.

#### 1.1.2. Data and schema ownership

If different applications (such as the "secondary applications with less disciplined data strategies" mentioned above) can change the content or structure of shared parts of the database willy-nilly, then that's going to lead to problems. This points to needing explicit controls over data access and schema changes.

It's worth noting that most git merges don't throw up merge conflicts: in many cases, applications may naturally update different parts of the database and the cross over, where they would tread on each other's toes, may be small.

One starting point could be to define different parts of the database that are owned by different apps. This would reduce the "shared ownership" footprint. Alternatively, it might be simpler to just specify one application as the primary database manager. For example, imagine a Rails app and a reporting service. The Rails app can simply own the database. If the secondary application does need write or DDL access, this could be scoped to a known subset or schema. Or if the applications are "peers" then they each have their scope and tread carefully over any shared scope.

#### 1.1.3. Technical-side of schema evolution

The most obvious technical problem is the impact of database changes on applications, i.e.: if one application needs to change the data or the schema, how does this impact other applications?

Schema evolution between servers and clients in distributed systems is a well known space. APIs have versioning. Schemas are evolved in non-breaking ways. GraphQL schema documents are exchanged. Consistency models are Jepson tested.

There is a basic level of "are all systems expecting the same database schema?" and an advanced level of "how shall we treat these competing writes?". If an application "owns" the DB then it should be in sync with the migration version. If an application doesn't own the DB and is not in sync, then maybe it damn well should be.

When an API introduces breaking changes, it can continue to support stale clients by serving the previous version of the API. Typically, databases don't do this. You can build immutable versioned databases. Maybe that's what an advanced integration database needs to be. You can also write adapters / gateways to translate queries and data. Maybe an integration database system could provide hooks for these version aware translations.

However, there may well be a simpler starting point: run the migrations for the database and then restart the applications with code that supports the latest schema. What IntegrateDB can do is provide a "cloud native migration flow" that makes sure that your applications are ready for the new migration.

#### 1.1.4. Human-side of schema evolution

If different teams need to coordinate to apply a migration then communication overhead expodes as the number of teams increases.

There is a Microsoft vs Apple trade off here, where Microsoft is short for backwards compatibility and Apple is short for forced updates. In the enterprise, maybe the communication headache and friction of forced updates outweighs the maintenance headache of backwards compatibility.

Outside of that -- when you can count the number of teams on the fingers of one hand -- maybe the communication overhead is worth it to avoid having to maintain backwards compatibility. You pays your money, you takes your choice. The consumer market chose Apple. Enterprises are on Microsoft Azure.

#### 1.1.5. Performance bottleneck

Services that share a database will degrade/break if that database slows down or goes offline. If your database fills up or goes offline, you've got problems regardless of whether its shared. If that database supported an API and other services used the API, those services will also degrade. If you're using a message bus, your backlog is going to fill up and your users will be twiddling their thumbs.

Of course, just because you integrate some services through a database doesn't mean that you need to base your entire system on that single database. And it doesn't mean you can't use all the normal failover and availability tactics to keep your databases online.

For the vast majority of apps, databases scale without issue. If you're pushing Postgres on a vertically scaled instance then you're handling a highly data intensive workload and should probably be optimising your architecture around that.

The same goes for lock contention. If you're hammering a large table, maybe you shouldn't give multiple applications access to it. But if you can ringfence data access by schema and relations then that needn't be an integration database issue.


## 2. What is the solution?

You can imagine a solution progressing through layers of sophistication:

| **1. Footgun** | **2. Concurrent** | **3. Ideal** |
|----------------|-------------------|--------------|
| Baseline measures to avoid data chaos that come at a cost of explicit coordination and constraints. | Extending the footgun solution to support concurrent database versioning and automatic data translation. | Crafting a database from the group up on highly compact, immutable. |

Given the need for an MVP, the fact that the clever versioning would be an optimisation of the basic controls and the sheer complexity of engineering a ground up database, it seems clear that the Footgun solution should be the initial focus.

### 2.1. Footgun solution

A candidate solution / approach is as follows.

When you build your application services, record the database migration version that the application version supports. For example, `example-app:v1.0.3` can be specified as supporting migration `7g6sd5f76d`. Or potentially, `example-app:v1.0.3` could be said to support different migration hashes for different schemas if these are migrated seperately.

The trick is to then apply the migration if-and-only-if all of the applications that use the database have published a version that supports the new schema. This compatibility check can also be limited to the affected schema-surface. I.e.: apps can say "I use this part of the database". Then if that has changed, they need a new version, if not they don't.

### 2.2. Footgun algorithm

To say the same thing again slightly more normatively:

Applications specify:

- `version`
- `schemas | relations` used
- `migration_version` supported

Migrations specify:

- `version`
- `schema | relations` affected

Then when IntegrateDB is given a migration to apply:

- get all apps using the affected `schemas | relations`
  - iff all apps have a `version` pushed to the container registry that supports the `migration_version`
    - apply the migration and upgrade the app services

Where an `apply-and-upgrade` workflow can look like:

- pull down and prepare the new app services
- pause new requests
- apply migration
- switch over to the new app services
- allow requests to continue

This could be optimised to minimise downtime and errors.

### 2.3. Potentially extended by convienient integration primitives

Orthogonal to the core footgun solution is the option to also wrap the integration database with some useful integration primitives. This just improves the ergonomics of the database. And should probably be an optional module / additional package.

There's no reason why a user couldn't just do this themselves but making it simple and easy is not to be underestimated. Redis is great because you can easily get stuff done with it, like knock up a bit of interprocess communication.

If you're installing IntegrateDB, why not also wrap the DB with some easy primitives like:

- a queue / message bus
- pub sub / subscriptions

For a queue, we can use [Oban](https://hexdocs.pm/oban/Oban.html).

For subscriptions we can just use `LISTEN` and `NOTIFY` (or possibly consume the logical replication feed if enabled like [supabase/realtime](https://github.com/supabase/realtime) does).
