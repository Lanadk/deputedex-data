DO
$$
    DECLARE
        duplicate_count integer;
    BEGIN
        SELECT COUNT(*)
        INTO duplicate_count
        FROM (SELECT data ->> 'row_hash'
              FROM documents_auteurs_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) t;

        IF duplicate_count > 0 THEN
            RAISE NOTICE 'Detected % duplicate documents_auteurs row_hash(es)', duplicate_count;
        ELSE
            RAISE NOTICE 'No duplicate documents_auteurs row_hash detected';
        END IF;
    END
$$;

WITH dedup AS (SELECT DISTINCT ON (data ->> 'row_hash') data
               FROM documents_auteurs_raw
               WHERE data ->> 'row_hash' IS NOT NULL
               ORDER BY data ->> 'row_hash',
                        (data ->> 'legislature_snapshot')::int DESC)

INSERT
INTO documents_auteurs_snapshot (document_uid,
                                 acteur_uid,
                                 organe_uid,
                                 qualite,
                                 row_hash,
                                 legislature_snapshot)
SELECT data ->> 'document_uid',
       data ->> 'acteur_uid',
       data ->> 'organe_uid',
       data ->> 'qualite',
       data ->> 'row_hash',
       (data ->> 'legislature_snapshot')::int
FROM dedup

ON CONFLICT (row_hash) DO NOTHING;