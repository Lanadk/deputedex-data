DO $$
    DECLARE
        duplicate_count integer;
        duplicate_uids text;
    BEGIN
        SELECT COUNT(*)
        INTO duplicate_count
        FROM (
                 SELECT data->>'uid'
                 FROM amendements_raw
                 GROUP BY 1
                 HAVING COUNT(*) > 1
             ) t;

        SELECT string_agg(uid, ', ')
        INTO duplicate_uids
        FROM (
                 SELECT data->>'uid' AS uid
                 FROM amendements_raw
                 GROUP BY 1
                 HAVING COUNT(*) > 1
             ) d;

        IF duplicate_count > 0 THEN
            RAISE NOTICE 'Detected % duplicate amendement uid(s): %',
                duplicate_count,
                duplicate_uids;
        ELSE
            RAISE NOTICE 'No duplicate amendement uid detected';
        END IF;
    END $$;

WITH dedup AS (
    SELECT DISTINCT ON (data->>'uid')
        data
    FROM amendements_raw
    WHERE data->>'uid' IS NOT NULL
    ORDER BY
        data->>'uid',
        (data->>'legislature_snapshot')::int DESC,
        data->>'row_hash'
)

INSERT INTO amendements_snapshot (
    uid,
    chronotag,
    legislature,
    numero_long,
    numero_ordre,
    numero_rect,
    organe_examen,
    examen_ref,
    texte_leg_ref,
    acteur_uid,
    groupe_politique_ref,
    type_auteur,
    division_titre,
    division_type,
    division_avant_apres,
    alinea_numero,
    dispositif,
    expose_sommaire,
    date_depot,
    date_publication,
    date_sort,
    sort,
    etat_code,
    etat_libelle,
    sous_etat_code,
    sous_etat_libelle,
    article99,
    row_hash,
    legislature_snapshot
)
SELECT
    data->>'uid',
    data->>'chronotag',
    data->>'legislature',
    data->>'numero_long',
    data->>'numero_ordre',
    data->>'numero_rect',
    data->>'organe_examen',
    data->>'examen_ref',
    data->>'texte_leg_ref',
    data->>'acteur_uid',
    data->>'groupe_politique_ref',
    data->>'type_auteur',
    data->>'division_titre',
    data->>'division_type',
    data->>'division_avant_apres',
    data->>'alinea_numero',
    data->>'dispositif',
    data->>'expose_sommaire',
    NULLIF(data->>'date_depot', '')::date,
    NULLIF(data->>'date_publication', '')::date,
    NULLIF(data->>'date_sort', '')::timestamptz,
    data->>'sort',
    data->>'etat_code',
    data->>'etat_libelle',
    data->>'sous_etat_code',
    data->>'sous_etat_libelle',
    CASE
        WHEN data->>'article99' = 'true' THEN true
        WHEN data->>'article99' = 'false' THEN false
        END,
    data->>'row_hash',
    (data->>'legislature_snapshot')::int
FROM dedup

ON CONFLICT (uid) DO UPDATE SET
                                chronotag = EXCLUDED.chronotag,
                                legislature = EXCLUDED.legislature,
                                numero_long = EXCLUDED.numero_long,
                                numero_ordre = EXCLUDED.numero_ordre,
                                numero_rect = EXCLUDED.numero_rect,
                                organe_examen = EXCLUDED.organe_examen,
                                examen_ref = EXCLUDED.examen_ref,
                                texte_leg_ref = EXCLUDED.texte_leg_ref,
                                acteur_uid = EXCLUDED.acteur_uid,
                                groupe_politique_ref = EXCLUDED.groupe_politique_ref,
                                type_auteur = EXCLUDED.type_auteur,
                                division_titre = EXCLUDED.division_titre,
                                division_type = EXCLUDED.division_type,
                                division_avant_apres = EXCLUDED.division_avant_apres,
                                alinea_numero = EXCLUDED.alinea_numero,
                                dispositif = EXCLUDED.dispositif,
                                expose_sommaire = EXCLUDED.expose_sommaire,
                                date_depot = EXCLUDED.date_depot,
                                date_publication = EXCLUDED.date_publication,
                                date_sort = EXCLUDED.date_sort,
                                sort = EXCLUDED.sort,
                                etat_code = EXCLUDED.etat_code,
                                etat_libelle = EXCLUDED.etat_libelle,
                                sous_etat_code = EXCLUDED.sous_etat_code,
                                sous_etat_libelle = EXCLUDED.sous_etat_libelle,
                                article99 = EXCLUDED.article99,
                                row_hash = EXCLUDED.row_hash,
                                legislature_snapshot = EXCLUDED.legislature_snapshot
WHERE amendements_snapshot.row_hash IS DISTINCT FROM EXCLUDED.row_hash;