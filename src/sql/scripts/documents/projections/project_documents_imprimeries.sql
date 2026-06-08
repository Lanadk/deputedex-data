DO
$$
    DECLARE
        duplicate_count integer;
        duplicate_uids  text;
    BEGIN
        SELECT COUNT(*)
        INTO duplicate_count
        FROM (SELECT data ->> 'document_uid'
              FROM documents_imprimeries_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) t;

        SELECT string_agg(uid, ', ')
        INTO duplicate_uids
        FROM (SELECT data ->> 'document_uid' AS uid
              FROM documents_imprimeries_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) d;

        IF duplicate_count > 0 THEN
            RAISE NOTICE 'Detected % duplicate documents_imprimerie uid(s): %',
                duplicate_count,
                duplicate_uids;
        ELSE
            RAISE NOTICE 'No duplicate documents_imprimerie uid detected';
        END IF;
    END
$$;

WITH dedup AS (SELECT DISTINCT ON (data ->> 'document_uid') data
               FROM documents_imprimeries_raw
               WHERE data ->> 'document_uid' IS NOT NULL
               ORDER BY data ->> 'document_uid',
                        (data ->> 'legislature_snapshot')::int DESC,
                        data ->> 'row_hash')

INSERT
INTO documents_imprimeries_snapshot (document_uid,
                                     issn,
                                     isbn,
                                     dian,
                                     nb_page,
                                     prix,
                                     row_hash,
                                     legislature_snapshot)
SELECT data ->> 'document_uid',
       data ->> 'issn',
       data ->> 'isbn',
       data ->> 'dian',
       NULLIF(data ->> 'nb_page', '')::int,
       data ->> 'prix',
       data ->> 'row_hash',
       (data ->> 'legislature_snapshot')::int
FROM dedup

ON CONFLICT (document_uid) DO UPDATE SET issn                 = EXCLUDED.issn,
                                         isbn                 = EXCLUDED.isbn,
                                         dian                 = EXCLUDED.dian,
                                         nb_page              = EXCLUDED.nb_page,
                                         prix                 = EXCLUDED.prix,
                                         row_hash             = EXCLUDED.row_hash,
                                         legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE documents_imprimeries_snapshot.row_hash IS DISTINCT FROM EXCLUDED.row_hash;