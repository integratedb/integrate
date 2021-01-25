-- Touches a UUID in the integratedb.sync table. This is picked up
-- by the replication listener as a cue to re-sync the claims (because
-- logical replication doesn't stream DDL changes).
CREATE FUNCTION integratedb_sync() RETURNS void
AS $$
  BEGIN
    INSERT INTO integratedb.sync (
      uid
    )
    VALUES (
      md5(random()::text || clock_timestamp()::text)::uuid
    );
  END;
$$ LANGUAGE plpgsql;
