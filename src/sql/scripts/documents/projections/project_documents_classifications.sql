DO
$$
    DECLARE
        duplicate_count integer;
        duplicate_uids  text;
    BEGIN
        SELECT COUNT(*)
        INTO duplicate_count
        FROM (SELECT data ->> 'document_uid'
              FROM documents_classifications_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) t;

        SELECT string_agg(uid, ', ')
        INTO duplicate_uids
        FROM (SELECT data ->> 'document_uid' AS uid
              FROM documents_classifications_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) d;

        IF duplicate_count > 0 THEN
            RAISE NOTICE 'Detected % duplicate document_classification uid(s): %',
                duplicate_count,
                duplicate_uids;
        ELSE
            RAISE NOTICE 'No duplicate document_classification uid detected';
        END IF;
    END
$$;

WITH dedup AS (SELECT DISTINCT ON (data ->> 'document_uid') data
               FROM documents_classifications_raw
               WHERE data ->> 'document_uid' IS NOT NULL
               ORDER BY data ->> 'document_uid',
                        (data ->> 'legislature_snapshot')::int DESC,
                        data ->> 'row_hash')

INSERT
INTO documents_classifications_snapshot (document_uid,
                                         depot_code,
                                         depot_libelle,
                                         classe_code,
                                         classe_libelle,
                                         type_code,
                                         type_libelle,
                                         sous_type_code,
                                         sous_type_libelle,
                                         sous_type_libelle_edition,
                                         statut_adoption_code,
                                         statut_adoption_libelle,
                                         row_hash,
                                         legislature_snapshot)
SELECT data ->> 'document_uid',
       data ->> 'depot_code',
       data ->> 'depot_libelle',
       data ->> 'classe_code',
       data ->> 'classe_libelle',
       data ->> 'type_code',
       data ->> 'type_libelle',
       data ->> 'sous_type_code',
       data ->> 'sous_type_libelle',
       data ->> 'sous_type_libelle_edition',
       data ->> 'statut_adoption_code',
       data ->> 'statut_adoption_libelle',
       data ->> 'row_hash',
       (data ->> 'legislature_snapshot')::int
FROM dedup

ON CONFLICT (document_uid) DO UPDATE SET depot_code                = EXCLUDED.depot_code,
                                         depot_libelle             = EXCLUDED.depot_libelle,
                                         classe_code               = EXCLUDED.classe_code,
                                         classe_libelle            = EXCLUDED.classe_libelle,
                                         type_code                 = EXCLUDED.type_code,
                                         type_libelle              = EXCLUDED.type_libelle,
                                         sous_type_code            = EXCLUDED.sous_type_code,
                                         sous_type_libelle         = EXCLUDED.sous_type_libelle,
                                         sous_type_libelle_edition = EXCLUDED.sous_type_libelle_edition,
                                         statut_adoption_code      = EXCLUDED.statut_adoption_code,
                                         statut_adoption_libelle   = EXCLUDED.statut_adoption_libelle,
                                         row_hash                  = EXCLUDED.row_hash,
                                         legislature_snapshot      = EXCLUDED.legislature_snapshot
WHERE documents_classifications_snapshot.row_hash IS DISTINCT FROM EXCLUDED.row_hash;