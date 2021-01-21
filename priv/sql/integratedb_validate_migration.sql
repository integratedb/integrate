CREATE FUNCTION integratedb_validate_migration(max_results integer default 100)
RETURNS integer AS $$
  DECLARE
    unmet RECORD;
  BEGIN
    RAISE NOTICE 'IntegrateDB validating migration ...';

    FOR unmet IN
      SELECT * from integratedb_unmet_claims(max_results)
    LOOP
      -- XXX Todo: log a useful debug trail from the unmet claim.

      -- RAISE NOTICE 'Unmet claim: table `%.%`, column `%`, type: `%`, min_length: `%`, is_nullable: `%`.',
      --   quote_ident(unmet.schema_name),
      --   quote_ident(unmet.table_name),
      --   quote_ident(unmet.column_name),
      --   quote_literal(unmet.column_type),
      --   quote_nullable(unmet.min_length),
      --   quote_nullable(unmet.is_nullable);

      RAISE NOTICE 'Unmet claim id: %', unmet.claim_id;
    END LOOP;

    IF FOUND THEN
      RAISE EXCEPTION 'IntegrateDB.InvalidMigration'
         USING HINT = 'Please resolve the unmet claims above. See https://integratedb.org/docs for more info.';

      RETURN 1;
    END IF;

    RAISE NOTICE 'IntegrateDB validated migration OK.';

    RETURN 0;
  END;
$$ LANGUAGE plpgsql
