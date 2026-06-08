DO
$$
    DECLARE
        duplicate_count integer;
    BEGIN
        SELECT COUNT(*)
        INTO duplicate_count
        FROM (SELECT data ->> 'row_hash'
              FROM documents_organes_referents_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) t;

        IF duplicate_count > 0 THEN
            RAISE NOTICE 'Detected % duplicate documents_organes_referents row_hash(es)', duplicate_count;
        ELSE
            RAISE NOTICE 'No duplicate documents_organes_referents row_hash detected';
        END IF;
    END
$$;

WITH dedup AS (SELECT DISTINCT ON (data ->> 'document_uid', data ->> 'organe_uid') data
               FROM documents_organes_referents_raw
               WHERE data ->> 'document_uid' IS NOT NULL
                 AND data ->> 'organe_uid' IS NOT NULL
               ORDER BY data ->> 'document_uid',
                        data ->> 'organe_uid',
                        (data ->> 'legislature_snapshot')::int DESC,
                        data ->> 'row_hash')

INSERT
INTO documents_organes_referents_snapshot (document_uid,
                                           organe_uid,
                                           row_hash,
                                           legislature_snapshot)
SELECT data ->> 'document_uid',
       data ->> 'organe_uid',
       data ->> 'row_hash',
       (data ->> 'legislature_snapshot')::int
FROM dedup

ON CONFLICT (document_uid, organe_uid) DO UPDATE
    SET row_hash             = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE documents_organes_referents_snapshot.row_hash IS DISTINCT FROM EXCLUDED.row_hash;