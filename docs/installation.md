
# Installation

Make sure that your postgres has logical replication enabled:

```sql
ALTER SYSTEM SET wal_level = 'logical'; # and then restart the db
```

Create an IntegrateDB user. Must have rights ...

XXX tbc.
