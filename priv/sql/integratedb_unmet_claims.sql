-- Return all the claims that do not have a claim alternative
-- with (a) a matching table and (b) a valid column alternative
-- for all of its columns.
CREATE FUNCTION integratedb_unmet_claims(max_results integer default 100)
RETURNS TABLE (claim_id bigint)
AS $$
  BEGIN
    RETURN QUERY
    SELECT claim.id as claim_id
      FROM integratedb.claims as claim

      WHERE claim.optional IS FALSE
        AND NOT EXISTS (
          SELECT claim_alt.id
            FROM integratedb.claim_alternatives as claim_alt

            JOIN information_schema.columns as info_schema
              ON (
                claim_alt.schema = info_schema.table_schema
                AND
                claim_alt.table = info_schema.table_name
              )

            WHERE claim_alt.claim_id = claim.id
              -- XXX Todo: better way of doing this than these two "same count" subqueries?
              AND (
                (
                  SELECT count(check_col.id)
                    FROM integratedb.columns as check_col

                    WHERE check_col.claim_alternative_id = claim_alt.id
                      AND check_col.optional = false
                )
                =
                (
                  SELECT count(col.id)
                    FROM integratedb.columns as col

                    WHERE col.claim_alternative_id = claim_alt.id
                      AND col.optional = false
                      AND EXISTS (
                        SELECT col_alt.id
                          FROM integratedb.column_alternatives as col_alt

                          JOIN information_schema.columns as info_schema
                            ON (
                              claim_alt.schema = info_schema.table_schema
                              AND claim_alt.table = info_schema.table_name
                              AND col_alt.name = info_schema.column_name
                              AND col_alt.type = info_schema.data_type
                              AND (
                                col_alt.min_length IS NULL
                                OR
                                col_alt.min_length <=
                                  case when info_schema.character_maximum_length is not null
                                    then info_schema.character_maximum_length
                                    else info_schema.numeric_precision
                                  end
                              )
                              AND (
                                col_alt.is_nullable IS TRUE
                                OR
                                info_schema.is_nullable = 'NO'
                              )
                            )

                          WHERE col_alt.column_id = col.id
                      )
                )
              )
        )
      LIMIT max_results;
  END;
$$ LANGUAGE plpgsql;
