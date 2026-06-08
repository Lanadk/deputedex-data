DO
$$
    DECLARE
        duplicate_count integer;
        duplicate_uids  text;
    BEGIN
        SELECT COUNT(*)
        INTO duplicate_count
        FROM (SELECT data ->> 'uid'
              FROM documents_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) t;

        SELECT string_agg(uid, ', ')
        INTO duplicate_uids
        FROM (SELECT data ->> 'uid' AS uid
              FROM documents_raw
              GROUP BY 1
              HAVING COUNT(*) > 1) d;

        IF duplicate_count > 0 THEN
            RAISE NOTICE 'Detected % duplicate document uid(s): %',
                duplicate_count,
                duplicate_uids;
        ELSE
            RAISE NOTICE 'No duplicate document uid detected';
        END IF;
    END
$$;

WITH dedup AS (SELECT DISTINCT ON (data ->> 'uid') data
               FROM documents_raw
               WHERE data ->> 'uid' IS NOT NULL
               ORDER BY data ->> 'uid',
                        (data ->> 'legislature_snapshot')::int DESC,
                        data ->> 'row_hash')

INSERT
INTO documents_snapshot (uid,
                         legislature,
                         denomination_structurelle,
                         provenance,
                         titre_principal,
                         titre_principal_court,
                         dossier_ref,
                         redacteur,
                         date_creation,
                         date_depot,
                         date_publication,
                         date_publication_web,
                         num_notice,
                         formule,
                         adoption_conforme,
                         row_hash,
                         legislature_snapshot)
SELECT data ->> 'uid',
       NULLIF(data ->> 'legislature', '')::int,
       data ->> 'denomination_structurelle',
       data ->> 'provenance',
       data ->> 'titre_principal',
       data ->> 'titre_principal_court',
       data ->> 'dossier_ref',
       data ->> 'redacteur',
       NULLIF(data ->> 'date_creation', '')::date,
       NULLIF(data ->> 'date_depot', '')::date,
       NULLIF(data ->> 'date_publication', '')::date,
       NULLIF(data ->> 'date_publication_web', '')::date,
       data ->> 'num_notice',
       data ->> 'formule',
       CASE
           WHEN data ->> 'adoption_conforme' = 'true' THEN true
           WHEN data ->> 'adoption_conforme' = 'false' THEN false
           END,
       data ->> 'row_hash',
       (data ->> 'legislature_snapshot')::int
FROM dedup

ON CONFLICT (uid) DO UPDATE SET legislature               = EXCLUDED.legislature,
                                denomination_structurelle = EXCLUDED.denomination_structurelle,
                                provenance                = EXCLUDED.provenance,
                                titre_principal           = EXCLUDED.titre_principal,
                                titre_principal_court     = EXCLUDED.titre_principal_court,
                                dossier_ref               = EXCLUDED.dossier_ref,
                                redacteur                 = EXCLUDED.redacteur,
                                date_creation             = EXCLUDED.date_creation,
                                date_depot                = EXCLUDED.date_depot,
                                date_publication          = EXCLUDED.date_publication,
                                date_publication_web      = EXCLUDED.date_publication_web,
                                num_notice                = EXCLUDED.num_notice,
                                formule                   = EXCLUDED.formule,
                                adoption_conforme         = EXCLUDED.adoption_conforme,
                                row_hash                  = EXCLUDED.row_hash,
                                legislature_snapshot      = EXCLUDED.legislature_snapshot
WHERE documents_snapshot.row_hash IS DISTINCT FROM EXCLUDED.row_hash;