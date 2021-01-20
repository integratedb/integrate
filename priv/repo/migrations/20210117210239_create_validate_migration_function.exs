defmodule Integrate.Repo.Migrations.CreateValidateMigrationFunction do
  use Ecto.Migration

  def up do
    execute """
    CREATE FUNCTION integratedb_unmet_claims(max_results integer default 100)
    RETURNS TABLE (
      schema_name varchar,
      table_name varchar,
      column_name varchar,
      column_type varchar,
      min_length integer,
      is_nullable boolean
    ) AS $$
      BEGIN
        RETURN QUERY
        SELECT
          c.schema as schema_name,
          c.table as table_name,
          f.name as column_name,
          f.type as column_type,
          f.min_length as min_length,
          f.is_nullable as is_nullable
          FROM integratedb.claims as c
          JOIN integratedb.columns as f
            ON c.id = f.claim_id
          WHERE NOT EXISTS (
            SELECT
              i.column_name
              FROM information_schema.columns as i
              WHERE i.table_schema = c.schema
                AND i.table_name = c.table
                AND i.column_name = f.name
                AND i.data_type = f.type
                AND (
                  f.min_length IS NULL
                  OR
                  -- f.min_length <= max_length
                  f.min_length <=
                    case when i.character_maximum_length is not null
                      then i.character_maximum_length
                      else i.numeric_precision
                    end
                )
                AND (
                  f.is_nullable IS TRUE
                  OR
                  i.is_nullable = 'NO'
                )
          )
          ORDER BY
            schema_name,
            table_name,
            column_name
          LIMIT
            max_results;
      END;
    $$ LANGUAGE plpgsql
    """

    execute """
    CREATE FUNCTION integratedb_validate_migration(max_results integer default 100)
    RETURNS integer AS $$
      DECLARE
        unmet RECORD;
      BEGIN
        RAISE NOTICE 'IntegrateDB validating migration ...';

        FOR unmet IN
          SELECT * from integratedb_unmet_claims(max_results)
        LOOP
          RAISE NOTICE 'Unmet claim: table `%.%`, column `%`, type: `%`, min_length: `%`, is_nullable: `%`.',
            quote_ident(unmet.schema_name),
            quote_ident(unmet.table_name),
            quote_ident(unmet.column_name),
            quote_literal(unmet.column_type),
            quote_nullable(unmet.min_length),
            quote_nullable(unmet.is_nullable);
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
    """
  end

  def down do
    execute "DROP FUNCTION integratedb_validate_migration"
    execute "DROP FUNCTION integratedb_unmet_claims"
  end
end
