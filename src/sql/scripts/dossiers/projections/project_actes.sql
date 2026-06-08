DO $$
    DECLARE
        duplicate_count integer;
        duplicate_uids text;
    BEGIN
        SELECT COUNT(*)
        INTO duplicate_count
        FROM (
                 SELECT data->>'uid'
                 FROM acte_legislatif_raw
                 GROUP BY 1
                 HAVING COUNT(*) > 1
             ) t;

        SELECT string_agg(uid, ', ')
        INTO duplicate_uids
        FROM (
                 SELECT data->>'uid' AS uid
                 FROM acte_legislatif_raw
                 GROUP BY 1
                 HAVING COUNT(*) > 1
             ) d;

        IF duplicate_count > 0 THEN
            RAISE NOTICE 'Detected % duplicate acte_legislatif uid(s): %',
                duplicate_count,
                duplicate_uids;
        ELSE
            RAISE NOTICE 'No duplicate acte_legislatif uid detected';
        END IF;
    END $$;

WITH dedup AS (
    SELECT DISTINCT ON (data->>'uid')
        data
    FROM acte_legislatif_raw
    WHERE data->>'uid' IS NOT NULL
    ORDER BY
        data->>'uid',
        (data->>'legislature_snapshot')::int DESC,
        md5(data::text)
)

INSERT INTO acte_legislatif_snapshot (
    uid,
    dossier_uid,
    parent_acte_uid,
    type_acte,
    code_acte,
    nom_canonique,
    libelle_court,
    organe_uid,
    date_acte,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'uid',
    data->>'dossier_uid',
    data->>'parent_acte_uid',
    data->>'type_acte',
    data->>'code_acte',
    data->>'nom_canonique',
    data->>'libelle_court',
    data->>'organe_uid',
    NULLIF(data->>'date_acte', '')::timestamptz,
    md5(data::text),
    (data->>'legislature_snapshot')::int
FROM dedup

ON CONFLICT (uid) DO UPDATE
    SET
        dossier_uid         = EXCLUDED.dossier_uid,
        parent_acte_uid     = EXCLUDED.parent_acte_uid,
        type_acte           = EXCLUDED.type_acte,
        code_acte           = EXCLUDED.code_acte,
        nom_canonique       = EXCLUDED.nom_canonique,
        libelle_court       = EXCLUDED.libelle_court,
        organe_uid          = EXCLUDED.organe_uid,
        date_acte           = EXCLUDED.date_acte,
        row_hash            = EXCLUDED.row_hash,
        legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE acte_legislatif_snapshot.row_hash IS DISTINCT FROM EXCLUDED.row_hash;