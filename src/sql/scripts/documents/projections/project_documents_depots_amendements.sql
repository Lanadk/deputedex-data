DO
$$
    DECLARE
        duplicate_count integer;
    BEGIN
        SELECT COUNT(*)
        INTO duplicate_count
        FROM (SELECT data ->> 'row_hash'
              FROM documents_depots_amendements_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) t;

        IF duplicate_count > 0 THEN
            RAISE NOTICE 'Detected % duplicate documents_depots_amendements row_hash(es)', duplicate_count;
        ELSE
            RAISE NOTICE 'No duplicate documents_depots_amendements row_hash detected';
        END IF;
    END
$$;

WITH dedup AS (SELECT DISTINCT ON (data ->> 'row_hash') data
               FROM documents_depots_amendements_raw
               WHERE data ->> 'row_hash' IS NOT NULL
               ORDER BY data ->> 'row_hash',
                        (data ->> 'legislature_snapshot')::int DESC)

INSERT
INTO documents_depots_amendements_snapshot (document_uid,
                                            type_depot,
                                            organe_uid,
                                            amendable,
                                            date_limite_depot,
                                            row_hash,
                                            legislature_snapshot)
SELECT data ->> 'document_uid',
       data ->> 'type_depot',
       data ->> 'organe_uid',
       CASE
           WHEN data ->> 'amendable' = 'true' THEN true
           WHEN data ->> 'amendable' = 'false' THEN false
           END,
       NULLIF(data ->> 'date_limite_depot', '')::date,
       data ->> 'row_hash',
       (data ->> 'legislature_snapshot')::int
FROM dedup

ON CONFLICT (row_hash) DO NOTHING;